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

    [ ] Task 1  Vehicle components                 IN PROGRESS (Dyad agent)
    [ ] Task 2  CarPlant, GradeProfile
    [ ] Task 3  CruiseLoop + Ziegler-Nichols gate   <-- validates the whole design
    [ ] Task 4  Clamping anti-windup
    [ ] Task 5  Sampler
    [ ] Task 6  MeasurementNoise
    [ ] Task 7  Wheel and slip

    [ ] src/ shared helper
    [ ] Notebooks 01, 03, 04, 05, 06   (Tier 1)
    [ ] Notebook 08                    (Tier 1)
    [ ] Notebooks 09, 02               (Tier 2)
    [ ] Notebooks 07, 10               (Tier 3)

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
    speed it falls back to on that climb       = 32.7 m/s = 118 km/h

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

### Risk 3 — the sampler may not be buildable as a real clocked partition

Dyad ships no sampled blocks and the `external`-component route over ModelingToolkit clocks is
unverified against this kernel. Task 5 mandates a guaranteed-working surrogate first. If the
stretch fails, notebook 09 still exists and must state plainly that it demonstrates the
mechanism rather than a real sampler.

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
- **Run the test suite from `test/`, not the repository root.** `generated/test_internals.jl`
  resolves references at the relative path `joinpath("snapshots", ...)`. `Pkg.test()` runs from
  `test/` so this works; a direct `julia test/runtests.jl` from the root finds no snapshots,
  silently skips every trajectory comparison, writes a stray `snapshots/` at the root, and
  still exits 0. The tell is the assertion count — the real suite is about 4700, the crippled
  one about 70. Use `cd test && julia --project=.. runtests.jl`.
- **Memory.** Running several agents alongside the Dyad language server exhausts this machine;
  `earlyoom` is configured to prefer killing `julia`. A run that dies with no error message was
  probably killed, not broken. Retry before debugging.

## Conventions

- Prose in English. Plant internals SI; the control loop and every speed axis in km/h, via
  `Vehicle.ToKmPerHour` on the sensor output. Controller gain `k` is therefore N.m per km/h.
- Model construction and solving go in a shared helper under `src/`; notebook cells stay thin
  so the later Pluto port is a rebind rather than a rewrite.
- Never edit anything under `generated/`.
- Comments explain why — a constraint, an invariant, a gotcha. Not what the code says, and not
  the history of how it got there.
