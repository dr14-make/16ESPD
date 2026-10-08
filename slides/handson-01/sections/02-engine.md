---
routeAlias: engine
layout: section
---

###### Step 02 · 27 min

# Engine

Torque command in, shaft torque out — late, slow, and never more than 150 N·m.

[page: step 02](../handson/lecture-01/#engine) · reference `dyad/HandsOn/Engine.dyad`

<!--
**Say:** This is the first box of the chain: a transport delay, a
first-order lag, and a ceiling.

**Tutor:** the delay and the lag are what will make Ziegler–Nichols and
Cohen–Coon possible in the PID lecture's tuning section — without them the car is first
order and never oscillates.

**First and higher order — explain it here if the room asks:**

- **Order = number of states**: how many first-order differential
  equations are left once Dyad has simplified the model (the ▷ slide in Part 1). Rule
  of thumb: one per independent store of energy or memory — an inertia, a spring, a
  heated mass, a filter.
- **First order**: one state, τ·dy/dt + y = K·u. The step response rises
  smoothly toward its final value, 63 % after one τ, and *never overshoots or
  oscillates*. Examples: the engine's lag on its own; the car's speed against drag,
  with τ of about a minute; a cup of tea cooling.
- **Second order**: two states, e.g. position and speed of a mass on a
  spring — a car's suspension. It can overshoot and oscillate, depending on its damping.
  Two first-order lags in a row are also second order, but without oscillation on their
  own.
- **Higher order**: more states, usually a chain of lags. The step response
  starts flat and S-shaped instead of rising at once, and under feedback the loop
  *can* oscillate — which is exactly what the PID lecture needs. A pure delay is,
  strictly, infinite order; the Padé block later in this step replaces it with 6 states,
  so this engine alone is already 7th order.

**Timing:** 27 minutes: 7 of theory up front (the next three slides), then 20 building — the longest step. It is the first bench,
the first analysis and the first plot; everything after reuses the pattern.
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
to right. At half a second we ask for 200 newton-meters, which is more than the engine can
give, on purpose. For 0.3 seconds, nothing happens: that flat piece is the delay. Then
comes a curve: that is the lag. At 150 newton-meters the curve is cut flat: that is the
limiter.

**Where the numbers come from physically:**

- **Delay 0.3 s** — the whole chain from pedal to combustion: the engine
  computer, fuel metering, waiting for a cylinder to fire, the driveline winding up. A
  student who says "injection is much faster than that" is right: 0.3 s lumps the whole
  chain into one number.
- **Lag 0.3 s** — the inlet manifold, the pipe that feeds air to the
  cylinders, has to fill before more torque is possible. Filling a volume through a
  throttle behaves like a first-order lag (next slide).
- **Limit 0 to 150 N·m** — the engine's peak torque. The floor of 0 means it
  cannot brake. Ask the room what a cruise control on this car does going downhill.
  *(Nothing useful — it can only cut torque to zero. Real cruise controls use the
  brakes too.)*

**Ask the room:** delay and lag are both 0.3 s. How do you tell them apart
on the plot? *(Delay: flat, nothing happens. Lag: starts immediately, but gradually.)*
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

> **The one thing to remember**
>
> After one time constant τ, a lag has covered **63 %** of the way. The car
> itself will turn out to be a lag too — with τ of about a minute.

</div>
</div>

<!--
**Say:** Imagine filling a bathtub from a faucet that gets weaker as the
tub fills. Far from the target, it fills fast. Close to the target, it fills slowly. You
get close quickly, but you never quite arrive. That curve is the exponential, and it shows
up everywhere in this course.

**Derivation, step by step** (if a student asks; otherwise just the
words):

1. Call the gap *g = T<sub>req</sub> − T*. The request is constant, so
   d*g*/dt = −d*T*/dt.
2. The equation says τₑ·dT/dt = g, so τₑ·dg/dt = −g: the gap shrinks at a rate
   proportional to its own size.
3. The function whose derivative is proportional to itself is the exponential:
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

- **97 N·m** — at 1.0 s

</div>
<div>

#### When does it hit 150?

200 × (1 − e<sup>−t′/0.3</sup>) = 150<br>e<sup>−t′/0.3</sup> = 0.25<br>t′ = 0.3 × ln 4 = 0.42 s

- **1.22 s** — then flat at 150

</div>
</div>

<!--
**Do it on the board, one column at a time.**

1. **Start:** the request arrives at 0.5 s. The delay holds everything back
   for 0.3 s. 0.5 + 0.3 = **0.8 s**.
2. **At 1.0 s:** the lag has been running for 1.0 − 0.8 = 0.2 s.
   0.2 / 0.3 = 0.667. e<sup>−0.667</sup> = 0.513. 1 − 0.513 = 0.487. 0.487 × 200 =
   **97 N·m**. (The lag aims at the full 200, not at 150 — the limiter only
   cuts the result afterwards.)
3. **Hitting 150:** set 200(1 − e<sup>−t′/0.3</sup>) = 150. Divide by 200:
   1 − e<sup>−t′/0.3</sup> = 0.75, so e<sup>−t′/0.3</sup> = 0.25. Take logs:
   t′/0.3 = ln 4 = 1.386, t′ = 0.416 s. Add the 0.8 s start: **1.22 s**.

**Say:** We worked out these three numbers before anyone opened Dyad. In
ten minutes you will read the same three numbers off your own plot. If they match, your
engine is built right.

**Ask the room:** why ask for 200 when the engine can only give 150?
*(To see the limiter work. A test should exercise every block it is testing.)*
-->

---

## From two blocks to an engine

![The finished Engine diagram: tau_cmd, delay, lag, limiter and torque in a row, spline port on the right, support port at the bottom.](/img/step02-engine-finished.png)

*Same `Engine` as step 01 — add 3 parameters, `limiter`, `torque`, and 3 ports on the outline*

<!--
**Say:** You do not start a new component. Open the Engine from step 1,
under Components, then MyCar, then Engine, and keep adding to it. The two blocks you
already have are the second and third in this row.

**Point at:** the outline rectangle and the three ports on it. A port on the
outline is what another component connects to; that is how the car plugs into this engine in
step 05.

**Order on the page:** A open it · B parameters · C limiter, torque, ports ·
D bench · E run and plot. Walk the room after C — a broken engine makes D impossible.
-->

---

## Every push needs something to push against

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

> **Where this bites today**
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
model with a loose support has the same problem, and Dyad refuses to run it.

**The sign rule, slowly:** Dyad counts force as positive when it flows
*into* a block. The tire pushes the car forward, so the car pushes the tire
backward — the force flowing into the tire is backward, so it is negative. Step 09 writes
exactly that line: `flange.f = -F_x`. Every Dyad and Modelica library uses this
rule. It looks backwards the first time, and it is the most common cause of a car that
drives in reverse.
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
**Say — name each value once:** A number that a part needs becomes a
parameter of the component. You add it with **Add parameter** in the
component panel, and the part refers to it by name. Then setting T max to 200 on the
Engine changes the ceiling in one place. The delay time, theta e, is a structural
parameter, because the Padé delay block builds its coefficients when the model compiles.
If the panel offers no structural option, paste that line into the code.

**Say:** The value 200 is above the ceiling on purpose. The plot should
show the limiter doing its job.

**They get wrong:** leaving `support` unconnected in the bench.
A torque source needs something to push against — the engine mounts. The compile error
talks about an unbalanced system; the fix is the `Fixed`.

**Why `y_min = 0`:** the engine cannot brake through this
path. Ask the room what would happen at a negative command without it.
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

**Tutor:** say the "new component of its own" part out loud — students try
to draw the bench inside `Engine`.

**They get wrong:** the analysis name. The plot command calls
`MyCar.EngineStepTransient()`; if Dyad Studio picked another name, change the word
after `analysis` in its code. The code block on this slide is the fallback.

**If it does not appear in Analyses:** Dyad Compile under Julia Commands.
-->

---

## Plot one signal, not all of them

<div class="grid grid-cols-2 gap-8">
<div>

```julia [Julia REPL]
using MyCar, Plots
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
that curve by name with the idxs argument.

**Point at:** the flat start. The command arrived at 0.5 s; torque starts
at about 0.8 s. That 0.3 s is the transport delay. The small wiggles before it are the
Padé approximation of a delay, not physics — the next slide explains them.

**Open the REPL:** Actions panel title bar → Dyad: Open Julia REPL.

**They get wrong:** `using MyCar` fails if the library was
named differently. Use their library's name.
-->

---

## A delay the computer can handle

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
**Say:** The delay is the only block that is not exactly what it says. It
is an approximation. That is fine, as long as you know it, and the wiggles are how you see
it.

**For a student who wants the math:** a delay of θ has the transfer function
e<sup>−sθ</sup>. A Padé approximation replaces it by a ratio of polynomials. The simplest
one is (1 − sθ/2)/(1 + sθ/2). `PadeDelay(n = 6, m = 5)` uses a 6th-order
denominator and a 5th-order numerator; they match e<sup>−sθ</sup> to order 11. Because the
numerator is lower order, a sudden step cannot pass straight through before the delay has
elapsed.

**Why structural:** the block computes its internal coefficients from the
delay when the model is compiled, so a new delay value means a new model, not just a new
number.
-->

---

## Why keep the delay and the lag at all?

<div class="grid grid-cols-2 gap-8">
<div>

Without them, the torque appears the instant you ask for it. Then:

- the car becomes too easy to control — any controller works, and there is nothing to
  learn;
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
**Say:** Both lags are physically real, but that is not the main reason
they are here. They are here because the question is control. Pushing a door that opens
instantly is easy. Pushing one that answers half a second late makes you overshoot. That
lateness is what makes control interesting, and difficult.

**For the tutor — the precise reasons** (from the lecture plan):

- Without the lags, the car is *first order*: one state, speed. A first-order
  system under a proportional controller never oscillates, however high the gain.
  Ziegler–Nichols needs that oscillation to measure anything.
- Cohen–Coon fits a model "first order plus dead time" and divides by the dead time.
  With no delay, it divides by zero.
- With no lag there is little overshoot, so the derivative part of PID has nothing to
  do.
-->
