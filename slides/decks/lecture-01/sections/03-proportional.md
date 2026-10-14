---
routeAlias: proportional
layout: section
---

###### Notebook 03

# Proportional

Proportional control gets close to the setpoint, but not all the way.

`notebooks/lecture01/03-proportional.ipynb`

<!--
From here to the end of section 05 the car does not change, not one parameter. Every change is to
the controller, and you make each one yourself.
-->

---

## The proportional control law

$$
u \;=\; k\,e \;=\; k\,\bigl(v_{\text{set}} - v\bigr)
$$

<div class="grid grid-cols-2 gap-8">
<div>

The torque command is proportional to the speed error. The controller has no memory of past
error and makes no prediction.

Units: *e* is km/h, *u* is N·m, so **k is N·m per km/h**.

</div>
<div>

> **Assumption: no torque limit**
>
> Cruise at **90**, step the setpoint to **110 km/h**, flat road. *Holding* those speeds takes
> 31 and 40 N·m. But at the step the error is 20 km/h, and *k* times 20 is large: the lowest
> gain here asks for 280 N·m, the highest for 17,800. **So this section's engine delivers
> whatever we ask** (`T_max` and `y_max` lifted). The limit returns in section 06.

**Open in Dyad** `dyad/Lecture1/CruiseLoop.dyad`

</div>
</div>

<!--
Walk to a line on a football pitch. Far away, you walk fast. Close, you slow down. On the line,
you stop. That is the proportional rule, and here it works perfectly.

Now a drone hovering at 50 meters. At the target the error is zero, so the command is zero, the
propellers stop, and it falls. It needs a non-zero output to stay put, and proportional control
only makes a non-zero output from a non-zero error.

Our car is the drone. Holding 110 kilometers per hour needs 40 newton-meters for as long as we
drive, because drag never stops.

In the model this is `CruiseController` with `with_I` and `with_D` false, plus the wire from
`plant.v_kmh` back to `controller.u_m`, the wire feedforward did not have. On the next slide you
add the one block this equation needs.

k is the proportional gain, also written K p. e is v set minus v; positive means we are too slow.

