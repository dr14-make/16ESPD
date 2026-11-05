---
routeAlias: p-positions
layout: section
---

###### Section 04

# P0 to P4

Five places for the machine in a parallel hybrid, and why the clutch between it and the engine
matters more than its power.

<!--
Section 04, P0 to P4. In a parallel hybrid the machine can sit in five places along the driveline,
named P0 to P4 from the engine outwards. We go through them, compare what each can do, and arrive at
the argument of the lecture: a machine that can be decoupled from the engine is worth more than a
stronger one that cannot. At the end you build the P2 powertrain, build 01.
-->

---
routeAlias: five-positions
---

## Five places for the machine

<div class="diagram-wide">

![The course car's driveline from left to right: the engine, its crank, the K0 clutch, the CVT, the differential and the front wheels. P0 sits on the engine's belt drive and P1 on the crank, both inside a red zone labeled turns with the engine, always. P2 sits after K0 on the CVT input, P3 on the CVT output, and P4 drives the rear axle through its own gear, all inside a green zone labeled can turn with the engine off: K0 open.](/diagrams/04-p-positions.svg)

</div>

<div class="grid grid-cols-2 gap-8 text-[0.85rem]">
<div>

**No mechanical disconnection.** **P0**: on the belt of the front-end accessory drive (FEAD).
**P1**: directly on the crankshaft.

</div>
<div>

**Decoupled from the engine.** **P2**: between the clutch and the transmission, at engine speed or
a multiple. **P3**: on the transmission output, at a multiple of wheel speed. **P4**: on the rear
axle or in the hubs.

</div>
</div>

<!--
The five positions, drawn on the driveline we use today: the engine, the K0 clutch, the CVT, the
differential, the front wheels.

The red zone on the left holds the two positions without the possibility of mechanical
disconnection: P0 on the engine's belt, P1 on the crankshaft. Both turn whenever the engine turns,
and the engine turns whenever they do.

The green zone holds the three decoupled positions: P2 after the clutch on the transmission input,
P3 on the transmission output, P4 on the rear axle or in the wheel hubs. With K0 open, the engine
can stand still while P2, P3 and P4 turn.

In our car the CVT is the transmission. The next five slides take the positions one at a time,
each on this same drawing, with the original deck's rating of what it can do.
-->

---
routeAlias: p0-belt
---

## P0: the belt starter-generator

<div class="diagram-wide">

<img src="/diagrams/04-p0.svg" alt="The course car's driveline with P0 highlighted: the machine on the engine's belt drive, inside the red zone that turns with the engine. P1 to P4 are greyed." style="max-height: 17rem" />

</div>

<div class="grid grid-cols-[1fr_1fr] gap-8 items-start">
<div class="text-[0.9rem]">

On the accessory belt, where the alternator sits: **linked to the engine, never separated**. The
engine's friction torque is a parasitic load on the machine, in boost and in recuperation. The
belt limits the torque: it slips, worst at a cold start.

