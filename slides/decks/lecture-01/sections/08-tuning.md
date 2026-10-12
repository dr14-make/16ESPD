---
routeAlias: tuning
layout: section
---

###### Notebook 08

# Tuning

You can compute a starting gain set from a single step test, without a model.

`notebooks/lecture01/08-tuning.ipynb`

<!--
So far I have given you the gains. This section shows where they come from. It is also the practical task from the course slides, the one you will be asked to perform.
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
Some say tuning is an art; others give you three rules. Both are right, for different plants.
The flowchart tells you which case you are in.

The question at the top matters most. If the plant is unstable on its own, no table will help.
Section 10 shows a plant that fails this test, and it is the same car.

A drone's attitude loop is unstable in open loop, so it is not well behaved. That is why you do
not tune a quadcopter by raising the gain until it oscillates.

Well behaved has no strict definition. It is a judgment: stable open
loop, near enough linear, minimum phase, a manageable delay. Minimum phase means no zero in the
right half plane. In plain terms, the output does not first move the **wrong** way when you
push it. Open-loop stable means that, left alone, disturbances die out. Our car coasts to a
stop. A quadcopter falls over. Model-based tuning, meaning pole placement, loop shaping and
autotuning, needs a mathematical model. Heuristic tuning is a table applied to measured
numbers, and it needs only an experiment.
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
Every heuristic method in this section assumes your plant looks like
that transfer function. Ours does, because we built it to. A first-order body, with a lag and a
transport delay in front of it.

G of s is the plant's transfer function, output over input in the Laplace domain. K is the
steady-state gain. Ours is 2.21 km/h per newton-meter. Tau is the time constant, the time to
cover 63 percent of the change. Ours is 63 seconds. Theta is the dead time, how long nothing
happens first. Ours is 1.816 seconds, as fitted. And e to the minus theta s is how a pure delay
is written in the Laplace domain. FOPTD means first order plus dead time. You will also see it
written FOPDT. Same thing.

The ratio tells you how hard the plant is to control. A plant with almost no dead time relative
to its time constant tolerates almost any gain. A plant that is mostly dead time does not.

Our car's ratio: theta is 1.82 seconds, against tau of 63 seconds. So theta over tau is about
0.029. That is the easy end of the table, and comfortably inside where these rules were fitted.

This explains a plot several slides from here. Cohen-Coon's gain scales as tau over theta. So a
small ratio gives a large gain. That is correct mathematically, but it may need more torque than
a 150 newton-meter engine has. The table is not wrong; the engine limit is the problem, and we
come back to it at the end of this section.

More dead time would make this car harder to control, and sampling adds dead time in section 09.
The same ratio gets worse because of our own software.
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
Here are K, tau and theta. Check them against what you wrote down in section 01. They must be
the same numbers. It is the same test.

The next four slides use only these three numbers. The mass, the drag area and the gear ratio do
not appear again.

The test steps the torque from one settled value to another, from 31.1 to 40.1 newton-meters.
The step was applied at t step, and we hand that time to the fit rather than guess it. The run
stops at 500 seconds, the analysis default. That leaves 450 seconds after the step, about seven
time constants, long enough for the response to settle.

The scaling step matters. We stepped by 9.04 newton-meters, so we divide the speed change by
9.04. Dividing by the step is step 4 of the procedure.
That is what makes K a property of the plant, rather than of the experiment.

A common mistake is stepping from zero, or using a very large step. The point of a step test is to
characterize the plant **where you operate it**. On a plant with v squared drag, a step from
rest measures a different plant.
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
Look at the figure. The output sits still for a while. That is dead time. Then it climbs and
settles.

t zero is when the input stepped. B is the total change in the output, end to end. Mark where
the output has covered half of B. That is t two. Mark where it has covered one minus one over e
of B, about 63.2 percent. That is t three. Only these two times are measured. The ln 2
in the formula appears because t two is the half-way point of an exponential.

