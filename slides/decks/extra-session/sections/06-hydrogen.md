---
routeAlias: hydrogen
layout: section
---

###### Section 06

# Hydrogen on board and at the station

Storage at 700 bar, fueling to SAE J2601 with precooling, the station chain, how many stations
there are and how many closed, the price per kilogram and per 100 km, and AFIR Article 6.

<!--
Section 06, hydrogen on board and at the station. First how a car stores it: compressed to 700
bar. Then how a station fills it in three minutes without overheating the tank, and the chain of
machines a station needs to do that. Then the state of the network: counts, closures, who buys the
cars. Then the price, per kilogram and per 100 kilometers against the Leaf and a petrol car, and the
EU's rule for stations.
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
Hydrogen as a fuel, in numbers. Its lower heating value is 33.3 kilowatt-hours per kilogram, the
deck's value; Argonne uses 119.96 megajoules per kilogram, the same thing. Per liter it is tiny:
even compressed to 700 bar at 15 degrees, Air
Liquide's paper gives about 40 kilograms per cubic meter. The Mirai's full tank, 5.6 kilograms,
holds 187 kilowatt-hours by the lower heating value; my multiplication.

Safety. The DOE's summary: hydrogen burns over a wide range of concentrations and needs little
energy to ignite, but it is so much lighter than air that it dissipates rapidly when released. The
flammable range, 4 to 75 percent in air against 1.4 to 7.6 for petrol vapor, we have only from search
summaries, so treat those as reported. The tanks are built with a burst safety factor of 2.25 in the
US and 2.35 in the EU, from a DOE program record.
-->

---
routeAlias: storage-700-bar
---

## On board: 700 bar

<div class="grid grid-cols-2 gap-8">
<div>

**Toyota Mirai gen 2:** three tanks, **5.6 kg**, **142.2 L**, multi-layer construction.

**Hyundai Nexo (2025):** **6.69 kg** usable in 3 × 54.2 L.

**Honda CR-V e:FCEV:** **4.3 kg** at 10,000 psi.

**Pressure classes:** **H70** (70 MPa) for cars, **H35** (35 MPa) for buses and trucks.

</div>
<div>

**Type IV tank:** carbon-fiber wrap on a plastic liner — "a type IV tank will require more
pre-cooling due to heat transfer effects of plastic liner".

**Mirai's 70 MPa, Type IV:** commonly cited, **not verified** from Toyota's own text.

<div class="caption text-left">[TOYOTA-UK-MIRAI-2020], [TOYOTA-UK-MIRAI-SPECS-2024],
[HYUNDAI-NEXO-2025], [MATTELAER-J2601-2024], [TIAX-PD068-2010] verified · [HONDA-CRV-EFCEV-2024]
secondary</div>

</div>
</div>

<!--
How a car stores it. The Mirai carries three tanks, together 5.6 kilograms in 142.2 liters, of
multi-layer construction, from Toyota. The new Hyundai Nexo: 6.69 kilograms usable in three tanks
of 54.2 liters. Honda's CR-V e:FCEV: 4.3 kilograms at 10,000 psi, which is 700 bar; that one is
Honda's text reproduced on an aggregator, so secondary.

There are two pressure classes in the fueling standard: H70, 70 megapascals or 700 bar, for cars;
and H35, 350 bar, for buses and trucks.

The tanks are Type IV: a carbon-fiber wrap carries the pressure, around a plastic liner that keeps
the gas in. The plastic insulates, so the gas heats up more during a fill: the TIAX study for DOE
says a Type IV tank needs more precooling. One flag: that the Mirai's tanks are 700 bar Type IV is
everywhere, but not in the Toyota texts we read; it is commonly cited, not verified.
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

TODO: no specific-energy or system numbers for hydrides or chemical carriers in the notes.

<div class="caption text-left">[DOE-REC-9013-2009], [DAIMLER-GENH2-2024] verified · 2030s:
newmobility.news, secondary</div>

</div>
</div>

<!--
Compressed gas is not the only option. Liquid hydrogen is denser, but liquefying it costs 10 to 13 kilowatt-hours per kilogram, a third or more of the energy it carries;
that is the DOE record again. Daimler's GenH2 truck carries 88 kilograms of liquid hydrogen in two
44 kilogram tanks, and drove 1,047 kilometers on one fill in 2023. Series production has slipped to
the early 2030s, reported by trade press, secondary, with slow liquid-hydrogen infrastructure as the
reason.

