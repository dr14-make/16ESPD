---
routeAlias: proportional
layout: section
---

###### Notebook 03

# Proportional

Proportional control gets you close, and close is where it stops.

`notebooks/lecture01/03-proportional.ipynb`

<!--
From here to the end of section 05, the car never changes. Not one parameter. Everything that
happens is a change to the controller, and you make each change yourself.
-->

---

## The whole control law

$$
u \;=\; k\,e \;=\; k\,\bigl(v_{\text{set}} - v\bigr)
$$

<div class="grid grid-cols-2 gap-8">
<div>

Torque command proportional to how far off we are. That is all of it. No memory, no
prediction.

Units, once and for all: *e* is km/h, *u* is N·m, so **k is N·m per km/h**.

</div>
<div>

> **One idealization, stated out loud**
>
> Cruise at **90**, step the setpoint to **110 km/h**, flat road. *Holding* those speeds takes
> 31 and 40 N·m. But at the step the error is 20 km/h, and *k* times 20 is large — the gentlest
> gain here asks for 280 N·m, the fiercest for 17,800. **So this section's engine delivers
> whatever we ask** (`T_max` and `y_max` lifted). The limit returns in section 06.

**Open in Dyad** `dyad/Lecture1/CruiseLoop.dyad`

</div>
</div>

<!--
Think of walking to a line on a football pitch. Far away, you walk fast. Close, you slow down. On
the line, you stop. A proportional controller and a person crossing a room are the same algorithm.
For that problem it works perfectly: you stop exactly on the line.

Now think about a drone hovering at 50 meters. At the target the error is zero, so the controller
commands zero, so the propellers stop, so it falls. That system needs a non-zero output to stay
where you put it. And proportional control can only make a non-zero output out of a non-zero
error.

Which of those two is our car? The drone. Holding 110 kilometers per hour needs 40 newton-meters
forever, because drag never stops. The next three slides are the evidence for that answer.

In the model, this is one `CruiseController` with `with_I` false and `with_D` false, plus the wire
from `plant.v_kmh` back to `controller.u_m`. That wire is the whole difference between this
section and the feedforward of section 02. On the next slide, you put the one block this equation
needs into your own controller.

A word on the symbols. u equals k times e is the entire proportional control law. The output is
gain times error, and nothing else. k is the proportional gain, in newton-meters per kilometer per
hour. You will sometimes see it written K p. e is v set minus v, the error, in kilometers per
hour. Positive means we are going too slowly. And u is the commanded engine torque, in
newton-meters.

T max, 150 newton-meters, is the engine's physical ceiling. y max is the controller's own output
clamp, a separate number. In this section both are lifted. That matters, because at the instant of
the step the gentlest gain here asks for 280 newton-meters, and the fiercest for 17,800. Against
150 available.
-->

---
routeAlias: build-gain
---

## Build: one gain

<div class="grid grid-cols-2 gap-6">
<div>

![CruiseController in progress: error into gain into y.](/img/lecture-01/step03-gain.png)

</div>
<div>

![plant.v_kmh settling at about 109.3 km/h against demand.y at 110: the steady-state error.](/img/lecture-01/step03-p-plot.png)

</div>
</div>

*In `CruiseController`: parameter `k` = 56 · `gain` Gain(k = k) · `error.y` → `gain` → `y` ·
run `CruiseLoopTransient`*

```julia
using MyCar, Plots; plotly()
r = MyCar.CruiseLoopTransient()
plot(r; idxs = [r."plant.v_kmh", r."demand.y"])
```

