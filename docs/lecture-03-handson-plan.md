# Lecture 3 live build — step plan

The build inside Lecture 3's 3-hour block, in the Lecture 1 format (decision D1): students wire a
brake system from pedal to wheel, brake a car hard on one lumped wheel with it, watch the wheel
lock, write an ABS slip controller of their own,
then take away its knowledge of the car's speed and see what that costs on a slippery road, each
step along with the lecturer in the section whose theory it puts into practice. Traction control
is a take-home bonus. ESP stays a lecturer demo on the planar car.

This file is the plan behind three artifacts, in the same split as Lecture 1: the build slides in
the lecture deck `slides/decks/lecture-03/` (one per step, the lecturer's instructions in the
speaker notes, figures from `scripts/export_lecture03_build_figures.jl`, `mise run
figures:lecture-03-build`), the build guide `slides/site/lecture/lecture-03/` (one anchored
section per step, with the code to paste), and the reference solutions in `dyad/HandsOn03/`
(built; checkpoints in `test/abs_handson_plausibility.jl`). The models keep the `HandsOn03` name.

Companion documents:

- `docs/abs-controller-spec.md`, `docs/abs-braking-distance-findings.md`: the library ABS and how
  it got to 38.7 m.
- `docs/lecture-03-esp-dyad-tasks.md`: the planar car and ESP, tasks 0–9, for the demo.
- `docs/lecture-01-live-build-plan.md`: the format the lecture copies.
- `docs/lecture-03-run-sheet.md`: the time budget of the whole block, theory and build.
- `docs/lecture-03-screenshots.md`: the Studio screenshots the build still needs.

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
shaft out. This build does not do that (decision D8). It needs only hands-on 1's `Body` and
the library, so a student who did not finish hands-on 2 can still do all of it.

## The arc

The theory deck's section 03 makes four claims about its ABS model: a locked wheel stops on the
sliding friction; ABS holds the tire near its peak and stops shorter; the controller must lead the
30 ms brake lag; and without the car's speed the controller must estimate it, which costs most of
the gain on slippery roads. The build tests them in that order, on the student's own parts.
Students first work out the tire's limit torque and the two bounding distances by hand, then wire
the brake system from pedal to wheel and lock the wheel with it, then write the slip controller (first without lead, then with it), then write a
wheel-speed-only ABS with the dump / hold / build cycle and the estimate it needs, and finally sweep
the road surface from the REPL. Every checkpoint is a number from the deck or one they computed in
step 01.

## Built or given

The lecture's goal is that a student can explain where on the friction curve an ABS keeps the
tire and why the hydraulic lag and the missing speed signal make that hard. The pressure-memory
state machine of the library ABS (`ABSModulatorDiscrete`: four phases, a lock-torque latch, a
hold timeout) is what a production ECU does, and the deck explains it; a lecture cannot build
all of it. Step 04 builds its core, three phases and one latch, because without the hold the
students' wheel-only ABS loses to the locked wheel (see step 04).
So:

