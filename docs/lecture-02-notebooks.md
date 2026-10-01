# Notebook specifications — Lecture 2

Cell-level detail for the Lecture 2 notebooks. Written so that someone who has not seen the
planning conversation can build any one of them. Read `docs/lecture-02-plan.md` first (thesis,
settled decisions, reality anchors, "Agent quick start", deck-figure map). The models these
notebooks run are specified in `docs/lecture-02-dyad-tasks.md`. Agent prompts are in
`docs/lecture-02-notebook-prompts.md`.

Numbers quoted below are indicative. Confirm each against the simulation and correct this file
where they differ: the simulation wins, and the correction is part of the task.

## Shared conventions

- **Pluto** (`notebooks/lecture02/NN-name.pluto.jl`), plan S9. Copy the setup-cell shape from
  `notebooks/lecture03/01-abs.pluto.jl`: activate the repository project, include
  `notebooks/lecture01/support.jl` and `notebooks/lecture02/support.jl`, call `setup()`.
- **Headless execution is the done-check**:
  `julia +dyad-3.4.0 --project=. notebooks/lecture02/NN-name.pluto.jl` must run to completion. The
  Pluto file header's `@bind` mock supplies each slider's default. Pluto cell order is reactive, but
  the file must also run top to bottom as a script, so define before use in file order.
- **Thin cells.** A code cell is a call and a plot. Model construction, sweeps and repeated plot
  recipes live in `notebooks/lecture02/support.jl`. Notebooks call the `Lecture2` analyses
  (`<Harness>Transient`) and nothing deeper; a missing knob is a request to the Dyad side, not a
  nested `a__b__c` override in the notebook.
- **Every notebook shows the Dyad model it runs** with `show_dyad("Name")` near where it is
  introduced (Lecture 1 convention; the helper is in `notebooks/lecture01/support.jl`).
- **Every notebook regenerates at least one deck figure and shows the original beside it.** Copy
  the image from the unzipped deck (`ppt/media/…`, mapped in the plan) into
  `notebooks/lecture02/assets/` and display it with `LocalResource` from PlutoUI.
- **Sliders** (`@bind`, PlutoUI) for the one or two knobs the notebook is about, with defaults
  equal to the values the check cells assert. A slider moved on the projector must not break a
  check cell: check cells use the default run, not the slider-bound run.
- **Check cells** assert the notebook's key numbers (`@assert` with a message stating the band)
  so the headless run fails loudly when a model change breaks the story.
- **Units on axes**: engine speed in rpm (from `Vehicle.ToRPM`), pressure in kPa, λ
  dimensionless, spark in degrees BTDC, time in s or ms as stated.
- **Honest numbers.** Where a parameter is `(assumed)`, the notebook says so in the cell that uses
  it. Quote numbers from the run, never from this spec.
- Every notebook ends with a short "What this bought us" markdown cell that names the next
  notebook.

## 00 — Shared support module (`notebooks/lecture02/support.jl`)

Module `Lecture02Support`, included after `Lecture01Support`. It holds:

- signal-name constants for engine quantities (`OMEGA`, `P_M`, `LAMBDA_CYL`, `TAU_E`, …) matching
  the harness paths the Dyad agents chose (read them from the analyses, do not guess);
- `rpm(omega)`, `kpa(p)`, conversions for plotting only;
- `engine_map(; speeds, throttles)`: runs the task 2 map sweep and returns a table (torque, BSFC,
  `p_m`, efficiency) as a `NamedTuple` of matrices;
- `plot_map(map, field; kwargs...)`: a contour or heatmap with speed on x and load on y, the
  slide 44 layout;
- `limit_cycle(t, y)`: period and peak-to-peak amplitude of a settled oscillation;
- `deck_figure(name)`: returns the PlutoUI resource for an asset in `notebooks/lecture02/assets/`;
- `compare(original, simulated)`: two-panel layout, deck image left and plot right.

Reuse Lecture 1 helpers (`signal`, `sweep`, `rerun`, `show_dyad`) rather than reimplementing them.

---

## 01 — Where the energy goes  *(Tier 2)*

**Thesis.** Before asking how an engine makes energy, ask where the car spends it.

**Source.** Slides 16–18 (resistance terms O_V, O_f, O_z, O_s, O_aux; rolling-resistance table).

