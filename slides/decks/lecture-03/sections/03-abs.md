---
routeAlias: abs
layout: section
---

###### Section 03

# Anti-lock braking

Keep every wheel rolling, near the peak of its friction curve, however hard the driver brakes.

`notebooks/lecture03/01-abs.pluto.jl`

<!--
Budget: 23 minutes, 14 slides, then the break. Hardware 9 (what 1, history 1, sensors 2,
modulator 2, channels 1.5, cycle 1.5), estimation 2, model and results 10 (model 3, one stop 2,
curve 2, distance 1.5, surfaces 1.5), summary 1, plus cover and slack 1. The four result slides are
the hands-on checkpoints: point at the green cues, the students will come back to them.

The center of the lecture. First the system as it is built: history, sensors, valves, layouts and
the control cycle. Then the model in the repository: a wheel-speed-only ABS controller, run on
one braking wheel, against a locked wheel.
-->

---
routeAlias: what-abs-does
---

## What ABS does

<div class="grid grid-cols-[1fr_1.1fr] gap-8">
<div>

The **anti-lock braking system (ABS)** keeps the wheels from locking under braking, so the tires
keep their grip on the road while the driver brakes as hard as they like.

Two benefits, in order of importance:

1. **The car can still be steered**: a rolling tire gives lateral force, a locked one almost none.
2. **A shorter stop on most roads**: the tire works near its peak instead of sliding.

Four parts:

- **wheel-speed sensors**, usually one per wheel
- **valves** and a **return pump**, in one hydraulic modulator
- the **controller**, an ECU usually mounted on the modulator

</div>
<div>

![An ABS layout in a car: wheel-speed sensors at all four wheels with toothed pulser rings on the brake discs, brake lines to a modulator unit near the master cylinder, and a control module.](/pptx/slide07-abs-layout.jpg)

</div>
</div>

<!--
The definition from the source deck, tightened: ABS lets the wheels keep tractive contact with the
road according to the driver's inputs while braking.

The order of the two benefits matters. Drivers think ABS is about stopping distance. It is first
about steering: in a panic stop, a car with locked front wheels goes straight on whatever the
driver does with the wheel. With ABS the driver can brake fully and steer around the obstacle.

The shorter stop is real on paved roads, 10 to 23 percent in NHTSA's tests. On loose gravel or
deep snow a locked wheel can stop shorter, because it builds a wedge of material in front of the
tire. Some off-road vehicles therefore have an ABS mode for loose surfaces.

The image is the source deck's, a 1990s layout.
-->

---
routeAlias: abs-history
---

## A short history

| Year | Milestone |
|---|---|
| ~1920 | **Gabriel Voisin** experiments with a flywheel-and-valve anti-skid on aircraft brakes |
| 1952 | **Dunlop Maxaret**, a mechanical anti-skid, in service on aircraft: shorter stops, fewer burst tires |
| 1966 | Jensen FF, the first production car with a (Maxaret-derived, mechanical) anti-lock system |
| 1978 | **Bosch ABS 2** in the Mercedes-Benz S-Class (W116): the first electronic four-wheel ABS for passenger cars, then the BMW 7 Series |
| 1984 | standard on every Mercedes-Benz car |
| 2004 | EU car makers commit to fit ABS on every new car (a voluntary agreement) |
| 2011–2014 | EU and US stability control mandates make ABS hardware universal on new cars |

<!--
The source deck said ABS was first developed for aircraft in 1929 by "Gabrier Voisin". The name is
Gabriel Voisin, the French aviation pioneer, and the commonly given date is around 1920. That date
comes from secondary sources; I found no primary one.

Dunlop's Maxaret was a purely mechanical device: a flywheel in the wheel hub that overran when the
wheel decelerated too fast and opened a valve releasing brake pressure. It was in aircraft service
from the early 1950s. The Jensen FF of 1966 carried a version of it, the first production car with
anti-lock brakes, though few were built.

The step to electronics was Bosch's, building on work started at Teldix in 1964. The first
prototypes had around a thousand analog components; the production ABS 2 of 1978 had 140. It
appeared as an option on the Mercedes S-Class at the end of 1978, and soon after on the BMW 7
Series. Bosch's own page calls it the first electronically controlled four-wheel antilock braking
system for passenger cars.

Neither the EU nor the US ever mandated ABS on cars by a law of its own. In Europe the car makers'
association committed to it from 2004. Then the stability control mandates, EU new types from
November 2011 and all new cars from November 2014, US model year 2012, required ESC, and ESC is
built on ABS hardware.

