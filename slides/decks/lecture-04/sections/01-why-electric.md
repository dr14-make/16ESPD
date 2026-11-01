---
routeAlias: why-electric
layout: section
---

###### Section 01

# Why electric

The case for the electric car, the energy it needs, and the chain that delivers it both ways.

<!--
Section 01, why electric. Before we build anything, three things: the case for the electric car, the
energy the car needs to drive a cycle, and the chain of links that delivers that energy to the
wheels and, when the car brakes, takes it back.
-->

---
routeAlias: why-evs
---

## Why electric vehicles

<div class="grid grid-cols-2 gap-8">
<div>

**The problem** (EEA, EU)

- Transport causes nearly a quarter of Europe's greenhouse-gas emissions, and has cut them less
  since 1990 than other sectors; road vehicles emit 73 % of it.
- EU fleet CO₂ limits for new cars, Regulation 2019/631 as amended: 95 g/km from 2020 (NEDC),
  **93.6 g/km** for 2025–29 and **49.5** from 2030 (WLTP), **zero from 2035**.

**What the electric drive changes**

- The chain from battery to wheel loses a few percent per link; a petrol engine turns at most
  about 40 % of its fuel into work (Toyota), Lecture 2's 36 % (derived).
- Nothing burns on board: no local exhaust.
- **Braking energy comes back.** The motor turns generator and charges the battery.
- Few moving parts, no gearbox, no oil change.

</div>
<div>

**What it costs**

- The battery: mass, cost, and energy per kilogram far below a fuel tank's.
- Charging time, and range in the cold.
- The CO₂ moves to the power station: it is only as clean as the grid. EU power, 2024:
  **183 g CO₂e/kWh** (EEA); at the Leaf's 17.1 kWh/100 km, about **31 g/km** (derived).

> **Today's question**
>
> Where does an electric car's energy go on the WLTC, and how much of it comes back?
> Section 08 answers it in kWh/100 km, link by link.

</div>
</div>

<!--
On the left, the problem, and what the electric drive changes. Transport causes nearly a quarter
of Europe's greenhouse-gas emissions, and since 1990 it has cut them less than the other sectors
have: that is the European Environment Agency's transport indicator, in its November 2025 edition.
Road transport emits 73 percent of the EU's transport emissions, the same indicator says for 2023.

The European Union limits the average CO2 of each manufacturer's new cars. The first limit, in
Regulation 443 of 2009, was 130 grams per kilometer. Its successor, Regulation 2019/631, set 95
grams per kilometer from 2020, measured on the old NEDC cycle, and cuts from a 2021 reference
measured on the WLTP: 15 percent from 2025 and, as adopted, 37.5 percent from 2030. Its 2023
amendment, Regulation 2023/851, raised the 2030 cut to 55 percent and added a 100 percent cut from
2035. On the WLTP that is 93.6 grams per kilometer for 2025 to 2029, 49.5 grams from 2030, and zero
grams from 2035, which in practice means only zero-emission new cars. The numbers 93.6 and 49.5 are the Commission's implementing decision of
2023. Two slides on, we see how the fleet has followed these limits, and which of them are being
reopened right now.

What does the electric drive change? First, efficiency. The chain from the battery to the wheel
loses a few percent per link, while a petrol engine turns at most about 40 percent of its fuel into
work, at its very best operating point. That 40 percent is Toyota's figure for its 2-liter Dynamic
Force engine of 2018, among the best production petrol engines. Lecture 2's engine, from the EPA's
map of a Mazda 2-liter, peaks at 36 percent, which I derived from its torque and fuel maps. And on
a drive cycle an engine spends most of its time far below its best point. Second, nothing burns on board, so there is no local exhaust. Third,
braking energy comes back: when the car brakes, the motor turns generator and charges the battery.
And fourth, the mechanics are simple: few moving parts, no gearbox, no oil change.

