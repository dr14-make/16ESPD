# Lecture 3 run sheet

What the lecturer needs during Lecture 3 but does not read aloud. The speaker notes in
`slides/decks/lecture-03/sections/` are the script; timing, setup and contingencies live here,
one section per deck section, in deck order.

Lecture 3 is one 3-hour block in the Lecture 1 format: the theory and a live build, students
building along in Dyad Studio on their own `MyCar`. Each build step has one slide in the section
it belongs to and an anchored section on the build guide (`lecture/lecture-03/` on the course
site). The plan behind the steps is `docs/lecture-03-handson-plan.md`.

**Total: 202 minutes**, including a 10-minute and a 5-minute break and the ESP demo: 22 more than
the block. The deck is planned at its full length; the "If behind" cut order below is how it fits
the room. Torque vectoring is not in this lecture: it belongs with the electric and hybrid drives.

| Section | Builds | Minutes |
|---|---|---:|
| 00 Front matter | 00 set up | 10 |
| 01 Friction and stopping | 01 the tire's limit, by hand | 19 |
| 02 How the brakes work | 02 pedal to wheel | 26 |
| 03 Anti-lock braking, to the break | 03 an ABS of your own | 45 |
| Break | | 10 |
| 03 Anti-lock braking, after the break | 04 only the wheel speed, 05 across road surfaces | 51 |
| Break | | 5 |
| 04 Traction control | 06 take-home bonus (slide only) | 10 |
| 05 Electronic stability program, demo included | | 23 |
| 06 Wrap-up | | 3 |

Running clock: 01 starts at 10, 02 at 29, 03 at 55, the first break at 100, 03 resumes at 110,
the second break at 161, 04 at 166, 05 at 176, 06 at 199, end at 202.

## Before class

- Deck on the projector, **presenter mode** from the nav bar (bottom left): notes, next slide and
  the clock.
- Three windows: the deck; Dyad Studio with your own `MyCar` on a fresh `lecture-03` branch,
  which you build on live exactly as the students do; the Julia REPL for the plots and
  `braking_distance`.
- Run steps 02–04 once before class from the reference (`HandsOn03.PedalStopTransient`,
  `ABSStopTransient`, `ABSStopWheelOnlyTransient`) so the library is compiled, and keep the REPL
  open.
- Step 00 needs the course-library tag (`TODO-TAG` on the build 00 slide and the guide page). A tag
  cut from this branch carries the planar car's `MultibodyComponents`, so ask the students to run
  step 00 before the lecture: the first compile then takes about a minute longer.
- The ABS figures are committed; nothing in the theory has to run. Notebook 01 open in Pluto is
  optional, for a question about `a_ref` (its slider).
- The ESP demo figures are committed too. For a live run, in the same REPL run
  `Lecture3.SineWithDwellRunTransient(A_sw = deg2rad(180))`,
  `Lecture3.ESPSineWithDwellTransient(A_sw = deg2rad(180), abs_on = 1.0, Ki = 1e5)` and
  `Lecture3.SplitMuStopTransient(select_low = 1.0, esp_on = 1.0)` once before class so they are
  compiled, and `Lecture3.BrakeAndSteerTransient(abs_on = 1.0)` for section 03's braking and
  steering slide. The clocked ones still take about 30 s each when warm: start one, keep talking over the
  committed figure, show the result. Notebook `notebooks/lecture03/03-esp.pluto.jl` has every
  section 05 number with its band. Without the REPL, show the figures.
- Handout: `handout.pdf`, published next to the deck, one slide per page, notes excluded.

## Throughout

- **Build slides:** switch the projector to Studio, build it, run it, switch back. The note on
  each build slide is the narration for the full recipe; the guide page has the same step with
  every line of code.
- **Green cues** (`.handson` blocks) on the theory slides mark what a build puts into practice
  (→) and the number it checks against (✓). The library's four ABS result slides are the
  checkpoints: point at the student's number in the cue.
