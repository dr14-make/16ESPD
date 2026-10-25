---
routeAlias: tcs
layout: section
---

###### Section 04

# Traction control

ABS turned around: keep a **driven** wheel from spinning, with the brakes and the engine.

<!--
Budget: 6 minutes, 6 slides, after the short break: what 1.5, actuators 1.5, Lecture 1 link 1,
take-home bonus 1, summary 1.

Traction control, TCS, or ASR in Bosch's and the German makers' naming, from
Antriebsschlupfregelung, drive slip control. It is the positive side of the friction curve.
-->

---
routeAlias: what-tcs-does
---

## What traction control does

<div class="grid grid-cols-[1fr_1fr] gap-8">
<div>

TCS keeps the driven wheels from **spinning** when driving off or accelerating, so they stay near
the friction peak on the **positive** side of the curve.

- **more traction**: on a slippery road, the wheel transmits more force near the peak than
  spinning;
- **stability**: a spinning rear wheel has no lateral grip left, and the tail steps out;
- **within the limits of physics**: it cannot create grip.

It uses the ABS hardware: the same wheel-speed sensors, and the same modulator to brake a wheel.

</div>
<div>

![The Bosch evolution of driving-safety systems drawn as nested ellipses: ABS inside ASR/TCS inside ESP/ESC.](/pptx/slide19-abs-tcs-esp.jpg)

<div class="caption">Each system contains the one before it</div>

</div>
</div>

<!--
The source deck: TCS ensures that the wheels do not spin when driving off or accelerating; to do
this, the drive torque at each driven wheel is reduced; it improves traction and safety by
avoiding unstable driving situations within the limits of physics.

The sensors are the ABS wheel-speed sensors. The driven wheels are compared with the undriven
ones, which roll freely and so give the car's speed directly: an easier estimation problem than
ABS has. On an all-wheel-drive car there is no free-rolling wheel, and the car's speed again has
to be estimated.

Bosch introduced TCS in 1986, on top of ABS. By 1990 five Bosch ASR variants were in production,
some acting only on the engine, two combining brake and throttle, per SAE paper 900204.
-->

---
routeAlias: differential-film
---

## Around the corner: why a car needs a differential

<div class="flex justify-center mt-4">
<Youtube id="yYAw79386WI" width="740" height="416" />
</div>

<div class="caption">"Around the Corner", Jam Handy Organization for Chevrolet, 1937; public domain in the US,
via the <a href="https://archive.org/details/Aroundth1937">Prelinger Archives</a></div>

<!--
Play from the start; the whole film is about 9.5 minutes, so stop once the spider gears have been
shown, or play it all if there is time. It answers the speed half of the next slide: in a bend
the outer wheel turns faster, a solid axle would scrub one tire, and the bevel gears in the
carrier let the two wheels turn at different speeds with the carrier at their mean. The next slide
adds what the film leaves out, the torque: a differential that frees the speeds must split the
torque equally.

The embed needs internet in the room. The link above is the Internet Archive original; the video
embedded here is a YouTube re-upload, https://www.youtube.com/watch?v=yYAw79386WI. Wikimedia
Commons lists the film as public domain in the US: published 1929 to 1963 without a copyright
renewal.
-->

---
routeAlias: open-differential
---

## The open differential

<div class="grid grid-cols-[1fr_1fr] gap-6">
<div>

![Top view of a driven axle. The engine and gearbox feed torque T_in into an open differential, drawn as a carrier with four bevel gears. Two side shafts carry T_L equal to T_in over 2 to the left wheel, on ice with mu 0.1, and T_R equal to T_in over 2 to the right wheel, on dry road with mu 1.0. A red TCS brake T_b sits on the left wheel. The wheel speeds obey omega_L plus omega_R equals twice the carrier speed.](/diagrams/04-open-differential.svg)

</div>
<div>

It lets the wheels turn at **different speeds** in a bend, and so it splits the **torque
equally**:

$$
T_L = T_R = \tfrac12 T_{in}, \qquad \omega_L + \omega_R = 2\,\omega_{carrier}
$$

So the wheel with **less grip sets the torque of both**. With $F_z = 4$ kN, $r = 0.31$ m:

<div class="text-sm">

| N·m | left, ice | right, dry | force |
|---|---:|---:|---:|
| no TCS | 124, spins | 124 | **0.8 kN** |
| $T_b = 600$ | 724 − 600 | 724 | **2.7 kN** |

</div>

