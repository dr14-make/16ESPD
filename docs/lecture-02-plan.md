# Lecture 2 — Engines and their control systems: design

The design document for the second half of Lecture 2. Read this first; the companion files hold the
detail:

| Document | Holds |
|---|---|
| `lecture-02-plan.md` (this file) | scope, thesis, model ladder, settled decisions, reality anchors, tiers |
| `lecture-02-dyad-tasks.md` | component specs, ground rules, acceptance criteria |
| `lecture-02-dyad-prompts.md` | the Dyad agent prompts, copy-pasteable, in build order |
| `lecture-02-notebooks.md` | notebook specs, cell by cell |
| `lecture-02-notebook-prompts.md` | the notebook agent prompts, copy-pasteable, with dependencies |
| `lecture-02-engine-research.md` | the research phase: slide inventory, stdlib survey, candidate list |
| `research_notes/Engine control systems/teaching_materials.md` | external sources, with verification status |
| `research_notes/Passenger car brake system modeling/engine_manifold_vacuum.md` | throttle and manifold equations and numbers |

## Source and scope

`materials/ControlTheory/2. Engine CS.pptx`, slides 16–59. Slides 2–15 (control basics, PID,
Ziegler-Nichols) are covered by the Lecture 1 notebooks and are out of scope here.

## Thesis

**An engine control unit is a stack of control loops wrapped around one nonlinear plant.**

Lecture 1 treated the engine as a first-order-plus-dead-time block (`Vehicle.IdealEngine`) and
tuned a cruise controller around it. This lecture opens that block. Students build the plant the
ECU actually controls, then add the ECU's functions one at a time: feed-forward fuel metering, the
injector that executes it, the lambda loop that corrects it, idle speed, spark and knock, and
finally the torque structure that answers the driver's pedal. Most figures in slides 44–58 are
outputs of a model, so every notebook regenerates at least one deck figure from first principles
and shows it next to the original.

## The model ladder

| Level | Model | What it adds | Notebooks |
|---|---|---|---|
| E0 | `Vehicle.IdealEngine` (Lecture 1, unchanged) | FOPTD torque | reference only |
| E1 | `Engine.MeanValueEngine` | throttle, manifold filling, speed-density air, torque production with spark and λ efficiency, friction, pumping, crankshaft | 03, 07, 11 |
| E2 | E1 + fuel film + exhaust transport + λ sensor + catalyst | the λ path | 04, 06 |
| E3 | ECU blocks closed around E1/E2 | fuel metering, λ loop, idle loop, knock, torque structure | 04, 06, 07, 08, 11 |

Component-level and cycle-level models sit beside the ladder rather than on it:
`SingleCylinder` (crank-angle cycle, notebook 02), `FuelInjector` (05), `IgnitionCoil` (08),
`NTCSensor` and `HotFilmMAF` (09), `CoolingCircuit` (10), `RoadLoadEnergy` (01).

## Settled decisions

These are settled so that agents do not relitigate them. Each one gives its reason.

**S1 — Three time scales, three separate models; never stack them.** Crank-angle events
(SingleCylinder, injector, coil) happen in milliseconds. Mean-value dynamics (manifold, λ,
crankshaft) take 0.01–1 s. Thermal warm-up takes minutes. One model spanning all three would be
stiff and unreadable. Results cross scales as parameters or tables: for example, the MBT spark
advance found in notebook 02 becomes the `sigma_mbt` table the mean-value engine reads.

**S2 — Mean value, causal signals for air and fuel; acausal where the stdlib has the domain.**
Air path, fuel path, exhaust and catalyst are written as causal signal-level components (flows and
pressures as `RealInput`/`RealOutput`), as the brake report recommended for the manifold. The
equations are two lines each and must be visible to students. The crankshaft uses a rotational
`Spline`, so the engine connects to `Driveline` and `CarPlant`. The injector and coil use
`ElectricalComponents` and `TranslationalComponents`. Cooling uses `ThermalComponents`.

**S3 — Torque model: physical efficiency chain, air-limited.**

    T_i   = eta_i(N) * M_sigma(sigma_mbt - sigma) * M_lambda(lambda) * H_l * (mdot_cyl / AFR_s) / omega
    T_e   = T_i - V_d/(4 pi) * (FMEP(N) + (p_exh - p_m))