[page: step 3](../lecture/lecture-01/#step-3) · reference `dyad/Lecture1/CruiseController.dyad`

<!--
u equals k times e. The error block already makes e. One block multiplies it by k, and the
controller is complete. It is the simplest one there is.

Open `CruiseController`. Add a parameter `k`, with default 56. Its units are newton-meters per
kilometer per hour.

Drag in `BlockComponents.Math.Gain` and name it `gain`. Set its parameter to k equals `k`. The
block refers to the controller's parameter by name.

Wire `error.y` into `gain.u`, and `gain.y` into `y`. Save. The problems panel is now empty,
because `y` has a source.

Now run `CruiseLoopTransient` from Analyses. That is the analysis we made in step 2. Plot
`plant.v_kmh` and `demand.y` on one axes. The code is on the slide.

You should see the speed climb from 90 within a few seconds and settle at about 109.3 kilometers
per hour, below the 110 of `demand.y`. That 0.7 kilometer per hour gap is the whole section. Keep
your eye on it. We explain it in a moment.

One difference from the notebook. Your engine still clips at 150 newton-meters, because `T_max`
only becomes a car parameter in section 06. The notebook figures that follow lift that ceiling. So
your rise is slower than the notebook's curve at the start. The settled value is the same, 109.3,
because holding 110 takes only 40 newton-meters, well under the ceiling.

If you want a second run, set `controller = CruiseController(k = 14)` in the loop's code and run
again. It settles about 2.8 kilometers per hour short. The next slide is that run, from the
notebook.

The common mistake here is typing 56 into the `gain` block instead of k equals `k`. It runs the
same today, and it breaks every sweep later, because the controller's `k` is no longer wired to
anything.
-->

---

## One gain, one step

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [03-proportional.ipynb · cell 2. One assumption, stated before it is used]
Scenarios = VehicleSystemsComponents.Lecture1
SPEED = "loop.plant.v_kmh"
UNLIMITED = 1.0e6            # N.m, the ceiling lifted away

single = Scenarios.CruiseLoopTransient(
    model = Scenarios.CruiseLoopStep(; name = :CruiseLoopStep,
                                     with_I = false, with_D = false),
    k = 14.0, T_max = UNLIMITED, y_max = UNLIMITED, stop = 30.0)

plt = plot_speed(single; sig = SPEED, setpoint = 110, label = "k = 14")
bracket_error!(plt, single; setpoint = 110, sig = SPEED)
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/03-proportional.ipynb)

- **2.8** km/h short
- **≈ 40** N·m to hold 110
- **280** N·m peak command

</div>
<div>

![Step response from 90 to 110 km/h under proportional control, settling just below the setpoint with the gap marked by a bracket.](/figures/03-single-gain.svg)

*The response settles, and it settles **below** the dashed setpoint. The bracket is the steady-state error.*

</div>
</div>

<!--
Look at the dashed line. Now the solid one. Now the gap between them. What do you see? The speed
stopped short of where we asked it to go.

Is this controller broken? No. It is doing exactly what it was told. It is stable, it is quick,
and it stopped somewhere sensible. And it is wrong, permanently, and it will never notice.

The bracket says 2.8 kilometers per hour short, at this gain of 14. That is the steady-state
error: the setpoint minus where the speed settled. A gain of 14 newton-meters per kilometer per
hour is deliberately gentle. What the loop ends up delivering is about 40 newton-meters, the
torque needed to hold 110. This run is 30 seconds long.

Now the third number on the slide, the one nobody expects. To make this modest-looking response,
the controller asked for 280 newton-meters at the instant of the step, when the error was still
the full 20 kilometers per hour. The engine can give 150. We lifted the limit to get this plot.

And compare it with the open loop. The open-loop car took several minutes to change speed. This
took seconds. Same engine, same mass, same drag. Feedback changed the dynamics of the system, not
just how it is operated.
-->

---

## Turn the gain up

<!-- The four gains and their outcomes are read from the executed notebook at the shipped
     theta_e = 0.3 s, where the ultimate gain is about 115 N.m per km/h. That is why the top
     two members of the family oscillate rather than settle, and why the slide says so. -->

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [03-proportional.ipynb · cell 3. Raising the gain]
GAINS = [14.0, 56.0, 220.0, 890.0]

