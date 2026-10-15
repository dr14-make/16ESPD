---
routeAlias: fuel-injection
layout: section
---

###### Section 05

# Fuel injection

From mechanical injection to direct injection, the injector itself, and the formula that sets how
long it stays open.

<!--
Fuel is the ECU's main actuator. We go through the history quickly, mechanical, single-point,
multipoint, direct, then open the injector, and end with the formula the ECU uses: pulse width
equals a base value times a long product of correction factors.
-->

---
routeAlias: fuel-injection-system
---

## Fuel injection system

<div class="grid grid-cols-[1.5fr_1fr] gap-8">
<div>

- **Function**
  - provide the proper amount of fuel for a particular operating state
- **Main components**
  - fuel tank · fuel pump · injectors · pressure regulator
- **Single-point injection systems**
  - **Mono-Jetronic**
- **Multipoint injection systems**
  - **K-Jetronic (KE-Jetronic)**: a mechanical system that does not require an engine-driven
    injection pump; pressure injectors
  - **L-Jetronic (LH-Jetronic)**: main controlled variables are air flow and engine speed

</div>
<div>

![A fuel system in a car: fuel tank with fuel gauge sending unit and pump, fuel filter, fuel lines to the injectors, fuel pressure regulator, air cleaner and evaporative emission control canister.](/pptx/slide38-fuel-system.jpg)

</div>
</div>

<!--
Jetronic is Bosch's name for its petrol injection systems. Mono-Jetronic had one injector for the
whole engine. K-Jetronic was mechanical: it injected continuously, and the quantity was set by an
air flap moving a fuel plunger. L-Jetronic was the first electronic one in wide use: it measured the
air flow and the engine speed, and timed electrical pulses to the injectors. That principle, air
flow and speed in, pulse width out, is still the one modern ECUs use.
-->

---

## Mechanical systems

<div class="grid grid-cols-[1.3fr_1fr] gap-8 items-center">
<div>

![K-Jetronic layout with 14 numbered parts: electric fuel pump, fuel accumulator, fuel filter, system pressure regulator, injector, cold-start valve, fuel distributor, air-flow sensor, thermo-time switch, auxiliary-air regulator, engine-temperature sensor, throttle-valve switch, lambda sensor, ECU.](/pptx/slide39-k-jetronic.jpeg)

</div>
<div>

![K-Jetronic air-flow sensor and fuel distributor: the air flow lifts a sensor plate on a lever, which raises the control plunger in the fuel distributor and opens the metering ports to the injection lines.](/pptx/slide39-fuel-distributor.jpeg)

</div>
</div>

<!--
K-Jetronic, continuous injection without electronics. On the right is the clever part. The air
flowing into the engine lifts a sensor plate on a lever. The lever pushes up the control plunger
in the fuel distributor, which uncovers metering slits, one per cylinder. More air, more lift, more
fuel. The air-fuel ratio is set by the geometry of the funnel and the slits.

Corrections, for a cold engine for example, worked by changing the control pressure on top of the
plunger. The later KE version added an electronic actuator for that, and a lambda sensor, part 13
on the left.
-->

---
routeAlias: single-point
---

## Single-point injection system

<div class="grid grid-cols-[1fr_1.3fr] gap-8 items-center">
<div>

- One single injector sized for full-load fueling
- Reasonable air/fuel ratio control
  - better transient performance than a carburetor
  - better steady-state mixture preparation than a carburetor
- Poor cylinder-to-cylinder AFR distribution
- Little potential to tune the intake manifold
- Reasonable cost
- Essentially obsolete

</div>
<div>

![Single-point injection: one injector in a central throttle body above the intake manifold, with the fuel tank, pump, filter and pressure regulator, and the ECU.](/pptx/slide40-single-point.png)

</div>
</div>

<!--
Single-point injection is a carburetor replaced by one electronic injector in the same place, above
the throttle. It was cheap, and it allowed the electronic air-fuel control a catalytic converter
needed.

Its weakness is the manifold. The fuel still has to travel the whole manifold to each cylinder, and
the cylinders nearest the injector get a different mixture from the farthest. That is the poor
distribution.

On the second sub-bullet: the source figure underneath says "poorer" steady-state mixture
preparation; the slide overlays "better". This deck carries the slide.
-->

---
routeAlias: multipoint
---

## Multipoint injection system

<div class="grid grid-cols-[1fr_1.4fr] gap-8 items-center">
<div>

- One injector per cylinder
- Good air/fuel ratio control
  - better transient performance than single-point injection
  - better steady-state mixture preparation than single-point injection
- Excellent cylinder-to-cylinder distribution
- Tuned intake manifold possible: increased performance
- Early systems not crank-synchronous
- Developments and refinements ongoing

</div>
<div>

![Multipoint injection: fuel pump, filter and fuel rail feeding one injector per cylinder in the intake port, with the pressure regulator, air flow meter, air temperature sensor, throttle potentiometer, idle speed control valve, coolant temperature sensor, crankshaft sensor and lambda sensor.](/pptx/slide41-multipoint.png)