Metal hydrides and chemical carriers bind hydrogen in a solid or a liquid and release it with heat.
Deck 8 shows them; our notes have no current numbers for them, so this stays qualitative.
-->

---
routeAlias: fueling-j2601
---

## Filling at 700 bar: SAE J2601

<div class="grid grid-cols-2 gap-8">
<div>

**The problem:** compressing the gas already in the tank heats it, and hydrogen *warms* when
throttled (Joule–Thomson inversion ≈ 200 K, below ambient).

**The limits:**

- tank gas **≤ 85 °C**
- dispenser up to **875–880 bar** to finish a 700 bar fill
- flow **≤ 60 g/s** (H70, light duty)

**The answer: precool** the gas — T40 delivers at **−40 to −33 °C**.

</div>
<div>

**Target:** **3 min**, 70 MPa, T40 station, SOC 90–100 %.

**Real US retail fills**, 1,850,493 events, 2014–2022:

- average **3.22 min**, **0.9 kg/min**
- only **28 %** under 2.5 min

**Floor:** 5 kg at 60 g/s ≥ **83 s**.

<div class="caption text-left">[MATTELAER-J2601-2024], [DOE-REC-9013-2009], [TIAX-PD068-2010],
[ANL-J2601-FILLTIME], [NLR-CDP-2023] verified · physics and 83 s: derived (`hydrogen.md` §1.1)</div>

</div>
</div>

<!--
Filling a hydrogen tank fast has one problem: heat. As gas flows in, it compresses the gas already
in the tank, and that heats it, just as a bicycle pump gets hot. And unlike most gases at room
temperature, hydrogen warms rather than cools when it is throttled through a valve, because its
Joule-Thomson inversion temperature, about 200 kelvin, is below ambient. Both effects push the tank
temperature up.

The limits. The gas in the tank must not exceed 85 degrees, the SAE safety guideline. To push
the tank to 700 bar at the end, the dispenser must reach 875 to 880 bar. And SAE J2601, the fueling
protocol for light vehicles, caps the flow at 60 grams per second.

The answer is to precool the hydrogen before it enters the car. J2601's fastest class, T40,
delivers it at minus 40 to minus 33 degrees.

The right column: how fast in practice. J2601's design target, from Argonne's paper: three minutes
for a 700 bar car at a T40 station, ending at 90 to 100 percent of the tank. NREL's data on 1.85
million real fills at US retail stations from 2014 to 2022: on average 3.22 minutes at 0.9
kilograms per minute, and only 28 percent faster than the DOE's ultimate target of 2.5 minutes. The
floor is set by the flow cap: 5 kilograms at 60 grams per second takes at least 83 seconds.
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
The diagram is a hydrogen station from left to right, after the TIAX layout for DOE. Hydrogen
arrives by tube trailer, by liquid tanker, or is made on site by electrolysis or steam reforming of
natural gas. It sits in bulk storage at low pressure. A compressor lifts it into a cascade of
high-pressure buffer tanks, between 300 and 950 bar in the DOE model. From the buffer it flows
through the chiller, which cools it to minus 40, and the dispenser, which ramps the pressure to up
to 875 bar into the car.

Below, three facts about it. Energy: compressing a kilogram from 20 to 700 bar takes at least 1.36
kilowatt-hours in theory; real stations need about 3.0 to reach 880 bar, and DOE field data range
from 1.7 to 6.4. Precooling adds only 0.15 to 0.2. So compression alone costs about 9 percent of the
hydrogen's energy; that is my division, 3.0 over 33.3.

Capital: in DOE's survey of California grant applications, a station of about 1,240 to 1,500
kilograms per day costs about 1.9 million dollars of 2016.

And what breaks: in NREL's maintenance data from 2014 to 2021, read off a pie chart, the dispenser
causes 48 percent of the maintenance events, the compressor 22, the chiller 14. Keep that in mind on
the next slide.
-->

---
routeAlias: station-counts
---

## Stations: counts and closures

<div class="grid grid-cols-2 gap-8 text-[0.95rem]">
<div>

**World, end 2024:** **1,160** stations; Europe 294, Germany 113 (all stations), China 384, Korea
198, Japan 161.

**Germany, public (H2 MOBILITY):** **50** in Jan 2026, **over 80** two years before; **22** small
700 bar stations closed in H1 2025.

