# Lecture 2 hands-on — step plan

One session of about 90 minutes in which students swap Lecture 1's `IdealEngine` for the mapped
engine of `lecture-02-mapped-engine-plan.md` and read fuel and CO₂ off the car. This file is
task 5 of that plan: the step plan behind the hands-on guide `slides/site/handson/lecture-02/`,
which is the one full source, its tutor guide `tutor.md` beside it, and the projector deck
`slides/decks/handson-02/`, one slide per step. It inherits decisions M1–M7 unchanged and covers
scope A only; scope B is an optional last step.

Companion documents:

- `docs/lecture-02-mapped-engine-plan.md` — the decisions, the reality anchors and tasks 1–6.
- `docs/lecture-02-handson-screenshots.md` — the Studio screenshots the guide and the deck need.
- `data/engine/README.md` — the maps, their axes and the fuel-cut requirement.

## The arc

The theory deck's section 08 promises four things: a pedal into a throttle, a manifold pressure
that is a state, measured maps read at speed and manifold pressure, and five scenarios on the
hands-on car that read off L/h, L/100 km, g CO₂/km and `p_m`. The session keeps that order.
Students first read the 90 km/h cruise point off the maps by hand, so they know the fuel figure
before any model runs; then build the one equation that makes `p_m` a state; then a map engine
of their own on a dynamometer bench; then paste the library's fuel cut into that engine, put it
in their car and drive the scenarios. Every checkpoint is a number they could have predicted.

## Built or given

The lecture's goal is that a student can read a map at (N, p_m) and explain why `p_m` lags the
pedal. The throttle's compressible-orifice flow and the λ-matched volumetric efficiency are
physics the lecture states and does not teach, and 90 minutes cannot hold them. So:

| Part | Built or given | Why |
|---|---|---|
| The maps (`data/engine/*.csv`) | given, read in the REPL | Derived from EPA data by a script; reading them is the skill, not making them. |
| `Manifold` — `V_m/(R T_m)·dp_m/dt = ṁ_thr + ṁ_bst − ṁ_cyl` | **built** (paste one equation) | It is the state the whole session is about: the lag, the overrun vacuum, the booster bump. One line, five minutes. |
| `Throttle`, `CylinderAirflow` | given, `Vehicle.Engine` | Choked-flow orifice and an `η_v` that must match the maps exactly. Re-typing coefficients teaches nothing and risks a λ that disagrees with `lambda.csv`. |
| `MapEngine` — `AirPath`, a speed sensor, `TorqueMap` (full-load cap inside), `FuelMap`, CO₂ = 3.09·fuel | **built** (drawn in the diagram: 6 given blocks, 15 wires) | The core of the lecture: speed and `p_m` in, torque and fuel out. Drawn, it is the picture of two maps hanging off the same speed and pressure wires; the only number typed is 3.09. |
| Fuel cut — `FuelCutLogic` (overrun cut and rev limiter), `CutTorqueMap`, `CutFuelMap` | **pasted** into the student's own `MapEngine`: one block, four wires, the two maps retyped (7 lines in two places) | Hysteresis latches are plumbing; what the student needs is what the cut does and when. The maps with a `cut` input keep `TorqueMap`'s and `FuelMap`'s ports, so the paste moves nothing they drew, and the engine with fuel cut is still their own. |
| `MappedEngine` — fuel cut, pedal curve, throttle actuator lag, crank inertia, λ and emission outputs | given, `Vehicle.Engine`; not used by the students | The library's full engine. Its fuel cut and closed-throttle curve are the same blocks the students paste, so it is the cross-check for step 03 E. |
| `MappedCar` — Lecture 1's `Car` with the student's `MapEngine` (fuel cut pasted in), a flywheel inertia, the given CVT driveline and later a brake | **built** (diagram edits, one parameter line in code) | The milestone, as `Car` was in hands-on 1, and both the car and its engine are the student's own. `MapEngine` has no flywheel (the dynamometer set the speed), so the car adds one `Inertia`, J = 0.15 kg·m² as `MappedEngine` assumes, between engine and driveline. |
| `CVTDriveline` — centrifugal launch clutch (engages around 1300 rpm) and a CVT, ratio 12.0–2.8 with final drive, engine speed scheduled from the pedal, 1800–6000 rpm, through a 0.5 s lag | given, `Vehicle` | The fixed 4.0 gear cannot start from rest (the engine would turn at 0 rpm, where it gives no torque) and sits on the rev limiter flat out. A clutch and a ratio controller are plumbing; the lesson is the map. Same four mechanical ports as hands-on 1's `Driveline`, plus `pedal`. |
| `RoadBrake` — friction force `F_cmd · tanh(v / 0.05 m/s)` between body and road | given, `Vehicle` | A `Force` source pushes the car backwards once it stops, and its sign depends on the wiring. The regularized friction stops the car and holds it, either way round. |
| Scenario benches | **built** (sources and initial lines) | Same pattern as hands-on 1; each is a few blocks. |
| WLTC driver and gearbox (scope B) | given, if it exists | Task 6. Not in the 90 minutes. |

