---
routeAlias: pid
layout: section
---

###### Notebook 05

# Proportional-integral-derivative

Three terms, three jobs: present, past, future.

`notebooks/lecture01/05-pid.ipynb`

<!--
**Say:** second boolean. `with_D = true`. That is the only change from the last notebook, and
it completes the controller that runs most of the machinery you will ever work on.

**Timing:** 12 minutes. The three-contributions plot is the one to spend time on — it is the
only place in the lecture where you can see the division of labor directly rather than infer
it.

**Cut order:** this is spine — do not cut it. The lecture is not complete without it.
-->

---

## The third path

$$
u \;=\; k\left(e \;+\; \frac{1}{T_i}\int_0^t e\,d\tau \;+\; T_d\,\frac{de}{dt}\right)
$$

<div class="grid grid-cols-3 gap-6">
<div>

### Present

Proportional. How far off am I *now*?

</div>
<div>

### Past

Integral. How long have I been off?

</div>
<div>

### Future

Derivative. How fast am I closing?

</div>
</div>

> **What the derivative actually does**
>
> Closing on the setpoint fast means the error is shrinking fast — a large negative rate of
> change — so the derivative path subtracts from the output and takes the foot off early. It
> brakes *on approach*, not on arrival.

<!--
**Say:** the derivative does not know where the setpoint is. It only knows how fast the error
is moving. That is enough to anticipate an overshoot before it happens, and it is why the
derivative is sometimes called a prediction — a one-term Taylor extrapolation, nothing more
mystical than that.

**They get wrong:** thinking the derivative pushes harder when you are far away. It does the
opposite. Far away and closing quickly, it is already pulling back.

**Flag forward:** in a real controller this is not a pure derivative — there is a filter on
it, and section 07 shows what happens without one. Mention it now in one sentence so the `Nd`
parameter is not a surprise later.

**Readout — every symbol on this slide**

- **de/dt** — the rate of change of the error, km/h per second. Negative while closing on the
  setpoint.
- **T<sub>d</sub>** — the *derivative time*, in seconds. It multiplies, so bigger is more
  derivative action — the opposite convention to T<sub>i</sub>.
- **N<sub>d</sub>** — the derivative filter coefficient, mentioned here and explained in
  section 07. A real derivative is always filtered.
-->

---

## Two ways to write the same controller

<div class="grid grid-cols-2 gap-8">
<div>

#### Parallel form — three independent gains

$$
u \;=\; K_p\,e \;+\; K_i\!\int_0^t\! e\,d\tau \;+\; K_d\,\frac{de}{dt}
$$

*What the course slides show, and what most code and most textbooks use.*

</div>
<div>

#### Standard form — one gain and two times

$$
u \;=\; k\left(e + \frac{1}{T_i}\!\int_0^t\! e\,d\tau + T_d\,\frac{de}{dt}\right)
$$

*What `LimPID` takes, and what this lecture uses throughout.*

</div>
</div>

<div class="grid grid-cols-2 gap-8">
<div>

| From standard to parallel | and back |
|---|---|
| $K_p = k$ | $k = K_p$ |
| $K_i = k/T_i$ | $T_i = K_p/K_i$ |
| $K_d = k\,T_d$ | $T_d = K_d/K_p$ |

</div>
<div>

> **Why this slide exists**
>
> The two forms are the same controller and they are not the same numbers. Handing somebody a
> $K_i$ where they expected a $T_i$ inverts the meaning of "bigger" — and the tuning tables in
> section 08 are written in the standard form.

</div>
</div>

<!--
**Say:** there is no deep content on this slide and it will still save you an afternoon one
day. Every PID library picks one of these two conventions and they rarely say which on the
front page.

**Point at** the middle row. In the parallel form a bigger number means more integral action.
In the standard form a bigger number means *less*, because $T_i$ divides. Same controller,
opposite intuition.

**Ask the room:** which form makes the units easier? *(Standard. $T_i$ and $T_d$ are seconds,
which you can compare against the plant's own time constant — and that comparison is how you
sanity-check a gain set. $K_i$ is in N·m per km/h per second, which means nothing to
anybody.)*

**Readout — every symbol on this slide**

- **K<sub>p</sub>, K<sub>i</sub>, K<sub>d</sub>** — the parallel form: three independent
  gains. K<sub>i</sub> is N·m per km/h per second; K<sub>d</sub> is N·m per km/h per
  second<sup>-1</sup>.
- **k, T<sub>i</sub>, T<sub>d</sub>** — the standard (ISA) form: one gain and two times, in
  seconds.
- **K<sub>p</sub> = k, K<sub>i</sub> = k/T<sub>i</sub>, K<sub>d</sub> = k·T<sub>d</sub>** —
  the conversion, left to right.
- **T<sub>i</sub> = K<sub>p</sub>/K<sub>i</sub>, T<sub>d</sub> = K<sub>d</sub>/K<sub>p</sub>**
  — and back.
-->

---

## What tuning actually is

