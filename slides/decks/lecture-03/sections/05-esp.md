---
routeAlias: esp
layout: section
---

###### Section 05

# Electronic stability program

Compare where the driver steers with where the car goes, and brake single wheels to close the
gap.

<!--
Budget: 15 minutes, 15 slides, demo included. Theory 9 (what 1.5, sensors 1, Ackermann 1,
reference model 2, yaw correction 2, evidence and the test 1.5), demo 5 (passive run 2, ESP on
1.5, ESP through ABS 1.5; the planar car and split-µ in passing, its table only), summary 1. Nothing to build: the students
watch the demo; the planar car is too large to draw in a lecture.

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

For the model: the planar car steers its two front wheels with Ackermann geometry. The
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

The source deck showed the same two cases as Renault illustrations, a car without ESP leaving the
road beside one with the braked wheel marked: `public/pptx/slide19-understeer.png` and
`slide19-oversteer.png`. They are left out to make room for the demo; the diagram says the same.
Its description of the logic, for reference: the ECU determines the car's speed from the
wheel-speed sensors, checks that the left-right wheel speed difference matches the bend, and
refines the picture with the yaw-rate sensor and the lateral accelerometer. Any discrepancy
between the real trajectory and the one the driver wants makes it brake one or more wheels; if that
is not enough, it reduces engine torque. Bosch's own description puts the engine torque reduction
first.
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

## The planar car, with ESP on top

<div class="grid grid-cols-[1fr_1fr] gap-8">
<div>

The car from section 03: four wheels, combined slip, steering, yaw, four ABS channels,
`Vehicle.Planar.PlanarCar`.

The **ESP** on top of it: a yaw-rate reference, a yaw-moment controller and a brake allocator,
`Vehicle.Planar.ESPController`. It brakes the wheels directly, or through the ABS channels.

</div>
<div>

**Checked before the demo:**

| | model |
|---|---:|
| steady cornering vs. the single-track formula | within 0.65 % |
| understeer gradient $K_{us}$ | 2.04·10⁻³ rad/(m/s²) |
| front slip-angle difference at 3 m/s, Ackermann | 0.0007 rad |
| the same, parallel steering | 0.0216 rad |

</div>
</div>

<!--
No minute of its own: its minute went to the planar car in section 03. One sentence, the car
from section 03 with ESP on top, then the passive run. Read the table only if asked: it is what
was checked before trusting the car in a spin.

The table is from `test/esp_plausibility.jl` and notebook `notebooks/lecture03/03-esp.pluto.jl`,
which recomputes every number of this section with its band. In a steady turn at small steering
angles the yaw rate matches v delta over L plus K us v squared, the formula of the
reference-model slide, to within 0.65 percent. The understeer gradient is 2.04 times ten to the
minus three radians per meter per second squared: 1.15 degrees of road-wheel angle per g, a
mildly understeering car, with a characteristic speed of 131 kilometers per hour.

The last two rows are the Ackermann slide, measured: driving a tight turn at 3 meters per second,
the two front tires' slip angles differ by 0.0007 radians with Ackermann steering and by 0.0216,
about 1.2 degrees, with the wheels parallel. That difference is the scrub.

The ESP is task 5 of `docs/lecture-03-esp-dyad-tasks.md`, the ABS channels task 6. The ESP's
reference is the single-track formula of the reference-model slide with the 0.85 margin on mu g
over v; its controller turns the yaw-rate error into a yaw moment, proportional, 40 000 newton
meter seconds per radian, with a 0.03 radian per second deadband; its allocator picks the outer
front wheel on oversteer and the inner rear on understeer, as on the yaw-correction slide, and
builds brake torque with a 0.1 second lag, up to 2500 newton meters.

If asked about load transfer: the car has it (task 7), off in every run shown here. With the
center of gravity 0.55 meters high, a steady 0.39 g left turn moves 1134 newtons off the left
front and 924 off the left rear onto the right wheels, and the yaw rate changes by only
0.14 percent, because a tire's cornering stiffness grows with its load. Near the
limit it matters: the passive car then spins at 270 degrees and plows only at 280. The
spin-or-plow boundary sits at the top of the test, so the passive 270-degree verdict is not a
robust number. ESP through ABS passes either way.
-->

---
routeAlias: esp-demo-passive
class: big-figure
---

