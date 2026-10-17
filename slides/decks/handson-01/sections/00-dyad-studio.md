---
routeAlias: dyad-studio
layout: cover
---

# Build the car in Dyad

<h1 class="!text-5xl !-mt-4 opacity-70">Lecture 1 hands-on</h1>

Vehicle Systems &amp; Components

From an empty library to a wheel spinning on a slippery road.

<div class="text-xs opacity-60 mt-12">

<kbd>→</kbd> <kbd>Space</kbd> next &nbsp;·&nbsp; <kbd>←</kbd> previous &nbsp;·&nbsp;
<kbd>O</kbd> overview &nbsp;·&nbsp; <kbd>G</kbd> go to slide &nbsp;·&nbsp;
presenter mode from the nav bar, bottom left

</div>

<!--
**Before the room fills.** Deck on the projector. On your laptop: VS Code with the Dyad
Studio extension, and an empty folder ready. Open **presenter mode** now: hover over the
bottom left of the slide, a small nav bar appears, click the presenter icon. You then see
these notes, the next slide and a timer in the same tab.

**What the tool is, in one line:** Dyad Studio is an add-on for the VS Code editor. Students
draw a model of the car out of parts, and it computes how the car moves over time
(*simulates* it).

**Where this sits:** the first of two sessions on one car. Today students build the car.
The next session, Lecture 1, adds a cruise control to it. Its slides link back here
wherever they need the physics.

**How the deck is laid out:** each step opens with a few theory slides, then the building
slides. Teach the theory from the front, then let the room build. Where a slide has a
formula, the notes have a *Derivation* list with the numbers filled in, so you can copy it
onto the board.

**Students follow the course page, not this deck.** Write the link on the board:
`handson/lecture-01/` on the course site. Every step there has a parts list, a screenshot,
numbered click-by-click actions and copy buttons for code. The deck is for you: what to
explain, what to show, where they get stuck.

**Timing:** about 225 minutes. Part 1 (everything up to and including step 01) is 48,
Part 2 (steps 02–10) is 171, handing in is 5. Plan a break after step 05, or split into two
sittings there.

**Jumping to a step:** add `#/` and the step's name to the deck's address, for example
`#/car` for step 05. The course page uses the same names with `#`, for example `#car`.

**If time runs short:** cut from the back. Steps 02–06 give everyone a working car; 07–10
are about the wheel spinning on a slippery road. Do not cut the next two slides: they
explain why the rest of the session matters.
-->

---

## Why we are here

<div class="grid grid-cols-2 gap-8">
<div>

You set cruise control to 90 km/h. A hill comes. The car slows down —
a little — and then it is back at 90.

Something **measured** the speed, **decided** it was too
low, and **pressed the pedal** harder. That something is a
*controller*, and designing it is what this course is about.

</div>
<div>

> **The catch**
>
> You cannot design how to drive a car if you do not know how the car reacts.
>
> How hard to press? How long before the car answers? What if the road is icy?
>
> So before any controller, we **build the car**: each part explained first,
> then built and tested in Dyad.

</div>
</div>

<!--
**Say:** Let us start with something everyone has seen: cruise control.
You press a button and the car holds 90 kilometers per hour uphill, downhill, and with
three people in the back. Nobody programmed "if hill, then more throttle". It measures the
speed, compares it with the set speed and corrects the throttle, again and again. This
repeated cycle is called a control loop, and the next lecture is about it.

**Say:** But think about a new driver in an unfamiliar car. They press too
hard and the car jumps, they let go and it slows, then they press again. They do not know
the car yet. A controller has the same problem: it has to be designed for *this*
car. So today we learn the car.

**Ask the room:** you press the pedal down hard. Does the car reach full
speed instantly? *(No. First a short pause, then the push builds up, and the faster the car
goes, the slower it gains speed. The numbers they will get today: the engine waits 0.3 s
before anything happens, then needs another 0.3 s to build about two thirds of its push. The car
reaches 100 km/h after 23.6 s and is within 1 % of its top speed only after 143 s.)*

**Ask the room:** what is different on ice? *(The wheels spin instead of gripping. Keep the
answer: it is the last step today, and the reason cruise control on ice is dangerous.)*
-->

