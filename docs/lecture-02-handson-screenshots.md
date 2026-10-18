# Lecture 2 hands-on — Studio screenshots

The screenshots the Lecture 2 hands-on guide and its projector deck need, one table per step
of `docs/lecture-02-handson-plan.md`. The diagrams are Studio screenshots of the student
reference models in `dyad/HandsOn02/`, which hold the components exactly as the guide builds
them, under the guide's names. Those models are task 4's to write. The list follows the build, so it doubles as a rehearsal
script. Save the files to `slides/images/handson-02/` under the names given;
`scripts/images.mjs` copies them into the deck and the guide. The guide shows every image, the
picture of the finished model at the start of each build; the projector deck shows only that
picture, one per step.

The hands-on deck's conventions apply to every diagram:

- The diagram view, fitted to the window, with the library panel and the problems panel closed.
- A shot that needs a parameter panel shows it over the diagram, with the toolbar masked out.
- A code shot shows the whole component without scrolling, at the editor's default font size.
- Same window size for every shot. About 1600 × 1000 matches the hands-on 1 images.
- Reset view fits the dashed outline to the canvas's shorter side, so on a portrait canvas the
  ports on the left and right edges and their labels fall outside it. Use a landscape canvas.
- The step 02–03 shots were taken in a 706 × 1015 window, the only size Chrome would take, with
  the diagram's webview cut to 480 px high so the fit goes by height. All four are cropped to the
  same 638 × 584 frame; the step 00 popup is cropped to itself, 324 × 878.

Plots are REPL plots of the reference analyses, at the hands-on 1 plot size (990 × 528), one
signal per axis unless the row says otherwise. Dyad's REPL defaults to the Plotly backend, where
`savefig` cannot write a PNG: run `gr()` first, and again after any ▷ run, which switches back to
Plotly. At 990 × 528, GR clips the axis labels without `margin = 5Plots.mm`.

## Step 00 — set up

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step00-engine-library.png` | — | The **+** (Add component) tree opened at `VehicleSystemsComponents › Vehicle › Engine`, cropped to the popup. `Engine` holds about 40 parts in alphabetical order, the `Test…` reference models among them, so one view shows `AirPath`, `CylinderAirflow` and `MappedEngine`; `Throttle` comes after the `Test…` entries, below the fold. `MyCar` is the last top-level library, under `VehicleSystemsComponents`, and is off screen once `Vehicle` is open. |

## Step 01 — read the maps

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step01-torque-map.png` | `data/engine/torque_Nm.csv` | Heatmap, `p_m` in kPa across, rpm up. A marker at 3080 rpm, 47.8 kPa: the 90 km/h point. The page's 47.7 kPa is the 3000 rpm row alone, not the marker. |
| `step01-fuel-map.png` | `data/engine/fuel_gps.csv` | Same axes and marker; the color bar in g/s. |

## Step 02 — manifold

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step02-manifold-code.png` | `HandsOn02.Manifold`, code view | The whole component: three inputs, `p_m` output, `V_m`, `T_m`, `R`, and the one `der(p)` equation. |
| `step02-airpath-bench.png` | `HandsOn02.AirPathStep` | `throttle_cmd` → `throttle`, `speed` → `cylinders.omega`, `no_booster` → `manifold.mdot_bst`, the three flow wires into `manifold`, and `manifold.p_m` fed back to `throttle` and `cylinders`. |
| `step02-idle-plot.png` | `HandsOn02.AirPathStepTransient`, idle | `manifold.p_m` in kPa falling from 101.3 to 33.0 over the first second. |

## Step 03 — map engine on a dynamometer

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step03-map-engine.png` | `HandsOn02.MapEngine` | The diagram students draw: ports `pedal` and `mdot_bst` on the left; `air`, `speed`, `torque_map` above `fuel_map`, `torque`, `co2`; the speed wires from `speed.w` and the pressure wires from `air.p_m` fanning out to both maps; `spline`, `support`, `mdot_fuel`, `mdot_co2`, `p_m` on the right edge. |
| `step03-dyno-bench.png` | `HandsOn02.MapEngineDyno` | Laid out left to right, no labels overlapping. `pedal` step and `no_booster` → `engine`, `speed` → `dyno`, `engine.spline` → `dyno`, both supports to `mounts`. |
| `step03-step-plot.png` | `HandsOn02.MapEngineDynoTransient`, defaults | Two axes, one time base: `engine.p_m` 47.8 → 52.9 kPa and `engine.torque_map.y` 31.1 → 41.4 N·m, zoomed to 0.9–1.3 s so the 50 ms lag shows. |
| `step03-map-engine-fuel-cut.png` | `HandsOn02.MapEngineFuelCut` | The engine after the fuel-cut paste: `cut_logic` at the bottom left, its output into both maps from below. A `dyad render` of the reference (dyad-cli 3.4.0), rasterized and trimmed, not a Studio shot: the CLI draws no port labels. |
| `step03-dyno-bench-fuel-cut.png` | `HandsOn02.MapEngineFuelCutDyno` | The bench after the paste, `speed` a ramp. A `dyad render`, as above. |
| `step03-fuel-cut-plot.png` | `HandsOn02.MapEngineFuelCutDynoTransient`, `rpm = 3000`, pedal 1 → 0, `p_m0 = 99889.9`, `stop = 6` | Three axes, one time base: `engine.speed.w` held, then ramping down from 2 s; `engine.mdot_fuel` falling to zero within about 30 ms of the release and back on at 4.73 s, below 1000 rpm; `engine.torque_map.y` at −18.7 N·m during the cut. |

