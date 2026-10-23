# Lecture 3 — Studio screenshots

The Studio screenshots the Lecture 3 build still needs. Until they are captured, the deck's build
slides and the guide page (`slides/site/lecture/lecture-03/`) show a dashed placeholder that names
the file and what it must show; capturing a shot means saving it under that name and replacing
the placeholder with the image.

The diagrams are screenshots of the `dyad/HandsOn03/` reference models, which hold the student's
components exactly as they stand after each step, under the names the guide gives them. The plots
are not screenshots: `scripts/export_lecture03_build_figures.jl` (`mise run
figures:lecture-03-build`) renders them from the same models, so a model change is one re-run
away from new figures. The list follows the build, so it doubles as a rehearsal script. Save the
files to `slides/images/lecture-03/` under the names given; `slides/scripts/images.mjs` copies
that folder into the deck and the guide page. Step numbers match
`docs/lecture-03-handson-plan.md`.

The hands-on deck's conventions apply to every diagram:

- The diagram view, fitted to the window, with the library panel and the problems panel closed.
- A shot of the code view shows the whole component, no scrolling, at the editor's default font.
- Same window size for every shot. About 1600 × 1000 matches the other lectures' images.

## Already rendered

| File | Step | From |
| ---- | ---- | ---- |
| `step02-locked-stop.svg` | 02 | `HandsOn03.LockedStopTransient` |
| `step03-abs-torque-slip.svg` | 03 | `HandsOn03.ABSStopTransient`, `T_p` 0 and 0.03 |
| `step04-phase-cycle.svg` | 04 | `HandsOn03.ABSStopWheelOnlyTransient`, `road_mu = 0.5` |
| `step05-surfaces.svg` | 05 | the three reference analyses and `Vehicle.ABSBrakeTransient` at μ 1.0, 0.5, 0.3 |

## To capture

| File | Step | Model | What must be visible | Used on |
| ---- | ---- | ----- | -------------------- | ------- |
| `step00-wheel-library.png` | 00 | any diagram | The **+** popup open at `VehicleSystemsComponents › Vehicle › Wheel`, listing `BrakedWheel`, `BrakeActuator`, `TireFrictionCurve`; `HandsOn03` visible one level up. | deck build 00, guide 00 |
| `step02-locked-bench.png` | 02 | `HandsOn03.LockedStop` | The finished bench: `demand` and `road` on the left, `wheel` in the middle with `fixed` under it, `body` and `speed` on the right; the three-way junction on `body.flange`. | deck build 02, guide 02 |
| `step03-slipabs-code.png` | 03 | `HandsOn03.SlipABS` | The code view: the `pressure` line, the rate `ifelse` and the three look-ahead lines. | guide 03 |
| `step03-abs-bench.png` | 03 | `HandsOn03.ABSStop` | `abs` between `demand` and `wheel`, the `wheel.kappa` and `speed.v` wires back into it. | guide 03 |
| `step04-estimator-code.png` | 04 | `HandsOn03.RefSpeedEstimator` | The code view, all seven relations. | guide 04 |
| `step04-phaseabs-code.png` | 04 | `HandsOn03.PhaseABS` | The code view: the `phase` line, the `cycled` latch and the nested rate `ifelse`. | guide 04 |
| `step04-wheel-only-bench.png` | 04 | `HandsOn03.ABSStopWheelOnly` | `wspeed` on `wheel.spline`, `est` with its three outputs into `abs`; no wire from `wheel.kappa` or `speed.v` into `abs`. | guide 04 |
| `step04-phase-plot.png` | 04 | `HandsOn03.ABSStopWheelOnlyTransient(road_mu = 0.5, stop = 10)` | The guide's REPL plot of `abs.phase`, `abs.tau_cmd` and `wheel.brake.tau_actual` from 0.9 to 1.45 s, as a student sees it. | guide 04 |
| `step05-surface-table.png` | 05 | the REPL | The step 05 loop's three printed rows. | guide 05 |

The rehearsal that captures them also settles the two open questions of the plan's risk table:
whether Studio's code view keeps the `pressure` placement and the nested `ifelse` (steps 03 and
04), and whether build 02's drawing fits its 15 minutes.