| Part | Built or given | Why |
|---|---|---|
| `Vehicle.Wheel.BrakedWheel`: inertia, `BrakeActuator` (30 ms lag), `SlipWheel1D` with `TireFrictionCurve`, all four wheels lumped (J 4 kg·m², F_z = full weight) | given, library only | The plant the deck's library numbers come from; no step uses it. The steps brake through `HydraulicBrakedWheel`, which has the same inertia and tire. |
| `Body`, hands-on 1 | the student's own, reused | Same drag, rolling resistance and mass as `Vehicle.VehicleBody` on a flat road, so the deck's distances hold (task H1 confirms to the digit). It keeps "your car" in the session. |
| `Vehicle.Brake.BrakePedal` (0–1 command), `StaticBooster`, `TandemMasterCylinder`, `BrakeLine`; `Vehicle.Wheel.HydraulicBrakedWheel` (inertia, front and rear `BrakeCaliper`, `SlipWheel1D`) | given | Deck section 02's force chain, as parts; the wiring is the lesson. |
| Hydraulic stop bench `PedalStop` | **built** (drawn: 12 blocks, 11 wires; pasted: the fluid declaration and 4 initial lines) | Section 02 ends in a working stop; at pedal 0.6 it is the no-ABS baseline every later number is compared with. |
| `Vehicle.Brake.ABSValve`: ideal per-circuit modulator; the caliper follows `p_cmd` after a 30 ms lag, never above the master cylinder; open with no lag while `p_cmd` ≥ the master-cylinder pressure; no accumulator or return pump | given | Puts the students' ABS on their own step 02 brake without a valve-level model. The deck's modulator and build 03 slides say it is ideal: no pedal pulse. |
| `SlipABS`: rate law, slip look-ahead, on/off below 1.5 m/s, a latch that sends the driver's pressure until the first dump | **built** (code view, about 10 lines) | The core of the lecture: "release when the slip passes the peak", and then "release when it *will* pass it 30 ms from now". |
| `Vehicle.ABSPressureIntegrator`: integrates a rate into `cmd`, clipped to `[0, demand]`, tracks the demand when inactive; unit-neutral (Pa in the steps, N·m in the library) | given | Anti-windup plumbing, a nested `ifelse`. It is the modulator's "build / hold / dump" in one block (rate positive, zero, negative), so the deck's valve slide still maps onto it. |
| `RefSpeedEstimator`: `v_ref` follows the wheel when the wheel is faster, otherwise falls at `a_ref`; slip from `v_ref`; the wheel's filtered acceleration `a_w` | **built** (code view, about 9 lines) | The reference-speed slide as a component; `a_ref` is the knob the deck's trap is about. |
| `PhaseABS`: dump on `a_w < −a_minus` or slip past `lambda_1`, hold on `a_w > +a_plus`, build slowly otherwise; a latch passes the demand through until the first dump | **built** (code view, a copy of `SlipABS`, about 7 lines) | The modulator's three valve states and the pressure memory, small enough to write; the version that beats the locked wheel on wheel speed alone and matches the library ECU on a dry road. |
| `Vehicle.ABSController` (clocked 5 ms, wheel speed only), `ABSBrakeTransient`, `LockedBrakeTransient`, `IdealBrakeTransient` | given, run from the REPL only | The deck's numbers and the cross-check for the student's models. Its clocked wiring (`PeriodicClock`, three `Sampler`s, `ZeroOrderHold`) is not drawn in Studio. |
| `Vehicle.braking_distance(sol)` | given (new, task H4) | One definition of "distance" (from brake application until v < 0.5 m/s) shared by the guide, the tests and notebook 01. |
| Bonus TCS: `TCSSlipCar` and its controller | **built**, at home | Hands-on 1's `SlipCar` with a `Vehicle.Wheel.BrakeActuator` in the wheel line, and the slip law turned around. |
| Planar car, ESP (`Vehicle.Planar.*`, `Lecture3.*`) | lecturer demo only | See § ESP. |

The hands-on keeps the physical-connector rule of `lecture-03-esp-dyad-tasks.md` wherever it
draws new wiring: speeds are measured by sensor components on physical ports
(`TranslationalComponents.Sensors.VelocitySensor` on the body flange,
`RotationalComponents.Sensors.VelocitySensor` on the wheel shaft), the controllers have signal
ports only, and the actuator commands are signals: `BrakePedal.u` in step 02, `ABSValve.p_cmd`
in steps 03–05, with `master.p_mc` as the driver's demand. The benches write no equation
that reads a plant variable (`controller.v = body.mass.v`, as the library harness does, is not
used). The exception is `HydraulicBrakedWheel.kappa`, a true-slip output of an existing
component. Steps 02–03 use it as an ideal slip sensor; step 04 replaces it with a
wheel-speed sensor, which is the point of that step.

Reference solutions go in `dyad/HandsOn03/`, as hands-on 2's are in `dyad/HandsOn02/`.
Checkpoints go in `test/abs_handson_plausibility.jl`, in testsets named "Hands-on 03 …".

## Steps

Budgets add up to 87 minutes of building inside the 180-minute block: 6 + 5 + 16 + 22 + 28 + 10.
Each step lists, under **Deck**, the build slide that introduces it and the theory slides it puts
into practice; `docs/lecture-03-run-sheet.md` places them on the clock.

Numbers marked **(deck)** are already in `slides/decks/lecture-03` and come from the library
analyses; numbers marked **(hand)** follow from the formulas given; **(H2)** and similar mark
numbers the reference task of that name measured. All reference runs use Tsit5 with
`dtmax = 1e-3`; the library analyses run with the same settings agree with the deck's numbers
to 0.1 m.

### Step 00 · Set up · 6 min

**Goal.** A `lecture-03` branch on `MyCar`, with the Lecture 3 library and `HydraulicComponents`,
so `Vehicle.Brake`, `Vehicle.Wheel` and `Vehicle.ABSPressureIntegrator` appear under **+**.

**Built / given.** Given: the course library, pinned to the tag the lecture was rehearsed on
(task H5), and `HydraulicComponents`, which the step 02 bench needs for its fluid declaration.

