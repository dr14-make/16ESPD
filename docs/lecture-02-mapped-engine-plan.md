# Lecture 2 hands-on — a mapped engine with manifold pressure

The hands-on half of the engine lecture. The lecture half is `lecture-02-plan.md`; read its
settled decisions first, because this plan inherits S1, S2, S5, S6, S7 and S10 unchanged.

## Goal

Students replace Lecture 1's `IdealEngine` with an engine an ECU calibrator would recognize: the
driver's pedal opens a throttle, the intake manifold fills, and measured maps read at engine speed
and manifold pressure return torque, fuel flow and emissions. They drive the hands-on car with it
and read off fuel consumption in L/h and L/100 km and CO₂ in g/km. The manifold pressure it
produces is the same signal the vacuum booster draws on in the brake lecture.

## Settled decisions

**M1 — Mapped, beside the physics engine.** The hands-on engine is table-driven. The lecture's
`MeanValueEngine` (lecture plan, E1–E3) stays the plant for the ECU-loop notebooks. The two answer
different questions: what the car burns, and what the ECU controls. Neither waits for the other.

**M2 — Manifold pressure is a state, not a map.** The brake booster feeds air into the manifold,
and a table cannot respond to that. The engine therefore contains the `IntakeManifold` of brake
plan increment 2a: one state `p_m`, inputs throttle angle, engine speed and booster inflow
`ṁ_bst`. Building it here completes 2a and supplies `Engine.AirPath` (lecture plan S5); it is
built once and shared.

**M3 — Maps are indexed by speed and manifold pressure.** Speed-density, as a production ECU reads
its MAP sensor. Every map output inherits the manifold dynamics: the tip-in lag, and the bump when
the booster empties into the manifold on brake release.

| Map | Axes | Source |
|---|---|---|
| Brake torque `T_e(N, p_m)` | rpm × kPa | ALPHA, derived (see M5) |
| Fuel mass flow `ṁ_f(N, p_m)` | rpm × kPa | ALPHA, derived |
| CO₂ mass flow | — | `3.09 · ṁ_f` (gasoline carbon balance, exact at full oxidation) |
| Engine-out HC, CO, NOx `(N, p_m)` | rpm × kPa | `(assumed)`; shapes from Heywood ch. 11 trends |

