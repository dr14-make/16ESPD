# Battery terms: reference material for the 16ESPD battery-definitions block

Compiled 2026-11-12. All URLs accessed 2026-11-12 unless stated otherwise. Every number carries a source tag and a verification label:

- `verified`: I opened the primary page or PDF and the quote comes from it.
- `read from figure`: read off a plot, with ± uncertainty.
- `secondary`: seen only in news, an aggregator, a teardown blog, or a vendor summary.
- `search summary`: seen only in a search-engine snippet. Treat it as a lead, not a citation.
- `derived`: arithmetic done here from the stated inputs. The arithmetic is shown.

This note does not repeat what `teaching_materials.md` and `charging.md` already source: Leaf 40 kWh gross / 39 kWh usable, 96s2p 192 cells, 350 V, 303 kg pack (≈ 132 Wh/kg), Leaf DC peak 46 kW, Leaf motor 110 kW peak / 85 kW rated, 2013 Leaf 103.3 kW 30 s pack power (INL), IONIQ 5 263 kW peak / 18 min 10–80 % / 80.0 kWh usable (EVDB), Geotab 2.3 %/yr. Those values are used below only as inputs to `derived` numbers, and they keep their original labels.

---

## Headline numbers (for slides)

| Number | What | Source | Label |
|---|---|---|---|
| "C/3 Rate … for a three-hour discharge"; 40 Ah → 13.3 A | Definition of a C-rate (USABC/INL EV test manual) | [USABC-EV-2025] | verified |
| DOD = "percentage of a device's operating capacity (Ah) removed by discharge" | Definition of depth of discharge | [USABC-EV-2025] | verified |
| SOH = metric "expressed as a percentage of the performance … when certified or new" | Legal definition of state of health, Euro 7 Art. 3(67) | [EU-2024-1257] | verified |
| SOCE = "percentage of useable battery energy" | On-board State of Certified Energy, the Euro 7 SOH monitor | [EU-2025-1707] | verified |
| 80 % to 5 yr / 100,000 km; 72 % to 8 yr / 160,000 km | Euro 7 minimum battery-energy durability, M1 BEV and PHEV | [EU-2024-1257] Annex II | verified |
| 75 % / 67 % | Same thresholds for vans (N1) | [EU-2024-1257] Annex II | verified |
| New M1 types from 29 Nov 2026; all new M1 from 29 Nov 2027 | When Euro 7 battery durability applies | [EU-2024-1257] Art. 10 | verified |
| 80 % at 5 yr / 62,000 mi; 70 % at 8 yr / 100,000 mi | US EPA version (GTR 22-based); section since removed from the eCFR | [40CFR-86.1815-27] | verified (2025 text) |
| 30 s peak discharge, 10 s peak regen; 15-year calendar life target | How USABC defines peak power and the life target | [USABC-EV-2025] | verified |
| 478 kW peak vs 159 kW 30-min power | IONIQ 5 N (84 kWh): peak vs continuous, factor 3.0 | [HYU-IT-I5N] | verified / derived (ratio) |
| 84.0 kWh, 697 V, 120.6 Ah | IONIQ 5 Long Range (2024+) pack, Hyundai Korea spec sheet | [HYU-KR-SPEC] | verified |
| SK On, pouch, NCM; pack by Hyundai Mobis | IONIQ 5 84 kWh cell maker, format, cathode | [HYU-KR-CELL] | verified |
| 384 cells / 32 modules, 697 V, 84 kWh | IONIQ 5 N pack (same 84 kWh / 697 V / 120.6 Ah pack) | [HYU-AU-ERG-I5N] | verified |
| 192s2p, 12 cells/module, 60.3 Ah, 3.63 V, ≈ 219 Wh per cell | IONIQ 5 84 kWh cell level | from the three rows above | derived |
| 360 cells / 30 modules, 653 V, 72.6 kWh | First IONIQ 5 Long Range (2021) for comparison | [HYU-AU-ERG-2021] | verified |
| 56.3 Ah, 3.65 V, 914 g, 224 Wh/kg, 460 Wh/L | AESC "High Energy Type" EV cell (the Leaf 40 kWh cell) | [AESC-EV-2019] | verified (archived page); Leaf attribution secondary [MOTORFAN-2017] |
| 8 cells, "2 parallel, 2 series X 2 units", 8.7 kg | AESC EV module | [AESC-EV-2019] | verified (archived page) |
| 24 modules (96s / 4s per module) | Leaf 40 kWh module count | [AESC-EV-2019] + 96s2p | derived; 24 × 8 also secondary [PUSHEVS-2018] |
| 225 Wh/kg cell → 130–132 Wh/kg pack (58 %) | Leaf 40 kWh cell-to-pack gravimetric ratio | [AESC-EV-2019], 303 kg | derived |
| 1.15–1.17 C (peak), 1.0 C (average) | Leaf 40 kWh DC charge C-rate | 46 kW, 40 kW avg | derived |
| 3.1 C (peak), 2.3 C (average) | IONIQ 5 84 kWh DC charge C-rate | 263 kW, 196 kW avg | derived |
| 97.5 % (Leaf), 95.2 % (IONIQ 5) | Usable / gross energy | 39/40, 80/84 | derived (secondary inputs) |
| 8 yr / 160,000 km, "moins de 9 barres sur 12" | Nissan EU (Belgium) Leaf battery capacity warranty | [NISSAN-BE] | verified |
| "pod čiarku 9 (z 12)" | Nissan Slovakia (MY2021 Leaf price list), same threshold | [NISSAN-SK-2021] | verified |
| 8 yr / 160,000 km, SoH ≥ 70 % | Hyundai EU high-voltage battery warranty | [HYU-EU-WARRANTY] | verified |
| LFP 2,500–9,000 EFC vs NMC 200–2,500 EFC to 80 % | Commercial 18650 cells, Sandia, same test matrix | [PREGER-2020] | verified |
| NMC 25 °C: ≈ 2,150 EFC (40–60 %), ≈ 1,650 (20–80 %), ≈ 450 (0–100 %) | Cycle life vs SoC window, 0.5C/1C | [PREGER-2020] Fig. 2a | read from figure (±10 %) |
| NMC 0–100 %, 1C: ≈ 170 (15 °C), ≈ 430 (25 °C), ≈ 640 (35 °C) EFC | Cycle life vs temperature | [PREGER-2020] Fig. 2a | read from figure (±10 %) |
| NMC 25 °C storage, 10 months: ≈ 2.5 % lost at 50 % SoC vs ≈ 6.5 % at 100 % SoC | Calendar ageing vs SoC | [KEIL-2016] Fig. 2b | read from figure (±1 point) |
| NMC 50 °C storage, 10 months: ≈ 12 % at 50 % SoC vs ≈ 23 % at 100 % SoC | Calendar ageing vs temperature | [KEIL-2016] Fig. 2b | read from figure (±1 point) |
| "ca. 0.2 percentage points of capacity fade per month at 25°C" | LFP calendar fade rate | [KEIL-2016] | verified |

