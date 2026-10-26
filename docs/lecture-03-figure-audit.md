# Lecture 3: figure audit

Every picture in the Lecture 3 deck (`slides/decks/lecture-03/sections/`) and the build guide
(`slides/site/lecture/lecture-03/index.md`), with a recommendation for each:

- **Keep**: our own figure, diagram or Studio screenshot, and it does its job.
- **Dyad**: replace with, or add, a screenshot of a real component or bench diagram from `dyad/`,
  taken by the conventions in `docs/lecture-03-screenshots.md`.
- **SVG**: replace with, or add, a handcrafted SVG in the style of
  `slides/decks/lecture-03/public/diagrams/`: sans-serif, 13 px or larger in a viewBox about
  1000 wide, dark outline boxes, light blue fills for the controller, orange for fluid return,
  thin blue for signals, library names in small blue type above each box.
- **Drop**: remove the picture; the slide works without it.
- **Figure**: a plot made by a script from a model run, not a diagram.

Where each picture comes from:

- **pptx**: `public/pptx/` holds pictures cut out of the source deck,
  `docs/materials/ABSESP/3. ABS, ESP, SRS.pptx`. The source deck took them from the web. No
  license is recorded anywhere in the repository. The sources slide says only "figures from
  HowStuffWorks and Renault as credited there" (`07-wrap-up.md:124`). Six of them carry a
  visible "©2000 How Stuff Works" mark. Every pptx picture is small, 205 to 734 px wide.
- **figures**: plots made by `scripts/export_lecture03_*.jl` or by notebook 01 or 02. Lecture 1's
  plots are reused as `10-*.svg`.
- **diagrams**: handcrafted SVGs.
- **img**: Studio screenshots and build plots in `slides/images/lecture-03/`, catalogued in
  `docs/lecture-03-screenshots.md`.

## Inventory, deck