**M4 — The data: EPA ALPHA, 2014 Mazda 2.0 L Skyactiv, scaled to 1.5 L.** The package is public
and requires citation ("2014 Mazda 2.0L SKYACTIV Engine LEV III Fuel - ALPHA Map Package. Version
2018-02. Ann Arbor MI: US EPA NVFEL, 2018"). It holds a fuel map in g/s on 21 speeds × 24 torques
(idle to ~6900 rpm), the full-load curve (peak ≈ 200 N·m), the closed-throttle curve
(−14 to −45 N·m) and idle speed (600–800 rpm). It holds no manifold pressure and no emissions.
Scale at constant BMEP and constant BSFC: torque and fuel flow × 1.5/1.998 at equal speed. The
result keeps lecture plan S4 (1.5 L NA, port injection) and Lecture 1's `T_max = 150 N·m`, and so
keeps the manifold reality anchors already written for 1.5 L. The 1.5 L Honda L15B7 package is
not used: it is turbocharged and its manifold leaves the vacuum range.

**M5 — Torque axis to manifold-pressure axis.** Speed-density inverts the fuel map: each ALPHA
point's fuel flow is the cylinder air flow `ṁ_cyl = η_v p_m V_d N / (120 R T_m)` divided by
`AFR_s · λ`, which fixes its `p_m`; torque and fuel are then re-gridded onto (N, p_m). Two
assumptions carry the conversion, both in `data/engine/eta_v_coeffs.csv`:

- `η_v(N, p_m) = η_fl(N) · (1 − k + k p_m / 95 kPa)`. `η_fl(N)` is a quadratic in speed, fitted to
  the ALPHA full-load fuel at 95 kPa and peaking at 1.05; the load factor, with `k` set so zero
  brake torque at 800 rpm falls at 33 kPa, gives `η_v` ≈ 0.37 at idle, as late intake-valve
  closing does. With `0 < k < 1` the cylinder air flow rises strictly with `p_m`.
- `λ(N, p_m)` is 1 below 85 % of 95 kPa and falls to 0.90 (≤ 1500 rpm) through 0.80 (≥ 6000 rpm)
  at full load, for exhaust-component protection.

`Engine.CylinderAirflow` uses this `η_v` verbatim, so the air path and the maps agree on λ. The
conversion is `scripts/alpha_engine_maps.jl`, which writes the tables to `data/engine/`, so the
raw ALPHA file and every step from it stay reviewable.

**M6 — Pedal to throttle angle, directly.** A 1-D progressive pedal curve, as on a drive-by-wire
throttle with no torque structure. The torque-based pedal interpretation belongs to the lecture's
notebook 11.

**M7 — Scope A first, B if time allows.**
- **A — fixed scenarios on the one-gear hands-on car** (`Driveline`, i = 4.0, r = 0.31 m): pedal
  steps, wide-open-throttle sprint, steady cruise at 50/90/130 km/h, coast-down on closed throttle,
  and a brake stop with `p_m` on the plot.
- **B — WLTC class 3.** Adds a 5- or 6-speed gearbox with a shift schedule and a PI driver
  following the speed trace. Built only after A is complete; if the session has no room, it ships
  as a prepared notebook instead.

## Reality anchors

Bands from `lecture-02-plan.md` and the brake plan still apply. Added for the mapped engine;
"predicted" values were computed from the scaled ALPHA map on the Lecture 1 car
(m = 1400 kg, CdA = 0.63 m², f_r = 0.012), single gear, before any model was built:

| Quantity | Band | Predicted |
|---|---|---|
| Peak brake torque | 145–155 N·m | 150 N·m |
| Minimum BSFC | 225–260 g/kWh | 232 g/kWh |
| Idle fuel flow, 750 rpm | 0.4–0.9 L/h | 0.45 L/h |
| Cruise 50 km/h (1710 rpm) | 3–4 L/100 km | 3.3 L/100 km, 77 g CO₂/km |
| Cruise 90 km/h (3080 rpm) | 4–5.5 L/100 km | 4.6 L/100 km, 105 g CO₂/km |
| Cruise 130 km/h (4450 rpm) | 6–8 L/100 km | 7.0 L/100 km, 162 g CO₂/km |
| Full-load manifold pressure, each ALPHA breakpoint | 90–98 kPa | 95 kPa; four breakpoints miss (see `data/engine/README.md`) |
| Full-load `η_v` | ≤ 1.05 | 1.05 peak |
| Overrun manifold pressure, 3000 rpm | 17–34 kPa with ECU bypass air | 13.5 kPa from the plain air path; expected because it models only the idle leak |
| Zero-torque manifold pressure, 800 rpm | 30–36 kPa | 33 kPa (sets `k`); brake plan 2a |
| λ at the 50/90/130 km/h cruise points | 1 | 1 |
| Round-trip fuel, maps back at the ALPHA points | < 5 % | 4.4 % max, 0.5 % RMS |

The cruise figures are single-gear and steady-state, so they sit below a real car's WLTC label;
scope B is where that comparison is made.

## Tasks

Each task is one branch and PR in its own worktree, done when its numbers are reported against the
bands above.

1. **ALPHA import and re-grid** (`scripts/`, `data/engine/`): parse the package, scale to 1.5 L,
   convert to (N, p_m), write the torque, fuel, full-load and closed-throttle tables. Plot the
   source and derived maps side by side. Assumed HC/CO/NOx tables written here, tagged `(assumed)`.
2. **`Engine.IntakeManifold` + `Engine.Throttle`**: brake plan 2a, unchanged interface and tests,
   with V_d = 1.5 L. Closes 2a.
3. **`Engine.MappedEngine`**: pedal → throttle → manifold → `InterpolatedTable` maps → torque
   source on a crankshaft `Inertia`; outputs fuel, CO₂ and emission flows and `p_m`; exposes the
   `ṁ_bst` input. The maps hold fueled operation only, so overrun needs deceleration fuel cut:
   torque from `closed_throttle.csv`, zero fuel and emissions. Test component with idle, tip-in
   and coast-down.
4. **`Engine.MappedEngineCar`** + hands-on analyses: the hands-on car with the mapped engine, the
   scenario set of M7-A, integrated fuel and CO₂ per distance.
5. **Hands-on guide and deck** (`slides/decks/handson-02/`, VitePress guide): steps mirror tasks
   2–4, in the format of `handson-01`.
6. **Scope B** — gearbox, shift schedule, driver, WLTC trace (DieselNet, class 3).

The theory deck (`slides/decks/lecture-02/`) is carried from `2. Engine CS.pptx` slides 16–59 in
the format of `lecture-01`, with figures from the lecture notebooks (PR #2); its live cards depend
on PR #39.

## Open items

- HC, CO and NOx table shapes and magnitudes: only trends are defensible without a source; say so
  in the guide.
- The exact pedal curve.
