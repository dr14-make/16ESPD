---
routeAlias: drive-cycles
layout: section
---

###### Section 09

# Drive cycles

The speed traces behind every fuel, CO₂ and emissions label, and the one you drive in the
hands-on: the WLTC, class 3b.

<!--
Section 01 gave the forces. Section 08 gave the engine. A drive cycle is what joins them: a
prescribed speed against time, the same for every car, so that the numbers on two labels can be
compared. At the end of the hands-on you drive your own car over the WLTC, 30 minutes of it. This
section says what that trace is, where it comes from, and what else engineers do with traces like it.
-->

---
routeAlias: why-cycles
---

## Why drive cycles exist

<div class="grid grid-cols-[1.25fr_1fr] gap-8">
<div>

- **Type approval** (homologation): a new car type must meet the pollutant limits and declare its
  fuel consumption and CO₂. One fixed speed trace makes every car's numbers comparable.
- **On a chassis dynamometer**: the driven wheels turn rollers, and a driver follows the trace on a
  screen, within **±2 km/h and ±1 s** of it.
- **The road load comes from a coast-down**: on a test track the car rolls free from high speed,
  its deceleration is fitted as a force, and the dynamometer applies that force.
- **Results per phase and combined**: pollutants and CO₂ in **g/km**; fuel in **L/100 km**,
  computed from the carbon in the exhaust.

</div>
<div>

**Road-load curve** (WLTP, $v$ in km/h)

$$
F \;=\; f_0 + f_1\,v + f_2\,v^2
$$

$f_0$ is mostly rolling resistance, $f_2$ mostly drag: the $O_F$ and $O_V$ of <Link to="drag-and-rolling">section 01</Link>.

> **Lecture 1's car as a road load**
>
> $f_0 = m\,g\,f_k =$ **164.8 N**, $f_1 = 0$,
> $f_2 = \tfrac12\rho\,c_x S_x / 3.6^2 =$ **0.0292 N/(km/h)²**

</div>
</div>

<!--
Why a fixed trace at all? Because a fuel figure means nothing without saying how the car was
driven. Section 08's cruise points already showed that: liters per 100 kilometers changes with
speed. So the regulation fixes the driving, and the car is the only variable.

The test is indoors. The car stands with its driven wheels on rollers, and a driver, a person or a robot, follows the speed on a screen. The tolerance band is plus or minus
2 kilometers per hour and plus or minus 1 second around the trace (Regulation 2017/1151,
Sub-Annex 6, as cited by MathWorks).

The rollers must push back as the road and the air would. That force is measured first, on a test
track: drive up to speed, shift to neutral, and record how the car slows down. The deceleration
times the mass is the road load, and it is fitted as f 0 plus f 1 v plus f 2 v squared (Sub-Annex 4,
paragraph 2.4: f 0 in newtons, f 1 in newtons per kilometer per hour, f 2 in newtons per kilometer
per hour squared). That is exactly section 01: the constant term is rolling resistance, the square
term is drag. For Lecture 1's car, with its 1400 kilograms, f k of 0.012, C d A of 0.63 and air at
1.2, that is 164.8 newtons and 0.0292; its rolling resistance has no speed term, so f 1 is zero.

The exhaust is collected per phase. Fuel is not metered: it is calculated from the carbon in the
exhaust, CO2, CO and hydrocarbons (Sub-Annex 7, paragraph 6), so CO2 and fuel are two views of one
measurement.
-->

---
routeAlias: modal-vs-transient
class: big-figure
---

## Modal and transient cycles

<CardExport notebook="illustrations" name="nedc-vs-wltc" height="27rem" />

<div class="grid grid-cols-2 gap-8 text-sm mt-2">
<div>

**Modal** (synthetic): constant accelerations, constant speeds. The **NEDC**, four urban ECE-15
cycles and one extra-urban EUDC, was the EU's type-approval cycle until WLTP; its hardest
acceleration is **1.04 m/s²**.

</div>
<div>

