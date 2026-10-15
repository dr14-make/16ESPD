---
routeAlias: mapped-engine
layout: section
---

###### Section 08

# The mapped engine

What you build in the hands-on: a pedal, a throttle, a manifold pressure, and measured maps that
return torque, fuel and CO₂.

<!--
The bridge to the hands-on. This section shows what you will build and the equations it rests on.
The numbers you will measure with it are for the hands-on itself.
-->

---
routeAlias: what-you-build
---

## What you build

Lecture 1's `IdealEngine` is replaced by an engine an ECU calibrator would recognize.

![The mapped engine: pedal to throttle, throttle air flow into the intake manifold whose state is the pressure p_m, the brake booster feeding air in as well, the cylinders drawing air out; maps read at engine speed and p_m return torque to the crankshaft and car, and fuel flow to the fuel and CO₂ outputs; engine speed feeds back to the maps and the cylinders.](/diagrams/08-mapped-engine.svg)

<div class="grid grid-cols-3 gap-6 text-sm mt-2">
<div>

**Pedal → throttle**: drive by wire, a progressive pedal curve straight to the throttle angle
(section 04).

</div>
<div>

**Manifold pressure is a state**: it fills through the throttle and empties into the cylinders.
The maps are read at speed and manifold pressure, speed-density, as from a MAP sensor (section 04).

</div>
<div>

**Measured maps**: torque and fuel flow from the US EPA's ALPHA data for a 2014 Mazda 2.0 L
Skyactiv, scaled to a **1.5 L** four-cylinder port-injected engine (section 05).

</div>
</div>

<!--
Follow the air, as in section 04. Your foot sets the pedal, the pedal sets the throttle. Air flows
through the throttle into the manifold, and the cylinders draw it out. The manifold pressure is the
balance of the two, and it is a state: it takes time to change. That is the lag Lecture 1's engine
had as a bare 0.3 second time constant. Here it comes from physics, and it changes with speed.

The maps are tables over speed and manifold pressure. They return brake torque, fuel flow, and
engine-out emissions. The torque turns the crankshaft and drives the hands-on car through its
single gear.

The dashed input is the brake booster. It draws its vacuum from this same manifold, and when it
empties back on brake release the manifold pressure bumps. You will see that in the brake lecture.

The data is real: a measured fuel map of a Mazda 2.0 liter Skyactiv from the US EPA, scaled to 1.5
liters, so the peak torque matches Lecture 1's 150 newton-meters.
-->

---
routeAlias: mapped-engine-equations
---

## The equations under it

<div class="grid grid-cols-[1fr_1.1fr] gap-6 text-sm">
<div>

**Manifold filling** (one isothermal receiver)

$$
\frac{V_m}{R\,T_m}\,\frac{dp_m}{dt} \;=\; \dot m_{\text{thr}} + \dot m_{\text{bst}} - \dot m_{\text{cyl}}
$$

**Cylinder air flow** (speed-density)

$$
\dot m_{\text{cyl}} \;=\; \eta_v(N, p_m)\,\frac{p_m\,V_d\,N}{120\,R\,T_m}
$$

**Fuel from air and λ** (sections 02 and 05)

$$
\dot m_f \;=\; \frac{\dot m_{\text{cyl}}}{\text{AFR}_s\,\lambda}, \qquad \text{AFR}_s = 14.6
$$

**CO₂ from fuel** (carbon balance, full oxidation)

$$
\dot m_{\text{CO}_2} \;=\; 3.09\,\dot m_f
$$

</div>
<div>

<CardExport notebook="12-mapped-engine" name="manifold-lag" height="19rem" />

<div class="caption">Manifold pressure after a small throttle step, both from 33 kPa, beside Lecture 1's lag</div>

</div>
</div>

<div class="text-sm mt-4">

λ = 1 over most of the map, richer near full load to protect the exhaust (section 05's AFR map).
Overrun uses **fuel cut-off**: zero fuel, closed-throttle torque (section 03's control strategy).

</div>

<!--
Four lines, all of which you have now seen in the lecture.

The first is the manifold: mass in minus mass out, over a volume. V m over R T m is how much the
pressure moves per kilogram of air. With a liter of manifold that gives a time constant of about
0.15 seconds at idle, 800 rpm. At 3000 rpm, from the same manifold pressure, it is 0.034 seconds:
the cylinders empty the manifold almost four times as fast. The plot shows both against Lecture 1's
fixed 0.3 second lag, which was slower than either.

The second is how much air the cylinders take: the displacement times the revolutions, at the
manifold density, times a volumetric efficiency. N over 120, because a four-stroke fills each
cylinder once every two revolutions. This is the speed-density calculation an ECU without an air
mass meter does.

The third is section 02's lambda and section 05's base pulse width, as a flow. The fourth is
chemistry: each kilogram of petrol burned completely makes 3.09 kilograms of CO2.

Coast-down uses the cut-off from section 03's control strategy slide.
-->

---
routeAlias: what-you-measure
---

## What you will do with it

<div class="grid grid-cols-2 gap-8">
<div>

**Scenarios on the hands-on car** (one gear, i = 4.0)

- pedal steps: the manifold lag in the torque
- wide-open-throttle sprint: the real top speed
- steady cruise at 50, 90 and 130 km/h
- coast-down on a closed throttle: fuel cut-off
- a brake stop, with $p_m$ on the plot

</div>
<div>

**Read off**

- fuel flow in **L/h**
- consumption in **L/100 km**
- **CO₂ in g/km**
- the manifold pressure $p_m$ that the brake booster will draw on

</div>
</div>

<!--
The same car as Lecture 1, the same single gear, with the new engine. Each scenario answers one
question. A pedal step shows the lag the manifold adds. The sprint shows the top speed with a real
torque curve, the number Lecture 1 promised to fix. The cruise points give fuel consumption and CO2
per kilometer, the numbers on a car's sticker. Coast-down shows fuel cut-off. And the brake stop
records the manifold pressure the booster depends on.

If time allows, the hands-on adds a gearbox and a driver following the WLTC cycle, where the
results can be compared with a real car's label.
-->

---

## Summary of the lecture

- **01** the engine's work goes to drag, rolling, slope, acceleration and the auxiliaries.
- **02** Otto and Diesel cycles; stoichiometric is 14.6, and λ measures the mixture against it.
- **03** sensors, ECU and actuators in a loop, with a strategy for every operating mode.
- **04** the ECU knows what its sensors tell it: position, temperature, air mass.
- **05** pulse width = base × factors; the injector is a solenoid valve timed by the ECU.
- **06** the spark fires before TDC to put peak pressure just after it; advance trades torque for
  emissions.
- **07** the λ loop holds the catalyst's window with a switching sensor and a limit cycle.
- **08** in the hands-on, the mapped engine: pedal, manifold pressure, maps, fuel and CO₂.

### An engine control unit is a stack of control loops wrapped around one nonlinear plant.

<!--
Back to the sentence we started with. The plant is the engine, nonlinear in speed and load: the
maps are how the ECU copes with that. The loops are fuel, spark, idle and lambda, each with its
sensors and actuators.

In the hands-on you build the plant. The notebooks put the loops around it, one at a time.
-->
