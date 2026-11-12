# EV charging: reference material for 16ESPD extra session

Compiled 2026-11-12. Every number carries its source tag, the date of the number, and a verification label:

- `verified`: I opened the primary page or PDF and the quote is taken from it.
- `read from figure`: read off a plot, with ± uncertainty.
- `secondary`: seen only in news, an aggregator, or a vendor summary.
- `search summary`: seen only in a search-engine snippet. Treat it as a lead, not a citation.
- `computed`: arithmetic from the stated inputs, done here.

This note does not repeat the following, which the course note already has: the IEA GEVO 2026 charger counts, the AFIR Art. 3 power targets, and the ANL 2013 Leaf on-board charger efficiency.

---

## Headline numbers (for slides)

| Number | What | Source | Label |
|---|---|---|---|
| 4.20 V, 65 mA cut-off (≈ C/50), 0.5C max | CC-CV charge spec of an 18650 high-energy cell (3.25 Ah) | [PAN-NCR18650B] | verified (mirror copy) |
| "below 10 °C, charge at a 0.25C rate" | Datasheet derating of charge current in the cold | [PAN-NCR18650B] | verified (mirror copy) |
| 3.6 V CV, terminate < 50 mA; charge current < 250 mA below 0 °C | LFP cell (A123/Lithium Werks 26650, 2.5 Ah) | [LW-26650-2022] | verified |
| Anode below 0 V vs Li/Li⁺ → plating; typical at ">1C" or ~0 °C | Mechanism of lithium plating | [DAS-2024] | verified |
| 46 kW peak, 43 min 10–80 %, 40 kW average | Nissan Leaf 40 kWh (ZE1) on CHAdeMO, Fastned data | [EVDB-LEAF40] | secondary |
| 32 °C | Pack temperature above which the 40 kWh Leaf throttled DC charging ("rapidgate") | [CT-RAPIDGATE-2019] | secondary |
| +6.5 °C vs +2.9 °C | Average pack temperature rise per charge, 50 kW DC vs AC L2, air-cooled 2012 Leaf | [INL-DCFC-2015] | verified |
| 18 min 10–80 %, 196 kW average, 263 kW peak | Hyundai Ioniq 5 84 kWh, 800 V (697 V nominal) | [HYU-EU-CT], [EVDB-IONIQ5] | verified / secondary |
| 18 min 10–80 % (37 min before), 320 kW peak | Porsche Taycan 2024 update, 800 V | [POR-TAYCAN-2024] | verified |
| 27 min 10–80 %, 124 kW average, 250 kW peak | Tesla Model Y LR RWD 2025, 400 V (357 V nominal) | [EVDB-MY-2025] | secondary |
| 28 min 10–80 %, 120 kW average, 175 kW peak | VW ID.3 Pro S 77 kWh MY24-25, 400 V (352 V nominal) | [EVDB-ID3-2024] | secondary |
| 5.1–7.0 % | AC losses at an 11 kW wallbox, 5 current EVs | [ADAC-LADEVERLUST-2026] | verified |
| 12.7–24.2 % | AC losses at a 2.3 kW household socket (Mode 2) | [ADAC-LADEVERLUST-2026] | verified |
| 5–15 % total; 1–10 % in-vehicle | DC fast-charging losses; worst for a cold battery without preconditioning | [ADAC-LADEVERLUST-2026] | verified |
| 2.3 %/yr average; up to 3.0 %/yr for heavy > 100 kW DC users vs ~1.5 %/yr for AC | Fleet battery degradation, 22,700 EVs | [GEOTAB-2026] | verified |
| ≈ 24 % vs ≈ 27 % capacity lost at 50,000 mi | INL four-Leaf study, L2 vs 50 kW DC, Phoenix | [INL-DCFC-2015] | read from figure (±2 %) |
| 7,574 points (+19 %), 12.8 % ≥ 150 kW | Czech public charging points, end 2025 | [CDV-FDRIVE-2026], [CT24-2026] | secondary |
| > 1.06 million | EU public charging points, end 2025 | [CDV-FDRIVE-2026] | secondary |
| 500 A permanent / 700 A boost at 1000 V | Liquid-cooled CCS2 HPC cable rating | [PHX-HPC] | search summary |
| 400 kW vs 200 kW | Power at a 500 A cable limit, 800 V vs 400 V | computed | computed |
| 3.68 / 7.36 / 11.04 / 22.08 kW | 1×16 A, 1×32 A, 3×16 A, 3×32 A at 230 V | computed | computed |
| 3.75 MW (3,000 A × 1,250 V) | Megawatt Charging System (MCS) ceiling | [SAE-J3271] + [WIKI-MCS] | verified (doc) / secondary (ratings) |
| 4,090 swap stations (17 Sep 2026) | NIO battery-swap network in China | [GASGOO-NIO-2026] | secondary |

---

## 1. Cell-level charging: CC-CV, why there is a CV phase, lithium plating

### Sources

