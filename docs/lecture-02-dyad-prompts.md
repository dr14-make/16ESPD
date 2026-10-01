# Dyad agent prompts — Lecture 2

Twelve tasks, in build order. Each prompt is self-contained: hand it to a fresh agent as is. Check
the reported numbers before starting the next task. The design is validated by tasks 2 and 5
(the gates). Tasks 4 and 6 depend on nothing and can run in parallel with the mean-value chain.

Every prompt assumes the same preamble. Paste it above the task text.

> **Preamble.** Repository: `/home/dr14/CVUT/VehicleSystemsComponents`. Work in your own worktree:
> `wt switch --create feat/lecture02-<short-task-name>` (worktrunk; it prints the path, so work
> there by path). Read, in order: `docs/lecture-02-plan.md` (settled decisions S1–S10, reality
> anchors, "Agent quick start"), the sections of `docs/lecture-02-dyad-tasks.md` named in your
> task plus its "Read before the first compile" and "Ground rules", and
> `docs/HANDOVER.md` § "Gotchas found during the build". Dyad language:
> `agent_resources/skills/dyad-language/SKILL.md`. Stdlib source:
> `agent_resources/stdlib_reference/<Library>/<Path>.dyad`. Compile with
> `~/.dyad-maxwell/dyad-lang/apps/cli/dyad compile .` and confirm your change appears in
> `generated/` before trusting a test. Run tests with
> `cd test && julia +dyad-3.4.0 --project=.. runtests.jl`. Do not edit existing components or
> `generated/`. Stage files by name, Conventional Commits, US English. Report every acceptance
> number you measured, and say plainly if one misses its band. Do not move a band.

---

## Task 1 — Air path (also completes brake plan increment 2a)

Sections: "Engine constants", "Vehicle/Engine — air path (task 1)", acceptance "Task 1".
Also read `research_notes/Passenger car brake system modeling/engine_manifold_vacuum.md` and
`docs/brake-system-implementation-plan.md` § 2a.

Create `dyad/Vehicle/Engine/` with `Throttle`, `IntakeManifold`, `CylinderAirflow` (with the
`use_table` switch and an assumed `eta_v` table) and the `AirPath` assembly with brake plan 2a's
interface (inputs `u_thr`, `omega`, `mdot_aux`; outputs `p_m`, `mdot_thr`, `mdot_cyl`). Write
`test component TestAirPath` cases: idle (800 rpm, closed, 3 s), tip-in to WOT at 3000 rpm,
overrun at 3000 rpm, and a small throttle step at idle and at 3000 rpm for the time constant.
Calibrate `A_idle` so idle `p_m` is 33 kPa, with the constant `eta_v0` that brake 2a uses
and again with the table; report both values.

Done when acceptance "Task 1" passes. Report: idle, WOT and overrun `p_m`; the two time constants
against the predicted 0.125 s and 0.033 s; the calibrated `A_idle`; the minimum `mdot_thr`.
Then add one line under brake plan § 2a pointing at `Vehicle.Engine.AirPath`.

---

## Task 2 — Mean-value engine and its maps (gate)

Sections: "Vehicle/Engine — torque and the mean-value engine (task 2)", "Decisions delegated"
D1 and D3, acceptance "Task 2". Depends on task 1. Also read the MathWorks SI Core Engine page
linked there and `agent_resources/docs/analyses.md` and `analysis_points.md`.

Build `SpeedScheduledDelay` (choose `n` per D1 and test it against `PadeDelay` at constant
speed), `TorqueProduction` (assumed `M_lambda` and `sigma_mbt` tables), and `MeanValueEngine`.
`WallWetting` comes from task 3. Until then, use a pass-through behind `with_film = false` and
leave the port in place. Build the `Lecture2` harnesses `EngineDyno` and `ThrottleStep`, plus
the map sweep (an analysis or a documented Julia function; say which).

Verify the gate first: the throttle-to-torque time constant falls with speed at idle, 2000 and
4000 rpm, and the induction delay equals 180° crank within 5 %. If it fails, stop and report;
nothing downstream makes sense without it. Then calibrate per D3 and check the map anchors.

