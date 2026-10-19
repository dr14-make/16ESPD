# Lecture 2 theory deck — where its figures come from

Every plot, diagram and table in the Lecture 2 theory deck (`slides/decks/lecture-02/`, PR #48),
with what replaces it, the code that produces the replacement, and what that code waits on. The
pictures carried from `2. Engine CS.pptx` are a stopgap; the goal is that most plots, diagrams and
tables come from code. Read `lecture-02-plan.md` (model ladder, tiers, reality anchors) and
`lecture-02-mapped-engine-plan.md` (tasks 1–6 of #44) first. Terms follow `slides/CONTEXT.md`: a
**figure** is a plot produced by running a notebook, a **diagram** is hand-drawn, a **live card**
is a notebook cell shown on a slide, a **screenshot** is a Dyad Studio capture.

## Classes

| Class | Meaning |
|---|---|
| **R** | Replace with a figure from a named notebook cell or script |
| **G** | Generate a table from code or repository data |
| **D** | Keep as a diagram, redrawn to match a Dyad component, or a screenshot of it |
| **N** | New figure or table the code makes possible, on a slide that has none for it |
| **K** | Keep the pptx picture; code cannot or should not produce it |
| **X** | Remove; superseded or duplicated once the code figures exist |

R, G, D and N count as "from code"; K and X do not.

Slides are numbered twice. **pptx** is the slide number in `2. Engine CS.pptx`, which is also the
prefix of each image in `public/pptx/`. **Deck** is `section.position`, the position counting the
section's cover slide as 1: `01.3` is the third slide of `sections/01-vehicle-energy.md`, the
rolling-resistance slide. The route alias is given where the slide has one.

## How code output reaches the deck

Lecture 2 uses **live cards painted from snapshots**, the mechanism #28 is building for Lecture 1,
and never the `save_figure` path.

- A slide places `<PlutoCard notebook="…" name="…" />`, and the cell carries the matching `card`
  metadata. With no kernel (Pages, `slidev dev` alone, the handout export), the card paints the
  cell's saved output from the notebook's committed `.plutostate` snapshot (#31). With PlutoDeck
  running, it switches to the live cell (#32).
- Plots are PlutoPlotly, as ADR 0005 on the `feat/pluto-lecture-01` integration branch records:
  its plot data travels in the snapshot and its Plotly loader works with no network. Plots.jl
  images do not.
- Tables are cards too: a cell that reads `data/engine/` or a coefficient file and renders an HTML
  table. The workspace check then catches a table whose data or code changed after the snapshot,
  which a table typed into the markdown cannot do.
- `slides/decks/lecture-02/public/figures/` is never created. Lecture 1's `save_figure` SVGs are
  being retired (#38); adding a second deck to that path would add to what #38 has to delete.

**Infrastructure gate I0.** Live cards are not on `main` yet. The deck can show a card once the
addon restore (#30, PR #39, which targets `feat/pluto-lecture-01`), the snapshot writer and
painter (#31) and several notebooks per deck (#34; Lecture 2 draws on about ten) have merged to
`main` through #28. Until then every replacement below can be built and checked as a notebook
cell, and the deck keeps the pptx picture in its slot. If the lecture date arrives before I0, the
fallback is a one-off PlutoPlotly HTML export per cell into the deck, not `save_figure`.

The draft notebooks 03–06 (PR #2) need three changes before any of their cells become cards: their
plots move from Plots.jl to PlutoPlotly, the cells the deck uses gain `card` metadata, and the
stubs are replaced by the real analyses. A stub's output is a placeholder, not a figure.

## Where the cells live

| Notebook | Spec | Cells this plan adds |
|---|---|---|
| 01 Where the energy goes | `lecture-02-notebooks.md` | force-vs-speed from the `VehicleBody` defaults before task 8; rolling-resistance table from a coefficient file |
| 02 The cycle and the spark | as specced | ideal air-standard Otto and Diesel p–V loops, before task 6 |
| 03 The engine as a plant | as specced | λ × spark sweep on `EngineDyno` (torque, BSFC and power against λ) |
| 09 Sensors | as specced | NTC resistance from the Bosch M12 table, before task 10 |
| **12 The mapped engine** (new) | this plan | ALPHA maps from `data/engine/`, `AirPathTransient` runs, mapped-engine runs once tasks 3–4 land |

No specced notebook reads `data/engine/`: notebook 03 plots the `MeanValueEngine` maps (task 2),
not the ALPHA maps. Notebook 12 is the home for everything the deck can take from the hands-on
engine's data and air path, which is most of what is possible today.

## Slide by slide

### 01 Vehicle energy (pptx 16–18)

| pptx | Deck | Visual | Class | Replacement | Produced by | Blocked on | Text update |
|---|---|---|---|---|---|---|---|
| 16 | 01.2 `energy-used` | `slide16-vehicle-forces.jpeg`, free-body sketch | K | — | — | — | — |
| 16 | 01.2 `energy-used` | energy per term over WLTC and the EPA highway cycle | N | stacked bars, energy per km per term | notebook 01 cells 3–4, `DriveCycleTransient`, `RoadLoadMeter` | Dyad task 8 | the auxiliaries line can quote the model's 500 W `(assumed)` |
| 17 | 01.3 `rolling-resistance` | `slide17-rolling-resistance-vs-speed.png`, f against speed per tire pressure | K | — | — | — | — |
| 17 | 01.3 `rolling-resistance` | `slide17-rolling-resistance-table.png` | G | table of rolling coefficients by surface | notebook 01, reading a new `data/road/rolling_resistance.csv` that its `C_r` slider also uses | nothing; **today** | — |
| 18 | 01.4 `drag-and-rolling` | `slide18-drag-and-rolling-force.png` | R | drag and rolling force against speed for the Lecture 1 car, crossover marked | notebook 01 cell 2; from `VehicleBody` defaults today, `RoadLoadMeter` after task 8 | nothing; **today** | **yes**: crossover and ratio, see below |

### 02 Engine and cycles (pptx 19–23)

| pptx | Deck | Visual | Class | Replacement | Produced by | Blocked on | Text update |
|---|---|---|---|---|---|---|---|
| 20 | 02.3 `otto-cycle` | `slide20-otto-cycle.png`, ideal p–V with stroke sketches | R | ideal air-standard Otto p–V today; fired cycle at MBT beside it after task 6 | notebook 02 cell 1 (ideal), cell 3 (`SparkSweep` on `SingleCylinder`) | nothing for the ideal loop; **today**. Task 6 for the fired loop | compression ratio and efficiency from the run (`r_c` = 10.5) |
| 20 | 02.3 `otto-cycle` | `slide20-four-stroke.gif`, animation | K | — | — | — | — |
| 21 | 02.4 `two-and-four-stroke` | `slide21-two-and-four-stroke.gif`, animation | K | — | — | — | — |
| 22 | 02.5 `diesel-cycle` | `slide22-diesel-pv.png` | R | ideal air-standard Diesel p–V beside the Otto loop at equal heat input | notebook 02, new cell, pure computation | nothing; **today** | — |
| 23 | 02.6 `stoichiometric` | `slide23-power-and-efficiency-vs-afr.png` | R | torque and brake efficiency against λ, as % of their maxima | notebook 03, new λ × spark sweep cell on `EngineDyno` | Dyad task 2, plus a λ input on `EngineDyno` | label the shape `(assumed)`: it is `M_lambda` |
| 23 | 02.6 `stoichiometric` | `slide23-mixture-range.png` | X | its content (7:1, 20:1 limits) is in the notes; frees room for the efficiency map | — | — | — |
| 23 | 02.6 `stoichiometric` | brake efficiency map of the hands-on engine, peak marked | N | efficiency contour over speed and torque from the ALPHA maps | notebook 12 from `torque_Nm.csv` and `fuel_gps.csv` | nothing; **today** | **yes**: 37 % → 36 %, and the idle claim |

Slide 02.6 holds two plots and a block of principles already. With the efficiency map it should
split in two: principles and the efficiency map, then the stoichiometric mixture and the λ plot.

### 03 Engine control system (pptx 24–29)

| pptx | Deck | Visual | Class | Replacement | Produced by | Blocked on | Text update |
|---|---|---|---|---|---|---|---|
| 24 | 03.2 `ecs-structure` | `diagrams/03-engine-control-loop.svg` | D | redrawn with the model's blocks: sensors (`LambdaSensorSwitching`, `NTCSensor`, `HotFilmMAF`), ECU (`FuelMetering`, `TwoStepLambdaController`, `IdleSpeedController`, `KnockControl`, `TorqueStructure`), actuators (`Throttle`, `FuelInjector`, `IgnitionCoil`), plant `MeanValueEngine` | hand-drawn against `EngineCarPlant` | Dyad task 12 | — |
| 24 | 03.2 `ecs-structure` | `slide24-ecu-map.png`, generic calibration surface | R | the hands-on engine's torque map `T_e(N, p_m)`, as a surface | notebook 12 from `torque_Nm.csv` | nothing; **today** | notes: the map is the hands-on engine's ALPHA map, not notebook 03's |
| 28 | 03.6 `control-strategy` | coast-down: throttle closed, fuel to zero, torque to the closed-throttle curve | N | fuel flow and torque against time through a lift-off | notebook 12, `MappedEngine` test or `MappedEngineCar` coast-down | mapped-engine task 3 (task 4 for the car) | — |
| 29 | 03.7 `ee-architecture` | `slide29-ee-architecture.png` | K | — | — | — | — |

### 04 Sensors (pptx 30–37)

| pptx | Deck | Visual | Class | Replacement | Produced by | Blocked on | Text update |
|---|---|---|---|---|---|---|---|
| 30 | 04.2 `automotive-sensors` | `slide30-sensor-in-the-loop.png` | K | — | — | — | — |
| 30 | 04.2 `automotive-sensors` | `slide30-characteristic-curves.png`, sketched curve types | K | — | — | — | — |
| 32 | 04.4 `basic-control-system` | `slide32-engine-control-layout.png`, hardware layout | K | — | — | — | — |
| 34 | 04.6 `tps` | `slide34-throttle-body.jpeg`, photo | K | — | — | — | — |
| 34 | 04.6 `tps` | `slide34-tps-construction.png`, cutaway | K | — | — | — | — |
| 34 | 04.6 `tps` | `slide34-tps-circuit.png`, sensor circuit | K | — | — | — | — |
| 36 | 04.8 `temperature-sensors` | `slide36-coolant-temperature-sensor.jpeg`, photo | K | — | — | — | — |
| 36 | 04.8 `temperature-sensors` | `slide36-hfm-exploded.png`, exploded view | K | — | — | — | — |
| 36 | 04.8 `temperature-sensors` | `slide36-ntc-characteristic.png` | R | NTC resistance against temperature, log scale; divider voltage beside it after task 10 | notebook 09, from the Bosch M12 table today, `NTCSensor` after task 10 | nothing; **today** | notes: the Fahrenheit and "low resistance" remarks go with the pptx curve |
| 37 | 04.9 `maf` | `slide37-maf-response.png`, oscilloscope trace | R | throttle air flow `mdot_thr` (what a MAF sees) and `mdot_cyl` through a tip-in: the overshoot while the manifold fills; `HotFilmMAF` output overlaid after task 10 | notebook 12, `AirPathTransient`; notebook 09 for the sensor | nothing; **today** | notes: "Notebook 09 will regenerate" → notebook 12, with 09 adding the sensor |
| 37 | 04.9 `maf` | `slide37-hot-film-maf.png`, photo | K | — | — | — | — |
| 37 | 04.9 `maf` | volumetric efficiency `η_v(N, p_m)`, the speed-density table | N | contour, with the 33 kPa idle and 95 kPa full-load lines | notebook 12 from `eta_v.csv` | nothing; **today** | — |

### 05 Fuel injection (pptx 38–46)

| pptx | Deck | Visual | Class | Replacement | Produced by | Blocked on | Text update |
|---|---|---|---|---|---|---|---|
| 38 | 05.2 `fuel-injection-system` | `slide38-fuel-system.jpg`, hardware layout | K | — | — | — | — |
| 39 | 05.3 | `slide39-k-jetronic.jpeg`, hardware layout | K | — | — | — | — |
| 39 | 05.3 | `slide39-fuel-distributor.jpeg`, cutaway | K | — | — | — | — |
| 40 | 05.4 `single-point` | `slide40-single-point.png`, hardware layout | K | — | — | — | — |
| 41 | 05.5 `multipoint` | `slide41-multipoint.png`, hardware layout | K | — | — | — | — |
| 42 | 05.6 `direct-injection` | `slide42-homogeneous-di.png`, hardware layout | K | — | — | — | — |
| 42 | 05.6 `direct-injection` | `slide42-stratified-di.png`, cutaway | K | — | — | — | — |
| 43 | 05.7 `fuel-injector` | `slide43-injector-spray.jpg`, photo | K | — | — | — | — |
| 43 | 05.7 `fuel-injector` | `slide43-injector-section.png`, cutaway | K | — | — | — | — |
| 44 | 05.8 `pulse-width` | `slide44-afr-map.png`, target AFR table | G | target AFR table, `14.6 · λ(N, p_m)`, rpm rows × load columns, colored like the original | notebook 12 from `lambda.csv` | nothing; **today** | **yes**: 14.7 → 14.6, the axes, where it richens |
| 44 | 05.8 `pulse-width` | base pulse width across the map | N | `t_base(N, p_m)` from the fuel map and the injector's static flow | notebook 12 from `fuel_gps.csv` and 146 cm³/min; notebook 04 cell 3 adds dead time after tasks 3–4 | nothing; **today** | — |
| 45 | 05.9 `injector-activation` | `slide45-injector.png`, four traces | R | activation, current, needle lift and fuel on one time axis, `t_on` and `t_off` marked | notebook 05 cell 2, `InjectorPulseTransient` | Dyad task 4 | `t_on`, `t_off` and dead time from the run |
| 46 | 05.10 | `slide46-spray-geometry.png`, spray shapes | K | — | — | — | — |

### 06 Ignition (pptx 47–55)

| pptx | Deck | Visual | Class | Replacement | Produced by | Blocked on | Text update |
|---|---|---|---|---|---|---|---|
| 47 | 06.2 `ignition-timing` | `slide47-advance-curves.png` | R | MBT advance against speed at part and full load; manifold pressure below | notebook 02, cell 5 extended to two loads (`SparkSweep`) | Dyad task 6 | **yes**: "about 5° BTDC" against the run |
| 48 | 06.3 | `slide48-spark-plug-section.png`, cutaway | K | — | — | — | — |
| 48 | 06.3 | `slide48-spark-plug-electrodes.png`, photo | K | — | — | — | — |
| 49 | 06.4 | `slide49-corona-igniter.png`, photo | K | — | — | — | — |
| 50 | 06.5 `ignition-advance` | `slide50-combustion-pressure.png` | R | pressure against crank angle at MBT, MBT + 15°, MBT − 15° | notebook 02 cell 4, `SparkSweep` | Dyad task 6 | peak-pressure angle at MBT from the run (band 12–20° ATDC) |
| 50 | 06.5 `ignition-advance` | `slide50-advance-map.png` | R | `sigma_mbt(N, p_m)` as a surface; task 6's physics-based version beside it later | notebook 03, new cell plotting the `TorqueProduction` table | Dyad task 2 | label `(assumed)` until task 6 |
| 51 | 06.6 `timing-and-emissions` | `slide51-hc-vs-lambda.png` | K | the model has no spark-dependent chemistry (plan, known limits) | — | — | — |
| 51 | 06.6 `timing-and-emissions` | `slide51-nox-vs-lambda.png` | K | as above | — | — | — |
| 51 | 06.6 `timing-and-emissions` | `slide51-co-vs-lambda.png` | K | as above | — | — | — |
| 52 | 06.7 `ignition-functions` | `slide52-torque-vs-lambda.png` | R | torque against λ, one curve per spark advance | notebook 03, the λ × spark sweep cell (same run as 02.6) | Dyad task 2 | label `(assumed)` shapes |
| 52 | 06.7 `ignition-functions` | `slide52-bsfc-vs-lambda.png` | R | BSFC against λ, one curve per spark advance | as above | Dyad task 2 | as above |
| 53 | 06.8 `ignition-coil` | `slide53-coil-section.png`, cutaway | K | — | — | — | — |
| 53 | 06.8 `ignition-coil` | `slide53-coil-cutaway.gif` | X | second cutaway of the same part; frees room for the coil traces | — | — | — |
| 53 | 06.8 `ignition-coil` | `slide53-coil-ignition-circuit.png` | D | screenshot of `IgnitionCoil`: battery, primary, switch, secondary, gap; the breaker circuit stays on 06.9 | Dyad Studio | Dyad task 9 | — |
| 53 | 06.8 `ignition-coil` | primary current through the dwell, secondary voltage at cut-off | N | two stacked traces; stored energy `½ L₁ I₁²` read off | notebook 08, `IgnitionCoil` harness | Dyad task 9 | the "up to 100,000 V" note against the run's 20–40 kV |
| 54 | 06.9 | `slide54-distributor.jpeg`, photo | K | — | — | — | — |
| 54 | 06.9 | `slide54-advance-mechanism.png`, mechanism drawing | K | — | — | — | — |
| 54 | 06.9 | `slide54-contact-breaker-circuit.png`, historical circuit | K | — | — | — | — |
| 55 | 06.10 | `slide55-coil-near-plug.jpg`, hardware layout | K | — | — | — | — |

### 07 Emissions and lambda (pptx 56–59)

| pptx | Deck | Visual | Class | Replacement | Produced by | Blocked on | Text update |
|---|---|---|---|---|---|---|---|
| 56 | 07.2 `evap` | `slide56-evap-system.gif`, hardware layout | K | — | — | — | — |
| 56 | 07.2 `evap` | purge step rejected by the λ loop | N | λ against time through an 8 % purge step | notebook 06 cell 9, `LambdaLoopTransient` | Dyad task 5 | — |
| 57 | 07.3 `lambda-control` | `slide57-sensor-locations.png`, installation drawing | K | — | — | — | — |
| 57 | 07.3 `lambda-control` | `slide57-two-step.png` | R | controller output (jump and ramp) and sensor voltage, stacked | notebook 06 cell 3 | Dyad task 5 | **yes**: amplitude and period from the run |
| 58 | 07.4 `oxygen-sensor` | `slide58-sensor-construction.jpeg`, cutaway | K | — | — | — | — |
| 58 | 07.4 `oxygen-sensor` | `slide58-sensor-curve.jpeg` | R | sensor voltage against λ | notebook 06 cell 1, `LambdaSensorRampTransient` | Dyad task 5 | — |
| 59 | 07.5 `catalyst` | `slide59-catalyst-layouts.png`, installation drawing | K | — | — | — | — |
| 59 | 07.5 `catalyst` | oxygen storage under the limit cycle | N | λ entering and stored oxygen `θ`, stacked; downstream λ flat | notebook 06 cell 7 | Dyad task 5 | — |

### 08 The mapped engine (no pptx source)

| pptx | Deck | Visual | Class | Replacement | Produced by | Blocked on | Text update |
|---|---|---|---|---|---|---|---|
| — | 08.2 `what-you-build` | `diagrams/08-mapped-engine.svg` | D | redrawn to `MappedEngine`'s components: `Throttle`, `IntakeManifold`, `CylinderAirflow`, the `InterpolatedTable` maps, torque source and `Inertia`; or its screenshot, shared with the hands-on deck | hand-drawn or Dyad Studio | mapped-engine task 3 | — |
| — | 08.3 `mapped-engine-equations` | manifold pressure after a throttle step at 800 and 3000 rpm, normalized, beside Lecture 1's 0.3 s lag | N | two step responses and the `IdealEngine` lag on one axis | notebook 12, `AirPathTransient` | nothing; **today** | notes: 0.15 s at idle stays; add 0.023 s at 3000 rpm |
| — | 08.4 `what-you-measure` | fuel and CO₂ at 50, 90, 130 km/h | N | table: L/h, L/100 km, g CO₂/km | notebook 12, `MappedEngineCar` cruise runs | mapped-engine task 4 | — |

Slide 08.4 can carry the cruise table only if the hands-on is not meant to reveal those numbers
first; the section's notes say the numbers are for the hands-on. That is the lecturer's choice.
The table counts as N below.

### 09 Drive cycles (no pptx source)

Added after this plan's counts; the tables below do not include it. Sources and the numbers'
provenance are in `lecture-02-drive-cycles-research.md`.

| pptx | Deck | Visual | Class | Replacement | Produced by | Blocked on | Text update |
|---|---|---|---|---|---|---|---|
| — | 09.3 `modal-vs-transient` | NEDC above WLTC class 3b on one time axis, parts shaded | N | — | `illustrations` card `nedc-vs-wltc`, from `assets/data/drive_cycles/` and R83's tables | nothing | — |
| — | 09.4 `cycles-by-region` | comparison table | G | authored Markdown; the NEDC, WLTC and EPA rows pinned by the `illustrations` assertion cell | `illustrations` | nothing | — |
| — | 09.7 `wltc-class-3b` | WLTC class 3b with phases and the cumulative distance | N | — | `illustrations` card `wltc-3b` | nothing | — |

Front-matter slides 00.1–00.3 have no picture, and the equation tables on 01.2 and 08.3 and the
section index on 00.3 are authored text, so they are not counted.

## Text that changes with the code

| pptx | Deck | Current claim | What the code says | Changes when |
|---|---|---|---|---|
| 18 | 01.4, 01.5 | rolling and drag cross near 8 m/s (29 km/h); drag is more than ten times rolling at motorway speed; summary: drag dominates above about 30 km/h | for the Lecture 1 car (1400 kg, `f_r` 0.012, `CdA` 0.63 m², ρ 1.2): rolling 165 N, crossover 20.9 m/s (75 km/h), drag 3.0× rolling at 130 km/h | today, with the 01.4 figure |
| 23 | 02.6 | about 37 % efficiency | the hands-on engine's minimum BSFC is 232 g/kWh at 3000 rpm, 77.5 kPa, 99 N·m: 35.7 % with `H_l` = 43.4 MJ/kg | today |
| 23 | 02.6 | stoichiometric "used for idle running" | λ = 1 everywhere below 85 % of full-load manifold pressure, richening to 0.90–0.80 at full load (`lambda.csv`) | today; the notes already say so, the slide does not |
| 44 | 05.8 | target map at 14.7 over speed × load 10–100, richer above 4000 rpm | the hands-on map is 14.6 · λ over rpm × kPa, richer only above 85 % load, deepest at high speed; the 14.6/14.7 note in 05.8 goes | today, with the G table |
| 24 | 03.2 notes | notebook 03 puts our 1.5 L maps here | the map shown is the hands-on engine's ALPHA map from notebook 12 | today |
| 36–37 | 04.8, 04.9 notes | remarks on the pptx curve's labels; notebook 09 regenerates the MAF | the remarks go with the curve; the MAF trace comes from notebook 12 first | today |
| 47 | 06.2 | normal operation about 5° BTDC | `sigma_mbt` is about 10° at idle `(assumed)`; task 6 gives the physics-based MBT | Dyad task 6 |
| 50 | 06.5 | peak pressure shortly after TDC | the run's angle (band 12–20° ATDC) | Dyad task 6 |
| 52 | 06.7 | torque peaks rich, consumption lowest lean, more advance is better within knock | true of the model by construction, `M_lambda` and `M_sigma` are assumed; the slide must say so | Dyad task 2 |
| 53 | 06.8 notes | up to 100,000 V | the open-circuit peak of the model, 20–40 kV band | Dyad task 9 |
| 57 | 07.3 | typical variation 2–3 % | the run's amplitude and its frequency at idle and 3000 rpm (band 0.5–5 Hz) | Dyad task 5 |
| — | 08.3 notes | time constant about 0.15 s at idle | matches the air path (0.15 s at 800 rpm); add 0.023 s at 3000 rpm part load | today |

## Waves

Each wave lists the slides it unblocks. Every wave also waits on I0 for display.

| Wave | Waits on | Unblocks |
|---|---|---|
| **W0 — today** | merged code only: `data/engine/` (#46), the air path (#47), `VehicleBody`, the Bosch NTC table | R 01.4, 02.3 (ideal loop), 02.5, 03.2 map, 04.8, 04.9 trace · G 01.3, 05.8 · N 02.6, 04.9 η_v, 05.8 pulse width, 08.3 |
| **W1 — Tier 1** | Dyad tasks 2–5, notebooks 03–06 | R 02.6 λ plot, 05.9, 06.5 map, 06.7 (two), 07.3, 07.4 · N 07.2, 07.5 |
| **M — mapped engine** | mapped-engine tasks 3–4, in parallel with W1 | D 08.2 · N 03.6, 08.4 |
| **W2 — Tier 2** | Dyad tasks 6 and 8, notebooks 02 and 01 | R 06.2, 06.5 pressure, and the fired loop on 02.3 · N 01.2 |
| **W3 — Tier 3** | Dyad tasks 9, 10 and 12, notebooks 08, 09 and 11 | D 03.2 loop, 06.8 circuit · N 06.8 · the model overlays on 04.8 and 04.9 |

W0 needs no Dyad work: twelve items in notebooks 01, 02, 09 and the new 12. Task 7 (idle,
notebook 07) unblocks no slot.

## Counts

| Class | Count | Of which today |
|---|---|---|
| R | 15 | 6 |
| G | 2 | 2 |
| D | 3 | 0 |
| N | 10 | 4 |
| **From code** | **30** | **12** |
| K | 39 | — |
| X | 2 | — |

The deck references 61 visuals (59 pptx pictures and 2 SVG diagrams). After the plan it shows 69:
61 − 2 removed + 10 new. Of the 39 kept, 30 are photos, cutaways, animations and hardware layouts
that code cannot produce, and 9 are plots or diagrams code should not replace: the
engineeringtoolbox tire data, conceptual sketches, and the HC/NOx/CO plots the model does not
simulate.

**Over plots, diagrams and tables**, which is what the goal names, the majority is reachable. The
deck has 30 of them today and 39 after the plan; 30 of the 39 come from code.

| After | Plots, diagrams, tables shown | From code | Share |
|---|---|---|---|
| W0 | 33 | 12 | 36 % |
| W0 + W1 | 35 | 21 | **60 %** |
| + M | 37 | 24 | 65 % |
| + W2 | 38 | 27 | 71 % |
| + W3 | 39 | 30 | 77 % |

The majority is reached at the end of W1, the lecture plan's "Tier 1 is safe" line. Counting every
picture, photos included, code reaches 30 of 69 (43 %) and no wave reaches a majority without
dropping hardware photos the lecture needs.

## Gaps

**Slots no plan fills yet.** Each needs a cell added to a notebook spec.

| Slot | Missing |
|---|---|
| 01.3 rolling table | no coefficient file in `data/`; notebook 01's slider assumes one |
| 02.5 Diesel p–V | notebook 02 has no Diesel cell; `SingleCylinder` is spark-ignition only, so it is an ideal-cycle cell |
| 02.6, 06.7 λ plots | no notebook sweeps λ and spark; `EngineDyno` meters fuel at λ = 1 through a fixed gain and needs a λ input |
| 06.2 advance curves | notebook 02 cell 5 sweeps speed at one load; the slide needs part and full load |
| 06.5 advance map | no cell plots `TorqueProduction`'s `sigma_mbt` table |
| 03.2, 04.9, 05.8, 08.3 | no specced notebook reads `data/engine/` or runs `AirPathTransient` for the deck; notebook 12 is new |
| 03.6 fuel cut-off | mapped-engine task 3 tests coast-down, but no notebook plots it |

**Conflicts to settle.**

- Slide 44's AFR map. Dyad task 3 transcribes the pptx map (14.7, speed × load %) into
  `FuelMetering`; the hands-on engine has its own (`lambda.csv`, 14.6, rpm × kPa). This plan
  shows the hands-on map on 05.8. `FuelMetering` should read `lambda.csv` too, or notebook 04
  must explain why the theory engine and the hands-on engine target different mixtures.
- Dyad task 8 and notebook 01 require drag above 3× rolling at 130 km/h. With the Lecture 1 car
  the ratio is 2.99, and lower still if `f_r` rises with speed. The band needs to move to about
  2.5×, or the acceptance needs to state the car it assumes.

**Figures the notebooks make that the deck has no slot for.**

| Notebook | Cells | Nearest slide |
|---|---|---|
| 02 | ideal Otto efficiency against `r_c`; knock proxy; indicated against ideal efficiency | 02.6, which explains why 36 % and not 50 % |
| 03 | `p_m` at idle, WOT and overrun; induction delay against speed | 00.2 `from-lecture-1`, which asks where the delay and lag come from |
| 04 | tip-in λ spike, x–τ compensation, cold against warm | 03.6, acceleration enrichment and warm-up |
| 05 | fuel per pulse against pulse width; dead time against battery voltage; flyback | 05.8, the battery-voltage factor in the notes |
| 06 | period against speed; rich shift; post-cat trim; wideband against two-step | 07.3, 07.5 |
| 07 | the whole idle loop | 03.6, idling |
| 10 | warm-up, thermostat, catalyst light-off | 03.6, warm-up |
| 11 | WOT terminal speed with the rev limiter; the Lecture 1 cruise step on the real engine | 00.2 notes promise the 246 km/h fix; the deck shows it nowhere |

These belong to the notebooks; the deck links to them rather than adding slides for each. The
strongest candidates for a new slide are notebook 03's induction delay on 00.2 and notebook 11's
top speed, because the deck already promises both.
