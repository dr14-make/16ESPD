---
routeAlias: car-and-regen
layout: section
---

###### Section 07

# The car and regen

The chain in the planar car, the motor as a brake, the three ceilings on regen, and series
blending onto Lecture 3's brakes.

The dry stop defaults to `withdraw = 0`: **36.22 m**, **49.32 %** motor braking
(**176.9/181.8 kJ** motor/friction), about half the stop. ABS withdrawal remains opt-in until
the gentle ABS calibration #156; WLTC is unchanged. The guide demonstrates the rule on
`Vehicle.Planar.PlanarBEVLowGripStopTransient()` / `HandsOn04.BEVLowGripStopTransient()`
(default `withdraw = 1`, `stop = 28`); compare `withdraw = 0, stop = 12`. Low-grip bench results:
275.02 m enabled, minimum front slip −0.04931 above 3 m/s; 112.35 m disabled with locked/reversing
wheels, **not a physical benchmark**.

`notebooks/lecture04/04-machine-battery-regen.pluto.jl`

<!--
Section 07, the car and regen. We put the chain into the planar car, then look at the motor as a
brake, at the three ceilings that limit how hard it can brake, and at how its braking is blended
with Lecture 3's friction brakes. There are two builds: the car, build 04, and regen, build 05. The
figures come from notebooks 03 and 04.
-->

---
routeAlias: drivetrain
---

## The car: machine → 8.193 → differential → front wheels

<div class="grid grid-cols-[1.5fr_1fr] gap-6 items-center">
<div class="diagram-wide">

