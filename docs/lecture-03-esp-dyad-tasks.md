# Dyad agent brief — Lecture 3 planar car and ESP

This brief turns `docs/lecture-03-esp-research.md` (the research) into ten Dyad tasks. Each task
ends in a check the agent runs before the next task starts. The model is a planar four-wheel car
built from `MultibodyComponents.PlanarMechanics`, with a yaw-rate ESP that brakes single wheels
through four ABS channels.

Every expected number below has a source:

- **hand**: a closed-form calculation, worked in the text;
- **MTK probe**: a throwaway ModelingToolkit model of the same car (the research's `car.jl`,
  extended for this brief);
- **Dyad probe**: a throwaway `.dyad` model compiled with dyad-cli 3.4.0 in a scratch copy of
  this repository, with `MultibodyComponents` 0.2.6 added.

Neither probe is committed. § "Probe evidence" lists what each one confirmed. Where a number has
not been simulated, the text says **not simulated**.

The ready-to-paste prompts are at the end, in § "Prompts".

## Read before the first compile

1. `docs/lecture-03-esp-research.md`: §2 (tire), §3 (controller), §4 (sine-with-dwell), §5
   (Dyad feasibility) and the Appendix (the compiled probe).
2. `agent_resources/skills/dyad-language/SKILL.md`, then from `agent_resources/docs/`:
   `syntax.md`, `components.md`, `initialization.md`, `metadata.md` (test blocks), `analyses.md`.
3. `docs/HANDOVER.md` § "Gotchas found during the build". The two that bite hardest: a `.dyad`
   edit does nothing until `npx -y @juliacomputing/dyad-cli@3.4.0 compile .` regenerates
   `generated/`, and the suite must run from `test/`.
4. `docs/lecture-01-dyad-tasks.md` § "Parameter forwarding" and § "Harnesses and analyses".
5. `docs/abs-controller-spec.md` § "Sign conventions" and § 5 (`ABSModulator`), before task 6.
6. The `MultibodyComponents` sources. They are not in `agent_resources/stdlib_reference/`. Find
   them with
   `julia +dyad-3.4.0 --project=. -e 'using MultibodyComponents; println(pkgdir(MultibodyComponents))'`
   and read `dyad/PlanarMechanics/slip_based_wheel_joint.dyad`, `body.dyad`, `revolute.dyad`,
   `fixed_translation.dyad`, `prescribed_velocity.dyad`, `world.dyad` and
   `examples/` (`TwoTrackModelTest`, topology only).

## Layout

    dyad/Vehicle/Planar/   reusable planar parts: wheel, car, steering sources, ESP blocks, ABS channels
    dyad/Vehicle/Planar/module.jl   plain Julia: the FMVSS 126 metric functions (task 4)
    dyad/Lecture3/         harnesses and analyses that exist only to teach this lecture

The Lecture 1 dividing line holds: if a later lecture would use it unchanged, it belongs under
`Vehicle/`. Reference everything fully qualified, e.g.
`VehicleSystemsComponents.Vehicle.Planar.PlanarCar`. No component may share its name with a
sibling directory, so nothing is called `Planar` or `Lecture3`.

`generated/Vehicle/Planar/module.jl` already includes `dyad/Vehicle/Planar/module.jl` if it
exists (the compiler emits that hook for every submodule). That is where the metric functions go,
so tests and the notebook call the same code as `VehicleSystemsComponents.Vehicle.Planar.fmvss126_metrics`.

## Ground rules

- **Existing components stay unchanged.** Nothing under `dyad/Vehicle/Wheel/`, `dyad/Vehicle/Brake/`,
  `ABSController.dyad`, `ABSBrakeTest.dyad` or `VehicleBody.dyad` is edited. Lecture 1 and the
  Lecture 3 ABS notebook pin their numbers. Reuse them by instantiation:
  `Vehicle.Wheel.BrakeActuator` inside the planar wheel and `Vehicle.ABSModulatorDiscrete` inside
  the ABS channel.
- **Compose the library; write equations only where nothing exists.** Read a component's source
  before using it; parameter names are not guessable.
- **Base connectors are unqualified.** `Frame2D()` is a built-in connector like `Spline()` and
  `Flange()`. The qualified `MultibodyComponents.PlanarMechanics.Frame2D()` does not resolve
  (Dyad probe).
- **`World(g = 0)` in every car model.** Planar gravity acts in the road plane. A model with no
  `Body` must omit `World` entirely: a `World` with nothing reading `g` fails at problem setup
  with "Expected an `Initial` parameter to exist for variable `g`" (Dyad probe, single-wheel rig).
- **Solver.** Every test case sets `"solver": "Tsit5"` (or `"Rodas5P"`), and every analysis
  `alg = ODEAlg.Tsit5()` with `dtmax = 0.005`. Never `FBDF`: it steps over the time-programmed
  steering and returns a wrong `Success` (research §5). The test default `ODEAlg.Auto()` and the
  analysis default `AutoImplicit` are implicit and fail at t = 0 at exact free rolling.
- **Initialize at speed, with the wheels 0.01 m/s fast.** `initial body.v = [v0, 0]`,
  `initial body.r = [0, 0]`, `initial body.phi = 0`, `initial body.w = 0`, every wheel
  `inertia.w = (v0 + 0.01)/radius` and `inertia.phi = 0`, every `brake.tau_actual = 0`, and each
  steering `Position` source's filter state `pos.w = 0`. Exact rolling makes
  `sqrt(v_slip_long² + v_slip_lat²)` non-differentiable at t = 0 and implicit solvers return
  `Unstable`. The 0.01 m/s offset is a known, testable perturbation (task 2 checks it exactly).
- **Sign conventions, one set for every block.** Body frame x forward, y left, yaw positive
  counterclockwise (a left turn). Wheels are `fl`, `fr`, `rl`, `rr`; left is +y. Slip `kappa` is
  negative while braking, as in `SlipWheel1D` and the ABS blocks. Tire forces `F_x`, `F_y` are
  the forces *on the car*, along and across the wheel heading. Steering angles are positive to
  the left.
- **Units.** SI inside components, angles in rad. Degrees appear only in docstrings, test names,
  plots and the FMVSS amplitude list.
- **Provenance tag on every default**, in its docstring: `(probe)`, `(derived)`, `(FMVSS 126)`,
  `(NHTSA)`, `(assumed)`, as in the constants table below.
- **No events.** Switching uses `ifelse`, `min`, `max`, as in `ABSController.dyad`.
- **Every component ships a `test component`** with a `"tests"` metadata block. Every
  `Lecture3` harness `X` gets an analysis `XTransient` extending `TransientAnalysis`, with every
  knob the notebook varies forwarded by a short name.
- **Four named wheel instances, not component arrays.** Arrays were not tried in the probe.
- **If a band fails, report the number.** Do not move a band. Do not tune a parameter outside its
  sourced range without saying so.
- US English in identifiers and docstrings. Comments state a constraint or a gotcha, never what
  the code says and never the history of the change.

## How testing works

Three layers, all run by `test/runtests.jl`.

| Layer | Where | What it asserts |
|---|---|---|
| Component regression | `"tests"` metadata on each `test component` → `generated/**/<Name>_test.jl` | `expect.initial` and `expect.final` values with a per-signal `atol`, and a trajectory snapshot for every name in `expect.signals` |
| Plausibility | new `test/esp_plausibility.jl`, included from `test/runtests.jl` after `plausibility_helpers.jl` | derived metrics (yaw-rate ratios, lateral displacement, wheel selection, slip bounds, closed-form comparisons) against the bands below |
| Visual | `notebooks/lecture03/03-esp.pluto.jl` (task 9) | what a number cannot show: trajectories, which wheel brakes, the spin |

**What a Dyad test checks, exactly.** For each case the generated code builds the model with the
case's `params`, runs `TransientAnalysis` with the case's `solver`, `stop`, `abstol` and `reltol`,
and then:

1. `@test successful_retcode(sol)`;
2. for each `expect.initial` / `expect.final` entry, `@test value ≈ expected atol=atol rtol=1e-5`,
   where `atol` comes from the case's `"atol"` map (default `1e-5`). So the `atol` you write is
   the tolerance. Write it deliberately;
3. for each name in `expect.signals`, a comparison against
   `test/snapshots/<module path>/<Component>_<case>_sig<i>.ref` at 100 evenly spaced times.
   **If the `.ref` file does not exist, the run writes it and passes.** A first run therefore
   proves nothing about trajectories. The `expect` values are the real assertions; the snapshots
   only catch later regressions. Commit the `.ref` files the first green run writes.

`DYAD_UPDATE_REFS=1` rewrites every reference. Use it only after naming the model change that
moved the curve (`docs/HANDOVER.md`).

