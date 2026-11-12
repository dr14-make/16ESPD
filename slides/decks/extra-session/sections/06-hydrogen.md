---
routeAlias: hydrogen
layout: section
---

###### Section 06

# Hydrogen on board and at the station

Storage at 700 bar, fueling to SAE J2601 with precooling, the station chain, how many stations
there are and how many closed, the price per kilogram and per 100 km, and AFIR Article 6.

<img class="hero" src="/photos/06-h2-magdeburg.jpg" alt="A hydrogen dispenser marked CGH2 standing next to ordinary petrol pumps under the canopy of a TotalEnergies filling station at dawn."/>

<div class="caption">H₂ at a TotalEnergies station, Magdeburg, 2023 · Michał Beim, CC BY-SA 4.0</div>

<!--
The fuel cell turns about 45 to 65 percent of the hydrogen's energy into electricity, depending on
load. The nozzle promises a full tank in about three minutes; the plug needs 18 to 43. This section
asks two questions. First, what does it take, at the car and at the station, to push five kilograms
of gas into a tank that fast? Second, how many stations are there, and what does the hydrogen cost
per kilogram, and so per 100 kilometers?

*[show photo]* A hydrogen dispenser, marked CGH2 for compressed hydrogen gas, beside the petrol
pumps of a TotalEnergies station in Magdeburg. Photograph by Michał Beim, Wikimedia Commons.
-->

---
routeAlias: hydrogen-as-fuel
skipInCut: true
---

## Hydrogen as a fuel

<div class="grid grid-cols-2 gap-8">
<div>

- **LHV: 33.3 kWh/kg** (deck); 119.96 MJ/kg (ANL)
- **At 700 bar, 15 °C:** about **40 kg/m³**
- The Mirai's **5.6 kg** fill = 187 kWh of hydrogen (LHV)

**Safety:** wide flammable range, low ignition energy, but much lighter than air: it dissipates
rapidly.

</div>
<div>

**Flammability in air:** 4–75 vol % (search summary) vs petrol vapor 1.4–7.6 % (search summary).

**Tank burst safety factor:** **2.25** (US) to **2.35** (EU).

<div class="caption text-left">[GONIN-HYSAFE-2026], [LOHSE-BUSCH-IJHE-2020], [DOE-SAFE-USE],
[DOE-REC-9013-2009] verified · 187 kWh: 5.6 × 33.3, derived</div>

</div>
</div>

<!--
Hydrogen as a fuel, in numbers. Its lower heating value, the one this deck uses, is 33.3
kilowatt-hours per kilogram. Argonne, a US lab, gives it as 119.96 megajoules. Per kilogram that is
a lot. Per liter it is tiny. Even at 700 bar and 15 degrees, a cubic meter holds only about 40
kilograms.

The Mirai's full tank, 5.6 kilograms, holds 187 kilowatt-hours. *[ask]* A Leaf battery holds 40. Why
does the Mirai not drive four and a half times as far? *[pause]* The fuel cell turns only about 60
percent of it into electricity. The battery car gives back most of its 40. And the Mirai is a large
car, nearly two tonnes. The energy in the tank is not the energy at the wheel. Section 07 follows
the whole chain.

Safety. The US Department of Energy, the DOE, sums it up. Hydrogen burns over a wide range of
mixtures with air, and a small spark can light it. But it is much lighter than air, so a leak rises
and spreads out quickly. The usual flammable range is 4 to 75 percent in air; for petrol vapor,
about 1.4 to 7.6. We could not check these two in a primary source, so treat them as rough. The
tanks have a burst safety factor of 2.25 in the US and 2.35 in the EU: they burst only at more than
twice their working pressure.

The DOE also lists the tests for a hydrogen car: tank leak tests, simulated garage leaks, and
dropping the tanks. The station has its own standards: ISO 19880 for the station, SAE J2601 for how
a car is fueled, J2799 for the car talking to the dispenser, ISO 17268 for the nozzle, ISO 14687 for
the purity of the gas.

