---
routeAlias: abs
layout: section
---

###### Section 03

# Anti-lock braking

Keep every wheel rolling, near the peak of its friction curve, however hard the driver brakes.

`notebooks/lecture03/01-abs.pluto.jl`

<!--
Budget: 88 minutes, with the 10-minute break in the middle: 46 before it, 42 after.
Before: cover and what ABS does 2, hardware 9 (history 1, sensors 2, modulator 2, channels 2,
cycle 2), the model 3, build 03 28, one stop and on the curve 4. After: reference speed 2, build
04 with its checkpoint 25, braking distance 2, surfaces 2, against measured cars 1.5, why ABS
can stop longer 1.5, build 05 7, summary 1.

The center of the lecture, and where most of the building happens. The room arrives with a locked
wheel on its own car from build 02, so the problem is on screen before the solution is. Then the
system as it is built:
history, sensors, valves, layouts and the control cycle. Then the model in the repository, and
your own slip controller beside it. After the break: an ABS that sees only the wheel speed, and
the same stop on three roads. The four result slides of the library model are the checkpoints for
your builds: the green cues say which number is yours.
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

You have the problem on your own car already: build 02 at pedal 0.6 locks the wheel and stops in
43.7 meters. Keep that run; every ABS build is measured against it.
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

<div class="handson">→ Build 03 uses an <b>ideal</b> modulator, <code>ABSValve</code>: the ECU sends the wheel
pressure it allows and the valve sets it. No inlet or outlet valve, no accumulator, no pump, so
<b>no pedal pulse</b>. Build and dump become the two signs of one pressure rate.</div>

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

Say clearly what the build uses instead. `ABSValve` is the result of this hardware, not the
hardware: the controller sends an allowed wheel pressure, and the valve makes the caliper follow
it, never above the master cylinder and 30 milliseconds late. A command held steady is hold, a
falling one is dump, a rising one is build. The dumped fluid leaves the model, and the pedal is a
force command, so the pulse the driver feels cannot appear. A model with real inlet and outlet
valves, accumulator and return pump is in preparation.

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

<div class="handson">→ Build 03, next: a simpler controller of your own, <code>SlipABS</code>: release on the
predicted slip, without the pressure memory</div>

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
demand and no ABS. Your `PedalStop` at pedal 0.6 plays the third one on your own car: it puts
6109 newton meters on the wheel, about this 6000 demand, and locks at the same 43.7 meters.

On the next slide you write the release rule yourself, on the true slip and without the pressure
memory: the idea of this slide in eight lines.
-->

---
routeAlias: build-slip-abs
---

## Build 03: an ABS of your own

<div class="grid grid-cols-[1fr_1.15fr] gap-8 items-start">
<div>

<div class="text-sm">

```txt
# SlipABS, in code. Inputs kappa, v, demand; output tau_cmd
pressure = VehicleSystemsComponents.Vehicle.ABSPressureIntegrator(T_track = 0.01)
# A: dump past the peak, build otherwise
pressure.requested_rate = ifelse(kappa_pred < -lambda_target, -k_dec, k_inc)
pressure.active = ifelse(v > v_min, 1.0, 0.0)
# C: look T_p = 30 ms ahead
der(kappa_f) = (kappa - kappa_f) / T_f
kappa_dot = (kappa - kappa_f) / T_f
kappa_pred = kappa + T_p * kappa_dot
```

</div>

*New `ABSStop`: `demand` Step(6000 at 0.5 s) → `abs` → `wheel.tau_cmd` of a `BrakedWheel` ·
your `body` · `fixed` · `speed` · `road` · `wheel.kappa` → `abs.kappa` · `speed.v` → `abs.v` ·
five `initial` lines · run A (`T_p = 0`), then C (`T_p = 0.03`)*