Report: time constant and delay at the three speeds; `k_f`, `eta_i`, `eta_v` peak; peak torque
and its speed; peak brake efficiency; min BSFC; torque loss at 10° retard; idle fuel in L/h; the
D1 phase errors at 1 Hz and 4 Hz.

---

## Task 3 — Fuel path: wall wetting and fuel metering

Sections: "Vehicle/Engine + Vehicle/ECU — fuel path (task 3)", acceptance "Task 3". Depends on
task 2. Open the deck (`materials/ControlTheory/2. Engine CS.pptx`; unzip, then
`ppt/media/image53.png`) and transcribe the slide 44 AFR map into
`data/engine/afr_map_slide44.csv` with a source header.

Build `Vehicle/Engine/WallWetting` and switch `MeanValueEngine` to `with_film = true` by default.
Build `Vehicle/ECU/FuelMetering` (base fuel from the map, `F_cool`, `lambda_trim`, inverse x–τ
compensation behind `with_comp`, `t_inj` with the EV14 dead-time table, overrun fuel cut behind
`with_cutoff`). Build the `Lecture2/TipInTest` harness.

Report: λ excursion on tip-in warm and cold, with and without compensation; the excursion with
deliberately wrong estimates (`Xh` 30 % low), which notebook 04 shows; `t_inj` at idle and at
3000 rpm WOT; the map round-trip error.

---

## Task 4 — Fuel injector (independent)

Sections: "Vehicle/Engine — fuel injector (task 4)", "Decisions delegated" D4, acceptance
"Task 4". Read the stdlib sources listed there before writing anything; `TranslationalEMF` is
deliberately not used.

Build `Vehicle/Engine/Solenoid` (flux-linkage state, gap-dependent inductance,
energy-consistent force), `Vehicle/Engine/FuelInjector`, and the `Lecture2/InjectorPulse`
harness. Tune the assumed magnetic and spring parameters to the dead-time band. Do not tune
`R = 12 Ω` or the 146 cm³/min static flow; both are Bosch datasheet values.

Report: dead time at 8, 12, 14 and 16 V against the EV14 table (0.800 ms at 14 V, 2.00 ms at
8 V); dropout time; flyback clamp voltage; static flow; fuel per pulse at pulse widths 0.5–10 ms
(the characteristic notebook 05 plots). State which parameters are assumed.

---

## Task 5 — Exhaust, λ sensors, catalyst and λ control (gate)