*[ask]* Why 700 bar for cars, when buses use 350? *[pause]* Range in a small car. But the DOE's
numbers show the cost. In theory, compressing a kilogram to 350 bar takes 1.05 kilowatt-hours, and
to 700 bar 1.36, only 30 percent more. In practice, a 350 bar fill needs 440 bar at the dispenser,
and usually no precooling, no chilling of the gas, for 5 kilograms in five minutes. A 700 bar fill
needs 880 bar and gas at minus 40. A real station spends about 2.2 kilowatt-hours per kilogram for
350 bar, 3.0 for 700.

So the problem is density. Every way of storing hydrogen is a way of fighting that 40 kilograms per
cubic meter.
-->

---
routeAlias: storage-700-bar
---

## On board: 700 bar

<div class="grid grid-cols-[1.2fr_1fr] gap-8 items-start">
<div>

![Longitudinal section of a Type IV hydrogen tank: a capsule with domed ends; the outer layer is a hatched carbon-fiber wrap, labeled carries the pressure; inside it a thin plastic liner, labeled keeps the gas in, insulates, so a fill needs more precooling; the inside holds H2 at 700 bar, about 40 kg/m³ at 15 °C. A valve sits on the axis through the right dome. Note: Mirai gen 2, three tanks, 5.6 kg H2 in 142.2 L.](/diagrams/06-type-iv-tank.svg)

<div class="caption">Generic Type IV tank, not to scale · liner and precooling [TIAX-PD068-2010] · ≈ 40 kg/m³ at
700 bar, 15 °C [GONIN-HYSAFE-2026] · Mirai [TOYOTA-UK-MIRAI-SPECS-2024]; that its tanks are 700 bar
Type IV is commonly cited, not verified.</div>

**Pressure classes:** **H70** (70 MPa) for cars, **H35** (35 MPa) for buses and trucks.

</div>
<div>

<img class="photo" src="/photos/06-mirai-tank.jpg" style="height: 15rem" alt="A Mirai high-pressure hydrogen tank in a cutaway car: a yellow carbon-fiber-wrapped cylinder in a black shell, with its valve block and orange lines at one end."/>

<div class="caption">Mirai (gen 1) 70 MPa tank · Mariordo, CC BY-SA 4.0</div>

<div class="caption text-left mt-3">

Mirai gen 2: **5.6 kg** in 3 tanks, **142.2 L** · Hyundai Nexo (2025): **6.69 kg** usable in
3 × 54.2 L · Honda CR-V e:FCEV: **4.3 kg** at 10,000 psi

[TOYOTA-UK-MIRAI-2020], [TOYOTA-UK-MIRAI-SPECS-2024], [HYUNDAI-NEXO-2025], [MATTELAER-J2601-2024],
[TIAX-PD068-2010] verified · [HONDA-CRV-EFCEV-2024] secondary

</div>

</div>
</div>

<!--
How a car stores it. *[show photo]* On the right, a first-generation Mirai tank in a cut-open show
car: the yellow carbon-fiber wrap, the valve block at one end. Photograph by the user Mariordo,
Wikimedia Commons. The second Mirai has three tanks, together holding 5.6 kilograms in 142.2 liters.
That is about 39 kilograms per cubic meter, the density of hydrogen at 700 bar. The first Mirai held
4.6 kilograms in two tanks. The second goes about 30 percent further, up to 400 miles by Toyota's
figure. The new Hyundai Nexo: 6.69 kilograms in three tanks of 54.2 liters, up from 6.33. Honda's
CR-V: 4.3 kilograms at 10,000 psi, which is 700 bar.

The fueling standard has two pressure classes: H70, 700 bar, for cars; H35, 350 bar, for buses and
trucks, which have room for bigger tanks.

*[show figure]* The tanks are Type IV. A carbon-fiber wrap carries the pressure. Inside it, a
plastic liner keeps the gas in. *[ask]* Why would a plastic liner matter for filling? *[pause]*
Plastic insulates. Compression heat stays in the gas instead of passing into the wall. So a Type IV
tank needs more precooling, more chilling of the gas at the station, a US Department of Energy study
notes. Remember this for filling.

