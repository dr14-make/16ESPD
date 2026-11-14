# Fuel cells and hydrogen: refueling stations, vehicles, efficiency, stack modeling

Research note for 16ESPD (CTU Prague), extra session on fuel cells and hydrogen.
Compiled 2026-11-12. Every number carries its own date, so check that date before putting a number on a slide.

**Verification labels**
- `verified`: I opened the primary page or PDF myself, and the quote is copied from it.
- `read from figure`: the value was read off a chart, with ± uncertainty.
- `secondary`: the value comes only from news or an aggregator. The aggregator may quote a primary source that I could not open.
- `search summary`: I saw only a search-engine snippet.
- `derived`: my own arithmetic on labeled inputs. The formula is shown.

**Access notes**
- nrel.gov no longer resolves. NREL has been renamed the National Laboratory of the Rockies (NLR); its pages are at nlr.gov and its PDFs at docs.nlr.gov, both readable.
- energy.ca.gov, h2stations.org, ISO, SAE, S&P Global and TÜV SÜD refused automated fetches.
- Where one of these sites was the primary source, the label says what was actually read.

---

## Headline numbers (slide-ready)

| Number | What | Source tag | Label |
|---|---|---|---|
| 70 MPa (H70) / 35 MPa (H35) | The two light-duty pressure classes in SAE J2601 | [DOE-H2IQ-HD-2024], [MATTELAER-J2601-2024] | verified |
| −40 °C to −33 °C | Gas delivery temperature for the T40 category (the 3-minute class) | [MATTELAER-J2601-2024] | verified |
| 85 °C | Maximum gas temperature in the vehicle tank during a fast fill | [DOE-REC-9013-2009], [GONIN-HYSAFE-2026] | verified |
| up to 875–880 bar | Dispenser overpressure needed to complete a 700-bar fill | [DOE-REC-9013-2009], [TIAX-PD068-2010] | verified |
| 300–950 bar | Range of cascade (buffer) storage pressure in the DOE/ANL station cost model | [DOE-ST100-2020] | verified |
| 60 g/s | Maximum H70 light-duty flow rate under SAE J2601 (categories A–D) | [MATTELAER-J2601-2024] | verified |
| 1.36 kWh/kg | Theoretical isothermal compression work, 20 bar to 700 bar | [DOE-REC-9013-2009] | verified |
| 3.0 kWh/kg (model), 1.7–6.4 kWh/kg (field) | Real compression energy for an 880-bar station | [DOE-REC-9013-2009] | verified |
| 0.15–0.2 kWh/kg | Precooling energy to reach −40 °C | [DOE-REC-9013-2009] | verified |
| ≈ $1.9 M (median) | Capital cost of a California 700-bar station sized ~1,240–1,500 kg/day, in $2016 | [DOE-REC-21002-2020] | verified |
| 1,160 | Stations in operation worldwide at the end of 2024 (Europe 294, of which Germany 113) | [LBST-H2STATIONS-2025] | secondary |
| 50 | Public stations in Germany, January 2026; more than 80 two years earlier | [ECOMENTO-DE-50-2026] (H2 MOBILITY data) | secondary |
| 22 | Small 700-bar stations closed by H2 MOBILITY in the first half of 2025 | [H2M-CLOSURES-2025] | secondary |
| 36 | Public stations in Germany taken off the network in 2025, all operators (Initiative H2-Infrastruktur Deutschland, 2026-01-05) | [SOLARSERVER-DE-36-2026] | secondary |
| 61 total / 50 open-retail | California stations, 2025-08-29 | [CARB-AB126-2025] | verified |
| 58 % → 74 % | California network availability, Q2 2024 → Q2 2025 (2021–2025 average 63 %) | [CARB-AB126-2025] | verified |
| 14,138 | FCEVs registered in California in April 2025: the first-ever year-over-year decline (−291) | [CARB-AB126-2025] | verified |
| ≈ €12.85 to ≈ €19 per kg | Retail hydrogen price in Germany (dates differ: see §2). €12.85 sits beside an "ADAC 2022 and BMDV 2021" cost comparison, so it is probably a 2022–23 value (my inference); €19 is Jan 2026 | [H2LIVE-PRICE], [ECOMENTO-DE-50-2026] | verified (price stated but undated) / secondary |
| ≈ €8/kg net | H2 MOBILITY truck price for hylane customers from 2026-01-01 (Düsseldorf, Rhein-Neckar). Not a car retail price | [H2M-HYLANE-2025] | verified |
| $34.55/kg | California average light-duty pump price, October 2024 (Platts) | [PLATTS-CA-2024] | secondary |
| 1 t/day, 700 bar, every ≤ 200 km on the TEN-T core network plus every urban node, by 2030-12-31 | AFIR Art. 6 hydrogen station requirement | [AFIR-2023-1804] | verified |
| 2 | Public stations in Czechia run by ORLEN (Praha-Barrandov, Litvínov), April 2026; further ORLEN construction "zatím pozastavili" (paused for now) as operation is loss-making. Others: CEPRO Mstětice, Vítkovice (Ostrava) | [SYSLOG-ORLEN-2026], [EKONOMICKYDENIK-CEPRO-2023] | secondary |
| 278 CZK/kg | ORLEN hydrogen price at opening, March 2023. No newer price found | [CNN-PRIMA-BARRANDOV-2023] | secondary |
| 0 of 10 | Mníšek pod Brdy hydrogen buses in passenger service on 2026-10-12 (station still being commissioned; target was Dec 2025) | [EPOCH-CZ-MNISEK-2026] | secondary |
| 3 min, 70 MPa, T40 | J2601 design target for a light-duty fill (SOC 90–100 %), per ANL/DOE | [ANL-J2601-FILLTIME] | verified |
| 3.22 min, 0.9 kg/min | Average real fill time and rate, 1,850,493 fills at the retail stations in the NREL dataset, 2014Q3–2022Q2 | [NLR-CDP-2023] | verified |
| 16,011 | FCEVs sold worldwide in 2025 (+24.4 %): China 7,797, South Korea 6,802, Europe 566, Japan 430, US 365 | [ARGUS-SNE-2026] | secondary |
| 49 | New fuel cell cars registered in Germany in 2025 (−69.0 %) | [KBA-2025] | verified |
| ≈ 130,000 | Global FCEV stock in 2025 (+20 %). Trucks use about 60 % of road hydrogen, buses about 30 % | [IEA-GHR-2026] | verified |
| 128 kW, 330 cells, 5.4 kW/L, 5.6 kg H2 | Toyota Mirai (2nd generation) fuel cell stack and hydrogen tank | [TOYOTA-UK-MIRAI-2020], [TOYOTA-UK-MIRAI-SPECS-2024] | verified |
| 0.79 kg/100 km | Mirai (2nd generation) combined WLTP consumption, 19-inch wheels | [TOYOTA-UK-MIRAI-SPECS-2024] | verified |
| 110 kW gross / 94 kW net, 6.69 kg, 826 km WLTP | Hyundai Nexo (2nd generation, Nov 2025 EU press release) | [HYUNDAI-NEXO-2025] | verified |
| 63.7 % / 66.0 % | Peak efficiency of the fuel cell system / stack (2016–17 Mirai, ANL dynamometer test) | [ANL-MIRAI-AMR-2018] | verified |
| 55 kWh/kg (61 % LHV) | PEM electrolysis system, DOE 2022 status | [DOE-PEM-TARGETS] | verified |
| 69 % vs 26 % vs 13 % | Electricity-to-wheel efficiency: BEV vs FCEV vs e-fuel ICE | [AGORA-SYNCOST-2018] | read from figure (±0.5 %) |
| 10–14 kg CO2-eq/kg H2 | Unabated natural gas (SMR) hydrogen; direct emissions about 9 | [IEA-H2-DEF-2023] | verified |
| 22–26 kg CO2-eq/kg H2 | Unabated coal gasification hydrogen | [IEA-H2-DEF-2023] | verified |
| 12.41 g/h per A | Hydrogen use of a 330-cell stack, Faraday's law | derived | derived |

---

## 1. Station technology

### 1.1 Pressure classes, fueling protocol, precooling

**[DOE-H2IQ-HD-2024]** "H2IQ Hour: Hydrogen Fuel Dispensing for Medium- and Heavy-Duty Vehicles", US DOE HFTO webinar slides (NREL presenters), 2024-03-26. https://www.energy.gov/sites/default/files/2024-04/h2iqhour-03262024.pdf. Label: `verified`.
- The fueling-protocol table lists "Pressure | 70 MPa (H70) and 35 MPa (H35)" and "Hydrogen Delivery Temperature | -40°C to 0°C (T40, T30, T20, T10, T0) and ambient (TA 30°C)".
- The table names the protocol: "Fueling Protocols • SAE J2601 (primarily, 350 bar and 700 bar)".
- An NREL heavy-duty test fill: "SAE J2601-5 MCF-HF-G H70 FM300 T40 … Total Fill Time: 423.5 Seconds (7.06 minutes) … Starting/Ending Pressure : 5.5 MPa/ 74.6 MPa … APRR: 9.9 MPa/min … Average Mass Flow Rate: 172.3 g/s (10.3 kg/min)".
- That NREL fill is useful as a real-world pressure-ramp example.

**[MATTELAER-J2601-2024]** V. Mattelaer (Senior Engineer), "H2 Fuelling Standards", HyTruck project (Interreg Baltic Sea Region) slides, uploaded 2024-04. https://interreg-baltic.eu/wp-content/uploads/2024/04/HyTruck-H2-Fuelling-Standards-Vincent-Mattelaer.pdf. Label: `verified`.
- Standards map from the slides:
  - General requirements: ISO 19880-1.
  - Dispenser: ISO 19880-2.
  - Light-duty fueling protocol: SAE J2601.
  - Communication: SAE J2799 / ISO 19885-2.
  - Nozzle: ISO 17268.
  - Hydrogen quality: ISO 14687.
