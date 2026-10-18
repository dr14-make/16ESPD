# Roadster presentation notebook — design

Design for issue #64's lecturer-driven Pluto notebook, "Tesla Roadster: is it physically
possible?". The story, baseline car and acceptance bands are in `docs/roadster-dyad-tasks.md`;
claims and sources are in `docs/research_notes/Roadster plausibility/sources.md`. This file decides
how the notebook runs live. The notes marked "as built" record where the notebook departs from
the original plan.

## Decisions at a glance

- **One notebook**, `notebooks/roadster/02-is-it-possible.pluto.jl`. All the sections share the car
  sliders, the prebuilt problems and the scoreboard, and they pay the cold compile once.
- **Every live slider calls `remake` on a problem built once at load.** No slider calls an
  analysis constructor. A warm `remake` + `solve` takes 4–25 ms. A warm analysis call takes 5 ms
  to 11 s, depending on the analysis.
- **Hover is solved live** through `remake`, like every other section. The Hover analysis is
  deterministic since it runs without automatic discontinuity detection.
- **The scoreboard is a fixed panel** in the bottom-right corner, with the two car sliders (mass
  and drive layout) pinned directly under it, so they stay in reach in present mode.
- **Narrative order:** introduction, the videos, knowns and assumptions, a warm-up, then one
  section per Tesla claim (claim, physics check, model, simulation, verdict), then the
  scoreboard and a summary.
- **Plain language.** Short sentences, every symbol defined where it first appears, one idea per
  slide, and a reading guide under every plot.
- **Plots.jl with GR**, through `Lecture01Support.setup()`, as in `notebooks/lecture03/`.

## 1. Interactivity budget (measured)

These were measured in this worktree with `julia +dyad-3.4.0 --project=.`, one thread, on
2026-10-18. "Warm" is the median of 5 calls after the first.

| Analysis | First call | Warm analysis call | Warm `remake` + `solve` | First `remake` + `solve` |
| --- | --- | --- | --- | --- |
| `RoadsterLaunchTransient` | 22.0 s (includes package compile) | 37 ms | 14 ms, or 25 ms at the analysis tolerances | 8.4 s |
| `SuctionFanTransient` | 0.9 s | 5 ms | not needed | — |
| `SuctionFanInvertedHoldTransient` | 0.8 s | 5 ms | not needed | — |
| `ColdGasThrustStandTransient` | 17.0 s | **0.13–8.8 s, erratic** | 4–6 ms | 9.9 s |
| `Hop` | 11.9 s | **10.4 s** | 8–9 ms | 10.0 s |
| `Hover` | 11.3 s | **11.0 s** | 4 ms | — |

The three analyses with `automatic_discontinuity_detection = true` rebuild their problem on
every call, which is why they stay slow when warm. Their `remake` path is fast. So the rule is the
same for every section: build each problem once at load, then `remake(prob; p = [...])` and
`solve` with the analysis's own `abstol`/`reltol`. Without those tolerances, t60 drifts by about
0.001 s from the analysis value. `remake` gives the same result as calling the analysis directly,
to 4 decimal places, for every parameter checked: `m`, `share`/`h_over_L`, `fan_cmd`, `thrust_cmd`,
`tank_pressure` (the dependent `m0` updates), `tank_volume`, `down_fraction`, `CdA`, `mu_A`,
`T_max`, `P_max`, `skirt_gap`, nested `tank.n`, the stand's `p0`/`n`/`V` and Hop's `t_b`.

**As built, after the Hop and Hover fixes.** Both run with `automatic_discontinuity_detection =
false`, so a warm direct `Hop()` or `Hover()` call now takes 15–18 ms and a warm `remake` + `solve`
8–9 ms. `ColdGasThrustStandTransient` still uses detection. A `remake` of a problem whose analysis
solve ran to the end can restart from the callbacks' end state: before the hop fix, a remade
`Hop` at `t_b = 0.413` reached 8.19 m against the analysis's 8.01 m. The support `Rig` therefore
runs each analysis to `start + 1e-6` only, re-spans the problem, and solves the default itself.
With that, `remake` matched direct analysis calls exactly for every `t_b` checked.

**Load cost.** A cold load takes about 90 s: each problem's first build plus its first `remake`.
As built: the rig cell takes 99 s, the whole headless script 108–118 s wall, and a Pluto open
with the packages already loaded 137 s.
The lecturer opens the notebook before the session, and Pluto keeps it warm. A precompile workload
could cut this, but it adds to every lecture's package precompile, so it is left out.