<div class="handson">Measured on a production P0 (2012 Sonata's belt starter-generator, ORNL): system
peak <b>86–88 %</b> including the belt; belt loss <b>1–2 %</b> at high power, <b>3–6 %</b> at
moderate load and low speed.</div>

</div>
<div class="tight">

| BiSG, belt-integrated | |
|---|---|
| Torque boost | medium: belt slip, durability |
| Recuperation | medium: engine losses |
| Driveability | medium: limited boost |
| Electric creep, drive | not possible |
| Packaging | **easy**: little impact on the car |
| System efficiency | medium: the belt |
| Usual machine | 2.5–6 kW, 89–95 % |
| Engine start | restarts it; 48 V systems keep the 12 V starter |

</div>
</div>

<!--
P0, the belt-integrated starter-generator, BiSG in the original deck. Point at the highlighted box:
it sits on the front-end accessory belt, where the alternator sits today, inside the red zone.

The key physical fact is that the engine and the machine can never be separated; the belt links
them. So the engine's friction torque is a parasitic load on the machine both when it gives boost
torque and when it recuperates: a share of every brake goes into turning the engine. And the belt
limits the torque it can pass: it slips, especially at a cold start. That is why, the deck says,
all current 48 volt BiSG mild hybrids still keep the 12 volt starter.

The table is the deck's characteristics. Boost, recuperation and driveability are all medium, for
those two reasons. Electric creep or drive is not possible, with that little torque through a belt.
Packaging is the strength: the components integrate with little impact on the rest of the car, which
is why the deck calls it the most cost-effective mild hybrid topology. System efficiency is medium,
because of the belt. The usual machine is 2.5 to 6 kilowatts at 89 to 95 percent.

The green box puts a number on the belt. Oak Ridge measured the 2012 Hyundai Sonata's belt
starter-generator, effectively a P0 machine of 8.5 kilowatts: the whole system peaks at 86 to 88
percent including the belt, and the belt alone loses 1 to 2 percent at high power and 3 to 6 percent
at moderate load and low speed. That is the research note's section 2.4.
-->

---
routeAlias: p1-crank
---

## P1: on the crankshaft

<div class="diagram-wide">

<img src="/diagrams/04-p1.svg" alt="The course car's driveline with P1 highlighted: the machine on the crankshaft between the engine and K0, inside the red zone that turns with the engine. P0, P2, P3 and P4 are greyed." style="max-height: 17rem" />

</div>

<div class="grid grid-cols-[1fr_1fr] gap-8 items-start">
<div class="text-[0.9rem]">

Directly on the crankshaft, before K0: **no belt to slip**, so more torque than a P0. Generator when
the car decelerates, starter, motor assisting the engine in acceleration. But it **still turns with
the engine**: the friction torque is a parasitic load in boost and in recuperation, and creeping
turns the engine too.

<div class="handson">In line with the crankcase, in most cases a BLDC machine: short and wide in
diameter, as in the Honda Insight.</div>

</div>
<div class="tight">

| CiSG, crankshaft-integrated | |
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
P1, the crankshaft-mounted machine, CiSG in the original deck. Point at the box on the crank, still
inside the red zone, before the clutch K0.

With no belt in between, it can give more torque than the belt starter-generator, and it does three
jobs: a generator when the car decelerates, the engine's starter, and a motor that assists the engine
when the car accelerates.

The key fact is the zone it sits in: it still turns with the engine, always. So the engine's
friction is a parasitic load again, in boost and in recuperation, and recuperation stays medium. It
can creep, if its torque allows, but only by turning the engine with it.

The table: torque boost high if the machine is strong enough; driveability medium, depending on that
torque. Packaging is difficult: the powertrain has to be designed for it. System efficiency is high:
no belt and no gear mesh. The usual machine is up to 15 kilowatts at 89 to 95 percent.

The green box is from the deck's slide on machines for hybrids: a crankshaft machine sits in line
with the crankcase and is in most cases a brushless DC machine, short in length and wide in
diameter. The deck's example is the Honda Insight.
-->

---
routeAlias: p2-after-k0
---

## P2: behind the clutch

<div class="diagram-wide">

<img src="/diagrams/04-p2.svg" alt="The course car's driveline with P2 highlighted: the machine after the K0 clutch on the CVT input, inside the green zone that can turn with the engine off. P0, P1, P3 and P4 are greyed." style="max-height: 17rem" />

</div>

<div class="grid grid-cols-[1fr_1fr] gap-8 items-start">
<div class="text-[0.9rem]">

After K0, on the transmission input, by a belt or integrated through a gear mesh. **Open K0** and
the engine stands still: electric creep and drive, recuperation while coasting, no engine drag.
**Close K0** with the machine turning and it starts the engine. In our car the CVT's ratio moves
its speed with the engine's.

<div class="handson">The P2 we size after: the 2011 Sonata Hybrid, a <b>30 kW</b> machine in place
of the torque converter, behind an engine clutch (ORNL). You build it: build 01.</div>

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
P2, the first position in the green zone. Point at K0 and then at the box right after it: the machine
sits after the clutch, on the transmission's input shaft. The deck says it can be side-attached to
the transmission through a belt, or integrated into it through a gear mesh.

The clutch is the whole story. With K0 open the engine stands still and is not dragged: the machine
can creep and drive the car electrically, and recuperate while braking and coasting, all of it
reaching the battery except the transmission's loss. With K0 closed it turns at the engine's speed
and boosts like a P1. And by closing K0 while the machine turns, it starts the engine, so a P2 needs
no separate starter. The price, the deck says, is a higher integration cost.

In our car the transmission is the CVT, so the machine sits before the ratio: the CVT moves its
speed as well as the engine's. We use that in section 05.

The green box is the real P2 we size after: the 2011 Hyundai Sonata Hybrid that Oak Ridge
benchmarked, a 30 kilowatt machine in place of the torque converter, behind an engine clutch. That is
what you build at the end of this section.
-->

---
routeAlias: p3-output
---

## P3: on the transmission output

<div class="diagram-wide">

<img src="/diagrams/04-p3.svg" alt="The course car's driveline with P3 highlighted: the machine geared to the CVT output, inside the green zone that can turn with the engine off. P0, P1, P2 and P4 are greyed." style="max-height: 17rem" />

</div>

<div class="grid grid-cols-[1fr_1fr] gap-8 items-start">
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
P3. Point at the box after the CVT: the machine is connected through a gear mesh to the
transmission's output shaft. In our car, that is the CVT output, as the plan puts it.

Its speed is a multiple of the wheel speed, fixed by its own gear, whatever the CVT's ratio does. So
unlike P2, the CVT cannot move the machine to a better speed.

The gain is in recuperation. When the car brakes, the energy comes from the wheels through the
differential and reaches the machine before it reaches the CVT: no engine drag, and no CVT loss. The
deck calls it the highest energy recuperation potential; of the positions on the front axle it is.
It can creep and drive electrically with K0 open, like a P2.

The price is the engine start. The machine is on the far side of the CVT and K0, so it cannot crank
the engine; a car with a P3 needs a starter for stop/start.

The rest of the table is the deck's common rating for P2, P3 and P4: high boost if the machine can,
medium driveability, difficult packaging, high system efficiency with only gear mesh losses.
-->

---
routeAlias: p4-rear-axle
---

## P4: on the rear axle

<div class="diagram-wide">

<img src="/diagrams/04-p4.svg" alt="The course car's driveline with P4 highlighted: the machine driving the rear axle through its own gear, inside the green zone that can turn with the engine off. P0 to P3 are greyed." style="max-height: 17rem" />

</div>

<div class="grid grid-cols-[1fr_1fr] gap-8 items-start">
<div class="text-[0.9rem]">

On the rear axle through its own gear, or in the wheel hubs. The engine drives the front axle, the
machine the rear: they meet only through the road, a **through-the-road hybrid**. That gives
**all-wheel drive**, and no transmission in the regen path; but it **needs a starter**. In our car,
one machine on the rear flanges, not torque vectoring.

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
P4. Point at the box at the bottom: the machine drives the rear axle through its own gear, or sits in
the wheel hubs. The deck puts it on the rear differential.

The engine drives the front axle through K0 and the CVT, the machine drives the rear. There is no
shaft between them: they are coupled only through the road, which is why this is called a
through-the-road hybrid. Two consequences. It gives all-wheel drive as a bonus. And, like P3, it
cannot start the engine: it needs a starter.

Recuperation is the highest in the deck's rating: no engine drag, and no transmission between the
wheel and the machine, only its own gear. It can creep and drive electrically with the engine off.

In our car the plan puts it on the rear flanges with its own reduction, one machine for the axle; it
is not torque vectoring.

The green box is from the deck's slide on machines for hybrids: a motor integral with the wheel is the
same inside-out type as the crankshaft machine of P1, short in length and wide in diameter.
-->

---
routeAlias: positions-compared
---

## What each position can do

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
The five positions in one table, the original deck's six questions. Read it by rows, not by
columns.

Torque boost: only P0 is limited, by its belt. Energy recuperation is the key row: P0 and P1 drag
the engine with every brake; the decoupled positions do not. Electric creep and drive: impossible on
P0, only with the engine turning on P1, with the engine off on P2 to P4. Packaging is the one row P0
wins, which is why it is the cheapest. And the last row: P0 and P1 start the engine themselves, P2 by
closing K0, P3 and P4 need a separate starter.

The two rows to remember are recuperation and electric drive. Both are decided by the clutch, not by
the machine. The next slide puts a number on that.
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
P_{\text{to battery}} = \eta\,\big(P_{\text{brake}} - P_{\text{gear loss}}\big)
$$

And with the engine coupled there is no driving with the engine off: no electric creep, no
sailing.

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

Same power, same car: decoupling is worth **up to 15 points**.

</div>
</div>

<div class="handson">The decoupling clutch matters more than the machine's power.</div>

<!--
This is the argument of the lecture.

Take the car braking. With the engine coupled, P0 or P1, the machine cannot have all of the braking
power: the engine turns with it and its friction and pumping take a share first. What reaches the
battery is the brake power minus the engine's drag, times the efficiency of the machine and
converter. With K0 open, P2, P3 or P4, the engine stands still and only the gears between the wheel
and the machine take their share.

And when driving: with the engine coupled the machine can never drive with the engine off. It can
creep, as a P1, only by turning the engine with it. So the two modes that save the most in town,
driving on electricity at low power and sailing with the engine off, need the clutch.

The table on the right is the cleanest evidence, from the Chalmers study the ICCT review reproduces:
the same C-segment car with a seven-speed dual-clutch gearbox, the same 15 kilowatt machine, moved
from position to position, against the car without stop/start. On the WLTC: P0 8.9 percent, P1 10.4,
P2 24.5, P3 25.0. The ICCT summarizes it: at equal power, decoupling the machine from the engine,
P2 or P3 against P0 or P1, is worth up to 15 percentage points. Going from 8 to 15 kilowatts adds
only 1.5 to 2.0 points for P0 and P1.

The green box is the sentence to take home, and the research note's teaching takeaway, consistent
across all three studies: the decoupling clutch matters more than the machine's power. Section 07
checks whether our own car says the same.
-->

---
routeAlias: why-p2
---

## Why you build P2

<div class="tight">

| Mode | P0 | P1 | **P2** | P3 | P4 |
|---|:-:|:-:|:-:|:-:|:-:|
| electric drive, engine off | | | ✓ | ✓ | ✓ |
| boost | ✓ | ✓ | ✓ | ✓ | ✓ |
| regen without engine drag | | | ✓ | ✓ | ✓ |
| engine start by the machine | ✓ | ✓ | ✓ | | |
| machine speed through the CVT ratio | | | ✓ | | |

</div>

<div class="handson">P2 is the one position with every mode, so one energy manager exercises them
all. Moving the machine to P0, P1, P3 and P4 is the same experiment four more times: a table, in
section 07.</div>

<!--
Why you build P2 and not another position.

The table lists the modes a hybrid can have and ticks the positions that have them. Electric drive
with the engine off: only the decoupled three. Boost: all five. Regen without engine drag: the
decoupled three. Starting the engine: P0 and P1 directly, P2 by closing K0; P3 and P4 need a starter. And the last
row is particular to our car: only P2 sits before the CVT, so the CVT's ratio moves the machine's
speed as well as the engine's.

So P2 is the one column with a tick in every row. That is settled decision S1 of the plan: one
energy manager on a P2 exercises every mode, and moving the machine to the other four positions is
the same experiment four more times. You build P2, and I show the other four as one table in section
07.
-->

---
routeAlias: build-p2
---

## Build 01: the P2 powertrain

<div class="grid grid-cols-[1.1fr_1fr] gap-8 items-start">
<div>

<div class="placeholder">

**Screenshot: `step01-p2-powertrain.png`**

The finished P2 powertrain in Studio: engine → K0 → machine → CVT → differential, the battery on
the machine.

Captured with the build guide, #111

</div>

**Given:** the K0 clutch with its actuator (#197), the 30 kW machine and 1.4 kWh battery (#198)

<span class="todo">TODO: guide link · reference `dyad/HandsOn05/…`</span>

</div>
<div class="stack">

*Lecture 2's `MapEngine` → K0 clutch → Lecture 4's machine, ≈ 30 kW → `CVTDriveline` → planar
differential → front flanges; Lecture 4's battery at ≈ 1.4 kWh · then two runs: K0 closed with
the machine idle; K0 open with the engine stopped*

```julia
# TODO: snippet from the build guide (#111)
```

<div class="handson">✓ engine only, K0 closed: the car follows the WLTC, speed error
<span class="todo">TODO</span> · electric only, K0 open, engine stopped: the car follows the WLTC at
low demand, speed error <span class="todo">TODO</span></div>

</div>
</div>

<!--
Build 01: the P2 powertrain. On the left will be the finished powertrain in Studio; the screenshot
is captured with the build guide, issue 111.

The italic line is the build. Lecture 2's mapped engine, then the K0 clutch, which the library gives
you with its actuator. Then your Lecture 4 machine, resized to about 30 kilowatts, and Lecture 4's
battery resized to about 1.4 kilowatt-hours; the library gives the resized parameter sets. Then the
CVT driveline the course already has, and the planar car's differential to the front flanges.

Then two runs, and they are the checkpoint, from the plan's live-build table. Engine only: K0
closed, the machine idle; the car must follow the WLTC, as Lecture 2's car did. Electric only: K0
open, the engine stopped; the car must follow the WLTC where the demand is low. The checkpoint asks
only for low demand: at about 30 kilowatts instead of Lecture 4's 110, the machine is not meant to
carry the fast phases alone.

The numbers in the green box, the speed errors for both runs, come from the reference model and
are still TODO.
-->

---

## Summary of section 04

- **P0, P1** turn with the engine: cheap, but every brake drags the engine and there is no
  driving with the engine off.
- **P2, P3, P4** sit behind a clutch: electric drive, sailing, regen without engine drag.
- At equal power, decoupling is worth **up to 15 points** on the WLTC. The clutch matters more
  than the machine's power.
- You built the P2: the one position with every mode.

### Next: where the engine runs when it runs. <Link to="operating-point">→ 05, moving the operating point</Link>

<!--
Section 04 in four lines. P0 and P1 turn with the engine: cheap to integrate, but every brake drags
the engine and the car cannot drive with the engine off. P2, P3 and P4 sit behind a clutch: they can
drive electrically, sail, and regenerate without dragging the engine. At equal power, decoupling
is worth up to 15 points on the WLTC in the Chalmers study; the clutch matters more than the
machine's power. And you built the P2, the one position with every mode.

Next: when the engine does run, where on its map should it run?
-->