Sources: Bosch Mobility, antilock braking system page; Mercedes-Benz press release on 40 years of
ABS; Motor Sport magazine 1959 on the Maxaret; Wikipedia for Voisin and the Jensen FF.
-->

---
routeAlias: wheel-speed-sensors
---

## Wheel-speed sensors

<div class="grid grid-cols-[1fr_1fr] gap-8">
<div>

A toothed ring (or a magnetic encoder ring) turns with the wheel; a sensor counts the teeth
passing. **Pulse frequency is proportional to wheel speed.**

**Passive, inductive** (variable reluctance): a coil around a magnet. The teeth change the
magnetic flux and induce an AC voltage whose amplitude and frequency rise with speed. Too weak
below a few km/h.

**Active, Hall or magnetoresistive**: a powered chip. Bosch's sensors detect speed down to
**0.1 km/h** and send **current pulses** on a two-wire interface, so the signal does not depend on
the amplitude. Magnetoresistive versions also report the direction of rotation.

</div>
<div>

![A toothed wheel turning past a wheel-speed sensor, which generates one pulse per tooth.](/pptx/slide08-tone-wheel.png)

> **The ABS measures only this**
>
> Wheel speed, at every wheel. Not the car's speed, not the slip. The next slides show what
> that costs.

</div>
</div>

<!--
The same two sensor principles as the crank sensor in Lecture 2: the variable-reluctance sensor
and the Hall sensor. The source deck described the passive type: low AC voltage, frequency
rising with wheel speed.

The passive sensor needs no supply, but its voltage falls with speed, so it gives no usable signal
at a crawl, a few kilometers per hour. That was acceptable for ABS, which switches off near
standstill anyway. Hill-hold, parking and stability functions need the speed down to zero, so
modern cars use active sensors. Bosch's active sensor has the sensing element, an amplifier and
the signal processing on one chip, and sends constant-amplitude current pulses: two current
levels, around 7 and 14 milliamps in trade literature, though I could not find that number in a
Bosch specification.

The source deck said the ECU compares the sensor signals to values stored in its memory. More
precisely: it computes wheel speed and wheel deceleration from the pulse timing, every few
milliseconds, and compares the wheels with each other and with an estimate of the car's speed.

Source: Bosch Mobility, wheel-speed sensor page.
-->

---
routeAlias: modulator
---

## The hydraulic modulator: build, hold, dump

<div class="grid grid-cols-[1.5fr_1fr] gap-6">
<div>

![One ABS channel: the master cylinder feeds the caliper through a normally open inlet valve; a normally closed outlet valve lets caliper fluid into a low-pressure accumulator, and a return pump sends it back to the master-cylinder side. Below, a table: build has the inlet open and outlet closed, so wheel pressure follows the driver; hold has both closed, so it is frozen; dump has the inlet closed and outlet open, so it falls into the accumulator.](/diagrams/03-abs-channel.svg)

</div>
<div>

![An ABS hydraulic modulator: an aluminum block with brake lines entering the top and an electric connector on the side.](/pptx/slide09-abs-modulator.jpg)

Bosch: ABS "reduces brake pressure then increases it again **up to 40 times a second**".

<div class="handson">→ Hands-on step 03: build and dump become the two signs of one pressure rate</div>

</div>
</div>

<!--
The source deck's three valve positions, mapped onto how a modern unit is built. Each wheel channel
has two solenoid valves rather than one three-position valve: an inlet valve that is open when
unpowered and an outlet valve that is closed when unpowered. So if the electronics fail, the
brakes work as if there were no ABS.

Position one, open: build. Position two, line blocked: hold, so pressure cannot rise even if the
driver pushes harder. Position three, release: dump, the outlet valve lets fluid out into a small
spring-loaded accumulator. The pump returns it to the master-cylinder side, which is what the
driver feels as pulsing in the pedal.

The important property: ABS can only take pressure away from what the driver commands. It cannot
build more than the master cylinder supplies. ESP, later, needs two more valves per circuit to do
exactly that.

Bosch's "up to 40 times a second" counts pressure modulation steps. The full slip cycle, one
release and reapply of the wheel, is slower: 2 to 6 cycles per second measured on a production
Bosch ABS, according to Day and Roberts, SAE 2002-01-0559, as cited in
`docs/abs-frequency-research.md`.