One caution: everyone calls the Mirai's tanks 700 bar Type IV, but the Toyota documents we read do
not say so.
-->

---
routeAlias: storage-alternatives
skipInCut: true
---

## Other ways to store it

<div class="grid grid-cols-2 gap-8">
<div>

**Liquid hydrogen:**

- liquefaction **10–13 kWh/kg** — **30–40 %** of the LHV
- Daimler GenH2 truck: **88 kg** liquid, 2 × 44 kg, **1,047 km** on one fill (2023)
- series production pushed to the "early 2030s" (secondary)

</div>
<div>

**Metal hydrides, chemical carriers:** hydrogen bound in a solid or a liquid compound and released
by heat.

Deck 8 shows them; no current system numbers in our sources.

<div class="caption text-left">[DOE-REC-9013-2009], [DAIMLER-GENH2-2024] verified · 2030s:
newmobility.news, secondary</div>

</div>
</div>

<!--
Compressed gas is not the only option. Liquid hydrogen is denser. Liquefying it costs 10 to 13
kilowatt-hours per kilogram. That is 30 to 40 percent of the energy it carries, spent before the car
moves.

*[ask]* Who would accept that loss? *[pause]* Someone who needs range more than efficiency: a
long-haul truck. Daimler's GenH2 truck carries 88 kilograms of liquid hydrogen in two 44 kilogram
tanks. In 2023 it drove 1,047 kilometers on one fill. But the trade press reports that full
production has slipped to the early 2030s, because liquid-hydrogen infrastructure is slow. A small
series of 100 trucks is to reach customers from the end of 2026, with a 300 kilowatt fuel cell.
Their tanks take extra-cold liquid hydrogen, a process developed with Linde. The trial trucks pair
300 kilowatts of fuel cell with a battery that adds up to 400 kilowatts for short bursts. That is
the same series hybrid as the Mirai, where only the motor drives the wheels, at truck scale.

Liquid is also one way hydrogen reaches a car station: the liquid tanker on the next slides. The
station pumps it and turns it back into gas, and the 30 to 40 percent is already spent.

*[ask]* Compare the two energy bills. Compressing a kilogram to 700 bar costs about 3
kilowatt-hours. Liquefying it costs 10 to 13. *[pause]* Three to four times as much. Liquid hydrogen
buys range with energy. Only a truck that must cross a country on one fill can justify it.

Metal hydrides and chemical carriers hold hydrogen in a solid or a liquid and release it with heat.
Deck 8 shows them. Our sources have no current numbers for these systems, so tonight we only
describe them. They share liquid hydrogen's problem: getting the hydrogen in and out costs energy,
time, or both.

So for cars the answer today is 700 bar gas. That brings back the heat problem: filling it fast.
-->

---
routeAlias: fueling-j2601
---

## Filling at 700 bar: SAE J2601

<div class="grid grid-cols-[1.75fr_1fr] gap-6 items-start">
<div>

![Sketch of a 700 bar fill against time in minutes, two panels. Top, pressure: a straight ramp at a set average rate (APRR) climbing from low pressure past the 700 bar nominal line to just under the dashed red limit of 875 bar at the dispenser, ending at 3 minutes. Bottom, gas temperature: the gas into the car is precooled to −40 to −33 °C (the T40 band, drawn flat along the bottom), while the gas in the tank heats up and levels off just under the dashed red limit of 85 °C. Vertical dotted lines mark 83 s (5 kg at the 60 g/s maximum flow), the 3-minute J2601 target and the 3.22-minute field mean of 1.85 million fills. The curve shapes are illustrative; the labeled limits and times are sourced.](/diagrams/06-fill-700bar.svg)