Dyad tests can only see initial and final values. Anything that needs a value at an instant, a
peak, an integral or a ratio goes in `test/esp_plausibility.jl`, which runs the `Lecture3`
analyses through `VehicleSystemsComponents.Lecture3.<Name>Transient(; knobs...)` and reads
signals with `symbolic_container(result)`, as `test/roadster_plausibility.jl` does.

**Commands.**

| What | Command |
|---|---|
| Compile | `npx -y @juliacomputing/dyad-cli@3.4.0 compile .` from the repository root |
| One component's Dyad tests | `cd test && julia +dyad-3.4.0 --project=.. -e 'using VehicleSystemsComponents, Test; include("../generated/test_internals.jl"); @testset "one" begin include("../generated/Vehicle/Planar/TestPlanarWheelRig_test.jl") end'` |
| All planar Dyad tests | same, with `include("../generated/Vehicle/Planar/tests.jl")` (and `../generated/Lecture3/tests.jl`) |
| The plausibility file alone | `cd test && julia +dyad-3.4.0 --project=.. -e 'using VehicleSystemsComponents, Test; include("plausibility_helpers.jl"); include("esp_plausibility.jl")'` |
| Full suite | `cd test && julia +dyad-3.4.0 --project=.. runtests.jl` |

The single-component command was run in the Dyad probe against a scratch rig: 9 assertions, all
passing, 54 s including compilation. Run it from `test/` so references land in `test/snapshots/`.
After any `.dyad` edit, check the change appears in `generated/` before trusting a result. Record
the full suite's assertion count before task 0 and compare it after each task: it may only grow.

## Vehicle constants

One place for shared numbers. Each component repeats the defaults it uses, with the tag. These are
the research probe's values, because every simulated number in this brief comes from them
(decision D5).

| Name | Value | Tag / derivation |
|---|---|---|
| `m` | 1500 kg | (probe); NHTSA large-passenger class mean 1403 kg |
| `Iz` | 2500 kg·m² | (probe); class mean 2893 |
| `a`, `b` (CG to front, rear axle) | 1.2 m, 1.5 m | (probe); `L = a + b = 2.7 m` |
| `tw` (track) | 1.55 m | (probe) |
| `h_cg` | 0.55 m | (NHTSA) class 0.585 m; task 7 only |
| `radius` | 0.31 m | repository default |
| `J` (one wheel) | 1.0 kg·m² | (assumed); ABS note 1.1–1.6 |
| `g` | 9.81 m/s² | the probe's value; use it in every planar block so hand numbers match |
| `Nf`, `Nr` (static load per wheel) | 4087.5 N, 3270.0 N | (derived) `m g b/(2L)`, `m g a/(2L)` |
| `mu_A`, `mu_S` | 1.0, 0.8 | (probe) |
| `sAdhesion` front, rear | 0.12, 0.09 | (probe), research §2 |
| `sSlide` | `3·sAdhesion` | (probe) |
| `vAdhesion_min`, `vSlide_min` | 0.05, 0.15 m/s | (probe) `TwoTrackModelTest` values |
| `C_alpha` per tire, front / rear | 51.1 / 54.5 kN/rad | (derived) `1.5 mu_A N / sAdhesion`. The research's §6 table says 61/49; that is a slip of the pen, its own K_us uses the right values |
| `K_us` | 2.0387e-3 rad/(m/s²) = 1.15° of road-wheel angle per g | (derived) `m/L (b/Cf − a/Cr)` with axle stiffnesses `Cf = 102.2`, `Cr = 109.0 kN/rad` |
| characteristic speed | 36.4 m/s (131 km/h) | (derived) `sqrt(L/K_us)` |
| `i_s` steering ratio | 16 | (assumed), research §6 |
| `v0` | 80/3.6 = 22.222 m/s | (FMVSS 126) |
| `r/δ` at `v0` | 5.995 1/s | (derived) `v0/(L + K_us v0²)`; neutral steer would give 8.23 |
| `T_brake` | 0.03 s | `BrakeActuator` default (hydraulic lag) |
| `tau_max` per wheel | 2500 N·m | (assumed) research §6 |
| `w0` brake regularization | 1.0 rad/s | `BrakeActuator` default |
| ESP `Kp`, dead-band | 40 000 N·m per rad/s, 0.03 rad/s | (probe) |
| ESP `Ki` | 0 in task 5; 100 000 N·m/rad from task 6 | (probe, this brief) needed for split-µ |
| ESP build lag `T_build` | 0.1 s | (assumed) research §6 |
| ESP `k_lim`, `mu_est`, `v_on` | 0.85, 1.0, 5.0 m/s | Rajamani via research §3; FMVSS requires ESC above 20 km/h |

## Bill of materials

### Reused, unchanged

| Part | Used as | Notes |
|---|---|---|
| `MultibodyComponents.PlanarMechanics.World(g = 0)` | world | omit in models with no `Body` |
| `PlanarMechanics.Body(m, I, render = false, linearStatePriority = 2)` | chassis | `body.v`, `body.a`, `body.w`, `body.phi` are in world axes; resolve to body axes yourself |
| `PlanarMechanics.FixedTranslation(r = [..])` | CG → axle, axle → wheel arms | six instances |
| `PlanarMechanics.Revolute()` + `RotationalComponents.Sources.Position()` + `RotationalComponents.Components.Fixed()` | steered front wheels | parallel steer, no Ackermann. `Position`'s default filtered reference adds two states each; set `initial pos.w = 0` |
| `PlanarMechanics.SlipBasedWheelJoint` | tire | inside `PlanarBrakedWheel` only |
| `PlanarMechanics.PrescribedVelocity()` | single-wheel rig | `fixed_orientation = true` (default) |
| `RotationalComponents.Components.Inertia`, `Fixed` | wheel spin | |
| `Vehicle.Wheel.BrakeActuator` | wheel brake | its `spline_a`/`spline_b` match the joint's `flange_a`. Confirmed in the Dyad probe |
| `Vehicle.ABSModulatorDiscrete` | per-wheel slip limiter | takes slip directly, so the wheel-only reference-speed estimator is bypassed (research §3) |
| `DiscreteComponents.PeriodicClock`, `Sampler`, `ZeroOrderHold` | ABS and clocked ESP | as in `ABSBrakeTest` |
| `BlockComponents.Sources.Ramp`, `Step`, `Constant` | steering ramp, brake demand | |
| `Lecture1.MeasurementNoise` | sensor noise (task 8) | read it first; reuse if its interface fits |

### New components

Interfaces are specified to the connector. Parameter defaults are from the constants table.

**`Vehicle.Planar.PlanarBrakedWheel`** (task 1). One wheel: contact, spin inertia, brake.

    frame_a  = Frame2D()        # wheel center; attach to an arm or a steering revolute
    tau_cmd  = RealInput()      # requested brake torque, >= 0
    dN       = RealInput()      # dynamic normal-load change, N (0 until task 7)
    kappa    = RealOutput()     # (radius*omega - v_long) / max(|v_long|, v_eps); negative braking
    alpha    = RealOutput()     # atan(v_lat / max(|v_long|, v_eps)); positive when the patch moves left
    omega    = RealOutput()     # wheel spin, rad/s
    variables F_x = -joint.f_long, F_y = -joint.f_lat, F_z = max(0, N + dN)
    parameters radius, J, N (no default; required), mu_A, mu_S, mu_scale = 1, sAdhesion = 0.12,
               sSlide = 3*sAdhesion, vAdhesion_min = 0.05, vSlide_min = 0.15,
               T_brake = 0.03, tau_max = 2500, w0 = 1.0, v_eps = 0.5
    inside: joint(mu_A = mu_scale*mu_A, mu_S = mu_scale*mu_S, r = [1, 0], render = false)
            joint.flange_a -> inertia.spline_a; inertia.spline_b -> brake.spline_a;
            brake.support -> Fixed; joint.dynamicLoad = dN

`joint.f_long` and `joint.f_lat` carry the sign of the slip velocity; the force on the car is
their negative. `mu_scale` is a parameter, so split-µ is a per-wheel parameter, which is all the
split-µ test needs.

**`Vehicle.Planar.PlanarCar`** (task 2). The chassis, four wheels, steering, and body-frame
signals.

    delta_sw  = RealInput()                       # steering-wheel angle, rad (decision D4)
    tau_fl, tau_fr, tau_rl, tau_rr = RealInput()  # brake commands
    vx, vy, r, beta, ax, ay, psi, x, y = RealOutput()   # body frame; beta = atan(vy / max(vx, 1))
    kappa_fl ... kappa_rr, omega_fl ... omega_rr = RealOutput()
    variable delta (road-wheel angle) = delta_sw / i_s
    parameters m, Iz, a, b, tw, radius, J, mu_A, mu_S, sAdhesion_f, sAdhesion_r,
               mu_scale_fl ... mu_scale_rr, T_brake, tau_max, i_s, v0
    (task 7 adds h_cg = 0.0 and a LoadTransfer block)