Sources: Bosch Mobility, antilock braking system page; the repository's report
`docs/reports/Passenger car brake system modeling.md` and its research notes on the modulator.
-->

---
routeAlias: abs-channels
---

## Channels and sensors

<div class="grid grid-cols-3 gap-6">
<div>

### Four-channel, four-sensor

A sensor and a valve pair for every wheel. Each wheel is controlled on its own.

The layout of every modern car with ESP, which needs to brake single wheels.

</div>
<div>

### Three-channel, three-sensor

One channel per front wheel, one for both rear wheels together; the rear speed sensor sits in the
rear axle's differential.

Common on pickup trucks and older cars.

</div>
<div>

### One-channel, one-sensor

One valve for both rear wheels, one sensor in the rear axle. **Rear-wheel ABS** only: the fronts
can still lock.

Older pickup trucks.

</div>
</div>

> **Select-low.** When one channel serves two wheels, it releases as soon as the **first** of
> them starts to lock. The axle brakes only as hard as its worse wheel allows, and neither wheel
> locks.

<!--
The source deck's three layouts. A channel is one independently controlled pressure: one inlet and
outlet valve pair. A sensor is one wheel-speed signal.

Why a three-channel system controls the rear axle as one: the rear contributes less to braking,
and keeping both rear wheels rolling is what keeps the car stable. Controlling them together with
select-low gives away a little braking on a split surface, one side on ice and one on asphalt, but
keeps the rear from yawing the car.

The front wheels are usually controlled individually, select-high in effect. On a split surface
that gives a yaw moment, which the driver corrects with the steering; modern systems limit how
fast the pressure difference between the fronts can grow, giving the driver time to react.

Four-channel is the norm since ESP: to brake one wheel on purpose, each wheel needs its own valves.

These layouts are from the source deck; I did not find a primary source that classifies them, so
treat the "common on" remarks as typical rather than exact.
-->

---
routeAlias: abs-cycle
---

## The control cycle

<div class="grid grid-cols-[1.1fr_1fr] gap-8">
<div>

The source deck's **simplest algorithm**:

1. While braking, watch every wheel for a deceleration **faster than the car can decelerate**.
2. **Dump** pressure on that wheel until it accelerates again.
3. **Hold**, the line isolated from the master cylinder.
4. **Build** pressure again until the wheel decelerates too fast once more.
5. Repeat.

The driver feels a **pulsing in the pedal**.

</div>
<div>

Bosch's production cycle has **eight phases**, and two things the simple version lacks:

- **Hold before dump**: a wheel decelerating hard may only be approaching the peak.
- **Pressure memory**: rebuild fast to just below the pressure at which the wheel started to
  lock, then creep up slowly.

| | |
|---|---|
| slip cycle, production ABS | **2–6 per second** |
| pressure steps | up to 40 per second |
| ECU sample time | 3–6 ms |

</div>
</div>

<!--
The left column is the source deck's algorithm, reworded. It said "repeat this procedure around
15 times per second". That number mixes up two rates. The pressure valves step tens of times per
second. The wheel's full slip cycle, lock-release-recover, runs at 2 to 4 per second on the front
wheels on a dry road and 4 to 6 on the rear and on ice, measured on a Bosch ABS 5.2 car by Day and
Roberts, SAE paper 2002-01-0559. The frequency is not chosen; it follows from the wheel's dynamics
and the hydraulics.

The Bosch cycle, as reproduced by Day and Roberts from Bosch's Driving-safety systems handbook:
follow the master cylinder until the wheel deceleration passes a threshold, hold until slip passes
a threshold, dump until the wheel accelerates again, hold, build fast, hold, build slowly at about
a tenth of the fast rate, then dump again. The controller learns the lock-up pressure each cycle.

The ECU sample times, 3 milliseconds for Bosch and 6 for Aisin, come from patents cited in
`docs/abs-frequency-research.md`.

The video in the source deck showed the cycle on a test car; it is not reproduced here.
-->

---
routeAlias: reference-speed
---

## Slip without knowing the car's speed

<div class="grid grid-cols-[1fr_1fr] gap-8">
<div>

Slip needs the car's speed $v$, and an ABS measures only wheel speeds $\omega_i$. So it
**estimates** a reference speed:

- while the wheels roll freely, $v_{ref}$ = the fastest wheel's $\omega r$;
- while they slip, $v_{ref}$ may fall no faster than a deceleration **$a_{ref}$** the road
  plausibly allows.

