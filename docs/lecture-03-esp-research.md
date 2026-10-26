# ESP in Dyad: model fidelity, tire, controller, tests and build sequence

Research note for Lecture 3 (ABS, TCS, ESP). It answers what is needed to simulate an electronic
stability program (ESP, called ESC in the regulations) in this repository's Dyad workspace, and
in what order to build it.

The note has three kinds of evidence:

- **Literature** claims cite their sources. Anything I could not read in a primary text is
  marked **unverified** or "secondary".
- **Code** claims come from reading the installed sources of `MultibodyComponents` 0.2.6 and this
  repository at origin/main (ba1478d).
- **Simulation** claims come from two throwaway feasibility probes. The first is a planar
  four-wheel car assembled from `MultibodyComponents.PlanarMechanics` in plain ModelingToolkit.
  The second is the same car written as a `.dyad` file and compiled with
  `@juliacomputing/dyad-cli@3.4.0` in a scratch copy of this project. Both give the same
  numbers. Neither is committed; the Dyad source is reproduced in the Appendix.

## Summary

1. **`PlanarMechanics` works here and is the right chassis.**
   - `MultibodyComponents` is in the depot (0.2.4–0.2.6) and in `DyadRegistry`. Adding it to this
     project resolves with no version change to any existing dependency; 0.2.6 and about 11
     transitive packages are added.
   - `TwoTrackModelTest` runs: 16 states, 20 s, `Success` with `Rodas5P`. It is a toy, though
     (300 kg chassis, I = 0.1 kg·m², starts at rest, peaks at 3.4 m/s). Use it for topology only.
   - A planar car at 80 km/h compiles from Dyad source and runs a full sine-with-dwell in
     0.3–2.6 s per run.
2. **Minimum model: a planar two-track car.** The states are body vx, vy and yaw rate, plus four
   wheel spins. Front steering is prescribed, the loads are static, and there is no roll.
   - A bicycle model cannot show *which* wheel ESP brakes, and wheel selection is the core idea
     of the lecture. Keep the bicycle model as the controller's *reference*, not as the plant.
   - Add quasi-static load transfer as the second increment. Roll is not needed.
3. **Tire: `SlipBasedWheelJoint` is usable once it is tuned per axle.**
   - It is an isotropic combined-slip model: one triple-S curve on the resultant slip velocity,
     split along the slip direction. That is a friction circle by construction.
   - Its cornering stiffness is 1.5·µ_A·N / sAdhesion. **With the same `sAdhesion` on both axles
     the car is exactly neutral-steer**, whatever the weight distribution.
   - Use `sAdhesion` ≈ 0.12 front and 0.09 rear. That gives 12.5 and 16.7 per rad of load, in
     the measured 9–13 per rad range for the front, and a mild understeer gradient.
   - It also moves the longitudinal peak from 0.04 toward the realistic 0.1–0.18.
4. **Controller: reference yaw rate, P/PI yaw-moment control, one braked wheel.**
   - The reference is r_ref = vx·δ / (L + K_us·vx²), saturated at ±0.85·µg/vx.
   - Allocation: brake the **outer front** wheel on oversteer and the **inner rear** wheel on
     understeer.
   - The probe, with ideal sensing, a 100 ms brake lag and **no slip limiting**, passes every
     FMVSS 126 sine-with-dwell run where the uncontrolled car spins. But it locks the braked
     wheel (κ = 1) and loses 40% of the speed. ESP braking therefore needs a per-wheel slip limit,
     which is the four-channel ABS.
5. **First test: sine-with-dwell (FMVSS 126 / UN R140).** It has crisp numeric pass criteria, it
   is open-loop in steering (no driver model), and it separates "spins" from "doesn't" sharply.
   Add split-µ braking next, which reuses ABS directly. The ISO 3888 lane change needs a driver
   model; leave it for later.
6. **Dyad gotchas found in the probe.** Each one cost a failed run.
   - `Frame2D` is a built-in connector. Write `Frame2D()`; the qualified
     `MultibodyComponents.PlanarMechanics.Frame2D()` fails to resolve.
   - `World(g = 0)` is mandatory. Planar gravity acts *in the road plane*.
   - Implicit solvers with ForwardDiff return `Unstable` at t = 0 when the car starts in perfect
     free rolling. The cause is the derivative of `sqrt(v_slip_long² + v_slip_lat²)` at zero.
     Start the wheels 0.01 m/s fast, or use `Tsit5`.
   - **`FBDF` steps straight over the time-programmed steering input and returns a wrong
     `Success`.** Use `Tsit5` or `Rodas5P`.
7. **Build sequence:** nine validated increments, from adding the dependency to a clocked ESP
   with sensor models. The first five reach a passing ESP demo, about 4–6 working days in total.
   See §7.

## 1. Model fidelity

### Options

| model | states | shows | misses |
|---|---|---|---|
| Linear bicycle | vy, r | understeer gradient, reference yaw rate, step response | saturation, which wheel brakes, combined slip |
| Nonlinear bicycle + yaw-moment input Mz | vx, vy, r | spin-out, ESP as an abstract Mz | wheel selection, ABS interaction, split-µ |
| **Planar two-track, static loads** | x, y, ψ, vx, vy, r, 4×ω | wheel-selective braking, locked wheel losing lateral force, split-µ | load transfer, roll |
| + quasi-static load transfer | same | inner-wheel unloading, lower grip under braking at the front | roll dynamics |
| + roll, suspension | +2–4 | rollover-mitigation ESP | adds stiffness and parameters with no payoff for a yaw demo |

The ESC definition in FMVSS 126 S4 makes "applies and adjusts the vehicle brake torques
individually" and "a computer closed-loop algorithm to limit vehicle oversteer and ... understeer"
the defining attributes [1]. A model that cannot brake one wheel cannot show that. **The planar
two-track model is the minimum.** The linear bicycle model belongs in the controller as the
reference generator (§3), and on a slide as the explanation of understeer.