---

## 1. IONIQ 5 84 kWh pack (2024+)

### Sources

**[HYU-KR-SPEC]** Hyundai Motor Korea, *더 뉴 아이오닉 5 (2027년형) 제원표* (IONIQ 5 MY2027 specification sheet), https://www.hyundai.com/contents/repn-car/catalog/spec/ioniq5-27my-spec.pdf. Label: `verified`.

- Column "축전지 정격전압(V) / 용량(Ah)" (battery rated voltage / capacity): "Long Range 2WD … 697 / 120.6", "Long Range AWD … 697 / 120.6", "Standard 2WD 523 / 120.6".
- "배터리 종류 리튬 이온" (battery type: lithium-ion); "배터리 용량(kWh) 63.0 84.0".
- Maximum power: Long Range 2WD "168 / 229" kW/PS; AWD "239 / 325" (combined front + rear).
- Curb mass Long Range 2WD 19″: 2,015 kg; AWD 19″: 2,120 kg. Footnote: figures are Korean Ministry (산업부) certification values.
- Korea-only side note: "고전압배터리 : 10년 20만km" (high-voltage battery: 10 years / 200,000 km), listed in the subsidy section. The EU warranty is different (§3).
- `derived`: 697 V × 120.6 Ah = 84.06 kWh, consistent with 84.0 kWh. 523 V × 120.6 Ah = 63.07 kWh for the 63 kWh pack, so both packs use the same Ah and differ in series count.

**[HYU-KR-CELL]** Hyundai Motor Korea, *전기차 배터리 셀 정보* (EV battery cell information), https://www.hyundai.com/kr/ko/service-membership/ev/ev-battery-cell-information. Label: `verified`.

- Row: "더 뉴 아이오닉 5 롱레인지 2WD | 84.0 | 697 | 168 / 4,600 | SK ON | 파우치형 | NCM | 현대모비스 | 국내". Columns: pack energy (kWh), pack rated voltage (V), motor max power (kW/rpm), cell maker, cell format (pouch), cell main material (NCM), battery (pack) maker (Hyundai Mobis), country of production (Korea).
- The AWD and the IONIQ 5 N rows read the same (84.0 kWh, 697 V, SK ON, pouch, NCM). Standard 2WD: 63.0 kWh, 523 V, SK ON, pouch, NCM.

**[HYU-AU-ERG-I5N]** Hyundai Motor Company Australia, *IONIQ 5 N Emergency Response Guide*, https://hyundai.com/content/dam/hyundai/au/en/documents/Hyundai_Emergency_Response_Guide_IONIQ_5_N.pdf. Label: `verified`.

- High-voltage battery table: "Rated Voltage (V) 697", "Energy (kWh) 84", "Quantity for Pack (Cell/Module) 384 cells/32 modules".
- I found no Hyundai document that gives the cell count for the non-N 84 kWh car. The N uses the same 84.0 kWh / 697 V / SK On pouch pack per [HYU-KR-CELL] and the same 120.6 Ah per [HYU-IT-I5N], so 384 cells for the regular Long Range is an inference, not a quote.

**[HYU-AU-ERG-2021]** Hyundai Motor Company Australia, *IONIQ 5 Emergency Response Guide* (2021), https://hyundai.com/content/dam/hyundai/au/en/documents/IONIQ_5_Emergency_Response_Guide_2021.pdf.pdf. Label: `verified`.

- "Type Lithium-ion polymer"; "Rated Voltage (V) Extended : 653 / Economical : 588"; "Energy (kWh) Extended : 72 / Economical : 58"; "Quantity for Pack (Cell / Module) Extended : 360 cells / 30 modules, Economical : 288 cells / 24 modules".

