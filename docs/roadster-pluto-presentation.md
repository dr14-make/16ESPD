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
- **Narrative order** (as built): introduction, the videos, theory, knowns and unknowns,
  technology, closed forms without simulation, the Dyad simulations, verdicts.
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

Each section is one `##` heading, so it is one slide in present mode. Each one ends with its
verdict and a "what this bought us" line that names the next section. Each one shows its model
once with `show_dyad`. Defaults are the baseline car, and check cells assert on the default
solution, never on the slider-bound one.

### Car panel (inside the scoreboard, global)

- `m`: 1,700–2,350 kg, step 50, default 2,000.
- Layout: `Select(["RWD", "AWD"])`, which maps to `share`/`h_over_L` = 0.55/0.17 or 1/0.

### 0. Warm-up: is the ramp video real time?

- **Method:** closed form only. Playing a clip k times too fast scales the apparent acceleration by
  k², so k = √(a_measured / g).
- **Data:** the repo has no frame data. The section shows the stated fits from `sources.md`: the
  ramp's early fall at 2.3 g gives k ≈ 1.52, and the kickflip's −0.92 g gives k ≈ 0.96, which is
  real time. If a CSV of frame positions is later added under `notebooks/roadster/assets/`, the
  same cell fits it by least squares.
- **Slider:** playback factor k, 0.8–2.0.
- **Plot:** fall distance against video time. The 2.3 g "measured" parabola is overlaid with a
  1 g parabola replayed at k.
- **Scoreboard row:** "Ramp shot plays in real time" — model: about 1.5× sped up.

### 1. Tires only: 0–60 under 1 s?

- **Solve:** a launch problem, `remake` per move. Each move also solves the other layout as a ghost
  curve, so two solves, about 50 ms.
- **Sliders:** `mu_A` 1.0–1.6 (1.26); `P_max` 0.5–2.0 MW (1.0); `CdA` 0.3–1.2 m² (0.6). The power
  and drag sliders exist to show that they do nothing.
- **Plots:**
  - v(t), with a 60 mph line, Tesla's 1.0 s recorded and 0.81 s live markers, and the other layout
    as a ghost.
  - **The limit map,** the hero plot that sections 2 and 4 reuse: force at the wheel against speed.
    It shows the grip line `mu_A·F_z` (from the solution), the torque cap `T_max/r` (horizontal),
    the power hyperbola `P_max/v`, and the delivered `F_x(v)` trajectory. The binding limit is the
    lowest curve.
- **Verdict:** No. RWD takes 3.33 s and AWD 2.27 s, limited by grip, not by power.
- **Scoreboard row:** "0–60 under 1 s on tires" — model t60.

### 2. Suction fan

- **Solve:** a launch problem with `fan_cmd`, `skirt_gap` and `T_max`, through `remake`. The fan
  and inverted hold call the analyses directly, because they take 5 ms warm.
- **Sliders:** `fan_cmd` 0–1 (1); skirt gap 1–10 mm (3); `T_max` 8–20 kN·m (12).
- **Plots:**
  - The limit map again. The grip line now sits above the torque cap, which shows the limit moving
    from the tire to the drive.
  - Fan power against skirt gap, from the closed form `Q·dp/η` as a curve, with the
    `SuctionFanTransient` operating point at the current gap. The 3 mm (48 kW) and 10 mm (160 kW)
    anchors are marked.
  - Inverted hold: a bar of downforce against weight for the current `m`, and the least `dp`
    (4,903 Pa, 13.3 kW at 3 mm).
- **Verdict:** Yes. 1.62 s, limited by torque. The skirt gap sets the power bill, not the time.
- **Scoreboard rows:** "Performance trim under 1.6 s" — model t60. "Holds the car upside down" —
  margin of downforce over weight.

### 3. Cold-gas tank

- **Solve:** a thrust-stand problem through `remake` (5 ms).
- **Sliders:**
  - p0: 300–690 bar (380).
  - V: 200–600 L (600).
  - n: 1.0–1.4 (1.4).
  - A toggle, "fixed throat" or "80 kN at any pressure". The second needs `A_t` exposed.
