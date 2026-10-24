# Lecture 3 — Studio screenshots

The Studio screenshots of the Lecture 3 build, all captured in the student-style rehearsal and
saved under `slides/images/lecture-03/`; the deck's build slides and the guide page
(`slides/site/lecture/lecture-03/`) show them where the table below says. `slides/scripts/images.mjs`
copies that folder into the deck and the guide page. Step numbers match
`docs/lecture-03-handson-plan.md`.

The three bench diagrams (`step02-pedal-bench`, `step03-abs-bench`, `step04-wheel-only-bench`)
are screenshots of the `dyad/HandsOn03/` reference diagrams, whose layout is in their metadata.
The three code views, the phase plot and the REPL table come from the rehearsal's own `MyCar`,
as a student sees them; the code views therefore show Studio's `"short … component description"`
and diagram-only port placements, not the reference files' text. The plots in SVG are not
screenshots: `scripts/export_lecture03_build_figures.jl` (`mise run figures:lecture-03-build`)
renders them from the reference models, so a model change is one re-run away from new figures.

The conventions for a re-capture:

- The diagram view, fitted to the window, with the library panel and the problems panel closed.
- A shot of the code view shows the whole component, no scrolling, at the editor's default font.
- Same window size for every shot. About 1600 × 1000 matches the other lectures' images.
- Crop each shot to the pane, as Lecture 1 does: no title bar, tabs, activity bar or status bar.

## Rendered (re-run on the hydraulic benches)

| File | Step | From |
| ---- | ---- | ---- |
| `step02-locked-stop.svg` | 02 | `HandsOn03.PedalStopTransient`, pedal 0.6, 43.7 m |
| `step03-abs-torque-slip.svg` | 03 | `HandsOn03.ABSStopTransient`, `T_p` 0 and 0.03, front wheel pressure; 53.4 and 34.2 m |
| `step04-phase-cycle.svg` | 04 | `HandsOn03.ABSStopWheelOnlyTransient`, `road_mu = 0.3`, 1.0–2.5 s; 130.6 m, caliper 14.5–22.1 bar |
| `step05-surfaces.svg` | 05 | the three reference analyses, `PedalStopTransient` first, and `Vehicle.ABSBrakeTransient` at μ 1.0, 0.5, 0.3; 43.7/34.2/38.5/38.7, 85.1/64.6/78.0/83.2, 136.7/106.1/130.6/141.3 m |

## Captured

| File | Step | Model | What it shows | Used on | Status |
| ---- | ---- | ----- | ------------- | ------- | ------ |
| `step00-wheel-library.png` | 00 | any diagram | The **+** library panel open at `VehicleSystemsComponents › Vehicle › Wheel`, listing `BrakedWheel`, `HydraulicBrakedWheel`, `BrakeActuator`, `TireFrictionCurve`; `HandsOn03` visible one level up. | deck build 00, guide 00 | done, rehearsal `MyCar` |
| `step02-pedal-bench.png` | 02 | `HandsOn03.PedalStop` | The finished hydraulic chain: `command` → `pedal_unit` → `booster` → `master` from the left, `fixed_hydraulic` under the three housings, `line_f` and `line_r` into `wheel`, `road` and `fixed` under the wheel, `body` and `speed` on the right; the three-way junction on `body.flange`. | guide 02 | done, reference diagram, full window |
| `step03-slipabs-code.png` | 03 | `HandsOn03.SlipABS` | The code view: the `pressure` line, the rate `ifelse`, the `cycled` latch, the `p_cmd` line and the three look-ahead lines. | guide 03 | done, rehearsal `MyCar` |
| `step03-abs-bench.png` | 03 | `HandsOn03.ABSStop` | Build 02's chain with `valve_f` and `valve_r` between `master` and the lines; `abs` below, `master.p_mc`, `wheel.kappa` and `speed.v` into it, `abs.p_cmd` out to both valves. | guide 03 | done, reference diagram, full window |
| `step04-estimator-code.png` | 04 | `HandsOn03.RefSpeedEstimator` | The code view, all seven relations. | guide 04 | done, rehearsal `MyCar` |
| `step04-phaseabs-code.png` | 04 | `HandsOn03.PhaseABS` | The code view: the `phase` line, the `cycled` latch and the nested rate `ifelse`. | guide 04 | done, rehearsal `MyCar` |
| `step04-wheel-only-bench.png` | 04 | `HandsOn03.ABSStopWheelOnly` | `wspeed` on `wheel.spline`, `est` with its three outputs into `abs`; no wire from `wheel.kappa` or `speed.v` into `abs`. | guide 04 | done, reference diagram, full window |
| `step04-phase-plot.png` | 04 | `HandsOn03.ABSStopWheelOnlyTransient(road_mu = 0.3, stop = 20)` | The guide's REPL plot of `abs.phase`, `abs.p_cmd` and `wheel.caliper_f.p` from 1.0 to 2.5 s, as a student sees it. | guide 04 | done, rehearsal `MyCar` |
| `step05-surface-table.png` | 05 | the REPL | The step 05 loop's three printed rows. | guide 05 | done, rehearsal `MyCar` |

