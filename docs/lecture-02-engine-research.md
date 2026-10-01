# Lecture 2 (second half) — engines and their control systems: research

Research phase only: what we can build in Dyad and which notebooks it supports. Nothing here is
implemented yet.

## Source and scope

`materials/ControlTheory/2. Engine CS.pptx`, 59 slides. Slides 2–15 (systems, open and closed loop,
PID, Ziegler-Nichols) are already taught by the Lecture 1 notebooks. The second half, slides 16–59,
is what this document covers:

| Slides | Topic | Content type in the deck |
|---|---|---|
| 16–18 | Vehicle energy: drag, rolling, acceleration, grade, auxiliaries; rolling-resistance table | equations, table |
| 19–23 | ICE classification, Otto and Diesel cycles, efficiency, stoichiometric AFR 14.6 | p–V diagrams, prose |
| 24–29 | Engine control system: ECU, sensors and actuators; functions; control strategies (cranking, warm-up, cut-off, idle, enrichment and enleanment, rev limit); E/E architecture | block diagrams, lists |
| 30–37 | Sensors: classification, requirements, TPS, contactless sensors, NTC temperature, hot-film MAF | photos, characteristic curves |
| 38–46 | Fuel injection: SPI/MPI/GDI, injector construction, **pulse width = base × factors**, AFR map vs speed and load, injector current and needle lift, spray geometry | map (image53), timing figure (image54) |
| 47–55 | Ignition: timing and advance, spark plug, MBT, **pressure trace vs spark angle**, NOx/HC/BSFC vs timing, dwell, coil, distributor, coil-on-plug | figures (image62–67) |
| 56 | EVAP canister purge | schematic |
| 57–59 | **Lambda control**: two-step jump/ramp limit cycle, sensor placement, ZrO₂ switching characteristic, three-way catalyst | figures (image75, image76) |

The deck is descriptive: almost every figure in 44–58 is the *output* of a model we can build. That
is the teaching angle: students regenerate the deck's figures from first principles rather than
reading them.

## What the repository already gives us

- `Vehicle.IdealEngine`: torque command → shaft torque through a 0.3 s Padé transport delay and a
  0.3 s first-order lag. Its own docstring says the lags stand in for "injection-to-torque" delay
  and "manifold filling". **That is the bridge into this lecture**: Lecture 1 assumed the plant was
  FOPTD; Lecture 2 shows where the delay and the lag come from, and that they move with speed and
  load.
- `Vehicle.VehicleBody` already models drag, rolling resistance, and grade (slides 16–18 minus
  acceleration bookkeeping and auxiliaries). `CarPlant`, `Driveline` and `CruiseLoop` wrap it.