**[PAN-NCR18650B]** Panasonic, *NCR18650B Lithium Ion datasheet*, undated (the cell family dates from about 2012). The copy I read is hosted on TI E2E: https://e2e.ti.com/cfs-file/__key/communityserver-discussions-components-files/196/Panasonic-NCR18650B-datasheet.pdf. Label: `verified`, but from a third-party mirror, not a Panasonic-hosted file. The datasheet does not name the cathode chemistry. The NCR line is commonly reported as NCA, a layered oxide like NMC with the same 4.2 V CV level, but I have not verified that.

- "Charging: CC-CV, Std. 1625mA, 4.20V, 4.0 hrs"
- "Charge: CC-CV 0.5C (max) 4.20V, 65mA cut-off at 25°C"
- "Temperature: Charge*: 0 to +45°C … * At temperatures below 10°C, charge at a 0.25C rate."
- Rated capacity: "Min. 3200mAh", typical "Min. 3250mAh".
- `computed`: the 65 mA cut-off is 65/3250 ≈ C/50. Two more datasheets would be needed before claiming that C/20 to C/50 is the typical range (see Gaps).

**[LW-26650-2022]** Lithium Werks (formerly A123), *26650 Lithium Ion Power Cell, Specs for ANR26650M1B*, datasheet dated 08/2022 (from the file name "080322"). https://lithiumwerks.com/wp-content/uploads/2022/08/26650-Power-Cell-080322.pdf. Label: `verified`.

- LFP chemistry: "Based on lithium iron phosphate chemistry (LiFePO4)". Nominal 3.3 V, 2.5 Ah minimum.
- "Recommended Charge Current 3 A (1.2C rate)"; "Max Continuous Charge Current 10 A (4C rate)"; "Max Pulse Charge Current (10s) 26 A (8C rate)"
- "Recommended Fast Charge Voltage 3.6 V"; "Terminate Charge @ 3.6 V < 50 mA" (`computed`: ≈ C/50); "Float Charge Voltage 3.5 V"
- "Temperature Range (Charging) 0 ºC to 60 ºC", with "current at <250mA when under 0ºC" (`computed`: 250 mA ≈ C/10).
- The 3.65 V LFP figure you asked about appears only on non-A123 sheets (`search summary`). This primary sheet says 3.6 V.

**[DAS-2024]** S. Das, P. Shrotriya, "Electrochemical Mechanism Underlying Lithium Plating in Batteries: Non-Invasive Detection and Mitigation", *Energies* 17 (2024) 5930, https://doi.org/10.3390/en17235930. Open access, read via NSF PAR: https://par.nsf.gov/servlets/purl/10615623. Label: `verified`.

- Mechanism: "the local anode surface overpotential drops and becomes negative vs. Li+/Li … This phenomenon is typically observed during low-temperature or fast charging (>1C) conditions, which cause lithium deposition to be thermodynamically more favorable than intercalation"
- "During regular operation, intercalation is more thermodynamically favorable, with an anodic potential of 65–200 mV vs. Li/Li+."
- "This intense polarization causes the local anode potential to drop below 0 V, which might be considered a thermodynamic need for lithium plating."
- "at low temperatures (~0 °C), a reduction in the solid-state diffusion and slower kinetics causes lithium-ion accumulation at its edge plane, resulting in lithium plating"
- Table of causes: "High CC-CV Charging Rates: Fast charging generates large lithium-ion flux toward the anode, but the anode solid intercalation remains slower"; "Low temperature reduces electrode diffusivity"; "Overcharging the cell around 4.5 V forces more lithium into the anode".
- Abstract: extreme plating "can develop lithium dendrites, which may pass through the separator and lead to an internal short circuit and the subsequent thermal runaway".

**[TOMASZEWSKA-2019]** A. Tomaszewska et al., "Lithium-ion battery fast charging: A review", *eTransportation* 1 (2019) 100011, https://doi.org/10.1016/j.etran.2019.100011. Open access (CC BY), with a repository copy at https://spiral.imperial.ac.uk/handle/10044/1/72827. Label: `search summary`. ScienceDirect returned 403 and the repository PDF would not download, so I have not read the text. This is the standard review to cite for fast charging and low-temperature plating once someone opens it.

### Why the CV phase exists (worked example on the course car, `computed`)

The cell limit applies to the cell's terminal voltage, and terminal voltage = OCV + I·R. At the end of the CC phase the IR term pushes the terminal voltage to the limit while the OCV is still below it, and the cell is not yet full. Holding the voltage at the limit lets the current decay, so the OCV keeps rising toward the limit without the terminal voltage ever exceeding it. The anode potential follows the same logic: a high current at high SoC drives the graphite potential toward 0 V vs Li/Li⁺, which is where plating starts [DAS-2024].

Leaf ZE1 pack (course parameters): 96s2p, R_pack ≈ 0.1 Ω, 4.2 V × 96 = 403 V ceiling.