On the right, what it costs. The battery: its mass, its cost, and an energy per kilogram far below
that of a fuel tank. Charging takes time, and the range drops in the cold. And the CO2 does not
disappear, it moves to the power station: an electric car is only as clean as the grid that charges
it. How clean is that? The European Environment Agency puts the EU's electricity generation in 2024
at 183 grams of CO2 equivalent per kilowatt-hour, 41 percent less than ten years earlier. The Leaf
we model is rated at 17.1 kilowatt-hours per 100 kilometers on the WLTP, measured at the plug; that
figure comes from ADAC's catalog, a secondary source. 17.1 times 183 is about 31 grams per kilometer,
my own arithmetic, against the 93.6 grams the law asks of the average new car at its tailpipe. Not
zero, but far less, and falling as the grid gets cleaner.

The box at the bottom right is today's question: where does an electric car's energy go on the WLTC,
and how much of it comes back? Section 08 answers it in kilowatt-hours per 100 kilometers, link by
link. Instead of taking an efficiency from a brochure, we measure it on the model we build.
-->

---
routeAlias: ev-market
class: big-figure
---

## Where the market is

<div class="grid grid-cols-[1.6fr_1fr] gap-6 items-center">
<div>

![Electric share of new-car sales, battery-electric and plug-in hybrid together, 2015 to 2025. China rises from 1 % to 53 %, Europe from 1 % to 28 % with a jump in 2020, the world from under 1 % to 25 %, the United States from under 1 % to 10 %, flat since 2023.](/figures/01-ev-share.svg)

<div class="caption">IEA Global EV Data Explorer, via Our World in Data (2026). BEV + PHEV.</div>

</div>
<div class="text-[0.95rem]">

**2025** (IEA, Global EV Outlook 2026)

- more than **20 million** electric cars sold: **25 %** of new cars, BEV and PHEV;
- China almost **55 %**, Europe **28 %**, the US just below **10 %**.

**In the EU** (ACEA): battery-electric **17.4 %** of new cars in 2025, 13.6 % in 2024; plug-in
hybrids 9.4 %.

**Charging** (IEA): over **7 million** public points worldwide at the end of 2025.

</div>
</div>

<!--
Before the physics, where the market stands. The figure is drawn by a script in the repository from
a small table under `data/ev_context`, with its sources. It shows the share of new cars sold that
are electric, which here means battery-electric and plug-in hybrids together, from 2015 to 2025.
The values are the International Energy Agency's Global EV Data Explorer, as Our World in Data
republishes it; the explorer itself would not download from a script, so this is a secondary copy
of the IEA's numbers, and it agrees with the IEA's own report for the last three years.

Read the four lines. Blue is China: about 1 percent in 2015, then a steep climb from 2021, to 53
percent in 2025 in the data file. Orange is Europe, the IEA's region: slow until 2020, a jump that
year when the EU's 95 gram limit began to bite, then flat around 21 to 22 percent, and up to 28
percent in 2025. Green is the world, 25 percent. Purple is the United States, about 10 percent and
flat since 2023.

On the right, the headline numbers in the IEA's own words, from its Global EV Outlook 2026 of May
2026. More than 20 million electric cars were sold in 2025, a quarter of all new cars. China almost
55 percent; the report says almost 55 while its data file says 53, and I quote both so you see the
two. Europe 28 percent, and the United States just below 10 percent.

For the European Union alone, the carmakers' association ACEA counts battery-electric cars only:
17.4 percent of new registrations in 2025, up from 13.6 percent in 2024, with plug-in hybrids
another 9.4 percent. That is from ACEA's full-year press release of January 2026.

And the chargers: the IEA counts more than 7 million public charging points worldwide at the end of
2025, 1.8 million of them added that year.

Why does this matter for an engineering lecture? Because a quarter of the world's new cars now
carry the chain we build today: battery, converter, machine, gear, wheel.
-->

---
routeAlias: eu-co2
class: big-figure
---

## The EU's CO₂ limit for new cars

<div class="grid grid-cols-[1.6fr_1fr] gap-6 items-center">
<div>

![Average CO2 of new cars in the EU, 2010 to 2025, with the targets dashed. On the NEDC cycle the fleet falls from 140 to 118 g/km by 2016, rises to 122 in 2019 and drops to 108 in 2020, against 130 for 2015–19 and 95 from 2020. On the WLTP the fleet is 148 in 2019, 130 in 2020, 114 in 2021, about 107 to 2024 and 96.7 in 2025, against about 115 for 2021–24, 93.6 for 2025–29, 49.5 for 2030–34 and 0 from 2035; a dotted line at about 11 g/km marks the proposed 90 % cut.](/figures/01-eu-co2.svg)