$$
C(s) \;=\; k\left(1 + \frac{1}{T_i s} + T_d s\right)
     \;=\; \underbrace{k}_{\text{gain}}\;
       \frac{\overbrace{T_i T_d\,s^2 + T_i\,s + 1}^{\text{two zeros}}}
            {\underbrace{T_i\,s}_{\text{a pole at the origin}}}
$$

<div class="grid grid-cols-2 gap-8">
<div>

- The **pole at the origin** is the integrator. You do not get to move it; it is what kills
  steady-state error.
- The **two zeros** are yours to place, and where you put them is set by $T_i$ and $T_d$.
- The **gain** slides the whole thing up and down.

</div>
<div>

> **So**
>
> Everything anyone has ever written about PID tuning — root locus, loop shaping, the three
> tables in section 08, and turning the knob until it looks right — is a method for answering
> the same question: **where do the two zeros go, and how much gain?**

</div>
</div>

*A real controller has one more pole, from the filter on the derivative — section 07's $N_d$.*

<!--
**Say:** if you have had a linear systems course, this is where PID stops looking like three
heuristic knobs and starts looking like an ordinary compensator design. If you have not, take
the sentence in the box and move on — it is still true and still useful.

**Say:** and it explains why there are so many tuning methods that all work. They are
answering one question with three free parameters, and several different routes get to a good
answer.

**Flag forward:** the methods in section 08 do not look like zero placement at all — they look
like arithmetic on measured numbers. That is exactly their appeal: somebody else did the zero
placement for a whole family of plants and left you a table.

**Readout — every symbol on this slide**

- **s** — the Laplace variable. Multiplying by s is differentiating; dividing is integrating.
- **C(s)** — the controller's transfer function: output over input, in the frequency domain.
- **Pole** — a root of the denominator. The one at the origin (s = 0) is the integrator, and
  we do not get to move it.
- **Zero** — a root of the numerator. PID has two, and where you put them is exactly what
  T<sub>i</sub> and T<sub>d</sub> decide.
- **Loop gain** — the k out front, which slides the whole response up and down.
-->

---

## P, PI and PID, one step

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [05-pid.ipynb · cell 2. Two decisions before the first run]
controller(; with_I, with_D) = Scenarios.CruiseLoopStep(;
    name = :CruiseLoopStep, with_I = with_I, with_D = with_D)

p_only  = Scenarios.CruiseLoopTransient(
    k = GAIN, T_max = UNLIMITED, y_max = UNLIMITED, stop = 60.0)
pi_loop = Scenarios.CruiseLoopTransient(
    model = controller(with_I = true, with_D = false),
    k = GAIN, Ti = T_I, T_max = UNLIMITED, y_max = UNLIMITED, stop = 60.0)
pid_loop = rerun(
    Scenarios.CruiseLoopTransient(
        model = controller(with_I = true, with_D = true),
        k = GAIN, Ti = T_I, Td = T_D, wd = 0.0,
        T_max = UNLIMITED, y_max = UNLIMITED, stop = 60.0),
    "loop.controller.xd0" => -V_START)
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/05-pid.ipynb)

</div>
<div>

![Three step responses on one axes: P settling below the setpoint, PI reaching it with overshoot, PID reaching it with the overshoot suppressed.](/figures/05-p-pi-pid.svg)

*The spine of the lecture: short of target, past target, on target.*

</div>
</div>

<!--
**This plot is the lecture in one picture.** Give it a full minute of silence before you say
anything.

**Point at** each curve in turn and let the room name the failure: P stops short; PI arrives
but goes past; PID arrives and stays.

**Say:** every one of these is the same car and the same *k*. Nothing physical changed
between them. Three lines of configuration.

**Ask the room:** if a colleague showed you only the PID curve, what could you not tell?
*(Whether it is well tuned or merely lucky. Which is exactly why section 08 exists.)*

**Readout — every symbol on this slide**

- **k = 56, T<sub>i</sub> = 10 s, T<sub>d</sub> = 0.5 s** — one gain set, three controllers.
- **wd = 0.0** — the derivative setpoint weight. Zero means the derivative acts on the
  *measurement* only, not on the setpoint, so a step in the setpoint does not produce an
  infinite kick. Standard practice, and why the code sets it.
- **xd0** — the derivative block's initial state, preloaded with the starting speed so the run
  does not begin with a spurious transient.
- **V_START = 90 km/h** — where the car is before the step.
-->

---

## Who does what, and when

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [05-pid.ipynb · cell 3. The three contributions]
# each path's state, scaled by k so every trace is in N.m
contribution(run, path) = (signal(run, path)[1],
                           GAIN .* signal(run, path)[2])

t_p, u_p = contribution(pid_loop, "loop.controller.proportional.y")
t_i, u_i = contribution(pid_loop, "loop.controller.integrator.y")
t_d, u_d = contribution(pid_loop, "loop.controller.derivative.y")
t_u, u_cmd = signal(pid_loop, "loop.controller.y")
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/05-pid.ipynb)

</div>
<div>

![Three traces of controller output: a proportional spike at the step decaying away, an integral trace rising to a constant, and a derivative pulse that is zero before and after the transient.](/figures/05-three-contributions.svg)

