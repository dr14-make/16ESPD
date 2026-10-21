---
routeAlias: esp
layout: section
---

###### Section 05

# Electronic stability program

Compare where the driver steers with where the car goes, and brake single wheels to close the
gap.

<!--
ESP is Bosch's and Mercedes' name; the generic name is ESC, electronic stability control, which is
what the regulations use. Others call it VSC, DSC, VDC or StabiliTrak. Same function.
-->

---
routeAlias: what-esp-does
---

## What ESP does

<div class="grid grid-cols-[1fr_1fr] gap-8">
<div>

ESP helps the driver keep control when the car starts to **skid**: it keeps the car on the
trajectory the driver asks for, within the limits of grip.

- built on ABS and TCS, plus **three sensors**: steering angle, yaw rate, lateral acceleration;
- compares the **driver's intention** with the **car's motion** many times a second (Bosch: 25);
- corrects by **braking single wheels** and by **reducing engine torque**.

</div>
<div>

| | |
|---|---|
| 1984 | Bosch starts development |
| 1995 | first in series production: Mercedes-Benz S-Class coupé, Bosch team led by **Anton van Zanten** |
| 1997 | Mercedes A-Class rolls over in a Swedish magazine's evasive "elk test"; ESP made standard on it |
| 2011 | US: required on all new light vehicles (FMVSS 126, from Sept. 2011) |
| 2014 | EU: required on all new cars (from Nov. 2014; new types from Nov. 2011) |

</div>
</div>

<!--
The source deck called it dynamic trajectory control: ESP assists the driver to retain control of
the vehicle in the event of a loss of grip, and its aim is to maintain the trajectory.

The history, from Bosch's press archive: development began in 1984, a joint Bosch and Daimler-Benz
team formed in 1992, and ESP was shown on the S-Class coupé in May 1995, in the showroom that
September. Anton van Zanten led the 35-person team and received the European Inventor Award for
it in 2016. The paper that introduced it is van Zanten, Erhardt and Pfaff, "VDC, the Vehicle
Dynamics Control System of Bosch", SAE 950759.

The elk test: in 1997 a Swedish magazine rolled the brand-new A-Class in a lane-change test.
Mercedes stopped deliveries, fitted ESP as standard, and that made ESP a mass-market system.

The source deck said ESP "analyses the data of seven sensors". Counted per type there are five:
wheel speed, steering angle, yaw rate, lateral acceleration and the master-cylinder pressure
sensor; counted per device, four wheel-speed sensors plus the others make more than seven.
-->

---
routeAlias: esp-sensors
---

## Sensors: intention and motion

<div class="grid grid-cols-[1.2fr_1fr] gap-6">
<div>

