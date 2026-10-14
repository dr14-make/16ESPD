---
routeAlias: tuning
layout: section
---

###### Notebook 08

# Tuning

You can compute a starting gain set from a single step test, without a model.

`notebooks/lecture01/08-tuning.ipynb`

<!--
So far I have given you the gains. Now you see where they come from. This is also the practical
task from the course slides, the one you will be asked to do.
-->

---

## First question: is the system well behaved?

<div class="grid grid-cols-2 gap-8">
<div>

Not well behaved means: strongly nonlinear, or unstable and you are
trying to stabilize it, or a lot of delay, or non-minimum phase. Those need more than
PID, or at least more than these methods.

#### Our car

- stable open loop ✓
- near enough linear around 100 km/h ✓
- minimum phase ✓
- a manageable amount of delay ✓

</div>
<div>

#### Then: model, or hardware?

| You have | You can |
|---|---|
| hardware only | guess and check; or a step test and a heuristic table |
| a model | pole placement, loop shaping, autotuning — or the same tables, safely |

*We have a model, but we use the hardware methods on
it, because those are the ones you can use on a real car.*

</div>
</div>

<!--
Some say tuning is an art; others give you three rules. Both are right, for different plants. The
plant is the thing we control; here, the car. This slide tells you which case you are in.

The first question matters most. If the plant is unstable on its own, no table will help. Section
10 shows a plant that fails this test, and it is the same car. The loop that keeps a drone level
fails it too. That is why you do not tune a quadcopter by raising the gain until it oscillates.

Well behaved is a judgment with four parts. Stable open loop means that with no controller acting,
disturbances die out on their own. Our car coasts to a stop. A quadcopter falls over. Near enough
linear means the car responds about the same way across the speeds we use. Between 90 and 110 km/h
its response time only moves from 74 to 61 seconds. Minimum phase means the output never first
moves the **wrong** way when you push it. More torque never makes our car slow down first. A
manageable delay means the time before anything happens is short compared with the response. We
measure that in two slides.

The second question is whether you have a model. Model-based methods need a mathematical model.
Pole placement means choosing the gains so the loop responds exactly as fast and as smoothly as you
specify. Loop shaping means designing the controller from how the loop answers slow and fast
changes. Autotuning means software that runs a test and computes the gains for you. Heuristic
tuning means a rule of thumb: you put a few measured numbers into a table. It needs only an
experiment.
-->

---

## The plant model the tables assume

$$
G(s) \;=\; \frac{K\,e^{-\theta s}}{\tau s + 1} \qquad\text{first order plus dead time}
$$

<div class="grid grid-cols-[1.4fr_1fr] gap-8">
<div>

| | is | here |
|---|---|---|
| $K$ | steady-state gain — output change per unit of input change | km/h per N·m |
| $\tau$ | time constant — time to cover 63 % of the change | s |
| $\theta$ | dead time — how long nothing happens first | s |

Three numbers. They describe the *shape* of the step response, not a
car, and many industrial plants have that shape.

</div>
<div>

#### The ratio θ/τ

$$
r \;=\; \theta/\tau
$$

| $\theta/\tau$ | character |
|---|---|
| &lt; 0.1 | easy — high gains are available, PI is usually enough |
| 0.1 – 1 | ordinary — what the tables were fitted for |
| &gt; 1 | dead-time dominated — PID struggles; you want a predictor |

</div>
</div>

<!--
Every rule-of-thumb method here assumes your plant responds like this formula. Its name is first
order plus dead time, shortened to FOPDT or FOPTD. First order means the output glides toward its
new value, slowing as it gets close, with no wobble. Dead time means that at first nothing happens.
Ours has this shape, because we built it that way: a body that responds smoothly, with an engine
lag and a transport delay in front. The transport delay is the wait between asking for torque and
getting it.

The formula has three numbers. K is the steady-state gain, how far the speed moves per newton-meter
once everything settles: 2.21 km/h per newton-meter. Tau is the time constant, the time to cover
63 percent of the change: 63 seconds. Theta is the dead time, how long nothing happens: 1.816
seconds, as fitted. That is six times the engine's 0.3 second delay, because the fit also counts
the slow start of the curve as dead time.

