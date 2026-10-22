# Lecture 3 hands-on — step plan

One session of about 90 minutes in which students brake a car hard on one lumped wheel, watch the
wheel lock, write an ABS slip controller of their own, then take away its knowledge of the car's
speed and see what that costs on a slippery road. Traction control is a bonus task outside the
session. ESP stays a lecturer demo on the planar car.

This file is the plan behind three artifacts, in the same split as hands-on 2: the guide
`slides/site/handson/lecture-03/` (`index.md`, the one full source, and `tutor.md`; not written
yet), the projector deck `slides/decks/handson-03/` (one slide per step, built, with its figures
from `scripts/export_handson03_figures.jl`, `mise run figures:handson-03`), and the reference
solutions in `dyad/HandsOn03/` (built; checkpoints in `test/abs_handson_plausibility.jl`).

Companion documents:

- `docs/abs-controller-spec.md`, `docs/abs-braking-distance-findings.md`: the library ABS and how
  it got to 38.7 m.
- `docs/lecture-03-esp-dyad-tasks.md`: the planar car and ESP, tasks 0–9, for the demo.
- `docs/lecture-02-handson-plan.md`: the format this plan copies.
- To write once the reference models exist: `docs/lecture-03-handson-screenshots.md`.

## Where the students' car stands after Lecture 2

`MyCar` (github.com/dr14-make/MyCar) is the student's own Dyad library. Its `main` holds hands-on 1
and the Lecture 1 live build: `Engine`, `Driveline`, `Body`, `Car`, `GradeBody`, `GradeForce`,
`GradeCar`, `WheeledDriveline`, `WheeledCar`, the student's own `TireFrictionCurve`, `SlipWheel1D`
and `SlipCar`, and `CruiseController` (P and I on `origin/main`, Lecture 1 commits cc7a5ca and
c6d0079). There is no `handson-02` branch on `origin` yet; the rehearsal checkout
`~/TMP/MyCar-lecture01` carries hands-on 2 steps 02–03 uncommitted.

After hands-on 2 a student also has, on a merged `handson-02` branch:

- the course library as a Pkg dependency: `Pkg.add(url = "https://github.com/dr14-make/16ESPD")`
  puts `VehicleSystemsComponents` in `Project.toml`, and its modules under **+** in Studio. The
  rehearsal `Manifest.toml` pins `repo-rev = "feat/lecture02-theory-deck"`, a branch, not a tag;
- `Manifold`, `MapEngine` (fuel cut pasted in), and `MappedCar`: their `MapEngine`, a flywheel,
  the given `Vehicle.CVTDriveline` and, after step 06 B, the given `Vehicle.RoadBrake` pushing on
  the body. The car's wheel is an `IdealRollingWheel` inside `CVTDriveline`: it cannot slip, and
  the brake acts on the body, not on a wheel.

So the hands-on-2 car cannot lock a wheel, and giving it one means a new driveline with a wheel
shaft out. This session does not do that (decision D8). It needs only hands-on 1's `Body` and
the library, so a student who did not finish hands-on 2 can still do all of it.

## The arc

The theory deck's section 03 makes four claims about its ABS model: a locked wheel stops on the
sliding friction; ABS holds the tire near its peak and stops shorter; the controller must lead the
30 ms brake lag; and without the car's speed the controller must estimate it, which costs most of
the gain on slippery roads. The session tests them in that order, on the student's own parts.
Students first work out the tire's limit torque and the two bounding distances by hand, then build
the locked stop, then write the slip controller (first without lead, then with it), then write a
wheel-speed-only ABS with the dump / hold / build cycle and the estimate it needs, and finally sweep
the road surface from the REPL. Every checkpoint is a number from the deck or one they computed in
step 01.

## Built or given

The lecture's goal is that a student can explain where on the friction curve an ABS keeps the
tire and why the hydraulic lag and the missing speed signal make that hard. The pressure-memory
state machine of the library ABS (`ABSModulatorDiscrete`: four phases, a lock-torque latch, a
hold timeout) is what a production ECU does, and the deck explains it; 90 minutes cannot build
all of it. Step 04 builds its core, three phases and one latch, because without the hold the
students' wheel-only ABS loses to the locked wheel (see step 04).
So:

