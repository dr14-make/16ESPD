# Dyad agent brief — Lecture 1 models

Companion to `lecture-01-plan.md`, which holds the pedagogical intent. This file holds the
models. Read the plan first; several component shapes only make sense once you know which
notebook consumes them.

## Submodule layout

    dyad/
      Vehicle/      the vehicle and its environment, shared by every lecture
      Lecture1/     controllers, teaching harnesses and analyses, specific to this lecture

The dividing line: if lecture 2 would use it unchanged, it belongs in `Vehicle/`. That puts
`CarPlant` and `GradeProfile` in `Vehicle/` — a car is a car and a hill is a hill regardless of
what is being taught about them. `CruiseLoop`, the scenario harnesses and every analysis go in
`Lecture1/`, because they exist to teach control rather than to be a vehicle.

Lecture-structured where lectures actually differ. The car itself is reused by lecture 2
(engine control) and beyond, and promoting a component to a different submodule later breaks
every reference to it, so the physical models are separated now rather than moved later.

Referenced fully qualified from the root library: `VehicleSystemsComponents.Vehicle.IdealEngine`,
`VehicleSystemsComponents.Lecture1.CruiseLoop`. A definition may not share its name with a
sibling submodule directory.

## Ground rules

- **Compose the standard library; write equations only where nothing exists.** Of the
  components below only `GradeForce`, `SlipWheel1D` and `MeasurementNoise` need new equations.
  The rest are assemblies.
- **Namespace everything.** Only the base connectors (`RealInput`, `Flange`, `Spline`, ...) go
  unqualified. Everything else is fully qualified or it will not compile.
- **Never edit `generated/`.**
- **Every component ships a `test`** with `expect.initial` and `expect.final`. Those two are
  the numbers that must be right up front; signal snapshots pass trivially on first run.
- **Verify as you go.** Compile and simulate each component before building the next. Do not
  stack five unverified components and then debug the assembly.
- US English in identifiers and docstrings. Comments explain *why* — a constraint, an
  invariant, a gotcha — never what the code already says and never the history of the change.

## Vehicle submodule

### `IdealEngine`

Torque command in, shaft torque out, with the two lags that make the plant FOPTD. Compose:

    RealInput tau_cmd
      -> BlockComponents.Nonlinear.PadeDelay(delayTime = theta_e)
      -> BlockComponents.Continuous.FirstOrder(T = tau_e)
      -> BlockComponents.Nonlinear.Limiter(y_max = T_max, y_min = 0)
      -> RotationalComponents.Sources.TorqueSource
    ports: Spline spline, support
    parameters: theta_e = 0.04 s, tau_e = 0.3 s, T_max = 150 N.m

The transport delay and the lag are load-bearing, not decoration — see the plan's "Why the
engine lags are not optional". Do not simplify them away.

### `Driveline`

    RotationalComponents.Components.IdealGear(ratio = i)
      -> RotationalComponents.Components.IdealRollingWheel(radius = r)
    ports: Spline spline, support_r; Flange flange, support_t
    parameters: i = 4.0, r = 0.31 m

Keep the gear as its own subcomponent rather than folding the ratio into an effective radius.
Notebook 01 derives tractive force as `T * i / r` on the board, and the model should read the
same way.

### `GradeForce` (new equations)

Road gradient as a time-varying input; `TranslationalComponents.Components.Mass` only offers a
fixed `theta` parameter, which cannot represent a hill that starts at t = 30 s.

    extends TranslationalComponents.Interfaces.PartialForce
    RealInput grade        # tan(alpha), matching RollingResistance's `inclination`
    parameters: m, g = 9.80665
    f = -m * g * sin(atan(grade))

### `VehicleBody`

    TranslationalComponents.Components.Mass(m)
    TranslationalComponents.Sources.QuadraticSpeedDependentForce(
        ForceDirection = false,        # v*|v| so drag opposes motion in both directions
        f_nominal = 0.5 * rho * CdA * v_nominal^2,
        v_nominal = 30)
    TranslationalComponents.Components.RollingResistance(fWeight = m * g)   # regularized near v = 0
    Vehicle.GradeForce(m)
    ports: Flange flange; RealInput grade
    parameters: m = 1400 kg, CdA = 0.63 m^2, rho = 1.2 kg/m^3, f_r = 0.012

