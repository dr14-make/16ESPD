# Electric and hybrid vehicles: reference numbers for validating Lectures 4 and 5

Scope: Lecture 4 covers the battery-electric course car: a DC-equivalent motor with a loss map, an
average-model inverter, a V = E − I·R battery with coulomb-counted SoC, regen blended with hydraulic
brakes, and WLTC consumption. Lecture 5 covers the parallel hybrid, comparing P0–P4 positions on the
WLTC. The course car is 1400–1500 kg, CdA 0.63 m², f_r 0.012, r 0.31 m, with Nissan-Leaf-class
powertrain numbers. This note collects published numbers and curves to validate those models against.

How to read the source labels:
- **verified**: I opened the primary page or PDF and read the number there.
- **read from figure**: I read the value by eye from a plot in a verified PDF. The uncertainty is
  stated.
- **derived**: I computed it from verified inputs. The inputs and method are given.
- **secondary**: the number comes from a reputable aggregator or catalog (ADAC, EV Database), not
  from the manufacturer or a lab.
- **search summary**: the number comes from a search-engine summary or an abstract. The full text was
  not read.

All downloaded PDFs were read in October 2026.

---

## 0. Headline numbers

| Quantity | Value | Status |
|---|---|---|
| Leaf ZE1 40 kWh, WLTP combined consumption | 17.1 kWh/100 km (171 Wh/km, AC from the grid, includes charging losses), range 270 km; WLTP City 389 km | secondary (ADAC catalog) |
| Leaf ZE1 40 kWh, EPA combined | 30.0 kWh/100 mi = 186 Wh/km (AC), 112 MPGe, 151 mi range | verified (fueleconomy.gov API) |
| Leaf ZE1 40 kWh, JC08 (Japan) | 120 Wh/km (AC), 400 km | verified (Nissan JP spec sheet) |
| 2012 Leaf (ZE0, 80 kW) motor peak efficiency | above 97% (5,000–9,000 rpm) | verified (ORNL) |
| 2012 Leaf inverter peak efficiency | above 99% at high speed | verified (ORNL) |
| 2012 Leaf motor + inverter peak efficiency | above 96% | verified (ORNL) |
| Braking energy at the wheel on WLTC 3b, course car | 25–26% of positive traction energy (33–36 Wh/km) | derived (§4.1) |
| Leaf braking-to-battery efficiency on UDDS | 70–80% (MY2012), 72–87% (MY2013) | search summary (Boretti 2016 abstract) |
| 48 V mild-hybrid WLTC CO₂ reduction, similar 15–16 kW e-machine | P0 3.8–6.6%; P1 8.5%; P2 11.9–15.8%; P3 15.3%; P4+P0 15.5% (vs 12 V stop/start) | verified (ICCT 2022, quoting Schaeffler 2018) |

---

## 1. Leaf-class reference numbers

### 1.1 Sources

