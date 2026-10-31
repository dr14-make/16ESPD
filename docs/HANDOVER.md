# Handover — Lecture 1 build

Everything needed to pick this up cold. Read this file first, then the three it points to.

| Document | Holds |
|---|---|
| `lecture-01-plan.md` | scope, model ladder, tiers, why each decision went the way it did |
| `lecture-01-notebooks.md` | cell-by-cell spec for all ten notebooks |
| `lecture-01-dyad-tasks.md` | component specs, ground rules, acceptance criteria |
| `lecture-01-dyad-prompts.md` | the seven agent prompts, copy-pasteable, in build order |

## One-paragraph summary

A 90-minute lecture introducing control theory and PID, taught entirely through one vehicle
model at three fidelity levels. Ten Jupyter notebooks, committed with outputs executed. The
lecturer drives from the projector. Dyad models live in two submodules: `Vehicle/` (physical,
reused by later lectures) and `Lecture1/` (control assemblies and scenarios).

## Status

    [x] Task 1  Vehicle components
    [x] Task 2  CarPlant, GradeProfile
    [x] Task 3  CruiseLoop + Ziegler-Nichols gate   Ku = 114.56, Pu = 2.175 s
    [x] Task 4  Clamping anti-windup                ClampingPID + ClampingCruiseClimb
    [x] Task 5  Sampler                             surrogate only — see Risk 3
    [x] Task 6  MeasurementNoise                    the block; no loop wires it in yet
    [ ] Task 7  Wheel and slip

    [x] shared helper                              notebooks/lecture01/support.jl, not src/
    [x] Notebooks 01, 03, 04, 05, 06   (Tier 1)
    [x] Notebook 08                    (Tier 1)
    [x] Notebooks 09, 02               (Tier 2)
    [x] Notebooks 07, 10               (Tier 3)

    [ ] Notebook 09 and dyad/Lecture1/SampledCruiseLoop.dyad carry a Pade surrogate rather than a clocked
        partition, and should be translated to DiscreteComponents. Blocked upstream — see
        Risk 3 and https://github.com/dr14-make/16ESPD/issues/1

Update this block as things land. If the lecture has to be given from whatever is finished,
Tier 1 alone is a complete lecture: intro, P, PI, PID, windup, heuristic tuning.

## Plant parameters

    m       = 1400 kg          vehicle mass
    CdA     = 0.63 m^2         drag area          rho = 1.2 kg/m^3
    f_r     = 0.012            rolling resistance coefficient
    r       = 0.31 m           wheel radius
    i       = 4.0              total gear ratio
    T_max   = 150 N.m          engine torque limit
    tau_e   = 0.3 s            manifold-filling lag
    theta_e = 0.04 s           injection-to-torque transport delay   <-- see Risk 1

Derived, computed analytically and to be confirmed against simulation:

    drag coefficient      0.5*rho*CdA          = 0.378 N/(m/s)^2
    rolling force         f_r*m*g              = 164.8 N
    max tractive force    T_max*i/r            = 1935.5 N
    terminal speed, flat, full torque          = 68.4 m/s = 246 km/h
    cruise torque at 90 km/h                   = 31.1 N.m
    cruise torque at 110 km/h                  = 40.1 N.m
    10% climb at 130 km/h needs                = 2024 N  >  1935 N available  -> saturates
    speed the climb drives it towards          = 32.7 m/s = 118 km/h (asymptote)
      — 120 s of hill reaches 119.05 km/h and is still falling, so say "heads for", not
        "settles at", anywhere a finite climb is being described

The 90 -> 110 km/h step needs torque to go from 31 to 40 N.m, comfortably inside the limit, so
notebooks 03-05 never saturate. Saturation is introduced deliberately in 06 and nowhere earlier.

## Open risks

### Risk 1 — RESOLVED: theta_e ships at 0.3 s

Measured, and cross-checked by two independent calculations that agree to three figures:

    theta_e     w_180        Pu          Ku (N.m per km/h)
    0.04 s      8.96 rad/s   0.702 s     773
    0.30 s      2.88 rad/s   2.182 s     115

An earlier version of this section predicted `w_180 = 29 rad/s`, `Pu = 0.22 s` and `Ku = 7500`.
Those numbers were wrong — the transport delay contributes `omega*theta` **radians** of phase,
and 1.16 rad was mistakenly used as 2.3 degrees. The corrected figures are above; anything
quoting the old ones is stale.