Theta over tau tells you how hard the plant is to control. With almost no dead time, it tolerates
almost any gain. With mostly dead time, it does not. Ours is 1.82 over 63, about 0.029: the easy
end, well inside where these rules were fitted.

Cohen-Coon, the first table we use, gives a gain that grows with tau over theta, about 35 here. So
our small ratio gives a large gain, more torque than a 150 newton-meter engine has. We come back to
that at the end of this section. And in section 09, reading the speed only at fixed intervals adds
more dead time.
-->

---

## The step test, used for tuning

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [08-tuning.ipynb · cell The open-loop step test]
# 1. settle  2. step  3. record  4. scale by the step size
Scenarios = VehicleSystemsComponents.Lecture1

V_START, SETPOINT, T_STEP = 90.0, 110.0, 50.0
A_STEP = cruise_torque(SETPOINT) - cruise_torque(V_START)

step_test = Scenarios.CarStepTestTransient(
    tau_lo = cruise_torque(V_START), tau_hi = cruise_torque(SETPOINT),
    v0 = V_START / 3.6, t_step = T_STEP)

K, tau, theta = fopdt_fit(step_test;
    output = "plant.v_kmh", A = A_STEP, t0 = T_STEP)
@show K tau theta
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/08-tuning.ipynb)

- **K** km/h per N·m
- **τ** seconds
- **θ** seconds

</div>
<div>

![The open-loop step response with the dead time, the time constant and the total change marked, in the style of the Cohen-Coon step-test figure.](/figures/08-step-test-annotated.svg)

*The same three landmarks as section 01, read by the construction in the tuning document rather than by eye.*

</div>
</div>

<!--
A step test means: hold the input steady, change it suddenly by a fixed amount, and record what
the output does. The code holds the car at 90 km/h, steps the torque at 50 seconds to the value
that holds 110, and fits the three numbers.

Check K, tau and theta against what you wrote down in section 01: 2.21 km/h per newton-meter, 63
seconds and 1.816 seconds. They must match: it is the same test.

The next four slides use only these three numbers. Mass, drag area and gear ratio do not appear
again.

The torque steps from 31.1 to 40.1 newton-meters, and the run stops at 500 seconds: about seven
time constants after the step, enough to settle. We divide the speed change by the 9.04
newton-meter step. That is step 4 of the procedure, and it makes K a property of the plant, not of
the experiment.

Do not step from zero, and do not use a very large step. A step test describes the plant **where
you operate it**. Air drag grows with the square of the speed, so a step from rest measures a
different plant.
-->

---

## Reading the three numbers off the curve

![A step response with the construction that yields the three FOPTD parameters: the input step at t0, the half-change and 63 percent landmarks at t2 and t3, the intercept t1 they imply, the dead time theta from t0 to t1 and the time constant tau from t1 to t3.](/diagrams/08-foptd-construction.svg)

$$
t_1 = \frac{t_2 - \ln 2\,\cdot t_3}{1 - \ln 2} \qquad
K = \frac{B}{A} \qquad \tau = t_3 - t_1 \qquad \theta = t_1 - t_0
$$

*Use the exact constants, not rounded ones: t₁ magnifies any error
in the two landmarks by about 2.3 time constants. `fopdt_fit` in
`support.jl` is this construction.*

<!--
The output sits still for a while. That is dead time. Then it climbs and settles.

t zero is when the input stepped. B is the total change in the output. Mark where the output has
covered half of B: that is t two. Mark where it has covered one minus one over e of B, about 63.2
percent: that is t three. Only these two times are measured. The natural log of 2 appears because
t two is the half-way point of that smooth first-order curve.

t one is the time those two imply: where the first-order curve would have started with no dead
time. Before it is theta. From it to t three is tau. So K is B over A, tau is t three minus t one,
and theta is t one minus t zero. A is the size of the input step, so dividing by A is the scaling
from the last slide.

Use the exact constants, not 0.632 rounded. With a tau of about a minute, the rounding alone would
add about a third of a second of dead time.

