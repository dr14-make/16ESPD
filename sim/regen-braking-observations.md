# Observations: coasting and braking of the drivable planar BEV

Seen while driving `sim/drive.jl` (native) and the wasm build of the same model. These are
observations to verify, not fixes. Reproduce with:

    julia +dyad-3.5.0 --project=. sim/check_coast_brake.jl

`Vehicle.Planar.PlanarBEVDrive` (`dyad/Vehicle/Planar/PlanarBEVDrive.dyad`) is the model:
`PlanarCar`, `ElectricDrive` on the front axle through `DifferentialGear`,
`Vehicle.Electric.RegenBlend`, `BrakeControlUnit` (continuous ESP and a 5 ms four-channel
`ABSUnit`) and `PlanarRoadLoad`. Its brake chain is the one `PlanarBEVHardStop` uses, without the
ABS rule that bench switches on, so the braking finding applies to the bench only with `withdraw = 0`.

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

## 2. Braking: front ABS now withdraws regen

The follow-up enables `RegenBlend(abs_rule = true)` in `PlanarBEVDrive` and routes the opt-in
`BrakeControlUnit.front_active` output to `blend.abs_active`. Running
`julia +dyad-3.5.0 --project=. sim/check_coast_brake.jl` completes without front-wheel reversal.
On the same pedal sequence (9 s full throttle, 10 s coast, full brake at 19 s), sampled every
5 ms to the first speed below 0.5 m/s, stopping distance is **36.492357 → 36.231404 m**.
Minimum front slip above 3 m/s is **−5.917799 → −0.127072**; minimum front angular speed in
that range is **−47.6110 → +8.8282 rad/s**. Coast behavior and brake calibration are unchanged.

### Historical check before the follow-up

Full brake pedal (`brake_pedal.k = 1`) from 94.5 km/h, ABS and ESP on, dry road:

| t [s] | v [km/h] | motor torque [N·m] | friction demand per wheel [N·m] | τ friction FL | τ friction RL | κ FL | κ RL |
|---|---|---|---|---|---|---|---|
| 19.25 | 87.2 | −110 | 2226 | 683 | 933 | −0.119 | −0.090 |
| 19.75 | 69.2 | −153 | 2175 | 614 | 941 | −0.121 | −0.092 |
| 20.25 | 51.2 | −206 | 2061 | 417 | 1032 | −0.093 | −0.077 |
| 20.75 | 33.9 | −267 | 1845 | 39 | 1048 | −0.593 | −0.073 |
| 21.0 | 26.0 | −274 | 1845 | 4 | 925 | −1.657 | −0.083 |
| 21.5 | 10.2 | −249 | 1845 | 0 | 1015 | −6.24 | −0.070 |

(FR and RR mirror FL and RL. Below the ABS's 1.5 m/s cut-off the demand passes straight through and
all four brakes lock for the last metre.)

What the numbers show:

- **Above the 34.3 km/h corner the ABS modulates all four friction brakes.** Regen is limited by
  charge power to 110–206 N·m at the shaft, the front friction brakes carry 400–700 N·m per wheel,
  and the front slip stays near the tire's 0.12 peak.
- **Below the corner the motor alone locks the front axle and drives it backward.** The blend asks
  the machine for its 320 N·m torque limit; it delivers 250–275 N·m, about 1100 N·m per front wheel
  through the 8.193 reduction. The ABS releases the front friction brakes to zero, but it cannot
  release the machine: the front slip passes −0.59 at 33.9 km/h and reaches −6.2 at 10 km/h, a
  wheel turning backward.
- **`PlanarBEVDrive` does not use the ABS rule.** `RegenBlend(abs_rule = true)` withdraws regen
  while `ABSUnit.front_active` reports a front brake held below its demand; `PlanarBEVHardStop` and
  `PlanarBEVLowGripStop` use it (`withdraw = 1`) and keep the front slip above −0.2 while the car
  is faster than 3 m/s. The drivable car has the blend without the rule.
- **`RegenBlend` still splits the friction remainder equally over four wheels**:

      tau_brake = (tau_demand - tau_regen) * ratio / 4

  Regen acts on the front axle only, but the remainder is asked equally of all four brakes.

To verify or fix:

- Use `RegenBlend(abs_rule = true)` in `PlanarBEVDrive` and connect `ABSUnit.front_active` (the
  `BrakeControlUnit` would have to pass it out) to `blend.abs_active`, as the hard-stop benches do.
  On the 80 km/h hard stop the rule costs 0.16 m against friction alone (27.10 m against 26.94 m);
  without it the stop takes 27.24 m with the front wheels turning backward.
- Per-axle distribution: compute each axle's friction share from a target front/rear brake balance
  minus that axle's regen, rather than an equal quarter of the remainder.
- Any change here moves `PlanarBEVDrive`, its wasm build and `sim/drive.jl`'s HUD expectations.

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
   Leaf's OEM tires if published (EU tire-label rolling-resistance class); compare with 0.012.
4. **Coast-down times.** From the published A, B, C, integrate the coast-down time 100 → 60 km/h and
   100 → 20 km/h with the test mass (EPA ETW), and compare with the model's time over the same speeds
   (`sim/check_coast_brake.jl`, extended to coast longer). This gives one number per case that
   either agrees or does not.
5. **Mass and inertia.** The model uses 1500 kg plus four wheels at 1 kg·m². Compare with the Leaf's
   curb mass, the EPA test weight, and a sourced wheel-and-tire inertia; note how much each changes
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