## Captured: the build sequence, cropped to the pane

Eighteen shots of the build in progress, captured from the student project `~/TMP/MyCar`
(scratch branch `lecture-03-shots`) in Dyad Studio web in a 1600 × 1000 window. Each is cropped
to the pane, like Lecture 1's, unlike the three full-window bench diagrams above. The diagrams
have a tidied layout and wire routes; model behavior is unchanged. The plots come from the guide's
own REPL snippets, with the Plotly backend in the Julia Plots tab, at the size of
`step04-phase-plot.png`. The distances read from the same runs match the guide: 35.96 m (pedal
0.3), 43.71 m (pedal 0.6), 53.35 m (run A), 34.21 m (run C), 38.52 m (wheel speed only, dry).

| File | Step | Model | What it shows | Used on | Status |
| ---- | ---- | ----- | ------------- | ------- | ------ |
| `step02-params.png` | 02, Do this 1 | `MyCar.PedalStop` | The parameter panel with nothing selected, over the finished bench: `pedal` 0.6, `road_mu` 1.0 and **Add parameter**. | deck build 02, guide 02 | done, `MyCar`, cropped to the pane |
| `step02-command-params.png` | 02, Do this 1 | `MyCar.PedalStop` | The finished bench with `command` selected: `height = pedal`, `start_time` 0.5, `offset` 0.0. | guide 02 | done, `MyCar`, cropped to the pane |
| `step02-line-r-params.png` | 02, Do this 1 | `MyCar.PedalStop` | The finished bench with `line_r` selected: `D` 3e-3 m, `L` 4.0 m, `nu` 10e-6 m²/s. | guide 02 | done, `MyCar`, cropped to the pane |
| `step02-force-chain.png` | 02, Do this 3 | `MyCar.PedalStop`, in progress | All twelve blocks placed, only the force chain wired: `command` → `pedal_unit` → `booster` → `master.pushrod`. | guide 02 | done, `MyCar`, cropped to the pane |
| `step02-hydraulics.png` | 02, Do this 3 | `MyCar.PedalStop`, in progress | The housings on `fixed_hydraulic`, both circuits through the lines into the wheel, `wheel.support` on `fixed`; `road`, `body` and `speed` not yet wired. | guide 02 | done, `MyCar`, cropped to the pane |
| `step02-fluid-code.png` | 02, Do this 4 | `MyCar.PedalStop` | The code view: twelve instances, the `path medium` line, fourteen connects, the `continuity` line and the four initial lines. | guide 02 | done, `MyCar`, cropped to the pane |
| `step02-pedal03-plot.png` | 02, Do this 6 | `MyCar.PedalStopTransient(pedal = 0.3)` | The guide's plot: `master.p_mc` about 5.5×10⁶ Pa, `speed.v` to zero at about 3.4 s, `wheel.kappa` about −0.027; 35.96 m. | guide 02 | done, `MyCar`, cropped to the pane |
| `step02-pedal06-plot.png` | 02, Do this 6 | `MyCar.PedalStopTransient()` | The same plot at pedal 0.6: about 8.9×10⁶ Pa, at rest just before 4 s, `wheel.kappa` −1; 43.71 m. | guide 02 | done, `MyCar`, cropped to the pane |
| `step03-slipabs-diagram.png` | 03, A | `MyCar.SlipABS` | Its own diagram: `kappa`, `v`, `demand` on the left edge, `p_cmd` on the right, `pressure` in the middle with `demand` wired to it. | guide 03 | done, `MyCar`, cropped to the pane |
| `step03-params.png` | 03, B | `MyCar.ABSStop` | The parameter panel with nothing selected, over the finished bench: `pedal`, `road_mu`, `T_p` 0.03 s, `lambda_target` 0.04. | guide 03 | done, `MyCar`, cropped to the pane |
| `step03-valves.png` | 03, B | `MyCar.ABSStop`, in progress | `valve_f` and `valve_r` wired between `master` and the lines, their `p_cmd` inputs open; no `abs` yet. | guide 03 | done, `MyCar`, cropped to the pane |
| `step03-runA-plot.png` | 03, B | `MyCar.ABSStopTransient(T_p = 0)` | Run A: `wheel.caliper_f.p` saws between about 1 and 7×10⁶ Pa, `wheel.kappa` dives deeper every cycle, to −1; 53.35 m. | guide 03 | done, `MyCar`, cropped to the pane |
| `step03-abs-params.png` | 03, C | `MyCar.ABSStop` | `abs` selected: `lambda_target = lambda_target`, `k_inc` 2.9e7, `k_dec` 5.8e7, `v_min` 1.5 m/s, `T_p = T_p`, `T_f` 0.003 s. | guide 03 | done, `MyCar`, cropped to the pane |
| `step03-runC-plot.png` | 03, C | `MyCar.ABSStopTransient()` | Run C: the caliper holds near 6.4×10⁶ Pa with a fine ripple until about 3 s, `wheel.kappa` near −0.04, a brief lock near standstill; 34.21 m. | guide 03 | done, `MyCar`, cropped to the pane |
| `step04-estimator-diagram.png` | 04, A | `MyCar.RefSpeedEstimator` | Its own diagram: `omega` on the left edge, `kappa_hat`, `v_ref`, `a_w` on the right. | guide 04 | done, `MyCar`, cropped to the pane |
| `step04-phaseabs-diagram.png` | 04, B | `MyCar.PhaseABS` | Its own diagram: `kappa`, `a_w`, `v`, `demand` on the left, `p_cmd` on the right, `pressure` with `demand` wired to it. | guide 04 | done, `MyCar`, cropped to the pane |
| `step04-wheel-only-midbuild.png` | 04, C | `MyCar.ABSStopWheelOnly`, in progress | `wspeed` on `wheel.spline` and into `est.omega`, `est`'s outputs open; the old `abs` deleted and `PhaseABS` not yet placed, so this shot's order differs from the guide's. | guide 04 | done, `MyCar`, cropped to the pane |
| `step04-dry-plot.png` | 04, C | `MyCar.ABSStopWheelOnlyTransient()` | The step's plot call on the dry run with `xlims = (1.0, 3.3)`: `abs.phase` about 14 switches a second at speed, pressure rippling near 6.3×10⁶ Pa until about 2.2 s, then deep dumps; 38.52 m. | guide 04 | done, `MyCar`, cropped to the pane |

The rehearsal settled the first of the plan's two open questions: Studio's code view keeps the
`pressure` placement and the nested `ifelse`, but ports written in code get no placement unless the pasted
code carries their `{^…}` markers and `metadata`, which the guide's code now does. Whether build 02 fits its 16
minutes is still open.