<div class="caption">Illustrative shapes; limits: T40 −40 to −33 °C, 60 g/s [MATTELAER-J2601-2024], ≤ 85 °C and
≤ 875–880 bar [DOE-REC-9013-2009], [TIAX-PD068-2010], APRR [GONIN-HYSAFE-2026] · 3 min target
[ANL-J2601-FILLTIME] · 3.22 min mean of 1,850,493 fills [NLR-CDP-2023] · 83 s derived.</div>

</div>
<div class="text-[0.9rem]">

<img class="photo" src="/photos/06-h2-nozzles.jpg" style="height: 13rem" alt="Two hydrogen nozzles hanging side by side in a blue dispenser bay, labeled 350 bar and 700 bar."/>

<div class="caption">350 and 700 bar nozzles, Offenbach, 2020 · L. Willms, CC BY-SA 3.0</div>

**Why it heats:** the incoming gas compresses the gas in the tank, and hydrogen *warms* when
throttled (Joule–Thomson inversion ≈ 200 K). So **precool**.

**Real US fills, 2014–2022:** **0.9 kg/min**; only **28 %** under 2.5 min.

<div class="caption text-left">physics: derived (<code>hydrogen.md</code> §1.1) · [NLR-CDP-2023]</div>

</div>
</div>

<!--
Filling a hydrogen tank fast has one problem: heat. *[show photo]* First the nozzles: 350 bar for
buses, 700 bar for cars, at a station in Offenbach. Photograph by L. Willms, Wikimedia Commons.
*[ask]* Who has pumped up a bicycle tire and felt the pump get hot? *[pause]* Same thing. The
incoming gas compresses the gas already in the tank and heats it. Unlike air, hydrogen at room
temperature warms when it flows through a valve, because its Joule-Thomson inversion temperature,
about 200 kelvin, is below room temperature. Both push the tank temperature up.

*[show figure]* The dashed red lines are the limits. The gas in the tank must stay below 85 degrees.
To finish a 700 bar fill, the dispenser must reach 875 to 880 bar. And SAE J2601, the standard for
how a car is fueled, caps the flow at 60 grams per second. The answer is precooling: the station
chills the hydrogen first. The fastest class, T40, delivers it at minus 40 to minus 33 degrees.

The dotted lines show real fill times. J2601 aims at three minutes for a 700 bar car at a T40
station, ending 90 to 100 percent full. A US national lab has data on 1.85 million real fills at
retail stations: 3.22 minutes on average, 0.9 kilograms a minute. Only 28 percent beat the US energy
department's target of 2.5 minutes. The flow cap sets the floor: 5 kilograms at 60 grams a second
takes at least 83 seconds.

Hyundai quotes five minutes for the new Nexo, counted to over 95 percent full. Trucks are on another
scale. A heavy-duty fill tested at the same lab put in about 10 kilograms a minute and took seven
minutes. A new heavy-duty protocol aims at 80 kilograms in 10 minutes.

3.2 minutes. The fastest car in section 04 needed 18. This is the nozzle's one big advantage. The
next slides ask what it costs.
-->

---
routeAlias: station-chain
---

## The station chain

<div class="diagram-wide">

![A hydrogen station from left to right. Supply, outside the station, arrives three ways: tube trailer, liquid tanker with cryopump and vaporizer, or on-site electrolysis or SMR. Inside the station: bulk storage at low pressure; a compressor, about 3.0 kilowatt-hours per kilogram; cascade storage at 300 to 950 bar; a chiller to minus 40 degrees Celsius, 0.15 to 0.2 kilowatt-hours per kilogram; a dispenser, H70 up to 875 bar, or H35. Then the car, outside the station: 5.6 kilograms at 700 bar, tank gas at most 85 degrees Celsius.](/diagrams/06-station-chain.svg)

</div>

<div class="grid grid-cols-3 gap-6 text-[0.85rem] mt-4">
<div>

**Energy per kg:** isothermal 20 → 700 bar **1.36 kWh** (theory); real to 880 bar **≈ 3.0 kWh**
(1.7–6.4 field); precool **0.15–0.2 kWh**. 3.0 kWh/kg ≈ **9 %** of the LHV.