**Ship `theta_e = 0.3 s.`** At 0.04 s the Ziegler-Nichols PID gains come out at `Kp = 455`,
which commands 9100 N.m on a 20 km/h step — sixty-one times what the engine can deliver. At
0.3 s the same method gives `Kp = 67.5`, which is nine times over. Neither fits inside the
actuator, but only one of them is recognisably a controller for this car. A 0.2-0.3 s delay is
defensible as the whole powertrain torque-response path (ECU, fuelling, combustion, driveline
compliance) rather than injection alone, and the engine's third-order Pade approximation was
already sized for it.

Cost of the change: `theta_e` is structural, so it is a recompile. The Vehicle snapshots
regenerate and notebook 01 must be re-executed, because its fitted dead time shifts. Terminal
speed and the climb settling speed are unaffected — neither depends on the delay.

### Finding — no heuristic tuning fits inside the actuator on a 20 km/h step

At `theta_e = 0.3 s`, Ziegler-Nichols commands nine times the torque limit and Cohen-Coon from
the notebook 01 step test (`k = 23.4`) commands about three times it. This is arithmetic, not a
modelling defect: holding 110 km/h takes 40 N.m, so any gain small enough to fit a 20 km/h step
inside 150 N.m leaves a steady-state error of about 7 km/h.

Notebook 08 should say so rather than hide it. The honest conclusion is that a heuristic tuning
gives a starting point, not a shippable controller, and the two real fixes are anti-windup
(notebook 06) or ramping the setpoint instead of stepping it — which is what production cruise
control does.

### Risk 1b — notebooks 03-05 must run with the torque limit lifted

The plan originally asserted that the 90 -> 110 km/h step never saturates, so that saturation
could be introduced deliberately in notebook 06. That is false, and no choice of gains fixes it.

Holding speed at 110 km/h needs about 40 N.m, so a gain that leaves a steady-state error of
`e` commands roughly `40/e` per km/h of error. On a 20 km/h step the peak command is therefore
`20/e` times the holding torque. Staying under 150 N.m needs `e` above about 7 km/h — an error
so large the controller looks broken. The indicative gain family saturates throughout:

    k =  14  ->    280 N.m     2x the limit
    k =  56  ->   1120 N.m     7x
    k = 220  ->   4400 N.m    29x
    k = 890  ->  17800 N.m   119x

Raising `T_max` is not the fix: at 250 N.m the 10% climb no longer saturates and notebook 06
loses its scenario instead.

**Resolution.** Notebooks 03, 04 and 05 set `y_max` high enough to be irrelevant and say so in
the prose: *assume for now an engine that delivers whatever we ask; notebook 06 removes that
assumption.* This is how the source videos teach it — ideal PID first, then "real actuators
saturate" — and it makes notebook 06 a reveal rather than a footnote. The gains those notebooks
quote are then honest, because they are the gains of the linear design.

It also arms notebook 08's closing lesson with a number from the students' own work: the
Cohen-Coon gains below command 469 N.m on that step against an engine that has 150.

### Risk 2 — the vehicle's own time constant is 60 seconds

Drag alone is a very weak restoring force, so the open-loop car is extremely sluggish. Two
consequences to watch: the open-loop step in notebook 01 needs a long simulation window to
reach steady state, and the step test that notebook 08 reads `K`, `tau` and `theta` off will
have a `tau` on the order of a minute. That is physically correct — coasting from 110 to 90
km/h really does take a long time — but the time axes must be chosen to suit it, and the closed
loop will be dramatically faster than the open loop, which is itself worth saying out loud in
the lecture.

### Risk 3 — RESOLVED: the surrogate ships, and the reason recorded here was wrong

Notebook 09 runs `Lecture1.HalfSampleDelay`, a third-order Pade transport delay of `Ts/2` in the
feedback path. It reproduces the phase a zero-order hold costs, so every trend the notebook
teaches is faithful, and it produces no staircase. The notebook states that plainly.

The reason recorded here was "Dyad ships no sampled blocks". **That is false.**
`DiscreteComponents` is a declared dependency of this package and ships `PeriodicClock`,
`Sampler`, `ZeroOrderHold`, `SampleWithADEffects`, `UnitDelay`, `DiscreteIntegrator`,
`DiscretePIDStandard`, `DiscreteStateSpace` and `DiscreteTransferFunction` — plus an
`Examples/SimplePID` with exactly the topology notebook 09 wants.