- SAE J2601 H70 table:
  - "CHSS Capacity Range (kg) 2 to 4 | 4 to 7 | 7 to 10 | >10" maps to categories A, B, C, D.
  - "Maximum Flow Rate (g/s) 60 60 60 60".
- Temperature categories:
  - "T20: -26°C to -17.5°C"
  - "T30: -33°C to -26°C"
  - "T40: -40°C to -33°C"
- Note on revisions: "Category D will be removed in SAE J2601:2024. Category D will become a part of SAE J2601-5."
- Heavy duty: ISO 19885-3 / PRHYDE is "Able to fuel 80 kg in 10 minutes".

**[GONIN-HYSAFE-2026]** R. Gonin, F. Ammouri, D. Vempaire, B. R. Chowdhury, B. Lu (Air Liquide), "Experimental Investigation of Volume Estimation Methods for Hydrogen Refueling Stations", *HySafe* (peer-reviewed), 2026, doi:10.58895/hysafe.59. Label: `verified`.
- "A common solution is to compress the hydrogen in a gaseous form up to 700 bar to obtain a density of approximately 40 kg/m3 at a standard temperature of 15°C."
- "To reach 700 bar inside the compressed hydrogen storage system (CHSS), the refueling process requires managing the increase in the gas temperature inside the CHSS due to the compression. This is performed by selecting a refueling time and a fuel delivery temperature adapted to the refueling conditions (ambient temperature, precooling capacity, CHSS volume, etc.)."
- "…recommend safety guidelines during refueling (e.g., not to exceed 85°C in the gas (SAE International, 2020))."
- "The CHSS volume is an input for the two refueling protocols described in the SAE J2601 …: the MC method formula and the look-up tables. According to the CHSS volume, the average pressure ramp rate (APRR) and end-of-fill dispenser pressure differ."

**[DOE-REC-9013-2009]** M. Gardiner, "Energy requirements for hydrogen gas compression and liquefaction as related to vehicle storage needs", DOE Hydrogen and Fuel Cells Program Record #9013, 2009-07-07 (approved 2009-10-26). https://www.hydrogen.energy.gov/pdfs/9013_energy_requirements_for_hydrogen_gas_compression.pdf. Label: `verified`.
- Old, but still the standard DOE reference for station compression energy.
- Theoretical compression energy: "The theoretical energy to compress hydrogen isothermally from 20 bar to 350 bar … is 1.05 kWh/kg H2 and only 1.36 kWh/kg H2 for 700 bar".
- Field data and precooling: "DOE Technology Validation Project data for compression from on-site H2 production is 1.7 to 6.4 kWh/kgH2 … Additional energy required for pre-cooling (as cold as -40 C) to ensure on board fast fill temperatures are 85 C or lower can be modest (0.15 kWh/kg H2)".
- Overpressure: "A 350 bar system can require an overpressure as high as 440 bar and the maximum vessel temperature must be limited to 85 o. Pre-cooling is not usually needed for 350 bar fills of 5 kg H2 in less than 5 minutes … 700 bar fast fill systems can require an overpressure as high as 880 bar with pre-cooling as low as -40o C (233 Kelvin)".
- HDSAM model estimate: "…a refueling station compression energy efficiency of 52% to fill 350 and 49% for 700 bar vehicles. This corresponds to an energy use of 2.23 and 3.0 kWh/kg H2 for compression to 440 bar and 880 bar respectively … 0.2 kWh/kg H2 for cooling to -40o C for the 700 bar fill. Existing DOE Technology Validation hydrogen demonstration refueling sites have experienced an average compression energy of 3.1 kWh/kg H2".
- Air Products estimate: "2.67 kWh/kg compression energy to 880 bar … precooling energy required to cool hydrogen from 30o C to -20o C for a 700 bar refueling to be 0.18 kWh/kg H2".
- Liquefaction: "typically 10-13 kWh/kg LH2". This is useful for the liquid-hydrogen supply path and for the Daimler truck.
- Typical safety factor: "factor of safety of 2.25(US) to 2.35(EU)".

**[TIAX-PD068-2010]** K. McKenney et al. (TIAX), "Modeling Hydrogen Dispensing Options for Advanced Storage", DOE Hydrogen Program Review PD068, 2010-06-07. https://www.hydrogen.energy.gov/docs/hydrogenprogramlibraries/pdfs/review10/pd068_mckenney_2010_p_web.pdf. Label: `verified`.
- Layout diagram: pipeline delivery → bulk storage → compressor → cascade storage → pre-cooler → dispensing "up to 875 bar" → "5.6 kg, 700 bar gaseous vehicle storage". The diagram is a good template for a slide.
- Station chain: "Fueling station configuration is similar to baseline 350 bar stations (i.e., bulk storage, compression, cascade storage, and dispenser)".
- Why precool: "Pre-cooling to -20 to -40oC is required to offset the heat of compression and the Joule-Thomson (JT) effects".
- Fill limits: "Final SOC = 100% with the specific P (<87.5 MPa) and T (<85oC)".
- Tank type matters: "a type IV tank will require more pre-cooling due to heat transfer effects of plastic liner".

**[DOE-ST100-2020]** C. Houchins (Strategic Analysis), "Hydrogen Storage Cost Analysis" (ST100), DOE AMR 2020. https://www.hydrogen.energy.gov/pdfs/review20/st100_houchins_2020_o.pdf. Label: `verified`.
- Station model table: "Target Vehicle Pressure (bar) 700 … Max dispensed pressure is higher 875 bar".
- "Cascade Vessel Type Type 2".
- "Cascade Storage Pressure (bar) 300-950 … ANL optimization parameter".

**[DOE-REC-21002-2020]** M. Koleva, M. Melaina, "Hydrogen Fueling Stations Cost", DOE Hydrogen Program Record 21002, 2020-11-02 (approved 2021-02-11). https://www.hydrogen.energy.gov/pdfs/21002-hydrogen-fueling-station-cost.pdf. Label: `verified`.
- Supply options and the station chain, in one primary sentence: "Typically, HFSs are supplied with hydrogen via tube trailers, liquid hydrogen tankers, or onsite production. Hydrogen station designs typically include bulk storage, compression/pumping, high-pressure buffer storage, precooling unit, and dispensers".
- Capital cost figures are in §2.

**[ISO-19880-1]** ISO 19880-1:2020 "Gaseous hydrogen — Fuelling stations — Part 1: General requirements". Label: `search summary`. iso.org returned 403, so the scope comes from national standards-store mirrors.
- Scope: "minimum requirements for the design, installation, commissioning, operation, inspection and maintenance" of public and non-public gaseous hydrogen stations, for light-duty vehicles, with guidance for medium- and heavy-duty vehicles.
- Excludes cryogenic hydrogen dispensing and metal hydride applications.
- Covers production or delivery, compression, buffer storage, pre-cooling and dispensing.
- A revision (ISO/AWI 19880-1) was registered in January 2026.

**[SAE-J2601-2020]** SAE J2601_202005 "Fueling Protocols for Light Duty Gaseous Hydrogen Surface Vehicles", SAE, 2020-05. https://www.sae.org/standards/content/j2601_202005/. Label: `search summary`. The SAE page returned no content, so the standard was not read.
- A search snippet attributed to J2601: "a performance target of a fueling time of 3 minutes and a state of charge (SOC) of 95 to 100% (with communications), which can be achieved with a T40-rated dispenser".
- I could not open the page that carried that snippet.

**[ANL-J2601-FILLTIME]** K. Reddi, A. Elgowainy (Argonne National Laboratory), N. Rustagi, E. Gupta (DOE Fuel Cell Technologies Office), "Impact of hydrogen SAE J2601 fueling methods on fueling time of light-duty fuel cell electric vehicles", author manuscript on OSTI (ID 1389635; its references run to January 2017). https://www.osti.gov/servlets/purl/1389635. Label: `verified` (PDF text extracted). This is the citable, non-paywalled source for the 3-minute target.
- "The desired performance attributes used to develop the SAE J2601 fueling protocol ensure consumer convenience by enabling a fueling time of 3 minutes for a 70 MPa FCEV at a T40 station (i.e., capable of precooling to -40oC) achieving a state of charge of 90% to 100% of the rated capacity of the vehicle storage (defined at nominal working pressure and 15oC)."
- The SOC band here (90–100 %) differs from the SAE snippet above (95–100 % with communications). Quote the source you cite.
- The paper compares the J2601 "lookup table" and "MC formula" methods: the MC formula method "provides faster vehicle fills", especially at high ambient temperature.

**[NLR-CDP-2023]** G. Saur, S. Gilleon, S. Sprik, "Next Generation Hydrogen Station Composite Data Products: Retail Stations – Summer 2022: Data through Quarter 2 of 2022", NREL/PR-5400-86247, 2023-05-09. https://docs.nlr.gov/docs/fy23osti/86247.pdf (nlr.gov, formerly nrel.gov). Label: `verified` (PDF text extracted). Real fill times, CDP-INFR-02 and CDP-INFR-03 (data range 2014Q3–2022Q2):
- "1,850,493 Events", "Average = 0.9 kg/min", "0.8% >1.51 kg/min", "0.2% >2 kg/min".
- "Average = 3.22 min", "53% <3.3 min", "28% <2.5 min".
- The chart legends mark the "2020 MYRDD Target for 5kg" and the "Ultimate MYRDD Target (5 kg in 2.5 min)". The 3.3-min mark matches 5 kg at the 1.5 kg/min (2020) target. Label for that pairing: `read from figure`.
- Slide point: the average US retail fill already takes about 3 minutes, but only 28 % of fills are faster than the 2.5-minute DOE ultimate target.

