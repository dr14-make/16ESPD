---
routeAlias: pid
layout: section
---

###### Notebook 05

# Proportional-integral-derivative

P, I and D: the present error, the past error, and its rate of change.

`notebooks/lecture01/05-pid.ipynb`

<!--
The second switch, `with_D = true`, is the only change. It completes the PID controller, which
runs most of the machinery you will work on.
-->

---

## The derivative term

$$
u \;=\; k\left(e \;+\; \frac{1}{T_i}\int_0^t e\,d\tau \;+\; T_d\,\frac{de}{dt}\right)
$$

<div class="grid grid-cols-[1fr_1.5fr] gap-8">
<div>

### Present

Proportional. How far off am I *now*?

### Past

Integral. How long have I been off?

### Future

Derivative. How fast is the error changing?

</div>
<div>

![The speed error of the PID step run over its first seconds. At one moment, marked now, the error's value is the proportional term, the shaded area under the curve up to now is the integral, and the tangent line at now is the derivative.](/figures/05-present-past-future.svg)

</div>
</div>

> **What the derivative does**
>
> Closing on the setpoint fast means the error is shrinking fast, a large negative rate of
> change. So the derivative path subtracts from the output and reduces the torque *before* the
> car arrives.

<!--
The derivative does not know where the setpoint is. It only knows how fast the error is moving.
That is enough to see an overshoot coming, which is why it is sometimes called a prediction: a
one-term Taylor extrapolation of the error.

d e by d t is negative while we close on the setpoint. T d is in seconds, and it multiplies, so
bigger means more derivative action, the opposite convention to T i.

A common mistake is to think the derivative pushes harder when you are far away. Far away and
closing quickly, it is already pulling back.

A real controller never uses a pure derivative. There is always a filter on it, with a coefficient
called N d. Section 07 shows what happens without one.
-->

---
routeAlias: build-derivative
---

## Build: the derivative path

<div class="grid grid-cols-2 gap-6">
<div>

![CruiseController in progress: add_d into derivative on add_pid's second input, with the derivative's parameter panel showing k = Td and T = Td/Nd.](/img/lecture-01/step05-derivative.png)

</div>
<div>

![plant.v_kmh and controller.y for the PID loop.](/img/lecture-01/step05-pid-plot.png)

</div>
</div>

*Parameters `Td` = 0.5, `Nd` = 10, `wd` = 0, `xd0` = −90 · delete `zero_d` · `add_d` Add(k1 = wd, k2 = −1) from `u_s`, `u_m` ·
`derivative` Derivative(k = Td, T = Td/Nd, x0 = xd0) → `add_pid.u2`*

**Real controllers almost never differentiate the setpoint. D sees only the speed.**

```julia
using MyCar, Plots; plotly()
r = MyCar.CruiseLoopTransient()
top = plot(r; idxs = [r."plant.v_kmh", r."demand.y"])
bottom = plot(r; idxs = r."controller.y")
plot(top, bottom; layout = (2, 1), link = :x, xlims = (0, 40))
```

[page: step 5](../lecture/lecture-01/#step-5) · reference `dyad/Lecture1/CruiseController.dyad`

<!--
This derivative is filtered, and it may ignore the setpoint. You type both parameters now and
understand them in section 07.

In `CruiseController`, add four parameters: `Td` equals 0.5, of type `Time`; `Nd` equals 10; `wd`
equals 0; `xd0` equals minus 90. `k` and `Ti` stay.

Delete `zero_d` and its wire.

Drag in an Add from `BlockComponents.Math`, name it `add_d`, set k one to `wd` and k two to minus
1, and place it below the integrator. Wire `u_s` into `add_d.u1`, and `u_m` into `add_d.u2`. It is
a second error block with its own setpoint weight. At `wd` equals 0 it is just minus `u_m`, so the
derivative acts on the measurement only.

Drag in a Derivative from `BlockComponents.Continuous`, name it `derivative`, and set k to `Td`, T
to `Td` over `Nd`, and x zero to `xd0`. Wire `add_d.y` into `derivative.u`, and `derivative.y`
into `add_pid.u2`.

Save, run `CruiseLoopTransient` again, and plot `plant.v_kmh` with `demand.y`, and `controller.y`
below.

Why is `wd` zero? Real controllers almost never differentiate the setpoint. This is the standard
two-degree-of-freedom PID: P acts on `wp` times r minus y, I on the full error, D on `wd` times r
minus y. The library's `LimPID` builds `add_p` and `add_d` the same way. Industrial controllers
call `wd` equals 0 PI-D, or derivative on measurement, and make it the default.

Why is `xd0` minus 90? At `wd` equals 0 and a settled 90 km/h cruise, the filter's input is minus
90, so that is where the filter starts. The reference `CruiseLoop` computes it the same way. Leave
it at 0 and the filter sees a 90 km/h step at time zero and commands a spike of minus 50400
newton-meters.

The speed reaches **110 km/h** and peaks at about 114, against 115.5 in step 4. Your engine's 150
newton-meter ceiling still clips the start, so you overshoot more than the notebook. In
`controller.y`, the jump at the step is the proportional term, 56 times 20 newton-meters. No
derivative spike rides on it.

A common mistake is T set to `Td` times `Nd` instead of `Td` over `Nd`. The filter is then 100
times slower than the derivative, and the D term does almost nothing.
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

*What `CruiseController` takes, and what this lecture uses throughout.*

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

> **Check which form you are given**
>
> The two forms describe the same controller with different numbers. Handing somebody a
> $K_i$ where they expected a $T_i$ reverses the meaning of "bigger", and the tuning tables in
> section 08 are written in the standard form.

</div>
</div>

<!--
Every PID library picks one of these two conventions, and the documentation rarely says which up
front. The conversion is on the slide.

Look at the middle row. In the parallel form a bigger number means more integral action. In the
standard form it means **less**, because T i divides.

The standard form has the easier units. T i and T d are seconds, which you can compare against the
plant's own time constant, and that is how you sanity-check a gain set. K i and K d have units
nobody can picture.
-->

---

## PID as a transfer function

$$
C(s) \;=\; k\left(1 + \frac{1}{T_i s} + T_d s\right)
     \;=\; \underbrace{k}_{\text{gain}}\;
       \frac{\overbrace{T_i T_d\,s^2 + T_i\,s + 1}^{\text{two zeros}}}
            {\underbrace{T_i\,s}_{\text{a pole at the origin}}}
$$

<div class="grid grid-cols-2 gap-8">
<div>

- The **pole at the origin** is the integrator. You cannot move it; it is what removes
  steady-state error.
- The **two zeros** are yours to place, and where you put them is set by $T_i$ and $T_d$.
- The **gain** scales the whole controller.

</div>
<div>

> **Every tuning method answers one question**
>
> Root locus, loop shaping, the three tables in section 08, and turning the knob until it looks
> right all answer the same question: **where do the two zeros go, and how much gain?**

</div>
</div>

*A real controller has one more pole, from the filter on the derivative, set by section 07's $N_d$.*

<!--
If you have had a linear systems course, this slide shows PID as an ordinary compensator design.
If you have not, remember the sentence in the box and move on.

s is the Laplace variable: multiplying by s differentiates, dividing by s integrates. The pole at
s equals 0 is the integrator, and we do not get to move it. PID has two zeros, and T i and T d
decide where they go. k scales the whole controller.

That is why so many tuning methods work: one question, three free parameters, several routes to a
good answer. The methods in section 08 look like arithmetic on measured numbers. Somebody else did
the zero placement for a whole class of plants and published a table.
-->

---

## P, PI and PID, one step

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [05-pid.ipynb · cell 2. Two decisions before the first run]
controller(; with_I, with_D) = Scenarios.CruiseLoopStep(;
    name = :CruiseLoopStep, with_I = with_I, with_D = with_D)

p_only  = Scenarios.CruiseLoopTransient(
    model = controller(with_I = false, with_D = false),
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

*P settles short of the target, PI overshoots it, PID reaches it with little overshoot.*

</div>
</div>

<!--
P stops short. PI reaches the setpoint but overshoots. PID reaches it and stays.

Same car, same gains: k equals 56, T i equals 10 seconds, T d equals 0.5 seconds. Only the
controller configuration changed.

`wd` equals 0.0 keeps the setpoint step out of the derivative. `xd0` is preloaded from the
starting speed, 90 km/h, so the run does not begin with a spurious transient.

From this one curve you cannot tell whether the gains are well tuned or just suit this one step.
Section 08 tunes them properly.
-->

---

## The three terms during the step

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [05-pid.ipynb · cell 3. The three contributions]
# each path's state, scaled by k so every trace is in N.m
contribution(run, path) = (signal(run, path)[1],
                           GAIN .* signal(run, path)[2])

t_p, u_p = contribution(pid_loop, "loop.controller.error.y")
t_i, u_i = contribution(pid_loop, "loop.controller.integrator.y")
t_d, u_d = contribution(pid_loop, "loop.controller.derivative.y")
t_u, u_cmd = signal(pid_loop, "loop.controller.y")
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/05-pid.ipynb)

</div>
<div>

![Three traces of controller output: a proportional spike at the step decaying away, an integral trace rising to a constant, and a derivative pulse that is zero before and after the transient.](/figures/05-three-contributions.svg)

*Proportional carries the transient. Integral holds the steady state. Derivative is nonzero only while the error is changing, and zero at both ends.*

</div>
</div>

<!--
Each trace is one path's output times k, so all three are in newton-meters on one axis.

Proportional jumps at the step to 1120 newton-meters, 56 times the 20 km/h error, then shrinks to
almost nothing.

Integral starts at zero, because this run seeds it at zero. It overshoots to about 75
newton-meters and settles at 40.2, the torque that holds 110. Almost nothing at the step, all of
the torque at the end.

Derivative swings through a pulse during the transient and returns to zero. It is only present
while something is changing.

`controller.y` is the sum: what the engine is actually asked for.

The terms act at different times, so when the response misbehaves tells you which term to adjust.

At 10 seconds, the right edge, the integral holds about 57 newton-meters, the proportional pulls
back at about minus 19, and the derivative is near zero. By 60 seconds the integral holds the car
alone, at 40.2.
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
- Too much: sluggish, and jittery, reacting to every small change.

</div>
<div>

![Six step responses at increasing derivative time: overshoot shrinks and then the response becomes slow and ragged.](/figures/05-td-family.svg)

*There is an optimum. Above it, more derivative makes the response slower and more ragged.*

</div>
</div>

<!--
More proportional or integral action trades one property for another, steadily. The derivative has
an optimum, and above it the response gets worse.

Too little and the overshoot survives. Too much and the response is sluggish, slower to arrive,
and jittery, reacting to small changes it should ignore.

Look at the raggedness of the largest T d, with a clean measurement. Add one percent of
speedometer noise and that curve becomes unusable. That is section 07.

To a passenger, an aggressive derivative feels like surging. Comfort limits the gains too.
-->

---

## P, PI, PD and PID

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

> **One model for all four**
>
> Sections 03, 04 and 05 are one Dyad model with two booleans flipped. There is no separate
> "P controller" anywhere in this repository, because P is PID with two paths switched off.

**Open in Dyad** `dyad/Lecture1/CruiseLoop.dyad`

</div>
</div>

<!--
You pick a member of the family by deciding which terms your plant needs.

Leave the integrator out when the plant already integrates, like a motor position loop, where
holding a position needs no effort. A second integrator there mostly adds oscillation.

Leave the derivative out when the measurement is noisy and you cannot filter it enough. That is
most of the time: a large fraction of industrial loops in service are PI.

In the reference, `with_I` drives `i_switch` and `with_D` drives `d_switch`, so all four
controllers are one diagram. Your controller has no switches: it is the PID row, built by hand.
-->

---
routeAlias: checkpoint-pid
---

## Checkpoint PID

<div class="grid grid-cols-2 gap-8">
<div>

#### Your controller now

- `error` → `add_pid`, three inputs: `error` straight, `integrator` on `u3`, `add_d` →
  `derivative` on `u2`.
- `add_pid` → `gain` → `y`.
- Parameters `k` = 56, `Ti` = 10, `xi0` = 0, `Td` = 0.5, `Nd` = 10, `wd` = 0, `xd0` = −90.

#### Your run shows

`plant.v_kmh` at **110 km/h** with less overshoot than PI (a peak of about 114 km/h), and no derivative spike in
`controller.y`.

</div>
<div>

> **Behind? Rejoin here**
>
> Paste the step 5 code from the guide page's [step 5](../lecture/lecture-01/#step-5) into
> `CruiseController` and `CruiseLoopStep`, or open `Lecture1.Step05`. Section 06 builds on this
> diagram.

</div>
</div>

<!--
Second checkpoint. You drew every block of this controller. Check your neighbor's screen.

If you are still building, paste the step 5 code from the guide page over your `CruiseController`
and `CruiseLoopStep`, or open `Lecture1.Step05` in the course repository. Section 06 adds a
limiter to **this** diagram, so do not go into the break without it.

If your run differs from mine, check the signs of `add_d`, then the derivative's T, which must be
`Td` over `Nd`, then `xd0`.
-->

---

## Summary of section 05

- A controller that reaches the setpoint and overshoots far less getting there.
- A plot of what each term does, and when. Use it to find the term to adjust when a loop
  misbehaves.
- Four controllers from two booleans.

### Next: the engine reaches its torque limit, and the integrator keeps accumulating. <Link to="windup">→ 06, integral windup</Link>

<!--
So far: flat road, and a step the engine could easily deliver. After the break the car meets a
hill it cannot climb. The torque limit makes the loop nonlinear, and this failure has damaged real
hardware.

Be at checkpoint PID before the break. It is your last chance to paste the reference before
section 06 builds on it.
-->
