---
title: Lecture 2 hands-on — tutor guide
---

[← Vehicle Systems & Components](../../index.html) · [Student guide](./) · [Projector deck →](../../handson-02/index.html){target="_self"}

# Lecture 2 hands-on: tutor guide

What to say, how long each part takes, where students stall, and the answer models

Students follow the [student guide](./): it holds every instruction, the theory in its **Why** boxes, and the checkpoints. The [projector deck](../../handson-02/index.html){target="_self"} shows one slide per step: the goal, the finished model, the checkpoint numbers and the time budget. This page is for you. Read it once before the session and keep it open beside the deck; each slide's speaker note links to its section here.

## Before the session {#before}

- **Screens.** Deck on the projector, Dyad Studio on your laptop with your own `MyCar` from hands-on 1 open on `main`. Open **presenter mode** from the deck's nav bar.
- **On the board:** the link to the student guide, `handson/lecture-02/` on the course site.
- **Where this sits.** After the engine lecture. Its last section, "The mapped engine", promised what we do today: a pedal, a throttle, a manifold pressure, and measured maps that return torque, fuel and CO₂. Today students build it into the car they built in hands-on 1.
- **Deep links** into the deck are by name: `#/cruise` is step 05, `#/map-engine` step 03.

### Time

About 90 minutes. Step 07 only if time is left.

| Step | Min | Split |
| --- | --: | --- |
| 00 Set up | 8 | the add downloads and precompiles; talk through step 01's maps while it runs |
| 01 Read the maps | 12 | 4 of theory, 8 in the REPL |
| 02 Manifold | 15 | 4 of theory, 3 to paste, 5 to draw the bench, 3 to run twice |
| 03 Map engine | 20 | 3 of theory, 8 to draw the engine, 3 to paste the bench, 3 for runs 1 and 2, 3 for the fuel-cut paste and its run |
| 04 Mapped car | 12 | 2 of theory, 6 to duplicate and rewire, 4 for the full-pedal run |
| 05 Cruise | 12 | 2 of theory, 3 for the bench, 5 for three runs, 2 to fill the table |
| 06 Coast and brake | 8 | 4 for the coast-down, 4 for the brake |
| Hand in | 3 | |

**Where the time really goes.** In rehearsal, step 03 E, the fuel-cut paste and its run, took about **12 minutes** against its 3-minute budget. Plan for it: if the room is behind at the end of 03 D, demonstrate E on the projector and let students paste it while you talk.

**If time runs short:** cut step 06's brake stop first, then step 02's 3000 rpm run. Do not cut step 05: the cruise numbers are the session's result.

### Answer models

Every finished model a student builds in steps 02 and 03 is in the course library, `dyad/HandsOn02/`, under the guide's names. Students see them under **+** in the `HandsOn02` folder; the guide tells them to build their own and open these only to compare.

| Step | Component | Analysis |
| --- | --- | --- |
| 02 | `HandsOn02.Manifold`, `HandsOn02.AirPathStep` | `HandsOn02.AirPathStepTransient` |
| 03 A–D | `HandsOn02.MapEngine`, `HandsOn02.MapEngineDyno` | `HandsOn02.MapEngineDynoTransient` |
| 03 E | `HandsOn02.MapEngineFuelCut`, `HandsOn02.MapEngineFuelCutDyno` | `HandsOn02.MapEngineFuelCutDynoTransient` |
| 04–06 | not written yet: `MappedCar`, `MappedCarWOT`, `MappedCarCruise`, `MappedCarCoast` | — |

The guide's *Stuck? The full model* boxes hold the code of steps 02 and 03. The checkpoints of steps 01–03 are tested in `test/engine_plausibility.jl`: the testsets "Hands-on 02 map engine", "Hands-on 02 manifold", "Hands-on 02 cruise table" and "Hands-on 02 fuel cut".

### Opening

**Say:** Hands-on 1 ended with a promise. Our car reached 246 km/h, and we said the number was wrong: a real engine gives its torque only in the middle of its speed range. The engine lecture showed what a real engine control unit does instead: it measures the engine speed and the pressure in the intake manifold, and looks both up in tables. Today we use real tables, measured by the US EPA on a Mazda engine.