family = sweep(
    Scenarios.CruiseLoopTransient(
        model = Scenarios.CruiseLoopStep(; name = :CruiseLoopStep,
                                         with_I = false, with_D = false),
        k = 14.0, T_max = UNLIMITED, y_max = UNLIMITED, stop = 60.0),
    "k", GAINS)

plot_sweep(family; sig = SPEED, setpoint = 110, name = "k")
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/03-proportional.ipynb)

| k [N·m per km/h] | what it does |
|---:|---|
| 14 | settles, 2.8 km/h short |
| 56 | settles, 0.7 km/h short |
| 220 | **never settles** — past K<sub>u</sub> |
| 890 | **never settles** — past K<sub>u</sub> |

*The ultimate gain is about **115** N·m per km/h. Two of these four are on the far side of it.*
</div>
<div>

![Four step responses at increasing proportional gain on one axes: each rises faster and settles closer to the setpoint, and none reaches it.](/figures/03-gain-family.svg)

*Left: four gains across two decades. Right: the last half minute, magnified — the two lowest gains have settled short, the two highest are still oscillating.*

</div>
</div>

<!--
Look at the curves in order: 14, 56, 220 and 890 newton-meters per kilometer per hour. These four
gains span about two decades. Each curve rises faster, and each one stops closer. Now look at the
dashed setpoint. None of them arrives.

Now the right-hand panel. It is the last 30 seconds, magnified onto a 5 kilometer per hour window.
Two of these curves are flat lines below the setpoint: 2.8 short at k equals 14, and 0.7 short at
56. The other two are still oscillating, and they will still be oscillating tomorrow.

So the pattern only holds while the loop is stable. Between 56 and 220 we crossed something: the
ultimate gain, K u, about 115 newton-meters per kilometer per hour. At that gain the loop
oscillates forever, neither growing nor decaying. Past it, steady-state error is not a small
number. It is a question with no answer.

So what gain do we need for zero error? Infinite. And we cannot even reach 220. There is a ceiling
on this approach, and we just hit it.

That ultimate gain is not a nuisance. It is a measurement, and in section 08 two of the three
tuning methods are built on it.

You might think: just turn it up more. But what else grows when the gain grows? The commanded
torque at the instant of the step, and the loop's appetite for sensor noise. We spend section 08
on exactly that bill.
-->

---

## Error against gain

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [03-proportional.ipynb · cell 4. Error against gain]
# solved from the force balance, not simulated: e = T(v_set - e)/k
function settled_error(k; v_set = 110.0)
    e = 0.0
    for _ in 1:20
        e = cruise_torque(v_set - e) / k
    end
    return e
end

K_ULTIMATE = 115.0     # N.m per km/h
plot(ks, settled_error.(ks); xscale = :log10, lw = 2.5)
vline!([K_ULTIMATE]; ls = :dash, color = :firebrick, label = "Ku = 115")
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/03-proportional.ipynb)

</div>
<div>

![Steady-state error against proportional gain on a logarithmic gain axis: a hyperbolic decay that approaches zero without reaching it.](/figures/03-error-vs-gain.svg)

*Hyperbolic decay, solved from the force balance so it is defined everywhere. It approaches zero and never arrives — and past K<sub>u</sub>, shaded, there is no steady state left to measure.*

</div>
</div>

<!--
Look at the curve hugging the axis on the right and never touching it. This is the shape of
asymptotically, never.

Now the shaded region. This curve is solved, not simulated. It is the fixed point of e equals T
cruise of v set minus e, all over k, and that has an answer at every gain. The shading marks the
gains above K u, 115, where that answer stops meaning anything, because the loop no longer
settles. The black dots are simulated runs that settled. The red crosses are the two gains from
the last slide that the curve predicts and the simulation refuses to deliver. The gain axis is
logarithmic, because the gain spans two and a half decades. Equal spacing means equal ratios, not
equal differences.

