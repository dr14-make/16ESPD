---
routeAlias: car-and-regen
layout: section
---

###### Section 07

# The car and regen

The chain in the planar car, the motor as a brake, the three ceilings on regen, and series
blending onto Lecture 3's brakes.

`notebooks/lecture04/04-machine-battery-regen.pluto.jl`

<!--
Budget: about 40 minutes, of which builds 04 and 05 take about 15 each: the drivetrain 3, build
04 15 including its checkpoint, the motor as a brake 2, three ceilings 3, blending 2, the hard
stop 3, the split 2, WLTC 2, build 05 15. Deck 7 slides 6 and 33, extended with the plan's S8.
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
Steps 01 to 03 go into a car. The battery feeds the converter, the converter the machine, the
machine turns the Leaf's single 8.193 reduction, and the reduction turns the planar car's
differential, which splits its torque equally between the two front wheels and lets them turn at
different speeds. The 12 V network hangs on the battery.

The driver is a PI controller on the WLTC trace, and its output is a machine torque. The drive
turns torque into current: the machine gives field times K Phi newton meters per ampere, so it
asks the converter for tau ref over that. Below base speed, about 48 km/h in this car, the field
is 1. Above it the converter weakens the field: at 131 km/h to about a third, and the same torque
takes three times the current. A field-oriented drive does the same with its q current. Divided by
full field only, the drive would give a third of the torque asked for on the motorway, and the
driver loop's gain would fall with it.

Prepared in the course library: the planar car with the course road load, the WLTC bench with the
driver and the standstill workaround, `AuxLoad` and `TorqueSplit`.
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
Fifteen minutes: a drive of seven parts, one code line, one pasted bench, one 1800 second run.

1. `ElectricDrive`: two parameters, four ports, six parts from the guide's table, renamed. Set the
   machine's field weakening to true. Wire the DC side: battery to converter and aux, all the
   negative pins to ground. Converter out to the machine, the field across. Machine to the
   reduction's spline a, the reduction's spline b to the drive's spline. The housings to support.
   SoC out.
2. The one line, the torque-to-current conversion at the present field.
3. `BEVWLTC`: paste from the guide. It is the course library's planar WLTC bench with your drive
   on the front axle through the differential, and `TorqueSplit` between the driver and the drive:
   driving, the machine takes all of it; braking, the machine takes it above 10 km/h and fades to
   none at standstill, with the front friction brakes taking the rest so the car stops and is
   held without rolling back.
4. Run Analysis, then the snippet. The run takes about 7 seconds once compiled.

Expected, from `HandsOn04.BEVWLTCTransient`: the car on the trace to within 1.63 km/h; 23 267
meters against 23 266; never backwards. Battery current from 138 amperes, 46 kW in the Extra High
phase, to minus 86, 31 kW charging under braking; the auxiliaries alone draw 0.86 ampere. SoC from
0.9 to 0.822: 3.1 kWh of the 40. Field 1 below about 48 km/h, 0.36 at 131 km/h where the machine
turns 9260 rpm. The driver never asks for more than 117 newton meters, and gets it to within 0.2.

Stall: a car that rolls backwards at the first stop has the machine braking to standstill: the
split is missing or its fade is wrong. A run that "succeeds" with the car frozen is the plan's S9
trap: the bench keeps the car off exact zero, and benches use Rodas5P.

Testsets: `test/bev_plausibility.jl`.
-->

---
routeAlias: build-car-checkpoint
class: big-figure
---

## Build 04 checkpoint: the WLTC, followed