- At 50 kW and ≈ 350 V: I ≈ 143 A, so I·R ≈ 14 V for the pack, ≈ 0.15 V per series cell.
- CC therefore has to stop when OCV ≈ 403 − 14 = 389 V (≈ 4.05 V per cell). The remaining charge goes in under CV as the current decays.
- At C/20 (33 Ah × 2 / 20 = 3.3 A) the IR term is 0.33 V for the pack, so the cell is effectively at OCV.
- The 4.2 V ceiling assumes the AESC LMO cell has the same upper limit as other layered or spinel cells. I did not find an AESC datasheet (see Gaps).

---

## 2. Measured DC fast-charge curves

### (a) Nissan Leaf 40 kWh (ZE1): CHAdeMO, passive air-cooled pack, "rapidgate"

**[EVDB-LEAF40]** EV Database, *Nissan LEAF 40 kWh (MY18-22)*, accessed 2026-11-12, https://ev-database.org/car/1106/Nissan-LEAF-40-kWh. Label: `secondary` (aggregator; the curve is credited "Data made available by Fastned").

- DC: 46 kW CHAdeMO, "Limited by charging capabilities of vehicle"
- 10–80 %: 43 min, with an average of 40 kW over that window
- Usable 39.0 kWh (40.0 kWh nominal); "350 V" nominal (400 V class)
- AC: 3.6 kW standard and 6.6 kW optional ("Optional in some countries, standard in others")
- Manufacturer claim on the same page: 50 kW max, 20–80 % in 60 min
- The charge curve is shown only as an image. Read it there for the slide.

**[CT-RAPIDGATE-2019]** CleanTechnica, "Nissan LEAF #Rapidgate Mostly Solved By Software Update?", 2019-01-05, https://cleantechnica.com/2019/01/05/nissan-leaf-rapidgate-mostly-solved-by-software-update/. Label: `secondary` (it reports Bjørn Nyland's test).

- "The throttling occurred whenever the battery was above 32° Celsius."
- Plugged in at a 41 °C pack: old software "would have required 54 minutes to recover 70% SOC from near empty", new software "just under 40 minutes".
- At 45 °C: "from 72 minutes (old software) to 48 minutes (new software)".
- "peak charging power at moderately hot battery temperatures has been boosted by 40 to 50% or more."
- Test conditions: "Norwegian winter in ambient temperatures of 0° to -10° Celsius."
- Not verified: the often-quoted "~22–25 kW on the 2nd/3rd charge" figure is forum-reported only (`search summary`).

**[INL-DCFC-2015]** M. Shirk, J. Wishart (INL), "Effects of Electric Vehicle Fast Charging on Battery Life and Vehicle Performance", SAE 2015 World Congress, INL/CON-14-33490, 2015-04, https://www.osti.gov/biblio/1236824 (PDF: https://www.osti.gov/servlets/purl/1236824). Label: `verified` (pages 6–8 read). The study used the 2012 Leaf (24 kWh), which has the same passive, air-cooled pack concept as the ZE1.

- "The average DCFC pack temperature rise during charging was 6.5°C, while the ACL2 pack average was 2.9°C"
- "the lack of active cooling account[s] for greater temperature increase for the DCFC pack"
- "Nissan service literature … battery temperatures above 55°C will cause a charge event to pause until temperature falls"
- Used for the plain explanation of why rapidgate happens: with no active cooling, heat from each charge adds to the last one.

**New Leaf (3rd generation) moved to CCS2 in Europe. Confirmed.**
**[NISSAN-LEAF3-2025]** Nissan Global Newsroom, "All-new 3rd generation Nissan LEAF", June 2025 (date from press coverage, e.g. electrive 2025-06-17), https://global.nissannews.com/en/releases/all-new-3rd-generation-nissan-leaf_tab. Label: `verified` (the date is secondary).

- "Japan will retain CHAdeMO and Europe will offer a CCS port." The North American car uses NACS.
- "supports up to 150 kW DC fast-charging capability"; "owners can replenish 10-80% of their state of charge in as little as 35 minutes" (150 kW charger, 25 °C)
- "two liquid-cooled lithium-ion battery options, both of which offer thermal conditioning functionality". This is the direct fix for rapidgate.
- "Specifically for Europe, the all-new LEAF is Vehicle-to-Grid (V2G) compatible."
- The 52 kWh variant is limited to 105 kW DC and both packs take 11 kW AC (`secondary`: heise, ev-database).

### (b) 800 V cars

**[HYU-EU-CT]** Hyundai Europe, "Charging times" (IONIQ 5), accessed 2026-11-12, https://www.hyundai.com/eu/about-hyundai/electrification/everyday-e-mobility/charging-times.html. Label: `verified`.

- 63 kWh: "takes around 18 minutes to charge from 10 to 80% at a 350 kW fast-charging station (DC)"; 58 min at 50 kW.
- 84 kWh: "under 18 minutes … at a 350 kW fast-charging station (DC)"; 76 min at 50 kW.
- For the slide: the same car takes 76 min on a 50 kW CHAdeMO-class charger, so on a slow charger the car's 800 V architecture gives no advantage.