$$
\lambda \;=\; \frac{\omega r - v_{ref}}{v_{ref}}
$$

</div>
<div>

> **The trap**
>
> If $a_{ref}$ is larger than the road really allows ($\approx \mu g$), $v_{ref}$ falls faster
> than the car. The controller **under-reads** the slip, releases late, and the stop gets
> longer.
>
> On ice $\mu g$ is under 1 m/s²; on dry asphalt nearly 10.

Production systems **learn** the road's deceleration, and some use a longitudinal accelerometer.

<div class="handson">→ Hands-on step 04: you write this estimator and feed your ABS from the wheel speed alone</div>

</div>
</div>

<!--
This is the hardest part of a real ABS, and the reason the model in the repository has two
versions of its controller.

When all four wheels brake at once, none of them rolls freely, so none tells you the car's speed.
The ABS assumes the car cannot decelerate faster than some limit and lets its estimate fall no
faster than that, following a wheel only when the wheel is faster.

In the model, `ABSWheelOnlyEstimatorDiscrete` does exactly that: `v_ref` follows the wheel speed
when the wheel is faster, else falls at the effective a_ref, every 5 milliseconds. Notebook 01
has a slider for a_ref. Move it to 10 or more and watch the ABS lose on wet and snowy roads.

With four wheels, the ABS releases one wheel briefly now and then to let it spin up and measure
the car's speed again. A single wheel model cannot do that.
-->

---
routeAlias: abs-model
---

## The model: one wheel, one ABS