</div>
</div>

<!--
One injector per cylinder, in the intake port, aimed at the back of the intake valve. Now every
cylinder gets its own fuel, close to where it is needed, and the manifold carries only air, so it
can be shaped for airflow alone.

Early systems fired all injectors together, once or twice per revolution, regardless of which
valve was open. Sequential injection, timed to each cylinder's intake stroke, came later.

This is the engine of the hands-on: port injection, four cylinders. And the diagram names almost
every sensor from section 04.

As on the previous slide, the source figure says "poorer" on the second sub-bullet and the slide
overlays "better".
-->

---
routeAlias: direct-injection
---

## Direct injection

<div class="grid grid-cols-[1.25fr_1fr] gap-6 text-sm">
<div>

**Homogeneous direct injection**
- injection during the intake stroke (wide injection window) for thorough mixing with the incoming
  air
- combustion is similar to port fuel injection, but burn rates increase
- improved efficiency through a higher compression ratio
- eliminates wet-wall fueling, and results in better AFR control

**Stratified direct injection**
- fuel injected late in the compression stroke (short injection window)
- the rich mixture is brought to the spark plug by the interaction of air motion and a compact
  bowl-in-piston chamber
- combustion starts in the rich region and the flame propagates through the lean region
- ultra-lean combustion (AFR > 80:1) allows unthrottled operation
- homogeneous at high load, for maximum air utilization

</div>
<div class="stack">

![Gasoline direct injection system: high-pressure pump, fuel rail and injectors in the cylinder head, with air-mass meter, electronic throttle, EGR valve, knock, speed and phase sensors, oxygen sensors and a NOx catalyst.](/pptx/slide42-homogeneous-di.png)

![Stratified charge: the injector sprays into a bowl in the piston, and the air motion carries the rich cloud up to the spark plug.](/pptx/slide42-stratified-di.png)

</div>
</div>

<!--
Direct injection puts the injector in the combustion chamber, at 100 bar or more instead of 3 to
4.

Homogeneous mode injects early, during intake, so the mixture is uniform, as in port injection. The
gain: the evaporating fuel cools the charge, which allows a higher compression ratio, and there is
no fuel film on the port walls.

Stratified mode injects late, so there is a rich cloud at the plug and almost pure air around it.
The engine can run with the throttle wide open and control load by fuel alone, like a diesel. No
throttle means no pumping loss.

One of the key technologies is the piezoelectric injector, extremely fast and precise. It has a
side effect: a warm engine can be started without the starter motor. The computer finds a cylinder
with its piston in the right position, injects fuel and fires it. That makes stop-start much
easier, so cars no longer need to idle at traffic lights.

Reading: https://www.seattletimes.com/business/technology/how-gasoline-direct-injection-engines-work/
and on pre-chamber ignition, https://www.roadandtrack.com/new-cars/a34054931/pre-chamber-ignition-system-explained/
-->

---
routeAlias: fuel-injector
---

## Fuel injector

<div class="grid grid-cols-[1.3fr_1fr] gap-8">
<div>

- **Functions**
  - regulate the fuel quantity
  - form the spray
- Fuel injectors meter and atomize the fuel. When the solenoid winding is energized, the nozzle
  needle lifts a mere **0.05 mm** off its seat.
- The injected fuel quantity per unit of time is essentially determined by the **system pressure**
  and the **free cross-section** of the spray orifices in the spray-orifice disk.

</div>
<div class="stack">

![An injector spraying a fine cone of atomized fuel.](/pptx/slide43-injector-spray.jpg)

![Injector in section, numbered: 1 pintle, 2 needle, 3 armature, 4 spring, 5 solenoid winding, 6 electrical terminals, 7 fuel strainer.](/pptx/slide43-injector-section.png)

<div class="caption">1 pintle · 2 needle · 3 armature · 4 spring · 5 solenoid winding · 6 electrical terminals · 7 fuel strainer</div>

</div>
</div>

<!--
An injector is a solenoid valve. Current through the winding, 5, pulls the armature, 3, against the
spring, 4, and lifts the needle, 2, off its seat by five hundredths of a millimeter. Fuel at system
pressure flows out through the orifices.

The important consequence: with the pressure fixed, the flow rate while open is a constant. So the
ECU controls the fuel quantity by time alone. Open twice as long, twice the fuel. That is why the
next slide is about a time, the pulse width.

Notebook 05, "Inside an injector", models the solenoid, the armature and the needle.
-->

---
routeAlias: pulse-width
---

## Fuel injection: basic principles

<div class="grid grid-cols-[1.1fr_1fr] gap-6">
<div class="text-sm">

The engine control unit uses a formula and a large number of lookup tables to determine the
**pulse width** for given operating conditions. The equation is a series of many factors multiplied
by each other:

$$
t_{\text{inj}} \;=\; t_{\text{base}} \cdot f_A \cdot f_B \cdot f_C \cdots
$$