**Fill time.**
- **[HYUNDAI-NEXO-2025]** (`verified`): Hyundai quotes a "five-minute hydrogen refill", defined as more than 95 % refueling.
- `derived`: at the J2601 maximum of 60 g/s, 5 kg takes at least 83 s. Average ramp-limited fills are therefore 3–5 min.

**Physics note for the lecture (`derived`, standard thermodynamics; no single source quoted):**
- The gas in the tank heats up mainly by adiabatic compression of the gas already in the tank, plus conversion of the incoming flow work.
- Hydrogen's Joule–Thomson inversion temperature (~200 K) is below ambient. Throttling at the dispenser therefore warms hydrogen rather than cooling it.
- Both effects are why precooling to −40 °C is needed to stay under the 85 °C tank limit at a 3-minute rate.
- The DOE quotes above ([DOE-REC-9013-2009], [TIAX-PD068-2010]) name both mechanisms.

### 1.2 Station layout (slide summary)

Supply → bulk storage → compressor → high-pressure cascade/buffer (~300–950 bar) → chiller/precooler (−40 °C) → dispenser (H70 up to 875 bar, H35).

Supply options: tube trailer, liquid hydrogen tanker (with cryopump/vaporizer), or on-site electrolysis/SMR.

Sources: [DOE-REC-21002-2020], [TIAX-PD068-2010], [DOE-ST100-2020]. All `verified`.

### 1.3 Energy cost of station operations: summary

| Step | kWh/kg | % of LHV (33.3 kWh/kg) | Source | Label |
|---|---|---|---|---|
| Isothermal compression, 20 → 700 bar (theory) | 1.36 | 4.1 % | [DOE-REC-9013-2009] | verified |
| Real compression to 880 bar (HDSAM / APCI / field average) | 3.0 / 2.67 / 3.1 | 8–9 % | [DOE-REC-9013-2009] | verified |
| Precooling to −40 °C | 0.15–0.2 | ≤ 0.6 % | [DOE-REC-9013-2009] | verified |
| Liquefaction (for liquid hydrogen supply) | 10–13 | 30–40 % | [DOE-REC-9013-2009] | verified |

---

## 2. Station reliability and economics

**[CARB-AB126-2025]** California Air Resources Board, "2025 Annual Evaluation of Fuel Cell Electric Vehicle Deployment and Hydrogen Fuel Station Network Development (Pursuant to AB 126)", December 2025. https://ww2.arb.ca.gov/sites/default/files/2025-12/AB-126-Report-2025-Final.pdf. Label: `verified` (PDF text extracted).

Network status (2025-08-29):
- "As of Aug 29, 2025, California's hydrogen fueling network has 61 stations with Chevron as a new station developer".
- "…among the 61 stations, 11 stations are considered Temporarily Non Operational (TNO) … This combination of station activities results in a total of 50 stations that are Open-Retail in California".

Closures:
- "two stations (University of California Irvine and Santa Monica) were decommissioned and two new stations by Chevron have opened … each being 808 kg/day. The Woodside station never became open-retail and has been closed. Decommissioned stations are smaller legacy stations being closed due to high repair and maintenance costs."

Availability:
- "The overall station availability since 2021 (the proportion of the maximum network capacity that is actually available, including TNOs) is 63%. In a year-over-year comparison, the average availability of the hydrogen station network was 58% in the second quarter of 2024 and improved to an average of 74% in the second quarter of 2025."

Market:
- "Low Carbon Fuel Standard (LCFS) credit values, limited supply, and maintenance disruptions elevated hydrogen retail prices. High hydrogen retail prices have further dampened consumer demand…"
- "Based on April 2025 registration data from DMV, there were 14,138 FCEVs with an active registration status in California. The data demonstrates the first historical decline in total registrations, with 291 fewer FCEVs registered between 2024 and 2025."
- The report's introduction says 14,128 for the same date. Its two figures disagree, so use 14,138 from Finding 3.

Projection:
- The station projection was cut from up to 87 to 64 by end-2025.
- "the hydrogen fueling station network is projected to reach 112 stations by 2031, which is 17 fewer stations compared to last year's analysis", partly due to "the recent decision of Air Products and Iwatani to return grants for planned stations."

**[H2FCP-2025-ANNUAL]** Hydrogen Fuel Cell Partnership, "H2FCP 2025 Annual Report: A Year of Progress, Resilience…", blog post, 2026-02-24. https://h2fcp.org/blog/h2fcp-2025-annual-report-year-progress-resilience-and-stronger-foundation-hydrogen-mobility. Label: `verified` (industry partnership, not a regulator).
- "California's hydrogen refueling network stabilized at 51 operating retail stations".
- "average availability climbing to approximately 90% by year-end".
- This availability metric differs from CARB's capacity-weighted 63 %/74 %. Do not compare the two directly.

**[NREL-CDP]** NLR (ex-NREL) "Next Generation Hydrogen Station Composite Data Products: Retail Stations", https://www.nlr.gov/hydrogen/infrastructure-cdps-retail, retrieved 2026-11-12. Label: `verified` for the page facts below. The old nrel.gov URLs do not resolve; the same pages live on nlr.gov.
- The page is "Last Updated Feb. 10, 2025". Its newest product set is the 2023 release with data through Q2 2022 ([NLR-CDP-2023], §1.1). **No 2024–2026 reliability or availability data is published there.**
- Maintenance by known equipment type, CDP RETAIL INFR 21 (created 2022-03-28, data 2014Q3–2021Q2). Label: `read from figure` (percent labels are printed on the pie; the slice-to-component mapping is my reading of the legend colors).
  - "Total Events = 19,040, 61% unscheduled": dispenser 48 %, compressor 22 %, chiller 14 %, storage 9 %, gas management panel 7 %.
  - "Total Hours = 51,960, 64% unscheduled": dispenser 36 %, chiller 20 %, storage 20 %, compressor 18 %, gas management panel 6 %.
- "2021 Station Unavailability for 51 stations", CDP RETAIL INFR 93 (created 2022-04-14). Label: `read from figure` (±3 stations): about 0–10 stations unavailable in January–February 2021, rising to about 30–40 in early September 2021.
- A 2020 DOE review: "most maintenance remains on dispensers, followed by compressors". Label: `search summary`.
- Related paper: Kurtz, Sprik, Peters, Bradley, "Retail Hydrogen Station Reliability Status and Advances" (analysis of more than 5,000 maintenance events). Not opened.
- For 2024–2025 availability, use CARB (58 % → 74 %, above) or the H2FCP figure (≈ 90 % at end-2025, different metric).

**Station capital cost: [DOE-REC-21002-2020]** (above). Label: `verified`.
- "Capital equipment cost estimates for 111 new fueling stations selected for award in California varied between approximately $1,200 and $3,000 per kilogram hydrogen dispensed per day … all stations were designed with 700-bar fueling capability".
- "an average hydrogen station has capacity of 1,240 kg/day (median capacity of 1,500 kg/day) and requires approximately $1.9 million in capital (median capital cost of $1.9 million)".
- Table 2:
  - Gaseous tube trailer, 770 kg/day: $1,400k.
  - Liquid tanker, 1,400–1,620 kg/day: $1,900–4,200k.
- All values in $2016, uninstalled, from grant applications.

**Retail price, Germany.**
- **[H2LIVE-PRICE]** H2 MOBILITY Deutschland, h2.live (English site), retrieved 2026-11-12. https://h2.live/en/. Label: `verified` for the text, but the date is unknown.
  - Quote: "The price for a kilogram of hydrogen at all public H2 MOBILITY filling stations is €12.85 (gross)."
  - This is the uniform price H2 MOBILITY set in 2023. It is likely stale on that page, because prices have been dynamic since October 2023.
  - The same FAQ answer goes on: "For 100 km, a fuel cell vehicle consumes approximately 0.8 kilograms of hydrogen (WLTP), generating fuel costs of €10.28 … (Source: ADAC 2022 and BMDV 2021)". The comparison it sits in is dated 2021–22, which supports reading €12.85 as a 2022–23 value (my inference).
- **[ECOMENTO-DE-50-2026]** T. Langenbucher, "Nur noch 50 öffentliche Wasserstoff-Tankstellen in Deutschland", ecomento.de, 2026-01-16 (citing H2 MOBILITY data and Handelsblatt). https://ecomento.de/2026/01/16/nur-noch-50-oeffentliche-wasserstoff-tankstellen-in-deutschland/. Label: `secondary`.
  - Price: "bis zu rund 19 Euro pro Kilogramm" (up to about €19 per kg), varying by region and pressure.
- Düsseldorf station (search summary, h2-international.com, 2025): €13.55/kg at 350/500 bar and €15/kg at 700 bar. H2 MOBILITY called these prices "close to the purchase cost". Label: `search summary`.
- **[H2M-PRICECUT-PRIMARY-2026]** H2 MOBILITY, "Preissenkung bei H2 MOBILITY: THG-Quotenhandel zeigt erste Wirkung", Berlin, 2026-05-28. https://h2.live/news/4167/. Label: `verified`.
  - "senkt zum 01. Juni die Preise für Wasserstoff an mehreren leistungsstarken Tankstellen in einem ersten Schritt um rund 10%" (from 1 June, cuts prices at several high-throughput stations, as a first step, by about 10 %).
  - "Die Preisanpassung betrifft die Standorte Mannheim, Heidelberg, Frankenthal, Ludwigshafen und Düsseldorf-Höherweg" and "gilt für die Druckstufen 350 bar und 700 bar".
  - The release gives no euro price per kg.