t one is the intercept those two imply. It is where the first-order curve would have started if
there had been no dead time at all. Everything before it is theta. Everything from it to t three
is tau. So K is B over A, tau is t three minus t one, and theta is t one minus t zero.

And the division by A matters. Scale the response by the size of the step you made. That is
step 4 of the procedure. Then K becomes a property of the plant, rather than of how hard you
happened to push.

A common mistake is reading tau as the time to reach the final value. It is 63 percent of it.
The remaining 37 percent takes another three time constants.
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

Here are the three gains. k is in newton-meters per km/h. T i and T d are in seconds.

Look at the table. The same ratio, theta over tau, appears in every cell. The gain goes as one
over K, so a plant with a high gain K gets a lower controller gain. And it goes as tau over theta, so it grows
as the dead time shrinks. That is why k grows without bound as theta goes to zero. Pick the row for the
controller you intend to build, P, PI or PID. You do not have to use all three paths.

Now look at the response. Does it look like something you would ship? Cohen-Coon is usually
quick, and usually oscillatory. It is a starting point, not an answer.
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
This is a different kind of experiment. Cohen-Coon watched the plant on its own. Ziegler-Nichols
closes the loop and pushes it toward instability on purpose. Then it reads two numbers off the
oscillation.

Look at the three curves: decaying, sustained, growing. Below the ultimate gain the oscillation
decays. Above it, it grows. The middle one, neither growing nor decaying, is the one we measure.
The runs on either side of it are how you find it. `ladder` is the set of gains you walk up to find
it, one run each.

K u is the ultimate gain, the proportional gain at which the loop oscillates at constant
amplitude. Ours is about 115 newton-meters per km/h. P u is the ultimate period, the period of
that oscillation. About 2.2 seconds here.

One warning. If the oscillation squares off against the torque limit, instead of looking
sinusoidal, that is relay limit-cycling. It is caused by banging between the actuator limits.
It is not the linear sustained oscillation the method assumes, and the K u you would read off it
is not the one the table wants.

We are deliberately making a car oscillate. Would you do this on a real vehicle? Keep your answer
in mind. We come back to it two slides from now.
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
This is the table from this lecture you are most likely to use in practice. Copy it down. For
P, the gain is K u over 2. The times are all fractions of the ultimate period. For PI, K u over
2.2, with T i equal to P u over 1.2. For PID, K u over 1.7, with T i equal to P u over 2 and T d
equal to P u over 8.

Look at the gain column going **down** as you add paths. Adding the integral adds phase lag,
which brings the loop closer to instability, so the gain must come down.

And the footnote. In the PID row, T i is always four times T d, whatever P u is. It is the only
row with both.
In the language of the section 05 slide, Ziegler-Nichols always puts the two zeros in the same
place relative to each other, and only moves them with P u.

The design target is quarter-amplitude decay. Each overshoot is a quarter of the one before.
That was a 1940s process-plant preference, not a law.
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
The main difference is in the T i column. One table divides the ultimate period; the
other multiplies it. Ziegler-Nichols divides it. Tyreus-Luyben sets T i to 2.2 times P u. That
is a factor of 4.4 slower, from the same experiment.

In the PID row, the gain is K u over 2.2, against Ziegler-Nichols' K u over 1.7. That is three quarters of the
gain: 52.09 against 67.41 newton-meters per km/h. The derivative time is P u over 6.3. There
is no P row, because the method mainly slows the integrator, and a P controller has none.

Ziegler-Nichols was designed when a quarter-amplitude decay was considered a good response.
That is far more oscillatory than anyone wants in a vehicle. Tyreus-Luyben uses the same
measurement with a less oscillatory target.

A tuning rule encodes somebody's requirements, not a law
of nature. If their requirements are not yours, their table is not yours either.
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
The course slides list five tuning methods, and this is the fifth. It is the only one of the
closed-loop family that is safe on hardware. And it is the reason your thermal chamber has an
autotune button, and your car does not have a "raise the gain until it oscillates" button.