- It may have **more than 100 parameters**, each with its own lookup table.
- Some of the parameters even change over time, to compensate for changes in the performance of
  engine components.

<CardExport notebook="12-mapped-engine" name="pulse-width-map" height="15rem" />

</div>
<div>

<CardExport notebook="12-mapped-engine" name="afr-table" height="22rem" />

<div class="caption">Target air-fuel ratio of the hands-on engine, 14.6 · λ, over engine speed and manifold pressure</div>

</div>
</div>

<!--
This is the heart of fuel control.

The base pulse width comes from the air: the measured air mass per cylinder, divided by the target
air-fuel ratio, gives the fuel mass; divided by the injector's flow rate, it gives a time. The
target comes from a map like this one, the hands-on engine's, from notebook 12: rows are engine
speed, columns manifold pressure. It holds 14.6 below 85 percent of full-load pressure, and richens
above that, deepest at high speed, to protect the exhaust valves and the catalyst from
overheating.

The contour at the bottom left is the base pulse width that results, with a 146 cubic centimeters
per minute injector: about 2 milliseconds at idle. The dashed line is where the pulse fills the
whole engine cycle. Beyond it, above about 5250 rpm at full load, this small injector cannot keep
up; the real engine would need a bigger one.

Then the factors: one for coolant temperature, rich when cold; one for intake air temperature; one
for battery voltage, because the injector opens slower on a low battery; one for acceleration
enrichment; one from the lambda loop of section 07. Each is a lookup table, each calibrated on a
test bench. Adaptive factors learn slowly as the injectors and the sensors age.

A video: https://www.youtube.com/watch?v=4FfcjERUtUw

Notebook 04, "How much fuel", will build the whole formula, factors and dead time included.
-->

---
routeAlias: injector-activation
---

## Activation of the fuel injector

<div class="grid grid-cols-[1.4fr_1fr] gap-8">
<div>

- The injector **activates with the switch signal** (a).
- The **rising current** (b) causes the needle to lift (*c*).
- Maximum displacement is reached at the **pickup time** $t_{\text{on}}$.
  - The needle stops at the solenoid armature stop.
- The **current continues to rise**: the magnetic field is not yet at saturation.
- At switch-off the **magnetic field does not decay abruptly**, so the needle closes only after
  the **dropout time** $t_{\text{off}}$.
- The **injected fuel quantity** (d) grows while the needle is open.

</div>
<div>

![Activation of a fuel injector against time: a) the activation signal, a rectangular pulse; b) the current curve, rising with a kink when the armature reaches its stop; c) the valve-needle displacement, lagging by the pickup time t_on and the dropout time t_off; d) the injected fuel quantity, a ramp while the needle is open.](/pptx/slide45-injector.png)

</div>
</div>

<!--
Four traces, one time axis. The ECU's command is a clean rectangle, a. The current, b, cannot jump,
because the winding is an inductor, so it rises with the winding's time constant. When the magnetic
force beats the spring, the needle lifts, c. The small kink in the current is the armature arriving
at its stop: its motion induces a back voltage.

At switch-off the field takes time to collapse, so the needle closes late.

So the fuel delivered, d, is not proportional to the command pulse. It is the command minus the
opening delay plus the closing delay. ECUs correct for that with a dead-time added to every pulse,
and the dead-time depends on battery voltage. That is one of the factors on the previous slide.

Notebook 05 will regenerate these four traces from an electromagnetic model of the injector.
-->

---

## Injection spray geometry

<div class="grid grid-cols-[1fr_1.5fr] gap-8 items-center">
<div>

- **Tapered spray**: for engines with only one intake valve per cylinder
- **Dual spray**: two intake valves per cylinder
- **Gamma angle**: for difficult installation conditions; requires a spray target

</div>
<div>

![Spray geometries: a) tapered spray, 80 % of the fuel inside angle α80 and 50 % inside α50; b) dual spray, two sprays with 70 % of the fuel in each inside β, here β = 8°; c) gamma angle, a spray offset at angle γ.](/pptx/slide46-spray-geometry.png)

</div>
</div>

<!--
The spray must land on the back of the intake valve, not on the port wall, where it would form a
film. With two intake valves the injector makes two sprays, one per valve. When the injector cannot
be mounted pointing at the valve, the spray is angled, gamma.

The angles alpha 80 and alpha 50 contain 80 and 50 percent of the fuel: that is how a spray's width
is specified.
-->

---

## Summary of section 05

- Injection went from mechanical (K-Jetronic) to single-point, to multipoint, to direct.
- Multipoint, one injector per port, is the hands-on engine: good distribution and a tuned manifold.
- The injector is a solenoid valve: at constant pressure, the fuel quantity is set by the open time.
- **Pulse width = base pulse width × factor A × factor B × …**, each factor its own lookup table.
- The needle lags the command at opening and closing, which the ECU corrects for.

### Next: lighting the mixture. <Link to="ignition">→ 06, ignition</Link>

<!--
The fuel is in. Now the spark: when to fire it, and how to make it.
-->
