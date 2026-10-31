# Observations: coasting and braking of the drivable planar BEV

Seen while driving `sim/drive.jl` (native) and the wasm build of the same model. These are
observations to verify, not fixes. Reproduce with:

    julia +dyad-3.5.0 --project=. sim/check_coast_brake.jl

`sim/plant.jl`'s `drive_model` is the model: `PlanarCar`, `ElectricDrive` on the front axle through
`DifferentialGear`, `Vehicle.Electric.RegenBlend`, `BrakeControlUnit` (continuous ESP and a 5 ms
four-channel `ABSUnit`) and `PlanarRoadLoad`. It wires exactly what
`dyad/Vehicle/Planar/PlanarBEVDrive.dyad` declares; that file is not compiled yet. Its brake chain is
the one `PlanarBEVHardStop` uses, so the braking finding applies to that bench and its tests as well.

## 1. Coasting: the road load is present and correct; there is no lift-off deceleration

From full throttle to 105.6 km/h, then throttle released at t = 9 s:

| t [s] | v [km/h] | road load F [N] | motor torque [N·m] |
|---|---|---|---|
| 9 | 105.6 | 502 | 120 (driving) |
| 11 | 103.9 | 492 | −1 |
| 15 | 99.1 | 463 | −1 |
| 19 | 94.5 | 437 | −2 |

- `PlanarRoadLoad` contains both terms and the force matches the hand calculation at 29.33 m/s:
  air drag ½ · 1.2 · 0.63 · 29.33² = 325 N, rolling 0.012 · 1500 · 9.807 = 177 N, sum 502 N.
- The drag term scales with v²: at 94.5 km/h it is 325 · (94.5 / 105.6)² = 260 N, plus 177 N rolling,
  which is the 437 N measured.
- The deceleration is 502 / 1500 = 0.33 m/s², about 1.1 km/h per second. That is what this car in
  neutral should do with these coefficients, and it reads as "no resistance" while driving.
- The wasm build (`sim/wasm/full.wasm`, run in Node) gives the same speeds to 0.1 km/h at every
  point of this coast-down, so the browser car has the same road load.
- The user's report while driving: the drag "does not seem real at all". The force is applied as
  modeled, so either the coefficients or the model's expectations need checking, not the wiring.
- `RegenBlend` regenerates only for a negative `tau_ref` (a brake request), so releasing the throttle
  gives free coasting: no lift-off (coast) regeneration, which a production EV has.

To verify: whether `CdA = 0.63` m² and `f_r = 0.012` are the intended values, and whether lift-off
regeneration belongs in the drivable model (pedal map) or in `RegenBlend`.

## 2. Braking: the front friction brakes are held at zero while the motor alone brakes the front axle

Full brake pedal (`brake_pedal.k = 1`) from 94.5 km/h, ABS and ESP on, dry road:

| t [s] | v [km/h] | motor torque [N·m] | friction demand per wheel [N·m] | τ friction FL | τ friction RL | κ FL | κ RL |
|---|---|---|---|---|---|---|---|
| 19.25 | 88.9 | −124 | 2231 | 223 | 679 | −0.051 | −0.037 |
| 19.75 | 78.0 | −135 | 2212 | 8 | 873 | −0.034 | −0.050 |
| 20.5 | 61.4 | −172 | 2134 | 0 | 838 | −0.043 | −0.047 |
| 21.25 | 42.5 | −250 | 1972 | 0 | 804 | −0.067 | −0.042 |
| 22.0 | 19.3 | −313 | 1845 | 0 | 894 | −0.100 | −0.048 |

(FR and RR mirror FL and RL. Below `v_fade` = 10 km/h the regen ceiling fades to zero and the front
friction brakes come back, which is the "front only near standstill" seen while driving.)

What the numbers show:

- **The front wheels are braked only by the motor.** Up to 313 N·m at the shaft, ×8.193 through the
  reduction, is about 1280 N·m per front wheel, against a friction demand of 1845–2231 N·m per wheel.
- **The ABS releases the front friction brakes because the regen alone holds the front slip past its
  threshold** (κ FL −0.04 to −0.10). The machine is outside the ABS loop (as `RegenBlend`'s docstring
  says), so the ABS can only remove friction torque from the front, never regen torque.
- **Likely root cause: `RegenBlend` splits the friction remainder equally over four wheels**:

      tau_brake = (tau_demand - tau_regen) * ratio / 4

  Regen acts on the front axle only, but the remainder is asked equally of all four brakes. The front
  axle is therefore asked for regen plus its full friction share, more than its grip, and the ABS
  drops the front friction to zero. The rear axle gets only its quarter shares.