### Load transfer

- **Longitudinal transfer.** ΔFz = m·ax·h/L, moving load from rear to front.
- **Lateral transfer per axle.** ΔFz ≈ m·ay·h/t, split between the axles by roll-stiffness
  distribution. Use the static-load share as a first guess. Without roll stiffness data this split
  is an assumption, **unverified**.

Both matter quantitatively during ESP braking. The unloaded inner rear wheel locks first, which is
why real systems prefer the inner rear only up to a limit (the Bosch patent [8] adds the inner
front for that reason). They are not needed for the qualitative spin/no-spin demo: the probe
spins and recovers without them.

`SlipBasedWheelJoint` has a `dynamicLoad` input for exactly this. Feeding it from the body's
accelerations closes an algebraic loop (force → acceleration → load → force). I expect MTK to
tear it, but **I did not test it**. If it causes trouble, pass ax and ay through a first-order
lag of about 50 ms first. That is physically defensible as suspension lag, **unverified** as a
number.

Roll is not needed. Hamblin et al. found roll measurably changes the cornering stiffness
identified from test data [10]. That is an identification issue, not a reason to model roll in a
demo.

### Teaching trade-off

The two-track model costs four wheel spin states, which are stiff (§5). It also costs a
steering linkage. In return, students can *see* the outer front wheel brake on oversteer and the
locked wheel slide. The bicycle model can be shown alongside it as a five-line Julia cell, for
the reference yaw rate and the understeer gradient.

## 2. Tire model

### What `SlipBasedWheelJoint` actually does

From `dyad/PlanarMechanics/slip_based_wheel_joint.dyad` (MultibodyComponents 0.2.6):

```
v_slip_long = v_long - radius*w_roll        # positive while braking
v_slip_lat  = v_lat
v_slip      = sqrt(v_slip_long^2 + v_slip_lat^2) + 0.0001
vAdhesion   = max(vAdhesion_min, sAdhesion*abs(radius*w_roll))
vSlide      = max(vSlide_min,    sSlide*abs(radius*w_roll))
f           = max(0, N + dynamicLoad) * limit_S_triple(vAdhesion, vSlide, mu_A, mu_S, v_slip)
f_long      = f*v_slip_long/v_slip;   f_lat = f*v_slip_lat/v_slip
```

Consequences:

- **Combined slip: an isotropic friction circle.** The force has one magnitude, from the resultant
  slip, and points against the slip velocity. A locked wheel (ω = 0) slides at µ_S against its
  velocity, so it loses its lateral "steering" force. That is the effect ABS exists to prevent,
  and it comes for free.
- **Slip is normalized by the wheel's circumferential speed rω, not by the vehicle speed.** The
  peak sits at |v_slip| = sAdhesion·rω. So the lateral peak is at tan α ≈ sAdhesion, and the
  longitudinal peak (driving) is at v_slip/(rω) = sAdhesion. Below `vAdhesion_min` /
  `vSlide_min` the thresholds stop shrinking, which is the low-speed regularization.
- **Same curve in both directions.** Real tires have different longitudinal and lateral
  stiffness and shape. Pacejka's Magic Formula has separate Bx… and By… sets for that [3, 4].
- **Cornering stiffness per tire is C_α = 1.5·µ_A·N / sAdhesion.** The slope of
  −0.5x³ + 1.5x at 0 is 1.5. So C_α is proportional to the load, with no load sensitivity.
- **Proportional C_α means exactly neutral steer.** The understeer gradient is

  ```math
  K_{us} = \frac{m}{L}\left(\frac{b}{C_f} - \frac{a}{C_r}\right)
  ```

  with C_f, C_r per axle. With C ∝ load and N_f ∝ b, N_r ∝ a, the bracket is zero. Understeer
  has to be put in by hand, through a softer front `sAdhesion` (or a lower front µ_A).
- **No relaxation length.** Lateral force builds instantly with slip angle. That is acceptable at
  0.7 Hz steering.
- The `limit_S_triple` curve is the same triple-S as this repository's `TireFrictionCurve`. So
  ABS knowledge transfers, and so does the ABS research's verdict: at `sAdhesion = 0.04` it is far
  too sharp. Burckhardt's dry asphalt peaks at 0.17 [ABS note, §2].

### Recommended parameters

| parameter | front | rear | rationale |
|---|---|---|---|
| `sAdhesion` | 0.12 | 0.09 | C_α/N = 12.5 / 16.7 per rad. Measured front-axle values on a 1992 Mercury Tracer were 57.7–83.0 kN/rad at a 6339 N axle load, which is 9.1–13.1 per rad [10]. The front/rear split gives K_us ≈ 0.0020 rad/(m/s²) = 1.2°/g of road-wheel angle, a mild understeer. Typical production values are higher, **unverified** |
| `sSlide` | 3·sAdhesion | 3·sAdhesion | keeps the post-peak drop gradual |
| `mu_A`, `mu_S` | 1.0, 0.8 | 1.0, 0.8 | NHTSA slide/peak on dry asphalt is 0.89 [ABS note, ref 9]. 0.8 is a compromise that makes the spin visible |
| `vAdhesion_min`, `vSlide_min` | 0.05, 0.15 m/s | same | the `TwoTrackModelTest` values; only matter below ~2 m/s |