Torque follows air, as in a real SI engine. Fuel sets λ, and λ sets efficiency through `M_lambda`.
This is the MathWorks SI Core Engine structure (spark-retard multiplier on inner torque, then
friction), which the materials survey verified. The Crossley & Cook torque polynomial is not
used as the model, because its exponents were restored from a bad text extraction. It may be
plotted beside ours in notebook 03 as a published comparison once checked against the PDF.

**S4 — The engine: 1.5 L naturally aspirated four-cylinder, port injection.** Displacement 1.5 L
and manifold volume 1.0 L, the MathWorks defaults the brake plan's increment 2a already uses.
Peak torque target 140–150 N·m, consistent with Lecture 1's `T_max = 150 N·m` (a Mazda
Skyactiv-G 1.5-class engine). Idle at 800 rpm, matching the brake plan.

**S5 — The air path is shared with the brake plan.** Brake plan increment 2a specifies an
`IntakeManifold` (inputs θ, N and booster inflow; output `p_m`) and has not been built yet. This
lecture builds it once, as `Engine.Throttle` + `Engine.IntakeManifold` + `Engine.CylinderAirflow`
assembled into `Engine.AirPath` with exactly the 2a interface. The 2a "done when" criteria are
adopted as this lecture's air-path acceptance criteria, so building task 1 completes 2a. Update the
brake plan to point at `Engine.AirPath` when task 1 lands.

**S6 — `MeanValueEngine` ships beside `IdealEngine`; Lecture 1 is untouched.** Lecture 1's
regression tests pin FOPTD numbers. The capstone builds a new `EngineCarPlant` instead of editing
`CarPlant`.

**S7 — Discrete logic as continuous latches; no events.** This is the house rule from
`ABSController` and the brake plan. The two-step λ controller, knock retard, fuel cut-off, rev
limiter and fan hysteresis all use `ifelse`/`min`/`max`. Where a sign function makes the solver
step across a discontinuity, it is smoothed with `tanh(e/eps)`, and a test shows the result
does not depend on `eps`.

**S8 — Speed-dependent delays as a speed-scheduled lag chain.** The induction-to-exhaust and
exhaust-to-sensor delays shrink as the engine speeds up. That is the whole reason the λ limit cycle
gets faster with rpm, and it is a headline result of notebook 06. `PadeDelay` takes a structural,
constant delay, so it cannot do this. Use a chain of `n` first-order lags whose time constants are
`theta(omega)/n`, with `n` chosen in task 5 (decision D2 in the tasks file). Constant-speed tests
compare it against `PadeDelay`.

**S9 — Notebooks are Pluto (`.pluto.jl`), like Lecture 3.** Sliders (`@bind`) make the spark
angle, controller gains and engine speed live knobs on the projector. Notebooks reuse
`notebooks/lecture01/support.jl` the way `notebooks/lecture03/01-abs.pluto.jl` does, plus a new
`notebooks/lecture02/support.jl` for engine signal names and plot helpers. Model construction and
solving stay out of notebook cells.

