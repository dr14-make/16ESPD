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

**Timing:** 14 minutes, and it is worth borrowing from section 09 if you need to. This is the
most practically useful thing in the lecture.

**Cut order:** this is spine — do not cut it. The lecture is not complete without it.
-->

---

## The plant has two halves

- The **actuator** — the thing that supplies the force. Our engine.
- The **process** — the thing being pushed. Our car.

Real actuators have backlash, rate limits and **saturation**.
A linear model has none of these: ask it for a million newton-metres and it will agree.

**Open in Dyad** `dyad/Vehicle/IdealEngine.dyad`

> **The hill we are about to drive up**
>
> 130 km/h on a sustained 10 % climb needs **2024 N** at the road.
>
> The engine can deliver **1935 N**.
>
> The car will lose, and head for about **118 km/h** — a 120 s climb gets it to **119.05**,
> still falling.

*↩ Hands-on step 07: [the slope, and the 2023 N sum](../handson-01/index.html#/7/1)*

<!--
**Say:** the numbers in the red box are not chosen to make a point. They come out of the
force balance from hands-on step 05, with the parameters on the front slide. You can compute
them; that is the whole point of having built the car first.

**Say:** and notice how close it is — 2024 against 1935. Five per cent short. This is not a
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
- **2024 N** — the tractive force a 10 % climb at 130 km/h demands. **1935 N** — what the
  engine can deliver. Five per cent short.
- **118 km/h** — the asymptote this climb heads for. Say *heads for*, not *settles at*: the
  climb is 120 s long and the car is at 119.05 km/h and still falling when the road flattens.
- **y_min = 0** — the limiter's lower bound. This engine cannot produce negative torque, so
  it cannot brake.
-->

---

## The climb, with an ordinary PI controller

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [06-windup.ipynb · cell The climb, no anti-windup]
Scenarios = VehicleSystemsComponents.Lecture1

SPEED     = "loop.plant.v_kmh"
COMMAND   = "loop.controller.add_ff.y"      # before the limiter
DELIVERED = "loop.plant.engine.limiter.y"   # on the crankshaft
INTEGRAL  = "loop.controller.integrator.y"

# `Ni` is the back-calculation tracking factor; a large value makes the
# correction negligible, which is the no-anti-windup case.
no_aw = Scenarios.CruiseClimbTransient(
    k = 56.0, Ti = 10.0, Td = 0.5, Ni = 1.0e6,
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
while it is trying to fly to 50 metres. The propellers max out at 1000 rpm, the integrator
winds the command to 2000, and the moment you let go…

**In the model:** `gradient`, `start_time` and **`duration`**. The road flattens again because
the duration is finite, and the flattening is where the damage shows.

**Readout — every symbol on this slide**

- **grade = 0.10** — tan α, a 10 % climb, about 5.7°.
- **start_time = 30 s, duration = 120 s** — the hill starts at 30 s and the road flattens
  again at 150 s.
- **v_set = 130 km/h** — the cruise setpoint.
- **Commanded torque** — what the controller asks for; it keeps climbing. **Delivered
  torque** — what the engine gives; it is flat on the limit.
- **The integrator state** — plotted separately, because it is the thing actually going wrong
  and it is invisible in the speed trace.
- **antiwindup = :none** — no protection, deliberately, so the failure is visible.
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

- **overshoot(sol, 130; y0 = 130)** — peak excursion past the setpoint as a percentage of the
  step. `y0` is the pre-step speed, given explicitly here because the run starts at the
  setpoint.
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
| In `LimPID` | the variant built for task 4 | built in, via `Ni` |

*Both keep the integrator near the limit rather than far above
it, which is the only thing that matters.*

**Open in Dyad** `dyad/Lecture1/CruiseLoop.dyad`

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

**In the model:** **`Ni`**, the back-calculation parameter, and **`y_max` defaulting to
`T_max`** — the controller's own ceiling, which the next slide argues should sit lower.

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
# Three schemes, three calls: `Ni` switches back-calculation on and off,
# and clamping is a different controller, so a different analysis.
CLIMB = (k = 56.0, Ti = 10.0, Td = 0.5, v_set = 130.0, gradient = 0.10,
         start_time = 30.0, duration = 120.0, stop = 400.0)

runs = ["none"             => Scenarios.CruiseClimbTransient(; Ni = 1.0e6, CLIMB...),
        "back-calculation" => Scenarios.CruiseClimbTransient(; Ni = 0.9, CLIMB...),
        "clamping"         => Scenarios.ClampingCruiseClimbTransient(; CLIMB...)]

# peak over setpoint, not `overshoot`: no step to normalize against
[name => maximum(signal(s, SPEED)[2]) - 130 for (name, s) in runs]
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/06-windup.ipynb)

| Variant | Over setpoint | Recovery |
|---|---|---|
| none | +49.80 km/h | 68.3 s |
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
on the climb. No controller can make a 150 N·m engine deliver 2024 N of tractive force.
Anti-windup does not add performance — it stops you being punished for asking.

**Ask the room:** which of the two methods would you ship? *(Either. Clamping is cheaper and
easier to explain to the next engineer; back-calculation is smoother, with a tuning parameter
of its own. The real answer is: whichever one your framework already implements correctly.)*

**Readout — every symbol on this slide**

- **:none** — no protection. **:clamping** — conditional integration. **:backcalculation** —
  `LimPID`'s built-in, via N<sub>i</sub>.
- **Peak overshoot** — the single number that separates them.
- **What none of them fixes** — all three sag to the same 119.05 km/h on the climb.
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

### Next: the numbers that tell you where to start. <Link to="tuning">→ 08, tuning</Link> (or <Link to="derivative-and-noise">07, derivative and noise</Link> if there is time)

<!--
**This is the safe stopping point.** If you are running long, everything from here on can be
cut except section 08, which carries the practical task from the existing course slides. Go
straight there.
-->