- **Catch-up:** every step on the guide page ends with a "Fell behind?" block holding the finished
  code. The reference answers are `dyad/HandsOn03/` under the same names; under **+** they show as
  `VehicleSystemsComponents › HandsOn03`. Step 05 runs on them by replacing `MyCar.` with
  `VehicleSystemsComponents.HandsOn03.`.
- **Solver:** every analysis is Tsit5 with `dtmax = 1e-3`. A student on FBDF gets a wrong
  "success": that is the first thing to check when a number is off.
- **If a solve stalls in front of the room:** show the committed figure on the build slide and
  keep talking. Do not debug live.
- **If behind,** cut in this order: the sources slide (always skipped in the room), the channels
  slide in 03, the history slide in 03, the valve-level stretch goal, the active wheel-speed
  sensor in 03, the locked wheel that does not steer in 01 (section 03's braking and steering
  shows it on the planar car), the differential film in 04, our ESP against a production ESP in
  05, then 05's sensor principles (how each sensor measures, the yaw-rate sensor, lateral
  acceleration) down to the sensors slide alone. That is about 15 of the 22 minutes. Then hand
  out `PhaseABS` in step 04 so students write only the estimator. Do not cut the four ABS result
  slides, any build slide or the ESP demo.

## 00 Front matter — 10 min

- Cover 0.5, from Lecture 1 1.5, the sections 1, the models 1, build 00 6.
- Build 00 adds `HydraulicComponents` next to the course library; a student without it gets a
  compile error in build 02, at the brake fluid. After the two `Pkg` lines, **Dyad: Restart
  Language Server**: a compile without it flags every library part
  `missing-direct-dependency … not a direct dependency`.
- "The sections": the right column says which section each build sits in; walk it once.
- Build 00: wait until most laptops list `BrakedWheel` under **+**. A student without hands-on 2
  branches from `main`; today needs only hands-on 1's `Body`.

## 01 Friction and stopping — 19 min

- Friction and the table 2, tire curve 2, tire models 3, braking distance 2, build 01 5,
  cornering limit 2, a locked wheel does not steer 2, summary 1.
- The static/kinetic block pictures were folded out; draw the friction-against-push curve on the
  board only if asked.
- Build 01 is paper or REPL. Wait for 4256 N·m from most of the room: it comes back on every
  ABS slide.

## 02 How the brakes work — 26 min

- Lever and hydraulics 2, force chain 2, pedal to pressure 2, master cylinder 1.5, the rest of the
  system 1.5, **the parts you are given and build 02** 16, summary 1. The parts slide takes about
  a minute of build 02's 16; leave it up while the room places the blocks.
- Keep the theory moving; the pedal-to-pressure figure is the one to linger on: build 02's two
  runs sit on it, 150 N below run-out and 300 N past it.
- Build 02 is the largest drawing of the day: twelve blocks, fourteen wires. The two code pastes
  are the stall: the brake fluid (`path medium` and `continuity`) and the four `initial` lines.
  Without the fluid lines Studio reports `Invalid common set: In component PedalStop, no local
  specification or external connectors … master.front.medium, master.rear.medium,
  line_f.port_a.medium, …` (the CLI: `Expected to find line_f.port_a.medium in at least one
  continuity graph for PedalStop`); a wheel speed that climbs means the initial lines are missing.
  Before that, the renames: placed blocks come out as `step`, `brakepedal`, `fixed`/`fixed1`,
  `constant1`…, and the pastes need the guide's names (translational `Fixed` to `fixed_hydraulic`
  first, then the rotational one to `fixed`). A snippet that fails with `UndefVarError:
  PedalStopTransient not defined in Main.MyCar` needs one ▷ **Run Analysis** first; the same
  holds for every new analysis in 03 and 04. Expected at pedal 0.3: 55 bar, no lock, 36.0 m; at 0.6: 89 bar,
  `wheel.kappa` −1, 43.7 m.

- "Where the assist comes from" (`vacuum-booster`, after build 02) is optional and outside the
  minutes, 3 min: `Lecture3.VacuumPedalStop` on manifold vacuum, the store and the electric pump.
  Show it only if ahead; its live run is in the slide's note.
