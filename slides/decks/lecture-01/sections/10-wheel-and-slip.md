---
routeAlias: wheel-and-slip
layout: section
---

###### Notebook 10

# Wheel and slip

The tire is an actuator too, and it saturates — which makes cruise control dangerous on ice.

`notebooks/lecture01/10-wheel-and-slip.ipynb`

<!--
Everything so far assumed the tire does whatever the driveline asks. You already removed that
assumption in the hands-on, in steps 09 and 10, and watched a wheel spin on snow with nobody
controlling it. This section puts a controller on that car.
-->

---

## First, just add the wheel

<div class="grid grid-cols-[1.4fr_1fr] gap-8">
<div>

```julia [10-wheel-and-slip.ipynb · cell 1. The wheel appears]
Scenarios = VehicleSystemsComponents.Lecture1

SPEED_L1  = "plant.v_kmh"    # the L1 harness is the loop
GAIN, T_I, T_D = 56.0, 10.0, 0.5
UNLIMITED = 1.0e6            # N.m, as in notebooks 03 to 05

# same gains as section 05, now with wheel inertia
# and an ideal rolling contact
l1 = Scenarios.WheeledCruiseTransient(
    k = GAIN, Ti = T_I, Td = T_D, wd = 0.0,
    T_max = UNLIMITED, y_max = UNLIMITED, stop = 60.0)

t1, y1 = signal(l1, SPEED_L1)
@show rise_time(t1, y1, 110) overshoot(t1, y1, 110)
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/10-wheel-and-slip.ipynb)

</div>
<div>

A rotating wheel is extra inertia the engine has to accelerate —
J/r² ≈ 10 kg on 1400. The plant is slightly heavier than it was, so the gains should
survive.

*↩ Hands-on step 06: [the wheel's hidden mass](../handson-01/index.html#/hidden-mass)*

> **If the response shifted**
>
> Say by how much. "The gains still work" is a claim, and a rise time is the evidence for it.

</div>
</div>

<!--
In hands-on step 06 you saw, open loop, that the wheel barely moves the launch. Now the
closed-loop question: do the gains of section 05 still hold? Look at the rise time and the
overshoot, and compare them with section 05.

This is a fidelity increase that changes nothing important, and that is worth seeing on its own.
Not every added detail matters. Knowing which ones do is the modeling skill.

This is the second rung of our model ladder, L1: wheel inertia plus an ideal rolling contact. L0
was everything up to section 09. L2 adds slip. Ideal rolling means wheel speed times radius is
road speed, by definition. There is no sliding, ever. The wheel inertia, J w, is rotational
inertia the engine must also accelerate, in kilogram meters squared.

Rise time is the time from 10 percent to 90 percent of the commanded step, in seconds.
Overshoot is the peak past the setpoint, in percent.

The model here is `WheeledCruiseStep`. It closes the reference `CruiseController` around
`HandsOn.WheeledCar`, the car from hands-on step 06, with `J_w` exposed. This one is a demo.
Your own swap comes with the slipping wheel.
-->

---

## Beat one: the wheel runs away

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [10-wheel-and-slip.ipynb · cell 2. Wheelspin]
# the hands-on bench, step 10: full throttle from rest
@named standing = VehicleSystemsComponents.HandsOn.SlipCarStandingStart()

MU_SNOW, MU_DRY = 0.2, 1.0   # packed snow, dry asphalt

# `saveat` is dense output, not decimation: the launch
# transient is over inside one adaptive step.
launch = sweep(standing, "friction.k", [MU_SNOW, MU_DRY];
               tspan = (0.0, 5.0), saveat = 0.01)
runs = Dict(launch.values .=> launch.sols)

# wheel_kmh is on the car's own scale: wheelspin is the gap
for path in ("car.v_kmh", "car.wheel_kmh",
             "car.wheel.kappa", "car.wheel.F_x")
    @show path signal(runs[MU_SNOW], path)[2][end]
end
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/10-wheel-and-slip.ipynb)

*↩ Hands-on step 10: [the same standing start, open loop](../handson-01/index.html#/wheelspin)*

Under closed loop the error stays large, so the integrator winds up —
against a limit **that is not in the engine at all**.

</div>
<div>

![Four panels from two standing starts, on snow and on dry asphalt: vehicle speed, wheel surface speed, slip ratio, and longitudinal tire force. On snow the wheel surface runs away to 1501 km/h while the car reaches only 10 km/h, and the force trace peaks then collapses to a plateau.](/figures/10-wheelspin.svg)

*Two standing starts, same command. On snow the wheel surface reaches 1501 km/h and the car 10 km/h; on dry asphalt, 21.2 and 21.1 km/h.*

</div>
</div>

<!--
This is the standing start from hands-on step 10. It is your bench, `SlipCarStandingStart`, on
the reference `SlipCar`. Same numbers: 1501 km/h of tread speed against 10 km/h of car. Those of
you who finished step 10 know what happened. The wheel ran away, and the car barely moved.

Look at the force panel, bottom right. It has the whole argument in one step. For the first four
tenths of a second, both surfaces carry every newton the engine asks for. Then the snow hits
1 371 newtons, everything it has, and falls off a cliff to 961 newtons, where it stays. **More
wheel speed bought less force.**

The engine delivered everything it was asked for. The driveline turned. The tread reached 1501
km/h. And the car got to 10 km/h.

A word on the code. `friction.k` is the road friction multiplier, swept over two values. 1.0 is
dry asphalt, and 0.2 is packed snow. The ice patch later in this section is 0.05.
`car.wheel_kmh` is the driven wheel's surface speed, omega times r, in km/h. That is the same
unit as the car's road speed, `car.v_kmh`, so wheelspin is the gap between the two.
`car.wheel.kappa` is the slip ratio, read inside the wheel, because `SlipCar` has no port for
it. And `car.wheel.F_x` is the longitudinal force the tire makes. The saveat of 0.01 is dense
output, not decimation. The launch transient is over inside one adaptive step, so the raw step
points would draw straight lines.

Now the new part, which the hands-on could not show. Connect it to section 06. The integrator
sees a large, persistent error and winds up, exactly as it did on the hill. But this time the
limit is not the engine's torque ceiling. The engine is nowhere near it. The limit is in the
contact patch, and no amount of torque gets past it.

Would the anti-windup from section 06 help here? No. It watches the engine's saturation, and the
engine is not saturating. This is a limit the controller has no way of seeing. That is the
uncomfortable point of this whole section.
-->

---

## Beat two: the curve

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

*↩ Hands-on step 08: [slip, and how grip depends on it](../handson-01/index.html#/slip-and-grip)*

$$
\kappa \;=\; \frac{\omega r - v}{\max(|v|,\ \varepsilon)}
     \qquad F_x \;=\; \mu(\kappa)\,F_z
$$

```julia [10-wheel-and-slip.ipynb · cell 3. The friction curve]
# the curve's equation lifted out of the component, not a
# formula retyped: change the model and this plot changes
curve_model = complete(
    VehicleSystemsComponents.HandsOn.TireFrictionCurve(name = :curve))
