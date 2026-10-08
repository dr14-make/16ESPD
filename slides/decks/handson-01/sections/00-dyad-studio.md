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
**Before the room fills.** Deck on the projector, Dyad Studio on your
laptop with an empty folder ready. Open **presenter mode** from the nav bar now (bottom left,
it appears on hover): these notes, the next slide and a timer in the same tab, no popup to
block.

**Where this sits:** the first of two sessions on one car. Here students
learn the car and build it; Lecture 1 then controls it, and its slides link back to the
slides here wherever they rely on the physics.

**How the deck is laid out:** each step opens with the theory it needs —
plain language on the slide, every formula derived, every number worked in the notes — then
the doing slides. Teach the theory slides from the front, then let the room build. Every
formula has a *Derivation* list in these notes with the numbers plugged in, so you can
do it on the board without preparing.

**Students follow the page, not the deck.** Put the link on the board:
`handson/lecture-01/` on the course site. Every step there has the parts
table, the screenshot, numbered actions and copy buttons. The deck is for you: what to
explain, what to show, where they get stuck.

**Timing:** about 225 minutes — Part 1 48, Part 2 171, hand-in 5 — so plan a long
afternoon with a break after step 05, or two sittings split there. Deep links are by name:
`#/car` here is step 05 on the page.

**If time runs short:** cut from the back. Steps 02–06 give everyone a
working car; 07–10 are the slip story. Never cut the next two slides — they are why anyone
listens to the rest.
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
three people in the back. Nobody programmed "if hill, then more throttle". It measures,
compares and corrects, over and over. That loop is control, and the next lecture is all
about it.

**Say:** But think about a new driver in an unfamiliar car. They press too
hard and the car jumps, they let go and it slows, then they press again. They do not know
the car yet. A controller has the same problem: it has to be designed for *this*
car. So today we learn the car.

**Ask the room:** you press the pedal down hard. Does the car reach full
speed instantly? *(No — first a short pause, then it builds up, and the faster it goes
the slower it gains speed. By the end of today they will be able to say exactly how long
each of those takes, in seconds.)*

**Ask the room:** what is different on ice? *(The wheels spin. Keep the
answer — it is the last step today, and the reason cruise control on ice is dangerous.)*
-->

---
routeAlias: what-we-build
---

## What we are building today

![The car as a chain of four parts: the pedal command goes into the engine, the engine's shaft into the gear and wheel, the wheel pushes the body along the road, and a speedometer reads the body's speed in km/h. Each part is labeled with the hands-on step that builds it.](/diagrams/00-car-chain.svg)

- **246 km/h** flat out — you will predict it, then hit it
- **10 km/h** on snow, wheel spinning — same engine

<!--
**Say:** This is the whole day on one slide: four parts in a row. The
pedal asks for engine torque. The engine makes it, a bit late and a bit slowly. The gear
and the wheel turn that torque into a push on the road. The body is the car's mass, with
air and tires holding it back. A speedometer reads the speed.

**Say:** Each box is one step today, and you build them in that order. At
step 5 the boxes are joined and your car drives. Then we make the tire more realistic, and
on snow the wheel spins while the car crawls.

**Point at:** the two numbers. Say: before you build each part, we work out
on paper what it must do. Then your model has to agree. If it does, you built it right. That
is the deal for the whole day: predict first, then check.

**Why this slide matters:** students lose interest when they do not know where
the formulas are going. Come back to this picture at the start of every step — each step is
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
| <Link to="standing-start">10</Link> | Standing start | 23 | wheelspin on ice |

<!--
**Say:** We build one car, from the bottom up. Each step is one component,
and each component is tested before the next one uses it. That habit is the real
lesson.

**Point at:** step 05. That is the milestone: if your car makes 246 km/h,
the equations and the model agree, and you have built the car the PID lecture uses.

**Point at:** the last column. Each of those is a number we predict at the
start of the step and check at its end. The last slide of step 10 collects them all.

**Say:** Keep the names the page gives you, like engine, car, and v
underscore kmh. The checkpoints and the plot commands use those names. A different name
means a different signal name, and then the command does not find it.
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

**Why "state" means "remembers":** if you know the speed right now and what
the pedal and the road will do next, you can predict the speed a second from now. You do not
need the car's history. That is what a state is — the minimum you need to know.

**Ask the room:** is a hill an input or a disturbance? *(It acts like an
input — it pushes on the car — but nobody chose it. The difference is who decides. A
controller exists to deal with the things it did not choose.)*

**Flag forward:** from hands-on step 09 the car has a second state, the
wheel's own speed, because the wheel can spin faster than the car moves. That second state
is where ice becomes dangerous.
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

> **The rule that shapes every step**
>
> You can only simulate a component whose inputs are all driven. So each experiment gets
> a small *test bench* around the thing you built: a source into its input, the
> thing itself, and an analysis on the bench.

