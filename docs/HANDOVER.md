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
  (`-Inf not allowed`), so shade with a finite `Shape`. A fourth: Plots gives the figure one
  legend, placed on the whole figure by the last subplot's `legend` setting, so a last panel with
  `legend = false` hides every legend and `:topleft` lands on the title.
  `scripts/plotly_svg.jl` handles all of this except `vspan!` and draws each panel's legend inside
  its axes; the Lecture 3 steer and ESP exporters use it. `link = :x` also drops the upper
  panel's tick labels on plotly; give the panels the same `xlims` instead. The Lecture 3 notebook
  and build exports (`figures:lecture-03`, `figures:lecture-03-build`) still ask for GR and need
  the 3.4 kernel or the same change.
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
- **Regen withdrawal after #156 rebases #140.** `RegenBlend(abs_rule = true)` uses sampled
  `front_active` (either front command below demand); `allow` decays in 30 ms and returns in
  0.5 s. After the pressure-memory fix below, keep dry withdrawal ON: 27.102 m versus
  26.938 m friction-only (0.61% longer), within the passing regression's explicit 1% tolerance.
  Rule OFF is 27.238 m but reverses front wheels; it is not a physical comparison benchmark.
  The motor-share goal remains unmet: blanket withdrawal leaves only 0.839% gross shaft share.
  WLTC does not use the rule; its equations and results are unchanged. Current evidence,
  low-grip caveats and the measured pressure-memory trace are recorded below.