`ax`, `ay` are `body.a` resolved into body axes. Static loads `Nf`, `Nr` are computed from `m`,
`a`, `b`, `g` inside, so changing the CG moves them. Until task 7 each wheel's `dN` is 0. The
initial conditions in § Ground rules belong in the harness, with `v0` forwarded; put them in
the car only if Dyad lets a harness override them.

**`Vehicle.Planar.SineWithDwell`** (task 4). Output `y`, a steering-wheel angle. Parameters `A`
(rad), `f = 0.7` Hz, `t0 = 1.0` s, `T_dwell = 0.5` s, `sign = 1`. The Appendix source of the
research is correct; add `T_dwell` and `sign`.

    tau = time - t0
    y = sign * ( 0                              for tau < 0
                 A sin(2π f tau)                for tau < 0.75/f
                 -A                             for tau < 0.75/f + T_dwell
                 A sin(2π f (tau - T_dwell))    for tau < 1/f + T_dwell
                 0 )

**`Vehicle.Planar.YawReference`** (task 5). Inputs `delta_sw`, `vx`; output `r_ref`. Parameters
`L`, `K_us`, `i_s`, `mu_est`, `g`, `k_lim = 0.85`, `v_floor = 1.0`.

    r_nom = vx * (delta_sw / i_s) / (L + K_us * vx^2)
    r_ref = clamp(r_nom, -k_lim*mu_est*g / max(vx, v_floor), +k_lim*mu_est*g / max(vx, v_floor))

**`Vehicle.Planar.YawMomentController`** (task 5). Inputs `r`, `r_ref`, `vx`; outputs `Mz`
(requested yaw moment, N·m) and `oversteer` (1.0 when `|r| > |r_ref|`, else 0.0). Parameters
`Kp`, `Ki = 0`, `deadband = 0.03`, `v_on = 5.0`, `Mz_max = 10000`.

    e  = r - r_ref
    der(e_int) = e                      # initial e_int = 0
    Mz_raw = -Kp * (|e| > deadband ? e - deadband*sign(e) : 0) - Ki * e_int
    Mz = vx > v_on ? clamp(Mz_raw, -Mz_max, Mz_max) : 0

The integral runs always; the MTK probe passed sine-with-dwell with it on (§ Probe evidence).

**`Vehicle.Planar.BrakeAllocator`** (task 5). Inputs `Mz`, `oversteer`; outputs `dT_fl`, `dT_fr`,
`dT_rl`, `dT_rr` (signed, N·m). Parameters `tw`, `radius`, `T_max = 2500`, `T_build = 0.1`.

    T   = min(|Mz| * radius / (tw/2), T_max)
    side = Mz > 0 ? left : right                 # braking the left side turns the car left
    axle = oversteer > 0.5 ? front : rear        # outer front on oversteer, inner rear on understeer
    request on the chosen axle: +T on `side`, -T on the other wheel of that axle; 0 on the other axle
    dT_i = first-order lag of the request with T_build      # active pressure build-up

A positive `dT` adds brake demand. A negative `dT` asks to *remove* torque that the driver or ABS
is applying; it only matters while the driver brakes (split-µ, task 6). In task 5 the harness
applies `max(0, dT_i)`. The lever arm of a steered front wheel changes with δ; ignore it, as the
probe does (fine below δ ≈ 0.1 rad).

**`Vehicle.Planar.ESPController`** (task 5). Composition of the three blocks above. Inputs
`delta_sw`, `r`, `vx`; outputs `dT_fl ... dT_rr`, plus `Mz`, `r_ref`, `oversteer` as variables
for plots. Every parameter forwarded by its short name.

**`Vehicle.Planar.BrakeChannel@[input clk extends Discrete]`** (task 6). One wheel's ABS
channel. Clocked inputs `demand` (driver), `dT`, `kappa`, `v_ref`; clocked output `tau_cmd`.

    modulator = Vehicle.ABSModulatorDiscrete(dt, lambda_1, ...)   # every parameter forwarded
    modulator.demand = demand + max(dT, 0)
    tau_cmd = max(modulator.tau_cmd - max(-dT, 0), 0)            # ESP cut acts after ABS

The cut is applied after the modulator on purpose: when the driver demand is far above the
friction limit, subtracting from the *demand* changes nothing the wheel sees.

**`Vehicle.Planar.FourChannelABS@[input clk extends Discrete]`** (task 6). Four `BrakeChannel`s.
Clocked inputs `demand`, `v_ref`, `dT_fl ... dT_rr`, `kappa_fl ... kappa_rr`; clocked outputs
`tau_fl ... tau_rr`. Parameters `lambda_1_f = 0.08`, `lambda_1_r = 0.06`, `select_low = 1.0`
(rear wheels both get `min(tau_rl, tau_rr)` when 1), and the modulator rates. The harness samples
the inputs and holds the outputs, as `ABSBrakeTest` does.

**`Vehicle.Planar.LoadTransfer`** (task 7). Inputs `ax`, `ay`; outputs `dN_fl ... dN_rr`.
Parameters `m`, `h`, `L`, `a`, `b`, `tw`, `T_lt = 0.05`.

    axf, ayf = first-order lags of ax, ay with T_lt     # initial 0
    d_long = -m * axf * h / (2L)                        # braking (ax < 0) loads the front
    dN_fl = d_long - m*ayf*h*(b/L)/tw;   dN_fr = d_long + m*ayf*h*(b/L)/tw
    dN_rl = -d_long - m*ayf*h*(a/L)/tw;  dN_rr = -d_long + m*ayf*h*(a/L)/tw

The lateral split by static-load share is an assumption (research §1). The four sum to zero.

**`Vehicle.Planar.ESPControllerDiscrete@[input clk extends Discrete]`** and sensor blocks
(task 8): specified in task 8.

**Harnesses in `Lecture3/`**: `PlanarOpenLoop` (tasks 2–3), `SineWithDwellRun` (task 4),
`ESPSineWithDwell` (tasks 5–7), `ESPSteerRamp` (task 5), `ABSStraightStop` and `SplitMuStop`
(task 6), `ClockedESPSineWithDwell` (task 8). Each has an analysis `<Name>Transient`.

## Task 0 — Dependency

**Goal.** `MultibodyComponents` is a dependency, and nothing else moves.

**Files.** `Project.toml` (`[deps]` and `[compat]`). Nothing else.

**Do.** Before anything, run the full suite and record the assertion count. Then
`julia +dyad-3.4.0 --project=. -e 'using Pkg; Pkg.add(name = "MultibodyComponents", version = "0.2.6", preserve = Pkg.PRESERVE_ALL)'`.
Add `MultibodyComponents = "=0.2.6"` to `[compat]`, pinned like the other component libraries.
Recompile with dyad-cli 3.4.0.

**Tests.** None new. The existing suite is the test.

**Done when.**
- The resolve changed no existing package version (the research's scratch resolve added 0.2.6
  and about 11 transitive packages and changed nothing else).
- Recompiling leaves `git status` clean apart from `Project.toml`.
- The full suite passes with the same assertion count as before.
- `using MultibodyComponents` loads in the project environment.

**Failure looks like** a version change in the resolve output, or a compiler error in a library
that compiled before. Stop and report; do not loosen another pin to make room.

**Physical sanity.** Not applicable.

**Size.** S, under half a day.

## Task 1 — `PlanarBrakedWheel` and the single-wheel rig

**Goal.** One wheel whose forces match the triple-S curve exactly, whose slip outputs carry the
repository's sign convention, and whose locked state loses lateral force.

**Files.** `dyad/Vehicle/Planar/PlanarBrakedWheel.dyad` with the component and
`test component TestPlanarWheelRig`.

**Rig.** No `World`, no `Body`. A `PrescribedVelocity` drives the wheel center at
`[v, vy]` from two `Constant`s, orientation fixed at 0, so the slip angle is `atan(vy/v)`.
`Constant`s drive `tau_cmd` and `dN`. Parameters `v = 20`, `vy`, `tau`, `dN` forwarded.
Wheel: `N = 4000`, `sAdhesion = 0.12`, `sSlide = 0.36`, `mu_A = 1`, `mu_S = 0.8`, `J = 1`,
`tau_max = 10000`. `initial wheel.inertia.w = (v + 0.01)/0.31`, `inertia.phi = 0`,
`brake.tau_actual = 0`. Stop at 1 s, solver `Tsit5`.