**California:** **61** stations, **50** open-retail (Aug 2025); availability **58 % → 74 %**
(Q2 2024 → Q2 2025); FCEV registrations fell for the first time: **14,138**.

</div>
<div>

**Czechia:** ORLEN runs **2** public stations, Praha-Barrandov and Litvínov; further construction
**paused**, operation loss-making (Apr 2026). Barrandov was out of service for over a month in
mid-2025.

**Also closed:** Shell in California (2024); Everfuel in Denmark (2023).

<div class="caption text-left">[LBST-H2STATIONS-2025], [ECOMENTO-DE-50-2026],
[H2M-CLOSURES-2025], [SYSLOG-ORLEN-2026], [FDRIVE-BARRANDOV-2025], [SHELL-CA-2024], [EVERFUEL-2023]
secondary · [CARB-AB126-2025] verified</div>

</div>
</div>

<!--
How many stations are there, and which way is the number going? Most of these numbers are
secondary: reported by trade press quoting the operators. I say which.

The world count, from the LBST assessment for the end of 2024, reported by Motor1: 1,160 stations,
294 in Europe, 113 of them in Germany, counting bus and depot stations too. China has 384, Korea
198, Japan 161. No end-2025 count has been published yet.

Germany's public network, from H2 MOBILITY via ecomento, secondary: 50 public stations in January
2026, down from over 80 two years earlier. H2 MOBILITY closed 22 small 700 bar stations in the first
half of 2025, saying they no longer met technical and economic requirements and the passenger-car
market had stayed muted; its focus is now commercial vehicles.

California, from the state's own annual report, verified: 61 stations at the end of August 2025, of
which 50 open for retail; the other 11 temporarily non-operational. Network availability rose from
58 percent in the second quarter of 2024 to 74 percent a year later. And registered fuel-cell cars
fell for the first time, to 14,138.

Czechia, secondary: ORLEN Unipetrol runs two public stations, in Prague at Barrandov and in
Litvínov, says operating them loses money at current volumes, and has paused building more. In
2025 the Barrandov station was out of service for more than a month with a technical fault.

Others left entirely: Shell closed its California car stations in 2024; Everfuel restructured its
Danish network in 2023. All secondary.
-->

---
routeAlias: who-buys-fcevs
skipInCut: true
---

## Who buys fuel-cell vehicles

<div class="grid grid-cols-2 gap-8">
<div>

**FCEVs sold in 2025:** **16,011** (+24.4 %)

<div class="tight">

| China | Korea | Europe | Japan | US |
|---:|---:|---:|---:|---:|
| 7,797 | 6,802 | **566** | 430 | 365 |

</div>

**Germany, new registrations 2025:** **49** (−69.0 %).

<div class="caption text-left">[ARGUS-SNE-2026] secondary · [KBA-2025] verified</div>

</div>
<div>

**World FCEV stock, 2025:** almost **130,000** (+20 %), from Chinese trucks and Korean cars.

**Road hydrogen use:** trucks about **60 %**, buses about **30 %**.

**Czechia:** 10 hydrogen buses at Mníšek pod Brdy, **none** in passenger service on 12 Oct 2026.

<div class="caption text-left">[IEA-GHR-2026] verified · [EPOCH-CZ-MNISEK-2026] secondary</div>

</div>
</div>

<!--
Who buys them? Global sales in 2025 from SNE Research, reported by Argus, secondary: 16,011
fuel-cell vehicles, up 24 percent. But read the table: China 7,797, mostly commercial vehicles; Korea
6,802, mostly the Nexo; Europe 566, Japan 430, the US 365. Europe, Japan and the US all fell. In
Germany, the federal motor transport authority counted 49 new fuel-cell cars in all of 2025, down 69
percent.

The IEA's Global Hydrogen Review 2026, verified: the world stock grew 20 percent to almost 130,000,
driven by trucks in China and a rebound of car sales in Korea. Trucks use about 60 percent of the
hydrogen on the road, buses about 30. So hydrogen on the road is mostly a commercial-vehicle fuel.

At home: ten hydrogen buses for the Mníšek pod Brdy lines were delivered from 2025, but on 12
October 2026 none was yet in passenger service; the station was still being commissioned. That is
from Epoch Times CZ, secondary.
-->

---
routeAlias: hydrogen-price
---