Here is where the formula comes from. A relay puts out a square wave. You choose its amplitude
d, how far above and below the steady output it switches, and that bounds the disturbance. The
plant mostly responds to the first harmonic, and a square wave of height d has a first harmonic
of 4 d over pi. The output oscillates with amplitude a, and you read its period, P u, straight
off the plot. Divide 4 d over pi by a, and you have the gain at which the loop would sustain the oscillation.
That is the definition of K u. The oscillation a relay produces is a limit cycle, and here it is
the measurement, not a fault.

What would you pick d to be on a real machine? As small as gives a clean measurement above the
noise. The aim is to disturb the process as little as possible.

We do not run this one in the notebooks. It needs a relay block the model does not have, and it
would tell us what Ziegler-Nichols already told us.
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
Three gain sets, Cohen-Coon, Ziegler-Nichols and Tyreus-Luyben, each a k, T i, T d triple. One
plant, one step test. Everything that differs between the curves came out of a table, not out of
the car.

Which of these three would you ship in a car? Hands up for Cohen-Coon. For
Ziegler-Nichols. For Tyreus-Luyben.

Most people pick the calmest. Why? Good answers are about passengers and about the distance from
instability, not about rise time.

None of these is the final answer. They are three starting points from three sets of
assumptions, and every one of them expects you to adjust it afterwards. A table gives you a
usable starting gain set from one experiment.

We never used the mass of the car. A tuning method that needs no
model is a method you can use on hardware somebody else built.
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
Look at the risk column. Risk is what the experiment costs you if it goes wrong. That column
decides which method you are allowed to use on the day. And it has nothing to do with control
theory. It is about what you are willing to do to the equipment.

You have a customer's machine, in their factory, running their product. Which row? Cohen-Coon,
or relay autotune if you can install one. Not Ziegler-Nichols.

All five give you a starting point, not a finished design. The final adjustment, up to about a
factor of two, is yours.
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
Back to the question from two slides ago: would you do this on a real vehicle? The method is
correct, but dangerous. At the edge of instability, a small increase
in gain makes the oscillation grow instead of decay. In a simulation, that costs you a re-run.
In a vehicle, it is a safety risk. Knowing which of your tools are dangerous is an important part
of engineering judgment.

There is a middle route, and we have just used it. Run Ziegler-Nichols
on a **model**, then take the gains to the hardware. You get the measurement without the risk,
at the price of trusting the model. That is why we built the model first, in the hands-on session
before this lecture.