**S10 — Numbers carry their provenance.** As in the brake plan, every default's docstring is
tagged `(MathWorks)`, `(Bosch)`, `(EPA ALPHA)`, `(Brandt)`, `(Di Cairano)`, `(deck)`, `(textbook)`,
`(derived)` or `(assumed)`. The injector, coil, MAF and two-step sensor have no open OEM data (see
the survey's gaps), so their values are `(assumed)`, they are tuned to the timing bands below, and
the notebooks say so.

## Reality anchors

A model that lands outside a band is wrong, or it needs a stated reason, even if it runs cleanly.
These are the acceptance bands the tasks file refers to.

| Quantity | Band | Source |
|---|---|---|
| Idle manifold pressure, 800 rpm, throttle closed | 30–36 kPa abs (calibrate to 33) | brake plan 2a; `engine_manifold_vacuum.md` |
| Wide-open-throttle manifold pressure | > 90 kPa abs | brake plan 2a |
| Overrun (closed throttle, 3000 rpm) manifold pressure | below idle; 17–34 kPa | `engine_manifold_vacuum.md` |
| Manifold time constant at 800 rpm | 0.08–0.2 s (predicted 0.125 s) | derived, τ_m = 120·V_m/(η_v·V_d·N) |
| Manifold time constant at 3000 rpm | 0.02–0.05 s (predicted 0.033 s) | derived |
| Peak brake torque, 1.5 L NA | 130–150 N·m (BMEP 1.1–1.25 MPa) | derived from S4; Skyactiv-G 1.5 class |
| Peak brake efficiency | 33–38 % | deck slide 23 (37 %); EPA ALPHA maps |
| Minimum BSFC | 225–260 g/kWh | derived from the efficiency band, H_l = 43.4 MJ/kg |
| Idle fuel consumption | 0.4–0.9 L/h | assumed (to verify against ALPHA idle points) |
| Torque loss at 10° retard from MBT | 2–5 % | textbook MBT-curve shape (assumed coefficient) |
| Peak cylinder pressure location at MBT | 12–20° ATDC | textbook rule of thumb (Heywood, unverified) |
| λ excursion under the two-step loop | ±2–3 % | deck slide 57 |
| λ limit-cycle frequency | 0.5–5 Hz, rising with engine speed | derived (period ≈ 4 × loop delay); assumed band |
| Injector opening dead time | 0.6–1.0 ms at 14 V; 1.5–2.5 ms at 8 V | EV14 retailer table (14 V 0.80 ms, 12 V 0.90, 8 V 2.00): not verified at Bosch |
| Injector coil resistance | 12 Ω | Bosch EV14 datasheet (verified) |
| Injector needle lift | 0.05–0.1 mm | deck slide 43 (0.05 mm) |
| Injector static flow at 3 bar | 146 cm³/min (EV14 smallest variant) | Bosch EV14 datasheet; matches the 6000 rpm WOT demand derived for S4 |
| Coil dwell for full charge at 14 V | 2–4 ms; stored energy 30–100 mJ | assumed (no open OEM source) |
| Secondary peak voltage, open circuit | up to 30 kV | deck slide 48 |
| Idle speed floor during a load step | ≥ 450 rpm | Di Cairano et al. 2008 constraint |
| λ sensor operating temperature | > 300 °C | deck slide 58 |
| Warm-up, 20 → 90 °C coolant at light load | 4–10 min | derived from lumped masses (assumed) |
| Thermostat opening | 85–95 °C | assumed |

## Notebooks and tiers

| # | Notebook | Deck figure regenerated | Tier |
|---|---|---|---|
| 01 | Where the energy goes | slides 16–18 resistance terms over a WLTC cycle | 2 |
| 02 | The cycle and the spark | slide 50 pressure traces; MBT curve; slide 20 p–V | 2 |
| 03 | The engine as a plant | where Lecture 1's lag and delay come from; maps | **1** |
| 04 | How much fuel | slide 44 pulse-width formula and AFR map; tip-in λ spike | **1** |
| 05 | Inside an injector | slide 45 current, needle lift, fuel quantity | **1** |
| 06 | Lambda control and the catalyst | slide 57 jump/ramp limit cycle; slide 58 curve | **1** |
| 07 | Idle speed control | new loop; reuses Lecture 1 tuning | 2 |
| 08 | Ignition coil, dwell and knock | slides 52–53; knock sawtooth | 3 |
| 09 | Sensors | slides 36–37 characteristics | 3 |
| 10 | Warm-up and cooling | slide 28 warm-up strategy | 3 |
| 11 | The whole ECU in the car | slides 24–25; resolves Lecture 1's "246 km/h is too high" | 3 |

**Tier 1 (03–06) is a complete lecture half on its own**: plant → feed-forward fuel → actuator →
the λ feedback loop. Build strictly in order, so that time pressure cuts from the end.

    1. Dyad tasks 1-5 -> notebooks 03, 04, 05, 06      --- the lecture is safe from here ---
    2. Dyad tasks 6-8 -> notebooks 02, 07, 01
    3. Dyad tasks 9-12 -> notebooks 08, 09, 10, 11

Task 4 (injector) and task 6 (single cylinder) depend on nothing and can run in parallel with the
mean-value chain.

## Workflow

- One Dyad task or notebook per branch and PR, in its own worktree (`wt switch --create`).
- A Dyad task is done when its acceptance criteria pass and are reported as numbers. A notebook is
  done when it executes headless and its check cells pass.
- Testing has three layers, as in the brake plan: Dyad `test component` regressions (the `tests`
  metadata block), a plausibility suite `test/engine_plausibility.jl` checking the reality anchors,
  and the notebooks for shapes a number cannot capture. The generic helpers the brake plan
  specifies (`rise_time`, `max_rate`, `cycle_frequency`) do not exist yet. Whichever task needs
  them first creates `test/plausibility_helpers.jl`, and both suites include it rather than
  copying.

## Agent quick start

Everything an agent needs to pick up a task cold. Commands assume the repository root.

| Purpose | Command or path |
|---|---|
| Compile `dyad/` into `generated/` | `~/.dyad-maxwell/dyad-lang/apps/cli/dyad compile .` |
| Run the test suite | `cd test && julia +dyad-3.4.0 --project=.. runtests.jl` (never from the root; see HANDOVER gotchas) |
| Load the library interactively | `julia +dyad-3.4.0 --project=.`, then `using VehicleSystemsComponents` |
| Run a Pluto notebook headless | `julia +dyad-3.4.0 --project=. notebooks/lecture02/<file>.pluto.jl` (the `@bind` mock supplies defaults) |
| Dyad language reference | `agent_resources/skills/dyad-language/SKILL.md`, then `agent_resources/docs/{syntax,components,initialization,analyses,metadata}.md` |
| Standard-library source | `agent_resources/stdlib_reference/<Library>/<Path>.dyad`, e.g. `BlockComponents/Tables/InterpolatedTable.dyad` |
| Analyses (transient, steady state, linear, closed loop) | `agent_resources/docs/analyses.md`; DyadControlSystems analyses in `~/.julia/packages/DyadControlSystems/*/dyad/` |
| Build pitfalls already paid for | `docs/HANDOVER.md` § "Gotchas found during the build"; read it before the first compile |
| House patterns to copy | continuous latches: `dyad/Vehicle/ABSController.dyad`; test metadata: `dyad/Vehicle/Wheel/SlipWheel1D.dyad`; harness + analysis: `dyad/Lecture1/CarStepTest.dyad`; source tags and test layers: `docs/brake-system-implementation-plan.md` |
| Notebook pattern to copy | `notebooks/lecture03/01-abs.pluto.jl` (setup cell, `@bind`, helper reuse); helper API in `notebooks/lecture01/support.jl` (`setup`, `signal`, `sweep`, `rerun`, `show_dyad`) |
| Deck figures | `materials/ControlTheory/2. Engine CS.pptx`; unzip it and the images are under `ppt/media/` (map below) |
| Engine equations and sources | `research_notes/Engine control systems/teaching_materials.md` §3; manifold: `research_notes/Passenger car brake system modeling/engine_manifold_vacuum.md` |

Deck figures each notebook regenerates (file names inside `ppt/media/` of the unzipped deck):

| Slide | Figure | Media file |
|---|---|---|
| 16 | vehicle resistance equations | `image140.png`–`image180.png`, `image19.png` |
| 17 | rolling-resistance coefficient table | `image20.png`, `image21.png` |
| 20 | Otto cycle p–V | `image23.gif`, `image24.png` |
| 44 | AFR map vs speed and load | `image53.png` |
| 45 | injector activation, current, lift, fuel quantity | `image54.png` |
| 50 | combustion pressure vs ignition angle | `image62.png` |
| 51 | NOx, HC, fuel consumption vs timing and λ | `image63.png`, `image64.png`, `image65.png` |
| 57 | two-step λ control, manipulated variable vs sensor voltage | `image75.png` |
| 57 | λ sensor installation, two- and three-sensor control | `image76.png` |
| 58 | ZrO₂ sensor characteristic | `image77.jpeg`–`image79.jpeg` |

Notebooks copy the figures they show into `notebooks/lecture02/assets/`.

## Known limits

- No gearbox: the capstone keeps Lecture 1's fixed ratio `i = 4`, so engine speed is tied to
  road speed. That is enough to show the rev limiter and a realistic top speed. Gear selection is
  a later lecture.
- No turbocharging, EGR, variable valve timing or direct injection. Slide 42 (GDI) and slide 26's
  valve timing stay descriptive.
- No emissions chemistry beyond catalyst oxygen storage. NOx/HC versus spark (slide 51) is shown as
  the deck's figure, not simulated.
- Cylinder-individual effects (misfire, individual-cylinder λ) are out of scope for the mean-value
  engine.
