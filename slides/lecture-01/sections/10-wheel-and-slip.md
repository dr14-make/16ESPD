---
routeAlias: wheel-and-slip
layout: section
---

###### Notebook 10

# Wheel and slip

The tire is an actuator too, and it saturates — which makes cruise control dangerous on ice.

`notebooks/lecture01/10-wheel-and-slip.ipynb`

<!--
**Say:** everything so far assumed the tire does whatever the driveline asks. Students already
removed that assumption in the hands-on — steps 09 and 10 — and watched a wheel spin on snow
with nobody controlling it. This section puts a controller on that car.

**Timing:** 10 minutes if you have them. Beats one and two are recaps of the hands-on, steps 08
and 10 — take them fast. Beat three is new and is the section students remember; if you can
only show one beat, show the ice patch.

**Cut order:** first to go. Everything here is upside; the lecture stands without it.
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

*↩ Hands-on step 06: [the wheel's hidden mass](../handson-01/index.html#/6/1)*

> **If the response shifted**
>
> Say by how much. "The gains still work" is a claim, and a rise time is the evidence for it.

</div>
</div>

<!--
**Say:** students saw open-loop in step 06 that the wheel barely moves the launch. Now the
closed-loop question: do the gains of section 05 still hold? This is a fidelity increase that
changes nothing important, and that is worth showing on its own. Not every added detail
matters. Knowing which ones do is the modeling skill.

**Read out** the rise time and overshoot and compare with section 05.

**Readout — every symbol on this slide**

- **L1** — the model ladder's second rung: wheel inertia plus an ideal rolling contact.
  **L0** was everything up to section 09; **L2** adds slip.
- **Wheel inertia J<sub>w</sub>** — rotational inertia the engine must also accelerate, kg·m².
- **rise_time** — 10 % to 90 % of the commanded step, seconds. **overshoot** — peak past the
  setpoint, per cent.
- **Ideal rolling** — wheel speed times radius *is* road speed, by definition. No sliding,
  ever.
-->

---

## Beat one: the wheel runs away

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [10-wheel-and-slip.ipynb · cell 2. Wheelspin]
@named standing = Scenarios.TestSlipCarPlant()

MU_SNOW, MU_DRY = 0.2, 1.0   # packed snow, dry asphalt

# `saveat` is dense output, not decimation: the launch
# transient is over inside one adaptive step.
launch = sweep(standing, "friction.k", [MU_SNOW, MU_DRY];
               tspan = (0.0, 5.0), saveat = 0.01)
runs = Dict(launch.values .=> launch.sols)

# four panels: rpm and km/h do not share an axis
for path in ("plant.v_kmh", "plant.wheel_rpm",
             "plant.kappa", "plant.wheel.F_x")
    @show path signal(runs[MU_SNOW], path)[2][end]
end
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/10-wheel-and-slip.ipynb)

