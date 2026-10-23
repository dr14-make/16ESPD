# Lecture 3 run sheet

What the lecturer needs during Lecture 3 but does not read aloud. The speaker notes in
`slides/decks/lecture-03/sections/` are the script; timing, setup and contingencies live here,
one section per deck section, in deck order.

Lecture 3 is one 3-hour block in the Lecture 1 format: the theory and a live build, students
building along in Dyad Studio on their own `MyCar`. Each build step has one slide in the section
it belongs to and an anchored section on the build guide (`lecture/lecture-03/` on the course
site). The plan behind the steps is `docs/lecture-03-handson-plan.md`.

**Total: 176 minutes**, including a 10-minute and a 5-minute break and the ESP demo.

| Section | Builds | Minutes |
|---|---|---:|
| 00 Front matter | 00 set up | 10 |
| 01 Friction and stopping | 01 the tire's limit, by hand | 14 |
| 02 How the brakes work | | 10 |
| 03 Anti-lock braking, to the break | 02 lock the wheel, 03 an ABS of your own | 55 |
| Break | | 10 |
| 03 Anti-lock braking, after the break | 04 only the wheel speed, 05 across road surfaces | 42 |
| Break | | 5 |
| 04 Traction control | 06 take-home bonus (slide only) | 6 |
| 05 Electronic stability program, demo included | | 18 |
| 06 Torque vectoring | | 3 |
| 07 Wrap-up | | 3 |

Running clock: 01 starts at 10, 02 at 24, 03 at 34, the first break at 89, 03 resumes at 99, the
second break at 141, 04 at 146, 05 at 152, 06 at 170, 07 at 173, end at 176.

## Before class

- Deck on the projector, **presenter mode** from the nav bar (bottom left): notes, next slide and
  the clock.
- Three windows: the deck; Dyad Studio with your own `MyCar` on a fresh `lecture-03` branch,
  which you build on live exactly as the students do; the Julia REPL for the plots and
  `braking_distance`.
- Run steps 02–04 once before class from the reference (`HandsOn03.LockedStopTransient`,
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
  compiled. The clocked ones still take about 30 s each when warm: start one, keep talking over the
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
- **If behind,** cut in this order: the sources slide (always skipped in the room), section 06 down
  to its summary slide, the channels slide in 03, the history slide in 03, the hydraulic stretch
  goal. Then hand out `PhaseABS` in step 04 so students write only the estimator. Do not cut the
  four ABS result slides, any build slide or the ESP demo.

## 00 Front matter — 10 min

- Cover 0.5, from Lecture 1 1.5, the sections 1, the models 1, build 00 6.
- "The sections": the right column says which section each build sits in; walk it once.
- Build 00: wait until most laptops list `BrakedWheel` under **+**. A student without hands-on 2
  branches from `main`; today needs only hands-on 1's `Body`.

## 01 Friction and stopping — 14 min

- Friction and the table 2, tire curve 2, braking distance 2, build 01 5, cornering limit 2,
  summary 1.
- The static/kinetic block pictures were folded out; draw the friction-against-push curve on the
  board only if asked.
- Build 01 is paper or REPL. Wait for 4256 N·m from most of the room: it comes back on every
  ABS slide.

## 02 How the brakes work — 10 min

- Lever and hydraulics 2, force chain 2, pedal to pressure 2, master cylinder 1.5, the rest of the
  system 1.5, summary 1.
- Nothing to build. Keep it moving; the pedal-to-pressure figure is the one to linger on.

## 03 Anti-lock braking — 97 min, the break inside it

Before the break, 55 min:

- Cover and what ABS does 2, **build 02** 15, history 1, sensors 2, modulator 2, channels 2,
  control cycle 2, the model 3, **build 03** 22, one stop and on the curve 4.
- Build 02: the five `initial` lines are the stall. A wheel speed that climbs instead of falling
  means they are missing. Expected 43.7 m, `wheel.kappa` −1 by 0.67 s.
- Build 03: run A loses to the locked wheel (53.8 m): say it is the point, not a mistake, before
  anyone starts debugging. C gives 34.4 m. Rehearse whether Studio's code view keeps the
  `pressure` line and the `ifelse`; the guide's "Fell behind?" block has the full source.
- "One stop" and "on the curve" are the checkpoints for 02 and 03. Check the neighbor's screen,
  then release the room.

## Break — 10 min

Everyone needs a working `ABSStop` before it ends: build 04 is a copy of it. Stragglers paste the
step 03 code from the guide page.

After the break, 42 min:

- Reference speed 2, **build 04** with its checkpoint slide 25, braking distance 2, surfaces 2,
  **build 05** 10, summary 1.
- Reference speed: plant the question "what would `a_ref` be on snow?" and leave it open; build 05
  answers it.
- Build 04 is the longest: two components in code and a bench. If the room is behind at the
  halfway mark, hand out `PhaseABS` from the guide and let them write only the estimator. A
  student who filters `a_w` more heavily than `T_f = 5 ms` gets a snow stop longer than locked.
  Expected 35.5 m dry, 69.8 m wet.
- "Braking distance" is the checkpoint for 02–04: 43.7, 34.4, 35.5 m against the library's 38.7.
- Build 05 is a REPL loop: the first two columns must match the "Across road surfaces" table to
  the decimal. The `a_ref = 2.4` reruns give 124.1 m on snow and 105.4 m dry.
- The hydraulic version of step 04 is a stretch goal for whoever finishes early
  (`docs/brake-system-implementation-plan.md`, step 3); never wait for it.

## Break — 5 min

After the section 03 summary. The building is done for the day.

## 04 Traction control — 6 min

- What it does 1.5, two actuators 1.5, Lecture 1 link 1, take-home bonus 1, summary 1.
- The bonus is step 06 on the guide page: a brake-based TCS on hands-on 1's `SlipCar`, handed in
  as a pull request for extra points. Its reference (`feat/handson03-tcs-bonus`) is not built yet.

## 05 Electronic stability program — 18 min

- Theory 9: what ESP does 1.5, sensors 1, Ackermann 1, reference model 2, braking one wheel 2,
  does it work and the test 1.5. Ackermann is the slide to shorten: the table, not the
  derivation.
- Demo 8: the planar car 1, the passive run 2 (both figure slides), ESP on 1.5 (path and table,
  then yaw rate and brake torque), ESP through ABS 1.5, split-µ 2. Students watch; nothing to
  build.
- ESP braking directly passes at every amplitude but locks the braked wheel and leaves at
  48 km/h; say it, then show the fix on the next slide: through ABS the slip stays above −0.09
  and the car leaves at about 19 m/s.
- Split-µ: stress that the steering wheel is held straight. ABS alone turns the car 129°; the
  P controller barely helps, the PI holds 3° at the cost of stopping distance.
- If short of time, take the split-µ slide down to its table (1 min).
- Figures: `public/figures/05-swd-path.svg`, `05-swd-yaw-rate.svg`, `05-swd-esp-path.svg`,
  `05-swd-esp-yaw.svg`, `05-esp-abs.svg`, `05-split-mu.svg`, from
  `scripts/export_lecture03_esp_figures.jl` at 23bd4bb (the script's docstring has the command;
  about ten minutes). The numbers on the slides are what it prints.

## 06 Torque vectoring — 3 min

- Yaw moment 1, three ways 1, summary 1. First to shrink if the builds or the demo ran long.

## 07 Wrap-up — 3 min

- The table 1, summary 1, what you measured 1. Skip the sources slide.
- "What you measured" closes the build: one row per step, each a number the students have on
  their own screen. Remind them to commit their `lecture-03` branch.