**The heaviest slider move** is a `down_fraction` grid: 4 cases × 11 points, 44 solves, 1.0 s.
That is over budget, so it is computed once at load for the baseline car, and a slider moves only
the live marker (one solve). As built, the grid uses the slider's 0.05 step, 4 × 21 solves, 1.6 s at
load.

## 2. Sensitivity of t60 (measured, Δt60 in s from the default)

| Case (default t60) | P 0.5 MW | P 2 MW | CdA 1.2 | CdA 0 | T_max 20k | T_max 8k | μ 1.5 | m 1,700 | m 2,350 | p0 690 bar | n = 1 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| RWD tires (3.328) | 0 | 0 | +0.022 | −0.021 | 0 | 0 | −0.67 | +0.011 | −0.009 | — | — |
| AWD tires (2.268) | +0.097 | 0 | +0.008 | −0.008 | 0 | +0.14 | −0.37 | +0.006 | −0.005 | — | — |
| Suction, either layout (1.62) | +0.34 | 0 | +0.004 | −0.004 | −0.52 to −0.56 | +0.84 | 0 | −0.24 | +0.28 | — | — |
| RWD tires + thrust (0.554) | +0.030 | 0 | ~0 | ~0 | 0 | +0.055 | −0.015 | −0.076 | +0.094 | −0.23 | −0.021 |
| AWD tires + thrust (0.595) | +0.007 | 0 | ~0 | ~0 | 0 | +0.010 | −0.032 | −0.076 | +0.083 | −0.25 | −0.022 |
| Suction + thrust (0.532) | +0.032 | 0 | ~0 | ~0 | −0.085 | +0.077 | 0 | −0.087 | +0.105 | −0.21 | −0.016 |

Skirt gap changes no t60 by even 0.0001 s: it changes only fan power.

These are the teaching points, and the sliders are chosen to show them:
- **Tires only:** μ is the only knob that matters. Power, drag and mass do almost nothing below
  60 mph. Mass drops out because both grip and inertia scale with it.
- **With suction, the knobs that matter swap.** μ stops mattering, and torque, power and mass take
  over. That swap is the verdict of section 2.
- **With thrust, tank pressure dominates** while the throat area stays fixed. RWD beats AWD,
  because the load transfer from about 5 g of acceleration lands on the rear tires.

## 3. Sections

The notebook is organized around Tesla's claims, so a student can follow one question at a time.
Each `##` heading is one slide in present mode, and each slide carries one idea.

### Opening

1. Title, with the four steps every claim goes through, and the present button.
2. **What Tesla showed:** the five claims, numbered as the sections that follow.
3. **The videos:** the two official clips.
4. **What Tesla said, and what it did not:** each number marked T, P, M or ?.
5. **What we assume for the unknowns.**
6. **How the simulations run:** build once, `remake` per slider. The rig, reference, grid and
   hint cells sit under this slide and show only the build time.
7. **Warm-up: is the ramp video real time?** k = √(a/g), with the playback slider.

### One section per claim

| # | Claim | Physics check | Dyad model | Simulation |
| --- | --- | --- | --- | --- |
| 1 | The tires grip up to 1.26 g | needed acceleration, μg, RWD weight transfer, torque and power caps, grip needed for 1 s | `RoadsterLaunch` with `PowerLimitedMotor`, `AxleLoad`, `TractionControl` | v(t); limit map |
| 2 | Suction fan: 4,700 kg, under 1.6 s, upside down | Δp = D/A, the motor becomes the limit, leak flow and fan power | `SuctionFan` | limit map; fan power against skirt gap |
| 3 | Cold-gas thrusters: 80 kN from 600 L | ideal-gas mass, choked thrust, blowdown table from the closed form | `AirTank`, `ColdGasNozzle` on `TestColdGasThrustStand` | thrust and air against time |
| 4 | 0–60 mph in 1.0 / 0.81 / under 0.59 s | needed acceleration table, what thrust adds | the full `RoadsterLaunch` with tank, nozzle and force split | v(t); force stack; push down or back |
| 5 | "It can fly": 8 m hop, hover | √(2gh), impulse and air, hover flow, hover time against mass | `VerticalHop`, `VerticalGroundContact`, hop and hover tests | hop; hover; 3 × 3 hover table; roll budget |

Every claim section has the same four parts, in this order:

1. **Tesla's claim:** what was said, with the number and the source marking.
2. **Physics check:** a worked example. Formula, numbers in, result with units. Every symbol is
   defined where it first appears.
3. **Our model:** the Dyad diagram screenshot from `notebooks/roadster/img/`, a one-line role
   for each block, and the Dyad source under a fold.