T max, 150 newton-meters, is the engine's ceiling. y max is the controller's own output clamp, a
separate number. In this section both are lifted, because at the step the lowest gain here asks
for 280 newton-meters and the highest for 17,800.
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
using Plots; plotly()
r = MyCar.CruiseLoopTransient()
plot(r; idxs = [r."plant.v_kmh", r."demand.y"])
```

[page: step 3](../lecture/lecture-01/#step-3) · reference `dyad/Lecture1/CruiseController.dyad`

<!--
The error block already makes e. One block multiplies it by k.

Open `CruiseController`. Add a parameter `k`, default 56. Drag in `BlockComponents.Math.Gain`,
name it `gain`, and set its parameter to k equals `k`, so it uses the controller's parameter by
name.

Wire `error.y` into `gain.u`, and `gain.y` into `y`. Save. The problems panel is now empty.

Run `CruiseLoopTransient` from Analyses, and plot `plant.v_kmh` and `demand.y` on one axes. The
code is on the slide.

The speed climbs from 90 within a few seconds and settles at about 109.3, below the 110 of
`demand.y`. The rest of this section explains that 0.7 kilometer per hour gap.

Your engine still clips at 150 newton-meters, because `T_max` only becomes a car parameter in
section 06, and the notebook lifts that ceiling. So your rise is slower at the start. The settled
109.3 is the same, because holding 110 takes only 40 newton-meters.

For a second run, set `controller = CruiseController(k = 14)` in the loop's code. It settles about
2.8 kilometers per hour short. That run is on the next slide.

The common mistake is typing 56 into `gain` instead of k equals `k`. It runs the same today, and
breaks every sweep later.
-->

---

## A single proportional run

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
The speed stopped short of the setpoint. The controller is not broken: it is stable, quick, and
settles close. But the error stays for as long as the loop runs.

That 2.8 kilometers per hour is the steady-state error, at a low gain of 14. The loop ends up
delivering about 40 newton-meters, the torque that holds 110.

At the instant of the step, with the full 20 kilometers per hour of error, the controller asked
for 280 newton-meters. The engine can give 150. We lifted the limit to get this plot.

The open-loop car took several minutes to change speed. This one took seconds, with the same
engine, mass and drag. Feedback changed the dynamics.
-->

---

## Raising the gain

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

*The ultimate gain, where the loop oscillates without decaying, is about **115** N·m per km/h.
Two of these four are above it.*
</div>
<div>

![Four step responses at increasing proportional gain on one axes: each rises faster and settles closer to the setpoint, and none reaches it.](/figures/03-gain-family.svg)

*Left: four gains from 14 to 890 N·m per km/h. Right: the last half minute, magnified. The two lowest gains have settled short, the two highest are still oscillating.*

</div>
</div>

<!--
Each higher gain rises faster and stops closer to the setpoint, but none reaches it.

The right-hand panel magnifies the last 30 seconds. At 14 and 56 the curves are flat lines below
the setpoint. At 220 and 890 they oscillate and never settle.

Between 56 and 220 we crossed the ultimate gain, K u, about 115. At K u the loop oscillates
forever, neither growing nor decaying. Above it there is no settled value, so no steady-state
error to measure.

Zero error would need an infinite gain, and the loop is already unstable at 220. Raising the gain
cannot remove the error.

Remember K u: two of the three tuning methods in section 08 are built on it.

A higher gain also raises the torque commanded at the step, and how much sensor noise reaches the
command. Section 08 deals with both.
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

*The error falls roughly as 1/k. It is solved from the force balance, so it is defined at every gain. It approaches zero but never reaches it. Above K<sub>u</sub>, shaded, the loop does not settle, so there is no steady state to measure.*

</div>
</div>

<!--
The curve approaches the axis but never touches it.

It is solved, not simulated, so it has an answer at every gain. The shading marks gains above K u,
115, where that answer means nothing because the loop no longer settles. Black dots are simulated
runs that settled. Red crosses are the two gains from the last slide that do not. The gain axis is
logarithmic: it spans a factor of 400.

The argument has three steps, and you should be able to reproduce it in the exam. One: at 110 the
car needs about 40 newton-meters just to hold speed. Two: a proportional controller's only output
is k times the error. Three: so the error cannot be zero, because then the torque would be zero
and the car would slow down.

What plant would let proportional control reach the setpoint exactly? One where holding the
setpoint needs zero effort, like walking across a room. Almost no plant you will control in
practice does.
-->

---

## Why the steady-state error cannot be zero

<div class="grid grid-cols-2 gap-8">
<div>

$$
u_{\text{needed}}(110) \;\approx\; 40\ \mathrm{N{\cdot}m} \qquad u = k\,e
$$

$$
\Rightarrow\quad e_{\infty} \;=\; \frac{u_{\text{needed}}}{k} \;\neq\; 0
$$

*Doubling the gain halves the error, but no finite gain removes it.*

</div>
<div>

> **The drone has the same problem**
>
> The drone hovers *below* 50 m because it needs 100 rpm to stay up, and only an error can
> produce 100 rpm. Our car cruises *below* 110 km/h because it needs 40 N·m to stay there.
>
> **For the car, drag plays the role that gravity plays for the drone.**

</div>
</div>

### The fix needs a term that *remembers* past error.

<!--
Write this down: under proportional control, the steady-state error is the effort you need divided
by the gain you chose. Here that effort is about 40 newton-meters, and it never goes away, because
drag never goes away.

The more torque the car needs, the bigger the error. On a hill this same controller does worse;
you see that in section 06.

So the controller needs a term that does not depend on the current error: one that accumulates it,
and remembers that the car has been too slow for a while.
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
> code to paste. The reference is `CruiseLoop` with `with_I = false, with_D = false`, the
> default of `CruiseLoopTransient`, and it settles at the same 109.3.

</div>
</div>

<!--
Checkpoint. Look at your neighbor's screen. Same 109.3?

If you are still building, paste the step 3 code from the guide page, or open the reference
`CruiseLoopTransient`; P is its default, because `CruiseLoopStep` sets `with_I` and `with_D`
false. Every step from section 04 on builds on this diagram.

If your number is not 109.3, check the signs on `error`, then the three initial lines, then that
`gain` reads k equals `k`.
-->

---

## Summary of section 03

- A loop that is fast and stable, with a permanent steady-state error.
- A formula for the error: *e*<sub>∞</sub> = effort needed ÷ gain chosen.
- No gain removes the error: the fix needs a different *kind* of term.

### Next: a term that accumulates the error. <Link to="proportional-integral">→ 04, proportional-integral</Link>

<!--
Proportional control is fast and stable, but it leaves a permanent error. Next, a term that
accumulates the error.
-->