---
routeAlias: what-we-build
---

## What we are building today

![The car as a chain of four parts: the pedal command goes into the engine, the engine's shaft into the gear and wheel, the wheel pushes the body along the road, and a speedometer reads the body's speed in km/h. Each part is labeled with the hands-on step that builds it.](/diagrams/00-car-chain.svg)

- **246 km/h** flat out — you will predict it, then hit it
- **10 km/h** after 5 s on snow, wheel spinning — same engine

<!--
**Say:** This slide shows the whole session: four parts in a row. The
pedal asks the engine for a twisting force, called *torque*. The engine delivers it, a bit
late and a bit slowly. The gear and the wheel turn that twist into a push on the road. The
body is the car's mass, with air and tires holding it back. A speedometer reads the speed.

**Say:** Each box is one step today, and you build them in this order. At
step 5 the boxes are joined and your car drives. Then we make the tire more realistic, and
on snow the wheel spins while the car crawls.

**Point at:** the two numbers. Say: before you build each part, we work out
on paper what it must do. Then your model has to agree. If it does, you built it right. We
work this way all day: predict first, then check.

**What the two numbers mean, if asked:**

- **246 km/h** is the top speed with the pedal held fully down (the engine's maximum of
  150 newton-meters) on a flat, dry road. The simulation shows 246.39 km/h after 300 s
  (step 05).
