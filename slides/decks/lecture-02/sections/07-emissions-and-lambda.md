---
routeAlias: emissions-and-lambda
layout: section
---

###### Section 07

# Emissions and lambda control

Fuel vapor from the tank, the λ loop around the injectors, the oxygen sensor that closes it, and
the catalyst it protects.

<!--
The section where the engine control system finally closes a loop on its own output. First the
evaporative system, which adds fuel the injectors did not meter. Then lambda control: the oxygen
sensor in the exhaust measures the result of the fuel calculation, and corrects it.
-->

---
routeAlias: evap
---

## Evaporative emission system

<div class="grid grid-cols-[1.2fr_1fr] gap-8 items-center">
<div>

- Prevents fuel vapor build-up in the sealed fuel tank.
- Fuel vapors trapped in the sealed tank are vented through the vapor valve assembly on top of the
  tank.
- **How the system works**
  - The charcoal canister temporarily absorbs the HC evaporated from the fuel tank.
  - When the engine runs and the purge control valve opens, the absorbed fuel is purged from the
    canister and returned to the intake pipe by the negative pressure in the intake pipe.
  - The returned fuel is drawn into the cylinder together with the fuel from the injector and the
    air.

</div>
<div>

![Evaporative emission system in a car: fuel tank with evaporative line to the charcoal canister, purge line through the purge control valve to the intake pipe, next to the injector.](/pptx/slide56-evap-system.gif)

</div>
</div>

<!--
Petrol evaporates in the tank, more on a hot day. The vapor is hydrocarbons, and venting it to the
air is not allowed. So a canister of activated charcoal soaks it up.

The canister fills up, and has to be emptied. When the engine runs, the ECU opens the purge valve,
and the manifold vacuum draws air through the charcoal, carrying the fuel into the engine.

For control this is a disturbance: fuel the ECU did not meter enters the cylinders. The amount is
unknown, it depends on how full the canister is. The lambda loop of the next slide sees the mixture
go rich and corrects it. That is one reason the loop exists.
-->

---
routeAlias: lambda-control
---

## Lambda control

<div class="grid grid-cols-[1fr_1.2fr] gap-6">
<div>

- Ensures the conversion rate of the catalytic converter: it must hold the **stoichiometric ratio**.
- Mixture formation is followed up in a **control loop**.
- Deviations are detected by **lambda sensors**.
- Typical variation **2–3 %**.
- Limited control dynamics, determined by the **sum of the response times**.

<div class="stack mt-4">

![Installation locations of λ sensors: a) two-sensor control, a two-step or broad-band sensor before the primary catalytic converter and a two-step sensor after it; b) three-sensor control, with a further sensor after the main catalytic converter.](/pptx/slide57-sensor-locations.png)

</div>
</div>
<div>

![Two-step control with a λ sensor before the catalytic converter: the sensor voltage switches between rich and lean, and the manipulated variable jumps at each switch and then ramps, a limit cycle; a) shift to rich, b) shift to lean, using a dwell time t_v after the sensor jump, from the post-catalyst control.](/pptx/slide57-two-step.png)

</div>
</div>

<!--
The catalyst, last slide of this section, only converts all three pollutants in a narrow window
around lambda one. Two or three percent off, and one of them gets through. Feed-forward fuel
metering from section 05 cannot hold that on its own: the air measurement drifts, the injectors
age, the canister purges. So the exhaust is measured, and the fuel corrected.

The right figure is how. The sensor before the catalyst is a switch: it only says rich or lean. So
the controller cannot regulate to a value; it oscillates around it. When the sensor says rich, the
correction jumps lean, then ramps further lean until the sensor flips. Then it jumps rich and ramps.
A jump and a ramp: a PI controller acting on a sign. The result is a limit cycle around lambda one.

Why does it oscillate and not settle? The response times add up: injection, combustion, the gas
traveling down the exhaust to the sensor, and the sensor's own response. That transport delay is
what limits the dynamics, as the last bullet says. You met dead time in Lecture 1.

The second sensor after the catalyst trims the first: if the catalyst output drifts rich, it shifts
the switching point, the dwell time t v in panel a and b.

Notebook 06, "Lambda control and the catalyst", will regenerate this limit cycle from a model with
the exhaust delay and a switching sensor.
-->

---
routeAlias: oxygen-sensor
---

## Oxygen sensor

<div class="grid grid-cols-[1.5fr_1fr] gap-6">
<div class="text-[0.95rem]">