## Demo: the test on our car, without ESP

![Top view of three runs of the sine-with-dwell from 80 km/h, the car drawn every 0.4 s. At 76 degrees of steering-wheel angle the car follows a smooth lane change and drives on. At 180 degrees it swings out, turns broadside and spins, stopping near x 92 m pointing backward. At 270 degrees it runs wider and straighter than asked, the nose plowing, but stays pointing forward.](/figures/05-swd-path.svg)

<div class="grid grid-cols-[1fr_auto] gap-6 items-start text-sm">
<div>

| steering wheel | 32° | 76° | 97° | 141° | 180° | 220° | 270° |
|---|---:|---:|---:|---:|---:|---:|---:|
| yaw-rate ratio, +1.00 s | 0.00 | 0.00 | 1.37 | 1.01 | 0.93 | 0.85 | 0.00 |
| largest sideslip $\beta$ | 0.9° | 3.2° | 84° | 83° | 83° | 61° | 5.9° |
| verdict | pass | pass | **spins** | **spins** | **spins** | **spins** | plows |

</div>
<div>

`Lecture3.SineWithDwellRunTransient`, Tsit5.

The test needs **≤ 0.35**.

</div>
</div>

<!--
Budget: 2 minutes, with the next slide. The figure is a real run. A live run,
`Lecture3.SineWithDwellRunTransient(A_sw = deg2rad(180))`, needs the planar car compiled and
warmed up before class; see the run sheet.

This is the planar car with no controller, driven through the FMVSS 126 maneuver from the
previous slide: 80 kilometers per hour, a 0.7 hertz sine on the steering wheel, half a second of
dwell at the second peak. The test scales the amplitude by A, the steering-wheel angle that gives
0.3 g in a slow ramp: 21.6 degrees on this car. It runs from 1.5 A, 32 degrees, upward, to 6.5 A
or 270 degrees, whichever is larger.

At 76 degrees the car changes lanes and drives on. From 97 to 220 degrees the rear lets go at the
reversal and the car spins: the sideslip reaches 61 to 84 degrees, and at 97 to 180 degrees it
ends sliding backward. At 270 degrees it does not spin: the front tires saturate first and the
car plows, understeer, with a sideslip of only 5.9 degrees. Real test data show the same
non-monotonic pattern. That 270-degree pass does not save the car: one failed amplitude fails the
test.

The figure is the 76, 180 and 270 degree runs and the table every amplitude, from
`scripts/export_lecture03_esp_figures.jl` at 23bd4bb, with no load transfer. The same runs give a lateral displacement 1.07 seconds after the start of steering of
2.54 meters at 76 degrees and 3.76 at 180, both above the 1.83 meters the test asks for.
-->

---
routeAlias: esp-demo-yaw
class: big-figure
---

## Why it fails: the yaw rate does not die out

![Two panels over 6 s. Top: steering-wheel angle, a sine of 76, 180 and 270 degrees amplitude that dwells at its negative peak and returns to zero at 2.93 s; dotted lines mark 1.00 s and 1.75 s after that. Bottom: yaw rate. At 76 degrees it follows the steering and returns to zero by 3.3 s. At 270 degrees it also returns to zero. At 180 degrees it falls to about minus 50 degrees per second at the reversal and stays at minus 48 until near the end: the car keeps rotating after the steering is straight.](/figures/05-swd-yaw-rate.svg)

<div class="caption">FMVSS 126: 1.00 s after the steering ends the yaw rate must be ≤ 35 % of its peak, after 1.75 s ≤ 20 %</div>

<!--
Read the bottom panel at the two dotted lines. The stable car's yaw rate is back at zero long
before them: ratio 0.00. The 180-degree car is still rotating at 48 degrees per second, the same
as its peak after the reversal: ratio 0.93 at both instants. The steering wheel has been straight
for a second and the car does not respond to it any more, because the rear tires are sliding.

This is what ESP is for. At the reversal the measured yaw rate overshoots the reference from the
single-track model; ESP sees the oversteer and brakes the outer front wheel, the left front here,
since the car is turning right after the reversal.
-->

---
routeAlias: esp-demo-on
class: big-figure
---

## With ESP: the car stops rotating, and has turned