- **10 km/h** is *not* a top speed. It is where the car is 5 seconds after a full-throttle
  start on a slippery road (the road's grip set to 0.2 of dry). The simulation shows
  10.12 km/h, while the tire surface spins at about 1500 km/h. On a dry road the same start
  gives 21 km/h after 5 s (step 10).

**Why this slide matters:** students lose interest when they do not know what
the formulas are for. Come back to this picture at the start of every step; each step is
one box.
-->

---

## Today

| # | Step | Min | You end with |
| --- | --- | --- | --- |
| <Link to="three-ideas">—</Link> | Why, what, your library, GitHub | 35 | an empty `MyCar` library on a branch |
| <Link to="tour">01</Link> | Tour, and two kinds of wire | 13 | two blocks, one wire, two views |
| <Link to="engine">02</Link> | Engine | 27 | torque with a delay, a lag and a ceiling |
| <Link to="driveline">03</Link> | Driveline | 13 | gear and rolling wheel |
| <Link to="body">04</Link> | Body | 21 | mass, drag, rolling resistance |
| <Link to="car">05</Link> | Car | 27 | 246 km/h flat out — the number from paper |
| <Link to="wheel-inertia">06</Link> | Wheel inertia | 12 | a spinning wheel that barely matters |
| <Link to="grade">07</Link> | Grade | 13 | your first equation |
| <Link to="tire-curve">08</Link> | Tire curve | 20 | grip against slip |
| <Link to="slip-wheel">09</Link> | Slip wheel | 15 | a wheel that can spin |
| <Link to="standing-start">10</Link> | Standing start | 23 | wheelspin on snow |

<!--
**Say:** We build one car, from the bottom up. Each step builds one part of the car (Dyad
calls a part a *component*), and each part is tested before the next one uses it. Make
this a habit.

**Point at:** step 05. That is the milestone: if your car makes 246 km/h, the paper
calculation and the model agree, and you have built the car that Lecture 1 puts a cruise
control on (the controller there is called a *PID controller*).

**Point at:** the last column. Most of those end in a number we predict at the start of
the step and check at its end. The slide *Predicted values, step by step*, near the end of
step 10, lists them all.

**Point at:** the "Min" column. Minutes per step, theory included. The first row (35) covers
this introduction, creating the library and putting it on GitHub.

**Say:** Keep the names the page gives you, like engine, car, and v
underscore kmh. The checkpoints and the plot commands use those names. If you rename a
part, its signal names change and the command does not find them.

**If a student renamed something:** the plot command does not find the signal. Quickest
fix: rename the part back to the name on the page and save.
-->

---

## Four words to describe any system

<div class="grid grid-cols-2 gap-8">
<div>

- **Input *u*** — what we choose to change. *The pedal.*
- **Disturbance *d*** — what changes it without asking.
  *Hills, wind, luggage, ice.*
- **State *x*** — what it remembers from one moment to the next.
  *How fast it is going.*
- **Output *y*** — what we can measure.
  *The speedometer.*

</div>
<div>

![A box labeled car, holding the state, speed. The input u, the pedal, enters from the left; the disturbance d, hills and wind, enters from above; the output y, the speedometer reading, leaves on the right.](/diagrams/00-four-words.svg)

</div>
</div>

<!--
**Say:** With four words you can describe a car, a heater, a drone or a
pharmacy's stock level. Look at the picture. We push the pedal: that is the input. The
road and the weather push back without asking: that is the disturbance. The car carries
its speed from one moment to the next: that is the state. The speedometer tells us about
it: that is the output.

**The letters u, d, x, y** are just the usual short names for these four. Nothing to
compute on this slide.

**Why "state" means "remembers":** if you know the speed right now and what
the pedal and the road will do next, you can predict the speed a second from now. You do not
need the car's history. A state is the smallest set of values you need for that prediction.

**Ask the room:** is a hill an input or a disturbance? *(It acts like an
input, because it pushes on the car, but nobody chose it. The difference is who decides. A
controller has to deal with disturbances it does not choose.)*

**Flag forward:** in steps 09–10 the car gets a second state, the
wheel's own speed, because the wheel can spin faster than the car moves. That second state
is what lets the wheel spin on ice.
-->

---
routeAlias: three-ideas
---

## Three ideas before you click anything

<div class="grid grid-cols-2 gap-8">
<div>

- **A library is a folder.** `dyad/` holds your
  `.dyad` files; `generated/` is the Julia the extension writes
  from them — never edit it.
- **Component = what the system is.** Parts, wires, equations.
- **Analysis = what to do with it.** "Simulate this for 300 s."
- **Diagram and code are one file.** A block is a line; a wire is a
  `connect`.

</div>
<div>

> **The rule behind every test bench**
>
> You can only simulate a component whose inputs are all driven. So each experiment gets
> a small *test bench* around the thing you built: a source into its input, the
> thing itself, and an analysis on the bench.

</div>
</div>

Page: [What you are looking at](../handson/lecture-01/#ui)

<!--
**Say:** Dyad Studio is an extension, an add-on, for the VS Code editor. You draw or write
models in the Dyad language. Dyad translates them into Julia, a programming language for
numerical work, and runs the simulation there. You will not write any Julia today, except
a few short lines, copied from the page, to plot results.

**The words on the slide, in plain terms:**

- **Library:** a folder holding your models. Today it is called `MyCar`.
- **Component:** one model, for example the engine or the whole car. It is drawn as a
  block, and it can contain other blocks.
- **Analysis:** an experiment you run on a component, for example "simulate 300 seconds and
  record everything". It shows up in its own panel with a ▷ run button.
- **Test bench:** a small extra component that holds the part you built, plus whatever feeds
  it. In step 02 that is a step signal feeding the engine's torque command.
- **`connect`:** the line of code that a wire becomes.

**Point at:** the callout. Students hit this in step 02 and ask why they
cannot just run the engine. Give the answer now: an engine with an unconnected torque input
cannot be simulated, because nothing says what the torque command is.

**They get wrong:** editing files in `generated/`. Say it twice:
Dyad rewrites that folder on every compile, so edits there are lost.
-->

---

## Causal and acausal modeling

<div class="grid grid-cols-2 gap-8">
<div>

### Causal — block diagrams

Every block has fixed inputs and outputs: *speed in, force out*.
You decide what is computed from what, and rearrange the physics by hand to fit.
A damper driven by force instead of speed is a different block.

![A causal damper block: speed v enters on the left, force F leaves on the right.](/diagrams/00-causal-damper.svg)

*Simulink, most control tools.*

</div>
<div>

### Acausal — physical parts

Each part states its physics as **equations**, not
assignments. Connecting parts adds more equations. Dyad works out what to compute
from what, so the same damper works whichever side drives it.

![An acausal damper: plain lines with no arrows join it to the parts on both sides.](/diagrams/00-acausal-damper.svg)

At every joint: **speeds are equal**,
**forces add up to zero**.

*Dyad, Modelica.*

</div>
</div>

<!--
**The two words:** *causal* means every wire has a direction, an arrow from cause to effect.
*Acausal* means the wire has no direction: two parts are simply joined, like bolted
together. A *damper* is a shock absorber: the faster you push it, the harder it pushes back.

**Say:** In a block diagram, every wire is an arrow. Someone has to decide
that speed causes force, and not the other way around. Physics does not work like that. A
damper is a relation between force and speed. If you push it, it moves; if you move
it, it pushes back. The same law holds in both directions.

**Say:** In Dyad you write the law once, force equals a constant times speed, and you
connect parts together. Dyad decides the direction for each model you build. That is why
the engine, the driveline and the body connect with plain lines today, not arrows.

**Point at:** the joint rule. A mechanical connection means only this:
the same speed on both sides, and forces that balance. The tour step shows it
again as the "two kinds of wire".

**Names at the bottom, if asked:** Simulink is the block-diagram tool inside MATLAB.
Modelica is an older modeling language that works the same way as Dyad.

**Not everything is acausal:** the torque command and the km/h readout are
signals, with arrows. Models often mix both kinds.
-->

---

## What Dyad does when you press ▷

<div class="grid grid-cols-[1.4fr_1fr] gap-8">
<div>

1. **Collect equations.** Every part's equations, plus two for every
   joint: equal speeds, forces summing to zero.
2. **Check: equations = unknowns.** A model that is not balanced does not
   compile. An unconnected input is one unknown too many, which is why we need test benches.
3. **Simplify.** Symbolic algebra removes trivial equations
   (*a = b*) and solves for the derivatives. Left: a set of differential
   equations in the states only,

   $$ \dot x = f(x, u, t) $$

4. **Solve in time.** From the start state, a solver steps forward,

   $$ x(t+\Delta t) \approx x(t) + \Delta t\, f(x, u, t) $$

   choosing *Δt* itself — small where things change fast.

</div>
<div>

#### The car body, step 04

Unknowns: *v, F<sub>drag</sub>, F<sub>roll</sub>*.
Equations:

$$ F_{\text{drag}} = 0.378\, v^2 $$

$$ F_{\text{roll}} = 165\ \text{N} $$

$$ 1400\,\dot v = F - F_{\text{drag}} - F_{\text{roll}} $$

3 equations, 3 unknowns. After simplification, one state:

$$ \dot v = \frac{F - 0.378\,v^2 - 165}{1400} $$

</div>
</div>

<!--
**Say:** The run button does four things. Dyad turns your diagram into equations, checks
that there are as many equations as unknowns, simplifies them, and hands the result to a
*solver*: a program that steps the model forward in time.

**The symbols, read aloud:**

- *ẋ*, "x dot", is how fast *x* changes per second. *v̇*, "v dot", is how fast the speed
  changes: the acceleration.
- *ẋ = f(x, u, t)* says: how fast the state changes depends only on the state now, the
  input now and the time. A *differential equation* is just an equation like that.
- *Δt*, "delta t", is one small time step.

**Walk the example:** the car body from step 04. *F* is the push from the wheel,
*F*<sub>drag</sub> the air resistance, *F*<sub>roll</sub> the tire rolling resistance,
*v* the speed. The push *F* comes from the engine through the wheel joint, so it is not an
unknown of the body alone. Three unknowns, three equations: balanced. Put the first two
into the third and the body is one equation for one state, the speed.

**Where the numbers come from** (all from the step 04 body model):

- 1400 is the car's mass in kg.
- 0.378 = ½ × air density 1.2 × drag area 0.63. Drag at 100 km/h (27.8 m/s) is
  0.378 × 27.8² ≈ 292 N.
- 165 N = rolling coefficient 0.012 × 1400 kg × 9.81 m/s² = 164.8 N, rounded.

**On the solver:** the second formula is the simplest way of stepping in time (Euler's
method): new state = old state + time step × rate of change. Real solvers are more
accurate, but they work the same way. They pick the step size themselves, so a sudden pedal
press gets tiny steps and a steady cruise gets large ones.

**They get wrong:** the "not balanced" error, meaning equations and unknowns do not match.
It almost always means an input nobody drives, or a part not connected to the ground. Point
back here when it happens in step 02.
-->

---

## Where things are

![Dyad Studio with four numbered arrows: the Components and Analyses panels in the Dyad sidebar, and the Run Analysis and Toggle Between Code and Diagram View buttons in the editor title bar.](/img/dyad-studio-map.png)

_**1** Components — right-click → Add Component · **2** Analyses — ▷ runs one ·
**3** ▷ Run Analysis · **4** ⇄ Toggle Between Code and Diagram View ·
bottom right: Julia Commands → Dyad Compile_

<!--
**Do it live:** open the Dyad sidebar. The *activity bar* is the column of icons on the far
left of VS Code; click the Dyad icon there. Walk the four panels from top to bottom:
Actions, Components, Analyses, Notebooks. Click each control on the slide on your own
screen as you name it.

**The four arrows:**

- **1 Components:** your library and the parts in it. Right-click the library name →
  **Add Component** to make a new part.
- **2 Analyses:** the experiments. The ▷ next to one runs it.
- **3 ▷ Run Analysis:** the triangle at the top right of an open file. On a test bench it
  offers to create a new analysis.
- **4 ⇄:** the two-arrow icon just left of that triangle. It flips the open file between
  diagram and code.

**Point at:** 4, the ⇄. You will use it more than any other button today, and
it is easy to miss.

**Say:** Saving compiles your model, which means Dyad translates it so it can run. If an
analysis does not show up in the Analyses panel after you save, use **Dyad Compile** to
force it. It sits at the bottom right, under **Julia Commands**, beside the terminal.

**Point at:** the terminal in the screenshot, bottom middle. A good compile ends in a green
**SUCCESS**.

**Ignore:** the tangled plot in this screenshot. Step 02 explains it and
shows the fix.
-->

---

## Adding a part

<div class="grid grid-cols-[1.4fr_1fr] gap-8">
<div>

![The diagram toolbar's plus button opened: a search box above a tree of libraries.](/img/dyad-studio-add-component.png)

</div>
<div>

- **+** (Add component) in the diagram toolbar.
- Search by name — `PadeDelay` — or walk the path the parts table gives:
  `BlockComponents › Nonlinear › PadeDelay`.
- `Dyad` holds the ports: `RealInput`, `Spline`,
  `Flange`.
- Your own library is at the bottom — that is where your `Engine` will
  appear when the car needs it.
- The sliders button: **Edit Parameters**.

</div>
</div>

<!--
**Where the + is:** the diagram toolbar is the small bar in the top-left corner of an open
diagram. The **+** is its fifth icon.

**Say:** Four standard libraries matter today. `BlockComponents` for signals, that is,
numbers passed along a wire. `RotationalComponents` for turning shafts.
`TranslationalComponents` for the car sliding along the road. And `Dyad`, which holds the
*ports*: the plug points on a component's edge that other components wire to.

**The port names on the slide:** `RealInput` is a plug for a number coming in. `Spline` is
a plug for a turning shaft. `Flange` is a plug for something sliding in a straight line.

**Point at:** the bottom entry, the student's own library. Components they
build show up here and are placed like standard parts. This is how the car is
assembled in step 05.

**If the search finds nothing:** the student skipped importing the three libraries on the
next slide. Send them back to it.
-->

---

## Create your library

1. <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> → **Dyad: Create Component
   Library** → name it `MyCar`, pick an empty folder.
2. Wait: the extension runs `Pkg.instantiate()` by itself. The first time it
   downloads and precompiles the standard libraries — minutes, not seconds.
3. Dyad sidebar → **Components**: `MyCar` is there.
4. **Actions → Import Library**, three times, into the `MyCar`
   folder: `BlockComponents`, `RotationalComponents`,
   `TranslationalComponents`. A new library has none of them.
5. **Dyad: Open Julia REPL** → `using Pkg; Pkg.add("Plots")`
   — needed for every plot today.

> **Checkpoint**
>
> The terminal finished without errors, `MyCar` is in the Components panel,
> and `Project.toml` lists the three libraries and `Plots`.

Page: [Create your library](../handson/lecture-01/#library)

<!--
**Timing:** the page budgets 15 minutes, but the downloads can take much longer on a slow
network. If students did not do it beforehand, start it first thing and talk through the
three ideas and the map while it downloads.

**The words on the slide:**

- **Command palette:** the search box that <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>
  opens at the top of VS Code. Type the command name, press Enter.
- **`Pkg.instantiate()`:** Julia downloads every package the library needs.
- **Precompile:** Julia prepares those packages once so later runs start faster. This is
  the slow part.
- **Julia REPL:** a Julia command prompt in the terminal. Type a line, press Enter, it runs.
- **Plots:** the Julia package that draws graphs.
- **`Project.toml`:** a text file in the top of the `MyCar` folder listing the packages the
  library uses.

**Say:** A new library starts almost empty. The engine, gear, wheel and
mass we use today live in three standard libraries, so add them now: Import Library,
three times, into your MyCar folder. Then add Plots from the Julia REPL, so you can plot
your results.

**What students see:** after step 1, VS Code reopens in the new folder and the terminal
prints for several minutes; wait until it stops. Under `MyCar` in Components there are a
few example models from the template. They are harmless; leave them. For the checkpoint,
open `Project.toml`: the four names must be under the `[deps]` heading.

**They get wrong:** skipping the imports. Step 01's search for
`FirstOrder` then finds nothing, or code that names
`RotationalComponents` fails to compile. Also: a folder that already has
files in it, or a name with a space. The name must be `MyCar`, because the plot commands
start with `MyCar.`.

**If stuck:** a red error in the terminal during the download is almost always caused by
the network or a full disk. Pair the student with a neighbor and keep going. At the break,
open the Julia REPL in their folder and run `using Pkg; Pkg.instantiate()` to retry.
-->

---

## Put it on GitHub, start a branch

<div class="grid grid-cols-[1.4fr_1fr] gap-8">
<div>

1. **Source Control** (<kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>G</kbd>) →
   **Publish to GitHub** → name `MyCar`, keep the files
   ticked. That is `main`: the empty library.
2. Status bar, bottom left: `main` → **Create new branch…** →
   `handson-01`. All of today goes on it.
3. After **every checkpoint**: message `Step 02: engine` →
   **Commit** → **Sync Changes**.
4. At the end: a **pull request** from `handson-01` into
   `main`.

</div>
<div>

> **Why a branch**
>
> `main` stays the clean starting point; the branch holds today's work, and the
> pull request shows it as one reviewable change, commit by commit.

</div>
</div>

Page: [Put your library on GitHub](../handson/lecture-01/#github)

<!--
**The words, in plain terms:**

- **GitHub:** a website that stores a copy of the project online.
- **Commit:** a saved snapshot of the files, with a short message.
- **Sync Changes:** upload new snapshots to GitHub. The first time on the new branch the
  button says **Publish Branch** instead.
- **Branch:** a separate line of snapshots. `main` is the default one.
- **Pull request:** a request on GitHub to merge one branch into another. Reviewers comment
  on it. Today it is how students hand in.

**Say:** Before we build anything, put the empty library on GitHub. That
is your starting point, called main. Then make a branch called handson-01: everything you
build today goes there. Each time you reach a checkpoint, commit with the step's name and
sync. At the end you open a pull request, and that is how you hand the work in.

**Checkpoint:** the repository opens on github.com with the library's files, and the
bottom-left corner of VS Code shows `handson-01`.

**If VS Code asks** whether to stage all changes when they commit: answer **Yes**.

**They get wrong:** committing on `main` because the branch was
never created — check the status bar of a few screens. If it happened and nothing was
synced yet, create the branch now: the commits come along with it. If the steps were
already synced to `main` on GitHub, the pull request will show nothing new;
sort that out with the student after the session.

**If stuck:** no **Publish to GitHub** button means VS Code is
not signed in to GitHub: Accounts icon, bottom left → Sign in with GitHub. Git missing
altogether: the intro deck's install list.

**Timing:** 5 minutes, and it runs in parallel with the library download
if students publish as soon as the folder exists.
-->