- Used to determine whether the air–fuel ratio of a combustion engine is **rich or lean**.
- Used to regulate the air/fuel mixture very precisely to **λ = 1**.
- The sensor is a solid electrolyte of **ZrO₂ ceramic**, which becomes conductive for oxygen
  ions at temperatures above **300 °C**.
- The voltage output of the O₂ sensor changes with the oxygen content of the exhaust.
- The signal is sent to the ECM, and the ECM changes the time that an injector is open.
- The sensor does not actually measure oxygen concentration, but the **difference** between the
  oxygen in the exhaust gas and the oxygen in air.

</div>
<div class="grid grid-cols-[1fr_1.6fr] gap-3 items-center">
<div class="stack">

![A zirconia oxygen sensor: the finger-shaped ceramic element with exhaust gas outside and reference air inside, and the sensor housing.](/pptx/slide58-sensor-construction.jpeg)

</div>
<div>

![Switching oxygen sensor characteristic: sensor voltage about 0.9 V on the rich side falling steeply through U_reg near λ = 1 to about 0.1 V on the lean side.](/pptx/slide58-sensor-curve.jpeg)

<div class="caption">Sensor voltage (0 to 0.9 V) against normalized A/F ratio λ (0.98, 1.0, 1.02); dashed line U<sub>reg</sub>, the switching level</div>

</div>
</div>
</div>

<!--
The element is a thimble of zirconium dioxide. Outside is the exhaust gas, inside is reference
air. When it is hot, oxygen ions can move through the ceramic, and the difference in oxygen between
the two sides produces a voltage, like a battery.

The curve explains the two-step control of the last slide. Rich, there is almost no oxygen in the
exhaust, so the difference is large: about 0.9 volts. Lean, there is spare oxygen: about 0.1 volts.
In between, within two percent of lambda one, the voltage drops off a cliff. So the sensor is a
superb detector of which side of one you are on, and almost useless for how far. Hence the switch,
the jump and the ramp. A broad-band sensor, the alternative in the previous figure, measures lambda
over a wide range and allows a continuous controller.

300 degrees is why the lambda loop cannot close straight after a cold start, as section 03 said.
Sensors have a heater to get there faster.

ECM is engine control module, another name for the ECU.

Notebook 06 will regenerate this characteristic.
-->

---
routeAlias: catalyst
class: big-figure
---

## Catalytic converters

<div class="grid grid-cols-[2fr_1fr] gap-6">
<div>

A catalytic converter is a vehicle emissions control device. It converts the toxic by-products of
combustion in the exhaust of an internal combustion engine into less toxic substances by way of
catalyzed chemical reactions. It treats

- carbon monoxide
- unburned hydrocarbons
- oxides of nitrogen

**Three stages**

- the **reduction catalyst** uses platinum and rhodium to help reduce the NOx emissions
- the **oxidation catalyst** reduces the unburned hydrocarbons and carbon monoxide by burning
  (oxidizing) them over a platinum and palladium catalyst
- the **control system** (second oxygen sensor)

</div>
<div>

![Catalytic converter configurations: a) a primary catalytic converter close to the engine and a main converter under the floor; b) a 4-in-2 exhaust manifold with the main converter after the second junction; c) one exhaust system per cylinder bank, each with a primary and main converter; d) a Y-shaped junction joining both banks into one main converter.](/pptx/slide59-catalyst-layouts.png)

</div>
</div>

<!--
Three-way means three pollutants at once. The trick is that the jobs are opposite. NOx must lose
oxygen, a reduction. CO and HC must gain oxygen, an oxidation. Both can happen in one converter only
if there is just enough oxygen for both, and that is lambda one. Lean, NOx goes through; rich, CO
and HC go through.

The catalyst also stores some oxygen, which is why the lambda limit cycle around one is acceptable:
the storage smooths the small rich and lean swings.

The third stage is not chemistry: it is the second oxygen sensor, which checks the catalyst works
and trims the first loop.

On the right, where the converters sit. A small primary converter close to the engine lights off
quickly after a cold start; the main one under the floor does the bulk of the work.
-->

---

## Summary of section 07

- The evaporative system stores tank vapor in a charcoal canister and purges it into the intake; to
  the fuel loop it is a disturbance.
- The three-way catalyst converts CO, HC and NOx only near λ = 1.
- The switching oxygen sensor says only rich or lean, so the λ loop is a jump-and-ramp limit cycle.
- Its speed is limited by the delays around the loop: injection, combustion, exhaust transport and
  the sensor.

### Next: the engine you build. <Link to="mapped-engine">→ 08, the mapped engine</Link>

<!--
That is the control system. The last section is the plant you will build in the hands-on.
-->