**Ask the room:** what does a car's sticker say about fuel? *(Liters per 100 km and grams of CO₂ per km. By the end of today they have both for their own car at three speeds.)*

**Point at** the overview diagram on the title slide, and follow the air: the pedal opens the throttle, air fills the manifold, the cylinders draw it out. The manifold pressure is what is left: a state, which takes time to change. The maps are read at speed and that pressure. Students build the manifold (step 02) and a small map engine (step 03); the throttle and the cylinders come finished from the course library, physics the lecture stated, not what today teaches. The booster input is held at zero today; the brake lecture connects it.

**Say:** the same rhythm as hands-on 1: predict a number, build, check the model gives it. Step 01 predicts the day's most important number, the fuel at 90 km/h, from the tables alone; step 05 measures it. Step 04 is the milestone: the same car with a real engine, and it no longer reaches 246. Keep the names the guide gives, `engine`, `car`, `p_m`, `fuel_lph`: the plot commands use them.

## 00 Set up {#setup}

**Say:** today's engine uses parts you will not build: the throttle, the cylinders' air flow, the map tables and the fuel-cut logic. They live in the course library, `VehicleSystemsComponents`. One line in the REPL adds it, like the standard libraries in hands-on 1, and its parts appear under **+**.

**Rehearsed:** `Pkg.add(url = …)` plus **Dyad: Compile** is enough: the library shows under **+** in a diagram.

**Where students stall:**

- **Branching from `main`,** which holds only the empty library: step 04 then has no `Car` to duplicate. Check a few status bars.
- **Pkg's yellow warning** after the add, "different versions are currently loaded … Restart julia". Harmless; carry on.
- **Looking for the library in the left Components tree.** It shows only under **+**; that is expected.
- **The `HandsOn02` folder and the `Test…` components** under **+** are the reference answers. Build your own.
- **A network error during the add:** pair the student with a neighbor.

**Open:** pin the add to a tag once the course library's branch merges, so students get the engine the checkpoints were read from.

## 01 Read the maps {#maps}

**Say:** before any model, the data. Three tables on the same grid, measured on a test bench by the US EPA and scaled to our 1.5 L engine. We find the 90 km/h point in them by hand; step 05 measures the same point in the car, and if the two agree the car is right. Then the guide's *Why speed and manifold pressure* box: speed and pressure fix the engine's state; the "moment later" is step 02.

**Do it on the board**, one column at a time, from the guide's *Details* box under step 01: where on the map, how much fuel, per 100 km. We have not built anything, and we already know what the car burns at 90.

**Point at** the torque map's left edge: negative torque at low pressure, the engine pumping against a vacuum. Step 06 uses it to brake the car. λ is 1 almost everywhere, for the catalyst; rich only near full load.

**Where students stall:**

- **Reading kPa as gauge pressure.** They are absolute: 101 kPa is wide open, 33 kPa at idle a strong vacuum.
- **`kpa, rpm, T = engine_map("fuel_gps.csv")`,** which overwrites the torque map in `T`. The guide names the others `F` and `L`.
- **`heatmap(rpm, kpa, T)`, axes swapped.** Plots wants x, y, then a matrix with one row per y. The file's rows are speeds, so speeds go on y.
- **Which pressure.** 47.7 kPa is the 3000 rpm row; the 90 km/h point itself, at 3080 rpm, is 47.8 kPa. The plot marker goes at 3080 rpm, 47.8 kPa.

**Where the numbers come from:** US EPA ALPHA, 2014 Mazda 2.0 L Skyactiv, scaled to 1.5 L at constant BMEP and BSFC, and re-gridded from a torque axis to a manifold-pressure axis by `scripts/alpha_engine_maps.jl`; citation and every assumption in `data/engine/README.md`. The three cruise rows, 50 · 90 · 130 km/h, are checked to the digit in the "Hands-on 02 cruise table" testset.

**For step 03:** the map holds torque up to 105 kPa, above what the engine reaches. `full_load.csv` holds the real ceiling: 148.4 N·m at 3000 rpm against the map's 163.0 at 99.9 kPa.

