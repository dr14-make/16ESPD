---
routeAlias: pid
layout: section
---

###### Notebook 05

# Proportional-integral-derivative

Three terms, three jobs: present, past, future.

`notebooks/lecture01/05-pid.ipynb`

<!--
Second boolean. `with_D = true`. That is the only change from the last notebook, and it
completes the controller that runs most of the machinery you will ever work on.
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
The derivative does not know where the setpoint is. It only knows how fast the error is
moving. That is enough to anticipate an overshoot before it happens. It is why the derivative
is sometimes called a prediction. It is a one-term Taylor extrapolation, nothing more mystical
than that.

d e by d t is the rate of change of the error, in km/h per second. It is negative while we are
closing on the setpoint. T d is the derivative time, in seconds. It multiplies, so bigger
means more derivative action. That is the opposite convention to T i.

A common mistake is to think the derivative pushes harder when you are far away. It does the
opposite. Far away and closing quickly, it is already pulling back.

One more thing, so it is not a surprise later. In a real controller this is not a pure
derivative. There is always a filter on it, with a coefficient called N d. Section 07 shows
what happens without one.
-->

---
routeAlias: build-derivative
---

## Build: the third path

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
The third term needs the error's rate of change. Two details make it a real derivative rather
than a textbook one. It is filtered, and it may ignore the setpoint. Both are parameters you
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

> **Why this slide exists**
>
> The two forms are the same controller and they are not the same numbers. Handing somebody a
> $K_i$ where they expected a $T_i$ inverts the meaning of "bigger" — and the tuning tables in
> section 08 are written in the standard form.

</div>
</div>

<!--
There is no deep content on this slide, and it will still save you an afternoon one day. Every
PID library picks one of these two conventions, and they rarely say which on the front page.

The parallel form has three independent gains, K p, K i and K d. The standard form, also
called the ISA form, has one gain k and two times, T i and T d, in seconds. To go from standard
to parallel, K p is k, K i is k over T i, and K d is k times T d. To go back, T i is K p over K
i, and T d is K d over K p.

Look at the middle row. In the parallel form a bigger number means more integral action. In
the standard form a bigger number means **less**, because T i divides. Same controller,
opposite intuition.

Which form makes the units easier? The standard form. T i and T d are seconds, which you can
compare against the plant's own time constant. That comparison is how you sanity-check a gain
set. K i is in newton-meters per km/h per second, and K d is in newton-meters per km/h per
second to the minus one. Those units mean nothing to anybody.
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
If you have had a linear systems course, this is where PID stops looking like three heuristic
knobs and starts looking like an ordinary compensator design. If you have not, take the
sentence in the box and move on. It is still true and still useful.

Here s is the Laplace variable. Multiplying by s is differentiating, and dividing by s is
integrating. C of s is the controller's transfer function: output over input, in the frequency
domain. A pole is a root of the denominator. The one at the origin, at s equals 0, is the
integrator, and we do not get to move it. A zero is a root of the numerator. PID has two, and
where they go is exactly what T i and T d decide. The gain k out front slides the whole
response up and down.

This also explains why there are so many tuning methods that all work. They answer one
question with three free parameters, and several different routes get to a good answer.

The methods in section 08 do not look like zero placement at all. They look like arithmetic on
measured numbers. That is exactly their appeal. Somebody else did the zero placement for a
whole family of plants and left you a table.
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

*The spine of the lecture: short of target, past target, on target.*

</div>
</div>

<!--
This plot is the lecture in one picture. Take a good look at it before I say anything.

Look at each curve in turn and name its failure. P stops short. PI arrives but goes past. PID
arrives and stays.

Every one of these is the same car and the same k. One gain set: k equals 56, T i equals 10
seconds, T d equals 0.5 seconds. Nothing physical changed between them. Three lines of
configuration.

The code sets `wd` to 0.0. That is the derivative setpoint weight. Zero means the derivative
acts on the measurement only, not on the setpoint, so a step in the setpoint does not produce
an infinite kick. That is standard practice. `xd0` is the derivative block's initial state. It
is preloaded from the starting speed, V start, which is 90 km/h, so the run does not begin
with a spurious transient.