</div>
<div class="text-[0.95rem]">

**The fleet** (EEA): 106.7 g/km in 2024, **96.7** in 2025 (provisional, WLTP).

**The law** (EU): 2019/631, amended by 2023/851 and 2025/1214: 93.6 g/km on average over
**2025–27**, 49.5 from 2030, zero from 2035; **€95** per g/km over, per car.

**Under review:** the Commission proposed in Dec 2025 a **90 %** cut for 2035, with credits for
the rest. Not adopted on 1 Nov 2026.

</div>
</div>

<!--
How has the fleet followed the law? The figure is drawn from the European Environment Agency's
monitoring data, the average CO2 of all new cars registered in the EU, with Iceland and Norway, and
the targets dashed. Its table is in the repository too.

Blue is the old test cycle, the NEDC. From 140 grams per kilometer in 2010 the average fell to 118
by 2016, under the 130 gram target, then crept back up to 122 in 2019. In 2020 the 95 gram target
came in, and the average dropped by 15 grams in one year, the same year Europe's electric share on
the last slide jumped from 3 to 10 percent.

Orange is the WLTP, the cycle that replaced the NEDC. For 2019 and 2020 the EEA gives both, and
the step from 122 to 148 in 2019 is not the cars getting worse, it is the harder test cycle; the
gray text marks it. On the WLTP, the 95 grams of the NEDC correspond to about 115, the EEA's
equivalent, and the fleet sat below it from 2021, at about 107 grams through 2024. In 2025 the
target dropped to 93.6, and the fleet followed to 96.7, provisional, from the EEA's news of June
2026.

Why is 96.7 above 93.6 allowed? That is the first line on the right of the law. The 2025
amendment, Regulation 2025/1214 of June 2025, lets each manufacturer average its emissions over
2025, 2026 and 2027 instead of meeting the target every year; the targets themselves did not change.
A manufacturer that misses pays 95 euros per gram per kilometer over its target, for every car it
registered. Then 49.5 from 2030, and zero from 2035.

The last box is the news. The regulation itself asks the Commission to review the 2035 target in
2026. In December 2025 the Commission proposed, in its automotive package, to replace the 100
percent cut by 90 percent, with the remaining 10 percent compensated by credits for low-carbon
steel and renewable fuels; the dotted line, about 11 grams per kilometer, is my own arithmetic for
90 percent off the 2021 reference. As of today, 1 November 2026, it is not law: Parliament's
committees have not finished, its plenary vote is expected in November or December, and the Council's
progress report of June said the member states' positions diverge widely. So the law in force is
still zero from 2035. If you read this deck later, check the European Parliament's procedure file,
2025/0420, for the outcome.
-->

---
routeAlias: rules-timeline
class: big-figure
---

## The rules, 2025–2036

<img src="/diagrams/01-rules-timeline.svg" class="mx-auto" style="max-height: 33rem" alt="Timeline from 2024 to 2036 in five lanes, with today, 1 November 2026, marked. EU car CO2: 93.6 g/km averaged over 2025–27, 49.5 from 2030, 0 from 2035 in law, a 90 % cut proposed in December 2025 and not adopted. Euro 7: new types from 29 November 2026, all new cars from 29 November 2027, tyre abrasion for new C1 types from July 2028; brake particles 3 mg/km for a BEV and 7 for the rest; battery at least 80 % after 5 years or 100 000 km and 72 % after 8 years or 160 000 km. Batteries: passport from 18 February 2027, recycled content from August 2031 and 2036, carbon-footprint declaration waiting for its method. Charging: 400 kW every 60 km on the core network by end 2025, 600 kW by end 2027, the wider network by end 2030, 1.3 kW per BEV. United States: the EPA's CO2 standards for 2027 on repealed in February 2026 and in court, CAFE reset to 34.9 mpg in 2031, EV tax credit ended September 2025."/>

<!--
The rules an electric car is designed against, on one time line from 2024 to 2036. The red dashed
line is today, the first of November 2026. Each lane is one regulation; green diamonds are dates in
force, the lane's gray line is the fine print.