The brake stands in for the grip the ice lacks: a **brake-based differential lock**.

</div>
</div>

<!--
Budget: 1.5 minutes. The equal split first, then the table, then why it is only a low-speed trick.

Symbols: T in is the torque from the gearbox into the differential, T L and T R the torques in the
left and right side shafts, all in newton meters. Omega L and omega R are the wheel speeds and
omega carrier the speed of the differential's housing, in radians per second. F z is each wheel's
normal load, 4000 newtons; T b the TCS brake torque on the left wheel.

Why a differential at all: in a bend the outer wheel travels farther, so the two driven wheels
must turn at different speeds. The open differential allows it: the carrier turns at the mean of
the two wheel speeds. The price is in the torque. The small bevel gears in the carrier are a
balance beam, and a balance beam pushes equally on both ends. So both wheels always get the same
torque, and that torque can be no larger than the wheel with less grip can carry. On ice the
left wheel can carry 0.1 times 4000 newtons times 0.31 meters, 124 newton meters; the right wheel
gets the same 124, whatever its grip, and the car pulls with 800 newtons. The engine has nowhere
to put more torque: the left wheel just spins up. That is the classic car stuck with one wheel on
ice.

Brake the spinning wheel with 600 newton meters. The differential still splits equally, but now
the left side resists with its brake plus the ice, 724 newton meters, so the differential can pass
724 to each side. The table's "724 − 600" is that left shaft: 724 arrive, the brake takes 600 and
only 124 reach the ice. The force column is the drive force on the road, the two tire torques
added and divided by the wheel radius. The right wheel puts its 724 into the dry road, and the drive force is 124 plus
724 over 0.31, 2.7 kilonewtons, more than three times as much. The engine must now supply 1448
newton meters at the axle in total, 1200 more than the 248 without TCS, and the 600 at the brake
become heat: at 20 kilometers per hour
that is about 11 kilowatts in one brake disc. That is why brake-based TCS is a drive-off aid: a
Bosch patent switches it off above about 40 kilometers per hour (US 4,971,400; in
docs/esp-tcs-plausibility-research.md). Above that, and whenever both wheels spin, only cutting the
engine torque helps; braking both wheels would just fight the engine.

A mechanical limited-slip or locking differential does the same job without the heat; the brake
version is cheaper because the hardware is already in the car.

The take-home bonus has a single wheel and no differential, so braking there just takes torque
off that wheel, like an engine cut. The differential effect needs two driven wheels.
-->

---
routeAlias: tcs-actuators
---

## Two actuators: the brake and the engine

<div class="grid grid-cols-[1fr_1fr] gap-8">
<div>

### Brake one wheel

When **one** driven wheel spins (one side on ice), brake it. Through an open differential the
torque on that wheel **is passed to the other**, the one with grip.

- fast: tens of milliseconds;
- costs heat, so not for long;
- needs to **build** pressure without the driver: an extra valve and the pump.

</div>
<div>

### Reduce engine torque

When **both** driven wheels spin, reduce the torque at the source:

- close the throttle (electronic throttle, Lecture 2);
- retard the spark, cut injection to single cylinders: faster;
- in an EV: command the motor, milliseconds.

The driver may feel the accelerator pedal pulse.

</div>
</div>

<!--
The source deck said TCS "pumps" the brake on the spinning wheel and that some systems also
reduce engine power.

The brake side is the previous slide: braking the spinning wheel lets the open differential pass
more torque to the wheel with grip.

To brake without the driver pressing the pedal, the modulator needs to build pressure on its own.
An ABS-only unit cannot: its pump only returns fluid. A TCS or ESP unit adds a switchover valve and
a high-pressure suction valve per circuit, so the pump can draw fluid from the reservoir and
pressurize a wheel.

The engine side, from Lecture 2: the electronic throttle closes, which is slow because the
manifold has to empty; spark retard reduces torque within a combustion cycle; cutting injection
to some cylinders is the fastest and coarsest. Which ones a particular system uses differs; I found
no primary source listing them for a given product. An electric motor responds in milliseconds,
which makes traction control on EVs much tighter.
-->

---
routeAlias: tcs-and-lecture-1
---

## You have seen this already

<div class="grid grid-cols-[1fr_1.3fr] gap-8">
<div>

Lecture 1's cruise controller on ice: the controller asked for more torque, the wheel spun up,
the force fell.

A **friction-aware torque limit** kept the wheel near the car's speed and **lost less speed**
while asking for a fifth of the torque.