**Models.** `Lecture2.DriveCycleTransient` (WLTC 3b and an EPA cycle), `Vehicle.RoadLoadMeter`.

**Cells.**
1. *Markdown*: the force balance from slide 16, each term named against its slide symbol.
2. *Code*: steady-speed sweep 20–160 km/h, power per term, stacked. The crossover where drag
   overtakes rolling resistance is marked.
3. *Code*: drive the WLTC trace. Plot speed tracking, then cumulative energy per term.
4. *Code*: energy per km per term for WLTC vs the EPA highway cycle; a bar chart.
5. *Markdown*: the share that is braking (inertia energy thrown away) is the hybrid argument, and
   it links to Lecture 3.
6. *Slider*: `C_r` from the slide 17 table (dry asphalt to gravel), rerun the cycle.

**Check.** Energy closure within 1 %; drag/rolling ratio > 3 at 130 km/h.

---

## 02 — The cycle and the spark  *(Tier 2)*

**Thesis.** Spark timing has an optimum, and it moves with speed, which is why the ECU stores a map.

**Source.** Slides 20–23 (Otto cycle, efficiency), 47 (ignition timing), 50 (pressure vs
ignition angle, `image62.png`), 51.

**Models.** `Lecture2.SparkSweep` on `Vehicle.Engine.SingleCylinder`.

**Cells.**
1. *Markdown*: ideal Otto efficiency `1 - r_c^(1-gamma)`; plot it against `r_c`, mark 10.5 and 13.
2. *Code*: motored cycle, a p–V loop with zero net area, and the compression check.
3. *Code*: fired cycle at MBT: the p–V loop beside slide 20's.
4. *Code*: **the slide 50 figure**: pressure vs crank angle at MBT, MBT + 15° and MBT − 15°, beside
   `image62.png`.
5. *Code*: IMEP vs spark advance at 1500, 3000 and 4000 rpm. MBT is the peak of each curve, and it
   moves right with speed.
6. *Markdown*: why it moves. The ignition delay is fixed in milliseconds, so at higher speed it
   covers more crank angle. Slide 47's "with increased engine speed we increase advance".
7. *Code*: max dp/dθ vs advance, the knock proxy. Over-advance is where knock lives (notebook 08).
8. *Code*: indicated efficiency at MBT vs ideal Otto; name the losses (finite burn, heat loss).
   This is why 37 % and not 50 %.
9. *Slider*: spark advance and engine speed, live pressure trace.

**Check.** Peak pressure location at MBT inside 12–20° ATDC; MBT(4000) > MBT(1500).

---

## 03 — The engine as a plant  *(Tier 1)*

**Thesis.** Lecture 1's engine was a lag and a delay. Here is where they come from, and why they
are not constant.

**Source.** Slides 24–26 (ECU, sensors, actuators), 37 (air mass measurement); Lecture 1's
`IdealEngine` docstring and `docs/HANDOVER.md` Risk 1 (why Lecture 1 used 0.3 s).

**Models.** `Lecture2.EngineDynoTransient`, `Lecture2.ThrottleStepTransient`, the map sweep,
`Vehicle.Engine.MeanValueEngine`.

**Cells.**
1. *Markdown*: the ECU block diagram (slide 24), reduced to the plant: throttle, fuel, spark in;
   speed, manifold pressure and air flow out.
2. *Code*: `show_dyad("AirPath")`, then the throttle equation and the manifold equation typeset.
3. *Code*: manifold pressure at idle, WOT and overrun; compare with the anchors (33 kPa idle).
4. *Code*: **the time constant changes with speed**: throttle steps at 800, 2000 and 4000 rpm,
   normalized, on one axes; then `τ_m = 120·V_m/(η_v·V_d·N)` against the measured values.
5. *Code*: the induction delay, 180° crank, in milliseconds vs speed.
6. *Markdown*: compare with Lecture 1's 0.3 s lag and 0.3 s delay. Say plainly that the physical
   values are smaller, and why Lecture 1 chose larger ones (HANDOVER Risk 1: Ziegler-Nichols needs
   an observable ultimate period). One controller tuned at one point sees a different plant at
   another, which is why ECUs schedule gains and use maps.
7. *Code*: `show_dyad("TorqueProduction")`; the efficiency chain typeset (plan S3).
8. *Code*: the engine's own maps: WOT torque curve, BSFC contour, efficiency contour, in the slide
   44 layout.