**[HYU-IT-I5N]** Hyundai Italia, *Caratteristiche Tecniche HYUNDAI IONIQ 5 N, 84 kWh AWD*, dated 2024-01-04 (file name), https://dmassets.hyundai.com/is/content/hyundaiautoever/20240104_Scheda+Tecnica+Hyundai+IONIQ+5+N+1pdf. Label: `verified`.

- "Capacità batteria kWh 84"; "Batteria Ah 120,6"; "Massa a vuoto kg 2.275".
- "Potenza max. kW (CV) 478 (650)"; "Potenza max. a 30min kW (CV) 159 (216)". This is the peak vs 30-minute (continuous) power used in §6.

**[INSIDEEVS-2021]** InsideEVs, "Hyundai Ioniq 5 Battery Cells Exposed", 2021-10-28, https://insideevs.com/news/543792/hyundai-ioniq5-battery-cells-exposed/. Label: `secondary` (reports the BASTRO teardown of the 72.6 kWh pack).

- "One module consists of 12 pouch cells and stores about 2.4 kWh of energy." Lists 77.4 kWh as 32 modules / 384 cells.
- "most likely high-nickel NCM chemistry" for the SK On cells. [HYU-KR-CELL] now confirms NCM for the 84 kWh pack.

### Cell-level numbers (`derived`)

- Cells per module: 384 / 32 = 12, matching the teardown's 12 pouch cells per module.
- Series count: with the SK On cell at ≈ 3.63 V nominal, 697 V / 3.63 V ≈ 192 series. 384 cells / 192 = **2 parallel**, so **192s2p**. Nominal cell voltage 697 / 192 = 3.630 V.
- Cell capacity: 120.6 Ah / 2 = **60.3 Ah**. Cell energy: 84,000 Wh / 384 = **218.8 Wh** (3.63 V × 60.3 Ah = 218.9 Wh).
- 2021 Long Range check: 653 V / 3.63 V ≈ 180s; 360 cells / 180 = 2p, also 2p.
- 63 kWh pack: 523 V / 3.63 V ≈ 144s. If it is also 2p, that is 288 cells. Not checked against a Hyundai document.
- The 3.63 V cell voltage itself is an assumption (it makes the series count an integer). No Hyundai or SK On document read gives the cell voltage or cell Ah directly.

### Gross vs usable, mass

- Gross 84.0 kWh `verified` [HYU-KR-SPEC]. Usable 80.0 kWh is EVDB (`secondary`, in `charging.md`). `derived`: 80.0 / 84.0 = **95.2 %** usable, i.e. ≈ 4 kWh (≈ 5 %) kept as buffer. Hyundai does not publish a usable figure in any document I read.
- **Pack mass: not found from a primary source.** Third-party spec sites list 477 kg for the 84 kWh pack (auto-data.net, carsart.net, `search summary`), and carsales.com.au gives 477.1 kg for the 77.4 kWh pack in the Kia EV6 (`search summary`). Without a primary mass, no cell or pack Wh/kg is given for the IONIQ 5. If the 477 kg is used, 84.0 / 477 = 176 Wh/kg pack-level, `derived` from a `search summary` input.

---

## 2. Nissan Leaf ZE1 40 kWh: AESC cell and module

### Sources

**[AESC-EV-2019]** Automotive Energy Supply Corporation (AESC), "Cell, Module, and Pack for EV Applications", product page, Wayback Machine snapshot of 2019-01-02: https://web.archive.org/web/20190102230029/http://www.eco-aesc-lb.com/en/product/liion_ev/. Label: `verified` (manufacturer's own page, archived copy; the live domain no longer serves it).

- Cell, "General specifications": "Cell Type High Energy Type", "Rated Capacity* 56.3Ah", "Nominal Voltage* 3.65V", "Length 261mm Width 216mm Thickness 7.91mm", "Mass 914g", "Energy Density 460Wh/L 224Wh/kg".
- "*Definition of terms is according to IEC 62660-1."
- Module: "The modules for EV are formed by connecting 8 cells and then encaced in a metal case." "Number of Cells 8", "Configuration 2 parallel, 2 series X 2 units", "Length 300mm … Width 222mm Height 68mm", "Mass 8.7 kg".
- The page's pack block ("Number of Modules 48 … 360V … 24kWh") is inside HTML comment markers in the snapshot, i.e. the old 24 kWh pack that was no longer shown. The page does not name the Leaf or the cathode chemistry.

**[MOTORFAN-2017]** MotorFan (no individual byline), "日産リーフe+のリチウムバッテリーの構造 一体なにが進化したのか？", first published 2017-10-01, updated 2026-07-10, https://motor-fan.jp/article/1530473/. Label: `secondary`.

- Attributes the same cell to the 40 kWh Leaf: "電圧：3.65V", "容量：56.3Ah", "長さ261×幅216×厚7.91mm", "重さ：914g", and "電圧350V、容量40kWh、192セル" for the pack. Says the current Leaf moved to 8-cell modules.

**[PUSHEVS-2018]** P. Lima, "2018 Nissan Leaf battery real specs", PushEVs, 2018-01-29, https://pushevs.pages.dev/2018/01/29/2018-nissan-leaf-battery-real-specs. Label: `secondary`.

- "In the Nissan Leaf, each battery pack has 24 modules and each module has 8 cells." Gives NCM 523 as chemistry and "192 x 3,65 V x 56,3 Ah = 39,46 kWh". The chemistry is not confirmed by AESC or Nissan in anything I read.

### Leaf numbers (`derived`)

