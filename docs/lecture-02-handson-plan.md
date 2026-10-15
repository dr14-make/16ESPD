# Lecture 2 hands-on — step plan

One session of about 90 minutes in which students swap Lecture 1's `IdealEngine` for the mapped
engine of `lecture-02-mapped-engine-plan.md` and read fuel and CO₂ off the car. This file is
task 5 of that plan: the step plan behind `slides/decks/handson-02/` and
`slides/site/handson/lecture-02/`. It inherits decisions M1–M7 unchanged and covers scope A
only; scope B is an optional last step.

Companion documents:

- `docs/lecture-02-mapped-engine-plan.md` — the decisions, the reality anchors and tasks 1–6.
- `docs/lecture-02-handson-screenshots.md` — the Studio screenshots the deck and the guide need.
- `data/engine/README.md` — the maps, their axes and the fuel-cut requirement.

## The arc

The theory deck's section 08 promises four things: a pedal into a throttle, a manifold pressure
that is a state, measured maps read at speed and manifold pressure, and five scenarios on the
hands-on car that read off L/h, L/100 km, g CO₂/km and `p_m`. The session keeps that order.
Students first read the 90 km/h cruise point off the maps by hand, so they know the fuel figure
before any model runs; then build the one equation that makes `p_m` a state; then a map engine
of their own on a dynamometer bench; then put the finished library engine in their car and
drive the scenarios. Every checkpoint is a number they could have predicted.

## Built or given

The lecture's goal is that a student can read a map at (N, p_m) and explain why `p_m` lags the
pedal. The throttle's compressible-orifice flow and the λ-matched volumetric efficiency are
physics the lecture states and does not teach, and 90 minutes cannot hold them. So:

| Part | Built or given | Why |
|---|---|---|
| The maps (`data/engine/*.csv`) | given, read in the REPL | Derived from EPA data by a script; reading them is the skill, not making them. |
| `Manifold` — `V_m/(R T_m)·dp_m/dt = ṁ_thr + ṁ_bst − ṁ_cyl` | **built** (paste one equation) | It is the state the whole session is about: the lag, the overrun vacuum, the booster bump. One line, five minutes. |
| `Throttle`, `CylinderAirflow` | given, `Vehicle.Engine` | Choked-flow orifice and an `η_v` that must match the maps exactly. Re-typing coefficients teaches nothing and risks a λ that disagrees with `lambda.csv`. |
| `MapEngine` — pedal curve, `AirPath`, torque and fuel maps, full-load cap, CO₂ = 3.09·fuel | **built** (paste, then read line by line) | The core of the lecture: speed and `p_m` in, torque and fuel out. Built small, it shows every idea in under 40 lines. |
| `MappedEngine` — adds fuel cut, rev limiter, throttle actuator lag, λ and emission outputs | given, `Vehicle.Engine` | Hysteresis latches and five more maps are plumbing. The student meets fuel cut by swapping it onto their own bench and watching the fuel go to zero. |
| `MappedCar` — Lecture 1's `Car` with the engine swapped and a brake added | **built** (diagram edits) | The milestone, as `Car` was in hands-on 1, and it is the student's own car. |
| Scenario benches | **built** (sources and initial lines) | Same pattern as hands-on 1; each is a few blocks. |
| WLTC driver and gearbox (scope B) | given, if it exists | Task 6. Not in the 90 minutes. |

Student reference solutions go in a new subpackage `dyad/HandsOn02/`, as `dyad/HandsOn/` holds
hands-on 1's. They are task 4's to write, or a follow-up to it; nothing in this task touches
`dyad/`.

## Steps

Budgets add up to 90 minutes: 8 + 12 + 15 + 20 + 12 + 12 + 8 + 3.

### Step 00 · Set up · 8 min

**Goal.** A `handson-02` branch on the student's `MyCar`, with the course library added so
`VehicleSystemsComponents.Vehicle.Engine` appears under **+**.

**Built / given.** Given: the course library from github.com/dr14-make/16ESPD (public).

**Actions.** Branch `handson-02` from `main` after hands-on 1's PR; in the Julia REPL
`Pkg.add(url = "https://github.com/dr14-make/16ESPD")`; Dyad Compile; check the **+** tree.

**Reference model.** None.

**Checkpoint.** `using VehicleSystemsComponents` loads; **+** → `VehicleSystemsComponents` →
`Vehicle` → `Engine` lists `AirPath`, `Throttle`, `CylinderAirflow`, `MappedEngine`.

**TODO.** Rehearse the add route. If Dyad Studio needs **Actions → Import Library** for a git
package, or a branch other than `main`, the action changes. Pin the course library to a tag
once tasks 3–4 merge, so students get the engine the checkpoints were read from.

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