![Two panels over the 1800 s WLTC: the car's speed lies on the trace through the Low, Medium, High and Extra High phases up to 131 km/h; the battery power swings between about 46 kW driving and about 31 kW charging under braking.](/figures/08-wltc-tracking.svg)

<div class="handson">✓ worst gap <b>1.63 km/h</b> · <b>23 267 m</b> · SoC <b>0.9 → 0.822</b> · every
negative dip of the battery power is energy coming back</div>

<!--
The figure is notebook 03, the energy-bill notebook, section 1, "The car follows the cycle": the
course library's `PlanarBEVWLTC`, the twin of your `BEVWLTC` with the meters of step 06.

Top: the trace in gray, the car on top of it; at this scale they cannot be told apart. Bottom: the
battery power. Every negative dip is braking: the machine turns generator and the pack charges.
The dips are small in town and large in the Extra High phase, where the car brakes from motorway
speed.

This is the moment to point out that the regen is already there in step 04, without any regen
controller: the machine asked for a negative torque simply generates. What step 05 adds is the
limits and the friction share.
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
Deck 7 slides 6 and 33. Slide 6: as the car brakes, the energy of motion is transferred to the
motor, the motor acts as a generator, and the electricity is stored in the battery. Slide 33 shows
the classic circuit: a switch moves the motor from the battery onto a load resistor, and the
motor's back-EMF drives current through it: dynamic braking. The deck notes that the generated
voltage depends on speed, so a DC-DC converter is needed to charge the battery. That converter is
step 02's: asked for a negative current, it reverses the power flow.

The limits. At low speed the back-EMF is small, and at standstill zero: a machine asked for a
negative torque there pushes the car backwards. Step 02 showed the other side: braking at
standstill, the supply pays the copper loss, 6.5 kW. The torque limit is the machine's 320 newton
meters. The battery limits the charge power, and a full battery takes less. And only the driven
wheels brake electrically: on a front-driven car, the rear axle's share is always friction.

The anchor: Nissan's e-Pedal decelerates the Leaf up to 0.2 g on lift-off; Bosch's ESP hev quotes
up to 0.2 g of pure regenerative braking with a vacuum booster and 0.3 with an iBooster.
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
The plan's S8, step 05's `RegenBlend`. The driver's brake demand goes to the machine first, up to
the smallest of three ceilings, each a torque at the machine.

The torque limit: 320 newton meters, the machine's peak, Nissan. The charge power: 80.5 kW, INL's
10 second charge capability of a 2013 Leaf pack at 20 percent depth of discharge; the ZE1's larger
pack takes more. Divided by the machine speed it is a torque that falls as 1 over omega. The fade:
below 10 km/h the machine's share falls linearly to zero, so it never drives the car backwards. No
primary source gives a fade speed; the plan's band is 5 to 10, and 10 is assumed.

The machine speed is estimated from the car's: v over 3.6, times 8.193, over the 0.31 meter wheel
radius.

The checkpoints worked: at 80 km/h the machine turns 587 radians per second, and 80 500 over 587
is 137 newton meters. At the wheels that is 1123, 3.6 kN on the road, 0.25 g: inside the 0.2 to
0.3 g band. The corner: 80 500 over 320 is 251.6 radians per second, 34.3 km/h.
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
Two strategies from the literature: Gao and Ehsani, and Ehsani's textbook's regen chapter.

Series blending: the machine takes the whole demand while it can, and the friction brakes only
the remainder. To do that the pedal must not push the hydraulics directly: the controller decides
how much pressure to build. That needs brake-by-wire, or an electromechanical booster such as
Bosch's iBooster, which Lecture 3 mentioned. Nissan's ZE1 spec sheet lists a cooperative regen
brake with electric control.

Parallel blending: the friction brakes work as always, and the machine adds a share on top. No
decoupling, cheaper, and on a light brake demand it burns energy in the pads that the machine
alone could have recovered. Benchmarks found series clearly ahead.

Our `RegenBlend` is series: the remainder goes to Lecture 3's equal per-wheel demand, through its
ABS unit, unchanged.

The sketches are diagrams, not results: the results are the next slides.
-->

---
routeAlias: hard-stop
class: big-figure
---

## The hard stop: the ceilings take turns

![Left: the machine's braking torque against car speed on Lecture 3's hard stop from 80 km/h, lying on the smallest of three ceilings: the charge-power curve 80.5 kW / ω above the corner at 34.3 km/h, the 320 N·m torque limit from there to 10 km/h, and the linear fade below. Right: speed against distance from the pedal; with regen and friction the car stops in 36.2 m, on friction alone in 38.8 m.](/figures/07-regen-hard-stop.svg)

<div class="handson">✓ <b>137 N·m</b> at 80 km/h, 183 at 60: charge power · <b>320 N·m</b> from 34.3 to
10 km/h · the fade below · battery up to <b>75.9 kW</b>, −205 A · <b>36.2 m</b>, against 38.8 m on friction alone</div>

<!--
The figure is notebook 04 section 4: the course library's `PlanarBEVHardStop`, Lecture 3's
straight ABS stop from 80 km/h with step 05's blend, and the same stop with the charge limit at
zero, friction alone.

The driver asks each wheel for 2500 newton meters, 1221 at the machine: twice what the tires can
carry, so the ABS holds every wheel near its peak slip, and the demand is far above every ceiling.
So the machine regenerates exactly the envelope, left: the charge-power curve at high speed, 137
newton meters at 80 km/h and 183 at 60; the torque limit from the corner at 34.3 down to 10 km/h;
then the fade. The battery charges at up to 75.9 kW, 205 amperes, less than the 80.5 limit,
because the limit is on the machine's power and the losses come off before the terminals.

Right: the stop is shorter with regen, 36.2 meters against 38.8. On friction
alone the front ABS works the front tires at about 62 percent of their grip; below the corner speed
the machine's steady 320 newton meters holds them at 93 percent. The machine is a smoother
modulator than the ABS's valves.
-->

---
routeAlias: hard-stop-split
---

## Machine or friction: where the energy went

<div class="grid grid-cols-[1.6fr_1fr] gap-6 items-center">
<div>

![Energy over the hard stop in kJ, regen plus friction against friction only: the machine takes 176.9 kJ back through the reduction, against 0.8 on friction alone; the friction brakes burn 181.8 kJ, against 366.8; tire slip 22.0 against 19.8. Of the car's 381 kJ, the machine takes 49.3 % of the braking.](/figures/07-hard-stop-split.svg)

</div>
<div class="text-[0.95rem]">

The car starts with **380.7 kJ**. The machine takes **49 %** of the braking, friction **51 %**:
not most of it, because the hard stop asks for far more than the ceilings allow.

**170.2 kJ** reaches the battery: 47 Wh, about **350 m** of WLTC driving.

> **Outside the ABS loop.** The ABS modulates only the friction brakes. From about 62 km/h the
> machine's torque holds the front slip past the ABS's reapply threshold, so the front friction
> brakes stay off. A production system withdraws regen when the ABS acts; on a slippery road this
> machine would lock the front wheels.

</div>
</div>

<!--
Notebook 04 section 4, the energy split. The hard stop's meters, read at the end: the machine
takes back 176.9 kJ through the reduction, the friction brakes burn 181.8, tire slip 22.0. They
add up to the 380.7 kJ the car started with in body and wheels, to under 10 to the minus 9 of it.
The machine's share: 49.3 percent.

On friction alone, the orange bars, the friction brakes burn 366.8 kJ and the machine takes back
almost nothing, 0.8 kJ.

170.2 kJ reaches the battery terminals: 47 watt-hours, about 350 meters of WLTC at 131 Wh/km.

The box is a known limit worth saying out loud. The machine sits outside the ABS loop: the ABS
reads the slips and modulates the friction brakes, and nothing withdraws the regen when it acts.
On the dry hard stop, from about 62 km/h the machine's torque keeps the front slip at minus 0.04
to minus 0.06, past the 0.03 at which the ABS reapplies, so the ABS holds the front friction brakes
released and the front tires work at about 65 percent of their grip until the machine's 320 newton
meters reaches it below 34 km/h. On a low-µ road the machine alone would lock the front wheels.
Production systems withdraw regen when the ABS acts.
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

**Against the anchor: 18–25 %.** A quarter of the traction comes back as braking; the measured
Leaf's regen path recovers **70–87 %** of it (Boretti), ours **88.6 %**: an ideal reduction.

**Change one thing:** a 15 kW charge limit brings the share down to **21.40 %**, inside the
measured cars' range, but the friction brakes then burn **9.5 %** of the braking.

</div>
</div>

<!--
Why the blending lesson needs the hard stop: on the WLTC it hardly shows. The cycle's hardest
deceleration is 1.5 meters per second squared, 0.15 g: 87 newton meters and 32 kW at the machine,
far inside the 320 and 80.5. So above walking pace the machine takes the whole demand, and
friction only the fade's leftovers and the hold at standstill: 0.004 percent of the braking.

The recovered share: 34.25 Wh per km back into the battery terminals, over 143.6 Wh per km of
traction at the shaft, 23.85 percent. Inside the plan's 18 to 25, in its upper half. The band is
derived: 25 to 26 percent of the traction is braking energy, and Boretti measured the 2012 and
2013 Leaf's regen path, braking at the vehicle to the battery, at 70 to 87 percent. Ours lets
88.6 percent through: the reduction and the differential are lossless.

The variation in the guide: lower the charge limit to 15 kW and the share drops to 21.40, the
measured car's range, but only by burning braking energy on friction, 9.5 percent of it, above the
plan's 4 percent. The gap to the measured car is the regen path's efficiency, not a limit.

Against step 04's `TorqueSplit`: 23.80 percent; series blending changes the WLTC by a twentieth of
a point.
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

<div class="handson">✓ hard stop: 80 → 0 km/h in <b>3.0 s</b>, <b>36.2 m</b> · <code>blend.tau_regen</code>
<b>137</b> at 80 km/h, <b>320</b> from 34.3 to 10 km/h · machine <b>176.9 kJ</b>, friction
<b>181.8 kJ</b>: 49 / 51 % · <b>170.2 kJ</b> to the battery · <code>P_charge = 0.0</code>:
<b>38.8 m</b></div>

<div class="handson">✓ WLTC: <b>34.25 Wh/km</b> back of <b>143.6</b> traction: <b>23.85 %</b> · friction
0.001 Wh/km · <code>P_charge = 15.0e3</code>: <b>21.40 %</b>, friction 3.69 Wh/km</div>

</div>
</div>

<!--
Fifteen minutes: one small block with five equations, two pasted benches, two runs and two
variations.

1. `RegenBlend`: five parameters, two inputs, the driver's torque and the speed in km/h, two
   outputs, the machine's torque and each of the four friction brakes' torque. In code: the
   machine speed from the car's, the fade, the charge-power ceiling, the smallest of the three,
   the demand as a positive braking torque, the regen as the smaller of demand and ceiling, and
   the remainder through the reduction, divided over four wheels. Driving passes straight
   through.
2. `BEVHardStop`: Lecture 3's straight ABS stop, with your drive on the front axle and the blend
   between the driver's brake command and the ABS unit. Paste.
3. `BEVRegenWLTC`: step 04's bench with the blend in place of the split, the friction share on
   all four brakes, and four meters. Paste.

Expected, from `HandsOn04.BEVHardStopTransient`: 80 to 0 km/h in 3.0 seconds after the pedal,
36.2 meters. The regen torque follows the envelope: 137 at 80 km/h, 183 at 60, 320 from 34.3 to
10, the fade below. The battery charges at up to 75.9 kW, minus 205 amperes. The front-left
friction brake falls to zero from about 62 km/h and stays there down to 10 km/h, where the fade
hands it back; the rear-left carries the friction share all the way, cycling under the ABS.
Machine 176.9 kJ, friction 181.8, battery 170.2. With
the charge limit at zero: 38.8 meters.

From `HandsOn04.BEVRegenWLTCTransient`: 34.25 Wh/km back of 143.6 of traction, 23.85 percent; the
shaft took back 38.7 and 88.6 percent of that reached the battery; friction 0.001 Wh/km. At a 15
kW charge limit: 21.40 percent, friction 3.69 Wh/km, 9.5 percent of the braking.

Testsets: `test/regen_plausibility.jl`.
-->

---

## Summary of section 07

- The drive turns the driver's torque into a converter current at the present field; the car
  follows WLTC to **1.63 km/h** on **23 267 m**.
- A machine asked to brake generates. Regen is limited by **torque, charge power, a low-speed
  fade** and grip.
- **Series blending** gives the machine the demand first, friction the rest.
- Hard stop: the ceilings take turns; machine **49 %**, friction **51 %**, and the stop is
  **shorter**, 36.2 m against 38.8 m.
- WLTC: no ceiling binds; **23.85 %** of the traction comes back.

### Next: add it all up. <Link to="energy-bill">→ 08, the energy bill</Link>

<!--
One minute. The car drives and brakes. What is left is to put a meter on every link and read where
the energy went.
-->