| Slide (routeAlias) | File (`file:line`) | What it shows | Source | Problems | Recommendation | Status |
|---|---|---|---|---|---|---|
| `from-lecture-1` | `figures/10-past-the-peak.svg` (`00-front-matter.md:71`) | μ–slip curve, unstable side shaded | Lecture 1 figure | none | Keep | — |
| `build-setup` | `img/step00-wheel-library.png` (`00:195`) | the + library panel | Studio | none | Keep | — |
| `friction` | none (notes mention `slide03-friction-forces.jpg`, `slide03-static-kinetic.jpg`, `01:70`) | | | the table is enough | Keep without a picture | — |
| `tire-is-not-a-block` | `figures/10-mu-slip-curve.svg` (`01:115`) | μ–slip curve; right panel marks Lecture 1's standing starts on a log axis | Lecture 1 figure | the right panel is about driving off on snow, not braking | Keep. Optional: a braking-side, one-panel version from `export_lecture03_tire_figures.jl` | — |
| `tire-models` | `figures/01-tire-models.svg` (`01:162`) | five tire models, longitudinal and lateral | script | none | Keep | — |
| `cornering-limit` | `pptx/slide04-car-on-curve.jpg` (`01:359`) | pixel-art cars on a curve, velocity and friction arrows | pptx, origin unknown, no credit | 299×275 px, blurry when scaled; shows none of the slide's numbers | **SVG**: a car on a 50 m radius, v tangent, μmg toward the center, the three v_max values 80/62/44 km/h beside it, and a small friction circle with the braking share taken out | open (rank 12) |
| `locked-wheel-steer` | `figures/01-locked-wheel-forces.svg` (`01:382`) | three wheels over friction circles | script | the subscripts are 8–10 px; check them on the projector | Keep | — |
| `lever-and-hydraulics` | `pptx/slide05-lever.jpg`, `slide05-hydraulic-multiplication.png`, `slide05-simple-brake-system.png` (`02:36,44,52`) | lever 2X:X; 2 in to 6 in pistons, 100 to 900 lb; pedal 4x:x into a caliper | pptx, **HowStuffWorks, "©2000 How Stuff Works" on all three** | copyrighted, license unclear; inches and pounds; 325–450 px wide; three styles on one slide; the numbers are not our model's | **SVG**, one picture in three panels, in SI with the model's numbers: the pedal lever ×3.5 (`BrakePedal`); Pascal with the 25 mm master bore against the 57 mm front caliper piston, area ratio 5.2; then the two in series, foot to caliper | **done**: `diagrams/02-lever-hydraulics.svg`; the three pptx images removed |
| `force-chain` | `diagrams/02-force-chain.svg` (`02:80`) | the pedal-to-caliper block chain with library names | handcrafted | none | Keep. The Dyad diagram `HandsOn03.PedalStop` would show more wiring and say less | — |
| `pedal-to-pressure` | `figures/02-pedal-to-pressure.svg` (`02:135`) | booster characteristic | notebook 02 | none. The booster itself is described in words only | Keep. Optional SVG: a booster cross-section (vacuum chamber, diaphragm, air valve, reaction disc). The orphan `figures/02-vacuum-manifold.svg` (from `export_lecture03_vacuum_figures.jl`) would fit the notes' "where does the vacuum come from" | — |
| `master-cylinder` | `pptx/slide06-master-cylinder.jpg` (`02:182`) | tandem master cylinder section | pptx, **HowStuffWorks ©** | copyrighted; 400×300 px; the labels are small; no compensating ports, although the notes explain them | **SVG**: one bore, primary and secondary piston, both springs, the compensating ports with the 2.5 mm dead stroke, front and rear outlets labeled as in `TandemMasterCylinder` (`front`, `rear`, `p_mc`, 25 mm bore) | **done**: `diagrams/02-tandem-master-cylinder.svg`; pptx image removed |
| `master-cylinder` | `diagrams/02-dual-circuit.svg` (`02:194`) | II and X split | handcrafted | none | Keep | — |
| `combination-valve` | `pptx/slide06-brake-components.jpg` (`02:231`) | 3D car with pedal, booster, master cylinder, combination valve, lines, discs, drums | pptx, **HowStuffWorks ©** | copyrighted; 400×350 px; small labels; US layout with rear drums | **SVG**: a plan view in the style of `02-dual-circuit.svg`: pedal, booster, master cylinder, a proportioning valve on the rear circuit, a knee-point inset of p_rear against p_front, and "EBD: the same job in the ABS valves". Lower priority: **Drop** and keep the bullets | open (rank 14) |
| `given-parts` | none | the parts table | | a table with 12 rows and no picture | Keep. The next slide shows the diagram | — |
| `build-pedal-stop` | `img/step02-params.png`, `img/step02-locked-stop.svg` (`02:315,345`) | finished bench; locked stop | Studio; build script | none | Keep | — |
| `what-abs-does` | `pptx/slide07-abs-layout.jpg` (`03:57`) | 1990s brochure drawing: sensors, modulator, control module | pptx, a scanned brochure, origin unknown | license unclear; 400×286 px; contains "Replace brake fluid every 45,000 miles"; its labels (gear pulser, control module) differ from the slide's | **SVG**: a plan-view car, four sensors at the hubs, the hydraulic unit with its ECU, an X split, the three part types colored as in the slide's bullets. A simplified preview of `03-abs-system.svg`. Also: the slide says "Four parts:" over three bullets (`03-abs.md:48`) | **done**: `diagrams/03-abs-layout.svg`; pptx image removed. "Four parts:" left to the review agent |
| `abs-history` | none | | | a timeline table | Keep | — |
| `wheel-speed-sensors` | `pptx/slide08-tone-wheel.png` (`03:148`) | tone wheel, sensor, square pulses | pptx, origin unknown | 400×257 px, crude; **wrong signal**: it draws square pulses, but the slide describes the passive sensor's AC voltage that grows with speed | **Figure, reused**: Lecture 2's `crank-vr-hall` card (`lecture-02/sections/04-sensors.md`, `<CardExport notebook="illustrations" name="crank-vr-hall">`): VR against Hall on one toothed wheel. Or an **SVG**: tone wheel and VR coil, with the voltage at two speeds, beside a Hall current trace | **done**: Lecture 2 card `illustrations/crank-vr-hall` copied into `public/cards/` with `components/CardExport.vue`; pptx image removed |
| `active-wheel-speed-sensor` | `diagrams/03-active-wheel-sensor.svg` (`03:209`) | encoder ring, chip, 7/14 mA current | handcrafted | none | Keep | — |
| `abs-system` | `diagrams/03-abs-system.svg` (`03:267`) | the whole ABS hydraulics and signals | handcrafted | the NO/NC labels and the motor caption are 10–11 px in a 1200 px viewBox; the top-right label touches the edge | Keep. Check on the projector; set the small labels to at least 13 px | open (rank 15) |
| `abs-system-models` | none | table: the real ABS against our three models | | the densest table in the deck | Optional SVG: three mini block chains side by side (ABSStop, ABSBrakeTest, planar ABSUnit), one row per real part. Low priority | — |
| `modulator` | `diagrams/03-abs-channel.svg` (`03:395`) | one channel: inlet, outlet, accumulator, pump, the build/hold/dump table | handcrafted | none | Keep | — |
| `modulator` | `pptx/slide09-abs-modulator.jpg` (`03:400`) | photo of an ABS unit, tinted blue | pptx, **HowStuffWorks ©** | copyrighted; 400×300 px; tinted background | **Drop**, or use a CC-licensed photo with its credit (Wikimedia Commons has ABS units). A photo cannot be drawn | open (rank 13) |
| `abs-channels` | none | three layouts in text | | three layouts described only in words | **SVG**: three plan-view cars in the `02-dual-circuit.svg` template: 4 channels/4 sensors, 3/3 with one sensor in the rear differential, 1/1 rear only. Sensors as dots, one colored valve pair per channel, "select-low" on the shared channels | **done**: `diagrams/03-abs-channels.svg` |
| `abs-cycle` | none | the simple algorithm and the Bosch cycle in text | | the classic picture of this topic is missing | **SVG**: the Bosch control cycle over about one cycle. Top: vehicle speed, v_ref and wheel speed. Middle: wheel deceleration with the −a, +a, +A thresholds. Bottom: wheel pressure with the phases numbered 1–8 (hold before dump, dump, hold, fast build, slow build). Our `PhaseABS` dump/hold/build shown in the same colors as the build 04 state diagram | **done**: `diagrams/03-abs-cycle.svg`, a sketch, not a model run |
| `abs-model` | `diagrams/03-abs-loop.svg` (`03:560`) | the ABS loop with library names | handcrafted | none; the names match `ABSWheelOnlyEstimatorDiscrete`, `ABSModulatorDiscrete`, `BrakeActuator`, `BrakedWheel` | Keep. Optional Dyad inset: `Vehicle.ABSControllerWheelOnly` (estimator and modulator, 7 of 9 wires routed) or the bench `Vehicle.ABSBrakeTest` (12 blocks placed, compact; the speed equation of the ideal bench is not drawn, but this bench has none) | — |
| `build-slip-abs` | `img/step03-params.png` (`03:625`) | finished ABSStop | Studio | none | Keep | — |
| `build-slip-abs-runs` | `img/step03-abs-torque-slip.svg` (`03:784`) | runs A and C | build script | none | Keep | — |
| `one-stop` | `figures/03-vehicle-and-wheel-speed.svg`, `03-brake-torque.svg` (`03:833,838`) | speeds; caliper torque | notebook 01 | none | Keep | — |
| `on-the-curve` | `figures/03-where-on-the-curve.svg`, `03-wheel-slip.svg` (`03:882,887`) | samples on the curve; slip | notebook 01 | none | Keep | — |
| `reference-speed` | none | the estimator in words and a formula | | the trap ("v_ref falls faster than the car") is easy to show and hard to say | **Figure** from `export_lecture03_figures.jl`: `Vehicle.ABSBrakeTransient` at μ 0.3 with a_ref 8 and 2.4: true speed, wheel ωr and v_ref against time, the gap between v_ref and the car shaded as "slip under-read" | open (rank 11) |
| `build-wheel-only` | `img/step04-wheel-only-bench.png` (`03:980`) | finished ABSStopWheelOnly | Studio | none | Keep | — |
| `build-wheel-only-cycle` | `img/step04-phase-cycle.svg` and an inline SVG state diagram (`03:1133,1135`) | the phase cycle on snow; build/hold/dump states | build script; inline SVG | none; the inline SVG uses `currentColor` | Keep | — |
| `abs-distance` | `figures/03-speed-over-distance.svg` (`03:1234`) | speed over distance | notebook 01 | none | Keep | — |
| `abs-surfaces` | `figures/03-distance-vs-mu.svg` (`03:1289`) | distance against μ | notebook 01 | none | Keep | — |
| `abs-measured` | none | table of measured tests | | | Keep | — |
| `abs-loses` | none | four reasons in text | | | Optional SVG: a locked tire pushing a gravel wedge beside a rolling one; a flat snow μ–slip curve over the dry curve. Low priority | — |
| `build-surfaces` | `img/step05-surfaces.svg` (`03:1501`) | grouped bars | build script | none | Keep | — |
| `planar-car` | `img/planar-car-inside.png` (`03:1582`) | inside `Vehicle.Planar.PlanarCar` | Studio (Dyad diagram) | none | Keep | — |
| `brake-steer-demo` | `figures/03-brake-steer-path.svg` (`03:1621`) | two paths, ABS on and off | `export_lecture03_steer_figures.jl` | none | Keep | layout only: capped at 21rem |
| `brake-steer-demo` | `img/planar-brake-steer-bench.png` (`03:1635`) | the `Lecture3.BrakeAndSteer` bench | Studio (Dyad diagram) | shown at `class="h-40"`, 160 px tall on a 760 px canvas: the 1512×800 screenshot cannot be read | **Dyad, resized**: give it at least `h-64`, or crop it to `abs`, `car` and `sensors` | **done**: shown up to 17rem beside the table (was 160 px); the path plot capped at 21rem to make room |
| `what-tcs-does` | `pptx/slide19-abs-tcs-esp.jpg` (`04:42`) | Bosch marketing graphic: nested ellipses ABS ⊂ ASR/TCS ⊂ ESP/ESC on a dark blue gradient | pptx, Bosch, ® mark | license unclear; a dark background that matches nothing in the deck; it says nothing beyond the three names | **SVG**: nested sets, each with what it adds: ABS (wheel speeds, dump valves), TCS (+ valves that build pressure, the engine), ESP (+ steering angle, yaw rate, a_y). Reuse it on `systems-table` | **done**: `diagrams/04-abs-tcs-esp.svg`; pptx image removed |
| `differential-film` | YouTube embed (`04:70`) | 1937 Chevrolet film | public domain (Prelinger) | needs internet in the room | Keep | — |
| `open-differential` | `diagrams/04-open-differential.svg` (`04:99`) | open differential with a TCS brake | handcrafted | none | Keep | — |
| `tcs-actuators` | none | two actuator columns in text | | | Optional SVG: the TCS loop, slip in, with two paths out: one wheel's brake (switchover valve, pump, tens of ms) and the engine (throttle slow, spark faster, injection cut fastest, EV motor ms) | — |
| `tcs-and-lecture-1` | `figures/10-ice-patch-limited.svg` (`04:233`) | Lecture 1 ice patch with a torque cap | Lecture 1 figure | none | Keep | — |
| `bonus-tcs` | none | the take-home task | | the reference is not built (`feat/handson03-tcs-bonus`), and the guide leaves the diagram out on purpose | Keep without a picture | — |
| `what-esp-does` | none | text and a history table | | | Keep | — |
| `esp-sensors` | `pptx/slide16-esp-components.png` (`05:80`) | Renault ESP components on a car plan view, numbered legend | pptx, Renault document (code "INT-0110…" in the image) | license unclear; 604×417 px with text baked in, too small on a projector; Renault's item list (a disconnection switch) differs from the slide's lists | **SVG**: a plan-view car, sensors colored by the slide's two lists: intention (steering angle, pedal, pressure sensor in the hydraulic unit) and motion (yaw-rate and a_y cluster at the center of gravity, four wheel-speed sensors); the hydraulic unit and ECU; the engine link | **done**: `diagrams/05-esp-components.svg`; pptx image removed |
| `esp-sensors` | `pptx/slide17-yaw-rate-sensor.jpg` (`05:99`) | a black sensor housing with a connector | pptx, origin unknown | 228×199 px. **It looks like a steering-angle sensor**: a ring housing that slides over the column. A yaw-rate sensor is a flat box. Verify | **Drop**. The next slide has `05-yaw-rate-sensor.svg`. Or a CC-licensed photo of a real yaw-rate sensor | **done**: dropped; pptx image removed |
| `esp-sensor-principles` | none | sensor table | | | Keep | — |
| `yaw-rate-sensor` | `diagrams/05-yaw-rate-sensor.svg` (`05:186`) | Coriolis vibrating mass | handcrafted | none | Keep | — |
| `lateral-acceleration` | `diagrams/05-accelerometer.svg` (`05:242`) | comb-finger accelerometer | handcrafted | none | Keep | — |
| `ackermann` | `diagrams/05-ackermann.svg` (`05:306`) | Ackermann geometry | handcrafted | none | Keep | — |
| `reference-model` | `diagrams/05-single-track.svg` (`05:378`) | single-track model | handcrafted | none | Keep | — |
| `yaw-correction` | `diagrams/05-esp-yaw-correction.svg` (`05:428`) | understeer and oversteer correction | handcrafted | none; it replaces the unused `slide19-understeer.png` and `slide19-oversteer.png` | Keep | — |
| `esp-algorithm` | `diagrams/05-esp-cascade.svg` (`05:467`) | the ESP cascade | handcrafted | none | Keep | — |
| `esp-evidence` | none | crash table, test criteria | | the test's steering input is described only in words | Optional SVG: the sine-with-dwell input, 0.7 Hz, 500 ms dwell, the 1.00 s and 1.75 s checks and the 1.07 s displacement mark. The top panel of `05-swd-yaw-rate.svg` nearly does this two slides later | — |
| `esp-model` | none | text and a check table | | "the planar car with ESP on top" is never shown as a bench | **Dyad**: `Lecture3.ESPSineWithDwell`. Six blocks (`steer`, `demand`, `steering_robot`, `car`, `sensors`, `ecu` = `BrakeControlUnit`), all placed, the same compact layout as `BrakeAndSteer` (30..900 × 200..580), 9 of 24 wires routed and the rest straight. Presentable | open: the Studio capture of `Lecture3.ESPSineWithDwell` needs Chrome |
| `esp-model-loop` | `diagrams/05-esp-model-loop.svg` (`05:635`) | our ESP block by block, with what it lacks dashed | handcrafted | none; the names match `YawReference`, `YawMomentController`, `BrakeAllocator`, `BrakeChannel`, `PlanarCarSensors` | Keep. A Dyad diagram of `Vehicle.Planar.ESPController` is **not** presentable: its four outputs and `Mz`, `r_ref`, `oversteer` are equations (`dT_fl = esp_on * allocator.dT_fl`, …), so the allocator would look unconnected | — |
| `esp-ours-vs-real` | none | comparison table | | | Keep | — |
| `esp-demo-passive` | `figures/05-swd-path.svg` (`05:749`) | three passive paths | `export_lecture03_esp_figures.jl` | none | Keep | — |
| `esp-demo-yaw` | `figures/05-swd-yaw-rate.svg` (`05:800`) | steering and yaw rate | same | none | Keep | — |
| `esp-demo-on` | `figures/05-swd-esp-path.svg` (`05:822`) | ESP on against off | same | none | Keep | — |
| `esp-demo-wheels` | `figures/05-swd-esp-yaw.svg` (`05:870`) | yaw against the reference; brake torque per wheel | same | none | Keep | — |
| `esp-through-abs` | `figures/05-esp-abs.svg` (`05:923`) | lowest slip; end speed | same | none | Keep | — |
| `split-mu` | `figures/05-split-mu.svg` (`05:980`) | four split-µ paths and headings | same | none | Keep. `Lecture3.SplitMuStop` has the same layout as `ESPSineWithDwell` if a bench picture is wanted | — |
| `systems-table` | none | the three-system table | | | **SVG**: reuse the nested-sets SVG from `what-tcs-does` | **done**: reuses `diagrams/04-abs-tcs-esp.svg` |
| `what-you-measured`, `sources` | none | tables | | | Keep | — |