`RollingResistance` takes `cr` and `inclination` as inputs, not parameters — drive `cr` from a
`BlockComponents.Sources.Constant` and `inclination` from the same grade signal as `GradeForce`.

### `ToKmPerHour`, `ToRPM`, `ToPercent`

Signal-level unit conversions, each `extends BlockComponents.Interfaces.SISO` with a single
equation (`y = 3.6*u`, `y = (60/(2*pi))*u`, `y = 100*u`).

The one deliberate exception to composing the standard library: `Math.Gain` would do it, but a
subcomponent and two connects to express `y = 3.6*u` is more indirection than the equation it
hides, and a bare `Gain(k = 3.6)` in a diagram does not say what it converts.

### `WheeledDriveline` (L1, notebook 10)

As `Driveline` but with `RotationalComponents.Components.Inertia(J_w)` between gear and wheel,
introducing the wheel's rotational state.

### `SlipWheel1D` (new equations, notebook 10)

One-dimensional slipping contact. The 3D multibody slip models are high-index DAEs and far too
heavy here; this is the 1D equivalent, built on the same friction-curve shape so it stays a
recognized model.

    ports: Spline spline (wheel shaft); Flange flange (to body); RealInput mu_scale
    parameters: radius, F_z, sAdhesion = 0.04, sSlide = 0.12, mu_A, mu_S, v_eps

    kappa = (omega * radius - v) / max(abs(v), v_eps)
    mu    = mu_scale * <adhesion/sliding curve in kappa: rises to mu_A at sAdhesion,
                        falls to mu_S beyond sSlide>
    F_x   = mu * F_z

`mu_scale` is the road-friction input that notebook 10 collapses to create the ice patch. The
curve has a discontinuous second derivative at the transitions; note in the docstring that
explicit RK solvers handle it better than BDF, as the multibody equivalent does.

## Lecture1 submodule

### Parameter forwarding — the rule for scenario knobs

**Anything a notebook varies is forwarded to the top-level model and exposed on the analysis.**
`CarPlant` already does this for `theta_e` and `T_max`, and `CarStepTest` exposes `tau_lo`,
`tau_hi`, `v0` and `t_step`. Follow that pattern for every new knob.

Dyad also generates a nested override mechanism — keyword arguments split on a double
underscore and forwarded down the tree, so `WideOpenThrottle(plant__body__m = 1600)` reaches
`VehicleBody`. It works, and it is strict about unmatched names. It is still not the interface:
that path encodes the model's internal structure, so renaming a subcomponent breaks every
notebook using it, for a reason unrelated to anything those notebooks teach. Treat it as an
escape hatch for one-off exploration.

Forward only what is actually varied. `m`, `CdA` and the road gradient are scenario knobs;
`rho` and `g` are not.

### Harnesses and analyses

**A component with unconnected `RealInput` ports cannot be a `TransientAnalysis` model.**
`CarPlant` takes `tau_cmd` and `grade`, so every notebook scenario needs a harness component
that drives those inputs, plus an analysis extending `TransientAnalysis` that points at it.
This was missing from the first version of this brief.

Harnesses also carry the initial conditions. `CarPlant` will not initialize without
`plant.body.mass.s`, and a harness that starts from a settled cruise should also set
`plant.engine.lag.x` to the holding torque — otherwise the run wastes hundreds of seconds
settling before the interesting part, because the vehicle's own time constant is about 60 s.

### `CarPlant` (L0) — in the `Vehicle` submodule

`IdealEngine` + `Driveline` + `VehicleBody` + `TranslationalComponents.Sensors.VelocitySensor`,
with the sensor output passed through `Vehicle.ToKmPerHour`.
Ports: `RealInput tau_cmd`, `RealInput grade`, `RealOutput v_kmh` (primary measurement),
`RealOutput v` (SI, for plots that want it).

**The control loop runs in km/h.** Setpoint, measurement and error are all km/h, so the
controller gain `k` has units of N.m per km/h. Plant internals stay SI and exactly one
conversion exists in the whole model — do not add a second one anywhere.