Student reference solutions go in the subpackage `dyad/HandsOn02/`, as `dyad/HandsOn/` holds
hands-on 1's. Step 03's `MapEngine`, `MapEngineDyno` and `MapEngineDynoTransient` are there, and so
are the same two after the fuel-cut paste, `MapEngineFuelCut` and `MapEngineFuelCutDyno` with
`MapEngineFuelCutDynoTransient`. Students edit their one `MapEngine` in place; the repository keeps
both states, because runs 1 and 2 must keep reading the engine without the cut. Steps 04–06 are
there too: `MappedCar` with `MappedCarWOT`, `MappedCarCruise` and `MappedCarCoast`, and the car
after step 06 B, `MappedCarWithBrake`, with `MappedCarBrakeStop`. Every step's checkpoints are in
`test/engine_plausibility.jl`.

## Steps

Budgets add up to 90 minutes: 8 + 12 + 15 + 20 + 12 + 12 + 8 + 3.

### Step 00 · Set up · 8 min

**Goal.** A `handson-02` branch on the student's `MyCar`, with the course library added so
`VehicleSystemsComponents.Vehicle.Engine` appears under **+**.

**Built / given.** Given: the course library from github.com/dr14-make/16ESPD (public).

**Actions.** Branch `handson-02` from `main` after hands-on 1's PR; in the Julia REPL
`Pkg.add(url = "https://github.com/dr14-make/16ESPD")`; <kbd>F1</kbd> → `Dyad: Compile`; check the
**+** tree.

**Reference model.** None.

**Checkpoint.** `using VehicleSystemsComponents` loads; **+** → `VehicleSystemsComponents` →
`Vehicle` → `Engine` includes `AirPath`, `Throttle`, `CylinderAirflow`, `MappedEngine`.

**Rehearsed.** `Pkg.add(url = …)` plus Dyad Compile is enough: the library shows under **+**, not
in the left **Components** tree. Pkg's yellow "different versions are currently loaded" warning is
harmless.

**TODO.** Pin the course library to a tag once its branch merges, so students get the engine the
checkpoints were read from.

**Screenshots.** `step00-engine-library.png`.

### Step 01 · Read the maps · 12 min

**Goal.** Know what "speed × manifold pressure" means by finding the 90 km/h cruise point on
the torque map and reading its fuel flow, before any model runs.

**Built / given.** Given: `torque_Nm.csv`, `fuel_gps.csv`, `lambda.csv`. Built: a REPL snippet
that heatmaps them.