**Transient** (from real driving): speed changes every second. The **WLTC** was built from
driving data, as were the US FTP-75 and the Artemis cycles; class 3b reaches **1.67 m/s²** and
**131.3 km/h**.

</div>
</div>

<!--
Two ways to write a cycle. Top, the NEDC: every piece is a straight line, a constant
acceleration or a constant speed, from a table of 25 operations for the urban part and 21 for the
extra-urban part (UNECE Regulation 83, Annex 4a). Four times the same 195 second town cycle, up to
50, then one 400 second run out of town, up to 120 for 10 seconds. The plot is drawn from those
tables.

Bottom, the WLTC class 3b, 1800 seconds, one speed per second, from the regulation's tables. Its
shape is irregular because it was assembled from recorded driving: about 765 000 kilometers of
in-use data from the EU, Switzerland, the US, India, Korea and Japan, weighted by each region's
mileage, cut into short trips and recombined (JRC). The US FTP-75 goes back to a Los Angeles
route, the LA4; the Artemis cycles to a European real-world driving database.

The difference matters for calibration. On a modal cycle the engine sees a handful of steady
operating points and a few gentle ramps; an ECU can be tuned to look good exactly there. On a
transient cycle the engine passes through most of its map. The hardest acceleration over one
second is 1.04 meters per second squared on the NEDC, the very first ramp, and 1.67 on the WLTC,
at 1029 seconds.
-->

---
routeAlias: cycles-by-region
---

## The main cycles

<div class="text-sm">

| Cycle | Region, use | Type | Duration s | Distance km | Average km/h | Max km/h | Standstill |
|---|---|---|---|---|---|---|---|
| NEDC | EU type approval until 2017–18 | modal | 1180 | 11.03 | 33.6 | 120.0 | 24 % |
| WLTC class 3b | EU since 2017, UN GTR 15 | transient | 1800 | 23.27 | 46.5 | 131.3 | 13 % |
| FTP-75 | US city label | transient | 1874 | 17.77 | 34.1 | 91.2 | 18 % |
| HWFET | US highway label | transient | 765 | 16.51 | 77.7 | 96.4 | 1 % |
| US06 | US, aggressive driving | transient | 600 | 12.89 | 77.3 | 129.2 | 7 % |
| JC08 | Japan until WLTC (2018) | transient | 1204 | 8.17 | 24.4 | 81.6 | ≈ 30 % |
| CADC urban · rural · motorway 130 | research (Artemis) | transient | 993 · 1082 · 1068 | 4.87 · 17.28 · 28.74 | 17.7 · 57.5 · 96.9 | 57.3 · 111.1 · 131.4 | — |

</div>

<div class="grid grid-cols-[1.2fr_1fr] gap-8 text-sm mt-3">
<div>

**The WLTC class is set by the power-to-mass ratio** (rated power over mass in running order
minus 75 kg): class 1 up to 22 W/kg, class 2 up to 34 W/kg, class 3 above; class 3 splits at a
top speed of 120 km/h into 3a and **3b**. Class 3 stands for the cars driven in Europe and Japan.

</div>
<div>

**Japan** replaced JC08 by the WLTC for labels of new models from October 2018. **The US** label
rests on FTP-75 and HWFET; since 2008 its 5-cycle method adds US06, the air-conditioning cycle
SC03 and a cold FTP.

</div>
</div>

<!--
The table puts the main cycles side by side. NEDC, WLTC and the three EPA cycles are computed in
the illustrations notebook from the regulations' and EPA's own traces, all the same way: distance
is the integral of the speed, average speed includes the stops, standstill is the time at zero.
JC08 and the Artemis cycles are DieselNet's figures; JC08's standstill is derived from its two
average speeds, with and without idle.

Read the columns against each other. The NEDC is short, slow and stands still a quarter of the
time. The WLTC is half as long again, faster on average, and stands still half as much. The US
splits city and highway into two cycles and adds US06 for hard driving. Japan's JC08 was a slow
city cycle with a lot of idling.

The CADC, the Common Artemis Driving Cycles, came out of a European research project on real-world
driving patterns. They are not used for approval; researchers use them to test a car the way it is
driven.