- **Plot:** thrust against time, with horizontal lines at 80 % and 50 % of the initial thrust and
  their crossing times. The other polytropic index is a ghost curve, and remaining air mass is on a
  second axis.
- **Verdict:** 80 kN falls below 80 % after 0.37 s and below 50 % after 1.18 s, so the claimed
  thrust is a peak, not a level.
- **Scoreboard row:** "80 kN rear thrust" — model initial thrust and the time it holds above 80 %.

### 4. Thrust launch

- **Solve:** a launch problem through `remake`, 25 ms per move. The `down_fraction` grid is
  computed at load (1.0 s).
- **Controls:**
  - Checkboxes for thrust and suction.
  - Tank: `Select` 200 L (Thrust trim, per Electrek) or 600 L. Pressure is taken from section 3.
  - `down_fraction`: 0–1, step 0.05 (0).
- **Plots:**
  - v(t) for the current configuration. The three reference configurations from the brief are
    ghosts: tires + thrust 0.55 s, + suction 0.53 s, 200 L 0.68 s. Tesla's 0.81 s and <0.59 s are
    markers.
  - A force stack over time: tire force plus forward thrust, against the grip and torque limits.
  - t60 against `down_fraction` for the 4 precomputed cases, with the live point.
- **Verdict:** Thrust beats the claim. Pushing down pays only for AWD without suction, around 0.1.
  Report the air used to 60 mph (`tank.m_g` difference).
- **Scoreboard rows:** "Thrust trim under 0.9 s (0.81 s live)" and "Rocket trim under 0.59 s" —
  model t60 and air used.

### 5. Hop and hover: can it fly?

- **Hop:**
  - **Solve:** a Hop problem through `remake` with `t_b` and `m` (9 ms).
  - **Slider:** `t_b` 0.2–0.8 s (0.413).
  - **Plot:** altitude over time through the landing. The closed-form apex,
    `h(t_b) + v(t_b)²/(2g)`, is overlaid, and the air used is shown as a number.
  - **Verdict:** an 8 m hop costs about 43 kg of air. As built, the ground contact is fixed and the
    plain maximum is the apex: 7.99 m at `t_b = 0.413` s.
- **Hover:**
  - **Solve:** a Hover problem through `remake` with `m` (the car panel) and `tank_pressure`
    (its own slider, 300–690 bar), 9 ms warm.
  - **Grid:** the 3 × 3 table (m 1,700/2,000/2,350 kg × p0 300/380/690 bar) is computed at load.
  - **Live closed form:** endurance from `ṁ = m·g/v_e` integrated over the usable air.
  - **Plot:** altitude and valve command, with the saturation time marked.
  - **Verdict:** about 5.5 s of hover, so hops, not flight.
- **Scoreboard row:** "It can fly" — hover seconds.

**Hover caveat (resolved).** Repeated `Hover()` calls used to differ in their peak altitude, and
the plan was a committed snapshot. The Hover analysis now runs without automatic discontinuity
detection and is deterministic, so the section is live and no snapshot is committed.

### Optional: kickflip budget

- **Method:** closed form only.
- **Sliders:** roll rate 90–360 °/s (177), moment arm 0.6–1.2 m (0.9).
- **Calculation:** I_roll ≈ 870 kg·m², so L = I·ω, the impulse is L/arm, and the air is impulse/v_e,
  doubled to stop the roll. This comes to about 5 kg (about 9 kg with stopping), against 43 kg for
  the 8 m hop.
- **Verdict:** rotation is cheap and lift is expensive.

## 4. Claim vs model scoreboard

A fixed `<aside>` in the bottom-right corner, about 320 px wide, rendered by one cell that depends
on every section's result. It stays visible in present mode and when scrolling.

- **Rows:** one per claim, top to bottom in story order. Each row shows the claim, Tesla's value,
  the current model value and a verdict chip.
- **Verdict chips:** green "yes", red "no", gray "—" for a value that is not finite. As built, the
  panel starts collapsed to a summary line ("n of m possible") so it does not cover plots; the
  Verdicts slide has the same rows in full.
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
