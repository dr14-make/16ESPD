---
title: Lecture 1 hands-on — tutor guide
---

[← Vehicle Systems & Components](../../index.html) · [Student guide](./) · [Projector deck →](../../handson-01/index.html){target="_self"}

# Lecture 1 hands-on: tutor guide

What to say, how long each part takes, where students stall, and the answer models

Students follow the [student guide](./): it holds every instruction, the theory in its **Why** boxes, and the checkpoints. The [projector deck](../../handson-01/index.html){target="_self"} shows one slide per step: the goal, the finished model, the checkpoint numbers and the time budget. This page is for you. Read it once before the session and keep it open beside the deck; each slide's speaker note links to its section here.

## Before the session {#before}

- **Screens.** Deck on the projector. On your laptop, VS Code with the Dyad Studio extension and an empty folder ready. Open **presenter mode**: hover over the bottom left of the slide, click the presenter icon in the nav bar; notes, the next slide and a timer in the same tab.
- **On the board:** the link to the student guide, `handson/lecture-01/` on the course site.
- **Where this sits.** The first of two sessions on one car. Today students build it; the next session, [Lecture 1](../../lecture-01/index.html){target="_self"}, puts a cruise control on it, and its slides link back into the guide's Why boxes wherever they need the physics. Its run sheet (`docs/lecture-01-run-sheet.md`) and build plan (`docs/lecture-01-live-build-plan.md`) say what it expects from today: a `MyCar` with `Car` and `GradeBody`, under the guide's instance names.
- **Explaining.** Each step's Why boxes are what you teach from the front, before the room builds; the *Details* boxes hold the derivations with the numbers filled in, ready to copy onto the board. The deck has no theory slides: put the guide on the projector for a Why box when you want it on the wall.
- **Deep links** into the deck are by name, the same names as the guide's anchors: `#/car` is step 05, `#/standing-start` step 10.
- **Plain words.** Most students meet torque, state, time constant and slip here for the first time. Say the plain meaning the first time you use each one: torque is a twist in N·m; a state is what the simulator must remember from one instant to the next; a bench is a small model that feeds a part a test input so it can run; an analysis is the instruction "simulate this for so many seconds".

### Time

About 225 minutes, theory included: 48 for Part 1, 171 for Part 2, 5 to hand in. Plan a break after step 05, or split into two sittings there.

| Step | Min | Split |
| --- | --: | --- |
| Opening and What you are looking at | 15 | why we are here, what we build, the three ideas, the map |
| Create your library | 15 | downloads can take much longer: start them first, talk through the opening while they run |
| Put it on GitHub | 5 | runs in parallel with the download if students publish as soon as the folder exists |
| 01 Tour | 13 | 10 building, 3 on the two kinds of wire at the end |
| 02 Engine | 27 | 7 of theory, 20 building: the longest step, the first bench, analysis and plot |
| 03 Driveline | 13 | 3 for the formula, 10 building |
| 04 Body | 21 | 6 of theory (four forces, drag, rolling resistance), 15 building; the drag settings take longest |
| 05 Car | 27 | 7 of theory, 8 assembly, 5 bench and analysis, 5 run and plot, then "246 is wrong" |
| *Break* | | |
| 06 Wheel inertia | 12 | 2 for the hidden mass, 10 copying three models and adding one part |
| 07 Grade | 13 | 3 for the slope, 10 building |
| 08 Tire curve | 20 | 5 for slip and grip, 15 pasting, reading and plotting |
| 09 Slip wheel | 15 | paste, then read the relations; nothing runs |
| 10 Standing start | 23 | 3 for the two limits, 20 to build: 10 parts, 5 ports, 15 wires, a bench |
| Hand in | 5 | |

**If time runs short:** cut from the back. Steps 02–06 give everyone a working car; 07–10 are about the wheel spinning on a slippery road. Do not cut the opening: it says why the rest of the session matters. Lecture 1 needs `GradeBody` (step 07) in section 01 and `SlipCar` (step 10) in section 10; anyone who stops earlier catches up from the guide's *Stuck?* boxes.

### Answer models

Every model a student builds is in the course library, `dyad/HandsOn/`, under the guide's names; in the reference library they sit in a sub-library `HandsOn`, in a student's at the top level. Each guide step has a *Stuck? The full model* box with the code.

