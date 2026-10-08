---
routeAlias: tuning
layout: section
---

###### Notebook 08

# Tuning

You can compute a starting gain set from a single step test, without a model.

`notebooks/lecture01/08-tuning.ipynb`

<!--
**Say:** so far I have been handing you gains. Where did they come from? This section is the
answer, and it is also the practical task from the course slides — the one you will be asked
to perform.

**Timing:** 15 minutes. This section has the most cells of any in the lecture; if you are
behind, do the step test, Ziegler-Nichols, and the saturation trap, and let Cohen-Coon and
Tyreus-Luyben be read from the notebook afterwards.

**Cut order:** this is spine — do not cut it. The lecture is not complete without it.
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

*We have a model, and we will deliberately use the
hardware methods on it — because those are the ones that transfer to a car.*

</div>
</div>

<!--
**Say:** tuning advice splits people into two camps — "it is an art" and "here are three
rules". Both are right, for different plants. The flowchart is what tells you which camp you
are in today.

**Say:** and the gate at the top matters more than anything below it. If the plant is running
away from you, no table will save you. Remember that sentence — section 10 shows you a plant
that fails this gate, and it is the same car.

**Ask the room:** which box would a drone's attitude loop sit in? *(Unstable open loop — not
well behaved. Which is why you do not tune a quadcopter by raising the gain until it
oscillates.)*

**Terms, if anyone asks**

- **Well behaved** — stable open loop, near enough linear, minimum phase, manageable delay. No
  strict definition; it is a judgement.
- **Minimum phase** — no zero in the right half plane. In plain terms: the output does not
  first move the *wrong* way when you push it.
- **Open-loop stable** — left alone, disturbances die out. Our car coasts to a stop; a
  quadcopter falls over.
- **Model-based tuning** — pole placement, loop shaping, autotuning. Needs a mathematical
  model.
- **Heuristic tuning** — a table applied to measured numbers. Needs only an experiment.
-->

---

## What every one of these tables assumes

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

Three numbers. Not a model of a car — a model of a *shape*, and
a great many industrial plants have that shape.

</div>
<div>

#### The ratio that decides everything

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
**Say:** before any table, this. Every heuristic method in this section assumes your plant
looks like that transfer function. Ours does, because we built it to — a first-order body
with a lag and a transport delay in front of it.

**Point at** the ratio table. This is the number that tells you whether the job is easy. A
plant with almost no dead time relative to its time constant will take almost any gain you
throw at it; a plant that is mostly dead time will not.

**Read out** our car's ratio: θ = 1.88 s against τ = 63 s, so θ/τ ≈ 0.030 — the easy end of
the table, and comfortably inside where these rules were fitted.

**And flag the consequence now,** because it explains a plot several slides from here:
Cohen-Coon's gain scales as τ/θ, so a small ratio buys a large gain — mathematically correct,
and quite possibly more than a 150 N·m engine can execute. That is not the table being wrong.
That is the saturation trap arriving early.

**Ask the room:** what would make this car harder to control? *(More dead time. Which is
exactly what sampling adds in section 09 — same ratio, made worse by our own software.)*

**Readout — every symbol on this slide**

- **G(s)** — the plant's transfer function: output over input in the Laplace domain.
- **K** — steady-state gain. Output change per unit input change, once settled. Ours: 2.21
  km/h per N·m.
- **τ** — time constant, seconds. Time to cover 63 % of the change. Ours: 63 s.
- **θ** — dead time, seconds. How long nothing happens first. Ours: 1.878 s as fitted.
- **e<sup>−θs</sup>** — how a pure delay is written in the Laplace domain.
- **r = θ/τ** — the ratio every table keys on. Ours is about 0.030: the easy end.
- **FOPTD** — first order plus dead time. Also written FOPDT; same thing.
-->

---

## The step test, again — for real this time

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
**Read out** K, τ and θ and ask the room to check them against what they wrote down in
section 01. They must be the same numbers — it is the same test.

**Say:** and that is the whole measurement. Everything for the next four slides comes out of
these three numbers. Not the mass, not the drag area, not the gear ratio — those never appear
again.

**Say:** the scaling step matters. We stepped by 10 N·m, so we divide the speed change by 10.
That is what makes K a property of the plant rather than of the experiment.

**They get wrong:** stepping from zero, or stepping huge. The point of a step test is to
characterize the plant *where you operate it*. On a plant with v² drag, a step from rest
measures a different plant.

**Readout — every symbol on this slide**

- **tau_lo → tau_hi** — step the manipulated variable from one settled value to another, here
  31.1 → 40.1 N·m.