**Actions.** Load each CSV with `readdlm(…; header = true)`, `heatmap(kpa, rpm, Z)`; at
3080 rpm find where torque crosses 31.1 N·m (Lecture 1's 90 km/h holding torque); read fuel
there; convert to L/h and L/100 km with ρ = 0.745 kg/L; look at λ.

**Reference model.** None; the CSVs. The numbers are computed from them as
`scripts/alpha_engine_maps.jl` computes its cruise anchors (bilinear on the grid).

**Checkpoint** (from the CSVs; plan's anchors):

- 90 km/h: 3080 rpm, 31.1 N·m → `p_m` ≈ **47.8 kPa**; fuel **0.850 g/s** = **4.11 L/h** →
  **4.6 L/100 km**, **105 g CO₂/km**.
- 50 km/h: 1710 rpm, 18.4 N·m → **41.9 kPa**, **0.346 g/s** = **1.67 L/h** → **3.3 L/100 km**
  (3.34), **77 g CO₂/km**. 130 km/h: 4450 rpm, 51.0 N·m → **60.8 kPa**, **1.892 g/s** =
  **9.14 L/h** → **7.0 L/100 km**, **162 g CO₂/km**. Shown on the page beside 90 km/h; the
  "Hands-on 02 cruise table" testset checks every figure to the digit shown.
- λ = 1.00 there; **0.87** at 3000 rpm, 100 kPa (full-load enrichment).
- The 3000 rpm row alone crosses 31.1 N·m at **47.7 kPa** (0.82 g/s, 4.4 L/100 km); 47.8 kPa is
  the 90 km/h point at 3080 rpm.
- The torque map gives **160.3 N·m** at 4000 rpm, 100 kPa, and peaks at **177.0 N·m** at
  3250 rpm, 105 kPa; the full-load curve peaks at **150.2 N·m** near 4100 rpm (`full_load.csv`).

**Screenshots.** `step01-torque-map.png`, `step01-fuel-map.png` (REPL plots, not Studio).

### Step 02 · Manifold: a pressure that fills · 15 min

**Goal.** Build the manifold as one equation and see `p_m` behave as a state: it pulls down to
33 kPa at idle and settles in about 0.15 s, five times faster at 3000 rpm.

**Built / given.** Built: `Manifold` (paste), bench `AirPathStep`. Given: `Vehicle.Engine.Throttle`,
`Vehicle.Engine.CylinderAirflow`.

**Actions.** Paste `Manifold`; draw the bench: `Step` → `throttle.u_thr`, `Constant` speed →
`cylinders.omega`, `Constant(0)` → `manifold.mdot_bst`, wire the three flows and `p_m`;
`initial manifold.p = 101325`; run 3 s at 800 rpm closed; then a small step at idle; then 3000
rpm closed and wide open.

**Reference model.** Existing: `Vehicle.Engine.TestAirPath` (its five test cases are the
checkpoints). To build: `HandsOn02.Manifold`, `HandsOn02.AirPathStep`,
`HandsOn02.AirPathStepTransient`.

**Checkpoint** (from `TestAirPath`, merged in #47):

- Idle, 800 rpm, closed: 101.3 → **33.0 kPa** (32955.7 Pa).
- Small step at idle, `du = 0.005`: 33.0 → **37.3 kPa**; τ ≈ **0.15 s** on this step. The first
  fall from 101 kPa is nonlinear, with a 1/e time of about 0.10 s.
- 3000 rpm closed (overrun): **13.5 kPa**; wide open: **99.9 kPa**; τ ≈ **0.03 s**.

**TODO.** Confirm the student `Manifold` with given parts reproduces `TestAirPath` exactly (it
should: the equation is `IntakeManifold`'s).

**Screenshots.** `step02-manifold-code.png`, `step02-airpath-bench.png`,
`step02-idle-plot.png`.

### Step 03 · Map engine on a dynamometer · 20 min

**Goal.** An engine of your own that reads torque and fuel at (N, `p_m`), caps torque at the
full-load curve and makes CO₂ = 3.09 × fuel; on a bench that holds the speed, a small pedal step
at the 90 km/h cruise point shows the manifold lag in the torque. Then paste fuel cut into that
engine and see the fuel go to zero on overrun and come back near idle.

**Built / given.** Built: `MapEngine`, drawn in the diagram; bench `MapEngineDyno`, pasted; fuel
cut, pasted into `MapEngine`. Given: `Vehicle.Engine.AirPath`, `TorqueMap`, `FuelMap`,
`FuelCutLogic`, `CutTorqueMap`, `CutFuelMap`.

**Actions.** Draw `MapEngine`. Place `air` = `Engine.AirPath`, `speed` = `VelocitySensor`,
`torque_map` = `Engine.TorqueMap`, `fuel_map` = `Engine.FuelMap`, `co2` = `Gain(k = 3.09)`,
`torque` = `TorqueSource`; add the ports `pedal`, `mdot_bst` (inputs), `spline`, `support`,
`p_m`, `mdot_fuel`, `mdot_co2` (outputs). Draw the 15 wires: `pedal` → `air.u_thr`;
`mdot_bst` → `air.mdot_bst`; `speed.w` → `air.omega`, `torque_map.omega`, `fuel_map.omega`;
`air.p_m` → `torque_map.p_m`, `fuel_map.p_m`, `p_m`; `torque_map.y` → `torque.tau`;
`fuel_map.y` → `co2.u`, `mdot_fuel`; `co2.y` → `mdot_co2`; `torque.spline` → `spline`;
`speed.spline` → `spline`; `torque.support` → `support`. The pedal drives the throttle directly,
so the only lag between pedal and torque is the manifold's. Paste `MapEngineDyno` (pedal `Step`,
`Constant(0)` → `mdot_bst`, a `VelocitySource` holding `rpm`, mounts) and its analysis. First run,
the defaults: hold 3080 rpm at the 90 km/h pedal, step the pedal 0.1034 → 0.12 at 1 s, run 2 s,
plot `engine.p_m` and `engine.torque_map.y`. Second run: 3000 rpm, pedal 0 → 1. Then E, the
fuel-cut paste, in two places of `MapEngine`'s code: the `torque_map` and `fuel_map` lines are
replaced by `CutTorqueMap`, `CutFuelMap` and a new `cut_logic` = `FuelCutLogic` placed at the
bottom left; four `connect`s go after the last one (pedal and `speed.w` into `cut_logic`, its `cut`
into both maps). In `MapEngineDyno`'s `speed` line `Constant(k = rpm * pi / 30)` becomes a `Ramp`
to 800 rpm over 3 s from 2 s, which the 2 s runs never reach. Release the pedal from wide open at
3000 rpm and run 6 s.

**Reference model.** `HandsOn02.MapEngine`, `HandsOn02.MapEngineDyno`,
`HandsOn02.MapEngineDynoTransient` for A–D; `HandsOn02.MapEngineFuelCut`,
`HandsOn02.MapEngineFuelCutDyno`, `HandsOn02.MapEngineFuelCutDynoTransient` for E, the same models
after the paste. The "Hands-on 02 map engine" and "Hands-on 02 fuel cut" testsets in
`test/engine_plausibility.jl` check every number below. Applying the page's paste to a
Studio-drawn `MapEngine` and the page's bench reproduces `MapEngineFuelCutDyno` exactly.

**Checkpoint** (from `HandsOn02.MapEngineDynoTransient`):

- Run 1, 3080 rpm: before the step `p_m` **47.8 kPa**, torque **31.1 N·m**, fuel **0.85 g/s**;
  after it **52.9 kPa**, **41.4 N·m**, **1.02 g/s**. The torque rises 10–90 % in **51 ms**; `p_m`
  covers 63 % of its rise in 23 ms.
- Run 2, 3000 rpm, closed: `p_m` **13.5 kPa**, torque **−18.2 N·m**, fuel **0.097 g/s** — still
  burning. Wide open: `p_m` **99.9 kPa**; map torque 163.0 N·m, capped to **148.4 N·m**; fuel
  **3.75 g/s**, CO₂ **11.6 g/s**. The torque rises 10–90 % in 2.3 ms: a wide-open step fills the
  manifold almost at once and hides the lag.
- Cruise pedals, found by bisection: **0.044 / 0.103 / 0.190** hold 18.4 / 31.1 / 51.0 N·m at
  1710 / 3080 / 4450 rpm, with fuel 0.346 / 0.850 / 1.892 g/s as `fuel_gps.csv` reads at those
  pressures. `MappedEngine` puts a pedal curve and a 50 ms throttle actuator in front of the
  same air path; the curve makes its steady pedals 0.124 / 0.220 / 0.331.
- Idle, 800 rpm, closed: `p_m` **33.0 kPa**.
- E, pedal released from wide open at 3000 rpm at 1 s: before it **148.4 N·m**, **3.75 g/s**; the
  fuel is 99 % gone in **30 ms**, then **0**; the torque settles at **−18.7 N·m**
  (`closed_throttle.csv` at 3000 rpm), against run 2's −18.2 with the fuel still on; `p_m`
  **13.5 kPa**. `MappedEngine` released the same way ends on the same torque. On the ramp the fuel
  stays cut through 1300 rpm and returns at **4.73 s**, below **1000 rpm**, with `p_m` **27.0 kPa**;
  at 800 rpm, 6 s: **33.0 kPa**, **0.096 g/s**, torque about 0.
- After the paste, run 1 is unchanged and run 2 starts in the cut: 0 fuel and −18.7 N·m with the
  pedal closed. So runs 1 and 2 stay on `HandsOn02.MapEngine`, the engine before the paste.

**TODO.** Rehearse the 15-wire drawing once in Dyad Studio against the 8 minutes it is given; if
it overruns, hand out the "Stuck?" code and keep the runs.

**TODO.** Rehearse E's three pastes in Dyad Studio's code view. They were checked with the CLI only:
applied to a Studio-drawn `MapEngine` and bench, they compile, render with no placement warning
and run identical to `MapEngineFuelCutDyno`; whether Studio keeps the inline annotations as
written, and how long the step takes, is not yet seen.

**Screenshots.** `step03-map-engine.png`, `step03-dyno-bench.png`, `step03-step-plot.png`,
`step03-fuel-cut-plot.png`.

### Step 04 · The car with a mapped engine · 12 min

**Goal.** Your Lecture 1 car with the new engine and a CVT; full pedal from rest launches through
the clutch and reaches a real top speed, not 246 km/h.

**Built / given.** Built: `MappedCar` (duplicate `Car`), bench `MappedCarWOT` (pasted). Given:
`Vehicle.CVTDriveline`. The engine is the student's own `MapEngine` from step 03, fuel cut
included.

**Actions.** Duplicate `Car` → `MappedCar`; delete `engine`, place the student's `MapEngine` as
`engine`; delete `driveline`, place `Vehicle.CVTDriveline` as `driveline` on the same four
mechanical ports; rename the input `tau_cmd` → `pedal` and wire it to `engine.pedal` and
`driveline.pedal`; add `flywheel` = `RotationalComponents.Components.Inertia(J = 0.15)` between
`engine.spline` and `driveline.spline`; `Constant(0)` → `engine.mdot_bst`; new outputs `p_m`
(from `engine.p_m`) and `fuel_lph` (`Gain(k = 3600/0.745)` on `engine.mdot_fuel`); in code, a
`parameter ratio_initial::Real = 12` passed to `CVTDriveline(ratio_initial = ratio_initial)`.
Bench: `Constant(1)` pedal, car at rest, engine at 900 rpm, 120 s.

The bench sets `car.body.mass.s`, `car.body.mass.v`, `car.flywheel.w`, `car.flywheel.phi`,
`car.driveline.clutch.spline_b.phi` and `car.engine.air.manifold.p`: the clutch lets the engine
and the wheel turn apart, so each side needs its own speed and angle. `ratio_initial` is a car
parameter because a nested modifier on the driveline, `MappedCar(driveline(ratio_initial = …))`,
resolves bench parameters inside the car and fails at setup.

**Reference model.** `HandsOn02.MappedCar` (on `HandsOn02.MapEngineFuelCut`),
`HandsOn02.MappedCarWOT`, `HandsOn02.MappedCarWOTTransient`.

**Checkpoint** ("Hands-on 02 CVT" testset):

- Launch: the engine flares to **1300 rpm** while the clutch slips; it locks at **1.33 s**,
  13.7 km/h, 1414 rpm.
- **0–100 km/h in 10.4 s.** The engine peaks at **6390 rpm** at 6.4 s, under the 6500 rpm
  limiter (the ratio sits on its 12.0 stop up to about 58 km/h), then settles at 6000 rpm. The
  fuel is never cut.
- **197 km/h at 60 s, 205 km/h at 120 s**, 205.3 km/h terminal, ratio 3.41: 126.5 N·m at 6000 rpm
  and 98.8 kPa, 79.5 kW, equals the road load there.

**Screenshots.** `step04-mapped-car.png`, `step04-wot-plot.png`.

### Step 05 · Cruise: fuel and CO₂ · 12 min

**Goal.** Hold 50, 90 and 130 km/h, read `fuel_lph`, turn it into L/100 km and g CO₂/km by hand,
and compare with step 01's fixed-gear prediction.

**Built / given.** Built: bench `MappedCarCruise` (pasted; one bench, three runs from the REPL).

**Actions.** Paste the bench; it starts steady at `speed_kmh`, with the engine at `rpm0`, the CVT
at the matching ratio and the manifold at `p_m0`, and holds `pedal_cmd`. Run 60 s at the
defaults (90 km/h) and with the given values for 50 and 130 km/h; read `car.v_kmh`,
`car.fuel_lph`, `car.p_m` at 60 s; L/100 km = L/h ÷ km/h × 100; g CO₂/km = 2302 × L/h ÷ km/h.

| km/h | `pedal_cmd` | `rpm0` | `p_m0` |
|---|---|---|---|
| 50 | 0.04878 | 1992 | 40100 |
| 90 | 0.0916 | 2182 | 54420 |
| 130 | 0.17373 | 3118 | 67220 |

**Reference model.** `HandsOn02.MappedCarCruise`, `HandsOn02.MappedCarCruiseTransient`.

**Checkpoint** ("Hands-on 02 CVT cruise" testset; each speed held within 0.25 km/h for 60 s):

| km/h | rpm | ratio | `p_m` kPa | L/h | L/100 km | g CO₂/km | fixed gear (step 01) |
|---|---|---|---|---|---|---|---|
| 50 | 1992 | 4.64 | 40.1 | 1.84 | **3.7** | **85** | 3.3 at 1710 rpm |
| 90 | 2182 | 2.83 | 54.4 | 3.55 | **3.9** | **91** | 4.6 at 3080 rpm |
| 130 | 3118 | 2.80 | 67.2 | 7.78 | **6.0** | **138** | 7.0 at 4450 rpm |

The fuel map read at the CVT's rpm and `p_m` gives the car's fuel flow to 1 %. The CVT burns
more at 50 km/h because its schedule never goes below 1800 rpm, where the fixed gear runs
1710 rpm, and less at 90 and 130 because it runs the engine slower and less throttled. A
fuel-optimal schedule along the map's lowest-consumption line is an extension, not built.

**Screenshots.** `step05-cruise-bench.png`, `step05-cruise-90-plot.png`.

### Step 06 · Coast-down and a brake stop · 8 min

**Goal.** Release the pedal at 90 km/h: fuel goes to zero and the engine brakes the car; then
brake to rest and hold there, and watch the vacuum the brake booster will draw on.

**Built / given.** Built: bench `MappedCarCoast` (copy of `MappedCarCruise`), then an `F_brake`
input and `brake` = `Vehicle.RoadBrake` in `MappedCar`, and `brake_cmd` in the bench. Given:
`Vehicle.RoadBrake`.

**Actions.** Pedal `Step` from the 90 km/h value to 0 at 5 s; run 100 s; plot `v_kmh`,
`engine.speed.w`, `fuel_lph`, `p_m`. Then `brake_cmd` = `Step(height = 4000, start_time = 5)` →
`car.F_brake`, and run 20 s; the other benches get `Constant(0)` into `car.F_brake`.

**Reference model.** `HandsOn02.MappedCarCoast` and `MappedCarCoastTransient` (part A);
`HandsOn02.MappedCarWithBrake`, `MappedCarBrakeStop` and `MappedCarBrakeStopTransient` (part B).

**Checkpoint** ("Hands-on 02 CVT coast and brake" testset):

- At release: fuel **3.55 → 0 L/h** within 10 ms; `p_m` **17.1 kPa** (the engine turns
  2150 rpm, not 3000, so not step 02's 13.5); **0.39 m/s²** against 0.29 in neutral.
- From 70 to 30 km/h the CVT holds the engine at **1730–1780 rpm**, still cut.
- Clutch open at **66.0 s, 11.2 km/h**, 1140 rpm; fuel back at **66.3 s, 10.8 km/h**, below
  1000 rpm, `p_m` **27.4 kPa**; idle **775 rpm**, 33.6 kPa, 0.47 L/h; at rest at about 91 s.
- Brake stop: **3.2 m/s²**; 25 km/h at 10.7 s; **at rest at 12.9 s** and held; `p_m` 17.6–33.7 kPa
  throughout; fuel back and clutch open at 12.0 s, 10.4 km/h; no stall, idle at 775 rpm.
- `RoadBrake` slows a 1400 kg mass at 4000 / 1400 m/s² and holds it at rest, wired either way
  round ("Vehicle road brake" testset).

**Screenshots.** `step06-coast-plot.png`, `step06-mapped-car-brake.png`,
`step06-brake-plot.png`.

### Hand in · 3 min

Pull request `handson-02` → `main`, as in hands-on 1, with the cruise table filled in.

### Step 07 · WLTC (if time allows) · —

**Goal.** The car on the WLTC class 3 trace with a gearbox and a driver; compare L/100 km and
g CO₂/km with a real 1.5 L car's label.

**Built / given.** Given: everything (task 6). If task 6 has not landed, it ships as a prepared
notebook and the step is a demo.

**Reference model.** To build: task 6.

**Checkpoint.** **TODO** the WLTC L/100 km and g CO₂/km from task 6, and the label figure to
compare against (with its source).

**Screenshots.** **TODO** with task 6.

## TODO slots and what fills each

| Slot | Where | Filled by |
|---|---|---|
| Course-library tag to pin | step 00 | the branch merging |
| Rehearsal of the 15-wire `MapEngine` drawing | step 03 | rehearsal in Studio |
| WLTC numbers and the label | step 07 | task 6 |
| Screenshots of step 07 | step 07 | task 6 |

## Settled with the lecturer

- **The cruise table before step 05:** shown. Step 01 gives the 50 and 130 km/h figures beside
  90 km/h; step 05 measures all three in the car.
- **Fuel cut:** students do not build the latch. They paste it, with an explanation, into their own
  `MapEngine` in step 03 E; the swap to the library `MappedEngine` is dropped.
- **The car's engine:** the student's own `MapEngine` with the pasted fuel cut, plus a flywheel
  inertia in the car. `MappedEngine` stays in the library as the cross-check.
- **Fixed gear or clutch:** a clutch and a CVT. The one-gear car could not start from rest and
  sat on the rev limiter; braking to a stop stalled its engine. The car now carries the given
  `CVTDriveline`, whose centrifugal clutch opens near idle, so the brake stop runs to rest and
  the engine idles on. The brake is the given `RoadBrake`, which holds the car at rest.

## Open questions for the lecturer

- Do students add the course library by URL (as here), or clone the course repository?