A common mistake is reading tau as the time to reach the final value. It is 63 percent of it. The
remaining 37 percent takes another three time constants.
-->

---

## Cohen-Coon: from the open-loop response

<div class="grid grid-cols-[1.4fr_1fr] gap-8">
<div class="text-sm">

| with $r = \theta/\tau$ | $k$ | $T_i$ | $T_d$ |
|---|---|---|---|
| P | $\dfrac{1}{K}\dfrac{\tau}{\theta}\left(1 + \dfrac{r}{3}\right)$ | — | — |
| PI | $\dfrac{1}{K}\dfrac{\tau}{\theta}\left(0.9 + \dfrac{r}{12}\right)$ | $\theta\,\dfrac{30 + 3r}{9 + 20r}$ | — |
| PID | $\dfrac{1}{K}\dfrac{\tau}{\theta}\left(\dfrac{4}{3} + \dfrac{r}{4}\right)$ | $\theta\,\dfrac{32 + 6r}{13 + 8r}$ | $\theta\,\dfrac{4}{11 + 2r}$ |

*Cohen-Coon, from `tuning_methods.pdf` Table 1. One open-loop step
test, three rows, pick the controller you want.*

```julia [08-tuning.ipynb · cell Cohen-Coon]
SPEED = "loop.plant.v_kmh"       # the plant's km/h, inside the harness
COMMAND = "loop.controller.y"    # torque asked of the engine
UNLIMITED = 1.0e6                # N.m — the ceiling lifted away

k_cc, Ti_cc, Td_cc = cohen_coon(K, tau, theta)

# Both switches on: the full PID, with the Cohen-Coon gains.
pid = Scenarios.CruiseLoopTransient(
    model = Scenarios.CruiseLoopStep(; name = :CruiseLoopStep,
                                     with_I = true, with_D = true),
    k = k_cc, Ti = Ti_cc, Td = Td_cc, wd = 0.0,
    T_max = UNLIMITED, y_max = UNLIMITED, stop = 60.0)

plot_speed(pid; sig = SPEED, setpoint = 110)
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/08-tuning.ipynb)

</div>
<div>

![Speed under the Cohen-Coon PID for the 90 to 110 km/h step, against the 110 km/h setpoint.](/figures/08-cohen-coon.svg)

> **Why the dead time is in the denominator**
>
> *k* grows without bound as θ goes to zero. A plant with no dead time has no Cohen-Coon tuning
> at all, which is the second reason the engine's transport delay is in the model.

*The tables are transcribed in
`test/tuning_tables.jl`, with every coefficient checked against
`docs/materials/ControlTheory/tuning_methods.pdf` by hand.*

</div>
</div>

<!--
Cohen and Coon fitted this formula to a family of plants in 1953. It is not derived from our car.
It uses only the **shape**, first order plus dead time, and that is enough for a starting point.

The columns are the three PID settings from section 05. k is the proportional gain, in
newton-meters per km/h. T i is the integral time and T d the derivative time, both in seconds.

The ratio theta over tau appears in every cell. The gain goes as one over K, so a plant with a high
gain gets a lower controller gain. And it goes as tau over theta, so it grows without bound as the
dead time goes to zero. Pick the row for the controller you build: P, PI or PID.

For our car the PID row gives k equal to 21.06, T i 4.416 seconds and T d 0.657 seconds.

Now the response. Would you ship it? The rise time, from 10 to 90 percent of the step, is 2.43
seconds. The speed overshoots by 16.3 percent of the step, to about 113 km/h. That is noticeable,
not broken. Cohen-Coon is usually quick, and usually oscillatory. It is a starting point. It also
asks the engine for 422 newton-meters, almost three times what it has. We come back to that.
-->

---

## Ziegler-Nichols: the ultimate gain and period

<!-- At the shipped theta_e = 0.3 s the ultimate period is about 2.2 s and the ultimate
     gain about 115 N.m per km/h (about 414 N.m per m/s; this loop
     runs in km/h). -->

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [08-tuning.ipynb · cell Ziegler-Nichols]
DELTA = 0.1     # km/h — the smallest poke that measures cleanly

# P-only, both switches off: the pure proportional
# loop that Ziegler-Nichols step 2 asks for.
probe = Scenarios.CruiseLoopTransient(
    model = Scenarios.CruiseLoopStep(; name = :CruiseLoopStep,
                                     with_I = false, with_D = false),
    k = 100.0, v_lo = V_START, v_hi = V_START + DELTA,
    T_max = UNLIMITED, y_max = UNLIMITED, stop = 30.0)

ladder = sweep(probe, "k",
    [80.0, 100.0, 110.0, 112.0, 114.0, 115.0, 125.0])

# `oscillation` gives the period and the peak-to-trough amplitude
# ratio per cycle: under one below Ku, over one above, one at Ku.
walk = [(k = k, osc = oscillation(sol),
         floor = minimum(signal(sol, COMMAND)[2])) for (k, sol) in ladder]
usable = filter(w -> w.floor > 0, walk)  # zero command = limit cycle

# interpolate the crossing; do not call a run sustained by eye
i = findlast(w -> w.osc.ratio < 1, usable)
below, above = usable[i], usable[i + 1]
Ku = below.k + (1 - below.osc.ratio) * (above.k - below.k) /
               (above.osc.ratio - below.osc.ratio)
Pu = oscillation(rerun(probe, "k" => Ku)).period

k_zn, Ti_zn, Td_zn = ziegler_nichols(Ku, Pu)  # 114.59, 2.185 s
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/08-tuning.ipynb)

*This experiment gives two numbers, and the tuning tables
on the next two slides use them.*

</div>
<div>

![Three proportional runs at increasing gain: one decaying oscillation, one sustained oscillation of constant amplitude, and one growing oscillation.](/figures/08-ultimate-oscillation.svg)

*Below **K<sub>u</sub>** the oscillation decays, above it grows. At **K<sub>u</sub>** it neither grows nor decays, and its period is **P<sub>u</sub>**.*

</div>
</div>

<!--
Ziegler-Nichols is the second method, named after its two authors. This experiment is different.
Cohen-Coon watched the plant on its own. Ziegler-Nichols closes the loop and pushes it toward
instability on purpose. Then it reads two numbers off the oscillation.

The controller is proportional only: the integral and derivative parts are switched off. The
setpoint moves by just 0.1 km/h. Then you raise the gain, one run per gain. Below a certain gain,
the ultimate gain, the oscillation decays. Above it, it grows. We want the one in the middle,
neither growing nor decaying. `ladder` is the set of gains we walk up: 80, 100, 110, 112, 114, 115
and 125. The crossing lies between 114 and 115.

K u is that ultimate gain: 114.59, about 115 newton-meters per km/h. P u, the ultimate period, is
the time for one cycle of that oscillation: 2.185 seconds, about 2.2.

One warning. If the oscillation squares off against the torque limit, that is relay limit-cycling:
the command banging between the actuator limits, like an on-off switch. It is not the smooth
oscillation the method assumes, and the K u you read off it is not the one the table wants. In our
ladder that happens at 125: the command hits zero, so that run is left out.

We are deliberately making a car oscillate. Would you do this on a real vehicle? Keep your answer.
We come back to it later in this section.
-->

---

## The Ziegler-Nichols table

<div class="grid grid-cols-[1.4fr_1fr] gap-8">
<div>

| from $K_u$ and $P_u$ | $k$ | $T_i$ | $T_d$ |
|---|---|---|---|
| P | $K_u/2$ | — | — |
| PI | $K_u/2.2$ | $P_u/1.2$ | — |
| PID | $K_u/1.7$ | $P_u/2$ | $P_u/8$ |

*`tuning_methods.pdf` Table 2. Adding the integral path **lowers**
the gain.*

</div>
<div>

> **The design target**
>
> Ziegler and Nichols were aiming at a **quarter-amplitude decay**: each overshoot a quarter of
> the one before. That was a reasonable target for a 1940s process plant. It is far more
> oscillatory than anyone wants in a vehicle.

</div>
</div>

*In the PID row $T_i = 4\,T_d$, whatever $P_u$ is, so the two zeros are always placed in the
same ratio.*

<!--
This is the table from this lecture you are most likely to use in practice. Copy it down. P: K u
over 2. PI: K u over 2.2, with T i equal to P u over 1.2. PID: K u over 1.7, with T i equal to P u
over 2 and T d equal to P u over 8. The times are all fractions of the ultimate period.

For our car the PID row gives k equal to 67.41 newton-meters per km/h, T i 1.092 seconds and T d
0.273 seconds.

From P to PI the gain comes **down**. The integral reacts late, because it adds up past error, and
that lag brings the loop closer to oscillating. The derivative reacts early, so the PID row can
afford a higher gain again.

The footnote: in the PID row, T i is always four times T d, whatever P u is. So the measured period
only sets the overall time scale of the controller.

The design target is quarter-amplitude decay: each overshoot is a quarter of the one before. That
was a 1940s process-plant preference, not a law.
-->

---

## Tyreus-Luyben: same measurement, less oscillation

<div class="grid grid-cols-[1.4fr_1fr] gap-8">
<div>

| same $K_u$, $P_u$ | $k$ | $T_i$ | $T_d$ |
|---|---|---|---|
| PI | $K_u/3.2$ | $2.2\,P_u$ | — |
| PID | $K_u/2.2$ | $2.2\,P_u$ | $P_u/6.3$ |

*`tuning_methods.pdf` Table 3. There is no P row: the method mainly
slows the integrator, and a P controller has none.*

```julia [08-tuning.ipynb · cell Tyreus-Luyben]
k_tl, Ti_tl, Td_tl = tyreus_luyben(Ku, Pu)   # same Ku, Pu
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/08-tuning.ipynb)