[page: step 03](../lecture/lecture-03/#step-03) · reference `dyad/HandsOn03/SlipABS.dyad`

</div>
<div>

![Two panels against time for the two ABS runs. Top, brake torque: without look-ahead it saws between about 600 and 4700 N·m roughly every 0.38 s; with the 30 ms look-ahead it holds near 4300 to 4400 N·m, just above the dotted 4256 N·m tire peak, until 3 s, then goes to 6000. Bottom, slip: without look-ahead each cycle dives past the -0.12 sliding line to -0.2 and deeper; with it the slip sits on the -0.04 peak line until the ABS switches off near 3 s.](/img/lecture-03/step03-abs-torque-slip.svg)

<div class="handson">✓ A, <code>T_p = 0</code>: <b>53.8 m</b>, <i>longer</i> than locked, 2.6 Hz ·
C, <code>T_p = 0.03</code>: <b>34.4 m</b>, 21 % shorter, slip at −0.04, 31 Hz</div>

</div>
</div>

<!--
The release rule from the last slide, written by you. Twenty-eight minutes, in three parts.

A, the controller. Right-click `MyCar`, Add Component, `SlipABS`, and toggle to code. Its ports:
three inputs, `kappa` the wheel's slip, `v` the car's speed, `demand` the driver's torque; one
output, `tau_cmd`, the torque command to the brake. Parameters: `lambda_target` 0.04, the peak;
`k_inc` 20,000 and `k_dec` 40,000 newton-meters per second, how fast the pressure builds and
dumps; `v_min` 1.5 meters per second, below which the ABS switches off. Place the given
`ABSPressureIntegrator` as `pressure`, with `T_track` 0.01. It integrates a pressure rate and
keeps the result between zero and the driver's demand: build is a positive rate, dump a negative
one, hold is zero. That is the modulator slide in one block.

The equations: connect `demand` to `pressure.demand`. The rate: if the slip is past minus
`lambda_target`, dump at `k_dec`, else build at `k_inc`. Active only above `v_min`. Connect
`pressure.tau_cmd` to `tau_cmd`. For part A write `kappa` where the slide says `kappa_pred`. The
whole source is on the guide page.

B, the bench, new. Add Component, `ABSStop`, with a parameter `road_mu`, Real, 1. This ABS
commands brake torque, so the wheel is the library's `BrakedWheel`, from Vehicle, Wheel, named
`wheel`: the same inertia and tire as build 02's wheel, with a brake that follows a torque command
with a 30 millisecond lag in place of the hydraulic ports. Your `Body` as `body`, a rotational
`Fixed` named `fixed`, a translational `VelocitySensor` named `speed`, the `Constant` `road`, and a
`Step` named `demand`, height 6000, start time 0.5: the driver's torque demand. Your `SlipABS` as
`abs`. Wires: `demand.y` into `abs.demand`, `abs.tau_cmd` into `wheel.tau_cmd`, `wheel.kappa` into
`abs.kappa`, `speed.v` into `abs.v`; then `road.y` to `wheel.mu_scale`, `wheel.support` to
`fixed.spline`, and `wheel.flange`, `body.flange` and `speed.flange` together, as in build 02. In
code, five initial lines: build 02's four, and the brake at zero torque,
`wheel.brake.tau_actual = 0`. Run it, `ABSStopTransient`, 6 seconds, Tsit5 with a maximum step of
a millisecond.

Say it plainly: the baseline from build 02 is hydraulic, and this ABS commands the brake torque
directly. The numbers line up because pedal 0.6 puts 6109 newton meters on the wheel, about the
6000 this bench demands, and without the ABS both lock and stop in 43.7 meters. An ABS that drives
valves in the hydraulic circuit is the library's next brake step, issue 92 in the course
repository.

Run A stops in 53.8 meters. Longer than the locked wheel. That is not a mistake in your model. The
law reacts to the slip now, but the brake follows 30 milliseconds later. By then the wheel is past
the 12 percent sliding point, every cycle: a quarter of the stop is spent sliding, and the torque
saws at 2.6 per second between 600 and 4700.

C, the look-ahead. Add parameters `T_p` 0.03 and `T_f` 0.003, three variables, and the three
lines on the slide: a filtered slip rate, and the slip predicted 30 milliseconds ahead. The rate
line now reads `kappa_pred`. Run again: 34.4 meters, 21 percent shorter than locked. The torque
holds at 4300 to 4400, a little above the 4256 of step 01, because the brake also decelerates the
wheel's own inertia. The slip sits at minus 0.04, the peak. Below 1.5 meters per second the ABS
switches off and the wheel locks just before standstill, as a real one does.

C is the library's `ABSIdealController` equation for equation: your 34.4 is the "ABS on the true
slip" row on the braking-distance slide. Where students stall: the code view. If Studio drops the
`pressure` line or reformats the ifelse, paste the full source from the guide's "Fell
behind?" block. Reference: `HandsOn03.SlipABS` and `HandsOn03.ABSStop`.
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

<div class="handson">✓ Build 02 at pedal 0.6: your car is at rest at about 4 s, as the red curve here · build 03 C:
your torque holds just above 4256 N·m instead of cycling below it, because it knows the true slip</div>

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

Compare with your build 03 C. Yours holds the torque almost flat, just above 4256, at 31 Hz: it
reads the true slip. The library controller here sees only the wheel speed and cycles deeper.
After the break you build one that sees only the wheel speed too.
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

<div class="handson">✓ Builds 02–03: your wheel at pedal 0.6 reaches κ = −1 within 0.2 s; your ABS's
slip stays near −0.04</div>

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

Check your neighbor's screen: a locked wheel at minus one, an ABS wheel at minus 0.04. Then the
break, ten minutes. Anyone without a working `ABSStop` pastes the step 03 code from the guide page
before we go on: after the break the next build is a copy of it.
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

<div class="handson">→ Build 04, next: you write this estimator and feed your ABS from the wheel speed alone</div>

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

Budget: 2 minutes. This is the first slide after the break; recap in one sentence where the room
stands: a locked stop and an ABS on the true slip, 43.7 and 34.4 meters.
-->

---
routeAlias: build-wheel-only
---

## Build 04: only the wheel speed

<div class="grid grid-cols-[1fr_1.1fr] gap-8 items-start">
<div>

<svg viewBox="0 0 520 250" class="w-full" role="img" aria-label="State diagram of the three phases. Build, slowly at 8000 N·m/s, goes to dump when the wheel decelerates faster than 12 m/s² or the estimated slip passes 0.2. Dump, at 40000 N·m/s, goes to hold when the wheel accelerates faster than 3 m/s², or back to build once neither dump condition holds. Hold, rate zero, goes to build when the wheel acceleration falls below 3 m/s². Before the first dump the demand passes straight through.">
  <defs>
    <marker id="arr" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
      <path d="M0 0 L10 5 L0 10 z" fill="currentColor"/>
    </marker>
  </defs>
  <g text-anchor="middle" fill="currentColor" style="font-size:15px">
    <text x="18" y="22" text-anchor="start" opacity="0.7" style="font-size:13px">start: demand passes through</text>
    <line x1="78" y1="30" x2="78" y2="58" stroke="currentColor" marker-end="url(#arr)"/>
    <rect x="18" y="60" width="120" height="54" rx="10" fill="#2e8b57" fill-opacity="0.25" stroke="#2e8b57" stroke-width="2"/>
    <text x="78" y="84" font-weight="bold">BUILD</text>
    <text x="78" y="103" style="font-size:13px">+k_inc, slow</text>
    <rect x="382" y="60" width="120" height="54" rx="10" fill="#b22222" fill-opacity="0.25" stroke="#b22222" stroke-width="2"/>
    <text x="442" y="84" font-weight="bold">DUMP</text>
    <text x="442" y="103" style="font-size:13px">−k_dec</text>
    <rect x="200" y="182" width="120" height="54" rx="10" fill="#daa520" fill-opacity="0.25" stroke="#daa520" stroke-width="2"/>
    <text x="260" y="206" font-weight="bold">HOLD</text>
    <text x="260" y="225" style="font-size:13px">rate 0</text>
    <line x1="140" y1="74" x2="380" y2="74" stroke="currentColor" marker-end="url(#arr)"/>
    <text x="260" y="66" style="font-size:13px">a_w &lt; −a_minus  or  kappa &lt; −lambda_1</text>
    <line x1="380" y1="102" x2="140" y2="102" stroke="currentColor" stroke-dasharray="5 4" marker-end="url(#arr)"/>
    <text x="260" y="120" opacity="0.8" style="font-size:13px">no dump condition (dry road)</text>
    <line x1="430" y1="116" x2="322" y2="196" stroke="currentColor" marker-end="url(#arr)"/>
    <text x="432" y="168" style="font-size:13px">a_w &gt; +a_plus</text>
    <line x1="198" y1="196" x2="90" y2="116" stroke="currentColor" marker-end="url(#arr)"/>
    <text x="88" y="168" style="font-size:13px">a_w &lt; +a_plus</text>
  </g>
</svg>

*`RefSpeedEstimator` and `PhaseABS` in code · `ABSStopWheelOnly` = `ABSStop` with `abs` =
`PhaseABS` · `wspeed` on `wheel.spline` → `est.omega` · `est` → `abs` for `kappa`, `a_w`, `v`*

[page: step 04](../lecture/lecture-03/#step-04) · reference `dyad/HandsOn03/PhaseABS.dyad`

</div>
<div>

<div class="text-sm">

```txt
# RefSpeedEstimator: input omega; outputs kappa_hat, v_ref, a_w
v_w = omega * radius
der(v_ref) = ifelse(v_w > v_ref, (v_w - v_ref) / T_up, -a_ref)
kappa_hat = (v_w - v_ref) / max(v_ref, v_eps)
der(v_f) = (v_w - v_f) / T_f        # T_f = 0.005
a_w = (v_w - v_f) / T_f

# PhaseABS: inputs kappa, a_w, v, demand; output tau_cmd
phase = ifelse(a_w > a_plus, 0,
               ifelse(a_w < -a_minus or kappa < -lambda_1, -1, 1))
der(cycled) = ifelse(phase < -0.5, (1 - cycled) / T_latch, 0)
pressure.requested_rate = ifelse(phase < -0.5, -k_dec,
                                 ifelse(phase < 0.5, 0, k_inc))
pressure.active = ifelse(v > v_min and cycled > 0.5, 1.0, 0.0)
```

</div>

**HOLD is the pressure memory:** after a dump the pressure stays just under the level that was
too much, and the next build starts there, not from zero.

</div>
</div>

<!--
The longest build of the day, 25 minutes: an ABS that knows only what a real one knows, the
wheel speed. Two components in code and one bench.

First the estimator, the reference-speed slide as a component. Add Component, `RefSpeedEstimator`,
code view. One input, `omega`, the wheel's angular speed from a sensor. Three outputs: `kappa_hat`
the estimated slip, `v_ref` the estimated car speed, `a_w` the wheel's own acceleration.
Parameters from the guide: radius 0.31, `a_ref` 8, `v0` 25, `T_up` 0.01, `v_eps` 0.5, `T_f`
0.005. The lines: the wheel's surface speed is omega times r. The estimate follows the wheel up
within 10 milliseconds when the wheel is faster, and otherwise falls at `a_ref`. The slip is the
wheel against the estimate. And the wheel's acceleration, filtered over 5 milliseconds, the same
trick as the slip rate in build 03. Two initial lines: `v_ref` and `v_f` start at 25.

Then the controller. Duplicate `SlipABS` and name it `PhaseABS`. Drop the look-ahead and add the
input `a_w`. Parameters: `a_minus` 12, `a_plus` 3, `lambda_1` 0.2, `k_dec` 40,000, `k_inc` 8000,
`v_min` 1.5, `T_latch` 0.001. Two variables, `phase` and `cycled`, with `cycled` starting at zero.

Read the phase line against the state diagram. If the wheel accelerates faster than 3 meters per
second squared, hold: rate zero. If it decelerates faster than 12, or the estimated slip passes
20 percent, dump. Otherwise build, slowly. Why 12: a rolling wheel cannot decelerate faster than
the car, and the car manages at most about 9.8 on a dry road. A wheel decelerating at 12 has gone
past the tire's peak, and the controller needs no estimate of the car's speed to see it. The slip
condition only catches a wheel that is already locked.

`cycled` is a latch. Until the first dump the integrator is inactive and passes the driver's
demand straight through: the fast first build. After it, the builds are slow and start from
where the hold left the pressure. That is the pressure memory of the control-cycle slide, and it
is what the modulator's two valves do: inlet open is build, both shut is hold, outlet open is
dump.

The bench: duplicate `ABSStop`, name it `ABSStopWheelOnly`. Swap `abs` for a `PhaseABS`. Delete
the `wheel.kappa` and `speed.v` wires into `abs`. Place a RotationalComponents `VelocitySensor`
named `wspeed` on `wheel.spline`, and your `RefSpeedEstimator` named `est`. Wire `wspeed.w` to
`est.omega`, and `est.kappa_hat`, `est.a_w`, `est.v_ref` to the three matching inputs of `abs`.
Run 6 seconds, Tsit5.

Why not build 03's controller on the estimate? It was tried: 46.9 meters, longer than locked, at
any `a_ref`. After each dump it rebuilt from almost nothing, and the slip crept up unseen until
the wheel dived. The deceleration trigger and the hold fix both.

Where students stall: two components in 25 minutes. If the room is behind at the halfway mark,
hand out `PhaseABS` from the guide's "Fell behind?" block and let them write only the estimator.
Reference: `HandsOn03.RefSpeedEstimator`, `HandsOn03.PhaseABS`, `HandsOn03.ABSStopWheelOnly`.
-->

---
routeAlias: build-wheel-only-cycle
---

## Build 04 checkpoint: dump, hold, build

<div class="grid grid-cols-[1.3fr_1fr] gap-8 items-start">
<div>

![Two panels from 0.9 to 1.45 s of the wheel-speed-only stop at road mu 0.5. Top, brake torque: the command climbs slowly in the green build phases from about 1800 to 2500 N·m, drops in the short red dump phases, and stays flat in the amber hold phases; the torque at the wheel follows it smoothly between 2000 and 2300 N·m. Bottom, speed: the car falls steadily from 82 to 72 km/h, the wheel runs about 3 km/h below it with small dips, and the estimate rides the wheel. Title: your three-phase ABS, wheel speed only, mu 0.5, 69.8 m.](/img/lecture-03/step04-phase-cycle.svg)

</div>
<div>

```julia
r = MyCar.ABSStopWheelOnlyTransient(road_mu = 0.5,
                                    stop = 10)
plot(r; idxs = [r."abs.phase", r."abs.tau_cmd",
     r."wheel.brake.tau_actual"], layout = (3, 1))
```

<div class="handson">✓ μ 1: <b>35.5 m</b>, shorter than locked (43.7 m) and than the library's
clocked ECU (38.7 m) · μ 0.5: <b>69.8 m</b> against 85.1 m locked, build → dump → hold about 5
times a second, <code>abs.pressure.p</code> flat in every hold</div>

On a dry road the dump ends before the wheel turns round: dump and build only, 10 a second.

</div>
</div>

<!--
Run the dry road first: 35.5 meters. Shorter than your locked wheel, 43.7, and shorter than the
library's wheel-speed-only ECU, 38.7, and only a meter from your true-slip ABS's 34.4. With the
wheel speed alone.

Then the wet road, road_mu 0.5, with a stop time of 10 seconds: 69.8 meters, against 85.1 locked.
Plot the phase and the two torques together. The figure is the reference run, zoomed to half a
second: green build, red dump, amber hold. In every hold the command is flat: that is the pressure
memory. The hold shows on wet and snow, where a dump lets the wheel spin back up past plus 3. On a
dry road it is so short that the wheel only stops decelerating, so the cycle is dump and slow
build, about ten times a second.

One subtlety for the curious. On a dry road `a_ref` 8 is below the car's real deceleration, so
the estimate runs above the car; from about 1.9 seconds the estimated slip passes 0.2 although
the tire is at its peak, and the slip trigger dumps on slip that is not there. It costs about two
meters: `a_ref` 10 gives 33.6. Build 05 comes back to this knob.

Whoever finishes early: a hydraulic version, with inlet and outlet valves in place of the rate
integrator. The library plan for it is `docs/brake-system-implementation-plan.md`, step 3.
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

<div class="handson">✓ Yours: build 02 locked 43.7 m · build 03 on the true slip 34.4 m · build 04 on the
wheel speed only 35.5 m, ahead of the library's 38.7 m</div>

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

Your three builds sit on this table: the locked row, the true-slip row, and your wheel-speed-only
ABS at 35.5 meters, between the true-slip row and the library's. Yours beats the library's clocked
ECU because it dumps on the wheel's deceleration and holds; the library's acts on its slip
estimate. The next slide shows where that difference matters most.
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

<div class="handson">→ Build 05: this table from your own models at μ 1.0, 0.5, 0.3; then μ 0.3 again
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

Real ABS learns the road's deceleration, and some systems add an accelerometer. Adaptive a_ref is
the stretch goal in `docs/abs-controller-spec.md`. Build 05 does the first half of that exercise
by hand: it reruns mu 0.3 with a_ref set to about 0.8 mu g, 2.4, the value an adaptive estimate
would converge to. Making a_ref adapt on its own is left as an exercise. But a small or negative
gain on snow is not only a model artifact: real cars show it too, the next two slides.

And remember the first benefit: even where the distance is no shorter, the ABS wheel still rolls,
and the car can still be steered.
-->

---
routeAlias: abs-measured
---

## Against measured cars

<div class="grid grid-cols-[1.2fr_1fr] gap-6 items-start">
<div class="text-[0.9rem]">

ABS against locked wheels, instrumented tests:

| surface | ABS stop |
|---|---:|
| wet, very slick (Jennite) | 41 % shorter |
| wet asphalt | 11–17 % shorter\* |
| dry concrete | 10–13 % shorter\* |
| packed snow and ice | 0–11 % shorter |
| fresh snow on pavement | about 15 % longer |
| loose gravel | 25–30 % longer |

<div class="text-xs opacity-70">* against the driver's best stop without ABS, not a locked wheel:
the gain over locking is larger</div>

</div>
<div>

**The standard does not ask for a shorter stop.** UN R13-H: the ABS must use at least **75 %** of
the tire's peak friction, $\varepsilon = z_{ABS} / k \ge 0.75$, tested near μ 0.8 and at μ ≤ 0.3.

**Our models.** Dry 11–12 % shorter: in the measured range. On snow the true-slip ABS gains
22–25 %, **more than any car measured**: our snow tire is the dry curve scaled down, peak at 4 %
slip, locked at 70 % of the peak. Real packed snow peaks at 20–40 % slip and keeps 85–100 % when
locked.

<div class="handson">✓ Yours on the wheel speed alone: ε ≈ 0.81–0.83 on every road, above the
0.75 line</div>

</div>
</div>

<!--
Budget: 1.5 minutes. Read the table top to bottom: the slicker and the more solid the road, the
more ABS gains; on loose surfaces it loses.

Sources, all in `docs/abs-efficiency-research.md` with the full citations:
- wet Jennite, packed snow and ice 11 %, gravel 25 %: the 1969 Chrysler four-wheel ABS against
  fully locked wheels, quoted by Clemett and Moules (Ford), Highway Research Record 477, 1973.
- dry concrete 10–13 %, wet asphalt 11–17 %, loose gravel 25–30 % longer: NHTSA, Forkenbrock,
  Flick and Garrott, SAE 1999-01-1287, nine production cars of the 1990s. On paved surfaces the
  baseline was the driver's best modulated stop, because locked stops wore the tires out; on gravel
  it was full-pedal locked.
- packed snow and ice 0 %: Strandberg, VTI/VETA 1995, Volvo 850 with 66 ordinary drivers: ABS won
  on average in all 24 tire-surface combinations, but many single locked runs on loose snow beat
  it.
- fresh snow about 15 % longer: Sokolovskij and Pečeliūnas, 2007, 3.0 against 2.6 m/s². Two
  different cars, so read it as a direction, not a number. SAE 940724 (Eddie, 1994) reports the
  same for fresh snow on pavement just below freezing; only its abstract was available.

UN Regulation 13-H, Annex 6: epsilon is the deceleration with ABS cycling, between 45 and 15
km/h, divided by the best deceleration without locking a wheel. So the yardstick is the peak of
the curve, not the locked wheel. Our tire locks at 0.7 of its peak, just under the line, which is
why a locked wheel fails it and an ABS that barely beats locking can still pass.

The epsilon on the cue is a rough one, the ideal distance v squared over 2 g mu divided by the
measured distance. It counts the first tenth of a second before the brake builds, which pulls it
down, and credits drag to the brakes, which pushes it up.

Our snow tire: Ichihara and Mizoguchi, HRB Special Report 115, 1970, measured the peak on
compacted snow at 20 to 40 percent slip and found the locked value only a little below it. A
variable-slip tester (Fleege, Wambold and Rado, TRB 1996) puts the winter peak near 30 percent,
against 18 percent dry. A Dyad run with a snow-shaped tire, locked at 0.9 to 0.95 of the peak,
shortens the locked stop to 103–109 meters, and our wheel-speed ABS then stops 5 to 8 percent
longer than locked: the real fresh-snow result, for the real reason.
-->

---
routeAlias: abs-loses
---

## Why ABS can stop longer

<div class="grid grid-cols-2 gap-8 text-[0.95rem]">
<div>

**A wedge ahead of the tire.** On gravel and loose snow a locked tire plows the surface into a
wedge in front of it and digs down to firmer ground. A rolling ABS tire rides on top.

**No peak to find.** On packed snow and ice the curve is flat: the locked tire keeps nearly all of
the peak. *"In the absence of a distinct peak at low slip … no improvement over locked-wheel
stopping distance can be expected"* (Ford, 1973).

</div>
<div>

**The cycle costs grip.** Every dump drops the pressure below the lock level. On ice a real ABS
dumps almost to zero, four to six times a second. Rates tuned for a dry road dump too deep on
snow: **yours does**.

**A wrong speed guess.** With $a_{ref}$ too high the slip is under-read and the wheel slides;
too low and the ECU dumps on slip that is not there.

</div>
</div>

<div class="mt-6">

What ABS never loses: **the wheel keeps rolling, so the car still steers**. That is why it stays on
in snow even where the stop is longer.

</div>

<!--
Budget: 1.5 minutes. Four reasons, two from the road, two from the controller.

The wedge: the RACV review (Burton et al., Monash, 2004) and Strandberg's ice and snow tests; the
locked tire on loose snow "digs itself down" to a layer with more grip. NHTSA measured 25 to 30
percent longer stops with ABS on loose gravel.

No peak: the quotation is Clemett and Moules, Ford, Highway Research Record 477, 1973. ABS earns
its gain from the drop between the peak and the sliding value. Where the curve has no drop, there
is nothing to earn, only the cycle to pay for.

The cycle: Day and Roberts, SAE 2002-01-0559, from Bosch test data: on ice the wheel pressure
swings between about 5 and 35 bar, four to six cycles a second. Your PhaseABS has build and dump
rates in bar per second set for the dry lock pressure, 62 bar. On snow the lock pressure is about
19 bar, and one 30-millisecond valve lag at the dump rate already takes 17 bar. Scaling the rates
and thresholds by the road, 0.3, takes your snow stop from about 131 to 113 meters. Production
ECUs learn the lock pressure and rebuild from it.

The speed guess: the reference-speed slide and build 05.

-->

---
routeAlias: build-surfaces
---

## Build 05: across road surfaces

<div class="grid grid-cols-[1fr_1.25fr] gap-8 items-start">
<div>

<div class="text-sm">

```julia
using VehicleSystemsComponents: Vehicle
stop(μ; a = Inf) = 0.5 + 1.5 * 25 / min(0.7μ * 9.81, a) + 1
d(run) = round(Vehicle.braking_distance(run); digits = 1)
for μ in (1.0, 0.5, 0.3)
    println(μ, "  ",
        d(MyCar.PedalStopTransient(road_mu = μ, stop = stop(μ))), "  ",
        d(MyCar.ABSStopTransient(road_mu = μ, stop = stop(μ))), "  ",
        d(MyCar.ABSStopWheelOnlyTransient(road_mu = μ,
                                          stop = stop(μ; a = 8))))
end
```

</div>

*One table from the REPL · then μ 0.3 with `a_ref = 0.8 μ g ≈ 2.4`, and the same `a_ref` on a
dry road*

[page: step 05](../lecture/lecture-03/#step-05)

</div>
<div>

![Grouped bars of braking distance from 90 km/h at road mu 1.0, 0.5 and 0.3. Locked: 43.7, 85.1, 136.8 m. ABS on true slip: 34.4, 63.4, 102.2 m. ABS on wheel speed only, yours: 35.5, 69.8, 119.6 m. ABS on wheel speed only, the library's clocked ECU: 38.7, 83.2, 141.3 m, the last longer than locked.](/img/lecture-03/step05-surfaces.svg)

<div class="handson">✓ Both your ABS columns beat locked everywhere · on snow the library ECU loses,
<b>141.3 vs 136.8 m</b> · yours with <code>a_ref = 2.4</code>: <b>124.1 m</b> on snow, <i>longer</i> than
at 8, and <b>105.4 m</b> on a dry road</div>

</div>
</div>

<!--
The last build: no new blocks, a table. Seven minutes.

Open the REPL and paste the loop from the guide page. It runs your three benches at road factor
1, 0.5 and 0.3, each long enough for the car to stop: the stop-time rule gives about 20 seconds
on snow. Read the table against the bars. The first column is your build 02 bench at its default
pedal, 0.6. It must match the previous slide's locked column within a tenth of a meter, 43.7,
85.1, 136.8, and your true-slip column its ideal-ABS column to the decimal, 34.4, 63.4, 102.2.
Your wheel-speed-only column: 35.5, 69.8, 119.6. All under locked.

The fourth column is the library's clocked ECU, `Vehicle.ABSBrakeTransient`, from the previous
slide. On snow it loses to the locked wheel, 141.3 against 136.8. That is the trap: `a_ref` 8 is
almost three times what mu 0.3 allows, 2.9, so its estimate falls too fast, it under-reads the
slip and lets the wheel slide. Your `PhaseABS` does not fall into it: it dumps on the wheel's own
deceleration, which needs no estimate of the car's speed.

Then the rerun. `MyCar.ABSStopWheelOnlyTransient(road_mu = 0.3, a_ref = 2.4, stop = 25)`, and the
same `a_ref` at road_mu 1. On snow: 124.1 meters, longer than at 8. On a dry road: 105.4. The
other side of the same knob: an `a_ref` below the car's real deceleration lets the estimate run
above the car, the estimated slip passes 0.2 although the tire is at its peak, and your
controller dumps on slip that is not there. The library ECU with 2.4 on snow: 128.4 meters.

The sentence to take away: an ABS can only be as good as its guess of the car's speed, so a
wheel-speed-only ECU leans on the wheel's deceleration and uses the guess only to catch a locked
wheel.
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
- On your car: 43.7 m locked, 34.4 m on the true slip, 35.5 m on the wheel speed alone, by
  dumping on the wheel's deceleration and **holding** the pressure.

### Next: the same idea for a wheel that is driven, not braked. <Link to="tcs">→ 04, traction control</Link>

<!--
ABS controls slip on the braking side of the curve. The driving side has the same peak and the
same runaway: you saw it at the end of Lecture 1.

Then a 5-minute break. The building is done for today; after the break come traction control,
with one bonus task to take home, and the ESP demo.
-->