- **A** — the size of that input step, 9.04 N·m. Dividing by it is step 4 of the procedure and
  is what makes K a property of the plant.
- **t0 = t_step** — when the step was applied, handed to the fit rather than guessed.
- **stop = 500 s** — the analysis default, long enough for the response to settle; about eight
  time constants.
-->

---

## Reading the three numbers off the curve

![A step response with the construction that yields the three FOPTD parameters: the input step at t0, the half-change and 63 percent landmarks at t2 and t3, the intercept t1 they imply, the dead time theta from t0 to t1 and the time constant tau from t1 to t3.](/diagrams/08-foptd-construction.svg)

$$
t_1 = \frac{t_2 - \ln 2\,\cdot t_3}{1 - \ln 2} \qquad
K = \frac{B}{A} \qquad \tau = t_3 - t_1 \qquad \theta = t_1 - t_0
$$

*Use the exact constants, not rounded ones — t₁ magnifies any error
in the two landmarks by about 2.3 time constants. `fopdt_fit` in
`support.jl` is this construction.*

<!--
**Walk the figure:** the output sits still for a while — that is dead time. Then it climbs
and settles. Mark where it has covered half its total change, and where it has covered 63 %.
Those two times are the whole measurement.

**Say:** $t_1$ is where the first-order curve would have started if there had been no dead
time at all. Everything before it is θ; everything from it to $t_3$ is τ.

**Say:** and the division by $A$ matters. Scale the response by the size of the step you made
— step 4 of the procedure — and $K$ becomes a property of the plant rather than of how hard
you happened to push.

**They get wrong:** reading τ as "time to reach the final value". It is 63 % of it, and the
remaining 37 % takes another three time constants.

**Readout — every symbol on this slide**

- **t₀** — when the input stepped.
- **B** — the total change in the output, end to end.
- **t₂** — when the output had covered half of B.
- **t₃** — when it had covered 1 − 1/e of B, about 63.2 %.
- **t₁** — the intercept those two imply: where a pure first-order curve would have started.
  Everything before it is dead time.
- **K = B/A**, **τ = t₃ − t₁**, **θ = t₁ − t₀**.
- **ln 2** — appears because t₂ is the half-way point of an exponential.
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

# `with_I` and `with_D` are structural, so a PID is a different compiled
# model rather than the same one with gains set.
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
> at all — which is the second reason the engine's transport delay is in the model.

*The tables are transcribed in
`test/tuning_tables.jl`, with every coefficient checked against
`docs/materials/ControlTheory/tuning_methods.pdf` by hand.*

</div>
</div>

<!--
**Say:** this is a formula someone fitted to a family of plants in 1953. It is not derived
from our car and it knows nothing about it. What it knows is the *shape* — first order plus
dead time — and that shape is enough for a starting point.

**Read out** the three gains, with units on the first one: newton-metres per km/h.

**Point at** the response and ask whether it looks like something you would ship.
*(Cohen-Coon is usually quick and usually oscillatory. It is a starting point, not an answer
— say that phrase every time a table produces a number.)*

**Readout — every symbol on this slide**

- **r = θ/τ** — the same ratio, appearing in every cell of the table.
- **1/K** — the gain is inversely proportional to the plant's gain. A twitchy plant gets a
  gentler controller.
- **τ/θ** — and proportional to how little dead time there is. This is why k blows up as
  θ → 0.
- **P / PI / PID rows** — pick the row for the controller you intend to build; you do not have
  to use all three paths.
- **The result** — k in N·m per km/h, T<sub>i</sub> and T<sub>d</sub> in seconds.
-->

---

## Ziegler-Nichols: find the edge of stability

<!-- At the shipped theta_e = 0.3 s the ultimate period is about 2.2 s and the ultimate
     gain about 115 N.m per km/h (about 414 N.m per m/s; this loop
     runs in km/h). -->

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [08-tuning.ipynb · cell Ziegler-Nichols]
# `CruiseLoopStep` leaves both switches off, so the plain
# analysis is already the P-only loop this step needs.
DELTA = 0.1     # km/h — the smallest poke that measures cleanly

probe = Scenarios.CruiseLoopTransient(
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

k_zn, Ti_zn, Td_zn = ziegler_nichols(Ku, Pu)  # 114.56, 2.175 s
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/08-tuning.ipynb)

*Two numbers come out of this experiment, and two tuning
tables consume them — the next two slides.*

</div>
<div>

![Three proportional runs at increasing gain: one decaying oscillation, one sustained oscillation of constant amplitude, and one growing oscillation.](/figures/08-ultimate-oscillation.svg)

