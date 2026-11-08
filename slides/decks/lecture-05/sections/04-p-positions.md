---
routeAlias: p-positions
layout: section
---

###### Section 04

# P0 to P4

Five places for the machine in a parallel hybrid, and why the clutch between it and the engine
matters more than its power.

<!--
Section 04: P0 to P4. In a parallel hybrid, the machine can sit in five places along the
driveline, the chain of shafts and gears from the engine to the wheels. P stands for position, and
the positions are numbered P0 to P4 from the engine outward. We go through them, compare what each
can do, and arrive at the main argument of the lecture: a machine that can be decoupled from the
engine is worth more than a stronger machine that cannot. At the end you build the P2 powertrain,
build 01.
-->

---
routeAlias: cvt
---

## The CVT: any ratio in a range

<div class="grid grid-cols-[1fr_1.2fr] gap-8 items-start">
<div>

A **continuously variable transmission** changes its ratio smoothly, not in steps. So for one wheel
speed, the engine speed can be chosen.

$$
\omega_e = i\,\omega_w
$$

<div class="caption text-left">ω<sub>e</sub>: engine-side speed · ω<sub>w</sub>: wheel speed ·
<i>i</i>: the ratio, final drive included</div>

<div class="handson">Section 05 uses this freedom: the ratio puts the engine at its most efficient
speed.</div>

</div>
<div class="tight">

| The course's CVT model | |
|---|---|
| Ratio range | **12.0** at launch to **2.8** at top speed |
| Ratio chosen by | the pedal: target engine speed from **1800 rpm** (pedal up) to **6000 rpm** (pedal down); from build 02 on, a speed command instead |
| Outside the range | the ratio stops at its limit; the engine leaves its target |
| How fast | follows the command with a **0.5 s** lag |
| Losses | none: ideal, power in = power out |
| Starting from rest | needs a clutch: in Lecture 2 a centrifugal clutch, closing near **1300 rpm**; in our P2, K0 |

</div>
</div>

<!--
Two parts carry the hybrid we build: the CVT and the K0 clutch. The drawing of the five positions,
two slides from now, is built on them. So here is what each one does and how we model it. First,
the CVT.

CVT stands for continuously variable transmission. A normal gearbox has a few fixed gears. A CVT
can take any ratio between two limits, and it changes that ratio smoothly. The formula says what
that buys us. The engine-side speed, omega e, equals the ratio i times the wheel speed, omega w. The
wheel speed is set by the car's speed. So by choosing the ratio, we choose the engine's speed. In
our model the ratio already includes the final drive, the fixed gear in front of the wheels.

The table describes our model. The ratio runs from 12.0 at launch, for strong pull at low speed, to
2.8 at top speed, so that the engine turns slowly on the highway. Both values are assumptions for a
small car's belt CVT.

How is the ratio chosen? In Lecture 2's model, and in build 01, the pedal picks a target engine
speed: 1800 rpm with the pedal up, rising to 6000 rpm with the pedal fully down. The CVT then picks
the ratio that puts the engine at that speed. From build 02 on, we use a version that takes the
target speed as a command instead, from the engine's line of efficient speeds. That is section 05.

If the target needs a ratio outside 12.0 to 2.8, the ratio stops at its limit and the engine leaves
its target: it runs below the target at launch, and above it at high speed. The ratio does not
jump. It follows the command with a lag of 0.5 seconds, like the hydraulics of a real belt CVT. And
the model has no losses: all the power that goes in comes out. That is a simplification to
remember.

Last row: a CVT alone cannot start the car from rest, because the wheels stand still and no ratio
fits. It needs a clutch that slips. Lecture 2's car used a centrifugal clutch, which closes as the
engine speeds up past about 1300 rpm. In our P2, that job goes to K0, on the next slide.
-->

---
routeAlias: k0-clutch
---

## K0: the clutch that cuts off the engine

<div class="grid grid-cols-[1fr_1.2fr] gap-8 items-start">
<div>

K0 sits between the engine and the electric machine.

- **Open**: the engine can stand still while the machine drives or brakes the car.
- **Closed**: the engine drives the car, or the machine spins the engine up to start it.
- **Slipping**: the two sides turn at different speeds, and the clutch passes friction torque
  between them.

