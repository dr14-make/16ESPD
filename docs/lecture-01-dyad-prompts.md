# Dyad agent prompts — Lecture 1

Seven tasks, in build order. Each is self-contained and states its own done-condition. Hand
them over one at a time and check the reported numbers before starting the next — the whole
design is validated by task 3.

Reference: `docs/lecture-01-dyad-tasks.md` (component specs) and `docs/lecture-01-plan.md`
(why each piece exists).

---

## Task 1 — Vehicle physical components

Read `docs/lecture-01-dyad-tasks.md` first.

Create the `Vehicle` submodule at `dyad/Vehicle/` with four components. Compose standard-library
components wherever one exists; only `GradeForce` needs new equations.

1. **`IdealEngine`** — `RealInput tau_cmd`; `Spline spline, support`. Chain:
   `BlockComponents.Nonlinear.PadeDelay(delayTime=theta_e)` ->
   `BlockComponents.Continuous.FirstOrder(T=tau_e)` ->
   `BlockComponents.Nonlinear.Limiter(y_max=T_max, y_min=0)` ->
   `RotationalComponents.Sources.TorqueSource`.
   Parameters `theta_e=0.04`, `tau_e=0.3`, `T_max=150`.
   The delay and the lag are load-bearing for the lecture design — do not simplify them away.

2. **`Driveline`** — `Spline spline, support_r`; `Flange flange, support_t`.
   `RotationalComponents.Components.IdealGear(ratio=i)` then
   `RotationalComponents.Components.IdealRollingWheel(radius=r)`, with `i=4.0`, `r=0.31`.
   Keep the gear as its own subcomponent; do not fold the ratio into an effective radius.

3. **`GradeForce`** — new equations. `extends TranslationalComponents.Interfaces.PartialForce`,
   `RealInput grade` (= tangent of road angle), parameters `m` and `g=9.80665`,
   `f = -m*g*sin(atan(grade))`. Needed because
   `TranslationalComponents.Components.Mass` offers only a fixed `theta` parameter, and the
   lecture needs a hill that begins mid-simulation.

4. **`VehicleBody`** — `Flange flange`; `RealInput grade`. Assemble
   `Mass(m=1400)`;
   `QuadraticSpeedDependentForce(ForceDirection=false, v_nominal=30, f_nominal=0.5*rho*CdA*v_nominal^2)`
   with `rho=1.2`, `CdA=0.63`;
   `RollingResistance(fWeight=m*g)` with `cr` driven from a `Constant(0.012)` and `inclination`
   driven from the same grade input; and `GradeForce(m)`.

Every component gets a `test` with `expect.initial` and `expect.final`. Compile and simulate
each one before starting the next. Report the final values you assert.

---

## Task 2 — CarPlant, GradeProfile, and the open-loop checks

Create the `Lecture1` submodule at `dyad/Lecture1/`.

1. **`CarPlant`** — `IdealEngine` + `Driveline` + `VehicleBody` +
   `TranslationalComponents.Sensors.VelocitySensor`.
   Ports: `RealInput tau_cmd`, `RealInput grade`, `RealOutput v`.

2. **`GradeProfile`** — flat, then a sustained climb of a given gradient from a given start
   time. Compose from `BlockComponents.Sources`; no new equations.

Then verify numerically and report the numbers:

- **(a)** full torque from rest reaches a finite terminal speed — report it in km/h;
- **(b)** a sustained 10% climb at 130 km/h drives the engine into its 150 N.m limit and the car
  falls back below setpoint — report the speed it settles at.

If (b) does not saturate, say so and propose a parameter change. Do not change parameters
unilaterally — the scenario numbers are pedagogical choices, not free variables.

---

## Task 3 — CruiseLoop, and the Ziegler-Nichols gate

Create **`Lecture1.CruiseLoop`**: `CarPlant` closed around
`BlockComponents.Continuous.LimPID`, with a setpoint input.

Expose `with_I` and `with_D` as structural parameters — notebooks 03, 04 and 05 are this one
model with those two booleans flipped, so do not build three separate loops. Also expose `k`,
`Ti`, `Td`, `Nd`, `Ni`, `y_max`, `y_min`, `wp`, `wd`.

Verify and report numbers:

- **(a)** with `with_I=false, with_D=false`, a step 90 -> 110 km/h leaves a visible steady-state
  error across a range of `k` — give the error at four gains spanning roughly two decades.