**Magic Formula option.** A dry-tarmac set B = 10, C = 1.9, D = 1, E = 0.97 on slip *ratio* is
published by MathWorks [4]. It peaks at κ = 0.18 with 0.915·D at lock (computed here). That
matches Burckhardt's 0.17. MultibodyComponents ships `pacejka_magic(B,C,D,E,x)` and a 3D
`PacejkaWheelJoint` that uses these default values. But that joint feeds **slip velocity in m/s**
into a curve parameterized for dimensionless slip. At 22 m/s, B = 10 per m/s puts the peak near
κ ≈ 0.008. **Do not use it for ESP without renormalizing.** No planar Pacejka joint exists.

**Friction ellipse vs. MF combined-slip weighting vs. brush/Dugoff.**

- For a demo whose message is "a braked wheel has less lateral grip", the isotropic circle is
  enough.
- Pacejka's combined-slip weighting functions G_xα, G_yκ [3] are the production-grade answer.
  They cost ~10 parameters per direction. **Not read here; book not accessible.**
- Dugoff gives combined slip from two stiffnesses and µ in closed form. It is a good middle
  ground if a custom planar wheel is ever written, **unverified** beyond textbook familiarity.

## 3. ESP controller

### Structure

```
δ_sw, vx ─► reference model ─► r_ref, β_ref (bounded by µ)
r, β̂     ─► yaw-moment controller ─► Mz_cmd
Mz_cmd  ─► wheel selection + torque allocation ─► ΔT_brake,i (or Δslip setpoint,i)
                                         └► wheel-slip controllers (ABS/TCS) ─► brake torque
engine torque request ◄─ (reduce during intervention)
```

van Zanten's Bosch papers frame ESP as slip-angle (β) control. The yaw moment is "generated
through individual wheel slip control" [5]: ESP changes the *slip setpoints* of subordinate wheel
controllers, rather than commanding brake torque directly. Only the abstract was readable; the
control laws are behind SAE's paywall.

### Reference yaw rate and sideslip

Steady-state linear bicycle model, per Rajamani §8.2.3–8.2.5 (section titles verified from the
table of contents [6]; equations as reproduced by Kahraman et al. citing Rajamani [7]):

```math
r_{nom} = \frac{v_x\,\delta}{L + K_{us}\,v_x^2},\qquad
|r_{ref}| \le 0.85\,\frac{\mu g}{v_x},\qquad
|\beta_{ref}| \le \tan^{-1}(0.02\,\mu g)
```

The 0.85·µg/vx bound is the yaw rate at which lateral acceleration reaches 85% of the friction
limit (a_y = r·v_x). The ESP therefore stops asking for more yaw than the road can deliver.
That is also how FMVSS 126 defines oversteer and understeer: yaw rate greater, or less, "than the
yaw rate that would occur at the vehicle's speed" [1], quoted as far as the excerpt I read.
µ must be estimated. Use µ = 1 for the dry-road demo and mark µ-estimation as out of scope.

### Yaw-moment law

| law | pro | con |
|---|---|---|
| **P (or PI) on r − r_ref with a dead-band** | four lines; tunable live in class | no β protection; integrator windup on saturation |
| P on r plus a β term: Mz = −k_r(r − r_ref) − k_β·β when \|β\| > β_lim | adds the sideslip limit that van Zanten emphasizes [5] | β must be estimated |
| Sliding mode on s = (r − r_ref) + ξ(β − β_ref) | robust to µ; Rajamani's chapter treats this family [6] | chattering, so it needs a boundary layer; more to explain |
| LQR / MPC (Falcone et al.) | state of the art in research | not production practice; too much for one lecture |

**Recommendation: P with a dead-band first.** That is what the probe uses: k = 40 kN·m per
rad/s, dead-band 0.03 rad/s. Add the β term second.

### Allocation

| situation (left turn, r > 0) | sign of needed Mz | wheel braked |
|---|---|---|
| oversteer: \|r\| > \|r_ref\| | negative (clockwise) | **outer (right) front** |
| understeer: \|r\| < \|r_ref\| | positive | **inner (left) rear** |

Sources: Bosch patent US7949454 (understeer: inner rear, extended to the inner front in some
cases) [8]; secondary descriptions (Saab workshop manual; kfz-tech) agree, while Saab says
"outer wheels" (plural) for oversteer [9]. Kahraman et al.'s Table 2 [7] brakes the *rear right*
for an understeering left turn. That disagrees with the Bosch description. I follow Bosch.

The brake torque needed for a moment Mz from one wheel on a track t is T = |Mz|·r_w/(t/2). On a
steered front wheel the lever arm changes with δ. Kahraman et al. give the exact form [7]; the
probe ignores it, which is fine below δ ≈ 0.1 rad.

**Sign check, from the probe:** a brake force at y = +t/2 (left), pointing backward, gives
Mz = −y·Fx = +(t/2)·F_b. Braking the left side turns the car left.

### Interaction with ABS, TCS and the engine

- FMVSS 126 S5.1.3 requires ESC to remain capable of activation while ABS or TCS is active [1].
- **The probe shows why the slip limit matters.** With no slip limit, the commanded 2000–2500 N·m
  locked the braked wheel in every ESP run (κ = 1.0). The car still recovered, because a locked
  outer front wheel also sheds lateral force, which also reduces oversteer. But speed dropped
  from 22.2 to 13–15 m/s. A production ESP brakes within the stable slip range (van Zanten [5]).
- **Implementation:** route each ESP torque request through that wheel's ABS channel, as an
  added demand, so the existing `ABSController` limits it. The `ABSController`'s wheel-only
  reference-speed estimator is wrong for ESP, where one wheel is braked deliberately. Use a
  four-wheel reference speed (max of the free wheels, or the true vx in the continuous version).
- Engine torque reduction is part of the S4 definition [1]. The probe coasts, as the test
  prescribes ("coasting in high gear" [1]), so it can be omitted for sine-with-dwell. Keep it for
  a TCS/ESP-on-throttle scenario.

### Sensors and estimation