mu_law = only(eq for eq in equations(curve_model)
              if isequal(eq.lhs, curve_model.mu_abs))

mu_of = build_function(
    substitute(mu_law.rhs,
        Dict{Any, Any}(initial_conditions(curve_model))),
    curve_model.slip; expression = Val(false))

# the wheel scales the curve by the road: mu = mu_scale * curve.mu
kappas = range(0.0, 0.5; length = 2001)
dry_curve = MU_DRY .* mu_of.(kappas)
peak_kappa = kappas[argmax(dry_curve)]
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/10-wheel-and-slip.ipynb)

</div>
<div>

![Friction coefficient against slip ratio: a curve rising steeply to a marked peak and then falling away, with the wheelspin run's operating points marked on the falling side.](/figures/10-mu-slip-curve.svg)

*μ against slip ratio, with the peak marked — and the wheelspin run's operating points sitting past it.*

</div>
</div>

<!--
This is the curve from hands-on step 08. It rises to the adhesion peak at kappa equal to 0.04,
then falls toward sliding. On the rising part, more slip gives more force. The peak is an
actuator limit that moves with the weather. And then there is everything past the peak.

The new thing on this plot is the wheelspin run's operating points. They all sit on the falling
side. That is where the car spent beat one.

What happens to a wheel that ends up on the right-hand side of that peak? You met the answer in
hands-on step 10. Less force, so less resistance to the engine's torque, so more slip, so even
less force. The next slide is what that means for a controller.

Here are the symbols. Kappa is the slip ratio, and it is dimensionless. It is omega r minus v,
divided by the larger of the absolute value of v and epsilon. Zero means pure rolling. Positive
means the wheel is turning faster than the car is moving. Omega is the wheel's angular velocity,
in radians per second. r is the wheel radius, and v is the vehicle speed, in meters per second.
Epsilon, `v_eps` in the model, is a small floor on the denominator, so that slip is defined at
standstill.

Mu is the friction coefficient: the fraction of the normal load available as tractive force. F z
is the normal load on the wheel, in newtons. F x, which is mu times F z, is the longitudinal
force it can make. Inside the curve component, `sAdhesion` and `sSlide` are where the curve
peaks and where it has fully transitioned to sliding. And mu A and mu S are the adhesion and
sliding coefficients.
-->

---

## Why it runs away

### More slip → less force → more slip.

That is a positive feedback loop, and it is *inside the plant*.
Nobody wired it; it is what the tire does.

In that region the plant is **open-loop unstable**.

> **Remember the first question in section 08**
>
> *Is the system well behaved?* Stable, near enough linear, minimum phase, manageable delay.
>
> Here, past the peak, the answer is **no** — and no amount of PID tuning fixes a plant that is
> running away from you.

<!--
The loop is a recap. The box is the new part: it is what that loop means for the tuning you did
in section 08.

More slip gives less force, which gives more slip. That is positive feedback, an effect that
reinforces its own cause. Here it is inside the plant, and nobody wired it. Open-loop unstable
means the plant runs away on its own, with no controller involved.

And notice this is the same car. The plant did not get replaced. It moved into a region where it
has a different character. That is what nonlinear means in practice. Not a curved graph, but
different rules in different places.

That is why the tuning flowchart puts this question first and not third. If you tune a loop on
the good side of the peak, and it occasionally visits the bad side, your gains are answering a
question the plant has stopped asking.

What would you have to control to stay on the left of the peak? Slip itself. That needs a sensor
for slip and a loop around it. Hold that thought. It is the last slide.
-->

---

## Reminder: the car whose wheel can slip

<div class="grid grid-cols-[1.4fr_1fr] gap-8">
<div>

![SlipWheel1D from hands-on step 09: the friction curve block sits between the shaft and the body contact, connected by equations rather than wires.](/img/handson-01/step09-slip-wheel.png)

</div>
<div>

`SlipCar` is your `GradeCar` with the rolling constraint cut:

- `Driveline` split open: gear → wheel inertia → `SlipWheel1D` → body
- κ = (ω·r − v) / max(|v|, v<sub>eps</sub>), μ = `mu_scale` · μ(κ),
  F<sub>x</sub> = μ · F<sub>z</sub>, F<sub>z</sub> = m·g/2
- one more input, **`mu_scale`**: 1 dry, 0.2 snow, 0.05 ice
- one more output, **`wheel_kmh`**: ω·r in km/h, beside `v_kmh`
- slip ratio inside it: `wheel.kappa`

*↩ Hands-on steps 09–10: [a wheel that can slip](../handson-01/index.html#/slip-wheel)*

</div>
</div>

<!--
One slide of recap before it goes into the loop. This is the car from hands-on steps 09 and 10,
the one whose wheel spun up to 1501 km/h in beat one.

Look at the screenshot. `curve` has no wires. It is connected by equations: `curve.kappa` equals
`kappa`, and `mu` equals `mu_scale` times `curve.mu`.

Now look at the list. The two new ports are the whole interface change. `tau_cmd`, `grade` and
`v_kmh` are exactly where `GradeCar` had them. That is why the next step is a swap, and not a
rebuild.

If you finished step 10: what number does `wheel_kmh` show on the dry road? 21.2 km/h, against
21.1 for the car. Wheel and car move together.

If your own `SlipCar` lacks `T_max`, `theta_e` or `CdA`, that is fine. The reference
`HandsOn.SlipCar` has them, with the same defaults, and step 10 does not set them.
-->

---
routeAlias: step-10
---

## Step 10: swap the car

<div class="grid grid-cols-2 gap-8">
<div>

![The loop with plant as SlipCar and a friction profile driving its mu_scale input.](/img/lecture-01/step10-slip-loop.png)

</div>
<div>

![Vehicle speed against wheel surface speed across the ice patch: the wheel speed shoots far above the car's, and the gap between them is the wheelspin.](/img/lecture-01/step10-ice-patch-plot.png)

</div>
</div>

*Duplicate `CruiseLoopStep` → `SlipCruiseIcePatch` · `plant`: `GradeCar` → `SlipCar` · `demand` →
`Constant(k = 90)` · `friction` Pulse(amplitude = 0.05, offset = 1.0, start_time = 4,
duty_cycle = 1.0, period = 8) → `plant.mu_scale` · `controller.xi0 = 31.078 / 56` · `initial`
`plant.body.mass.s = 0`, `plant.body.mass.v = 25`, `plant.engine.lag.x = 31.078`,
`plant.wheel_inertia.phi = 0`, `plant.wheel_inertia.w = 25 / plant.r` · TransientAnalysis
`SlipCruiseTransient`, `stop = 45`*

```julia
using MyCar, Plots; plotly()
r = MyCar.SlipCruiseTransient()
s = [r."plant.v_kmh", r."plant.wheel_kmh"]
top = plot(r; idxs = s)
bottom = plot(r; idxs = s, ylims = (85, 115))
plot(top, bottom; layout = (2, 1), link = :x)
```

[page: step 10](../lecture/lecture-01/#step-10) · reference `SlipCruiseLoop` in `dyad/Lecture1/SlipCruiseLoop.dyad`

<!--
The same controller, the same gains, the same loop. Only the car changes, to the one whose tire
can let go.

We build a new harness in `MyCar`, duplicated from `CruiseLoopStep` as it stands after step 6.
That means k is 56, T i is 10, T d is 0.5, N d is 10, `wd` is 0, and `xd0` is minus 90. It also
has the step 6b limits: `controller.y_max` is 150 and `y_min` is 0. Sections 07 and 08 worked
on duplicates, so nothing needs resetting.

Step one. Duplicate `CruiseLoopStep`, and name the copy `SlipCruiseIcePatch`. That is the
reference bench's name. `CruiseLoopStep` itself stays on `GradeCar`. In the copy, select `plant`.
Change its type from `MyCar.GradeCar` to `MyCar.SlipCar`. You can also delete it and drag
`SlipCar` in, named `plant`. Clear any parameter overrides that `SlipCar` does not have.

Step two. Re-wire anything the swap dropped. `controller.y` goes into `plant.tau_cmd`. `road.y`
goes into `plant.grade`. And `plant.v_kmh` goes into `controller.u_m`.

Step three. From BlockComponents, Sources, drag in a Pulse and name it `friction`. Set amplitude
to 0.05, offset to 1.0, start_time to 4, duty_cycle to 1.0, and period to 8. Wire `friction.y`
into `plant.mu_scale`. The pulse outputs its amplitude on the patch and its offset outside it,
so the grip drops from 1.0 to 0.05 for 8 seconds. `MyCar` cannot see the course library. This
pulse is what the reference uses, wrapped in its `FrictionProfile` with low equal to 0.05.

Step four. Replace `demand` with a `BlockComponents.Sources.Constant`, with k equal to 90, and
name it `demand`. Wire `demand.y` into `controller.u_s`. `road` stays the constant 0.

Step five. The integrator must start at the holding torque, or the car slows down before it
reaches the ice. `CruiseController` has had `xi0` on `integrator.x0` since step 4. In the loop,
set `controller.xi0` to 31.078 divided by 56. That is 31.078 newton meters divided back through
the gain, the same as the reference's `xi0` equals tau0 over k. `wd` equal to 0 and `xd0` equal
to minus 90 stay at their defaults.

Step six. The initial conditions, in the code view. There are two more than before, because the
wheel now has its own speed. Initial `plant.body.mass.s` is 0. Initial `plant.body.mass.v` is
25. Initial `plant.engine.lag.x` is 31.078. Initial `plant.wheel_inertia.phi` is 0. And initial
`plant.wheel_inertia.w` is 25 divided by 0.31. That is the wheel rolling, at 90 km/h.

Step seven. Run Analysis, choose TransientAnalysis, name it `SlipCruiseTransient`, and set stop
to 45. Run it.

Now plot `plant.v_kmh` and `plant.wheel_kmh` with the code on the slide. On top, the two speeds.
Below, the same two, zoomed in on the car's speed.

Here is what you should see. Before t equals 4 seconds, the two speeds lie on top of each other
at 90. On the ice, the wheel speed tears away upward. The reference run reaches about 3400 km/h
of tread speed, while `plant.v_kmh` sags only 3.10 km/h. The slip ratio goes to 38. After t
equals 12 seconds, the car surges to 111.86 km/h. If your wheel speed stays on the car's speed,
then `friction.y` is not reaching `plant.mu_scale`.

The usual mistake is forgetting the wheel's initial speed. Without initial
`plant.wheel_inertia.w`, the wheel starts at rest under a car doing 90 km/h. That is a violent
slip at t equals 0, and it has nothing to do with the ice.

If you fell behind, use the reference. `SlipCruiseLoop` is the reference loop on
`HandsOn.SlipCar` with the reference controller. `SlipCruiseIcePatch` is its bench, and
`SlipCruiseTransient` runs it. Its defaults are not this run. To reproduce this step, set `Td`
to 0.5, `wd` to 0, `patch_start` to 4, `patch_duration` to 8, and `stop` to 45.
-->

---

## Beat three: cruise control on ice

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [10-wheel-and-slip.ipynb · cell 4. Cruise control on ice]
CRUISE, MU_ICE = 90.0, 0.05           # km/h; the ice
PATCH_START, PATCH_LENGTH = 4.0, 8.0  # s

ice_patch(; kwargs...) = Scenarios.SlipCruiseTransient(;
    k = GAIN, Ti = T_I, Td = T_D, v_set = CRUISE,
    mu_low = MU_ICE, patch_start = PATCH_START, kwargs...)

# cruising at 90 km/h; friction collapses for eight seconds
blind = ice_patch(patch_duration = PATCH_LENGTH, stop = 45.0)

SPEED   = "loop.plant.v_kmh"        # what it measures
WHEEL   = "loop.plant.wheel_kmh"    # what it does not
SLIP    = "loop.plant.wheel.kappa"  # nor this
COMMAND = "loop.controller.y"
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/10-wheel-and-slip.ipynb)

**The controller reads falling speed, commands more torque,
spins the driven wheel — and destroys the traction it was trying to use.**

</div>
<div>

![Four panels across a shaded eight-second low-friction patch: vehicle speed sagging by three km/h and then surging past the setpoint, wheel surface speed climbing to about 3400 km/h, slip ratio past the adhesion peak to 38, and commanded torque rising to the engine's limit.](/figures/10-ice-patch.svg)

*Speed, wheel speed, slip ratio and commanded torque, with the eight seconds of ice shaded. Only the first panel has a sensor on it.*

</div>
</div>

<!--
Let us read the four traces in time order, as a sequence of entirely reasonable decisions.

Friction collapses. The car starts to lose speed. The controller sees speed below the setpoint,
which is true, and commands more torque. That is exactly what it is for. The extra torque cannot
go into the road, so it goes into spinning the wheel. Slip passes the peak. The available force
**falls**. The car slows further. The controller sees a bigger error, and commands more torque
still.

Nothing in that chain is a bug. Every step is the controller doing its job correctly. The system
as a whole does the wrong thing, and it does it faster the better the controller is tuned.

Now the numbers. The cruise speed, `v_set`, is 90 km/h. The friction multiplier on the patch,
`mu_low`, is 0.05. At its peak, the road then carries 343 newtons, against the 401 newtons it
takes to hold 90 km/h. The patch starts at 4 seconds and lasts 8 seconds. Two seconds could not
produce a visible speed drop. At 90 km/h, a total loss of traction for two seconds costs about 2
km/h. The run stops at 45 seconds, which is long enough to capture the recovery.

The speed sags **3.10 km/h** across the eight seconds. That is less than a gentle hill would
cost, and that is the trap. Meanwhile the tread goes to about **3400 km/h**, and the slip ratio
to **38**. The tire crossed its adhesion peak **0.08 s** into the patch, and never came back.
When the ice ends, the car surges to **111.86 km/h**, nearly 22 km/h over the setpoint. It takes
**20.7 s** to come back inside half a km/h of 90.

Where does the surge come from? The wheel is a flywheel holding **4.64 MJ** at its peak, against
**0.44 MJ** for the whole car at 90 km/h. When grip returns, that energy has somewhere to go.

In a real car, the driver feels this as the back stepping out on a motorway at 90 km/h. And it
is caused by a system they switched on for comfort.
-->

---

## What should have happened

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [10-wheel-and-slip.ipynb · cell 5. What a friction-aware limit would have done]
# half the car's weight on the driven axle, which is the
# `F_z` the wheel model ships
F_Z = CAR.m * CAR.g / 2

# the engine torque that reaches the most force the ice
# can carry: 26.6 N.m, against the 31.1 that holds 90 km/h
ICE_CEILING = maximum(dry_curve) * MU_ICE * F_Z * CAR.r / CAR.i

# the same compiled run, with the ceiling brought down to it
capped = rerun(blind, "y_max" => ICE_CEILING; saveat = 0.05)
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/10-wheel-and-slip.ipynb)

The car still loses speed on the ice — physics is physics. It loses
**less** of it: 2.01 km/h against 3.10, while being asked for a fifth as
much torque. And it does not lose the wheel — about 219 km/h of tread against 3400.

</div>
<div>

![The same ice patch run overlaid with a friction-aware torque limit: the wheel stays near vehicle speed and the slip ratio stays on the near side of the peak, while speed dips and recovers.](/figures/10-ice-patch-limited.svg)

*Against the blind run. The capped car commands a fifth of the torque and loses **less** speed doing it — 2.01 km/h against 3.10.*

</div>
</div>

<!--
Be precise about what the fix bought. The car still slows down. It has to. There is less
friction available, and no controller can conjure grip. What the limit prevented was the
controller **making it worse**. Averaged over the eight seconds, the capped tire put **more**
force on the road, 276 newtons against 242, while being asked for a fifth as much torque. More
command, less force. That is the whole of traction control in one line.

But let us not oversell it. The cap did not hold the tire at its peak. The capped run still ends
the patch at a slip ratio of 1.5, nowhere near 0.04. A constant ceiling cannot track a peak. It
can only stop the command running away from the surface, and that turns out to be most of the
benefit.

There is an honest caveat. `y_max` is a constant, so the cap is on for the whole run, including
the dry road on either side. 26.6 newton meters is less than the 31.1 that holds 90 km/h. So the
capped car reaches the ice at 89.47 km/h, and drifts down afterwards. Look at the green trace,
the capped run, after t equals 12 seconds. A fixed cap is the right idea with the wrong
information. And that is exactly why lecture 2 needs a loop around slip.

That is a general shape worth naming. When an actuator's limit depends on conditions the
controller cannot see, somebody has to tell it. That is not tuning. That is architecture.
-->

---

## Two lessons

### One

Real cruise control disengages when traction control intervenes. Now
you know exactly why — the two loops are fighting over the same actuator, and the speed
loop is the one with the worse information.

### Two

The fix is an **inner loop regulating slip** inside an
**outer loop regulating speed**. The inner one is fast and local; the outer
one is slow and comfortable.

That is **cascade control**.

### Which is where lecture 2 begins.

<!--
Notice that we did not need a new controller type to see the need for one. The need came out of
the plant, by removing one assumption about a tire.

The inner loop is fast and local. It rejects disturbances before the outer loop notices. The
outer loop is slow and comfortable, and it sets the inner loop's setpoint.

That is a good note to end on generally. Almost every advanced control architecture you will
meet exists because somebody found a plant that defeated the simple one. Not because it was
elegant.
-->

---

## Three hours, one car

- **01** know the plant before you control it.
- **02** feedback exists because the world moves.
- **03** P is fast and permanently wrong.
- **04** the integrator inverts the plant for you.
- **05** present, past, future — three jobs.
- **06** actuators saturate; integrators do not notice.
- **07** derivatives amplify by frequency.
- **08** one step test, three tables — and plot the command.
- **09** sampling costs phase.
- **10** the tire is an actuator, and it has a peak.

### Every notebook is in the repository, executed, with its plots. Re-run them.

<!--
If you take one habit away from today, take the one that showed up three times without being
planned: **plot the actuator command**. Section 06 found windup with it. Section 07 found
chatter with it. Section 08 found an undeliverable design with it. In all three, the controlled
variable looked fine.

The notebooks are in the repository, and so is the `docs` folder. Everything on these slides is
reproducible, and the plots are committed, so you can read them without installing anything.

Next lecture: the engine torque map, which fixes the 246 km/h lie from hands-on step 05. And
cascade control, which fixes the ice patch.
-->