![Top view of the 180-degree sine-with-dwell from 80 km/h, the car drawn every 0.4 s. Without ESP, dashed red, the car swings out to y 5.5 m, turns broadside and spins, stopping near x 95 m. With ESP, solid blue, it changes lanes less sharply, to y 3 m, and drives on pointing along its path, still going at x 100 m.](/figures/05-swd-esp-path.svg)

<div class="grid grid-cols-[1fr_auto] gap-6 items-start text-sm">
<div>

| steering wheel, ESP on | 32° | 76° | 97° | 141° | 180° | 220° | 270° |
|---|---:|---:|---:|---:|---:|---:|---:|
| yaw-rate ratio, +1.00 s | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| largest sideslip $\beta$ | 0.9° | 2.8° | 8.4° | 9.4° | 9.6° | 8.5° | 8.1° |
| lateral displacement [m] | 1.20 | 2.26 | 2.45 | 2.58 | 2.58 | 2.56 | 2.55 |
| end speed [m/s] | 21.4 | 18.6 | 14.6 | 13.6 | 13.4 | 13.5 | 13.4 |

</div>
<div>

`Lecture3.ESPSineWithDwell`, Tsit5.

**Passes** at every amplitude:
≤ 0.35 and ≥ 1.83 m.

</div>
</div>

<!--
Budget: 1.5 minutes, with the next slide. The figure is a real run: the same car and maneuver as
the last two slides, 180 degrees, with the ESP controller on and off. A live run is
`Lecture3.ESPSineWithDwellTransient(A_sw = deg2rad(180))`, with `esp_on = 0` for the passive car.

Without ESP the car spins: sideslip 83 degrees. With ESP it changes lanes and drives on, its
largest sideslip 9.6 degrees. The table is the whole test with ESP on. The yaw-rate ratio is at
most 0.002 at both instants, 1.00 and 1.75 seconds after the steering ends, against the 0.35 and
0.20 allowed; passively the car failed with 0.85 to 1.37 from 97 to 220 degrees. The lateral
displacement 1.07 seconds after the steering starts is 2.45 to 2.58 meters from 97 degrees up,
above the 1.83 the test asks for; the test checks it only from 5 A, 108 degrees, which is why
32 and 76 degrees do not count. ESP costs some of it: the passive car moved 3.76 meters at
180 degrees, while spinning.

Look at the last row before moving on. The car enters at 22.2 meters per second, 80 kilometers per
hour, and leaves at 13.4: 48 kilometers per hour. The next slide says why.
-->

---
routeAlias: esp-demo-wheels
class: big-figure
---

## Which wheel ESP brakes, and what it costs

![Two panels over 6 s at 180 degrees. Top: yaw rate. The reference from the single-track model, dotted, steps to plus 22, minus 25 to minus 30 degrees per second and back to zero at 2.93 s. Without ESP, dashed red, the yaw rate stays at minus 48 degrees per second to the end. With ESP, solid blue, it follows the reference with overshoots, swings to plus 15 at 3.4 s, and is back at zero before the 1.00 s check. Bottom: brake torque per wheel, up to 2500 N·m. Rear left and front right brake in the first half of the sine; after the reversal the front left and rear right alternate, and the front left brakes hardest, up to 2500 N·m around the end of the steering.](/figures/05-swd-esp-yaw.svg)

<div class="grid grid-cols-[1fr_1fr] gap-6 items-start text-sm">
<div>

Brake work while the car oversteers, $\int \tau\,dt$ in N·m·s:
**front left 1843**, front right 436, rear left 58, rear right 1053.
The **outer front** wheel does most.

</div>
<div>

From 97° up the braked wheels **lock**: slip −0.996. The car slows from 80 to **48 km/h**.
Next: the same ESP through **four ABS channels**.

</div>
</div>

<!--
Top panel: the measured yaw rate against the reference, the yaw rate the driver asks for from the
single-track model, capped by mu g over v. Passively the car rotates at 48 degrees per second long
after the reference is back at zero. With ESP the measured yaw rate tracks the reference roughly,
overshoots it, and is at zero well before the first check at plus 1.00 seconds.

Bottom panel: which wheel. After the reversal the car turns right, so the left wheels are on the
outside. Over the reversal and the dwell, from 1.71 to 4.93 seconds, the left front wheel takes
1843 newton meter seconds of brake work, the right rear 1053, the right front 436, the left rear
58: the outer front first, as on the yaw-correction slide. In the first half of the sine, a left
turn, the right front and left rear brake: the outer front again, and the inner rear when the car
lags the reference. The controller is proportional, so the torque switches between wheels as the
error changes sign; a real ESP does the same with pressure pulses.