FMVSS S4 requires a "means to determine the vehicle's yaw rate and to estimate its side slip or
side slip derivative" and to monitor driver steering inputs [1]. The standard ESP sensor set is:

- steering-wheel angle;
- yaw-rate gyro;
- lateral accelerometer;
- four wheel speeds;
- master-cylinder pressure.

The set is from the Bosch-related descriptions [9]. Bosch Automotive Handbook not accessible,
so **secondary**.

Sideslip is estimated kinematically, β̇ ≈ a_y/v_x − r. Integration drifts, so production
estimators blend in a model-based estimate (van Zanten [5] mentions estimation, details
paywalled). **For the lecture, use true β and true vx in the continuous controller.** Add a
noisy yaw-rate sensor and the kinematic β estimate as a later increment, to show the drift.

## 4. Test maneuvers and pass criteria

### Sine-with-dwell (FMVSS 126; UN R140 / R13-H): implement first

All values are from 49 CFR 571.126 [1]:

- **Speed.** 80 ± 2 km/h, coasting in high gear.
- **Steering.** A 0.7 Hz sine with a 500 ms dwell at the second peak.
- **Amplitudes.** Runs go from 1.5A up in 0.5A steps, to the greater of 6.5A and 270°, capped
  at 300°.
- **What A is.** The steering-wheel angle giving 0.3 g in steady state, from slowly increasing
  steer at 13.5°/s.
- **Completion of steer (COS)** is when the steering angle returns to zero. **Beginning of steer
  (BOS)** is the first crossing of ±5° steering-wheel angle.
- **Lateral stability (S5.2.1, S5.2.2).** The yaw rate 1.0 s after COS must be ≤ 35% of the
  "first peak value of yaw rate recorded after the steering wheel angle changes sign". It must be
  ≤ 20% at 1.75 s after COS. S7.11.8 calls this the *second* peak, "the first local yaw rate peak
  produced by the reversal of the steering wheel".
- **Responsiveness (S5.2.3).** The lateral displacement of the CG must be ≥ 1.83 m at 1.07 s
  after BOS (GVWR ≤ 3500 kg), for runs at ≥ 5A.

UN R140 was extracted from R13-H, which "more or less duplicated" FMVSS 126 according to
Mechanical Simulation [11]. I could not open the R140 text (UNECE 403, EUR-Lex empty), so the
identity of the numbers is **unverified**. ISO 19365:2016 standardizes validating a *simulation*
of exactly this test against measurements [11], which is a nice framing for the lecture.

**Probe results**, sine-with-dwell, A = 20° (computed from the linear model at a 16:1 steering
ratio), so 5A ≈ 100°. "ESP" means the P controller with a 100 ms first-order brake lag, no slip
limit, true r and vx.

| SWA | passive YRR@1.0 / @1.75 | passive β_max, end speed | ESP YRR@1.0 / @1.75 | ESP y(BOS+1.07) | ESP β_max, end speed |
|---|---|---|---|---|---|
| 30° | 0.00 / 0.00 | 0.8°, 22.1 m/s | 0.00 / 0.00 | 1.07 m | 0.8°, 21.5 |
| 60° | 0.00 / 0.00 | 1.9°, 21.7 | 0.00 / 0.00 | 2.10 m | 1.7°, 20.0 |
| 100° | **1.32 / 1.33** (spin) | 84°, −4.0 | 0.00 / 0.00 | 2.39 m | 6.1°, 14.7 |
| 140° | **1.01 / 1.01** (spin) | 83°, −2.5 | 0.00 / 0.00 | 2.54 m | 6.4°, 13.9 |
| 180° | **0.91 / 0.91** (spin) | 82°, −1.4 | 0.00 / 0.00 | 2.61 m | 6.8°, 13.5 |
| 220° | **0.87 / 0.87** (spin) | 62°, 2.2 | 0.00 / 0.00 | 2.64 m | 7.1°, 13.3 |
| 270° | 0.00 / 0.00 (plows) | 5.4°, 19.7 | 0.00 / 0.00 | 2.64 m | 6.9°, 13.2 |

- The uncontrolled car fails between 100° and 220°.
- At 270° it plows instead of spinning: the front axle saturates first. Real test data show the
  same non-monotonic pattern; that the probe reproduces it is a good sign, but it is **not
  validated against data**.
- ESP passes both stability criteria and the 1.83 m responsiveness limit at every amplitude.
- The 40% speed loss is the missing slip limit (§3), not a property of ESP.

### Split-µ braking: implement second

Straight-line braking with µ = 1.0 on the left wheels and 0.3 on the right. The yaw moment from
the unequal brake forces spins the car without control. ABS alone limits wheel lock but not the
yaw. ESP, or ABS yaw-moment build-up delay, keeps the heading. The test needs no steering
profile, reuses the four ABS channels directly, and needs a per-wheel `mu_scale`. The
`SlipBasedWheelJoint` has no µ input, so pass µ through a wrapper's `mu_A` / `N` or a custom
wheel (§5). **No regulation-backed pass criterion was checked.** Use the heading deviation and
the lateral offset at standstill as course metrics.

### Step steer (ISO 7401)

A ramp to a fixed steering angle at constant speed; it measures yaw-rate response time and
overshoot. It is good for validating the passive car against the bicycle model (increment 3 in
§7). I did not read ISO 7401; the procedure details are **unverified**.

### ISO 3888-1 double lane change / ISO 3888-2 obstacle avoidance

These are closed-loop driver tests, so they need a path-following driver model (preview or
pure-pursuit). ISO 3888-1:2018 is a 6-page track-geometry standard for passenger cars and
LCVs ≤ 3.5 t [12]. The cone dimensions often quoted (sections 15/30/25/25/15 m, lane widths
1.1w + 0.25 m, etc.) **could not be verified**. Leave this test for a later lecture or a bonus.