- **Planar ABS calibration (#156).** The old 0.08/0.06 release and 0.03 recovery window
  held slip below the tires' 0.12/0.09 peaks. Peak-centered prediction (0.14/0.11),
  80 ms look-ahead, 90% pressure retention, 10 ms hold and 40 kN.m/s initial build give
  9.74 m/s² during established braking: 26.52 m from 80 km/h, 41.03 m from 100 km/h.
  No tire or load-transfer defaults changed. At h=0 the load-transfer flag has no effect.
- **Historical #156 rule-OFF comparison (#140).** The 33.04 m / 45.3% machine-share
  result below is the uncoordinated blend, not today's rule-ON default. Do not retune
  the friction ABS to hide the coordination defect. Historical 100 km/h runs could reverse
  front wheel rotation; those are not physical locked-wheel benchmarks.
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

### Issue #156 — historical planar ABS evidence and moved-number ledger

This ledger records #156 before the #140 rebase follow-up; its BEV blend rows are rule OFF.
Its test counts and figure-export status are historical, not validation of the rebased default.
For current required-runtime measurements and pending work, see the follow-up below.

Distances start at the pedal (0.5 s), stop at vx < 0.5 m/s unless noted. No reaction distance.
Dry source anchors: [auto motor und sport Leaf ZE1, 39 m from 100 km/h](https://www.auto-motor-und-sport.de/)
and Argonne's 2013 Leaf, 36.9 m from 60 mph; primary links and provenance are in
`docs/research_notes/Electric and hybrid vehicles/bev-road-load-and-braking-validation.md`, item 8.
Those imply 9.8–10.2 m/s² and 25–26 m from 80 km/h. Our 30 ms hydraulics and sampled
pressure build leave 26.52 m from the pedal, versus established deceleration 9.74 m/s².
These are assumed teaching-controller calibrations, not claimed Bosch production values.

**Cause isolation (same car, one change at a time):** baseline 36.05 m (6.84 m/s² distance
proxy); release at tire peaks alone 33.29 m; recovery 0.08 alone 33.19 m; prediction removed
42.80 m; pressure retention 0.9 alone 37.08 m with near-lock overshoot. Thus no single scalar
retune suffices: the early release/near-zero recovery window and deep pressure dumps interact
with hydraulic lag. At 1 s the front brake gives 887 N·m against peak tire torque 1267 N·m;
front force 2777 N of 4087.5 N normal load, rear 2530 N of 3270 N. Mean slip (0.8–2 s)
0.0553 front / 0.0491 rear, below tire peaks 0.12 / 0.09. The first hold times out at
0.6 s and dumps pressure again despite a rolling wheel. The final window centers the cycle
near peak force without changing tire friction. All four wheel slips are checked in `esp`.

`PlanarCar.load_transfer` is false by default, and h_cg is zero. `ABSStraightStop` enables
transfer but also has zero height, so the flag alone changes nothing. At h=0.5 m, transfer
alone makes 37.23 m, not a fix: at 1 s front/rear loads become 4916/2442 N per wheel versus
4087.5/3270 N, moving grip forward while the early front release still wastes it. Independent
ABS can use all four loads; disabling transfer is not the main missing 0.3 g. Defaults remain
unchanged to preserve the lateral teaching progression.

| Quantity | Before → after |
|---|---|
| Planar predicted release, front / rear | 0.08 / 0.06 → 0.14 / 0.11 (derived from tire peaks) |
| Prediction / recovery / pressure retention | 30 ms / 0.03 / 0.6 → 80 ms / 0.12 / 0.9 (derived / assumed) |
| Hold timeout / initial build | 60 ms / 160 kN·m/s → 10 ms / 40 kN·m/s (assumed) |
| Straight ABS, 80 km/h | 36.05 → 26.52 m; metadata final x 47.182 → 37.643 m |
| Straight ABS, 100 km/h | 58.57 → 41.03 m |
| Mean front / rear slip, 0.8–2 s | 0.0553 / 0.0491 → 0.1031 / 0.0808 |
| Uniform μ=0.3 | 146.19 → 85.73 m; min active slip > −0.13 |
| Brake-and-steer path distance | 38.2 → 28.3 m (locked unchanged 31.6 m) |
| Offset at obstacle / at rest | 3.02 / 10.9 → 2.64 / 4.00 m |
| Peak yaw / final heading / min front slip | 27.9°/s / 49° / −0.105 → 20.8°/s / 28° / −0.127 |
| Mean front lateral force after steer | 3.9 → 3.37 kN |
| Split μ ABS-only, below 3 m/s: heading / y / x / time | 129° / 21.1 / 65.7 m / 4.5 s → 101.4° / 7.5 / 52.7 m / 3.09 s |
| Split μ select-low: heading / y / x / time | 22.7° / 14.4 / 89.5 m / 6 s → 20.8° / 7.1 / 62.3 m / 4.59 s |
| Split μ + P ESP: heading / y / x / time | 24.6° / 14.6 / 86.8 m / 6 s → 20.1° / 6.9 / 64.4 m / 4.70 s |
| Split μ + PI ESP, at 6 s | 3.2° / 4.6 / 108 m → 3.0° / 3.2 / 86.2 m |
| Split μ actual 0.5 m/s stopping x-distance from pedal | ABS 55.89 → 43.88 m; select-low 52.02 m after; PI 78.92 m after |
| ESP+ABS end speed at 32/76/97/141/180/220/270° | 21.0/19.6/19.1/18.4/18.9/19.0/19.3 → 21.0/19.2/18.7/18.5/18.4/18.8/18.9 m/s |
| ESP+ABS min slip at same amplitudes | −.04/−.06/−.06/−.07/−.08/−.08/−.09 → −.04/−.11/−.11/−.13/−.13/−.13/−.13 |
| ESP+ABS responsiveness range, 97° up | 2.87–3.44 → 2.74–3.24 m; max |YRR| 0.042 → 0.043 |
| BEV 80 km/h with / without regen | 36.22 / 38.82 → 33.04 / 26.94 m |
| BEV 100 km/h with / without regen | 61.51 / 59.12 → 41.76 / 41.57 m |
| BEV machine braking share, 80 / 100 km/h | 49.3 / 44.8 → 45.3 / 24.8 % |
| BEV 80 km/h shaft / friction / tire / battery | 176.9 / 181.8 / 22.0 / 170.2 → 160.1 / 193.2 / 27.3 / 154.8 kJ |
| BEV friction-only brake / tire energy | 366.8 / 19.8 → 352.7 / 34.6 kJ |
| BEV stop time after pedal / recovered Wh / equivalent WLTC range | 3.0 s / 47 Wh / 350 m → 2.7 s / 43 Wh / 320 m |
| Regen distance advantage at 80 km/h | 2.6 m shorter → 6.1 m longer (known #140) |

`abs` 84 pass; `esp` 159 pass; `regen` 69 pass, one broken (#140 no-distance-penalty);
`planar_wltc` 36 pass, one pre-existing broken initialization case. Groups run separately.
Compiled with dyad-cli 3.5.0; no generated files edited manually. Layout metadata unchanged.
ESP and steer exporters needed stale `.sensors` paths changed to `.car.bus`; mise tasks added.
The Lecture 4 figure task completed. Legacy Lecture 3 notebook export is blocked by missing
GR; build export by a Plotly/JSON serialization error. Their unrelated/partial SVG changes
were restored, as were unrelated Lecture 4 id churn. Changed planar and BEV figures retained.

### Follow-up #156 — rebase #140: historical pre-memory-fix evidence

Rebased `41ef17a` as `7bac0b4` on `878ce03` (`origin/main`). Actual conflicts were
`docs/HANDOVER.md`, `PlanarBEVHardStop.dyad`, `regen_plausibility.jl`, the Lecture 4 guide
and three generated `.jl` files. `ABSUnit` auto-merged, retaining calibration and the reporting
signal. HandsOn and plan/deck auto-merged with stale text that needed correction. Compiler
3.5.0 generates the Julia output; generated files are not hand-edited.

Rule ON remains the hard-stop default (`withdraw = 1`) per user request. Distances and times
below start at the pedal (0.5 s) and end at vx < 0.5 m/s; no reaction distance. Energies are J;
`shaft_in` and `shaft_out` are reported separately, not silently netted.

| Dry 80 km/h case | Distance (m) | Time after pedal (s) | shaft_in | shaft_out | Friction | Tire | Battery recovered | Machine share |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Rule ON (default) | 59.409163717 | 5.100 | 3501.911496 | 5010.979664 | 350708.377370 | 31457.672893 | 2979.353015 | 0.98865324% |
| Friction only | 26.937898732 | 2.335 | 853.747 | 7484.425 | 352732.323 | 34555.337 | 0 | — |
| Rule OFF (diagnostic) | 33.037836314 | 2.705 | 160119.109 | 0.217 | 193237.591 | 27300.500 | 154840.805 | 45.3137% |

Rule ON minimum slip above 3 m/s is −0.0243273 front / −0.0935963 rear. The broken
no-distance-penalty assertion must remain: the penalty worsens to 32.47 m against friction only.

**Pressure-memory trace:** rule-ON front friction torque is
exactly zero at t = 0.55, 0.6, 0.65, 0.8, 1, 1.5, 2, 2.5 and 3 s. `allow` is 0.3114,
0.05882, 0.011109 and 7.485e-5 at the first four times. At 0.515 s predicted slip is
−0.151742 (< −0.14), entering release with
`p = tau_lock = 0`. At 0.525 s phase returns to increase, but rate remains zero:
both `15*tau_lock` and `1.5*tau_lock` are zero. At 1 s predicted slip is +0.001823
and phase is increase, yet pressure and rate remain zero. This traces the missing front
recovery to zero lock-pressure memory, rather than insufficient grip.

**Low grip (road grip ×0.3):** rule ON reaches vx < 0.5 m/s 16.4 s after the pedal at
190.445049116 m; minimum slip above 3 m/s is −0.0493111 front / −0.105156 rear. The default
`stop = 28` run fails `Unstable` at 24.565 s during prolonged parking, consistent with the
known tire singularity; the `stop = 20` rerun succeeds with the same stopping distance.
HandsOn agrees at 190.472 m. Rule OFF with `stop = 12` succeeds
numerically at 95.098241553 m, but minimum front slip −17.35917766 indicates reversed wheels:
this is NOT a physical stopping-distance benchmark.

| Moved-number ledger | Before → after |
|---|---|
| Dry calibrated rule OFF → rule ON default | 33.037836314 → 59.409163717 m; 45.3137 → 0.98865324% machine |
| Dry enabled, old calibration → rebased calibration | 38.836 → 59.409163717 m; old motor 5930 J / friction 360743 J / share 1.617% |
| Dry shaft / friction / tire / battery, rule OFF → default ON | 160.119 / 193.238 / 27.301 / 154.841 → 3.502 / 350.708 / 31.458 / 2.979 kJ |
| Dry time after pedal / recovered Wh / equivalent WLTC distance | 2.705 / 43.01 / 320 → 5.100 s / 0.828 Wh / 6.16 m |
| Dry penalty over friction-only | 6.100 → 32.471 m |
| Low grip minimum front slip, enabled / disabled | −0.04931 / reversed → −0.04931 / −17.35918 (above 3 m/s) |
| Low grip rule ON, old → rebased | 275.02 → 190.445049116 m |
| Low grip rule OFF, old → rebased (reversed wheels; nonphysical) | 112.35 → 95.098241553 m |
| Old dry rule OFF before recalibration, regen / friction only | 36.22 / 38.82 m (historical only) |

WLTC is untouched: 23.85% recovered share, 34.25 Wh/km recovered, 131.15 Wh/km consumption.
Current tests: `regen` 97 pass / 1 broken; `abs` 84 pass; `esp` 159 pass;
`planar_wltc` 36 pass / 1 pre-existing broken initialization case. Groups run separately in the required Julia runtime.
No figure export in this follow-up. Lecture 4 data changed for `07-regen-hard-stop.svg` and
`07-hard-stop-split.svg`; notebook source now uses the coordinated default. Lecture 3
carry-forward changed figures are `03-brake-steer-path`, `03-brake-steer-forces`, `05-esp-abs`
and `05-split-mu`; all SWD plots also depend on the calibration.

### Pressure-memory recovery follow-up — current evidence

**Fix:** `Vehicle.ABSModulatorDiscrete` falls back to its existing `k_inc_fast` and
`k_inc_slow` ramps when recorded friction lock torque is below `tau_memory_min = 1 N·m`
(assumed). A release caused by external axle torque is not a friction-pressure estimate.
Searching upward toward demand is appropriate until a useful friction lock pressure is
recorded; pressure stays clipped to demand and slip still selects decrease/hold/increase.
Actual lock memory, release target and decrement law are unchanged. No tire/ABS calibration
or RegenBlend tuning changed. This shared modulator serves both one-wheel and planar ABS.

The original trace was reproduced in Julia: at 0.515 s predicted slip −0.15174184 captures
`p = tau_lock = 0`; at 0.525 s phase is increase but `rate = 0`, and at 1 s pressure is
still zero despite predicted slip +0.00182267. With the fix, at 0.525 s pressure is
200 N·m / rate 40000 N·m/s; at 0.55 s 600 / 16000; at 0.6 s pressure is 1400 N·m.
At 0.8 s a real 1254.87 N·m lock memory supports memory-scaled recovery.

An initial candidate treated any memory below one initial-build tick as unknown. It changed
the one-wheel snow reference from 141.3 to 123.01 m and invalidated the estimator teaching
comparison (`abs`: 82 pass / 2 fail). That threshold was too broad: small but real lock
pressures are meaningful on low grip. The final threshold is only 1 N·m, separating absent
pressure from useful low-grip memory; the failed candidate is not the committed formulation.

All distances below start at pedal 0.5 s, end at first vx < 0.5 m/s on a 5 ms grid.
Energies are end-of-run integrals; shaft input/output remain separate, not silently netted.

| Dry 80 km/h quantity | Before → after |
|---|---|
| Rule ON distance / time after pedal | 59.409163717 → 27.102036224 m / 5.100 → 2.340 s |
| Rule ON shaft in / out | 3501.911496 / 5010.979664 → 2951.278652 / 6479.217812 J |
| Rule ON friction / tire | 350708.377370 / 31457.672893 → 348907.684116 / 35277.237330 J |
| Rule ON battery positive recovery | 2979.353015 → 2956.884659 J (0.828 → 0.821 Wh) |
| Rule ON gross motor / friction share | 0.98865324 / 99.01135 → 0.83876751 / 99.16123 % |
| Rule ON min front / rear slip, vx > 3 | −0.0243273 / −0.0935963 → −0.1260722 / −0.0905537 |
| Rule ON distance penalty over friction-only | 32.471264985 → 0.164137493 m (0.6093%) |
| Rule OFF diagnostic distance / time | 33.037836314 → 27.238292677 m / 2.705 → 2.425 s |
| Rule OFF shaft in / out | 160119.109 / 0.217 → 91401.848027 / 61800.443694 J |
| Rule OFF friction / tire / battery positive recovery | 193237.591 / 27300.500 / 154840.805 → 226903.189571 / 124152.388374 / 92809.448651 J |
| Rule OFF gross motor share / min front slip | 45.3137 → 28.7152 % / approximately −0.1 → −5.893705 |
| Friction-only BEV distance / time | 26.937898732 / 2.335 s → unchanged |
| Friction-only BEV brake / tire energy | 352732.323 / 34555.337 J → unchanged |

**Keep dry withdrawal ON.** It is shorter than OFF and keeps front slip above −0.2
in the sampled vx > 3 m/s window.
OFF now reverses front wheels above 3 m/s, so its distance and positive-only recovery are
not physical regen benchmarks. ON is within the explicit 1% tolerance of friction-only;
the broken no-penalty test becomes a passing `distance <= 1.01 * friction_distance` assertion.
This does **not** meet the meaningful motor-share goal: front-active withdrawal suppresses
regen almost throughout the stop. Shaft output exceeds shaft input in this run; 0.839% is
a gross positive braking share, not net recovery. Coordinated allocation would be a separate
change, not further friction-ABS tuning.

Low grip ON: 190.445049116 → 87.594615426 m, 16.400 → 7.665 s after pedal;
minimum front/rear slip above 3 m/s −0.0493111/−0.105156 → −0.187106/−0.104377.
OFF remains 95.098241553 m with minimum front slip −17.35918 (reversed, nonphysical).
The 20 s ON run now fails at 15.835 s during parking, well after the stop at 8.165 s;
use `stop = 12` for the library and HandsOn measurements/tests instead of extending parking.

No figure export. Lecture 4 data changed: `07-regen-hard-stop.svg`, `07-hard-stop-split.svg`.

**ABS-alone regression (baseline constructor versus fixed constructor, same runtime):**

| Case | Before → after |
|---|---|
| Straight friction, 80 / 100 km/h | 26.517044326 / 41.028141818 m → unchanged |
| Uniform grip ×0.3 | 85.728401494 → 85.728401494 m |
| Split-µ ABS-only actual stop Δx | 43.876445292 → 43.876445292 m |
| Split-µ rear select-low actual stop Δx | 52.022576445 → 52.022576445 m |
| Split-µ select-low + P ESP actual stop Δx | 54.162140463 → 54.162140463 m |
| Split-µ select-low + PI ESP actual stop Δx | 78.916918307 → 78.916918307 m |

Split-µ deck checkpoints are also unchanged: ABS-only at vx < 3 m/s is
101.3666° / y 7.5281 / absolute x 52.6865 m at 3.090 s; select-low is
20.8106° / 7.0764 / 62.2867 at 4.590 s; P ESP is 20.1060° / 6.8543 / 64.4233
at 4.705 s; PI at 6 s is 3.0224° / 3.1512 / 86.2477 m. These absolute x checkpoints
are not pedal-relative stopping distances. Full stops were measured with a 10 s horizon.

`abs`: 84 → 84 pass. `esp`: 159 → 159 pass. `planar_wltc`: 36 pass / 1 pre-existing
broken → unchanged. Regen WLTC assertions still reproduce 23.85% recovered share,
34.25 Wh/km recovered and 131.15 Wh/km consumption; its equations were not changed.
HandsOn low-grip stop is 87.604052512 m, versus library 87.594615426 m (both `stop = 12`,
Success), replacing 190.472 m. The dry HandsOn/library equivalence assertions pass.

Brake-and-steer and all seven ESP+ABS SWD amplitudes reproduce the baseline exactly in
these runs. Path distance remains 28.295190840 m; obstacle/rest offset 2.641548910 /
4.004687390 m; final heading 27.986659538°, peak yaw 20.759086473°/s, minimum front slip
−0.126814348 and mean front lateral force 3372.447339 N. SWD end speeds remain
20.9600/19.2299/18.6562/18.4697/18.4234/18.7715/18.8710 m/s; the YRR, responsiveness and
minimum-slip data also match. Lecture 3 figures therefore have no new data changes in this
follow-up (the earlier #156 export backlog above remains historical).

**Which regen limit binds:** initially demand binds (0.505 s, 61.03 N·m); by 0.515 s the
80.5 kW envelope binds (137.20 N·m at 79.92 km/h). Then withdrawal dominates: at 0.55 s
allow 0.3114 gives 42.87 N·m; at 0.6 s allow 0.05882 gives 8.19 N·m; at 0.8 s allow
7.485e−5 gives 0.01138 N·m, while front friction supplies 1226.13 N·m. The underlying
hardware envelope switches from charge power to 320 N·m at 34.27 km/h, then to linear fade
below 10 km/h, but withdrawal keeps actual regen near zero through 2.7 s. Below the ABS
cutoff it returns under the fade: at 2.8 s / 2.795 km/h allow 0.16473 gives 14.73 N·m.
Peak electromagnetic recovery is 78.957 kW; peak battery-terminal recovery 75.829 kW.
OFF peaks are 78.991 / 75.897 kW, but wheel reversal invalidates its low-speed hardware
tracking interpretation. The old all-times current-loop tracking assertion failed by
65.56 N·m in that reversed-wheel regime; it is now checked only while vx > 3 m/s and
front slip > −0.2, rather than changing the machine to fit a nonphysical comparison.


Final groups, run one at a time with Julia +dyad-3.5.0: `abs` 84 pass; `esp` 159 pass;
`regen` 97 pass / 1 broken → 102 pass / 0 broken; `planar_wltc` 36 pass / 1 pre-existing
broken. Compile: `npx -y @juliacomputing/dyad-cli@3.5.0 compile .` (existing mixed-clock
warning only); generated output is compiler-produced. No figure exports or WLTC changes.

### #162 course audit — every slide, guide, doc and figure against the recalibrated models

Rebased on `origin/main` 08a2c2e (PR #160, the drive simulator); no conflicts, compile clean.
Every number and figure from a model #161 and #162 changed (decks and speaker notes, guides,
notebooks, docs, `sim/`) was re-run and compared; everything not listed below matched.

- **One-wheel ABS is unchanged.** `ABSBrakeTransient` (μ 1.0/0.8/0.5/0.3/0.1, `a_ref` 8 and 2.4,
  default and Tsit5) and `IdealModulatorBrakeTransient` are byte-identical to `origin/main`; its
  defaults did not move. Only `ABSLockedWheelRecoveryTransient`, which starts with zero lock
  memory, moves (rim speed at 0.5 s 24.14 → 23.70 m/s); it still spins up within 0.1 s and is
  quoted nowhere. Lecture 3 section 3's one-wheel slides and figures stand; the GR-only legacy
  exports were not needed.
- **Figures.** The steer, ESP and Lecture 4 regen exports reproduce the committed
  `03-brake-steer-*`, `05-esp-abs`, `05-split-mu` and `07-*` SVGs up to element ids. The four
  sine-with-dwell SVGs (GR, 23bd4bb) come from models without ABS in the loop; the export prints
  the same numbers, so they stay. `step05-regen-blend.png` predates the ABS rule's
  `front_active` → `abs_active` wire and needs a new Studio capture.
- **Text fixed:** the run sheet's split-µ heading (129° → 101°) and through-ABS slip
  (−0.09 → −0.13); the ESP plausibility research's split-µ and planar ABS rows (now in band:
  26.5 m, ε 0.95); the BEV validation note's items 7 and 8 (100 km/h: 41.48 m with regen,
  41.57 m friction only; regen withdrawn under ABS on the hard stops); the drive simulator's
  braking observations, re-run (below 34 km/h `PlanarBEVDrive`, which has no ABS rule, turns
  the front wheels backward under regen alone); stale "not re-exported" notes; the Lecture 4
  guide's `RegenBlend` snippet, whose first docstring sat on the wrong line.
- **Open:** `PlanarBEVLowGripStopTransient()` and `HandsOn04.BEVLowGripStopTransient()` still
  default to `stop = 28` and fail `Unstable` at 15.835 s with withdrawal on, after stopping at
  8.165 s; the guide tells students to pass `stop = 12`.