*↩ Hands-on step 10: [the same standing start, open loop](../handson-01/index.html#/10/3)*

Under closed loop the error stays large, so the integrator winds up —
against a limit **that is not in the engine at all**.

</div>
<div>

![Four panels from two standing starts, on snow and on dry asphalt: vehicle speed, wheel speed in rpm, slip ratio, and longitudinal tire force. On snow the wheel runs away to 12 843 rpm while the car reaches only 10 km/h, and the force trace peaks then collapses to a plateau.](/figures/10-wheelspin.svg)

*Two standing starts, same command. On snow the wheel reaches 12 843 rpm and the car reaches 10 km/h; on dry asphalt, 182 rpm and 21 km/h.*

</div>
</div>

<!--
**Say:** this is the standing start from hands-on step 10, on the course model. Same numbers:
12 843 rpm at the wheel is the 1500 km/h of tread speed they plotted. Do not re-explain it;
ask someone who finished step 10 what happened.

**Point at** the force panel, bottom right — it has the whole argument in one step. For the
first four tenths of a second both surfaces carry every newton the engine asks for. Then the
snow hits 1 373 N, everything it has, and falls off a cliff to 961 N, where it stays. **More
wheel speed bought less force.**

**Say:** the engine delivered everything it was asked for. The driveline turned. The wheel
spun to 12 843 rpm. And the car got to 10 km/h.

**Say:** and now the new part, which the hands-on could not show: connect it to section 06.
The integrator sees a large, persistent error and winds up, exactly as it did on the hill. But
this time the limit is not the engine's torque ceiling — the engine is nowhere near it. The
limit is in the contact patch, and no amount of torque gets past it.

**Ask the room:** would the anti-windup from section 06 help here? *(No. It watches the
engine's saturation, and the engine is not saturating. This is a limit the controller has no
way of seeing. That is the uncomfortable point of this whole section.)*

**Readout — every symbol on this slide**

- **friction.k** — the road friction multiplier, swept over two values. 1.0 is dry asphalt;
  0.2 is packed snow. The ice patch later in this section is 0.05.
- **plant.wheel_rpm** — the driven wheel's rotational speed. It gets its own panel because rpm
  and km/h do not share an axis.
- **plant.v_kmh** — the car's actual road speed. **plant.kappa** — the slip ratio.
  **plant.wheel.F_x** — the longitudinal force the tire makes.
- **saveat = 0.01** — dense output, not decimation: the launch transient is over inside one
  adaptive step, so the raw step points would draw straight lines.
- **The limit that is not in the engine** — the engine is nowhere near its ceiling. The
  ceiling is in the contact patch.
-->

---

## Beat two: the curve

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

*↩ Hands-on step 08: [slip, and how grip depends on it](../handson-01/index.html#/8/2)*

$$
\kappa \;=\; \frac{\omega r - v}{\max(|v|,\ \varepsilon)}
     \qquad F_x \;=\; \mu(\kappa)\,F_z
$$

```julia [10-wheel-and-slip.ipynb · cell 3. The friction curve]
# the `mu` equation lifted out of the component, not a
# formula retyped: change the model and this plot changes
wheel_model = complete(
    VehicleSystemsComponents.Vehicle.SlipWheel1D(name = :wheel))
mu_law = only(eq for eq in equations(wheel_model)
              if isequal(eq.lhs, wheel_model.mu))

mu_of = build_function(
    substitute(mu_law.rhs,
        Dict{Any, Any}(initial_conditions(wheel_model))),
    wheel_model.kappa, wheel_model.mu_scale;
    expression = Val(false))

kappas = range(0.0, 0.5; length = 2001)
dry_curve = mu_of.(kappas, MU_DRY)
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
**Recap, fast:** this is the curve from hands-on step 08 — rising to the adhesion peak at
κ = 0.04, falling to sliding. Point at the rising part (more slip, more force), the peak (an
actuator limit that moves with the weather), and past it.

**The new thing on this plot:** the wheelspin run's operating points. They all sit on the
falling side. That is where the car spent beat one.

**Ask the room:** what happens to a wheel that ends up on the right-hand side of that peak?
*(They met the answer in hands-on step 10: less force, so less resistance to the engine's
torque, so more slip, so even less force. Let them say it — the next slide is what it means
for a controller.)*

**Readout — every symbol on this slide**

- **κ (kappa)** — the *slip ratio*, dimensionless: (ω·r − v) / max(|v|, ε). Zero means pure
  rolling; positive means the wheel is turning faster than the car is moving.
- **ω** — wheel angular velocity, rad/s. **r** — wheel radius. **v** — vehicle speed, m/s.
- **ε (v_eps)** — a small floor on the denominator so slip is defined at standstill.
- **μ (mu)** — the friction coefficient: the fraction of the normal load available as
  tractive force.
- **F<sub>z</sub>** — the normal load on the wheel, N. **F<sub>x</sub> = μ·F<sub>z</sub>** —
  the longitudinal force it can make.
- **sAdhesion, sSlide** — where the curve peaks and where it has fully transitioned to
  sliding. **μ_A, μ_S** — the adhesion and sliding coefficients.
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
**Say:** the loop on the left is a recap. The box on the right is the new part: this is what
that loop means for the tuning you did in section 08.

**Say:** and notice this is the same car. The plant did not get replaced; it moved into a
region where it has a different character. That is what "nonlinear" means in practice — not a
curved graph, but different rules in different places.

**Say:** which is why the tuning flowchart puts that question first and not third. If you tune
a loop on the good side of the peak and it occasionally visits the bad side, your gains are
answering a question the plant has stopped asking.

**Ask the room:** what would you have to control to stay on the left of the peak? *(Slip
itself — which needs a sensor for it and a loop around it. Hold that; it is the last slide.)*

**Terms, if anyone asks**

- **Positive feedback** — an effect that reinforces its own cause. Here it is inside the
  plant, and nobody wired it.
- **Open-loop unstable** — the plant runs away on its own, with no controller involved.
- **The well-behaved gate** — section 08's first question. Past the friction peak, the answer
  is no, and no PID tuning fixes it.
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

SPEED   = "loop.plant.v_kmh"      # what it measures
RPM     = "loop.plant.wheel_rpm"  # what it does not
SLIP    = "loop.plant.kappa"      # nor this
COMMAND = "loop.controller.y"
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/10-wheel-and-slip.ipynb)

**The controller reads falling speed, commands more torque,
spins the driven wheel — and destroys the traction it was trying to use.**

</div>
<div>

![Four panels across a shaded eight-second low-friction patch: vehicle speed sagging by three km/h and then surging past the setpoint, wheel speed climbing to 29 000 rpm, slip ratio past the adhesion peak to 38, and commanded torque rising to the engine's limit.](/figures/10-ice-patch.svg)

*Speed, wheel speed, slip ratio and commanded torque, with the eight seconds of ice shaded. Only the first panel has a sensor on it.*

</div>
</div>

<!--
**Narrate the four traces in time order,** as a sequence of entirely reasonable decisions:

- Friction collapses. The car starts to lose speed.
- The controller sees speed below setpoint — which is true — and commands more torque. That is
  exactly what it is for.
- The extra torque cannot go into the road, so it goes into spinning the wheel.
- Slip passes the peak. Available force *falls*. The car slows further.
- The controller sees a bigger error and commands more torque still.

**Say:** nothing in that chain is a bug. Every step is the controller doing its job correctly.
The system as a whole does the wrong thing, and it does it faster the better the controller is
tuned.

**The numbers, if you want them on the board:** the speed sags **3.10 km/h** across the eight
seconds — less than a gentle hill would cost, which is the trap. Meanwhile the wheel goes to
**29 101 rpm** and the slip ratio to **38**; the tire crossed its adhesion peak **0.08 s** into
the patch and never came back. When the ice ends the car surges to **111.88 km/h**, nearly 22
km/h over the setpoint, and takes **20.4 s** to come back inside half a km/h of 90.

**If someone asks where the surge comes from:** the wheel is a flywheel holding **4.64 MJ** at
its peak, against **0.44 MJ** for the whole car at 90 km/h. When grip returns, that energy has
somewhere to go.

**Say:** and in a real car the driver feels this as the back stepping out on a motorway at 90
km/h, caused by a system they switched on for comfort.

**Readout — every symbol on this slide**

- **mu_low = 0.05** — the friction multiplier during the patch. The road carries 343 N at its
  peak, against the 401 N it takes to hold 90 km/h.
- **patch_start = 4 s, patch_duration = 8 s** — eight seconds of it. Two seconds cannot
  produce a visible speed drop: at 90 km/h a total loss of traction for two seconds costs
  about 2 km/h.
- **v_set = 90 km/h** — the cruise speed. **stop = 45 s** — long enough to capture the
  recovery.
- **Four traces** — vehicle speed, wheel speed, slip ratio, commanded torque, on a shared time
  axis with the patch shaded. **Only the first has a sensor on it.**
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
**less** of it: 1.99 km/h against 3.10, while being asked for a fifth as
much torque. And it does not lose the wheel — 1 846 rpm against 29 101.

</div>
<div>

![The same ice patch run overlaid with a friction-aware torque limit: the wheel stays near vehicle speed and the slip ratio stays on the near side of the peak, while speed dips and recovers.](/figures/10-ice-patch-limited.svg)

*Against the blind run. The capped car commands a fifth of the torque and loses **less** speed doing it — 1.99 km/h against 3.10.*

</div>
</div>

<!--
**Say:** and be precise about what the fix bought. The car still slows down. It has to — there
is less friction available and no controller can conjure grip. What the limit prevented was
the controller *making it worse*. Averaged over the eight seconds the capped tire put *more*
force on the road — 275 N against 242 — while being asked for a fifth as much torque. More
command, less force. That is the whole of traction control in one line.

**Do not oversell it.** The cap did not hold the tire at its peak: the capped run still ends
the patch at a slip ratio of 1.5, nowhere near 0.04. A constant ceiling cannot track a peak —
it can only stop the command running away from the surface, and that turns out to be most of
the benefit.

**The honest caveat:** `y_max` is a constant, so the cap is on for the whole run, including
the dry road either side. 26.6 N.m is less than the 31.1 that holds 90 km/h, so the capped car
reaches the ice at 89.47 km/h and drifts down afterwards. Watch the green trace past t = 12 s.
A fixed cap is the right idea with the wrong information — which is exactly why lecture 2
needs a loop around slip.

**Say:** that is a general shape worth naming. When an actuator's limit depends on conditions
the controller cannot see, somebody has to tell it. That is not tuning. That is architecture.
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
**Say:** and notice we did not need a new controller type to see the need for one. The need
came out of the plant, by removing one assumption about a tire.

**Say:** that is a good note to end on generally — almost every advanced control architecture
you will meet exists because somebody found a plant that defeated the simple one. Not because
it was elegant.

**Terms, if anyone asks**

- **Cascade control** — one loop inside another: a fast inner loop regulating slip, a slower
  outer loop regulating speed. Lecture 2's subject.
- **Inner loop** — fast, local, rejects disturbances before the outer loop notices. **Outer
  loop** — slow, comfortable, sets the inner loop's setpoint.
- **Why real cruise control disengages** — two loops fighting over one actuator, and the speed
  loop has the worse information.
-->

---

## Ninety minutes, one car

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
**Close with this:** if you take one habit away, take the one that showed up three times
today without being planned — *plot the actuator command*. Section 06 found windup with it.
Section 08 found an undeliverable design with it. Section 07 found chatter with it. In all
three the controlled variable looked fine.

**Point them at** the notebooks and at `docs/`. Everything on these slides is reproducible,
and the plots are committed so they can read them without installing anything.

**Next lecture:** the engine torque map, which fixes the 246 km/h lie from hands-on step 05 —
and cascade control, which fixes the ice patch.
-->