</div>
<div>

**Capital:** California stations of ~1,240–1,500 kg/day, **≈ $1.9 M** median ($2016).

</div>
<div>

**What breaks:** dispenser **48 %** of maintenance events, compressor 22 %, chiller 14 %
(2014–2021).

</div>
</div>

<div class="caption">[DOE-REC-9013-2009], [DOE-REC-21002-2020] verified · maintenance: [NREL-CDP], read
from figure</div>

<!--
*[show figure]* A hydrogen station, from left to right. Hydrogen arrives by tube trailer or liquid
tanker, or is made on site. It sits in bulk storage at low pressure. A compressor pushes it into a
cascade, a row of storage tanks at 300 to 950 bar. Then it flows through a chiller to minus 40 and
the dispenser, up to 875 bar, into the car.

*[ask]* Where does this chain use its energy: compressor or chiller? *[pause]* The compressor. In
theory, compressing a kilogram from 20 to 700 bar takes 1.36 kilowatt-hours. A real station needs
about 3.0 to reach 880 bar, and field data range from 1.7 to 6.4. Precooling adds only 0.15 to 0.2.
A kilogram of hydrogen carries 33.3 kilowatt-hours, so compression alone uses about 9 percent of it.

Cost to build: a California station for about 1,240 to 1,500 kilograms a day costs about 1.9 million
dollars, in 2016 dollars. At 5 kilograms a fill, it serves about 250 cars a day, if they come. The
supply route matters too. A station fed by tube trailer, at 770 kilograms a day, cost 1.4 million.
One fed by liquid tanker cost 1.9 to 4.2 million.

And what breaks? In US maintenance records from 2014 to 2021, the dispenser caused 48 percent of the
maintenance events, the compressor 22, the chiller 14. The part the driver touches works at 875 bar
and minus 40 degrees, and it fails most. Keep that in mind for the next slide.
-->

---
routeAlias: station-counts
---

## Stations: counts and closures

<img src="/figures/06-station-counts.svg" style="max-height: 22rem" alt="Two panels. Left, horizontal bars of hydrogen refueling stations worldwide at the end of 2024, 1,160 in all: China 384, Europe 294 (of which Germany 113, shaded darker), South Korea 198, Japan 161, USA 89. Right, public car stations: Germany over 80 in January 2024, 50 in January 2026; Czechia 2 in April 2026. A note: H2 MOBILITY closed 3 (March 2024), 6 (October 2024), 11 (March 2025) and 11 (Q2 2025) stations; 36 public stations went off the network in Germany in 2025, all operators."/>

<div class="caption">World: LBST / H2stations.org 17th assessment via Motor1 [LBST-H2STATIONS-2025], all stations incl.
depots · Germany: H2 MOBILITY via [ECOMENTO-DE-50-2026], [H2M-CLOSURES-2025], [SOLARSERVER-DE-36-2026];
the 2024 closures (3, 6) search summary · Czechia: ORLEN via [SYSLOG-ORLEN-2026] · all secondary.</div>

<div class="grid grid-cols-[1fr_1fr_auto] gap-6 items-start text-[0.85rem] mt-2">
<div>

**California:** **61** stations, **50** open-retail (Aug 2025); availability **58 % → 74 %**
(Q2 2024 → Q2 2025); FCEV registrations fell for the first time: **14,138**.

</div>
<div>

**Czechia:** ORLEN's construction **paused**, operation loss-making (Apr 2026); Barrandov out of
service for over a month in mid-2025. **Also closed:** Shell in California (2024); Everfuel in
Denmark (2023).

<div class="caption text-left">[CARB-AB126-2025] verified · [FDRIVE-BARRANDOV-2025], [SHELL-CA-2024],
[EVERFUEL-2023] secondary</div>

</div>
<div>

<img class="photo" src="/photos/06-h2-frankfurt.jpg" style="height: 9rem" alt="Three hydrogen dispensers under an Agip canopy near Frankfurt: two for compressed gas at 350 bar and one for liquid hydrogen (Flüssiger Wasserstoff)."/>

