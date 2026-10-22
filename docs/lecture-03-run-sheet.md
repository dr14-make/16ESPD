# Lecture 3 run sheet

What the lecturer needs during the Lecture 3 theory session but does not read aloud. The speaker
notes in `slides/decks/lecture-03/sections/` are the script; timing, setup and contingencies live
here, one section per deck section, in deck order.

The 3-hour block is two halves: **this deck, about 90 minutes**, then the **90-minute ABS
hands-on** on its own deck, `slides/decks/handson-03/`, and its guide. The hands-on plan is
`docs/lecture-03-handson-plan.md`.

**Total: 89 minutes**, including a 10-minute break and the ESP demo.

| Section | Slides | Minutes |
|---|---:|---:|
| 00 Front matter | 4 | 4 |
| 01 Friction and stopping | 6 | 9 |
| 02 How the brakes work | 7 | 11 |
| 03 Anti-lock braking | 14 | 23 |
| Break | | 10 |
| 04 Traction control | 5 | 5 |
| 05 Electronic stability program, demo included | 12 | 19 |
| 06 Torque vectoring | 4 | 4 |
| 07 Wrap-up and hand-over | 5 | 4 |

Running clock: 01 starts at 4, 02 at 13, 03 at 24, break at 47, 04 at 57, 05 at 62, 06 at 81,
07 at 85.

## Before class

- Deck on the projector, **presenter mode** from the nav bar (bottom left): notes, next slide and
  the clock.
- The ABS figures are committed; nothing has to run. Notebook 01 open in Pluto is optional, for a
  question about `a_ref` (its slider).
- The ESP demo figures are committed too. A live run needs the planar car, which is not on the
  integration branch yet: check out `feat/lecture-03-planar-car`, run
  `Lecture3.SineWithDwellRunTransient(A_sw = deg2rad(180))` once before class so it is compiled,
  and keep the REPL open. Without that, show the figures.
- Handout: `handout.pdf`, published next to the deck, one slide per page, notes excluded.

## Throughout

- **Green cues** (`.handson` blocks) mark slides the hands-on puts into practice (→) and the
  numbers it checks against (✓). Point at them; do not explain the step. Students come back to
  section 03's result slides during the hands-on, so leave them as they are.
- If behind, cut in this order: the sources slide (always skipped in the room), section 06 down
  to its summary slide, the channels slide in 03, the history slide in 03. Do not cut the four
  ABS result slides or the ESP demo.

## 00 Front matter — 4 min

- Cover 0.5, from Lecture 1 1.5, the sections 1, the models 1.
- "The models behind this lecture": the third column is the hands-on; say "after the theory" and
  move on.

## 01 Friction and stopping — 9 min

- Friction and the table 2, tire curve 2, braking distance 2, cornering limit 2, summary 1.
- The static/kinetic block pictures were folded out; draw the friction-against-push curve on the
  board only if asked.
- Braking distance: the 90 km/h peak and sliding numbers return in hands-on step 01.

## 02 How the brakes work — 11 min

- Lever and hydraulics 2, force chain 2, pedal to pressure 2, master cylinder 2, the rest of the
  system 2, summary 1.
- Not in the hands-on. Keep it moving; the pedal-to-pressure figure is the one to linger on.

## 03 Anti-lock braking — 23 min

- Hardware 9: what ABS does 1, history 1, sensors 2, modulator 2, channels 1.5, control cycle
  1.5. Estimation 2: reference speed. Model and results 10: model 3, one stop 2, on the curve 2,
  distance 1.5, surfaces 1.5. Summary 1, cover and slack 1.
- The four result slides (`one-stop`, `on-the-curve`, `abs-distance`, `abs-surfaces`) are the
  hands-on's checkpoints. Name the numbers the students will hit: 43.7 m locked, 34.4 m on true
  slip, 38.7 m wheel speed only.
- Reference speed: the `a_ref` trap is what step 05 shows. Plant the question "what would `a_ref`
  be on snow?" and leave it open.

## Break — 10 min

After the ABS summary. The theory half is front-loaded so the break falls near the middle.

## 04 Traction control — 5 min

- What it does 1.5, two actuators 1.5, Lecture 1 link 1, summary 1.
- The bonus task (step 06, TCS on `SlipCar`) is on the "You have seen this already" slide.

## 05 Electronic stability program — 19 min

- Theory 12: what ESP does 2, sensors 1.5, Ackermann 2, reference model 2.5, braking one wheel 2,
  does it work and the test 2.
- Demo 6: the planar car 2, the passive run 3 (both figure slides), ESP on 1.
- The "Examples" slide (Renault pictures) was cut: the yaw-correction diagram says the same.
- **ESP on is pending task 5** of `docs/lecture-03-esp-dyad-tasks.md`. Say so. The right column
  of that slide is the research probe's expectation, not a Dyad run.
- Figures: `public/figures/05-swd-path.svg`, `05-swd-yaw-rate.svg`, from
  `scripts/export_lecture03_esp_figures.jl` run against the planar-car branch at 126ee69 (the
  script's docstring has the command). When task 5 lands, add the ESP-on run to that script as
  `05-swd-esp-on.svg` and fill the dashed slot.

## 06 Torque vectoring — 4 min

- Yaw moment 1.5, three ways 1.5, summary 1. First to shrink if the demo ran long.

## 07 Wrap-up and hand-over — 4 min

- The table 1, summary 1, hand-over 2. Skip the sources slide.
- Leave the hand-over slide on the projector while the room switches to the hands-on: it lists
  the steps, their minutes, the theory slide each one rests on, and what to have open.