9. *Markdown*: peak efficiency against slide 23's 37 %; where friction and pumping take the rest.
10. *Slider*: engine speed for cell 4's step, live.

**Check.** Idle `p_m` 30–36 kPa; time constant at 4000 rpm smaller than at 800 rpm; peak torque
130–150 N·m.

---

## 04 — How much fuel  *(Tier 1)*

**Thesis.** The ECU's pulse-width formula is feed-forward: it inverts the plant so that λ stays at 1
before any sensor sees an error.

**Source.** Slides 38 (injection system), 44 (pulse width = base × factors, `image53.png`), 28
(acceleration enrichment, deceleration enleanment, cut-off).

**Models.** `Lecture2.TipInTestTransient`, `Vehicle.ECU.FuelMetering`, `Vehicle.Engine.WallWetting`.

**Cells.**
1. *Markdown*: the slide 44 formula, then the same formula as `FuelMetering` computes it.
   `show_dyad("FuelMetering")`.
2. *Code*: the transcribed AFR map as a heatmap beside `image53.png`. Where is it rich, and why
   (power and component protection at high load)?
3. *Code*: `t_inj` across the map, with the dead-time offset and its battery-voltage dependence.
4. *Markdown*: the fuel film (x–τ): fuel that lands on the port wall arrives late.
5. *Code*: tip-in without compensation: λ goes lean, then tip-out goes rich.
6. *Code*: with inverse x–τ compensation, the spike is gone. With estimates 30 % wrong, it is half
   gone. That is the calibration engineer's problem.
7. *Code*: cold vs warm engine; why warm-up enrichment exists (slide 28).
8. *Markdown*: "acceleration enrichment" and "deceleration enleanment" are this compensation by
   another name.
9. *Slider*: estimate error in `Xh` (−50 % to +50 %).

**Check.** Uncompensated lean excursion ≥ 5 %; compensated < 1 %.

---

## 05 — Inside an injector  *(Tier 1)*

**Thesis.** A pulse width is a command, not a quantity of fuel. The injector's electromagnetics and
mechanics decide what actually flows.

**Source.** Slides 43 (construction, 0.05 mm lift), 45 (activation, current, lift, fuel,
`image54.png`).

**Models.** `Lecture2.InjectorPulseTransient`, `Vehicle.Engine.Solenoid`, `Vehicle.Engine.FuelInjector`.

**Cells.**
1. *Markdown*: the four domains in one component: electrical, magnetic, mechanical, fluid.
   `show_dyad("FuelInjector")`.
2. *Code*: **the slide 45 figure**: activation, current, needle lift and cumulative fuel stacked on
   one time axis, beside `image54.png`. Mark `t_on` and `t_off`.
3. *Markdown*: the kink in the current is the armature moving: back-EMF from the changing
   inductance.
4. *Code*: fuel per pulse vs pulse width: linear above ~2 ms, offset by the dead time, nonlinear
   below.
5. *Code*: dead time vs battery voltage, against the EV14 table (stated as retailer data).
6. *Markdown*: this is why notebook 04's formula has a battery-voltage correction.
7. *Code*: flyback voltage at switch-off; why drivers clamp it.
8. *Slider*: battery voltage, live current and lift traces.

**Check.** Dead time at 14 V inside 0.6–1.0 ms; static flow within 5 % of 146 cm³/min.

---

## 06 — Lambda control and the catalyst  *(Tier 1)*

**Thesis.** The λ loop does not settle. It oscillates on purpose, and the catalyst is what makes that
acceptable.

**Source.** Slides 56 (EVAP purge), 57 (λ control, `image75.png`, `image76.png`), 58 (sensor
characteristic), 59 (catalyst).

**Models.** `Lecture2.LambdaLoopTransient` and its switches; `Vehicle.Engine.LambdaSensorSwitching`,
`LambdaSensorWideband`, `Catalyst`; `Vehicle.ECU.TwoStepLambdaController`, `WidebandLambdaPI`,
`PostCatTrim`.

**Cells.**
1. *Code*: the switching sensor characteristic beside slide 58's figure; why it can only say
   "rich" or "lean".
2. *Markdown*: a relay can only make a loop oscillate. The jump/ramp controller makes the
   oscillation small and centered.
3. *Code*: **the slide 57 figure**: manipulated variable (sawtooth) and sensor voltage (square wave)
   stacked, beside `image75.png`.
