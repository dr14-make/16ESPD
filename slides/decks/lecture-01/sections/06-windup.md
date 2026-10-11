---
routeAlias: windup
layout: section
---

###### Notebook 06

# Integral windup

The integrator does not know the engine has run out.

`notebooks/lecture01/06-windup.ipynb`

<!--
**Say:** everything so far has been true of a linear model. This section is about the first
place where the real world stops being linear, and it is the failure that has actually
destroyed hardware.

**Timing:** 25 minutes, the longest section and the most practically useful thing in the
lecture: 3 for the two halves, 5 for steps 6a and 6b, 6 for the climb harness (6c) and the
two slides on why the overshoot is coming, 6 for clamping and step 6d, 5 for back-calculation,
the three-way comparison and the two limits. Four build steps: two inside `GradeCar` and
`CruiseController`, one new climb harness, and one equation.
-->

---

## The plant has two halves

- The **actuator** — the thing that supplies the force. Our engine.
- The **process** — the thing being pushed. Our car.

Real actuators have backlash, rate limits and **saturation**.
A linear model has none of these: ask it for a million newton-meters and it will agree.

**Open in Dyad** `dyad/HandsOn/Engine.dyad` — the `limiter` after the lag

> **The hill we are about to drive up**
>
> 130 km/h on a sustained 10 % climb needs **2023 N** at the road.
>
> The engine can deliver **1935 N**.
>
> The car will lose, and head for about **118 km/h** — a 120 s climb gets it to **119.05**,
> still falling.