![ESP components on a car's plan view: hydraulic links in purple to the four wheel brakes, electric links in green; a sensor combining lateral acceleration and yaw rate, a steering-wheel angle sensor, a disconnection switch, and engine torque management.](/pptx/slide16-esp-components.png)

</div>
<div>

**Driver's intention** (desired state):

- **steering-wheel angle**
- vehicle speed, from the wheel-speed sensors
- brake pressure, accelerator pedal

**Car's motion** (actual state):

- **yaw rate** $\dot\psi$: rotation about the vertical axis
- **lateral acceleration** $a_y$
- wheel speeds

<div class="stack">

![A yaw-rate sensor: a small black plastic housing with a connector.](/pptx/slide17-yaw-rate-sensor.jpg)

</div>

</div>
</div>

<!--
The source deck's sensor slide. The steering-angle sensor measures the steering wheel's position.
From that angle, the vehicle speed, and the brake pressure or accelerator position, the ECU
computes what the driver wants: the desired state. The yaw-rate sensor, combined in one housing
with a lateral accelerometer and mounted near the car's center of gravity, measures what the car
actually does: the actual state.

The source deck called the yaw-rate sensor a gyrometer, which is fair: it is a vibrating
micromechanical gyroscope. Bosch's micromechanical yaw-rate sensor arrived in 1998; the first ESP
used a different design.

The figure is from the source deck, a Renault diagram. Item 3 there is a switch to disable the
system, which regulations allow only under conditions.
-->

---
routeAlias: ackermann
---

## Steering geometry: Ackermann

<div class="grid grid-cols-[1.1fr_1fr] gap-8">
<div>

![A car in a left turn, top view: lines from one turn center O on the extended rear-axle line run to each front wheel; each wheel stands at right angles to its line, so the inner front wheel is steered by a larger angle delta i than the outer one, delta o. L is the wheelbase, t the track, R the turn radius.](/diagrams/05-ackermann.svg)

</div>
<div>

In a slow turn every wheel rolls about **one center** on the rear-axle line, so the **inner**
front wheel steers more:

$$
\cot\delta_o - \cot\delta_i \;=\; \frac{t}{L}
$$

$L = 2.7$ m, $t = 1.55$ m, $R = 10$ m to the rear-axle center:

| | |
|---|---:|
| inner, $\arctan\frac{L}{R - t/2}$ | 16.3° |
| outer, $\arctan\frac{L}{R + t/2}$ | 14.1° |
| single-track, $\arctan\frac{L}{R}$ | 15.1° |

- without it the front tires **scrub** at parking speed;
- at speed **slip angles** dominate: cars use partial Ackermann;
- the single-track model's one front wheel takes the **mean** angle: the $\delta$ of the
  reference yaw rate.

</div>
</div>

<!--
The reference model on the next slide has one front wheel. A real car has two, and they do not
steer by the same angle. This slide is where the two become one.

Ackermann geometry: at low speed the tires make almost no lateral force, so each wheel rolls in
the direction it points. For all four to roll without sliding sideways, their axes must meet in
one point, the turn center. The rear wheels are not steered, so that point lies on the extended
rear axle. The inner front wheel is closer to it and must steer more. Subtract the two cotangents
and R drops out: cot delta o minus cot delta i equals track over wheelbase, at every radius.

The worked example, a mid-size car on a 10 meter turn, radius measured to the middle of the rear
axle. Inner wheel arctan of 2.7 over 9.225: 16.3 degrees. Outer wheel arctan of 2.7 over 10.775:
14.1 degrees. Check: 3.991 minus 3.417 is 0.574, and 1.55 over 2.7 is 0.574. The difference is
over 2 degrees, and the single lumped wheel, 15.1 degrees, sits within a tenth of a degree of the
mean, 15.2. Gillespie writes the same with small angles: delta o about L over R plus t over 2,
delta i about L over R minus t over 2, and the mean delta about L over R.

Why it matters: with parallel steering the two front tires fight each other at parking speed,
they scrub and wear, and the steering feels heavy. At speed every tire runs at a slip angle, the
turn center moves forward of the rear axle, and the more loaded outer tire wants the larger slip
angle. So real cars use only part of the Ackermann difference, and racing cars sometimes none or
the reverse. The steering linkage only approximates the formula anyway: the steering arms are
angled so that, straight ahead, their extensions meet near the middle of the rear axle.

For the model: the planned planar car steers its two front wheels with Ackermann geometry. The
ESP reference yaw rate comes from the single-track model, which needs one angle, the mean of the
two. At low speed that model gives yaw rate v over R, which is v delta over L.

History: Georg Lankensperger in Munich, 1816; Rudolph Ackermann patented it for him in England in
1818. Sources: T. D. Gillespie, Fundamentals of Vehicle Dynamics, SAE 1992, chapter 6, low-speed
turning; W. F. and D. L. Milliken, Race Car Vehicle Dynamics, SAE 1995, chapter on steering
systems, for partial and reverse Ackermann; Rajamani, chapter 2, for the kinematic single-track
model. Cited from the books as I know them; the chapter numbers were not rechecked online.
-->

---
routeAlias: reference-model
---

## The reference model

<div class="grid grid-cols-[1fr_1.1fr] gap-8">
<div>

![The single-track model: the two front wheels lumped into one, steered by delta, and the two rear wheels into one, at distances l_f and l_r from the center of gravity; the velocity v at the center of gravity makes the sideslip angle beta with the car's axis; psi-dot is the yaw rate.](/diagrams/05-single-track.svg)

</div>
<div>

The yaw rate the driver asks for, from the **single-track** model in steady state:

$$
\dot\psi_{ref} \;=\; \frac{v}{L + K_{us}\,v^2}\;\delta
$$

$L$ wheelbase, $\delta$ road-wheel steer angle, $K_{us}$ the understeer gradient.

But the road can only give $a_y = v\,\dot\psi \le \mu g$:

$$
|\dot\psi_{ref}| \;\le\; \frac{\mu\,g}{v}
$$

ESP acts on the error $\dot\psi_{ref} - \dot\psi$, and on the sideslip angle $\beta$.

</div>
</div>

<!--
The source deck said ESP compares the sensor data with a reference model of the vehicle's behavior
stored in its memory. This is that reference model, in its textbook form.

The single-track or bicycle model lumps each axle into one wheel. In a steady turn at low speed,
the car turns at v times delta over L: pure geometry. At higher speed the tires need slip angles
to make lateral force, and a normally understeering car turns less than the geometry says. The
understeer gradient K us captures that; it is positive for an understeering car, and car makers
design every car to understeer mildly.

The second line is the friction limit: lateral acceleration in a steady turn is speed times yaw
rate, and it cannot exceed mu g. So the desired yaw rate is clipped; textbooks such as Rajamani's
Vehicle Dynamics and Control, chapter 8, put a margin of about 0.85 on it. I took the 0.85 factor
from memory and could not check it online.

The sideslip angle beta, the angle between where the car points and where it moves, is not
measured. It is estimated from lateral acceleration, yaw rate and speed, and ESP keeps it small,
because a driver cannot catch a car whose sideslip has grown large.
-->

---
routeAlias: yaw-correction
---

## Braking one wheel to steer the car

![Two cars in a left-hand bend, top view. Understeer: the car goes straighter than the driver wants; braking the inner rear wheel makes a yaw moment that turns the car in. Oversteer: the tail steps out and the car turns more than wanted; braking the outer front wheel makes a yaw moment that holds it back.](/diagrams/05-esp-yaw-correction.svg)

<!--
This is how ESP acts. A braking force at one wheel, off the car's center line, makes a yaw moment
about the center of gravity: brake force times half the track width.

Understeer, left: the car turns less than the driver asks, the front tires have run out of grip,
and the nose pushes wide. ESP brakes the inner rear wheel. That pulls the car round into the bend,
and slowing the car also helps the front tires.

Oversteer, right: the rear tires have run out of grip and the tail steps out; the car turns more
than the driver asks. ESP brakes the outer front wheel. That makes a moment against the rotation,
and the front tire, braked, also takes some lateral force away from the front, which calms the
rotation further.

In practice ESP often brakes more than one wheel, and always reduces engine torque. The choice of
wheel above is the textbook rule, as in Bosch's Automotive Mechatronics handbook; I did not find it
on a Bosch web page.

This is also why ESP needs the extra valves from the TCS slide: the driver is not braking, so the
modulator must build pressure at one wheel on its own.
-->

---
routeAlias: esp-examples
---

## Examples

<div class="grid grid-cols-2 gap-6">
<div>

![Understeer: a car without ESP runs wide off the outside of the bend; beside it, a car with ESP braking its inner rear wheel to stay on the road.](/pptx/slide19-understeer.png)

</div>
<div>

![Oversteer: a car without ESP spins out of the bend; beside it, a car with ESP braking its outer front wheel to stay on the road.](/pptx/slide19-oversteer.png)

</div>
</div>

<!--
The source deck's two Renault illustrations of the same two cases. In each, the car on the left
without ESP leaves the road: wide on understeer, spinning on oversteer. On the right the braked
wheel is marked.

The source deck also had a video of an ESP demonstration; it is not reproduced here.

The source deck's description of the logic, for reference: the ECU determines the car's speed
from the wheel-speed sensors, checks that the difference in speed between the left and right
wheels matches the bend, and refines the picture with the yaw-rate sensor and the lateral
accelerometer. Any discrepancy between the real trajectory and the one the driver wants makes it
brake one or more wheels; if that is not enough, it reduces engine torque. Bosch's own description
puts the engine torque reduction first.
-->

---
routeAlias: esp-evidence
---

## Does it work?

<div class="grid grid-cols-[1fr_1fr] gap-8">
<div>

**NHTSA**, US crash data:

| reduction with ESC | cars | SUVs |
|---|---:|---:|
| single-vehicle crashes | 34 % | 59 % |
| single-vehicle rollovers | 71 % | 84 % |

A 2014 NHTSA follow-up: fatal single-vehicle crashes −31 % for cars, −45 % for light trucks and
vans.

</div>
<div>

**The test**, FMVSS 126 and UN R140: a **sine-with-dwell** steering input at 0.7 Hz with a 500 ms
dwell, from 80 km/h.

- yaw rate **≤ 35 %** of its peak 1.0 s after the steering ends;
- **≤ 20 %** after 1.75 s;
- lateral displacement **≥ 1.83 m** 1.07 s after the steering starts.

The car must stop rotating, and still have turned.

</div>
</div>

<!--
The left table is from NHTSA's final rule for FMVSS 126, 2007, which cites its own crash-data
studies; the follow-up is Kahane, DOT HS 812 020, 2014.

The right column is the test every new light vehicle in the US must pass, and that UN Regulation
140 uses for Europe. The steering robot turns the wheel in a sine, holds it at its second peak for
half a second, and returns to center. The yaw rate must then die out: no more than 35 percent of
its peak after one second, 20 percent after 1.75 seconds. That is the oversteer criterion: the
car must not spin. The displacement criterion, 1.83 meters for cars up to 3500 kilograms, makes
sure the car did not pass by simply refusing to turn.

Sources: 49 CFR 571.126, read through the Cornell LII mirror; NHTSA final rule, 72 FR 17236; the
EU dates from Regulation (EC) 661/2009 as applied by 407/2011. I read the R140 criteria only
through FMVSS 126, which R140 is derived from.
-->

---
routeAlias: esp-model
---

## What a model of ESP needs

<div class="grid grid-cols-[1fr_1fr] gap-8">
<div>

The ABS model is **one lumped wheel on a straight line**. It has no lateral force, no steering
and no yaw: ESP cannot be shown on it.

The plan in `docs/lecture-03-preparation.md`: a **planar four-wheel car**

- chassis mass and yaw inertia, wheelbase and track;
- four wheels, each with its own speed and brake;
- front steering with Ackermann geometry;
- **combined slip**: longitudinal and lateral force share one friction limit.

</div>
<div>

Then, in order:

1. four-channel ABS: brake in a turn, with and without ABS;
2. a reference yaw rate from steering angle and speed;
3. a yaw-moment controller;
4. selective wheel braking;
5. understeer and oversteer manoeuvres.

Each step is validated before the next.

</div>
</div>

<!--
An honest boundary. The ESP slides are theory only; the repository cannot simulate them yet.

The preparation document proposes building the car from MultibodyComponents' PlanarMechanics: its
slip-based wheel joint already has longitudinal and lateral slip and a combined friction limit.
The first result it targets is the one from section 01: a locked front wheel loses its lateral
force, and the car stops following the steering. With ABS the tires stay near the peak and keep
turning the car.

Only after that does ESP come: the reference model from two slides back, a controller on the yaw
rate error, and the wheel choice from the understeer and oversteer slide.
-->

---

## Summary of section 05

- ESP compares the **driver's intention** (steering angle, speed) with the **car's motion** (yaw
  rate, lateral acceleration).
- The reference is the **single-track model**, limited by $\mu g / v$.
- It corrects by braking single wheels, **inner rear** on understeer, **outer front** on
  oversteer, and by reducing engine torque.
- Since 2011–2014 it is mandatory on new cars in the US and the EU.

### Next: adding torque instead of only taking it away. <Link to="torque-vectoring">→ 06, torque vectoring</Link>

<!--
ESP steers the car with the brakes. Every intervention costs speed. The newest systems do the same
with drive torque.
-->