**[EVDB-IONIQ5]** EV Database, *Hyundai IONIQ 5 84 kWh RWD (MY24)*, accessed 2026-11-12, https://ev-database.org/car/2236/Hyundai-IONIQ-5-84-kWh-RWD. Label: `secondary` (curve "Data made available by Fastned").

- 263 kW peak, 10–80 % in 18 min at 196 kW average, 697 V nominal / 800 V architecture, 80.0 kWh usable, 11 kW AC.

**[POR-TAYCAN-2024]** Porsche Newsroom, "The new Porsche Taycan: improved in almost every discipline", 2024-02-07, https://newsroom.porsche.com/en/2024/products/porsche-the-new-taycan-35190.html. Label: `verified`.

- "at 800-volt DC charging stations … it can be charged at up to 320 kW"; above 300 kW "for up to five minutes"
- "In the first-generation Taycan, the charging time from 10 to 80 per cent SOC at 15 degrees Celsius is 37 minutes … the updated Taycan takes just 18 minutes despite its larger battery capacity."
- "Performance Battery Plus now has a gross capacity of 105 kWh, increased from 93 kWh."

### (c) 400 V cars

**[EVDB-MY-2025]** EV Database, *Tesla Model Y Long Range RWD (Juniper) (2025)*, accessed 2026-11-12, https://ev-database.org/car/3120/Tesla-Model-Y-Long-Range-RWD. Label: `secondary`.

- 250 kW peak, 10–80 % in 27 min at 124 kW average, 357 V nominal / 400 V, 75.0 kWh usable, 11 kW AC.
- `search summary`: the 4680-cell variant (ev-database car 3417) is listed at 36 min and 90 kW average.

**[EVDB-ID3-2024]** EV Database, *Volkswagen ID.3 Pro S (MY24-25)*, accessed 2026-11-12, https://ev-database.org/car/2210/Volkswagen-ID3-Pro-S. Label: `secondary`.

- 175 kW peak, 10–80 % in 28 min at 120 kW average, 352 V nominal / 400 V, 77.0 kWh usable, 11 kW AC.

**[FASTNED-TESLA]** Fastned, Tesla brand page, accessed 2026-11-12, https://www.fastnedcharging.com/en/brands-overview/tesla. Label: `verified`.

- Model 3 max charge speed on Fastned: LR 190 kW, SR 170 kW.
- "The charge curve shows the charging behaviour of this car when the battery is in optimal conditions (around. 30 °C)."
- Curves are images only, so no numeric SoC table was available.

**Slide reading.** The peak kW figure is not what decides charge time; the shape of the curve is. Compare the Model Y at 250 kW peak and 124 kW average with the Ioniq 5 at 263 kW peak and 196 kW average.

---

## 3. Charging modes, connectors, on-board chargers

**[IEC-61851-1-2017]** IEC 61851-1:2017 ed. 3.0, *Electric vehicle conductive charging system – Part 1: General requirements*, 2017-02-07, https://webstore.iec.ch/en/publication/33644. Label: `verified` (abstract only).

- Applies to supply equipment "up to 1 000 V AC or up to 1 500 V DC". In-cable control and protection devices for mode 2 are covered by IEC 62752.
- The abstract does not give per-mode current limits.

**Modes.** Label: `search summary`. These are the commonly cited values; I did not have the normative text.

| Mode | What | Typical limits (commonly cited) |
|---|---|---|
| 1 | AC, household or industrial socket, no communication | ≤ 16 A; prohibited or restricted in many countries |
| 2 | AC, socket plus IC-CPD in the cable (IEC 62752) | ≤ 32 A, ≤ 250 V 1-ph / 480 V 3-ph; in practice ~8–13 A on a household socket |
| 3 | AC, dedicated EVSE, control pilot (PWM) communication | Up to 63 A 3-ph cited; 32 A per phase (22 kW) is the common European ceiling |
| 4 | DC, off-board charger, bypasses the OBC | IEC 61851-23; CCS, CHAdeMO, GB/T, NACS DC, MCS |

**On-board charger ratings in Europe (230 V phase voltage).** Label: `computed`.

| Supply | Power |
|---|---|
| 1 × 16 A | 3.68 kW ("3.7 kW") |
| 1 × 32 A | 7.36 kW ("7.4 kW") |
| 3 × 16 A | 11.04 kW ("11 kW") |
| 3 × 32 A | 22.08 kW ("22 kW") |

All four current EVs in [EVDB-*] above have 11 kW (3-phase, 16 A) OBCs. The old Leaf 40 kWh has a single-phase 3.6 kW or 6.6 kW unit, so on a three-phase 22 kW public post it still charges at 3.6 or 6.6 kW [EVDB-LEAF40]. The Taycan and Volvo EX30 offer 22 kW AC [ADAC-LADEVERLUST-2026].

**Connectors**

