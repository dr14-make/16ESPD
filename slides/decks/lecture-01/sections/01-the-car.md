---
routeAlias: the-car
layout: section
---

###### Notebook 01

# The car

You built it and know its physics. Now measure it as if you did not.

`notebooks/lecture01/01-the-car.ipynb`

<!--
**Say:** no controller in this notebook either. The force balance, the terminal speed and the
engine's lags were explained and built in the hands-on. What is left is the control
engineer's view of the same car: one experiment, three numbers.

**Timing:** 7 minutes. Two simulations — start the first solve while the "car you built"
slide is still up.

**Cut order:** this is spine — do not cut it. The lecture is not complete without it.
-->

---

## Full throttle from rest

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [01-the-car.ipynb · cell 4. Open loop to terminal speed]
Scenarios = VehicleSystemsComponents.Lecture1

wot = Scenarios.WideOpenThrottleTransient()

plt = plot_speed(wot; sig = "plant.v_kmh", label = "speed",
                 title = "Full torque from rest, flat road")
hline!(plt, [v_terminal * 3.6]; ls = :dash, color = :grey,
       label = "terminal speed, analytic")
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/01-the-car.ipynb)

**Open in Dyad** `dyad/Lecture1/WideOpenThrottle.dyad`

> **Watch the time axis**
>
> 300 seconds, and the last stretch barely moves. The car's own time constant is about
> **67 s**.

*↩ Hands-on step 05: [why it takes so long — the car's time constant](../handson-01/index.html#/time-constant)*

</div>
<div>

![Speed against time, full torque from rest, rising asymptotically to about 246 km/h over several hundred seconds.](/figures/01-speed-to-terminal.svg)

*Speed to terminal, full torque from rest — the course model, and the same curve as hands-on step 05. The asymptote is the 246 km/h derived on paper.*

</div>
</div>

<!--
**Run it** before you start talking — it is the slowest solve in the notebook.

**Say:** everyone has seen this curve — it is their step 05. The point today is not the 246;
it is the time axis. Two and a half minutes to get within one per cent, because drag is a
very weak restoring force at low speed.

**Say:** remember this time axis. In notebook 03 the closed loop will do a 20 km/h step in a
handful of seconds. Feedback did not make the engine stronger; it made the *dynamics*
different. That is the single most important sentence about feedback in this lecture.

**Check:** if the curve runs away instead of flattening, the sign on the drag force is wrong.

**In the model:** **why a harness exists**: two constant sources feeding the plant's two
inputs, and the initial conditions. Leave those inputs dangling and the model will not solve.
It is the course's version of the students' `CarFullThrottle` bench.

**Readout — every symbol on this slide**

- **300 s** — the run length. About twice the 143 s the car needs to reach 99 % of terminal
  speed.
- **67 s** — the car's own time constant near 100 km/h: m ÷ (dF/dv), mass divided by how hard
  drag pushes back per unit of speed.
- **Time constant** — the time to cover 63 % of the remaining distance to the final value.
  Three of them gets you to 95 %.
- **The dashed line** — the 246 km/h computed by hand in hands-on step 05. Two routes, one
  number.
-->

---

## The step test

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [01-the-car.ipynb · cell 5. The step test, and the zoom below it]
# the two cruise torques derived on paper, handed to the model
step_test = Scenarios.CarStepTestTransient(
    tau_lo = T_90, tau_hi = T_110, v0 = 90 / 3.6, t_step = t_step)

plot_torque(step_test;
    commanded = "cmd.y",
    delivered = "plant.engine.limiter.y",
    limit = nothing,
    xlims = (t_step - 0.5, t_step + 3.0))
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/01-the-car.ipynb)

**Open in Dyad** `dyad/Lecture1/CarStepTest.dyad`

