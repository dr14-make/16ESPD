---
routeAlias: brakes
layout: section
---

###### Section 02

# How the brakes work

From the driver's foot to the wheel: a lever, a booster, a hydraulic cylinder, two circuits and
the calipers.

`notebooks/lecture03/02-brake-hydraulics.pluto.jl`

<!--
Budget: 11 minutes, 7 slides: lever 2, force chain 2, pedal to pressure 2, master cylinder 2,
the rest of the system 2, summary 1. Section 02 is not in the hands-on; keep it moving.

The brakes transmit the force the driver applies to the pedal to the wheels using friction, at the
pads, and the tires pass it to the road using friction again. Three pieces of physics sit in
between: leverage, hydraulics and friction. This section follows a foot's force through them, with
the brake model in the repository as the running example.
-->

---
routeAlias: lever-and-hydraulics
---

## Leverage and hydraulics

<div class="grid grid-cols-3 gap-6">
<div>

![A lever on a pivot: a force F at the end of the long arm 2X balances a force 2F at the end of the short arm X; the long end moves 2Y while the short end moves Y.](/pptx/slide05-lever.jpg)

**Lever.** Force times arm is the same on both sides: twice the arm, twice the force, half the
travel.

</div>
<div>

![Hydraulic multiplication: a 2-inch piston pushed down with 100 lb lifts a 6-inch piston with 900 lb; the small piston travels nine times as far.](/pptx/slide05-hydraulic-multiplication.png)

**Hydraulics.** Pressure is the same everywhere in a closed fluid (Pascal):
$F_2 = F_1 \, A_2 / A_1$. Again paid for in travel.

</div>
<div>