The top lane is the CO2 limit of the last slide: 93.6 grams averaged over 2025 to 2027, 49.5 from
2030, zero from 2035 in law, with the 90 percent proposal of December 2025 not adopted.

Second, Euro 7, Regulation 2024/1257, the first exhaust standard that also regulates what an
electric car emits. It applies to new types of cars from the 29th of November 2026, four weeks from
now, and to all new cars a year later. It adds two things for electric cars. Brake dust: particles
below 10 micrometers, PM10, at most 3 milligrams per kilometer for a battery-electric car and 7 for
every other car until 2034, and 3 for all from 2035. The electric car gets the stricter limit
because regen does most of its braking, which is exactly what section 07 is about. And tire wear,
abrasion limits for new types of ordinary car tires from July 2028 and for all of them from 2030;
the limit values themselves come from the UN's vehicle regulations, not from Euro 7. The second
thing is battery durability: a car's battery must keep at least 80 percent of its certified energy
for 5 years or 100 000 kilometers, and 72 percent up to 8 years or 160 000 kilometers.

Third, the EU Battery Regulation, 2023/1542. From the 18th of February 2027 every electric-vehicle
battery placed on the market carries a digital battery passport. From August 2031 a new EV battery
must contain recycled cobalt, lithium and nickel, 16, 6 and 6 percent, rising in 2036 to 26, 12 and
15. A declaration of the battery's carbon footprint was due from February 2025, but only 12 months
after the Commission adopts the method for computing it, and as of today it has not, so that duty has
not started yet.

Fourth, charging, the Alternative Fuels Infrastructure Regulation, 2023/1804. Along the EU's core
trunk roads, a charging pool every 60 kilometers in each direction, at least 400 kilowatts with one
point of 150 kilowatts by the end of 2025, and 600 kilowatts by the end of 2027; the wider network by
2030. And every year, each member state must offer 1.3 kilowatts of public charging power for each
battery-electric car registered there.

Last, the United States, where the direction reversed. The EPA's 2024 standards for model years 2027
onward would have cut new cars' CO2 by about half by 2032. In February 2026 the EPA rescinded its
2009 endangerment finding and with it every vehicle greenhouse-gas standard; states and
environmental groups are challenging that in court, with no ruling yet. The fuel-economy standards,
CAFE, were reset in September 2026 to about 34.9 miles per gallon for model year 2031, against about
50 under the 2024 rule, and since July 2025 the fine for missing them is zero dollars. The federal
tax credit for buying an electric car ended on the 30th of September 2025. Every one of these is
in the course's research note with its Federal Register or Official Journal reference.
-->

---
routeAlias: energy-model
---

## The energy the car needs: Lecture 2's road load

<div class="grid grid-cols-[1.1fr_1fr] gap-8">
<div>

The deck's energy model, term by term, at the wheel:

$$
F = \underbrace{\tfrac12 \rho\, C_d A\, v^2}_{O_v,\ \text{drag}}
  + \underbrace{f_r\, m g}_{O_f,\ \text{rolling}}
  + \underbrace{m\, a}_{O_z,\ \text{acceleration}}
  + \underbrace{m g \sin\alpha}_{O_s,\ \text{slope}}
$$

plus $O_{aux}$, the auxiliaries, drawn from the battery.

It is Lecture 2's `RoadLoad`, now a part of its own: the same law drives the engine car and the
planar car.

</div>
<div class="tight">

| Course car | Value |
|---|---|
| mass *m* | 1500 kg |
| *C*<sub>d</sub>*A* | 0.63 m² |
| rolling *f*<sub>r</sub> | 0.012 |
| auxiliaries | 300 W |
| cycle | WLTC class 3b, 23.27 km |

<div class="handson">On WLTC at 1500 kg: <b>139 Wh/km</b> of traction at the wheel, and braking
energy worth <b>25–26 %</b> of it (derived, plan)</div>

</div>
</div>

