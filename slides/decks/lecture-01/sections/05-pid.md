---
routeAlias: pid
layout: section
---

###### Notebook 05

# Proportional-integral-derivative

P, I and D: the present error, the past error, and its rate of change.

`notebooks/lecture01/05-pid.ipynb`

<!--
The second switch, `with_D = true`, is the only change from the last notebook. It completes the
PID controller, which runs most of the machinery you will work on.
-->

---

## The derivative term

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

Derivative. How fast is the error changing?

</div>
</div>

> **What the derivative does**
>
> Closing on the setpoint fast means the error is shrinking fast, a large negative rate of
> change. So the derivative path subtracts from the output and reduces the torque *before* the
> car arrives.

<!--
The derivative does not know where the setpoint is. It only knows how fast the error is
moving. That is enough to anticipate an overshoot before it happens, which is why the
derivative is sometimes called a prediction. It is a one-term Taylor extrapolation of the error.

d e by d t is the rate of change of the error, in km/h per second. It is negative while we are
closing on the setpoint. T d is the derivative time, in seconds. It multiplies, so bigger
means more derivative action. That is the opposite convention to T i.

A common mistake is to think the derivative pushes harder when you are far away. It does the
opposite. Far away and closing quickly, it is already pulling back.

In a real controller this is not a pure derivative. There is always a filter on it, with a coefficient called N d. Section 07 shows
what happens without one.
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
The third term needs the error's rate of change. It differs from the textbook derivative in two
ways. It is filtered, and it may ignore the setpoint. Both are parameters you
type now and understand fully in section 07.

Let's build it together, in `CruiseController`.

First, add four parameters. `Td` equals 0.5, in seconds, of type `Time`. `Nd` equals 10. `wd`
equals 0. And `xd0` equals minus 90. These are the notebook's values. `k` equals 56 and `Ti`
equals 10 stay as they are.

Now delete `zero_d` and its wire. `add_pid.u2` is free again.

Drag in an Add block from `BlockComponents.Math` and name it `add_d`. Set k one to `wd` and k
two to minus 1. Place it below the integrator. Wire `u_s` into `add_d.u1`, and `u_m` into
`add_d.u2`. This is a second error block with its own setpoint weight. At `wd` equals 1 it
would be the error itself. At `wd` equals 0 it is just minus `u_m`, so the derivative acts on
the measurement only.

Next, drag in a Derivative from `BlockComponents.Continuous` and name it `derivative`. Set k to
`Td`, T to `Td` over `Nd`, and x zero to `xd0`. Wire `add_d.y` into `derivative.u`, and
`derivative.y` into `add_pid.u2`.

Save, and run `CruiseLoopTransient` again from `CruiseLoopStep`.

Plot `plant.v_kmh` with `demand.y`, and `controller.y` in a panel below. The code is on the
slide.

Why is `wd` zero? Look at the bold line on the slide. Real controllers almost never
differentiate the setpoint. This is the standard two-degree-of-freedom PID. P acts on `wp`
times r minus y. I acts on the full error. D acts on `wd` times r minus y. The library's
`LimPID` builds `add_p` and `add_d` the same way. Industrial controllers offer it as a
structure switch, and their default, called PI-D or derivative on measurement, is `wd` equals
0. Section 07 shows you what `wd` equals 1 does.

Why is `xd0` minus 90? The filter's input is `wd` times `u_s` minus `u_m`. At `wd` equals 0
and a settled 90 km/h cruise, that is minus 90. The seed is `wd` minus 1, times m zero, with m
zero equal to 90. That is the value the filter would hold at that cruise, and the reference
`CruiseLoop` computes it the same way. If you leave it at 0, the filter sees a 90 km/h step at
time zero and commands a spike of minus 50400 newton-meters. That is minus k times N d times m
zero.

You should see the speed reach **110 km/h** with less overshoot than in step 4. The peak is
about 114 km/h, against 115.5 before. Your engine's 150 newton-meter ceiling still clips the
start, so your curve overshoots more than the notebook's. The notebook lifts that ceiling, and
your engine keeps it. In `controller.y`, the jump at the setpoint step is the proportional
term, 56 times 20 newton-meters, as in step 4. No derivative spike rides on it. This is the PID
curve of the P, PI and PID slide coming up.

A common mistake is setting T to `Td` times `Nd` instead of `Td` over `Nd`. The filter then
becomes 100 times slower than the derivative it is meant to smooth, and the D term does almost
nothing.
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
Every PID library picks one of these two conventions, and the documentation rarely says which
up front.

The parallel form has three independent gains, K p, K i and K d. The standard form, also
called the ISA form, has one gain k and two times, T i and T d, in seconds. To go from standard
to parallel, K p is k, K i is k over T i, and K d is k times T d. To go back, T i is K p over K
i, and T d is K d over K p.

Look at the middle row. In the parallel form a bigger number means more integral action. In
the standard form a bigger number means **less**, because T i divides. The controller
is the same, but "bigger" means the opposite.

The standard form has easier units. T i and T d are seconds, which you can
compare against the plant's own time constant. That comparison is how you sanity-check a gain
set. K i is in newton-meters per km/h per second, and K d is in newton-meters per km/h per
second to the minus one. Those units are hard to interpret.
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
If you have had a linear systems course, this slide shows PID as an ordinary compensator design
rather than three separate knobs. If you have not, remember the sentence in the box and move on.

