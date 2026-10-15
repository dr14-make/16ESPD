---
routeAlias: sensors
layout: section
---

###### Section 04

# Sensors

How sensors are classified, what they must withstand, and the ones the fuel calculation needs:
throttle position, temperature and air mass.

<!--
The ECU only knows what its sensors tell it. We classify sensors first, then look at the engine
control system as a whole, then at the four that feed the fuel calculation directly.
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
why the industry is moving to contactless sensors, two slides on.
-->

---
routeAlias: tps
---

## Throttle position sensor (TPS)

<div class="grid grid-cols-[1.2fr_1fr] gap-6">
<div>

- A variable resistor connected to the throttle plate
- Today electronic throttles are used
  - only the accelerator pedal has a sensor, and the throttle plate is moved by a DC stepper motor:
    electronic throttle control (ETC), or "drive by wire"
  - the throttle position sensor is then redundant, kept for diagnostic purposes

<div class="grid grid-cols-2 gap-3 stack mt-2">

![A throttle body with its position sensor mounted on the shaft.](/pptx/slide34-throttle-body.jpeg)

![Throttle-valve sensor construction: throttle-valve shaft, two potentiometer tracks, wiper arm with wipers, electrical connection.](/pptx/slide34-tps-construction.png)

</div>
</div>
<div>

![Electrical circuit of a throttle-valve sensor: two potentiometer tracks R1 and R2 between operating voltage and ground, with trimming and protective resistors, giving two measurement voltages U_A1 and U_A2.](/pptx/slide34-tps-circuit.png)

</div>
</div>

<!--
The classic throttle position sensor is a potentiometer on the throttle shaft. The circuit on the
right has two tracks, R 1 and R 2. Two tracks give two voltages, and the ECU compares them: if they
disagree, a track is worn or a wire is broken. That is diagnosis built into the sensor.

With drive by wire the pedal has the sensor, and the throttle is an actuator the ECU positions.
That is what makes torque-based control possible: the ECU, not your foot, decides how far the
throttle opens. The hands-on engine keeps it simple: pedal straight to throttle angle.
-->

---

## Wear-free sensors

- **Magnetic inductive sensors**: non-contacting position and rotation measurement (AC current)
  - short-circuit ring
  - eddy current: when an electrically conducting disk approaches a coil supplied with
    high-frequency alternating current, eddy currents are created in the disk as a function of the
    distance
  - rotating alternating field
- **Magnetostatic sensors**: measure a DC magnetic field
  - Hall effect
    - switches
    - speed
    - position
  - Gaussian effect

<!--
No contact, no wear. Two families. Inductive sensors use an alternating field and watch how a
conducting part changes it. Magnetostatic sensors measure a steady field, most often with a Hall
element: a current through a semiconductor, a magnetic field across it, and a voltage appears at
right angles. The crankshaft and camshaft position sensors are usually Hall or inductive sensors
reading a toothed wheel.
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

## Summary of section 04

- Sensors are classified by application, characteristic curve and output signal.
- Engine sensors must survive heat, vibration, chemicals and interference, and be cheap.
- The throttle position sensor is a potentiometer; with drive by wire the pedal carries it.
- Temperature sensors are NTC thermistors: cold means high resistance and a richer mixture.
- The air mass, measured by a hot-film meter or computed from manifold pressure, is the load signal
  that fuel metering starts from.

### Next: turning air mass into fuel. <Link to="fuel-injection">→ 05, fuel injection</Link>

<!--
We know how much air is coming in. Now the fuel.
-->
