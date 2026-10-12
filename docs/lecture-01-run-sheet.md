# Lecture 1 run sheet

What the lecturer needs during Lecture 1 but does not read aloud. The speaker notes in
`slides/decks/lecture-01/sections/` are a read-aloud script; timing, setup and contingencies
live here, one section per deck section, in deck order.

**Total: 187 minutes**, students building along in Dyad Studio.

| Section | Minutes |
|---|---:|
| 00 Front matter | 12 |
| 01 The car | 22 |
| 02 Open vs closed loop | 15 |
| 03 P | 15 |
| 04 PI | 18 |
| 05 PID | 18 |
| Break | 10 |
| 06 Windup | 25 |
| 07 Derivative and noise | 15 |
| 08 Tuning | 18 |
| 09 Discretization (demo only) | 8 |
| 10 Wheel and slip | 11 |

## Before class

- Deck on the projector; Dyad Studio and the notebooks on the laptop.
- Open **presenter mode** from the nav bar (bottom left, appears on hover): notes, next slide
  and a timer in the same tab, no popup to block.
- In Studio, open the students' hands-on package with `Car` and `GradeBody` in it. You build on
  it live, exactly as they do.
- Three windows: deck on the projector, Dyad Studio for the build, Jupyter for the notebook
  figures. Every demo slide names the notebook file and cell heading and carries the code with
  a copy button. A gray strip means there is a Dyad model worth having open for that beat.
- Keys: → or Space next, ← previous, O overview, G go to slide, F fullscreen.
- Handout: `handout.pdf`, published next to the deck, one slide per page, notes excluded.

## Throughout

- **Build slides:** switch the projector to Studio, build it, run it, switch back. The note on
  each build slide is the narration for the full recipe.
- **Catch-up checkpoints:** **P** at the end of 03 and **PID** at the end of 05. The guide page
  (`lecture/lecture-01/` on the course site) has both as code to paste. Reference is
  `CruiseLoop` with `with_I = false, with_D = false` for P, and `with_I = true, with_D = true`,
  `Td = 0.5`, `wd = 0` for PID.
- **If a solve stalls in front of the room:** every notebook is committed with its outputs.
  Scroll to the plot that is already there and keep talking. Do not debug live.

## 00 Front matter — 12 min

- Slide budgets: "What a system is" 2, "What a control system is" 1, "Three kinds of control" 1,
  "Five jobs, one diagram" 2, "Feedback is a family" 1.
- "The car, once": half a minute; section 01's recap comes back to the numbers.
- "What a system is": walk the table against the students' `Car` diagram if Studio is up.
- "Where the models live": leave it up while you state the HandsOn/Lecture1 rule. The gray
  "open in Dyad" strip is the reference model for the second screen; the students' own diagram
  is the one on the projector during a build.
- "Two conventions": on "what is missing from a gain of 220", wait for someone to say "units".

## 01 The car — 22 min

- Split: recap 8 (model map 3, four Studio moves 3, plant numbers 2), full throttle 2, step test
  and build 1a 5 (3 building, 1 running), three names 1, K/τ/θ 3, GradeBody reminder and
  build 1b 3 (reminder 30 s, build 2, bench run 1).
- Students need their hands-on package `MyCar` open with `Car` and `GradeBody`. Anyone without it
  uses the reference `dyad/HandsOn/` from the guide page; instance names match. Pair anyone who
  skipped the hands-on with someone who did it for the first build.
- Recap: do not re-derive. The hands-on deck has every derivation; the link at the bottom goes to
  its summary table.
- Start the full-throttle solve (`01-the-car.ipynb`, cell 4) while the recap is still up; it is
  the slowest solve in the notebook.
- Have open: `dyad/Lecture1/WideOpenThrottle.dyad` for full throttle;
  `dyad/Lecture1/CarStepTest.dyad`, then `HandsOn/Engine.dyad` for the step test (delay → lag →
  limiter).
- Notebook cells: 4 full throttle, 5 step test, 7 K/τ/θ (read the values slowly, with units).
- Builds 1a (`CarStepTest`) and 1b (`GradeCar`) are live on the projector. Walk the room while 1a
  solves.
- Three names slide: mark the transient and steady-state regions on the step-test plot by hand.
- If short of time, skip the `GradeCarFullThrottle` bench run; a `GradeCar` block with `tau_cmd`
  and `grade` inputs is enough.
- Checkpoint at the end of 01: every student has a `GradeCar` that compiles. Anyone without one
  takes the reference `HandsOn.GradeCar` from the guide page before 02.

## 02 Open vs closed loop — 15 min

- Split: two architectures 2, invert and drive 2, break it 3, close the loop 2, build step 5
  (loop and controller shell), what feedback costs and hand-off 1.