| Step | Components | Test or analysis |
| --- | --- | --- |
| 01 | `HandsOn.Tour` (the students call theirs `Engine`) | — |
| 02 | `HandsOn.Engine`, `HandsOn.EngineStep` | `HandsOn.EngineStepTransient` |
| 03 | `HandsOn.Driveline` | `HandsOn.TestDriveline` |
| 04 | `HandsOn.Body` | `HandsOn.TestBody` |
| 05 | `HandsOn.Car`, `HandsOn.CarFullThrottle` | `HandsOn.CarFullThrottleTransient` |
| 06 | `HandsOn.WheeledDriveline`, `HandsOn.WheeledCar`, `HandsOn.WheeledCarFullThrottle` | `HandsOn.TestWheeledDriveline`, `HandsOn.WheeledCarFullThrottleTransient` |
| 07 | `HandsOn.GradeForce`, `HandsOn.GradeBody` | `HandsOn.TestGradeForce`, `HandsOn.TestGradeBody` |
| 08 | `HandsOn.TireFrictionCurve`, `HandsOn.TestTireFrictionCurve` | `HandsOn.TireFrictionCurveSweep` |
| 09 | `HandsOn.SlipWheel1D` | `HandsOn.TestSlipWheel1D` |
| 10 | `HandsOn.SlipCar`, `HandsOn.SlipCarStandingStart` | `HandsOn.SlipCarStandingStartTransient` |

`HandsOn.GradeCar` is Lecture 1's first build, not today's. Every checkpoint number is asserted by the test cases in the `metadata` of these files, against the reference curves in `test/snapshots/HandsOn/`. `Vehicle.CarPlant`, the course model, reads the same 246.39 km/h as `HandsOn.Car`.

### Opening {#opening}

**Say:** something everyone has seen, cruise control. You set 90 km/h; a hill comes; the car slows a little and is back at 90. Nobody programmed "if hill, then more throttle". Something measured the speed, decided it was too low and pressed the pedal harder, again and again: a control loop, and the next lecture is about it. But think of a new driver in an unfamiliar car: they press too hard and the car jumps, let go and it slows. They do not know the car yet. A controller has the same problem; it is designed for *this* car. So today we learn the car.