- **[H2M-HYLANE-2025]** H2 MOBILITY news, Köln, 2025-11-18. https://h2-mobility.de/news/4039/. Label: `verified`.
  - "Ab dem 1. Januar 2026 tanken hylane-Kunden an ausgewählten H2 MOBILITY-Tankstellen Wasserstoff … für rund 8 Euro netto pro Kilogramm." Available "in den Regionen Düsseldorf sowie Rhein-Neckar"; "Das Angebot gilt exklusiv mit einer hylane-Tankkarte."
  - This is a truck fleet contract price, net of VAT. It is not the car retail price.
- Other 2026 car prices found are weak: energiemarie.de (consumer site) gives €13.20–13.50/kg at 700-bar car pumps in May 2026 (`search summary`); an ecomento reader comment dated 2026-07-10 reports €17.95/kg at 700 bar at a new Waiblingen station (`secondary`, reader comment, not reporting).
- **[H2M-PRICECUT-2026]** Hydrogen Central, "H2 MOBILITY cuts hydrogen prices at high-volume German stations", 2026-06-19. Label: `secondary`. Reports the same cut as [H2M-PRICECUT-PRIMARY-2026].
  - About −10 % at Mannheim, Heidelberg, Frankenthal, Ludwigshafen and Düsseldorf-Höherweg, for both 350 and 700 bar.
  - Drivers named: "economies of scale and the financial benefits of greenhouse gas quota trading".
- vision-mobility.de, 2026-09-28, source "H2 Mobility". Label: `secondary`.
  - From 2026-10-01, 15 more stations (Bayreuth … Wesseling) become "um 12 bis 16 % günstiger" (12–16 % cheaper).
  - No euro values are given.
- Truck fleet contract: hylane customers at about €8/kg net from 2026-01-01. Now confirmed from the primary page: see [H2M-HYLANE-2025] above (`verified`).

**Retail price, California.**
- **[PLATTS-CA-2024]** S&P Global Commodity Insights, "California hydrogen pump prices for light-duty vehicles reach new highs", 2024-10-01. Label: `secondary`. The page returned 403; the quote is reproduced by Hydrogen Central and by search snippets.
  - "Platts … assessed the monthly average price of light-duty hydrogen fuel in California pump stations at $34.55/kg on Oct. 1, a 1.3% increase from the previous record-high set in January 2024."
- True Zero (largest operator) raised the price to $36/kg across its stations (Hydrogen Insight, 2023). Label: `search summary`.
- First Public Hydrogen Authority press release (April 2026): "Retail hydrogen prices in some markets today can range from $30 to $65 per kilogram". Label: `search summary`.
- **[CEC-AB126-2026]** CEC/CARB, "Joint Agency Staff Report on Assembly Bill 126: 2025 Annual Assessment of the Hydrogen Refueling Network in California", CEC-600-2026-022, posted 2026-05. https://www.energy.ca.gov/sites/default/files/2026-05/CEC-600-2026-022.pdf. Label: `search summary` (energy.ca.gov refuses automated fetches; no mirror found on ww2.arb.ca.gov or h2fcp.org).
  - Snippets: the price of hydrogen "averaged $35.47 in the second quarter of" (the year is cut off in the snippet; 2025 by context, unconfirmed); "the average price of dispensed hydrogen has largely remained the same since the sharp increase".
  - Snippets: 50 stations open to the public as of 2025-09-02, with 11 more temporarily non-operational; average network availability over the past year "approximately 60 percent".
  - A secondary blog summarizing it rounds the price to $36/kg, "equivalent to about $14.40 per gallon of gasoline".
- Platts assessed California light-duty pump prices at $34.70/kg in early December 2024 (S&P Global article, via search snippet). Label: `search summary`.

**Cost per 100 km (`derived`).**

Hydrogen inputs:
- Mirai 0.79 kg/100 km WLTP ([TOYOTA-UK-MIRAI-SPECS-2024], verified).
- Nexo 0.81 kg/100 km WLTP ([HYUNDAI-NEXO-2025], verified).

| Case | Price input | Cost per 100 km |
|---|---|---|
| Mirai, Germany, €12.85/kg (stated, undated) | [H2LIVE-PRICE] | 0.79 × 12.85 = **€10.15** |
| Mirai, Germany, ~€19/kg (Jan 2026 upper bound) | [ECOMENTO-DE-50-2026] | 0.79 × 19 = **€15.01** |
| Mirai, California, $34.55/kg (Oct 2024) | [PLATTS-CA-2024] | 0.79 × 34.55 = **$27.29**. WLTP consumption is used here; real US consumption differs. |

For the BEV and petrol comparison:
- Cost per 100 km = consumption × price.
- Example placeholders, which are **not sourced** and should be replaced with current CZ/DE prices:
  - BEV at 17 kWh/100 km: €0.35/kWh at home gives ≈ €6; €0.60/kWh at a fast charger gives ≈ €10.
  - Petrol car at 6 L/100 km and €1.75/L: ≈ €10.5.
- The message holds across that range: a hydrogen car in Germany costs about the same as petrol or more, and more than a BEV charged at home. In California it costs 2–3× either.

---

## 3. Station counts and network trend

**[LBST-H2STATIONS-2025]** LBST / H2stations.org, 17th annual assessment (data to end of 2024), released 2025-02. Read via Motor1, "There are only 1,160 hydrogen refuelling stations worldwide", 2025-02-13, https://www.motor1.com/news/750564/hydrogen-refuelling-stations-worldwide-map/, and the TÜV SÜD / h2stations.org release (both of those blocked automated access). Label: `secondary`.

| Region | End-2024 stations | New in 2024 |
|---|---|---|
| World | 1,160 (45 countries) | ~125 |
| Europe | 294 | 42 |
| Germany | 113 | — |
| France | 65 | — |
| Netherlands | 25 | — |
| Switzerland | 19 | — |
| China | 384 | ~30 |
| South Korea | 198 | 25 |
| Japan | 161 | 8 |
| USA | 89 (9 opened, 12 closed) | — |