Understeer, checked separately: in a slow steering ramp with the front friction cut to 70 percent,
the ESP brakes only the inner rear wheel, 3048 newton meter seconds and nothing on the others, and
halves the yaw-rate shortfall, from 0.145 to 0.071 radians per second.

The cost, said plainly: this ESP asks for brake torque without ABS underneath. From 97 degrees up
the braked wheels lock, the longitudinal slip reaches minus 0.996, and a locked tire gives little
lateral force. The car still passes, but it leaves the maneuver at 13 to 15 meters per second
instead of 22. The next slide sends the ESP's requests through four ABS channels, one per wheel,
which is the modulator and channel slides of section 03 put to work.

Figures: `scripts/export_lecture03_esp_figures.jl` at 23bd4bb; the numbers on both slides are
what it prints, and match the task 5 plausibility test and notebook 03.
-->

---
routeAlias: esp-through-abs
class: big-figure
---

## ESP through ABS: the braked wheel keeps rolling

![Two panels. Left: the lowest slip of the four wheels over 6 s at 180 degrees. With ESP braking directly, dashed red, it drops to minus 1, a locked wheel, again and again between 1.2 and 3.6 s. With ESP through ABS, solid blue, it never goes below minus 0.08. Right: speed at 6 s against steering-wheel amplitude, from an entry speed of 22.2 m/s. Braking directly, the car keeps 21.4 m/s at 32 degrees but only 13.4 to 14.6 from 97 degrees up. Through ABS it keeps 18.4 to 19.6 m/s from 76 degrees up.](/figures/05-esp-abs.svg)

<div class="grid grid-cols-[1fr_auto] gap-6 items-start text-sm">
<div>

| steering wheel | 32° | 76° | 97° | 141° | 180° | 220° | 270° |
|---|---:|---:|---:|---:|---:|---:|---:|
| end speed, braking directly [m/s] | 21.4 | 18.6 | 14.6 | 13.6 | 13.4 | 13.5 | 13.4 |
| end speed, through ABS [m/s] | 21.0 | 19.6 | 19.1 | 18.4 | 18.9 | 19.0 | 19.3 |
| lowest slip $\kappa$, through ABS | −0.04 | −0.06 | −0.06 | −0.07 | −0.08 | −0.08 | −0.09 |

</div>
<div>

A locked tire has **no lateral force** left.

Still **passes** everywhere:
ratio within ±0.05, ≥ 2.87 m.

</div>
</div>

<!--
Budget: 1.5 minutes. The same ESP, the same car, the same test; only the path of the brake
request changes. It now goes through the car's four ABS channels, one per wheel, the section 03
modulator on a 5 millisecond clock, releasing at a slip of 0.08 on the front wheels and 0.06 on
the rear. The controller also gains an integral term, 100 000 newton meters per radian, so that
the yaw moment it asks for is not lost when ABS takes torque away. A live run is
`Lecture3.ESPSineWithDwellTransient(A_sw = deg2rad(180), abs_on = 1.0, Ki = 1e5)`.

Left panel, 180 degrees, the lowest slip of the four wheels at each instant. Braking directly, a
wheel locks every time ESP brakes hard, and a locked tire slides almost straight backward: it
gives up the lateral force it had, which is the friction-circle slide of section 01. Through ABS
the slip never goes below minus 0.08, near the tire's peak, so the braked wheel keeps both its
braking force and its cornering force.

Right panel and the table, every amplitude. From 97 degrees up the car leaves the maneuver 4.5 to
5.9 meters per second faster, about 19 meters per second instead of 13 to 15. At 32 degrees it is
0.4 slower: the integral term brakes a little where the proportional ESP did not need to. The
test is still passed at every amplitude: the yaw-rate ratio is at most 0.042 in magnitude at both
instants, and the lateral displacement is 2.87 to 3.44 meters from 97 degrees up, more than the
2.45 to 2.58 of the ESP braking directly, because a rolling front wheel still steers.

This is why the wrap-up says ESP is impossible without four-channel ABS: the modulator that lets
ESP build pressure at one wheel is the same one that keeps that wheel from locking.