The real blocker is the compiler. Independently reproduced against the `dyad-3.3.0` channel,
Julia 1.12.7, with `DiscreteComponents` 0.2.0
(`ae11bd6ca7e94d72412d9ef95d6557f94ffbb2e3`), `ModelingToolkit` 11.35.1 and
`ModelingToolkitBase` 1.58.2. The one-line repro

    mtkcompile(DiscreteComponents.Examples.SimplePID(; name = :m))

first throws:

    MethodError: no method matching input_timedomain(
        ::SampleTime,
        ::SymbolicUtils.SmallVec{...})

This first failure is a library default/dispatch defect, but it is not the fundamental blocker.
`SimplePID` already gives its `PeriodicClock` an explicit `dt = 0.1`; overriding the controller's
default explicitly,

    mtkcompile(DiscreteComponents.Examples.SimplePID(
        name = :m, discretepidstandard__Ts = 0.1))

gets past `input_timedomain` and then throws the exact blocking exception:

    HybridSystemNotSupportedException: Hybrid continuous-discrete systems are currently not
    supported with the standard MTK compiler.

The same result occurs for `Examples.TestDiscreteIntegrator` when all three integrators receive
explicit numeric `Ts` values. Thus an explicit sample time fixes the earlier default-parameter
failure, but a clean Sampler/discrete-controller/ZeroOrderHold boundary around a continuous
plant still reaches the standard compiler's unsupported hybrid-system path. This is upstream
library/compiler support, not a topology or notebook usage problem.