</div>
<div>

| PID row | $k$ | $T_i$ | $T_d$ |
|---|---|---|---|
| Ziegler-Nichols | $K_u/1.7$ | $P_u/2$ | $P_u/8$ |
| Tyreus-Luyben | $K_u/2.2$ | $2.2\,P_u$ | $P_u/6.3$ |

Three quarters of the gain, and an integrator **4.4 times slower**: $2.2P_u$ against $P_u/2$.
From the same two measured numbers.

</div>
</div>

<!--
Tyreus-Luyben is a third table, again named after its authors, and it uses the same two numbers.
The main difference is the T i column. Ziegler-Nichols divides the ultimate period. Tyreus-Luyben
multiplies it: T i is 2.2 times P u, 4.806 seconds against 1.092. That is a factor of 4.4 slower,
from the same experiment.

In the PID row the gain is K u over 2.2, against K u over 1.7. That is three quarters of the gain:
52.09 against 67.41 newton-meters per km/h. T d is P u over 6.3, 0.347 seconds. There is no P row,
because the method mainly slows the integrator, and a P controller has none.

Ziegler-Nichols dates from when quarter-amplitude decay counted as a good response. That is far too
oscillatory for a vehicle. Tyreus-Luyben uses the same measurement with a calmer target.

A tuning rule encodes somebody's requirements. If their requirements are not yours, neither is
their table.
-->