*Below **K<sub>u</sub>** the oscillation decays, above it grows. At **K<sub>u</sub>** it neither — and its period is **P<sub>u</sub>**.*

</div>
</div>

<!--
**Say:** this is a completely different kind of experiment. Cohen-Coon watched the plant on
its own. Ziegler-Nichols closes the loop and pushes it towards instability on purpose, then
reads two numbers off the wreckage.

**Point at** the three curves: decaying, sustained, growing. The middle one is the
measurement. Everything either side of it is how you find it.

**Read out** K<sub>u</sub> and P<sub>u</sub> from the executed notebook — I have deliberately
not printed them on the slide, because they move with the engine's transport delay. Say the
units for K<sub>u</sub>: newton-metres per km/h.

**Ask the room:** we are deliberately making a car oscillate. Would you do this on a real
vehicle? *(This is the setup for the slide after next — let them answer before you agree.)*

**If the oscillation is not clean** in the executed run — if it is squaring off against the
torque limit rather than looking sinusoidal — say so plainly: that is relay limit-cycling, not
the linear sustained oscillation the method assumes, and the K<sub>u</sub> you would read off
it is not the one the table wants.

**Readout — every symbol on this slide**

- **K<sub>u</sub>** — the *ultimate gain*: the proportional gain at which the loop oscillates
  at constant amplitude. Ours is about 115 N·m per km/h.
- **P<sub>u</sub>** — the *ultimate period*: the period of that oscillation, in seconds. About
  2.2 s here.
- **ks_probe** — the ladder of gains you walk up to find K<sub>u</sub>.
- **Sustained oscillation** — neither growing nor decaying. Below K<sub>u</sub> it decays,
  above it grows.
- **Relay limit cycling** — squared-off oscillation caused by banging between actuator limits.
  Not the linear oscillation the method assumes; if you see it, the K<sub>u</sub> you read is
  not the one the table wants.
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

*`tuning_methods.pdf` Table 2. Note what the rows cost: adding the
integral path **lowers** the gain you may use.*

</div>
<div>

> **What the numbers encode**
>
> Ziegler and Nichols were aiming at a **quarter-amplitude decay** — each overshoot a quarter of
> the one before. That was a reasonable target for a 1940s process plant. It is far more
> oscillatory than anyone wants in a vehicle.

</div>
</div>

*$T_i = 4\,T_d$ in every ZN row, whatever $P_u$ is — the two zeros are always placed in the
same ratio.*

<!--
**Read the table out** row by row and let them copy it. This is the one table from this
lecture they are most likely to use in anger.

**Point at** the gain column going *down* as you add paths. That surprises people: it is not
that PID is better than P at the same gain, it is that adding the integral spends phase
margin, so you must give gain back.

**Say:** and the footnote — $T_i$ is always four times $T_d$. In the language of the section
05 slide, Ziegler-Nichols always puts the two zeros in the same place relative to each other
and only slides them with $P_u$. That is the whole content of the method.

**Readout — every symbol on this slide**

- **K<sub>u</sub>/2, /2.2, /1.7** — the gain for P, PI and PID. Note it *falls* as you add
  paths.
- **P<sub>u</sub>/1.2, /2, /8** — the times, all fractions of the ultimate period.
- **T<sub>i</sub> = 4·T<sub>d</sub>** — true in every ZN row, whatever P<sub>u</sub> is. The
  two zeros always sit in the same ratio.
- **Quarter-amplitude decay** — the design target: each overshoot a quarter of the one before.
  A 1940s process-plant taste, not a law.
-->

---

## Tyreus-Luyben: same measurement, calmer answer

<div class="grid grid-cols-[1.4fr_1fr] gap-8">
<div>

| same $K_u$, $P_u$ | $k$ | $T_i$ | $T_d$ |
|---|---|---|---|
| PI | $K_u/3.2$ | $2.2\,P_u$ | — |
| PID | $K_u/2.2$ | $2.2\,P_u$ | $P_u/6.3$ |

*`tuning_methods.pdf` Table 3. There is no P row: the method exists
to be gentler, and a P controller has nothing to be gentle with.*

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

Three quarters of the gain, and an integrator **4.4 times slower** — $2.2P_u$ against $P_u/2$.
Same two measured numbers.

</div>
</div>

<!--
**Point at** the T<sub>i</sub> column. That is the real difference: one table divides the
ultimate period, the other multiplies it. A factor of more than four in integrator speed, from
the same experiment.