- **CCS2 / IEC 62196-3 and Type 2 / IEC 62196-2.** This is the EU standard connector, mandated through AFIR. EAFO's definitions note that "the total number of CCS 'Combo 2' connectors equals the total amount of DC recharging points" (`search summary`, EAFO FAQ).
- **CHAdeMO / ChaoJi.** **[CHADEMO-HP]** CHAdeMO Association, "High Power (ChaoJi)", accessed 2026-11-12, https://www.chademo.com/technology/high-power. Label: `verified`.
  - 2017 protocol: "100 kW continuous and 150-200 kW peak, at 400 A × 500 V".
  - ChaoJi / CHAdeMO 3.0: "up to 600 A", "1 kV to 1.5 kV", "500 to 900 kW". Full spec released in 2021; CHAdeMO 3.1/ChaoJi-2 in 2023; co-developed with the China Electricity Council; backward compatible with GB/T and CHAdeMO through adapters.
  - **Decline in Europe.** The new Leaf takes CCS in Europe [NISSAN-LEAF3-2025], so no new European-market car I checked keeps CHAdeMO. AFIR does not require CHAdeMO on new public chargers (not re-verified here).
- **GB/T (China).** GB/T 20234.3-2023 DC coupler, issued 2023-09-07: rated ≤ 1,500 V DC and ≤ 800 A. GB/T 20234.4-2023 covers the high-power coupler and took effect 2024-04-01. Label: `search summary` (codeofchina / chinesestandard.net).
- **NACS / SAE J3400.** **[SAE-J3400]** SAE, *J3400_202409 North American Charging System (NACS) for Electric Vehicles – Recommended Practice*, first issued 2023-12-18, revised 2024-09-30, https://saemobilus.sae.org/standards/j3400_202409-north-american-charging-system-nacs-electric-vehicles. Label: `verified`.
  - "hand-mated" coupler carrying DC or single-phase AC through the same two current-carrying contacts.
  - The page states no V/A rating. Vendors cite 500 V and 1,000 V DC variants (`search summary`).
  - J3400/1 (adapters) issued April 2025 (`search summary`).
- **MCS (trucks).** **[SAE-J3271]** SAE, *J3271_202503 SAE Megawatt Charging System for Electric Vehicles*, Technical Information Report, 2025-03-05, https://saemobilus.sae.org/standards/j3271_202503-sae-megawatt-charging-system-electric-vehicles. Label: `verified`.
  - Five sub-parts: J3271/1 coupler, /2 communication, /3 cables/cooling/automated connection, /4 use cases incl. bidirectional, /5 interoperability testing.
  - Ratings: "3.75 megawatts (3,000 amps at 1,250 volts direct current)" (**[WIKI-MCS]**, `secondary`).
  - First certified products run at about 1.0–1.2 MW, and a Mercedes eActros 600 was charged at 1,000 kW / 1,250 A at ABB (`search summary`).
  - IEC counterpart IEC TS 63379, reported published February 2026 (`search summary`).

---

## 4. Efficiency and losses: AC vs DC, temperature

**[ADAC-LADEVERLUST-2026]** ADAC (W. Rudschies), "Elektroauto Ladeverluste: AC oder DC – was ist effizienter?", 2026-08-06, https://www.adac.de/rund-ums-fahrzeug/elektromobilitaet/laden/ladeverluste-elektroauto-studie/. Label: `verified`. The test dates are not stated on the page.

**AC losses (Part I)**, measured from the grid into the battery:

| Model | 2.3 kW socket | 4.1 kW (PV) | 11 kW wallbox | 22 kW |
|---|---|---|---|---|
| Mercedes CLA 350 EQ | 24.2 % | 12.8 % | 6.9 % | n/a |
| Renault R5 E-Tech | 13.7 % | 8.0 % | 5.1 % | n/a |
| Tesla Model Y | 12.7 % | 9.4 % | 6.1 % | n/a |
| Volvo EX30 | 14.2 % | 9.1 % | 7.0 % | 6.7 % |
| VW ID.7 | 15.3 % | 10.6 % | 6.9 % | n/a |

- "Beim Laden an der Wallbox mit 11 bzw. 22 kW wurden bei allen Fahrzeugen die niedrigsten Ladeverluste ermittelt." (The lowest losses for every car were at the 11 or 22 kW wallbox.)
- Why low power is worse: the car's fixed loads (control units, pumps, BMS) run for hours regardless of power, so their share of the energy grows as charging power falls. This is the explanation implied by the data, not a quote.

**DC losses (Part II)**, losses inside the vehicle:

| Model | 23 °C, preconditioned | 0 °C, preconditioned | 0 °C, not preconditioned |
|---|---|---|---|
| Hyundai Ioniq 6 (800 V) | 1 % | 1 % | 6 % |
| Renault Mégane E-Tech | 4 % | 6 % | 8 % |
| Tesla Model Y | 3 % | 4 % | 10 % |
| VW ID.3 | 3 % | 5 % | 7 % |