*Proportional carries the transient. Integral holds the steady state. Derivative exists only while the error is moving — zero at both ends.*

</div>
</div>

<!--
**Point at** the three traces in order and narrate them:

- Proportional: jumps at the step, then decays to almost nothing. It has done its job in the
  first few seconds and then it retires.
- Integral: starts at the old cruise torque, climbs, and settles at the new one. It does
  almost nothing at the step and everything at the end.
- Derivative: zero before the step, a pulse during the transient, zero after. It is only ever
  present while something is changing.

**Say:** this is the answer to "which gain should I turn". They are not three knobs on the
same thing. They act at different times, and the symptom tells you which one to reach for.

**Ask the room:** at t = 100 s, which term is holding the car at 110 km/h? *(Only the
integral. The other two are at zero. Make them say it out loud.)*

**Readout — every symbol on this slide**

- **proportional.y, integrator.y, derivative.y** — each path's own output inside `LimPID`,
  before the shared gain.
- **× k** — every trace is multiplied by the gain so all four are in newton-metres and can
  share an axis.
- **controller.y** — the sum, which is what the engine is actually asked for.
- **Zero at both ends** — the derivative before the step and after settling, because the error
  is not moving at either time.
-->

---

## How much derivative

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [05-pid.ipynb · cell 4. Choosing Td]
TDS = [0.1, 0.25, 0.5, 1.0, 2.0, 4.0]

td_family = sweep(pid_loop, "Td", TDS)

plot_sweep(td_family; sig = SPEED, setpoint = 110, name = "Td",
           xlims = (0, 40))
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/05-pid.ipynb)

- Too little: the overshoot survives.
- Too much: sluggish, and jittery — braking against every wobble.

</div>
<div>

![Four step responses at increasing derivative time: overshoot shrinks and then the response becomes slow and ragged.](/figures/05-td-family.svg)

*There is a middle. Past it, more derivative makes the response worse in a different way.*

</div>
</div>

<!--
**Say:** notice that "more" stops helping. Proportional and integral both trade one property
for another monotonically; the derivative has an optimum, and past it the cure is worse than
the disease.

**Point at:** the raggedness in the largest-*T<sub>d</sub>* curve. Say: and this is on a
perfectly clean measurement. Put one per cent of speedometer noise on the signal and that
curve becomes unusable — section 07.

**Ask the room:** in a car, what does an aggressive derivative feel like to a passenger?
*(Surging — the controller reacting to every small change. There is a comfort requirement
hiding in the gain set.)*

**Readout — every symbol on this slide**

- **T<sub>d</sub> = 0.1, 0.25, 0.5, 1.0, 2.0, 4.0 s** — the sweep.
- **xlims = (0, 40)** — the window, in seconds.
- **Sluggish** — the response takes longer to arrive. **Jittery** — it reacts to small changes
  it should ignore.
-->

---

## Why P, PI and PD all have names

<div class="grid grid-cols-2 gap-8">
<div>

Set a gain to zero and that path disappears. What is left gets named after the letters that
remain:

| Controller | Paths | In our model |
|---|---|---|
| P | present | `with_I = false, with_D = false` |
| PI | present, past | `with_I = true, with_D = false` |
| PD | present, future | `with_I = false, with_D = true` |
| PID | all three | `with_I = true, with_D = true` |

</div>
<div>

> **Which is what we have been doing**
>
> Sections 03, 04 and 05 are one Dyad model with two booleans flipped. There is no separate
> "P controller" anywhere in this repository — and there should not be, because they are not
> separate things.

**Open in Dyad** `dyad/Lecture1/CruiseLoop.dyad`

</div>
</div>

<!--
**Say:** PID is not an algorithm you pick off a shelf. It is a family, and you select a member
by deciding which of the three questions your plant actually needs answered.

**Ask the room:** when would you deliberately leave the integrator out? *(When the plant
already integrates — a motor position loop, where holding a position needs no effort. Adding
a second integrator there mostly buys you oscillation.)*

**Say:** and when would you leave the derivative out? *(When the measurement is noisy and you
cannot filter it enough. Which is most of the time — a large fraction of industrial loops in
service are PI, not PID.)*

**In the model:** The two **`structural parameter`** lines, and the single `LimPID` they
configure. Four controllers, one file, twelve lines apart.

**Terms, if anyone asks**

- **P** present only. **PI** present and past. **PD** present and future. **PID** all three.
- **Why leave the integrator out** — when the plant already integrates, e.g. a motor position
  loop, where holding position costs nothing.
- **Why leave the derivative out** — when the measurement is too noisy to differentiate. Most
  industrial loops in service are PI.
-->

---

## What this bought us

- A controller that reaches the setpoint and does not overshoot getting there.
- A picture of which term does what, and when — the thing to consult when a loop misbehaves.
- Four controllers from two booleans.

### Next: the engine runs out of torque, and the integrator does not notice. <Link to="windup">→ 06, integral windup</Link>

<!--
**Say:** everything up to here has been on flat road with a step the engine could easily
deliver. Every plot has been well behaved. Now we point the car up a hill it cannot climb, and
the nice linear story breaks in a way that has hurt real hardware.
-->