<!--
How much energy does the car need? That is Lecture 2's road load, which the deck calls its energy
model. Let us read the formula term by term. F is the force the wheels must push with, in newtons,
and it has four parts. The first is aerodynamic drag, O v in the deck's notation: one half times the
air density rho, in kilograms per cubic meter, times the drag coefficient C d times the frontal area
A, in square meters, times the speed v squared, in meters per second. The second is rolling
resistance, O f: the rolling coefficient f r, which has no unit, times the mass m in kilograms,
times g, 9.81 meters per second squared. The third is the force that accelerates the car, O z: mass
times acceleration a. The fourth is the slope, O s: m g times the sine of the road's angle alpha.
These four are forces at the wheel. The deck adds a fifth term, O aux, the auxiliaries: everything
electrical that is not propulsion. That one is not a force at the wheel but a power drawn from the
battery.

This is exactly the road load of Lecture 2's notebook 01. What is new is that the course library has
taken it out into a part of its own, `RoadLoad`, with no mass in it, so that the planar car can use
the same law through an adapter. The engine car and the electric car meet the same road.

The table gives the course car's numbers: 1500 kilograms; a C d A of 0.63 square meters; a rolling
coefficient of 0.012; 300 watts for the auxiliaries, which is a car on a test cycle with the climate
control off; and the WLTC class 3b cycle, 23.27 kilometers long.

The green box is the size of the prize. Run this road load backwards over the WLTC with a 1500
kilogram car and add up the positive power at the wheel: 139 watt-hours per kilometer of traction.
Add up the negative power, the braking phases, and you get energy worth 25 to 26 percent of that.
That is the upper limit of what regenerative braking could recover on this cycle, if every bit of
the braking energy came back. Both numbers are derived in the course's research note, from the cycle
file and this road load. The same calculation shows that less than 4 percent of the braking energy
lies below 15 kilometers per hour, so a regen system that fades out at walking pace gives away very
little.
-->

---
routeAlias: energy-chain
class: big-figure
---

## The chain, both ways

<div class="diagram-wide">

![Block chain from left to right: grid and charger (dashed), battery (V = E − R0 i, step 03, 3.1 Wh/km), converter (v_out = d v_in, step 02, 2.1 Wh/km), machine (T = KΦi, E = KΦω, step 01, 17.6 Wh/km), reduction and differential (8.193, ideal, step 04), wheels and road (104.9 Wh/km). Black arrows to the right for driving, green arrows back to the battery for braking; the 12 V network hangs off the battery at 300 W, 6.4 Wh/km.](/diagrams/01-energy-chain.svg)

</div>

Every link is reversible. Each step today builds one, from the motor outwards; step 06 puts a
meter on each and reads the bill.

<!--
This picture is the lecture. Read it first from left to right, along the black arrows: that is
driving, with the energy flowing to the road. The grid fills the battery through a charger, which
costs 10 to 15 percent. The charger box is dashed: dashed means given in the course library, or
outside the model. The battery, V equals E minus R0 i, is built in step 03. It feeds the converter,
v out equals d times v in, built in step 02. The converter feeds the machine, T equals K Phi i and E
equals K Phi omega, built in step 01. The machine turns the reduction and the differential, ratio
8.193, ideal in the model, so they cost nothing; that is step 04. And the wheels push against the
road: drag, rolling resistance and tire slip. The 12 volt network hangs off the battery at 300
watts.

Now read the green arrows from right to left: that is braking. The wheels drive the machine, the
machine generates, the converter's current reverses, and the pack charges. Only below walking pace
do the friction brakes take over.

The orange numbers are the losses per kilometer on the WLTC, measured on the finished car in build
step 06. The road takes 104.9 watt-hours per kilometer: 103.1 in drag and rolling resistance and 1.8
in tire slip. The machine loses 17.6. The 12 volt network takes 6.4, the battery's resistance 3.1,
the converter 2.1, and the friction brakes, below walking pace, 0.1. All together, 134.3 watt-hours
per kilometer leave the cells, the number at the bottom of the picture.

The green step numbers are the build order. We start with the machine, the heart of the chain and
the link the theory explains, then the converter that feeds it, the battery behind it, the car
around it, regen, and finally the bill. That is the sentence under the picture: every link is
reversible, each step builds one, and step 06 puts a meter on each and reads the bill.
-->

---
routeAlias: bev-layout
---

## The battery-electric car

<div class="grid grid-cols-2 gap-8">
<div>

**Three parts** (deck): a battery to store the energy, a motor, and a controller between them
that sets the motor's power.

The battery is charged

- from the grid, through the plug;
- by **regenerative braking**.