- Have open: `dyad/Lecture1/CruiseLoop.dyad` from the start of the section.
- Notebook: `notebooks/lecture01/02-open-vs-closed-loop.ipynb`, cells "Invert the model", "Break it
  three ways", "Close the loop".
- Invert slide: let the room list the assumptions before showing the next slide.
- Build step 2 live; walk the room after part A (controller shell). Part B is drag and drop;
  students check against the two screenshots.
- "Close the loop": do not explain the remaining gap; 03 does.

## 03 P — 15 min

- Split: control law 2, build step 3 and first run 4 (2 building, 2 running), the notebook's
  three cells 6 (fast, the closed loop settles in seconds), why it cannot be zero 2,
  checkpoint P 1.
- Have open: `dyad/Lecture1/CruiseLoop.dyad` on the control-law slide,
  `dyad/Lecture1/CruiseController.dyad` on the build slide.
- Notebook: `notebooks/lecture01/03-proportional.ipynb`, cells "2. One assumption, stated before it
  is used", "3. Raising the gain", "4. Error against gain".
- Build step 3: show the 0.7 km/h gap but do not explain it yet.
- "Why it cannot be zero": do not say "integral"; let the room produce the word.
- **Checkpoint P:** wait here, a minute or longer. Take the time from the notebook cells, not the
  build. Catch-up: guide page step 3 code, or reference `CruiseLoopTransient` (P by default,
  because `CruiseLoopStep` sets `with_I = false, with_D = false`).
- If the error vanished at high gain in the executed notebook, the integral path was left on
  (`with_I = false` is the difference from 04).

## 04 PI — 18 min

- Split: adding a memory 2, build step 4 and run 6 (4 building, 2 running and reading), PI
  against P 2, the punchline 5, what it costs 2, hand-off 1.
- The punchline is the best slide in the lecture. Do not rush to it or past it; slow down on it.
- Have open: `dyad/Lecture1/CruiseLoop.dyad` on "Adding a memory" and "The punchline"; build
  reference `dyad/Lecture1/CruiseController.dyad`.
- Notebook: `04-proportional-integral.ipynb`, cell 1 "PI against P", cell 2 the punchline, cell 4
  the cost slide. On the cost slide, read the overshoot percentages from cell 4's output.
- If the integrator settles anywhere other than the hand-computed 40.1 N·m, units or gear ratio
  disagree between notebook and model. Stop and find it.

## 05 PID — 18 min

- Split: the third path 2, build step 5 and run 6 (4 building, 2 running and comparing with
  step 4), two forms 2, what tuning is 2, P/PI/PID 2, who does what 2, how much derivative and
  the names 1, checkpoint PID 1.
- Spend the time on the three-contributions plot; it is the only place the division of labor is
  directly visible. Give the P/PI/PID plot a full minute of silence before speaking.
- Have open: `dyad/Lecture1/CruiseLoop.dyad` on "Why P, PI and PD all have names"; build reference
  `dyad/Lecture1/CruiseController.dyad`.
- Notebook: `05-pid.ipynb`, cell 2 P/PI/PID, cell 3 contributions, cell 4 Td.
- If a student's run differs, compare against the reference `CruiseController` in this order:
  `add_d` signs, then `T = Td / Nd`, then `xd0`.
- **Checkpoint PID:** wait here. Stragglers paste the step 5 code or switch to reference
  `CruiseLoop` with `with_I` and `with_D` true, `Td = 0.5`, `wd = 0` (its `xd0` follows `wd`).
  Nobody goes into the break without it; the break absorbs stragglers.

## Break — 10 min

Check everyone is at checkpoint PID before releasing the room.

## 06 Windup — 25 min

- The longest section. Split: two halves 3, steps 6a and 6b 5, climb harness 6c and the two
  "overshoot is coming" slides 6, clamping and step 6d 6, back-calculation, three-way comparison
  and the two limits 5.
- Four build steps: two inside `GradeCar` and `CruiseController`, one new climb harness, one
  equation.
- Notebook: `notebooks/lecture01/06-windup.ipynb`, cells "The climb, no anti-windup", "The
  overshoot", "Three-way comparison".
- "Why the crash is already scheduled": take two guesses from the room, write them on the board,
  then run the overshoot cell.
- Overshoot slide: collect answers before showing the fix; "limit the output" is the usual first
  answer.
- Back-calculation slide: have the reference `CruiseClimb` (`dyad/Lecture1/WindupClimb.dyad`)
  open next to the students' `MyCar.CruiseClimb`.
- Two-limits slide: optional live demo if the room wants it. Set `controller.y_max = 140` on
  `CruiseClimb`, re-run, then try 300.