- **[N-JP-ZE1]** Nissan Japan, 日産リーフ 主要諸元 (main specifications), model ZAA-ZE1, catalog
  1709 (Sept. 2017).
  [PDF](https://www3.nissan.co.jp/content/dam/Nissan/jp/vehicles/leaf/1709/pdf/leaf_specification.pdf).
  verified.
- **[N-GL-ZE1]** Nissan Global newsroom, "New Nissan LEAF" release 170906-01-e (6 Sept. 2017).
  [page](https://global.nissannews.com/en/releases/170906-01-e). verified.
- **[N-JP-AZE0]** Nissan Japan, LEAF ZAA-AZE0 specification sheet (Nov. 2012 update), hosted by
  autoprove.net. [PDF](https://autoprove.net/wp-content/uploads/2012/11/fa10ddd4d1c2e41e2baf64064ea6e7c8.pdf).
  verified, but it is a third-party copy of a Nissan document.
- **[FE-GOV]** US DOE/EPA fueleconomy.gov web service, vehicle IDs 32154 (2012 Leaf) and 39860
  (2018 Leaf). `https://www.fueleconomy.gov/ws/rest/vehicle/<id>`. verified.
- **[EPA-TCL]** US EPA, Test Car List data files, MY2012 (`12tstcar.csv`) and MY2018
  (`18tstcar-2018-10-24.xlsx`).
  [page](https://www.epa.gov/compliance-and-fuel-economy-data/data-cars-used-testing-fuel-economy).
  verified. They give road-load (coastdown) target coefficients A, B, C and the equivalent test weight.
- **[ANL-2013]** Argonne/INL, "2013 Nissan Leaf, Advanced Vehicle Testing – Baseline Testing Results"
  (VIN 1N4AZ0C0DC405045, SV trim).
  [PDF](https://www.energy.gov/sites/prod/files/2015/01/f19/fact2013nissanleaf.pdf). verified.
- **[ORNL-2013]** T. Burress (ORNL), "Benchmarking State-of-the-Art Technologies", DOE VTO Annual
  Merit Review, project APE006, 2013.
  [PDF](https://www.energy.gov/sites/prod/files/2014/03/f13/ape006_burress_2013_o.pdf). verified.
- **[ADAC]** ADAC Autokatalog, Nissan Leaf (40 kWh) MY20 (01/21–07/21)
  [page](https://www.adac.de/rund-ums-fahrzeug/autokatalog/marken-modelle/nissan/leaf/ze1/318672/) and
  N-CONNECTA (02/18–01/19)
  [page](https://www.adac.de/rund-ums-fahrzeug/autokatalog/marken-modelle/nissan/leaf/ze1/287893).
  secondary.
- **[EVDB]** EV Database, Nissan LEAF 40 kWh (MY18-22).
  [page](https://ev-database.org/car/1106/Nissan-LEAF-40-kWh). secondary.

### 1.2 Table

The ZE0 that ORNL benchmarked (US MY2012) has the first-generation 80 kW / 280 Nm motor. Nissan
calls it EM61 (name not verified at a primary source). The EM57 motor arrived with the AZE0 update
(Japan Nov. 2012, US MY2013) at 80 kW / 254 Nm, and the ZE1 uses an uprated EM57 at 110 kW. Do not mix
ORNL's 280 Nm map with EM57 ratings.

| Quantity | Leaf ZE1 40 kWh (2017–) | Leaf ZE0 24 kWh (US MY2012) | Status / source |
|---|---|---|---|
| Motor peak power | 110 kW (150 PS) over 3,283–9,795 rpm | 80 kW. ORNL ran it above 80 kW | ZE1 verified [N-JP-ZE1]. ZE0 verified [ORNL-2013] slide 11, [FE-GOV] "80 kW DCPM" |
| Motor peak torque | 320 N·m over 0–3,283 rpm | 280 N·m | ZE1 verified [N-JP-ZE1]. ZE0 verified [ORNL-2013] slides 10–11 |
| Base (corner) speed | 3,283 rpm. Check: 110 kW / 320 N·m gives 3,283 rpm | ≈ 2,730 rpm (80 kW / 280 N·m). The ORNL map shows the 280 N·m line ending at ≈ 2,700–2,800 rpm | ZE1 verified. ZE0 derived, and read from figure |
| Continuous / rated power | 85 kW (Japanese 定格出力, rated output). ADAC lists "Nennleistung" 90 kW | 80 kW for 1 h at 7,000 rpm, stator stabilizing at ≈ 135 °C. Earlier steps: 50 kW for 1 h, 60 and 70 kW for 0.5 h each | ZE1 85 kW verified [N-JP-ZE1]. 90 kW secondary [ADAC]. ZE0 verified [ORNL-2013] slide 12 |
| AZE0 (2013) for comparison | — | 80 kW / 254 N·m, rated output 70 kW, 360 V, 24 kWh, final drive 8.1938 | verified [N-JP-AZE0]. [ANL-2013] lists 253 N·m and final drive "7.9" for the US 2013 car, so the two disagree on the ratio |
| Max motor speed | Not stated by Nissan. The top speed of 144 km/h [ADAC] at 8.193 and r = 0.31 m implies ≈ 10,100 rpm | Speed rating 10,390 rpm. 7,000 rpm = 64 mph, 10,300 rpm = 94.1 mph | ZE1 derived. ZE0 verified [ORNL-2013] slide 10 |
| Single reduction ratio | 8.193 | 7.94 | ZE1 verified [N-JP-ZE1]. EPA lists 8.19 [EPA-TCL]. ZE0 verified [ORNL-2013] slide 10 and [EPA-TCL] 7.94 |
| Inverter | Rating not found | One inverter (no boost converter). 18 IGBT + 18 diode dies (3 per switch), IGBT estimated at ≈ 1,000 V / 300 A. DC link 600 V, 1,186.5 µF film capacitor. Tested at 375 V DC link, f_sw = 5 kHz, coolant 65 °C | ZE0 verified [ORNL-2013] slides 7–11 |
| Motor construction | — | 8-pole IPM, 48 slots, stator OD 19.8 cm, stack 15.1 cm, ≈ 56 kg, 0.3 mm laminations | verified [ORNL-2013] slides 10–11 |
| Battery energy | 40 kWh gross. 39.0 kWh usable per ADAC/EVDB | 24 kWh rated. INL measured 20.8 kWh at C/3 at 6,258 mi on a 2013 car | 40 kWh verified [N-JP-ZE1]. Usable secondary. 24 kWh verified [ANL-2013]. 20.8 kWh verified (§3.1) |
| Nominal pack voltage | 350 V | 360 V (Nissan JP AZE0). [ANL-2013] gives 364.8 V for 96 × 3.8 V | ZE1 verified [N-JP-ZE1]. ZE0/AZE0 verified |
| Cells | 192 cells, 96s2p, AESC pouch ≈ 56.3 Ah, NMC (EVDB says NMC532) | 192 cells, 96s2p, AESC LMO/graphite pouch, 66.2 Ah per 2p pair (33.1 Ah per cell), 3.7–3.8 V nominal | ZE1 count and config secondary [EVDB]. 56.3 Ah from Gao et al. 2024 (§3.1), verified there as a statement. ZE0 verified [ANL-2013] |
| Curb mass | 1,490 / 1,510 / 1,520 kg (S / X / G, Japan). EU figures are higher: 1,545 kg MY20 base and 1,580 kg N-Connecta, probably including a 75 kg driver | 3,277 lb (1,486 kg) design curb weight, 3,302 lb (1,498 kg) delivered (2013 SV) | JP verified [N-JP-ZE1], also [N-GL-ZE1]. EU secondary [ADAC]. US verified [ANL-2013] |
| EPA test weight (ETW) | 3,750 lb (1,701 kg) and 3,875 lb (1,758 kg) | 3,750 lb (1,701 kg) | verified [EPA-TCL] |
| Cd | 0.28 | Not verified (0.29 is often quoted) | ZE1 verified [N-GL-ZE1] |
| Frontal area | **Not found** from a primary source. For the course CdA of 0.63 m² with Cd 0.28, A = 2.25 m² | — | gap. The 2.25 m² is derived |
| Road-load coefficients (EPA target, SI) | A = 112 N, B = 3.62 N/(m/s), C = 0.424 N/(m/s)² (one test group). Other groups: A 116 N, C 0.437 | A = 150 N, B = 0.615 N/(m/s), C = 0.508 N/(m/s)² | derived from verified [EPA-TCL] lbf, lbf/mph, lbf/mph² values |
| Road-load seen as course-car parameters | f_r ≈ A/(m·g) = 0.0067 at ETW. C/(½ρ) = 0.71 m² (ρ = 1.2) | f_r ≈ 0.009, C/(½ρ) = 0.85 m² | derived. Coastdown C also contains speed-squared drivetrain and tire losses, so it overstates the aero CdA |
| Road load at 100 km/h | 539 N, versus 462 N for the course car (1450 kg, CdA 0.63, f_r 0.012) | 559 N | derived |
| Tires | 205/55R16 91V (S, X) or 215/50R17 91V (G) | 205/55R16 (Bridgestone Ecopia EP422) | verified [N-JP-ZE1], [ANL-2013] |

### 1.3 Official consumption and range

| Cycle | ZE1 40 kWh | ZE0/AZE0 24 kWh | Status |
|---|---|---|---|
| WLTP combined, EU | **17.1 kWh/100 km, 270 km** (MY20, 16″). WLTP City 389 km. The 2018 N-Connecta (17″) is listed at 20.6 kWh/100 km with the same 270 km. EVDB lists 171 Wh/km "rated" and 270 km | — | secondary [ADAC], [EVDB]. Nissan EU primary not found. The 20.6 figure does not fit 270 km with a 39 kWh pack; treat it as the high end of the homologation interpolation |
| EPA combined | 30.0 kWh/100 mi (186 Wh/km), 112 MPGe, 151 mi. City 27.0 kWh/100 mi (168 Wh/km), highway 33.7 kWh/100 mi (210 Wh/km) | 2012: 34 kWh/100 mi (211 Wh/km), 99 MPGe, 73 mi. 2013 SV: 300 Wh/mi, 115 MPGe, 84 mi | verified [FE-GOV], [ANL-2013] |
| JC08 (Japan) | 120 Wh/km, 400 km | AZE0: 114 Wh/km, 228 km | verified [N-JP-ZE1], [N-JP-AZE0] |
| ANL dyno, 2013 Leaf, 72 °F, AC Wh/mi | — | UDDS 201.4 (cold start 211.7), HWFET 240.8, US06 321.6. Steady speed: 20 mph 147.1, 40 mph 197.6, 60 mph 285.4, 80 mph 397.8 | verified [ANL-2013]. The PDF table layout is garbled, so the column assignment is my reading |
| ANL constant-speed charge chain, 2013 Leaf | — | On-board charger efficiency 86–87%. Battery round-trip 95–98%. Overall AC-to-DC-out 82–85% | verified [ANL-2013] p. 3 |

All official figures (WLTP, EPA, JC08) are **AC energy from the grid, including charging losses**. A
model that integrates battery DC energy over the WLTC should come out about 10–15% below 171 Wh/km
(ANL charge chain, above).

---

## 2. Measured motor and inverter efficiency maps

### 2.1 Sources

- **[ORNL-2013]** (above). Slide 11 shows "LEAF motor efficiency contours" (top) and "LEAF inverter
  efficiency contours" (bottom). Slide 12 shows "LEAF motor & inverter efficiency contours", the
  "LEAF system efficiency published by Nissan" (from *"Power from Within"*, Nissan LEAF Special Edition
  of SAE Vehicle Electrification, p. 17, 23 Feb. 2011), and the continuous-power test trace. Axes are
  0–10,000 rpm and 0–300 N·m. All verified.
- The full ORNL Leaf report was **not found** as an ORNL/TM number. The FY2012/FY2013 APEEM annual
  progress reports on OSTI probably contain it, but I did not locate it. The AMR slides are the citable
  source here.
- **[ORNL-2011]** T. Burress, "Benchmarking ...", AMR 2011, APE006.
  [PDF](https://www.energy.gov/sites/prod/files/2014/03/f10/ape006_burress_2011_o.pdf). verified. It
  covers the 2010 Prius: 60 kW, 207 N·m, 13,500 rpm, peak motor efficiency 96%, combined maps at 225,
  500 and 650 V DC.
- Full Prius report: Burress, Campbell, Coomer, Ayers, *Evaluation of the 2010 Toyota Prius Hybrid
  Synergy Drive System*, ORNL/TM-2010/253, March 2011 ([OSTI 1007833](https://www.osti.gov/biblio/1007833)).
  search summary; not opened. It holds full efficiency maps and is the best source if a Prius
  comparison is wanted.

### 2.2 2012 Leaf (ZE0) headline results (verified, [ORNL-2013] slides 11–12)

- Peak motor efficiency **above 97%** between 5,000 and 9,000 rpm. There is a large region above 90%.
- Inverter efficiency **above 99%** at high speeds.
- Combined motor + inverter **above 96%**. This is "in general agreement" with Nissan's published map.
  ORNL's values are slightly higher.
- Test conditions: 375 V DC link, 5 kHz switching, water-ethylene glycol at 65 °C.
- Nissan's own system map (slide 12) uses a color scale from 85 to 95%. Its peak region (≈ 94–95%)
  sits at about 4,000–8,000 rpm and 80–150 N·m.

### 2.3 Points read from the combined (motor + inverter) map, slide 12

These were read by eye from contour labels on a 220 dpi render. Uncertainty is about ±150 rpm,
±10 N·m and ±1 percentage point. Use them for a lecture comparison, not for fitting.

| Speed (rpm) | Torque (N·m) | η combined (%) | Region |
|---|---|---|---|
| 900 | 180 | 80 | low speed, high torque (copper-loss dominated) |
| 2,000 | 250 | 87 | near peak torque |
| 2,400 | 230 | 89 | |
| 2,850 | 245 | 90 | near the corner point |
| 3,500 | 80 | 94 | |
| 4,900 | 105 | 95 | |
| 7,300 | 85 | 96 | peak island, just under the 80 kW hyperbola |
| 8,600 | 55 | 95 | |
| 9,600 | 50 | 94 | |
| 5,750 | 57 | 94 | |
| 3,400 | 42 | 93 | |
| 2,900 | 34 | 92 | |
| 4,850 | 23 | 92 | |
| 2,500 | 26 | 91 | |
| 1,900 | 10 | 87 | light load |
| 2,800–9,000 | below ≈ 5 | 70–80 | near-zero torque (fixed losses dominate) |

Motor-only map (slide 11, top), read by eye: a 97% island at about 5,500–9,500 rpm and 75–140 N·m.
94–95% at 1,500–2,500 rpm and ≈ 100 N·m. 88–93% at 1,000–3,000 rpm and ≈ 220 N·m. Values drop
below 85% only under ≈ 15 N·m.

Inverter-only map (slide 11, bottom), read by eye: mostly 96–98%. It reaches 99% above ≈ 9,000 rpm and
60–80 N·m, and falls to the 80s only below ≈ 1,000 rpm. Inverter efficiency rises with speed at fixed
torque because output power rises while the losses track current.

**Teaching use.** A loss model P_loss = k_c·T² + k_i·ω + k_w·ω³ + C₀ fitted to the course-car motor
should reproduce: (a) a peak near 95–96% combined in the mid-speed, mid-torque region; (b) ≈ 80% at
low speed and high torque; (c) a collapse toward 70% at near-zero torque. Point (c) matters on the
WLTC, because much of the cycle is light-load cruising.

### 2.4 Related ORNL data useful for Lecture 5

- **2012 Hyundai Sonata HSG** (belt starter-generator, effectively a P0 machine): rated 43 N·m,
  8.5 kW, 15,750 rpm. Peak efficiency including belt losses is 88% motoring, 87% generating. The HSG
  inverter peaks at 98%. System peak is 87% motoring and 86% regenerating, or 82–84% at the 8.5 kW
  limit. Belt losses are 1–2% at high power and 3–6% at moderate load and low speed. verified
  [ORNL-2013] slides 13–15.
- **2011 Sonata Hybrid** (P2 with an engine clutch, motor in place of the torque converter, 6-speed
  AT): 30 kW primary machine. The deck gives its torque as both "105 Nm" (slide 6) and "205 Nm, corner
  ≈ 1,400 rpm" (slide 8). There is a 1.4 kWh, 270 V LG Chem manganese-spinel pack, and a claimed
  electric drive up to 62 mph. verified [ORNL-2011], including its internal inconsistency on torque.

---

## 3. Li-ion cell OCV(SoC) and internal resistance

No public OCV-vs-SoC table at 10% steps was found for any AESC Leaf cell. Below are (a) Leaf-specific
data read from INL pack tests, (b) Leaf-cell anchor points and resistances from a peer-reviewed
second-life study, and (c) a 10%-step OCV table for a well-characterized NMC cell, computed from a
published parameter set.

### 3.1 Sources

- **[INL-5045]** INL/Intertek, "BEV Battery Testing Results, 2013 Nissan Leaf – VIN 5045",
  INL/MIS-14-31587 (8 July 2014).
  [PDF](https://www.energy.gov/sites/prod/files/2015/01/f19/batteryLeaf5045.pdf). verified. AESC,
  96 series elements, 24.0 kWh / 66.2 Ah rated, 3.8 V / 360 V nominal, 2.50–4.20 V per cell. It
  contains a C/3 static capacity curve (Fig. 1) and USABC EVPC pulse resistance at each 10% DOD (Figs. 2
  and 3).
- **[GAO-2024]** W. Gao, Z. Cao, N. Vosoughi Kurdkandi, Y. Fu, C. Mi, "Evaluation of the second-life
  potential of the first-generation Nissan Leaf battery packs in energy storage systems",
  *eTransportation* 20 (2024) 100313, doi:10.1016/j.etran.2024.100313, open access CC BY-NC-ND.
  [PDF](https://chrismi.sdsu.edu/publications/214.pdf). verified.
- **[CHEN-2020]** C.-H. Chen, F. Brosa Planella, K. O'Regan, D. Gastol, W. D. Widanage, E. Kendrick,
  "Development of Experimental Techniques for Parameterization of Multi-scale Lithium-ion Battery
  Models", *J. Electrochem. Soc.* 167 (2020) 080534. LG M50 21700, 5 Ah, NMC811 / graphite-SiOx. The
  paper itself was not opened. The electrode OCP fits come from the PyBaMM parameter set `Chen2020`
  ([source](https://github.com/pybamm-team/PyBaMM/blob/main/packages/pybamm/src/pybamm/input/parameters/lithium_ion/Chen2020.py)),
  verified.
- **[INL-DATA]** INL, "Nissan Leaf cell testing" and "pack testing" datasets on the DOE Battery Data
  Hub (cells from a 2017 Leaf, graphite/LMO pouch, 33 Ah nominal, 2P96S).
  [page](https://batterydata.energy.gov/dataset/metadata/inl-nissan-leaf-cell-testing). search summary.
  The site needs JavaScript and I could not open the files. It may contain raw OCV and HPPC data.

### 3.2 Leaf (AESC LMO, 33 Ah cell, 2013 car) loaded voltage vs SoC: C/3 discharge

Read from [INL-5045] Fig. 1 (pack voltage vs Ah at 22.1 A, beginning of test). The measured capacity
was 56.9 Ah, which sets SoC = 1 − Ah/56.9. Read by eye, about ±3 V pack (±0.03 V per cell). Per-cell =
pack/96. This is the **loaded** voltage at C/3. The OCV is roughly 0.03 V per cell higher, from
22 A × 0.14 Ω / 96.

| Ah discharged | SoC (%) | Pack V | V per series element |
|---|---|---|---|
| 0 | 100 | 400 | 4.17 |
| 10 | 82 | 383 | 3.99 |
| 20 | 65 | 377 | 3.93 |
| 30 | 47 | 372 | 3.88 |
| 40 | 30 | 362 | 3.77 |
| 48 | 16 | 354 | 3.69 |
| 50 | 12 | 347 | 3.61 |
| 55 | 3 | 296 | 3.08 |
| 57 | 0 | 239 | 2.49 |

Leaf Gen-1 anchor points from [GAO-2024], which used aged cells: 4.15 V ≈ 92% SoC, 3.6 V ≈ 20%,
3.3 V ≈ 10%. The recommended window of 10–90% SoC corresponds to 3.2–4.1 V. verified.

### 3.3 Internal resistance

| Item | Value | Status |
|---|---|---|
| 2013 Leaf pack, 10 s charge pulse resistance | 0.11–0.12 Ω from ≈ 7 to 47 Ah discharged, 0.136 Ω at ≈ 54 Ah | read from figure [INL-5045] Fig. 2, ±0.005 Ω |
| 2013 Leaf pack, 30 s discharge pulse resistance | 0.136–0.145 Ω from ≈ 7 to 46 Ah, rising to 0.20 Ω at ≈ 53 Ah | read from figure [INL-5045] Fig. 3 |
| Same, per 33 Ah cell (× 2 / 96) | ≈ 2.3–2.4 mΩ (10 s charge), ≈ 2.9–3.0 mΩ (30 s discharge), ≈ 4.2 mΩ near empty. Includes interconnects | derived |
| 2013 Leaf pack power capability | 103.3 kW (30 s discharge at 80% DOD), **80.5 kW (10 s charge at 20% DOD)** | verified [INL-5045] p. 1 |
| Nissan spec, Gen-1 cell pair (2p, 66.2 Ah) | 1 mΩ (not stated whether AC or DC). Voltage range 2.8–4.2 V, 3.8 V mean | verified [GAO-2024] Table 1 |
| Measured, new Gen-3 56.3 Ah Leaf cell | R0 ≈ 1 mΩ and R1 ≈ 1 mΩ (1-RC model) | verified [GAO-2024] §2.3 (statement in text) |
| Retired Gen-1 pair at 70% SoC | R0 1.70–2.06 mΩ, R1 1.32–1.37 mΩ | verified [GAO-2024] Fig. 5 text |
| Temperature dependence, LMO/graphite (LEV50N 50 Ah prismatic, not a Leaf cell) | resistance changes by "about 50% to 60%" over 15–35 °C | search summary of a preprint: Cornejo et al., arXiv:2609.04487 (2026). No primary Leaf-cell R(T) table found |

For the course-car battery with R as a single number: per-cell DC resistance (10–30 s) is about
2.5–3 mΩ for the 33 Ah cell. For a 96s2p pack, that gives R_pack ≈ 0.12–0.14 Ω mid-SoC at room
temperature, rising by about 50% near empty. For a 56 Ah ZE1-class cell, R0 + R1 ≈ 2 mΩ gives
R_pack ≈ 0.1 Ω.

### 3.4 10%-step OCV table for a comparable well-characterized NMC cell (derived)

Computed by me from [CHEN-2020] (PyBaMM `Chen2020`): U_ocv(SoC) = U_p(y) − U_n(x), with
stoichiometry windows from PyBaMM's `ElectrodeSOHSolver` for 2.5–4.2 V (x₀ = 0.026, x₁₀₀ = 0.911,
y₀ = 0.854, y₁₀₀ = 0.264, Q = 5.15 Ah). Status: **derived**. These are model OCPs, not a measured
full-cell OCV. The cell is a cylindrical NMC811, not an AESC pouch. Use it for shape and E(SoC) table
format only.

| SoC (%) | 0 | 10 | 20 | 30 | 40 | 50 | 60 | 70 | 80 | 90 | 100 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| OCV (V) | 2.500 | 3.296 | 3.485 | 3.581 | 3.667 | 3.751 | 3.841 | 3.948 | 4.042 | 4.097 | 4.200 |

Compared with the Leaf LMO curve (§3.2), the LMO cell is flatter and higher between 30 and 90% SoC
(≈ 3.8–4.0 V) and has a sharper knee below 10%. That knee is why Nissan's usable window and the
GAO-2024 recommendation stop at about 10% SoC.

---

## 4. Regenerative braking

### 4.1 How much braking energy is there on the WLTC? (derived, course car)

Computed by me with the repo's `assets/data/drive_cycles/wltc_class3b.csv` (23.27 km), ρ = 1.2,
CdA 0.63, f_r 0.012, 1 Hz backward calculation, with the wheel power split into positive and negative
parts.

| Mass | Positive traction energy at wheel | Braking energy at wheel (negative power) | Braking / traction | Share of braking above 15 km/h |
|---|---|---|---|---|
| 1,400 kg | 3.10 kWh (133 Wh/km) | 0.78 kWh (33 Wh/km) | 25.1% | 96.3% |
| 1,500 kg | 3.24 kWh (139 Wh/km) | 0.84 kWh (36 Wh/km) | 26.0% | 96.3% |

So the upper bound for regen on the WLTC is about a quarter of the traction energy at the wheel.
Low-speed fade below about 15 km/h costs under 4% of it. The WLTC is a gentle cycle: its hardest
deceleration is 1.5 m/s² (0.15 g, computed from the same file). A regen system of 0.2–0.3 g (§4.3)
therefore never has to blend in friction on the WLTC because of deceleration demand. Only power, SoC
and low-speed limits can force friction in.

### 4.2 Measured recovery efficiency

- **Boretti, A.**, "Analysis of the Regenerative Braking Efficiency of a Latest Electric Vehicle", SAE
  2013-01-2872 ([SAE Mobilus](https://saemobilus.sae.org/content/2013-01-2872)). It uses Argonne D3
  data for a 2012 Leaf on the UDDS. Propulsion efficiency (power to vehicle / power from battery)
  "approaches 90%". Round-trip regenerative braking efficiency is "about 70%". search summary of the
  abstract.
- **Boretti, A.**, "Comparison of Regenerative Braking Efficiencies of MY2012 and MY2013 Nissan Leaf",
  *Int. J. Eng. Technol. Innov.* 6(3):214, 2016
  ([WVU record](https://researchrepository.wvu.edu/faculty_publications/2509)). On the UDDS, propulsion
  is 87–89% (unchanged). Power to battery / braking power at the vehicle improved from about 70–80% to
  72–87%. verified abstract on the WVU page.
- **Combined estimate (derived):** 25% (§4.1) × 70–87% gives about **18–22% of positive traction
  energy returned to the battery** on the WLTC for the course car. This is in line with the ≈ 16–18%
  recovered/traction that a 2026 MDPI *Vehicles* simulation reported on WLTP (search summary, not
  opened; [link](https://www.mdpi.com/2624-8921/8/3/66)). No **measured** WLTC regen share for a
  production BEV was found from a primary source.
- **Liu, Ortmann, Nefcy, Colvin, Connolly (Ford)**, "Methods of Measuring Regenerative Braking
  Efficiency in a Test Cycle", *SAE Int. J. Alt. Powertrains* 6(1):103–112, 2017,
  doi:10.4271/2017-01-1168. It gives definitions of regen efficiency on the FTP and compares them with
  EPA's brake-energy-recovery method. No numbers in the abstract. verified abstract.

### 4.3 Limits seen in practice

| Limit | Value | Status / source |
|---|---|---|
| 2013 Leaf, 60–0 mph hard stop | peak power into the battery only 0.7 kW (50% SoC) and 10.6 kW (100% SoC). ANL: "during a full brake request, the friction brakes are predominantly used" | verified [ANL-2013] p. 2, note 7 |
| 2013 Leaf, coasting 60–10 mph in Drive | peak 14.0 kW into the battery, 78.6 Wh total over 55.6 s | verified [ANL-2013] |
| 2013 Leaf pack, 10 s charge capability at 20% DOD | 80.5 kW. The battery is not what limits regen at mid SoC; motor torque, the brake system and the strategy are | verified [INL-5045] |
| Leaf ZE1 e-Pedal (one-pedal) | lift-off deceleration up to 0.2 g | search summary of the Nissan release ([global.nissannews.com](https://global.nissannews.com/en/releases/e-pedal-easy-driving-using-only-the-accelerator-pedal)) |
| Leaf ZE1 brake system | "回生協調ブレーキ: 電動型制御ブレーキ" (cooperative regen brake, electrically controlled). This is series-type blending by brake-by-wire | verified [N-JP-ZE1] |
| Bosch ESP hev | pure regenerative deceleration up to 0.2 g with a vacuum booster, **up to 0.3 g** with iBooster. "Recuperation efficiency of up to 100%, depending on the foundation brake design" | verified ([Bosch Mobility](https://bosch-mobility.com/en/solutions/driving-safety/esp-hev-module/)) |
| Low-speed fade speed | **No primary number found.** Patents (e.g., US 8,066,339) describe ramping regen torque to zero and blending in friction at low speed, with the start speed raised when friction capability is reduced | search summary (patents). gap |
| Regen torque at high speed | limited by the motor's constant-power region: T_regen ≤ P_max/ω. Battery charge-power and SoC limits apply on top (regen is often derated near full charge, compare the 100% vs 50% SoC hard-stop data above) | standard motor physics. The SoC effect is consistent with [ANL-2013] |

### 4.4 Blending strategies

- **Series (cooperative) blending:** regen supplies all braking up to its limit, and friction adds only
  the remainder. Variants are "optimal energy recovery" (maximize regen within front/rear
  distribution limits) and "optimal braking feel". It needs brake-by-wire or a decoupled pedal (iBooster
  + ESP hev, Nissan's electric control brake).
- **Parallel blending:** friction and regen act together in a fixed or speed-dependent ratio, with no
  pedal decoupling. It is simpler and recovers less.
- Sources: Gao and Ehsani, "Electronic Braking System of EV and HEV — Integration of Regenerative
  Braking, Automatic Braking Force Control and ABS", SAE 2001-01-2478
  ([SAE](https://saemobilus.sae.org/content/2001-01-2478)). Ehsani, Gao, Emadi, *Modern Electric,
  Hybrid Electric, and Fuel Cell Vehicles* (CRC), regenerative-braking chapter. NPTEL lecture 39, "Brake
  System of EVs and HEVs" ([NPTEL](https://archive.nptel.ac.in/content/storage2/courses/108103009/module11/lec39/1.html)),
  which lists "series braking with optimal feel / optimal energy recovery" and "parallel braking". All
  search summary. A 2011 benchmarking study found that "serial regenerative braking clearly
  out-performs parallel" ([scinapse](https://www.scinapse.io/papers/2182340700); search summary).

---

## 5. Parallel hybrid P0–P4: fuel/CO₂ savings by e-machine position

### 5.1 Primary review used

**[ICCT-2022]** J. Dornoff, J. German, A. Deo (ICCT), A. Dimaratos (DITENCO), *Mild-hybrid vehicles: a
near term technology trend for CO₂ emissions reduction*, ICCT white paper, July 2022.
[PDF](https://theicct.org/wp-content/uploads/2022/07/mild-hybrid-emissions-jul22.pdf). verified. It
reproduces three like-for-like simulation studies.

Executive summary (verified): with a comparable 15–16 kW machine, type-approval CO₂ reduction versus
stop/start ranges from **≈ 7% for P0 to almost 16% for P2, P3 and P4+P0**. Going to 20–30 kW adds 5–10%
on P2, P3 and P4. Micro-hybrids (stop/start) average 7% on the NEDC and 3.5% on the WLTC.

### 5.2 Schaeffler 2018 (WLTC, vs a 12 V stop/start C-segment car, 1.0 L 3-cyl, 7-DCT, 1.4 kWh battery)

Source: Eckenfels et al., "48V Hybridization: A Smart Upgrade for the Powertrain", Schaeffler
Symposium 2018, as reproduced in [ICCT-2022] Fig. 6. verified at ICCT. The Schaeffler original was not
opened.

| Position | E-machine | WLTC CO₂ reduction |
|---|---|---|
| P0 (BSG) | 8.5 kW | 3.8% |
| P0 (BSG) | 16 kW | 6.6% |
| P1 (crank-integrated, beltless FEAD) | 15 kW | 8.5% |
| P2 off-axis (belt-driven) | 16 kW | 11.9% |
| P2 coaxial, standard FEAD | 15 kW | 14.8% |
| P2 coaxial, beltless FEAD | 15 kW | 15.8% |
| P3 (transmission output) | 16 kW | 15.3% |
| P4+P0 (rear e-axle, 2-speed) vs FWD | 15 kW | 15.5% |
| P4+P0 vs conventional AWD | 15 kW | 23.9% |

### 5.3 Chalmers (Melaika, Mamikoglu, Dahlander, SAE 2019-01-0366), C-segment 1,300 kg + 50 kg, 7-DCT, vs no stop/start

From [ICCT-2022] Table 4. verified at ICCT.
[SAE record](https://saemobilus.sae.org/papers/48v-mild-hybrid-architecture-types-fuels-power-levels-needed-achieve-75g-co2-km-2019-01-0366).

| Position | EM power | Gasoline 1.5 L, NEDC / **WLTC** / RTS95 |
|---|---|---|
| 12 V stop/start | 3 kW | 7.8 / **5.0** / 4.3% |
| P0 | 8 / 15 kW | 9.7 / **7.5** / 6.9%; 10.1 / **8.9** / 9.5% |
| P1 | 8 / 15 kW | 10.7 / **8.5** / 7.7%; 11.5 / **10.4** / 11.5% |
| P2 | 8 / 15 / 20 kW | 25.0 / **20.5** / 12.5%; 29.0 / **24.5** / 20.5%; 31.0 / **25.2** / 24.3% |
| P3 | 8 / 15 / 20 kW | 26.0 / **20.6** / 10.4%; 31.0 / **25.0** / 20.1%; 32.0 / **26.6** / 24.3% |

Relative to stop/start, going from 8 to 15 kW adds 1.5–2.0 points for P0/P1, and from 8 to 20 kW adds
5.0–6.3 points for P2/P3. Decoupling the machine from the engine (P2/P3 versus P0/P1) is worth up to
15 points at equal power. verified [ICCT-2022].

### 5.4 TU Braunschweig (Werra et al., CTI Symposium 2018, doi:10.1007/978-3-662-58866-6_29), 1,520 kg C-segment, manual, vs stop/start

From [ICCT-2022] Fig. 8. verified at ICCT. It sweeps P0, P2, P3 and P4+P0 (10 kW P0) over 10–30 kW
with the same strategy, including electric driving. On the WLTC: P0 reaches ≈ 2.8–5.1%. P2 and P3 reach
≈ 10–16%, with P3 2–5 points above P2. P4 (30 kW) + P0 (10 kW) reaches ≈ 29%. The individual point
labels in the figure were not mapped to curves with certainty.

### 5.5 Other studies (lower confidence)

- AVL (Kapus et al. 2020; Schöffmann et al. 2017, 2019): P2 with 20 kW on a 1.6 L GDI C-segment car
  gives 13% on the WLTC. verified as quoted in [ICCT-2022].
- Liu, Liao, Lai, *Adv. Mech. Eng.* 2021, doi:10.1177/16878140211036022 (GT-ISE, Ford Focus baseline):
  P0 ≈ 13.5%, P1 ≈ 15.5%, P2 ≈ 18.5% fuel economy gain; P2 28% on UDDS and 27% on WLTC class 3b. search
  summary. Note these are "fuel economy improvement" figures, not consumption reductions.
- Shang et al., *Adv. Mech. Eng.* 2024, doi:10.1177/16878132231222067: an **experimental** 48 V P0
  gives 7.9% lower WLTP fuel consumption than conventional. Stop/start contributes 3.8%, BSG neutral
  (sailing) 0.9%, and torque assist 0.5%. search summary.
- Continental, Bosch, Delphi and FEV primary publications with per-position numbers were **not found**
  or not opened.

### 5.6 Typical e-machine power per position (48 V)

| Position | Typical power in the studies above | Notes |
|---|---|---|
| P0 (belt) | 8.5–16 kW. Hyundai HSG 8.5 kW / 43 N·m, ORNL-measured peak 86–88% including the belt | Belt losses of 1–2% at high load and 3–6% at low load ([ORNL-2013]). Recuperation also pays engine friction |
| P1 (crank) | 8–15 kW | No belt loss, but still coupled to engine friction |
| P2 (input, with K0 clutch) | 8–20 kW (48 V). Full hybrids around 30 kW (2011 Sonata) | Benefits from gear ratios. Can sail and drive electrically |
| P3 (output) | 8–20 kW | No transmission loss in regen. A fixed ratio limits the motor operating range |
| P4 (rear axle) | 15–30 kW | Usually paired with a P0 for engine start. Adds AWD |

Teaching takeaway, consistent across all three like-for-like studies: **the decoupling clutch matters
more than the machine power**. The ranking is P0 < P1 << P2 ≈ P3 (≈ P4+P0). On the WLTC the gap between
the coupled and decoupled positions is about 7–15 points at 15 kW.

---

## 6. Context claims in the Lecture 4 deck

Sources for the deck's statements that carry no model number: why electric (section 01) and the
machine types (section 03). The slides quote these sources' wording and numbers.

- **[EEA-TRANSPORT]** European Environment Agency, *Greenhouse gas emissions from transport in
  Europe* (indicator, published 6 Nov 2025).
  [page](https://www.eea.europa.eu/en/analysis/indicators/greenhouse-gas-emissions-from-transport).
  verified. "The transport sector is responsible for nearly a quarter of Europe's greenhouse gas
  emissions", and transport has not shown the same decreases since 1990 as other sectors. Road
  transport emitted 73 % of the EU's transport emissions in 2023, international bunkers included.
  The deck's earlier "about a fifth" is not what the EEA says, so the slide now says "nearly a
  quarter".
- **[EU-443]** Regulation (EC) No 443/2009 setting emission performance standards for new passenger
  cars, of 23 April 2009, as adopted.
  [text](https://www.legislation.gov.uk/eur/2009/443/adopted/data.htm?view=plain) (the UK
  National Archives' copy of the Official Journal text; EUR-Lex,
  [CELEX 32009R0443](https://eur-lex.europa.eu/eli/reg/2009/443/oj), refused a scripted download).
  verified. Article 1 sets the average CO₂ emissions of new passenger cars at 130 g CO₂/km and,
  from 2020, a target of 95 g CO₂/km for the new-car fleet. Recital 3: road transport is the
  second largest greenhouse-gas emitting sector in the Union. Repealed by Regulation (EU) 2019/631
  from 2020.
- **[MCHP-AN885]** P. Yedamale, *Brushless DC (BLDC) Motor Fundamentals*, Microchip application
  note AN885, 2003. [PDF](https://ww1.microchip.com/downloads/en/AppNotes/00885a.pdf). verified,
  p. 8: "Every 60 electrical degrees of rotation, one of the Hall sensors changes the state", so
  six steps complete an electrical cycle. The angle is electrical: mechanical degrees are that
  divided by the number of pole pairs.
- **[AUDI-Q4]** Audi MediaCenter, *Electric motors and electric all-wheel drive*, Audi Q4 e-tron
  press kit, 14 Apr 2021.
  [page](https://www.audi.com/en/electric-suvs-in-the-premium-compact-segment-the-audi-q4-e-tron-and-the-q4-sportback-e-tron-until-2026-13887/electric-motors-and-electric-all-wheel-drive-13900).
  verified. A permanently excited synchronous motor drives the rear axle in all models and, in
  moderate driving, drives the car on its own for efficiency and traction; the quattro models add
  an asynchronous (induction) motor on the front axle, activated when the driver asks for more
  power than the rear can give, whose principal advantages include minimal drag losses when it is
  inactive. Volkswagen's ID.4 GTX uses the same pair (rear PSM, front ASM); its newsroom pages
  returned 404 when checked, so that example is not used.

---

## 7. Gaps

- **Leaf WLTP consumption from Nissan itself** was not found. 17.1 kWh/100 km and 270 km are from ADAC
  and EV Database. The EEA CO₂-monitoring database (the type-approval primary source) returned 403.
- **Leaf frontal area** was not found. Cd 0.28 is verified. CdA ≈ 0.63 m² in the course car implies
  A = 2.25 m², but that is not a source value.
- **ZE1 inverter rating and EM57 maximum rpm** were not found from primary sources. ZE0 Cd (0.29) is
  unverified.
- **No ORNL efficiency map exists for the 110 kW EM57.** The verified map is for the 80 kW / 280 N·m
  ZE0 motor. The point values in §2.3 were read by eye.
- **No measured 10%-step OCV table for an AESC Leaf cell.** §3.2 is loaded C/3 pack voltage read from a
  figure. §3.4 is model-derived for an LG M50, not a Leaf cell. The INL Leaf cell dataset on the DOE
  Battery Data Hub may hold raw OCV/HPPC data, but its files could not be opened.
- **No primary R(T) table for a Leaf cell.** The only temperature sensitivity found is for an LMO
  prismatic cell, from a 2026 preprint.
- **No measured WLTC regen share for a production BEV.** §4.1 is a derived upper bound. The Boretti
  efficiencies are UDDS, from abstracts only.
- **No primary low-speed regen fade speed.**
- **Supplier primary documents** (Continental, Bosch, Delphi, FEV) giving P0–P4 savings were not
  located. The P-position numbers rest on the ICCT 2022 review of Schaeffler, Chalmers and Braunschweig
  simulations. Only one experimental P0 number (Shang 2024) was found, from a search summary.