**Say:** Ziegler-Nichols was designed when a quarter-amplitude decay was considered a good
response. That is far more oscillatory than anyone wants in a vehicle. Tyreus-Luyben is the
same idea with modern taste.

**Say:** which tells you something important — a tuning rule encodes somebody's requirements,
not a law of nature. If their requirements are not yours, their table is not yours either.

**Readout — every symbol on this slide**

- **K<sub>u</sub>/2.2** — against Ziegler-Nichols' K<sub>u</sub>/1.7. Three quarters of the
  gain: 52.07 against 67.39 N·m per km/h.
- **2.2·P<sub>u</sub>** — the integral time is *multiplied* by the ultimate period where ZN
  divides it. That is a factor of 4.4 slower.
- **P<sub>u</sub>/6.3** — the derivative time.
- **No P row** — the method exists to be gentler, and a P controller has nothing to be gentle
  with.
-->

---

## Relay autotune: $K_u$ without the cliff edge

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

> **Why this is the one that ships**
>
> You choose $d$, so you choose how hard the plant is shaken. The oscillation is bounded by
> construction — you never have to walk the gain up towards instability and hope you notice in
> time. This is what the "autotune" button on industrial hardware is doing.

</div>
</div>

*The formula is the describing-function approximation of the relay: it takes the first
harmonic of a square wave of amplitude $d$, which has amplitude $4d/\pi$.*

<!--
**Say:** the lecturer's own slide lists five tuning methods and this is the fifth. It is the
only one of the closed-loop family that is safe on hardware, and it is the reason your thermal
chamber has an autotune button and your car does not have a "raise the gain until it
oscillates" button.

**Point at** the formula and say where it comes from: a relay puts out a square wave, the
plant mostly responds to its first harmonic, and a square wave of height $d$ has a first
harmonic of $4d/\pi$. Divide by the response amplitude and you have the gain at which the loop
would sustain — which is the definition of $K_u$.

**Ask the room:** what would you pick $d$ to be on a real machine? *(As small as gives a clean
measurement above the noise. The whole point is to disturb the process as little as you can
get away with.)*

**We do not run this one** in the notebooks — say so. It needs a relay block the model does
not have, and it would tell us what Ziegler-Nichols already told us.

**Readout — every symbol on this slide**

- **d** — the relay amplitude: how far above and below the steady output you switch. *You*
  choose it, and it bounds the disturbance.
- **a** — the amplitude of the resulting oscillation in the measured output.
- **P<sub>u</sub>** — its period, read straight off the plot.
- **K<sub>u</sub> = 4d/πa** — the describing-function estimate. The 4/π is the first harmonic
  of a square wave of height d.
- **Limit cycle** — the sustained oscillation a relay produces. Here it is the measurement, not
  a fault.
-->

---

## All three, one axes

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

*Three tables, one plant, one step test. They do not agree — and that is the honest state of heuristic tuning.*

</div>
</div>

<!--
**Ask the room, and make them commit:** which of these three would you ship in a car? Hands
up for each. *(Usually the calmest. Then ask why — and the answers will be about passengers
and about margin, not about rise time. That is a real engineering conversation and it is
worth ninety seconds.)*

**Say:** none of these is "the" answer. They are three starting points from three sets of
assumptions, and every one of them expects you to tweak afterwards. The value of a table is
that it gets you into the right decade in one experiment.

**Say:** and notice what we never did. We never used the mass of the car. A tuning method that
needs no model is a method you can use on hardware somebody else built.

**Readout — every symbol on this slide**

- **Three gain sets** — Cohen-Coon, Ziegler-Nichols, Tyreus-Luyben, each a (k, T<sub>i</sub>,
  T<sub>d</sub>) triple.
- **One plant, one step test** — everything that differs between the curves came out of a
  table, not out of the car.
-->

---

## Five methods, one page

| Method | Experiment | Measures | Risk to the plant | Tends to give |
|---|---|---|---|---|
| Guess and check | any | your patience | whatever you do to it | an intuition for the knobs |
| Cohen-Coon | open-loop step | $K$, $\tau$, $\theta$ | none — never leaves the stable region | quick, oscillatory |
| Ziegler-Nichols | closed loop, P only | $K_u$, $P_u$ | **drives it to the edge of instability** | aggressive, quarter-decay |
| Tyreus-Luyben | the same experiment | $K_u$, $P_u$ | the same | conservative, sluggish |
| Relay autotune | closed loop, relay | $d$, $a$, $P_u$ | bounded by the $d$ you chose | $K_u$ safely, then a table |

> **The common thread**
>
> Every row is a way of buying **two or three numbers** about the plant and spending them in a
> formula somebody else fitted. None of them is a design. All of them are a starting point you
> then adjust.