- Catch-up 6a: `HandsOn.GradeCar` already has `T_max`; replace `plant` with it.
- Catch-up 6c: reference `Lecture1.CruiseClimb` has the same name but its loop is the
  back-calculation comparison (`LimPID`). The no-anti-windup run is
  `Lecture1.ClampingCruiseClimbTransient` with `y_max = 1e6`, `y_min = -1e6`.
- Catch-up 6d: `ClampingCruiseClimb` is the same harness with the reference controller; the
  reference `CruiseController` wires it as the `clamp` block, and the exact equation is in
  `Lecture1.ClampingGate`, written on `u` and `u_lim` instead of `control_error` and
  `limiter.y`.

## 07 Derivative and noise — 15 min

- Split: noisy sensor 2, step 7 5 (insert the noise, run at wd = 1, then wd = 0), two sines 2,
  near-pure derivative and the Nd sweep live on the students' loop 4, choosing the cutoff 2.
- The two-sines slide is the one that has to land; everything else is evidence. Trace the
  tangents on the projected plot with a finger.
- The noise is a deterministic sum of sines, so the committed fallback plots reproduce exactly.
  Mention it only if someone asks why it looks periodic.
- "Choosing the cutoff": the last paragraph of the note (filtered derivative as a loop with an
  integrator) is optional; skip it if short of time.
- Catch-up step 7: `NoisyCruiseLoop` is the reference loop with `noise` in place,
  `NoisyCruiseStep` its bench, `NoisyCruiseTransient` runs it. Its defaults differ; set
  `Td = 0.5`, `wd` per run 1 then 0 (its `xd0` follows `wd`), `T_max = 1e6`, `y_max = 1e6`,
  `y_min = -1e6`, `stop = 40`, and `Nd` = 100, 20, 5, 2 for the sweep.

## 08 Tuning — 18 min

- Split: step test and the three tables 12, step 8 and robustness re-runs on the students'
  `TuningCruiseStep` 4, the trap 2.
- Most cells in the lecture: run them in order and let the tables do the talking.
- Ziegler-Nichols: read Ku and Pu from the executed notebook (about 115 and about 2.2 s). If the
  run squares off against the torque limit instead of oscillating cleanly, say so: that is relay
  limit-cycling.
- "All three" slide: about ninety seconds for the hands-up discussion.
- Saturation trap: show the left panel first with the right covered, then uncover it. Have
  `dyad/Lecture1/CruiseLoop.dyad` open.
- Catch-up step 8: `HandsOn.GradeCar` carries `m` and `theta_e` with the same defaults. Reference
  runs are notebook 08's `tuned` cell: `CruiseLoopTransient` with both switches on, the
  Ziegler-Nichols gains and the limits lifted.

## 09 Discretization — 8 min (demo only)

- No build. Students watch; their own controller stays continuous.
- The sample-time sweep ("same gains, at four sample times") carries the point.
- Have open: reference `SampledCruiseLoop` (`dyad/Lecture1/SampledCruiseLoop.dyad`) for "the
  sampled loop, in Studio". Students do not reproduce it.
- Notebook: `notebooks/lecture01/09-discretization.ipynb`, cells "The sample-time sweep" and "The
  fixes".
- Strobe-light slide: tell it as a story, not a diagram; walk a couple of steps while you do.
- Two-fixes slide: look at the re-tuned curve, then gesture from memory to where the continuous
  design sat.

## 10 Wheel and slip — 11 min

- Split: the wheel 1, beats one and two 2 (recaps of hands-on steps 08 and 10, take them fast),
  why it runs away 1, `SlipCar` reminder and step 10 4, ice patch and fix 2, close 1.
- Beat three, cruise control on ice, is new and is what students remember. It runs on the loop
  they just swapped the plant into.
- Notebook: `notebooks/lecture01/10-wheel-and-slip.ipynb`, cells 1 to 5 ("The wheel appears",
  "Wheelspin", "The friction curve", "Cruise control on ice", "What a friction-aware limit would
  have done").
- Wheel slide: read the rise time and overshoot from cell 1's output and compare with section 05.
  `WheeledCruiseStep` on `HandsOn.WheeledCar` is a demo, not a student build.
- Beat one: rather than re-explain the wheelspin, ask someone who finished step 10 what happened.
- Have open: `SlipCruiseLoop` (`dyad/Lecture1/SlipCruiseLoop.dyad`) for step 10.
- Catch-up step 10: reference bench `SlipCruiseIcePatch`, run by `SlipCruiseTransient`. Set
  `Td = 0.5`, `wd = 0`, `patch_start = 4`, `patch_duration = 8`, `stop = 45`.
- If the wheel speed stays on the car's speed: `friction.y` is not wired to `plant.mu_scale`.
- If there is a violent slip at t = 0: `initial plant.wheel_inertia.w` is missing.
- Close: point students to the notebooks and `docs/`.