![A simple brake system: the pedal, a lever with ratio 4x to x, pushes a small piston; a line carries the fluid to a larger caliper piston that moves 3y for the pedal piston's y.](/pptx/slide05-simple-brake-system.png)

**Together.** The pedal multiplies the foot's force, the fluid multiplies it again at each caliper.

</div>
</div>

<!--
Neither the lever nor the fluid makes energy. Each trades travel for force. The lever: force times
distance is the same on both ends. The hydraulic cylinders: pressure is the same everywhere in the
fluid, so force scales with piston area, and the volume pushed out of the small piston equals the
volume taken in by the large one, so travel scales the other way.

In the middle figure the large piston has three times the diameter, nine times the area: 100
pounds become 900, and the small piston moves nine times as far.

The figures are the source deck's, from HowStuffWorks, in inches and pounds.

The travel budget is what limits the pedal ratio. Every millimeter of caliper piston travel costs
many millimeters of pedal, and the pedal hits the floor. That is why a car has a booster too.
-->

---
routeAlias: force-chain
---

## The force chain in the model

![Block chain: the foot's force F_ped goes into the pedal lever, times 3.5, BrakePedal; then the vacuum booster, times 5 up to run-out, StaticBooster; then the tandem master cylinder, p equals F over A_mc, TandemMasterCylinder; two circuits leave it toward lines and calipers, drawn dashed as not built yet, about 49 N·m per bar at the front axle and 20 at the rear.](/diagrams/02-force-chain.svg)

<div class="grid grid-cols-3 gap-6 text-sm mt-2">
<div>

**1 g stop** for the 1400 kg car: $m g r = 4256$ N·m at the wheels, which at 68.9 N·m/bar is
**61.8 bar**.

</div>
<div>

**Foot alone**, 500 N, the legal ceiling (FMVSS 135): **29.2 bar**, about **0.47 g**.

</div>
<div>

**With the booster**, 1 g needs **169 N** of pedal force.

</div>
</div>

<!--
This is the model in `dyad/Vehicle/Brake/`, joined by translational flanges exactly as the pushrods
join the parts in a car. Three blocks are built: `BrakePedal`, `StaticBooster`,
`TandemMasterCylinder`. The two circuits end in capped ports for now. Lines and calipers are the
next increment of the brake plan, `docs/brake-system-implementation-plan.md`.

The three numbers come from running notebook 02, cells "Why brakes need help" and the pressure
table. To stop at 1 g, the tire must push back with the car's weight, about 13 700 newtons; at
the 0.31 meter wheel radius that is 4256 newton meters. The report's caliper sizes, 57 millimeter
front and 38 millimeter rear pistons with a pad mu of 0.40, give 68.9 newton meters per bar,
49.0 front and 19.9 rear. The report marks these caliper values as textbook, unverified. So 1 g
needs 61.8 bar.

FMVSS 135, the US light-vehicle brake standard, caps the pedal force a test may use at 500
newtons. Through the 3.5 lever and the 25 millimeter master cylinder bore, with no booster, 500
newtons makes 29.2 bar: less than half a g. With vacuum assist, 169 newtons is enough for 1 g.
A failed booster costs deceleration, not the brakes.

Lever ratio 3.5 and servo ratio 5 are assumed values; the bore and the booster's diaphragm come
from the California PATH test car, report UCB-ITS-PRR-97-21.
-->

---
routeAlias: pedal-to-pressure
class: big-figure
---

## Pedal force to line pressure

<div class="grid grid-cols-[1.6fr_1fr] gap-6 items-center">
<div>

![Master-cylinder pressure against pedal force, 0 to 500 N: with idle vacuum, a jump at about 11 N to 6 bar, a steep boosted slope up to a run-out knee at 232 N and 84 bar, then a shallow slope; without vacuum, a single shallow line reaching about 29 bar at 500 N. A dotted line marks the 61.8 bar a 1 g stop needs.](/figures/02-pedal-to-pressure.svg)

</div>
<div class="text-[0.95rem]">

**Vacuum booster.** Vacuum on the front of a diaphragm, atmosphere let in behind it when the
driver pushes.

| landmark | model |
|---|---:|
| cut-in, jump-in | 11.4 N → 5.7 bar |
| boosted slope | 0.357 bar/N |
| run-out knee | 232 N, 84.3 bar |
| slope past run-out | 0.071 bar/N |
| no vacuum, 500 N | 29.2 bar |

</div>
</div>

<!--
The figure is the pressure plot of notebook 02, "Experiment: pedal force to line pressure", at
the default idle vacuum of 33 kilopascal absolute, with the no-vacuum curve dashed.

Read it left to right. Below the cut-in the booster's valve stays closed and nothing happens. At
cut-in the output jumps: the reaction disc has not touched the driver's plunger yet. Then every
newton of foot gives five newtons more at the master cylinder: the boosted slope. At run-out the
rear chamber is at full atmosphere and the diaphragm cannot push harder; past the knee only the
foot adds, at one fifth of the slope.

Where does the vacuum come from? A throttled petrol engine makes it for free in the intake
manifold, the same manifold pressure you met in Lecture 2. Diesels and turbo engines need a vacuum
pump. Electric cars use an electric vacuum pump or an electromechanical booster such as Bosch's
iBooster, which also lets the brake system blend in regenerative braking.

The pressures match the brake plan's hand calculations to better than 0.1 percent; the notebook
shows the comparison.
-->

---
routeAlias: master-cylinder
---

## Tandem master cylinder and two circuits

<div class="grid grid-cols-[1fr_1fr] gap-8">
<div>

![Inside the master cylinder: two reservoirs above one bore holding a primary piston, pushed from the pedal, and a secondary piston with springs, each feeding its own brake line.](/pptx/slide06-master-cylinder.jpg)

Two pistons in one bore. The pushrod drives the primary piston; its pressure drives the floating
secondary piston. In steady state both circuits carry the same pressure:

$$
p_{mc} = \frac{F_{rod} - F_{spring} - F_{seal}}{A_{mc}}
$$

</div>
<div>

![Two top views of a car. II split: one circuit brakes both front wheels, the other both rear wheels. X split: each circuit brakes one front wheel and the diagonally opposite rear wheel.](/diagrams/02-dual-circuit.svg)

If one circuit leaks, the other still brakes two wheels.

</div>
</div>

<!--
Since the late 1960s, cars have had two hydraulic circuits. If a line bursts, half the brakes still
work. The tandem master cylinder feeds both from one pedal: if the primary circuit leaks, the
primary piston travels until it touches the secondary and pushes it mechanically; if the secondary
leaks, the secondary piston bottoms out and the primary circuit still builds pressure. The driver
notices a longer pedal, not a dead one.

II, front and rear: losing the front circuit leaves only the rear brakes, which carry the smaller
share of a hard stop. X, diagonal: either failure keeps one front brake, about half the
capability, but braking one front wheel pulls the car toward that side. Front-wheel-drive cars
with a negative scrub radius in the steering geometry use the X split because the geometry
counters that pull.

In the model, `TandemMasterCylinder` uses the quasi-static form on the slide, with a 25 millimeter
bore from the PATH test car. Before pressure rises, each piston covers a dead stroke, 2.5
millimeters assumed, closing its compensating port to the reservoir.

The model's single lumped wheel cannot yaw, so it can show a failed circuit only as lost
deceleration and longer pedal travel, not as the pull.
-->

---
routeAlias: combination-valve
---

## The rest of the system

<div class="grid grid-cols-[1.2fr_1fr] gap-8">
<div>

![Brake system components in a car: pedal, booster, master cylinder, combination valve, brake lines, disc brakes at the front, drum brakes and the parking (emergency) brake at the rear.](/pptx/slide06-brake-components.jpg)

</div>
<div>

The **combination valve** of older cars does two jobs:

- **pressure differential switch**: lights a warning lamp when one circuit has lost pressure;
- **proportioning valve**: limits the rear pressure above a knee point, because in a hard stop
  load moves to the front axle and the rear wheels would lock first.

On cars with ABS the valve's second job has become software: **electronic brake-force
distribution (EBD)** uses the ABS valves to limit rear pressure.

</div>
</div>

<!--
The source deck's overview, again HowStuffWorks.

Why the rear needs less pressure: decelerating, the car pitches forward, and load moves from the
rear axle to the front. A rear tire with less normal load reaches its friction limit at less
brake torque. If the rear wheels lock before the front, the car becomes unstable: the rear swaps
ends. If the front wheels lock first, the car goes straight and cannot be steered, which is the
safer failure. Every brake system is therefore designed so the front locks first. A fixed
proportioning valve gets this right for one load; EBD, using the ABS hardware and wheel-speed
sensors, gets it right for any load. That is the first sign that ABS hardware does more than ABS.

The brake plan's increment 1c adds the proportioning valve and the ideal-against-installed brake
distribution plot to the model.
-->

---

## Summary of section 02

- The pedal lever and the vacuum booster multiply the foot's force; both pay for it in travel or
  in vacuum.
- The tandem master cylinder turns force into the same pressure in **two independent circuits**,
  split front/rear or diagonally.
- For the lecture's car, **62 bar** stops it at 1 g. A 500 N foot alone makes 29 bar; the
  booster brings 1 g down to 169 N.
- Rear pressure is limited so the front wheels lock first, by a valve or by EBD.

### Next: what happens when the driver asks for more than the tire can give. <Link to="abs">→ 03, anti-lock braking</Link>

<!--
So far the driver's demand goes straight to the wheel. In a panic stop the driver asks for far
more than the tire can carry, and the wheel locks. That is where ABS comes in.
-->