- Caveat from LBST: "The actual number of hydrogen refuelling stations is subject to uncertainties, partly due to a lack of public announcements in the event of closures."
- The 18th assessment (end-2025 data) was **not found** as of 2026-11-12. LBST's own news page (https://en.lbst.de/, fetched 2026-11-12) lists 2026 items on other topics, and its newest H2stations.org release is still the 2025-02-11 one (`verified` for that absence). Trade-press searches in English and German found no end-2025 world/Europe/Germany figures. See Gaps.
- Europe now has an official station-data platform: the Clean Hydrogen Partnership launched "H2-Stations" (https://h2-stations.eu, live map at map.h2-stations.eu) on 2026-05-20, offering "free and open access to both static and dynamic HRS data at a European level". The announcement gives no station counts. Label: `verified`. The map was not read.
- The LBST count for Germany (113) covers all stations, including bus and depot stations, so it is not comparable with the H2 MOBILITY public count below.

**Germany: H2 MOBILITY.**
- **[ECOMENTO-DE-50-2026]** (`secondary`, citing H2 MOBILITY):
  - "aktuell 50 öffentlich zugängliche Anlagen am Netz" (currently 50 publicly accessible stations online). "vor zwei Jahren waren es noch über 80" (two years earlier there were more than 80).
  - Pressure split: 2 stations offer 350 bar only, 35 offer both pressures, 13 offer 700 bar only.
  - Europe (h2.live map): 152 open, 51 in realization.
- **[H2M-CLOSURES-2025]** H2 MOBILITY press release, Berlin, 2025-02-17, via Hydrogen Central (2025-02-25). https://hydrogen-central.com/network-consolidation-700-bar-h2-mobility-continues-to-drive-transformation-towards-commercial-vehicles-hydrogen-refueling-stations/. Label: `secondary`.
  - "11 small 700-bar refuelling stations" close on 2025-03-31: Neuruppin, Bonn, Flensburg, Geisingen, Potsdam, Ulm, Siegen, Aachen, Bad Rappenau, Heidelberg (Speyerer Straße), Mönchengladbach.
  - 11 more close by the end of Q2 2025.
  - Reasons: the stations, "some of which were built more than 10 years ago", "no longer meet today's technical and economic requirements", and a "muted market ramp-up for passenger cars".
  - New focus: "light and heavy commercial vehicles".
  - Earlier closures: 3 stations (electrive, 2024-03-26) and 6 older stations (electrive, 2024-10-02). Label: `search summary`.
- **[SOLARSERVER-DE-36-2026]** solarserver.de, "Petition gegen Rückbau von Wasserstofftankstellen in Deutschland", 2026-01-05, citing the Initiative H2-Infrastruktur Deutschland (Frank Stuckstedte). https://www.solarserver.de/2026/01/05/petition-gegen-rueckbau-von-wasserstofftankstellen-in-deutschland/. Label: `secondary`.
  - By the end of 2025, "insgesamt 36 öffentlich zugängliche Wasserstofftankstellen vom Netz gegangen" (a total of 36 publicly accessible hydrogen stations went off the network).
  - The article gives no count of stations remaining. Use the H2 MOBILITY figure (50, January 2026) for that.
- ecomento, 2025-04-11 (`secondary`): in March 2025, the 350-bar share of H2 MOBILITY fuelings was "deutlich über 50 Prozent" (well over 50 %), above 700 bar for the first time.

**California:** see [CARB-AB126-2025] in §2. 61 total and 50 open-retail on 2025-08-29.
- **[SHELL-CA-2024]** Shell exit, February 2024. Label: `secondary` (InsideEVs, Autoblog 2024-02-24, Hydrogen Insight).
  - Shell permanently closed its light-duty hydrogen stations in California, citing "supply complications and other external market factors".
  - It kept 3 heavy-duty stations.
  - Reports differ on the count (six or seven stations).
- A KBB report says True Zero closed 10 locations. Undated. Label: `search summary`.
- A CleanTechnica piece (March 2026) claims more than 60 % of California retail stations were offline in late March 2026. Single outlet, page not retrievable. Label: `search summary`.

**Denmark: [EVERFUEL-2023].** Everfuel Q2 2023 report (2023-08-30) and September 2023 coverage. Label: `secondary` (Hydrogen Central, electrive 2023-09-16, Hydrogen Insight).
- Everfuel decided to "restructure the hydrogen station network due to current immature hydrogen mobility market and technology".
- CEO: "The mobility market is set to remain sub-scale for some time".
- Reasons cited: "continuous low technical uptime" and too few vehicles.
- Press reports say Denmark was left with no commercial car stations. Everfuel's own list named specific sites, so the "all stations" framing may be overstated.

**UK:** Shell closed its three car stations; the date was not given in the snippet. Motive closed its Swindon station. Label: `search summary`.

**Czechia.**
- **[CNN-PRIMA-BARRANDOV-2023]** "V Praze už se dá tankovat do aut vodík…", CNN Prima News, 2023-03-10. https://cnn.iprima.cz/v-praze-byla-otevrena-verejna-plnici-stanice-pro-vozidla-na-vodik-jezdi-jich-jen-par-207118. Label: `secondary`.
  - ORLEN Unipetrol, Praha-Barrandov: 700 bar for cars, 350 bar for trucks and buses.
  - "278 korun za jeden kilogram" (278 CZK per kg).
  - Twelve hydrogen cars were registered in Czechia (Interior Ministry data).
- **[CC-LITVINOV-2023]** CzechCrunch, 2023-07-05. Label: `secondary`.
  - Second ORLEN station, at the Orlen Benzina site in Záluží u Litvínova, with the "same technical parameters" as Barrandov. Fully self-service, non-stop.
- **[EKONOMICKYDENIK-CEPRO-2023]** Ekonomický deník, 2023-06-20. Label: `secondary`.
  - CEPRO station at the Mstětice depot near Prague, with "plnících pistolí pro plnění tlakem 350 bar a tlakem 700 bar" (nozzles for 350 bar and 700 bar).
  - Six more stations were supported under OP Doprava 3 (Prague, Ostrava, Brno, Napajedla).
- **[CT24-VITKOVICE-2022]** ČT24, 2022-06-28. Label: `secondary`.
  - The first public station, in Vítkovice (Ostrava), "ve zkušebním provozu" (in test operation).
  - Introductory flat price of 2,500 CZK or €100 per fill.
  - National plan: "Do roku 2030 v České republice osmdesát plnicích vodíkových stanic" (80 hydrogen filling stations in Czechia by 2030).
- **[FORBES-CZ-ORLEN]** Forbes.cz (undated in the snippet; probably 2025). Label: `search summary`.
  - ORLEN Unipetrol "provozuje dvě, v Praze a Litvínově" (operates two, in Prague and Litvínov).
  - It plans stations at Praha-Horní Počernice, Brno-Slatina and Ostrava-Pustkovec "do konce roku 2026" (by the end of 2026).
  - About 20 stations around 2030, down from an earlier target of 28.
  - Public stations named: Barrandov, Litvínov, Vítkovice, Mstětice.
- **[SYSLOG-ORLEN-2026]** F. Hubička, "Nástup vodíku v dopravě na českém trhu zpomaluje, rozhodují náklady i slabá poptávka", Systemylogistiky.cz, 2026-04-21. https://www.systemylogistiky.cz/2026/04/21/nastup-vodiku-v-doprave-na-ceskem-trhu-zpomaluje-rozhoduji-naklady-i-slaba-poptavka/. Label: `secondary` (trade press quoting ORLEN Unipetrol spokesperson Lada Gadas).
  - "V Česku dnes Orlen Unipetrol provozuje dvě veřejné vodíkové plnicí stanice, a to v Praze na Barrandově a v Litvínově." (ORLEN Unipetrol today operates two public hydrogen stations in Czechia, Praha-Barrandov and Litvínov.)
  - "Skupina Orlen Unipetrol proto přehodnotila původní plány a další výstavbu vodíkových stanic zatím pozastavila." Spokesperson: "…a další výstavbu jsme zatím pozastavili". (Further construction is paused for now.)
  - "Orlen Unipetrol uvádí, že při současném objemu tankování je jejich provoz ztrátový." (At current fueling volumes, operating them is loss-making.)
  - "V provozu jsou zatím jen nižší desítky vozů" (only a few dozen hydrogen vehicles are in operation).
  - HYTEP's Martin Křemenák: about €6/kg would be needed to compete with diesel. No current CZK price is given.
  - So the Horní Počernice, Brno-Slatina and Ostrava-Pustkovec stations planned "do konce roku 2026" were **not opened** as of April 2026, and construction is on hold. No later report found.
- **[FDRIVE-BARRANDOV-2025]** fDrive.cz, "Konec vodíku v Čechách? Barrandovská plnička už několik týdnů nefunguje", 2025-06-13. https://fdrive.cz/clanky/konec-vodiku-v-cechach-barrandovska-plnicka-uz-nekolik-tydnu-nefunguje-14722. Label: `secondary`.
  - The Barrandov station "je už více než měsíc mimo provoz" (has been out of service for more than a month) "kvůli blíže nespecifikované technické závadě" (an unspecified technical fault); "Oprava tak může trvat i několik týdnů."
  - With Barrandov down, the nearest working station was Litvínov. A useful real-world availability example for the lecture.
- **Price:** no CZK/kg price newer than 278 CZK/kg (March 2023) was found. Label: `secondary` (as above).
- auto.cz, undated in the snippet: "V Česku je šest vodíkových čerpaček" (six hydrogen stations in Czechia) and 29 hydrogen cars (Čistá doprava data). Label: `search summary`.
- **Vítkovice status on 2026-11-12 is unverified.** No 2025–2026 report on its operation or price was found.

**EU law: [AFIR-2023-1804].** Regulation (EU) 2023/1804 of 13 September 2023 on the deployment of alternative fuels infrastructure, OJ L 234, 22.9.2023. Text from the EU Publications Office (Cellar) XHTML, http://publications.europa.eu/resource/celex/32023R1804. Label: `verified`.
- **Art. 6(1):** "Member States shall ensure that by 31 December 2030 publicly accessible hydrogen refuelling stations designed for a minimum cumulative capacity of 1 tonne per day and equipped with at least a 700 bar dispenser are deployed with a maximum distance of 200 km between them along the TEN-T core network. Member States shall ensure that, by 31 December 2030, at least one publicly accessible hydrogen refuelling station is deployed in each urban node."
- **Art. 6(1), cont.:** "…a clear linear trajectory towards meeting the 2030 targets, along with a clear indicative target for 2027…"
- **Art. 6(3):** "…shall ensure that the station is designed to serve light-duty and heavy-duty vehicles."
- **Art. 6(4) derogation:** "along roads of the TEN-T core network with a total annual average daily traffic of fewer than 2 000 heavy-duty vehicles … Member States may reduce by up to 50 % the capacity…"
- **Review clause:** "Regarding hydrogen refuelling stations, the Commission shall further assess the requirements referred to in Article 6 … the need to specify a higher capacity for those stations, the need to specify targets for liquid hydrogen refuelling infrastructure…"
- **Review date:** "By 31 December 2026 and every five years thereafter, the Commission shall review this Regulation."

---

## 4. Vehicles

**[TOYOTA-UK-MIRAI-2020]** Toyota (GB) media, "Introducing the All-New Toyota Mirai", 2020-11-30 (Ref 201130M). https://media.toyota.co.uk/introducing-the-all-new-toyota-mirai/. Label: `verified`.
- "sets a new record for specific power density at 5.4 kW/l (excluding end plates)".
- "fewer cells (330 instead of 370)"; "Maximum power has thus risen from 114 kW to 128 kW".
- "three high-pressure hydrogen tanks … Together they can hold 5.6kg of hydrogen, compared to 4.6kg in the current Mirai's two tanks"; "multi-layer construction".
- "extending the driving range by 30 per cent to around 400 miles".
- Battery: "Containing 84 cells, it has a 310.8 rated voltage … and a 4.0Ah capacity".
- `derived`: 310.8 V × 4.0 Ah = 1.24 kWh. This is a power buffer, not an energy store.
- The page does not state 70 MPa or the tank type. 70 MPa / Type IV is commonly cited but was **not verified** from Toyota primary text in this session.

**[TOYOTA-UK-MIRAI-SPECS-2024]** Toyota (GB), "Toyota Mirai Technical Specifications", PDF, file dated 2024-11-27. https://media.toyota.co.uk/wp-content/uploads/sites/5/pdf/241127-Mirai-Tech-Specs.pdf. Label: `verified`.
- Stack: "FCB130 | Polymer electrolyte | Number of cells 330 | Series | Max. output 172 bhp / 174 DIN hp / 128 kW".
- Stack volume: "4 (exc. end plates), 4.4 (inc. end plates)" L. Weight 52 kg.
- Battery: lithium-ion, 84 cells, 310.8 V nominal, 4.0 Ah, package 44.6 kg.
- Motor: 134 kW, 300 Nm, rear-wheel drive.
- Fuel and range: "Combined (kg/100km) 0.79 – 19in wheel, 0.89 – 20in wheel"; "Fuel tank capacity (kg/l) 5.6/142.2"; "EV driving range (miles) Up to 400".
- Kerb weight 1,900–1,950 kg. Cd 0.29.
- `derived`:
  - 128 kW / 52 kg = 2.46 kW/kg.
  - 128 kW / 4 L = 32 kW/L, which contradicts the official 5.4 kW/L. The "4 L" in the spec sheet is probably not the full stack volume (128/5.4 ≈ 23.7 L).
  - Flag this inconsistency rather than putting 4 L on a slide.
  - 128 kW / 330 cells = 388 W per cell.

**[HYUNDAI-NEXO-2025]** Hyundai Motor Europe press release "All-new NEXO sets new standards…", 2025-11-11. https://www.hyundai.news/eu/articles/press-releases/all-new-nexo-sets-new-standards.html. Label: `verified`.
- Fuel cell: "110 kW (Gross) / 94 kW (Net, FC system output)".
- System output up from 135 kW to 190 kW. Front motor "150 kW front (350 Nm)".
- Storage: 6.69 kg usable (previously 6.33 kg), "54.2 ℓ x 3" = 162.6 L.
- Range and consumption: 826 km WLTP (18-inch wheels); 0.81 kg/100 km (18-inch), 0.89 kg/100 km (19-inch). The release says consumption figures are not final.
- Battery: 80 kW / 2.64 kWh.
- Refueling: "five-minute hydrogen refill" (more than 95 % fill).
- Korean market figures differ (≈720 km). Label: `search summary`.

**[HONDA-CRV-EFCEV-2024]** Honda press release "Honda Reveals 2025 Honda CR-V e:FCEV…", 2024-02-27, via Automotive World. https://www.automotiveworld.com/news-releases/honda-reveals-2025-honda-cr-v-efcev-americas-first-production-plug-in-hydrogen-fuel-cell-electric-vehicle/. Label: `secondary` (Honda text reproduced verbatim on an aggregator).
- Battery and range: "17.7 kWh"; "up to 29 miles of battery electric range (EPA estimated)"; "270 mile zero-emission EPA driving range rating".
- Hydrogen: 4.3 kg at "10,000 psi".
- Fuel cell: "Estimated Power Output 92.2kW". Co-developed with GM.
- Versus the Clarity fuel cell: "reduce the cost by two-thirds" and "the durability of the system has doubled".
- Charging: "Plug-in Level II charging capability".
- This car is a good example of a plug-in series hybrid FCEV for the course model.

**Sales.**
- **[ARGUS-SNE-2026]** C. Idrissov, "China, S Korea drove rebound in 2025 H2 vehicle sales", Argus Media, 2026-02-13 (SNE Research data). Label: `secondary`.
  - Global 2025 sales 16,011 (+24.4 %).

    | Market | 2025 units | Share |
    |---|---|---|
    | China | 7,797 | 48.7 % |
    | South Korea | 6,802 | 42.5 % |
    | Europe | 566 | 3.5 % |
    | Japan | 430 | 2.7 % |
    | US | 365 | 2.3 % |
    | Others | 51 | — |

  - Hyundai: 7,047 (2024: 4,460). Toyota: 1,257. Asiae, reporting the same SNE tracker, gives Hyundai 6,861 and Toyota (Mirai plus Crown) 1,168, −39.1 %.
  - Europe 566 is −23.1 % year over year. US −37.7 %. Japan −37.3 %. H1 2025 alone was −27 % (4,102 units).
  - Message: growth is concentrated in Chinese commercial vehicles and Korean Nexo sales. Europe, the US and Japan are falling.
- **[KBA-2025]** Kraftfahrt-Bundesamt, press release "Fahrzeugzulassungen im Dezember 2025 – Jahresbilanz", 2026-01. https://www.kba.de/DE/Presse/Pressemitteilungen/Fahrzeugzulassungen/2026/pm01_2026_n_12_25_pm_komplett.html. Label: `verified`.
  - "49 Fahrzeuge mit Brennstoffzelle (Wasserstoff) (-69,0 %)" (49 fuel cell vehicles, −69.0 %). These are new passenger car registrations in Germany in 2025.
- **[CARB-AB126-2025]**: California registrations fell for the first time (see §2).
- **[IEA-GHR-2026]** IEA, *Global Hydrogen Review 2026*, published 2026-06-18, Demand chapter. https://www.iea.org/reports/global-hydrogen-review-2026/demand. Label: `verified`.
  - "Fuel cell electric vehicle (FCEV) stock grew 20% in 2025, to almost 130 000" "due to truck sales in China and a rebound of car sales in Korea".
  - Policies in those countries are the main driver of a projected tripling of stock by 2030.
  - "trucks and buses accounting for around 60% and 30% of hydrogen use".

**Trucks.**
- **[HYUNDAI-XCIENT-2025]** Hyundai Motor Company, "Hyundai Motor Unveils the New XCIENT Heavy-Duty Fuel Cell Truck at ACT Expo 2025", 2025-04-29. https://www.hyundai.com/worldwide/en/newsroom/detail/hyundai-motor-unveils-the-new-xcient-heavy-duty-fuel-cell-truck-at-act-expo-2025-0000000949. Label: `verified`.
  - Powertrain: "180 kW hydrogen fuel cell system"; "350 kW e-motor … 2,237 Nm"; "72 kWh battery pack".
  - Storage and range: "10 hydrogen tanks (total combined capacity of approximately 68 kg)"; "maximum 450 miles".
  - Fleet: "more than 13 million kilometers of cumulative driving in Switzerland"; deployed in 13 countries.
  - Earlier European version (2021): 2 × 90 kW stacks at 350 bar, about 400 km. Label: `search summary`.
- **[DAIMLER-GENH2-2024]** Daimler Truck press release, 2024-07-25. https://daimlertruck.com/en/newsroom/pressrelease/52775389. Label: `verified`.
  - Five GenH2 trucks in customer trials (Air Products, Amazon, Holcim, INEOS, Wiedmann & Winz).
  - Storage: "88 kilograms (44 kg each)" of liquid hydrogen.
  - Power: "300 kilowatts (2 x150 kW)", plus a battery that adds up to 400 kW for short periods.
  - Range: "1,000 kilometers and more". The September 2023 record run covered "1,047 km with one tank filling of liquid hydrogen".
- Follow-up results. Label: `search summary` (fleet.ie / Truckinginfo).
  - The trials passed 225,000 km, with 285 refuelings and about 15 t of liquid hydrogen.
  - Refueling uses the sLH2 process (subcooled liquid hydrogen, developed with Linde).
- January 2026 (newmobility.news, 2026-01-28). Label: `secondary`.
  - A small series of 100 "NextGenH2" trucks is to reach customers from the end of 2026; Dachser is named as the first customer.
  - Fuel cell: cellcentric BZA150, 300 kW.
  - Series production is pushed to the "early 2030s", with slow liquid hydrogen infrastructure cited as the reason.

**Buses.**
- **[SOLARIS-2025]** Solaris press release "Solaris summarises 2025…", 2026-03-13. https://www.solarisbus.com/en/press/solaris-summarises-2025-sales-growth-strong-position-in-e-mobility-and-expansion-into-new-markets-2410. Label: `verified`.
  - "306 hydrogen buses" delivered in 2025, and "a 58% share in the hydrogen bus segment".
  - In H1 2025, fuel cell buses were about 5.2 % of European zero-emission city bus registrations. Label: `search summary`.
- Solaris Urbino 18 hydrogen (Bus of the Year 2025): 100 kW fuel cell, 8 tanks, 51.2 kg hydrogen. Label: `search summary`.
- **Czechia.**
  - ČEZ press release (2024) on the "largest Czech hydrogen project": 10 Solaris Urbino 12 hydrogen buses near Mníšek pod Brdy (Martin Uher Bus, lines 446/517/688).
  - ČEZ is building a 540 kW electrolyzer powered by the Vrané nad Vltavou hydro plant, with a station for up to 3 buses per hour.
  - Start-up slipped from end-2025 to Q1/Q2 2026 (oenergetice.cz). Label: `search summary`.
  - The first two buses reached the Martin Uher depot on 2025-09-17 (zdopravy.cz, busportal.cz). Label: `search summary`.
  - zdopravy.cz, 2026-06-20 (`secondary`): councillor Petr Borecký said the fleet "se rozjede na linky PID do konce letošního léta" (will start on PID lines by the end of this summer); "Nyní už celé zařízení v Mníšku pod Brdy stojí a finišuje se jeho sestavení." The refueling unit is from Logan Energy.
  - **[EPOCH-CZ-MNISEK-2026]** Epoch Times CZ, "Pilotní vodíkové autobusy v Mníšku ani po třičtvrtě roku stále nevyjely…", 2026-10-12. https://www.epochtimes.cz/ceska-republika/pilotni-vodikove-autobusy-v-mnisku-ani-po-trictvrte-roku-stale-nevyjely-zpozdeni-pry-zazivaji-podobne-projekty-po-cele-evrope-a301028.html. Label: `secondary`.
    - "Vodíkové autobusy v Mníšku pod Brdy však stále nejezdí" (the hydrogen buses still do not run).
    - ČEZ: "Celý systém je zkompletovaný, propojený a postupně probíhá oživování technologie." "Úspěšně proběhly například tlakové zkoušky a zkoušky těsnosti." (The system is complete and connected and is being commissioned; pressure and leak tests passed.)
    - No date set; operator Martin Uher "doufá, že to bude ještě letos" (hopes it will be this year).
  - **So on 2026-10-12, none of the 10 buses was in passenger service.** Nothing later found.
  - Ústí nad Labem DP has a framework contract for up to 20 Urbino 12 hydrogen buses. Label: `search summary`.
  - The Ústí project is suspended: ČTK via oEnergetice.cz, 2025-01-22 (`secondary`). Mayor Petr Nedvědický: "Projekt jsme kvůli rozhodnutí o typu (podporovaného) vodíku, který vydala Evropská komise, museli pozastavit". Spolchemie hydrogen would cost €6–8/kg locally, which he called "ekonomicky nevýhodné" (economically disadvantageous). https://oenergetice.cz/vodik/vodikove-autobusy-v-mhd-v-usti-nad-labem-v-nejblizsi-dobe-nebudou
  - Ostrava (DPO): an older article mentions a tender for a station at Hranečník and 5 hydrogen buses. No delivery was confirmed; Ostrava's recent orders are battery-electric Solaris buses (electrive, 2026-08-08). Label: `search summary`.
  - Litvínov–Most: a hydrogen bus trial ran from 2023-06-29 to 07-09 (Slovak bus maker, 10.5 kg hydrogen, 350 km on hydrogen). Label: `secondary` (CzechCrunch).

---

## 5. Efficiency chain, well-to-wheel, hydrogen "colors"

**[AGORA-SYNCOST-2018]** Agora Verkehrswende and Agora Energiewende, "The Future Cost of Electricity-Based Synthetic Fuels", webinar slides (Deutsch and Maier), 2018-05-16, slide 7, "based on acatech et al. (2017a), Figure 5". https://www.agora-energiewende.org/fileadmin/Projekte/2017/SynKost_2050/Agora_SynCost_Webinar_slides_Deutsch_and_Maier_20180516.pdf. Label: `read from figure`. The values are printed on the figure, so uncertainty is only rounding (±0.5 %).

| Step | BEV | FCEV | e-fuel ICE |
|---|---|---|---|
| Renewable power | 100 % | 100 % | 100 % |
| Transmission | 95 % | 95 % | 95 % |
| Electrolysis | — | 70 % | 70 % |
| Battery charge/discharge | 90 % (→ "Battery use 86 %") | — | — |
| Compression / transport | — | 80 % | — |
| Power-to-liquid / transport | — | — | 70 % / 95 % |
| Fuel cell | — | 60 % | — |
| Internal combustion engine | — | — | 30 % |
| Electric motor | 85 % | 85 % | — |
| Mechanical drivetrain | 95 % | 95 % | 95 % |
| **Total** | **69 %** | **26 %** | **13 %** |

- Slide text: "a combustion-engine vehicle would need about five times as much renewable electricity as a battery-driven vehicle. A fuel cell vehicle needs about two and a half times as much electricity."
- `derived` check:
  - FCEV: 0.95·0.70·0.80·0.60·0.85·0.95 = 0.258.
  - BEV: 0.95·0.90·0.85·0.95 = 0.690.

**[CERULOGY-TE-2017]** C. Malins (Cerulogy), "What role is there for electrofuel technologies in European transport's low carbon future?", report for Transport & Environment, November 2017. https://transportenvironment.org/uploads/files/2017_11_Cerulogy_study_What_role_electrofuels_final_0.pdf. Label: `verified` for the quote. The step assumptions are **not** stated in this document; they come from an earlier T&E source.
- "Transport and Environment (2017) estimate that for representative cases, direct supply of electricity for battery charging delivers an overall 73% efficiency from electricity production to energy use in transport, while use of hydrogen in a fuel cell vehicle delivers only 22% energy efficiency and PtL electrofuels deliver only 13% overall efficiency."

**Bottom-up check from primary DOE and Toyota numbers (`derived`).**

Inputs:
- PEM electrolysis system, 55 kWh/kg ([DOE-PEM-TARGETS], verified).
- Compression, 3.0 kWh/kg, plus precooling, 0.2 kWh/kg ([DOE-REC-9013-2009], verified).
- Mirai consumption, 0.79 kg/100 km WLTP (verified).

Result:
- Electricity per 100 km = 0.79 × (55 + 3.0 + 0.2) = **46.0 kWh/100 km**.
- Delivery transport and station standby losses are excluded.
- A BEV of similar size uses about 15–20 kWh/100 km at the plug. That range is an assumption, not sourced here.
- Ratio ≈ 2.3–3.1×, consistent with Agora's "two and a half times".

**[DOE-PEM-TARGETS]** US DOE HFTO, "Technical Targets for Proton Exchange Membrane Electrolysis", energy.gov, retrieved 2026-11-12 (no page date). https://www.energy.gov/eere/fuelcells/technical-targets-proton-exchange-membrane-electrolysis. Label: `verified`.

| Electrolysis efficiency, kWh/kg H2 (% LHV) | 2022 status | 2026 target | Ultimate |
|---|---|---|---|
| System | 55 (61 %) | 51 (65 %) | 46 (72 %) |
| Stack | 51 (65 %) | 48 (69 %) | 43 (77 %) |

**[ANL-MIRAI-AMR-2018]** H. Lohse-Busch et al. (Argonne), "Technology Assessment of a Fuel Cell Vehicle: 2017 Toyota Mirai", DOE AMR 2018, TV149. https://www.hydrogen.energy.gov/pdfs/review18/tv149_lohsebusch_2018_p.pdf. Label: `verified`.
- "FC Stack peak efficiency 66.0%" and "FC System peak efficiency 63.7%" (UDDS, laboratory data). This is the first-generation Mirai: 114 kW stack, 1.6 kWh battery.
- On a 25 % grade at 72 °F: "peak output of 111.6kW", dropping to about 73 kW after about 6 minutes (thermal derating).
- A DOE Record 20005 (2020) lists the peak system efficiency status as 64 % against a 65 % target (2025) and 70 % ultimate. Label: `search summary`. The PDF was downloaded but not checked line by line.
- Drive-cycle average fuel cell efficiency is lower than peak, because peak efficiency sits at low-to-mid load. The ANL slides show this as a figure. No single cycle-average number was extracted; see Gaps.

**Hydrogen colors and CO2 intensity.**

**[IEA-H2-DEF-2023]** IEA, "Towards hydrogen definitions based on their emissions intensity", April 2023 (for the G7 ministerial), CC BY 4.0. https://www.iea.org/reports/towards-hydrogen-definitions-based-on-their-emissions-intensity. The PDF was read from a mirror. Label: `verified`.
- Natural gas: "Hydrogen production from unabated natural gas results in an emissions intensity in the range of 10-14 kg CO2-eq/kg H2, with upstream and midstream emissions of methane and CO2 in natural gas production being responsible for 1-5 kg CO2-eq/kg H2."
- SMR: "The direct emissions of hydrogen production from natural gas without CCS using steam methane reforming (SMR) are around 9 kg CO2-eq/kg H2 … in total emissions of 11 kg CO2-eq/kg H2" (global median upstream).
- Coal: "Hydrogen production from coal gasification without CCS results in total emissions of 22-26 kg CO2-eq/kg H2".
- Grid electrolysis: "Using the current average global CO2 intensity of 460 g CO2-eq/kWh results in an emissions intensity for hydrogen of 24 kg CO2-eq/kg H2 … as low as 0.5 kg CO2-eq/kg H2 in … Sweden".
  - This is a good slide point: grid electrolysis ("yellow" hydrogen) can be as dirty as coal hydrogen.
- Global average: "The average emissions intensity of global hydrogen production in 2021 was in the range of 12-13 kg CO2-eq/kg H2."
- The IEA proposes defining hydrogen by measured emissions intensity rather than by "colors".
- Production mix: "Natural gas … accounting for 62% of production"; coal "around a fifth".

**[IEA-GHR-2026]** Production chapter. Label: `verified`.
- "Low-emissions hydrogen production reached almost 1 Mt in 2025."
- "Installed electrolysis capacity doubled in 2025 to surpass 4 GW."
- "Global hydrogen production remains dominated by unabated fossil fuels."

---

## 6. Modeling data for a PEM stack (series-hybrid source)

**Faraday consumption (`derived` from constants).**
- ṁ_H2 = I · N_cells · M_H2 / (2F).
- Constants: M_H2 = 2.01588 g/mol, F = 96485.33 C/mol, so M_H2/(2F) = 1.0447×10⁻⁸ kg/(A·s) per cell.
- For N = 330 (Mirai): **3.447×10⁻⁶ kg/s per A = 12.41 g/h per A**.
- Check: at 0.79 kg/100 km, 100 km uses 790 g, which equals 63.7 A·h of stack current.

**Voltage and efficiency (`derived`).**
- LHV 33.3 kWh/kg is the deck's value: 33.3 × 3.6 MJ × 2.01588×10⁻³ kg/mol = 241.7 kJ/mol.
- E_LHV = ΔH/(2F) = **1.253 V**.
- Cell efficiency (LHV) ≈ μ_f · V_cell / 1.253, where μ_f is fuel utilization.
- The reversible voltage at 25 °C, 1.229 V, appears in [PUKRUSHPAN-JDSMC-2004].

**[PUKRUSHPAN-JDSMC-2004]** J. T. Pukrushpan, H. Peng, A. G. Stefanopoulou, "Control-Oriented Modeling and Analysis for Automotive Fuel Cell Systems", *ASME J. Dyn. Sys., Meas., Control* 126 (2004) 14–25. Author copy: https://public.websites.umich.edu/~annastef/papers/Pukrushpan2004JDSMC.pdf. Label: `verified`.

This is a widely used automotive polarization model, parameterized on the **75 kW Ford P2000** stack: "Most of the parameters are based on the 75 kW stacks used in the FORD P2000 fuel cell prototype vehicle".

- Cell voltage: v_fc = E − v_act − v_ohm − v_conc (Eq. 1).
- Open-circuit voltage: E = 1.229 − 8.5×10⁻⁴ (T_fc − 298.15) + 4.3085×10⁻⁵ T_fc [ln p_H2 + ½ ln p_O2] (Eq. 2). T in K, p in atm.
- Activation loss: v_act = v₀ + v_a (1 − e^(−c₁ i)) (Eq. 3). i is in A/cm²; **c₁ = 10**.
  - v₀ and v_a are given as functions of T, p_O2 and p_sat (Eq. 8).
- Ohmic loss: v_ohm = i · R_ohm, with R_ohm = t_m / σ_m (Eqs. 4–5).
  - σ_m = (b₁₁ λ_m − b₁₂) exp[b₂ (1/303 − 1/T_fc)] (Eq. 6).
  - Printed values: **b₁₁ = 0.05139, b₁₂ = 0.00326, b₂ = 350**.
  - λ_m runs from 0 to 14 (0–100 % relative humidity).
- Concentration loss: v_conc = i (c₂ i / i_max)^c₃ (Eq. 7).
  - **c₃ = 2, i_max = 2.2 A/cm²**. c₂ is piecewise in p_O2 and p_sat (Eq. 8).
- Table 1:
  - **n = 381 cells, A_fc = 280 cm²**.
  - **t_m = 0.01275 cm** (Nafion 117).
  - Stack temperature constant at 80 °C. Oxygen excess ratio regulated at 2.
- `derived` ohmic check at T = 353.15 K and λ_m = 14:
  - With the printed b₁₁ = 0.05139: σ = 0.844 S/cm, R_ohm = **0.0151 Ω·cm²**.
  - With b₁₁ = 0.005139: σ = 0.081 S/cm, R_ohm = 0.157 Ω·cm².
  - 0.005139 is the value I recall from the original Springer et al. (1991) correlation, but I did **not** verify it in this session.
  - Check the printed b₁₁ against the thesis (https://public.websites.umich.edu/~annastef/FuelCellPdf/pukrushpan_thesis.pdf) before teaching it.

**Simpler textbook form (Larminie & Dicks, *Fuel Cell Systems Explained*).**
- V = E_oc − r·i − A·ln(i/i₀) − m·exp(n·i).
- The OPEM open-source implementation (Params.py, `Larminiee_Standard_Vector`) uses a 23-cell example with E0 = 1.178 V, A = 0.06 V, RM = 0.0018 Ω, i₀ = 0.00654 A, i_L = 100 A, i_n = 0.23 A, T = 328.15 K. Label: `verified` as code (https://sources.debian.org/src/python-opem/1.4%2Bdfsg-1/opem/Params.py).
  - These are in amperes for a small test stack, not per cm² for an automotive stack.
- The textbook's own constant table (Ballard Mark V vs "typical low-temperature PEMFC") was **not verified**. Take the values from the book itself or from the course deck, which follows Larminie & Lowry.

**Automotive anchor points for calibrating a lumped model (Mirai).**
- 330 cells, 128 kW (Toyota, verified), so 388 W per cell at peak.
- SwRI on-road benchmarking of the Mirai Gen II: "average minimum cell voltage is also around 0.75 ~0.8 volts under 60 mph driving". SwRI also built a polarization curve from a grade test (figure only). Label: `search summary`. Source: https://www.swri.org/what-we-do/internal-research-development/2022/automotive-transportation/gap-analysis-performance-balance-of-plant-control-of-pem-fuel-cells-through-benchmarking-the-toyota-mirai-03-r6171
- First-generation Mirai (ANL): 114 kW stack and 1.6 kWh battery; peak system efficiency 63.7 % (verified).
- A published Mirai 2 polarization curve with cell active area and parameters was **not found** in open access. A Toyota-affiliated paper (J. Electrochem. Soc., doi:10.1149/1945-7111/ac662d) evaluates Mirai 2 stacks at 0.2 and 2.2 A/cm² but is paywalled.

---

## 7. Safety, and trucks vs cars (optional)

**Safety.**
- **[DOE-SAFE-USE]** US DOE HFTO, "Safe Use of Hydrogen". https://www.energy.gov/eere/fuelcells/safe-use-hydrogen. Label: `verified`.
  - "hydrogen has a wide range of flammable concentrations in air"; "lower ignition energy than gasoline or natural gas"; "because hydrogen is much lighter than air, it dissipates rapidly when it is released".
  - Testing listed: "tank leak tests, garage leak simulations, and hydrogen tank drop tests".
- Flammability limits of 4–75 vol % in air and minimum ignition energy of ~0.02 mJ: consistent across NREL's fuel-property comparison and other sources. Label: `search summary`; the NREL PDF (fy09osti/45408) is unreachable.
- Gasoline vapor flammability is about 1.4–7.6 %. Label: `search summary`.
- Tank burst safety factor of 2.25 (US) to 2.35 (EU): [DOE-REC-9013-2009], verified. Current UN R134 / GTR 13 burst ratios were **not** checked.

**Trucks vs cars.**
- Evidence from this note:
  - [IEA-GHR-2026] (verified): stock growth comes from Chinese trucks; trucks and buses account for about 90 % of road hydrogen use.
  - H2 MOBILITY: 350-bar commercial fuelings overtook 700-bar fuelings, and small car stations are closing.
  - Everfuel and Shell refocused on heavy duty.
  - AFIR Art. 6 requires stations to serve both light- and heavy-duty vehicles.
  - Daimler pushed series production to the early 2030s.
- The IEA GHR 2025 notes that heavy trucks are "the only fast-growing market for fuel cell electric vehicles, despite their higher total costs of ownership when compared to battery electric or diesel trucks". Label: `search summary`.
- Counter-evidence for the slide:
  - BEV trucks are also scaling: Ostrava's bus orders are battery-electric.
  - The UK HyHaul hydrogen truck project was canceled for lack of customer commitments (fleetnews). Label: `search summary`.

---

## Gaps

Updated 2026-11-12. Items marked **Closed** or **Partly closed** were worked on in this pass; the evidence sits in the section named.

**Closed**

- **NLR (ex-NREL) station reliability data** (§2, §1.1): the pages moved to nlr.gov and are readable. Dispensers carry 48 % of maintenance events and 36 % of hours (2014Q3–2021Q2, `read from figure`); average real fill 3.22 min over 1,850,493 fills (2014Q3–2022Q2, `verified`). What remains: NLR has published **no reliability data newer than Q2 2022** (page last updated 2025-02-10), so 2024–2026 availability still rests on CARB.
- **3-minute fill target** (§1.1): citable via Argonne/DOE [ANL-J2601-FILLTIME], `verified`: 3 minutes, 70 MPa, T40 station, SOC 90–100 %. The SAE and ISO texts themselves are still unread (paywalled).

**Partly closed**

- **Czech stations and buses** (§3, §4): ORLEN runs 2 public stations and has paused further construction (April 2026, `secondary`), so the three planned stations did not open. The Mníšek buses were still not in service on 2026-10-12 (`secondary`). Ústí's bus project is suspended (January 2025, `secondary`). Still open: a current CZK/kg price (newest is 278 CZK/kg, March 2023), whether Vítkovice and Mstětice still operate, and any Ostrava DPO hydrogen bus.
- **German retail price** (§2): H2 MOBILITY's own release confirms a ~10 % cut from 2026-06-01 at five stations (`verified`), and the hylane truck price of ~€8/kg net from 2026-01-01 (`verified`). Still open: no dated euro-per-kg car price from H2 MOBILITY. h2.live's €12.85 sits in a 2021–22 comparison and is stale; the h2.live live map loads prices by script and was not read.

**Open**

- **H2stations.org / LBST 18th assessment (end-2025 counts)**: not published on LBST's site or found in trade press as of 2026-11-12. World, Europe and Germany figures here remain end-2024. The only end-2025 German figure is 36 public stations closed in 2025 (`secondary`). Check h2stations.org by hand, or the EU H2-Stations map (h2-stations.eu) for a current European count.
- **CEC/CARB joint AB 126 report** (CEC-600-2026-022): energy.ca.gov still refuses automated fetches and no mirror was found. Its Q2 price ($35.47/kg) and ~60 % availability are `search summary` only. Open the PDF by hand to verify before using them.

**Unchanged (not worked in this pass)**

7. **Mirai 70 MPa / Type IV tanks** were not verified from Toyota primary text. The Toyota spec PDF also shows a stack volume of "4 L" that contradicts 5.4 kW/L.
8. **No open-access Mirai 2 polarization curve** with active area was found. The Larminie & Dicks constant table was not verified online. The b₁₁ coefficient in Pukrushpan (2004) may be a misprint and needs checking against the thesis.
9. **Drive-cycle average fuel cell system efficiency** (as opposed to peak) was not extracted as a number.
10. **BEV and petrol per-100-km costs** use placeholder prices. Insert current CZ/DE electricity and fuel prices with sources.
11. **Global sales figures** (SNE Research via Argus/Asiae) disagree on Hyundai (6,861 vs 7,047) and Toyota (1,168 vs 1,257). Treat them as ±3 %.
12. **California station closures in 2026** (True Zero, the "60 % offline" claim) rest on single secondary outlets and are unverified.