## Price per kilogram, and per 100 km

<div class="grid grid-cols-[1.2fr_1fr] gap-6 items-start">
<div>

<div class="tight">

| Car and energy, Czechia, Nov 2026 | Price | CZK / 100 km |
|---|---|---:|
| Leaf, home, average household | 7.01 CZK/kWh | **120** |
| Leaf, home, D27d low tariff | 3.51 CZK/kWh | 60 |
| Leaf, public DC ≤ 149 kW | 13.00–16.90 CZK/kWh | 222–289 |
| Petrol, Lecture 2 engine, 5.22 L | 42.98 CZK/L | **224** |
| Mirai, ORLEN, 0.79 kg | **499 CZK/kg** — TODO-verify | **394** |

</div>

<div class="caption text-left">Derived in `energy-prices-cz.md`: Leaf 17.1 kWh/100 km at the grid;
prices [EUROSTAT-NRG-PC-204-2026S1], [CEZ-D27D-2026], [PRE-JEDNORAZOVE], [CEZ-FUTUREGO-2026-11],
[CSU-CENPHMT-2026-W45] verified; [AKTUALNE-H2-2024] secondary</div>

</div>
<div class="text-[0.9rem]">

**The Mirai's price is the weakest number here.** 499 CZK/kg is a Jan 2024 report (secondary);
ORLEN's own release set **278 CZK/kg** in 2023 → 220 CZK/100 km. No 2025–26 price found.

**Elsewhere, per kg:** Germany about **€13–19**; California **$34.55** (Oct 2024).

<div class="caption text-left">[ORLEN-TZ-2023-06-28] verified · [H2LIVE-PRICE] verified, undated;
[ECOMENTO-DE-50-2026], [PLATTS-CA-2024] secondary</div>

</div>
</div>

<!--
What does 100 kilometers cost in Czechia this month? Energy only: no standing charges, no purchase
price. Every row is consumption times price, computed in the energy-prices note.

The Leaf uses 17.1 kilowatt-hours per 100 kilometers at the wall, its WLTP figure with charging
losses included. At the average Czech household price from Eurostat, 7.01 crowns per
kilowatt-hour, that is 120 crowns per 100 kilometers. On ČEZ's D27d tariff for electric cars, in
low-tariff hours, 60 crowns. On a public DC charger, PRE's or ČEZ's ad hoc price, 222 to 289 crowns.

The petrol car is Lecture 2's engine: 5.22 liters per 100 kilometers on the WLTC, at the Czech
Statistical Office's average price for week 45, 42.98 crowns per liter: 224 crowns.

The Mirai: 0.79 kilograms per 100 kilometers at 499 crowns per kilogram, 394 crowns, the most
expensive line. But that price is the weakest number on the slide, and the box on the right says
why. 499 crowns is ORLEN's price as reported by Aktuálně.cz in January 2024, secondary. ORLEN's own
2023 press release, verified, set 278 crowns per kilogram; at that price the Mirai would cost 220
crowns, the same as petrol. We found nothing newer than January 2024. TODO before Monday: verify
the current ORLEN price, or show both and label them.

Abroad, per kilogram: Germany about 13 to 19 euros, the lower figure from H2 MOBILITY's undated
price page and the upper from January 2026 press, secondary. California: 34.55 dollars in October
2024, from S&P Global Platts, secondary.

So across that range: at home the Leaf is cheapest by far; on public DC it costs about what petrol
does; hydrogen costs about as much as petrol at best and nearly twice as much at the reported price.
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
The EU's rule for hydrogen stations, Article 6 of the alternative fuels infrastructure regulation,
AFIR, the same regulation as the charging targets in section 04.

By the end of 2030 every Member State must have public hydrogen stations of at least one tonne a
day with a 700 bar dispenser, at most 200 kilometers apart along the core trans-European road
network, plus at least one station in every urban node, meaning the larger cities on that network.
Each station must be designed to serve both cars and heavy vehicles.

The right column. Where fewer than 2,000 heavy vehicles a day use a core road, a country may halve
the capacity. And the Commission must review the regulation by the end of this year, 2026, and
consider higher capacity and liquid hydrogen.

For scale against section 06's counts: in 2022 the Czech national plan aimed at 80 hydrogen stations
by 2030, reported by ČT24. Today ORLEN runs two, and has paused building more.
-->