*↩ Hands-on step 02: [why the engine is late and slow](../handson-01/index.html#/pedal)*

1. Wait until the process is at rest.
2. Put the controller in manual.
3. Change the control variable rapidly, and as large as noise allows.
4. Record the response and scale it by the size of the step.

</div>
<div>

![Commanded and delivered torque on one axes: the delivered trace starts late by the transport delay and then lags behind the command.](/figures/01-torque-step.svg)

*Commanded against delivered torque. The gap at the start is the transport delay; the curve after it is the manifold lag.*

</div>
</div>

<!--
**Say:** this procedure is four lines long and it is the foundation of notebook 08. Every
heuristic tuning rule in this lecture reads its numbers off this one experiment.

**Point at, on the torque plot:** first the flat piece where the command has stepped and
nothing has happened yet — that is *dead time*, the engine has not been told yet. Then the
curve — the manifold filling. Two different delays with two different causes, and they need
different treatment.

**Tie back:** hands-on step 02 argued the lags in on paper — without them the car is first
order, Ziegler-Nichols has nothing to oscillate and Cohen-Coon divides by a dead time of zero.
This plot is the first time they are visible as a control problem.

**Ask the room:** why step from 31 to 41 N·m rather than 0 to 150? *(Because we want the
response around the operating point we actually drive at. A huge step wanders across the
nonlinearity in v².)*

**In the model:** **`tau_lo` and `tau_hi` are parameters**, so the step test runs the
equation the students just wrote down. Then `IdealEngine.dyad`: **delay → lag → limiter**, in
that order.

**Readout — every symbol on this slide**

- **T_90 = 31.1 N·m, T_110 = 40.1 N·m** — the cruise torques for 90 and 110 km/h, derived
  from the force balance and handed to the model as parameters.
- **t_step = 50 s** — when the command steps.
- **Commanded torque** — `cmd.y`, what the controller asks for.
- **Delivered torque** — `plant.engine.limiter.y`, what comes out of the engine after the
  delay, the lag and the limit.
- **Dead time** — the flat gap at the start where the command has changed and nothing has
  happened. A pure delay.
- **Lag** — the curve after it. A first-order response, not a delay: it starts immediately and
  approaches gradually.
-->

---

## Three names for one curve

<div class="grid grid-cols-3 gap-6">
<div>

### Transient

The temporary part. The system's reaction to an abrupt change, which dies
out.

</div>
<div>

### Steady state

What is left after long enough that every startup effect has gone. The
settled relationship between input and output.

</div>
<div>

### Dynamic response

The whole journey — their sum.

</div>
</div>

$$
y(t) \;=\; y_{\text{transient}}(t) \;+\; y_{\text{steady-state}}(t)
$$

> **Why the vocabulary matters today**
>
> Proportional control is about to fail in *steady state* while looking fine in the
> *transient*. Without these three words that failure is invisible.

<!--
**Point at the speed plot from the previous slide** and mark the two regions with your hand:
here it is moving, here it has stopped moving. Do it physically — this is the one piece of
vocabulary everyone thinks they already have and half the room does not.

**Ask the room:** where exactly does the transient end? *(It does not — it decays
asymptotically. We pick a threshold, usually 2 % or 5 %, and that choice is ours, not the
system's.)*

**Flag forward:** every requirement you will ever be given is phrased in these terms — rise
time and overshoot live in the transient, steady-state error lives in the other half.

**Terms, if anyone asks**

- **Transient response** — the temporary part, which decays. Rise time, overshoot and settling
  time are measured here.
- **Steady-state response** — what is left once the transient has died. Steady-state error is
  measured here.
- **Dynamic response** — the sum of the two. The whole journey from one settled state to the
  next.
- **Settling time** — when the response stays within a band, usually 2 % or 5 %, of its final
  value. The band is our choice, not the system's.
-->

---

## Reading K, τ and θ off the curve

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [01-the-car.ipynb · cell 7. Reading K, tau and theta off the curve]
K, tau, theta = fopdt_fit(step_test;
    output = "plant.v_kmh", A = T_110 - T_90, t0 = t_step)

# and, for comparison, the tangent gain and time constant at
# each end of the step, straight from the force balance
local_gain(v) = 3.6 / (2 * c_drag * v * CAR.r / CAR.i)
local_tau(v)  = CAR.m / (2 * c_drag * v)
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/01-the-car.ipynb)

- **K** = 2.21 km/h per N·m
- **τ** = 63.0 s
- **θ** = 1.88 s

> **θ is not the engine's delay**
>
> It is five times larger. Drag is quadratic, so the car's time constant changes across the
> step, and θ is the only parameter that can absorb that. The fit measures bend, not delay.

</div>
<div>

![The speed response to the torque step: flat at 90 km/h, then an S-shaped climb settling at 110.](/figures/01-step-response.svg)

*The step response the three numbers are read from. θ is the flat piece before it moves, τ the rise, K the settled change divided by the torque step.*

</div>
</div>

<!--
**Read out** all three values from the cell output, slowly, with units. Students will need
them again in section 08 and they should write them down now.

**Say:** this is the whole of system identification for a first-order plant plus dead time —
FOPTD. A step in, a curve out, three numbers off the curve. No free-body diagram, no
equations of motion. If somebody handed you this car as a sealed box you could still have got
here.

**Do not skip the amber box, and do not let it embarrass you.** A student who knows the
engine's delay is 0.3 s will see 1.88 s and conclude the fit is broken. It is not. FOPTD has
three parameters and our car is not FOPTD — it is a *quadratic* drag law, so its time
constant is different at every speed. The fit spends θ on the mismatch because θ is the only
parameter left.

**Say:** and this is what a practitioner would have. You do not get to know that your plant
is really quadratic; you get a curve and three numbers. Notebook 08 tunes from these three
exactly as they stand, and the controller works — which is the more interesting result.

**Point at:** the ratio θ/τ — about 0.030 here. That is the number every tuning rule in
notebook 08 keys on, and it puts this car at the easy end of the range.

**Honest framing, if asked:** quote the tangent gain and time constant at each end of the
step — 74.1 s at 90 km/h, 60.6 s at 110. They bracket the fit rather than pretending it is
exact.

**They get wrong:** reading τ as "time to reach the final value". It is the time to reach
63 % of it. The helper uses the two-landmark construction from the tuning document, not an
eyeball.

**Readout — every symbol on this slide**

- **K = 2.21 km/h per N·m** — steady-state gain: how far the output moves per unit of input,
  once settled.
- **τ = 63.0 s** — time constant: how long it takes to get there, dominated by the vehicle,
  not the engine.
- **θ = 1.878 s** — dead time as the fit reports it. *Not* the engine's 0.3 s delay — see the
  amber box.
- **FOPTD** — first order plus dead time, the three-parameter shape these numbers describe.
- **Tangent gain / time constant** — the local values computed from the force balance at each
  end of the step: 74.1 s at 90 km/h, 60.6 s at 110. They bracket the fit honestly.
- **Secant gain** — the total speed change divided by the total torque change, 20 ÷ 9.04. What
  K should land near.
-->

---

## What this bought us

- The car you built, seen from outside: one step in, one curve out.
- Three numbers off one step test — *K*, *τ*, *θ* — which section 08 will turn into gains.
- The vocabulary: transient, steady state, dynamic response.

### Next: we have a model of the car. Do we even need to measure it? <Link to="open-vs-closed-loop">→ 02, open loop versus closed loop</Link>

<!--
**Say:** we now know what the car does when left alone — from its physics, and now from a
measurement. That is the only honest starting point for control, and it is the step people
skip.

**Bridge:** and here is an uncomfortable thought before the break in pace — we have a model of
the car that is good enough to predict its terminal speed. If the model is that good, why
measure anything at all? Why not just compute the right throttle and apply it? *(That is
notebook 02, and the answer is a hill.)*

**If you are short on time** and cutting section 02, bridge straight to 03 instead: "we know
the car; now let us try to make it hold a speed we choose."
-->
