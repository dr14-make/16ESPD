---
routeAlias: torque-vectoring
layout: section
---

###### Section 06

# Torque vectoring

Modern systems do not only brake a wheel: they **add** torque to one and take it from the other.

<!--
The source deck ended with a note in Czech: "moderní přidávají kroutící moment… pokud najdeš info"
— modern systems add torque, if you find information. This section is that information.
-->

---
routeAlias: yaw-moment
---

## A yaw moment from drive torque

<div class="grid grid-cols-[1.1fr_1fr] gap-6">
<div>

![A car in a left-hand bend, top view: the outer rear wheel gets an extra drive force plus delta F, the inner rear wheel a reduced force minus delta F, and the pair makes a yaw moment M_z that turns the car into the bend; the track t is marked between the rear wheels.](/diagrams/06-torque-vectoring.svg)

</div>
<div>

**Direct yaw moment control.** A force difference across an axle turns the car, whatever the
steering does:

$$
M_z \;=\; \left(F_{x,\text{outer}} - F_{x,\text{inner}}\right)\frac{t}{2}
$$

ESP makes $M_z$ by **braking**: it slows the car, so it is used only in an emergency.

Torque vectoring makes it by **moving drive torque**: it can be used all the time, to make the car
turn in more eagerly or more stably.

</div>
</div>

<!--
The same physics as ESP's selective braking: a longitudinal force off the center line makes a yaw
moment, force times half the track. The difference is the sign. A brake can only pull a wheel
back. A torque-vectoring drive can push the outer wheel forward and hold the inner one back by the
same amount: the yaw moment doubles and the net drive force is unchanged.

That changes what the system is for. ESP is an emergency intervention, because every brake
application costs speed and heats the brakes. Torque vectoring can work continuously, in normal
driving, shaping how the car responds to the steering: less understeer on the way into a bend,
more stability on the way out.

The formula is plain statics; with equal and opposite delta F it reduces to delta F times t.
-->

---
routeAlias: tv-hardware
---

## Three ways to vector torque

<div class="grid grid-cols-3 gap-6">
<div>

### Brake-based

ESP hardware brakes the **inner** driven wheel in a bend; the open differential sends that torque
to the outer one.

VW **XDS** (Golf GTI, 2009) and similar systems in most makes.

Cheap: software only. Costs some speed and brake heat.

</div>
<div>

### Active differential

Clutches and gear sets in the differential **overdrive** one side.

Mitsubishi **AYC** (Lancer Evolution IV, 1996), Honda **SH-AWD** (Legend, 2004: rear left–right
split anywhere from 100:0 to 0:100), Audi **sport differential** (2008).

No losses to brakes; heavy and costly.

</div>
<div>

### Electric motors

**One motor per wheel** or per side: each wheel's torque is commanded directly, in milliseconds,
and can be negative (regenerative).

Dual-motor axles in performance electric cars.

The cleanest actuator: torque vectoring is just a control law.

</div>
</div>

<!--
Three generations of actuator for the same moment.

Brake-based: Volkswagen's XDS, electronic differential lock extended, uses the ESP hydraulics to
brake the inside front wheel when it starts to lose grip in fast cornering, which reduces
understeer. It needs no new hardware, which is why most makers have a version of it. It is
torque vectoring by subtraction.

Active differentials: Mitsubishi's Active Yaw Control on the 1996 Lancer Evolution IV was the
first, a torque-transfer rear differential. Honda's Super Handling All-Wheel Drive of 2004 varied
the front-rear split from 30:70 to 70:30 and the rear left-right split from 100:0 to 0:100 using
electromagnetic clutches. Audi's sport differential, from the 2008 S4, uses superposition gear
sets and multi-plate clutches to send most of the torque to one rear wheel. These add torque to
the outer wheel instead of taking it from the inner one.

Electric motors: with a motor at each wheel or each side of an axle, torque vectoring needs no
mechanism at all. Each wheel gets its own torque command, positive or negative, with millisecond
response. That merges TCS, ABS-like slip control, regenerative braking and yaw control into one
controller acting on the motors. I did not research specific products here.

Sources: Volkswagen newsroom on XDS; Honda's 2004 press release on SH-AWD; Mitsubishi's model
history; Audi's S4 press material via AudiWorld.
-->

---

## Summary of section 06

- A force difference across an axle makes a yaw moment $M_z = \Delta F_x\, t/2$ per wheel.
- ESP makes it by **braking**; torque vectoring by **moving drive torque**, which costs no speed.
- Actuators: brake-based (software on ESP), active differentials, and one electric motor per
  wheel.

### Next: what each system controls, and where to read more. <Link to="wrap-up">→ 07, wrap-up</Link>

<!--
From braking a wheel to steering the car with drive torque: the last step of the same idea.
-->