- 56.3 Ah confirmed by the cell maker's own page [AESC-EV-2019]. That this is the Leaf ZE1 cell rests on [MOTORFAN-2017] plus three consistency checks: 350 V / 96 = 3.646 V ≈ 3.65 V; 192 × 3.65 V × 56.3 Ah = **39.46 kWh** ≈ 40 kWh; the module is 2p4s, and 96s / 4s = 24 modules × 8 cells = 192 cells.
- Module count: **24** (96s ÷ 4s per module).
- Cell energy 3.65 V × 56.3 Ah = 205.5 Wh. Cell specific energy 205.5 Wh / 0.914 kg = **224.8 Wh/kg** (AESC states 224). Volume 261 × 216 × 7.91 mm = 0.446 L, so 205.5 Wh / 0.446 L = 461 Wh/L (AESC states 460).
- Cell mass in the pack: 192 × 0.914 kg = **175.5 kg**, which is 175.5 / 303 = **58 %** of the 303 kg pack.
- Module mass in the pack: 24 × 8.7 kg = **208.8 kg** (69 % of the pack). The remaining ≈ 94 kg is enclosure, busbars, wiring, BMS and junction box.
- Pack specific energy: 39.46 kWh / 303 kg = **130 Wh/kg** (132 Wh/kg with the rounded 40 kWh). Cell-to-pack gravimetric ratio 130 / 225 = **0.58**: the pack keeps 58 % of the cell's Wh/kg.
- Pack capacity: 2 × 56.3 = 112.6 Ah at 350 V.
- Usable / gross: 39 / 40 = **97.5 %** (both `secondary` per `teaching_materials.md`).

---

## 3. Battery warranties

**[NISSAN-BE]** Nissan Belgique, "Nissan Charge" (vehicles électriques), https://fr.nissan.be/experience-nissan/vehicules-electriques/nissan-charge.html. Label: `verified`.

- Footnote 1: "La garantie Nissan sur l'état de la batterie lithium-ion couvre la perte de capacité de la batterie (moins de 9 barres sur 12), telle qu'affichée sur l'indicateur de capacité du véhicule, sur une période de 8 ans ou sur 160 000 kilomètres". The same page's footnote 2 refers to "la batterie de 39 kWh", i.e. the 40 kWh Leaf.

**[NISSAN-SK-2021]** Nissan (importer Grand Automotive CE Kft.), *NISSAN LEAF, Modelový rok 2021, Cenník*, prices valid from 2021-04-06, dealer-hosted: https://www.autostyl.sk/data/documents/cennik-nissan-leaf-3poer.pdf. Label: `verified` (dealer-hosted copy of the importer's price list).

