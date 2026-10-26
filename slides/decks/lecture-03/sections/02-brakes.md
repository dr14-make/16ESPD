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
Budget: 30 minutes, 11 slides: lever 2, booster 2, pedal to pressure 2, force chain 2, load
transfer 2, master cylinder 1.5, the rest of the system 1.5, the parts you are given and build 02
16, summary 1. Keep the theory moving: the section ends with build 02, where the students wire the
whole chain, pedal to wheel, and stop their car with it.

The brakes transmit the force the driver applies to the pedal to the wheels using friction, at the
pads, and the tires pass it to the road using friction again. Three pieces of physics sit in
between: leverage, hydraulics and friction. This section follows a foot's force through them, with
the brake model in the repository as the running example.
-->

---
routeAlias: lever-and-hydraulics
---

## Leverage and hydraulics

![Three panels. Lever, times 3.5: a foot force of 100 N on the long arm, 3.5 a from the pivot, gives 350 N at the rod on the short arm a; the foot moves 35 mm, the rod 10 mm; BrakePedal, i_p 3.5. Pascal, times 5.2: the rod pushes a 25 mm piston with 350 N; the pressure, 7.1 bar, is the same everywhere in the fluid and lifts a 57 mm piston with 1820 N; the rod moves 10 mm, the large piston 1.9 mm. Together, times 18: the foot's 100 N on the pedal becomes 350 N at the master cylinder, 7.1 bar in the line and 1820 N at the caliper piston against the disc, with no booster and no springs.](/diagrams/02-lever-hydraulics.svg)

<div class="grid grid-cols-3 gap-6 text-sm mt-2">
<div>

**Lever.** Force times arm is the same on both sides: twice the arm, twice the force, half the
travel.

</div>
<div>

**Hydraulics.** Pressure is the same everywhere in a closed fluid (Pascal):
$F_2 = F_1 \, A_2 / A_1$. Again paid for in travel.

</div>
<div>

**Together.** The pedal multiplies the foot's force, the fluid multiplies it again at each caliper.

</div>
</div>

<!--
Neither the lever nor the fluid makes energy. Each trades travel for force. The lever: force times
distance is the same on both ends. The hydraulic cylinders: pressure is the same everywhere in the
fluid, so force scales with piston area, and the volume pushed out of the small piston equals the
volume taken in by the large one, so travel scales the other way.

The figure uses the model's own sizes, with no booster and no return springs. Left: the pedal
lever, `BrakePedal`'s ratio i_p of 3.5. The foot's arm is 3.5 a long, the rod's a, so 100
newtons at the foot become 350 at the rod, and the foot moves 35 millimeters for the rod's 10.
Middle: the rod pushes the master cylinder's 25 millimeter piston, `TandemMasterCylinder`'s
bore. 350 newtons on 4.9 square centimeters is 7.1 bar, everywhere in the fluid. The front
caliper's 57 millimeter piston has 5.2 times the area, 25.5 square centimeters, so it pushes
with 1820 newtons and moves 1.9 millimeters for the rod's 10. Right: both in series, 3.5 times
5.2, about 18 times the foot's force at each caliper piston, against the disc.

The travel budget is what limits the pedal ratio. Every millimeter of caliper piston travel costs
many millimeters of pedal, and the pedal hits the floor. That is why a car has a booster too.
-->

---
routeAlias: booster
---

## The vacuum booster

<div class="grid grid-cols-[1fr_1.25fr] gap-8 items-center">
<div>

A can split by a **diaphragm**. The front chamber holds **vacuum** from the engine, all the time.

- **At rest**: the rear holds vacuum too. No pressure difference, no push.
- **Press the pedal**: a valve lets **outside air** into the rear. The air pushes the diaphragm,
  and the rod with it, toward the master cylinder.
- The valve lets in just enough air for **5 ×** the rod's force. A rubber reaction disc feeds
  part of it back, so the foot still feels the brake.
- **Run-out**: the rear is at full atmosphere; from there only the foot adds.

$$
F_{max} = (p_{atm} - p_{vac})\,A_d - F_{spring} \approx 68\ \text{kPa} \times 533\ \text{cm}^2 \approx 3.5\ \text{kN}
$$

</div>
<div>

![Cutaway of a vacuum booster between the pedal's pushrod on the left and the master cylinder on the right. A diaphragm with a central plate splits the can: the rear chamber, on the pedal side, receives outside air through the valve on the pushrod when the driver presses, up to 101 kPa; the front chamber holds 33 kPa of vacuum through a hose and check valve to the engine's intake, and a return spring. Arrows show the pressure difference times the area pushing the diaphragm and the rod forward.](/diagrams/02-vacuum-booster.svg)

</div>
</div>

<!--
Budget: 2 minutes.

The lever slide ended on the travel budget: the pedal cannot multiply the force much more. The
booster adds force without adding travel, by borrowing it from the air.

The booster is a round can, about 26 centimeters across, between the pedal and the master
cylinder, split by a rubber diaphragm with a plate in the middle. The front chamber, on the master
cylinder's side, is connected by a hose to the engine's intake manifold, through a check valve
that only lets air out of the booster. So it always holds vacuum: 33 kilopascal absolute at idle,
a third of the atmosphere.

At rest the valve on the pushrod connects the two chambers, so the rear holds the same vacuum.
Equal pressure on both sides: no force. Press the pedal and the valve does two things: it closes
the link between the chambers and opens the rear to the outside air. Now the rear is at up to 101
kilopascal, the front at 33, and that difference pushes on the whole diaphragm: the plate and the
output rod go forward into the master cylinder, together with the force from the foot.

The valve is a follower. A rubber reaction disc between the plate and the output rod squeezes
back against the driver's plunger, so the valve lets in only as much air as gives five times the
input force, and the driver feels a firm pedal that grows with the braking. Lift the foot and the
valve reconnects the chambers, the engine pulls the air out, and the return spring pushes the
diaphragm back.

The formula is the limit. The difference between atmosphere and vacuum, 68 kilopascal, times the
diaphragm's 533 square centimeters is 3.6 kilonewtons, less the return spring's 97 newtons: 3.5
kilonewtons of help. Compare the lever slide: 100 newtons of foot made 350 at the rod. Once the
rear chamber is full of air, the booster has nothing more to give: that is run-out, 232 newtons
of foot in the model, the knee on the next slide.

In the model this is `Vehicle.Brake.StaticBooster`: the five-times slope, the jump-in and the
run-out, without the chambers filling. The diaphragm area, the idle vacuum and the spring preload
are PATH's test car, UCB-ITS-PRR-97-21; the servo ratio of 5 is assumed. Where the vacuum comes
from, and what happens when it runs out, is the optional slide after build 02.
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

The axes: pedal force in newtons across, master-cylinder pressure in bar up. The solid curve has
engine vacuum, the dashed one none; the dotted line is the 61.8 bar a 1 g stop needs, worked out
on the next slide.

Read it left to right. Below the cut-in, 11.4 newtons, the booster's valve stays closed and
nothing happens. At cut-in the output jumps to 5.7 bar: the reaction disc, the rubber disc that
feeds part of the output force back to the driver's foot, has not touched the driver's plunger
yet. Then the booster multiplies the force from the lever by five: the boosted slope. Where 0.357
bar per newton comes from: 3.5 for the lever times 5 for the booster, over the bore area of 4.91
square centimeters, is 0.357 bar for each newton of foot. At run-out, 232 newtons and 84.3 bar,
the rear chamber is at full atmosphere and the diaphragm cannot push harder; past the knee only
the foot adds, at one fifth of the slope, 0.071 bar per newton.

Where does the vacuum come from? A throttled petrol engine makes it for free in the intake
manifold, the same manifold pressure you met in Lecture 2. Diesels and turbo engines need a vacuum
pump. Electric cars use an electric vacuum pump or an electromechanical booster such as Bosch's
iBooster, which also lets the brake system blend in regenerative braking.

The pressures match the brake plan's hand calculations to better than 0.1 percent; the notebook
shows the comparison.
-->

---
routeAlias: force-chain
---

## The force chain in the model

![Block chain: the foot's force F_ped goes into the pedal lever, times 3.5, BrakePedal; then the vacuum booster, times 5 up to run-out, StaticBooster; then the tandem master cylinder, p equals F over A_mc, TandemMasterCylinder; two circuits, front and rear, each go through a line and a caliper, BrakeLine and BrakeCaliper, about 49 N·m per bar at the front axle and 20 at the rear; the rear circuit passes a dashed proportioning valve, times 0.43 above 45 bar, marked as in real cars but not in our model; both calipers sit in HydraulicBrakedWheel.](/diagrams/02-force-chain.svg)

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
join the parts in a car: `BrakePedal`, `StaticBooster`, `TandemMasterCylinder`, then per circuit
a `BrakeLine` and an axle's `BrakeCaliper`, joined by hydraulic ports. The two calipers sit in
`Vehicle.Wheel.HydraulicBrakedWheel`, between the wheel's inertia and the tire. Notebook 02 runs
the chain to the master cylinder, with both circuits capped; build 02, at the end of this
section, runs all of it on your car.

The three numbers come from running notebook 02, cells "Why brakes need help" and the pressure
table. To stop at 1 g, the tire must push back with the car's weight, about 13 700 newtons; at
the 0.31 meter wheel radius that is 4256 newton meters. The brake report's caliper sizes
(`docs/reports/Passenger car brake system modeling.md`), 57 millimeter
front and 38 millimeter rear pistons with a pad mu of 0.40, give 68.9 newton meters per bar,
49.0 front and 19.9 rear. The report marks these caliper values as textbook, unverified. So 1 g
needs 4256 over 68.9, 61.8 bar.

In the diagram, F ped is the foot's force on the pedal in newtons and A mc the area of the master
cylinder bore: 25 millimeters across, 4.91 square centimeters. The master cylinder's pressure is
the pushrod force over that area.

FMVSS 135, the US light-vehicle brake standard, caps the pedal force a test may use at 500
newtons. Through the 3.5 lever and the 25 millimeter master cylinder bore, with no booster, 500
newtons makes 29.2 bar: less than half a g. With vacuum assist, 169 newtons is enough for 1 g.
A failed booster costs deceleration, not the brakes.

Lever ratio 3.5 and servo ratio 5 are assumed values; the bore and the booster's diaphragm come
from the California PATH test car, report UCB-ITS-PRR-97-21.

The dashed box in the rear circuit is the proportioning valve a real car has there; our model
does not. Above a knee pressure it passes only part of any further increase to the rear, here 43
percent above 45 bar, aftermarket figures. Why the rear needs less is the next slide.
-->

---
routeAlias: load-transfer
---

## Braking tilts the car: front and rear

<div class="grid grid-cols-[1fr_1.2fr] gap-8 items-center">
<div>

The braking force acts at the road, the car's mass at height $h$ above it. The nose dips and
load moves from the rear axle to the front:

$$
\Delta F_z = \frac{m\,a\,h}{l}
$$

| 1400 kg car | front $F_z$ | rear $F_z$ |
|---|---:|---:|
| at rest | 8.2 kN | 5.5 kN |
| braking at 1 g | 11.1 kN | 2.6 kN |

A lighter rear tire locks at less torque. If **the rear locks first**, the car spins. So the rear
gets less pressure: a **proportioning valve** passes 43 % of the pressure above a knee of about
45 bar; with ABS, **EBD** does it in software.

</div>
<div>

![Side view of a car braking while it drives to the right: the nose dips; at the center of gravity, height h above the road, the inertial force m a points forward and the weight m g down; the braking forces at both tires point back; under the wheels, wheelbase l apart, the front normal load F z f plus delta F z is drawn much larger than the rear's F z r minus delta F z.](/diagrams/02-load-transfer.svg)

<div class="caption">l 2.6 m, h 0.55 m, 60 % on the front at rest (assumed); our model has no valve</div>

</div>
</div>

<!--
Budget: 2 minutes.

The force chain just split the pressure two ways, front and rear, and gave the front calipers
more than twice the torque per bar: 49 against 20 newton meters. Why not the same?

Braking, the tires push back at the road, but the car's mass sits 0.55 meters higher. The
inertia, m times a, acts at the center of gravity and tries to tip the car forward; the nose dips.
Take moments: the front axle carries more, the rear less, by m a h over the wheelbase l. For our
1400 kilogram car at 1 g that is 1400 times 9.81 times 0.55 over 2.6, 2.9 kilonewtons. The front
goes from 8.2 to 11.1, the rear from 5.5 to 2.6: the rear loses half its load.

A tire's grip is mu times its load. So the rear's limit falls as the braking gets harder, and the
front's rises. The ideal split, braking each axle in proportion to its load, moves from 60 percent
front at rest to 81 percent at 1 g. The calipers give a fixed 71 percent, which is ideal at only
one deceleration, 0.52 g. Brake harder and the rear has too much: on a dry road its wheels would
lock first, at about 0.8 g.

Why that matters: locked front wheels push the car straight on, it cannot be steered but stays
straight. Locked rear wheels have no side force either, so the rear swings out and the car spins.
Every brake system is designed for the front to lock first.

The fix in hardware is the proportioning valve in the rear line. Below a knee pressure it passes
the pressure through; above it, only a fraction of any further increase, 43 percent in the
aftermarket figures, with the knee at 41 to 48 bar. Some cars use a load-sensing valve linked to
the rear suspension, so a loaded car gets more rear pressure. With ABS the valve became software:
electronic brake-force distribution, EBD, holds the rear inlet valves once the rear wheels slip
more than the front, right for any load. The valve's hardware comes back two slides on, on
"The rest of the system".

Numbers: the wheelbase, the center-of-gravity height and the static split are assumed, from the
brake report, `docs/reports/Passenger car brake system modeling.md`, which also gives the 0.52 g
crossing; the valve's knee and slope are aftermarket figures, Brakes-shop and Wilwood, not OEM
data. Our model has no valve and no EBD: the one lumped wheel carries both axles' calipers under
one tire, so no axle can lock first. The planar car of section 03 has load transfer, off in the
runs shown.
-->

---
routeAlias: master-cylinder
---

## Tandem master cylinder and two circuits

<div class="grid grid-cols-[1fr_1fr] gap-8">
<div>

![Section of a tandem master cylinder, not to scale. The pushrod from the booster pushes the primary piston with F_rod into a 25 mm bore; a spring sits between it and the floating secondary piston, a second spring between that piston and the end of the bore. A reservoir with one compartment per circuit feeds each chamber through a compensating port just ahead of the piston seal; the gap from seal to port is the 2.5 mm dead stroke. Circuit 1 leaves the primary chamber, circuit 2 the secondary chamber, both at the same p_mc in steady state; in the model the ports are front and rear. TandemMasterCylinder: spring 138 N, seal 80 N.](/diagrams/02-tandem-master-cylinder.svg)

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

Read the formula: the pressure p mc, in pascals, is the pushrod force F rod, minus the return
spring's force F spring and the seal friction F seal, all in newtons, divided by the bore area A
mc in square meters. It holds in steady state, when the pistons are not accelerating.

The drawing is our model's cylinder, not to scale. The pushrod comes in from the left with
F_rod, the booster's output. The primary piston, then the primary spring, then the floating
secondary piston, then the secondary spring against the end of the 25 millimeter bore. Above it
the reservoir, one compartment per circuit, each joined to its chamber by a small compensating
port just ahead of the piston's seal: the orange 2.5 millimeters. Circuit 1 leaves the primary
chamber, circuit 2 the secondary; in our model they are the ports `front` and `rear`, both at
one `p_mc`. The 138 newtons are the spring preload `F_cs0` and the 80 newtons the seal friction
`F_cf` in the formula on the slide, both from the PATH test car.

In the model, `TandemMasterCylinder` uses this quasi-static form, with a 25 millimeter
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

Why the rear needs less pressure is the load-transfer slide: braking moves load to the front,
and the rear must not lock first. A fixed proportioning valve gets this right for one load; EBD,
using the ABS hardware and wheel-speed sensors, gets it right for any load. That is the first
sign that ABS hardware does more than ABS.

The course model has no proportioning valve and no EBD: its single lumped wheel carries both
axles' calipers under one tire, so no axle can lock first. The brake plan,
`docs/brake-system-implementation-plan.md`, lists the valve as a later step.
-->

---
routeAlias: given-parts
---

## The parts you are given

<div class="text-[0.85rem]">

| Part | In `PedalStop` | What it does |
| --- | --- | --- |
| `Brake.BrakePedal` | `pedal_unit` | a lever, × 3.5; the command 0–1 is the foot force over 500 N |
| `Brake.StaticBooster` | `booster` | vacuum assist, × 5 up to run-out at 232 N of foot; no chamber dynamics |
| `Brake.TandemMasterCylinder` | `master` | 25 mm bore: pushrod force to one pressure `p_mc` in `front` and `rear` |
| `Brake.BrakeLine` | `line_f`, `line_r` | a laminar line, 3 mm bore; 1.5 m front, 4 m rear |
| `Wheel.HydraulicBrakedWheel` | `wheel` | the four wheels as one: 4 kg·m², a `BrakeCaliper` per axle, 49.0 and 19.9 N·m/bar, and the `TireFrictionCurve` under the whole 13 729 N; out: the true slip `kappa` |
| `path medium` | in code | the brake fluid, DOT 4: 1045 kg/m³, 1.4 GPa; declared once, on the bench |
| `Step` | `command` | the driver's foot: 0 to `pedal` at 0.5 s |
| `Constant` | `road` | the road factor into `wheel.mu_scale` |
| `Fixed`, translational | `fixed_hydraulic` | ground for the pedal pivot and the two housings |
| `Fixed`, rotational | `fixed` | what the calipers push against |
| `VelocitySensor`, translational | `speed` | the car's speed, on `body.flange` |
| your `Body` | `body` | hands-on 1's: 1400 kg, drag and rolling resistance |

</div>

<div class="handson">→ Build 02 wires these; the guide's <b>Given parts</b> box at step 02 says what
each one models, its ports and where its numbers come from</div>

<!--
About a minute of build 02's sixteen. Every block in build 02 is a library part; the wiring is
yours. One line each, in the order the force goes: the lever, the booster, the master cylinder,
the two lines, the wheel with its two calipers and the tire. Then the fluid, the supports and the
sensor. Leave the slide up while the room places the blocks.

Where the values come from, if asked: the pedal lever, the booster's servo ratio, cut-in and
jump-in, the master cylinder's dead stroke and the line sizes are assumed, the course's choice.
The booster's diaphragm, vacuum and return spring, and the master cylinder's bore, spring and seal
friction, are from the California PATH brake test car, report UCB-ITS-PRR-97-21. The 500 newton
ceiling is FMVSS 135's. The caliper gains are textbook values, unverified: 57 and 38 millimeter
pistons, pad friction 0.40. The fluid is DOT 4 at room temperature. The derivations are in
`docs/reports/Passenger car brake system modeling.md`.
-->

---
routeAlias: build-pedal-stop
---

## Build 02: pedal to wheel

<div class="grid grid-cols-[1fr_1.15fr] gap-8 items-start">
<div>

![The finished PedalStop diagram: command, pedal_unit, booster and master from the left, fixed_hydraulic under the three housings, line_f and line_r into wheel, road and fixed under the wheel, speed and body on the right; the parameter panel shows pedal 0.6 and road_mu 1.0.](/img/lecture-03/step02-params.png)

*New `PedalStop`: `command` Step(`pedal` at 0.5 s) → `pedal_unit` BrakePedal → `booster` →
`master` → `line_f`, `line_r` (4 m) → `wheel` HydraulicBrakedWheel ← your `body` ·
`fixed_hydraulic` under the housings · `fixed`, `speed`, `road` · rename each block · in code,
the fluid and four `initial` lines · ▷ once, then run `pedal = 0.3` and 0.6*

**Given:** the previous slide's parts · your `Body`

[page: step 02](../lecture/lecture-03/#step-02) · reference `dyad/HandsOn03/PedalStop.dyad`

</div>
<div class="stack">

```txt
# above relations, one line:
path medium::HydraulicComponents.Interfaces.AbstractMedium =
    HydraulicComponents.IsothermalCompressible(…)
# in relations:
continuity(medium, master.front.medium)
```

```julia
using VehicleSystemsComponents: Vehicle
r = MyCar.PedalStopTransient(pedal = 0.3);  # then ()
plot(r; idxs = [r."master.p_mc", r."wheel.kappa"],
     layout = (2, 1))   # p_mc in Pa
Vehicle.braking_distance(r)
```

![Two panels against time at pedal 0.6. Top: car speed falls in a straight line from 90 km/h at 0.5 s to zero just before 4 s, while the wheel's surface speed drops to zero within 0.2 s. Bottom: wheel slip goes from 0 to -1 within 0.2 s of the pedal and stays there until the car stops. Title: hydraulic pedal stop, 43.7 m from 90 km/h.](/img/lecture-03/step02-locked-stop.svg)

<div class="handson">✓ 0.3, 150 N: <b>55 bar</b>, 3765 N·m, no lock, <b>36.0 m</b> · 0.6, 300 N:
<b>89 bar</b>, 6109 N·m, <code>wheel.kappa</code> −1, <b>43.7 m</b>: the no-ABS baseline</div>

</div>
</div>

<!--
Sixteen minutes, the parts slide included: the largest drawing of the day, twelve blocks and
fourteen wires, then two code pastes, the analysis and two runs. Your first build of the day with a
simulation in it: the brake system of this section, from the pedal to the wheel, stopping your own
car. Every block is a library part; the wiring is yours. The guide page, step 02, has the same
steps with every line of code; its "Do this" numbers are in brackets.

1. New component [1]. In the Components tree, right-click `MyCar`, Add Component, name it
   `PedalStop`. With nothing selected, click Edit Parameters in the diagram toolbar, Add
   parameter: `pedal`, Real, 0.6, the pedal command; `road_mu`, Real, 1.0, the road-friction
   multiplier. Right-clicking the canvas offers only a label, so use the toolbar.
   Check: the panel on the slide, `pedal` 0.6 and `road_mu` 1.0.

2. Place the twelve blocks, left to right [1]. Through +:
   - BlockComponents › Sources › `Step` → `command`: height `pedal`, start time 0.5, offset 0.
     The driver's foot. The pedal command runs from 0 to 1, the foot force as a fraction of the
     500 newton ceiling, the way a throttle command is a fraction of full throttle.
   - VehicleSystemsComponents › Vehicle › Brake › `BrakePedal` → `pedal_unit`, defaults.
   - … › Brake › `StaticBooster` → `booster`, defaults.
   - … › Brake › `TandemMasterCylinder` → `master`, defaults.
   - … › Brake › `BrakeLine` → `line_f`, defaults, 1.5 meters.
   - … › Brake › `BrakeLine` → `line_r`, L = 4.0: the rear line runs the length of the car.
   - VehicleSystemsComponents › Vehicle › Wheel › `HydraulicBrakedWheel` → `wheel`, defaults:
     the wheel's inertia, a front-axle and a rear-axle `BrakeCaliper`, and the tire, with the
     whole car's weight on it.
   - your own `Body` from hands-on 1 → `body`.
   - TranslationalComponents › Components › `Fixed` → `fixed_hydraulic`: ground for the pedal
     pivot and the booster and master-cylinder housings.
   - RotationalComponents › Components › `Fixed` → `fixed`: what the calipers push against.
   - TranslationalComponents › Sensors › `VelocitySensor` → `speed`.
   - BlockComponents › Sources › `Constant` → `road`, k = `road_mu`.
   Leave the parts slide up while the room places them.

3. Rename every block [2]. Studio names each block after its part, `step`, `brakepedal`,
   `tandemmastercylinder`, `fixed` and `fixed1`, `constant1`; rename each to the name above:
   select it, Edit Parameters, the pencil by the name. The code pastes and the snippets read
   these names. The two `Fixed` blocks in order: the translational one, with the green square
   port, to `fixed_hydraulic` first; only then the rotational one, the gray circle, to `fixed`,
   because a name still taken cannot be given.

4. Wire [3], fourteen wires in three groups. The reference file writes them as eleven `connect` lines, because two of them join several ports: the three housings to ground, and the wheel, body and speed sensor.
   - The force chain: `command.y` → `pedal_unit.u`, `pedal_unit.rod` → `booster.input`,
     `booster.rod_out` → `master.pushrod`.
   - The housings and the two circuits: `pedal_unit.support`, `booster.support` and
     `master.support` → `fixed_hydraulic.flange`; `master.front` → `line_f.port_a`,
     `line_f.port_b` → `wheel.front`; `master.rear` → `line_r.port_a`, `line_r.port_b` →
     `wheel.rear`; `wheel.support` → `fixed.spline`.
   - The wheel under the car: `road.y` → `wheel.mu_scale`, `wheel.flange` → `body.flange`, and
     `speed.flange` → the same `body.flange`.
   Check against the slide: the green tree under the three housings, the two blue circuits
   through the lines, the gray wire down to `fixed`, the three-way junction on the `wheel.flange` wire, left of `body`.

5. The brake fluid [4]. Toggle to code (⇄) and paste from the guide: the `path medium` line
   above relations, the `continuity` line inside them. Dyad cannot declare a fluid inside a
   library part, so the bench that assembles the circuit declares it; the connections carry the
   fluid from `master.front` to every port of both circuits. The slide shortens the medium's
   arguments; the guide has them in full: bulk modulus 1.4e9, density 1045, `let_gas = false`,
   DOT 4.
   Stall: "Invalid common set: In component PedalStop, no local specification or external
   connectors on which to determine value for the following common variables:
   master.front.medium, master.rear.medium, line_f.port_a.medium, …" means the fluid lines are
   missing; the command line says "Expected to find line_f.port_a.medium in at least one
   continuity graph". A compile error at the `path medium` line itself means
   `HydraulicComponents` was not added in build 00.

6. The starting state [4], four initial lines at the end of relations, from the guide: the wheel
   at angle zero, turning at 25 over 0.31 radians per second so it rolls at the car's speed; the
   body at position zero and 25 meters per second. Without them the wheel starts at rest.
   Stall: a wheel speed that climbs instead of falling means the initial lines are missing.

7. The analysis [5]. Below the component, in code, `PedalStopTransient` from the guide: 6
   seconds, Tsit5 with a maximum step of a millisecond, passing `pedal` and `road_mu` through.
   Stall: odd numbers or a suspicious success mean the analysis is not on Tsit5 with a maximum
   step of a millisecond. A stiff solver such as FBDF steps over the switching; it is the first
   thing to check whenever a number today is off.

8. Click ▷, Run Analysis, `PedalStopTransient`, once [6]: that loads `MyCar` into the REPL.
   Until then the snippet fails with "UndefVarError: PedalStopTransient not defined in
   Main.MyCar".

9. First run, `pedal = 0.3`, 150 newtons of foot, with the snippet on the slide [6]. The guide's
   version also plots `speed.v`. The plot's pressure axis is in pascals: 5.5 times ten to the six
   is 55 bar. The master cylinder reaches 55 bar and the calipers 3765 newton meters, under the
   4256 the tire can carry from step 01. The wheel never locks; its slip stays above minus 0.03.
   The car decelerates at about 0.87 g and stops 36.0 meters after the pedal; `braking_distance`
   measures from the pedal at 0.5 seconds until the car is below 0.5 meters per second. The front
   caliper's pressure rises from 10 to 90 percent in 4.4 milliseconds, and the master cylinder
   pushes 3.5 cubic centimeters of fluid into the two circuits.
   Stall: a pressure that stays at zero means a housing not on `fixed_hydraulic`, or the
   `command` wire on the wrong port.

10. Second run, the default, 0.6 [6]: `MyCar.PedalStopTransient()`. 300 newtons, past the
    booster's run-out at 232. 8.9 times ten to the six pascals, 89 bar, 6109 newton meters, 1.4
    times what the tire can carry. The wheel locks within two tenths of a second and the car
    slides to rest just before 4 seconds: 43.7 meters, just short of step 01's 45.5 meter sliding
    bound, because the wheel is not locked for the first moments and drag and rolling resistance
    help. The figure on the slide is this run. Remember 43.7: it is the no-ABS baseline every ABS
    today is measured against.

Put the two side by side: the harder foot stopped 7.7 meters longer. In a panic the driver presses
as hard as they can, and the wheel locks. That is the problem ABS solves, next section.

If the room runs long, hand out the guide's "Fell behind?" block and keep the two runs.

Expected, from `HandsOn03.PedalStopTransient`: at pedal 0.3, a peak master-cylinder pressure of
55.15 bar, 3765 newton meters, a minimum slip of minus 0.027, 35.97 meters and 3.51 cubic
centimeters. At 0.6, 89.16 bar, 6109 newton meters and 43.73 meters, at rest between 3.9 and 4.0
seconds. At road factors 0.5 and 0.3: 85.1 and 136.7 meters. The testset is "Hands-on 03 step 02:
hydraulic pedal stop" in `test/abs_handson_plausibility.jl`. The library twin, on a plain 1400
kilogram mass, is `Vehicle.Brake.TestHydraulicStop`. Reference: `HandsOn03.PedalStop`,
`dyad/HandsOn03/PedalStop.dyad`.
-->

---
routeAlias: vacuum-booster
---

## Where the assist comes from

<div class="grid grid-cols-[1fr_1.15fr] gap-6 items-start">
<div>

<img src="/figures/02-throttle-vacuum.svg" class="h-60 mx-auto" alt="Steady manifold absolute pressure against throttle opening, 0 to 50 percent, at 800, 2000 and 3000 rpm, with the booster's most assist on a second axis: closed throttle gives 33 kPa and 3.5 kN at idle, 18 kPa at 2000 rpm and 13.5 at 3000; by 20 percent opening the manifold is at 74 to 98 kPa, and above 40 percent close to ambient, with almost no assist left."/>

<img src="/img/lecture-03/full-car-vacuum.png" class="h-44 mx-auto mt-2" alt="FullCarVacuumStop in Studio. Along the top, throttle_pedal into the engine, then flywheel, clutch and variator, whose shaft runs right and down into the wheel; housing below them. Below, build 02's chain: command, pedal_unit, booster, master, line_f and line_r into wheel, with body and speed on the right and road feeding the wheel's friction. One teal hose runs from the engine's vacuum port down into the top of the booster."/>

</div>
<div>

![Stopping distance from 25 m/s at a 150 N pedal, by vacuum source: idle 38.4 m, wide-open throttle with a fresh reserve 39.5 m, wide-open throttle with the reserve spent 329 m, engine off with the reserve spent 435 m, electric pump starting from 40 kPa 39.3 m.](/figures/02-vacuum-stopping.svg)

The booster borrows **manifold vacuum**: 33 kPa at idle, almost none at wide-open throttle.
A **check valve** keeps the stored vacuum, about **two** assisted stops once the source is gone.

With a real engine feeding it (`FullCarVacuumStop`), lifting off at 90 km/h pulls the manifold
from 54 to 23 kPa: full assist, **39.2 m**.

</div>
</div>

<!--
Optional, 3 minutes. A lecturer demo, outside the run sheet's minutes: show it only if ahead.

The chart above the screenshot is the air path alone, at steady state: how much vacuum the
manifold holds at each throttle opening. Shut, the cylinders pump the manifold down to 33
kilopascal at idle and 13.5 at 3000 rpm, coasting. Open the throttle a fifth and the manifold is
nearly back at the atmosphere: the vacuum, and with it the booster's assist, the right axis, is
gone. A hard stop starts with the foot off the throttle, so the booster normally has its vacuum;
the store behind the check valve covers the rest. From `scripts/export_lecture03_vacuum_figures.jl`,
the same equations as `Vehicle.Engine.AirPath`.

Two models with the same brake chain as build 02: brake pedal, booster, master cylinder, two
brake lines, braked wheel. They differ in where the booster gets its vacuum. All pressures here
are absolute: the atmosphere is 101 kilopascal, and a lower number means a deeper vacuum.

The whole car in the picture: `Lecture3.FullCarVacuumStop`. Here the Hands-on 02 engine,
`HandsOn02.MapEngineFuelCut`, really drives the wheel, through its flywheel, the centrifugal
clutch and the CVT. One hose joins the engine to the booster, a `vacuum` port on each (next
slide): through it the booster sees the manifold pressure, and the air the booster draws out of
its front chamber flows back into the manifold. The story: the car cruises at 90 kilometers per hour with the throttle pedal at 0.0916,
about 9 percent; the engine turns 2182 rpm and the manifold sits at 54 kPa. At 0.5 seconds the
driver lifts off, so the throttle closes, and presses the brake with the same 150 newtons.

- Before lift-off the booster holds only the cruise vacuum, 54 kPa. That is good for 2.4
  kilonewtons of assist, just short of the 2.45 that 150 newtons asks for.
- With the throttle shut the engine pumps the manifold down: 33 kPa after 0.1 seconds, 23 kPa by
  1.5 seconds. The booster follows to 25 kPa, and its reserve grows to 4.0 kilonewtons. It gives
  the full 2.45 kilonewtons within half a second of the pedal going down, until the car stops.
- The car stops in 39.2 meters and 2.9 seconds, at the same 56 bar, against 38.4 for the bench.
  Started from the idle store of 33 kPa instead (`p_vac0 = 33e3`), the whole car needs 38.1: the
  engine's drag gains a quarter meter, and the half-empty cruise store costs a meter.
- The manifold never rises above its 54 kPa cruise value, far below the 101 of the atmosphere.
  After the stop the engine idles at about 770 rpm and the manifold settles near 34 kPa.

The bench behind the chart: `Lecture3.VacuumPedalStop`. It is build 02's `PedalStop` with
`Vehicle.Brake.VacuumBooster` in place of the static booster. Its "engine" is only the air path,
`Vehicle.Engine.AirPath`, held at a fixed throttle and a fixed engine speed. The switch `ev_pump`
picks the source: 0 the engine's manifold, 1 an electric pump, `Vehicle.Brake.ElectricVacuumPump`.
A small hose junction, `source`, joins the booster's hose to the one it picks and caps the other.
Every run uses the same brake pedal, `pedal = 0.3`, which is 150 newtons of foot force, from 25
meters per second, which is 90 kilometers per hour. The chart on the right comes from this bench.

1. Idle: 38.4 meters, 56 bar in the master cylinder, against 36.0 for the static booster of build
   02. The extra 2.4 meters are the booster filling its rear chamber, about 0.2 seconds.
2. Wide-open throttle, fresh store: the manifold is near ambient and the check valve shuts, but
   the booster still holds the 33 kPa it stored at idle: 39.5 meters, almost normal.
3. Store used up: each full application lets rear-chamber air into the front chamber. After the
   engine stops, four 400-newton applications leave 3.5, 2.1, 1.0 and 0.2 kilonewtons of assist,
   the service manuals' "two or three assisted stops". With none left, 150 newtons makes 4 bar
   instead of 56, and the car needs 435 meters with the engine off, 329 at wide-open throttle.
4. Electric pump, starting at its 40 kPa switch-on point: 39.3 meters. That is why diesels,
   hybrids and EVs carry one; Hella's UP28 pulls a 2.8-liter booster to 50 kPa in 6.7 seconds.

Live, if there is time, in the Studio REPL (compiled before class):

1. `using VehicleSystemsComponents: Lecture3, Vehicle`
2. `Vehicle.braking_distance(Lecture3.VacuumPedalStopTransient())`: 38.4.
3. `Vehicle.braking_distance(Lecture3.VacuumPedalStopTransient(engine_on = 0.0, n_apply = 4.0,
   stop = 60.0))`: 435, the reserve spent. `engine_on = 0` stops the engine and `n_apply = 4`
   means four full presses since it stopped. A minute of simulated time; give it a moment.
4. `Vehicle.braking_distance(Lecture3.FullCarVacuumStopTransient())`: 39.2. About a minute the
   first time.

At pedal 0.6 the wheel locks whatever the source while the store holds: 44.1 meters at idle and
45.4 for the whole car, against 43.7 for build 02.

The booster's geometry, valve thresholds and flow coefficients are PATH's, UCB-ITS-PRR-97-21.
The servo ratio, jump-in, cut-in and the valve's 10-newton dead band are assumed: PATH's 50
newtons would leave the booster 250 newtons short of the static characteristic. Figure:
`scripts/export_lecture03_vacuum_figures.jl`. The whole-car numbers are checked in
`test/vacuum_full_car.jl`.
-->

---
routeAlias: vacuum-port
---

## One hose, one connector

![Before and after. Before: the engine and the booster joined by two signal wires, the manifold pressure p_m into the booster's p_src one way, and the booster's air flow mdot_out back into the engine's mdot_bst; two wires for one hose, and the sign is yours to write. Now: one hose between a vacuum port on each, carrying the pressure p, the same at both ends, and the mass flow m-dot, counted into each part; connect(engine.vacuum, booster.vacuum) gives p_engine = p_booster and m-dot_engine + m-dot_booster = 0.](/diagrams/02-vacuum-port.svg)

<div class="grid grid-cols-3 gap-6 text-sm mt-2">
<div>

**Before:** two signal wires, the manifold pressure `p_m` to the booster and its air flow
`mdot_out` back. Each points one way, and the minus sign between "out" and "in" was ours to write.

</div>
<div>

**Now:** one connector, `Vehicle.GasPort`, as the brake line's hydraulic port and the spline:
a **potential** $p$, absolute pressure in Pa, and a **flow** $\dot m$, air in kg/s, counted
into each part.

</div>
<div>

**Why a flow:** a hose joint stores no air, so at every connection $\sum \dot m = 0$. One
`connect` writes that and $p_1 = p_2$; the physics, and the 39.2 m stop, are unchanged.

</div>
</div>

<!--
Optional, 2 minutes. A lecturer demo like the vacuum-booster slide, outside the run sheet's
minutes: show it right after that slide, and only if ahead.

Budget: 2 minutes, not counted in the section's 26.

What changed in the library. In a car one rubber hose joins the engine's intake manifold to the
vacuum booster. The model used to join them with two signal wires. The first carried `p_m`, the
manifold's absolute pressure in pascals, from the engine into the booster's input `p_src`: the
pressure on the far side of the booster's check valve. The second carried `mdot_out`, the air
mass flow in kilograms per second that the check valve lets out of the booster's front chamber,
back into the engine's input `mdot_bst`, where it adds to the air in the manifold. On the diagram
of `FullCarVacuumStop` that was two wires looping between engine and booster.

Now the manifold and the booster each have one port, `vacuum`, of the connector type
`Vehicle.GasPort`, and one line joins them: `connect(engine.vacuum, booster.vacuum)`. The
connector carries two variables. `p` is the absolute pressure at the end of the hose, in pascals.
It is a potential variable: every port on one connection has the same `p`, as both ends of a
short hose share one pressure. `mdot` is the air mass flow through the port in kilograms per
second, counted positive into the part that owns the port. It is a flow variable. The brake line's
hydraulic port is the same idea with pressure and mass flow of brake fluid; the spline is the
same idea with angle and torque.

Why the flow needs the sum-to-zero rule. For a flow variable, `connect` writes that all the flows
at the joint add up to zero. With each `mdot` counted into its own part, that says the air the
booster gives up is exactly the air the manifold takes in: a joint stores no air, so none is lost
or made there. If `connect` only made the two flows equal, both ends would say "in", and air would
appear from nothing. With signals, we wrote the minus sign ourselves, by calling one variable
`mdot_out` and the other `mdot_bst`. The connector writes it at every joint, also where three
hoses meet: the bench with the electric pump has a small junction with three ports, and the same
rule holds there.

Inside the parts nothing changed. The booster still computes `mdot_out = C_vm · max(0, p_f − p)`,
where `p_f` is its front-chamber pressure and `C_vm` the check valve's flow coefficient, and
sets its port's flow to minus that. The manifold sets its port's pressure to its own and adds the
port's flow to its mass balance. The whole car still stops in 39.2 meters, checked in
`test/vacuum_full_car.jl`. A port with nothing connected carries no flow, a capped hose: that is
why hands-on 2's engine simply leaves it open.

Ask the room, if there is time: why is pressure the potential and air flow the flow, and not the
other way round? *(Pressure is a level, the same on both sides of a joint; air flow is an amount
that moves through it and has to be conserved.)*
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
- On your car: pedal 0.3 stops in **36.0 m** without locking; pedal 0.6 locks the wheel,
  **43.7 m**.

### Next: what happens when the driver asks for more than the tire can give. <Link to="abs">→ 03, anti-lock braking</Link>

<!--
So far the driver's demand goes straight to the wheel. In a panic stop the driver asks for far
more than the tire can carry, and the wheel locks: your pedal 0.6 run. That is where ABS comes
in.
-->