- `PlanarBEVHardStop`'s docstring already describes this behavior ("the ABS holds the front friction
  brakes off and the front tires work at about 65 % of their grip"), so it is documented, but it is
  not what a production brake system does. There, regen and friction apply in parallel, distributed
  per axle, and regen is reduced or cut when the ABS acts on the regen axle.

To verify or fix:

- Is the stopping distance with regen (`P_charge` default) longer than with friction only
  (`P_charge = 0`, which the regen plausibility test already runs)? If yes, the blend costs braking
  performance, which confirms the finding.
- Per-axle distribution: compute each axle's friction share from a target front/rear brake balance
  minus that axle's regen, rather than an equal quarter of the remainder.
- Regen–ABS coordination: limit or cut regen while the ABS is modulating a wheel of the regen axle,
  so friction under ABS control takes over (the usual production strategy).
- Any change here moves `PlanarBEVHardStop`, `PlanarBEVRegenWLTC` and `test/regen_plausibility.jl`,
  and the Lecture 4 deck figures built from them.

## Validate against researched data

The numbers above are the model's own. Before changing anything, check them against published data
and record each source (URL, document, table) next to the number it supports. Prefer primary
sources: EPA, manufacturer specification sheets, SAE standards, peer-reviewed or national-lab
measurements. The library already tags its parameters this way (`(Nissan)`, `(INL)`, `(assumed)`);
keep that convention, and mark anything not found as `(assumed)` rather than guessing.

The drive parameters are tagged as the Nissan Leaf ZE1, so validate against that car where data
exists.

### Road load and coast-down

1. **Coast-down coefficients.** EPA's Test Car List data publishes target road-load coefficients
   A, B, C (lbf, lbf/mph, lbf/mph²) per model year, from SAE J1263/J2263 coast-down tests. Find the
   Leaf ZE1 (2018 onward) entry, convert to SI (`F = A + B v + C v²`), and tabulate it next to the
   model's `F` at 20, 50, 80, 100, 130 km/h. Report the ratio model ÷ published at each speed.
2. **Drag area.** Published `Cd` and frontal area for the Leaf ZE1, giving `CdA`; compare with the
   model's 0.63 m².
3. **Rolling resistance.** A sourced range for passenger-car `f_r` on dry asphalt, and for the
   Leaf's OEM tyres if published (EU tyre-label rolling-resistance class); compare with 0.012.
4. **Coast-down times.** From the published A, B, C, integrate the coast-down time 100 → 60 km/h and
   100 → 20 km/h with the test mass (EPA ETW), and compare with the model's time over the same speeds
   (`sim/check_coast_brake.jl`, extended to coast longer). This gives one number per case that
   either agrees or does not.
5. **Mass and inertia.** The model uses 1500 kg plus four wheels at 1 kg·m². Compare with the Leaf's
   curb mass, the EPA test weight, and a sourced wheel-and-tyre inertia; note how much each changes
   the coast-down.

### Lift-off regeneration and braking

6. **Lift-off deceleration.** Published lift-off regeneration levels for the Leaf (standard drive,
   B mode, e-Pedal), as deceleration in m/s² or g. If the drivable model gets lift-off regen, this is
   the number it should match.
7. **Brake blending.** How the Leaf (or production EVs generally) splits braking between regen and
   friction: series vs parallel blending, front/rear friction balance, and what happens to regen
   during an ABS event. Sources: Nissan or supplier documentation (the brake system's
   electro-hydraulic actuator), SAE papers on cooperative regenerative braking, ABS–regen
   coordination literature. State which strategy `RegenBlend` + `ABSUnit` corresponds to and which
   one a production car uses.
8. **Stopping distance.** A published 100 → 0 km/h braking distance for the Leaf on dry asphalt
   (magazine instrumented tests are acceptable if no primary source exists; say which). Compare with
   the model's distance from the full-brake run, with regen as now and with `P_charge = 0`.

### Report back

A table per section: quantity, model value, published value, source, ratio or difference, and a
verdict (agrees / within the source's spread / disagrees). Then, only for what disagrees, the
proposed change with the source that justifies it. Do not change parameters that agree just to make
the car "feel" different.

## 3. Display only (sim, not model)

Both sims draw only the friction-brake torque per wheel (`car.tau_*`), so a wheel braked by the
motor looks unbraked. Showing the regen torque on the front wheels (motor torque × ratio / 2 per
wheel) alongside friction would make the split visible. This is in `sim/drive.jl` and
`sim/wasm/app.mjs`, not in the library.
