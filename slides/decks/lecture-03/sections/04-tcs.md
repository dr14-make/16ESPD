---
routeAlias: tcs
layout: section
---

###### Section 04

# Traction control

ABS turned around: keep a **driven** wheel from spinning, with the brakes and the engine.

<!--
Budget: 12 minutes, after the short break: what 1.5, the differential film 2.5, the open
differential 1.5, actuators 1.5, brake or engine 2, Lecture 1 link 1, take-home bonus 1,
summary 1.

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

![Three nested boxes. ABS, innermost: wheel-speed sensors and valves that hold and dump; holds a braked wheel's slip. TCS or ASR around it adds valves and a pump that build pressure, and the engine torque; holds a driven wheel's slip. ESP or ESC around both adds the steering angle, the yaw rate and the lateral acceleration; holds the car's yaw rate and sideslip.](/diagrams/04-abs-tcs-esp.svg)

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

The figure: each box is a system, and each contains the one before it. Black text is what a
system adds to the hardware inside it, orange what it holds near the peak. ABS has the wheel-speed
sensors and the valves that hold and dump pressure. TCS adds valves and a pump that build pressure
without the pedal, and a say in the engine torque. ESP adds three sensors: steering angle, yaw
rate, lateral acceleration.

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

The take-home bonus has one lumped driven wheel and no differential: the both-wheels-spin case.
Braking there fights the engine, and the bonus measures exactly that against an engine cut. The
differential effect needs two driven wheels.
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
routeAlias: tcs-brake-or-engine
---

## Both wheels spin: brake or engine?

Our whole car on snow (`mu_scale = 0.2`), full throttle from rest, after 10 s. One driven wheel
stands for both, so no differential can pass torque on.

| TCS | speed | slip | engine | burned in the brakes |
|---|---:|---:|---:|---:|
| off | 5.64 m/s | 9.7 | 6410 rpm, on the limiter | 0 |
| brake only | 5.99 m/s | 0.11 | 2450 rpm | **115 kJ** |
| **engine only** | **6.62 m/s** | **0.03** | 2520 rpm | 0 |
| both | 6.45 m/s | 0.03 | 2450 rpm | 28 kJ |

The brake **fights** an engine still at full throttle and turns the difference into heat. Cutting
the engine removes the **cause**: slip on target, and a meter per second more.

<!--
Budget: 2 minutes.

The model: `HandsOn03.TCSStart`, the take-home bonus's reference. It is hands-on 2's whole car,
the mapped engine with fuel cut, flywheel, centrifugal clutch and CVT, driving the hydraulic braked
wheel from hands-on 3, on snow. The car starts at rest with the engine idling; the driver floors
the throttle at zero and holds it for 10 seconds. Two controllers can act, each switched on by its
own parameter, `brake_enabled` and `engine_enabled`:

- the brake path is build 03's `SlipABS` turned round. Driving slip is positive, so it builds
  pressure in the two ABS valves while the predicted slip is above the 0.04 target, and releases
  it below. The valves draw from a fixed 8.9 megapascal supply, the stand-in for the TCS pump.
- the engine path is the same law on the throttle: a limit between 0 and 1 that falls while the
  slip is too high and recovers below the target. The engine gets the lower of the driver's
  throttle and that limit.

Reading the table, row by row:

- Off: the wheel spins up, slip near 10, which means the tire surface runs ten times faster than
  the car. The engine runs into its 6500 rpm limiter. 5.64 meters per second after 10 seconds.
- Brake only: the slip comes down to about 0.1, but the engine still pushes with full throttle,
  and the brake takes that torque off again. Only a third of a meter per second gained, and 115
  kilojoules turned into heat in the brakes: about a liter of water heated by 27 degrees, in 10
  seconds.
- Engine only: the slip sits on target, 0.03 against 0.04, and the car is about a meter per
  second faster than without TCS. Nothing is burned.
- Both: a little slower than engine only. The brake still eats torque, with no second wheel to
  send it to.

The rule from the previous slide, now measured: brake a single spinning wheel, so the open
differential sends the torque to the other wheel; cut the engine when both spin. The brake helps
only through the differential, and our model has none.

Why the engine path has to look further ahead: it looks 0.3 seconds into the future, the brake
path 30 milliseconds. The throttle acts through the manifold filling and the torque build-up,
Lecture 2's air path, while the valve acts almost at once. That is also why production systems cut
spark or injection when they need speed.

If asked about the CVT: it stays at its 12 to 1 launch ratio in all the controlled runs, since the
car stays slow; only the uncontrolled engine runs fast enough for the schedule to shift.

Numbers from `test/tcs_bonus.jl`, Tsit5 with a millisecond maximum step and 1e-5 tolerances.
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

<div class="handson">→ Take-home bonus, next: TCS on your whole car, by brake and by engine</div>

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

## Take home: traction control on your whole car

<div class="grid grid-cols-[1.2fr_1fr] gap-8 items-start">
<div>

Hands-on 2's `MappedCar` with hands-on 3's valves, on snow (`mu_scale = 0.2`), full throttle from
rest, 10 s. Two ways to stop the wheelspin:

- **Brake:** build 03's `SlipABS` turned round. Pressure builds while
  `kappa_pred > lambda_target`, fed from a fixed 8.9 MPa supply, the ABS pump's stand-in.
- **Engine:** the same law on a throttle limit; the engine gets min(driver, limit).

Your four runs should match the "brake or engine" table.

[page: step 06](../lecture/lecture-03/#step-06)

</div>
<div>

> **Hand in, for extra points**, as a pull request from your `lecture-03` branch
>
> - wheel slip and car speed over 10 s for the four cases
> - one paragraph: why braking barely helps here and cutting the engine does, what an open
>   differential with two driven wheels would change, and why the engine path needs a much
>   longer look-ahead than the brake

</div>
</div>

<!--
Budget: 1 minute. Not built in the room: a bonus task for home, for extra points.

The parts are all ones the students have: the mapped engine with fuel cut, flywheel, centrifugal
clutch and CVT from hands-on 2; the ABS valves, brake lines and hydraulic braked wheel from
hands-on 3; their `SlipABS` from build 03. Given: `BoundaryPressure`, the fixed supply, and
`ABSPressureIntegrator`. The guide page has the task and the numbers, not the diagram.

The plant has one driven wheel standing for both: the both-wheels-spin case. Without TCS the wheel
spins up, slip near 10, and the engine runs into its 6500 rpm limiter. Braking holds the slip near
0.1 but only fights an engine still at full throttle: the car gains a third of a meter per second
and the brakes turn 115 kilojoules into heat. Cutting the engine removes the cause: the slip sits
within 0.02 of the 0.04 target and the car is a meter per second faster. Both together is a little
slower than engine only, because the brake still eats torque with no second wheel to send it to.
That is the production rule from the actuators slide: brake one spinning wheel, cut the engine
when both spin.

The engine path looks 0.3 seconds ahead, the brake path 30 milliseconds: the throttle acts through
the manifold filling and the torque build-up, the valve almost at once.

Where the traction comes from: 6865 newtons is the normal load on the driven wheel, half the
weight of the 1400 kilogram car. Times the snow factor 0.2 and the peak 1.0 it gives 1373 newtons;
spinning, at the sliding 0.7, 961.

The reference solution is in the library, `HandsOn03.TCSStartTransient`, with `brake_enabled`
and `engine_enabled` each 1 or 0, Tsit5 at a millisecond maximum step and 1e-5 tolerances: at the
default ones the uncontrolled run stalls on the rev limiter. Checked in `test/tcs_bonus.jl`. The
numbers are on the "brake or engine" slide, so the bonus is the building and the paragraph, not
the result.
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