## 5. Dyad feasibility

### Reuse vs. new

| need | reuse | new |
|---|---|---|
| chassis, rigid links, world | `PlanarMechanics.World(g = 0)`, `Body`, `FixedTranslation` | — |
| steering | `PlanarMechanics.Revolute` + `RotationalComponents.Sources.Position` | `SineWithDwell` source (time-programmed `ifelse`) |
| tire | `PlanarMechanics.SlipBasedWheelJoint` | `PlanarBrakedWheel` wrapper: joint + `Inertia` + brake + slip outputs κ, α |
| brake | `Vehicle.Wheel.BrakeActuator`: its `Spline` connectors match `SlipBasedWheelJoint.flange_a`; the probe used a `TorqueSource` instead, so **not yet tested** | — |
| ABS per wheel | `Vehicle.ABSController` (clocked), 4 instances on one `PeriodicClock` | four-wheel reference-speed estimator |
| ESP | — | `YawReference`, `YawMomentController`, `BrakeAllocator` |
| load transfer | `dynamicLoad` input | quasi-static `LoadTransfer` block |
| metrics | — | Julia helper for YRR and displacement (post-processing, not Dyad) |

The wheel wrapper should *not* reuse `SlipWheel1D` / `BrakedWheel`: those carry a translational
`Flange`, while the planar joint carries a `Frame2D`.

### Dyad specifics confirmed by the probe

- `Frame2D()`, like `Spline()` and `Flange()`, is a built-in connector type. Write it
  unqualified.
- RealInputs of library components are set by plain equations (`joint.dynamicLoad = 0`,
  `brake.tau = -tau_brake * tanh(inertia.w / 0.5)`).
- `time` can be used directly in relations, which is how the sine-with-dwell is written.
- Initialization at speed needs:
  - `initial body.v = [v0, 0]`, `initial body.r = [0, 0]`, `body.phi`, `body.w`;
  - every wheel `inertia.w` and `inertia.phi`;
  - the two `Position` sources' filter states `initial posL.w = 0`. The default
    `ReferenceType.Filtered()` adds two states per source; without these the initialization
    is underdetermined.
- Four named wheel instances work. Component arrays were **not tried**.
- Clocked controllers: `ABSController` already demonstrates `@[input clk extends Discrete]`. An
  ESP loop is commonly said to run at 10–20 ms, **unverified**. Remember the handover gotcha: a
  clocked variable reads back as its last value, so read the held signal.
- `MultibodyComponents` must be added to `Project.toml` `[deps]` (and `[compat]`). The scratch
  resolve with `PRESERVE_ALL` changed no existing version. It is held at 0.2.6 by compat
  somewhere, so newer releases exist; not investigated.

### Numerical behavior (probe)

| solver | result |
|---|---|
| `Auto` (DyadInterface default), `Rodas5P`, `FBDF`, wheels at exact rolling speed | `Unstable` at t = 0. ForwardDiff through `sqrt(0 + 0)` gives a NaN Jacobian |
| `Rodas5P`, wheels started at (v0 + 0.01)/r | correct, 0.5 s per run |
| `Tsit5` | correct either way, 0.3–2.6 s per run |
| `FBDF`, wheels offset | **wrong**: returns `Success` with no response to the steering input (YRR 0.64 at both instants, no speed loss). It steps over the dwell profile |

The upstream `TwoTrackModelTest` avoids the problem by starting from rest. MultibodyComponents'
own test solves it with `Rodas5P(autodiff = AutoFiniteDiff())`.

Recommendations:

- Offset the initial wheel speed slightly, or regularize inside the wrapper.
- Pin the analysis solver to `Tsit5` or `Rodas5P`.
- Set `saveat`/`dtmax` ≤ 0.01 s, so that the 1.0 s and 1.75 s samples are interpolated, as
  S7.11.8 requires [1], and so no solver steps over the steering profile.

Low-speed slip: the joint regularizes with `vAdhesion_min` / `vSlide_min`. The ESP must turn off
below 20 km/h anyway (FMVSS S4 [1]).

## 6. Parameters

| symbol | value | source / note |
|---|---|---|
| m | 1500 kg (probe); 1400 kg to match `VehicleBody` | NHTSA "Passenger Large" class mean 1403 kg [13] |
| I_z | 2500 kg·m² (probe); 2900 is the class mean | 2893 kg·m² "Passenger Large" [13]; 1850 kg·m² for a 1030 kg Mercury Tracer [10] |
| a, b | 1.2, 1.5 m (probe); class 1.28, 1.40 m | wheelbase 2.679 m, front axle to CG 1.277 m [13] |
| t (track) | 1.55 m (probe); class 1.47 m | [13] (older US fleet) |
| h_cg | 0.55 m | class 0.585 m [13]; Tracer 0.52 m [10] |
| r_w | 0.31 m | repository default |
| J_w | 1.0 kg·m² per wheel | ABS research: 1.1–1.6, secondary [ABS note, §2] |
| C_α front / rear | 61 / 49 kN/rad per tire (probe) | from sAdhesion 0.12 / 0.09; measured 29–42 kN/rad per front tire on a small car [10] |
| µ_A, µ_S | 1.0 / 0.8 | §2 |
| steering ratio | 16:1 | typical, **unverified**; only the A-scaling depends on it |
| brake torque cap per wheel | 2500 N·m | assumed; the repository `BrakeActuator` default is 2000 N·m |
| ESP brake lag | 100 ms first order | assumed; active pressure build-up with the return pump is slower than a pedal apply, **unverified** |

The table [13] is reproduced in Penn State course notes from Heydinger et al., SAE 1999-01-1336.
That is a secondary copy; the SAE original was not accessible. The class table's mass column is
labeled "sprung mass", but its values match curb masses, so read it with care.