<div class="caption">H₂ dispensers, Frankfurt, 2009 · Zgonnik, public domain</div>

</div>
</div>

<!--
How many stations are there, and which way is the number going? Most of these figures are press
reports quoting the operators. California's come from the state's own annual report.

*[show figure]* On the left, the world at the end of 2024: 1,160 stations. 294 in Europe, 384 in
China, 198 in Korea, 161 in Japan. No end-2025 count has been published.

On the right, Germany, the country that built the most in Europe. H2 MOBILITY had 50 public stations
in January 2026, down from over 80 two years earlier. In the first half of 2025 it closed 22 small
700 bar car stations. It said they no longer met technical and economic requirements, and car sales
had stayed weak. It now focuses on trucks and buses. In March 2025, for the first time, more than
half of its fuelings were at 350 bar, the truck and bus pressure.

California: 61 stations, 50 open for retail in August 2025. Availability rose from 58 to 74 percent
in a year, so a quarter of the network's capacity was still out of use. An industry group reports
about 90 percent availability for the same network at the end of 2025. It counts differently, so ask
how each figure was measured before you compare. The state cut its forecast for 2031 to 112
stations, 17 fewer than a year earlier, partly because two suppliers gave back their grants. And the
number of registered fuel-cell cars fell for the first time.

*[ask]* Czechia: how many public hydrogen stations does ORLEN run? *[pause]* Two: Praha-Barrandov
and Litvínov. ORLEN says they lose money at current volumes, and it has paused building more. In
2025 Barrandov was out of service for over a month; the next working station was in Litvínov. Others
have left completely: Shell's California car stations in 2024, Everfuel's Danish network in 2023.
*[show photo]* Bottom right, an early station of the kind now closing: dispensers for 350 bar gas
and for liquid hydrogen near Frankfurt in 2009. Public-domain photograph by the user Zgonnik.

Compare the plug: 7,669 public charging points in Czechia, against two nozzles.
-->

---
routeAlias: who-buys-fcevs
skipInCut: true
---

## Who buys fuel-cell vehicles

<div class="grid grid-cols-[1.4fr_1fr] gap-8 items-start">
<div>

**FCEVs sold in 2025:** **16,011** (+24.4 %)

<img src="/figures/06-fcev-sales.svg" alt="Horizontal bars of fuel-cell vehicles sold in 2025: China 7,797, South Korea 6,802, Europe 566, Japan 430, US 365."/>

<div class="caption">SNE Research via Argus Media, 13 Feb 2026 [ARGUS-SNE-2026], secondary · world 16,011 incl. 51
elsewhere.</div>

**Germany, new registrations 2025:** **49** (−69.0 %). <span class="caption">[KBA-2025] verified</span>

</div>
<div class="text-[0.9rem]">

<img class="photo" src="/photos/07-h2-bus.jpg" style="height: 9rem" alt="A fuel-cell city bus refueling under the canopy of a hydrogen station at dusk, storage tanks behind it."/>

<div class="caption">Fuel-cell bus refueling, Herten, 2026 · Icke68746, CC0</div>

**World FCEV stock, 2025:** almost **130,000** (+20 %), from Chinese trucks and Korean cars.

**Road hydrogen use:** trucks about **60 %**, buses about **30 %**.

**Czechia:** 10 hydrogen buses at Mníšek pod Brdy, **none** in passenger service on 12 Oct 2026.

<div class="caption text-left">[IEA-GHR-2026] verified · [EPOCH-CZ-MNISEK-2026] secondary</div>

</div>
</div>

<!--
Who buys fuel-cell vehicles? One market tracker counts 16,011 sold worldwide in 2025, up 24 percent.
*[show figure]* *[ask]* Where do you think they were sold? *[pause]* China, 7,797, mostly commercial
vehicles. Korea, 6,802, mostly the Nexo. Together, nine in ten. Europe 566, Japan 430, the US 365,
and all three fell. Germany registered 49 new fuel-cell cars in all of 2025, down 69 percent.