Sections: "Vehicle/Engine + Vehicle/ECU — exhaust, λ sensors, catalyst, λ control (task 5)",
"Decisions delegated" D2, acceptance "Task 5". Depends on tasks 2 and 3. Open the Brandt, Wang &
Grizzle PDF (https://grizzle.robotics.umich.edu/files/twc_conf.pdf) and copy the catalyst
equations exactly; do not reconstruct them from the summary.

Build `ExhaustTransport`, `LambdaSensorSwitching`, `LambdaSensorWideband`, `Catalyst`,
`Vehicle/ECU/TwoStepLambdaController`, `WidebandLambdaPI`, `PostCatTrim`, and the
`Lecture2/LambdaLoop` harness with its structural switches and the purge disturbance.

Verify the gate first: the two-step loop limit-cycles at idle and at 3000 rpm with the
amplitude and frequency in band, and faster at 3000 rpm. If it does not, stop and report.

Report: λ amplitude and frequency at idle, 2000 and 3000 rpm; the measured period against
4 × (total loop delay); the `eps_V` halving check; `theta` range under the limit cycle; time to
saturation and the downstream switch under a 5 % lean bias; post-cat trim recovery time; purge
rejection time; wideband steady-state error.

---

## Task 6 — Single cylinder, crank angle (independent)

Sections: "Vehicle/Engine — single cylinder, crank angle (task 6)", acceptance "Task 6".

Build `Vehicle/Engine/SingleCylinder` and the `Lecture2/SparkSweep` analysis. This model is
time-scale separate (plan S1): it never connects to the mean-value engine. Its MBT results feed
a comparison table, not a port.

Report: motored peak pressure against `p_ivc * r_c^gamma`; motored net work; at 1500, 3000 and
4000 rpm the MBT advance, the location of peak pressure at MBT, IMEP and indicated efficiency
against ideal Otto; peak pressure and location at MBT ± 15°; max dp/dθ against advance.

---

## Task 7 — Idle speed control

Sections: "Vehicle/ECU — idle speed control (task 7)", acceptance "Task 7". Depends on tasks 2
and 3. Also read the Di Cairano et al. paper linked there for the constraint and the spark
reserve.

Build `Vehicle/ECU/IdleSpeedController` and the `Lecture2/IdleLoop` harness. Tune gains by any
method you like (Lecture 1's tuning tables in `test/tuning_tables.jl` are available), then try
`PIDAutotuningAnalysis` from DyadControlSystems on the air path and report whether it ran.

Report: speed dip and recovery time for air-only and air-plus-spark; minimum speed; the gains;
whether `PIDAutotuningAnalysis` worked and what it returned.

---

## Task 8 — Road load and drive cycle

Sections: "Lecture 2 road load (task 8)", acceptance "Task 8". Independent of the engine.

Download a WLTC class 3b trace (DieselNet) and an EPA UDDS or HWFET trace into
`data/drive_cycles/` with source headers. Build `Vehicle/RoadLoadMeter` and
`Lecture2/DriveCycle` around the unchanged `CarPlant`.

Report: per-term energy over the cycle in MJ and per km; the 1 % energy closure; tracking RMS;
the drag-to-rolling ratios at 50 and 130 km/h; the cycle's distance against its published value.

---

## Task 9 — Ignition coil and knock control

Sections: "Ignition coil and knock (task 9)", "Decisions delegated" D4, acceptance "Task 9".
Depends on task 2 (knock uses the engine's speed and load).

Build `Vehicle/Engine/IgnitionCoil` with its harness (dwell sweep at 10, 12 and 14 V) and
`Vehicle/ECU/KnockControl` with a harness on `EngineDyno` at a knock-prone point (low speed, WOT).

Report: primary current and stored energy against dwell and battery voltage; secondary peak
voltage open circuit and with the gap; the knock sawtooth period and its mean against the limit.
Mark every coil parameter `(assumed)`; the survey found no open OEM data.

---

## Task 10 — Sensors

Sections: "Sensors (task 10)", acceptance "Task 10". Independent.

Build `Vehicle/Engine/NTCSensor` (Bosch NTC M12 table copied from
`research_notes/Engine control systems/teaching_materials.md` §4) and `Vehicle/Engine/HotFilmMAF`
with its constant-power variant, each with a test harness.

Report: NTC voltage curve at the table points; where its sensitivity peaks; MAF step response
time closed loop and open loop; MAF error after an intake-air temperature step.

---

## Task 11 — Cooling and warm-up

Sections: "Cooling and warm-up (task 11)", acceptance "Task 11". Independent of the mean-value
engine; drive the heat input from a prescribed fuel power.

Build `Vehicle/Engine/CoolingCircuit`, `Vehicle/Engine/CatalystThermal` and a
`Lecture2/WarmUp` harness with a spark-retard switch.

Report: warm-up time; thermostat regulation band; fan cycling period at a hot condition;
catalyst light-off time with and without retard.

---

## Task 12 — Capstone: torque structure and the engine in the car

Sections: "Capstone (task 12)", acceptance "Task 12". Depends on tasks 2, 3 and 5 (λ loop
optional, off by default).

Build `Vehicle/ECU/TorqueStructure` (the inverse throttle map comes from the task 2 map sweep),
`Vehicle/EngineCarPlant` mirroring `CarPlant`'s ports, and `Lecture2/EngineCruise`.

Report: WOT terminal speed and what limits it; the rev-limiter cycle frequency; the 90 → 110
km/h cruise step with Lecture 1 gains against the Lecture 1 result (overshoot, settling
time); anything about the Lecture 1 gains that no longer works, stated plainly.
