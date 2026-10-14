---
routeAlias: pid
layout: section
---

###### Notebook 05

# Proportional-integral-derivative

P, I and D: the present error, the past error, and its rate of change.

`notebooks/lecture01/05-pid.ipynb`

<!--
The second switch, `with_D = true`, derivative on, is the only change. It completes the PID
controller, proportional-integral-derivative, which runs most of the machinery you will work on.
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
straight-line guess of where the error is heading.

d e by d t is the rate of change of the error. It is negative while we close on the setpoint. T d is in seconds, and it multiplies, so
bigger means more derivative action, the opposite convention to T i.

A common mistake is to think the derivative pushes harder when you are far away. Far away and
closing quickly, it is already pulling back.

A real controller never uses a pure derivative. There is always a filter on it, a smoothing stage,
set by a number called N d. Section 07 shows what happens without one.
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
using Plots; plotly()
r = MyCar.CruiseLoopTransient()
top = plot(r; idxs = [r."plant.v_kmh", r."demand.y"])
bottom = plot(r; idxs = r."controller.y")
plot(top, bottom; layout = (2, 1), link = :x, xlims = (0, 40))
```

[page: step 5](../lecture/lecture-01/#step-5) · reference `dyad/Lecture1/CruiseController.dyad`

<!--
This derivative is filtered, smoothed, and it may ignore the setpoint. You type both parameters now
and understand them in section 07.

In `CruiseController`, add four parameters: `Td` equals 0.5, of type `Time`; `Nd` equals 10; `wd`
equals 0; `xd0` equals minus 90. The last three are of type Real. `k` and `Ti` stay.

Delete `zero_d` and its wire.

Drag in an Add from `BlockComponents.Math`, name it `add_d`, set k one to `wd` and k two to minus
1, and place it below the integrator. Wire `u_s` into `add_d.u1`, and `u_m` into `add_d.u2`. It is
a second error block with its own setpoint weight. At `wd` equals 0 it is just minus `u_m`, so the
derivative acts on the measurement only.

Drag in a Derivative from `BlockComponents.Continuous`, name it `derivative`, and set k to `Td`, T
to `Td` over `Nd`, and x zero to `xd0`. Wire `add_d.y` into `derivative.u`, and `derivative.y`
into `add_pid.u2`.

Save, run `CruiseLoopTransient` again from the Analyses list, and paste the slide's code into the
Julia REPL. It plots `plant.v_kmh` with `demand.y` on top, and `controller.y`, the torque command,
below.

Why is `wd` zero? `wd` is a setpoint weight: how much of the setpoint, r, the derivative sees,
next to the measured speed, y. Real controllers almost never differentiate the setpoint, because a
step in the setpoint would make the derivative jump. That jump is called derivative kick. This is
the standard two-degree-of-freedom PID, where the setpoint and the measurement are treated
differently: P acts on `wp` times r minus y, I on the full error, D on `wd` times r minus y. `wp`
is the same kind of weight for P; your controller has none, which is the same as `wp` equals 1. The
library's `LimPID` block builds `add_p` and `add_d` the same way. Industrial controllers call `wd`
equals 0 PI-D, or derivative on measurement, and make it the default.

Why is `xd0` minus 90? The filter has a state, a memory, and it needs a starting value. At `wd`
equals 0 and a settled 90 km/h cruise, the filter's input is minus 90, so that is where the filter
starts. The reference `CruiseLoop` computes it the same way. Leave it at 0 and the filter sees a 90
km/h step at time zero and commands a spike of minus 50400 newton-meters.

The speed reaches **110 km/h** and peaks at about 114, against 115.5 in step 4. Your engine's 150
newton-meter ceiling still clips the start, so you overshoot more than the notebook, which peaks
at 110.55. In `controller.y`, the jump at the step is the proportional term, 1120 newton-meters,
56 times 20. No derivative spike rides on it.

A common mistake is T set to `Td` times `Nd` instead of `Td` over `Nd`. The filter is then 100
times slower than the derivative, and the D term does almost nothing.
-->

---

## What the four derivative parameters do

| Parameter | Value | What it is | Turn it up, and… |
|---|---|---|---|
| `Td` | 0.5 s | **Derivative time.** How far ahead D looks: $T_d\,\dot e$ is the error change expected over the next $T_d$ seconds. | …D brakes earlier and harder. Overshoot falls, up to a point; beyond it the loop gets sluggish and noisy. Notebook 05's sweep finds the least overshoot at 0.5 s. |
| `Nd` | 10 | **Filter ratio.** The derivative is smoothed by a lag of $T_d/N_d$ = 0.05 s. | …D gets closer to a true derivative, and sensor noise is amplified up to $N_d$ times more. Turn it down and D is blurred and weaker. Usual range: 5 to 20. |
| `wd` | 0 | **Setpoint weight.** D acts on $w_d\,r - y$, not on $e$. | …a setpoint step gets differentiated too: at `wd` = 1, every change of the cruise setting kicks the torque. At 0, D sees only the speed. |
| `xd0` | −90 | **Filter start value.** Where the filter's state sits at $t = 0$. | …nothing to tune: set it to the filter's input in the starting cruise, $w_d\,r - y = -90$. Leave it at 0, and the run starts with a −50 400 N·m spike. |

<div class="grid grid-cols-2 gap-8">
<div>

The `derivative` block computes

$$
\frac{Y(s)}{U(s)} = \frac{k\,s}{T s + 1} = \frac{T_d\,s}{\frac{T_d}{N_d}\,s + 1}
$$

</div>
<div>

> **Slow changes see a derivative, fast ones see a gain of $N_d$**
>
> Below about $N_d/T_d$ = 20 rad/s, the block differentiates. Above it, the output stops
> growing with frequency and levels off at $N_d$ times the input. That cap is what keeps noise
> from blowing up.

</div>
</div>

<!--
You typed four numbers on the last slide. Here is what each one means.

T d is the derivative time. T d times the rate of change of the error is how much the error will
change over the next T d seconds, if it keeps changing at the current rate. So T d is how far
ahead the controller looks. Turn it up, and the controller starts braking earlier. Overshoot
falls, but only up to a point. Push further, and the loop gets sluggish and amplifies noise.
Notebook 05 sweeps T d and finds the least overshoot at 0.5 seconds, which is why we use it.

N d is the filter ratio. A pure derivative amplifies anything fast without limit, including
sensor noise. So the derivative goes through a small lag, a smoothing stage that needs about T d
over N d seconds to follow a change. Ours is 0.05 seconds, much faster than anything the car does. A bigger N d means a sharper derivative and
more noise. A smaller one blurs the derivative until it does little. Five to twenty is the usual
range.

w d is the setpoint weight. The derivative acts on w d times the setpoint minus the speed. At w d
equals 1 that is the full error, and every time the driver changes the cruise setting, the
derivative of that step is a spike of torque. At 0, the derivative sees only the measured speed.
That is the industrial default.

x d zero is not a tuning knob. It is where the filter starts. In the starting cruise at 90 km/h,
the filter's input is minus 90, so that is where it should start. Leave it at zero, and the run
opens with a spike of minus fifty thousand newton-meters.

At the bottom is the transfer function of the derivative block itself, its output over its input
written with a variable s, where multiplying by s means differentiating. Two slides on we see
where that comes from. Here it is T d s over T d over N d times s, plus one. For slow signals the
bottom is about 1, and the block is T d times a derivative. For fast signals the s cancels, and
the block becomes a plain gain of N d, 10. The border is N d over T d, 20 radians per second,
about three cycles per second. That cap is what keeps the noise in check. Section 07 shows what
happens without it.
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
car's own time constant, 63 seconds, and that is how you sanity-check a gain set. Our controller in
parallel form is K p 56, K i 5.6, and K d 28. K i and K d have units
nobody can picture.
-->

---

## Where a transfer function comes from

<div class="grid grid-cols-[1fr_1.5fr] gap-8">
<div>

The Laplace transform swaps time *t* for a variable *s*. With everything starting at rest, three
rules cover this lecture:

| In time | In *s* |
|---|---|
| $\dfrac{dx}{dt}$ | $s\,X(s)$ |
| $\displaystyle\int_0^t x\,d\tau$ | $\dfrac{X(s)}{s}$ |
| $x(t-\theta)$ | $e^{-\theta s}X(s)$ |

A differential equation becomes algebra. Solve it for **output over input**, and that ratio is
the transfer function.

</div>
<div>

#### The car, from section 01's step test

$$
\tau\,\frac{dv}{dt} + v = K\,T(t-\theta)
\;\Rightarrow\;
(\tau s + 1)\,V = K e^{-\theta s}\,T
\;\Rightarrow\;
G(s) = \frac{V}{T} = \frac{K\,e^{-\theta s}}{\tau s + 1}
$$

*K* = 2.21 km/h per N·m, *τ* = 63 s, *θ* = 1.82 s, for changes around 90 km/h.

#### The controller

$$
u = k\left(e + \frac{1}{T_i}\!\int_0^t\! e\,d\tau + T_d\frac{de}{dt}\right)
\;\Rightarrow\;
U = k\left(1 + \frac{1}{T_i s} + T_d s\right)E
$$

The controller's transfer function $C(s) = U/E$ is *k* times the bracket.

</div>
</div>

<!--
Before we treat the PID as a transfer function, here is where a transfer function comes from.

The Laplace transform replaces time with a new variable, s. The three rules on the left are all
we need. Differentiating becomes multiplying by s. Integrating becomes dividing by s. A delay of
theta seconds becomes multiplying by e to the minus theta s. The rules hold when everything
starts at rest, and for a controller acting on changes around a steady cruise, that is our case.

So a differential equation turns into ordinary algebra. We solve it for the output divided by the
input, and that ratio is the transfer function. It describes the system for any input.

Take the car first. Section 01's step test fitted it as a first-order lag with a delay, a system
that closes a fixed share of the remaining gap every second: tau times the rate of change of
speed, plus the speed, equals K times the delayed torque. Apply the rules:
the derivative becomes s V, and the delay becomes e to the minus theta s. Collect V on the left,
divide by T, and you have G of s: K times the delay, over tau s plus one. The three numbers you
read off the curve in section 01 are the whole transfer function: K, 2.21 kilometers per hour per
newton-meter; tau, 63 seconds; and theta, 1.82 seconds.

Now the controller. Apply the same rules to the PID law: the error stays E, the integral becomes E
over s, and the derivative becomes s times E. Divide U by E, and k times the bracket is the
controller's transfer function. The next slide puts it over one denominator.
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
- The **two zeros** are yours to place, and where you put them is set by $T_i$ and $T_d$. Ours,
  $T_i$ = 10 s and $T_d$ = 0.5 s, give $5s^2 + 10s + 1 = 0$: zeros at $s = -0.11$ and $-1.89$.
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
If you have had a linear systems course, this slide shows PID as an ordinary controller design.
If you have not, remember the sentence in the box and move on.

s is the Laplace variable: multiplying by s differentiates, dividing by s integrates. Put over one
denominator, the controller is a fraction. A zero is a value of s that makes the top zero. A pole
is a value of s that makes the bottom zero. The bottom is T i times s, so the pole is at s equals
0, the origin. That pole is the integrator, and we do not get to move it. PID has two zeros, and
T i and T d decide where they go. With ours they sit at minus 0.11 and minus 1.89. k scales the
whole controller.

Root locus and loop shaping, in the box, are two classic pencil-and-paper design methods.

That is why so many tuning methods work: one question, three free parameters, several routes to a
good answer. The methods in section 08 look like arithmetic on measured numbers. Somebody else did
the zero placement for a whole class of plants and published a table.
-->

---

## Poles: what the denominator says about the response

<div class="grid grid-cols-[1fr_1.6fr] gap-6">
<div>

A **pole** is a value of *s* that makes the denominator zero. Each pole *p* adds a term
$e^{p t}$ to the response.

On the right: the same torque step from 90 km/h, with the car's one pole moved to each place.

- **Left half-plane**: the speed settles, with time constant $-1/p$. Further left is faster.
- **Off the real axis**: a pair $\sigma \pm j\omega$ overshoots and rings at ω rad/s, dying out
  as $e^{\sigma t}$.
- **Right half-plane**: the speed runs away. Unstable.
- **At the origin**: $e^{0t} = 1$ never fades. That is the integrator holding its value.

The real car's pole is $-1/\tau = -0.016$: 63 s per time constant. Closing the loop moves the
poles, and **tuning is choosing where they go**.

</div>
<div>

![Left: the complex s-plane, the stable left half shaded blue and the unstable right half orange, with four labeled poles: the car as a circle at minus 0.016, a fast real pole as a square at minus 0.8, a complex pair as diamonds at minus 0.25 plus or minus 1.2 j, and an unstable pole as a triangle at plus 0.15. Right: the car's speed after the same torque step from 90 km/h toward 110, with its pole at each of those places, one line style each: with the real pole it has reached only 95 after 20 seconds, with the fast pole it is at 110 within five seconds, with the pair it overshoots to about 120 and rings down, and with the unstable pole it runs away past 140.](/figures/05-poles.svg)

</div>
</div>

<!--
The denominator of a transfer function decides how the system moves on its own. Its roots are
called poles. Each pole p puts a term e to the p t into the response, so where a pole sits tells
you how the system behaves.

The left plot is the plane where poles live. Left and right is the real part of the pole: it sets
how fast things settle, or how fast they blow up. Up and down is the imaginary part: it sets how
fast things oscillate.

The right plot makes that concrete with our car. Every curve is the same experiment: the car
cruising at 90 km/h, and a torque step that should take it to 110. The only difference between
the curves is where we put the car's pole. Same colors, same line styles as the markers on the
left.

Start with the solid blue line, the circle: that is the real car. Its pole is minus one over tau,
minus 0.016, almost on the vertical axis. Its time constant, the time to cover about two thirds of
the way, is the 63 seconds from the step test.
After twenty seconds it has reached only 95 km/h. That is why the car on its own took minutes to
settle in section 01. A pole close to the axis is slow.

The dashed green line, the square, is the same car with its pole moved far left, to minus 0.8.
Time constant one over 0.8, about 1.25 seconds. It is at 110 within five seconds, and it never
goes past. Moving a pole left makes the response faster.

The orange line, the diamonds, is a complex pair. A complex pole always comes with its mirror
image. Now the speed overshoots to about 120 and rings around 110 before it settles. The
imaginary part, 1.2 radians per second, sets the ringing: one swing about every five seconds.
The real part, minus 0.25, sets how quickly the ringing dies out. Further from the real axis
means more ringing; closer to the vertical axis means it lasts longer.

The dotted line, the triangle, sits right of the axis, at plus 0.15. The speed does not settle at
all. It runs away, faster and faster, and passes 140 km/h within ten seconds.
One pole in the right half plane, and the system is unstable, however good the others are.

One more pole sits exactly at the origin: the PID's integrator. e to the zero t is one, a term
that never fades. That is the integrator remembering the error.

A real car cannot move its own pole. But when we close the loop around it, the poles of the loop
are no longer the car's poles. The controller's gains move them. A good tuning pulls the slow
pole left, like the green curve, and accepts a little of the orange curve's overshoot, without
ever pushing a pole across to the triangle's side. Every tuning method, a table or a knob, is a
way of choosing where the poles end up.
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

In numbers: P peaks at 117.8 and settles at 109.3. PI peaks at 118.8, an overshoot of 44 percent,
and settles at 110. PID peaks at 110.55, 2.7 percent, and settles at 110.

Same car, same gains: k equals 56, T i equals 10 seconds, T d equals 0.5 seconds. Only the
switches changed.

`wd` equals 0.0 keeps the setpoint step out of the derivative. `xd0` is preloaded from the
starting speed, 90 km/h, so the run does not begin with a false jolt.

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

Derivative dips once, to about minus 700 newton-meters, during the fastest part of the approach,
and returns to zero. It is only present while something is changing. That dip is what removes the
PI overshoot.

`controller.y` is the sum: what the engine is actually asked for. One exception: for about half a
second near the start the sum is negative, and the command sits at zero, because the engine cannot
brake.

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

The overshoot for each T d: at 0.1 seconds, 28.8 percent. At 0.25, 9.8. At 0.5, 2.7, the least,
which is why we use it. At 1 second, 5.1. At 2, 9.3. At 4, 16.8. The two largest have not even
settled when the run ends.

Look at the raggedness of the largest T d, with a clean measurement. Add a few tenths of a
kilometer per hour of noise to the speed reading and that curve becomes unusable. That is section
07.

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

Leave the integrator out when the plant, the thing being controlled, already integrates. A motor
turning to a position is one: the position is the running total of the speed, and holding a
position needs no effort. A second integrator there mostly adds oscillation.

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
Second checkpoint. You drew every block of this controller. Check your neighbor's screen: the
speed should peak at about 114 and settle at 110, and `controller.y` should show no spike from the
derivative at the step.

If you are still building, paste the step 5 code from the guide page over your `CruiseController`
and `CruiseLoopStep`, or open `Lecture1.Step05` in the course repository. Section 06 adds a
limiter, a block that caps the torque command at what the engine can give, to **this** diagram,
so do not go into the break without it.

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
hill it cannot climb. The torque limit makes the loop nonlinear: asking for twice the torque no
longer gives twice the torque. This failure has damaged real hardware.

Be at checkpoint PID before the break. It is your last chance to paste the reference before
section 06 builds on it.
-->