- **(b) THE GATE** — with `with_I=false, with_D=false`, raising `k` far enough produces
  sustained oscillation. Report the ultimate gain `Ku` and the ultimate period `Pu`.

(b) is the most important check in the build. The lecture's tuning notebook applies
Ziegler-Nichols to this car, and ZN requires sustained oscillation under proportional control —
which is possible only because the engine carries a transport delay and a first-order lag. If
you cannot find `Ku`, do not work around it: report immediately, with what you tried, because
the plant parameters then have to change and a Tier 1 notebook is at risk.

---

## Task 4 — Clamping anti-windup

`LimPID` implements anti-windup by back-calculation (the `Ni` parameter). The lecture teaches
**clamping** — conditional integration, where the integrator input is zeroed while the output
is saturated and the error carries the same sign as the output.

Build a clamping variant of the cruise loop so the demonstration matches what the students are
told. Keep the back-calculation version as well; notebook 06 compares them.

Verify on the 10% climb at 130 km/h: with no anti-windup the integrator grows through the climb
and the car overshoots hard once the road flattens; with each method it does not. Report peak
overshoot for all three cases.

---

## Task 5 — Sampler for the discretization notebook

Notebook 09 shows a continuous-tuned PID degrading as the sample rate drops.

Dyad has `ClockInput`/`ClockOutput` connectors, but the standard library ships **no** sampled
blocks — no `Sample`, no `ZeroOrderHold`, no `UnitDelay`, no discrete PID, and no `when` syntax
in Dyad relations. Two routes:

**Floor — build this first, it must exist.** A half-sample transport delay,
`PadeDelay(delayTime = Ts/2)`, in the feedback path. A zero-order hold costs the loop half a
sample of phase, so this reproduces the destabilizing mechanism without a real sampler. It
produces no staircase; put that limitation in the docstring.

**Stretch — time-box it, abandon rather than overrun.** A real clocked partition as an
`external` component: interface declared in Dyad, implementation hand-written in Julia
returning a ModelingToolkit `System` built on `Clock(Ts)` / `Sample` / `Hold` / `ShiftIndex`.
Whether this Dyad kernel's compiler passes handle a clocked partition is unverified.

Verify with the tuned gains: sweep `Ts` and report the sample time at which overshoot becomes
objectionable, and the one at which the loop goes unstable.

---

## Task 6 — MeasurementNoise

**`Lecture1.MeasurementNoise`** — additive noise on the velocity measurement, for notebook 07.

Use a **deterministic sum of sines, not a random number generator.** The notebooks are committed
with executed outputs, and a plot that changes between runs is worse than useless in a lecture.

Spread the components over one or two decades of frequency, so the derivative's amplification
shows up as a function of frequency rather than of amplitude — that is the entire point of the
notebook.

Verify: with the derivative filter wide open (large `Nd`) the commanded torque chatters;
reducing `Nd` cleans it up. Report the commanded-torque range in both cases.

---

## Task 7 — Wheel and slip

Notebook 10, Tier 3 — build this last.

1. **`WheeledDriveline`** — as `Driveline`, with `RotationalComponents.Components.Inertia(J_w)`
   between gear and wheel.

2. **`SlipWheel1D`** — new equations. Ports: `Spline spline` (wheel shaft), `Flange flange`
   (to body), `RealInput mu_scale`. Parameters `radius`, `F_z`, `sAdhesion=0.04`,
   `sSlide=0.12`, `mu_A`, `mu_S`, `v_eps`.

       kappa = (omega*radius - v) / max(abs(v), v_eps)
       mu    = mu_scale * <curve rising to mu_A at sAdhesion, falling to mu_S beyond sSlide>
       F_x   = mu * F_z

   Use the same friction-curve shape as `MultibodyComponents.SlipWheelJoint` so this remains a
   recognized model rather than an invented one. The 3D slip models are high-index DAEs and far
   too heavy here; this is the 1D equivalent. Note in the docstring that the curve's second
   derivative is discontinuous at the transitions and that explicit RK solvers handle it better
   than BDF.

3. **`FrictionProfile`** — unity, collapsing to low friction for a given duration, then back.

4. **`WheeledCarPlant`**, **`SlipCarPlant`**, **`SlipCruiseLoop`** assemblies.

Verify: a standing start at `mu_scale = 0.2` produces wheelspin — the wheel accelerates while
the car barely does. Report wheel speed and vehicle speed at the end.