A TCS does this properly: a **slip loop inside the speed loop**, limiting the torque to what the
road can carry **now**.

<div class="handson">→ Take-home bonus, next: a brake-based TCS on your <code>SlipCar</code></div>

</div>
<div>

![The ice-patch run overlaid with a friction-aware torque limit: the wheel stays near vehicle speed and the slip ratio stays on the near side of the peak, while speed dips and recovers.](/figures/10-ice-patch-limited.svg)

<div class="caption">Lecture 1, section 10: a fixed torque cap on the ice patch</div>

</div>
</div>

<!--
This is Lecture 1's last figure. A constant torque cap set from the ice's friction kept the wheel
from running away. But a constant cap does not know the grip: it also capped the car on dry road.

TCS replaces the constant cap with a slip controller: when the driven wheel's slip passes a
threshold, it takes torque away, by brake or engine, until the slip comes back. That is the inner
loop of the cascade Lecture 1 ended with. And real cruise controls disengage when traction control
intervenes, because the two act on the same engine torque.

In the repository the pieces exist: `SlipWheel1D`, `TireFrictionCurve` and the slip estimate the
ABS uses. A traction controller on the slipping car is a natural exercise: the same modulator
logic with the signs reversed. The next slide makes it your take-home bonus.
-->

---
routeAlias: bonus-tcs
---

## Take home: traction control on your `SlipCar`

<div class="grid grid-cols-[1.2fr_1fr] gap-8 items-start">
<div>

Hands-on 1's `SlipCar` on snow (`mu_scale = 0.2`), full torque from rest. Without TCS the wheel
spins up as in Lecture 1; with a brake-based TCS it holds near the peak, and the car is faster
after 10 s.

*`TCSSlipCar`: your `SlipCar` with a `Vehicle.Wheel.BrakeActuator` between `wheel_inertia` and
`wheel`, its support on `rot_ground`, a `tau_tcs` input · `TCS`: build 03's law turned round,
pressure builds while `kappa_pred > lambda_target`, clipped to [0, `tau_tcs_max`]*

**Given:** `BrakeActuator`, a brake with a 30 ms lag · `ABSPressureIntegrator`

The brake torque is commanded directly; a real car builds that pressure with the ABS pump, through
the switchover and high-pressure valves.

[page: step 06](../lecture/lecture-03/#step-06)

</div>
<div>

> **Hand in, for extra points**, as a pull request from your `lecture-03` branch
>
> - wheel slip and car speed over 10 s, with and without TCS; by hand, the traction limit is
>   0.2 × 6865 N = **1373 N** at the peak against **961 N** spinning, about **8.5 against
>   5.7 m/s** after 10 s
> - one paragraph: why a production TCS cuts engine torque when both driven wheels spin, what
>   `SlipCar`'s 0.3 s engine delay would do to that loop, and why the brake works on one wheel
>   only through an open differential

</div>
</div>

<!--
Budget: 1 minute. Not built in the room: a bonus task for home, for extra points.

The parts are all ones you have now: your `SlipCar` from hands-on 1, the given `BrakeActuator`
and `ABSPressureIntegrator`, and your `SlipABS` from build 03, with the sign of the slip turned
round. The guide page has the task, the parts and the advice, not the diagram.

The reference solution is kept off main, on branch feat/handson03-tcs-bonus (not built yet), as
the hands-on 2 WLTC bonus was. The hand numbers on the slide: 6865 newtons is the normal load on
the driven wheel, half the weight of the 1400 kilogram car. Times the snow factor 0.2 and the
peak 1.0 it gives 1373 newtons of traction; spinning, at the sliding 0.7, 961. The 8.5 and 5.7
meters per second are hand estimates: net of resistance, about 0.85 against 0.57 meters per
second squared, over 10 seconds.
-->

---

## Summary of section 04

- TCS keeps the **driven** wheels near the friction peak on the positive side of the curve.
- It **brakes** a single spinning wheel, which the open differential turns into torque for the
  other, and **reduces engine torque** when both spin.
- The undriven wheels give the car's speed, if there are any.
- It is the slip loop Lecture 1 asked for on the ice patch.

### Next: controlling the car's rotation, not only its wheels. <Link to="esp">→ 05, electronic stability program</Link>

<!--
ABS and TCS both keep each wheel on its curve. Neither knows whether the car as a whole goes where
the driver steers. That is ESP.
-->