- "Alles zusammen genommen betragen die Energieverluste beim DC-Laden zwischen 5 und 15 Prozent." (Taken together, DC charging losses are 5 to 15 percent.) The DC charger's own conversion loss averaged 3 %.
- "Das Heizen der Batterien an der Ladesäule hatte zusätzliche Energieverluste von 2 bis 8 Prozent zur Folge." (Heating the battery at the charger cost an extra 2 to 8 percent.)
- Preconditioning while driving saves time, not energy.

**Link to the course.** The ANL 2013 Leaf OBC figure of 86–87 % (already in the note) fits the high end of these AC numbers. The 2026 cars at 11 kW show 93–95 % grid-to-battery efficiency.

---

## 5. Communication, Plug & Charge, bidirectional charging

**[ISO-15118-20]** ISO 15118-20:2022 ed. 1.0, *Road vehicles – Vehicle to grid communication interface – Part 20: 2nd generation network layer and application layer requirements*, 2022-04-26, 561 pp, https://webstore.iec.ch/publication/26347. Label: `verified` (abstract).

- "This document defines the communication messages and sequence requirements for bidirectional power transfer."
- Covers conductive and wireless charging, automatic connection devices, and IP-based communication between the EVCC and the SECC.
- EN ISO 15118-20 was approved by CEN on 2022-04-12 (`search summary`).

**Physical layer.** ISO 15118-3:2015 Annex A (normative) puts HomePlug Green PHY powerline communication on the control pilot line, in the 2–30 MHz band at up to 10 Mbit/s. Pairing of car and charger uses SLAC. DIN SPEC 70121 (2014) is the earlier DC-only CCS protocol on the same PLC layer and is what most CCS chargers in service still speak. Label: `search summary` (DIN TOC, TI app note, vendor datasheets).

**Regulation.** Commission Delegated Regulation (EU) 2025/656 (OJ 2025-06-18) amends AFIR Annex II. Label: `search summary` (Bender, Pionix, German Nationale Leitstelle datasheet 2026-03-30). I could not load the EUR-Lex text.

- Public points offering automatic authentication must support EN ISO 15118-2 and -20.
- From 2027-01-01, ISO 15118-20 Plug & Charge is the only allowed automatic authentication method.
- Sources disagree on whether all new Mode 3 points must support -20 from 2027 or only those offering automated authentication. Check Annex II.

**V2G deployment, Renault 5 / Mobilize, France**

- **[TMH-2024]** The Mobility House, "Charge for free: Renault Group, Mobilize and The Mobility House launch vehicle-to-grid in France…", 2024-10-22, https://www.mobilityhouse.com/int_en/our-company/newsroom/article/charge-for-free-renault-group-mobilize-and-the-mobility-house-launch-vehicle-to-grid-in-france-while-germany-is-establishing-the-regulatory-framework. Label: `verified`.
  - "Renault 5 owners can now charge and drive for free". Also covers the Alpine A290.
  - Uses the bidirectional AC PowerBox Verso and the Mobilize Power energy contract.
  - France is the first market, Great Britain is next (2025), and Germany is waiting on its regulatory framework.
- **[RENAULT-V2G-2023]** Renault Group media, "Mobilize V2G: where the future electric Renault 5 becomes a source of energy", 2023-06-13, https://media.renault.com/?p=182506. Label: `verified`.
  - "a bidirectional on-board charger incorporating V2G technology". This is AC V2G: the inverter is the car's OBC, not the wallbox.
  - Powerbox "between 7 kW and 22 kW".
  - "On average, the cost of charging is cut by half."
  - No communication standard is named.
- The link to ISO 15118-20 is reported only by press (`search summary`).
- Savings "up to 600 euros" in year one, against the EDF regulated tariff as of 2025-10-01 (`search summary`, mobilize.com).
- No customer counts were found.

---

## 6. 400 V vs 800 V: why 800 V charges faster

The argument, `computed`:

- Charging power is P = U·I. The current is capped by the connector contacts and the cable's I²R heating, not by the charger's power electronics.
- At a 500 A cable limit: 400 V × 500 A = 200 kW, and 800 V × 500 A = 400 kW.
- For the same power, doubling the voltage halves the current, which cuts I²R loss in the cable and contacts to a quarter. The pack's own I²R loss falls as well.
- Measured outcome:
  - 800 V cars sustain a 196 kW average [EVDB-IONIQ5].
  - 400 V cars with similar or higher peaks average about 120 kW [EVDB-MY-2025], [EVDB-ID3-2024].
  - In-vehicle DC loss is 1 % (Ioniq 6) vs 3 % (Model Y, ID.3) at 23 °C [ADAC-LADEVERLUST-2026].
- Course car for scale: 350 V × 143 A ≈ 50 kW. CHAdeMO's own 2017 high-power spec stopped at 400 A × 500 V [CHADEMO-HP].

