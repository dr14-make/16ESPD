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
Budget: 26 minutes, 9 slides: lever 2, force chain 2, pedal to pressure 2, master cylinder 1.5,
the rest of the system 1.5, the parts you are given and build 02 16, summary 1. Keep the theory
moving: the section ends with
build 02, where the students wire the whole chain, pedal to wheel, and stop their car with it.

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

![Block chain: the foot's force F_ped goes into the pedal lever, times 3.5, BrakePedal; then the vacuum booster, times 5 up to run-out, StaticBooster; then the tandem master cylinder, p equals F over A_mc, TandemMasterCylinder; two circuits, front and rear, each go through a line and a caliper, BrakeLine and BrakeCaliper, about 49 N·m per bar at the front axle and 20 at the rear; both calipers sit in HydraulicBrakedWheel.](/diagrams/02-force-chain.svg)

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
eleven wires, then two code pastes, the analysis and two runs. Your first build of the day with a
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

4. Wire [3], eleven wires in three groups.
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