If a colleague showed you only the PID curve, what could you not tell? Whether it is well tuned
or merely lucky. Which is exactly why section 08 exists.
-->

---

## Who does what, and when

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

*Proportional carries the transient. Integral holds the steady state. Derivative exists only while the error is moving — zero at both ends.*

</div>
</div>

<!--
Let's go through the three traces in order. Each is a path's own output inside
`CruiseController`, multiplied by the gain k, so all of them are in newton-meters and share an
axis.

Proportional jumps at the step, then decays to almost nothing. It has done its job in the
first few seconds, and then it retires.

Integral starts at the old cruise torque, climbs, and settles at the new one. It does almost
nothing at the step and everything at the end.

Derivative is zero before the step, a pulse during the transient, and zero after. It is only
ever present while something is changing. At both ends the error is not moving, so the
derivative is zero.

And `controller.y` is the sum. That is what the engine is actually asked for.

This is the answer to "which gain should I turn". They are not three knobs on the same thing.
They act at different times, and the symptom tells you which one to reach for.

At t equals 100 seconds, which term is holding the car at 110 km/h? Only the integral. The
other two are at zero.
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
Notice that "more" stops helping. Proportional and integral both trade one property for another
monotonically. The derivative has an optimum, and past it the cure is worse than the disease.

We sweep T d through 0.1, 0.25, 0.5, 1.0, 2.0 and 4.0 seconds, and look at the first 40
seconds. Too little derivative and the overshoot survives. Too much and the response is
sluggish, meaning it takes longer to arrive, and jittery, meaning it reacts to small changes it
should ignore.

Look at the raggedness in the curve with the largest T d. And this is on a perfectly clean
measurement. Put one percent of speedometer noise on the signal and that curve becomes
unusable. That is section 07.

In a car, what does an aggressive derivative feel like to a passenger? Surging. The controller
reacts to every small change. There is a comfort requirement hiding in the gain set.
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
PID is not an algorithm you pick off a shelf. It is a family, and you select a member by
deciding which of the three questions your plant actually needs answered.

When would you deliberately leave the integrator out? When the plant already integrates. Take
a motor position loop, where holding a position needs no effort. Adding a second integrator
there mostly buys you oscillation.

And when would you leave the derivative out? When the measurement is noisy and you cannot
filter it enough. That is most of the time. A large fraction of industrial loops in service
are PI, not PID.

In the reference model, two on/off switches configure a single `CruiseController`. `with_I`
drives a block called `i_switch` between the integrator and the sum, and `with_D` drives
`d_switch` between the derivative and the sum. Four controllers, one file, one diagram. Your own
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
> The guide page's [step 5](../lecture/lecture-01/#step-5) has the finished controller as code
> to paste. The reference is `CruiseLoop` with `with_I = true, with_D = true`, `Td = 0.5`,
> `wd = 0`.
> Section 06 builds on this diagram.

</div>
</div>

<!--
Second checkpoint. This is the controller that runs most of the machinery you will ever work
on, and you drew every block of it. Check your neighbor's screen.

If you are still building, paste the step 5 code from the guide page. Or switch to the
reference `CruiseLoop` with `with_I` and `with_D` both true, `Td` equals 0.5 and `wd` equals
0. Those are our values. Its `xd0` follows `wd` by itself. Section 06 adds a limiter to
**this** diagram, so do not go into the break without it.

If your run differs from mine, compare against the reference `CruiseController` in this
order. First the signs of `add_d`. Then the derivative's T, which must be `Td` over `Nd`. Then
`xd0`.
-->

---

## What this bought us

- A controller that reaches the setpoint and overshoots far less getting there.
- A picture of which term does what, and when — the thing to consult when a loop misbehaves.
- Four controllers from two booleans.

### Next: the engine runs out of torque, and the integrator does not notice. <Link to="windup">→ 06, integral windup</Link>

<!--
Everything up to here has been on flat road with a step the engine could easily deliver. Every
plot has been well behaved. After the break we point the car up a hill it cannot climb, and
the nice linear story breaks in a way that has hurt real hardware.

Before the break, make sure you are at checkpoint PID. The break is your last chance to paste
the reference before section 06 builds on it.
-->