**Cable and connector limits.** **[PHX-HPC]** Phoenix Contact CHARX connect CCS2 HPC cables, accessed 2026-11-12, https://www.phoenixcontact.com/en-fr/products/dc-charging-cable-ev-t2hpcc-dc500a-30m50ecbk11s-1369277. Label: `search summary` (the product page returned 403).

- Liquid-cooled: "500 A permanent", "up to 700 A in Boost mode", 1000 V DC, IEC 62196-3-1, cooled with a 50/50 water-glycol mix.
- Uncooled class: "500 A in Boost Mode / 375 A permanently / 1,000 V".
- Without cooling the practical limit is 200–250 A (`search summary`, Volex NACS adapter: "250A without liquid cooling").

**800 V car on a 400 V charger.** **[HMG-EGMP-2022]** Hyundai Motor Group, E-GMP story, 2022-01-17, https://www.hyundaimotorgroup.com/en/story/CONT0000000000005041. Label: `verified`.

- "it uses the motor and the inverter to convert the voltage from 400V to 800V before battery storage."
- "For 800V ultra-fast charging, the thermal management technology of the battery system is important"
- Porsche uses a dedicated on-board DC/DC booster for the same job (not verified here).

---

## 7. Battery degradation from fast charging

**[GEOTAB-2026]** Geotab press release, "New Geotab data shows EV battery health remains strong as fast charging use increases", 2026-01-13, https://www.geotab.com/press-release/ev-battery-health-degradation-fast-charging-study/. Label: `verified`.

- "real-world battery health data from more than 22,700 electric vehicles across 21 makes and models"
- "an average annual battery degradation rate of 2.3%"
- "Vehicles relying on high-power DC fast charging above 100 kW experience degradation rates of up to 3.0% per year … compared with around 1.5% for vehicles that primarily used AC or lower-power charging."
- "Vehicles operating in hotter regions degraded around 0.4% faster per year than those in mild climates."
- "Degradation accelerates only when vehicles spend more than 80% of their time at very high or very low states of charge."
- **[ELECTRIVE-GEOTAB-2026]** electrive, 2026-01-14, https://www.electrive.com/2026/01/14/geotab-analysis-impact-of-fast-charging-on-battery-capacity-loss. Label: `secondary`.
  - 2.3 % now vs 1.8 % in Geotab's earlier study (electrive says "2023"; another summary says 2024).
  - Over 8 years, AC-dominant users lose about 12 % and frequent DC users "up to 22 per cent", so SoH stays "around 78 per cent".
- The "< 12 % vs > 12 % of sessions on DC, 1.5 vs 2.5 %/yr" split is `search summary` only. Neither page I opened contains it.

**[INL-DCFC-2015]** (full citation in §2a). Controlled four-car experiment: two 2012 Leafs charged only at 50 kW DC and two only at L2 (3.3 kW), in Phoenix, AZ, charged twice daily.

- `read from figure` (Fig. 14, ±0.02): capacity remaining at 50,000 mi was ≈ 0.73 (DCFC) vs ≈ 0.76 (ACL2) of baseline. The often-quoted 27.6 % vs 24.6 % loss from INL's 2014 slides is consistent with this (`search summary`).
- `verified`, Table 2, 45 mph range: ACL2 cars 105.9 → 80.9 mi and 102.6 → 82.4 mi; DCFC cars 104.3 → 68.9 mi and 100.0 → 71.4 mi.
- `verified` conclusion: "while the DC fast charged vehicles did lose more capacity than the control vehicles, that difference is small relative to the total capacity loss". The DCFC cars "were charged twice daily at a high rate, twice as often as recommended by the manufacturer … in a city with a very hot climate."
- `verified`, temperature: "For the DC fast charged packs, 95% of time was spent under 46°C". This links heat, missing active cooling and degradation.

---

## 8. Czech Republic and EU numbers

**Czechia**

| Date | Value | Source | Label |
|---|---|---|---|
| End 2025 | **7,574 public charging points**, +19 % (+1,215) y/y | [CDV-FDRIVE-2026] fDrive.cz, "Kilowatty místo kusů…", 2026-01-27, https://fdrive.cz/clanky/kilowatty-misto-kusu-jak-cesko-dohani-evropu-v-dobijeni-16020, citing Centrum dopravního výzkumu (CDV) | secondary |
| End 2025 | ≥ 150 kW: 12.8 % ("Téměř tisíc", almost a thousand); 50–150 kW: 18.3 % | same | secondary |
| End 2025 | "stejnosměrných DC stanic, kterých je nyní 2 510" (2,510 DC stations/points, +33 %). It is unclear whether these are stations or points. If points, DC ≈ 33 % (`computed`). | same | secondary |
| End 2025 | Czechia ranks 14th in the EU by absolute count, 21st per capita | same | secondary |
| End 2025 | Same 7,574 and 12.8 % fast; "přes tři tisíce dobíjecích stanic" (over 3,000 stations) | [CT24-2026] ČT24, "Nabíječek elektromobilů přibývá…", 2026-04-03, https://ct24.ceskatelevize.cz/clanek/domaci/nabijecek-elektromobilu-pribyva-roste-i-zajem-o-ojetiny-371923, citing CDV on EAFO data | secondary |
| 31 Dec 2024 | 5,192 public points (MPO) | MPO presentation, 2025-06-10, https://mzp.gov.cz/system/files/2025-06/OPZP-1_2_Muricky_MPO-20250610.pdf | search summary |
| Sep 2026 | 7,590 points, 1,119 (14.7 %) > 150 kW (Čistá doprava portal) | ekonomickydenik.cz | search summary |
| H1 2024 | 5,201 points: AC 72.6 %, DC < 150 kW 21.4 %, DC ≥ 150 kW 6.0 % | EAFO Czechia page | search summary |