## 7. Recommended build sequence

Each increment ends with a check that must pass before the next one starts. Sizes are rough
estimates for one person familiar with this repository.

| # | increment | completion check | size |
|---|---|---|---|
| 0 | Add `MultibodyComponents` to `Project.toml`; recompile with dyad-cli 3.4.0 | existing test suite green; recompiling an unchanged tree leaves `git status` clean apart from the new generated files | S (½ day) |
| 1 | `PlanarBrakedWheel` wrapper with `BrakeActuator`, κ and α outputs, per-wheel µ; single-wheel test on a `Body` with a prescribed slip angle | F_lat peaks at tan α = sAdhesion; under brake + slip angle the resultant ≤ µ·N (friction circle); a locked wheel gives F_lat → µ_S·N·sin(slip direction) | S (1 day) |
| 2 | `PlanarCar`: four wheels, prescribed steering, static loads, initialized at 80 km/h | straight coast: r ≡ 0, vy ≡ 0, slow deceleration only; init with no warnings | S–M (1 day) |
| 3 | Steady-state and step-steer validation | constant small δ: r within 5% of vx·δ/(L + K_us·vx²); K_us from the formula matches the simulated slope r(δ) | S (½ day) |
| 4 | `SineWithDwell` harness + Julia metric helper (YRR at COS + 1.0/1.75 s, displacement at BOS + 1.07 s, A from slowly increasing steer) | passive car fails at some amplitude in 1.5A…270°; metrics match the probe table to ±0.05 | M (1 day) |
| 5 | Continuous ESP: `YawReference`, P/PI `YawMomentController`, `BrakeAllocator` | passes S5.2.1–S5.2.3 at every amplitude; outer front braked on oversteer, inner rear on understeer, checked in a constant-radius understeer run | M (1–1½ days) |
| 6 | Four ABS channels in the brake path; ESP demand added to ABS demand | no wheel exceeds the ABS slip window during the sine-with-dwell; end speed visibly higher than in step 5; split-µ braking run | M (1–2 days) |
| 7 | Quasi-static load transfer via `dynamicLoad` | static sum of loads = m·g at every instant; inner-wheel load drops in a turn; no new initialization failure | S–M (1 day) |
| 8 | Clocked ESP (sampled, ZOH) + sensor models (yaw-rate noise and offset, kinematic β̂) | discrete version within 10% of the continuous one at a 10 ms sample time; β̂ drift shown | M–L (2–3 days) |
| 9 | Pluto notebook for Lecture 3: trajectories, yaw rate vs. reference, wheel torques, pass/fail table | runs top to bottom in the course environment | M (1–2 days) |

Increments 0–5 give a lecture-ready demo of "ESP stops the spin". Increments 6–7 make it
quantitatively honest. Increment 8 links to the Lecture 1 discretization material.

## 8. Corrections to `lecture-03-preparation.md`

- The file paths are stale:
  - `dyad/Vehicle/BrakeActuator.dyad` is now `dyad/Vehicle/Wheel/BrakeActuator.dyad`;
  - the notebook is `notebooks/lecture03/01-abs.pluto.jl`.
- "`SlipBasedWheelJoint` already supplies ... a combined friction limit": true, but it is
  *isotropic*, normalized by the wheel's rolling speed, and exactly neutral-steer with equal
  `sAdhesion`. See §2.
- `TwoTrackModelTest` is a 300 kg, I = 0.1 kg·m², from-rest, 3.4 m/s toy:
  - its front wheels are separate 100 kg bodies on revolutes steered by a torque square wave;
  - its loads are constant (1000/1500 N).
  - It is a topology reference only, as the prep note already warns.
- The note does not mention `World(g = 0)`, or the solver and initialization pitfalls in §5.
- "Four-channel ABS reusing `Vehicle.ABSController`": workable. Its wheel-only reference-speed
  estimator, though, is wrong once ESP brakes single wheels (§3).

## Open questions for the user

1. **Chassis source.** Use `PlanarMechanics`, which is proven to work here, or write a small
   custom two-track component with explicit equations, which students can read in one screen?
2. **Tire.** Keep the isotropic triple-S with per-axle `sAdhesion`, consistent with
   `TireFrictionCurve`? Or write a planar Magic-Formula wheel on slip ratio, which is more
   realistic but a new component?
3. **ABS retune.** Should Lecture 3 also move `TireFrictionCurve` off `sAdhesion = 0.04`, which
   would change the ABS lecture's numbers, so that ABS and ESP share one tire?
4. **Scope of the controller.** Continuous only, or the clocked version too (increment 8)?
5. **Steering input.** Prescribe the road-wheel angle directly, or the steering-wheel angle with a
   ratio, so that the FMVSS "A" and the 270° limit read as in the regulation?

## Reproduce

All files are in the session scratchpad, which is not committed:

- `mbenv/car.jl`, `run4.jl`: the ModelingToolkit probe and the table in §4. Run them with
  `julia +dyad-3.4.0 --project=mbenv`.
- `mbenv/tt.jl`: `TwoTrackModelTest`.
- `dyadcopy/`: a copy of this project with `MultibodyComponents` added and
  `dyad/Vehicle/Planar/ESPProbe.dyad` (the Appendix). Run `runprobe2.jl` for the solver
  comparison.

## Appendix: compiled Dyad probe

It compiles with dyad-cli 3.4.0 once `MultibodyComponents` is a dependency. It is a starting
point for increments 1–5, not a finished component: it has no slip limit and no load transfer,
and the controller sits inline in the test harness.