So the surrogate remains the available route. Do not re-derive this beyond the one-line check.
When the explicit-`Ts` repro returns a system instead of throwing, the translation is unblocked.
It is tracked in [issue #1](https://github.com/dr14-make/16ESPD/issues/1).

### Risk 4 — terminal speed of 246 km/h is unrealistically high

Because the ideal engine delivers peak torque at every speed. This is a feature rather than a
bug: it is the natural hook into lecture 2's engine torque map. Notebook 01 should say so
rather than leave a student to notice it and distrust the model.

## Decision log

Decisions and the reason each was taken, so a takeover does not relitigate them.

| Decision | Chosen | Why |
|---|---|---|
| Lecture scope | Transcripts 1-5 + tuning tables + saturation trap + discretization | matches the existing slide deck, which runs system -> response -> step test -> PID -> tuning -> practical ZN task |
| Deferred to lecture 2 | cascade, loop shaping, pole placement, system ID, linearization, engine control | too much for one session; the engine half of the deck already lives there |
| Who executes | lecturer drives; outputs committed | student laptops cannot have the Dyad distribution by lecture time; committed outputs also serve as the fallback when a live solve stalls |
| Notebook count | ten, one concept each | P, PI and PID are the same Dyad model with two booleans flipped, so fine-grained splitting is nearly free and gives short live beats |
| Engine model | transport delay + first-order lag + torque limit | an instantaneous engine makes the plant first order: no sustained oscillation, so no Ziegler-Nichols, and Cohen-Coon divides by zero |
| Notebook format | Jupyter, executed and committed | Pluto renders as source on GitHub, losing the fallback; sweep families teach trends better than a slider anyway. Pluto remains a post-lecture upgrade |
| Submodules | `Vehicle/` + `Lecture1/` | the car is reused by later lectures; moving a component between submodules later breaks every reference |
| Noise source | deterministic sum of sines | committed outputs must reproduce; an RNG gives a different plot every run |
| Anti-windup | build a clamping variant alongside LimPID's back-calculation | the source video teaches clamping and notebook 06 is Tier 1, so the mismatch would be visible on screen |
| Submodule split | `Vehicle/` is the vehicle and its environment (`CarPlant`, `GradeProfile` included); `Lecture1/` is controllers, harnesses and analyses | the test is whether lecture 2 would use it unchanged. A car is a car regardless of what is being taught about it |
| Scenario parameters | forwarded to the top-level model and exposed on the analysis, never reached by nested override | a nested override encodes the model's internal structure in the notebook, so renaming a subcomponent breaks notebooks for a reason unrelated to what they teach. A forwarded parameter is an interface; `body__m` is a path |
| Slip model | 1D, on the multibody friction-curve shape | the 3D slip models are high-index DAEs, far too heavy for an introductory lecture |
| Unit conversion | a Dyad component on the sensor output, not notebook arithmetic | the conversion is visible as a block in the diagram, and a plotted signal is never transformed after the fact |
| Loop units | the whole control loop runs in km/h | setpoint, measurement and error are all km/h, so every gain in every notebook means the same thing and the numbers match a dashboard. Plant internals stay SI; exactly one conversion exists, at the sensor |

### Finding — the step test's dead time is curvature, not delay

Fitting FOPTD to the 90 -> 110 km/h step gives `K = 2.21 (km/h)/N.m`, `tau = 63.0 s`,
`theta = 1.63 s` — a dead time forty times the engine's actual 0.04 s transport delay.

It is not an error. Drag is quadratic, so the local time constant falls from 74.1 s at 90 km/h
to 60.6 s at 110 km/h, and dead time is the only parameter in the FOPTD form that can absorb
that curvature. Shrinking the step shrinks the fitted `theta`, and at 0.2 km/h it goes negative
— which is impossible for a real delay and proves what is being measured.

Two consequences. Notebook 01 must not claim the fitted `theta` recovers `theta_e`; it should
present the tangent gain and time constant at each end of the step, which genuinely bracket the
fit (`K = 2.21` sits on the secant 2.212, `tau = 63.0` between 60.6 and 74.1). And notebook 08
gains a real lesson: a step test does not know what is inside the plant, and reports an
effective dead time that lumps curvature and unmodeled dynamics together with any true delay.

This does not affect Risk 1. The ultimate gain is set by phase at about 29 rad/s, where real
dynamics dominate; a low-frequency curvature artifact adds no phase lag there.

## Gotchas found during the build

- **A model with unconnected `RealInput` ports cannot be a `TransientAnalysis` model.** Every
  notebook scenario therefore needs a harness component driving those inputs, plus its own
  analysis. This was missing from the first version of the Dyad brief.
- **`CarPlant` will not initialize without `plant.body.mass.s`.** A harness starting from
  settled cruise should also set `plant.engine.lag.x` to the holding torque, or the run spends
  hundreds of seconds settling first — the vehicle's own time constant is about 60 s.
- **World age in `setup()`.** `Core.eval(@__MODULE__, :(using X))` creates a binding that the
  already-compiled calling method cannot see, giving `UndefVarError ... The binding may be too
  new`. Split the calls into separate methods reached through `invokelatest`.
- **Neither `jupyter` nor `IJulia` is installed on this machine**, so no notebook can be
  executed here until one is. Committed outputs are a decision from the planning session, not a
  nicety — they are the projector fallback and the student-facing artifact.
- **Editing a `.dyad` file does not update `generated/`.** The suite runs the checked-in
  generated Julia, so a source edit sits inert until the Dyad compiler runs. A suite run right
  after editing a source file tests the *old* code and passes — which looks like confirmation
  and is its opposite. This cost a whole cycle: a test-case pin was added, the references were
  regenerated without it, and the run went green comparing unpinned against unpinned. The pin
  only took effect when an unrelated build triggered a recompile. After any `.dyad` edit,
  confirm the change appears in the matching `generated/` file before trusting a test result.
- **Compile with the CLI release that matches `[dyad] kernel` in `Project.toml`.** The command
  is `npx -y @juliacomputing/dyad-cli@3.5.0 compile .` from the repository root; bump the
  version together with the kernel pin. Kernel 3.5.1 has no CLI release of its own: Dyad 3.5.1
  fixed only Dyad Studio and ships the 3.5.0 compiler. The package lives on the GitHub npm
  registry, so `~/.npmrc` needs a token with `read:packages` for the `@juliacomputing` scope (see the
  dyad-lang `apps/cli/README.md`). Recompiling an unchanged checkout must leave `git status`
  clean; that is the check that the compiler is the right one. Older CLIs on this machine fail
  on the 3.4 standard libraries rather than on our code: `~/.dyad-maxwell/dyad-lang/apps/cli/dyad`
  is a 1.1 prerelease and dies in `ElectricalComponents` ("Expected module Analog/Basic/Tests"),
  and `~/julia/dyad-lang/apps/cli/dyad` is a 3.2.0 build that rejects `DiscreteComponents`
  0.5 (`Unknown element x0 in definition InitialCondition`).
- **On Dyad 3.5, the planar car is wrong unless its analysis sets `optimize =
  OptimizationLevel.None()`.** The default, `Aggressive`, rewrites each small linear block into
  `DyadCompilerPasses.linear_solve`, which returns one shared buffer per block size. The planar
  car has four identical 2×2 blocks (one per corner), so every corner reads the last corner's
  tire force: no error, `retcode = Success`, and the sine-with-dwell yaw peak drops from 0.214
  to 0.078 rad/s. These analyses therefore set `optimize = OptimizationLevel.None()`:
  `PlanarOpenLoopTransient`, `SineWithDwellRunTransient`, `ESPSineWithDwellTransient`,
  `ESPSteerRampTransient`, `SplitMuStopTransient`, `BrakeAndSteerTransient`,
  `ABSStraightStopTransient`, `PlanarWLTCTransient`, `PlanarCruiseTransient`,
  `PlanarBEVWLTCTransient`, `HandsOn04.BEVWLTCTransient`, `HandsOn04.BEVEnergyBillTransient`,
  `PlanarBEVHardStopTransient`, `PlanarBEVRegenWLTCTransient`, `HandsOn04.BEVHardStopTransient`
  and `HandsOn04.BEVRegenWLTCTransient`. A new analysis of a model with repeated identical algebraic loops
  needs the same line; compare a run at `None` against `Aggressive` to tell. Do not set it
  everywhere: `ThrottlePedalStepTransient` starts the throttle at the wrong position under
  `None` and is correct under the default. The generated tests cannot take the setting, so the
  generated Lecture 3 tests for these models fail on 3.5 (3992 of 7749 checks) until the fix
  ships. Upstream: JuliaComputing/DyadCompilerPasses.jl#114, fix in draft PR #153 (unreleased
  as of DyadCompilerPasses 0.3.11). `test/runtests.jl` pins that count in `KNOWN_FAILURES`:
  the `generated` group passes only at exactly 3992 failures and no errors, and any other count,
  lower included, fails the run. When a Dyad release carries the fix, drop the setting, delete
  the `generated` line from `KNOWN_FAILURES`, and rerun the suite.