---

## Relay autotune: $K_u$ without approaching instability

<div class="grid grid-cols-[1.4fr_1fr] gap-8">
<div>

1. Let the plant settle, and move the setpoint to where it already is.
2. Replace the controller with a **relay**: output $u_0 + d$ while the error is positive,
   $u_0 - d$ while it is negative.
3. The loop limit-cycles. Measure the output amplitude $a$ and the period $P_u$.

$$
K_u \;=\; \frac{4d}{\pi a}
$$

Then feed $K_u$ and $P_u$ into either of the last two tables.

</div>
<div>

> **Why industrial controllers use it**
>
> You choose $d$, so you choose how hard the plant is shaken. The oscillation is bounded by
> construction: you never raise the gain toward instability and hope you notice in time. This is what the "autotune" button on industrial hardware is doing.

</div>
</div>

*The formula is the describing-function approximation of the relay: it takes the first
harmonic of a square wave of amplitude $d$, which has amplitude $4d/\pi$.*

<!--
This is the fifth tuning method in the course slides, and the only closed-loop one, with the
controller in the loop, that is safe on hardware. It is why a temperature test chamber has an
autotune button, and your car has no "raise the gain until it oscillates" button.

A relay is an on-off switch. It puts out u zero, the input that holds the current value, plus d
while the error is positive, and u zero minus d while it is negative. You choose d, so the shaking
is bounded. The loop then settles into a steady oscillation, called a limit cycle. The relay's
output is a square wave. A square wave of height d acts mostly like one smooth wave of height 4 d
over pi, and the plant smooths away the rest. The plant's output oscillates with amplitude a, and
its period is P u. 4 d over pi, divided by a, is the gain at which the loop would sustain the
oscillation. That is K u. Here the limit cycle is the measurement, not a fault.