The class rule decides which WLTC a car drives. Low-powered vehicles get a gentler trace they can
actually follow. The hands-on car has 86.8 kilowatts on 1400 kilograms, 62 watts per kilogram, and
a top speed near 190: class 3b.

The regulation states 1.013 kilometers for one ECE-15 cycle; integrating its own operation table
gives 1.018, so the NEDC comes to 11.03 kilometers here against the 11.007 often quoted. The
standstill figure for the WLTC counts the time between two zero samples; DieselNet's 242 seconds of
stops also round to 13 percent.
-->

---
routeAlias: lab-and-road
---

## The gap between the label and the road

<div class="grid grid-cols-2 gap-8">
<div>

- **The NEDC was gentle**: low accelerations, a few steady points, 24 % standing still. Few real
  drivers drive like that.
- **The gap grew**: by 2017, real-world fuel consumption of new EU cars was **39 %** above the
  NEDC label, more than four times the 2001 gap (ICCT).
- **Cycle beating**: a known, fixed trace invites calibrating to the trace and using every
  tolerance of the test.
- **Dieselgate** (September 2015): software recognized the laboratory test and ran full NOx
  control only there; on the road NOx was **up to 40×** the US standard (US EPA).

</div>
<div>

**The response in the EU**

- **WLTP** replaces the NEDC: new models from **September 2017**, all new cars from
  **September 2018**.
- **RDE**, Real Driving Emissions: NOx and particle number measured **on the road** with a
  portable emissions measurement system (**PEMS**) in the car. A conformity factor of
  **2.1** allowed for NOx at first, for new models from September 2017 and all new cars from
  September 2019.
- RDE complements the laboratory test; it does not replace it. CO₂ and fuel stay a laboratory
  measurement.

</div>
</div>

<!--
Context, briefly; it is the history of why the hands-on drives the trace it does.

The NEDC grew out of the ECE-15 town cycle, with the extra-urban part added later. Every car drove
it the same way, so every car could be tuned for it, within every tolerance the procedure allowed.
That was legal, and the gap between the label and what drivers measured at the pump grew year
after year: 39 percent in 2017, against under a tenth
in 2001, according to the ICCT's analysis of about 1.3 million cars.

Dieselgate was the illegal end of the same problem. In September 2015 the US EPA notified
Volkswagen that its 2.0 liter diesels detected the official test and switched on full emission
controls only during it; in normal driving, NOx was up to 40 times the standard. The discrepancy
was found by West Virginia University researchers working with the ICCT, on the road, with
portable equipment.

The EU's answer was two-sided. The WLTP, with the WLTC, replaced the NEDC in the laboratory. And
RDE took the pollutant measurement onto the road: a PEMS attached to the car, driven on real roads
with random variations of acceleration, deceleration, ambient temperature and payload. The conformity factor allows for the
measurement uncertainty of the portable equipment: 2.1 means 168 milligrams of NOx per kilometer
against the 80 milligram limit for a diesel (European Commission).
-->

---
routeAlias: using-cycles
---

## How engineers use cycles

<div class="grid grid-cols-[1fr_1.1fr] gap-8">
<div>

**Two ways to simulate a car over a cycle**

- **Backward** (quasi-static): from the trace's speed and acceleration, compute the force at the
  wheel, then torque and speed at the engine, then fuel from the map. Fast, no driver; it assumes
  the car follows the trace.
- **Forward** (dynamic): a **driver model** compares the car's speed with the trace and sets pedal
  and brake; the powertrain responds. Slower, but the car can fall short of the trace. The
  hands-on uses this: your car, its engine, a PI driver.

**Uses**: sizing (peak power the trace demands), gear ratios and shift schedules, calibrating on
the cycle, and comparing powertrains on equal terms.

</div>
<div>

**One car, three drivelines over the WLTC** (backward estimate, hot start, lossless driveline)

<div class="text-sm">