![The ABS loop. Inside an ECU sampled every 5 ms: a speed estimator, ABSWheelOnlyEstimatorDiscrete, which lets v_ref fall at most at a_ref and computes slip lambda; then a modulator, ABSModulatorDiscrete, build, hold, dump, remembering the lock torque, which also takes the driver's demand. Its torque command goes to the brake actuator, BrakeActuator, a 30 ms first-order lag, then to the wheel, tire and car, BrakedWheel and TireFrictionCurve. The wheel speed omega is fed back to the estimator: the only thing it measures.](/diagrams/03-abs-loop.svg)

<div class="grid grid-cols-3 gap-6 text-sm mt-2">
<div>

**Plant.** 1400 kg on one lumped wheel, $J_w$ = 4 kg·m², $r$ = 0.31 m, 90 km/h, driver demand
6000 N·m from 0.5 s: 1.4× what the tire can carry.

</div>
<div>

**Release** on *predicted* slip $\lambda + T_p \dot\lambda$, $T_p$ = 30 ms, past the 4 % peak,
or on slip past 20 %. Release to 60 % of the lock torque.

</div>
<div>

**Reapply** fast to 85 % of the lock torque, then slowly. Off below 1.5 m/s. Also run: the same
logic on the **true** slip, and the **locked** wheel.

</div>
</div>

<div class="handson">→ Hands-on steps 02–03: you build the locked bench, then write a simpler controller, <code>SlipABS</code>:
release on the predicted slip, without the pressure memory</div>

<!--
The model in `dyad/Vehicle/ABSController.dyad` and its test benches in `ABSBrakeTest.dyad`. It is
a compressed version of the Bosch cycle on the previous slides, with three phases, decrease, hold
and increase, and an off state below 1.5 meters per second.

The key design choice is the predicted slip. The brake hydraulics take 30 milliseconds to respond,
so by the time a release command takes effect the wheel has dived further. The controller looks
30 milliseconds ahead, slip plus 30 milliseconds times its rate of change, and releases when that
predicted slip passes the peak. That is the lead that covers the actuator lag.

The second choice is pressure memory, from the Bosch cycle: release to 60 percent of the torque at
which the wheel started to lock, reapply quickly to 85 percent, then creep up.

Getting here took several iterations: an earlier version that released on present slip and
dumped the brake almost to zero each cycle stopped longer than the locked wheel. The record is in
`docs/abs-braking-distance-findings.md` and `docs/abs-frequency-research.md`. The controller was
rewritten in commit c960b11; the numbers on the next slides are from running notebook 01 on it.

Three benches: `ABSBrakeTransient` with the wheel-speed-only controller, `IdealBrakeTransient`
with the same kind of logic on the true slip and speed, and `LockedBrakeTransient` with the full
demand and no ABS.
-->

---
routeAlias: one-stop
---

## One stop from 90 km/h, dry road

<div class="grid grid-cols-2 gap-6">
<div>

![Vehicle and wheel speed against time: braking starts at 0.5 s; the ABS car's wheel surface speed ripples just under its vehicle speed all the way down, and the ABS car stops at about 3.6 s; the car with a locked wheel decelerates less steeply and stops at about 4 s.](/figures/03-vehicle-and-wheel-speed.svg)

</div>
<div>

![Brake torque at the caliper against time: without ABS it rises to 6000 N·m and stays; with ABS it peaks near 4600 N·m and then oscillates between about 3000 and 4000 N·m, below the dotted tire limit of 4256 N·m, until it goes to 6000 N·m near standstill.](/figures/03-brake-torque.svg)

</div>
</div>

<div class="caption">Notebook 01 at road μ = 1.0, a_ref = 8 m/s². Left: speeds. Right: brake torque at the caliper.</div>

<div class="handson">✓ Checkpoint, hands-on steps 02–03: the locked car is at rest at about 4 s; your ABS's torque
cycles below the 4256 N·m tire limit</div>

<!--
Both from notebook 01, cells "What the wheel is doing", at the defaults.

Left: the wheel surface speed, omega times r, light blue, stays just under the car's speed: the
wheel keeps rolling with a few percent of slip all the way down. The locked car, red dashed,
decelerates at the sliding friction and stops later.

Right: the torque at the caliper. Without ABS it goes to the driver's 6000 newton meters and stays
there; the wheel is locked within about a tenth of a second. With ABS it overshoots once, then
cycles between about 3000 and 4000 newton meters, just under the dotted line: 4256 newton meters,
the torque at which the tire is at its peak. That is the ABS doing its job: braking at the edge of
what the tire can carry.

The cycle here is faster than a production ABS's, about eight to nine per second read off the
trace, against 2 to 6 measured. The model's tire curve is sharper than a real tire's, which makes
the cycle faster. Near standstill the ABS switches off and the wheel locks, as a real ABS does
below a few kilometers per hour.
-->

---
routeAlias: on-the-curve
---

## Where on the tire curve the wheel works

<div class="grid grid-cols-[1.2fr_1fr] gap-6">
<div>

![Friction coefficient against slip, from 0 to -0.3: the tire curve, drawn with braking's negative sign, reaches its peak magnitude of 1.0 at -0.04 and settles at 0.7 from -0.12; the ABS run's samples cluster tightly around the peak. Title: 90 percent of the stop near the peak, 4 percent sliding.](/figures/03-where-on-the-curve.svg)

</div>
<div>

![Wheel slip against time: without ABS the slip goes to -1 within about 0.1 s of braking and stays there; with ABS it hovers just past the -0.04 adhesion peak until the ABS switches off near standstill.](/figures/03-wheel-slip.svg)

**90 %** of the stop near the peak ($0.02 \le |\kappa| \le 0.08$), **4 %** sliding.

<div class="handson">✓ Checkpoint, steps 02–03: the locked wheel reaches κ = −1 within 0.1 s; yours stays
near −0.04</div>

</div>
</div>

<!--
The left plot is the most important one for understanding ABS. Each dot is one millisecond of the
stop. The gray line is the model's tire curve, with braking slip negative. The ABS dots crowd
around the peak at minus 0.04. The locked wheel's dots all sit at minus 1, off the left edge, at
the sliding friction of 0.7.

Right: slip over time. The locked wheel goes to minus one within a tenth of a second and stays.
The ABS wheel hovers just on the far side of the peak, with small excursions.

The percentages are computed in the notebook cell "Where on the tire curve the wheel operates"
from one-millisecond samples of the run.
-->

---
routeAlias: abs-distance
---

## Braking distance

<div class="grid grid-cols-[1.3fr_1fr] gap-6 items-center">
<div>

![Vehicle speed against distance since the brake was applied: the gray ideal curve at peak friction stops at 31.9 m, the green ideal ABS at 34.4 m, the blue ABS at 38.7 m, and the red locked wheel at 43.7 m.](/figures/03-speed-over-distance.svg)

</div>
<div>

From 90 km/h, dry road (μ = 1.0):

| | distance |
|---|---:|
| ideal: held at the peak, $v^2 / 2\mu_A g$ | 31.9 m |
| ABS on the true slip | 34.4 m |
| **ABS, wheel speed only** | **38.7 m** |
| **no ABS, locked** | **43.7 m** |
| sliding bound, $v^2 / 2\mu_S g$ | 45.5 m |

ABS stops **11 % shorter** than the locked wheel. NHTSA measured **10–13 %** on dry pavement.

<div class="handson">✓ Checkpoint: step 02 locked 43.7 m · step 03 your ABS on true slip 34.4 m ·
step 04 wheel speed only, between the two (library: 38.7 m)</div>

</div>
</div>

<!--
From notebook 01, cell "Braking distance", re-run for this deck on the current models. Braking
distance is measured from brake application to below 0.5 meters per second.

The ideal stop holds the tire exactly at its peak for the whole stop. No real controller does,
because the brake needs 30 milliseconds to respond and the wheel must cycle. The ideal ABS, with
perfect knowledge of the slip, gets within 2.5 meters of it. The wheel-speed-only ABS loses
another 4.3 meters to its speed estimate. It still beats the locked wheel by 5 meters, 11 percent,
in the range NHTSA measured on real cars.

The locked wheel stops a bit short of the sliding bound because it is not locked for the first
tenth of a second, and drag and rolling resistance help.

An earlier version of this controller stopped longer than the locked wheel, 55.7 against 43.7
meters; `docs/abs-braking-distance-findings.md` records that diagnosis. These numbers are after
the fix in commit c960b11.
-->

---
routeAlias: abs-surfaces
---

## Across road surfaces

<div class="grid grid-cols-[1.3fr_1fr] gap-6 items-center">
<div>

![Braking distance from 90 km/h against the road friction multiplier from 0.2 to 1.0, for ABS, ideal ABS and the locked wheel, inside a gray band between the peak-friction and sliding bounds. All fall with friction. ABS is below the locked wheel everywhere except at 0.3, where it is slightly above.](/figures/03-distance-vs-mu.svg)

</div>
<div class="text-[0.95rem]">

| road μ | ABS | ideal ABS | locked |
|---:|---:|---:|---:|
| 1.0 | 38.7 m | 34.4 m | 43.7 m |
| 0.7 | 59.0 m | 46.7 m | 61.7 m |
| 0.5 | 83.2 m | 63.4 m | 85.1 m |
| 0.3 | **141.3 m** | 102.2 m | **136.8 m** |
| 0.2 | 178.6 m | 149.4 m | 196.5 m |

On slippery roads the **speed estimate** costs most of the gain; at μ = 0.3 this ABS loses.

<div class="handson">✓ Hands-on step 05: this table from your own models at μ 1.0, 0.5, 0.3; then μ 0.3 again
with a_ref ≈ 2.4</div>

</div>
</div>

<!--
The sweep from notebook 01, cell "Braking distance across road surfaces", same ABS tuning, a_ref
of 8.

With true slip, the ideal ABS beats the locked wheel by 21 to 26 percent on every surface. The
wheel-speed-only ABS gets only a few percent on wet and snowy roads, and at a road factor of 0.3
it stops 4.5 meters longer than the locked wheel. The reason is the trap from the reference-speed
slide: an a_ref of 8 meters per second squared is far more than a road with mu 0.3 allows, about
2.9, so the estimated vehicle speed falls faster than the car and the controller under-reads the
slip.

This is the model's honest result, not a property of real ABS. Real ABS learns the road's
deceleration, and some systems add an accelerometer. Adaptive a_ref is the stretch goal in
`docs/abs-controller-spec.md`. The hands-on's step 05 does the first half of that exercise by
hand: it reruns mu 0.3 with a_ref set to about 0.8 mu g, 2.4, the value an adaptive estimate
would converge to. Making a_ref adapt on its own is left as an exercise.

And remember the first benefit: even where the distance is no shorter, the ABS wheel still rolls,
and the car can still be steered.
-->

---

## Summary of section 03

- ABS keeps the wheels rolling under full braking: the car **stays steerable**, and on paved roads
  it **stops shorter**.
- Wheel-speed sensors, a modulator that can only **build, hold or dump**, and an ECU. Four
  channels on any car with ESP.
- The controller must **estimate the car's speed** from wheel speeds, and **lead** the 30 ms
  hydraulic lag.
- In the model: 90 % of a dry stop near the peak, 11 % shorter than locked; on slippery roads
  a fixed $a_{ref}$ throws the gain away.

### Next: the same idea for a wheel that is driven, not braked. <Link to="tcs">→ 04, traction control</Link>

<!--
ABS controls slip on the braking side of the curve. The driving side has the same peak and the
same runaway: you saw it at the end of Lecture 1.
-->