**Tests** (hand: the triple-S formula with `x = v_slip/(sAdhesion·r·ω)`; the free-rolling cases
are exact apart from the joint's +1e-4 m/s regularization; the braked cases solve
`F_x·radius = tau` on the stable branch).

| case | `vy` | `tau` | `dN` | expect final | atol |
|---|---|---|---|---|---|
| `straight` | 0 | 0 | 0 | `F_y = 0`, `F_x = 0`, `kappa = 0` | 1 N, 1 N, 1e-4 |
| `half_peak` | 1.2 | 0 | 0 | `F_y = -2750.0`, `alpha = 0.05993` | 5 N, 1e-4 |
| `peak` | 2.4 | 0 | 0 | `F_y = -3999.8` | 5 N |
| `sliding` | 7.2 | 0 | 0 | `F_y = -3200.0` (= µ_S N) | 5 N |
| `braking` | 0 | 1000 | 0 | `F_x = -3225.8` (= tau/radius), `kappa = -0.0688` | 5 N, 0.002 |
| `braking_cornering` | 1.2 | 1000 | 0 | `F_x = -3225.8`, `F_y = -2321.3`, `kappa = -0.0834` | 5 N, 5 N, 0.002 |
| `locked` | 2.4 | 10000 | 0 | `F_x = -3177.2`, `F_y = -381.3`, `kappa = -1` | 5 N, 5 N, 0.003 |
| `unloaded` | 1.2 | 0 | -2000 | `F_y = -1375.0` | 5 N |
| `lifted` | 1.2 | 0 | -5000 | `F_y = 0`, `F_z = 0` | 1 N |

The `half_peak`, `locked` and solver rows were run in the Dyad probe and pass exactly as written
(with `Tsit5` and `Rodas5P`). The other rows are hand values from the same formula, **not
simulated**.

**Done when** every case passes, and the solver is `Tsit5`.

**Failure looks like:**
- `F_y` with the wrong sign: `F_y`/`F_x` were taken from the joint without negation.
- `kappa` near +0.07 when braking: the slip sign is reversed.
- an "`Initial` parameter ... `g`" error: a `World` was left in the rig.
- `braking` lands on `kappa ≈ -1`: the wheel ran past the peak because `tau` exceeded
  `µ_A N radius` = 1240 N·m, or the brake sign is wrong.

**Physical sanity.** The `locked` case is the reason ABS exists: at the same 6.8° slip angle the
free wheel gives 4000 N of side force and the locked wheel 381 N. `braking_cornering` shows the
friction circle: `hypot(F_x, F_y) = 3974 N ≤ µ_A N`, and braking cost 16 % of the side force.
Put both comparisons in `test/esp_plausibility.jl` as ratios.

**Size.** S, one day.

## Task 2 — `PlanarCar`, coasting and straight braking

**Goal.** The four-wheel car initializes at 80 km/h, goes straight when nothing acts on it, and
brakes with the deceleration a lumped model predicts.

**Files.** `dyad/Vehicle/Planar/PlanarCar.dyad`; `dyad/Lecture3/PlanarOpenLoop.dyad` with the
harness and `PlanarOpenLoopTransient`.

**Harness.** `PlanarCar`; steering from a `Ramp` (`height = delta_sw_final`, `duration =
t_ramp`, `start_time = t_steer`); one brake `Step` (`height = T_cmd`, `start_time = 0.5`) feeding
the wheels selected by four 0/1 parameters `brake_fl ... brake_rr`. Forward `v0`,
`delta_sw_final`, `t_ramp`, `t_steer`, `T_cmd`, the four selectors and every `mu_scale`.

**Tests.**

| case | setup | expect final | atol | source |
|---|---|---|---|---|
| `coast` | no steer, no brake, stop 5 | `vx = 22.222492`, `r = 0`, `vy = 0`, `y = 0` | 1e-4, 1e-8, 1e-8, 1e-6 | hand, MTK probe exact |
| `straight_brake` | `T_cmd = 500` on all four, stop 3 | `vx = 11.895`, `r = 0`, `kappa_fl = -0.0305`, `kappa_rl = -0.0291` | 0.02, 1e-6, 0.002, 0.002 | MTK probe; hand below |

`coast`: with no other longitudinal force, `m·vx + Σ J·ω/radius` is conserved. The wheels start
0.01 m/s fast, so the final speed is
`(m v0 + 4 J (v0 + 0.01)/radius²) / (m + 4 J/radius²) = 22.222492` m/s. The MTK probe gives
22.222492, and |r|, |vy| below 1e-15.

`straight_brake`: the effective mass is `m + 4J/radius² = 1541.6` kg, so
`ax = -4·500/(0.31·1541.6) = -4.185` m/s². Probe: −4.188 at 2.0 s (0.08 % from slip). Per
wheel `F = (500 − J·ax/radius)/0.31 = 1569` N, µ used 0.384 front and 0.480 rear, so on the
triple-S `kappa = -x·sA/(1 + x·sA)` = −0.030 front and −0.029 rear. Probe: −0.0305, −0.0291.

**Plausibility** (in `test/esp_plausibility.jl`): `ax` at 2.0 s within 1 % of −4.185; yaw rate
below 1e-6 throughout both cases; with only `fr` and `rr` braked, `psi` at 3 s is negative (the
car turns right; research §3 sign check).

**Done when** both cases and the three plausibility checks pass with `Tsit5`, and initialization
prints no "underdetermined" warning.

**Failure looks like:** an `Unstable` return at t = 0 (exact rolling speed, or an implicit
solver); a yaw drift in `coast` (the arms are not symmetric, or `tw/2` has the wrong sign on one
side); a `straight_brake` speed too high by about 3 % (the wheel inertias were left out of the
hand number, not the model).

**Physical sanity.** Coasting goes straight for ever; braking one side turns the car toward the
braked side.

**Size.** S–M, one day.

## Task 3 — Steady-state cornering against the bicycle model

**Goal.** The passive car's yaw rate matches `r = vx·δ/(L + K_us·vx²)` in the linear range, and
lateral acceleration never exceeds µ·g.

**Files.** Test cases on `PlanarOpenLoop` (no new component).