## 02 Manifold {#manifold}

**Say:** the one equation this session is about. Hands-on 1 had a 0.3 s lag "because the manifold has to fill". Today the manifold is a real volume, and the lag comes out of it, different at every speed. Then the guide's bathtub box: the throttle is the tap, the cylinders the drain, and the drain pulls harder the fuller the tub.

**Built or given:** students paste the manifold, one equation, and draw the bench. The throttle (a choked-flow orifice) and the cylinders' air flow (a volumetric efficiency that must match the maps exactly) are given from `Vehicle.Engine`; neither is today's lesson.

**Point at** the feedback wire: `p_m` goes back into the throttle and the cylinders, because both flows depend on it. That loop is what makes the pressure settle.

**Say, on the runs:** at idle the pressure pulls down from the outside air to 33 kPa, and a tiny throttle opening lifts it to 37. At 3000 rpm with the throttle closed it pulls down much further, to 13.5: overrun, the vacuum the brake booster loves. Wide open, it is back near the outside pressure.

**Where students stall:**

- **Ports stacked in the middle of `manifold`.** They pasted a block without the `{"Dyad": …}` port placements, and the bench cannot be wired: paste the guide's block again.
- **Search results.** "Manifold" also offers the course's `IntakeManifold`; "Throttle" offers four throttles. Take their own `MyCar › Manifold` and the plain `Vehicle › Engine › Throttle`.
- **Default names.** The parts arrive as `step`, `constant1`, `constant2`, `throttle`, `cylinderairflow`, `manifold`: set parameters first, then rename to the guide's names.
- **Which input is which.** The icons do not name their inputs: hover a port. `Throttle` has `u_thr` on top, `p_m` below; `CylinderAirflow` has `p_m` on top, `omega` below.
- **Parameter fields.** Click, <kbd>End</kbd>, <kbd>Shift</kbd>+<kbd>Home</kbd>, type, <kbd>Enter</kbd>. <kbd>Ctrl</kbd>+<kbd>A</kbd> selects the whole Studio page, and a triple-click does not select the old value.
- **The `initial` line** forgotten, or put after `metadata`. It goes after the last `connect`; without it the solver does not know the manifold starts full of outside air.
- **`UndefVarError: AirPathStepTransient not defined`** in a REPL opened before the component existed. Run once with ▷ on the analysis tab, which loads it, or restart the REPL.
- **Reading 33 000 as wrong.** The plot is in pascals; divide by 1000.
- **Reading τ on the first fall from 101 kPa.** That fall is not a straight lag; its 1/e time is about 0.10 s. The 0.15 s is the small step at 1 s.
- **Expecting 0 kPa with the throttle closed.** A closed throttle still leaks, and the cylinders stop pulling once the pressure is low.

**Where the numbers come from:** the test cases of `Vehicle.Engine.TestAirPath` (idle 32955.7 Pa, idle step 37270 Pa, overrun 13482.4 Pa, tip-in 99889.9 Pa), and the "Hands-on 02 manifold" testset on `HandsOn02.AirPathStepTransient`. A student manifold with the given parts is the same equation, so it must give the same numbers. The τ derivation is in the guide's *Details* box.

## 03 Map engine on a dynamometer {#map-engine}

**Say:** this is the lecture's engine as a picture you draw. The pedal opens the throttle, the air path gives the manifold pressure, and two maps read at speed and pressure give torque and fuel; CO₂ is fuel × 3.09. The pedal goes straight to the throttle: no pedal curve, no actuator, so the only thing between pedal and torque is the manifold of step 02.