- House patterns that carry over: causal signal-level components where acausal adds nothing
  (the brake report's recommendation), discrete logic as continuous `ifelse` latches rather than
  events (`ABSController`), a test component per model, and Padé delays with no feedthrough.

Standard-library pieces confirmed present (Dyad 3.4 depot):

| Need | Component |
|---|---|
| Engine maps (AFR, spark advance, VE, BSFC vs speed × load) | `BlockComponents.Tables.InterpolatedTable` (2-D, linear/constant/B-spline per axis) |
| 1-D characteristics (NTC, HEGO, throttle area) | `BlockComponents.Tables.Interpolation`, `Math.Tanh` |
| Transport delay | `BlockComponents.Nonlinear.PadeDelay` |
| Solenoid / coil / transformer | `ElectricalComponents.Analog.Basic.Inductor`, `VariableInductor`, `SaturatingInductor`, `Transformer`, `TranslationalEMF` |
| Needle stops | `TranslationalComponents.Components.ElastoGap`, `Mass`, `Spring` |
| Crankshaft, flywheel, accessory load | `RotationalComponents.Components.Inertia`, `Damper`, sources |
| Warm-up, thermostat, radiator | `ThermalComponents.Components.HeatCapacitor`, `ThermalConductor`, `ThermalResistor` |
| Linearization, loop analysis, autotuning | `DyadControlSystems`: `LinearAnalysis`, `ClosedLoopAnalysis`, `ClosedLoopSensitivityAnalysis`, `FrequencyResponseAnalysis`, `PIDAutotuningAnalysis`, `SystemIdentificationAnalysis` |
| Map calibration / parameter fitting | `DyadModelOptimizer` |
| Sampled ECU logic | `DiscreteComponents` (still blocked upstream for Lecture 1 notebook 09; see HANDOVER Risk 3) |

The intake manifold should be written as a causal isothermal filling equation (ṁ_in − ṁ_out =
V/(RT)·ṗ) rather than through `HydraulicComponents` with a gas medium: two lines of physics, fully
visible to students.

## Candidate models

Grouped by the deck's sections. Every model names the slide figure it reproduces.

### A. Vehicle energy (slides 16–18)

**A1 `RoadLoadEnergy`**: extend `VehicleBody` with an auxiliary power draw and per-resistance
energy integrators (∫F·v dt for drag, rolling, grade, inertia, plus ∫P_aux dt). Drive it with a
speed trace (WLTP class 3 or NEDC from a data file through `Interpolation`) through a speed-tracking
driver PI.
*Analysis:* transient over the cycle; a speed sweep giving energy per km vs steady speed; road
μ/C_r sweep using the slide 17 table.
*Teaches:* which resistance dominates in town vs on the motorway; why braking energy is the EV/hybrid
argument (ties into Lecture 3).

### B. Thermodynamic cycle and spark timing (slides 20–23, 47–51)

**B1 `SingleCylinder`**: crank-angle-resolved single zone: slider-crank volume V(θ), polytropic
compression and expansion, Wiebe heat release starting at the spark angle, prescribed constant
speed. Outputs p(θ), p–V loop, indicated work, IMEP, peak pressure and its location.
*Analysis:* spark-angle sweep → **regenerates the slide 50 figure** (pressure trace too advanced /
correct / too retarded) and the MBT curve (torque vs advance); compression-ratio sweep vs ideal Otto
efficiency 1 − r^(1−γ) (slide 20/23); speed sweep shows MBT advance moving with rpm (slide 47's
"with increased engine speed we increase advance"). Peak-pressure rise rate gives a knock proxy.
*Teaches:* why timing has an optimum, why the map is speed- and load-dependent, why 37 % and not the
ideal-cycle number.

### C. Mean-value engine: the plant the ECU controls (slides 24–28, 37, 44)

**C1 `ThrottleBody`**: compressible-orifice mass flow vs throttle angle and pressure ratio (choked
and unchoked branches), throttle effective area from an angle table.

**C2 `IntakeManifold`**: isothermal filling; cylinder air flow by speed-density
ṁ_cyl = η_v(n, p_m)·p_m·V_d·n/(2RT). The manifold time constant is
τ_m = 2V_m/(η_v V_d n) (to be confirmed against the benchmark source), so **it shrinks as speed
rises**: the Lecture 1 lag is not a constant.

**C3 `MeanValueEngine`**: C1 + C2 + fuel path (D1) + torque production
T = η_i(n, λ, spark)·m_f·H_l/(4π) − friction − pumping, + crankshaft `Inertia`. Inputs: throttle
angle, injected fuel mass flow, spark advance. Induction-to-power-stroke delay ≈ one engine cycle
(a Padé whose delay depends on speed, or a fixed delay at the operating point).
*Analysis:* `SteadyStateAnalysis` sweep → torque and BSFC map; `LinearAnalysis` at three operating
points → step-response gain, lag and delay vs speed and load; drop it into `CarPlant` in place of
`IdealEngine` and rerun the Lecture 1 cruise loop.
*Teaches:* the ECU's plant; "Lecture 1's FOPTD was a linearization of this at one point".

### D. Fuel metering (slides 38–46, 28)

**D1 `WallWetting`**: the x–τ fuel-film model: a fraction X of the injected fuel lands on the port
wall and evaporates with time constant τ.
**D2 `FuelPulseWidth`**: the slide 44 formula as a component: base pulse from air mass per stroke
and target λ (2-D map, slide 44's table image53 transcribed), × coolant-temperature, × acceleration
enrichment, + battery-voltage dead-time correction (feeds from E1).
*Analysis:* throttle tip-in and tip-out with no compensation → lean spike and rich spike in λ;
add inverse x–τ compensation → spike removed. Cold vs warm (X and τ rise when cold).
*Teaches:* why "acceleration enrichment" and "deceleration enleanment" exist (slide 28); that the
ECU formula is feed-forward plant inversion.

### E. Actuators (slides 43, 45, 52–53)

**E1 `FuelInjector`**: multi-domain: battery voltage source and driver switch → solenoid R–L (inductance
depends on armature gap) → magnetic force ∝ i²/gap² → needle `Mass` + return `Spring` + `ElastoGap`
stops at 0 and full lift (slide 43: 0.05 mm, check) → fuel flow ∝ lift through an orifice at rail
pressure.
*Analysis:* single pulse → **regenerates the slide 45 figure** (current kink at pickup, needle
lift, t_on/t_off, cumulative fuel); pulse-width sweep → injector flow characteristic with its offset
(dead time) and nonlinear short-pulse region; battery-voltage sweep → why the ECU adds a voltage
correction. Peak-and-hold driver as an extension.

**E2 `IgnitionCoil`**: primary R–L charged from 12 V for the dwell time, interrupted by a switch,
`Transformer` to a secondary with a spark-gap breakdown element.
*Analysis:* dwell sweep → stored energy ½LI² and secondary peak voltage (slide 52 "ignition energy
depends on primary current at cut-off"); battery-voltage and rpm effects → dwell map. Shows why
dwell is controlled in time while spark is controlled in crank angle.

### F. Sensors (slides 30–37, 58)

**F1 `NTCSensor`**: β-model or Steinhart–Hart thermistor in a 5 V divider → ADC voltage (slide 36
characteristic); sensitivity and linearization.
**F2 `HotFilmMAF`**: a heated film (`HeatCapacitor`) cooled by King's-law convection, held at
constant over-temperature by a bridge controller: **a closed loop inside a sensor**. Output = heating
power ↔ mass flow. Shows the millisecond response the slide claims and the temperature-compensation
issue.
**F3 `LambdaSensor`**: switching (HEGO/ZrO₂) characteristic as a `Tanh` around λ = 1 (slide 58:
0.9 V rich, 0.1 V lean), first-order sensor lag, gas transport delay ∝ 1/flow; a wideband variant as a
linear λ output.

### G. Closed loops: the ECU control strategies (slides 25, 28, 47, 50, 56–59)

**G1 `LambdaLoop`** (headline model): C3 at a fixed operating point + D1 + F3 + a two-step
jump/ramp controller (proportional jump on sensor switch, integral ramp between switches, optional
dwell t_v): written as an `ifelse` latch in the `ABSController` style.
*Analysis:* **regenerates slide 57's figure** (manipulated-variable sawtooth vs sensor square
wave); limit-cycle frequency and amplitude vs engine speed (the delay changes); a rich/lean shift via
asymmetric jumps or dwell (slide 57 fig. b); wideband sensor + PI with a Smith predictor vs the
two-step relay; EVAP purge (slide 56) as a fuel-flow disturbance step the loop must reject.
**G2 `CatalystOxygenStorage`**: one-state oxygen storage (integrator saturating at 0 and capacity)
between upstream and downstream sensors; post-cat sensor trim loop (slide 57b, 59).
*Teaches:* why oscillating around λ = 1 is acceptable (the catalyst buffers it); why the second sensor
exists.

**G3 `IdleSpeedControl`**: C3 at idle with accessory load steps (A/C compressor, alternator, power
steering) as torque disturbances; two actuators: air bypass/throttle (strong but slow through the
manifold) and spark advance (weak but immediate, idles retarded to keep a torque reserve).
*Analysis:* PI on air alone vs air + spark; `PIDAutotuningAnalysis` / `ClosedLoopSensitivityAnalysis`;
idle setpoint vs emissions trade-off (slide 28).
*Teaches:* a real two-input loop; reuses Lecture 1's PID and Ziegler-Nichols on a new plant.

**G4 `KnockControl`**: knock detected when the B1 proxy exceeds a threshold → retard by a step,
re-advance by a slow ramp: the same jump/ramp structure as G1 applied to spark.

**G5 `CoolingAndWarmUp`**: engine block + coolant `HeatCapacitor`s, wax thermostat as a
proportional valve, radiator fan with on/off hysteresis. Warm-up strategy: retard spark to heat the
catalyst to light-off before lambda control closes (slide 28 "warm-up").

**G6 `TorqueStructure`** (capstone): pedal → torque demand → inverse map to throttle setpoint +
spark reserve + fuel cut-off on overrun + rev limiter (slides 25, 28). Replaces `IdealEngine` in
`CarPlant`; rerun the Lecture 1 cruise scenario and compare.

## Candidate notebooks

Numbered to follow `notebooks/lecture01` style (one idea per notebook, figures committed).

| # | Notebook | Models | Deck figure regenerated | Tier |
|---|---|---|---|---|
| 01 | Where the energy goes | A1 | slide 16–18 equations, slide 17 table | 2 |
| 02 | The cycle and the spark | B1 | slide 20/22 p–V, **slide 50 pressure traces**, MBT | 2 |
| 03 | The engine as a plant | C1–C3 | where Lecture 1's 0.3 s lag and delay come from; τ_m vs rpm | **1** |
| 04 | How much fuel: pulse width and wall wetting | D1, D2 | slide 44 map; tip-in lean spike | **1** |
| 05 | Inside an injector | E1 | **slide 45 current/lift figure**, flow characteristic | **1** |
| 06 | Lambda control and the catalyst | F3, G1, G2 | **slide 57 jump/ramp limit cycle**, slide 58 curve | **1** |
| 07 | Idle speed control | C3, G3 | — (new loop; reuses Lecture 1 tuning) | 2 |
| 08 | Ignition coil, dwell and knock | E2, G4 | slide 52–53 | 3 |
| 09 | Sensors | F1, F2 | slide 36, 37 characteristics | 3 |
| 10 | Warm-up and cooling | G5 | slide 28 warm-up strategy | 3 |
| 11 | The whole ECU in the car | G6 | slide 24–25 block diagram | 3 |

Tier 1 alone (03–06) is a complete lecture half: plant → feed-forward fuel → actuator → feedback
λ loop, and it lands the control story on the one ECU loop every student has heard of.

## Analyses beyond transient runs

- **Steady-state sweeps** to build the engine's own maps (torque, BSFC, volumetric efficiency) and
  compare with the deck's lookup tables: the "maps are measured on a test bench" point of slide 50.
- **Linearization at operating points** (`LinearAnalysis`) to show gain, time constant and delay
  moving with speed and load: why the ECU uses gain scheduling and maps rather than one PID.
- **Loop-shaping and robustness** (`ClosedLoopSensitivityAnalysis`, delay margin) for the
  wideband λ loop and idle speed.
- **Calibration** (`DyadModelOptimizer`): fit the VE map or x–τ parameters to "measured" data,
  standing in for the calibration engineer's job and slide 44's "parameters that change over time".
- **Limit-cycle measurement**: period and amplitude of G1 vs delay, compared with the describing-
  function prediction for a relay with delay.

## Where the parameters come from

Full survey with citations and verification status:
`research_notes/Engine control systems/teaching_materials.md`. Per model:

| Model | Primary source | Access | Caveat |
|---|---|---|---|
| A1 road load, drive cycles | DieselNet WLTC class 1–3 text files; EPA UDDS/HWFET/US06 | free | GTR 15 annex itself unverified (PDF blocked) |
| B1 single cylinder | Wiebe function (§3.6); MIT OCW 2.61 for the cycle analysis | free (CC BY-NC-SA) | — |
| C1–C3 mean-value engine | Crossley & Cook 1991 as coded in MathWorks `sldemo_engine` (throttle, manifold, pumping and torque polynomials); throttle and manifold equations already in `research_notes/Passenger car brake system modeling/engine_manifold_vacuum.md` | free booklet | exponents restored from text extraction: check against the PDF; J and V_m not given |
| C3 cross-check | Linköping TCSI testbed (open MVEM, GPL-3); Modelica MVEMLib (GPL-2.0) | free | turbo engine; adds wastegate we can drop |
| C3 efficiency, BSFC | EPA ALPHA measured engine maps (Mazda Skyactiv, Toyota A25A, Honda L15B7) | free | — |
| D1 wall wetting, G-loops | Guzzella & Onder, 2nd ed. 2010, §2.4.2–2.4.3, §4.2–4.3, App. B (idle case study with numbers) | paywalled | ETH course textbook; library copy needed |
| F3 lambda sensor | Bosch LSU 4.9 table (wideband, λ 0.65–10.1), transcribed in the note | free datasheet | no open OEM curve for the two-step sensor: shape it from the slide 58 figure |
| F1 NTC | Bosch NTC M12 table (2.5 kΩ at 20 °C), transcribed | free datasheet | — |
| G1 lambda loop | MathWorks `sldemo_fuelsys` (tanh sensor, PI correction, 14.6 target, fault modes) | free | — |
| G2 catalyst | Brandt, Wang & Grizzle limited-integrator model; Muske & Peyton Jones 2004 | free PDFs | copy equations from the PDF (extraction garbled) |
| G3 idle speed | Di Cairano et al. CDC 2008 (air and spark, ~0.12 s / ~0.03 s delays at 650 rpm) | free | numeric gains not yet located |
| E1 injector, E2 coil, F2 MAF | no open OEM data found | — | parameters must be assumed and marked so, as in the brake report |

## Open decisions

- Notebook format: Lecture 1 shipped Jupyter (`.ipynb`); Lecture 3 uses Pluto (`.pluto.jl`).
- Lecture time budget: how much of slides 30–37 (sensors) and 52–55 (ignition hardware) gets a
  model vs stays descriptive.
- Parameter source for the mean-value engine: see the external materials survey in
  `research_notes/Engine control systems/teaching_materials.md`.
- Whether C3 replaces `IdealEngine` inside `CarPlant` or ships beside it (Lecture 1 regression tests
  pin the FOPTD numbers, so beside it, with an adapter, is the safer default).