- "One hose, one connector" (`vacuum-port`, right after it) is optional too, 2 min: the gas
  connector that joins engine and booster. Show it only together with `vacuum-booster`.

## 03 Anti-lock braking — 96 min, the break inside it

Before the break, 45 min:

- Cover and what ABS does 2, history 1, sensors 2, the active sensor 2 (optional), the system at
  a glance and what our models stand in for 3, modulator 2, channels 2, control cycle 2, the
  model 3, **build 03** with its result slide 22, one stop and on the curve 4.
- Build 03 copies `PedalStop` to `ABSStop` and puts one `ABSValve` per circuit between the master
  cylinder and the lines: three blocks, nine wires, two deleted; the fluid and the initial lines
  come with the copy. That is why it is 22 minutes, not 28. Say once, in one line, that
  `ABSValve` is ideal: no accumulator, no return pump, so no pedal pulse.
- Ports written in code need their `{^…}` markers and the `metadata` placements, pasted from the
  guide; without them the ports of `SlipABS`, `RefSpeedEstimator` and `PhaseABS` stack at the
  block's center on the bench and cannot be wired. Fallback: open the component's diagram and drag
  each port to the outline. `PhaseABS` is pasted whole, not duplicated from `SlipABS`.
- The stall is the `SlipABS` latch: before the first dump `p_cmd` is the driver's own pressure.
  A student who outputs `pressure.cmd` from the start puts the valve's 30 ms lag on every stop; the
  check is pedal 0.3, which must give 35.95 m, build 02's stop.
- Build 03: run A loses to the locked wheel (53.4 m): say it is the point, not a mistake, before
  anyone starts debugging. C gives 34.2 m, front pressure 63.6 bar with a 1 bar ripple at 26 Hz.
  Rehearse whether Studio's code view keeps the `pressure` line and the `ifelse`; the guide's
  "Fell behind?" block has the full source.
- "One stop" and "on the curve" are the checkpoints for 02 and 03. Check the neighbor's screen,
  then release the room.

## Break — 10 min

Everyone needs a working `ABSStop` before it ends: build 04 is a copy of it. Stragglers paste the
step 03 code from the guide page; `ABSStop` is the step 02 bench with the valves, so its block
pastes on its own, without a working `PedalStop`.

After the break, 51 min:

- Reference speed 2, **build 04** with its checkpoint slide 28, braking distance 2, surfaces 2,
  against measured cars 1.5, why ABS can stop longer 1.5, **build 05** 10, the planar car 1,
  braking and steering 2, summary 1. The six minutes build 03 no longer needs went to builds 04
  (3) and 05 (3); the planar car's three came out of section 05.
- "Against measured cars" and "Why ABS can stop longer" answer the question the snow numbers
  raise. Real ABS gains little on packed snow and loses on loose snow and gravel; the sources are
  in `docs/abs-efficiency-research.md`.
- Reference speed: plant the question "what would `a_ref` be on snow?" and leave it open; build 05
  answers it.
- Build 04 is the longest: two components in code and a bench. If the room is behind at the
  halfway mark, hand out `PhaseABS` from the guide and let them write only the estimator. Keep
  `T_f = 5 ms` on `a_w`. Expected 38.5 m dry, 130.6 m on snow; the checkpoint plot is on snow:
  front caliper 14.5–22.1 bar at about 6 dumps/s in the plotted 1.0–2.5 s; over the stop
  (t ≥ 1 s, v > 3 m/s) about 4/s and 1.6–22.3 bar, the dumps deepening as the car slows. Dry, the
  same span: 24.3–64.9 bar, a 2–3 bar ripple at about 14/s at speed, then four deep dumps. Set it
  against the measured Bosch cycle on the slide: snow in range, dry fast and shallow at speed and
  deep at the end, because the rates are fixed for one road. The plots are in Pa.