Now the argument. It is three sentences, and you should be able to reproduce it in the exam. One:
at 110 kilometers per hour the car needs about 40 newton-meters just to stand still against drag.
Two: a proportional controller's only source of output is k times the error. Three: therefore the
error cannot be zero, because if it were, the torque would be zero, and the car would slow down.

What would have to be true of a plant for proportional control to reach the setpoint exactly?
Holding the setpoint would have to need zero control effort. Walking across a room qualifies.
Almost nothing you will ever be paid to control does.
-->

---

## Why it cannot be zero

<div class="grid grid-cols-2 gap-8">
<div>

$$
u_{\text{needed}}(110) \;\approx\; 40\ \mathrm{N{\cdot}m} \qquad u = k\,e
$$

$$
\Rightarrow\quad e_{\infty} \;=\; \frac{u_{\text{needed}}}{k} \;\neq\; 0
$$

*Double the gain, halve the error. Never remove it.*

</div>
<div>

> **Same story, different plant**
>
> The drone hovers *below* 50 m because it needs 100 rpm to stay up, and only an error can
> produce 100 rpm. Our car cruises *below* 110 km/h because it needs 40 N·m to stay there.
>
> **Drag is playing the part gravity played.**

</div>
</div>

### The fix has to be something that *remembers*.

<!--
Write that division down. It is the most reusable thing in this section. Steady-state error under
proportional control is the effort you need, divided by the gain you chose. e infinity equals u
needed over k. Infinity here means as time goes to infinity, so once the loop has settled. And u
needed at 110 is about 40 newton-meters. It never goes away, because drag never goes away.

Notice what this tells you about the plant. The harder the job, the bigger the error. On a hill,
this same controller is worse. We will watch that happen in section 06.

So what could a controller add to its output that does not depend on the error right now?
Something accumulated. It should remember that it has been short for a while.
-->

---
routeAlias: checkpoint-p
---

## Checkpoint P

<div class="grid grid-cols-2 gap-8">
<div>

#### Your diagram now

- `CruiseLoopStep`: `demand` → `controller` → `plant` (`GradeCar`), `road` on `grade`, speed
  back to `u_m`.
- `CruiseController`: `u_s`, `u_m` → `error` → `gain` → `y`.
- One parameter, `k` = 56.

#### Your run shows

`plant.v_kmh` settled at **109.3 km/h**, 0.7 below the setpoint.

</div>
<div>

> **Behind? Rejoin here**
>
> The guide page's [step 3](../lecture/lecture-01/#step-3) has the controller and the loop as
> code to paste. The reference is `CruiseLoop` with `with_I = false, with_D = false` — the
> default of `CruiseLoopTransient` — and it settles at the same 109.3.

</div>
</div>

<!--
Checkpoint. Everyone should have this diagram and this number. Look at your neighbor's screen.
Same 109.3?

If you are still building, paste the step 3 code from the guide page, or open the reference
`CruiseLoopTransient`. P is its default, because `CruiseLoopStep` sets `with_I` false and `with_D`
false. From section 04 on, every step adds to this diagram, so nobody should go forward without
it.

If your number is not 109.3, check three things. First, the signs on `error`: k one is 1 and k two
is minus 1. Then the three initial lines. Then that `gain` reads k equals `k`.
-->

---

## What this bought us

- A loop that is fast, stable, and permanently wrong.
- A formula for how wrong: *e*<sub>∞</sub> = effort needed ÷ gain chosen.
- The knowledge that no gain fixes it — the fix has to be a different *kind* of term.

### Next: give the controller a memory. <Link to="proportional-integral">→ 04, proportional-integral</Link>

<!--
So that is proportional control: fast, stable, and permanently wrong. Your diagram has no integral
path yet, and that is why your 0.7 kilometer per hour gap is still there. Next, we give the
controller a memory.
-->