Pictures in `public/` that no slide shows: `figures/02-booster-characteristic.svg` and
`figures/02-vacuum-{manifold,reserve,stopping}.svg` (from `scripts/export_lecture03_vacuum_figures.jl`);
`figures/01-combined-slip.svg` and `figures/03-brake-steer-forces.svg`, named only in notes; and
`pptx/slide03-*.jpg` and `pptx/slide19-{understeer,oversteer}.png`, named only in notes
(`01-friction-and-stopping.md:70`, `05-esp.md:451`). If the pptx pictures go, update those
notes.

## Inventory, build guide

All guide pictures are our own: Studio screenshots of `dyad/HandsOn03/` and the rehearsal
`MyCar`, and plots from `scripts/export_lecture03_build_figures.jl`. All are **Keep**.

| Step | Pictures | Note |
|---|---|---|
| 00 | `step00-wheel-library.png` | — |
| 01 | none | a paper step; none needed |
| 02 | `step02-params`, `-command-params`, `-line-r-params`, `-force-chain`, `-hydraulics`, `-pedal-bench`, `-fluid-code`, `-pedal03-plot`, `-pedal06-plot`, `step02-locked-stop.svg` | — |
| 03 | `step03-slipabs-diagram`, `-params`, `-valves`, `-abs-bench`, `-runA-plot`, `-slipabs-code`, `-abs-params`, `-runC-plot`, `step03-abs-torque-slip.svg` | — |
| 04 | `step04-estimator-diagram`, `-estimator-code`, `-phaseabs-diagram`, `-phaseabs-code`, `-wheel-only-midbuild`, `-wheel-only-bench`, `-phase-plot`, `-dry-plot`, `step04-phase-cycle.svg` | the deck's inline build/hold/dump state diagram (`03-abs.md:1135`) is not in the guide; step 04's phase explanation would gain from it |
| 05 | `step05-surface-table.png`, `step05-surfaces.svg` | — |
| 06 | none | the diagram is left out on purpose (`04-tcs.md:297`) |