<div class="handson">The decoupled positions of this section, P2 to P4, exist because of K0.</div>

</div>
<div class="tight">

| The course's K0 model | |
|---|---|
| Strength | up to **230 N·m** of friction torque: 1.5 × the engine's peak torque |
| Actuator | hydraulic, **0.15 s** lag: 90 % closed in about **0.35 s** |
| Slip | friction torque grows smoothly with slip, close to full strength above about 1 rad/s |
| At the start of a run | open |
| Starting the car (H0) | closes as the engine passes about **1300 rpm**, over about **120 rpm** |
| Lock-up | closes as the machine side passes **840 rpm**: open at 800 rpm idle, closed by **880 rpm**; opens again at stops |
| Starting the engine (build 03) | K0 closes and cranks it; fuel fades in from **400** to **700 rpm**; the machine adds the torque K0 takes |

</div>
</div>

<!--
The second part is K0, the clutch between the engine and the electric machine. The name K0 comes
from the German word for clutch, Kupplung. The zero is there because it sits first, right after the
engine.

It has three states. Open: the engine is cut off. It can stand still while the machine drives the
car, or brakes the car to charge the battery, without dragging the engine along. Closed: the engine
and the machine turn together. Then the engine drives the car; or, if the engine is off, closing K0
lets the turning machine spin the engine up to start it. Slipping, in between: the two sides turn
at different speeds, and the clutch passes friction torque from the faster side to the slower one,
just as a car's clutch does when you start off.

The table describes our model. Its strength, the most friction torque it can pass, is 230 newton
meters: one and a half times the engine's peak torque of about 150. So when it is closed, it passes
up to 230 newton meters with very little slip.

It is closed by a hydraulic actuator, which we model as a lag of 0.15 seconds. So the clutch is 90
percent closed after about 0.35 seconds.

Now the slip row. The friction torque is the clutch's strength times how far it is closed, and its
direction follows the slip. It grows smoothly from zero, so the solver never has to stop at the
moment the clutch locks. Above about one radian per second of slip, it is close to full strength.
So a closed clutch behaves as locked, with a very small slip.

Every run starts with K0 open. The test models then close it in two ways. First, starting the car
in H0, the engine-only car: K0 closes as the engine speeds up past about 1300 rpm, over a band of
about 120 rpm, like Lecture 2's centrifugal clutch. Second, lock-up: once the machine side passes
840 rpm, K0 closes fully. It is open at the 800 rpm idle and closed by 880. K0 follows whichever of
the two asks for more. When the car slows to a stop, both speeds fall below their bands and K0
opens again.

Starting the engine, in build 03: the energy manager closes K0 while the machine turns, and K0
cranks the engine. The engine's fuel fades in between 400 and 700 rpm. While K0 cranks, it takes
torque from the shaft, and the machine adds that torque back, so the wheels still get what the
driver asks for.

The take-away: K0 is what lets the engine stop while the car moves. The positions after it, P2, P3
and P4, depend on it.
-->

---
routeAlias: five-positions
---

## Five places for the machine

<div class="diagram-wide">

![The course car's driveline from left to right: the engine, its crank, the K0 clutch, the CVT, the differential and the front wheels. P0 sits on the engine's belt drive and P1 on the crank, both inside a red zone labeled turns with the engine, always. P2 sits after K0 on the CVT input, P3 on the CVT output, and P4 drives the rear axle through its own gear, all inside a green zone labeled can turn with the engine off: K0 open.](/diagrams/04-p-positions.svg)

</div>

<div class="caption">P = position, numbered from the engine outward · red zone: always turns with
the engine · green zone: can turn with the engine off, once K0 opens</div>

<div class="grid grid-cols-2 gap-8 text-[0.85rem]">
<div>

**No mechanical disconnection.** **P0**: on the belt that drives the engine's accessories, such
as the alternator (FEAD, front-end accessory drive). **P1**: directly on the crankshaft.

</div>
<div>

**Decoupled from the engine.** **P2**: between the clutch and the transmission, at engine speed or
a multiple. **P3**: on the transmission output, at a multiple of wheel speed. **P4**: on the rear
axle or in the hubs.

</div>
</div>