4. **Simulation:** the sliders, the plot, and a fixed five-line reading guide under each plot:
   axes with units, what each line or color is, what to look at, what it means for the claim,
   and what to try.

Each section closes with a verdict box: green "plausible", amber "only if" or "as a peak", red
"not plausible". The closing slides are the scoreboard table, the summary, the sources and the
appendix of checks.

### Numbers in the text

Every number in the prose comes from a calculation or a model run, never from memory:

- **Worked examples** are closed forms, computed once and typed in.
- **Readings of a plot** are interpolated from the cell that drew it, so they follow the
  sliders.
- **"Try" suggestions** quote the `hints` cell, which solves the baseline car (2,000 kg, RWD)
  with one setting changed when the notebook opens: about 20 extra solves, under a second.
- **Verdicts** quote the default runs (`reference`, the rigs' `default`) and add the current
  slider value.

### Sliders

The sliders and their ranges are unchanged from the first version. They live in the simulation
slide of the claim they belong to:

- **Car panel (global):** mass 1,700–2,350 kg, step 50, default 2,000; RWD or AWD.
- **Warm-up:** playback factor k, 0.8–2.0.
- **Claim 1:** `mu_A` 1.0–1.6 (1.26), `P_max` 0.5–2.0 MW (1.0), `CdA` 0.3–1.2 m² (0.6).
- **Claim 2:** `fan_cmd` 0–1 (1), skirt gap 1–10 mm (3), `T_max` 8–20 kN·m (12).
- **Claim 3:** p0 300–690 bar (380), V 200–600 L (600), n 1.0–1.4 (1.4), throat fixed or scaled.
  Claim 4 takes its tank pressure, n and throat from these.
- **Claim 4:** thrust and suction checkboxes, 600 L or 200 L, `down_fraction` 0–1 (0).
- **Claim 5:** `t_b` 0.2–0.8 s (0.413), hover p0 300–690 bar (380), roll rate 90–360 °/s (177)
  and moment arm 0.6–1.2 m (0.9).

### Diagram screenshots

`diagrams([path => caption, ...])` in `support.jl` embeds each PNG as a data URI, so the image
travels with the notebook output. The paths resolve from the notebook's own directory. A file
that does not exist yet renders as a dashed box naming it, so a slide never shows an error:

- `img/roadster-launch.png` (Claims 1 and 4)
- `img/power-limited-motor.png`, `img/axle-load.png`, `img/traction-control.png` (Claim 1)
- `img/suction-fan.png` (Claim 2)
- `img/cold-gas-thrust-stand.png` (Claim 3)
- `img/vertical-hop.png` (Claim 5)

A diagram cell runs once when the notebook opens. An image added later appears after a re-run
of that cell or a reopen.

### Results the verdicts rest on (baseline car, measured)

- **Claim 1:** RWD 3.33 s, AWD 2.27 s; the tire limits for the whole run. 1 s would need μ ≈ 2.8.
- **Claim 2:** 1.62 s with either layout, torque-limited; 47.9 kW at 3 mm, 160 kW at 10 mm;
  downforce 2.35× weight; least hold 4,903 Pa, 13.3 kW.
- **Claim 3:** 80.0 kN at the start, below 80 % after 0.37 s, below 50 % after 1.18 s; 271 kg.
- **Claim 4:** tires + thrust 0.554 s, suction + thrust 0.532 s, 200 L 0.676 s; about 54 kg of
  air. 2,350 kg gives 0.637 s, which misses 0.59 s.
- **Claim 5:** 7.99 m apex for 43 kg at `t_b = 0.413` s; hover 5.47 s at 2,000 kg and 380 bar,
  14.3 s at best (1,700 kg, 690 bar).

## 4. Claim vs model scoreboard

A fixed `<aside>` in the bottom-right corner, about 320 px wide, rendered by one cell that depends
on every section's result. It stays visible in present mode and when scrolling.

- **Rows:** one per claim, top to bottom in story order. Each row shows the claim, Tesla's value,
  the current model value and a verdict chip.
- **Verdict chips:** green "yes", red "no", gray "—" for a value that is not finite. As built, the
  panel starts collapsed to a summary line ("n of m possible") so it does not cover plots; the
  Scoreboard slide has the same rows in full.
- **Car sliders:** `m` and the layout, so one move updates every section. As built they are a
  separate cell pinned under the scoreboard by CSS on its cell id: inside the scoreboard cell they
  would form a cycle, because every result the scoreboard shows depends on them.
- **Mobile width:** not a concern, because this runs on the lecture projector.

## 5. Notebook mechanics

- **Setup cell:** copy the shape of `notebooks/lecture03/01-abs.pluto.jl`. Include
  `notebooks/lecture01/support.jl` and `notebooks/roadster/support.jl`, and call `setup()`.
- **Present mode:** a button cell, `html"<button onclick='present()'>present</button>"`. Each `##`
  heading is a slide. `TableOfContents()` is for scrolling mode only.
- **Code:** all code cells are committed folded (`# ╟─`), and outputs show.
- **Headless done-check:** `julia +dyad-3.4.0 --project=. notebooks/roadster/02-is-it-possible.pluto.jl`
  runs to completion with the slider defaults. The last slide's check cell `@assert`s the default
  runs against the reference numbers, with the tolerance in the message.
- **Script mode runs in `Main`.** The setup cell binds the loaded package as `components`, not as
  `VehicleSystemsComponents`: `setup()` imports that name into `Main`, and a global of the same name
  in the same block conflicts with it.
- **Pluto worker mode, as found.** In this environment a Pluto worker process fails inside
  `setup()` while loading package images (`TypeError: expected Core.CodeInfo, got
  SynchJulia.DNode`). The lecture 3 notebooks fail the same way, so it is not specific to this
  notebook. Running Pluto in-process (`workspace_use_distributed = false`) with the packages
  loaded before the notebook opens works: every cell runs, and every slider re-runs without error.
  `notebooks/roadster/present.jl` does exactly that, and the title slide names it:
  `julia +dyad-3.4.0 notebooks/roadster/present.jl`.
- **Slides show only markdown, sliders, plots and rendered tables.** Every computation cell ends
  in `;` or returns `nothing`, and the rigs are built with `progress = false`.
- **Tables are HTML** (`html_table` in support), left-aligned in the text font. Pluto styles a
  bare output table as data, monospaced and right-aligned, which is unreadable for prose.
- **Videos:** the iframes carry `referrerpolicy="strict-origin-when-cross-origin"`. Pluto serves
  `Referrer-Policy: same-origin`, and YouTube's player refuses to load without a referrer
  (error 153).
- **Thin cells:** a cell is a call and a plot. `notebooks/roadster/support.jl` (module
  `RoadsterSupport`) holds the rigs and plot recipes, the same pattern as
  `notebooks/lecture02/support.jl`. Model assembly stays in `dyad/`. `src/` stays the generated
  package module, so plotting code does not become a package dependency.

## 6. Work needed before the notebook

Status as built:

1. **`notebooks/roadster/support.jl`:** done. `Rig(name, analysis; kwargs...)`, `solve_with(rig;
   kwargs...)` (not `run`, and not `simulate`, which DyadInterface exports), `t60`, `air_used`,
   `binding_limit`, `blowdown_marks`, `hop_apex`, `hover_time`, the closed forms, `limit_map`,
   `scoreboard`, and `dyad_fold`, which shows a model's Dyad source without diagram metadata
   under a fold.
2. **`CdA`, `tank_n` and `A_t` on `RoadsterLaunchTransient`, `A_t` on the stand, Hop and Hover,
   and `m`/`gap` on `SuctionFanInvertedHoldTransient`:** exposed, and the notebook sets only
   top-level analysis parameters. The "80 kN at any pressure" toggle sets
   `A_t = 1.286e-3 · 380e5 / p0`.
3. **Inverted-hold command:** the harness's `cmd` default, `−m·g / (4 · dp_max)`, does not follow
   `m`, neither through `remake` nor through `SuctionFanInvertedHoldTransient(m = 2350)`: Δp stays
   at 4,903 Pa. The notebook passes `cmd = m / 4700` itself.
4. **Hop ground contact:** fixed. The plain maximum is the apex, and `hop_apex` reads it on a
   dense grid.
5. **Hover snapshot:** not needed.
6. **Warm-up data (optional):** frame positions from the ramp clip, if a fit to real data is wanted
   instead of the stated 2.3 g.

Not needed: a burn-time parameter on the launch. The valve stays open past t60 in every
configuration, so a cutoff would not change the verdict.

## 7. Risks

- **Cold start takes about 90 s.** If Pluto restarts mid-session, the audience waits. The mitigation
  is to open the notebook early and keep the committed outputs as a fallback.
- **The pressure slider overstates thrust** with a fixed throat: 690 bar gives 148 kN, not 80 kN.
  The throat toggle in Simulation 3 keeps that honest.
- **A slider move costs 40–450 ms in Pluto**, measured in-process: 15–100 ms for the solves and
  readouts, the rest for the GR re-renders of every dependent plot. The car sliders and the tank
  sliders re-run the most cells. Check it on the projector machine.