**Actions.** Branch `lecture-03` from `main` (after hands-on 2's PR, or from hands-on 1's `main`
for a student who missed it); `Pkg.add(url = "https://github.com/dr14-make/16ESPD", rev = "<tag>")`
(replaces the branch pin); `Pkg.add("HydraulicComponents")`; <kbd>F1</kbd> → `Dyad: Compile`.

**Checkpoint.** `using VehicleSystemsComponents` and `using HydraulicComponents` load; **+** →
`VehicleSystemsComponents` → `Vehicle` → `Wheel` lists `BrakedWheel`, `HydraulicBrakedWheel`,
`BrakeActuator`, `TireFrictionCurve`; `Vehicle` → `Brake` lists the brake parts; `Vehicle` lists
`ABSPressureIntegrator`.

**Deck.** Build slide `build-setup`, the last slide of the front matter.

**Screenshots.** `step00-wheel-library.png`.

### Step 01 · The tire's limit, by hand · 5 min

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

### Step 02 · Pedal to wheel · 16 min

**Goal.** The brake system of deck section 02 on the student's own body: pedal command, booster,
tandem master cylinder, two lines and a wheel with axle calipers, wired by the student. A firm
pedal stops the car without locking; a hard one locks the wheel and gives the no-ABS baseline of
steps 03–05.

**Built / given.** Built: bench `PedalStop`, drawn, plus two pasted lines for the brake fluid.
Given: `Vehicle.Brake.BrakePedal`, `StaticBooster`, `TandemMasterCylinder`, `BrakeLine`,
`Vehicle.Wheel.HydraulicBrakedWheel` (inertia, front and rear `BrakeCaliper`, tire). Own: `Body`
(hands-on 1).

**Actions.** New component `PedalStop`, parameters `pedal = 0.6`, `road_mu = 1.0`. Place
`command` = `Step(height = pedal, start_time = 0.5)`, `pedal_unit` = `BrakePedal`, `booster` =
`StaticBooster`, `master` = `TandemMasterCylinder`, `line_f` = `BrakeLine`, `line_r` =
`BrakeLine(L = 4.0)`, `wheel` = `HydraulicBrakedWheel`, `body` = the student's `Body`,
`fixed_hydraulic` = `TranslationalComponents.Components.Fixed`, `fixed` =
`RotationalComponents.Components.Fixed`, `speed` = `TranslationalComponents.Sensors.VelocitySensor`,
`road` = `Constant(k = road_mu)`: twelve blocks. Wire `command.y → pedal_unit.u`,
`pedal_unit.rod → booster.input`, `booster.rod_out → master.pushrod`, the three `support`s →
`fixed_hydraulic.flange`, `master.front → line_f → wheel.front`, `master.rear → line_r →
wheel.rear`, `road.y → wheel.mu_scale`, `wheel.support → fixed.spline`, `wheel.flange`,
`body.flange`, `speed.flange` together. In code, the brake fluid (Dyad 3.4 rejects a medium
declared inside a library part that connects to outside ports, so the bench declares it):

    path medium::HydraulicComponents.Interfaces.AbstractMedium = HydraulicComponents.IsothermalCompressible(bulk_modulus = 1.4e9, density = 1045.0, let_gas = false)
    continuity(medium, master.front.medium)

and four initial lines: `wheel.inertia.phi = 0`, `wheel.inertia.w = 25 / 0.31`,
`body.mass.s = 0`, `body.mass.v = 25`. Analysis `PedalStopTransient`, stop 6 s, Tsit5,
`dtmax = 1e-3`, forwarding `pedal` and `road_mu`. Run `pedal = 0.3`, then the default 0.6. Plot
`master.p_mc`, `speed.v`, `wheel.kappa`; in the REPL, `Vehicle.braking_distance(sol)`.

**Reference model.** `HandsOn03.PedalStop`, `HandsOn03.PedalStopTransient` (forwards `pedal`,
`road_mu`, `stop`). The library twin, on a plain 1400 kg mass, is
`Vehicle.Brake.TestHydraulicStop` / `HydraulicStopTransient` (`test/brake_plausibility.jl`).

**Checkpoint** (dry road).

- Pedal 0.3 (150 N): peak `p_mc` **55.15 bar**, caliper torque **3765 N·m**, under the 4256 N·m
  tire limit; about 0.87–0.88 g; the wheel never locks (min κ −0.027); **35.97 m** after
  application. 3.51 cm³ of fluid displaced; front caliper pressure 10–90 % rise **4.4 ms**.
- Pedal 0.6 (300 N, past booster run-out at 232 N): **89.16 bar**, **6109 N·m**, κ reaches
  −0.999 within 0.2 s of the step; at rest between 3.9 and 4.0 s; **43.73 m**. 4.11 cm³
  displaced.
