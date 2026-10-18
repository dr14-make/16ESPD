---
routeAlias: wheel-and-slip
layout: section
---

###### Notebook 10

# Wheel and slip

The tire is an actuator too, and it saturates. That makes cruise control dangerous on ice.

`notebooks/lecture01/10-wheel-and-slip.ipynb`

<!--
Everything so far assumed the tire does whatever the driveline asks. In hands-on steps 09 and 10
you removed that assumption, and watched a wheel spin on snow with nobody controlling it. Now we
put a controller on that car.
-->

---

## Adding the wheel's inertia

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

A rotating wheel is extra inertia the engine has to accelerate:
J/r² ≈ 10 kg on 1400. The plant is slightly heavier than it was, so the gains should
still work.

![Speed over the first 20 s of the 90 to 110 km/h step, with and without the wheel's inertia: the dashed wheeled curve lies almost on top of the solid one.](/figures/10-wheel-inertia.svg)

*↩ Hands-on step 06: [the wheel's hidden mass](../handson/lecture-01/index.html#hidden-mass)*

> **Check the rise time**
>
> If the response shifted, say by how much. The rise time shows whether the gains still work.

</div>
</div>

<!--
In hands-on step 06 you saw, with no controller, that the wheel barely changes the launch. Now the
question with the controller in the loop: do the gains of section 05 still hold?

Rise time is the time from 10 to 90 percent of the step. Overshoot is how far the peak goes past
the setpoint, in percent of the step. Without the wheel, the rise time is 1.27 seconds and the
overshoot 2.73 percent. With the wheel, 1.31 seconds and 2.78 percent. The wheel costs about 3
percent of rise time, and the overshoot barely changes. Not every added detail matters, and knowing
which ones do is part of modeling.

We number the model levels. L0 was everything up to section 09. This is L1: wheel inertia plus an
ideal rolling contact. L2 adds slip. Ideal rolling means wheel speed times radius is road speed, by
definition: no sliding, ever. Inertia is resistance to being spun up. The wheel inertia, J w, is 1
kilogram meter squared. Divided by the radius squared, it acts like about 10 extra kilograms on a
1400 kilogram car.

The model is `WheeledCruiseStep`: the reference `CruiseController` around `HandsOn.WheeledCar`, the
car from hands-on step 06, with `J_w` exposed. This one is a demo. Your own swap comes with the
slipping wheel.
-->

---

## Wheelspin at a standing start

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

*↩ Hands-on step 10: [the same standing start, open loop](../handson/lecture-01/index.html#wheelspin)*

Under closed loop the error stays large, so the integrator winds up
against a limit **that is not in the engine**.

</div>
<div>

![Four panels from two standing starts, on snow and on dry asphalt: vehicle speed, wheel surface speed, slip ratio, and longitudinal tire force. On snow the wheel surface runs away to 1501 km/h while the car reaches only 10 km/h, and the force trace peaks then collapses to a plateau.](/figures/10-wheelspin.svg)

*Two standing starts, same command. On snow the wheel surface reaches 1501 km/h and the car 10 km/h; on dry asphalt, 21.2 and 21.1 km/h.*

</div>
</div>

<!--
This is the standing start from hands-on step 10: your bench, `SlipCarStandingStart`, on the
reference `SlipCar`. Same numbers: 1501 km/h of tread speed against 10 km/h of car. The wheel ran
away, and the car barely moved.

Look at the force panel, bottom right. For the first four tenths of a second, both surfaces carry
every newton the engine asks for. Then the snow reaches 1 371 newtons, its maximum, and drops
sharply to 961, where it stays. **More wheel speed gave less force.** The engine delivered
everything it was asked for, and the car got to 10 km/h.

On the code: `friction.k` is the road friction multiplier, 1.0 for dry asphalt and 0.2 for packed
snow. The ice patch later is 0.05. `car.wheel_kmh` is the driven wheel's surface speed, omega times
r, in km/h, so wheelspin is its gap to `car.v_kmh`. `car.wheel.kappa` is the slip ratio: how much
faster the tread moves than the car, as a fraction of the car's speed. After five seconds it is 147
on snow and 0.0076 on dry asphalt. It is read inside the wheel, because `SlipCar` has no connection
point for it. `car.wheel.F_x` is the tire's force along the road. The saveat of 0.01 asks for a
value every hundredth of a second. The solver picks its own time steps, and the whole launch fits
inside one of them, so without it the plot would draw straight lines.

What the hands-on could not show connects to section 06. The integrator sees a large, persistent
error and winds up, as it did on the hill. But this time the engine is nowhere near its torque
ceiling. The limit is in the contact patch, and no amount of torque gets past it.

Would the anti-windup from section 06 help? No. It watches the engine's saturation, and the engine
is not saturating. The controller has no way of seeing this limit. That is the main point of this
section.
-->

---

## The friction curve

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

*↩ Hands-on step 08: [slip, and how grip depends on it](../handson/lecture-01/index.html#slip-and-grip)*

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

*μ against slip ratio, with the peak marked, and the wheelspin run's operating points past it.*

</div>
</div>

<!--
This is the curve from hands-on step 08. Adhesion means grip. The curve rises to the adhesion peak,
mu equal to 1.0 at kappa equal to 0.04, then falls to a sliding plateau of 0.7 from kappa 0.12 on.
Crossing the peak throws away 30 percent of the grip. The peak is an actuator limit that moves with
the weather.

New on this plot: the wheelspin run's operating points. They all sit on the falling side. The snow
run went out along the plateau to a slip ratio of 147.

On that side, less force means less resistance to the engine's torque, so more slip, so even less
force. The next slide is what that means for a controller.

The symbols. Kappa, the slip ratio, is omega r minus v, divided by the larger of the absolute value
of v and epsilon. It is dimensionless. Zero means pure rolling. Positive means the wheel turns
faster than the car moves. Omega is the wheel's angular velocity, r the wheel radius, v the vehicle
speed. Epsilon, `v_eps` in the model, is a small floor so that slip is defined at standstill.

Mu is the friction coefficient: the fraction of the normal load F z available as force. The normal
load is the weight pressing the tire onto the road. F x, mu times F z, is the force along the road.
In the curve component, `sAdhesion` and `sSlide` are where the curve peaks and where it has fully
reached sliding. Mu A and mu S are the adhesion and sliding coefficients.
-->

---

## Why the wheel runs away

<div class="grid grid-cols-[1fr_1fr] gap-8">
<div>

### More slip → less force → more slip.

That is a positive feedback loop, and it is *inside the plant*.
Nobody wired it; it is what the tire does.

In that region the plant is **open-loop unstable**.

> **Remember the first question in section 08**
>
> *Is the system well behaved?* Stable, near enough linear, minimum phase, manageable delay.
>
> Here, past the peak, the answer is **no**, and no amount of PID tuning fixes a plant that is
> unstable on its own.

</div>
<div>

![The dry-road friction curve: grip rises with slip to a peak, then falls toward a sliding plateau. The region past the peak, where more slip gives less force, is shaded.](/figures/10-past-the-peak.svg)

</div>
</div>

<!--
The loop is a recap. The box is new: it ties this loop to the tuning in section 08.

More slip gives less force, which gives more slip. That is positive feedback, inside the plant, and
nobody wired it. Open-loop unstable means the plant runs away on its own, with no controller
involved.

It is the same car. It moved into an operating region where it behaves differently. That is what
nonlinear means in practice.

That is why the tuning flowchart asks this question first. If you tune a loop on the good side of
the peak, and it sometimes visits the bad side, your gains were tuned for a different plant.

To stay left of the peak, you have to control slip itself. That needs a slip sensor and a loop
around it. That is the last slide.
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

*↩ Hands-on steps 09–10: [a wheel that can slip](../handson/lecture-01/index.html#slip-wheel)*

</div>
</div>

<!--
A recap before this car goes into the loop: the car from hands-on steps 09 and 10, whose wheel spun
up to 1501 km/h.

`curve` has no wires. It is connected by equations: `curve.kappa` equals `kappa`, and `mu` equals
`mu_scale` times `curve.mu`. F z, the load on the driven wheels, is half the car's weight: about
6 900 newtons.

A port is a connection point on a block. The two new ports are the only interface change.
`tau_cmd`, `grade` and `v_kmh` are where `GradeCar` had them. So the next step is a swap, not a
rebuild.

If you finished step 10: what does `wheel_kmh` show on the dry road? 21.2 km/h, against 21.1 for
the car. Wheel and car move together.

If your `SlipCar` lacks `T_max`, `theta_e` or `CdA`, that is fine. The reference `HandsOn.SlipCar`
has them with the same defaults, and step 10 does not set them.
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
using Plots; plotly()
r = MyCar.SlipCruiseTransient()
s = [r."plant.v_kmh", r."plant.wheel_kmh"]
top = plot(r; idxs = s)
bottom = plot(r; idxs = s, ylims = (85, 115))
plot(top, bottom; layout = (2, 1), link = :x)
```

[page: step 10](../lecture/lecture-01/#step-10) · reference `SlipCruiseLoop` in `dyad/Lecture1/SlipCruiseLoop.dyad`

<!--
Same controller, same gains, same loop. Only the car changes, to the one whose tire can let go.

The new harness in `MyCar` is a duplicate of `CruiseLoopStep` as it stands after step 6: k 56, T i
10, T d 0.5, N d 10, `wd` 0, `xd0` minus 90, and the step 6b limits, `controller.y_max` 150 and
`y_min` 0. Sections 07 and 08 worked on duplicates, so nothing needs resetting.

Step one. Duplicate `CruiseLoopStep` and name the copy `SlipCruiseIcePatch`, the reference bench's
name. `CruiseLoopStep` stays on `GradeCar`. In the copy, select `plant` and change its type from
`MyCar.GradeCar` to `MyCar.SlipCar`, or delete it and drag in a `SlipCar` named `plant`. Clear any
parameter overrides `SlipCar` does not have.

Step two. Re-wire anything the swap dropped: `controller.y` into `plant.tau_cmd`, `road.y` into
`plant.grade`, `plant.v_kmh` into `controller.u_m`.

Step three. From BlockComponents, Sources, drag in a Pulse named `friction`. Amplitude 0.05, offset
1.0, start_time 4, duty_cycle 1.0, period 8. Wire `friction.y` into `plant.mu_scale`. The grip
drops from 1.0 to 0.05 for 8 seconds. This is the same pulse the reference wraps in its
`FrictionProfile`, which `MyCar` cannot see.

Step four. Replace `demand` with a `BlockComponents.Sources.Constant`, k equal to 90, named
`demand`. Wire `demand.y` into `controller.u_s`. `road` stays the constant 0.

Step five. The integrator must start at the holding torque, 31.078 newton-meters, or the car slows
before it reaches the ice. The controller multiplies its integrator by the gain, so set
`controller.xi0` to 31.078 divided by 56, about 0.555, as in the reference.

Step six. The initial conditions, in the code view. Two are new, because the wheel now has its own
speed. Initial `plant.body.mass.s` is 0. `plant.body.mass.v` is 25, meters per second, which is 90
km/h. `plant.engine.lag.x` is 31.078. `plant.wheel_inertia.phi` is 0. And `plant.wheel_inertia.w` is
25 divided by `plant.r`, the 0.31 meter radius: about 80.6 radians per second, the wheel rolling at
90 km/h.

Step seven. Create a TransientAnalysis named `SlipCruiseTransient`, stop 45. Run it, and plot
`plant.v_kmh` and `plant.wheel_kmh` with the code on the slide. The top plot shows both speeds in
full. The bottom plot shows the same two zoomed in to 85 to 115 km/h, so you can see the car's own
speed.

Before 4 seconds the two speeds lie on top of each other at 90. On the ice the wheel speed shoots
up: the reference run reaches about 3400 km/h of tread speed, while `plant.v_kmh` sags only 3.10
km/h, to 86.9. The slip ratio goes to 38: the tread moves about 39 times as fast as the car. After
12 seconds the car surges to 111.86 km/h. If your wheel speed stays on the car's speed, `friction.y`
is not reaching `plant.mu_scale`.

The usual mistake is forgetting the wheel's initial speed. Then the wheel starts at rest under a
car doing 90 km/h: a violent slip at t equals 0 that has nothing to do with the ice.

If you fell behind: the reference loop is `SlipCruiseLoop`, its bench `SlipCruiseIcePatch`, run by
`SlipCruiseTransient`. Its defaults are not this run. Set `Td` to 0.5, `wd` to 0, `patch_start` to
4, `patch_duration` to 8 and `stop` to 45.
-->

---

## Cruise control on ice

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

**The controller reads falling speed and commands more torque.
The torque spins the driven wheel and removes the traction the car needs.**

</div>
<div>

![Four panels across a shaded eight-second low-friction patch: vehicle speed sagging by three km/h and then surging past the setpoint, wheel surface speed climbing to about 3400 km/h, slip ratio past the adhesion peak to 38, and commanded torque rising to the engine's limit.](/figures/10-ice-patch.svg)

*Speed, wheel speed, slip ratio and commanded torque, with the eight seconds of ice shaded. Only the first panel has a sensor on it.*

</div>
</div>

<!--
Read the four traces in time order. Each decision in them is reasonable.

Friction collapses. The car starts to lose speed. The controller sees speed below the setpoint, and
commands more torque. That is its job. The torque cannot go into the road, so it spins the wheel.
Slip passes the peak. The available force **falls**. The car slows further. The controller sees a
bigger error, and commands more torque still.

Nothing in that chain is a bug. The controller does its job at every step. The system as a whole
does the wrong thing, and the tighter the tuning, the faster it does it.

The numbers. `v_set` is 90 km/h. `mu_low` is 0.05: at its peak the road then carries 343 newtons,
against the 401 it takes to hold 90 km/h. The patch starts at 4 seconds and lasts 8. A two-second
patch would cost only 0.77 km/h, too little to see. The run stops at 45 seconds, long enough for
the recovery.

The speed sags **3.10 km/h** across the eight seconds, less than a gentle hill would cost. So the
speed signal gives almost no warning. Meanwhile the command climbs to the engine's 150
newton-meters and stays there. The tread goes to about **3400 km/h**, and the slip ratio to
**38**. The tire crossed its adhesion peak, the point of best grip, **0.08 seconds** into the
patch, and never came back. When the ice ends, the car surges to **111.86 km/h**, nearly 22 km/h
over the setpoint, and takes **20.7 seconds** to come back inside half a km/h of 90.

The surge comes from the wheel. It is a flywheel holding **4.64 megajoules** at its peak, against
**0.44 megajoules** for the whole car at 90 km/h. When grip returns, that energy goes into the car.

The driver feels the back stepping out on a highway at 90 km/h, caused by a system they switched
on for comfort.
-->

---

## A friction-aware torque limit

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

The car still loses speed on the ice, but
**less**: 2.01 km/h against 3.10, while being asked for a fifth as
much torque. And the wheel does not spin up: about 219 km/h of tread against 3400.

</div>
<div>

![The same ice patch run overlaid with a friction-aware torque limit: the wheel stays near vehicle speed and the slip ratio stays on the near side of the peak, while speed dips and recovers.](/figures/10-ice-patch-limited.svg)

*Against the blind run. The capped car commands a fifth of the torque and loses **less** speed: 2.01 km/h against 3.10.*

</div>
</div>

<!--
The car still slows down. It has to: no controller can create grip. What the limit prevented was
the controller **making it worse**. Over the eight seconds, the capped tire put **more** force on
the road, 276 newtons against 242, while asked for a fifth as much torque. In the blind run, more
command gave less force. Traction control, the system in a car that cuts engine torque when a
driven wheel starts to spin, is built on that.

The cap is 26.6 newton-meters: the most force the ice can carry, 343 newtons, taken back through
the gearbox and the wheel radius to the engine.

The cap did not hold the tire at its peak. The capped run still ends the patch at a slip ratio of
1.5, nowhere near 0.04. A constant ceiling cannot track a peak. It only stops the command running
away from the surface, and that is most of the benefit.

One caveat: `y_max` is a constant, so the cap is on for the whole run, dry road included. 26.6
newton meters is less than the 31.1 that holds 90 km/h. So the capped car reaches the ice at 89.47
km/h, and drifts down after it: look at the green trace after 12 seconds. A fixed cap does not know
the actual grip. That is why lecture 2 adds a loop around slip.

When an actuator's limit depends on conditions the controller cannot see, something has to tell the
controller. Tuning cannot do that. It takes a change to the control structure.
-->

---

## Two lessons

### One

Real cruise control disengages when traction control intervenes. The
reason: the two loops act on the same actuator, and the speed loop has the worse
information.

### Two

The fix is an **inner loop regulating slip** inside an
**outer loop regulating speed**. The inner one is fast and local; the outer
one is slow and comfortable.

That is **cascade control**.

### Lecture 2 starts here.

<!--
We found the need for a new controller structure from the plant alone, by removing one assumption
about the tire.

The inner loop is fast and local. It rejects disturbances before the outer loop notices. The outer
loop is slow and comfortable, and sets the inner loop's setpoint.

Almost every advanced control architecture you will meet exists because a simple controller failed
on some plant.
-->

---

## Summary of the lecture

- **01** know the plant before you control it.
- **02** feedback corrects for changes in the road and the car.
- **03** P is fast, but leaves a steady-state error.
- **04** the integrator finds the holding torque without a model.
- **05** P, I and D: present error, past error, rate of change.
- **06** actuators saturate, and the integrator winds up unless clamped.
- **07** the derivative amplifies high-frequency noise.
- **08** one step test, three tables, and always plot the command.
- **09** sampling adds phase lag.
- **10** the tire is an actuator whose force has a peak.

### Every notebook is in the repository, executed, with its plots. Re-run them.

<!--
If you take one habit away from today, take the one that came up three times: **plot the actuator
command**. Section 06 found windup with it. Section 07 found chatter. Section 08 found an
undeliverable design. In all three, the controlled variable looked fine.

The notebooks and the `docs` folder are in the repository. The plots are committed, so you can read
them without installing anything.

Next lecture: the engine torque map, a table of how much torque the engine gives at each engine
speed. It brings the 246 km/h top speed from hands-on step 05 down to a realistic value. And
cascade control, which fixes the ice patch.
-->