</div>
</div>

Page: [What you are looking at](../handson/lecture-01/#ui)

<!--
**Say:** Dyad Studio is a VS Code extension. You draw or write models in
the Dyad language. It compiles them to Julia, with ModelingToolkit underneath, and
simulates them. You will not write any Julia today, except to plot.

**Point at:** the callout. Students hit this in step 02 and ask why they
cannot just run the engine. Plant the answer now: an engine with a dangling torque input
is not a complete problem — nobody said what the torque command is.

**They get wrong:** editing files in `generated/`. Say it twice:
it is rewritten on every compile, edits there vanish.
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
**Say:** In a block diagram, every wire is an arrow. Someone has to decide
that speed causes force, and not the other way around. Physics does not work like that. A
damper is just a relation between force and speed. If you push it, it moves; if you move
it, it pushes back. It is the same law in two directions.

**Say:** In Dyad you write the law once, force equals the damping constant
times speed, and you bolt parts together. Dyad decides the direction for each model you
build. That is why the engine, the driveline and the body connect with plain lines today,
not arrows.

**Point at:** the joint rule. It is the whole of what a mechanical
connection means: same speed on both sides, and forces balance. The tour step shows it
again as the "two kinds of wire".

**Not everything is acausal:** the torque command and the km/h readout are
signals, with arrows. Mixing both is normal.
-->

---

## What Dyad does when you press ▷

<div class="grid grid-cols-[1.4fr_1fr] gap-8">
<div>

1. **Collect equations.** Every part's equations, plus two for every
   joint: equal speeds, forces summing to zero.
2. **Check: equations = unknowns.** A model that is not balanced does not
   compile. A dangling input is one unknown too many — the reason for test benches.
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
**Say:** Pressing the run button starts a small compiler. Dyad turns your
diagram into equations, checks how many there are, simplifies them, and hands the result
to a numerical solver. Underneath it is Julia's ModelingToolkit, but you never see it.

**Walk the example:** the drive force *F* comes from the engine
through the wheel joint, so it is not an unknown of the body alone. Three unknowns, three
equations — balanced. Substitute the first two into the third and the body is one
differential equation in one state, the speed.

**On the solver:** the formula on the slide is Euler's method — the
simplest idea of stepping in time. Real solvers are cleverer, but the idea is the same:
know the state now, compute how fast it changes, step forward. They pick the step size
themselves, so a sudden pedal press gets tiny steps and a steady cruise gets large ones.

**They get wrong:** the "not balanced" error. It almost always means an
input nobody drives, or a part not connected to the ground. Point back here when it
happens in step 02.
-->

---

## Where things are

![Dyad Studio with four numbered arrows: the Components and Analyses panels in the Dyad sidebar, and the Run Analysis and Toggle Between Code and Diagram View buttons in the editor title bar.](/img/dyad-studio-map.png)

_**1** Components — right-click → Add Component · **2** Analyses — ▷ runs one ·
**3** ▷ Run Analysis · **4** ⇄ Toggle Between Code and Diagram View ·
bottom right: Julia Commands → Dyad Compile_

<!--
**Do it live:** open the Dyad sidebar (the Dyad icon in the activity bar)
and walk the four panels: Actions, Components, Analyses, Notebooks. Click each control on
the slide on your own screen as you name it.

**Point at:** 4, the ⇄. It is the most used button today and the easiest
to miss.

**Say:** Saving compiles your model. If an analysis does not show up in
the Analyses panel after you save, use Dyad Compile, under Julia Commands, to force
it.

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
**Say:** Four standard libraries matter today: Blocks for signals,
Rotational for shafts, Translational for the car moving along the road, and Dyad for the
ports.

**Point at:** the bottom entry, the student's own library. Components they
build show up here and are placed exactly like standard parts — that is how the car is
assembled in step 05.
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
**Timing:** this is the step that eats a session. If you could not get
students to do it beforehand, start it first thing and talk through the three ideas and
the map while it downloads.

**Say:** A new library starts almost empty. The engine, gear, wheel and
mass we use today live in three standard libraries, so add them now: Import Library,
three times, into your MyCar folder. Then add Plots from the Julia REPL, so you can plot
your results.

**They get wrong:** skipping the imports. Step 01's search for
`FirstOrder` then finds nothing, or code that names
`RotationalComponents` fails to compile. Also: a folder that already has
files in it, or a name with a space. `MyCar` exactly — the plot commands say `using MyCar`.

**If stuck:** a red error in the terminal during instantiate is almost
always the network or a full disk. Pair the student with a neighbor and keep going;
re-run `Pkg.instantiate()` at the break.
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
**Say:** Before we build anything, put the empty library on GitHub. That
is your starting point, called main. Then make a branch called handson-01: everything you
build today goes there. Each time you reach a checkpoint, commit with the step's name and
sync. At the end you open a pull request, and that is how you hand the work in.

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