4. *Code*: λ in the cylinder over the same window: amplitude against slide 57's 2–3 %.
5. *Code*: period vs engine speed. Overlay `4 × loop delay`; the loop delay is the plant.
6. *Code*: rich shift via asymmetric jumps (slide 57 fig. b).
7. *Code*: catalyst storage `theta` under the limit cycle: it absorbs the oscillation, and the
   downstream λ is flat.
8. *Code*: a 5 % lean bias saturates the catalyst and the downstream sensor switches; post-cat trim
   brings it back. This is why the second sensor exists (`image76.png`).
9. *Code*: purge step rejected.
10. *Code*: wideband sensor + PI: λ settles; compare the two loops on one axes.
11. *Slider*: engine speed, and `k_jump`.

**Check.** Amplitude ±2–3 % at idle; frequency higher at 3000 rpm than at idle; downstream sensor
does not switch under the limit cycle.

---

## 07 — Idle speed control  *(Tier 2)*

**Thesis.** Two actuators, one slow and strong, one fast and weak: the ECU uses both.

**Source.** Slides 25 and 28 (idle-speed function and strategy); Di Cairano et al. 2008.

**Models.** `Lecture2.IdleLoopTransient`, `Vehicle.ECU.IdleSpeedController`.

**Cells.**
1. *Markdown*: what the idle controller fights (A/C, alternator, steering pump) and what stalling
   costs.
2. *Code*: air only: the A/C step dips speed and recovers slowly, delayed by the manifold.
3. *Code*: air plus spark from a retarded reserve: the dip halves.
4. *Markdown*: the price: idling retarded costs fuel. Torque reserve vs consumption.
5. *Code*: tune the air PI with Lecture 1's methods (link `08-tuning`) or `PIDAutotuningAnalysis`,
   whichever task 7 reports working.
6. *Slider*: spark reserve.

**Check.** Minimum speed ≥ 450 rpm; air + spark dip ≤ ½ of air-only.

---

## 08 — Ignition coil, dwell and knock  *(Tier 3)*

**Source.** Slides 47–55.

**Models.** `Vehicle.Engine.IgnitionCoil` harness; `Vehicle.ECU.KnockControl` harness.

**Cells.** Primary current rise during dwell and the energy stored; secondary voltage at
interruption (open circuit and with the gap); dwell needed vs battery voltage (dwell is time,
spark is angle). Knock: link notebook 02's dp/dθ, then the retard-fast/advance-slow sawtooth,
the same shape as the λ controller in 06.

**Check.** Secondary open-circuit peak 20–40 kV; knock mean within 2° of the limit.

---

## 09 — Sensors  *(Tier 3)*

**Source.** Slides 30–37.

**Models.** `Vehicle.Engine.NTCSensor`, `Vehicle.Engine.HotFilmMAF` harnesses.

**Cells.** NTC: Bosch table, divider voltage, sensitivity peak where `R = R_pu`, the ECU's
inverse lookup. MAF: the closed loop inside the sensor; step response closed vs open loop;
temperature compensation error.

**Check.** NTC matches the Bosch table at three points; MAF closed loop ≥ 5× faster.

---

## 10 — Warm-up and cooling  *(Tier 3)*

**Source.** Slides 27–28.

**Models.** `Lecture2.WarmUpTransient`.

**Cells.** Coolant and block warm-up; thermostat as a proportional controller and the fan as an
on/off one with hysteresis; catalyst light-off with and without spark retard (the warm-up
strategy on slide 28), and when λ control may close (sensor > 300 °C, slide 58).

**Check.** Warm-up 4–10 min; thermostat band 85–95 °C.

---

## 11 — The whole ECU in the car  *(Tier 3)*

**Source.** Slides 24–25, 28; Lecture 1 notebook 01 cell 4 ("246 km/h is too high").

**Models.** `Lecture2.EngineCruiseTransient`, `Vehicle.EngineCarPlant`.

**Cells.** Wide-open throttle from rest: the terminal speed is now limited by the engine
(≈ 190 km/h, rev limiter visible), which closes Lecture 1's open question. The Lecture 1 cruise
step with Lecture 1 gains on the real engine: what still works and what does not. Overrun fuel cut
when the driver lifts off. The whole ECU drawn as the stack of loops built in 03–10.

**Check.** WOT terminal speed below 200 km/h.