**Ask the room:** you press the pedal down hard. Does the car reach full speed instantly? *(No. First a short pause, then the push builds up, and the faster the car goes, the slower it gains speed. Today's numbers: the engine waits 0.3 s, then needs another 0.3 s for about two thirds of its push; the car reaches 100 km/h after 23.6 s and is within 1 % of its top speed only after 143 s.)*

**Ask the room:** what is different on ice? *(The wheels spin instead of gripping. Keep the answer: it is the last step today, and the reason cruise control on ice is dangerous.)*

**Point at** the car chain on the title slide: four parts in a row. The pedal asks the engine for torque; the engine delivers it, a bit late and a bit slowly; the gear and wheel turn the twist into a push; the body is the mass, with air and tires holding it back; a speedometer reads the speed. Each box is one step, built in this order, and at step 05 the boxes join and the car drives. Come back to this picture at the start of every step: students lose interest when they do not know what a formula is for.

**Say:** we work this way all day: before you build each part, we work out on paper what it must do, then your model has to agree. 246 km/h is the top speed flat out (150 N·m) on a flat, dry road; the run shows 246.39 after 300 s. 10 km/h is *not* a top speed: it is where the car is 5 s after a full-throttle start on a road with 0.2 of dry grip, 10.12 km/h while the tire surface spins at about 1500; dry, the same start gives 21 km/h. Step 05 is the milestone: if your car makes 246, the paper and the model agree, and you have built the car Lecture 1 puts a PID controller on.

**Say:** four words describe any system. The **input** *u* is what we choose to change, the pedal. The **disturbance** *d* changes it without asking: hills, wind, luggage, ice. The **state** *x* is what it remembers from one moment to the next, the speed: know it and what the pedal and road will do, and you can predict the next second without the history. The **output** *y* is what we measure, the speedometer. *Ask:* is a hill an input or a disturbance? *(It pushes on the car like an input, but nobody chose it; who decides is the difference.)* In steps 09–10 the car gets a second state, the wheel's own speed: that is what lets the wheel spin on ice.

**Say:** keep the names the guide gives you, `engine`, `car`, `v_kmh`: the checkpoints and the plot commands use them, and so does Lecture 1. A renamed part changes its signal names, and the plot command no longer finds them. Quickest fix: rename it back and save.

## What you are looking at {#ui}

**Say:** Dyad Studio is an add-on for VS Code. Students draw or write models in the Dyad language; Dyad translates them into Julia and runs the simulation there. Nobody writes Julia today beyond a few lines copied from the guide to plot. Then the three ideas, and the guide's *Why parts, not arrows* box: in a block diagram someone decides that speed causes force; physics does not. A damper relates force and speed whichever side pushes. In Dyad you write the law once and connect parts; Dyad decides the direction. Simulink is the block-diagram tool inside MATLAB; Modelica is the older language Dyad follows.

**Point at** the callout in the three ideas: you can only simulate a component whose inputs are all driven. Students hit this in step 02 and ask why they cannot just run the engine: nothing says what its torque command is.

**Do it live:** open the Dyad sidebar from the activity bar, walk the four panels, Actions, Components, Analyses, Notebooks, and click each control on the map as you name it. The ⇄ is the button they will use most and the easiest to miss. Saving compiles; if an analysis does not appear, **Dyad Compile** under **Julia Commands**, bottom right. A good compile ends in a green **SUCCESS** in the terminal. Ignore the tangled plot in the screenshot: step 02 explains it.

**The press-▷ box,** if the room wants it: collect equations, check equations = unknowns, simplify, solve in time. The body of step 04 is the example. The "not balanced" error almost always means an input nobody drives or a part not tied to ground: point back here when it happens in step 02. Euler's step is the simplest way of stepping in time; real solvers are more accurate and pick their step themselves.

**Where students stall:**

- **Editing files in `generated/`.** Say it twice: Dyad rewrites that folder on every compile.
- **The + search finds nothing:** the three standard libraries were not imported; send them to *Create your library*.

## Create your library {#library}

**Say:** a new library starts almost empty. The engine, gear, wheel and mass we use live in three standard libraries, so add them now: **Import Library**, three times, into the `MyCar` folder. Then Plots from the REPL.

**Timing:** the guide budgets 15 minutes, but the download can take much longer on a slow network. If students did not do it beforehand, start it first thing and talk through the opening and the map while it runs. After step 1 VS Code reopens in the new folder and the terminal prints for several minutes. The template's example models under `MyCar` are harmless.

**Where students stall:**

- **Skipping the imports.** Step 01's search for `FirstOrder` finds nothing, or code naming `RotationalComponents` does not compile.
- **A folder that already has files in it, or a name with a space.** The name must be `MyCar`: every plot command starts with `MyCar.`.
- **A red error during the download:** almost always the network or a full disk. Pair the student with a neighbor; at the break, run `using Pkg; Pkg.instantiate()` in their folder's REPL to retry.

## Put it on GitHub {#github}

**Say:** before we build anything, put the empty library on GitHub: that is `main`, your starting point. Then a branch `handson-01`; everything today goes there. At each checkpoint, commit with the step's name and sync. At the end, a pull request: that is how you hand in. If VS Code asks whether to stage all changes, **Yes**.

**Where students stall:**

- **Committing on `main`** because the branch was never created: check the status bar of a few screens. If nothing was synced yet, create the branch now and the commits come along. If the steps were synced to `main` already, the pull request will show nothing new; sort it out after the session.
- **No Publish to GitHub button:** VS Code is not signed in. Accounts icon, bottom left → Sign in with GitHub. Git missing altogether: the intro deck's install list.

## 01 Tour {#tour}

**Say:** the first thing you build is the front half of the engine. It is small because this step is about the editor, not the physics. `PadeDelay` holds a signal back 0.3 s; `FirstOrder` follows its input smoothly, 63 % of a change in 0.3 s. Step 02 explains both.

**Do it live, first, slowly:** Components → right-click `MyCar` → **Add Component** → `Engine`. **+** (fifth icon in the canvas toolbar) → `PadeDelay` → click the block → pencil ✎ → `delay` → `n` 6, `m` 5, `delayTime` 0.3. Then let them do `FirstOrder` as `lag` with `T` 0.3, wire, save. Wait until most hands are done before you show ⇄, then do the round trip live: `T = 0.5` in the code, save, ⇄, click `lag`, the panel shows 0.5, set it back. That is where most of the room sees that the two views are one file.

**Point at** the parameter panel, then the code line: `n`, `m`, `delayTime` appear in both; the panel is editing that line. Higher `n` and `m` imitate a pure delay more closely; students just type them in. Nothing in the diagram is hidden from the code, and the reverse holds for everything except equations, which have no picture: from step 07 on they write those in this view.

**Then the guide's *Why two kinds of wire* box.** A signal is a message, "the driver wants 40 N·m", one way. A mechanical joint is a bolt: the wheel does not "send" a force to the body, they move together. That is why a body joins a driveline with one wire. **Ask the room:** which kind is the wire you just drew? *(A signal: one number, one way.)*

**Where students stall:**

- **Wiring `u` to `y` backwards, or dropping the wire on the block body** instead of the port. A wire only exists if it shows as a `connect`: check with ⇄.
- **"My name is `Engine`, the screenshot says `Tour`."** The reference library already has a finished `Engine`, so the two-block copy needed another name. Theirs stays `Engine`.
- **`{^delay}` tags and a `metadata` block** in their file: positions and wire routes. Do not edit them.

**Checkpoint:** nothing to run. Commit `Step 01: tour`, then **Publish Branch**, the branch's first upload.

## 02 Engine {#engine}

**Say:** a chain of three boxes: the first makes the torque late, the second slow, the third caps it at 150 N·m. Then the guide's *Why late, slow and limited* box: read the pedal-response picture left to right. At 0.5 s we ask for 200 N·m, more than the engine can give, on purpose: a test should exercise every block it tests. For 0.3 s nothing; then a curve; at 150 cut flat.

**Why the delay and lag are there, for you:** Lecture 1 tunes its controller with Ziegler–Nichols and Cohen–Coon, and both need a car that reacts late and slowly. Without the delay and lag the car is first order, one state, its speed: a proportional controller never makes it swing back and forth however hard it pushes, so Ziegler–Nichols has nothing to measure; Cohen–Coon models the car as a lag plus a delay and divides by the delay. With no lag there is little overshoot, and the derivative part of PID has nothing to do. The step's last Why box says this in plain words; Lecture 1 needs nobody to know the recipes today.

**If the room asks what "order" means:** a state is a quantity the simulator must remember because it changes gradually. The order is the number of states, about one per thing that stores energy or memory. First order: one state, τ·d*y*/d*t* + *y* = *K*·*u*, 63 % after one τ, never overshoots or oscillates — the engine's lag alone, the car's speed against drag (67 s at 100 km/h), a cup of tea cooling. Second order: two states, a mass on a spring, a suspension; it can oscillate. Higher order: a chain of lags, an S-shaped start, and under a controller it *can* oscillate, which the PID lecture needs. A true delay is strictly infinite order; Dyad replaces it with 6 states, and with the lag's 1 the engine alone has 7.

**Physically:** the 0.3 s delay lumps the whole chain from pedal to burning fuel. A student who says injection is much faster is right. The 0.3 s lag is the intake manifold filling; the Lecture 2 hands-on builds that manifold for real. The floor of 0 means this engine cannot brake. **Ask the room:** what does a cruise control on this car do downhill? *(Nothing useful: it can only cut the torque to zero. Real cruise controls also use the brakes.)* **Ask:** delay and lag are both 0.3 s; how do you tell them apart on the plot? *(Delay: flat. Lag: starts at once, but gradually.)*

**Do it on the board,** from the *Details* box, one line at a time: 0.8 s, 97 N·m, 1.22 s. "ln" undoes e<sup>x</sup>. The lag aims at the full 200, not 150; the limiter only cuts afterwards. Then the lag: a bathtub filling from a faucet that weakens as it fills; you get close quickly but never quite arrive. **They get wrong:** "the time constant is how long it takes to get there". It is how long to get 63 % of the way.

**Say:** we worked out these numbers before opening Dyad. In ten minutes you read the same three off your own plot; if they match, your engine is built right.

**Order on the guide:** A open · B parameters · C limiter, torque source and ports · D bench · E run and plot. You do not start a new component: open step 01's `Engine` and keep adding. Walk the room after C: an engine wired wrong makes D impossible, and the **Problems** tab should list nothing for `Engine`. Then the *support port* box: hold a drill by the battery and pull the trigger; your hand is the `Fixed` block. The sign rule looks backwards at first, and a wrong sign is the most common cause of a car that drives in reverse.

**Define each value once:** `T_max = 200` on the engine then changes the ceiling in one place. `theta_e` is structural: the delay block computes its coefficients from it at compile time. If the panel offers no structural option, paste the guide's line.

**Where students stall:**

- **Drawing the bench inside `Engine`.** Say out loud that the bench is a new component of its own.
- **`support` left unconnected in the bench:** the compile error talks about an unbalanced system; the fix is the `Fixed` block wired to `support`. **Ask:** why `y_min = 0`? *(Without it a negative command twists the shaft backward: the engine would brake, or spin the disc in reverse.)*
- **The analysis name.** The plot command calls `MyCar.EngineStepTransient()`; if Studio picked another name, change the word after `analysis`. If it does not appear in Analyses: **Dyad Compile**.
- **After ▷ a Plots pane draws every signal at once,** unreadable: expected. The delay's six internal states swing into the thousands. Pick one signal by name with `idxs`; the first `using Plots` in a session takes a while.
- **"`MyCar` not defined"** in the REPL: `using MyCar` first, and if the library got another name, use it in both places.
- **A different curve:** flat at 200 instead of 150 → `y_max` is not `T_max`; rises at 0.5 s → the delay is not wired in; another shape → `T = tau_e`, the step's `height = 200` and `start_time = 0.5`.

**The Padé box, for a student who knows Laplace transforms** (skip otherwise): a delay θ is e<sup>−sθ</sup>; a Padé approximation replaces it with a ratio of polynomials, the simplest (1 − sθ/2)/(1 + sθ/2). `PadeDelay(n = 6, m = 5)` has a 6th-order denominator and a 5th-order numerator, matching e<sup>−sθ</sup> to order 11; because the numerator is lower order, a step cannot pass straight through before the delay has elapsed. Say "the delay stand-in" if Padé sounds foreign.

**Where the numbers come from:** the board numbers are the formula; the run, `HandsOn.EngineStepTransient`, shows about 2 N·m of wiggle before 0.8 s, 6.2 N·m at 0.8 s, 97.5 N·m at 1.0 s, 150 N·m from 1.22 s, `engine.delay.y` peaking at 208.1 near 0.9 s before settling at 200 (the stand-in overshoots; the limiter hides it), and `load.w` at 306.0 rad/s at 3 s. Within about 1 N·m of the board counts as a match. With *J* = 1 kg·m², the disc's angular acceleration in rad/s² is the torque in N·m.

## 03 Driveline {#driveline}

**Say:** two parts and four ports; it turns the engine's turning into the car's straight-line motion. Then the guide's *Why F = T · i / r* box: a bicycle in a low gear trades speed for force; a wrench turns force at the handle into twist, and the wheel is a wrench the other way round, so a bigger wheel means less force.

**They get wrong:** "150 N·m is a weak engine". Do the multiplication out loud: almost 2 kN at the road, the weight of 200 kg.

**Ask the room:** the wheel "rolls without sliding"; which step breaks that? *(Step 08 builds a tire that can slip, and in step 10 the wheel spins on snow while the car crawls at about 10 km/h.)*

**Point at** the wheel block: gray circle in, green square out. The port shape tells rotational from translational, and only like wires to like. `spline` from the engine, `flange` to the body, `support_r` the gearbox housing, `support_t` the road. Parameters `i` (Real) and `r` (Length); the parts take the *names*.

**Where students stall:** forgetting the reaction paths. `gear.support` and `wheel.support_r` go to `support_r`, `wheel.support_t` to `support_t`; the car grounds them in step 05.

**Where the numbers come from:** no bench and no analysis today: it is checked when the car runs in step 05. The students' check is that it saves with nothing in **Problems** and has the four ports. The 0.92 m/s² is the reference test `TestDriveline` (100 N·m into the driveline, 1400 kg on the flange): it expects 0.9217 m/s² and 9.2 m/s after 10 s. The engine speed at 90 km/h, 3080 rpm, comes back in step 05 to explain why 246 km/h is unrealistic, and in the Lecture 2 hands-on.

## 04 Body {#body}

**Say:** the car's 1400 kg and the two forces that hold it back on a flat road; hills come back in step 07. `Body` is one new component that becomes a single part in step 05's car. Then the *four forces* box: point at each arrow and give it one sentence. Whenever you leave something out of a model, state it: the course lectures' *O*<sub>aux</sub> is left out here.

**On drag:** a hand out of a car window at 30 km/h, then at 120: four times the speed, sixteen times the push. **Ask the room:** at 90 km/h, which is bigger, drag or rolling resistance? *(Drag, 236 against 165. At 30 km/h it flips: 26 against 165.)* The control remark in the box, in plain words: settings that work well at 90 km/h will not work as well at 130, because the car answers the pedal differently there.

**On rolling resistance:** the tires cost 1.2 % of the weight, about 165 N on 13 730 N. Parameter against signal is the one Dyad idea here: the slope is a signal so a hill can appear halfway through a drive.

**Point at** the two `Constant` blocks in the goal picture: rolling resistance takes its coefficient and the slope as wires, not typed numbers. Unwired, the model is incomplete. Drag and rolling push against the road and the air, so their supports go to `ground`.

**Where students stall:**

- **A positive `f_nominal`.** Drag then pushes the car forward and it accelerates without limit. If a car in step 05 reaches absurd speeds, this is the first thing to check.
- **`v_nominal`:** "why 30?" It cancels; it must only not be zero. Any speed gives the same curve; 30 m/s (340.2 N) is a round number.

**Ask the room:** why parameters instead of 340.2 and 13729? *(13729 is m·g. With names the next reader sees ρ, C<sub>d</sub>A and m, not unexplained numbers, and `m` feeds the mass and the rolling resistance, so changing the weight changes both.)*

**Where the numbers come from:** students run nothing here; their body first moves in step 05. The 500 N numbers are the course library's `TestBody`: 0.357 m/s² at the start, 29.78 m/s at the end. *g* = 9.80665 gives 164.75 N, not 164.8; it does not show in any result.

## 05 Car {#car}

**Say:** the milestone. The parts become one car, and every controller in the next lecture drives it: when Lecture 1 says "plant", it means this car. *Terminal speed* is the speed where the car stops getting faster; *full throttle* asks for the 150 N·m ceiling the whole time.

**Then the force balance box.** **Point at** the *T*: it is what the engine delivers after its delay, lag and limit, not what the driver asks for. **Point at** the *v*²: the car is nonlinear, which matters next lecture. Students never type the equation: the joint rule writes it.

**The nine numbers.** **Ask the room:** which of these will make the car hardest to control? *(Take two or three guesses. The delay and the lag: a controller that sees the car's reaction late tends to overreact.)*

**Do it on the board:** the top speed, the most important calculation of the day; take your time. Top speed means the car stopped getting faster, so the left side is zero. Then the cruise table: 31.1 N·m holds 90 km/h, 40.1 holds 110. The next lecture's controller finds 31.1 by itself, without being told. **Ask the room, before the time constant:** 246 km/h from a 150 N·m engine — does anyone believe that? *(Leave it open; the last box of the step answers it.)*

**The time constant:** it takes two and a half minutes flat out to get within 1 % of top speed, because drag is weak at low speed and little pulls the car toward its final speed. 67 / 0.3 ≈ 220, which the box rounds to 200. **Flag forward:** in Lecture 1 a controller takes this car from 90 to 110 km/h in a few seconds with the same engine, using feedback. Remind the room of the 67 s then.

**Assembly:** your own `Engine`, `Driveline` and `Body` from the bottom of the **+** list. `vsensor` is a speedometer in m/s, `to_kmh` turns it into km/h, once, at the model's output, as the lecture model does. `rot_ground` and `trans_ground` fix the "other ends" steps 02 and 03 left open: one for turning parts, one for straight-line parts.

**Where students stall:**

- **Leaving out `initial car.body.mass.s = 0`.** Position appears in no force, so it feels optional; without it the start is not fully defined and the model does not start.
- **`stop` shorter than 300 s.** The run stops on the way up and the student thinks the terminal speed is wrong.
- **▷ does not offer to create the analysis:** paste the `analysis … end` block from the guide. Not in **Analyses**: **Dyad Compile**.
- **A number off:** the guide's order: `f_nominal` sign, then `i` and `r`, then `T_max`, then `stop`.
- **The name is not defined in the REPL:** the analysis must be `CarFullThrottleTransient` and the library `MyCar`, or the student's own names in both places.

**Say, on the plot:** the course model Lecture 1 uses, `CarPlant`, also reads 246.39 km/h at 300 s, and at 800 s the two agree to within 0.0001 km/h. You built the lecture's car.

**Then *Why 246 is still wrong*.** Point at the torque curve in this order: blue, our engine; red, a typical real one, same peak but only in the middle; the shaded band, 90–130 km/h, where Lecture 1 drives and the two agree; the mark at 8430 rpm, where the drawn red curve is down to about 95 N·m — an illustration, not a measurement. **They get wrong:** treating a simulation result as a measurement. **Ask the room:** what would you add to get a believable top speed? *(A torque that depends on engine speed: a torque curve, where the Lecture 2 hands-on starts.)*

**Where the numbers come from:** 246 km/h and the cruise torques are the board arithmetic. 23.6 s, 143 s and 246.39 km/h are read off `HandsOn.CarFullThrottleTransient`; more points on the same curve for an early check: 21.2 km/h at 5 s, 43.6 at 10 s, 197.5 at 60 s. The rpm: *v* / *r* × *i* × 60 / 2π, with 60 / 2π ≈ 9.55: 3080 rpm at 90 km/h, 4450 at 130, 8430 at 246.

**Break here,** or split the session.

## 06 Wheel inertia {#wheel-inertia}

**Say:** until now the wheel had no weight of its own. Now the model tracks its spin, still tied to the car's speed; step 09 removes that link, which lets it spin on ice. We do not change the old car: we copy it and change the copy, so we can compare.

**Ask the room first,** before the hidden-mass box: how much later will the car reach 100 km/h with a heavy wheel? Most guess a lot. *(0.2 s out of 23.6. Not every added detail matters; knowing which is part of modeling.)*

**Where students stall:**

- **Forgetting `initial car.driveline.inertia.phi = 0`.** The wheel's angle is a new state and needs a start.
- **Curves differing more than the checkpoint:** `J_w` is not 1.0, or the old direct wire `gear.spline_b → wheel.spline` is still there. A final speed other than 246.39 is a problem in the parts copied from steps 02–05, not in the new wheel.
- `plot!`, with the "!", adds to the same picture. Their line colors may differ from the guide's.

**Where the numbers come from:** *J*/*r*² = 1 / 0.0961 = 10.4 kg, 0.74 %, so 23.6 × 1.0074 ≈ 23.8 s. The run, `HandsOn.WheeledCarFullThrottleTransient`: 43.27 km/h at 10 s against 43.59, 100 km/h at 23.8 s, 246.39 km/h at 300 s.

## 07 Grade {#grade}

**Say:** until now the road was flat, `incl_const` set to 0. A hill that starts mid-drive needs a force that follows a changing number, and no ready-made part gives the pull of gravity along a slope, so you write one. *Grade* is how a road sign writes steepness: 10 % is 10 m up per 100 m along the ground. Then the *slope* box; draw the triangle on the board. "Windup", in the box's last paragraph, is a controller problem Lecture 1 explains; nobody needs it today.

**If asked "why not sin 0.10?":** for small slopes sin α ≈ tan α, 0.0995 against 0.100, so it barely matters at 10 %; at 50 % it does. On the slope only the "into the road" part counts for rolling resistance: 165 × cos α = 164 N, the number in the 2023 N sum.

**Point at** `sin(atan(grade))`: a 10 % grade is tan α = 0.10, not α = 0.10. And the missing minus: a force source pushes on the body with −`f`.

**On `extends`,** the guide's *Details* box: start from a model and add to it. `PartialForce` already has two ports and a force `f`; the student writes one line. Three of the four flattened equations are inherited. Flatten `GradeForce` once live so the room sees the real thing; the guide's listing is written by hand from the library sources, and Studio may format it differently, with inherited names fully qualified.

**What students end with:** `GradeForce` (code) and `GradeBody` (a duplicate of `Body` with a `grade` input). Nothing runs in this step; the check is that both save with nothing in **Problems**. Short on time: paste `GradeForce` from the *Stuck?* box and read the equation. One `grade` input feeds both the rolling resistance and the gravity force, so the two never disagree about how steep the road is; `m = m`, `g = g` reuse the body's own values, so the mass is set in one place.

**Where the numbers come from:** 1400 × 9.81 × sin(arctan 0.10) = 1366 N; `TestGradeForce` reads 1366.1 N and a free 1400 kg mass slowing at 0.976 m/s². `TestGradeBody`, case `climb`: 500 N up a 2 % climb from 10 m/s, 0.0164 m/s² at the start and 10.16 m/s after 10 s. **Close:** 1366 N on a 10 % hill against 1935 N flat out; at 130 km/h the hill takes all of it.

## 08 Tire curve {#tire-curve}

**Say:** a tire grips by slipping a little as the tread deforms; up to a point, more slip means more force. Past it, it slides, and grip drops. *Slip* is how much faster the tire surface moves than the car, as a fraction of the car's speed; *grip* is how hard the tire can push, as a fraction of the weight pressing it down. The ideal wheel's assumption is in its name, `IdealRollingWheel`; on a dry road it makes almost no difference, so it is easy to miss until it fails.

**Ask the room:** what else have we quietly assumed? *(A straight road. A constant mass. An engine that gives 150 N·m at any speed, which step 05 flagged. Thirty seconds on the answers.)*

**Walk the curve** in the *slip and grip* box: the rising part is normal driving, what cars are designed for; the peak is a push equal to the full load; past it, down to 0.7 sliding. The orange snow curve is every height × 0.2. The red dashed line at μ = 0.28, the most the engine can ask (1935 / 6865): under the whole dry curve, over the whole snow curve; step 10 comes back to it. At standstill *v* = 0 and the slip formula breaks, so the model divides by at least 0.5 m/s; step 09 calls that floor `v_eps`. Anti-lock brakes work on the braking side; a later lecture covers them.

**The curve's construction,** the *Details* box: real tire curves come from measurements; here four numbers draw the shape, joined by one small cubic flat at both ends, used once for the rise and once, stretched and flipped, for the fall. A straight-line curve would look almost the same and simulate worse. Industry uses fitted models with many more parameters, Pacejka's with B, C, D, E and in full versions dozens more for load, camber and combined slip, but the shape is the same: rise, peak, fall to sliding.

**What students make:** `TireFrictionCurve` pasted as code, a bench `TestTireFrictionCurve` sweeping κ from −1 to +1 in 2 s, an analysis `TireFrictionCurveSweep`, a plot. They spend the time reading the code and on the plot, not typing. A pair in round brackets in `idxs` plots the first signal against the second.

**Where students stall:**

- **`TireFrictionCurveSweep` not defined:** the analysis got another name; change the word after `analysis`.
- **Peak not at 1.0:** the paste is incomplete, or `mu_A` is still 1.2 from *Try it*: set it back before step 09.
- **A plot against time:** the round-bracket pair is missing in `idxs`.
- **"The peaks are a spike near zero":** the axis runs from −1 to +1; that is correct.

**Point at** the right of the peak: more slip gives *less* force. That is why step 10's wheelspin keeps growing once it starts. The PID lecture's last section puts a cruise controller on this curve.

**Where the numbers come from:** the curve's own parameters, `sAdhesion = 0.04`, `mu_A = 1.0`, `sSlide = 0.12`, `mu_S = 0.7`. `TestTireFrictionCurve` asserts −0.7 at κ = −1, −0.85 at −0.08, 1.0 at 0.04 and 0.7 at +1. Dry flat out the curve reaches 0.28 at κ ≈ 0.008 (0.8 %, "about one percent"); cruising at 100 km/h, μ = 0.067 at κ ≈ 0.002. At κ = 0.02, μ ≈ 0.69.

## 09 Slip wheel {#slip-wheel}

**Say:** the ideal wheel forced the wheel's spin times its radius to equal the car's speed. That is the assumption we drop. The difference is slip, and step 08's curve turns it into force. Paste, then read: the guide walks through every relation. Dividing by the car's speed makes slip relative; `v_eps` = 0.5 m/s, 1.8 km/h, keeps it finite at a standstill. `F_z` is half the car's weight, 6865 N. The last line is the same push acting back on the wheel as a braking twist.

**Where students stall:**

- **The sign on `flange.f`.** Wrong, and the tire pulls the car backward: the first thing to check if step 10 looks strange. Dyad counts a force positive *into* a component; the tire pushes the car forward, so it writes `flange.f = -F_x`.
- **"`curve` has no wires":** correct. It is connected by `curve.kappa = kappa` and `mu = mu_scale * curve.mu`, not by `connect`. Both are valid.
- **The paste does not compile:** step 08 must be saved in the same library; `SlipWheel1D` uses `TireFrictionCurve()`.

**Where the numbers come from:** the reference test `TestSlipWheel1D`, which students do not run. It drives the wheel with 600 N·m for 5 s, a 1 kg·m² wheel and a bare 1400 kg mass, no drag, no rolling. Slippery (`mu_scale` 0.2): slip 135, car 3.43 m/s (12.4 km/h). Dry: slip 0.0076, car 6.86 m/s (24.7 km/h). A slip of 135 means the tire surface moves 136 times as fast as the car. The guide's *Why the slippery road gives less push* box answers "why dry is 0.0076" and "why slippery is slower".

## 10 Standing start {#standing-start}

**Say:** every part in this car is one you already have; only the wiring is new. The new wheel is the road contact, its `flange` straight to the body. This is a new car, `SlipCar`, not an edit of `Car`. Then the *two limits* box: the lower limit decides, and the table says which before anything runs. *Standing start* is full throttle from a stop; *wheelspin* the wheel turning much faster than the car moves.

**Order:** the car, its five parameters, the parts, the wires, then a separate bench. Fifteen wires: tell the room to tick them off on the guide's numbered table. **Point at** `r` used twice (tire and km/h gain) and `m` setting both body and axle load: one parameter each, so they cannot disagree; typed twice, changing one copy leaves the other wrong without an error. The wheel's surface speed is its spin times its radius; put it on the same axis as the car's speed, and wheelspin is the gap between the lines.

**Say, before anyone sees 1500 km/h:** the model has no rev limiter, so nothing stops the wheel; 1500 km/h at the tire is the engine at about 51 000 rpm. That follows from what we left out; it is not a bug. Say it now so nobody tries to "fix" it.

**Where students stall:**

- **Missing `initial car.wheel_inertia.w = 0`.** With slip, wheel speed is no longer tied to the car's, so it needs its own start.
- **`Problems` lists `SlipCar`:** compare the wires with the numbered table.
- **The car goes backward:** the sign on `flange.f` in `SlipWheel1D`.
- **Both lines together on the slippery run:** the bench's `friction` is still 1.0; set it back to 0.2.
- **`SlipCarStandingStartTransient` not defined:** rename the word after `analysis`.
- **The dry run:** `friction__k = 1.0` means "the `k` of the block named `friction`", for this run only. Or set `k` to 1.0 in the bench, save and run again.

**Close:** the run matches the two-limits table: on snow the tire reaches its limit before the engine does. Lecture 1 ends with this car under cruise control on an ice patch: the controller sees the speed falling, commands more torque, and produces what you just watched. That is the argument for traction control, and for the cascade control of Lecture 2, one controller inside another; nobody needs it today.

**Where the numbers come from:** the limits are arithmetic: 1400 × 9.81 / 2 = 6865 N; dry 6865, snow 1373, ice 343 against 1935, and 1935 / 6865 = 0.28, which the dry curve reaches at κ ≈ 0.0075 (step 09's test reads 0.0076). 21 km/h dry is step 05's car, which read 21.2 km/h at 5 s. The snow numbers are read off `HandsOn.SlipCarStandingStartTransient`, whose tests allow 0.1 km/h for the car and 0.5 for the wheel: after 1 s car 1.94 km/h, wheel 159.8; after 5 s car 10.12 km/h, wheel 1501. Dry after 5 s: 21.08 and 21.24 km/h. The bench picture in the guide is a `dyad render` of `HandsOn.SlipCarStandingStart` (dyad-cli 3.4.0), so it has no port names.

## Hand in {#hand-in}

**Say:** open a pull request from your branch into `main`, describe what you did and the numbers you got, and leave it open. A review comment is answered by fixing the model, committing and syncing on the same branch: the fix shows up in the same pull request.

**Where students stall:**

- **No yellow bar on github.com:** **Pull requests** → **New pull request**, base `main`, compare `handson-01`.
- **A missing commit** in the **Commits** tab: that step was not committed or not synced. Commit, sync, and it appears.
- **Merging their own pull request.** Nothing is lost, the commits are on `main`, but the review has nothing to comment on. Note who it was and sort it out after the session.

## Wrap-up {#wrap-up}

**Say:** go back to the first question of the day, how cruise control holds 90 km/h. You now have the car it has to drive, and you know how that car responds: late, slowly, against drag that grows with the square of speed, and on snow barely at all. **Point at** step 05 in the deck's last table: two independent methods, the equation on paper and the model you built, give the same number. Where a run did not agree, something in the model was wrong, not the arithmetic. Keep your `MyCar` library: Lecture 1 builds on it, and its slides link back to the guide's Why boxes whenever they use this physics.