```dyad
"Sine-with-dwell road-wheel angle"
component SineWithDwell
  y = RealOutput()
  parameter A::Angle = 0.1
  parameter f::Frequency = 0.7
  parameter t0::Time = 1.0
  variable tau::Time
relations
  tau = time - t0
  y = ifelse(tau < 0, 0.0, ifelse(tau < 0.75 / f, A * sin(2 * π * f * tau), ifelse(tau < 0.75 / f + 0.5, -A, ifelse(tau < 1 / f + 0.5, A * sin(2 * π * f * (tau - 0.5)), 0.0))))
end

"One braked planar wheel: slip-based contact, wheel inertia, commanded brake torque"
component PlanarBrakedWheel
  frame_a = Frame2D()
  tau_brake = RealInput()
  joint = MultibodyComponents.PlanarMechanics.SlipBasedWheelJoint(radius = radius, r = [1, 0], N = N, mu_A = mu_A, mu_S = mu_S, sAdhesion = sAdhesion, sSlide = 3 * sAdhesion, vAdhesion_min = 0.05, vSlide_min = 0.15, render = false)
  inertia = RotationalComponents.Components.Inertia(J = J)
  brake = RotationalComponents.Sources.TorqueSource()
  fixed = RotationalComponents.Components.Fixed()
  parameter radius::Length = 0.31
  parameter J::MomentOfInertia = 1.0
  parameter N::Force = 4000.0
  parameter mu_A::Real = 1.0
  parameter mu_S::Real = 0.8
  parameter sAdhesion::Real = 0.1
relations
  connect(frame_a, joint.frame_a)
  connect(joint.flange_a, inertia.spline_a)
  connect(inertia.spline_b, brake.spline)
  connect(brake.support, fixed.spline)
  joint.dynamicLoad = 0
  brake.tau = -tau_brake * tanh(inertia.w / 0.5)
end

test component ESPProbe
  parameter m::Dyad.Mass = 1500
  parameter Iz::MomentOfInertia = 2500
  parameter a::Length = 1.2
  parameter b::Length = 1.5
  parameter tw::Length = 1.55
  parameter v0::Velocity = 22.22
  parameter rw::Length = 0.31
  parameter Kp::Real = 40000
  world = MultibodyComponents.PlanarMechanics.World(g = 0)
  body = MultibodyComponents.PlanarMechanics.Body(m = m, I = Iz, render = false, linearStatePriority = 2)
  tf = MultibodyComponents.PlanarMechanics.FixedTranslation(r = [a, 0])
  tr = MultibodyComponents.PlanarMechanics.FixedTranslation(r = [-b, 0])
  fl_arm = MultibodyComponents.PlanarMechanics.FixedTranslation(r = [0, tw / 2])
  fr_arm = MultibodyComponents.PlanarMechanics.FixedTranslation(r = [0, -tw / 2])
  rl_arm = MultibodyComponents.PlanarMechanics.FixedTranslation(r = [0, tw / 2])
  rr_arm = MultibodyComponents.PlanarMechanics.FixedTranslation(r = [0, -tw / 2])
  steerL = MultibodyComponents.PlanarMechanics.Revolute()
  steerR = MultibodyComponents.PlanarMechanics.Revolute()
  posL = RotationalComponents.Sources.Position()
  posR = RotationalComponents.Sources.Position()
  fixL = RotationalComponents.Components.Fixed()
  fixR = RotationalComponents.Components.Fixed()
  steer = VehicleSystemsComponents.Vehicle.Planar.SineWithDwell(A = 180 / 16 * π / 180)
  fl = VehicleSystemsComponents.Vehicle.Planar.PlanarBrakedWheel(N = m * 9.81 * b / (a + b) / 2, sAdhesion = 0.12)
  fr = VehicleSystemsComponents.Vehicle.Planar.PlanarBrakedWheel(N = m * 9.81 * b / (a + b) / 2, sAdhesion = 0.12)
  rl = VehicleSystemsComponents.Vehicle.Planar.PlanarBrakedWheel(N = m * 9.81 * a / (a + b) / 2, sAdhesion = 0.09)
  rr = VehicleSystemsComponents.Vehicle.Planar.PlanarBrakedWheel(N = m * 9.81 * a / (a + b) / 2, sAdhesion = 0.09)
  variable vx::Velocity
  variable r_ref::AngularVelocity
  variable e::AngularVelocity
  variable Mz::Torque
  variable Tcmd::Torque
  variable over::Real
relations
  connect(body.frame_a, tf.frame_a, tr.frame_a)
  connect(tf.frame_b, fl_arm.frame_a, fr_arm.frame_a)
  connect(tr.frame_b, rl_arm.frame_a, rr_arm.frame_a)
  connect(fl_arm.frame_b, steerL.frame_a)
  connect(steerL.frame_b, fl.frame_a)
  connect(fr_arm.frame_b, steerR.frame_a)
  connect(steerR.frame_b, fr.frame_a)
  connect(rl_arm.frame_b, rl.frame_a)
  connect(rr_arm.frame_b, rr.frame_a)
  connect(steerL.flange_a, posL.spline)
  connect(posL.support, fixL.spline)
  connect(steerR.flange_a, posR.spline)
  connect(posR.support, fixR.spline)
  connect(steer.y, posL.phi_ref, posR.phi_ref)
  vx = cos(body.phi) * body.v[1] + sin(body.phi) * body.v[2]
  r_ref = max(min(vx * steer.y / ((a + b) + 0.002 * vx ^ 2), 0.85 * 9.81 / max(vx, 1.0)), -0.85 * 9.81 / max(vx, 1.0))
  e = body.w - r_ref
  Mz = -Kp * ifelse(abs(e) > 0.03, e - 0.03 * sign(e), 0.0)
  over = ifelse(abs(body.w) > abs(r_ref), 1.0, 0.0)
  Tcmd = min(abs(Mz) / (tw / 2) * rw, 2500.0)
  fl.tau_brake = ifelse(Mz > 0 and over > 0.5, Tcmd, 0.0)
  fr.tau_brake = ifelse(Mz < 0 and over > 0.5, Tcmd, 0.0)
  rl.tau_brake = ifelse(Mz > 0 and over < 0.5, Tcmd, 0.0)
  rr.tau_brake = ifelse(Mz < 0 and over < 0.5, Tcmd, 0.0)
  initial body.r = [0, 0]
  initial body.v = [v0, 0]
  initial body.phi = 0
  initial body.w = 0
  initial fl.inertia.w = (v0 + 0.01) / rw
  initial fr.inertia.w = (v0 + 0.01) / rw
  initial rl.inertia.w = (v0 + 0.01) / rw
  initial rr.inertia.w = (v0 + 0.01) / rw
  initial fl.inertia.phi = 0
  initial fr.inertia.phi = 0
  initial rl.inertia.phi = 0
  initial rr.inertia.phi = 0
  initial posL.w = 0
  initial posR.w = 0
end

analysis ESPProbeTransient
  extends TransientAnalysis(stop = 6.0, abstol = 1e-6, reltol = 1e-6)
  model = ESPProbe()
end
```