**EU**

| Date | Value | Source | Label |
|---|---|---|---|
| End 2025 | > 1.06 million public points, +178,000 y/y (≈ +20 %); > 50 % are in NL, FR, DE | [CDV-FDRIVE-2026] | secondary |
| End 2025 | 1,061,890 (EAFO export) | EV Boosters, https://evboosters.com/ev-charging-news/ev-charging-market-monitor-europes-public-ev-charging-network-reaches-1-3-million-points-by-april-2026/ | search summary |
| Apr 2026 | 1,139,463 total, of which 212,439 DC (`computed` ≈ 18.6 %) | same | search summary |
| 2026 (teaser dated 2026-10-29) | "public recharging infrastructure across the whole EU27 reached 1,176,554 points" (reference month not stated) | [EAFO-NEWS] https://alternative-fuels-observatory.ec.europa.eu/general-information/news/eafo-data-update-18-december-2025 | verified (text on EAFO page) |

The official end-2025 EU DC split exists on the EAFO interactive map (https://alternative-fuels-observatory.ec.europa.eu/interactive-map), but the values did not render for me.

---

## 9. Optional: battery swapping and wireless charging

**[GASGOO-NIO-2026]** Gasgoo, "NIO Adds 8 Charging and Battery Swap Stations, Nationwide Total Reaches 9,372", 2026-09-17, https://autonews.gasgoo.com/articles/ev/nio-adds-8-charging-and-battery-swap-stations-nationwide-total-reaches-9372-2101159044546236417. Label: `secondary`.

- 4,090 swap stations and 5,282 charging stations as of 2026-09-17.
- 100 millionth swap on 2026-02-06 (`search summary`).
- Target of ≥ 1,000 new swap stations in 2026 (`search summary`).

**SAE J2954 (wireless).** Label: `secondary` (trade press 2024-08-23; Wikipedia).

- Published as a full Standard in August 2024: "wireless power transfer at up to 11 kW with an efficiency of up to 93%".
- Classes WPT1/2/3 = 3.7 / 7.7 / 11 kW. Sources also give 7 kW for WPT2; 7.7 kW matches the earlier TIR.
- 85 kHz band (81.39–90 kHz); DIPS alignment.
- J2954/2 heavy-duty targets up to 500 kW.

---

## Gaps (could not verify)

1. **Tomaszewska et al. 2019 review**: not read (403 / download blocked). It is cited above as the standard fast-charging reference but labeled `search summary`.
2. **NMC-specific cell datasheet**: the 4.2 V example is the Panasonic NCR18650B, which is probably NCA (chemistry unverified). No AESC LMO (Leaf) cell datasheet found, so the Leaf's per-cell CV voltage and termination current are unverified. The "C/20 typical" figure is not verified; both datasheets read give ≈ C/50.
3. **Numeric power-vs-SoC tables**: Fastned and ev-database show curves only as images. P3 Charging Index PDF: 404. No INL measured curve for the 40 kWh Leaf. The rapidgate second-charge power (~20–25 kW) is forum-only.
4. **IEC 61851-1 per-mode current limits** (16 / 32 / 63 A) and **IEC 62196-2/-3 ratings**: normative text not accessed.
5. **EU Delegated Regulation 2025/656** text (EUR-Lex returned an empty page). The 2027 ISO 15118-20 scope is from vendor and national summaries only.
6. **MCS ratings** (3.75 MW), **IEC TS 63379** publication date, **GB/T 20234.3-2023** ratings, **J3400 V/A ratings**: secondary or search summary only.
7. **Czech official statistics**: the CDV press release itself and the MPO end-2025 figure were not opened, and fDrive's "2,510 DC" is ambiguous between stations and points. The EAFO Czechia page URL I tried returned 404.
8. **EU end-2025 DC share**: not available from a page I could read.
9. **Renault 5 V2G**: no customer numbers. The OBC V2G power rating and the ISO 15118-20 use are not confirmed from a primary source.
10. **Geotab "12 % of sessions" threshold**: not in the press release or the electrive article.
11. **Porsche 800→400 V booster** and **CCS 500 A as a standard limit** (as opposed to a product rating): not verified from a primary source.