- "Braking distance" is the checkpoint for 02–04: 43.7, 34.2, 38.5 m against the library's 38.7.
- Build 05 is a REPL loop: the locked column must match the "Across road surfaces" table within
  0.1 m; the true-slip column is close to it, not equal (34.2, 64.6, 106.1 m). The `a_ref = 2.4`
  reruns give 130.9 m on snow, no better than at 8, and 106.3 m dry.
- A valve-level modulator in place of the ideal `ABSValve` is a stretch goal for whoever finishes
  early (`docs/brake-system-implementation-plan.md`, step 3); never wait for it.
- "The whole car with ABS" (`abs-full-car`, after build 05) is optional and outside the minutes,
  2 min: `Lecture3.FullCarABSStop`, build 03's ABS in the whole car, 34.8 m dry against 45.4 m
  locked. Show it only if ahead; its live run is in the slide's note.
- "The planar car" and "Braking and steering" close the section: the one-wheel bench has no
  lateral force, so the steering benefit needs the planar car. The slide shows only steering:
  3.02 m to the side of the obstacle with ABS, 0.00 m locked. It leaves the stopping distance out
  on purpose: on this car the locked wheels stop shorter (31.6 m against 38.2 m), because the
  planar ABS channels hold slip and are not tuned for distance. If asked, the students' 1D ABS is
  the one for distance. Figures: `public/figures/03-brake-steer-path.svg` and
  `03-brake-steer-forces.svg`, from `scripts/export_lecture03_steer_figures.jl`.

## Break — 5 min

After the section 03 summary. The building is done for the day.

## 04 Traction control — 10 min

- What it does 1.5, the differential film 2.5 (stop once the spider gears are shown), the open
  differential 1.5, two actuators 1.5, Lecture 1 link 1, take-home bonus 1, summary 1.
- The bonus is step 06 on the guide page: a brake-based TCS on hands-on 1's `SlipCar`, handed in
  as a pull request for extra points. Its reference is `HandsOn03.TCSStartTransient` on
  `feat/handson03-tcs-bonus`: 8.0 against 5.6 m/s at 10 s, against the guide's hand 8.5 and 5.7.

## 05 Electronic stability program — 23 min

- Theory 17: what ESP does 1.5, sensors 1, how each measures 1, the yaw-rate sensor 1.5, lateral
  acceleration 1.5, Ackermann 1, reference model 2, braking one wheel 2, the algorithm 1.5, does
  it work and the test 1.5, our ESP block by block 1, against a production ESP 1.5. Ackermann is
  the slide to shorten: the table, not the derivation.
- Demo 5: the passive run 2 (both figure slides), ESP on 1.5 (path and table, then yaw rate and
  brake torque), ESP through ABS 1.5. The planar car slide is one sentence: the car was introduced
  in section 03. Split-µ is its table only, in passing. Students watch; nothing to build.
- ESP braking directly passes at every amplitude but locks the braked wheel and leaves at
  48 km/h; say it, then show the fix on the next slide: through ABS the slip stays above −0.09
  and the car leaves at about 19 m/s.
- Split-µ: stress that the steering wheel is held straight. ABS alone turns the car 129°; the
  P controller barely helps, the PI holds 3° at the cost of stopping distance.
- Split-µ is budgeted at its table only: ABS alone 129°, the PI ESP 3°. Read the figure and the
  four rows (2 min) only if ahead of the clock.
- Figures: `public/figures/05-swd-path.svg`, `05-swd-yaw-rate.svg`, `05-swd-esp-path.svg`,
  `05-swd-esp-yaw.svg`, `05-esp-abs.svg`, `05-split-mu.svg`, from
  `scripts/export_lecture03_esp_figures.jl` at 23bd4bb (the script's docstring has the command;
  about ten minutes). The numbers on the slides are what it prints.

## 06 Wrap-up — 3 min

- The table 1, summary 1, what you measured 1. Skip the sources slide.
- "What you measured" closes the build: one row per step, each a number the students have on
  their own screen. Remind them to commit their `lecture-03` branch.