## Status of the top 10

The top 10 were approved and are done in this worktree, except the Studio capture in item 6. The
handcrafted SVGs follow the palette, line widths and type sizes of the diagrams already in
`public/diagrams/`. They were checked as ImageMagick renders, not in a browser.

| # | Item | Status | Files |
|---|---|---|---|
| 1 | `lever-and-hydraulics` | done | added `diagrams/02-lever-hydraulics.svg`; removed `pptx/slide05-lever.jpg`, `slide05-hydraulic-multiplication.png`, `slide05-simple-brake-system.png` |
| 2 | `esp-sensors`, yaw-rate photo | done, dropped | removed `pptx/slide17-yaw-rate-sensor.jpg` |
| 3 | `wheel-speed-sensors` | done | added `components/CardExport.vue`, `public/cards/plotly-esm-min.mjs`, `public/cards/illustrations/crank-vr-hall.html` (copies of Lecture 2's); removed `pptx/slide08-tone-wheel.png`. Open: `scripts/export_deck_cards.jl` writes only Lecture 2, so this copy goes stale if the notebook changes |
| 4 | `abs-channels` | done | added `diagrams/03-abs-channels.svg` |
| 5 | `what-tcs-does`, `systems-table` | done | added `diagrams/04-abs-tcs-esp.svg`; removed `pptx/slide19-abs-tcs-esp.jpg` |
| 6 | `brake-steer-demo`, `esp-model` | partly done | bench screenshot enlarged; the `Lecture3.ESPSineWithDwell` capture is **open** (needs Studio and Chrome) |
| 7 | `master-cylinder` | done | added `diagrams/02-tandem-master-cylinder.svg`; removed `pptx/slide06-master-cylinder.jpg` |
| 8 | `esp-sensors`, components | done | added `diagrams/05-esp-components.svg`; removed `pptx/slide16-esp-components.png` |
| 9 | `abs-cycle` | done | added `diagrams/03-abs-cycle.svg` |
| 10 | `what-abs-does` | done | added `diagrams/03-abs-layout.svg`; removed `pptx/slide07-abs-layout.jpg` |

`style.css` gained five rules: `diagram-channels`, `diagram-systems`, `diagram-cycle`,
`diagram-path` and `img.bench-shot`. The sources slide no longer credits Renault. Ranks 11–16
below are still open.

## Ranked recommendations

Ranked by value for the students against effort. Removing a copyrighted or wrong picture
comes first.

1. **`lever-and-hydraulics`: one SVG in place of three HowStuffWorks images.** Removes three
   "©2000 How Stuff Works" pictures. Changes inches and pounds to SI and the model's ×3.5 lever and
   25/57 mm pistons. Gives the slide one style. Effort: low to medium.
2. **`esp-sensors`: drop `slide17-yaw-rate-sensor.jpg`.** It appears to show a steering-angle
   sensor, not a yaw-rate sensor, and the next slide draws the real thing. Effort: trivial; verify
   the part first.
3. **`wheel-speed-sensors`: reuse Lecture 2's `crank-vr-hall` card in place of
   `slide08-tone-wheel.png`.** The pptx picture shows square pulses for a passive sensor, which
   contradicts the slide. The card already exists. Effort: low.
4. **`abs-channels`: new SVG of the three channel layouts.** The slide describes three plan views
   in words only. It builds on the `02-dual-circuit.svg` template. Effort: low.
5. **`what-tcs-does` and `systems-table`: one nested-systems SVG in place of the Bosch
   graphic.** Removes a branded, dark-background picture, and gives the wrap-up table the picture
   it lacks. Effort: low.
6. **`brake-steer-demo` and `esp-model`: Dyad bench diagrams at a readable size.** Enlarge
   `planar-brake-steer-bench.png` from `h-40`. Add a Studio screenshot of
   `Lecture3.ESPSineWithDwell` to `esp-model`: its layout is already presentable. Effort: low (two
   Studio captures).
7. **`master-cylinder`: SVG tandem master cylinder in place of HowStuffWorks.** Copyrighted
   picture. The SVG can show the compensating ports and dead stroke the notes explain, with the
   model's names. Effort: medium.
8. **`esp-sensors`: SVG plan view in place of the Renault diagram.** License unclear, text too
   small, and its item list differs from the slide's. Color the sensors by intention and by
   motion. Effort: medium.
9. **`abs-cycle`: SVG of the Bosch control cycle.** The topic's best-known picture is missing.
   It connects the source deck's algorithm, Bosch's eight phases and the students' own `PhaseABS`.
   Effort: medium to high.
10. **`what-abs-does`: SVG plan view in place of the brochure scan.** License unclear, small, and
    it carries a stray service note. A simplified preview of `03-abs-system.svg`. Effort: medium.
    Also fix "Four parts:" over three bullets (`03-abs.md:48`).
11. **`reference-speed`: new figure of v, ωr and v_ref at μ 0.3.** It shows the a_ref trap that
    builds 04 and 05 turn on. Effort: medium (a new block in `export_lecture03_figures.jl`).
12. **`cornering-limit`: SVG in place of `slide04-car-on-curve.jpg`.** Low-resolution and of
    unknown origin. Effort: low.
13. **`modulator`: drop `slide09-abs-modulator.jpg`, or use a CC photo.** HowStuffWorks ©. Effort:
    trivial to drop.
14. **`combination-valve`: SVG plan view with the proportioning valve, or drop the picture.**
    HowStuffWorks ©. Effort: medium; dropping it is trivial.
15. **`abs-system`: raise its 10–11 px labels to 13 px.** Check it on the projector first.
    Effort: low.
16. Optional, low priority: `tcs-actuators` (TCS loop with two actuator paths), `esp-evidence`
    (sine-with-dwell input), `abs-loses` (gravel wedge, flat snow curve), `abs-system-models`
    (three mini chains), `pedal-to-pressure` (booster cross-section, or the orphan
    `02-vacuum-manifold.svg`), guide step 04 (the inline state diagram).

Dyad diagrams checked and found **not** presentable as they stand: `Vehicle.Planar.ESPController`
and `Vehicle.Planar.ABSUnit`, whose outputs are equations and not wires; `Vehicle.ABSModulatorDiscrete`
and `ABSWheelOnlyEstimatorDiscrete`, which are equations only; `HandsOn03.SlipABS`, `PhaseABS` and
`RefSpeedEstimator`, which have one block or none. Presentable: the three `HandsOn03` benches
(already used), `Lecture3.BrakeAndSteer`, `ESPSineWithDwell`, `SineWithDwellRun`, `SplitMuStop`,
`Vehicle.ABSBrakeTest`, `Vehicle.ABSControllerWheelOnly`, `Vehicle.Brake.TestForceChain` and
`Vehicle.Wheel.HydraulicBrakedWheel`. That last one is a straight row of inertia, two calipers and
the tire, all placed, but its wires carry no route metadata.