On a real machine, pick d as small as still gives a clean measurement above the noise.

We do not run this one. The model has no relay block, and it would tell us what Ziegler-Nichols
already told us.
-->

---

## The three tunings compared

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [08-tuning.ipynb · cell All three overlaid]
gains = ["Cohen-Coon"      => (k_cc, Ti_cc, Td_cc),
         "Ziegler-Nichols" => (k_zn, Ti_zn, Td_zn),
         "Tyreus-Luyben"   => (k_tl, Ti_tl, Td_tl)]

# One compiled model for all three: `rerun` swaps the gains in the problem
# the compiler already built.
tuned(k, Ti, Td) = rerun(pid, "k" => k, "Ti" => Ti, "Td" => Td,
                         "loop.controller.xd0" => -V_START)

plt = plot(; xlabel = "time [s]", ylabel = "speed [km/h]")
for (name, (k, Ti, Td)) in gains
    plot!(plt, signal(tuned(k, Ti, Td), SPEED)...; lw = 2, label = name)
end
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/08-tuning.ipynb)

</div>
<div>

![Three step responses from three tuning tables on one axes, ranging from quick and oscillatory to slow and smooth.](/figures/08-three-tunings.svg)

*Three tables, one plant, one step test. The three gain sets give clearly different responses.*

</div>
</div>

<!--
Three gain sets, one plant, one step test. Everything that differs between the curves came out of a
table, not out of the car.

Which would you ship in a car? Hands up for Cohen-Coon. For Ziegler-Nichols. For Tyreus-Luyben.

Here are the numbers. Cohen-Coon rises in 2.43 seconds and overshoots 16.3 percent. Ziegler-Nichols
rises in 0.53 seconds, overshoots 46.4 percent, to about 119 km/h, and rings. Tyreus-Luyben rises
in 0.81 seconds and overshoots 7.5 percent. On this plot Tyreus-Luyben is the clear choice.

Most people pick the calmest. Good reasons are about passengers and the distance from instability,
not about rise time.

None of them is final. Each is a starting point from its own assumptions, and each expects you to
adjust it.

And we never used the mass of the car. A method that needs no model works on hardware somebody else
built.
-->

---

## The five tuning methods compared

| Method | Experiment | Measures | Risk to the plant | Tends to give |
|---|---|---|---|---|
| Guess and check | any | nothing directly | whatever you do to it | an intuition for the knobs |
| Cohen-Coon | open-loop step | $K$, $\tau$, $\theta$ | none: never leaves the stable region | quick, oscillatory |
| Ziegler-Nichols | closed loop, P only | $K_u$, $P_u$ | **drives it to the edge of instability** | aggressive, quarter-decay |
| Tyreus-Luyben | the same experiment | $K_u$, $P_u$ | the same | conservative, sluggish |
| Relay autotune | closed loop, relay | $d$, $a$, $P_u$ | bounded by the $d$ you chose | $K_u$ safely, then a table |

> **What all five have in common**
>
> Every row measures **two or three numbers** about the plant and puts them into a formula
> somebody else fitted. Each gives a starting point that you then adjust.

<!--
Risk is what the experiment costs you if it goes wrong. That column decides which method you may
use on the day, and it has nothing to do with control theory. It is about what you are willing to
do to the equipment.

You have a customer's machine, in their factory, running their product. Which row? Cohen-Coon, or
relay autotune if you can install one. Not Ziegler-Nichols.

All five give you a starting point. The final adjustment, up to about a factor of two, is yours.
-->