## Step 04 — the car with a mapped engine

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step04-mapped-car.png` | `HandsOn02.MappedCar` | `pedal` input → `engine` (the student's `MapEngine`) → `flywheel` → `driveline` → `body`; `no_booster` → `engine.mdot_bst`; outputs `v_kmh`, `p_m`, `fuel_lph` on the right edge; the grounds. Shoot before step 06 adds the brake. |
| `step04-wot-plot.png` | `HandsOn02.MappedCarWOTTransient` | `car.v_kmh` from rest to about 190 km/h over 120 s, with a dashed line at 246 km/h for Lecture 1's car. |

## Step 05 — cruise

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step05-cruise-bench.png` | `HandsOn02.MappedCarCruise` | `pedal` constant → `car.pedal`, and the `initial` lines in the code view beside it. |
| `step05-cruise-90-plot.png` | `HandsOn02.MappedCarCruiseTransient`, 90 km/h | Two axes: `car.v_kmh` flat at 90, `car.fuel_lph` flat at 4.1. |

## Step 06 — coast-down and brake stop

| File | Model | What must be visible |
| ---- | ----- | -------------------- |
| `step06-coast-plot.png` | `HandsOn02.MappedCarCoastTransient`, no brake | Three axes: `car.v_kmh` from 90 down past 29 km/h, `car.fuel_lph` 4.1 → 0 at 5 s and back on at 29 km/h, `car.p_m` dropping to about 13.5 kPa. |
| `step06-mapped-car-brake.png` | `HandsOn02.MappedCar`, after step 06 B | The car with the `F_brake` input and `brake` between `body.flange` and `trans_ground`. |
| `step06-brake-plot.png` | `HandsOn02.MappedCarCoastTransient`, with the brake step | `car.v_kmh` and `car.p_m` through the stop, ending before the engine would stall. |

## Step 07 — WLTC (if time allows)

To be listed with task 6.

## Where each state lives

| File | Component | Analysis |
| ---- | --------- | -------- |
| `step02-manifold-code.png` | `HandsOn02.Manifold` | — |
| `step02-airpath-bench.png` | `HandsOn02.AirPathStep` | — |
| `step02-idle-plot.png` | — | `HandsOn02.AirPathStepTransient` |
| `step03-map-engine.png` | `HandsOn02.MapEngine` | — |
| `step03-dyno-bench.png` | `HandsOn02.MapEngineDyno` | — |
| `step03-step-plot.png` | — | `HandsOn02.MapEngineDynoTransient` |
| `step03-map-engine-fuel-cut.png` | `HandsOn02.MapEngineFuelCut` | — |
| `step03-dyno-bench-fuel-cut.png` | `HandsOn02.MapEngineFuelCutDyno` | — |
| `step03-fuel-cut-plot.png` | — | `HandsOn02.MapEngineFuelCutDynoTransient` |
| `step04-mapped-car.png` | `HandsOn02.MappedCar` | — |
| `step04-wot-plot.png` | — | `HandsOn02.MappedCarWOTTransient` |
| `step05-cruise-bench.png` | `HandsOn02.MappedCarCruise` | — |
| `step05-cruise-90-plot.png` | — | `HandsOn02.MappedCarCruiseTransient` |
| `step06-coast-plot.png` | — | `HandsOn02.MappedCarCoastTransient` |
| `step06-mapped-car-brake.png` | `HandsOn02.MappedCar`, with the brake | — |
| `step06-brake-plot.png` | — | `HandsOn02.MappedCarCoastTransient`, brake on |