The International Energy Agency says the world stock grew 20 percent, to almost 130,000, driven by
trucks in China and Korean cars. Trucks use about 60 percent of the hydrogen on the road, buses
about 30. So road hydrogen is mostly a commercial-vehicle fuel, and it grows where governments push
it.

By maker, the same tracker gives Hyundai about 7,000 sales and Toyota about 1,200. Two reports of it
differ by a few percent, so treat these as rounded. Toyota, the maker of the Mirai, sells about a
sixth as many as Hyundai.

In Europe, the hydrogen vehicles that sell are buses. *[show photo]* Like this one, refueling in
Herten in April 2026. CC0 photograph by the user Icke68746. Solaris delivered 306 hydrogen buses in
2025, 58 percent of the hydrogen bus market by its own count.

At home, the first trial was short. In 2023 a hydrogen bus ran between Litvínov and Most for ten
days, with 10.5 kilograms on board and about 350 kilometers of range. Then, from 2025, ten hydrogen
buses were delivered for the lines around Mníšek pod Brdy. ČEZ is building an electrolyzer, which
makes hydrogen from electricity, and a station for them. On 12 October 2026 none was yet carrying
passengers; the station was not yet running. That is from a press report last month. Ústí nad Labem
put its hydrogen bus project on hold in 2025. The mayor said local hydrogen at 6 to 8 euros a kilogram
did not pay. A Czech hydrogen industry group puts the price that would compete with diesel at about
6 euros.

*[ask]* Put the last two slides together. A buyer will not buy a car without stations. An operator
will not build stations without cars. *[pause]* That is the chicken-and-egg problem. Germany shows
it running backwards: fewer cars, so fewer stations, so fewer cars. Next: what the fuel costs those
who do buy.
-->

---
routeAlias: hydrogen-price
---

<!-- TODO(lecturer): if ORLEN publishes a current hydrogen price before Monday, update the Mirai row
of data/extra_session/cost_per_100km_cz.csv, re-export 06-cost-per-100km.svg, and update the "weakest
number" box under it. -->

## Price per kilogram, and per 100 km

<img src="/figures/06-cost-per-100km.svg" style="max-height: 25rem" alt="Horizontal bars of energy cost in CZK per 100 km in Czechia, with the price used under each label. Leaf at home on the D27d low tariff, 3.514 CZK/kWh: 60. Leaf at home, average price 7.0108 CZK/kWh: 120. Leaf on public DC, 13.00 to 16.90 CZK/kWh: a range bar from 222 to 289. Petrol car, 42.98 CZK/L at 5.22 L/100 km: 224. Mirai, 0.79 kg/100 km: a range bar from 220 at ORLEN's 2023 price of 278 CZK/kg to 394 at its January 2024 price of 499 CZK/kg, the light dashed part being the uncertain span."/>

<div class="caption">Derived: consumption × price [<code>energy-prices-cz.md</code>] · Leaf 17.1 kWh/100 km WLTP at the socket,
Mirai 0.79 kg/100 km [TOYOTA-UK-MIRAI-SPECS-2024], petrol 5.22 L/100 km (Lecture 2) · prices 12 Nov
2026: [EUROSTAT-NRG-PC-204-2026S1], [CEZ-D27D-2026], [PRE-JEDNORAZOVE], [CEZ-FUTUREGO-2026-11],
[CSU-CENPHMT-2026-W45] · H₂: 278 CZK/kg June 2023 [ORLEN-TZ-2023-06-28], 499 CZK/kg January 2024
[AKTUALNE-H2-2024] (secondary, newest found).</div>

<div class="grid grid-cols-2 gap-8 text-[0.9rem] mt-2">
<div>

**The Mirai's price is the weakest number here.** 499 CZK/kg is the last reported ORLEN price
(Aktuálně.cz, Jan 2024, secondary); no 2025–26 price was found.

</div>
<div>