The Dyad probe has no brake lag (Tlag = 0). The §4 table used the ModelingToolkit probe with a
100 ms lag. At 180° the Dyad probe gives YRR −0.95 passive (spin) and 0.00 with ESP, with an end
speed of 18.2 m/s, which is identical to the ModelingToolkit probe at Tlag = 0.

## Sources

1. 49 CFR § 571.126, FMVSS No. 126 "Electronic stability control systems for light vehicles":
   S4 definitions, S5.1–S5.2.3, S7.6, S7.9, S7.11.
   https://www.law.cornell.edu/cfr/text/49/571.126 (read)
2. Repository: `docs/abs-frequency-research.md` ("ABS note"), for the Burckhardt peak slip, NHTSA
   slide/peak ratios and wheel inertia, with its own sources.
3. Pacejka, H. B., *Tire and Vehicle Dynamics*, 3rd ed., Butterworth-Heinemann 2012, ch. 4
   (Magic Formula, combined slip). **Not accessible; cited for existence of the method only.**
4. MathWorks, "Tire-Road Interaction (Magic Formula)" block reference: B, C, D, E for dry/wet
   tarmac, snow, ice. https://www.mathworks.com/help/sdl/ref/tireroadinteractionmagicformula.html
   (read)
5. van Zanten, A. T., "Bosch ESP Systems: 5 Years of Experience", SAE 2000-01-1633.
   https://saemobilus.sae.org/content/2000-01-1633 (abstract only). The 1995 paper (van Zanten,
   Erhardt, Pfaff, "VDC, the Vehicle Dynamics Control System of Bosch", SAE 950759) was not
   accessed.
6. Rajamani, R., *Vehicle Dynamics and Control*, 2nd ed., Springer 2012, ch. 8, "Electronic
   Stability Control", pp. 201–240. Table of contents:
   https://www.gbv.de/dms/ilmenau/toc/669481157.PDF (TOC read; chapter text not accessible)
7. Kahraman, K. et al., "Yaw Stability Control System Development and Implementation for a Fully
   Electric Vehicle", arXiv:2012.04719: eqs. 21–24 (r_nom, 0.85·µg/vx, β bound, citing Rajamani
   2006), Table 2 (wheel selection), eqs. 26–27 (torque from Mz).
   https://arxiv.org/abs/2012.04719 (read)
8. US7949454B2 (Bosch), "Driving dynamics control system having an expanded braking function":
   inner-rear braking for understeer, extended to the inner front.
   https://patents.google.com/patent/US7949454 (seen in search excerpt)
9. Saab 9-5 workshop information, "ESP function"
   (https://saabwisonline.com/9-5-9600/2003/5-brakes/stabiliser-system-esp/technical-description/esp-function),
   and kfz-tech (https://www.kfz-tech.de/Engl/ElektrStabPrg.htm). Secondary; seen in search
   excerpts.
10. Hamblin, B. C., Brennan, S. N. et al., "Lessons Learned from Matching Experimental Data to
    Low-Order Models of Vehicle Yaw, Sideslip, and Roll Behavior", ASME IMECE2007-42202: Table 2
    inertial parameters (1992 Mercury Tracer), measured front cornering stiffness.
    https://www.me.psu.edu/toboldlygo/Publications/Conferences/2007_Hamblin_LessonsLearnedFromMatchingExperimentalDataToLowOrderModelsOfVehicleYawSideslipAndRollOverBehaviour.pdf
    (read)
11. Mechanical Simulation Corp., "The Sine with Dwell Test" (R13-H duplicates FMVSS 126;
    simulation allowed for homologation). https://www.carsim.com/applications/fmvss126 (search
    excerpt). ISO 19365:2016, *Passenger cars — Validation of vehicle dynamic simulation — Sine
    with dwell stability control testing* (catalog entry only).
12. ISO 3888-1:2018, *Passenger cars — Test track for a severe lane-change manoeuvre — Part 1:
    Double lane-change*. https://www.iso.org/standard/67973.html (catalog entry only)
13. Sommer, H. J., Penn State ME 481 notes 07_04, "Inertial Properties of American Vehicles",
    after Heydinger et al., "Measured Vehicle Inertial Parameters — NHTSA's Data Through November
    1998", SAE 1999-01-1336. https://www.me.psu.edu/sommer/me481/notes_07_04.pdf (read)

**Not accessible:** the van Zanten full texts, the Rajamani chapter text, Pacejka, the Bosch
Automotive Handbook, ISO 3888/7401, and the UN R140 text itself. Nothing from them is cited
beyond titles, tables of contents and abstracts.