| Part | Built or given | Why |
|---|---|---|
| `Vehicle.Wheel.BrakedWheel`: inertia, `BrakeActuator` (30 ms lag), `SlipWheel1D` with `TireFrictionCurve`, all four wheels lumped (J 4 kg·m², F_z = full weight) | given | The plant the deck's numbers come from. The student built the same tire in hands-on 1; rebuilding it with a brake teaches nothing new. |
| `Body`, hands-on 1 | the student's own, reused | Same drag, rolling resistance and mass as `Vehicle.VehicleBody` on a flat road, so the deck's distances hold (task H1 confirms to the digit). It keeps "your car" in the session. |
| Locked-stop bench `LockedStop` | **built** (drawn: 6 blocks, 6 wires, 5 initial lines) | The baseline every later number is compared with. |
| `SlipABS`: rate law, slip look-ahead, on/off below 1.5 m/s | **built** (code view, about 8 lines) | The core of the lecture: "release when the slip passes the peak", and then "release when it *will* pass it 30 ms from now". |
| `Vehicle.ABSPressureIntegrator`: integrates a pressure rate, clipped to `[0, demand]`, tracks the demand when inactive | given | Anti-windup plumbing, a nested `ifelse`. It is the modulator's "build / hold / dump" in one block (rate positive, zero, negative), so the deck's valve slide still maps onto it. |
| `RefSpeedEstimator`: `v_ref` follows the wheel when the wheel is faster, otherwise falls at `a_ref`; slip from `v_ref`; the wheel's filtered acceleration `a_w` | **built** (code view, about 9 lines) | The reference-speed slide as a component; `a_ref` is the knob the deck's trap is about. |
| `PhaseABS`: dump on `a_w < −a_minus` or slip past `lambda_1`, hold on `a_w > +a_plus`, build slowly otherwise; a latch passes the demand through until the first dump | **built** (code view, a copy of `SlipABS`, about 7 lines) | The modulator's three valve states and the pressure memory, small enough to write; the version that beats the locked wheel on wheel speed alone. |
| `Vehicle.ABSController` (clocked 5 ms, wheel speed only), `ABSBrakeTransient`, `LockedBrakeTransient`, `IdealBrakeTransient` | given, run from the REPL only | The deck's numbers and the cross-check for the student's models. Its clocked wiring (`PeriodicClock`, three `Sampler`s, `ZeroOrderHold`) is not drawn in Studio. |
| `Vehicle.braking_distance(sol)` | given (new, task H4) | One definition of "distance" (from brake application until v < 0.5 m/s) shared by the guide, the tests and notebook 01. |
| Bonus TCS: `TCSSlipCar` and its controller | **built**, outside the session | Hands-on 1's `SlipCar` with a `Vehicle.Wheel.BrakeActuator` in the wheel line, and the slip law turned around. |
| Planar car, ESP (`Vehicle.Planar.*`, `Lecture3.*`) | lecturer demo only | See § ESP. |

The hands-on keeps the physical-connector rule of `lecture-03-esp-dyad-tasks.md` wherever it
draws new wiring: speeds are measured by sensor components on physical ports
(`TranslationalComponents.Sensors.VelocitySensor` on the body flange,
`RotationalComponents.Sensors.VelocitySensor` on the wheel shaft), the controllers have signal
ports only, and the one actuator command is `BrakedWheel.tau_cmd`. The benches write no equation
that reads a plant variable (`controller.v = body.mass.v`, as the library harness does, is not
used). The exception is `BrakedWheel.kappa`, a true-slip output of an existing component, which the
ESP plan keeps unchanged. Steps 02–03 use it as an ideal slip sensor; step 04 replaces it with a
wheel-speed sensor, which is the point of that step.

Reference solutions go in `dyad/HandsOn03/`, as hands-on 2's are in `dyad/HandsOn02/`.
Checkpoints go in `test/abs_handson_plausibility.jl`, in testsets named "Hands-on 03 …".

## Steps

Budgets add up to 90 minutes: 8 + 7 + 15 + 22 + 25 + 10 + 3.

Numbers marked **(deck)** are already in `slides/decks/lecture-03` and come from the library
analyses; numbers marked **(hand)** follow from the formulas given; **(H2)** and similar mark
numbers the reference task of that name measured. All reference runs use Tsit5 with
`dtmax = 1e-3`; the library analyses run with the same settings agree with the deck's numbers
to 0.1 m.

### Step 00 · Set up · 8 min

**Goal.** A `handson-03` branch on `MyCar`, with the Lecture 3 library, so `Vehicle.Wheel` and
`Vehicle.ABSPressureIntegrator` appear under **+**.

**Built / given.** Given: the course library, pinned to the tag the session was rehearsed on
(task H5).

**Actions.** Branch `handson-03` from `main` (after hands-on 2's PR, or from hands-on 1's `main`
for a student who missed it); `Pkg.add(url = "https://github.com/dr14-make/16ESPD", rev = "<tag>")`
(replaces the branch pin); <kbd>F1</kbd> → `Dyad: Compile`.

**Checkpoint.** `using VehicleSystemsComponents` loads; **+** → `VehicleSystemsComponents` →
`Vehicle` → `Wheel` lists `BrakedWheel`, `BrakeActuator`, `TireFrictionCurve`; `Vehicle` lists
`ABSPressureIntegrator`.

**Deck.** None.

**Screenshots.** `step00-wheel-library.png`.

### Step 01 · The tire's limit, by hand · 7 min

**Goal.** Know the three numbers every later run is judged by, before anything runs: the brake
torque at which the tire is at its peak, and the stopping distances at the peak and sliding.

**Built / given.** Nothing built; the student's own `TireFrictionCurve` from hands-on 1 (same
defaults as the library's: peak 1.0 at 4 % slip, 0.7 from 12 %).