- At μ 0.5 and 0.3 the 0.6 stop gives 85.1 and 136.7 m, the torque-level locked stop
  (`LockedBrakeTransient`) within 0.1 m (`test/abs_handson_plausibility.jl`).

**Deck.** `force-chain`, `pedal-to-pressure`, `master-cylinder`; checkpoints `one-stop`,
`on-the-curve`, `abs-distance`.

**TODO.** Rehearse the drawing against 16 minutes: twelve blocks, eleven wires, and the two code
pastes (fluid, initial lines) are the likely stall.

**Screenshots.** `step02-pedal-bench.png`.

### Step 03 · An ABS of your own · 22 min

**Goal.** A slip controller that keeps the wheel off the sliding plateau, acting on the student's
own step 02 brake; first on the present slip, then on the slip predicted 30 ms ahead, which leads
the valve's lag. The second version stops in 34.2 m, beside the deck's 34.4 m.

**Built / given.** Built: `SlipABS` (code view), bench `ABSStop` (a copy of `PedalStop`: 3 blocks
placed, 9 wires added, 2 deleted, no new initial lines). Given: `Vehicle.ABSPressureIntegrator`,
`Vehicle.Brake.ABSValve`.

The ABS acts in the hydraulic path: one `ABSValve` per circuit between `master.front`/`rear` and
the lines. `SlipABS` outputs `p_cmd`, the wheel pressure it allows in Pa; `master.p_mc` is its
`demand`. The valve is ideal (no accumulator, no return pump, no pedal pulse); the deck says so on
the modulator and build 03 slides. A valve-level modulator is the library's
`docs/brake-system-implementation-plan.md` step 3.

**Actions.**