<!--
**Say:** this is the slide to photograph.

**Point at** the risk column. That is the column that decides which method you are allowed to
use on the day, and it has nothing to do with control theory — it is about what you are
willing to do to the equipment.

**Ask the room:** you have a customer's machine, in their factory, running their product.
Which row? *(Cohen-Coon, or relay autotune if you can install one. Certainly not
Ziegler-Nichols — and that is a professional judgement, not a technical one.)*

**Say:** and the honest summary of all five — they get you into the right decade. The last
factor of two is always yours.

**Terms, if anyone asks**

- **Experiment** — what you actually have to do to the plant.
- **Measures** — the two or three numbers you come away with.
- **Risk** — what the experiment costs you if it goes wrong. The column that decides which
  method you may use on the day.
- **Starting point** — what every one of these gives you. None is a finished design.
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
**Say:** this is the answer to the question I asked you two slides ago. The method is not
wrong; it is dangerous, and knowing which of your tools are dangerous is most of professional
judgement.

**Say:** and there is a middle route that we have just used without remarking on it — run
Ziegler-Nichols on a *model*, then take the gains to the hardware. You get the measurement
without the risk, at the price of trusting the model. Which is exactly why the model came
first — a whole hands-on session before this lecture.

**Ask the room:** what would you have to believe about the model for that to be safe? *(That
it is right near the stability boundary — which is where models are least trustworthy. There
is no free lunch here and they should feel that.)*

**Terms, if anyone asks**

- **Edge of instability** — where a small increase in gain makes oscillation grow instead of
  decay.
- **Why simulation is different** — an unstable model costs a re-run; an unstable vehicle costs
  rather more.
- **The middle route** — run ZN on the model, take the gains to the hardware. You trade risk
  for trust in the model, precisely where models are least trustworthy.
-->

---

## The trap

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [08-tuning.ipynb · cell The saturation trap]
# push the gains until the response looks superb
hot = tuned(8 * k_zn, Ti_zn / 2, Td_zn)

plot_speed(hot; sig = SPEED, setpoint = 110)   # looks perfect
plot_torque(hot; commanded = "loop.controller.y",
            delivered = "loop.plant.engine.limiter.y")
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/08-tuning.ipynb)

**Open in Dyad** `dyad/Lecture1/CruiseLoop.dyad`

> **The second plot**
>
> The commanded torque at the instant of the step is far outside anything the engine can
> deliver — and the speed plot gave you no hint at all.

</div>
<div>

![Two panels: a near-perfect speed response above, and below it the commanded torque spiking far above the engine's 150 newton-metre limit line.](/figures/08-saturation-trap.svg)

*Above: the response you were hoping for. Below: what it costs, against the torque limit drawn on.*

</div>
</div>

<!--
**Show the speed plot first and say nothing about torque.** Let them admire it. Ask whether
anyone would sign this off.

**Then show the torque plot.** Read out the peak and compare it to 150.

**Say:** a linear model will happily accept a controller your hardware cannot execute, and it
will not warn you. There is no error, no exception, no red line. The simulation is internally
consistent and completely useless.

**Then re-run with the limiter active** and watch the beautiful response disappear. Point out
that the anti-windup from section 06 is now doing real work — and that without it this same
design would also wind up.

**Say the rule:** always plot the actuator command. Every time. It is one extra line in the
notebook and it is the difference between a design and a drawing.

**In the model:** The notebooks lift **`T_max` and `y_max`** to run this. Put them back to 150
and re-run: the beautiful response is the first thing to go.

**Readout — every symbol on this slide**

- **8·k_zn, T<sub>i</sub>/2** — gains pushed well past the table, to make the response look
  superb.
- **The upper plot** — speed. Looks perfect.
- **The lower plot** — commanded torque, with the 150 N·m limit drawn on. Read the peak out
  loud.
- **The rule** — always plot the actuator command. One extra line, and it is the difference
  between a design and a drawing.
-->

---

## What this bought us

- A gain set from one step test, with no model of the car in the calculation.
- Three tables, three answers, and the judgement to choose between them.
- One rule that outlives all three: **plot the actuator command.**

### Next: the same controller, running on a computer that only looks occasionally. <Link to="discretization">→ 09, discretization</Link>

<!--
**Say:** if you remember one slide from this lecture in five years, make it the previous one.
Everything else here you can look up.

**The practical task** from the course slides is exactly what we just did — study the system,
apply Ziegler-Nichols, find suitable constants. You now have the notebook that does it, and
you can re-run it with your own numbers.
-->