![Top view of the planar car: the battery feeds the converter and a 300 W 12 V network; the converter drives the machine, which turns the 8.193 reduction and the differential between the front wheels. The driver's PI controller on the WLTC trace feeds a split or blend block, which sends a machine torque to the drive and the friction share to the four brakes.](/diagrams/07-bev-drivetrain.svg)

</div>
<div class="text-[0.95rem]">

$$
\omega_{m} = 8.193\;\frac{\omega_{fl} + \omega_{fr}}{2}
\qquad
\tau_{fl} = \tau_{fr} = \frac{8.193\;\tau_{m}}{2}
$$

**Torque in, current out.** The driver asks for a torque, the converter takes a current:

$$
i_{ref} = \frac{\tau_{ref}}{\text{field} \cdot K\Phi}
$$

Divided by the present field, a torque command means the same torque at any speed.

</div>
</div>

<!--
Builds 01 to 03 go into a car. The picture is a top view of the planar car, with its rear and front
axles labeled. The battery, 40 kilowatt-hours at 350 volts, from build 03, feeds the converter, from
build 02, and the 12 volt network, 300 watts. The converter drives the machine, from build 01. The
machine turns the 8.193 reduction, and the reduction turns the differential between the two front
wheels, which divides the torque by two. Then the controls: the driver, a PI controller on the WLTC
trace, feeds a block labeled split or blend, which is build 04's `TorqueSplit` or build 05's
`RegenBlend`. That block sends a machine torque to the drive, where it becomes a current command,
and the friction share to the brakes.

The first formula is the reduction and the differential together. The machine speed, omega m, is
8.193 times the average of the front-left and front-right wheel speeds, in radians per second. And
each front wheel gets the same torque: 8.193 times the machine torque, tau m, divided by two. The
differential splits its torque equally and lets the two wheels turn at different speeds in a curve.

The second formula: torque in, current out. The driver asks for a torque; the converter takes a
current command. The machine gives field times K Phi newton meters per ampere, so the drive asks the
converter for i ref equals tau ref divided by field times K Phi. Below base speed, about 48
kilometers per hour in this car, the field is 1. Above it the converter weakens the field, at 131
kilometers per hour to about a third, and the same torque then takes three times the current. A
field-oriented drive does the same with its q current. That is the last line of the slide: divided
by the present field, a torque command means the same torque at any speed. Divided by the full field
only, the drive would deliver a third of the torque asked for on the motorway, and the driver's loop
would lose gain with it.

Prepared for you in the course library: the planar car with the course road load, the WLTC bench
with its driver, the auxiliary load and the torque split.
-->

---
routeAlias: build-car
---

## Build 04: the car

<div class="grid grid-cols-[1fr_1.15fr] gap-8 items-start">
<div>

<img src="/img/lecture-04/step04-electric-drive.png" class="mx-auto" style="max-height: 16rem" alt="The finished ElectricDrive in Studio: battery and aux across one positive and one negative rail; converter from the positive rail into machine.p, its field into machine.field; machine into reduction into the spline port; battery.SoC up to the SoC port, tau_ref at the top left, support at the bottom."/>

*New `ElectricDrive`: parameters `ratio` 8.193, `P_aux` 300 · `battery`, `aux` AuxLoad,
`converter`, `machine` (`field_weakening = true`), `reduction` IdealGear, `ground` · one line:
`converter.i_ref = tau_ref / (converter.field * machine.k)` · new `BEVWLTC`: paste from the
guide · ▷ once, then plot*

**Given:** the planar car and road load, `DifferentialGear`, `AuxLoad`, `TorqueSplit`, the WLTC
bench

[page: step 04](../lecture/lecture-04/#step-04) · reference `dyad/HandsOn04/BEVWLTC.dyad`

</div>
<div class="stack">

```julia
r = MyCar.BEVWLTCTransient();
plot(r; idxs = [r."trace.y", r."kmh.y"])
plot(r; idxs = [r."drive.battery.i", r."drive.SoC",
     r."drive.converter.field"], layout = (3, 1))
r.sol[r."car.bus.x"][end], r.sol[r."drive.SoC"][end]
```

<div class="handson">✓ <code>kmh.y</code> on <code>trace.y</code> all the way: worst gap
<b>1.63 km/h</b>, inside WLTP's ±2 · <code>car.bus.x</code> <b>23 267 m</b> against the trace's
23 266 · never backwards at a stop</div>

<div class="handson">✓ <code>drive.battery.i</code> up to <b>138 A</b> (46 kW), down to <b>−86 A</b>
(31 kW charging) · <code>drive.SoC</code> <b>0.9 → 0.822</b> · field <b>1</b> below about
48 km/h, <b>0.36</b> at 131 km/h, 9260 rpm · torque asked at most <b>117 N·m</b></div>

</div>
</div>

<!--
Build 04: the car. On the left, the finished `ElectricDrive` in Studio. The battery and the
auxiliary load sit across one positive and one negative rail. The converter takes the positive rail
into the machine's p, and its field output goes into the machine's field input. The machine turns
the reduction, and the reduction ends at the drive's spline port. The battery's SoC goes up to the
SoC output port, the torque request, tau ref, comes in at the top left, and the support is at the
bottom.

The steps, in the italic line. A new component `ElectricDrive`, with two parameters: ratio, 8.193,
and P aux, 300 watts. It has four ports: the torque request, the output spline, the support, and the
SoC output. Then six parts from the guide's table, renamed: your battery; aux, the library's
`AuxLoad`, which draws whatever current makes 300 watts; your converter; your machine, with field
weakening set to true; a ground; and the reduction, an `IdealGear`, lossless, with the machine on
its fast side. Wire the DC side: the battery to the converter and the auxiliaries, all negative pins
to ground. The converter's output to the machine, the field across. The machine to the reduction,
the reduction to the drive's spline, the housings to the support, and SoC out. Then one line of
code, the torque-to-current conversion of the last slide: the converter's i ref equals tau ref over
`converter.field` times `machine.k`.

Then a new component `BEVWLTC`: paste it from the guide. It is the course library's planar WLTC
bench, with your drive on the front axle through the differential and a `TorqueSplit` between the
driver and the drive. Driving, the machine takes all of the driver's torque. Braking, the machine
takes it above 10 kilometers per hour and fades linearly to none at standstill, and the front
friction brakes take the rest, so that the car stops and is held at every stop without rolling back.
A machine asked to brake at standstill would drive the car backwards. Run Analysis once; the run
takes about 7 seconds once compiled.

The snippet plots the car's speed on the trace, then the battery current, the state of charge and
the converter's field, and reads the distance driven and the final state of charge.

The first green box: the speed, `kmh.y`, lies on the trace, `trace.y`, all the way. The worst gap is
1.63 kilometers per hour, inside the plus or minus 2 that WLTP allows. The distance, `car.bus.x`,
ends at 23 267 meters, against the trace's 23 266. And the car never rolls backwards at a stop.

The second green box: the battery current goes up to 138 amperes, 46 kilowatts, in the Extra High
phase, and down to minus 86 amperes, 31 kilowatts of charging, under braking. In between, the
auxiliaries alone draw 0.86 amperes. The state of charge falls from 0.9 to 0.822: 3.1 of the 40
kilowatt-hours. The field is 1 below about 48 kilometers per hour and 0.36 at 131, where the machine
turns 9260 rpm. And the driver never asks for more than 117 newton meters, which the machine
delivers at every speed to within 0.2.

If the car rolls backwards at the first stop, the machine is braking down to standstill: the split
is missing, or its fade is wrong. If a run reports success but the car never moves, that is the
standstill trap of the tire model: the bench starts the wheels turning just ahead of the car and
uses the Rodas5P solver for that reason, so keep both.
-->

---
routeAlias: build-car-checkpoint
class: big-figure
---

## Build 04 checkpoint: the WLTC, followed

![Two panels over the 1800 s WLTC: the car's speed lies on the trace through the Low, Medium, High and Extra High phases up to 131 km/h; the battery power swings between about 46 kW driving and about 31 kW charging under braking.](/figures/08-wltc-tracking.svg)

<div class="handson">✓ every negative dip of the battery power is braking energy coming back, with no
regen controller yet: <code>TorqueSplit</code> hands braking to the machine, fading out below
10 km/h, and the rest to the front brakes</div>

<!--
The checkpoint as a picture. The figure is notebook 03, section 1, the car follows the cycle: the
course library's `PlanarBEVWLTC`, the twin of your `BEVWLTC`, with the meters of build 06 on it. The
horizontal axis is time, 0 to 1800 seconds.

Top: the speed in kilometers per hour. The gray line is the WLTC trace, the blue line the car,
through the four phases, Low, Medium, High and Extra High, up to 131 kilometers per hour. At this
scale you cannot tell them apart.

Bottom: the battery power in kilowatts, in orange, positive when the battery delivers. It peaks at
about 46 kilowatts driving and dips to about 31 kilowatts of charging under braking. The dips are
small in town and large in the Extra High phase, where the car brakes from motorway speed.

The green box: every negative dip of the battery power is braking energy coming back, and there is
no regen controller yet. The `TorqueSplit` hands the braking to the machine, which fades out below
10 kilometers per hour, and the rest to the front brakes. A machine asked for a negative torque
simply generates. What build 05 adds is the limits, and the share for the friction brakes.
-->

---
routeAlias: motor-as-brake
---

## The motor as a brake

<div class="grid grid-cols-2 gap-8">
<div>

**Deck:** the motor keeps turning, its back-EMF drives a current the other way: the machine
**generates**. The deck burns it in a resistor; a converter instead pushes it **into the battery**.

Step 01 already did it: past *V*/*K*Φ, −304 N·m and −312 A back into the supply.

</div>
<div>

**What limits regen**

- **Speed.** At standstill there is no back-EMF to brake with; asked to brake there, the machine
  drives the car **backwards**.
- **Torque.** The machine's 320 N·m.
- **The battery.** How much charge power the pack takes, and less when it is full.
- **Grip.** Only the driven axle brakes.

Regen deceleration in real cars: **0.2–0.3 g** (Nissan e-Pedal, Bosch).

</div>
</div>

<!--
The motor as a brake. On the left, the deck: as the car brakes, the motor keeps turning, and its
back-EMF drives a current the other way, so the machine generates. The deck's circuit burns that
current in a resistor. A converter instead pushes it into the battery: build 02's converter, asked
for a negative current, reverses the power flow.

And build 01 already did it: past V over K Phi, the machine gave minus 304 newton meters and sent
312 amperes back into the supply.

On the right, what limits regen. Speed: at standstill there is no back-EMF to brake with, and a
machine asked to brake there drives the car backwards. Build 02 showed the other side: braking at
standstill, the supply has to pay the copper loss, 6.5 kilowatts. Torque: the machine's 320 newton
meters. The battery: how much charge power the pack accepts, and a full pack accepts less. And grip:
only the driven axle brakes electrically, so on our front-driven car the rear axle's share is always
friction.

The last line, regen deceleration in real cars: 0.2 to 0.3 g. Nissan's e-Pedal decelerates the Leaf
at up to 0.2 g when the driver lifts off. Bosch quotes up to 0.2 g of pure regenerative braking for
its ESP hev with a vacuum booster, and up to 0.3 g with its iBooster.
-->

---
routeAlias: three-ceilings
---

## Three ceilings

<div class="grid grid-cols-[1.25fr_1fr] gap-8">
<div class="tight">

| Limit | Torque at the machine | Value | Source |
|---|---|---|---|
| torque | τ<sub>max</sub> | 320 N·m | Nissan |
| charge power | *P*<sub>charge</sub> / ω | 80.5 kW | INL |
| low-speed fade | τ<sub>max</sub> · clamp(*v*/*v*<sub>fade</sub>, 0, 1) | *v*<sub>fade</sub> = 10 km/h | assumed |

$$
\tau_{regen} = \min\!\left(\tau_{demand},\ \tau_{max},\ \frac{P_{charge}}{\omega},\ \tau_{max}\,\mathrm{clamp}\!\left(\frac{v}{v_{fade}},0,1\right)\right)
$$

</div>
<div>

A **regenerative envelope**, the motoring one of section 04 mirrored:

- rising to 320 N·m at 10 km/h,
- flat down to the **corner**, where 320 N·m meets 80.5 kW: **34.3 km/h**,
- falling as 1/ω above it.

At 80 km/h: **137 N·m**, **0.25 g** of regenerative deceleration.

</div>
</div>

<!--
Build 05's `RegenBlend` gives the driver's brake demand to the machine first, up to the smallest of
three ceilings, each a torque at the machine. The table lists them.

The torque ceiling, tau max: 320 newton meters, the machine's peak, from Nissan. The charge-power
ceiling, P charge over omega: 80.5 kilowatts divided by the machine speed in radians per second, a
torque that falls as 1 over omega. The 80.5 kilowatts is Idaho National Laboratory's measured 10
second charge capability of a 2013 Leaf pack at 20 percent depth of discharge; the ZE1's larger pack
takes more. And the low-speed fade: tau max times v over v fade, clamped between 0 and 1, so below v
fade the ceiling falls linearly to zero and the machine never drives the car backwards. v fade is 10
kilometers per hour, and it is assumed: no primary source gives a fade speed, and the plan's band is
5 to 10.

The formula puts them together: the regen torque is the minimum of the demand and the three
ceilings. The machine speed omega is estimated from the car's speed: v in kilometers per hour,
divided by 3.6, times 8.193, divided by the 0.31 meter wheel radius.

On the right: the three ceilings draw a regenerative envelope, the motoring envelope of section 04
mirrored. It rises to 320 newton meters at 10 kilometers per hour, stays flat down from the corner,
where 320 newton meters meets 80.5 kilowatts, and falls as 1 over omega above the corner. The
corner: 80 500 watts over 320 newton meters is 251.6 radians per second at the machine, which is
34.3 kilometers per hour.

And at 80 kilometers per hour, where the hard stop starts: the machine turns 587 radians per second,
and 80 500 over 587 is 137 newton meters. At the wheels that is 137 times 8.193, 1123 newton meters,
3.6 kilonewtons on the road, which for 1500 kilograms is 0.25 g of regenerative deceleration, inside
the 0.2 to 0.3 g band of the last slide.
-->

---
routeAlias: blending
---

## Series or parallel blending

<div class="diagram-wide">

![Two sketches of braking torque against the driver's brake demand. Series: the machine takes all of the demand up to its limit, friction only the rest above it. Parallel: the machine and friction share every demand in a fixed ratio, and friction brakes even at a light demand the machine could have taken alone.](/diagrams/07-blending.svg)

</div>

<div class="grid grid-cols-2 gap-8 text-[0.95rem]">
<div>

**Series (cooperative):** regen takes everything up to its ceiling, friction the rest. It needs
the pedal decoupled from the hydraulics: brake-by-wire. The Leaf ZE1 has it; so does Bosch's
iBooster.

</div>
<div>

**Parallel:** friction and regen in a fixed or speed-dependent ratio, no decoupling. Simpler, and
it burns braking energy the machine could have recovered.

</div>
</div>

<!--
How should the machine and the friction brakes share the work? The literature names two strategies,
and the figure sketches both. Each panel plots braking torque against the driver's brake demand,
with the machine's limit marked. These are sketches, not results.

Left, series blending, also called cooperative: the machine takes all of the demand up to its limit,
and friction only the remainder above it. To do that, the pedal must not push the hydraulics
directly: a controller decides how much pressure to build. That needs brake-by-wire, or an
electromechanical booster. The Leaf ZE1's specification lists a cooperative regenerative brake with
electric control, and Bosch's iBooster makes the same possible.

Right, parallel blending: the machine and friction share every demand in a fixed or speed-dependent
ratio, with no decoupling. It is simpler, but on a light brake demand it burns energy in the pads
that the machine alone could have recovered. A benchmarking study found series blending clearly
ahead.

Our `RegenBlend` is series. The remainder goes to Lecture 3's brakes, divided equally over the four
wheels, through Lecture 3's ABS unit, unchanged. You build it next.
-->

---
routeAlias: build-regen
---

## Build 05: regen, blended onto the Lecture 3 brakes

<div class="grid grid-cols-[1fr_1.15fr] gap-8 items-start">
<div>

<img src="/img/lecture-04/step05-regen-blend.png" class="mx-auto" style="max-height: 21rem" alt="The finished BEVHardStop in Studio: pedal and kmh into blend; blend.tau_motor into drive, blend.tau_brake into the ABS; drive through the differential to the front wheels; slips and zero into the ABS, whose outputs drive the four brakes; motion reads the car's bus."/>

*New `RegenBlend`: parameters `ratio`, `radius`, `tau_max` 320, `P_charge` 80.5e3, `v_fade` 10 ·
two inputs, two outputs · its variables and equations in code · new `BEVHardStop` and
`BEVRegenWLTC`: paste from the guide · ▷ once each, then plot*

**Given:** Lecture 3's `ABSUnit`, `BusSlip`, your step 04 `ElectricDrive`

[page: step 05](../lecture/lecture-04/#step-05) · reference `dyad/HandsOn04/BEVHardStop.dyad`

</div>
<div class="stack">

```julia
r = MyCar.BEVHardStopTransient();
v = r.sol[r."kmh.y"]
plot(v, [r.sol[r."blend.tau_regen_max"] r.sol[r."blend.tau_regen"]];
     label = ["ceiling" "machine"], xflip = true)
kJ(x) = r.sol[x][end] / 1e3
kJ(r."E_shaft_in"), kJ(r."E_brake"), kJ(r."E_dc_in")
```

<div class="handson">✓ hard stop: 80 → 0 km/h in <b>2.7 s</b>, <b>33.0 m</b> · <code>blend.tau_regen</code>
<b>137</b> at 80 km/h, <b>320</b> from 34.3 to 10 km/h · machine <b>160.1 kJ</b>, friction
<b>193.2 kJ</b>: 45 / 55 % · <b>154.8 kJ</b> to the battery · <code>P_charge = 0.0</code>:
<b>26.9 m</b></div>

<div class="handson">✓ WLTC: <b>34.25 Wh/km</b> back of <b>143.6</b> traction: <b>23.85 %</b> · friction
0.001 Wh/km · <code>P_charge = 15.0e3</code>: <b>21.40 %</b>, friction 3.69 Wh/km</div>

</div>
</div>

<!--
Build 05: regen, blended onto the Lecture 3 brakes. On the left, the finished `BEVHardStop` in
Studio. The pedal and the speed in kilometers per hour go into the blend. The blend's machine torque
goes to your drive, and its brake torque into Lecture 3's ABS unit. The drive turns the front wheels
through the differential. The wheel slips and a zero go into the ABS, and its outputs drive the four
brakes. A motion block reads the car's bus.

The steps. A new component `RegenBlend`, with five parameters: ratio, 8.193; radius, 0.31; tau max,
320; P charge, 80.5 kilowatts; and v fade, 10. It has two inputs, the driver's torque and the speed
in kilometers per hour, and two outputs, the machine's torque and the torque for each of the four
friction brakes. In code go its variables and equations, the last slides in order: the machine speed
from the car's speed, the fade, the charge-power ceiling, the smallest of the three ceilings, the
demand as a positive braking torque, the regen torque as the smaller of the demand and the ceiling,
and the remainder, carried through the reduction and divided over four wheels. Driving torque passes
straight through to the machine. Then paste two benches from the guide. `BEVHardStop` is Lecture 3's
straight ABS stop, with your drive on the front axle and the blend between the driver's brake
command and the ABS. `BEVRegenWLTC` is build 04's bench with the blend in place of the split, the
friction share on all four brakes, and four energy meters. Run each analysis once.

The snippet runs the hard stop, plots the regen ceiling and the machine's regen torque against
speed, with the speed axis flipped so that the stop reads from left to right, and reads three
energies at the end in kilojoules: what the shaft took back, what the friction brakes burned, and
what reached the battery.

The first green box, the hard stop. From 80 to 0 kilometers per hour in 2.7 seconds, in 33.0 meters.
The regen torque, `blend.tau_regen`, is 137 newton meters at 80 kilometers per hour and 320 from
34.3 down to 10. The machine takes 160.1 kilojoules and friction 193.2: 45 and 55 percent. 154.8
kilojoules reach the battery. And with P charge set to 0, which turns regen off, the stop is 26.9
meters. If you also plot the friction brakes, the front-left one falls to zero during the stop and stays there until near standstill, where the fade hands it back; the rear-left carries
the friction share all the way, cycling under the ABS.

The second green box, the WLTC. 34.25 watt-hours per kilometer come back, of 143.6 of traction at
the shaft: 23.85 percent. The friction brakes burn 0.001 watt-hours per kilometer. With P charge at
15 kilowatts: 21.40 percent, and the friction brakes burn 3.69 watt-hours per kilometer, 9.5 percent
of the braking. The next three slides explain these numbers.
-->

---
routeAlias: hard-stop
class: big-figure
---

## The hard stop: the ceilings take turns

![Left: the machine's braking torque against car speed on Lecture 3's hard stop from 80 km/h, lying on the smallest of three ceilings: the charge-power curve 80.5 kW / ω above the corner at 34.3 km/h, the 320 N·m torque limit from there to 10 km/h, and the linear fade below. Right: speed against distance from the pedal; with regen and friction the car stops in 33.0 m, on friction alone in 26.9 m.](/figures/07-regen-hard-stop.svg)

<div class="handson">✓ your <code>blend.tau_regen</code> lies on the smallest ceiling: charge power above
34.3 km/h, 320 N·m down to 10 km/h, the fade below · battery up to <b>75.9 kW</b>, −205 A</div>

<!--
The hard stop, from notebook 04, section 4. It is Lecture 3's straight ABS stop from 80 kilometers
per hour, with build 05's blend. The driver asks each wheel for 2500 newton meters, 10 000 in all,
which is 1221 newton meters at the machine. That is about twice what the tires can carry, so the ABS
holds every wheel near its peak slip, and the demand is far above every ceiling.

Left panel: the horizontal axis is the car's speed in kilometers per hour, the vertical axis the
braking torque at the machine in newton meters. Read it from right to left, because the car slows
down. The gray lines are the three ceilings: dashed, the 320 newton meter torque limit; dotted, the
charge-power curve, 80.5 kilowatts over omega; dash-dotted, the fade below 10 kilometers per hour.
The thick blue line is the machine, regenerating. It lies exactly on the smallest ceiling all the
way: on the charge-power curve from 80 down to the corner at 34.3 kilometers per hour, 137 newton
meters at 80 and 183 at 60; flat on the torque limit from 34.3 down to 10; and on the fade below
that. The ceilings take turns, as the title says.

Right panel: the car's speed against the distance from the moment the pedal goes down. Blue is regen
plus friction: the car stops in 33.0 meters. Orange is the same stop with the charge limit set to
zero, on friction alone: 26.9 meters. With regen the stop is 6.1 meters longer. The remaining deficit is regen-under-ABS coordination (#140), not the friction-only stop.

The green box is what your run of build 05 shows: `blend.tau_regen` lies on the smallest ceiling,
the charge power above 34.3 kilometers per hour, 320 newton meters down to 10, and the fade below.
The battery charges at up to 75.9 kilowatts, minus 205 amperes. That is less than 80.5, because the
limit is on the machine's electromagnetic power, and the machine's, the converter's and the
battery's losses come off before the terminals.
-->

---
routeAlias: hard-stop-split
---

## Machine or friction: where the energy went

<div class="grid grid-cols-[1.6fr_1fr] gap-6 items-center">
<div>

![Energy over the hard stop in kJ, regen plus friction against friction only: the machine takes 160.1 kJ back through the reduction, against 0.85 on friction alone; the friction brakes burn 193.2 kJ, against 352.7; tire slip 27.3 against 34.6. Of the car's 381 kJ, the machine takes 45.3 % of the braking.](/figures/07-hard-stop-split.svg)

</div>
<div class="text-[0.95rem]">

The car starts with **380.7 kJ**. The machine takes **45 %** of the braking, friction **55 %**:
not most of it, because the hard stop asks for far more than the ceilings allow.

**154.8 kJ** reaches the battery: 43 Wh, about **320 m** of WLTC driving.

> **Outside the ABS loop.** The ABS modulates only the friction brakes. From about 62 km/h the
> machine's torque holds the front slip past the ABS's reapply threshold, so the front friction
> brakes stay off. A production system withdraws regen when the ABS acts; on a slippery road this
> machine would lock the front wheels.

</div>
</div>

<!--
Where did the energy go on the hard stop? The figure is notebook 04, section 4: the energy over the
stop in kilojoules, in three groups of bars. Blue is the stop with regen plus friction, orange the
stop on friction alone. The first group is the machine, the energy it took back through the
reduction; the second, the friction brakes; the third, tire slip.

With regen: the machine takes back 160.1 kilojoules, the friction brakes burn 193.2, and tire slip
takes 27.3. On friction alone: the machine almost nothing, 0.8, the friction brakes 352.7, and tire
slip 34.6.

The car starts with 380.7 kilojoules of kinetic energy in its body and wheels; the title rounds it
to 381. The machine, the brakes and the tires add up to that, to better than one part in a billion:
the meters close. The machine's share of the braking is 160.1 over 160.1 plus 193.2, 45.3 percent,
and friction's 54.7 percent. Not most of it, because the hard stop asks for far more than the ceilings allow.

Of the machine's share, 154.8 kilojoules reach the battery terminals: 43 watt-hours. At the 134.3
watt-hours per kilometer the car takes out of its cells on the WLTC, as section 08 shows, that is
about 320 meters of driving.

The quote box is a limit of our model, worth saying out loud. The machine sits outside the ABS loop.
The ABS reads the wheel slips and modulates only the friction brakes, and nothing withdraws the
regen torque when the ABS acts. On this dry stop, from about 62 kilometers per hour, the machine's
torque alone holds the front slip at minus 0.04 to minus 0.06, past the 0.03 at which the ABS
reapplies the brake. So the ABS keeps the front friction brakes released, and the front tires work
at about two thirds of their grip until, below 34 kilometers per hour, the machine's 320 newton
meters reaches it. A production brake system withdraws regen when the ABS acts. On a slippery road,
this machine alone would lock the front wheels.
-->

---
routeAlias: regen-on-wltc
---

## On WLTC, no ceiling binds

<div class="grid grid-cols-2 gap-8">
<div>

WLTC never decelerates harder than **1.5 m/s²**: at most **87 N·m** and **32 kW** at the
machine. Neither the torque nor the charge-power ceiling binds above walking pace.

Friction burns only what the fade leaves near standstill: **0.004 %** of the braking.

The battery gets back **23.85 %** of the traction energy: 34.25 Wh/km.

</div>
<div>

**Change one thing:** a 15 kW charge limit brings the share down to **21.40 %**, but only by
putting **9.5 %** of the braking on friction.

The regen path, not a ceiling, sets the share: section 08 sets it against the measured Leaf.

</div>
</div>

<!--
On the WLTC the blending hardly shows, and this slide says why. On the left: the cycle never
decelerates harder than 1.5 meters per second squared, 0.15 g. That asks at most 87 newton meters
and 32 kilowatts of the machine, far inside its 320 newton meters and 80.5 kilowatts. So neither the
torque nor the charge-power ceiling binds above walking pace, and the machine takes the whole
demand. The friction brakes burn only what the fade leaves near standstill, and hold the car at the
stops: 0.004 percent of the braking.

The battery gets back 23.85 percent of the traction energy: 34.25 watt-hours per kilometer into the
battery terminals, over 143.6 watt-hours per kilometer of traction delivered at the machine's shaft.
The shaft takes back 38.7 watt-hours per kilometer under braking, and 88.6 percent of that reaches
the battery.

On the right, change one thing: lower the charge limit to 15 kilowatts, and the share drops to 21.40
percent. But it gets there only by putting braking energy on friction, 9.5 percent of the braking,
more than twice the 4 percent the plan allows for friction on the WLTC.

So the last line: the regen path, not a ceiling, sets the share. What decides it is how much of the
braking energy the machine, the converter and the battery pass back, and section 08 sets that
against the measured Leaf. For comparison, build 04's simple torque split gave 23.80 percent on the
same cycle: on the WLTC, series blending changes the result by a twentieth of a point.
-->

---

## Summary of section 07

- The drive turns the driver's torque into a converter current at the present field; the car
  follows WLTC to **1.63 km/h** on **23 267 m**.
- A machine asked to brake generates. Regen is limited by **torque, charge power, a low-speed
  fade** and grip.
- **Series blending** gives the machine the demand first, friction the rest.
- Hard stop: the ceilings take turns; machine **45 %**, friction **55 %**, and the stop is
  **longer**, 33.0 m against 26.9 m.
- WLTC: no ceiling binds; **23.85 %** of the traction comes back.

### Next: add it all up. <Link to="energy-bill">→ 08, the energy bill</Link>

<!--
Section 07 in five lines. The drive turns the driver's torque into a converter current at the
present field, and the car follows the WLTC to within 1.63 kilometers per hour over 23 267 meters. A
machine asked to brake generates, and regen is limited by the machine's torque, the battery's charge
power, a low-speed fade, and grip. Series blending gives the machine the demand first and friction
the rest. On the hard stop the ceilings take turns, the machine takes 45 percent and friction 55,
and the stop is longer, 33.0 meters against 26.9. On the WLTC no ceiling binds, and 23.85 percent
of the traction comes back.

The car drives and brakes. What is left is to put a meter on every link and read where the energy
went.
-->

<!-- Issue #156: the 6.1 m regen penalty is the uncoordinated blend (#140), not a reason to detune ABS. -->