- 90 km/h: 3080 rpm, 31.1 N·m → `p_m` ≈ **47.8 kPa**; fuel **0.85 g/s** = **4.10 L/h** →
  **4.6 L/100 km**, **105 g CO₂/km**.
- λ = 1.00 there; **0.87** at 3000 rpm, 100 kPa (full-load enrichment).
- Full-load torque peaks at **150.2 N·m** near 4100 rpm (`full_load.csv`).

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
- Small step at idle, `du = 0.005`: 33.0 → **37.3 kPa**; τ ≈ **0.15 s**.
- 3000 rpm closed (overrun): **13.5 kPa**; wide open: **99.9 kPa**; τ ≈ **0.03 s**.

**TODO.** Confirm the student `Manifold` with given parts reproduces `TestAirPath` exactly (it
should: the equation is `IntakeManifold`'s).

**Screenshots.** `step02-manifold-code.png`, `step02-airpath-bench.png`,
`step02-idle-plot.png`.

### Step 03 · Map engine on a dynamometer · 20 min

**Goal.** An engine of your own that reads torque and fuel at (N, `p_m`), caps torque at the
full-load curve and makes CO₂ = 3.09 × fuel; on a bench that holds 3000 rpm, a pedal tip-in
shows the manifold lag in the torque. Then swap in the library `MappedEngine` and see fuel cut.

**Built / given.** Built: `MapEngine` (paste, extends `Vehicle.Engine.EngineMapData`), bench
`MapEngineDyno`. Given: `Vehicle.Engine.AirPath`, `EngineMapData`, `MappedEngine`.

**Actions.** Paste `MapEngine`, read it line by line; draw `MapEngineDyno`: pedal `Step` 0 → 1 at
1 s, a `VelocitySource` holding 314.16 rad/s, mounts; run 3 s; plot `p_m`, `tau_e`,
`mdot_fuel`. Then replace `engine` with `Vehicle.Engine.MappedEngine` (plus `Constant(0)` into
`mdot_bst`), make the pedal step 1 → 0 and rerun.

**Reference model.** Existing: `Vehicle.Engine.TestMappedEngineDyno` (on
`feat/lecture02-mapped-engine`, task 3). To build: `HandsOn02.MapEngine`,
`HandsOn02.MapEngineDyno`, `HandsOn02.MapEngineDynoTransient`.

**Checkpoint** (3000 rpm; values from the CSVs at the `TestAirPath` pressures):

- Closed pedal: `p_m` **13.5 kPa**, `tau_e` **−18.2 N·m**, fuel **0.097 g/s** — still burning.
- Wide open: `p_m` **99.9 kPa**; map torque 163.1 N·m, capped to **148.4 N·m**; fuel
  **3.75 g/s**, CO₂ **11.6 g/s**, λ 0.87.
- `MappedEngine`, pedal released: fuel **0**, `tau_e` **−18.7 N·m** (`closed_throttle.csv`).

**TODO.** The rise time of `tau_e` after the tip-in (expect tens of ms, the 3000 rpm τ plus the
20 ms throttle actuator in `MappedEngine`) — read off `HandsOn02.MapEngineDynoTransient`. Confirm
the name `EngineMapData` and its parameter names once task 3 merges; `MapEngine` extends it.

**Screenshots.** `step03-map-engine-code.png`, `step03-dyno-bench.png`,
`step03-tip-in-plot.png`, `step03-fuel-cut-plot.png`.

### Step 04 · The car with a mapped engine · 12 min

**Goal.** Your Lecture 1 car with the new engine; full pedal from rest reaches a real top
speed, not 246 km/h.

**Built / given.** Built: `MappedCar` (duplicate `Car`), bench `MappedCarWOT`. Given:
`MappedEngine`.

**Actions.** Duplicate `Car` → `MappedCar`; delete `engine`, place `Vehicle.Engine.MappedEngine`
as `engine`; rename the input `tau_cmd` → `pedal`; `Constant(0)` → `engine.mdot_bst`; new
outputs `p_m` (from `engine.p_m`) and `fuel_lph` (`Gain(k = 3600/0.745)` on
`engine.mdot_fuel`); bench with `Constant(1)` pedal, start at rest, 120 s.

**Reference model.** To build: `Vehicle.Engine.MappedEngineCar` (task 4) and the student version
`HandsOn02.MappedCar`, `HandsOn02.MappedCarWOT`, `HandsOn02.MappedCarWOTTransient`.

**Checkpoint:**

- Top speed about **190 km/h**: drag alone would allow 192 km/h at 6570 rpm (from
  `full_load.csv` and the hands-on car), but the rev limiter cuts fuel at 6500 rpm =
  **189.9 km/h** and resumes at 6300 rpm = 184.1 km/h (`MappedEngine` parameters, task 3).
- **TODO** time to 100 km/h, and whether the speed visibly saws between 184 and 190 km/h — read
  off `HandsOn02.MappedCarWOTTransient`.
- **TODO** the initial lines the bench needs (the engine's crankshaft is tied to the wheel, so
  only `body.mass.s`, `body.mass.v` and `engine.air.manifold.p` should be set) — confirm on the
  reference.

**Screenshots.** `step04-mapped-car.png`, `step04-wot-plot.png`.

### Step 05 · Cruise: fuel and CO₂ · 12 min

**Goal.** Hold 50, 90 and 130 km/h, read `fuel_lph`, turn it into L/100 km and g CO₂/km by hand,
and compare with step 01's prediction.

**Built / given.** Built: bench `MappedCarCruise` (one bench, three pedal values).

**Actions.** `Constant(k = pedal)` into `car.pedal`, start at the cruise speed, run 60 s, read
`car.v_kmh`, `car.fuel_lph`, `car.p_m` at the end; L/100 km = L/h ÷ km/h × 100; g CO₂/km =
2302 × L/h ÷ km/h (1 L of petrol burns to 2.30 kg CO₂).

**Reference model.** To build: task 4's cruise analyses; student `HandsOn02.MappedCarCruise`.

**Checkpoint** (the plan's predicted anchors, reproduced from the CSVs):

| km/h | rpm | N·m | `p_m` kPa | L/h | L/100 km | g CO₂/km |
|---|---|---|---|---|---|---|
| 50 | 1710 | 18.4 | 41.9 | 1.67 | **3.4** | **77** |
| 90 | 3080 | 31.1 | 47.8 | 4.10 | **4.6** | **105** |
| 130 | 4450 | 51.0 | 60.8 | 9.14 | **7.0** | **162** |

**TODO** the pedal values that hold each speed (the progressive pedal and the throttle area
make them a model output) — from task 4's cruise runs, to three decimals. With them, confirm
the speed holds within ±1 km/h over 60 s.

**Screenshots.** `step05-cruise-bench.png`, `step05-cruise-90-plot.png`.

### Step 06 · Coast-down and a brake stop · 8 min

**Goal.** Release the pedal at 90 km/h: fuel goes to zero and the engine brakes the car;
brake to a stop and watch the vacuum the brake booster will draw on.

**Built / given.** Built: a `brake` input on `MappedCar` (`TranslationalComponents.Sources.Force`
between the body and ground) and bench `MappedCarCoast`.

**Actions.** Pedal `Step` from the 90 km/h value to 0 at 5 s; run 90 s; plot `fuel_lph`, `p_m`,
`v_kmh`. Then a brake force `Step` of 4000 N at 5 s; run until the car is below 25 km/h.

**Reference model.** To build: task 4's coast-down and brake-stop analyses; student
`HandsOn02.MappedCarCoast`.

**Checkpoint:**

- At release: fuel **4.10 → 0 L/h**; `tau_e` ≈ **−19 N·m** (`closed_throttle.csv` at 3080 rpm);
  deceleration **0.46 m/s²** against 0.29 in neutral (drag + rolling 401 N plus 246 N of engine
  braking, on 1400 kg).
- `p_m` falls to about **13.5 kPa** (overrun, `TestAirPath`) and rises as speed falls.
- Fuel stays cut down to **1000 rpm = 29.2 km/h**, then resumes; cut only arms above 1300 rpm =
  38.0 km/h (`MappedEngine` parameters, task 3).
- **TODO** `p_m` at fuel resume and during the brake stop, the brake force's sign as wired,
  and the stop time — from the reference runs.

**Screenshots.** `step06-coast-plot.png`, `step06-brake-plot.png`.

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
| Course-library add route and pin | step 00 | rehearsal in Studio |
| `EngineMapData` name and fields | step 03 code | task 3 merge |
| Tip-in rise time of `tau_e` | step 03 | `HandsOn02.MapEngineDynoTransient` |
| Initial lines of the car benches | steps 04–06 | `HandsOn02.MappedCar*` |
| Time to 100 km/h; rev-limiter sawtooth | step 04 | `HandsOn02.MappedCarWOTTransient` |
| Pedal values for 50/90/130 km/h | steps 05–06 | task 4's cruise runs |
| `p_m` at resume and under braking; brake sign; stop time | step 06 | task 4's coast and brake runs |
| WLTC numbers and the label | step 07 | task 6 |
| Every screenshot | all | `docs/lecture-02-handson-screenshots.md` |

## Open questions for the lecturer

- Step 01 has students predict the 90 km/h fuel figure from the maps. Is the full cruise table
  shown before step 05, or do they measure 50 and 130 km/h first?
- Is `MappedEngine` handed over finished (as planned here), or should students also build the
  fuel-cut latch?
- The one-gear car has no clutch: braking to standstill stalls the engine and `p_m` climbs to
  ambient. Stop the brake run at about 25 km/h, or add a clutch?
- Do students add the course library by URL (as here), or clone the course repository?