A · Write `SlipABS`. Ports: `kappa`, `v`, `demand` (inputs), `p_cmd` (output). Parameters
`lambda_target = 0.04`, `k_inc = 2.9e7`, `k_dec = 5.8e7` (Pa/s; the library's 20 000 and
40 000 N·m/s over the calipers' 68.9 N·m/bar), `v_min = 1.5`. Place `pressure` =
`Vehicle.ABSPressureIntegrator(T_track = 0.01)`. A variable `cycled`. Equations:

    initial cycled = 0
    der(cycled) = ifelse(v > v_min and kappa < -lambda_target, 1000 * (1 - cycled), 0)
    connect(demand, pressure.demand)
    pressure.requested_rate = ifelse(kappa < -lambda_target, -k_dec, k_inc)
    pressure.active = ifelse(v > v_min and cycled > 0.5, 1.0, 0.0)
    p_cmd = ifelse(cycled > 0.5, pressure.cmd, demand)

The latch matters: `ABSValve` leaves the inlet open with no lag only while `p_cmd` is at or above
the master-cylinder pressure, so a command that tracks the demand from below would put the 30 ms
lag on every stop. With it, a stop that never locks is step 02's stop.

B · Duplicate `PedalStop` → `ABSStop`; add parameters `T_p = 0.03`, `lambda_target = 0.04`.
Delete `master.front → line_f.port_a` and `master.rear → line_r.port_a`. Place `valve_f`,
`valve_r` = `Vehicle.Brake.ABSValve`, `abs` = `SlipABS(lambda_target = lambda_target)`. Wire
`master.front → valve_f.port_a`, `valve_f.port_b → line_f.port_a`, the same for the rear,
`master.p_mc → abs.demand`, `abs.p_cmd → valve_f.p_cmd, valve_r.p_cmd`, `wheel.kappa → abs.kappa`,
`speed.v → abs.v`. Analysis `ABSStopTransient`, forwarding `road_mu`, `T_p`, `lambda_target`,
`pedal`. Run 6 s.

C · Add the look-ahead to `SlipABS`: parameters `T_p = 0.03`, `T_f = 0.003`; variables
`kappa_f`, `kappa_dot`, `kappa_pred`; `initial kappa_f = 0`;
`der(kappa_f) = (kappa - kappa_f) / T_f`; `kappa_dot = (kappa - kappa_f) / T_f`;
`kappa_pred = kappa + T_p * kappa_dot`; the rate line reads `kappa_pred`, and the latch fires only
when both `kappa` and `kappa_pred` are past `-lambda_target`. On the bench, `abs` gets
`T_p = T_p`. Run again; then with `T_p = 0` from the REPL, which is run A again.

**Reference model.** `HandsOn03.SlipABS` (with `T_p`; `T_p = 0` is A), `HandsOn03.ABSStop`,
`HandsOn03.ABSStopTransient` (forwards `road_mu`, `T_p`, `lambda_target`, `pedal`, `stop`). With
`T_p = 0.03` it is the law of `Vehicle.ABSIdealController`, on pressure through the hydraulics
instead of on a torque command.

**Checkpoint.**

- A, no look-ahead: **53.4 m, longer than the locked 43.7 m**; at μ 0.5 and 0.3, 98.8 and
  151.6 m, longer there too. A slip law that ignores the 30 ms lag dumps too late and overshoots
  into sliding.
- C, look-ahead 30 ms: **34.2 m**, 22 % shorter than 43.7 m; mean front wheel pressure
  **63.6 bar** with a ripple of about 1 bar at **26 Hz**, a smooth slip regulator; at μ 0.5 and
  0.3: 64.6 and 106.1 m.
- The wheel pressure never exceeds the master-cylinder pressure.
- At pedal 0.3 the ABS never acts: **35.95 m**, the same as `PedalStop`.

**Deck.** `modulator` (the ideal valve; build and dump are the two signs of the rate),
`abs-cycle`, `abs-model` (look-ahead), `one-stop`, `on-the-curve`.

**TODO.** Rehearse the code-view paste in Studio: whether the diagram keeps the `pressure`
placement and whether a nested `ifelse` survives Studio's formatter; and the duplicate of
`PedalStop` with its fluid declaration.

**Screenshots.** `step03-slipabs-code.png`, `step03-abs-bench.png`, `step03-torque-plot.png`,
`step03-mu-kappa-plot.png`.

### Step 04 · Only the wheel speed · 28 min

**Goal.** An ABS fed from a wheel-speed sensor only, with the three-phase cycle a production ECU
runs: dump, hold, build slowly from the held level. It beats the locked wheel on every road,
roughly equals the library's clocked ECU on a dry road and beats it on wet and snow, but gains
only about 5 % on snow.

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
`a_minus = 12`, `a_plus = 3`, `lambda_1 = 0.2`, `k_dec = 5.8e7`, `k_inc = 1.16e7` (Pa/s),
`v_min = 1.5`, `T_latch = 0.001`; variables `phase`, `cycled`. Equations:

    phase = ifelse(a_w > a_plus, 0, ifelse(a_w < -a_minus or kappa < -lambda_1, -1, 1))
    initial cycled = 0
    der(cycled) = ifelse(phase < -0.5, (1 - cycled) / T_latch, 0)
    connect(demand, pressure.demand)
    pressure.requested_rate = ifelse(phase < -0.5, -k_dec, ifelse(phase < 0.5, 0, k_inc))
    pressure.active = ifelse(v > v_min and cycled > 0.5, 1.0, 0.0)
    p_cmd = ifelse(cycled > 0.5, pressure.cmd, demand)

C · Duplicate `ABSStop` → `ABSStopWheelOnly`; set `abs` to `PhaseABS` (re-wire `master.p_mc →
abs.demand` and `abs.p_cmd →` both valves if the swap drops them); delete the `wheel.kappa` and
`speed.v` wires into `abs`; replace `T_p` and `lambda_target` with `a_ref = 8`; place `wspeed` =
`RotationalComponents.Sensors.VelocitySensor` on `wheel.spline` and `est` = `RefSpeedEstimator`;
wire `wspeed.w → est.omega`, `est.kappa_hat → abs.kappa`, `est.a_w → abs.a_w`,
`est.v_ref → abs.v`. Run 6 s; then at `road_mu = 0.3` with `stop = 20`; plot `abs.phase`,
`abs.p_cmd` and `wheel.caliper_f.p`.

**Why three phases.** Step 03's `SlipABS` fed from the estimator reads almost no slip while the
estimate rides the slipping wheel down, so it dumps only once the wheel has dived, and then
rebuilds from almost nothing, so the slip grows unseen during every slow rebuild. `PhaseABS`
changes two things. It dumps on the wheel's own deceleration, which needs no estimate of the car's speed: a
rolling wheel cannot decelerate faster than the car, at most about 9.8 m/s² on a dry road, so past
12 m/s² the tire has gone over its peak. And it holds: once the wheel spins back up past
+3 m/s² the pressure stops where the dump left it, just under the level that was too much, and
the slow build starts there. The hold is the pressure memory of the theory deck's state-machine
slide, and it is what a hydraulic modulator does with its two valves per wheel: inlet open is
build, both shut is hold, outlet open is dump. The estimated slip only catches a wheel that is
already locked (`a_w` = 0 there). `cycled` is a one-line latch: until the first dump `p_cmd` is
the driver's pressure and the valve is open, the fast first build; afterwards builds are slow.

A valve-level modulator in place of the ideal `ABSValve`, with inlet and outlet valves, an
accumulator and a return pump, is a stretch goal for whoever finishes early;
`docs/brake-system-implementation-plan.md` step 3 plans it for the library.

**Reference model.** `HandsOn03.RefSpeedEstimator`, `HandsOn03.PhaseABS`,
`HandsOn03.ABSStopWheelOnly`, `HandsOn03.ABSStopWheelOnlyTransient` (forwards `road_mu`,
`a_ref`, `stop`).

**Checkpoint** (H3, measured):

- μ = 1: **38.5 m**, shorter than the locked 43.7 m and level with the library's clocked ECU's
  38.7 m (deck). μ 0.5: **78.0 m**; μ 0.3: **130.6 m**, about 5 % under the locked 136.7 m.
- Front pressure cycle: dry **1.6 Hz, 24–65 bar**; μ 0.3 **3.7 Hz, 1.6–22 bar** (near-full
  dumps). Measured Bosch ABS: 2–4 Hz on asphalt with 15–30 bar swings, 4–6 Hz on ice with
  near-full dumps (Day & Roberts, SAE 2002-01-0559). Ours is a little slow and dumps deep on a
  dry road because the rates are fixed for one road: one 30 ms valve lag at 580 bar/s is 17 bar,
  most of the snow lock pressure. `docs/abs-efficiency-research.md` §3 has the runs; scaling the
  rates and thresholds by the road takes the snow stop to 113 m.
- `abs.pressure.p` does not move in a hold. The wheel pressure never exceeds `master.p_mc`.

**Deck.** `wheel-speed-sensors` ("the ABS measures only this"), `reference-speed`, `modulator`
and the state-machine slide, `abs-distance`, `abs-measured`, `abs-loses`.

**Screenshots.** `step04-estimator-code.png`, `step04-phaseabs-code.png`,
`step04-wheel-only-bench.png`, `step04-phase-plot.png`.

### Step 05 · Across road surfaces · 10 min

**Goal.** One table from the REPL: locked, ABS on true slip and ABS on wheel speed only, at road
μ 1.0, 0.5 and 0.3. Then the `a_ref` trap: on μ 0.3 an `a_ref` of 8 m/s² is almost three times
what the road allows, which the library ECU falls into; and what `a_ref` does to the students'
own ABS.

**Built / given.** Built: a 10-line REPL loop over the three analyses (the guide gives its
skeleton). Given: `Vehicle.braking_distance`; `ABSBrakeTransient` for the library column.

**Actions.** For μ in (1.0, 0.5, 0.3), run `PedalStopTransient` (pedal 0.6), `ABSStopTransient`,
`ABSStopWheelOnlyTransient` with `road_mu = μ` and `stop = 0.5 + 1.5·25/(0.7·μ·g) + 1` (the
notebook's rule, about 20 s at 0.3); fill the table. Rerun wheel-only with
`a_ref = 0.8·μ·g ≈ 2.4` at μ 0.3, and with the same `a_ref` at μ 1.

**Reference model.** The three analyses of steps 02–04; the library's `ABSBrakeTransient`,
`IdealBrakeTransient`, `LockedBrakeTransient` for the cross-check.

**Checkpoint.**

| road μ | locked, pedal 0.6 | ABS, true slip | ABS, wheel only (yours) | ABS, wheel only (library, 5 ms) |
|---:|---:|---:|---:|---:|
| 1.0 | **43.7 m** | **34.2 m** | 38.5 m | 38.7 m |
| 0.5 | **85.1 m** | **64.6 m** | 78.0 m | 83.2 m |
| 0.3 | **136.7 m** | **106.1 m** | 130.6 m | **141.3 m**, longer than locked |

The pedal stop is within 0.1 m of the deck's torque-level locked column (`abs-surfaces`). The
true-slip column is close to the deck's ideal-ABS column (34.4, 63.4, 102.2 m) but not equal: it
brakes through the valves, lines and calipers. The wheel-only ABS keeps most of the gain on a dry
road (5.2 of 9.5 m) and little on snow (6.1 of 30.6 m); the deck's `abs-measured` and `abs-loses`
slides tie that to measured cars. The trap at `a_ref = 8` on snow shows on the library ECU only,
which acts on its slip estimate; with `a_ref = 2.4` it stops in **128.4 m**. The students'
`PhaseABS` dumps on the wheel's deceleration and does not fall into it: their `a_ref = 2.4`
rerun gives **130.9 m** at μ 0.3, no better than at 8. On a dry road the same `a_ref`, below the
car's real deceleration, lets the estimate run above the car, and the slip trigger dumps on slip
that is not there: **106.3 m**. All library numbers are reproduced with Tsit5 at
`dtmax = 1e-3`.

**Deck.** `abs-surfaces`, `abs-measured`, `abs-loses`, `reference-speed` (the trap).

**Screenshots.** `step05-surface-table.png` (REPL output).

### No hand-in

A live build has no hand-in, as in Lecture 1: students commit their steps on the `lecture-03`
branch, and the section 03 summary and the wrap-up's "What you measured" slide carry the sentence
the hand-in asked for. Only the bonus is handed in.

### Step 06 · Traction control, bonus task (extra points) · take-home

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
- **The plant is too large to draw in a lecture.** A harness is `PlanarCar`, `PlanarCarSensors`
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
| H1 | `HandsOn03.PedalStop` + transient, on `HandsOn.Body`, through `Vehicle.Brake` and `HydraulicBrakedWheel` | **done**: pedal 0.3 55.2 bar, no lock, 36.0 m; pedal 0.6 89.2 bar, locks, 43.7 m; at μ 0.5 and 0.3 within 0.1 m of `LockedBrakeTransient` (85.1, 136.8 m) |
| H2 | `HandsOn03.SlipABS`, `ABSStop` + transient, on the hydraulic brake through two `ABSValve`s | **done**: C 34.2 / 64.6 / 106.1 m, front pressure 63.6 bar with a 26 Hz, 1 bar ripple; A 53.4 / 98.8 / 151.6 m; pedal 0.3 35.95 m, as `PedalStop` |
| H3 | `HandsOn03.RefSpeedEstimator`, `PhaseABS`, `ABSStopWheelOnly` + transient | **done**: 38.5 / 78.0 / 130.6 m, all under locked; `a_ref = 2.4`: 130.9 m at μ 0.3, 106.3 m at μ 1 |
| H4 | `Vehicle.braking_distance(result; t_brake = 0.5, v_stop = 0.5)` (also `(t, s, v; …)`) in `dyad/Vehicle/module.jl`, the notebook's `braking` rule as one function; notebook 01 switched to it | **done**: unit test on a synthetic constant-deceleration trace; notebook 01 prints the same numbers |
| H5 | merge PR #90 to `main`, tag it, and pin the tag in step 00 | open (the lecturer's call); a fresh `MyCar` clone with `Pkg.add(…, rev = tag)` and `Pkg.add("HydraulicComponents")` runs steps 02–05 |
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

Lecture 3 follows Lecture 1's format (decision D1): one deck, `slides/decks/lecture-03`, with
each build step as one slide inside the section it belongs to, and the build guide on the course
site. The separate `handson-03` projector deck that an earlier version of this plan called for was
built and then folded into the lecture deck; its figures moved to `slides/images/lecture-03/`.

Where each step sits in the deck:

| Step | Build slide | Section | Placed after |
|---|---|---|---|
| 00 | `build-setup` | 00 front matter | "The models behind this lecture" |
| 01 | `build-limits` | 01 friction and stopping | `braking-distance` |
| 02 | `build-pedal-stop` | 02 brakes | `combination-valve`, the last theory slide of the section, so the locked wheel is on screen before section 03 |
| 03 | `build-slip-abs` | 03 ABS | `abs-model`; checkpoints `one-stop`, `on-the-curve` follow, then the break |
| 04 | `build-wheel-only`, `build-wheel-only-cycle` | 03 ABS | `reference-speed`, moved to just after the break; checkpoint `abs-distance` follows |
| 05 | `build-surfaces` | 03 ABS | `abs-surfaces`, the library sweep it extends |
| 06 | `bonus-tcs` | 04 TCS | `tcs-and-lecture-1` |

Each build slide carries the code or a placeholder for the Studio screenshot, a one-line recipe,
the reference run's figure and numbers, and a link to its anchor on the guide (`#step-00` to
`#step-06`); its speaker notes carry the lecturer's full instructions and where students stall.
The library's ABS result slides stay the checkpoints, with green cues naming the students'
numbers. The hand-over slide became "What you measured", one row per step.

## Risks

| Risk | Where | Mitigation |
|---|---|---|
| Studio's code view reformats or drops the `pressure` placement, or a nested `ifelse` | 03, 04 | rehearse; a "Fell behind?" block with the full `SlipABS`, `RefSpeedEstimator` and `PhaseABS` source on the guide |
| Initial conditions on the bench (four lines in 02, carried into 03 and 04 by the copy) mistyped or forgotten; the wheel starts at 0 rad/s and the run is a wheel spinning up, not a stop | 02 | the guide gives the lines to paste; the checkpoint plot shows wheel and car speed together |
| Compile time: `MyCar` recompiles hands-on 1, 2 and 3 on every `Dyad: Compile` | all | rehearse on a student-spec laptop; compile once per step, not per edit |
| Solver: the bang-bang rate law switches every few milliseconds behind a 30 ms lag | 03–05 | Tsit5 with a `dtmax`, set in every reference analysis and on the guide; never FBDF, which steps over switching inputs and reports a wrong `Success` |
| Too short a `stop` on low μ: the car is still moving and the distance is undefined | 05 | the notebook's stop-time rule in the loop skeleton; `braking_distance` errors with the speed it ended at |
| Run A loses to the locked wheel | 03 | not a failure: the guide states it and step C fixes it |
| Step 04 overruns: two components to write | 04 | the guide's "Fell behind?" block hands out `PhaseABS`; the students then write only the estimator |
| A student filters `a_w` more heavily to smooth the plot | 04 | the checkpoint states `T_f = 5 ms`; a heavier filter adds lag to the dump trigger |
| `SlipABS` outputs `pressure.cmd` from the start, without the latch | 03 | the valve's 30 ms lag then acts on every stop; the guide's check is pedal 0.3, which must give 35.95 m |
| The branch pin in students' `Manifest.toml` (`feat/lecture02-theory-deck`) gives a library without the Lecture 3 parts | 00 | H5: a tag, `rev =` in step 00 |
| `MultibodyComponents` arrives with the tag | 00 | D7 |

## TODO slots and what fills each

| Slot | Where | Filled by |
|---|---|---|
| Course-library tag | step 00 (`TODO-TAG` on the deck and the guide) | H5 |
| ~~Run A distance, sliding share, cycle frequency; run C cycle frequency~~ | step 03 | H2, filled |
| ~~Wheel-only column and the `a_ref = 2.4` run~~ | steps 04, 05 | H3, filled |
| TCS figures | step 06 | H6 |
| Screenshots, listed in `docs/lecture-03-screenshots.md` | deck, guide | rehearsal in Studio |
| ~~The guide; the deck's guide links point there~~ | `slides/site/lecture/lecture-03/` | written; no tutor guide, the speaker notes and the run sheet carry it |
| Rehearsal of the drawing (02) and the three code-view pastes (03, 04 twice) | steps 02–04 | rehearsal in Studio, with the screenshots |

## Open decisions

Each has a recommended default; the plan above runs on the defaults. D1 is decided.

| # | Decision | Options | Recommended default |
|---|---|---|---|
| D1 | Session format | a separate 90-minute hands-on after the theory, Lecture 2 style / a live build inside the lecture, Lecture 1 style | **decided: a live build inside the lecture, Lecture 1 style.** One 3-hour deck with a build slide per step and the build guide on the course site; the `handson-03` deck is gone. The library's ABS result slides serve as the checkpoints |
| D2 | Body | the student's hands-on 1 `Body` / `Vehicle.VehicleBody` | **the student's `Body`**: identical physics on a flat road (H1 proves it), and the car stays theirs |
| D3 | How the controller is built | code view, about 8 lines, integrator given / drawn from `BlockComponents` / given `ABSIdealController`, only wired | **code view with the integrator given**: the rate law and the look-ahead are the lesson; the clipping is not. Step 04's `PhaseABS` follows the same rule |
| D4 | Wheel-speed-only step | build a continuous `RefSpeedEstimator` / wire the library's clocked `ABSController` in Studio | **build the estimator**; the clocked wiring (a three-way connect with the clock, three samplers) is GUI risk with no lesson in it. The library column in step 05 covers sampling |
| D5 | ESP in the lecture | demo only / a REPL-only run at the end / build | **demo only**, in section 05 from notebook `03-esp` |
| D6 | TCS | take-home bonus / a step in the lecture | **bonus**, brake in the wheel line of hands-on 1's `SlipCar`; no lecture time is left |
| D7 | Library tag and `MultibodyComponents` | tag before the planar car merges / tag after it, with setup done before the lecture | **tag what was rehearsed**; if the planar car is in it, ask students to run step 00 before the lecture and measure the install time in rehearsal |
| D8 | ABS on the student's `MappedCar` | no / a new `CVTDriveline` variant with a wheel shaft out, `BrakedWheel` on it | **no**: the engine and clutch add compile time and nothing to the ABS lesson; it would also leave out students who did not finish hands-on 2 |
| D9 | Reference solutions on `main` | `dyad/HandsOn03/` on `main` like `HandsOn02` / off `main` | **on `main`**, except the TCS bonus |