| Driveline | L/100 km | g CO₂/km |
|---|---|---|
| One gear, i = 4.0 | 5.63 | 130 |
| 5-speed manual | 5.26 | 121 |
| Ideal CVT, minimum-fuel line | 4.93 | 113 |
| *Label: Mazda2 1.5 Skyactiv-G* | *5.3* | *120* |

</div>

The one gear runs out of torque for **116 s** of the cycle, mostly at launches, so its figure is
not reachable: that is why the hands-on car gets a CVT.

</div>
</div>

<!--
A drive cycle is also an engineering tool, long before the car meets a dynamometer.

Backward-facing: start from the trace. At every second you know speed and acceleration, so you
know the force the wheels must deliver: road load plus mass times acceleration. Through the
gearing that is a torque and speed at the engine, and the fuel map gives the fuel. No dynamics, no
driver, so it is fast; but it cannot tell you the car is unable to deliver what the trace asks.

Forward-facing: the way the car really works. A driver, here a PI controller, looks at the speed
error and moves the pedal; the engine and the driveline produce a torque, and the car's speed
follows from the dynamics. If the engine is too weak, the car falls behind the trace, and you see
it. NREL's ADVISOR combined the two for speed (Wipke and others, 1999). The hands-on is
forward-facing, with the mapped engine of section 08.

The table is the backward estimate made while planning the hands-on, for its car and its engine
maps: the same body and the same engine, three drivelines. A single fixed ratio wastes fuel at low
speed and runs out of torque for 116 seconds of the cycle, mostly at launches. A five-speed gearbox
is better; an ideal CVT that holds the engine on its best-efficiency line is better still, 4.93
liters per 100 kilometers. The real Mazda2 1.5, same engine family, is labeled 5.3 and 120 grams
(WLTP combined, Autotijd database). The estimate leaves out the cold start, the auxiliaries and the
driveline losses, which is why it reads low; a real belt CVT loses more than a manual gearbox.
-->

---
routeAlias: wltc-class-3b
class: big-figure
---

## The WLTC class 3b, which you drive

<div class="grid grid-cols-[1.7fr_1fr] gap-6 items-center">
<div>

<CardExport notebook="illustrations" name="wltc-3b" height="27rem" />

</div>
<div class="text-sm">

**Four phases**, each from standstill to standstill: Low, Medium, High, Extra High; 1800 s and
**23.27 km** in all.

**In the hands-on** your car, with its mapped engine and a CVT, follows the trace with a PI driver.
You read off

- the speed error against the trace,
- the distance at 1800 s: 23.27 km if the car kept up,
- the fuel burned, in L, then **L/100 km** and **g CO₂/km**,
- the phase figures at 589, 1022 and 1477 s: Low costs most per km.

</div>
</div>

<!--
This is the trace you drive. Class 3b, because the hands-on car has more than 34 watts per
kilogram and a top speed above 120.

Four phases, each a short trip of its own that starts and ends at rest. Low is town: 589 seconds,
3.095 kilometers, under 19 kilometers per hour on average, with a quarter of it standing still.
Medium is suburban, High is a main road, Extra High is the motorway, with the top speed of 131.3.
The dashed line is the distance covered; its markers are the phase ends, the instants at which you
split your fuel integral.

Two checks before you believe your fuel figure. First, the car must follow the trace: plot its
speed over the trace's. Second, the distance at the end must be 23.27 kilometers; a car that fell
behind has driven a different, easier cycle.

Then the number on the label: liters over kilometers, times 100. CO2 follows from the fuel, 2302
grams per liter of petrol, as in step 05. Low will be the worst phase per kilometer, from idling at
the stops and the launches; High the best.
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
- **09** labels come from fixed drive cycles; the WLTC replaced the gentle NEDC, and you drive it.

### An engine control unit is a stack of control loops wrapped around one nonlinear plant.

<!--
Back to the sentence we started with. The plant is the engine, nonlinear in speed and load: the
maps are how the ECU copes with that. The loops are fuel, spark, idle and lambda, each with its
sensors and actuators.

In the hands-on you build the plant. The notebooks put the loops around it, one at a time. And at
the end you drive it over the cycle that produces the number on a car's label.
-->
