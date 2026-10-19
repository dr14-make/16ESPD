---
routeAlias: engine-control-system
layout: section
---

###### Section 03

# Engine control system

Sensors, an electronic control unit, actuators. What the system must achieve, and how it behaves
from cranking to the rev limiter.

<!--
Now the controller. This section is the map for the rest of the lecture: the structure, the jobs,
the subsystems and the operating modes. Sections 04 to 07 then go into the pieces.
-->

---
routeAlias: ecs-structure
---

## Engine control system

<div class="grid grid-cols-[1.1fr_1fr] gap-8">
<div>

- A **control system** is a device, or set of devices, that manages, commands, directs or
  regulates the behavior of other devices or systems.
- The engine control system includes:
  - ***sensors*** for the detection of the engine operating modes
  - an ***electronic control unit*** (ECU), which processes the signal values supplied by the
    sensors according to defined control strategies and algorithms, and defines the actions to be
    delivered to the actuators
  - ***actuators***, which carry out the defined commands

<CardExport notebook="12-mapped-engine" name="torque-map" height="21rem" />

<div class="text-sm">

A calibration map: engine torque over manifold pressure and engine speed (hands-on engine, EPA data).

</div>

</div>
<div>

![The engine control loop: sensors on the engine feed the ECU, the ECU drives the actuators, the actuators act on the engine; the ECU also exchanges data with other vehicle systems' control.](/diagrams/03-engine-control-loop.svg)

</div>
</div>

<!--
Three parts, in a loop. The sensors read the engine, the ECU decides, the actuators act, and the
engine responds. The ECU also talks to the rest of the car: the gearbox, the brakes, the stability
control.

The surface below the text is a calibration map, a table over two operating variables. This
one is the hands-on engine's torque map, from the EPA's measured Mazda data in notebook 12: brake
torque over manifold pressure and engine speed. The ECU holds hundreds of these. What the ECU adjusts first are the fuel injection and the ignition timing.
For ecology, modern engines add more sensors: a second oxygen sensor, exhaust temperature, NOx.

Notebook 11, "The whole ECU in the car", closes all the loops of this diagram around one engine.
-->

---
routeAlias: ecs-functions
---

## Engine control system functions

Ensures that the driver's request is implemented (**desired torque**), while it must:

- minimize exhaust emissions and fuel consumption
- give optimal driveability in all operating conditions
  - no stalls, hesitations or other objectionable roughness during vehicle operation
- control the idle speed
- minimize evaporative emissions
  - EGR (exhaust gas recirculation) control
  - evaporative emissions control
- provide system diagnosis when malfunctions occur

<!--
The first line is the one that matters for control: the driver presses the pedal, and that is a
torque request. Everything else is a constraint on how the torque is delivered: low emissions, low
consumption, no stalls or jerks, a steady idle, and a diagnosis when something breaks.

Some of these goals fight each other. Power wants a rich mixture, the catalyst wants lambda one,
economy wants lean. The ECU's job is the compromise.

Notebook 11 will build the torque structure that turns the pedal into a torque request.
-->

---

## How this is achieved

- Determines precisely **how much fuel** the injector needs to deliver by monitoring the engine
  sensors.
- Turns the injectors on **for a precise amount of time** and at precise intervals, so that the
  proper air/fuel ratio is delivered to the engine.
- Regulates the **spark advance angle** by monitoring engine operating conditions, calculating the
  optimum spark timing, and firing the spark plug at the appropriate time.
- Modern vehicles also regulate **when and how to open the intake and exhaust valves**.

<!--
Four handles: the fuel quantity, the injection timing, the spark timing, and on modern engines the
valve timing. The first three get their own sections today. Valve timing we only mention; our model
does not have it.

Notice that air is not on the list. On a petrol engine the driver, through the throttle, sets the
air. The ECU measures the air and meters fuel to match. That is the core of section 05.
-->

---

## Subsystems

<div class="grid grid-cols-2 gap-8 text-[0.95rem]">
<div>

- **Starting system**: accelerates the engine to a speed at which it draws fuel and air into the
  cylinders and compresses it.
- **Cooling system**: heats up as soon as possible and keeps a constant working engine
  temperature.
- **Ignition system**: generates a very high voltage from the car's 12 V battery and sends it to
  each spark plug in turn, igniting the fuel–air mixture in the combustion chambers.
- **Fuel injection system**: delivers the proper amount of fuel from the fuel tank to the cylinders.

</div>
<div>

- **Evaporation and exhaust systems**
- **Charging system**: produces a constant voltage to power the vehicle equipment and charge the
  battery.
- **Diagnostic systems**
  - monitor the status and state of all subsystems and their components
  - give the driver a visual warning if there is a failure in the system

</div>
</div>

<!--
The engine is not one system but several. Each is a control problem of its own. Starting has to
spin the engine up fast enough to run. Cooling has to warm it quickly and then hold the temperature.
Ignition and fuel injection are the two we spend most time on. The evaporation and exhaust systems
are section 07.

Notebook 10, "Warm-up and cooling", will model the cooling circuit.
-->

---
routeAlias: control-strategy
---

## Control strategy

<div class="grid grid-cols-2 gap-6 text-sm">
<div>

**Cranking**
- get the engine started with the minimal delay
- minimize exhaust emissions: during cranking the catalyst is cold and its efficiency is very low

**Warm-up**
- keep the engine running smoothly, with no stalls or driveability problems
- raise the exhaust temperature to bring the catalyst (light-off) and the lambda sensor to
  operating temperature quickly, so that closed-loop control can begin
- keep exhaust emissions and fuel consumption to a minimum

**Cut-off**
- during deceleration, such as coasting or braking

</div>
<div>

**Idling**
- a consistent idle speed, even with load changes from the accessories
- the lowest idle speed that still runs smoothly, for the lowest exhaust emissions and fuel
  consumption

**Normal**
- the engine works in steady state, without noticeable variation of load and speed
  - acceleration enrichment: a richer mixture is required
  - deceleration enleanment: the inverse of acceleration

**Engine and vehicle speed limitation**
- limit engine and vehicle speed with fuel cut-off

</div>
</div>

<!--
The ECU is a different controller in each operating mode, and it switches between them.

Cranking and warm-up are where most of a car's emissions come from, because the catalyst is cold.
So warm-up deliberately wastes some fuel to heat the catalyst. Only once the lambda sensor is hot
can the lambda loop close; before that, fuel is open loop.

Cut-off: when you lift off the pedal at speed, the injectors stop. No fuel at all. The hands-on
engine does this too, on coast-down.

Idle is a speed loop, like your cruise control, but with the throttle bypass or the spark as the
actuator, and the air conditioning compressor switching in as the disturbance.

Acceleration enrichment exists because of the manifold: when the throttle opens, the air arrives
before the fuel film on the port walls catches up, and the mixture goes lean for a moment.

Notebook 10 models the warm-up strategy; notebook 07, "Idle speed control", the idle loop.
-->

---
routeAlias: ee-architecture
class: big-figure
---

## Models of electrical and electronic architecture

<div class="grid grid-cols-[1fr_1.1fr] gap-8 items-center">
<div>

- **Functional**: preliminary stage, signal flow diagram
- **Component network**
  - technology model
  - node model
  - ECU hardware model
  - ECU software module
  - network model and communication
- **Circuit diagram**
- **Wiring harness and installation space**

</div>
<div>

![Models of E/E architecture, from abstract to physical: the function network links sensors through functions to actuators; the component network places the functions on ECUs joined by a bus; the circuit diagram adds every wire, switch and ground; the wiring harness bundles the wires through connectors; the installation space places the ECUs and harness in the body and a door.](/diagrams/03-ee-architecture.svg)

</div>
</div>

<!--
The same control system described at five levels, from abstract to physical. The function network
says which sensor feeds which function and which actuator. The component network says which ECU runs
each function. The circuit diagram and the wiring harness say how the wires actually run, and the
installation space where the boxes sit in the body.

In this course we work at the top level: functions and signals. That is what Dyad models are.

The figure is redrawn from the Bosch figure the source deck scanned: the same five levels and the
same sensor, ECU and actuator in each, with a one-line gloss per level.
-->

---

## Summary of section 03

- Sensors, ECU, actuators: a loop around the engine, connected to the rest of the car.
- The goal is the driver's torque, delivered with low emissions, low consumption and no stalls.
- The handles are fuel quantity, injection timing, spark advance and, on modern engines, valve
  timing.
- The ECU switches strategy by operating mode: cranking, warm-up, cut-off, idle, normal, limiting.

### Next: what the ECU can measure. <Link to="sensors">→ 04, sensors</Link>

<!--
The ECU only knows what its sensors tell it. Next, the sensors.
-->