**Elsewhere, per kg:** Germany up to about **€19** (Jan 2026), where the 2023 uniform price was
€12.85; California **$34.55** (Oct 2024).

<div class="caption text-left">[H2LIVE-PRICE] verified, undated; [ECOMENTO-DE-50-2026], [PLATTS-CA-2024]
secondary</div>

</div>
</div>

<!--
*[ask]* Before we read the chart, do not look at its last bar. The petrol car of Lecture 2 costs 224
crowns of fuel per 100 kilometers. Guess the Mirai: cheaper, about the same, or more expensive?
*[pause]*

Energy only, at Czech prices: no fixed fees, no purchase price. *[show figure]* Every bar is
consumption times price. The Leaf takes 17.1 kilowatt-hours per 100 kilometers from the wall. That
is its WLTP test figure, with charging losses. At the average Czech household price that is 120
crowns. On ČEZ's low tariff for electric cars, 60. On a public DC charger, 222 to 289. The petrol
car: 5.22 liters at this week's average price, 224.

The Mirai: 0.79 kilograms per 100 kilometers at 499 crowns a kilogram is 394 crowns, the right end
of the longest bar. Be careful with that price. It is the last one anyone reported, in January 2024,
when ORLEN ended its introductory price of 278 crowns. ORLEN has published nothing since. Even at
the old introductory price, the left end of its bar, the Mirai would only match petrol, at 220
crowns. The dashed part is the range we cannot pin down. It would never get near the Leaf at home.

Abroad, for scale: Germany up to about 19 euros a kilogram in January this year. The single price H2
MOBILITY set there in 2023 was 12.85. California, 34.55 dollars in October 2024. Hydrogen is not
cheap anywhere yet.

*[3 h: take one student's family car and work its cost per 100 kilometers on the board, from its
consumption and this week's price. That is take-home exercise 4 started in the room.]*

So at home the plug costs a third as much or less, and the nozzle is the most expensive way to drive
on this slide.
-->

---
routeAlias: afir-art-6
---

## AFIR Article 6: hydrogen stations by 2030

<div class="grid grid-cols-2 gap-8">
<div>

**By 31 December 2030**, every Member State:

- public stations of at least **1 t/day**, with a **700 bar** dispenser
- at most **200 km** apart along the **TEN-T core network**
- at least **one** in each **urban node**
- each designed for **light- and heavy-duty** vehicles

</div>
<div>

**Derogation:** on core roads with fewer than **2,000** heavy-duty vehicles a day, capacity may be
cut by up to **50 %**.

**Review:** by **31 December 2026**, and every five years — including whether to require more
capacity or liquid hydrogen.

**Czechia's plan (2022):** 80 stations by 2030 (secondary).

<div class="caption text-left">[AFIR-2023-1804] Art. 6 verified · [CT24-VITKOVICE-2022] secondary</div>

</div>
</div>

<!--
The EU's rule for hydrogen stations is Article 6 of AFIR, the EU law on charging and fueling
stations from section 04.

By the end of 2030, every Member State must have public hydrogen stations of at least one tonne a
day, with a 700 bar dispenser. They must be at most 200 kilometers apart along the core
trans-European roads, with one in every urban node, meaning the larger cities on that network. Each
must serve cars and heavy vehicles. Where fewer than 2,000 heavy vehicles a day use a road, a
country may halve the capacity.

*[ask]* A tonne a day: how many Mirai fills is that? *[pause]* At 5.6 kilograms, about 180. Every
station AFIR asks for is sized for trucks, not for the few dozen hydrogen vehicles in Czechia today.

Member States must also show a straight-line path to 2030, with a non-binding target for 2027. The
Commission must review the law by the end of this year, and consider higher capacity and liquid
hydrogen. In 2022 the Czech national plan aimed at 80 hydrogen stations by 2030. Today ORLEN runs
two and has paused building more.

So the nozzle fills in three minutes. But the station is rare, costly and fragile, and the fuel
costs more than petrol. Section 07 asks the last question: how much electricity does it all take?
-->