*↩ Hands-on step 07: [the slope, and the 2023 N sum](../handson-01/index.html#/slope)*

<!--
**Say:** the numbers in the red box are not chosen to make a point. They come out of the
force balance from hands-on step 05, with the parameters on the front slide. You can compute
them; that is the whole point of having built the car first.

**Say:** and notice how close it is — 2023 against 1935. Four percent short. This is not a
cartoon overload; it is the ordinary case of a fully loaded car on a long climb.

**Ask the room:** what does the controller see when the engine is pinned at its limit?
*(Exactly what it saw before: a speed that is too low. It has no sensor for "the actuator has
given up". Hold that thought for two slides.)*

**In the model:** The **`limiter`**: `y_max = T_max`, and `y_min = 0`. That second one
matters too — this engine cannot brake, so downhill it has no answer at all.

**Readout — every symbol on this slide**

- **Actuator** — the thing that supplies the force or energy. Our engine.
- **Process** — the thing being pushed. Our car.
- **Saturation** — an actuator at its limit, unable to follow the command it was given.
- **2023 N** — the tractive force a 10 % climb at 130 km/h demands. **1935 N** — what the
  engine can deliver. Four percent short.
- **118 km/h** — the asymptote this climb heads for. Say *heads for*, not *settles at*: the
  climb is 120 s long and the car is at 119.05 km/h and still falling when the road flattens.
- **y_min = 0** — the limiter's lower bound. This engine cannot produce negative torque, so
  it cannot brake.
-->

---
routeAlias: step-6a
---

## Step 6a: the ceiling becomes a parameter

![GradeCar's parameter panel with T_max, and the engine selected so its binding T_max = T_max shows.](/img/lecture-01/step06-tmax.png)

*Your `GradeCar` · add `parameter T_max::Torque = 150` · `engine`: `T_max = T_max`*

[page: step 6a](../lecture/lecture-01/#step-6a) · reference `dyad/HandsOn/GradeCar.dyad`

<!--
**Say:** the engine has had a ceiling since hands-on step 02 — the `limiter` inside it, at
150 N·m. Until now nobody outside the engine could touch it. Today we need to, so it moves up
one level, onto the car.

**Build, in the students' `MyCar.GradeCar`:**

1. Open `GradeCar`, diagram view. In the parameter panel with nothing selected, add
   `parameter T_max::Torque = 150`, description "Peak deliverable torque".
2. Select `engine`. In its parameter panel set `T_max = T_max`. The engine already declares
   `T_max` (hands-on step 02), so this is a binding, not a new parameter.
3. Nothing to wire. No new blocks.

**Check before moving on:** the PID checkpoint loop from section 05 compiles and gives the same
curve as before — 150 is the default, so nothing may move. If it moved, the binding went to
the wrong instance.

**Say:** this is the hands-on move "add a parameter and pass it down", once more. `T_max` is
a fact about the hardware. The next step gives the controller its own number, and the rest of
the section is about what happens when the two disagree.

**Catch-up:** `HandsOn.GradeCar` carries `T_max` already; a student who is behind can
replace `plant` with it.
-->

---
routeAlias: step-6b
---

## Step 6b: the controller gets a limit of its own

![CruiseController in progress: gain feeds the limiter, and the limiter feeds the output y.](/img/lecture-01/step06-limiter.png)

*Your `CruiseController` · `Limiter(y_max = y_max, y_min = y_min)` between `gain` and `y`*

[page: step 6b](../lecture/lecture-01/#step-6b) · reference `dyad/Lecture1/CruiseController.dyad`

<!--
**Say:** the engine refuses anything above 150. The controller has never known that: it can
ask for a thousand N·m and the engine silently clips it. We give the controller its own
ceiling, so that it can at least see when it is asking for more than it gets.

**Build, inside the students' `CruiseController`:**

1. Add two parameters: `parameter y_max::Real = 1e300` ("Maximum output") and
   `parameter y_min::Real = -y_max` ("Minimum output") — the reference's defaults, so a
   controller with no limits set behaves as before.
2. Drag in `BlockComponents.Nonlinear.Limiter`. Name it **`limiter`**. Set
   `y_max = y_max`, `y_min = y_min`.
3. Delete the wire `gain.y → y`.
4. Wire `gain.y → limiter.u` and `limiter.y → y`.

**In `CruiseLoopStep`:** select `controller` and set `y_max = 150`, `y_min = 0` — the reference
`CruiseLoop`'s `y_max = T_max`, `y_min = 0`. Zero because this engine cannot brake.

**Check before moving on:** re-run `CruiseLoopTransient` on `CruiseLoopStep`. The 90 → 110 km/h step asks for
more than 150 N·m at the start, so `controller.y` now sits flat on 150 for the first moments
instead of spiking above it. `controller.gain.y` is the command *before* the limiter; plot
both and the gap between them is the saturation.

**They get wrong:** naming. The instance must be `limiter` and the pre-limiter signal
`gain.y`, or the notebook paths and the clamping equation in 6d will not find them.
-->

---
routeAlias: step-6c
---

## Step 6c: drive up the hill

<div class="grid grid-cols-2 gap-8">
<div>

![The climb harness: a constant 130 km/h demand, the controller and the GradeCar plant, with a pulse driving the road input.](/img/lecture-01/step06-climb.png)

</div>
<div>

![Speed, controller output and integrator state through the climb and after it: the integrator keeps climbing while the engine is saturated, and the speed overshoots after the crest.](/img/lecture-01/step06-windup-plot.png)

</div>
</div>

*Duplicate `CruiseLoopStep` → `CruiseClimb` · `demand` → `Constant(k = 130)` ·
`road` → `Pulse(amplitude = 0.10, offset = 0, start_time = 30, duty_cycle = 1.0, period = 120)` ·
`controller.xd0 = -130` · start at 130 km/h*

[page: step 6c](../lecture/lecture-01/#step-6c) · reference `CruiseClimb` in `dyad/Lecture1/WindupClimb.dyad`

<!--
**Say:** we have a 10 % hill that needs 2023 N at 130 km/h, and an engine that makes 1935.
Drive up it. Nothing in the controller changes — only the road.

**Build — a new harness in `MyCar`, beside `CruiseLoopStep`:**

1. Duplicate `CruiseLoopStep` (section 02). Name the copy **`CruiseClimb`**, the reference
   harness's name. `CruiseLoopStep` itself stays as it is, a checkpoint to come back to. The
   four instances keep their names: `demand`, `controller`, `plant`, `road`.
2. Replace `demand` with `BlockComponents.Sources.Constant`, `k = 130`. Wire
   `demand.y → controller.u_s`.
3. Replace `road` with BlockComponents › Sources › Pulse with `amplitude = 0.10`,
   `offset = 0`, `start_time = 30`, `duty_cycle = 1.0`, `period = 120`, named `road`. Wire
   `road.y → plant.grade`. The hill starts at 30 s and the road flattens again at 150 s.
   `MyCar` cannot see the course library; this pulse is what the reference uses, wrapped in
   its `GradeProfile`.
4. `controller`: `k = 56`, `Ti = 10`, `Td = 0.5` (the defaults from sections 03–05) and
   `y_max = 150`, `y_min = 0` (set in 6b). And `xd0 = -130`: the default −90 seeds the
   derivative filter for a cruise at 90 km/h; this run cruises at 130, so the filter's settled
   input `wd·u_s − u_m` is −130. Leave it at −90 and the run opens with a derivative kick.
5. Initial conditions, in the code view — the same three lines `CruiseClimb` uses:
   `initial plant.body.mass.s = 0`, `initial plant.body.mass.v = 36.111111111111114`
   (130 km/h in m/s), `initial plant.engine.lag.x = 50.9693` (the holding torque at
   130 km/h on the flat).
6. **▷ Run Analysis** → TransientAnalysis, name it `CruiseClimbTransient`, `stop = 400`. Run it.

**Plot, on one axes or stacked:** `plant.v_kmh`; `controller.gain.y` (the command, before
the limiter); `controller.y` (after it); `plant.engine.limiter.y` (what the engine
delivers); `controller.integrator.y` on its own axis.

**What the plot must show before moving on:**

- the speed sagging from 130 after t = 30 s, heading for about 118, 119.05 at the crest;
- `controller.y` and the delivered torque flat on 150 through the climb;
- `controller.gain.y` and the integrator still climbing, far above anything the engine can
  give;
- after t = 150 s, the overshoot — the notebook's no-anti-windup run peaks 49.47 km/h over
  the setpoint and takes 66.7 s to recover.

This is the students' controller with a limiter and no anti-windup: the "none" row of the
three-way table. If their overshoot is a few km/h rather than tens, the integrator is not
wired from `error` — check that before going on.

**Catch-up:** the reference `Lecture1.CruiseClimb` has the same name, but its loop is the
back-calculation comparison (`LimPID`). The no-anti-windup run is
`Lecture1.ClampingCruiseClimbTransient` with `y_max = 1e6`, `y_min = -1e6`: limits the command
never reaches, so the clamp never acts.
-->

---

## The climb, with an ordinary PI controller

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [06-windup.ipynb · cell The climb, no anti-windup]
Scenarios = VehicleSystemsComponents.Lecture1

SPEED     = "loop.plant.v_kmh"
COMMAND   = "loop.controller.gain.y"        # before the limiter
DELIVERED = "loop.plant.engine.limiter.y"   # on the crankshaft
INTEGRAL  = "loop.controller.integrator.y"

# Clamping acts only when the command reaches a limit; limits it never
# reaches give the controller with no anti-windup at all.
no_aw = Scenarios.ClampingCruiseClimbTransient(
    k = 56.0, Ti = 10.0, Td = 0.5, y_max = 1.0e6, y_min = -1.0e6,
    v_set = 130.0, gradient = 0.10,
    start_time = 30.0, duration = 120.0, stop = 400.0)

plot_speed(no_aw; sig = SPEED, setpoint = 130)
plot_torque(no_aw; commanded = COMMAND, delivered = DELIVERED)
signal(no_aw, INTEGRAL)                 # the integrator, separately
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/06-windup.ipynb)

**Open in Dyad** `dyad/Lecture1/WindupClimb.dyad`

</div>
<div>

![Stacked traces through a sustained climb: speed falling below the setpoint, delivered torque pinned flat on the limit line, commanded torque and the integrator state climbing far above it.](/figures/06-climb-windup.svg)

*Delivered torque is flat on the limit. Commanded torque and the integrator keep climbing anyway.*

</div>
</div>

<!--
**Point at, in this order:**

- The speed trace sagging away from the setpoint at t = 30 s. The car is losing.
- The delivered-torque trace lying flat on the limit line. The engine is doing everything it
  can.
- The commanded-torque trace carrying on upward, past the limit, off into nonsense.
- The integrator, which is what is driving it there.

**Say:** the integrator's rule is "error is non-zero, therefore keep accumulating". It is
obeying that rule perfectly. Nothing in the loop tells it that the accumulation has stopped
buying anything.

**Read out** the peak commanded torque and compare it to 150 N·m. Say the ratio out loud — it
is usually several times over.

**Say (the drone story, if it helps):** it is the same as holding a drone down on the ground
while it is trying to fly to 50 meters. The propellers max out at 1000 rpm, the integrator
winds the command to 2000, and the moment you let go…

**In the model:** `gradient`, `start_time` and **`duration`**. The road flattens again because
the duration is finite, and the flattening is where the damage shows.

**Readout — every symbol on this slide**

- **gradient = 0.10** — tan α, a 10 % climb, about 5.7°.
- **start_time = 30 s, duration = 120 s** — the hill starts at 30 s and the road flattens
  again at 150 s.
- **v_set = 130 km/h** — the cruise setpoint.
- **Commanded torque** — what the controller asks for; it keeps climbing. **Delivered
  torque** — what the engine gives; it is flat on the limit.
- **The integrator state** — plotted separately, because it is the thing actually going wrong
  and it is invisible in the speed trace.
- **y_max = 1.0e6, y_min = -1.0e6** — controller limits the command never reaches, so the
  clamp never acts: no anti-windup, deliberately, so the failure is visible. The engine still
  stops at 150 N·m.
-->

---

## Why the crash is already scheduled

When the road flattens at t = 150 s, the car accelerates. The error changes sign. The
integrator begins to unwind.

But it is unwinding *from far above the limit*. While the command falls from 400 N·m to 150,
the engine delivers the same full torque it was delivering before.

**Nothing the car does can be seen at the output until the command comes back inside the
limit.**

> **The dangerous property**
>
> The delay between "the error changed sign" and "the actuator responded" is not set by the
> plant, or by the gains. It is set by how far the integrator was allowed to wander while nobody
> was looking.

<!--
**Say it with the drone numbers, they are cleaner:** the integrator asks for 2000 rpm, the
motors do 1000. Let go. The drone shoots up past 50 m. The error goes negative. The integrator
starts coming down — 1900, still 1000 at the motors. 1500, still 1000. 1100, still 1000. Only
at 1000 does anything at all begin to happen, and by then the drone is out of sight.

**Say:** and that is the actual harm. Winding up is not itself the problem — commanding
400 N·m from a 150 N·m engine hurts nothing. The problem is the time it takes to *unwind*,
during which the controller is effectively disconnected.

**Ask the room** before running the next cell: how far past 130 km/h do you think we go?
*(Take two guesses, write them on the board, then run it.)*

**Terms, if anyone asks**

- **Windup** — an integrator accumulating past the point where the actuator can act on it.
- **Unwinding** — coming back down. The harm is here, not in the winding: until the command
  falls back inside the limit, nothing the car does reaches the engine.
- **Effectively disconnected** — the phrase to use. During unwinding, the loop is open whether
  you designed it that way or not.
-->

---

## The overshoot

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [06-windup.ipynb · cell The overshoot]
t, v = signal(no_aw, SPEED)

plt = plot_speed(no_aw; sig = SPEED, setpoint = 130)
vline!(plt, [30.0, 150.0]; ls = :dot, color = :gray,
       label = "climb starts / ends")

# The car starts AT the setpoint, so there is no step to normalize
# against: `overshoot` would divide by zero. Measure the excess.
peak = maximum(v)
@show peak peak - 130 t[argmax(v)]      # km/h, km/h over, s
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/06-windup.ipynb)

> **In a real car**
>
> This is a cruise control that, at the top of a long climb, accelerates hard for several
> seconds while the driver is doing nothing at all.

</div>
<div>

![Speed through and after the climb: a sag during the climb, then a large overshoot above the setpoint once the road flattens, before settling back.](/figures/06-overshoot.svg)

*The road flattens at t = 150 s, and the car keeps accelerating well past the setpoint before the integrator has unwound.*

</div>
</div>

<!--
**Read out** the peak speed, and how long the car spends above the setpoint. Compare against
the guesses on the board.

**Say:** nobody commanded this. The driver asked for 130 and the car chose to do something
else for several seconds. Any control failure that surprises the operator is a safety
problem, whatever the numbers say.

**Ask the room:** what would you change to stop it? *(Collect answers before showing the fix.
"Limit the output" is the usual first one — and it is not enough on its own, which is a useful
thing for them to discover in a moment.)*

**Readout — every symbol on this slide**

- **peak − 130** — the excursion past the setpoint, in km/h. Not the `overshoot` helper:
  that divides by the step size, and this run starts at the setpoint, so there is no step.
- **t[argmax(v)]** — when the peak happens, in seconds.
- **The dotted verticals** — where the climb starts and ends.
- **The peak** — read it off and compare with the guesses on the board.
-->

---

## Clamping: two conditions

![Block diagram of the clamping anti-windup logic: the controller output is compared before and after the saturation block, the sign of the error is compared with the sign of the output, and when both tests pass an AND gate switches the integrator input to zero.](/diagrams/06-clamping.svg)

*Both true → stop integrating. Either one false → the integrator is restored and starts coming down immediately.*

<!--
**Walk the diagram** with your hand, in this order: output, saturation block, the two
comparisons, the AND, the switch back into the integrator.

**Say:** first check — compare the controller's output before and after the saturation
block. Equal means we are inside the limit and everything is fine. Not equal means we are
saturating.

**Say:** second check — do the error and the output have the same sign? Same sign means the
integrator is still pushing in the direction that is already saturated. It is trying to make
things worse.

**Say:** both true, and only both, and we switch the integrator's input to zero. It freezes.
It does not reset, it does not decay — it holds, ready to move the instant either condition
stops being true.

**They get wrong:** thinking clamping means "limit the integrator to some maximum value". It
does not. It stops the accumulation conditionally. A fixed cap would still wind to the cap and
still have to unwind from it.

**Also note:** this is conditional integration, the method taught in the video the students
were pointed at. It is not the only method — back-calculation feeds the saturation error back
into the integrator instead — and we compare both next.

**Readout — every symbol on this slide**

- **Condition one** — the controller output before the saturation block differs from the
  output after it. That is what "saturating" means, operationally.
- **Condition two** — sign(e) = sign(u): the integrator is still pushing in the direction
  that is already maxed out.
- **AND** — both, and only both. Either one false and the integrator is released.
- **The switch** — sets the integrator's *input* to zero. It freezes; it does not reset and it
  does not decay.
- **Conditional integration** — the other name for clamping.
-->

---
routeAlias: step-6d
---

## Step 6d: two conditions, one equation

<div class="grid grid-cols-2 gap-8">
<div>

![CruiseController code view: the integrator input given by a nested ifelse equation that freezes it while the output is saturated and the error pushes further into the limit.](/img/lecture-01/step06-clamping-code.png)

</div>
<div>

![The same three signals as the windup run, on the same axes, with clamping: the integrator holds flat while saturated and the speed returns to the setpoint after the crest with almost no overshoot.](/img/lecture-01/step06-clamping-plot.png)

</div>
</div>

*Your `CruiseController` · delete `error.y → integrator.u` · in code:
`integrator.u = ifelse(...)` on `limiter.y` and `error.y` · re-run `CruiseClimb`*

[page: step 6d](../lecture/lecture-01/#step-6d) · reference `ClampingCruiseClimb` in `dyad/Lecture1/WindupClimb.dyad`

<!--
**Say:** the diagram on the previous slide is two comparisons and a switch. A diagram of it
would be eight blocks; an equation is four lines. Dyad lets you mix the two, so we write it.

**Build, inside the students' `CruiseController`:**

1. Diagram view: delete the wire `error.y → integrator.u`. The integrator now has an
   unconnected input; the next equation is what drives it.
2. Switch to the code view. Under the existing declarations, add
   `variable control_error::Real`.
3. In `relations`, add:

```
control_error = error.y
integrator.u = ifelse(limiter.y >= y_max,
                 ifelse(control_error >= 0, 0.0, control_error),
                 ifelse(limiter.y <= y_min,
                   ifelse(control_error <= 0, 0.0, control_error),
                   control_error))
```

Read it aloud as the two conditions: at the upper limit *and* the error still pushing up →
zero; at the lower limit *and* the error still pushing down → zero; otherwise the integrator
gets the error as before. Nested `ifelse` because the equation has no boolean `and`.

4. Back to the diagram: `integrator` has no wire into it, and that is correct. It is still
   wired `integrator.y → add_pid.u3`.

**Re-run `CruiseClimbTransient`,** same plot as 6c, same axes.

**What the plot must show before moving on:**

- the same sag on the climb, to 119.04 km/h against 119.10 — clamping adds no torque;
- `controller.integrator.y` going flat once the limiter saturates, instead of climbing;
- after t = 150 s: 0.17 km/h over the setpoint and back within 3.5 s, against 49.47 km/h
  and 66.7 s without it.

**They get wrong:** leaving the old wire in place. Then `integrator.u` is defined twice,
once by the connection and once by the equation, and Dyad reports one equation too many.
Second most common: testing `gain.y` instead of `limiter.y`. The output of the limiter is the
saturated signal, so `limiter.y >= y_max` is exactly "at the limit".

**Catch-up:** `ClampingCruiseClimb` is this harness with the reference controller; the
reference `CruiseController` carries this exact equation.
-->

---

## The other way: back-calculation

<div class="grid grid-cols-2 gap-8">
<div>

Instead of switching the integrator off, feed the part of the command
that did not get through back into it:

$$
\dot{I} \;=\; \frac{k}{T_i}\,e \;+\; \frac{1}{T_t}\bigl(u_{sat} - u\bigr)
     \qquad T_t = N_i\,T_i
$$

- Inside the limit $u_{sat} = u$, the second term is zero, and it is an ordinary integrator.
- In saturation the term is negative and pulls the integrator back down towards the value
  that would just reach the limit.

</div>
<div>

| | Clamping | Back-calculation |
|---|---|---|
| Action | on / off | continuous |
| Tuning | none | $N_i$ — how fast it unwinds |
| Reads | trivially | needs a second look |
| Where | your `CruiseController`, step 6d | `LimPID`, via `Ni` |

*Both keep the integrator near the limit rather than far above
it, which is the only thing that matters.*

**Open in Dyad** `dyad/Lecture1/WindupClimb.dyad` — `CruiseClimb`, whose loop
`BackCalcCruiseLoop` closes `LimPID` around the same `GradeCar`

</div>
</div>

<!--
**Say:** this is the method your toolbox most likely implements, so it is worth being able to
read. Clamping is the one that is easy to explain and easy to get right; back-calculation is
the one with a smoother handover and one more number to choose.

**Point at** the tracking time constant $T_t$. Small means the integrator is dragged back hard
the moment you saturate; large means it barely notices. Set it too small and the integral path
stops contributing at all near the limit.

**Ask the room:** what does back-calculation do that clamping does not? *(It unwinds while
still saturated, rather than merely refusing to wind further. You would expect it to recover
better. On this hill it does not — clamping overshoots 0.17 km/h and recovers in 3.5 s,
back-calculation 1.11 km/h and 13.6 s. Back-calculation balances rather than freezes, and
with T<sub>t</sub> = N<sub>i</sub>·T<sub>i</sub> = 9 s it settles high and still has a
surplus to unwind. That is a library default left alone, not a verdict on the method — and it
is why the lecture demonstrates clamping, which has no parameter to leave wrong.)*

**In the model:** `LimPID` appears in this lecture only here, as the comparison. Open the
reference `CruiseClimb` next to the students' `MyCar.CruiseClimb`: same plant, same road, same
gains; the only difference is the controller block. Point at **`Ni`**, the back-calculation
parameter, and **`y_max` defaulting to `T_max`** — the controller's own ceiling, the subject
of the last slide in this section.

**Readout — every symbol on this slide**

- **İ** — the rate of change of the integrator state.
- **u_sat − u** — how much of the command did not get through. Zero whenever we are inside
  the limit, which is why the term vanishes in normal operation.
- **T<sub>t</sub>** — the *tracking time constant*, seconds. How fast the integrator is
  dragged back when saturated. Small is aggressive.
- **N<sub>i</sub>** — how `LimPID` exposes it: T<sub>t</sub> = N<sub>i</sub>·T<sub>i</sub>.
  Default 0.9.
-->

---

## Three controllers, one hill

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [06-windup.ipynb · cell Three-way comparison]
# Three schemes, two controllers: clamping with unreachable limits is no
# anti-windup at all; back-calculation is the library's LimPID.
CLIMB = (k = 56.0, Ti = 10.0, Td = 0.5, v_set = 130.0, gradient = 0.10,
         start_time = 30.0, duration = 120.0, stop = 400.0)

runs = ["none"             => Scenarios.ClampingCruiseClimbTransient(; y_max = 1.0e6, y_min = -1.0e6, CLIMB...),
        "back-calculation" => Scenarios.CruiseClimbTransient(; Ni = 0.9, CLIMB...),
        "clamping"         => Scenarios.ClampingCruiseClimbTransient(; CLIMB...)]

# peak over setpoint, not `overshoot`: no step to normalize against
[name => maximum(signal(s, SPEED)[2]) - 130 for (name, s) in runs]
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/06-windup.ipynb)

| Variant | Over setpoint | Recovery |
|---|---|---|
| none | +49.47 km/h | 66.7 s |
| clamping | +0.17 km/h | 3.5 s |
| back-calculation | +1.11 km/h | 13.6 s |

</div>
<div>

![Speed and integrator state for three controllers through the same climb: without anti-windup the integrator runs far above the limit and the speed overshoots, while clamping and back-calculation both hold the integrator near the limit and follow the setpoint back cleanly.](/figures/06-three-way-antiwindup.svg)

*Speed above, integrator state below. The difference between the runs is entirely in the lower plot.*

</div>
</div>

<!--
**Point at the lower plot first**, not the speed. The integrator traces are where the
mechanism is visible: one of them wanders far above the limit, the other two sit on it.

**Then point at the speed plot** and say: same car, same hill, same gains. The only
difference is whether the integrator was allowed to accumulate something it could not spend.

**Read out** the three overshoot figures.

**Say:** and note what anti-windup did *not* fix. All three traces sag to the same 119 km/h
on the climb. No controller can make a 150 N·m engine deliver 2023 N of tractive force.
Anti-windup does not add performance — it stops you being punished for asking.

**Ask the room:** which of the two methods would you ship? *(Either. Clamping is cheaper and
easier to explain to the next engineer; back-calculation is smoother, with a tuning parameter
of its own. The real answer is: whichever one your framework already implements correctly.)*

**Readout — every symbol on this slide**

- **"none"** — the clamping controller with limits it never reaches: no protection. **"back-calculation"** — `LimPID`'s
  built-in at `Ni = 0.9`. **"clamping"** — conditional integration, a different controller and
  so a different analysis.
- **Peak overshoot** — the single number that separates them.
- **What none of them fixes** — all three sag to about 119 km/h on the climb.
  Anti-windup does not add performance; it stops you being punished for asking.
-->

---

## Two limits, and only one of them is real

<div class="grid grid-cols-2 gap-8">
<div>

- `T_max` is what the **engine enforces**. A fact about the hardware, true whether or not any
  software knows it.
- `y_max` is what the **controller believes**. A constant in a program — and what the
  saturation detector compares against.

| Engine | Controller believes | Lowest on climb | Peak after |
|---|---|---|---|
| 150 | 140 — margin | 102.04 | 130.15 |
| 150 | 150 — exactly at it | 119.04 | 130.17 |
| 150 | 200 — optimism | 119.09 | 130.55 |
| 150 | 300 — twice | 119.09 | 131.58 |
| 150 | none at all | 119.10 | **179.48** |

</div>
<div>

> **The rule is ordering, not margin**
>
> **The clamp must not sit above what the actuator enforces.** Above it, the damage is the size
> of the gap. Below it buys almost nothing and is *not free*: clamping at 140 against an engine
> that has 150 costs **17 km/h** of climbing authority to buy back **0.02 km/h** of overshoot.
>
> How far below is a trade against authority — made with both numbers in front of you, not by
> reflex.

</div>
</div>

<!--
**Say:** the folklore here is "leave yourself a margin below the nameplate". We measured it,
and on this car it is a bad trade. Read the *peak after* column downwards: below the ceiling
and at it are both safe, and above it the damage grows with the gap.

**In your model, if the room wants to see it:** on `CruiseClimb`, set `controller.y_max = 140`
and re-run, then `300`. The lowest speed on the climb and the peak after it move the way the
first and fourth rows say.

**Point at the last row.** A controller with no output clamp at all reproduces the windup run
to within a fraction of a km/h — and that row is not hypothetical, it is what notebooks 03, 04
and 05 were running. Correct anti-windup logic that is never reached is the most expensive
kind of correct: it passes review, and it does nothing.

**Why the margin costs so much here:** the proportional term has already driven the command
hundreds of N·m past both numbers, so 10 N·m of gap is worth almost nothing in overshoot —
while 10 N·m of authority you refused to use is worth 17 km/h on a 10 % climb.

**Where the reflex does earn its keep:** systems where the gap can be large — a valve that
sticks, a rudder meeting current, an amplifier sagging under load — and where the loop gain
is low enough that the command lives inside the gap rather than far above it.

**Readout — every symbol on this slide**

- **y_max** — the controller's output clamp, which *you* choose. It decides when the
  integrator freezes.
- **T_max** — what the engine enforces. Hot, aged, at altitude, on poor fuel, the real
  ceiling sits below the nameplate.
- **The rule** — ordering, not margin: y_max must not sit *above* T_max. How far below is a
  trade against climbing authority, and on this car the prudent-sounding margin loses that
  trade 17 km/h to 0.02.
- **The band between them** — if y_max sits above what the engine delivers, there is a range
  where the engine is saturated, the error will not close, and the controller sees no
  saturation at all. That is windup, back again.
-->

---

## What this bought us

- The first genuinely nonlinear failure in the lecture — and it came from the actuator, not
  from the controller's mathematics.
- Clamping: two conditions, one switch.
- A rule for the limit itself: below the hardware's, by however much you distrust your model
  of it.

### Next: the derivative, and what a noisy sensor does to it. <Link to="derivative-and-noise">→ 07, derivative and noise</Link>

<!--
**Say:** the students now have the controller the rest of the lecture runs on: P, I, D, a
limit, and clamping. Section 07 puts a noisy sensor in front of it; after that only
parameters change, until section 10 swaps the car.
-->