### `CruiseLoop`

`CarPlant` wrapped in `BlockComponents.Continuous.LimPID`, with a setpoint input.

Expose `with_I` and `with_D` as structural parameters. Notebooks 03, 04 and 05 are the same
model with those two booleans flipped — do not build three separate loops. Also expose `k`,
`Ti`, `Td`, `Nd`, `Ni`, `y_max`, `y_min`, `wp`, `wd`.

### Scenario sources

- `GradeProfile` — flat, then a sustained 10% climb from a given time.
- `FrictionProfile` — unity, then a collapse to low friction for a given duration, then back.

Both are `BlockComponents.Sources` compositions; neither needs new equations.

### `MeasurementNoise` (new equations, notebook 07)

Additive noise on the velocity measurement. **Use a deterministic sum of sines, not an RNG** —
the notebooks are committed with executed outputs and a plot that changes between runs is worse
than useless in a lecture. Spread the components across a decade or two of frequency so the
derivative's amplification is visible as a function of frequency rather than amplitude.

### Sampler (notebook 09) — your call

Two routes; see decision D1 below.

### `WheeledCarPlant`, `SlipCarPlant`, `SlipCruiseLoop` (notebook 10)

L1 and L2 assemblies, and the cruise loop closed around L2 for the ice-patch scenario.

## Decisions delegated to you

**D1 — how to build the sampler.** Dyad has `ClockInput`/`ClockOutput` connectors but the
standard library ships no sampled blocks at all: no `Sample`, no `ZeroOrderHold`, no
`UnitDelay`, no discrete PID, and no `when` syntax in Dyad relations. Two routes:

- *Floor, must exist:* a half-sample transport delay (`PadeDelay(delayTime = Ts/2)`) in the
  feedback path. A zero-order hold costs the loop half a sample of phase, so this reproduces
  the destabilizing mechanism exactly. No new code, cannot fail. It produces no staircase, so
  the notebook must say plainly that it is a surrogate.
- *Stretch, time-boxed:* a real clocked partition as an `external` component — interface
  declared in Dyad, implementation hand-written in Julia returning an MTK `System` built on
  `Clock(Ts)` / `Sample` / `Hold` / `ShiftIndex`. Whether this Dyad kernel's compiler passes
  handle a clocked partition cleanly is unverified.

Build the floor first so notebook 09 exists regardless. If the stretch lands it becomes the
headline and the floor stays in as the explanation of *why*.

**D2 — which anti-windup.** `LimPID` implements back-calculation via `Ni`; the source video
teaches clamping (conditional integration). Either show back-calculation and describe clamping
in prose, or build a clamping variant so the demo matches what the students were told. Lean
towards building the variant: notebook 06 is Tier 1 and the mismatch would be visible on screen.

**D3 — Pade order.** High enough that the delay is faithful at the loop's crossover, low enough
not to stiffen the system. Check both ends rather than taking the default.

## Acceptance criteria

Verify these numerically. If one fails, the parameters need trimming — say so rather than
adjusting the lecture around it.

1. Full torque from rest reaches a finite terminal speed.
2. Step 90 -> 110 km/h under pure proportional control leaves a **visible** steady-state error
   across the whole recommended gain range.
3. A sustained 10% climb at 130 km/h drives the engine into its torque limit and the car falls
   back below setpoint.
4. **Raising Kp under pure proportional control produces sustained oscillation**, with a
   measurable ultimate gain and ultimate period. *Verify this one first.* It is the gate that
   the entire FOPTD design exists to pass, and notebook 08 — a Tier 1 notebook carrying the
   practical task from the lecture slides — is impossible without it.
5. A standing start at low `mu_scale` produces wheelspin: the wheel accelerates while the car
   does not.

## Build order

    1. IdealEngine, Driveline, GradeForce, VehicleBody, CarPlant, CruiseLoop, GradeProfile
       -> verify acceptance criteria 1-4 before anything else
    2. Sampler (D1 floor)
    3. MeasurementNoise
    4. WheeledDriveline, SlipWheel1D, FrictionProfile, and the L1/L2 assemblies
