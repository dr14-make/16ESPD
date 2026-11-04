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
disconnection. P0: the machine is connected to the engine through a belt, on the front-end accessory
drive, where the alternator sits today. P1: the machine is connected directly to the crankshaft,
between the engine and the clutch. Both turn whenever the engine turns, and the engine turns
whenever they do.

The green zone holds the three decoupled positions. P2: the machine sits after the K0 clutch, on the
transmission input, attached by a belt or integrated, at the engine's speed or a multiple of it when
the clutch is closed. P3: the machine is geared to the transmission output, its speed a multiple of
the wheel speed. P4: the machine drives the rear axle through its own gear, or sits in the wheel
hubs. With K0 open, the engine can stand still while P2, P3 and P4 turn.

In our car the CVT is the transmission. The plan puts P3 at the CVT output and P4 on the rear
flanges with its own reduction.
-->

---
routeAlias: positions-compared
---

## What each position can do

<div class="tight">

| | P0, belt | P1, crank | P2, P3, P4, decoupled |
|---|---|---|---|
| Torque boost | medium: belt slip | high, if the machine can | high, if the machine can |
| Energy recuperation | medium: engine drag | medium: engine drag | **high**: no engine drag; P2 and P3 pay some transmission loss |
| Electric creep and drive | not possible | possible, with the engine turning | **possible, engine off** |
| Packaging | easy | difficult | difficult; P4 adds all-wheel drive |
| System efficiency | medium: belt | high: no belt, no gears | high: gear mesh only |
| Engine start | the machine | the machine | P2 through K0; P3, P4 need a starter |

</div>

<div class="handson">Measured on a production P0 (2012 Sonata's belt starter-generator, ORNL): system
peak <b>86–88 %</b> including the belt; belt loss <b>1–2 %</b> at high power, <b>3–6 %</b> at
moderate load and low speed.</div>

<!--
The original deck rates each position on the same six questions. I have put them in one table.

Torque boost: P0 is medium, limited by the belt, which slips under high torque, especially at a
cold start. P1 and the decoupled positions are high, if the machine is strong enough.

Energy recuperation is the key row. P0 and P1 are medium, because when they brake the car they
also drag the engine: its friction torque is a parasitic load on the machine, both in boost and in
recuperation. The decoupled positions are high: with K0 open the engine is not dragged at all;
P2 and P3 still pay some of the transmission's loss.

Electric creep and drive: not possible with P0, because of the limited torque and the belt. P1 can
creep, but only by turning the engine with it. The decoupled positions can drive with the engine
off.

Packaging: P0 is easy, components integrate with little impact on the rest; that is why the deck
calls it the most cost-effective. The others need a powertrain designed for them, and P4 adds
all-wheel drive as a bonus. System efficiency: P0 medium, because of the belt; P1 high, no belt and
no gears; P2 to P4 high, only gear mesh losses. And the last row: P0 and P1 can start the engine
themselves; a P2 can start it by closing K0; P3 and P4 need a separate starter.

The green box puts a number on the belt. Oak Ridge measured the 2012 Hyundai Sonata's belt
starter-generator, effectively a P0 machine of 8.5 kilowatts: the whole system peaks at 86 to 88
percent including the belt, and the belt alone loses 1 to 2 percent at high power and 3 to 6 percent
at moderate load and low speed. That is the research note's section 2.4.
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

The real P2 we size after is the 2011 Sonata Hybrid: its 30 kilowatt machine sits in place of the
torque converter, behind an engine clutch.
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