**Actions.** On paper or in the REPL, for 1400 kg on one lumped wheel, r = 0.31 m, 90 km/h:
`F_z = m g`; `T_peak = μ_A F_z r`; `d = v² / (2 μ g)` at μ_A and at μ_S; repeat for road μ 0.3.

**Checkpoint** (hand; the deck's values):

- `F_z` = **13 729 N**; `T_peak` = **4256 N·m**; the driver's 6000 N·m is 1.4× that, so the
  wheel must lock without ABS.
- μ = 1: peak **31.9 m**, sliding **45.5 m** (deck: `abs-distance`).
- μ = 0.3: peak **106.2 m**, sliding **151.7 m**.

**Deck.** `tire-is-not-a-block`, `braking-distance`, `abs-model` (the plant numbers).

**Screenshots.** None.

### Step 02 · Lock the wheel · 15 min

**Goal.** A braking bench with the student's own body on the library wheel; a 6000 N·m step locks
the wheel within a tenth of a second and the car stops on the sliding friction.

**Built / given.** Built: bench `LockedStop`, drawn. Given: `Vehicle.Wheel.BrakedWheel`. Own:
`Body` (hands-on 1).

**Actions.** New component `LockedStop`. Place `wheel` = `Vehicle.Wheel.BrakedWheel` (defaults),
`body` = the student's `Body`, `fixed` = `RotationalComponents.Components.Fixed`, `demand` =
`Step(height = 6000, start_time = 0.5)`, `road` = `Constant(k = 1)`, `speed` =
`TranslationalComponents.Sensors.VelocitySensor`. Wire `demand.y → wheel.tau_cmd`,
`road.y → wheel.mu_scale`, `wheel.support → fixed.spline`, `wheel.flange → body.flange`,
`speed.flange → body.flange`. In code, five initial lines: `wheel.brake.tau_actual = 0`,
`wheel.inertia.phi = 0`, `wheel.inertia.w = 25 / 0.31`, `body.mass.s = 0`, `body.mass.v = 25`.
Analysis `LockedStopTransient`, stop 6 s, Tsit5. Plot `speed.v`, `wheel.kappa`, `body.mass.s`;
in the REPL, `Vehicle.braking_distance(sol)`.

**Reference model.** `HandsOn03.LockedStop`, `HandsOn03.LockedStopTransient` (forwards
`road_mu`, `stop`). Must equal `Vehicle.LockedBrakeTransient` to 1e-6 (task H1).

**Checkpoint.**

- `wheel.kappa` reaches **−1** at **0.67 s**, 0.17 s after the step (H1; the deck's
  `on-the-curve` says about 0.1 s).
- Braking distance **43.7 m** (deck; H1 43.704 m), between the step-01 bounds and just short of
  the sliding bound 45.5 m (the wheel is not locked for the first 0.17 s; drag helps).
- At rest (below 0.5 m/s) at **3.96 s** (deck: `one-stop`).

**Measured (H1).** `HandsOn03.LockedStopTransient` equals `Vehicle.LockedBrakeTransient` (same
Tsit5 settings) to machine precision at μ 1.0, 0.5, 0.3: 43.7, 85.1, 136.8 m.

**Deck.** `braking-distance`, `one-stop`.

**TODO.** Rehearse the drawing against 15 minutes; the five initial lines are the likely stall,
as in hands-on 2 step 04.

**Screenshots.** `step02-locked-bench.png`, `step02-locked-plot.png`.

### Step 03 · An ABS of your own · 22 min

**Goal.** A slip controller that keeps the wheel off the sliding plateau; first on the present
slip, then on the slip predicted 30 ms ahead, which leads the brake's lag. The second version
stops in the deck's 34.4 m.

**Built / given.** Built: `SlipABS` (code view), bench `ABSStop` (copy of `LockedStop` plus two
wires). Given: `Vehicle.ABSPressureIntegrator`.

**Actions.**

A · Write `SlipABS`. Ports: `kappa`, `v`, `demand` (inputs), `tau_cmd` (output). Parameters
`lambda_target = 0.04`, `k_inc = 20000`, `k_dec = 40000`, `v_min = 1.5`. Place `pressure` =
`Vehicle.ABSPressureIntegrator(T_track = 0.01)`. Equations:

    connect(demand, pressure.demand)
    pressure.requested_rate = ifelse(kappa < -lambda_target, -k_dec, k_inc)
    pressure.active = ifelse(v > v_min, 1.0, 0.0)
    connect(pressure.tau_cmd, tau_cmd)

B · Duplicate `LockedStop` → `ABSStop`; place `abs` = `SlipABS` between `demand.y` and
`wheel.tau_cmd`; `wheel.kappa → abs.kappa`, `speed.v → abs.v`. Run 6 s.

C · Add the look-ahead to `SlipABS`: parameters `T_p = 0.03`, `T_f = 0.003`; variables
`kappa_f`, `kappa_dot`, `kappa_pred`; `initial kappa_f = 0`;
`der(kappa_f) = (kappa - kappa_f) / T_f`; `kappa_dot = (kappa - kappa_f) / T_f`;
`kappa_pred = kappa + T_p * kappa_dot`; the rate line reads `kappa_pred`. Run again; then with
`T_p = 0` from the REPL, which is run A again.

**Reference model.** `HandsOn03.SlipABS` (with `T_p`; `T_p = 0` is A), `HandsOn03.ABSStop`,
`HandsOn03.ABSStopTransient` (forwards `road_mu`, `T_p`, `lambda_target`, `stop`). With
`T_p = 0.03` it is `Vehicle.ABSIdealController` equation for equation, so `ABSStopTransient` must
equal `Vehicle.IdealBrakeTransient` to 1e-6 (task H2).

**Checkpoint.**

- A, no look-ahead: the wheel does not stay locked; distance **53.8 m (H2), longer than the
  locked 43.7 m**; 26 % of the time (from 1 s until 3 m/s) past the 12 % sliding point, slip
  dives to −0.2 and deeper; the torque saws between about 600 and 4700 N·m at **2.6 Hz**. That is
  the findings document's result: a slip law that ignores the 30 ms lag dumps too late and
  overshoots into sliding. At μ 0.5 and 0.3: 97.2 and 145.9 m.
- C, look-ahead 30 ms: **34.4 m** (deck, "ABS on the true slip"; H2 34.445 m), 21 % shorter than
  43.7 m; `wheel.brake.tau_actual` holds at 4300–4400 N·m with a small **31 Hz** ripple, just
  *above* the 4256 N·m of step 01 (the brake also decelerates the wheel's inertia), not below
  it; `wheel.kappa` stays near −0.04, never past −0.12; at μ 0.5 and 0.3: 26 and 23 Hz.
- `abs.tau_cmd ≤ demand` throughout; the ABS switches off below 1.5 m/s (at 3.0 s) and the wheel
  locks just before standstill, as a real ABS does.

**Measured (H2).** `ABSStopTransient` equals `Vehicle.IdealBrakeTransient` to machine precision
at μ 1.0, 0.5, 0.3: 34.4, 63.4, 102.2 m.

**Deck.** `modulator` (build and dump are the two signs of the rate), `abs-cycle`, `abs-model`
(look-ahead), `one-stop`, `on-the-curve`.

**TODO.** Rehearse the code-view paste in Studio: whether the diagram keeps the `pressure`
placement and whether a nested `ifelse` survives Studio's formatter.

**Screenshots.** `step03-slipabs-code.png`, `step03-abs-bench.png`, `step03-torque-plot.png`,
`step03-mu-kappa-plot.png`.

### Step 04 · Only the wheel speed · 25 min

**Goal.** An ABS fed from a wheel-speed sensor only, with the three-phase cycle a production ECU
runs: dump, hold, build slowly from the held level. It beats the locked wheel on every road and
the library's clocked ECU on all three.

**Built / given.** Built: `RefSpeedEstimator` and `PhaseABS` (code view), bench
`ABSStopWheelOnly` (copy of `ABSStop`). Given: `Vehicle.ABSPressureIntegrator` again; its
`requested_rate = 0` is the hold, so nothing new is given. This keeps D3 (the phase logic is the
lesson, the clipping is not) and D4 (the estimator is built, the clocked wiring is not).

**Actions.**

A · Write `RefSpeedEstimator`: input `omega`; outputs `kappa_hat`, `v_ref`, `a_w`; parameters
`radius = 0.31`, `a_ref = 8`, `v0 = 25`, `T_up = 0.01`, `v_eps = 0.5`, `T_f = 0.005`;
`v_w = omega * radius`; `initial v_ref = v0`;
`der(v_ref) = ifelse(v_w > v_ref, (v_w - v_ref) / T_up, -a_ref)`;
`kappa_hat = (v_w - v_ref) / max(v_ref, v_eps)`; and the wheel's surface acceleration,
filtered as step 03's slip rate was: `initial v_f = v0`; `der(v_f) = (v_w - v_f) / T_f`;
`a_w = (v_w - v_f) / T_f`.

B · Duplicate `SlipABS` → `PhaseABS`; drop the look-ahead; add the input `a_w`; parameters
`a_minus = 12`, `a_plus = 3`, `lambda_1 = 0.2`, `k_dec = 40000`, `k_inc = 8000`, `v_min = 1.5`,
`T_latch = 0.001`; variables `phase`, `cycled`. Equations:

    phase = ifelse(a_w > a_plus, 0, ifelse(a_w < -a_minus or kappa < -lambda_1, -1, 1))
    initial cycled = 0
    der(cycled) = ifelse(phase < -0.5, (1 - cycled) / T_latch, 0)
    connect(demand, pressure.demand)
    pressure.requested_rate = ifelse(phase < -0.5, -k_dec, ifelse(phase < 0.5, 0, k_inc))
    pressure.active = ifelse(v > v_min and cycled > 0.5, 1.0, 0.0)
    connect(pressure.tau_cmd, tau_cmd)

C · Duplicate `ABSStop` → `ABSStopWheelOnly`; set `abs` to `PhaseABS`; delete the `wheel.kappa`
and `speed.v` wires into `abs`; place `wspeed` = `RotationalComponents.Sensors.VelocitySensor`
on `wheel.spline` and `est` = `RefSpeedEstimator`; wire `wspeed.w → est.omega`,
`est.kappa_hat → abs.kappa`, `est.a_w → abs.a_w`, `est.v_ref → abs.v`. Run 6 s; plot
`abs.phase`, `abs.tau_cmd` and `wheel.brake.tau_actual`; then at `road_mu = 0.5`.

**Why three phases.** The first version of this step fed step 03's `SlipABS` from the
estimator. It stopped in 46.9 m dry, 90.7 m wet and 129.6 m on snow, longer than the locked wheel
on a dry road, and no `a_ref` from 2.4 to 15 m/s² brought it under 43.7 m (best 46.9 m at 8).
Its estimate rode the slipping wheel down and read about zero slip, so the law dumped only once
the wheel dived to −0.2 and deeper, and then rebuilt at a fixed 20 000 N·m/s from almost nothing:
the slip grew unseen during every slow rebuild. `PhaseABS` changes two things. It dumps on the
wheel's own deceleration, which needs no estimate of the car's speed: a rolling wheel cannot
decelerate faster than the car, at most about 9.8 m/s² on a dry road, so past 12 m/s² the tire
has gone over its peak. And it holds: once the wheel spins back up past +3 m/s² the pressure stops
where the dump left it, just under the level that was too much, and the slow build starts there.
The hold is the pressure memory of the theory deck's state-machine slide, and it is what a
hydraulic modulator does with its two valves per wheel: inlet open is build, both shut is hold,
outlet open is dump. The estimated slip only catches a wheel that is already locked (`a_w` = 0
there). `cycled` is a one-line latch: until the first dump the integrator is inactive and passes
the demand through, which is the fast first build; afterwards builds are slow.

A hydraulic version, with valves in place of the rate integrator, is a stretch goal for whoever
finishes early; `docs/brake-system-implementation-plan.md` step 3 plans it for the library.

**Reference model.** `HandsOn03.RefSpeedEstimator`, `HandsOn03.PhaseABS`,
`HandsOn03.ABSStopWheelOnly`, `HandsOn03.ABSStopWheelOnlyTransient` (forwards `road_mu`,
`a_ref`, `stop`).

**Checkpoint** (H3, measured):

- μ = 1: **35.5 m**, shorter than the locked 43.7 m and the library's clocked ECU's 38.7 m
  (deck), 1.1 m from the true-slip 34.4 m. μ 0.5: **69.8 m**; μ 0.3: **119.6 m**.
- μ = 0.5: the cycle runs build → dump → hold → build, 4.7 dumps a second over the stop
  (14 % dump, 14 % hold, 71 % build, from 1 s until 3 m/s); `abs.pressure.p` does not move in a
  hold; the torque at the wheel stays between about 2000 and 2300 N·m early in the stop.
- μ = 1: the dump ends before the wheel turns round, so HOLD never comes: dump and slow build at
  10 dumps a second, the true slip never past −0.043. From about 1.9 s `a_ref = 8`, below the
  car's deceleration, has let `est.v_ref` run 2 m/s above the car, the estimated slip passes
  `lambda_1` while the tire sits at its peak, and the controller dumps on that phantom slip. It
  costs about 2 m: `a_ref = 10` gives 33.6 m.
- On wet and snow `a_ref = 8` is above the car's deceleration, and `est.v_ref` rides the wheel,
  below the car (up to 0.95 m/s at μ 0.5).
- `abs.tau_cmd ≤ demand` throughout. With a 2000 N·m demand, below the tire's limit, the
  controller never dumps.

Tuning: only the parameters students are given were varied, against Tsit5 at `dtmax = 1e-3`.
`a_minus` sets the low-μ result (16 / 14 / 12 / 10 m/s²: 132.3 / 127.4 / 121.3 / 116.1 m at
μ 0.3, dry within 0.5 m); 12 is the lowest with a margin over the dry-road 9.8 m/s². `k_dec`
40 000 (step 03's) beats 80 000 and 120 000; `k_inc` from 5000 to 16 000 and `a_plus` from 1 to 6
move the distances by under 2 m. The wheel-acceleration filter is the sensitive one: at
`T_f = 10 ms` the snow stop grows to 137.8 m, longer than locked, the filter lag playing the part
the brake lag played in step 03 A.

**Deck.** `wheel-speed-sensors` ("the ABS measures only this"), `reference-speed`, `modulator`
and the state-machine slide, `abs-distance`.

**Screenshots.** `step04-estimator-code.png`, `step04-phaseabs-code.png`,
`step04-wheel-only-bench.png`, `step04-phase-plot.png`.

### Step 05 · Across road surfaces · 10 min

**Goal.** One table from the REPL: locked, ABS on true slip and ABS on wheel speed only, at road
μ 1.0, 0.5 and 0.3. Then the `a_ref` trap: on μ 0.3 an `a_ref` of 8 m/s² is almost three times
what the road allows, which the library ECU falls into; and what `a_ref` does to the students'
own ABS.

**Built / given.** Built: a 10-line REPL loop over the three analyses (the guide gives its
skeleton). Given: `Vehicle.braking_distance`; `ABSBrakeTransient` for the library column.

**Actions.** For μ in (1.0, 0.5, 0.3), run `LockedStopTransient`, `ABSStopTransient`,
`ABSStopWheelOnlyTransient` with `road_mu = μ` and `stop = 0.5 + 1.5·25/(0.7·μ·g) + 1` (the
notebook's rule, about 20 s at 0.3); fill the table. Rerun wheel-only with
`a_ref = 0.8·μ·g ≈ 2.4` at μ 0.3, and with the same `a_ref` at μ 1.

**Reference model.** The three analyses of steps 02–04; the library's `ABSBrakeTransient`,
`IdealBrakeTransient`, `LockedBrakeTransient` for the cross-check.

**Checkpoint.**

| road μ | locked | ABS, true slip | ABS, wheel only (yours) | ABS, wheel only (library, 5 ms) |
|---:|---:|---:|---:|---:|
| 1.0 | **43.7 m** | **34.4 m** | 35.5 m | 38.7 m |
| 0.5 | **85.1 m** | **63.4 m** | 69.8 m | 83.2 m |
| 0.3 | **136.8 m** | **102.2 m** | 119.6 m | **141.3 m**, longer than locked |

The first two columns are the deck's (`abs-surfaces`) and are what the student's models must
give; the third is measured (H3). The wheel-only ABS keeps most of the gain on a dry road (8.2 of
9.3 m) and about half of it on snow (17.2 of 34.6 m). The trap at `a_ref = 8` on snow shows on the
library ECU only, which acts on its slip estimate; with `a_ref = 2.4` it stops in **128.4 m**.
The students' `PhaseABS` dumps on the wheel's deceleration and does not fall into it. Their
`a_ref = 2.4` rerun shows the other side of the same knob instead: an `a_ref` below the car's
real deceleration (about 0.9 μ g with ABS) lets the estimate run above the car, and the slip
trigger dumps on slip that is not there: **124.1 m** at μ 0.3, longer than the 119.6 m at
`a_ref = 8` though still under locked, and **105.4 m** at μ 1. All library numbers are reproduced
with Tsit5 at `dtmax = 1e-3`.

**Deck.** `abs-surfaces`, `reference-speed` (the trap).

**Screenshots.** `step05-surface-table.png` (REPL output).

### Hand in · 3 min

Pull request `handson-03` → `main` with the step 05 table and one sentence on why the library's
wheel-only ABS loses its gain on snow and the student's does not.

### Step 06 · Traction control, bonus task (extra points) · outside the session

**Goal.** Hands-on 1's `SlipCar` on a snowy road, full torque from rest: without TCS the wheel
spins up as in Lecture 1; with a brake-based TCS the wheel holds near the peak and the car
gains more speed in 10 s.

**Built / given.** Given: `Vehicle.Wheel.BrakeActuator`, `Vehicle.ABSPressureIntegrator`. Built:
`TCSSlipCar` (duplicate `SlipCar`, brake between `wheel_inertia` and `wheel`, its `support` on
`rot_ground`, a `tau_tcs` input); `TCS`, the step 03 law turned round: the pressure builds while
`kappa_pred > lambda_target` and falls otherwise, clipped to `[0, tau_tcs_max]`; the bench, a
torque step on `tau_cmd` and `mu_scale = 0.2`.

**Reference model.** `HandsOn03.TCSSlipCar`, `HandsOn03.TCSStart`, kept off `main` as the WLTC
bonus was: on branch `feat/handson03-tcs-bonus` only. Students get the task, the parts and the
advice, not the diagram.

**Checkpoint / grading** (hand estimate; H6 would measure it, not built yet): the traction limit is
0.2 × 6865 N = 1373 N at the peak against 961 N spinning, so roughly 0.85 against 0.57 m/s² net
of resistance, about 8.5 against 5.7 m/s after 10 s. One paragraph on why a production TCS
cuts engine torque when both driven wheels spin (and what the 0.3 s engine delay of `SlipCar`
would do to the loop), and brakes a single wheel only through an open differential, which a
one-wheel model cannot show.

**Deck.** `what-tcs-does`, `tcs-actuators`, `tcs-and-lecture-1`.

## ESP: demo, not hands-on

ESP stays a lecturer demo and a notebook. Reasons:

- **It is not built.** Of `lecture-03-esp-dyad-tasks.md`, tasks 0–1 are committed and task 2 is
  built but uncommitted on `feat/lecture-03-planar-car`; the ESP itself is task 5, the notebook
  task 9.
- **The plant is too large to draw in 90 minutes.** A harness is `PlanarCar`, `PlanarCarSensors`
  (eleven connects), a steering `Position` source on a `Fixed`, a profile, the ESP and a dozen
  initial conditions, before a single run.
- **Cost on student machines.** Task 0 makes `MultibodyComponents` a dependency of the library;
  the Dyad probe took 53 s for a first compile. That cost lands at step 00 even for students who
  never touch the planar car (decision D7).

**Where the demo goes.** In the theory deck, section 05, after `yaw-correction` and before
`esp-evidence`: one or two slides from notebook `03-esp` (task 9), sine-with-dwell at 180° with
`esp_on = 0` (the car spins) and `esp_on = 1` (YRR 0.00, the outer front wheel braked). The
`esp-model` slide's "the repository cannot simulate them yet" is rewritten when task 5 lands.
Needs tasks 0–5 for the demo and 9 for the notebook; tasks 6–7 make it quantitatively honest.

**If the lecturer wants students to touch it** (decision D5, not the default): a REPL-only final
step after step 05, no building:
`Lecture3.ESPSineWithDwellTransient(A_sw = deg2rad(180), esp_on = 0)` and `= 1`, plotted
trajectories and `Vehicle.Planar.fmvss126_metrics`. It needs nothing beyond tasks 0–5, and adds
the dependency cost above.

## Library work before the hands-on

None of this is in `lecture-03-esp-dyad-tasks.md`; it is new work for the Dyad agent, in the
format of that brief (each task ends in a check). It touches nothing under `dyad/Vehicle/Wheel/`,
`ABSController.dyad`, `ABSBrakeTest.dyad` or `VehicleBody.dyad`, so the ESP plan's ground rule
"existing components stay unchanged" holds.

| Task | What | Check |
|---|---|---|
| H1 | `HandsOn03.LockedStop` + transient, on `HandsOn.Body` | **done**: equals `LockedBrakeTransient` to machine precision at μ 1.0, 0.5, 0.3; 43.7 m |
| H2 | `HandsOn03.SlipABS`, `ABSStop` + transient | **done**: `T_p = 0.03` equals `IdealBrakeTransient` to machine precision; A 53.8 m, 26 % sliding, 2.6 Hz |
| H3 | `HandsOn03.RefSpeedEstimator`, `PhaseABS`, `ABSStopWheelOnly` + transient | **done**: 35.5 / 69.8 / 119.6 m, all under locked; `a_ref = 2.4`: 124.1 m at μ 0.3, 105.4 m at μ 1. (The first version, `SlipABS` on the estimate, gave 46.9 / 90.7 / 129.6 m.) |
| H4 | `Vehicle.braking_distance(result; t_brake = 0.5, v_stop = 0.5)` (also `(t, s, v; …)`) in `dyad/Vehicle/module.jl`, the notebook's `braking` rule as one function; notebook 01 switched to it | **done**: unit test on a synthetic constant-deceleration trace; notebook 01 prints the same numbers |
| H5 | merge PR #90 to `main`, tag it, and pin the tag in step 00 | open (the lecturer's call); a fresh `MyCar` clone with `Pkg.add(…, rev = tag)` runs steps 02–05 |
| H6 | bonus TCS reference on `feat/handson03-tcs-bonus` | open; the task is on the deck, the reference and its figures are not built |

Every reference analysis sets `alg = Tsit5` explicitly, with `dtmax = 1e-3`, and forwards every knob
the guide varies by a short name (`road_mu`, `T_p`, `lambda_target`, `a_ref`, and the base `stop`),
so the guide never uses nested `a__b__c` overrides. The Dyad test cases cannot set `dtmax`, so their
expected final positions come from Tsit5 runs without it (47.98 m for the wheel-only bench, with a
0.05 m tolerance because its phases switch on thresholds). A docstring-only fix is still worth
taking along but was not made, since existing components stay unchanged in this work:
`ABSPressureIntegrator`'s docstring ("retained for the continuous ideal benchmark") is what students
read under **+**, and should state its contract instead.

Already planned elsewhere and needed only for the ESP demo: `lecture-03-esp-dyad-tasks.md` tasks
0–5 and 9 (6–7 for split-µ and load transfer).

## Deck: theory and practice

Lecture 3 follows Lecture 2's format: the theory session on `slides/decks/lecture-03`, then a
separate 90-minute hands-on with its own deck `slides/decks/handson-03/`, one slide per step,
each carrying the goal, the checkpoint and a guide link, and its tutor notes in the speaker notes
(decision D1). A `handson-03` deck is needed; the theory deck is not split.

The deck is built: title, steps 00–05, hand-in, the step 06 bonus and a wrap-up table, each step
slide with the goal, what is given and built, the code typed, a checkpoint figure from the reference
runs and the measured numbers, and the tutor notes (where students stall, why step 04 needs the
hold) in the speaker notes. Step 04 has two slides: the state diagram with the code, then the dump /
hold / build figure with its checkpoint. It is on the landing page. The four theory-deck changes
below are not made here: that deck is edited separately.

Each hands-on step puts into practice the theory slides listed under it above. The theory deck
needs four small changes:

- `00-front-matter.md`, "The models behind this lecture": add the hands-on's three student models
  (`LockedStop`, `SlipABS`, `RefSpeedEstimator`, `PhaseABS`) beside notebook 01.
- `abs-model`: one line in the slide or notes, "you write this controller in the hands-on,
  step 03", as lecture 2's section 08 is the bridge to its hands-on.
- `abs-surfaces`: the closing exercise ("make `a_ref` adapt") points at the hands-on step 05
  and its `a_ref` rerun.
- `esp-model`: rewritten when the planar demo exists (§ ESP).

## Risks

| Risk | Where | Mitigation |
|---|---|---|
| Studio's code view reformats or drops the `pressure` placement, or a nested `ifelse` | 03, 04 | rehearse; a "Stuck?" block with the full `SlipABS`, `RefSpeedEstimator` and `PhaseABS` source on the guide |
| Initial conditions on the bench (five lines) mistyped or forgotten; the wheel starts at 0 rad/s and the run is a wheel spinning up, not a stop | 02 | the guide gives the lines to paste; the checkpoint plot shows wheel and car speed together |
| Compile time: `MyCar` recompiles hands-on 1, 2 and 3 on every `Dyad: Compile` | all | rehearse on a student-spec laptop; compile once per step, not per edit |
| Solver: the bang-bang rate law switches every few milliseconds behind a 30 ms lag | 03–05 | Tsit5 with a `dtmax`, set in every reference analysis and on the guide; never FBDF, which steps over switching inputs and reports a wrong `Success` |
| Too short a `stop` on low μ: the car is still moving and the distance is undefined | 05 | the notebook's stop-time rule in the loop skeleton; `braking_distance` errors with the speed it ended at |
| Run A loses to the locked wheel | 03 | not a failure: the guide states it and step C fixes it |
| Step 04 overruns: two components to write | 04 | the guide's "Stuck?" block hands out `PhaseABS`; the students then write only the estimator's three `a_w` lines |
| A student filters `a_w` more heavily to smooth the plot | 04 | the checkpoint states `T_f = 5 ms`; at 10 ms the snow stop is longer than locked |
| The branch pin in students' `Manifest.toml` (`feat/lecture02-theory-deck`) gives a library without the Lecture 3 parts | 00 | H5: a tag, `rev =` in step 00 |
| `MultibodyComponents` arrives with the tag | 00 | D7 |

## TODO slots and what fills each

| Slot | Where | Filled by |
|---|---|---|
| Course-library tag | step 00 (`TODO-TAG` on the deck) | H5 |
| ~~Run A distance, sliding share, cycle frequency; run C cycle frequency~~ | step 03 | H2, filled |
| ~~Wheel-only column and the `a_ref = 2.4` run~~ | steps 04, 05 | H3, filled |
| TCS figures | step 06 | H6 |
| Screenshots (`step00-wheel-library.png` and the benches) | deck, guide | rehearsal in Studio |
| The guide and tutor guide; the deck's guide links point there | `slides/site/handson/lecture-03/` | not written |
| Rehearsal of the drawing (02) and the three code-view pastes (03, 04 twice) | steps 02–04 | rehearsal in Studio, with the screenshots |

## Open decisions

Each has a recommended default; the plan above runs on the defaults.

| # | Decision | Options | Recommended default |
|---|---|---|---|
| D1 | Session format | a separate 90-minute hands-on after the theory, Lecture 2 style / a live build inside the lecture, Lecture 1 style | **separate session**, with the `handson-03` deck and guide; the theory deck's ABS results slides then serve as the checkpoints |
| D2 | Body | the student's hands-on 1 `Body` / `Vehicle.VehicleBody` | **the student's `Body`**: identical physics on a flat road (H1 proves it), and the car stays theirs |
| D3 | How the controller is built | code view, about 8 lines, integrator given / drawn from `BlockComponents` / given `ABSIdealController`, only wired | **code view with the integrator given**: the rate law and the look-ahead are the lesson; the clipping is not. Step 04's `PhaseABS` follows the same rule |
| D4 | Wheel-speed-only step | build a continuous `RefSpeedEstimator` / wire the library's clocked `ABSController` in Studio | **build the estimator**; the clocked wiring (a three-way connect with the clock, three samplers) is GUI risk with no lesson in it. The library column in step 05 covers sampling |
| D5 | ESP in the session | demo only / a REPL-only run at the end / build | **demo only**, in the theory session from notebook `03-esp` |
| D6 | TCS | bonus outside the session / an in-session step | **bonus**, brake in the wheel line of hands-on 1's `SlipCar`; no session time is left |
| D7 | Library tag and `MultibodyComponents` | tag before the planar car merges / tag after it, with setup done before the session | **tag what was rehearsed**; if the planar car is in it, ask students to run step 00 before the session and measure the install time in rehearsal |
| D8 | ABS on the student's `MappedCar` | no / a new `CVTDriveline` variant with a wheel shaft out, `BrakedWheel` on it | **no**: the engine and clutch add compile time and nothing to the ABS lesson; it would also leave out students who did not finish hands-on 2 |
| D9 | Reference solutions on `main` | `dyad/HandsOn03/` on `main` like `HandsOn02` / off `main` | **on `main`**, except the TCS bonus |