**Tests.** Constant road-wheel angle reached by a 0.2 s ramp from t = 0, read at 4 s, no
brake. The car slows in a turn (the steered wheels' side force has a rearward component), so
compare with the formula at the *instantaneous* `vx`.

| case | δ (rad) | `delta_sw_final` (rad) | expect final `r` | expect final `vx` | atol | formula `r` at that `vx` |
|---|---|---|---|---|---|---|
| `steady_1` | 0.005 | 0.08 | 0.02996 | 22.211 | 3e-4, 0.02 | 0.02997 |
| `steady_2` | 0.010 | 0.16 | 0.05985 | 22.177 | 6e-4, 0.02 | 0.05989 |
| `steady_3` | 0.020 | 0.32 | 0.11908 | 22.040 | 1.2e-3, 0.02 | 0.11945 |
| `steady_4` | 0.030 | 0.48 | 0.17709 | 21.814 | 1.8e-3, 0.02 | 0.17831 |
| `steer_ramp` | SWA ramp 13.5°/s from 0.5 s, stop 8 | — | — | — | (plausibility only) | — |

Expected values are the MTK probe's. The `r` tolerance is 1 % of the value; the probe differs from
the formula by 0.02 % at 0.07 g and 0.68 % at 0.39 g, the growth being the cubic term of the
triple-S.

**Plausibility.**
- `|r/r_formula − 1| < 2 %` in all four cases.
- The understeer gradient recovered from the runs, `K_fit = (vx·δ/r − L)/vx²`, is within 10 % of
  2.039e-3 for `steady_1` and `steady_2` (probe: 2.041e-3).
- Sideslip in `steady_4`: hand `β = (b − a·m·vx²/(L·Cr))·r/vx = −0.71°`; probe −0.69°. Assert
  −0.69° ± 0.05°.
- `steer_ramp`: the steering-wheel angle at which `vx·r` first reaches 0.3 g is the FMVSS
  amplitude `A`. Probe: **A = 21.6°** at 2.10 s. The linear formula gives 20.25°; the ramp reads
  higher because yaw lags the steering. Assert 21.6° ± 1°, and use the measured A in task 4.
- `steer_ramp`: `max(vx·r) ≤ 1.01·µ_A·g`. Probe: 0.995 g.

**Done when** the four cases and the plausibility checks pass.

**Failure looks like:** `r` above the formula at every δ, close to `vx·δ/L` (both axles got the
same `sAdhesion`, which is exactly neutral steer); positive β at speed (a lateral sign error);
`vx·r` above 1.01 g (a `mu_scale` applied twice, or `N` doubled).

**Physical sanity.** The car understeers: `r/δ` = 5.99 1/s at 80 km/h against 8.23 for neutral
steer. It cannot corner harder than the tires allow.

**Size.** S, half a day.

## Task 4 — Sine-with-dwell harness and metrics (passive car)

**Goal.** The FMVSS 126 maneuver and its three pass criteria, computed by one Julia function that
tests and the notebook share. The passive car spins at some amplitudes and not at others.

**Files.** `dyad/Vehicle/Planar/SineWithDwell.dyad` (component and a test component);
`dyad/Vehicle/Planar/module.jl`; `dyad/Lecture3/SineWithDwellRun.dyad` with
`SineWithDwellRunTransient` (`stop = 6.0`, `Tsit5`, `dtmax = 0.005`, forwarded `A_sw`, `v0`).

**Metric function.** In `module.jl`:

    fmvss126_metrics(t, swa, r, y; A, f = 0.7, t0 = 1.0, T_dwell = 0.5)
        -> (; t_bos, t_cos, r_peak, yrr_1_00, yrr_1_75, y_bos_1_07, passes_stability, passes_responsiveness)

- BOS: the first time `|swa|` reaches 5°, interpolated.
- COS: `t0 + 1/f + T_dwell` = 2.9286 s for the defaults (the steering returns to zero).
- `r_peak`: the first local yaw-rate peak after the steering changes sign (S7.11.8): the extremum
  of `r` between `t0 + 0.5/f` and COS.
- `yrr_1_00 = r(t_cos + 1.0)/r_peak`, `yrr_1_75 = r(t_cos + 1.75)/r_peak`, by interpolation.
- `y_bos_1_07 = y(t_bos + 1.07)`, the lateral displacement of the CG in the initial heading.
- `passes_stability`: `yrr_1_00 ≤ 0.35` and `yrr_1_75 ≤ 0.20`. `passes_responsiveness`:
  `y_bos_1_07 ≥ 1.83` m, required only for `A_sw ≥ 5A`.

It takes plain vectors, so a test can feed it synthetic signals. Unit-test it in
`test/esp_plausibility.jl` on a hand-made `r(t)` whose ratios are known (for example a decaying
exponential with a set value at COS + 1.0 s), and check COS = 2.9286 s.

**`SineWithDwell` tests.** `A = 1`: final 0 at 4 s; value −1 during the dwell (a case stopping at
`t0 + 0.75/f + 0.25` = 2.321 s); value 0 at COS (stop at 2.9286 s, atol 1e-6).

**Amplitudes.** With A = 21.6° (task 3): 1.5A = 32°, 2.5A = 54°, 3.5A = 76°, 4.5A = 97°,
5.5A = 119°, 6.5A = 140°, then on to 270° (6.5A is below 270°, so the series continues).

**Expected results** (MTK probe, the task 3 car, no brake lag):

| SWA | YRR@1.0 | YRR@1.75 | y(BOS+1.07) | β_max | end speed | verdict |
|---|---|---|---|---|---|---|
| 32° | 0.00 | 0.00 | 1.15 m | 0.9° | 22.1 | pass |
| 76° | 0.00 | 0.00 | 2.52 m | 3.1° | 21.3 | pass |
| 97° | 1.39 | 1.39 | 3.08 m | 84° | −3.8 | **spins** |
| 140° | 1.01 | 1.01 | 3.68 m | 83° | −2.5 | **spins** |
| 180° | 0.91 | 0.91 | 3.73 m | 82° | −1.4 | **spins** |
| 220° | 0.87 | 0.87 | 3.62 m | 62° | 2.2 | **spins** |
| 270° | 0.00 | 0.00 | 3.44 m | 5.4° | 19.7 | plows, passes |

**Tests.** Dyad cases on `SineWithDwellRun` at 32° and 270° only (the two non-spinning ends),
`expect.final` on `vx` (atol 0.1) and `psi` (atol 0.02). Do not pin final values of a spinning
run: they are sensitive to everything. Plausibility, using `fmvss126_metrics`:
- 32°, 76°, 270°: `passes_stability`; YRR within ±0.05 of the table, `y_bos_1_07` within ±0.1 m.
- 97°, 140°, 180°: not `passes_stability`, and `β_max > 45°`.
- 270°: `β_max < 10°` (it plows; real test data show the same non-monotonic pattern).

**Done when** all of the above pass.

**Failure looks like:** the car never spins (check the solver is not FBDF and `dtmax` is set;
the research saw FBDF return `Success` with no response to the steering); the car spins already
at 32° (the rear `sAdhesion` is the front's, or `Iz` is off by 10×); YRR near 1 everywhere (the
peak window is wrong).

**Physical sanity.** An uncontrolled car spins in the middle amplitudes and plows at the largest.

**Size.** M, one day.

## Task 5 — Continuous ESP

**Goal.** A yaw-rate ESP that brakes the outer front wheel on oversteer and the inner rear wheel
on understeer, and passes FMVSS 126 at every amplitude.

**Files.** `dyad/Vehicle/Planar/YawReference.dyad`, `YawMomentController.dyad`,
`BrakeAllocator.dyad`, `ESPController.dyad`, each with a test component;
`dyad/Lecture3/ESPSineWithDwell.dyad` (forward `A_sw`, `esp_on` 0/1 multiplying the brake
request, `Kp`, `Ki`, `T_build`) and `dyad/Lecture3/ESPSteerRamp.dyad` (the task 3 ramp with ESP,
forward `mu_scale_front`). The harnesses apply `tau_i = esp_on · max(0, dT_i)`.

**Block tests** (hand, static inputs from `Constant`s, read at 1 s so the 0.1 s lag has settled):

| block | inputs | expect | atol |
|---|---|---|---|
| `YawReference` | `vx = 22.222`, `delta_sw = 0.32` (δ = 0.02) | `r_ref = 0.119900` | 1e-5 |
| `YawReference` | `vx = 22.222`, `delta_sw = 1.6` (δ = 0.1, r_nom 0.599) | `r_ref = 0.375233` (= 0.85·9.81/22.222) | 1e-5 |
| `YawMomentController` | `r = 0.30`, `r_ref = 0.20`, `vx = 20` | `Mz = -2800`, `oversteer = 1` | 1e-6 |
| `YawMomentController` | `r = 0.21`, `r_ref = 0.20` | `Mz = 0` (dead-band) | 1e-9 |
| `YawMomentController` | `r = 0.30`, `r_ref = 0.20`, `vx = 4` | `Mz = 0` (below `v_on`) | 1e-9 |
| `BrakeAllocator` | `Mz = -2800`, `oversteer = 1` | `dT_fr = 1120`, `dT_fl = -1120`, rear 0 | 1 |
| `BrakeAllocator` | `Mz = +2800`, `oversteer = 0` | `dT_rl = 1120`, `dT_rr = -1120`, front 0 | 1 |
| `BrakeAllocator` | `Mz = -20000`, `oversteer = 1` | `dT_fr = 2500` (cap) | 1 |

`1120 = 2800·0.31/0.775`.

**Expected results** (MTK probe, P controller, 0.1 s lag on the applied torque, no slip limit):

| SWA | YRR@1.0 | YRR@1.75 | y(BOS+1.07) | β_max | end speed | min κ |
|---|---|---|---|---|---|---|
| 32° | 0.00 | 0.00 | 1.19 m | 0.8° | 21.4 | −0.03 |
| 97° | 0.00 | 0.00 | 2.42 m | 6.1° | 14.8 | −1.00 |
| 140° | 0.00 | 0.00 | 2.56 m | 6.4° | 13.9 | −1.00 |
| 180° | 0.00 | 0.00 | 2.63 m | 6.8° | 13.5 | −1.00 |
| 270° | 0.00 | 0.00 | 2.66 m | 6.9° | 13.2 | −1.00 |

Here the lag sits in the allocator and the wheel adds its own 0.03 s, so expect small
differences; the bands below allow for them.

**Plausibility** on `ESPSineWithDwell`, the seven amplitudes of task 4:
- `esp_on = 1`: `passes_stability` at every amplitude; `y_bos_1_07 ≥ 1.83` m at every amplitude
  ≥ 5A (108°), expected 2.4–2.7 m; `β_max < 10°`.
- `esp_on = 0` reproduces task 4's metrics within 1e-6 (the ESP adds nothing when off).
- **Wheel selection, oversteer.** At 180°, between the steering reversal and 1.5 s after COS,
  the left front wheel (outer in the right turn that follows the reversal) has the largest
  `∫ tau dt` of the four.
- **Wheel selection, understeer.** `ESPSteerRamp` with `mu_scale_front = 0.7`: only `rl` (inner
  rear in a left turn) is braked. MTK probe: `∫ tau dt` = [0, 0, 3054, 0] N·m·s for fl, fr, rl,
  rr; the yaw-rate shortfall `min(r − r_ref)` halves, from −0.145 to −0.071 rad/s. Assert
  `∫ tau_rl dt > 10 ×` each other wheel, and the shortfall at least 30 % smaller than with
  `esp_on = 0`.
- Known flaw, asserted so it is visible: end speed at ≥ 97° is 12–16 m/s and the braked wheel
  locks (`min κ < -0.9`). Task 6 removes both.

**Done when** all of the above pass.

**Failure looks like:** ESP makes the spin worse (the allocation side is mirrored: braking the
left side must turn the car left); the car still spins at 97° (a `T_build` far above 0.1 s, or
`Kp` in the wrong units); a solver stall on the `ifelse` switching (add `dtmax = 0.005`; do not
switch to FBDF).

**Physical sanity.** The passive car spins at 97°; with ESP it does not, and the brake goes to
the outer front wheel.

**Size.** M, 1–1½ days.

## Task 6 — Four ABS channels, ESP through them, split-µ

**Goal.** ESP braking stays inside the stable slip range because it goes through the wheel's ABS
channel, and a split-µ stop shows both ABS's limit and ESP's fix.

**Files.** `dyad/Vehicle/Planar/BrakeChannel.dyad`, `FourChannelABS.dyad` (test components with
a single wheel are enough for the channel); `dyad/Lecture3/ABSStraightStop.dyad`,
`dyad/Lecture3/SplitMuStop.dyad`, and an `abs_on` path in `ESPSineWithDwell` (forward `abs_on`,
`Ki`, `select_low`, `mu_scale_right`, `T_cmd`). One `PeriodicClock(dt = 0.005)`; samplers on
`delta`-independent inputs (driver demand, `vx` as `v_ref`, the four `kappa`, the four `dT`);
four `ZeroOrderHold`s into the car. Read held signals in tests, never clocked ones (HANDOVER).

**ABS thresholds.** `ABSModulatorDiscrete` defaults to `lambda_1 = 0.04`, the 1D tire's peak.
This tire's longitudinal peak, normalized as `kappa`, is `sA/(1 + sA)` = 0.107 front and 0.083
rear, so 0.04 would release far below the peak. Use `lambda_1` = 0.08 front, 0.06 rear (about
75 % of peak). The modulator's rates were tuned for one lumped wheel with `J_w = 4`; this wheel
has `J = 1`. Scaling `k_dec`, `k_inc_fast`, `k_inc_slow` by 1/4 is the first thing to try, and
must be reported.

**Expected results.**

*Sine-with-dwell, ESP through ideal slip limiting* (MTK probe, continuous slip limiter at
κ = −0.08, P controller):

| SWA | YRR@1.0 | YRR@1.75 | y(BOS+1.07) | β_max | end speed | min κ |
|---|---|---|---|---|---|---|
| 97° | 0.00 | 0.00 | 2.79 m | 2.0° | 18.4 | −0.075 |
| 140° | 0.00 | 0.00 | 3.15 m | 2.3° | 18.0 | −0.081 |
| 180° | 0.00 | 0.00 | 3.28 m | 2.4° | 18.0 | −0.086 |
| 270° | 0.00 | 0.00 | 3.24 m | 2.6° | 17.6 | −0.098 |

With the integral term on (`Ki = 1e5`): YRR 0.01–0.02 at 1.0 s, end speed 16.3–17.4, still a
pass at 97°, 180° and 270°.

*Straight ABS stop, µ = 1* (Dyad probe: four `ABSModulatorDiscrete` channels with ideal
sensing, default rates, `lambda_1` 0.08/0.06, driver demand 2500 N·m per wheel at 0.5 s):
braking distance 37.6 m from 80 km/h, a mean of 0.67 g, with front κ held at −0.078 and rear at
−0.060. Locked-wheel-free ideal: `v0²/(2 µ_A g)` = 25.2 m. The 37.6 m is with untuned rates.

*Split-µ, µ = 1.0 left / 0.3 right, 2500 N·m demand per wheel at 0.5 s* (MTK probe, ideal slip
limiter, heading read when `vx` falls below 3 m/s or at 6 s):

| configuration | heading | lateral offset | distance | stopped by 6 s |
|---|---|---|---|---|
| ABS only | 106° (spins left) | 9.8 m | 54 m | yes |
| ABS + rear select-low | 19° | 7.7 m | 68 m | yes |
| + ESP, P, single-wheel add only | 106° | 9.9 m | 54 m | yes: adding brake to an ABS-limited wheel does nothing |
| + ESP PI (`Ki = 1e5`), differential allocation, cut after ABS | 3.1° | 3.4 m | 88 m | no, 6.4 m/s left |

The Dyad probe's ABS-only split-µ run (default rates, no select-low) turned 33° by 4 s; the
two ABS models differ, so only the ordering is a band.

**Tests and plausibility.**
- `ABSStraightStop`: braking distance (from 0.5 s to `vx < 0.5`) ≤ 32 m, i.e. a mean of at
  least 0.8 g. **Not yet reached** in the probe (37.6 m with untuned rates); this is the tuning
  target of the task. Report the best distance and the rates. Also: every κ ≥ −0.2 while
  `vx > 3` m/s, and zero yaw.
- `ESPSineWithDwell` with `abs_on = 1`, `Ki = 1e5`, at 32°, 97°, 140°, 180°, 270°:
  `passes_stability`; `y_bos_1_07 ≥ 1.83` m at ≥ 108°; every κ ≥ −0.2 while `vx > 3`; end speed
  at least 2 m/s higher than task 5's at the same amplitude.
- `SplitMuStop`: ABS-only turns toward the high-µ side (`psi > 0`) by more than 15°;
  select-low reduces `|psi|`; ESP PI with differential allocation keeps `|psi| < 5°` (probe
  3.1°) and stops later than select-low alone.
- Dyad cases: `ABSStraightStop` final `x` and `vx` (atol 0.5 m, 0.05), recorded after tuning.

**Done when** every item passes, or the braking distance misses only after a reported rate
retune.

**Failure looks like:** ABS chattering at every tick (`lambda_1` left at 0.04, or rates four
times too fast for `J = 1`); the ESP request vanishing under ABS (the demand was not added before
the modulator); split-µ ESP having no effect (the cut was subtracted from the demand instead of
from the modulator output).

**Physical sanity.** ESP still prevents the spin, but no wheel locks and the car keeps more of
its speed. On split-µ the car pulls toward the high-µ side, and holding the heading costs
stopping distance — the trade every ESP calibration makes.

**Size.** M–L, 2 days. The rate retune is the uncertain part.

Decision dependencies: D2 (a retuned `TireFrictionCurve` changes `lambda_1` and the 1D ABS
numbers), D6.

## Task 7 — Quasi-static load transfer

**Goal.** Wheel loads follow the body's accelerations, and the earlier results stay valid.

**Files.** `dyad/Vehicle/Planar/LoadTransfer.dyad` with a test component; `PlanarCar` gains
`h_cg` (default **0.0**) and feeds each wheel's `dN` from a `LoadTransfer`. `Lecture3` analyses
forward `h_cg`; the lecture's runs use 0.55.

The default of 0.0 keeps tasks 2–6 bit-for-bit: with `h = 0` every `dN` is 0. That is the
regression test.

**Tests.**

| case | setup | expect final | atol | source |
|---|---|---|---|---|
| `LoadTransfer` static | `ax = -4`, `ay = 0` | `dN_fl = dN_fr = +611.1`, rear −611.1 | 0.1 | hand: 1500·4·0.55/5.4 |
| `LoadTransfer` lateral | `ax = 0`, `ay = 3.873` | `dN_fl = -1145.2`, `dN_fr = +1145.2`, `dN_rl = -916.2` | 0.5 | hand |
| `PlanarOpenLoop` `steady_4_lt` | δ = 0.03, `h_cg = 0.55`, stop 4 | `ay = 3.873`, `r = 0.17727` | 0.01, 1e-3 | MTK probe |

**Plausibility.**
- In `steady_4_lt` the loads are `dN` = [−1136, +1155, −926, +907] N (probe; the small front
  asymmetry is the longitudinal term from the turn's drag) and sum to zero within 1e-6 N at every
  saved time.
- In `straight_brake` with `h_cg = 0.55`, `dN_fl = +640` N at 2.0 s (probe; hand
  `1500·4.189·0.55/5.4` = 640).
- All task 2–6 Dyad tests and snapshots pass unchanged with `h_cg` at its default.
- With `h_cg = 0.55`: the passive car still spins at 97° and 180° (probe YRR@1.0 = 1.34 and 0.86)
  and plows at 270° (β_max 6.4°); ESP through ABS still passes at 97°, 180°, 270° (probe end
  speed 17.0–17.4 m/s, min κ −0.11).

**Note.** `r` in `steady_4_lt` moves by only 0.1 % (0.17727 against 0.17709). With
`C_alpha ∝ N`, moving load from one wheel to the other leaves the axle's cornering stiffness
unchanged; load transfer only matters near the limit, where the inner wheel saturates first.
That is a lecture point, not a bug.

The algebraic loop (force → acceleration → load → force) closed without trouble in the MTK probe,
both with the 50 ms lag and without it. Keep `T_lt = 0.05` in Dyad: **not tried** in Dyad.

**Done when** the table and the plausibility checks pass and initialization gives no new
warning.

**Failure looks like:** loads move the wrong way under braking (the sign of `ax`); the loads
sum to `±2·d_long` (a front/rear sign); a structural-singularity error (the loop without the
lag; keep the lag).

**Physical sanity.** Braking loads the front; a left turn unloads the left wheels; total load is
always `m·g`.

**Size.** S–M, one day.

## Task 8 — Clocked ESP and sensor models

**Goal.** The ESP as an ECU runs it: sampled at 10 ms, reading noisy sensors and estimating
sideslip, with its results close to the continuous controller.

**Files.** `dyad/Vehicle/Planar/ESPControllerDiscrete.dyad` (`@[input clk extends Discrete]`,
the three blocks' equations in clocked form, the integral as a sum), `YawRateSensor.dyad`
(offset, first-order lag 20 ms, noise), `LateralAccelSensor.dyad`, `SideslipEstimator.dyad`
(continuous `der(beta_hat) = ay_meas/max(vx, v_floor) − r_meas`, initial 0);
`dyad/Lecture3/ClockedESPSineWithDwell.dyad` with forwarded `dt_esp`, `r_offset`, `ay_offset`,
`noise_on`.

**Tests.**
- `dt_esp = 0.01`, ideal sensors, ABS on: at 97°, 180°, 270°, `passes_stability`, and
  `y_bos_1_07` and end speed within 10 % of the task 6 run. **Not simulated.**
- Sideslip drift (hand): a constant gyro offset `ε_r` makes `beta_hat` drift at `−ε_r`; an
  accelerometer offset `ε_a` at `ε_a/vx`. With `ε_r = 0.5°/s` the error after 5 s is 2.5°; with
  `ε_a = 0.1 m/s²` at 22.2 m/s it is 0.26°/s, 1.3° after 5 s. A straight-line coast with each
  offset alone must reproduce these within 2 %.
- Dyad cases on the sensor blocks: offset and lag from a `Step` input, final values hand-exact.
- Read the held side of every clocked signal.

**Done when** all pass, and halving `dt_esp` to 5 ms changes `y_bos_1_07` by under 5 %.

**Failure looks like:** results flat at one value in a test (a clocked variable read directly);
the discrete integral winding up at standstill (it must stop below `v_on`).

**Physical sanity.** At 10 ms the ECU is as good as the continuous ideal; an uncorrected gyro
offset makes the sideslip estimate useless within seconds, which is why production estimators
blend in a model.

**Size.** M–L, 2–3 days. Optional for the lecture (decision D3).

## Task 9 — Notebook

**Goal.** `notebooks/lecture03/03-esp.pluto.jl`, in the style of `01-abs.pluto.jl`.

**Sections.**
1. The bicycle model: understeer gradient, `r/δ` against speed, the task 3 points on the curve.
2. The tire: friction circle from the task 1 rig; locked wheel against free wheel.
3. Sine-with-dwell, passive: trajectories at 76°, 97°, 270°; the pass/fail table across
   amplitudes.
4. ESP on: yaw rate against `r_ref`; which wheel brakes, as four torque traces; the same table.
5. ESP through ABS: slip stays in the window; the end-speed comparison with task 5.
6. Split-µ: trajectory and heading for the four configurations of task 6.
7. Optional: load transfer, the clocked ECU, sideslip drift.

**Done when** it runs top to bottom in a fresh session, every analysis it calls is a `Lecture3`
analysis with forwarded knobs (no nested `a__b__c` overrides), every number it prints sits in its
task's band, and each plot's claim is one sentence under it. If the lecture's figures are
exported, extend `scripts/export_lecture03_figures.jl` (mise task `figures:lecture-03`).

**Size.** M, 1–2 days.

## Probe evidence

What was simulated for this brief, and with what. Scratch scripts live in the planning session's
scratchpad (`plan/car2.jl`, `t1.jl`–`t11.jl`, `hand.jl`; `dyadcopy/dyad/Vehicle/Planar/WheelRig.dyad`,
`ABS4Probe.dyad`) and are not committed.

| Claim | Probe | Result |
|---|---|---|
| Single-wheel rig compiles and passes `half_peak`, `locked` with `Tsit5` and `Rodas5P`; the isolated test command works | Dyad | 9/9 assertions |
| A rig with `World` but no `Body` fails at problem setup | Dyad | "`Initial` parameter ... `g`" |
| Coast conserves `m vx + Σ J ω/r` exactly | MTK | 22.222492 against 22.222492 |
| Straight braking, 500 N·m per wheel | MTK | ax −4.188 (hand −4.185); κ −0.0305 / −0.0291 |
| Steady-state yaw rate against the bicycle formula | MTK | within 0.02–0.68 % up to 0.39 g |
| A from the 13.5°/s ramp; peak lateral acceleration | MTK | 21.6°; 0.995 g |
| Passive spins at 97–220°, plows at 270° | MTK | table in task 4 (matches the research) |
| ESP, P, no slip limit, passes everywhere and locks the braked wheel | MTK | table in task 5 (matches the research) |
| ESP with ideal slip limiting still passes, ends 3–4 m/s faster | MTK | table in task 6 |
| Inner rear braked in understeer | MTK | ∫T = [0, 0, 3054, 0] |
| Four `ABSModulatorDiscrete` channels on the planar car run with `Tsit5` and `Rodas5P` | Dyad | 37.6 m stop, κ −0.078 / −0.060 |
| Split-µ: ABS only spins; select-low and ESP PI with cut after ABS hold heading | MTK | table in task 6 |
| Load transfer, with and without a lag, loads match hand values | MTK | task 7 |

**Not simulated:** the hand-only rows of task 1; the tuned ABS stop (≤ 32 m); split-µ and
sine-with-dwell through the *Dyad* ABS with ESP; load transfer in Dyad; everything in task 8.

**Corrections to the research** found while planning:
- `C_alpha` per tire is 51.1 / 54.5 kN/rad, not 61 / 49 (§6 table; §2's K_us is right).
- A is 21.6° measured on the ramp, not the 20° the research computed from the linear model.
- A single-wheel rig must not contain `World` (new gotcha).
- A P yaw-rate controller that only adds brake torque cannot hold heading on split-µ: adding
  torque to an ABS-limited wheel changes nothing. The allocator therefore emits signed requests,
  the cut acts after ABS, and an integral term is needed.
- `ABSModulatorDiscrete`'s `lambda_1 = 0.04` belongs to the 1D tire; the planar tire needs
  0.08 / 0.06.

## Decisions still open

The plan runs on the recommended default of each. A different choice changes the tasks listed.

| # | Decision | Options | Recommended default | Tasks a change touches |
|---|---|---|---|---|
| D1 | Tire | keep `SlipBasedWheelJoint` (isotropic triple-S, per-axle `sAdhesion`) / write a planar Magic Formula wheel on slip ratio | **keep the triple-S**: proven here, the same curve as `TireFrictionCurve`, and the friction circle comes for free. A planar MF wheel is a new component with ~10 parameters per direction | 1 (rewrite), then every expected number in 2–7 |
| D2 | Retune `TireFrictionCurve` off `sAdhesion = 0.04` | retune so the 1D ABS and the planar car share a tire / leave it | **leave it**. Retuning changes the ABS notebook's and deck's numbers, which are done. The planar wheel has its own `sAdhesion`; the deck says in one line that the planar tire peaks near κ ≈ 0.1 | 6 (`lambda_1`), the 1D ABS tests and `01-abs` notebook if retuned |
| D3 | ESP scope | continuous only / also clocked with sensors | **continuous for the demo (tasks 5–7), clocked as optional task 8**. ABS is clocked either way | 8, 9 §7 |
| D4 | Steering input | road-wheel angle / steering-wheel angle with `i_s = 16` | **steering-wheel angle**, so A, 270° and the ESP's SWA sensor read as in FMVSS 126. `i_s` only rescales | 2–5 (car interface, harness amplitudes) |
| D5 | Parameter set | the probe car (1500 kg, a/b 1.2/1.5) / the NHTSA class means (1403 kg, 2893 kg·m², a/b 1.28/1.40) / `VehicleBody`'s 1400 kg | **the probe car**: every number in this brief is simulated with it. Switching means re-running the probes before task 3 | every expected number |
| D6 | Split-µ controller | P, add-only (fails split-µ) / PI with signed allocation and cut after ABS, plus rear select-low | **PI with signed allocation**: the only variant that held heading in the probe (3° against 19–106°) | 5 (allocator outputs signed), 6 |

## Build order

    0. MultibodyComponents dependency
    1. PlanarBrakedWheel + rig                                   -> tire matches the curve
    2. PlanarCar + PlanarOpenLoop: coast, straight braking
    3. steady-state cornering, A                                  -> GATE: the car is the bicycle model in the linear range
    4. SineWithDwell + metrics, passive car spins                  -> GATE: something to fix
    5. continuous ESP                                              -> lecture-ready demo
    6. four ABS channels, split-µ
    7. load transfer
    8. clocked ESP, sensors                                        (optional, D3)
    9. notebook (sections 1-4 can start after task 5)

Tasks 0–5 give the "ESP stops the spin" demo. Tasks 6–7 make it quantitatively honest.

## Prompts

Each prompt is self-contained: hand it to a fresh agent with the preamble pasted above it. Check
the reported numbers against this brief before starting the next task.

**Merging.** Each task works on its own branch off `feat/lecture-03-deck`, the Lecture 3
integration branch, and stops at a report. Merging is a human step after reading the report.

> **Preamble.** Repository: `/home/dr14/CVUT/VehicleSystemsComponents`. Work in your own
> worktree, branched from the integration branch:
> `wt switch --create feat/lecture-03-esp-<short-task-name> --base feat/lecture-03-deck`.
> `wt` prints the worktree path rather than entering it, so work there by path.
>
> Read `docs/lecture-03-esp-dyad-tasks.md`: "Read before the first compile", "Layout", "Ground
> rules", "How testing works", "Vehicle constants", the "Bill of materials" entries your task
> builds, and your task's section. Background is in `docs/lecture-03-esp-research.md`.
>
> Dyad language: `agent_resources/skills/dyad-language/SKILL.md`. Stdlib source:
> `agent_resources/stdlib_reference/<Library>/<Path>.dyad`. `MultibodyComponents` source: under
> `pkgdir(MultibodyComponents)`, `dyad/PlanarMechanics/`.
>
> Compile with `npx -y @juliacomputing/dyad-cli@3.4.0 compile .`, and confirm your change appears
> in `generated/` before trusting a test. Run your component's tests alone with the command in
> "How testing works", then the full suite with
> `cd test && julia +dyad-3.4.0 --project=.. runtests.jl`. Every test case and analysis uses
> `Tsit5` (or `Rodas5P`), never FBDF or the default.
>
> Do not edit existing components or `generated/` by hand. Stage files by name, never
> `git add -A`. Conventional Commits, US English. Do not push and do not merge.
>
> Report every expected number you measured next to the brief's value, and say plainly if one
> misses its band. Do not move a band.

---

### Task 0 — Add MultibodyComponents

Section: "Task 0". Record the full suite's assertion count first. Add `MultibodyComponents`
0.2.6 with `preserve = PRESERVE_ALL`, pin it `=0.2.6` in `[compat]`, recompile, and rerun the
suite.

Done when no existing package version moved, recompiling leaves only `Project.toml` changed, and
the suite passes with the same assertion count.

Report: the resolve output's added and changed packages; the assertion count before and after.

---

### Task 1 — Planar braked wheel

Section: "Task 1"; Bill of materials `PlanarBrakedWheel`. Depends on task 0. Read
`slip_based_wheel_joint.dyad`, `prescribed_velocity.dyad` and `Vehicle/Wheel/BrakeActuator.dyad`
first.

Build `Vehicle.Planar.PlanarBrakedWheel` and `TestPlanarWheelRig` (no `World`) with the nine
cases of the table. Add `test/esp_plausibility.jl`, include it from `test/runtests.jl`, and put
the locked-wheel and friction-circle ratios in it.

Report: every case's measured value against the table; the two ratios.

---

### Task 2 — Planar car: coasting and braking

Section: "Task 2"; Bill of materials `PlanarCar`. Depends on task 1. Read the research's
Appendix: its `ESPProbe` is the topology, already compiled once.

Build `Vehicle.Planar.PlanarCar` (steering-wheel-angle input, `i_s = 16`) and
`Lecture3.PlanarOpenLoop` with `PlanarOpenLoopTransient`. Add the `coast` and `straight_brake`
cases and the three plausibility checks.

Report: final `vx` in `coast` against 22.222492; max |r| and |vy|; `ax` at 2.0 s against −4.185;
front and rear κ; the sign of `psi` with right-side braking.

---

### Task 3 — Steady-state cornering

Section: "Task 3". Depends on task 2.

Add the four steady cases and `steer_ramp` to `PlanarOpenLoop`, and the plausibility checks.

Report: for each δ, `r` and `vx` at 4 s, the formula value at that `vx`, and the error; `K_fit`;
β in `steady_4`; A from the ramp; max lateral acceleration in g.

Stop and report if `r` sits near `vx·δ/L`: the axles have the same `sAdhesion`.

---

### Task 4 — Sine-with-dwell, passive car

Section: "Task 4". Depends on task 3 (uses its A).

Build `Vehicle.Planar.SineWithDwell`, the metric function in `dyad/Vehicle/Planar/module.jl`
with its unit test on synthetic signals, and `Lecture3.SineWithDwellRun`. Run the seven
amplitudes.

Report: the task 4 table as measured (YRR@1.0, YRR@1.75, y(BOS+1.07), β_max, end speed) beside
the brief's; the amplitudes at which the car spins.

---

### Task 5 — Continuous ESP

Section: "Task 5"; Bill of materials `YawReference`, `YawMomentController`, `BrakeAllocator`,
`ESPController`. Depends on task 4.

Build the four blocks with their tests, `Lecture3.ESPSineWithDwell` and `Lecture3.ESPSteerRamp`.
The allocator's outputs are signed; the harness applies `max(0, dT)`.

Report: the task 5 table as measured; pass/fail at every amplitude; the `∫ tau dt` per wheel in
the oversteer window at 180° and in the understeer ramp; the yaw-rate shortfall with and without
ESP.

---

### Task 6 — Four ABS channels and split-µ

Section: "Task 6"; Bill of materials `BrakeChannel`, `FourChannelABS`. Depends on task 5. Read
`docs/abs-controller-spec.md` § 5 and `dyad/Vehicle/ABSBrakeTest.dyad` for the clock, sampler and
hold wiring.

Build the channel blocks, `Lecture3.ABSStraightStop`, `Lecture3.SplitMuStop`, and the ABS path
in `ESPSineWithDwell`. Use `lambda_1` 0.08 front / 0.06 rear. Tune the modulator rates for
`J = 1` until the straight stop meets ≤ 32 m, starting from the default rates divided by 4.

Report: the stop distance and the rates that produced it; the sine-with-dwell table through ABS
with min κ and end speeds against task 5; the split-µ table (heading, offset, distance) for ABS
only, select-low, and ESP PI.

---

### Task 7 — Load transfer

Section: "Task 7"; Bill of materials `LoadTransfer`. Depends on task 6 (or task 5 if task 6 is
not merged; then skip the ABS rows).

Build `LoadTransfer`, add `h_cg` (default 0.0) to `PlanarCar`, and the new cases. Confirm every
earlier Dyad test and snapshot passes unchanged before adding anything.

Report: the hand-checked load values; `dN` in `steady_4_lt`; the zero-sum check; the
sine-with-dwell results with `h_cg = 0.55`.

---

### Task 8 — Clocked ESP and sensors (optional)

Section: "Task 8". Depends on task 6.

Build `ESPControllerDiscrete`, the sensor blocks, `SideslipEstimator` and
`Lecture3.ClockedESPSineWithDwell`.

Report: continuous against discrete at 10 ms and 5 ms (pass/fail, y(BOS+1.07), end speed); the
two drift rates against 0.5°/s and 0.26°/s.

---

### Task 9 — Notebook

Section: "Task 9". Depends on tasks 5 and 6 (sections 1–4 need only task 5).

Write `notebooks/lecture03/03-esp.pluto.jl` following `01-abs.pluto.jl`'s setup cells.

Report: that it runs top to bottom in a fresh session; any number it shows outside its band.