<!--
Here are the five positions, drawn on the driveline we use today. Read the black line from left to
right: the engine, the K0 clutch, the CVT, the differential, and the front wheels. The small boxes,
P0 to P4, are the places where a machine can sit. P0 and P1 are red, and P2, P3 and P4 are green,
the color of the zone they sit in. The zones are the dashed outlines.

The red zone on the left holds the two positions that cannot be mechanically disconnected: P0 on
the engine's belt, and P1 on the crankshaft. Both turn whenever the engine turns, and the engine
turns whenever they do.

The green zone holds the three decoupled positions: P2 after the clutch, on the transmission's
input; P3 on the transmission's output; and P4 on the rear axle or in the wheel hubs. With K0 open,
the engine can stand still while P2, P3 and P4 turn.

The one thing to take from this drawing is the two zones. Red means the machine can never stop
while the engine turns. Green means it can, once K0 opens.

In our car, the CVT is the transmission. The next five slides take the positions one at a time.
Each uses this same drawing, with the position in focus drawn with a thick border, red for P0 and
P1, green for P2 to P4, and the others grayed out. Each also comes with a rating of what that
position can do.
-->

---
routeAlias: p0-belt
---

## P0: the belt starter-generator

<div class="diagram-wide">

<img src="/diagrams/04-p0.svg" alt="The course car's driveline with P0 highlighted: the machine on the engine's belt drive, inside the red zone that turns with the engine. P1 to P4 are grayed." style="max-height: 17rem" />

</div>

<div class="grid grid-cols-[1fr_1fr] gap-8 items-start mt-4">
<div class="text-[0.9rem]">

On the accessory belt, where the alternator sits: **linked to the engine, never separated**. The
machine must always turn the engine too, against its friction: when it helps drive (boost) and when
it brakes to recover energy (recuperation). The belt limits the torque: it slips, worst at a cold
start.