---

## The danger in Ziegler-Nichols

> **On real hardware**
>
> The method requires you to drive the plant deliberately to the edge of instability, and to sit
> there long enough to measure a period.

- On a simulation: free. Make it unstable, it costs a re-run.
- On a thermal chamber: probably acceptable.
- On a vehicle at 110 km/h, on a public road, with a passenger: **no.**

*This is why Cohen-Coon exists. An open-loop step test never leaves
the stable region.*

<!--
Back to the question: would you run Ziegler-Nichols on a real vehicle? The method is correct, but
dangerous. At the edge of instability, a small increase in gain makes the oscillation grow. In a
simulation, that costs you a re-run. In a vehicle, it is a safety risk.

There is a middle route, and we have just used it. Run Ziegler-Nichols on a **model**, then take
the gains to the hardware. You get the measurement without the risk, at the price of trusting the
model. That is why we built the model first, in the hands-on.

The catch: the model must be accurate near the stability boundary, and that is where models are
least trustworthy.
-->

---
routeAlias: step-8
---

## Step 8: how wrong can the model be?

![GradeCar's parameter panel with the vehicle mass m and the transport delay theta_e exposed beside T_max.](/img/lecture-01/step08-params.png)

*Your `GradeCar` · add `parameter m::Dyad.Mass = 1400` and
`structural parameter theta_e::Time = 0.3` · `body`: `m = m` · `engine`: `theta_e = theta_e` ·
duplicate `CruiseLoopStep` → `TuningCruiseStep` · limits lifted · Ziegler-Nichols gains · vary `m`, `theta_e`*

```julia
using Plots; plotly()
r = MyCar.TuningCruiseTransient()
p = plot(r; idxs = r."plant.v_kmh", label = "baseline")
# after each change:
r = MyCar.TuningCruiseTransient()
plot!(p, r; idxs = r."plant.v_kmh", label = "m = 1600")
```

[page: step 8](../lecture/lecture-01/#step-8) · reference `dyad/Lecture1/Step08/GradeCar.dyad`

<!--
Tuning on the model is only as good as the model. So we check how much it matters if two numbers
are wrong: the mass, which changes with every passenger, and the delay, which we never measured
directly.

First, build in your `MyCar.GradeCar`. It is the same move as step 6a.

Open `GradeCar` and click Add parameter. Name it `m`, type `Dyad.Mass`, value 1400, description
"Vehicle mass". Add a second one: `theta_e`, type `Time`, value 0.3, description
"Injection-to-torque transport delay", and tick structural. A structural parameter is fixed when the
model is compiled. The engine's delay block is built from this value at compile time, so changing
it means a recompile. If Add parameter offers no structural option, switch to the code view and
write `structural parameter theta_e::Time = 0.3`.

Select `body` and set m to `m`. Your `GradeBody` already passes m on to `GradeForce`, so this one
binding reaches rolling resistance, the slope force and the inertia.

Select `engine` and set `theta_e` to `theta_e`. There is nothing to wire.

Now the harness. Right-click `CruiseLoopStep`, choose Duplicate, and name the copy
`TuningCruiseStep`. Leave `CruiseLoopStep` at its step-6 state: k 56, `Ti` 10, `Td` 0.5, limits
150 and 0. Section 10 duplicates it again.

In the copy, lift every limit, as the notebook does. Type 1e6, one million: `controller.y_max` to
1e6, `controller.y_min` to minus 1e6, and `plant.T_max` to 1e6.

Set the Ziegler-Nichols gains: `controller.k` 67.41, `Ti` 1.092, `Td` 0.273. Leave `Nd` at 10, `wd`
at 0 and `xd0` at minus 90.

Create a TransientAnalysis of `TuningCruiseStep`, name it `TuningCruiseTransient`, with stop equal
to 60. Run it. That is the step from 90 to 110 km/h, our baseline.

Set `plant.m` to 1600, section 02's 200 kilogram payload. Re-run.

Set m back to 1400, and set `plant.theta_e` to 0.6, twice the shipped delay. Re-run. This one
recompiles, because `theta_e` is structural.

The code on the slide puts all three runs on one axes. After each change, run its last two lines
again with a new label.

The payload barely moves the response. Feedback absorbs it: the section 02 lesson again. The
doubled delay rings much harder. The Ziegler-Nichols gain came from a K u measured at 0.3 seconds.
K u falls as the delay grows, so the distance from instability that the table left is gone. A model
error matters most near the stability boundary.

Put both back on `TuningCruiseStep`: m equal to 1400, and `theta_e` equal to 0.3. The next slide
runs on it.
-->

---

## The torque limit sets the response

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [08-tuning.ipynb · cell The saturation trap]
# the real engine back: `T_max` is the plant's ceiling,
# `y_max` the controller's own clamp, both 150 N.m
limited = [name => tuned(k, Ti, Td, "T_max" => CAR.T_max,
                                    "y_max" => CAR.T_max)
           for (name, (k, Ti, Td)) in gains]

# left: what each unlimited tuning asks the engine for
for (name, (k, Ti, Td)) in gains
    plot!(ask, signal(tuned(k, Ti, Td), COMMAND)...; label = name)
end
hline!(ask, [CAR.T_max])          # what the engine has
# right: the speed each one gets with the limit in place
for (name, sol) in limited
    plot!(got, signal(sol, SPEED)...; label = name)
end
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/08-tuning.ipynb)

**Open in Dyad** `dyad/Lecture1/CruiseLoop.dyad`

> **Always plot the actuator command**
>
> Every tuning asks for far more than the engine has, and the speed plot does not show it. With the limit back, the three tables land on nearly one curve: the engine sets the
> response, not the tuning.

</div>
<div>

![Two panels: on the left, the commanded torque of the three tunings spiking far above the engine's 150 newton-meter limit line; on the right, the same three tunings with the limit in place, rising together on nearly one curve.](/figures/08-saturation-trap.svg)

*Left: what each tuning asks the engine for, against the 150 N·m limit. Right: what the car does with the engine it has.*

</div>
</div>

<!--
Think back to the "three tunings compared" slide. Would any of you sign one of them off?

Left panel: the commanded torque with the limit lifted. The engine has 150 newton-meters.
Cohen-Coon asks for 422. Ziegler-Nichols, 1356. Tyreus-Luyben, 1042. A linear model accepts a
controller your hardware cannot execute, with no warning and no error.

Right panel: the same three with `T_max` and `y_max` back at 150. The rise times are 4.8, 4.23 and
4.25 seconds, against 2.43, 0.53 and 0.81 unlimited. The curves nearly coincide: for the first
seconds all three ask for more than 150, so all three get exactly 150. The engine sets the
response, and the difference between the tables barely shows. The overshoot, 5.5, 3.8 and 0.0
percent, stays low because of the clamping anti-windup from section 06: while the engine is at its
limit, the controller stops adding up error it cannot act on.

The rule: **always plot the actuator command.** It is one extra line, and it shows whether the
hardware can do what the design asks.

Try it on your `TuningCruiseStep`. Run `TuningCruiseTransient` and plot `controller.y` with
`plant.v_kmh`. The command starts at about 1350 newton-meters, nine times what the engine has, and
the speed shoots to about 118.5 km/h within a second and a half. Now put the limits back:
`plant.T_max` to 150, `controller.y_max` to 150, `controller.y_min` to 0. Re-run. The command sits
on 150 for over four seconds, the speed climbs in a straight line, reaches 110 just before six
seconds and peaks at 110.8. `CruiseLoopStep` is never touched.
-->

---

## Summary of section 08

- A gain set from one step test, with no model of the car in the calculation.
- Three tables that give three different gain sets, and how to choose between them.
- One rule that applies to every method: **plot the actuator command.**

### Next: the same controller on a computer that reads the speed at fixed intervals. <Link to="discretization">→ 09, discretization</Link>

<!--
If you remember one slide from this lecture in five years, make it the previous one. The rest you
can look up.

The practical task from the course slides is what we just did: study the system, apply
Ziegler-Nichols, find suitable constants. You have the notebook that does it, and you can re-run it
with your own numbers.
-->
