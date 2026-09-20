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

### Risk 1 — theta_e = 0.04 s is probably too small for the Ziegler-Nichols demo

This is the one that can cost a Tier 1 notebook. Linearizing about 30 m/s:

    vehicle drag slope    dF/dv = 2*0.378*30.6  = 23.1 N/(m/s)
    vehicle time constant m/(dF/dv) = 1400/23.1 = 60.6 s      (very slow)
    plant DC gain, torque to speed  (i/r)/23.1  = 0.559 (m/s)/N.m

With theta_e = 0.04 s the loop crosses -180 degrees at roughly 29 rad/s, giving an ultimate
period of about 0.22 s and an ultimate gain around 27,000 N.m per m/s. At that gain a
hundredth of a m/s of error saturates a 150 N.m engine, so what the agent will find is relay
limit-cycling against the torque limit, not the clean linear sustained oscillation that
Ziegler-Nichols assumes.

**Lever:** raise `theta_e`. At theta_e = 0.3 s the crossing moves to about 2.9 rad/s, Pu to
roughly 2.2 s, and Ku to around 420 — which oscillates at torque amplitudes well inside the
limit. A 0.2-0.3 s delay is defensible if it is framed as the whole powertrain torque-response
path (ECU, fuelling, combustion, driveline compliance) rather than injection alone, and that
framing is also more honest about what the model lumps together.

Task 3 is written to make the agent report a missing `Ku` rather than work around it. If that
report arrives, raise `theta_e` first before touching anything else.

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
| Slip model | 1D, on the multibody friction-curve shape | the 3D slip models are high-index DAEs, far too heavy for an introductory lecture |
| Unit conversion | a Dyad component on the sensor output, not notebook arithmetic | the conversion is visible as a block in the diagram, and a plotted signal is never transformed after the fact |
| Loop units | the whole control loop runs in km/h | setpoint, measurement and error are all km/h, so every gain in every notebook means the same thing and the numbers match a dashboard. Plant internals stay SI; exactly one conversion exists, at the sensor |

## Conventions

- Prose in English. Plant internals SI; the control loop and every speed axis in km/h, via
  `Vehicle.ToKmPerHour` on the sensor output. Controller gain `k` is therefore N.m per km/h.
- Model construction and solving go in a shared helper under `src/`; notebook cells stay thin
  so the later Pluto port is a rebind rather than a rewrite.
- Never edit anything under `generated/`.
- Comments explain why — a constraint, an invariant, a gotcha. Not what the code says, and not
  the history of how it got there.