**The controller's quadrants**

- forward and reverse driving: a **two-quadrant** controller;
- plus braking in both directions, energy back into the battery: **four quadrants**.

</div>
<div class="tight">

**The car you build: Leaf ZE1 numbers**

| | Value | Source |
|---|---|---|
| peak torque, power | 320 N·m, 110 kW | Nissan |
| base speed | 3283 rpm | Nissan |
| top motor speed | ≈ 10 100 rpm | derived |
| reduction | 8.193 | Nissan |
| pack | 40 kWh, 350 V, 96s2p | Nissan |
| pack resistance | 0.10–0.14 Ω | INL |
| mass | 1500 kg | course car |

</div>
</div>

<!--
The deck's battery-electric car has three parts: a battery that stores the energy, a motor, and a
controller between them that sets the motor's power. The battery is charged in two ways: from the
grid, through the plug, and by regenerative braking.

The controller is what we call the converter today. It sets the voltage the motor sees and the
current it draws. The deck sorts controllers by quadrants, the four quadrants of torque against
speed. A two-quadrant controller drives forward and in reverse. A four-quadrant controller can also
brake in both directions, with the current reversed so that the energy goes back into the battery.
Regenerative braking needs four quadrants.

The table on the right is the car you build today, with each number's source. Peak torque 320 newton
meters and peak power 110 kilowatts, both from Nissan's specification. Base speed 3283 rpm, also
Nissan's, and you can check that the numbers agree: 110 000 watts divided by 320 newton meters is
343.8 radians per second, which is 3283 rpm. So the motor gives 320 newton meters up to 3283 rpm,
where it meets its 110 kilowatts. The top motor speed, about 10 100 rpm, is derived: Nissan does not
state it, but the car's top speed of 144 kilometers per hour, through the 8.193 reduction and a
wheel radius of 0.31 meters, gives about 10 100 rpm. The reduction ratio, 8.193, is Nissan's. The
pack is 40 kilowatt-hours at 350 volts nominal, made of 96 pairs of cells in series, 96s2p. The pack
resistance, 0.10 to 0.14 ohm, comes from Idaho National Laboratory's pulse tests on a 2013 Leaf
pack; it rises by about half near empty, and our model uses 0.1 ohm. And the mass is the course
car's 1500 kilograms.

Why a car from 2017? Because it is the best-documented electric car there is: Nissan's
specification, Oak Ridge's teardown and Argonne's and Idaho's tests all describe it. It is no
longer built. The trade press reported the last ZE1 off the line in Sunderland in February 2024, and
Nissan announced the third-generation Leaf in June 2025, with a 52 or 75 kilowatt-hour pack and 130
or 160 kilowatts. The chain we build is the same; only the numbers grow.

The hybrid layouts, series and parallel, are next lecture, on the same car.
-->

---

## Summary of section 01

- A quarter of new cars sold worldwide in 2025 were electric (IEA); the EU's CO₂ limit is
  93.6 g/km now and zero from 2035 in law (EU), with a 90 % cut proposed.
- An electric car is a chain of reversible links: battery, converter, machine, gear, wheel.
- It needs the same road load as the engine car: on WLTC, **139 Wh/km** of traction at the
  wheel, and braking energy worth **a quarter** of it.
- The controller must work in four quadrants to brake into the battery.
- The car you build has the Leaf ZE1's motor, gear and pack on the course car's body.

### Next: the first link, the machine. <Link to="dc-machine">→ 02, the DC machine</Link>

<!--
To sum up section 01. A quarter of the new cars sold worldwide in 2025 were electric, by the IEA's
count, and the EU's limit for new cars is 93.6 grams of CO2 per kilometer now and zero from 2035 in
the law as it stands, with a 90 percent cut on the table. An electric car is a chain of reversible links: battery, converter, machine,
gear, wheel. It needs the same road load as the engine car: on the WLTC, 139 watt-hours per
kilometer of traction at the wheel, and braking energy worth about a quarter of that, which regen
can bring back. To brake into the battery, the controller must work in four quadrants. And the car
you build has the Leaf ZE1's motor, gear and pack on the course car's body.

Next we open the chain at its first link, the machine, the link the deck spends the most slides on.
-->