Figure and numbers: `scripts/export_lecture03_esp_figures.jl` at 23bd4bb; notebook 03, section 5,
shows the four wheels' slip separately.
-->

---
routeAlias: split-mu
class: big-figure
---

## Split-µ: braking with one side on ice

![Two panels. Left, top view: full braking from 80 km/h with the left wheels on dry asphalt and the right wheels on ice, the car drawn every 0.5 s. ABS only, red, turns left toward the dry side, more and more broadside, and stops at x 66 m, y 21 m. ABS with rear select-low, orange, and select-low with a proportional ESP, dashed purple, drift left to about y 15 m at x 87 to 90 m. Select-low with a PI ESP, blue, runs almost straight, to y 5 m at x 108 m. Right: heading over 6 s. ABS only climbs to 129 degrees by 4.5 s; the select-low runs reach 23 and 25 degrees by 6 s; the PI ESP stays near 3 degrees.](/figures/05-split-mu.svg)

<div class="grid grid-cols-[1fr_auto] gap-6 items-start text-sm">
<div>

| µ 1.0 left, 0.3 right | heading | to the side | distance | read at |
|---|---:|---:|---:|---:|
| ABS only | **129°** | 21.1 m | 65.7 m | 4.5 s, stopped |
| + rear select-low | 22.7° | 14.4 m | 89.5 m | 6 s |
| + ESP, P | 24.6° | 14.6 m | 86.8 m | 6 s |
| + ESP, PI | **3.2°** | 4.6 m | 108 m | 6 s |

</div>
<div>

`Lecture3.SplitMuStop`, steering wheel held straight.

Holding the heading **costs stopping distance**.

</div>
</div>

<!--
Budget: in passing, the table only: ABS alone turns the car 129°, the PI ESP holds 3° and costs
distance. The full read below is 2 minutes, only if ahead.

The classic case where ABS alone is not enough. Full braking from 80 kilometers per hour, 2500
newton meters asked at every wheel, the left wheels on dry asphalt and the right ones on ice at
30 percent of the grip, and the steering wheel held straight: the robot does not countersteer, as
a driver would.

ABS only: every wheel keeps rolling, as section 03 promised, but the left wheels brake three
times harder than the right ones. That difference is a yaw moment toward the dry side, and with
no one steering against it the car turns 129 degrees, past broadside, before it stops after
66 meters.

Rear select-low: both rear wheels get the smaller of their two ABS torques, so the rear axle
brakes evenly and adds no yaw moment. The heading falls to 23 degrees, and the car is still
rolling at 6 seconds: the dry rear wheel gave up braking force.

ESP, proportional: almost no change, 25 degrees. It reacts to the yaw rate, and the yaw rate here
is small; the heading lost is the integral of the yaw-rate error, and a P controller does not see
it. ESP with the integral term cuts brake torque on the dry side while the error persists, and
holds the heading at 3 degrees, at the price of a stop still unfinished at 108 meters.

Every ESP calibration makes this trade between heading and distance. Production systems also
delay the pressure build-up on the high-µ front wheel, the yaw-moment build-up delay, to give the
driver time to countersteer; I know it from the Bosch handbook and did not model it.

Figure and numbers: `scripts/export_lecture03_esp_figures.jl` at 23bd4bb, read when the car falls
below 3 meters per second or at 6 seconds; notebook 03, section 6.
-->

---

## Summary of section 05

- ESP compares the **driver's intention** (steering angle, speed) with the **car's motion** (yaw
  rate, lateral acceleration).
- The reference is the **single-track model**, limited by $\mu g / v$.
- It corrects by braking single wheels, **inner rear** on understeer, **outer front** on
  oversteer, and by reducing engine torque.
- Since 2011–2014 it is mandatory on new cars in the US and the EU; the test is the
  sine-with-dwell. Our planar car **without** ESP spins in it from 97° up; **with** ESP it passes
  at every amplitude.
- ESP brakes **through ABS**: no wheel locks, the car keeps ~5 m/s more speed. On split-µ it holds
  the heading, at the cost of stopping distance.

### Next: the whole lecture on one page. <Link to="wrap-up">→ 06, wrap-up</Link>

<!--
ESP steers the car with the brakes, and every intervention costs speed. Doing the same with drive
torque, one electric motor per wheel, comes with the electric and hybrid drives.
-->