**Built or given:** students draw `MapEngine` from six given blocks: `AirPath` (step 02's bench, packaged), `TorqueMap` and `FuelMap` (their tables inside, from the course library's `EngineMapData`; they take rad/s and Pa and convert to the tables' rpm and kPa), a speed sensor, a gain and a torque source. The only number they type is 3.09. The dyno bench is pasted. At the end they paste fuel cut into their own engine; that engine goes into their car in step 04.

**The tight part is the 15-wire drawing.** If the room is slow, hand out the guide's *Stuck?* code and keep the runs.

**Ask the room**, before run 2: what does the engine do with the pedal closed at 3000 rpm? *(13.5 kPa from step 02; the map there says −18.2 N·m and still 0.097 g/s of fuel. Keep the answer: it opens E.)*

**Point at, run 1:** the time between the pedal step and the torque. The pedal jumps; the torque takes about 50 ms, because the manifold has to fill to the new pressure. That is the state of step 02, not Lecture 1's fixed lag. **Run 2:** wide open, the torque rises 10–90 % in about 2 ms; a big throttle opening fills the manifold almost at once and hides the lag, which is why run 1 is a small step.

**Where students stall, A–D:**

- **The shaft.** The speed sensor's circle goes to `spline`, the same port as the torque source's, or the sensor reads a shaft nobody drives. There is no flywheel: on the dynamometer the bench sets the speed.
- **Ports.** Drop each one from **+** straight onto the outline, in `MapEngine`'s own diagram. To move or rename one, click just outside it (a click on it starts a wire), then drag, or **Edit Parameters** → pencil.
- **Port names.** Hover to read them: `air` has `u_thr`, `mdot_bst`, `omega` in from the top and `mdot_thr`, `p_m`, `mdot_cyl` out; the maps have `omega` on top, `p_m` below.
- **The last wire lost.** Save twice after it: one <kbd>Ctrl</kbd>+<kbd>S</kbd> can miss it, a known Studio bug. Then check the **Problems** tab is empty.
- **The pasted bench piles up in a corner** if its `{"Dyad": …}` placements were left out: paste the guide's block again.
- **Fuel read in kg/s.** The plot shows 0.00085, which is 0.85 g/s; wide open, 0.00375.

**E, the fuel-cut paste: the rehearsal's traps.**

- **▷ before the REPL.** The REPL keeps the `MapEngine` and `MapEngineDyno` it loaded before the paste and runs them without an error. A student who skips ▷ sees a speed that never ramps down, so the fuel never comes back; a REPL left open since step 00 shows no cut at all. One ▷ on `MapEngineDynoTransient` loads the edited ones.
- **The selection trap.** The paste blocks end without a line break; the site's copy button copies no trailing newline. A student who selects whole lines from the margin gets the next line joined onto the paste's last one. The guide says where to click and when to press <kbd>Enter</kbd>.
- **Diagonal wires.** The four new wires carry waypoints drawn for `HandsOn02.MapEngineFuelCut`'s layout, so on a student's own drawing they may cut diagonally across blocks. The connections are right. Dropping the waypoints is worse: Studio then draws straight diagonals across the whole diagram.
- **Nothing moves.** The two new map blocks have their ports where `TorqueMap`'s and `FuelMap`'s are, so retyping the two lines moves no wire.
- **Run 2 again, after the paste,** starts in the cut: 0 fuel and −18.7 N·m. The engine starts above 1300 rpm with the pedal closed. Runs 1 and 2 stop at 2 s, before the ramp, so they are otherwise unchanged.

**Say, on E:** the guide's *Why fuel cut* box: on overrun there is no reason to inject anything; the cut saves fuel, keeps unburned fuel out of the catalyst and brakes the car a little harder; it ends near idle so the engine does not stall. Two speeds, 1300 and 1000 rpm, so the injectors do not chatter: hysteresis, like a thermostat. Run 2's closed pedal read −18.2 N·m from the map; the cut gives −18.7, the closed-throttle curve: the 0.5 N·m is what the 0.097 g/s was still giving.

**Against `MappedEngine`:** the same −18.7 N·m after the same release, because it uses the same `FuelCutLogic` and curve. Its fuel goes a little later: its 50 ms throttle actuator keeps the manifold full a moment longer. In the cut the torque does not depend on `p_m`.

**Where the numbers come from:** run 1 starts at step 01's 90 km/h point (31.1 N·m, 47.8 kPa, 0.85 g/s; the pedal 0.1034 was found by bisection) and ends at 1.02 g/s. Run 2's pressures are `TestAirPath`'s at 3000 rpm, and the torques and fuel are the maps read there: `torque_Nm` at (3000, 99.9) = 163.0, capped by `full_load.csv` at 148.4; `fuel_gps` 3.75 g/s, × 3.09 = 11.6 g/s; closed, −18.2 N·m and 0.097 g/s. E's numbers are from `HandsOn02.MapEngineFuelCutDynoTransient`; the cut and resume speeds are `FuelCutLogic`'s defaults, 1300, 1000, 6500 and 6300 rpm, assumed. All are in the "Hands-on 02 map engine" and "Hands-on 02 fuel cut" testsets.

## 04 The car with a mapped engine {#mapped-car}

**Say:** the milestone. Same body, same driveline, same single gear of 4.0; only the engine changes, and with it the input: a pedal from 0 to 1, not a torque. Hands-on 1 ended on this question: what would you add to get a believable top speed? A torque curve. Push equals drag plus rolling, as before, but the push falls away at high revs.

**Duplicate, do not edit:** their hands-on 1 car stays as it was, and Lecture 1's cruise control still runs on it.

**Point at** the gain: fuel comes out in kilograms per second, a tiny number; 3600 / 0.745 = 4832.2 turns it into liters per hour. And the flywheel: on the dynamometer the bench set the speed; in the car the crankshaft and flywheel resist every change of speed, 0.15 × (4 / 0.31)² = 25 kg more car on 1400 kg.

**Derivation, if asked:** engine rpm = v / 0.31 × 4 × 60 / 2π, 34.2 rpm per km/h. So 6500 rpm is 189.9 km/h, 6300 is 184.1 and 1000 is 29.2. At 192 km/h, 6570 rpm, the engine gives 96 N·m at full load; × 4 / 0.31 = 1239 N = 0.378 × 53.3² + 165. Solving that balance over the tables gives 191.9 km/h; the limiter at 189.9 km/h comes first.

**Ask the room:** is the rev limiter what limits a real car's top speed? *(Rarely in top gear; this car has one gear, ratio 4, a second or third gear on a real car.)*

**Where students stall:**

- **`mdot_bst` left unconnected.** The model then has an input nobody drives and does not compile: the same "unbalanced" error as hands-on 1's missing support.
- **Ports renamed on an instance.** Rename and place `MappedCar`'s ports in its own diagram, not on a `car` in a bench.

**Open, before the session:**

- **No reference yet.** `HandsOn02.MappedCar`, `MappedCarWOT` and `MappedCarWOTTransient`, built on `HandsOn02.MapEngineFuelCut` with the flywheel, are still to write.
- **The bench's `initial` lines.** The engine shaft and the flywheel are tied to the wheel through the gear, so only `car.body.mass.s`, `car.body.mass.v` and `car.engine.air.manifold.p` should be set; confirm on the reference.
- **A trial of this car did not move from v = 0:** the full-load curve is 0 N·m at 0 rpm and caps the torque there. Started at 2 m/s it reached 189.9 km/h and hit MaxIters at about 87 s on the rev limiter. The car with `MappedEngine` behaves the same, so the fix belongs to the bench or the limiter.
- **The checkpoint:** whether the speed saws between 184 and 190 km/h or sits at 190, and the time to 100 km/h.

## 05 Cruise: fuel and CO₂ {#cruise}

**Say:** the session's result. Three steady speeds, three fuel figures. Step 01 predicted the 90 km/h one from the table; now the car gives it. Start the car at the speed you want and give it the pedal that holds it there; if the speed stays put for a minute, the engine's fuel flow is the cruise consumption. The engine gives liters per hour, the car covers kilometers per hour: divide, and the hours cancel.

**Ask the room:** a car at idle, standing still. What is its L/100 km? *(Infinite: fuel flows, distance does not. That is why the sticker uses a driving cycle, step 07.)*

**Point at** 130 against 50: 2.6 × the speed, 5.5 × the fuel per hour, 2.1 × the fuel per kilometer; drag goes with v². And `p_m`: even at 130 the manifold is at 61 kPa, a cruising petrol engine is throttled hard. Why below a real car's label: steady speed, one gear, warm engine, no auxiliaries; step 07 is where the comparison is fair.

**The pedal search.** The car's time constant is about a minute (hands-on 1, step 05), so a wrong pedal shows as a slow drift, not a jump; steps of 0.01 are fine. The car runs the student's `MapEngine`, whose pedal drives the throttle directly: on the dynamometer it holds the three cruise torques at 0.044 / 0.103 / 0.190, so start the search near those, not at `MappedEngine`'s 0.124 / 0.220 / 0.331.

**Where the numbers come from:** the plan's predicted anchors (`docs/lecture-02-mapped-engine-plan.md`), computed from the maps before any model existed: bilinear interpolation at 1710, 3080 and 4450 rpm and the holding torques 18.4, 31.1 and 51.0 N·m, checked to the digit in the "Hands-on 02 cruise table" testset. 50 km/h is 3.34 L/100 km, so 3.3.

**Open:** the reference `HandsOn02.MappedCarCruise` on the car with the student's `MapEngine`; then the pedal values that hold 50, 90 and 130 km/h to three decimals, in the guide in place of the search, which costs several runs per speed. Confirm the speed holds within ±1 km/h over 60 s.

## 06 Coast-down and a brake stop {#coast-brake}

**Say:** two things a driver does a hundred times a day, both invisible from the seat. Lift your foot at 90: the throttle closes, so the manifold empties to 13.5 kPa, as in step 02; and the engine control unit cuts the fuel, to zero, not to idle. The engine is now an air pump driven by the wheels, and pumping against that vacuum brakes the car. Then the brake: a brake booster's vacuum side is connected to this manifold, and the deeper the vacuum while you brake, the more it helps your foot.

**Ask the room:** coasting down a long hill in gear, or in neutral: which uses less fuel? *(In gear: zero. In neutral the engine idles at 0.45 L/h.)*

**Derivation:** the closed-throttle torque at 3080 rpm, interpolated in `closed_throttle.csv`, is −19.0 N·m; × 4 / 0.31 = 246 N. With 401 N of road load, 647 N / 1400 kg = 0.46 m/s²; in neutral, 401 / 1400 = 0.29 m/s². Fuel resumes below 1000 rpm, 1000 / 34.2 = 29.2 km/h; the cut arms only above 1300 rpm, 38 km/h, so a lift at 30 km/h never cuts. 4000 N is about 0.3 g on 1400 kg, a firm stop. 25 km/h is 855 rpm, just above idle; below that the one-gear car drags the engine toward standstill and `p_m` climbs to ambient, an artifact of having no clutch.

**If short of time,** do only the coast-down.

**Where students stall:**

- **Benches that stop compiling** after `F_brake` is added: every other car bench now has an input nobody drives. Each needs a `Constant(k = 0)` into `car.F_brake`.
- **The car speeds up when it brakes:** the two flanges of `brake` are the wrong way round; swap them.

**Open:** the reference `HandsOn02.MappedCarCoast` with its coast-down and brake-stop analyses; then `p_m` at the fuel-resume instant, `p_m` during the stop, the time to 25 km/h, and the sign of the brake force as wired (`Force` applies `f` at `flange_a` and `-f` at `flange_b`), so the guide can give the one correct wiring instead of "swap".

## Hand in {#hand-in}

**Say:** same as last time. The description carries the cruise table: three speeds, L/100 km and g CO₂/km.

**Where students stall:** a base of `main` while hands-on 1's pull request is still open: the pull request then shows hands-on 1's commits too. The base is the branch `handson-02` was created from.

## 07 WLTC {#wltc}

**Only if time allows.** If the session has no room, point students at the prepared notebook and stop at the hand-in.

**Say:** three additions, all things they have seen. The driver is the cruise controller of Lecture 1. The gearbox is the driveline of hands-on 1 with a choice of ratios. The trace is a table of speed against time.

**Open:** the whole step depends on task 6 (scope B: gearbox, shift schedule, PI driver, WLTC class 3 trace from DieselNet): the model names, the checkpoint over the cycle, and a real 1.5 L car's label figure with its source.

## Wrap-up {#wrap-up}

**Say:** every number in the deck's last table was known before the model ran. Where their run agreed, the model is right. **Point at** step 05: those are the numbers on a car's sticker, computed from a table measured on a test bench and a force balance they wrote in hands-on 1.