Here s is the Laplace variable. Multiplying by s is differentiating, and dividing by s is
integrating. C of s is the controller's transfer function: output over input, in the frequency
domain. A pole is a root of the denominator. The one at the origin, at s equals 0, is the
integrator, and we do not get to move it. A zero is a root of the numerator. PID has two, and
where they go is exactly what T i and T d decide. The gain k out front scales the whole
controller.

This also explains why there are so many tuning methods that all work. They answer one
question with three free parameters, and several different routes get to a good answer.

The methods in section 08 do not look like zero placement at all. They look like arithmetic on
measured numbers. That makes them easy to use: somebody else did the zero placement for a
whole class of plants and published a table.
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
This plot summarizes sections 03 to 05.

Look at each curve in turn. P stops short. PI reaches the setpoint but overshoots. PID reaches
it and stays.

Every one of these is the same car and the same k. One gain set: k equals 56, T i equals 10
seconds, T d equals 0.5 seconds. Nothing physical changed between them, only the
controller configuration.

The code sets `wd` to 0.0. That is the derivative setpoint weight. Zero means the derivative
acts on the measurement only, not on the setpoint, so a step in the setpoint does not produce
an infinite kick. That is standard practice. `xd0` is the derivative block's initial state. It
is preloaded from the starting speed, V start, which is 90 km/h, so the run does not begin
with a spurious transient.

From the PID curve alone you cannot tell whether the gains are well tuned or just happen to suit
this one step. Section 08 is about tuning them properly.
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
Let's go through the three traces in order. Each is a path's own output inside
`CruiseController`, multiplied by the gain k, so all of them are in newton-meters and share an
axis.

Proportional jumps at the step, to 1120 newton-meters, 56 times the 20 km/h error. It has done
its main job in the first few seconds. After that it shrinks, and by the end of the run it is
almost nothing.

Integral starts at zero. This run seeds the integrator at zero, so it has to build the
holding torque itself. It overshoots to about 75 newton-meters, then settles at 40.2. That is
the torque that holds 110 km/h. It contributes almost nothing at the step and all of the torque at the end.

Derivative starts at zero, swings through a pulse during the transient, and returns to zero.
It is only ever present while something is changing. At both ends the speed is not moving, so
the derivative is zero.

And `controller.y` is the sum. That is what the engine is actually asked for.

This tells you which gain to change. The three terms act at different times, so when the
response misbehaves tells you which term to adjust.

At the right edge of the plot, at t equals 10 seconds, the integral does most of the holding, at
about 57 newton-meters. The proportional is still pulling back, at
about minus 19, and the derivative is close to zero. By the end of the run, at 60 seconds, the
integral holds the car at 110 km/h alone, with 40.2 newton-meters. The other two are at zero.
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
Here more derivative stops helping. More proportional or integral action trades one property for
another, steadily. The derivative has an optimum, and above it the response gets worse.

We sweep T d through 0.1, 0.25, 0.5, 1.0, 2.0 and 4.0 seconds, and look at the first 40
seconds. Too little derivative and the overshoot survives. Too much and the response is
sluggish, meaning it takes longer to arrive, and jittery, meaning it reacts to small changes it
should ignore.

Look at the raggedness in the curve with the largest T d. This is with a clean measurement. Put one percent of speedometer noise on the signal and that curve becomes
unusable. That is section 07.

To a passenger, an aggressive derivative feels like surging, because the controller reacts to
every small change. So passenger comfort also limits the gains.
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
PID is a family of controllers. You choose a member by deciding which of the three terms your
plant needs.

Leave the integrator out when the plant already integrates. Take
a motor position loop, where holding a position needs no effort. Adding a second integrator
there mostly adds oscillation.

Leave the derivative out when the measurement is noisy and you cannot filter it enough. That is most of the time. A large fraction of industrial loops in service
are PI, not PID.

In the reference model, two on/off switches configure a single `CruiseController`. `with_I`
drives a block called `i_switch` between the integrator and the sum, and `with_D` drives
`d_switch` between the derivative and the sum. So all four controllers are one file and one diagram. Your own
controller has no switches. It is the PID row, built by hand. Where you used `zero_d` as a
placeholder on the way, the reference keeps the block and switches it off.
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
Second checkpoint. This is the controller that runs most of the machinery you will work on, and
you drew every block of it. Check your neighbor's screen.

If you are still building, paste the step 5 code from the guide page over your
`CruiseController` and `CruiseLoopStep`. Or open `Lecture1.Step05` in the course repository.
It is this exact checkpoint. Section 06 adds a limiter to **this** diagram, so do not go into
the break without it.

If your run differs from mine, compare against the reference `CruiseController` in this
order. First the signs of `add_d`. Then the derivative's T, which must be `Td` over `Nd`. Then
`xd0`.
-->

---

## Summary of section 05

- A controller that reaches the setpoint and overshoots far less getting there.
- A plot of what each term does, and when. Use it to find the term to adjust when a loop
  misbehaves.
- Four controllers from two booleans.

### Next: the engine reaches its torque limit, and the integrator keeps accumulating. <Link to="windup">→ 06, integral windup</Link>

<!--
Everything up to here has been on flat road with a step the engine could easily deliver. After the
break we send the car up a hill it cannot climb. The torque limit then makes the loop nonlinear,
and this failure has damaged real hardware.

Before the break, make sure you are at checkpoint PID. The break is your last chance to paste
the reference before section 06 builds on it.
-->