For that to be safe, the model must be accurate near the stability boundary, and that is where
models are least trustworthy.
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
using MyCar, Plots; plotly()
r = MyCar.TuningCruiseTransient()
p = plot(r; idxs = r."plant.v_kmh", label = "baseline")
# after each change:
r = MyCar.TuningCruiseTransient()
plot!(p, r; idxs = r."plant.v_kmh", label = "m = 1600")
```

[page: step 8](../lecture/lecture-01/#step-8) · reference `dyad/HandsOn/GradeCar.dyad`

<!--
The middle route was: tune on the model, ship to the car. That is only as good as the model. So
we use the model to check how much it matters if it is wrong, in the two numbers most likely to
be wrong. The mass, which changes with every passenger. And the delay, which we never measured
directly.

First we build, in your `MyCar.GradeCar`. It is the same move as step 6a.

Add `parameter m::Dyad.Mass = 1400`, with the description "Vehicle mass". Then add
`structural parameter theta_e::Time = 0.3`, with the description "Injection-to-torque transport
delay". It is structural because the Padé delay builds its coefficients from it at compile
time.

Select `body` and set m equal to `m`. Your `GradeBody` already passes m on to `GradeForce`, from
hands-on step 07. So this one binding reaches rolling resistance, the slope force and the
inertia.

Select `engine` and set `theta_e` equal to `theta_e`. There is nothing to wire.

Now the robustness re-runs. This is a new harness in `MyCar`, beside `CruiseLoopStep`,
`CruiseClimb` and `NoisyCruiseStep`.

Duplicate `CruiseLoopStep`, and name the copy `TuningCruiseStep`. `CruiseLoopStep` stays at its
step-6 state: k equal to 56, `Ti` equal to 10, `Td` equal to 0.5, limits 150 and 0. It stays
that way because section 10 duplicates it again.

In the copy, lift every limit, as the notebook does. Set `controller.y_max` to 1e6,
`controller.y_min` to minus 1e6, and `plant.T_max` to 1e6.

Set the Ziegler-Nichols gains. `controller.k` is 67.41, `Ti` is 1.092, and `Td` is 0.273. `Nd`
stays at 10, `wd` at 0, and `xd0` at minus 90.

Now Run Analysis, a TransientAnalysis of `TuningCruiseStep`. Name it `TuningCruiseTransient`,
with stop equal to 60. Run it. That is the step from 90 to 110 km/h, and it is our baseline.

Now set `plant.m` to 1600. That is section 02's 200 kilogram payload. Re-run.

Then set m back to 1400, and set `plant.theta_e` to 0.6, twice the shipped delay. Re-run. This
one recompiles, because `theta_e` is structural.

The code on the slide puts all three runs on one axes. After each change, run its last two lines
again, with a new label. You should see that the payload barely moves
the response. Feedback absorbs it. That is the section 02 lesson again. And you should see the
doubled delay ring much harder. The Ziegler-Nichols gain was computed from a K u measured at 0.3
seconds. K u falls as the delay grows, so the distance from instability that the table left is gone.
This is why a model error matters most near the stability boundary.

Now put both back on `TuningCruiseStep`: m equal to 1400, and `theta_e` equal to 0.3. The next
slide runs on it.
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
Think back to the three speed responses on the "three tunings compared" slide. Would any of you sign one of
them off?

Now look at the left panel. It is the commanded torque for the three tunings with the limit
lifted, and the 150 newton-meters the engine has drawn on. Here are the peaks, against 150.
Cohen-Coon asks for 422 newton-meters. Ziegler-Nichols, 1356. Tyreus-Luyben, 1042.

A linear model accepts a controller your hardware cannot execute, and it gives no warning and no
error. The simulation is consistent, but it does not describe the real car.

Now the right panel. It is the speed for the same three, with `T_max` and `y_max` back at 150
newton-meters. The half-second arrival is gone. The rise times are 4.8, 4.23 and 4.25 seconds,
against 2.43, 0.53 and 0.81 seconds unlimited. And the three curves nearly coincide. For the
first seconds, all three ask for more than 150 newton-meters. So all three get exactly 150, and
the car accelerates the same way. The engine sets the response. The difference between the tables,
which was large on that slide, barely shows.

The overshoot is 5.5, 3.8 and 0.0 percent. That low overshoot comes from the clamping
anti-windup of section 06. Without it, the integrator would wind up during those seconds at the limit,
and return it as overshoot.

So the rule is: **always plot the actuator command.** It is one extra line in the notebook, and it
shows whether the hardware can do what the design asks.

You can see this in your own model. The notebooks lift `T_max` and `y_max` to run this, and so
does your `TuningCruiseStep`, which already carries the Ziegler-Nichols gains. Run
`TuningCruiseTransient`, and plot `controller.y` as well as `plant.v_kmh`. The command starts at
about 1350 newton-meters, nine times what the engine has. The speed shoots up to about 118.5
km/h within a second and a half. Then put the limits back: `plant.T_max` to 150,
`controller.y_max` to 150, and `controller.y_min` to 0. Re-run. Now the command sits on 150 for
over four seconds, and the speed climbs in a straight line. It reaches 110 just before six
seconds, and peaks at 110.8. The fast arrival is gone, just as in the right panel.
`CruiseLoopStep` is never touched.
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

The practical task from the course slides is what we just did. Study the system, apply
Ziegler-Nichols, find suitable constants. You now have the notebook that does it, and you can
re-run it with your own numbers.
-->
