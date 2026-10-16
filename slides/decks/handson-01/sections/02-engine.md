---
routeAlias: engine
layout: section
---

###### Step 02 · 27 min

# Engine

Torque command in, shaft torque out — late, slow, and never more than 150 N·m.

[page: step 02](../handson/lecture-01/#engine) · reference `dyad/HandsOn/Engine.dyad`

<!--
**Say:** This step finishes the engine. It is a chain of three boxes. The first makes the
torque late, the second makes it slow, the third caps it at 150 newton-meters.

**Words for this step** — say the plain meaning the first time you use each one:

- **Torque** — a twist, in newton-meters (N·m). It is what the engine delivers.
- **Delay** (also *transport delay* or *dead time*, symbol θ, "theta") — the output
  copies the input, but 0.3 s later.
- **Lag** (also *first-order lag*) — the output follows the input gradually instead of
  jumping. How fast is set by its *time constant*, τ ("tau").
- **Limiter** — keeps a number between a floor and a ceiling, here 0 and 150 N·m.
- **Component** — one model in Dyad, such as `Engine`. You draw it as a diagram of
  parts and wires; Dyad also shows it as code.
- **Parameter** — a named number of a component, such as `T_max = 150`.
- **Port** — a plug on the edge of a component that other components connect to.
- **Bench** (test bench) — a small extra model that feeds the engine a test input so it
  can be run.
- **Analysis** — the instruction "simulate this model for so many seconds". Running it
  gives a result you can plot.

**Tutor — why the delay and the lag are there:** the next lecture builds a cruise
control. It picks the controller settings with two textbook recipes, Ziegler–Nichols and
Cohen–Coon. Both need a car that reacts late and slowly. Without the delay and the lag the
car never swings back and forth under control, and the recipes have nothing to measure.
The last slide of this step says the same.

**If the room asks what "first order" or "higher order" means:**

- **State** — a quantity the simulator must remember from one instant to the next,
  because it can only change gradually: a speed, an angle, a temperature. Dyad counts
  them after it simplifies the model (the "What Dyad does when you press ▷" slide in
  Part 1).
- **Order** = the number of states. Rule of thumb: one per thing that stores energy or
  memory — a spinning mass, a spring, a warm object, a filter.
- **First order** — one state, equation τ·dy/dt + y = K·u. After a sudden change of
  input, the output rises smoothly: 63 % of the way after one τ. It *never overshoots*
  (goes past the target) and never oscillates (swings back and forth). Examples: the
  engine's lag on its own; the car's speed against air drag, with τ of about a minute
  (67 s at 90 km/h, step 05); a cup of tea cooling.
- **Second order** — two states, for example the position and speed of a mass on a
  spring, like a car's suspension. It can overshoot and oscillate. Two lags in a row are
  also second order, but do not oscillate on their own.
- **Higher order** — more states, usually a chain of lags. After a sudden change the
  output starts flat and bends upward in an S-shape. Under a controller it *can*
  oscillate, which the PID lecture needs. A true delay counts, strictly, as infinite
  order. Dyad replaces it with a stand-in that has 6 states (the `PadeDelay` slide later
  in this step). With the lag's 1 state, the engine alone has 7.

**Timing:** 27 minutes: 7 of theory up front (the next three slides), then 20 building —
the longest step. It is the first bench, the first analysis and the first plot; every later
step repeats the same pattern.
-->

---
routeAlias: pedal
---

## What happens when you press the pedal

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

1. **Late.** For 0.3 s nothing happens: the engine computer reacts, fuel is
   injected, a cylinder fires. → *delay* block
2. **Slow.** Then torque grows, quickly at first and then more gently, as
   air fills the engine. → *lag* block
3. **Limited.** It never goes above 150 N·m, and never below 0 — this
   engine cannot brake. → *limiter* block

_A fourth block, the **torque source**, turns the number into a
real twist on the shaft._

</div>
<div>

![Torque against time. The request jumps from 0 to 200 newton-meters at 0.5 seconds. The delivered torque stays at zero until 0.8 seconds, then rises along a curve, and is cut flat at 150 newton-meters from about 1.22 seconds.](/diagrams/02-pedal-response.svg)

</div>
</div>

<!--
**Say:** You will make this plot yourselves in step 2. Read it from left
to right. At half a second we ask for 200 newton-meters, more than the engine can give, on
purpose. For 0.3 seconds, nothing happens: that flat piece is the delay. Then
comes a curve: that is the lag. At 150 newton-meters the curve is cut flat: that is the
limiter.

**The plot, in numbers:** request jumps 0 → 200 N·m at 0.5 s. Delivered torque is
0 until 0.8 s, then curves up, and is flat at 150 N·m from about 1.22 s. The next two
slides work these out.

**Where the numbers come from physically:**

- **Delay 0.3 s** — the whole chain from pedal to burning fuel: the engine
  computer, measuring out the fuel, waiting for a cylinder to fire, the shafts twisting up.
  A student who says "injection is much faster than that" is right: 0.3 s lumps the whole
  chain into one number.
- **Lag 0.3 s** — the intake manifold, the pipe that feeds air to the
  cylinders, has to fill before the engine can make more torque. Filling a volume through
  a valve behaves like a lag (next slide).
- **Limit 0 to 150 N·m** — 150 N·m is this engine's peak torque. The floor of 0 means
  it cannot brake.

**Ask the room:** what does a cruise control on this car do going downhill?
*(Nothing useful — it can only cut the torque to zero. Real cruise controls also use the
brakes.)*

**Ask the room:** delay and lag are both 0.3 s. How do you tell them apart
on the plot? *(Delay: flat, nothing happens. Lag: starts at once, but gradually.)*
-->

---

## The lag: closing a gap

<div class="grid grid-cols-2 gap-8">
<div>

In words: *the torque moves toward the request, and the bigger the
gap, the faster it moves.* As an equation:

$$ \tau_e\,\frac{dT}{dt} \;=\; T_{\text{req}} - T $$

**τₑ = 0.3 s** — the engine's time constant
(`tau_e`): how long the intake manifold takes to fill. Not the same as the
0.3 s delay θₑ before it.

A gap that shrinks in proportion to itself shrinks *exponentially*:

$$ T(t) \;=\; T_{\text{req}}\,\big(1 - e^{-t/\tau_e}\big) $$

</div>
<div>

| time since it started | share of the way |
| --- | --: |
| 1 × τₑ = 0.3 s | 63 % |
| 2 × τₑ = 0.6 s | 86 % |
| 3 × τₑ = 0.9 s | 95 % |

> **Remember**
>
> After one time constant τ, a lag has covered **63 %** of the way. The car
> itself will turn out to be a lag too — with τ of about a minute.

</div>
</div>

<!--
**Say:** Imagine filling a bathtub from a faucet that gets weaker as the
tub fills. Far from the target, it fills fast. Close to the target, it fills slowly. You
get close quickly, but you never quite arrive. That curve is called an exponential, and you
will see it often in this course.

**Read the symbols aloud as:** T = delivered torque. T<sub>req</sub> = requested
torque. dT/dt = how fast T is changing. τₑ ("tau e") = the lag's time constant, 0.3 s.
θₑ ("theta e") = the delay, also 0.3 s, a different thing. e ≈ 2.718, the base of the
exponential (the eˣ key on a calculator).

**Ask the room** (if they mix up the two 0.3 s values): which one is the flat part of the
plot? *(θₑ, the delay. τₑ shapes the curve after it.)*

**Derivation, step by step** (only if a student asks; otherwise just the
words):

1. Call the gap *g = T<sub>req</sub> − T*. The request is constant, so
   d*g*/dt = −d*T*/dt.
2. The equation says τₑ·dT/dt = g, so τₑ·dg/dt = −g: the gap shrinks at a rate
   proportional to its own size.
3. The function whose rate of change is proportional to itself is the exponential:
   g(t) = g(0)·e<sup>−t/τₑ</sup>. Check by differentiating: dg/dt = −g/τₑ. ✓
4. Starting from T = 0, the gap starts at g(0) = T<sub>req</sub>. So
   T = T<sub>req</sub> − g = T<sub>req</sub>(1 − e<sup>−t/τₑ</sup>).

**The table:** at t = τₑ, 1 − e<sup>−1</sup> = 1 − 0.368 = 0.632 → 63 %.
At 2τₑ, 1 − e<sup>−2</sup> = 1 − 0.135 = 0.865 → 86 %. At 3τₑ, 1 − 0.050 = 0.95 → 95 %.

**They get wrong:** "the time constant is how long it takes to get there".
It is not; it is how long to get 63 % of the way. It never strictly gets there.
-->

---

## Working out the step-02 plot before you make it

Request 200 N·m at t = 0.5 s. Delay 0.3 s, lag τₑ = 0.3 s, limit 150 N·m.

<div class="grid grid-cols-3 gap-8">
<div>

#### When does it start?

0.5 s + 0.3 s delay

- **0.8 s** — nothing before this

</div>
<div>

#### How much at 1.0 s?

0.2 s into the lag:<br>200 × (1 − e<sup>−0.2/0.3</sup>)<br>= 200 × (1 − 0.513)

- **≈ 97 N·m** at 1.0 s — your plot shows 97.5

</div>
<div>

#### When does it hit 150?

200 × (1 − e<sup>−t′/0.3</sup>) = 150<br>e<sup>−t′/0.3</sup> = 0.25<br>t′ = 0.3 × ln 4 = 0.42 s

- **1.22 s** — then flat at 150

</div>
</div>

<!--
**Do it on the board, one column at a time.** "ln" is the natural logarithm, the ln key
on a calculator; it undoes e<sup>x</sup>.

1. **Start:** the request arrives at 0.5 s. The delay holds everything back
   for 0.3 s. 0.5 + 0.3 = **0.8 s**.
2. **At 1.0 s:** the lag has been running for 1.0 − 0.8 = 0.2 s.
   0.2 / 0.3 = 0.667. e<sup>−0.667</sup> = 0.513. 1 − 0.513 = 0.487. 0.487 × 200 =
   **97 N·m**. (The lag aims at the full 200, not at 150 — the limiter only
   cuts the result afterwards.)
3. **Hitting 150:** set 200(1 − e<sup>−t′/0.3</sup>) = 150. Divide by 200:
   1 − e<sup>−t′/0.3</sup> = 0.75, so e<sup>−t′/0.3</sup> = 0.25. Take logs:
   t′/0.3 = ln 4 = 1.386, t′ = 0.416 s. t′ is time since the lag started, so add the
   0.8 s start: **1.22 s**.

**Say:** We worked out these three numbers before opening Dyad. In
ten minutes you will read the same three numbers off your own plot. If they match, your
engine is built right.

**What the simulation actually shows** (reference run, `test/snapshots/HandsOn`): about
2 N·m of wiggle before 0.8 s, 97.5 N·m at 1.0 s, and 150 N·m from about 1.22 s. The small
differences from the board come from the stand-in Dyad uses for the delay (the
`PadeDelay` slide). Within about 1 N·m counts as a match.

**Ask the room:** why ask for 200 when the engine can only give 150?
*(To see the limiter work. A test should exercise every block it is testing.)*
-->

---

## From two blocks to an engine

![The finished Engine diagram: tau_cmd, delay, lag, limiter and torque in a row, spline port on the right, support port at the bottom.](/img/step02-engine-finished.png)

*Same `Engine` as step 01 — add 3 parameters, `limiter`, `torque`, and 3 ports on the outline*

<!--
**Say:** You do not start a new component. Open the Engine from step 1:
in the Dyad sidebar, the Components panel, expand MyCar and click Engine. Keep adding to
it. The two blocks you already have, delay and lag, are the second and third in this row.

**Point at:** the thin blue rectangle around the parts — the component's
outline — and the three ports on it. Left: `tau_cmd`, the torque request coming in.
Right: `spline`, the output shaft. Bottom: `support`, the engine mounts. "Spline" is
Dyad's name for a rotating shaft connection, drawn as a gray circle. Another component
plugs into these ports; that is how the car connects to this engine in step 05.

**Order on the page:** the student page splits step 02 into stages A to E.
A open it · B add the three parameters · C add limiter, torque source and ports ·
D build the bench · E run and plot. Walk the room after C: an engine that is wired wrong
makes D impossible. After C, the **Problems** tab under the editor should list nothing
for `Engine`.
-->

---

## Support ports: every force needs a reaction

<div class="grid grid-cols-[1.4fr_1fr] gap-8">
<div>

An engine twists its shaft — and twists its mounts the other way. A wheel pushes the car
forward — and pushes the road backward. That is Newton's third law.

- In Dyad, the "other side" is a `support` port. It must end at a
  `Fixed` block: the ground, the car's frame.
- Forget it, and Dyad says the system is *unbalanced*: it has a force with
  nowhere to go.
- **Sign rule:** a force counts as positive when it pushes
  *into* a block. So a tire pushing the car forward shows up as a
  *negative* force at its port.

</div>
<div>

> **Where this matters today**
>
> Step 02 — the engine needs fixed mounts.
>
> Step 03 — the gear and wheel bring their supports out.
>
> Step 05 — the car connects them to ground.
>
> Step 09 — the tire's minus sign.

</div>
</div>

<!--
**Say:** Hold a power drill by the battery and pull the trigger. The bit
spins one way, and the drill tries to spin the other way in your hand. Your hand is the
Fixed block. Take your hand away, and the drill spins instead of the bit doing any work. A
model with an unconnected support has the same problem, and Dyad does not run it.

**Words:** a `support` port is the "other side" of a part — where its reaction
goes. `Fixed` is a block that holds a port still: the ground, or the car's frame.
"Unbalanced" in a Dyad error means the model has more unknowns than equations (the
"What Dyad does when you press ▷" slide in Part 1); a loose support is the usual cause.
A `flange` is the straight-line version of a port (green square), used from step 03 on.

**The sign rule:** Dyad counts force as positive when it flows
*into* a block. The tire pushes the car forward, so the car pushes the tire
backward — the force flowing into the tire is backward, so it is negative. Step 09 writes
that line: `flange.f = -F_x`. Dyad's libraries all use this rule, as does Modelica, the
older modeling language Dyad follows. It looks backwards at first, and a wrong sign here
is the most common cause of a car that drives in reverse.
-->

---

## Finish the chain, then build a bench

<div class="grid grid-cols-2 gap-8">
<div>

Parameters `theta_e` = 0.3 (structural), `tau_e` = 0.3,
`T_max` = 150 — the parts use the names.

`tau_cmd` → `delay` → `lag` →
`limiter` (y_max = T_max, y_min = 0) → `torque` →
`spline`; `torque.support` → `support`.

**Bench `EngineStep`:** a `Step` of 200 N·m at
0.5 s into your `Engine`, a 1 kg·m² `Inertia` on the shaft,
the mounts `Fixed`.

> **Why an Inertia?**
>
> An **inertia** is a spinning mass: it resists changes in rotation,
> *T = J · dω/dt*. The engine's torque must act on something — on a bare shaft
> it has nowhere to go and the model cannot be solved. With *J* = 1 kg·m², the
> shaft's angular acceleration in rad/s² equals the delivered torque in N·m.

</div>
<div>

![EngineStep bench: step source into the engine, inertia on its shaft, fixed mounts below, with the analysis in the code view.](/img/step02-engine-step.png)

</div>
</div>

<!--
**Where to click:** click an empty spot of the canvas. The panel on the right then
shows `Engine` itself, with an **Add parameter** button. Add `theta_e` = 0.3 (type Time),
`tau_e` = 0.3 (Time), `T_max` = 150 (Torque). Then click each block and type the *name*
into its field: `delay` → `delayTime` = `theta_e`, `lag` → `T` = `tau_e`,
`limiter` → `y_max` = `T_max`, `y_min` = `0`.

**Say — define each value once:** A number that a part needs becomes a
parameter of the component, and the part refers to it by name. Then setting T max to 200
on the Engine changes the ceiling in one place. The delay time, theta e, is a *structural*
parameter: changing it changes the model's structure, so Dyad rebuilds the model. That is
because the delay block computes its internal numbers from it when the model compiles.
If the panel offers no structural option, switch to code (⇄) and paste the line from the
student page.

**Say:** The value 200 is above the limit so that the plot shows the
limiter working.

**About the inertia** (the box on the slide): a 1 kg·m² spinning disc on the shaft.
With J = 1, the disc's speed-up in rad/s² equals the torque in N·m. rad/s is the unit of
turning speed: one full turn is 2π ≈ 6.28 rad. In the reference run the disc ends at
306 rad/s after 3 s.

**They get wrong:** leaving `support` unconnected in the bench.
A torque source needs something to push against — the engine mounts. The compile error
talks about an unbalanced system; the fix is the `Fixed` block wired to `support`.

**Ask the room:** why `y_min = 0`? What would a negative command do without it?
*(The torque source would twist the shaft backward: the engine would act as a brake, or
spin the disc in reverse. A real engine cannot do that through this path.)*
-->

---

## Initial state in code, analysis with ▷

```julia [EngineStep — complete bench and analysis]
component EngineStep
  cmd = BlockComponents.Sources.Step(height = 200, offset = 0, start_time = 0.5)
  engine = Engine()
  "Unit inertia, so its angular acceleration reads as the delivered torque"
  load = RotationalComponents.Components.Inertia(J = 1)
  mounts = RotationalComponents.Components.Fixed()
relations
  connect(cmd.y, engine.tau_cmd)
  connect(engine.spline, load.spline_a)
  connect(engine.support, mounts.spline)
  initial engine.lag.x = 0
  initial load.phi = 0
  initial load.w = 0
end

analysis EngineStepTransient
  extends TransientAnalysis(stop = 3)
  model = EngineStep()
end
```

<div class="grid grid-cols-[1.4fr_1fr] gap-8">
<div>

1. **New component** `EngineStep` (Components → right-click MyCar → Add Component), draw the bench.
2. ⇄ to code, add the three `initial` lines. Save.
3. **New analysis:** ▷ Run Analysis in the title bar → **TransientAnalysis** → model already assigned. Name it `EngineStepTransient`, `stop = 3`.
4. ▷ beside it in **Analyses** runs it.

</div>
<div>

> **Why initial conditions?**
>
> The solver steps forward from a known start, so every state needs a value at
> *t* = 0: here the lag's output and the shaft's angle and speed. All zero = no
> torque, not turning. Change them and the same model starts elsewhere, e.g. a car
> already at 90 km/h.

</div>
</div>

<!--
**Say:** The bench is a new component of its own, not part of the Engine.
The starting state has no diagram form, so it is three lines of code. You do not need to
type the analysis: the run button in the title bar offers the analysis types, and
Transient Analysis creates one with this bench as its model.

**Tutor:** say the "new component of its own" part out loud; students often
draw the bench inside `Engine`.

**What the three `initial` lines mean:** at time 0, the lag's output is 0
(`engine.lag.x`), the shaft angle is 0 (`load.phi`), and the shaft speed is 0
(`load.w`). These are the bench's states: the quantities the simulator must remember.

**Where to click:** ⇄ (Toggle Between Code and Diagram View) and ▷ (Run Analysis) are
in the editor's title bar, top right, on the row with the file's tab. *Transient
Analysis* means "simulate over time"; `stop = 3` means 3 seconds.

**They get wrong:** the analysis name. The plot command calls
`MyCar.EngineStepTransient()`; if Dyad Studio picked another name, change the word
after `analysis` in its code. The code block on this slide is the fallback.

**If it does not appear in Analyses:** click Dyad Compile under Julia Commands, bottom
right beside the terminal.

**After ▷ runs it:** a Julia Plots pane opens with every signal at once, unreadable.
That is expected; the next slide fixes it.
-->

---

## Plot one signal, not all of them

<div class="grid grid-cols-2 gap-8">
<div>

```julia [Julia REPL]
using Plots
r = MyCar.EngineStepTransient()
plot(r; idxs = r."engine.limiter.y")
```

</div>
<div>

![engine.limiter.y: zero until 0.5 s, a dead time, then a rise clipped flat at 150 N·m from about 1.2 s.](/img/step02-engine-step-plot.png)

</div>
</div>

- **0** — until 0.5 s + dead time
- **97.5** — N·m at 1.0 s
- **150** — N·m from 1.22 s

<!--
**Say:** The default plot draws every state. The delay has six internal
states that swing into the thousands, and they bury the one curve you care about. Pick
that curve by name with the idxs argument — "idxs" means "which signals to plot".

**Open the REPL:** the REPL is Julia's command line: type a line, press Enter, it runs.
Open it from the Dyad sidebar: the **Actions** panel's title bar → **Dyad: Open Julia
REPL**. Type the three lines on the slide. The first `using Plots` in a session can take a
while.

**Point at:** the flat start. The command arrived at 0.5 s; torque starts
at about 0.8 s. That 0.3 s is the delay. The small wiggles before it are the stand-in
for the delay, not physics — the next slide explains them.

**What students should see** (guide checkpoint, `HandsOn.EngineStepTransient`):

- `engine.limiter.y`: 0 at the step at 0.5 s, only 6.2 N·m at 0.8 s, 97.5 N·m at 1.0 s,
  flat at 150 N·m from 1.22 s to the end.
- If they also plot `engine.delay.y`: it peaks at about 208 near 0.9 s, then settles at
  200. The stand-in overshoots; the limiter hides it.
- `load.w` (disc speed) ends at 306.0 rad/s at 3 s.

**If a student's curve differs:** flat at 200 instead of 150 → `y_max` is not
`T_max`. Rises at 0.5 s → the delay is not wired in. A different curve shape → check
`T = tau_e` and the Step's `height = 200`, `start_time = 0.5`.

**They get wrong:** "`MyCar` not defined" in the REPL. Run `using MyCar` first, and if
the library got another name, use that name in both places.
-->

---

## Approximating the delay: `PadeDelay`

<div class="grid grid-cols-2 gap-8">
<div>

A true delay must remember the whole last 0.3 s of the pedal, to replay
it later. A simulator cannot store that; it only tracks a handful of numbers that change
smoothly.

So Dyad uses a stand-in, `PadeDelay`: six of those numbers,
tuned so that together they behave almost exactly like a 0.3 s delay.

</div>
<div>

> **The wiggles you just saw**
>
> The tiny wiggles in the torque before 0.8 s come from the stand-in, not from the
> engine.
>
> `theta_e`, the delay, is a **structural** parameter: change it
> and Dyad rebuilds the model.

> **Why "plot everything" failed**
>
> The default plot draws these six helper numbers too — they swing into the thousands
> and hide the torque. That is why you plot one signal by name.

</div>
</div>

<!--
**Say:** The delay is the only block here that is an approximation, a stand-in. The
wiggles show where it differs from a true delay.

**In plain words:** Padé is the name of the mathematician whose method builds the stand-in;
say "the delay stand-in" if you prefer. "Structural" means changing the value rebuilds the
model, not just one number in it.

**For a student who knows Laplace transforms** (skip otherwise): a delay of θ has the
transfer function e<sup>−sθ</sup>. A Padé approximation replaces it by a ratio of
polynomials. The simplest is (1 − sθ/2)/(1 + sθ/2). `PadeDelay(n = 6, m = 5)` uses a
6th-order denominator and a 5th-order numerator; they match e<sup>−sθ</sup> to order 11.
Because the numerator is lower order, a sudden step cannot pass straight through before
the delay has elapsed.

**Why structural:** the block computes its internal coefficients from the
delay when the model is compiled, so a new delay value means a new model, not just a new
number.
-->

---

## Why keep the delay and the lag at all?

<div class="grid grid-cols-2 gap-8">
<div>

Without them, the torque appears the instant you ask for it. Then:

- the car becomes too easy to control: any controller works;
- the two tuning methods in the next lecture (Ziegler–Nichols, Cohen–Coon) cannot be
  used at all;
- real cars are not like that: every real engine is late and slow.

</div>
<div>

> **A model is good enough when…**
>
> …it keeps the effects that matter for your question. For "how fast is it flat out?", the
> delay barely matters. For "how should cruise control react?", it matters a lot.

</div>
</div>

<!--
**Say:** Both effects are physically real, but the main reason they are
in the model is control. Pushing a door that opens instantly is easy. Pushing one that
responds half a second late makes you overshoot. That lateness is what makes control
difficult.

**Words:** Ziegler–Nichols and Cohen–Coon are two textbook recipes that pick a
controller's settings from how the car responds to a test. Students meet them in the next
lecture; nobody needs them today.

**For the tutor — the precise reasons** (from the lecture plan):

- Without the delay and lag, the car is *first order*: one state, its speed. A
  proportional controller pushes harder the further the speed is from the target; on a
  first-order car it never makes the speed swing back and forth, however hard it pushes.
  Ziegler–Nichols needs that swinging to measure anything.
- Cohen–Coon describes the car as "a lag plus a delay" and divides by the delay. With no
  delay, it divides by zero.
- With no lag there is little overshoot, so the derivative part of PID — the part that
  reacts to how fast the error is changing, to calm overshoot — has nothing to do.
-->