- **The planar car stalls Rodas5P only from exact rest (MultibodyComponents.jl#185).**
  `SlipBasedWheelJoint` adds `0.0001` outside `sqrt(v_slip_long^2 + v_slip_lat^2)`, so its
  Jacobian is NaN when both slip speeds are exactly zero. `PlanarWLTC` started with body and
  wheels at exact rest aborts at t = 0 (`dt forced below eps`, NaN rows on every wheel's `der(w)`),
  with or without a creep target. Once the car has moved, the slip speeds do not return to exact
  zero: braked to a stop they settle at round-off (1e-22 m/s longitudinal, 1e-20 m/s lateral)
  and a 400 s park, every WLTC stop and a `dtmax = 0.01` run all finish. A free-rolling rear
  wheel at constant speed does reach `v_slip_long == 0.0` exactly, and only the lateral round-off
  keeps it off the NaN. The bench therefore starts the wheels `dv_wheel = 0.01` m/s ahead of the
  body, as the Lecture 3 harnesses do, and carries no creep floor; the `planar_wltc` group's
  `@test_broken` on an exact-rest start turns into an unexpected pass once the fix ships.
- **`RoadLoad` cannot run backwards faster than 0.71 m/s.** Its stdlib `RollingResistance` uses
  the `Exp` regularization, `2 / (1 + exp(-v / (0.01 v0))) - 1` with `v0 = 0.1`, whose derivative
  is `Inf / Inf` once `exp(-v / 1e-3)` overflows at v < -0.71 m/s. A WLTC driver that brakes with
  negative drive torque overshoots each stop into reverse (−1.5 km/h at k = 100, −2.6 km/h at
  k = 50, which aborted at t = 444 s with NaN body accelerations). `PlanarWLTC` splits the
  driver's output by sign instead, drive torque on the front flanges and the negative part to
  the front friction brakes, which cannot reverse the car: lowest speed −4e-8 km/h.
- **An analysis cannot set its model's structural parameter, nor forward an expression.**
  `model = PlanarWLTC(cycle = false, v0 = v_set / 3.6)` in an analysis compiles, then fails at
  run time with `System PlanarWLTC: variable cycle does not exist`: the generated spec pushes
  `cycle` as a parameter override, and `v0 => v_set / 3.6` refers to an unbound `v_set`.
  Put the structural choice and the derived default in a test component that `extends` the
  bench (`PlanarCruise extends PlanarWLTC(cycle = false, v0 = v_set / 3.6)`), and forward only
  plain analysis parameters.
- **A clocked variable reads back as its last value.** `sol(t, idxs = controller.y)` on a
  variable of the discrete partition returns the value from the final tick for every `t`, with
  no error. Read the held, continuous-time side instead (`hold.y` after a `ZeroOrderHold`), in
  tests and notebooks alike.
- **A changed model needs new references, and only a changed model.** The sampled cruise loop
  became a real `DiscreteComponents` loop while its references still described the continuous
  half-sample-delay version, and the suite failed on them. Before regenerating a case, name the
  model or package change that moved its curve.
- **Run the test suite from `test/`, not the repository root.** `generated/test_internals.jl`
  resolves references at the relative path `joinpath("snapshots", ...)`. `Pkg.test()` runs from
  `test/` so this works; a direct `julia test/runtests.jl` from the root finds no snapshots,
  silently skips every trajectory comparison, writes a stray `snapshots/` at the root, and
  still exits 0. The tell is the assertion count — the real `generated` group is about 29,600,
  the crippled one about 70. Use `mise run test`, which runs
  `cd test && julia +dyad-3.5.0 --project=.. runtests.jl`.
- **The suite runs one child process per group.** One process holding every group's compiled
  models and solutions outgrows 30 GB and `earlyoom` kills it, while no group alone needs a
  sixth of that. With no argument, `runtests.jl` therefore starts each group in `GROUPS` as its
  own Julia process, one after another, prints a table of passes, failures, broken tests, peak
  memory and time per group, and exits nonzero if any group failed or was killed. Named groups
  run in the current process: `mise run test:group esp brake`, `runtests.jl esp brake` or
  `TEST_GROUPS=esp,brake`. A new suite file becomes a group with one line in `GROUPS`; a group
  that would rather share another's process can list both files under one name. Peak memory per
  group (`Sys.maxrss`, 2026-10-28): `esp` 4.6 GB, `abs` 4.3 GB, `generated` 3.5–4.1 GB, the
  rest 2.2–2.6 GB (1.5 GB of that is loading the library). The full run takes about 36
  minutes, 15 of them `esp`. If one group passes about 10 GB, split it before it becomes the
  new limit.
- **Exported figures carry their clipped points.** Setting `xlims` on a plot hides data from
  the eye, not from the SVG: one sweep figure came out at 2.7 MB, six times the largest other
  figure, which would make the deck crawl on a projector. Hand each panel only the window it is
  read over. Do not decimate instead — that aliases high-frequency chatter into a waveform the
  simulation never produced.
- **Quote anchors from what the lecture runs, not from a model's defaults.** Twice a brief
  carried measurements taken at a component's default derivative time while the notebooks were
  running the value the PID notebook arrives at. Both times the notebook agent caught the
  mismatch and both times the notebook was right to keep the lecture's value. Before quoting a
  number into a brief, check which parameter set produced it.
- **A load step needs a `tstops` entry, and it must be a `Step`, not a `Pulse`.** Sources switch
  with `ifelse` on `time`, which is no event. Without a stop the solver strides across the edge:
  the battery bench counted 0.5 s of its 100 A too little (SoC 1.3e-4 low). `Step` switches at
  `time >= start_time`, so with `tstops = [start_time]` the step leaving the stop sees the new
  value and the error falls to the tolerance (3.5e-6). `Pulse` switches on at `time >
  start_time`, so a stop on its edge makes the first stage after it read the old value, and it
  stays wrong (9.4e-5). `automatic_discontinuity_detection = true` does not rescue `Pulse` on
  3.5: it throws `Condition of ifelse must be a Bool` in DyadCompilerPasses' if-lifting.
- **`InverseSpeedDependentTorque` with `TorqueDirection = false` jumps at `w0` unless
  `w_nominal = w0`.** Below `w0` it gives `tau_nominal * w / w0`, which reaches `tau_nominal`
  at `w0`; above it gives `tau_nominal * w_nominal / w`, which is `tau_nominal * w_nominal /
  w0` there. For the machine's constant loss (200 W) nominated at base speed, 343.8 rad/s,
  with the default `w0 = 0.1`, that is a step from 0.58 N·m to 2000 N·m at 1 rpm, and every
  run through standstill would cross it. `Vehicle.Electric.DCMachine` therefore sets
  `w_nominal = w0 = w_reg` and `tau_nominal = -C / w_reg`, so the torque is `C / w` above
  `w_reg` and fades linearly to zero below it, with no jump.
- **Memory.** Running several agents alongside the Dyad language server exhausts this machine;
  `earlyoom` is configured to prefer killing `julia`. A run that dies with no error message was
  probably killed, not broken. Retry before debugging.
- **The dyad-3.5.0 kernel ships no GR.** Its stdlib has `Plots`, `PlotlyBase`, `PlotlyKaleido`
  and `Kaleido_jll`; the 3.4 kernel also had `GR`. `setup()` defaults to `backend = :gr` and
  fails on 3.5 with `Package GR not found in current path`, so the Lecture 4 notebook calls
  `setup(backend = :plotly)` and `scripts/export_lecture04_figures.jl` writes its SVGs through
  Kaleido. Three traps on that route: `Plots.savefig` passes Kaleido no size, so every figure
  comes out 700 × 500 whatever `size` says (the script converts the plot itself and passes its
  size); plotly's default line simplification draws smooth curves as visible polygons (the script
  sets `line.simplify = false`); and `vspan!` writes infinite bounds that the JSON writer rejects
  (`-Inf not allowed`), so shade with a finite `Shape`. The Lecture 3 export still asks for GR and
  needs the 3.4 kernel or the same change.
- **A plotly heatmap from Plots comes out transposed on the dyad-3.5 kernel.** Plots'
  `handle_surface` transposes a heatmap's matrix for a JSON writer that wrote matrices column by
  column; the kernel's JSON 1.10 writes them row by row, so the two transposes cancel and plotly
  draws `z[i, j]` at `(y[j], x[i])`. Nothing errors: a 331 × 202 efficiency map came out on its
  side and cut off at the 202nd torque row, with the zero-torque row as a vertical stripe at
  8200 rpm. `notebooks/lecture04/01-efficiency-map.pluto.jl` undoes it after each `heatmap!`
  with `p[sp].series_list[end][:z] = Plots.Surface(permutedims(F))`. The same JSON rejects NaN
  (`NaN not allowed to be written in JSON spec`), so a heatmap carries no NaN either: fill the
  matrix and cover the region outside the data with white `Shape`s.
- **A constant-power load on the battery has two solutions, and initialization can pick the
  wrong one.** `v i = P` behind the pack's `E - R0 i` is a quadratic: the link near 350 V with
  0.86 A, or the link collapsed to 0.086 V with 3500 A. Written algebraically in the BEV, the
  solver initialized on the second, burned 3.8 kWh in `R0` in 11 s and aborted (`dt forced below
  eps`, the converter's field at −77 000). A `guess i = 0` did not help: the torn unknown was the
  link voltage, not the load current. `Vehicle.Electric.AuxLoad` therefore makes its current a
  state, `T di/dt = P/v - i` from `i = 0`, which starts on the high-voltage branch and stays; the 10 ms lag
  costs 1e-5 of the auxiliary energy over WLTC.
- **A torque command through a current-imposing converter divides by the present field.**
  `ElectricDrive` asks for `i_ref = tau_ref / (converter.field * machine.k)`. Divided by `k`
  alone, the machine gives `field` times the torque asked for: 0.36 of it at WLTC's 131 km/h, so
  the speed driver's loop gain falls by two thirds on the motorway. The division closes an
  algebraic loop (`i_ref` → `L di/dt` → `v_out` → `d` → `field`) that Rodas5P solves without
  help; the WLTC run goes from 6.4 s to 6.8 s warm, and the machine gives the asked-for torque to
  0.19 N·m (the current loop's lag) wherever the field is weakened.
- **A step in the torque asked of the electric drive aborts Rodas5P above base speed.** The
  converter imposes its current through the armature inductance, so a step in `i_ref` steps
  `L di/dt`, and with the duty at its limit the algebraic `field` has to jump to hold the voltage:
  on the first BEV hard stop (a `Step` of −1221 N·m at 80 km/h) it had to go from 0.615 to 0.775
  at t = 0.5 s, and the run aborted there (`dt forced below eps`, the error estimate all on
  `converter.field`) with or without a `tstops` entry on the step. Ask for torque continuously:
  the hard stops ramp the pedal over 0.1 s (`Ramp`, with `tstops` on both corners); the WLTC
  driver's PI output is continuous already.
- **Regen outside the ABS loop keeps the ABS from reapplying (the dry default, `withdraw = 0`).** `ABSModulatorDiscrete` reapplies
  only once a released wheel's predicted slip is back above `-l_rec` (−0.03). On the BEV hard stop
  the machine's regenerative torque alone holds the front slip at −0.04 to −0.06 from 62 km/h
  (phase alternating hold/release), so the front friction brakes stay at zero and the front tires
  work at about 65 % of their grip until the machine's 320 N·m reaches it below 34 km/h. The stop
  is still shorter than on friction alone (36.2 m against 38.8 m), but a regen strategy that kept
  more torque on the front would lock it. Issue #140 adds an opt-in `RegenBlend` ABS rule:
  sampled `front_active` means either front command is below demand; regen's ceiling decays in
  30 ms and returns in 0.5 s, with the remainder handed to hydraulics. The dry references default
  to `withdraw = 0`: 36.22 m, 49.32 % motor, 176.9 kJ motor / 181.8 kJ friction. The inherited
  gentle ABS keeps withdrawal active almost throughout the dry stop; leave the rule opt-in
  pending ABS calibration #156. Demonstrate on `Vehicle.Planar.PlanarBEVLowGripStopTransient()`
  or `HandsOn04.BEVLowGripStopTransient()` (default `withdraw = 1`, `stop = 28`). Verified grip ×0.3
  measurements: minimum front slip −0.04931 while moving above 3 m/s, stop 275.02 m enabled;
  `withdraw = 0, stop = 12` locks and reverses the wheels, so its 112.35 m is not a physical
  benchmark. Long parking disabled reaches the known tire NaN. WLTC is unchanged; the blending rule is structural, default off.
  `regen` passes 98/98 and `abs` 84/84 on dyad-3.5.0. No ABS retuning is part of this follow-up.
- **`r."path"` takes a literal only.** On an analysis result, `r."E_dc"` works but `r."$x"`
  with `x = "E_dc"` throws a `MethodError`, and `getproperty(r, :E_dc)` a `FieldError`. A snippet
  that loops over signals collects the literals first: `links = ["road" => r."E_road", ...]`.
- **`switch` is a reserved word in Dyad.** An instance named `switch` fails to parse with "The
  'component' block needs to be closed with an 'end' keyword, but I found 'switch'". A component
  type may be called `Switch`.
- **A switch node needs a capacitance.** In the switched buck chopper (resistive `Switch` plus the
  library's exponential `Diode`) the node between them was algebraic, and at each turn-on the
  solver had to move it from the diode's drop to the supply in one algebraic step: at
  `abstol = reltol = 1e-6`, Rodas5P threw the node to −1088 V and aborted on the second pulse
  (t = 67.9 µs); it only ran at 1e-7 and tighter. The switch's output capacitance `C_oss` = 1 nF
  makes the node a state; the run then succeeds at 1e-6 and the current moves by 0.4 mA of 19 A.
- **Average switching power over the solver's own steps.** The loss in a switching edge is a
  pulse a few nanoseconds wide. A 1 µs sampling grid put the 10 kHz H-bridge's losses at
  1266 W against 26 W, and sampling the interpolant between steps still gave 103–179 W, because it
  misreads the currents that charge `C_oss`. The trapezoid rule over `sol.t` closes
  `P_dc = P_ac + P_loss` to 1e-7 and matches the hand estimate; the `switching` tests and the
  notebook use it. Voltages and smooth currents can still be sampled from the interpolant.
- **Moving parts into a subcomponent changes the numbers by one ulp, and an ABS stop amplifies
  it.** The first `RoadLoad` extraction held it as a `roadload` part of `VehicleBody`. The
  variables were renamed (`body.roadload.drag.f`), and the generated code sums the force terms
  in a different order. The right-hand side then differed by 5.6e-17. Smooth runs did not show
  it (`TestCarPlant` and the roadster launch matched to 1e-12), but the chattering ABS stops took
  different steps: 8282 against 8314. `braking_distance` reads `s` at the first solver step under
  `v_stop` without interpolating, so `ABSBrakeTransient()` moved from 38.69795 m to 38.69746 m.
  That is outside the vacuum group's `38.6980 atol = 1e-4` pin, although the interpolated
  positions of the two runs differ by only 1e-9 m, against 4e-7 m between either run and a 1e-10
  run. `VehicleBody` therefore `extends RoadLoad` and adds `mass`, which keeps every name, so the
  models that use it run bit-identical (same `sol.t`, same states). Before refactoring a
  component that pinned tests use, run the HEAD version beside the new one in one session: `git
  show HEAD:generated/.../X_definition.jl`, rename `X` to `OldX`, `Core.eval` it into the
  submodule. Then compare `sol.t` and the states with `==`.

## Conventions

- Prose in English. Plant internals SI; the control loop and every speed axis in km/h, via
  `Vehicle.ToKmPerHour` on the sensor output. Controller gain `k` is therefore N.m per km/h.
- Model construction and solving go in a shared helper under `src/`; notebook cells stay thin
  so the later Pluto port is a rebind rather than a rewrite.
- Never edit anything under `generated/`.
- Comments explain why — a constraint, an invariant, a gotcha. Not what the code says, and not
  the history of how it got there.
