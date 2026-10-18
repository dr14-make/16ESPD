---
routeAlias: sensors
layout: section
---

###### Section 04

# Sensors

How sensors are classified and what they must withstand; the ones the engine runs on: throttle,
crank and cam, temperature, air mass and pressure, knock; and how the ECU checks them.

<!--
The ECU only knows what its sensors tell it. We classify sensors first, then look at the engine
control system as a whole, then at the sensors one by one: the throttle, the magnetic sensors and
the crank wheel they read, temperature, air mass and pressure, and knock. The last slide collects
how the ECU checks them.
-->

---
routeAlias: automotive-sensors
class: big-figure
---

## Automotive sensors

A sensor converts a physical or chemical (usually non-electric) quantity $\Phi$ into an electric
quantity $E$.

![The automotive sensor in its loop: the physical quantity Φ from the vehicle enters the measuring sensor MS; the adapter circuit AD turns it into the electrical quantity E for the ECU, which also takes other sensors and ECUs (SE/ECU) and a switch SA, and drives a display DPL. The ECU's output goes through the driver D to the final controlling element FCE, which together form the actuator AC, and acts on the vehicle. Disturbances Z enter the measuring sensor and the adapter circuit.](/diagrams/04-automotive-sensor.svg)

<!--
This is the loop from section 03 with the sensor and the actuator opened up. The physical quantity
phi enters the measuring sensor, an adapter circuit makes it an electrical signal E, the ECU
computes, a driver amplifies, and a final controlling element, the actuator, acts on the vehicle.
Z marks the disturbances that get into the sensor and its adapter: temperature, supply voltage,
interference.

The ECU also takes signals that are not from this sensor: other sensors and other ECUs over the
bus, and plain switches. And it can drive a display.

Redrawn from Bosch's "Figure 3, Automotive sensor", which the source deck scanned: the same blocks
and the same abbreviations, written out in full beside each one.
-->

---
routeAlias: sensor-classification
---

## Sensor classification

<div class="grid grid-cols-[0.75fr_2fr] gap-6 items-center">
<div>

- Assignment and application
  - functional · safety · monitoring
- Type of characteristic curve
  - continuous linear
  - continuous non-linear
  - discontinuous
- Type of output signal
  - current, voltage, amplitude
  - frequency
  - pulse duration

</div>
<div>

<CardExport notebook="illustrations" name="sensor-classification" height="33rem" />

<div class="caption">Idealized curves; the NTC points are the Bosch Motorsport NTC M12 datasheet's</div>

</div>
</div>

<!--
The top row is the characteristic curve, output against measured quantity, with a real sensor of
each kind. A throttle potentiometer is continuous and linear: half a volt closed, four and a half
volts at ninety degrees. A temperature sensor is continuous and non-linear: this is the NTC we meet
again in a few slides, 45 kilo-ohms at minus 40, under 100 ohms at 130. A switching oxygen sensor
is discontinuous: about 0.85 volts rich, 0.1 volts lean, and the jump sits at lambda one.

The bottom row is how the value travels down the wire. Amplitude: the voltage itself is the value,
here the potentiometer through a tip-in. Frequency: a Hall wheel-speed sensor gives one pulse per
tooth, so the pulse rate is the speed; here the wheel accelerates from about 30 to 60 kilometers
per hour on a 48-tooth ring, 200 to 400 pulses a second, compressed to fifty milliseconds. Pulse
duration: a fixed carrier whose duty cycle carries the value. Frequency and pulse width survive a
long, noisy wire far better than a voltage level does.

These replace the scanned Bosch sketches of curve types and signal shapes. The curves are drawn
from explicit functions in the illustrations notebook, not from any model: idealized shapes,
except the NTC points, which are the datasheet's. The source sketch also showed a multistage
characteristic and a two-stage switch with hysteresis; the switching lambda sensor stands for both.
-->

---

## Sensor requirements

- **Operating conditions**: mechanical, climatic, chemical, electromagnetic
- **Reliability classes**
  1. steering, brakes, passenger protection
  2. engine, driveline, suspension, tires
  3. comfort and convenience, information, diagnostics, theft detection
- **Size, miniaturization concepts**
  - semiconductor technology (Hall effect)
  - surface and bulk micromechanics (acceleration and yaw sensors)
  - microsystem technology (micromechanical or micro-optical systems)
- **Manufacturing cost**
- **Accuracy requirements**
- **Integration level**

<!--
A sensor in a car lives next to a hot engine, gets splashed with salt water, shaken, and sits beside
an ignition coil firing tens of kilovolts. And it costs a few euros, because there are dozens of
them.

The reliability classes are ordered by consequence of failure. Steering and brakes first, engine
second, comfort last. Engine sensors are the middle class: a failure must not stop the car, so the
ECU has a substitute value for each one.
-->

---
routeAlias: basic-control-system
---

## A basic engine control system

<div class="grid grid-cols-[1.5fr_1fr] gap-6 items-center">
<div>

![Layout of a basic engine control system with 21 numbered components: control unit, throttle body, air-flow sensor, injectors, spark plug, sensors on the engine, oxygen sensors on either side of the catalytic converter, and the fuel and vapor system.](/pptx/slide32-engine-control-layout.png)

</div>
<div class="text-xs">

1. Engine control unit
2. Diagnostic harness
3. Check engine light
4. Throttle position sensor
5. Mass air flow sensor
6. Idle run regulation
7. Fuel pressure valve
8. Injectors
9. Spark plug
10. Phase sensor
11. Detonation (knock) sensor
12. Engine temperature sensor
13. Ignition module (coil)
14. Crankshaft position sensor
15. Oxygen sensor
16. Second oxygen sensor
17. Regeneration (vapor) valve
18. Charcoal absorber
19. Fuel filter
20. Fuel pump / fuel level sensor
21. Catalytic converter

</div>
</div>

<!--
Every part of today's lecture on one drawing. Follow the air: in through the mass air flow sensor,
5, past the throttle and its position sensor, 4, into the manifold, where the injectors, 8, add
fuel. The spark plug, 9, fired by the coil, 13, ignites it. The crankshaft sensor, 14, and the phase
sensor, 10, tell the ECU where each piston is. The knock sensor, 11, listens for detonation.

Then the exhaust: oxygen sensor 15 before the catalyst, 21, and the second, 16, after it. And the
fuel vapor path: tank, charcoal absorber, 18, and the purge valve, 17, back into the intake. That
is section 07.
-->

---

## Position and angular position sensors

- Measure one- or multi-dimensional displacement and angular position
  - accelerator and brake pedal position sensor
  - throttle valve position sensor
  - fuel tank level
  - steering wheel angle
- **Mechanical**
  - a proportional relationship between position and the length of a wire or conductive-film
    resistor
- The trend is toward **wear-free sensors** (contactless, proximity sensors)

<!--
The simplest position sensor is a potentiometer: a wiper slides along a resistive track, and the
voltage at the wiper is proportional to position. Cheap and accurate, but the wiper wears. That is
why the industry is moving to contactless sensors, three slides on.
-->

---
routeAlias: tps
---

## Throttle position sensor (TPS)

<div class="grid grid-cols-[1fr_1.3fr] gap-6">
<div>

- A variable resistor connected to the throttle plate
  - **two tracks** on one shaft: V1 rises, V2 falls, and **V1 + V2 = 5 V** at every angle
  - each track reads 0.5–4.5 V; outside that window is a short or an open circuit
- Today electronic throttles are used
  - only the accelerator pedal has a sensor, and the throttle plate is moved by a DC motor:
    electronic throttle control (ETC), or "drive by wire"
  - the throttle position sensor then closes the motor's position loop, and its second track
    is kept for diagnosis

<div class="stack mt-2">

![A throttle body with its position sensor mounted on the shaft.](/pptx/slide34-throttle-body.jpeg)

</div>
</div>
<div>

<div class="diagram-short">

![The dual-track throttle position sensor: two potentiometer tracks between 5 V and ground, each with an end resistor at both ends; one throttle shaft moves both wipers, track 1's voltage V1 rises as the plate opens and track 2's V2 falls, so V1 + V2 = 5 V at every angle.](/diagrams/04-tps-circuit.svg)

</div>

<CardExport notebook="09-sensors" name="tps-tracks" height="20rem" />

</div>
</div>

<!--
The classic throttle position sensor is a potentiometer on the throttle shaft. This one has two
tracks, wired in opposite directions: as the plate opens, V 1 rises from half a volt to four and a
half, and V 2 falls by the same amount. The end resistors keep each wiper off the supply and off
ground, so a healthy track never reads below 0.5 volts or above 4.5. A reading outside that window
is a broken wire or a short, not a throttle position.

The plot is notebook 09's model of it, swept past both stops. The green line is the sum, 5 volts
at every angle, give or take the 30 millivolts the ECU's own inputs pull. That sum is the
plausibility check. The dashed curves are the same sensor with track 1 worn, its wiper contact
grown to 50 kilo-ohms: track 1 alone reads low, which on its own looks like a smaller opening. The
sum gives it away, from about 4 degrees on.

The diagram stands in for the Dyad Studio screenshot of `Vehicle.Engine.ThrottlePositionSensor`,
`img/lecture-02/tps-sensor.png` in docs/lecture-02-screenshots.md; swap it in when it exists.

With drive by wire the pedal has the sensor, and the throttle is an actuator the ECU positions.
That is what makes torque-based control possible: the ECU, not your foot, decides how far the
throttle opens. Next slide.
-->

---
routeAlias: etc
---

## Electronic throttle control: drive by wire

<div class="grid grid-cols-[1fr_1.15fr] gap-6">
<div>

![The electronic throttle's position loop: pedal command u_cmd minus the measured opening u_meas into a PID controller, whose voltage drives an H-bridge, the DC motor and a gearbox onto the throttle plate; the return spring with its limp-home position and the stops act on the plate; the two-track TPS reads the plate angle, and the ECU's estimate from V1 and V2 closes the loop.](/diagrams/04-etc-loop.svg)

- The ECU positions the plate with a DC motor, closing a loop on the TPS
- Unpowered, springs hold the plate at **limp home**, a few degrees open
- The motor fights the spring preload in both directions: the loop needs integral action

</div>
<div>

<CardExport notebook="09-sensors" name="etc-step" height="27rem" />

</div>
</div>

<!--
This is the throttle as an actuator. The ECU compares the commanded opening with the opening it
measures through both TPS tracks, and a PID controller sets the motor voltage through an H-bridge.
The motor turns the plate through a gearbox.

Unpowered, two preloaded springs hold the plate about 6 degrees open: limp home. If the motor or
its driver fails, the engine still gets enough air to drive to a garage. The cost is that the
motor always works against a spring preload, which changes sign at limp home; that is why the loop
needs integral action.

The plot is notebook 09's model: a step from limp home to 60 percent at 0.1 seconds, a hold, a
ramp back to 10 percent. The plate gets there in about 60 milliseconds, 10 to 90 percent, with no
visible overshoot. The current saturates at the H-bridge's limit, about 9 amps, during the step,
and then settles to the 1.6 amps that hold the plate against the spring. Notebook 09 has a slider
for the controller gain.

The diagram stands in for the Dyad Studio screenshot of `Vehicle.Engine.ElectronicThrottle`,
`img/lecture-02/etc-diagram.png` in docs/lecture-02-screenshots.md; swap it in when it exists.
-->

---
routeAlias: magnetic-sensors
---

## Wear-free sensors: Hall and magnetoresistive

<div class="grid grid-cols-[1fr_1.05fr] gap-6 items-center">
<div>

- **Hall effect**: a current through a semiconductor plate, a field across it, and a voltage
  $U_H \propto I\,B$ appears at right angles
  - *switching* Hall: on or off at a field threshold (cam phase, gear tooth)
  - *linear* Hall: output proportional to $B$ (angle, position, current)
  - *differential*: two plates side by side cancel stray fields and air-gap drift
  - *back-biased*: a magnet behind the chip, a steel tooth wheel in front of it
- **Magnetoresistive** (AMR, GMR, TMR): the resistance follows the field's direction
  - about **50×** Hall's sensitivity, a **> 50 %** larger air gap, the best edge repeatability;
    a limited linear range
- **Inductive**: an AC coil and a conducting target (eddy current), or a passive VR coil (next
  slides)
- The same chips read a wheel in the ABS lecture and a rotor angle in the e-motor lecture

</div>
<div>

![Two principles side by side. Hall effect: a current I flows along a semiconductor plate, a field B points into it, negative carriers collect on one edge and positive on the other, and the Hall voltage U_H between the edges is proportional to I times B. Magnetoresistive: a current I flows along a thin strip whose magnetization M is turned by the field to an angle alpha from the current; the strip's resistance depends on alpha, the field's direction, not its strength.](/diagrams/04-hall-mr.svg)

<div class="caption">GMR against Hall: Allegro application note AN296248</div>

</div>
</div>

<!--
No contact, no wear. A Hall element is a current through a thin semiconductor plate. Put a
magnetic field across it and the Lorentz force pushes the moving carriers to one edge, so a
voltage appears across the plate, proportional to the current times the field. Switch it at a
threshold and you have a tooth detector; read it linearly and you have an angle or a current
sensor. Two plates a tooth-width apart, subtracted, see only what changes between them, so a
stray field or a changing air gap cancels: that is the differential sensor on the crank wheel.

Magnetoresistive chips are thin magnetic films whose resistance depends on the angle between the
current and the magnetization. The field turns the magnetization, so they sense direction. Per
Allegro's application note they are about fifty times as sensitive as Hall, work at an air gap
more than half as large again, and repeat their edges best; their linear range is small.

Eddy-current and short-circuit-ring position sensors exist, mostly in pedals and some throttles;
no engine function in this deck depends on them.

The modern pedal sensor is a dual-die Hall angle chip, a magnet on the shaft and two independent
dies reading its direction, for example the Melexis MLX90377. The interface slide at the end of
the section comes back to its output.

Wheel speed uses the same Hall and GMR chips; the ABS lecture covers that sensor and its current
interface. The rotor-angle sensor of an electric motor, in the e-drive lectures, is the same
physics again.
-->

---
routeAlias: crank-wheel
---

## Crankshaft position: the 60−2 wheel

<div class="grid grid-cols-[1fr_1.1fr] gap-6 items-center">
<div>

- A steel wheel on the crank pulley or the flywheel: **60 tooth positions, 6° apart, two
  removed**
  - the **gap** is the once-per-revolution reference; tooth 1 follows it
  - the gap spans 18°, so the period after it is about **3×** the one before
- One tooth per 6°: the tooth frequency in Hz **equals the speed in rpm**
  - 800 rpm → 800 Hz, 6000 rpm → 6 kHz
- Injection timing, spark advance and dwell (sections 05 and 06) are all counted in these teeth
- Bosch IS-C reference wheel: Ø 160.43 mm, air gap 0.8 ± 0.3 mm, up to 15 kHz

</div>
<div>

![A 60−2 trigger wheel on the crankshaft with 58 teeth and a gap where two are missing, read by a crank sensor, VR or Hall, at its rim. A belt or chain at 2 to 1 drives the camshaft at half speed; a cam wheel with one raised half carries one window per 720 degrees, read by a Hall cam sensor. Crank: angle within a turn; cam: which turn of the cycle.](/diagrams/04-crank-cam-layout.svg)

<div class="caption">Wheel and air gap: Bosch Motorsport IS-C datasheet; gap and frequencies derived</div>

</div>
</div>

<!--
The crank sensor is the sensor everything else is timed by. Every slide in sections 05 and 06
that says "degrees" means teeth counted on this wheel.

Sixty positions, six degrees apart, two of them empty. The gap is how the ECU knows where the
revolution starts: at steady speed the interval across the gap is three times a normal one,
because three pitches pass instead of one. The first tooth after the gap is tooth one, and the
wheel is mounted so that tooth one sits at a known angle before top dead center of cylinder one.

A handy fact: sixty teeth per revolution means the tooth frequency in hertz equals the engine speed
in rpm. Idle at 800 rpm, 800 teeth a second; 6000 rpm, 6 kilohertz.

The numbers at the bottom are a real part: Bosch Motorsport's inductive sensor IS-C and the 60−2
reference wheel in its datasheet.
-->

---
routeAlias: crank-signals
---

## Inductive or Hall: two signals from one wheel

<div class="grid grid-cols-[1fr_1.2fr] gap-6">
<div>

- **Inductive (VR)**: a coil around a magnet; a passing tooth changes the flux,
  $u \propto d\Phi/dt = \omega\, d\Phi/d\theta$
  - passive, two wires
  - amplitude grows with speed; **nothing at standstill**
  - the **zero crossing** marks the tooth center at any speed; the ECU arms on a threshold that
    rises with the amplitude
- **Hall**: an active chip, three wires, a square wave **from 0 rpm**
  - an edge where the field crosses a fixed threshold
  - Infineon TLE4929C: differential, back-biased; jitter ≤ 0.015° crank; calibrated after 3–4
    edges; reports the direction of rotation by its pulse width

</div>
<div>

<CardExport notebook="illustrations" name="crank-vr-hall" height="26rem" />

<div class="caption">Idealized wheel. VR behavior: Woodward MotoHawk and Bosch Motorsport; Hall IC: TLE4929C-X2A datasheet</div>

</div>
</div>

<!--
Two ways to read the same wheel. The inductive sensor, also called variable reluctance, is a coil
wound round a magnet. A tooth passing changes the flux through the coil, and the coil's voltage is
the rate of change of that flux. So the faster the wheel, the bigger the voltage: on the plot the
300 rpm trace is a tenth of the 3000 rpm one. At cranking it is small, and at standstill there is
nothing at all. What does not move with speed is the zero crossing in the middle of each tooth,
which is why the ECU's VR input times zero crossings and only uses an amplitude threshold to arm
itself.

The Hall sensor is an active chip with its own supply. It switches where the field crosses a
threshold, so the edges are the same at any speed, and it works from zero rpm. The Infineon part
is a differential Hall sensor built for exactly this: its jitter is fifteen thousandths of a
degree, it calibrates itself within the first three or four edges, and it even tells the ECU which
way the engine turns, with a short pulse forward and a long one backward.

The plot is the illustrations notebook: each tooth an idealized bump of flux, the VR voltage its
derivative times speed, the Hall output a fixed threshold on it.
-->

---
routeAlias: cam-phase
---

## Which stroke: the cam phase

<div class="grid grid-cols-[1fr_1.15fr] gap-6 items-center">
<div>

- The crank gap fixes the angle **within one turn**; a four-stroke cycle spans **720°**
  - TDC of cylinder 1 comes twice per cycle: once on compression, once on exhaust
- The camshaft turns at half speed: one cam window per cycle tells the two turns apart
  - 2 × 58 crank teeth per cycle, one cam window
- Without the cam signal
  - **wasted spark** still works: both cylinders of a pair fire at every TDC (section 06)
  - **sequential injection** does not: it must know which cylinder is about to take in its charge

</div>
<div>

<CardExport notebook="illustrations" name="crank-cam-phase" height="20rem" />

<div class="caption">Idealized; where the cam window sits is assumed</div>

</div>
</div>

<!--
The gap tells the ECU where it is within a revolution. But a four-stroke engine's cycle is two
revolutions, and top dead center of cylinder one comes round twice: once at the end of compression,
where it should fire, and once at the end of exhaust, where it should not. The crank alone cannot
tell them apart.

The camshaft turns once per cycle, so one window on a cam wheel says which of the two revolutions
this is. On the plot: two revolutions of crank teeth, two gaps, and one cam window.

Section 06 already met the consequence: the wasted-spark system fires both cylinders of a pair at
every top dead center, so it needs no cam signal. Sequential injection, one injector at a time
timed to its own intake stroke, does.

Unverified, to check against Reif, Gasoline Engine Management, before it goes on a slide: the ECU
injects and fires only once it is synchronized, after the gap and a cam edge; if the crank signal
is lost, injection and spark stop, and some systems run a degraded limp mode on the cam signal
alone.
-->

---
routeAlias: misfire
---

## Misfire detection from the crank speed

<div class="grid grid-cols-[1fr_1.2fr] gap-6">
<div>

- Each firing speeds the crank up; a **misfire** removes one torque pulse
  - the crank slows over that cylinder's 180° segment
  - the ECU times every segment from the 60−2 teeth and flags the outlier, cylinder by cylinder
- The dip shrinks with speed: $\Delta\omega \approx W / (J\,\omega)$
  - one lost firing, $W$ = 157 J: **2.4 %** of the speed at 2000 rpm, **0.27 %** at 6000 rpm
  - at high speed and light load it drowns in torsional vibration and wheel tolerances
- The crank sensor reused as a diagnostic: no extra hardware

</div>
<div>

<CardExport notebook="illustrations" name="misfire-dip" height="26rem" />

<div class="caption">Idealized four-cylinder crank; J = 0.15 kg·m² and 50 N·m assumed; the dip derived</div>

</div>
</div>

<!--
The crank sensor gets a second job. Every firing gives the crank a push; a cylinder that does not
fire leaves a gap in the pushes, and the crank slows down over that cylinder's half revolution.
The ECU already times every tooth, so it can time each cylinder's segment and see which one is
slow.

The difficulty is in the formula. The missing work is fixed, about 157 joules here, and the speed
dip it causes is that work divided by inertia times speed. At 2000 rpm that is 2.4 percent of the
speed; at 6000 rpm a ninth of that, a quarter of a percent. On a real engine the crankshaft also
twists, the teeth are not perfectly spaced, and the road shakes the driveline, and at high speed
and light load those effects are as big as the misfire.

The plot is a four-cylinder crank in the illustrations notebook: one inertia, four half-sine torque
pulses per cycle, a constant load, cylinder 4 left out. The top shows the speed, the bottom the
speed each cylinder's segment gains: zero for every firing, minus the dip for the misfire. The
inertia and the torque are assumed values.
-->

---

## Misfire: what OBD demands

<div class="grid grid-cols-[1.3fr_1fr] gap-8">
<div>

| Threshold | Counted over | Set at |
|---|---|---|
| **catalyst damage** | 200-revolution blocks, for each speed and load | the misfire rate that would overheat the catalyst; may be set at 5 % |
| **emissions** | 1000-revolution blocks | the rate that would exceed 1.5 × the emission standard; at least 1 % |

- Monitoring starts **by the end of the second crank revolution** after engine start
- The fault code names the **cylinder**
- One manufacturer's calibration: catalyst-damage threshold about 4.7 % over 200 revolutions

</div>
<div>

> **The arithmetic of the sensor**
>
> A crank sensor's jitter of 0.015° against a 6° tooth pitch is **0.25 %** of one tooth period:
> about the size of the 6000 rpm misfire dip. The ECU averages over a whole segment, 30 teeth,
> rather than trusting one tooth.

</div>
</div>

<div class="caption">CARB, 13 CCR §1968.2 (e)(3) (OBD II); calibration: GM 2012 OBD mode 6 tables; jitter: TLE4929C-X2A, ratio derived</div>

<!--
Misfire detection is not optional: the on-board diagnostics law sets it. California's OBD II
regulation, which the European rules follow closely, asks for two thresholds. The first protects
the catalyst: unburned mixture burns in the catalyst and overheats it, so the ECU counts misfires
in blocks of 200 revolutions and flags the rate that would damage it. The second protects the
emissions: blocks of 1000 revolutions, and the rate that would push the car over one and a half
times its emission limit. The fault code has to name the cylinder, and monitoring has to start
within two crank revolutions of starting the engine.

One manufacturer's published calibration puts the catalyst threshold at about 4.7 percent.

Unverified, from the research note's outline and not from the verified rows: a catalyst-damaging
misfire makes the check-engine light blink rather than stay lit.

The box on the right is the link back to the sensor: one tooth's timing noise is as big as the
whole misfire dip at 6000 rpm. That is why the ECU works with segment times, not single teeth.
-->

---
routeAlias: temperature-sensors
---

## Temperature sensors

<div class="grid grid-cols-[1.3fr_1fr] gap-8">
<div>

- **Inlet air temperature sensor**
  - measures the temperature of the air entering the engine
  - cold air is denser: **more fuel** for the proper A/F ratio
- **Engine temperature sensor**
  - monitors the operating temperature of the engine
  - engine cold = **high resistance** (NTC) = rich mixture

<div class="grid grid-cols-2 gap-3 stack mt-6">

![A coolant temperature sensor: a brass body with a threaded tip and an electrical connector.](/pptx/slide36-coolant-temperature-sensor.jpeg)

![An exploded hot-film air-mass meter housing, with its circuit board and the small intake-air temperature sensor that sits in the air flow.](/pptx/slide36-hfm-exploded.png)

</div>
</div>
<div>

<CardExport notebook="09-sensors" name="ntc-curve" height="25rem" />

<div class="caption">Bosch Motorsport NTC M12, datasheet</div>

</div>
</div>

<!--
Both are NTC thermistors: negative temperature coefficient, so the resistance falls as the
temperature rises, by two orders of magnitude over the range, as the curve shows. The ECU puts the
thermistor in a voltage divider and reads the voltage.

Inlet air: cold air is denser, so the same volume holds more oxygen, and needs more fuel.

Coolant: a cold engine needs a richer mixture, because fuel condenses on cold walls and does not
all evaporate. Cold means high resistance on an NTC.

The curve is a real sensor's, the Bosch Motorsport NTC M12: its datasheet points, and a
Steinhart-Hart curve through three of them, from notebook 09. 2.5 kilo-ohms at 20 degrees, about
190 ohms at 100.

The exploded sensor is a hot-film air-mass meter. The small part at the bottom is the inlet air
temperature sensor built into it.

Notebook 09, "Sensors", will add the divider voltage the ECU actually reads beside this curve.
-->

---
routeAlias: maf
---

## Load sensor: mass flowmeters

<div class="grid grid-cols-[1.25fr_1fr] gap-6">
<div class="text-sm">

- Mass flowmeters work on the **hot-wire or hot-film principle**, with no moving mechanical part
  inside the unit
  - they can follow flow variations in the millisecond range
- They measure the amount of outside air entering the engine
  - as air flows across the heated wire or film, it cools it down; the wire or film is a
    positive temperature coefficient (PTC) resistor
  - air temperature and humidity also affect the temperature of the heated element, so they are
    compensated
- This helps the computer determine how much fuel is needed

<div class="stack">

![A hot-film air-mass meter: a plug-in sensor in a tubular housing with a honeycomb flow straightener.](/pptx/slide37-hot-film-maf.png)

</div>
</div>
<div>

<CardExport notebook="12-mapped-engine" name="maf-tip-in" height="14rem" />

<CardExport notebook="12-mapped-engine" name="eta-v-map" height="14rem" />

</div>
</div>

<!--
The air mass is the load signal. Everything the fuel calculation does starts from it.

The principle: the ECU keeps a wire or film at a fixed temperature above the air. Flowing air
carries heat away, so it takes more current to hold the temperature. The current, through i equals
V over R, is the measure of the mass flow. It measures mass, not volume, so cold, dense air reads
higher, which is exactly what the fuel calculation needs.

The alternative is a manifold absolute pressure sensor, a MAP sensor: a flexible silicon chip whose
voltage changes as it bends. With the engine speed and a volumetric efficiency, the manifold
pressure gives the air flow. That is called speed-density. When you accelerate the throttle opens,
there is less vacuum, and the intake pressure rises. The hands-on engine works this way: its maps
are read at speed and manifold pressure. The contour at the bottom right is its volumetric
efficiency, the speed-density table: idle sits at 33 kilopascals, full load along the black line.

Drawbacks of older vane meters: inertia, and they had to be mounted the right way up for gravity.
The hot film has neither.

The trace at the top right is no sensor's output: it is the air path's throttle flow through a
tip-in at 3000 rpm, from notebook 12, which is what a perfect meter upstream of the throttle would
read. As the throttle snaps open, the flow spikes to about eight times its final value while the
manifold fills, then settles onto the flow into the cylinders. Notebook 09 will put the hot-film
sensor's own response on top of it.
-->

---
routeAlias: pressure-sensors
---

## Pressure sensors: MAP, barometric, rail

<div class="grid grid-cols-[1fr_1fr] gap-6">
<div>

- **Piezoresistive MEMS**: a silicon diaphragm with resistors in a Wheatstone bridge, a vacuum
  behind it for absolute pressure, an ASIC for gain and temperature compensation
- **MAP**, manifold absolute pressure: the load signal of speed-density
  - the hands-on engine's maps are read at speed and manifold pressure
  - Bosch PS-AA: 10–115 kPa → 0.4–4.65 V, ratiometric, 4.048 V/bar; T10/90 = 1 ms
- **Barometric**: corrects for altitude
- **Rail pressure** (GDI): strain gauges on a steel diaphragm; closes the high-pressure pump's
  loop (section 05)
  - Bosch PST-F 2: 0–280 bar → 0.5–4.5 V, 14.3 mV/bar

</div>
<div>

<CardExport notebook="illustrations" name="map-transfer" height="24rem" />

<div class="caption">Bosch Motorsport PS-AA datasheet; idle and full load: the hands-on engine; voltages derived</div>

</div>
</div>

<!--
The alternative load signal from the last slide, now as a sensor. A manifold pressure sensor is a
thin silicon diaphragm with a vacuum sealed behind it, so it reads absolute pressure. Resistors
diffused into the silicon change with strain, four of them in a bridge, and a small chip on the
same die amplifies and corrects for temperature.

The line is a real sensor's: the Bosch Motorsport PS-AA, 0.4 volts at 10 kilopascals to 4.65 at
115, and it settles within a millisecond. The hands-on engine idles at 33 kilopascals, 1.33 volts;
at full load, 95 kilopascals, 3.84 volts. With the engine stopped the manifold is at ambient, about
100 kilopascals, 4.04 volts. Below 0.4 or above 4.65 volts no healthy sensor reads; that is a
short or an open wire, the subject of the last slide of this section.

A direct-injection engine has a second pressure sensor on its fuel rail, a few hundred bar, which
needs a steel diaphragm with strain gauges instead of silicon. The ECU closes the high-pressure
pump's loop on it.

Unverified, from the research note, not on the slide: many ECUs read the barometric pressure from
the MAP sensor before cranking, and the barometric sensor often sits inside the ECU. The PST-F 2
rail sensor's fault bands below about 0.2 V and above about 4.8 V come from a retailer's copy of
its datasheet. In-cylinder pressure sensors exist in research and in some production diesels.
-->

---
routeAlias: knock-sensor
---

## Knock sensor

<div class="grid grid-cols-[1fr_1fr] gap-6 items-center">
<div>

- **Knock**: the end gas ignites by itself; the cylinder's gas rings at an acoustic resonance
  - pressure oscillation → block vibration → audible noise
  - first mode $f = 1.841\,c/(\pi B)$: bore $B$ = 86 mm, $c$ ≈ 900 m/s → about **6 kHz**
- **The sensor**: a piezoceramic ring under a seismic mass, bolted to the block
  - a broadband accelerometer, not a resonant one
  - Bosch KS4-P: 3–25 kHz, 26 ± 8 mV/g; own resonance 30 kHz; 20 ± 5 N·m
- **Finding knock**: band-pass around the knock frequency, inside a crank-angle window after
  each TDC, from the crank signal
- The control loop, spark retard and advance: <Link to="ignition-advance">06, ignition</Link>

</div>
<div>

![Left, the knock sensor in section: a bolt through a seismic mass and a piezoceramic ring, seated on a flat face of the engine block; block vibration presses the mass on the ring, which gives a charge on the signal wire. Right, the detection chain: the sensor signal, engine noise plus knock, goes through a band-pass around the knock frequency, then a crank-angle window after each cylinder's TDC, then a comparison with a threshold; a knock retards the spark, in section 06.](/diagrams/04-knock-sensor.svg)

<div class="caption">KS4-P: Bosch Motorsport datasheet; knock chain: MIT OCW 2.61, lecture 10; mode: US 9835514; c assumed</div>

</div>
</div>

<!--
Knock is the end gas, the last part of the charge, igniting on its own before the flame reaches
it. The pressure then rings at an acoustic resonance of the gas in the cylinder. For the first
mode the frequency is 1.841 times the speed of sound over pi times the bore: an 86 millimeter bore
and about 900 meters a second in the hot gas, an assumed value, give about 6 kilohertz. Patents
report knock bands around 6 to 8 kilohertz, and anywhere from 4 to 14 for one event.

The pressure wave shakes the block, and that is what the sensor picks up. It is an accelerometer:
a mass sits on a piezoceramic ring, the block's vibration makes the mass press on the ring, and
the ring gives a charge. It is deliberately broadband, flat from 3 to 25 kilohertz for the Bosch
part, with its own resonance well above at 30 kilohertz, so it hears every engine's knock
frequency. It is bolted at a set torque on a clean, flat seat, because the bolt is the coupling.

An engine is noisy: valves closing, injectors clicking, the piston slapping. So the ECU filters
around the knock frequency and only listens in a window of crank angle after each cylinder's top
dead center, where knock can happen. That window comes from the crank signal.

Unverified, from Guzzella and Onder section 4.2, details still to check in the book: the band-pass
output is rectified and integrated over the window, compared with a background level learned per
cylinder, and a knock retards that cylinder's spark by a step, then advances it back slowly.
Section 06 has the loop.
-->

---
routeAlias: sensor-interface
---

## What a sensor puts on its wire, and how the ECU checks it

<div class="grid grid-cols-[1.2fr_1fr] gap-6 items-center">
<div class="text-sm">

| Signal | Here | ECU check |
|---|---|---|
| ratiometric 0.5–4.5 V of a 5 V reference | TPS, MAP, rail | out of range: a short or an open wire |
| resistance in a divider | NTC | out of range; coolant ≈ intake air after a long soak |
| pulse train, VR or Hall | crank, cam | teeth per turn, the gap where expected, the cam edge in its window |
| SENT (SAE J2716) or PWM | Hall angle sensors: pedal, throttle | checksum, status, timeout |
| redundant pair | dual-track TPS, pedal | the tracks agree: V1 + V2 = 5 V |
| bus message | smart sensors | covered in the CAN lecture |

- **SENT**: one wire, one way; each 4-bit nibble is a time between falling edges, in ticks of
  3–90 µs, with a checksum

</div>
<div>

![Ratiometric interface: the ECU's 5 V reference supplies the sensor and is also the ADC's reference; the sensor's signal wire enters the ECU with a pull-down resistor to ground. Beside it, the signal's 0 to 5 V scale: 0.5 to 4.5 V is the valid span, the measurement; below 0.5 V is a fault, a short to ground or an open wire; above 4.5 V a fault, a short to supply. Because the ADC reads the ratio of the signal to the reference, a drifting reference cancels.](/diagrams/04-sensor-interface.svg)

<div class="caption">SENT: Wikipedia, "SENT (protocol)"; spans: the datasheets on the earlier slides</div>

</div>
</div>

<!--
This slide collects what the section has met, by what travels on the wire.

Most analog sensors are ratiometric: the ECU gives the sensor its 5 volt reference and uses the
same reference for its converter, so the sensor's output is a fraction of the reference and a
drift in the reference cancels. The healthy span stops short of both rails, half a volt to four
and a half for the throttle and the rail sensor. A wire that breaks pulls the input to ground
through the ECU's pull-down; a short does the same, or pulls it to the supply. Either lands outside
the span, and that is a fault code, not a measurement.

Temperature sensors are a resistance in a divider: the same out-of-range test, plus a plausibility
test. After the car has stood overnight, coolant and intake air must read the same.

Pulse trains are checked by counting: 58 teeth between gaps, the gap where expected, the cam edge
in its window.

Newer angle sensors send their value digitally on the same single wire, with SENT: each four-bit
nibble is the time between two falling edges, and the frame ends in a checksum. The ECU checks the
checksum and the status bits, and flags a sensor that stops sending.

A redundant pair checks itself, as the dual-track throttle sensor showed: the two tracks must add
up. Pedal sensors do the same; one Volkswagen pedal has a second track at half the slope of the
first (an OEM example, from the Ross-Tech wiki).

Unverified, from Reif's Gasoline Engine Management, not read: the drive-by-wire monitor also
compares the pedal, the throttle and the air mass expected for that opening, and drops to limp
home when they disagree.

Sensors that put their value on the bus are covered in the CAN lecture.
-->

---

## Summary of section 04

- Sensors are classified by application, characteristic curve and output signal; engine sensors
  must survive heat, vibration, chemicals and interference, and be cheap.
- The throttle position sensor is a potentiometer; with drive by wire the pedal carries one too.
- Wear-free sensors are Hall or magnetoresistive chips; an inductive VR coil needs speed.
- A 60−2 crank wheel gives the angle and the speed; the cam sensor tells the two turns of the cycle
  apart. The same signal detects misfire.
- Temperature sensors are NTC thermistors: cold means high resistance and a richer mixture.
- The air mass, measured by a hot-film meter or computed from manifold pressure, is the load
  signal that fuel metering starts from.
- The knock sensor is a piezo accelerometer, filtered in a crank-angle window.
- The ECU checks every sensor: out of range, plausibility, redundancy.

### Next: turning air mass into fuel. <Link to="fuel-injection">→ 05, fuel injection</Link>

<!--
We know how much air is coming in, where the crank is, and whether the engine knocks. Now the
fuel.
-->