- "Záruka kapacity článkov batérie je zárukou proti poklesu kapacity pod čiarku 9 (z 12) na ukazovateli kapacity batérie." (The cell capacity warranty covers a drop below bar 9 of 12 on the capacity gauge.) The years/km rows of this list did not extract as text.
- The Czech 2018 Leaf brochure (https://www.autobond.cz/wp-content/uploads/2018/01/NEW_LEAF_CZ.pdf) has the row "Záruka na baterie Nissan" with a check mark but its footnote text did not extract. Czech-specific years/km are therefore not verified; fdrive.cz reports 8 years / 160,000 km and "nad 70 %" (`search summary`).
- Nissan Ireland's warranty page ([NISSAN-IE], https://www.nissan.ie/ownership/nissan-services/nissan-warranties.html, `verified`) lists the "EV LITHIUM-ION BATTERY STATE OF HEALTH GUARANTEE" as "8 years warranty/unlimited mileage" for passenger cars and "8 years warranty or until 160,000 KMs" for vans, and the "EV DEDICATED COMPONENTS WARRANTY" (incl. the battery against defects) as "5 years warranty/unlimited mileage". Terms differ by country.
- **Bars to percent: not verified.** That 9 of 12 bars equals ≈ 70 % of new capacity appears only in press and forum sources (`search summary`). Nissan does not state a percentage in any page read.

**[HYU-EU-WARRANTY]** Hyundai Motor Europe, "Warranty", https://www.hyundai.com/eu/about-hyundai/our-cars/warranty.html. Label: `verified`.

- "The high-voltage batteries in our fuel-cell electric, electric, hybrid, and plug-in hybrid cars are covered for 8 years, or up to 160,000 km and additionally, High Voltage battery warranty covers Battery EV vehicle repairs needed for to return the battery State of Health (capacity) to at least 70% of its original state" (Hyundai's wording, including "for to").
- Hyundai Europe's maintenance page names the IONIQ 5 with an 8-year / 160,000 km battery warranty (https://www.hyundai.com/eu/electrification/owning-an-electric-vehicle/maintenance-service.html, `search summary`). UK mileage is 125,000 mi (`secondary`, Auto Express).

`derived` comparison for the slide: Hyundai's EU warranty floor (70 % SoH at 8 yr / 160,000 km) is 2 points below the Euro 7 legal minimum for new types (72 % SOCE at the same age, §4). Nissan's 9-of-12-bar floor is expressed on the dashboard gauge, not as a percentage.

---

## 4. Regulation: battery durability, SOH and SOCE

**[EU-2024-1257]** Regulation (EU) 2024/1257 of the European Parliament and of the Council of 24 April 2024 (Euro 7), OJ L, 8.5.2024. Read via the Publications Office: http://publications.europa.eu/resource/celex/32024R1257 (EUR-Lex: https://eur-lex.europa.eu/eli/reg/2024/1257/oj). Label: `verified` (original OJ text; later consolidations, e.g. the 2026-09-02 version listed on EUR-Lex, were not checked).

- Art. 3(66): "'battery durability' means in-vehicle durability of a traction battery measured in terms of its state of health;"
- Art. 3(67): "'state of health' or 'SOH' means the measured or estimated state of a specific performance metric of a vehicle or traction battery at a specific point in its lifetime, expressed as a percentage of the performance that was determined when certified or new;"
- Recital 33: "Whilst the term 'state of health' (SOH) is commonly applied … that term is not commonly defined and is determined through a variety of different methodologies, such as the 'State of Certified Energy' and the 'State of Certified Range'. Both metrics represent a percentage of the certified battery energy or electric range remaining at a given point in time."
- Art. 6(1): manufacturers shall ensure that vehicles "comply with the minimum performance requirements on battery durability as set out in Annex II."
- Annex II, Table 1, "Euro 7 Minimum performance requirements (MPR) for battery durability for vehicles of category M1", battery energy based MPR: "Start of life to 5 years or 100 000 km whichever comes first": OVC-HEV 80 %, PEV 80 %; "Vehicles more than 5 years or 100 000 km, and up to whichever comes first of 8 years or 160 000 km": OVC-HEV 72 %, PEV 72 %. The range-based MPR rows are empty in the OJ text.
- Annex II, Table 2 (N1): 75 % and 67 % for the same two periods.
- Art. 10(4): "With effect from 29 November 2026, approval authorities shall, in the case of new types of vehicles of category M1 or N1 which do not comply with this Regulation, refuse to grant … type-approval … on grounds relating to … battery durability." Art. 10(5): from 29 November 2027 for all new M1/N1 registrations.

**[EU-2025-1707]** Commission Implementing Regulation (EU) 2025/1707 of 25 July 2025 (OBFCM/OBM methods under Euro 7), OJ L, 5.9.2025, http://publications.europa.eu/resource/celex/32025R1707. Label: `verified`.

- Annex I, Appendix 5 "Battery durability parameters", ref. 5.1: "On-board SOCE value | On-board estimate of battery performance expressed as a percentage of useable battery energy | % | 0/100". Ref. 5.2: "On-board SOCR value | On-board estimate of battery performance expressed as a percentage of the certified electric range of the vehicle".
- The OBM data table labels the same parameter "Traction battery state of health (SOCE)". So in EU law the SOH reported to the driver and checked against the 80 %/72 % MPR is SOCE: usable energy now ÷ certified usable energy.

**[40CFR-86.1815-27]** US EPA, 40 CFR § 86.1815-27 "Battery-related requirements for battery electric vehicles and plug-in hybrid electric vehicles", eCFR point-in-time text of 2025-01-01: https://www.ecfr.gov/api/versioner/v1/full/2025-01-01/title-40.xml?part=86&section=86.1815-27. Label: `verified` (2025 text).

- "battery electric vehicles and plug-in hybrid electric vehicles must meet requirements related to batteries … from GTR No. 22"
- "(c) Evaluate SOCE based on measured Usable Battery Energy (UBE) values."
- "(e) … measured usable battery energy is at least 80 percent of the vehicle's certified usable battery energy after 5 years or 62,000 miles, and at least 70 percent of certified usable battery energy at 8 years or 100,000 miles."
- The eCFR version history lists this section as **removed with effect from 2026-04-20** (https://www.ecfr.gov/api/versioner/v1/versions/title-40.json?part=86&section=86.1815-27). Present it as the GTR 22 numbers in US units, not as a current US requirement.

**UN GTR No. 22 itself (ECE/TRANS/180/Add.22, adopted by WP.29 on 9 March 2022): not read.** unece.org and wiki.unece.org returned a Cloudflare challenge. The 80 % / 72 % (M1) GTR thresholds are confirmed indirectly: Euro 7 transposes them and the EPA text cites GTR 22. GTR 22's own SOCE definition text is `search summary` only: "the ratio of the currently usable energy … to its certified usable energy".

---

## 5. Cycle life vs DoD, C-rate and temperature; calendar ageing

**[PREGER-2020]** Y. Preger, H. M. Barkholtz, A. Fresquez, D. L. Campbell, B. W. Juba, J. Roman-Kustas, S. R. Ferreira, B. Chalamala, "Degradation of Commercial Lithium-Ion Cells as a Function of Chemistry and Cycling Conditions", *J. Electrochem. Soc.* 167 (2020) 120532, doi:10.1149/1945-7111/abae37, SAND2020-8433J. Accepted manuscript on OSTI: https://www.osti.gov/pages/servlets/purl/1650174. Label: `verified` (accepted manuscript; the published version was not compared).

- Cells: "LFP from A123 Systems (Part #APR18650M1A, 1.1Ah), NCA from Panasonic (Part #NCR18650B, 3.2Ah), and NMC from LG Chem (Part #18650HG2, 3Ah)". The NMC cathode is "a Ni-enriched variant of NMC811". These are 18650 consumer/power-tool cells, not automotive pouch cells.
- Protocol: "All cells were charged at a rate of 0.5C"; the C-rate varied in the matrix is the *discharge* rate (0.5C, 1C, 2C, 3C). SoC windows 40–60 %, 20–80 %, 0–100 %; temperatures 15, 25, 35 °C. End point "80% of initial capacity". "one EFC is based on the nominal capacity of the cell", so EFC already normalizes for the window width.
- "The LFP cells exhibit substantially longer cycle life spans under the examined conditions: 2500 to 9000 EFC versus 250 to 1500 EFC for NCA cells and 200 to 2500 EFC for NMC cells. Most of the LFP cells had not reached 80% capacity by the conclusion of this study" (their bars are extrapolated).
- "the SOC range affects % capacity for the NCA and NMC cells similarly (5-10% lower at 0-100%), but SOC range has little effect on the capacity for LFP cells."
- Temperature: Table 3 ranks fade for this work as LFP "15> 25 > 35" (least fade at 15 °C) and NMC "35> 25 > 15" (least fade at 35 °C). The text: "Studies of NMC cells consistently indicate a tipping point around 35°C", and "the 30°C gap in preferred conditions for LFP and NMC cells has implications for best practices in battery thermal management".
- On energy: "The performance differences between the three chemistries were minimized once the analysis factored in the lower capacity and voltage of the LFP cells".

`read from figure`, Fig. 2a (EFC to 80 % capacity, bar = mean of ≥ 2 cells; ±10 % reading error, more where individual cells scatter):

| Chemistry | Condition | EFC to 80 % | Note |
|---|---|---|---|
| NMC | 40–60 %, 25 °C, 0.5C | ≈ 2,150 | measured |
| NMC | 20–80 %, 25 °C, 0.5C | ≈ 1,650 | measured, cells spread ≈ 800–2,100 |
| NMC | 0–100 %, 25 °C, 0.5C | ≈ 450 | measured |
| NMC | 40–60 %, 25 °C, 3C | ≈ 2,550 | measured |
| NMC | 20–80 %, 25 °C, 3C | ≈ 1,250 | measured |
| NMC | 0–100 %, 15 / 25 / 35 °C, 1C | ≈ 170 / ≈ 430 / ≈ 640 | measured |
| NMC | 0–100 %, 15 / 25 / 35 °C, 2C | ≈ 180 / ≈ 750 / ≈ 640 | measured |
| LFP | 40–60 %, 25 °C, 0.5C | ≈ 7,800 | extrapolated |
| LFP | 20–80 %, 25 °C, 0.5C | ≈ 7,200 | extrapolated |
| LFP | 0–100 %, 25 °C, 0.5C | ≈ 6,400 | extrapolated |
| LFP | 20–80 % / 0–100 %, 25 °C, 3C | ≈ 3,500 / ≈ 3,500 | measured |
| LFP | 0–100 %, 15 / 25 / 35 °C, 1C | ≈ 8,800 / ≈ 7,200 / ≈ 4,500 | extrapolated |

`derived`, for the slide: at 25 °C and 0.5C discharge the NMC cell gave ≈ 4.8× more equivalent full cycles in a 40–60 % window than in 0–100 % (2,150 / 450), and ≈ 3.7× in 20–80 % (1,650 / 450). LFP showed little window dependence. Warn that the NMC temperature trend (35 °C better than 15 °C) is the reverse of LFP and partly reflects lithium plating at 15 °C during charge.

**[KEIL-2016]** P. Keil, S. F. Schuster, J. Wilhelm, … R. C. Karl, A. Jossen (full author list not checked), "Calendar Aging of Lithium-Ion Batteries: I. Impact of the Graphite Anode on Capacity Fade", *J. Electrochem. Soc.* 163 (2016) A1872–A1880, doi:10.1149/2.0411609jes, open access CC BY. Article HTML: https://iopscience.iop.org/article/10.1149/2.0411609jes; Fig. 2: https://content.cld.iop.org/journals/1945-7111/163/9/A1872/revision1/A1872fig2.jpeg. Label: `verified` (publisher HTML and figure; the PDF was blocked).

- Cells (Table I): NCA Panasonic NCR18650PD 2.8 Ah; NMC Sanyo UR18650E 2.05 Ah; LFP A123 APR18650M1A 1.1 Ah. Stored at 16 SoCs from 0 to 100 %, "at storage temperatures of 25°C, 40°C, and 50°C", "after a storage period of 9–10 months".
- "plateau regions, covering SoC intervals of more than 20%–30% of the cell capacity" with similar fade.
- LFP: "ca. 0.2 percentage points of capacity fade per month at 25°C."
- "To maximize battery life, lithium-ion cells should not be stored at high SoC corresponding to low anode potential."
- `read from figure`, Fig. 2a–c (relative capacity after storage, ±0.01):
  - NMC, 10 months: 25 °C ≈ 0.975 at 30–55 % SoC, ≈ 0.945 at 70–90 %, ≈ 0.935 at 100 %. 50 °C ≈ 0.88 at 50 %, ≈ 0.83 at 80–95 %, ≈ 0.77 at 100 %.
  - NCA, 10 months: 25 °C ≈ 0.97 at 50 %, ≈ 0.95 at 80 %, ≈ 0.945 at 100 %. 50 °C ≈ 0.925 at 50 %, ≈ 0.87 at 100 %.
  - LFP, 9 months: 25 °C ≈ 0.97 at 50 %, ≈ 0.94 at 80–100 %. 50 °C ≈ 0.88 at 50 %, ≈ 0.85 at 100 %.
- `derived` per-year values, assuming linear fade (calendar fade usually slows roughly with √t, so linear scaling overstates it): NMC at 25 °C ≈ 3 %/yr at 50 % SoC vs ≈ 8 %/yr at 100 % SoC; at 50 °C ≈ 14 %/yr vs ≈ 28 %/yr. These numbers include the initial loss of a fresh cell and are for 2010s consumer 18650 cells, so they are an upper bound for a modern EV cell. The fleet value is ≈ 2.3 %/yr total (Geotab, in `charging.md`).

---

## 6. Definitions: C-rate, DoD, SoH, peak vs continuous power

**[USABC-EV-2025]** USABC / Idaho National Laboratory, *Battery Test Manual for Electric Vehicles, Revision 4*, INL/MIS-25-83864, October 2025, https://uscar.org/download/247/usabc-manuals/16391/electric-vehicle-test-manual.pdf. Label: `verified`. (Revision 3.1, INL/EXT-15-34184, October 2020, is at https://cet.inl.gov/ArticleDocuments/USABCElectricVehicleTestManualRev3.1.pdf; not opened.)

- Glossary: "C/3 Rate [A]– a current corresponding to the manufacturer's rated capacity (in ampere-hours) for a three-hour discharge at BOL and 30°C between Vmax100 and Vmin0. For example, if the battery's rated capacity is 40Ah, then the C/3 rate is 13.3A."
- "Rated Capacity [Ah] – the useable capacity at a C/3 rate over the full electrochemical range of the device between Vmax100 and Vmin0."
- "Depth-of-Discharge (DOD) [%]– the percentage of a device's operating capacity (Ah) removed by discharge relative to a fully charged condition, normally referenced to a constant current discharge at the C/3 rate."
- "State- of-Charge (SOC) [%] – an estimate of the device charge capability expressed as a percentage of the BOL rated or operating capacity".
- "End-of-Life (EOL) – a condition reached when the device under test is no longer capable of meeting the targets such as the Power Target and Useable Energy Target."
- "Maximum Rated Pulse Discharge Current (ImaxD)[A] – the maximum discharge current that a manufacturer will permit to be sustained by a device for 30 seconds or less." Regen is the same "for 10 seconds or less".
- Table 1 (EV targets, end of life, 30 °C): peak discharge specific power "(30 sec)" 800/700/600 W/kg; "Calendar Life Years 15 15 15"; DST cycle life 750 / 1000 / 2000 cycles with 25–100 % fast charge; fast charge "80% UETarget in 10 min".
- The manual defines no "state of health" term. Use the Euro 7 legal definition (§4) for SoH.

**SoH**: Euro 7 Art. 3(67) [EU-2024-1257], quoted in §4, `verified`. The legally reported SoH metric is SOCE [EU-2025-1707].

**Peak vs continuous (30-minute) power.**

- UN Regulation No 85 defines "'Maximum 30 minutes power' means the maximum net power of an electric drive train at DC voltage … which a drive train can deliver over a period of 30 minutes as an average" (OJ L 323, 7.11.2014, pp. 52–90). Label: `search summary`. The text came from a third-party reproduction (lexaris.de); EUR-Lex and UNECE did not serve the document.
- Car example `verified`: IONIQ 5 N 478 kW peak vs 159 kW for 30 min [HYU-IT-I5N]. Leaf ZE1 110 kW peak vs 85 kW rated (in `teaching_materials.md`).

### C-rates of the reference cars (`derived`)

C-rate here = current ÷ pack Ah. When the current is unknown it is approximated as power ÷ energy (h⁻¹), which equals the current-based C-rate at nominal voltage.

| Car | Event | Arithmetic | C-rate |
|---|---|---|---|
| Leaf 40 kWh | DC charge peak 46 kW | 46,000 W / 350 V = 131 A; 131 / 112.6 Ah | 1.17 C (46/40 = 1.15 h⁻¹) |
| Leaf 40 kWh | DC charge average 10–80 %, 40 kW | 40 / 40 | 1.0 C |
| Leaf 40 kWh | Motor peak 110 kW | 110,000 / 350 = 314 A; 314 / 112.6 | 2.8 C (2.75 h⁻¹) |
| Leaf 40 kWh | Motor rated 85 kW | 85 / 40 | 2.1 C |
| IONIQ 5 84 kWh | DC charge peak 263 kW | 263,000 / 697 V = 377 A; 377 / 120.6 Ah | 3.1 C (3.3 per usable 80 kWh) |
| IONIQ 5 84 kWh | DC average 10–80 %, 196 kW | 196 / 84 | 2.3 C |
| IONIQ 5 84 kWh | Check: 70 % of 80 kWh in 18 min | 56 kWh / 0.3 h | 187 kW into the battery |
| IONIQ 5 84 kWh | Motor peak, RWD 168 kW / AWD 239 kW | 168 / 84; 239 / 84 | 2.0 C / 2.8 C |
| IONIQ 5 N | Peak 478 kW vs 30-min 159 kW | 478 / 84; 159 / 84 | 5.7 C vs 1.9 C |

Per cell, the IONIQ 5 peak is 377 A / 2 = 189 A on a 60.3 Ah cell, the same 3.1 C. The 800 V pack takes about 2.9× the Leaf's C-rate at peak while the cell format (large pouch, ≈ 55–60 Ah) is similar. The difference is liquid cooling and cell design, not cell size.

### Usable / gross (`derived`, inputs `secondary`)

- Leaf: 39 / 40 = 97.5 % (≈ 2.5 % buffer). With the cell-sum 39.46 kWh as gross, 39 / 39.46 = 98.8 %.
- IONIQ 5 84 kWh: 80.0 / 84.0 = 95.2 % (≈ 4.8 % buffer).

---

## 7. Rate capability: specific energy against specific power

**Simulated (`derived`).** PyBaMM (current release via `uv run --with pybamm`), DFN model, parameter
set `Chen2020` (LG M50, NMC 811 / graphite-SiOx [CHEN-2020], nominal 5.0 Ah), isothermal 25 °C,
constant-current discharge from full to 2.50 V. Per kilogram with the M50LT datasheet mass of
68.2 g [LG-M50LT-2020]; average power = energy ÷ discharge time.

| C-rate | Charge delivered | Energy | Wh/kg | Average W/kg |
|---|---|---|---|---|
| 0.2 C | 5.06 Ah | 18.56 Wh | 272 | 54 |
| 0.5 C | 5.02 Ah | 18.05 Wh | 265 | 132 |
| 1 C | 4.94 Ah | 17.29 Wh | 254 | 257 |
| 2 C | 4.73 Ah | 15.68 Wh | 230 | 486 |
| 3 C | 2.30 Ah | 7.50 Wh | 110 | 716 |

What ends the 3 C run, from the same model with a lumped thermal option: the minimum electrolyte
concentration at the end of discharge is 505 mol/m³ at 1 C, 60 at 2 C and 0 at 3 C (initial
1000), and the negative-electrode stoichiometry at cutoff is 0.05 at 1 C against 0.49 at 3 C. So at
3 C the electrolyte is depleted and about half the lithium is still in the anode. The parameter set
is a model fit, not a rate-capability measurement; the M50LT datasheet allows 3.0 C continuous
discharge (10–25 °C), so the 3 C cliff is the model's and its value should not be quoted as the
real cell's.

**Datasheets.**

- [LG-M50LT-2020], `verified` (EV West mirror; text extracted with pdftotext): "2.1 Energy … Nom.
  18.2 Wh … Min. 17.6 Wh"; "2.2 Nominal Voltage … 3.69V"; "2.8 Min. Discharge Voltage … 2.50V";
  "2.9 Max. Discharge Current … 10 ~ 25ºC … 3.0C (14,400mA)"; "2.12 Weight … 68.2 ± 1.0g (TBD)".
- [LW-26650-2022], `verified`: "Capacity @ 23 ºC Typical (Min) 2.6 Ah (2.5 Ah)"; "Energy @ 23 ºC
  8.58 Wh"; "Specific Power @ 25 ºC, 2 sec pulse > 4000 W/kg"; "Max Continuous Discharge Current
  52 A (20C rate)"; "Max Pulse Discharge Current (10s) 120 A (48C rate)"; "Mass 76.0 g +/- 1.5 g".
- `derived`: M50LT 18.2 / 0.0682 = 267 Wh/kg; 14.4 A × 3.69 V / 0.0682 kg ≈ 780 W/kg. A123
  8.58 / 0.076 = 113 Wh/kg; 52 A × 3.3 V / 0.076 kg ≈ 2,260 W/kg. Max current × nominal voltage
  overstates the power a little, since the voltage sags under that current.

## Not found / open

1. **IONIQ 5 84 kWh pack mass**: no Hyundai document gives it. 477 kg is `search summary` from spec aggregators. No IONIQ 5 cell or pack Wh/kg is given here for that reason.
2. **IONIQ 5 cell-level data from SK On**: cell Ah (60.3), voltage (3.63 V) and 192s2p are `derived` from Hyundai pack data, not quoted. The 384-cell count is verified only for the IONIQ 5 N; the regular Long Range is inferred from the identical pack energy, voltage, Ah and supplier. No SK On datasheet found. NCM ratio (e.g. NCM 811 vs a higher-nickel grade) not found.
3. **IONIQ 5 77.4 kWh pack**: 384 cells / 32 modules is `secondary` (InsideEVs/BASTRO) and the Genesis GV70 ERG (`search summary`). Not needed, since the 84 kWh pack is better sourced.
4. **Leaf chemistry**: AESC's page does not name the cathode. NCM 523 is `secondary` (PushEVs). Leaf usable 39 kWh remains `secondary`.
5. **Leaf ZE1 cell identity**: AESC's page does not name the Leaf. The link rests on MotorFan (`secondary`) and the arithmetic in §2, which fits to 1 %.
6. **Czech Nissan warranty years/km**: not verified from a Nissan CZ document. Belgium (8 yr / 160,000 km, 9 of 12 bars) and Slovakia (9 of 12 bars) are verified. The 9-bars ≈ 70 % mapping is unverified.
7. **UN GTR No. 22 text** (SOCE definition, Part A/B verification): not read, UNECE blocks automated access. Euro 7 and 2025/1707 give the EU definitions instead. Euro 7 consolidated text after amendments (EUR-Lex 2026-09-02 version) not checked for changes to Annex II.
8. **IEC 62660-1 / IEC 60050-482 definitions** of rated capacity, C-rate and SoH: not read (preview stops before clause 3; Electropedia returned 403). USABC and Euro 7 definitions are used instead. A textbook definition (Plett) was not consulted.
9. **UN R85 "maximum 30 minutes power"** wording: `search summary` only.
10. **Preger 2020 numbers**: per-condition EFC exist only as a bar chart (`read from figure`); most LFP values are extrapolations by the authors. Exact values could be recomputed from the cycling data on batteryarchive.org (not done).
11. **Calendar ageing of an automotive cell**: Keil 2016 uses 18650 cells. No automotive-format (pouch/prismatic) calendar dataset with per-year numbers was found in this pass.