<div class="handson">Measured on a production P0 (2012 Sonata's belt starter-generator, ORNL): system
peak <b>86–88 %</b> including the belt; belt loss <b>1–2 %</b> at high power, <b>3–6 %</b> at
moderate load and low speed.</div>

</div>
<div class="tight">

| BiSG, belt-integrated starter-generator | |
|---|---|
| Torque boost | medium: belt slip, durability |
| Recuperation | medium: engine losses |
| Driveability | medium: limited boost |
| Electric creep (slow crawl), drive | not possible |
| Packaging | **easy**: little impact on the car |
| System efficiency | medium: the belt |
| Usual machine | 2.5–6 kW, 89–95 % |
| Engine start | restarts it; 48 V systems keep the 12 V starter |

</div>
</div>

<!--
P0 is the belt-integrated starter-generator, BiSG for short: one machine that both starts the
engine and generates electricity, driven by a belt. In the drawing, it is the box outlined in red.
It sits on the front-end accessory belt, where the alternator sits today, inside the red zone.

The key physical fact is that the engine and the machine can never be separated, because the belt
links them. So the engine's friction always loads the machine. That happens when the machine gives
extra torque to help the engine, which we call boost, and also when it brakes the car to recover
energy, which we call recuperation: a share of every braking goes into turning the engine. And the
belt limits the torque it can pass. It slips, especially at a cold start. That is why current 48
volt BiSG mild hybrids still keep the 12 volt starter.

The table rates what it can do. Boost, recuperation and driveability are all medium, for those two
reasons. Driveability means how smoothly and strongly the car responds to the pedal. Electric
creep, the car crawling slowly on electric power as in a traffic jam, is not possible with so little
torque through a belt, and neither is electric driving. Packaging is the strength of P0: the parts
fit in with little impact on the rest of the car, which makes it the most cost-effective mild
hybrid layout. System efficiency is medium, because of the belt. The usual machine is 2.5 to 6
kilowatts, at 89 to 95 percent efficiency.

The green box puts a number on the belt. Oak Ridge National Laboratory, ORNL, measured the 2012
Hyundai Sonata's belt starter-generator, which is in effect a P0 machine of 8.5 kilowatts. The
whole system peaks at 86 to 88 percent, including the belt. The belt alone loses 1 to 2 percent at
high power, and 3 to 6 percent at moderate load and low speed.
-->

---
routeAlias: p1-crank
---

## P1: on the crankshaft

<div class="diagram-wide">

<img src="/diagrams/04-p1.svg" alt="The course car's driveline with P1 highlighted: the machine on the crankshaft between the engine and K0, inside the red zone that turns with the engine. P0, P2, P3 and P4 are grayed." style="max-height: 17rem" />

</div>

<div class="grid grid-cols-[1fr_1fr] gap-8 items-start mt-4">
<div class="text-[0.9rem]">

Directly on the crankshaft, before K0: **no belt to slip**, so more torque than a P0. Generator when
the car slows down, starter, motor helping the engine when the car speeds up. But it **still turns
with the engine**: it must turn the engine's friction in boost and in recuperation, and creeping
turns the engine too.

<div class="handson">In line with the engine block, in most cases a brushless DC (BLDC) machine:
short and wide in diameter, as in the Honda Insight.</div>

</div>
<div class="tight">

| CiSG, crankshaft-integrated starter-generator | |
|---|---|
| Torque boost | **high**, if the machine can |
| Recuperation | medium: engine losses |
| Driveability | medium: the machine's torque |
| Electric creep, drive | possible, the engine turning |
| Packaging | difficult: a powertrain designed for it |
| System efficiency | **high**: no belt, no gear mesh |
| Usual machine | up to 15 kW, 89–95 % |
| Engine start | the machine |

</div>
</div>

<!--
P1 is the crankshaft-mounted machine, CiSG for short. In the drawing, it is the box on the crank,
still inside the red zone, before the clutch K0.

With no belt in between, it can give more torque than the belt starter-generator. It does three
jobs: it is a generator when the car slows down, it is the engine's starter, and it is a motor that
helps the engine when the car speeds up.

The key fact is the zone it sits in: it still turns with the engine, always. So the machine must
turn the engine's friction again, both in boost and in recuperation, and recuperation stays medium.
It can creep, if its torque allows, but only by turning the engine along with it.

In the table, torque boost is high if the machine is strong enough, and driveability is medium,
depending on that torque. Packaging is difficult: the powertrain has to be designed for it. System
efficiency is high, because there is no belt and there are no gears in between. The usual machine
is up to 15 kilowatts, at 89 to 95 percent efficiency.

The green box is about the machine itself. A crankshaft machine sits in line with the engine block.
In most cases it is a brushless DC machine, a common type of electric motor with no brushes, short
in length and wide in diameter. One example is the Honda Insight.
-->

---
routeAlias: p2-after-k0
---

## P2: behind the clutch

<div class="diagram-wide">

<img src="/diagrams/04-p2.svg" alt="The course car's driveline with P2 highlighted: the machine after the K0 clutch on the CVT input, inside the green zone that can turn with the engine off. P0, P1, P3 and P4 are grayed." style="max-height: 17rem" />

</div>

<div class="grid grid-cols-[1fr_1fr] gap-8 items-start mt-4">
<div class="text-[0.9rem]">

After K0, on the transmission input, by a belt or through gears. **Open K0** and the engine stands
still: electric creep and drive, recuperation while coasting, no engine drag.
**Close K0** with the machine turning and it starts the engine. In our car the CVT's ratio moves
its speed with the engine's.

<div class="handson">The P2 we size after: the 2011 Sonata Hybrid, a <b>30 kW</b> machine where an
automatic gearbox has its fluid coupling, behind an engine clutch (ORNL). You build it: build
01.</div>

</div>
<div class="tight">

| P2, on the transmission input | |
|---|---|
| Torque boost | **high**, if the machine can |
| Recuperation | **high**: no engine drag; pays the CVT's loss |
| Driveability | medium: the machine's torque |
| Electric creep, drive | **possible, engine off** |
| Packaging | difficult: higher integration cost |
| System efficiency | **high**: gear mesh only |
| Engine start | by closing K0 |

</div>
</div>

<!--
P2 is the first position in the green zone. In the drawing, look at K0 and then at the box right
after it: the machine sits after the clutch, on the transmission's input shaft. It can be attached
beside the transmission through a belt, or built into the transmission through gears.

The clutch is the whole story here. With K0 open, the engine stands still and is not dragged along.
The machine can creep and drive the car electrically, and it can recuperate while braking and
coasting, with all of that energy reaching the battery except the transmission's loss. With K0
closed, the machine turns at the engine's speed and boosts like a P1. And by closing K0 while the
machine turns, it starts the engine, so a P2 needs no separate starter. The price is a higher
integration cost.

In our car the transmission is the CVT, so the machine sits before the ratio: the CVT moves the
machine's speed as well as the engine's. We use that in section 05.

The green box is the real P2 that we size our car after: the 2011 Hyundai Sonata Hybrid that Oak
Ridge measured. It has a 30 kilowatt machine in place of the torque converter, which is the fluid
coupling an automatic gearbox normally has, and it sits behind an engine clutch. That is what you
build at the end of this section.
-->

---
routeAlias: p3-output
---

## P3: on the transmission output

<div class="diagram-wide">

<img src="/diagrams/04-p3.svg" alt="The course car's driveline with P3 highlighted: the machine geared to the CVT output, inside the green zone that can turn with the engine off. P0, P1, P2 and P4 are grayed." style="max-height: 17rem" />

</div>

<div class="grid grid-cols-[1fr_1fr] gap-8 items-start mt-4">
<div class="text-[0.9rem]">

Geared to the transmission output: its speed is **a multiple of the wheel speed**, whatever the
ratio. Braking, the energy reaches it before the CVT, so it has **the highest recuperation of the
front-axle positions**. But K0 and the CVT stand between it and the engine: it cannot start it,
so stop/start **needs a starter**.

</div>
<div class="tight">

| P3, on the transmission output | |
|---|---|
| Torque boost | **high**, if the machine can |
| Recuperation | **highest**: no engine drag, no CVT loss |
| Driveability | medium: the machine's torque |
| Electric creep, drive | **possible, engine off** |
| Packaging | difficult: a powertrain designed for it |
| System efficiency | **high**: gear mesh only |
| Engine start | not by the machine: a starter |

</div>
</div>

<!--
P3. In the drawing, it is the box after the CVT: the machine is connected through gears to the
transmission's output shaft. In our car, that is the CVT's output.

Its speed is a multiple of the wheel speed, fixed by its own gear, whatever the CVT's ratio does.
So, unlike with P2, the CVT cannot move this machine to a better speed.

The gain is in recuperation. When the car brakes, the energy comes from the wheels through the
differential, and it reaches the machine before it reaches the CVT. So there is no engine drag and
no CVT loss. It has the highest energy recuperation potential of the positions on the front axle.
And it can creep and drive electrically with K0 open, just like a P2.

The price is the engine start. The machine is on the far side of the CVT and K0, so it cannot crank
the engine. A car with a P3 needs a starter for stop/start.

The rest of the table is the common rating for P2, P3 and P4: high boost if the machine can deliver
it, medium driveability, difficult packaging, which means hard to fit into the car, and high system
efficiency, with only the losses of its gears.
-->

---
routeAlias: p4-rear-axle
---

## P4: on the rear axle

<div class="diagram-wide">

<img src="/diagrams/04-p4.svg" alt="The course car's driveline with P4 highlighted: the machine driving the rear axle through its own gear, inside the green zone that can turn with the engine off. P0 to P3 are grayed." style="max-height: 17rem" />

</div>

<div class="grid grid-cols-[1fr_1fr] gap-8 items-start mt-4">
<div class="text-[0.9rem]">

On the rear axle through its own gear, or in the wheel hubs. The engine drives the front axle, the
machine the rear: they meet only through the road, a **through-the-road hybrid**. That gives
**all-wheel drive**, and no transmission in the regen path; but it **needs a starter**. In our car,
one machine drives both rear wheels the same; it does not give them different torques.

<div class="handson">A motor in the wheel hub is the same "inside-out" type as the crankshaft
machine: short and wide.</div>

</div>
<div class="tight">

| P4, on the rear axle | |
|---|---|
| Torque boost | **high**, if the machine can |
| Recuperation | **highest**: no engine drag, no transmission |
| Driveability | medium: the machine's torque |
| Electric creep, drive | **possible, engine off** |
| Packaging | difficult; adds **all-wheel drive** |
| System efficiency | **high**: gear mesh only |
| Engine start | not by the machine: a starter |

</div>
</div>

<!--
P4. In the drawing, it is the box at the bottom: the machine drives the rear axle through its own
gear, or it sits in the wheel hubs. Usually it sits on the rear differential.

The engine drives the front axle through K0 and the CVT, and the machine drives the rear axle.
There is no shaft between them. They are coupled only through the road, which is why this is called
a through-the-road hybrid. That has two consequences. It gives all-wheel drive as a bonus. And,
like P3, it cannot start the engine, so it needs a starter.

Recuperation is rated the highest: there is no engine drag, and no transmission between the wheel
and the machine, only the machine's own gear. It can also creep and drive electrically with the
engine off.

In our car, it drives the rear wheel hubs through its own reduction gear, with one machine for the
whole axle. It is not torque vectoring: it cannot give the left and right wheels different torques
to help the car turn.

The green box is about the machine. A motor built into the wheel is the same inside-out type as
the crankshaft machine of P1: short in length and wide in diameter.
-->

---
routeAlias: positions-compared
---

## What each position can do

<div class="diagram-wide">

<img src="/diagrams/04-p-positions.svg" alt="The course car's driveline with the five positions: P0 on the belt and P1 on the crank in the red zone that always turns with the engine; P2 after K0, P3 on the CVT output and P4 on the rear axle in the green zone that can turn with the engine off." style="max-height: 16rem" />

</div>

<div class="caption">Red zone: P0, P1, the first two columns · green zone, behind K0: P2, P3, P4, the
last column</div>

<div class="tight">

| | P0, belt | P1, crank | P2, P3, P4, decoupled |
|---|---|---|---|
| Torque boost | medium: belt slip | high, if the machine can | high, if the machine can |
| Energy recuperation | medium: engine drag | medium: engine drag | **high**: no engine drag; P2 also pays the CVT's loss |
| Electric creep and drive | not possible | possible, with the engine turning | **possible, engine off** |
| Packaging | easy | difficult | difficult; P4 adds all-wheel drive |
| System efficiency | medium: belt | high: no belt, no gears | high: gear mesh only |
| Engine start | the machine | the machine | P2 through K0; P3, P4 need a starter |

</div>

<!--
Here are the five positions in one table, rated on six questions. Above it is the driveline drawing
again. The red zone, P0 and P1, gives the first two columns of the table, and the green zone behind
K0, with P2, P3 and P4, gives the last column. Read the table by rows, not by columns. Packaging
means how hard the machine is to fit into the car; system efficiency is how much of the power gets
through.

Torque boost: only P0 is limited, by its belt. Energy recuperation is the key row. P0 and P1 drag
the engine with every braking, and the decoupled positions do not. Electric creep and drive is
impossible on P0, possible only with the engine turning on P1, and possible with the engine off on
P2 to P4. Packaging is the one row P0 wins, which is why it is the cheapest. And the last row: P0
and P1 start the engine themselves, P2 starts it by closing K0, and P3 and P4 need a separate
starter.

The two rows to remember are recuperation and electric drive. Both are decided by the clutch, not
by the machine. The next slide puts a number on that.
-->

---
routeAlias: decoupling
---

## The decoupling argument

<div class="grid grid-cols-[1.1fr_1fr] gap-8 items-start">
<div>

Braking, engine coupled (P0, P1):

$$
P_{\text{to battery}} = \eta\,\big(P_{\text{brake}} - P_{\text{engine drag}}\big)
$$

Braking, K0 open (P2, P3, P4):

$$
P_{\text{to battery}} = \eta\,\big(P_{\text{brake}} - P_{\text{driveline loss}}\big)
$$

<div class="caption text-left">All in kW · P<sub>brake</sub>: braking power at the wheels ·
P<sub>engine drag</sub>: power spent turning the engine · P<sub>driveline loss</sub>: power lost
in the gears on the way · η: efficiency of the machine and converter</div>

P2 loses the CVT and final drive; P3 and P4 only their gear.

And with the engine coupled there is no driving with the engine off: no electric creep, no
sailing (rolling with the engine off).

</div>
<div>

**Chalmers, WLTC, 15 kW, vs no stop/start**

<div class="tight">

| Position | CO₂ reduction |
|---|---:|
| P0 | 8.9 % |
| P1 | 10.4 % |
| P2 | 24.5 % |
| P3 | 25.0 % |

</div>

Same power, same car: P2 and P3 beat P0 by **15–16 percentage points**.

</div>
</div>

<div class="handson">The decoupling clutch matters more than the machine's power.</div>

<!--
This is the main argument of the lecture.

Take the car while it brakes. Both formulas say the same thing: the power that reaches the battery
is the braking power at the wheels, minus what is lost on the way, times eta, the efficiency of the
machine and its converter. All the powers are in kilowatts. The difference between the two formulas
is what is lost on the way. With the engine coupled, in P0 or P1, the engine turns with the
machine, and its friction and the work of pumping air take a share first. That is the engine drag.
With K0 open, in P2, P3 or P4, the engine stands still, and only the gears between the wheel and
the machine take their share. That is the driveline loss, and it is much smaller. For P2 that means
the CVT and the final drive; for P3 and P4, only their own gear.

Now take the car while it drives. With the engine coupled, the machine can never drive with the
engine off. As a P1 it can creep, but only by turning the engine with it. So the two modes that save
the most in town, driving on electricity at low power and sailing, which means rolling along with
the engine off, both need the clutch.

The table on the right is the cleanest evidence. It comes from the Chalmers study that the ICCT
review reproduces: the same compact car, from the C segment, the size of a Golf, with a seven-speed
dual-clutch gearbox, and the same 15 kilowatt machine moved from position to position, compared
against the car without stop/start. On the WLTC, P0 saves 8.9 percent, P1 10.4, P2 24.5, and P3
25.0. Read the gap off the table: at equal power, P2 is 15.6 percentage points above P0, and P3 is
16.1 above. So decoupling the machine from the engine is worth about 15 to 16 points. By contrast,
going from 8 to 15 kilowatts adds only 1.5 to 2.0 points for P0 and P1.

The green box is the sentence to take home, and all three studies agree on it: the decoupling
clutch matters more than the machine's power. Section 07 checks whether our own car says the same.
-->

---
routeAlias: why-p2
---

## Why you build P2

<div class="diagram-wide">

<img src="/diagrams/04-p2.svg" alt="The course car's driveline with P2 highlighted: the machine after the K0 clutch on the CVT input, inside the green zone that can turn with the engine off. P0, P1, P3 and P4 are grayed." style="max-height: 15rem" />

</div>

<div class="caption">P2 sits behind K0 and before the CVT: the only position with a tick in every
row</div>

<div class="tight">

| Mode | P0 | P1 | **P2** | P3 | P4 |
|---|:-:|:-:|:-:|:-:|:-:|
| electric drive, engine off | | | ✓ | ✓ | ✓ |
| boost | ✓ | ✓ | ✓ | ✓ | ✓ |
| regen without engine drag | | | ✓ | ✓ | ✓ |
| engine start by the machine | ✓ | ✓ | ✓ | | |
| machine speed set by the CVT ratio | | | ✓ | | |

</div>

<div class="handson">P2 is the one position with every mode, so one energy manager exercises them
all. Moving the machine to P0, P1, P3 and P4 is the same experiment four more times: a table, in
section 07.</div>

<!--
So why do you build P2, and not another position?

At the top you see P2 on the driveline: behind K0, and before the CVT. The table lists the modes a
hybrid can have, and ticks the positions that have them. Electric drive with the engine off: only
the three decoupled positions. Boost: all five. Regen without engine drag: again the three
decoupled ones. Starting the engine with the machine: P0 and P1 directly, and P2 by closing K0; P3
and P4 need a starter. And the last row is particular to our car: only P2 sits before the CVT, so
the CVT's ratio moves the machine's speed as well as the engine's.

So P2 is the one column with a tick in every row. That is why the build uses P2. One energy manager
on a P2 exercises every mode, and moving the machine to the other four positions is the same
experiment four more times. You build P2, and I show you the other four as one table in section 07.
-->

---
routeAlias: build-p2
---

## Build 01: the P2 powertrain

<div class="grid grid-cols-[1.1fr_1fr] gap-8 items-start">
<div>

![P2Powertrain in Studio: engine, K0, hybrid drive and variator left to right, command ports on the left, outputs and the spline on the right, the housing support at the bottom.](/img/lecture-05/step01-p2-powertrain.png)

**Given:** `DisconnectClutch` (K0 and its actuator) · `HybridDrive` (30 kW, 1.4 kWh)

[page: steps 1a–1c](../lecture/lecture-05/#step-1a) · reference `dyad/HandsOn05/P2Powertrain.dyad`, `dyad/HandsOn05/P2WLTC.dyad`

</div>
<div class="stack">

*`MappedEngine` → K0 → `HybridDrive` (30 kW, 1.4 kWh) on the CVT's input shaft →
`ControlledVariator` (the CVT) → planar differential → front wheel hubs · then two runs: engine
only, K0 slipping to start the car; electric only, K0 open, engine held*

```txt
connect(engine.spline, k0.spline_a)
connect(k0.spline_b, drive.spline, variator.spline_a)
connect(variator.spline_b, spline)
```

<div class="handson">✓ engine only (H0), full WLTC: speed error (worst gap to the test's speed)
<b>1.17</b> km/h, <b>5.72</b> L/100 km · electric only, WLTC Low: speed error <b>1.50</b> km/h,
SoC 0.60 → 0.39</div>

<img src="/img/lecture-05/step01-electric-wltc-low.png" style="max-height: 13rem" alt="Electric only on the WLTC Low phase: the actual speed follows the target, the machine turns up to about 3500 rpm, the SoC falls from 0.60 to about 0.39, and the fuel flow stays at zero." />

<div class="caption">Electric only, WLTC Low: zero fuel, SoC 0.60 → 0.39. The small pack cannot
drive a whole cycle.</div>

</div>
</div>

<!--
Build 01: the P2 powertrain. On the left you see the finished powertrain in Studio. Read it from
left to right: the engine, the K0 clutch, the hybrid drive, and the variator, which is the CVT. The
command inputs come in on the left, the outputs and the shaft to the wheels leave on the right, and
the mount to the car body is at the bottom.

The italic line on the right is the build. First comes Lecture 2's engine model. Then the K0 clutch,
which the library gives you together with its actuator. Then the hybrid drive: a 30 kilowatt machine
with its converter and a 1.4 kilowatt-hour battery, sized after the 2011 Sonata. It is built like
Lecture 4's drive, but it is not the Leaf's. It sits on the CVT's input shaft, beside K0, not as
another gear in series. Then comes the controlled variator, not the full CVT driveline, which would
bring a second clutch for starting the car. And last, the planar car's differential to the front
wheel hubs. The three connect lines in the code box join the shafts: the engine to the clutch, the
clutch to the machine and the CVT, and the CVT to the output.

Then come two runs, and they are your checkpoint. First, engine only, H0. K0 starts the car like the
clutch of a manual car: it slips as the engine revs, and it is closed while the car moves. The speed
error is the largest gap between the car's speed and the speed the test asks for. The car follows
the whole WLTC within 1.17 kilometers per hour, and it burns 5.72 liters per 100 kilometers.

Second, electric only: K0 open, and the engine stopped. The car must follow the WLTC where the demand
is low. The checkpoint asks only for low demand, because at about 30 kilowatts, instead of Lecture
4's 110, the machine is not meant to carry the fast phases alone.

The plot under the checkpoint is that electric run on the WLTC Low phase. Top left, the car's speed
follows the target, within 1.5 kilometers per hour. Bottom right, the fuel flow stays at zero. And
bottom left, the state of charge falls from 60 to 39 percent. So the pack is far too small to drive
a whole cycle on electricity.
-->

---

## Summary of section 04

- **P0, P1** turn with the engine: cheap, but every brake drags the engine and there is no
  driving with the engine off.
- **P2, P3, P4** sit behind a clutch: electric drive, sailing, regen without engine drag.
- At equal power, P2 and P3 beat P0 by **15–16 points** on the WLTC. The clutch matters more
  than the machine's power.
- You built the P2: the one position with every mode.

### Next: where the engine runs when it runs. <Link to="operating-point">→ 05, moving the operating point</Link>

<!--
Section 04 in four lines. P0 and P1 turn with the engine. They are cheap to integrate, but every
braking drags the engine, and the car cannot drive with the engine off. P2, P3 and P4 sit behind a
clutch. They can drive electrically, sail, and regenerate without dragging the engine. At equal
power, decoupling is worth 15 to 16 points on the WLTC in the Chalmers study, comparing P2 and P3
against P0. The clutch matters more than the machine's power. And you built the P2, the one
position with every mode.

Next: when the engine does run, where on its map should it run?
-->
