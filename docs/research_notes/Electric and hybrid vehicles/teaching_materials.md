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
| Frontal area | **Not found** from a primary source. For the course CdA of 0.63 m² with Cd 0.28, A = 2.25 m² | — | gap. The 2.25 m² is derived; checked against width × height in `bev-road-load-and-braking-validation.md` §2 |
| Road-load coefficients (EPA target, SI) | A = 112 N, B = 3.62 N/(m/s), C = 0.424 N/(m/s)² (one test group). Other groups: A 116 N, C 0.437 | A = 150 N, B = 0.615 N/(m/s), C = 0.508 N/(m/s)² | derived from verified [EPA-TCL] lbf, lbf/mph, lbf/mph² values |
| Road-load seen as course-car parameters | f_r ≈ A/(m·g) = 0.0067 at ETW. C/(½ρ) = 0.71 m² (ρ = 1.2) | f_r ≈ 0.009, C/(½ρ) = 0.85 m² | derived. Coastdown C also contains speed-squared drivetrain and tire losses, so it overstates the aero CdA |
| Road load at 100 km/h | 539 N, versus 462 N for the course car (1450 kg, CdA 0.63, f_r 0.012) | 559 N | derived. All three MY2018–22 40 kWh rows, other speeds and coast-down times: `bev-road-load-and-braking-validation.md` §1, §4 |
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
| Leaf ZE1 e-Pedal (one-pedal) | lift-off deceleration up to 0.2 g | verified, Nissan release of 6 Dec 2017 ([global.nissannews.com](https://global.nissannews.com/en/releases/e-pedal-easy-driving-using-only-the-accelerator-pedal)). D-mode lift-off regen, ABS–regen practice and stopping distances: `bev-road-load-and-braking-validation.md` §6–8 |
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

Sources for the deck's statements that carry no model number: why electric, the market and the
rules (section 01), the machine types (section 03), charging (section 05), today's batteries and
their price (section 06). The slides quote these sources' wording and numbers. The series plotted
on the slides (EV shares, EU new-car CO₂ and targets, BNEF pack prices) are copied into
`data/ev_context/`; change them there and here together.

- **[EEA-TRANSPORT]** European Environment Agency, *Greenhouse gas emissions from transport in
  Europe* (indicator, published 6 Nov 2025).
  [page](https://www.eea.europa.eu/en/analysis/indicators/greenhouse-gas-emissions-from-transport).
  verified. "The transport sector is responsible for nearly a quarter of Europe's greenhouse gas
  emissions", and transport has not shown the same decreases since 1990 as other sectors. Road
  transport emitted 73 % of the EU's transport emissions in 2023, international bunkers included.
  The deck's earlier "about a fifth" is not what the EEA says, so the slide now says "nearly a
  quarter". Re-checked 1 Nov 2026: the page still shows "Published 06 Nov 2025", latest full data
  year 2023 (preliminary 2024 estimate +0.7 %), wording unchanged; no 2026 edition yet. A November
  2026 edition may appear, so re-check before the lecture.
- **[EU-443]** Regulation (EC) No 443/2009 setting emission performance standards for new passenger
  cars, of 23 April 2009, as adopted.
  [text](https://www.legislation.gov.uk/eur/2009/443/adopted/data.htm?view=plain) (the UK
  National Archives' copy of the Official Journal text; EUR-Lex,
  [CELEX 32009R0443](https://eur-lex.europa.eu/eli/reg/2009/443/oj), refused a scripted download).
  verified. Article 1 sets the average CO₂ emissions of new passenger cars at 130 g CO₂/km and,
  from 2020, a target of 95 g CO₂/km for the new-car fleet. Recital 3: road transport is the
  second largest greenhouse-gas emitting sector in the Union. **Superseded**: Regulation (EU)
  2019/631 ([EU-2019/631], §6.4) repealed it with effect from 1 January 2020. Kept for history
  (the 130 g and 95 g NEDC steps); cite 2019/631 as amended for anything current.
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

### 6.1 Market

- **[IEA-GEVO-2026]** International Energy Agency, *Global EV Outlook 2026: Growing sales amid an
  energy crisis* (May 2026; the PDF read is marked "Revised version, May 2026").
  [report](https://www.iea.org/reports/global-ev-outlook-2026);
  [PDF](https://www.cleanenergyministerial.org/content/uploads/2026/05/globalevoutlook2026.pdf)
  (the copy hosted by the Clean Energy Ministerial, whose Electric Vehicles Initiative co-produces
  the report; the iea.org download sits behind a bot check). verified. Page numbers below are PDF
  pages.
  - p. 16, Chapter 1: the electric car market grew "by 20% from 2024 to exceed 20 million sales",
    and "The sales share of electric cars in the overall car market increased to 25%." Footnote 2
    on the same page: "the term electric vehicle is used to refer to both battery electric and
    plug-in hybrid electric vehicles (PHEVs)", so every IEA share here is BEV + PHEV.
  - p. 18: "More than 13 million electric cars were sold in China in 2025 … This lifted the
    electric car sales share to almost 55%."
  - p. 21: Europe "reaching a total of 4.2 million, or 28% of all new cars sold. In the European
    Union, electric car sales totalled almost 3 million and the EV sales share reached just under
    27%."
  - p. 17 (and the web chapter): US electric car sales "at around 1.5 million", "the sales share
    of electric cars remained relatively stable at just below 10%".
  - Figure 1.1 (p. 16), "Electric car sales globally and sales share for selected regions,
    2020-2025", plots the series, but its values are not in the PDF text.
- **[IEA-GEVO-2025]** IEA, *Global EV Outlook 2025*, chapter "Trends in electric car markets"
  (May 2025). [page](https://www.iea.org/reports/global-ev-outlook-2025/trends-in-electric-car-markets-2).
  verified (web chapter). 2024: "Electric car sales topped 17 million worldwide in 2024", "More
  than 20% of new cars sold worldwide were electric"; China "Almost half"; Europe "About one in
  five"; United States "more than 10%".
- **[IEA-GEVO-2024]** IEA, *Global EV Outlook 2024*, "Trends in electric cars" (April 2024).
  [page](https://www.iea.org/reports/global-ev-outlook-2024/trends-in-electric-cars). verified
  (web chapter). 2023: "around 18% of all cars sold"; China "more than one in three"; Europe
  "over one in five"; United States "one in ten".
- **[OWID-IEA-EVSHARE]** Our World in Data, *Share of new cars sold that are electric*, grapher
  CSV, data last updated 2026-06-15, citation "International Energy Agency. Global EV Outlook
  2026". [chart](https://ourworldindata.org/grapher/electric-car-sales-share);
  [CSV](https://ourworldindata.org/grapher/electric-car-sales-share.csv?v=1&csvType=full&useColumnShortNames=false).
  secondary (an aggregator republishing the IEA Global EV Data Explorer; the explorer itself and
  its API could not be downloaded from a script). Subtitle: "Electric cars include fully
  battery-electric and plug-in hybrids." Yearly series, percent of new car sales:

  | Year | China | Europe (IEA region) | EU-27 | United States | World |
  |---|---|---|---|---|---|
  | 2013 | 0.096 | 0.43 | 0.47 | 0.71 | 0.29 |
  | 2014 | 0.41 | 0.68 | 0.56 | 0.77 | 0.44 |
  | 2015 | 1.1 | 1.0 | 0.82 | 0.70 | 0.68 |
  | 2016 | 1.5 | 1.4 | 1.1 | 0.99 | 0.95 |
  | 2017 | 2.4 | 1.8 | 1.5 | 1.3 | 1.4 |
  | 2018 | 4.7 | 2.3 | 1.9 | 2.3 | 2.4 |
  | 2019 | 5.0 | 3.4 | 2.9 | 2.1 | 2.7 |
  | 2020 | 5.7 | 10 | 10 | 2.3 | 4.4 |
  | 2021 | 16 | 17 | 18 | 4.7 | 9.3 |
  | 2022 | 29 | 21 | 21 | 7.7 | 15 |
  | 2023 | 38 | 22 | 22 | 9.7 | 18 |
  | 2024 | 48 | 21 | 21 | 10 | 21 |
  | 2025 | 53 | 28 | 27 | 10 | 25 |

  Cross-check against the IEA's own text: 2023, 2024 and 2025 agree with [IEA-GEVO-2024],
  [IEA-GEVO-2025] and [IEA-GEVO-2026] for the world, Europe, the EU and the US. **China 2025
  disagrees**: the series gives 53 %, the GEVO 2026 text says "almost 55%" and "Close to 55%".
  Quote the report's wording on a slide and treat the 53 as the data file's value.
- **[ACEA-FY2025]** ACEA, *New car registrations: +1.8% in 2025; battery-electric 17.4% market
  share*, press release, 27 Jan 2026.
  [page](https://www.acea.auto/pc-registrations/new-car-registrations-1-8-in-2025-battery-electric-17-4-market-share/).
  verified. "Battery-electric cars accounted for 17.4% of the EU market share in 2025", "an
  increase from the low baseline of 13.6% one year earlier"; "plug-in-hybrid electric cars now
  represent 9.4% of EU car registrations, up from 7.2% last year." Scope: EU-27.
- **[EEA-CARS-2025-PROV]** European Environment Agency, *Average CO2 emissions from new cars and
  vans significantly decreased in 2025*, news item, 25 Jun 2026.
  [page](https://www.eea.europa.eu/en/newsroom/news/average-co2-emissions-from-new-cars-and-vans-significantly-decreased-in-2025).
  verified. New cars registered in the "European Union, Norway and Iceland" in 2025 averaged
  96.7 g CO2/km, down from 106.7 g CO2/km in 2024; "These data are based on the Worldwide
  Harmonized Light Vehicle Test Procedure (WLTP)"; the figures "remain provisional until vehicle
  manufacturers have been given the possibility to review them". BEVs were 18.9 % of new cars
  (14.4 % in 2024), PHEVs 9.7 % (7.1 %). Scope note: these BEV shares are EU + Norway + Iceland,
  which is why they sit above ACEA's EU-27 17.4 % and 13.6 %.
- **[EEA-CARS-IND]** EEA, *CO2 emissions performance of new passenger cars in Europe*, indicator,
  published 3 Aug 2026.
  [page](https://www.eea.europa.eu/en/analysis/indicators/co2-performance-of-new-passenger).
  verified. The text and Figure 1 still stop at 2024 (the 2025 provisional value above is not
  yet in the indicator): "In 2024, the average CO₂ emissions of newly registered passenger cars in
  the EU remained stable compared to 2023, at 106.7 gCO₂/km", BEV share "fell from 15.5% in 2023
  to 14.5% in 2024" (the 25 Jun 2026 news item gives 14.4 % for 2024). Test basis, from the
  indicator's methodology: "Until 2020, the assessment … was based on … (NEDC) … From 2021
  onwards, performance and target compliance is assessed on the basis of … (WLTP)". Targets:
  "For the years 2020-2024, the target is 95gCO2/km (NEDC), equivalent to around 115.1 gCO2/km
  (WLTP). From 2025 onwards … 93.6 gCO2/km until 2029, 49.5 gCO2/km from 2030 to 2034 and
  0 gCO2/km from 2035." The values of Figure 1, *Average CO₂ emissions from new passenger cars
  and future targets*, were read from the chart's data source on the EEA site
  ([JSON](https://www.eea.europa.eu/++api++/en/analysis/indicators/co2-performance-of-new-passenger/average-co2-emissions-from)).
  Scope: EU-27, Iceland (from 2018) and Norway (from 2019). g CO2/km:

  | Year | NEDC | WLTP | | Year | NEDC | WLTP |
  |---|---|---|---|---|---|---|
  | 2000 | 172.1 | | | 2013 | 126.7 | |
  | 2001 | 169.7 | | | 2014 | 123.4 | |
  | 2002 | 167.2 | | | 2015 | 119.5 | |
  | 2003 | 165.5 | | | 2016 | 118.1 | |
  | 2004 | 163.4 | | | 2017 | 118.5 | |
  | 2005 | 162.4 | | | 2018 | 120.8 | |
  | 2006 | 161.3 | | | 2019 | 122.3 | 148.2 |
  | 2007 | 158.7 | | | 2020 | 107.5 | 130.3 |
  | 2008 | 153.5 | | | 2021 | | 114.1 |
  | 2009 | 145.7 | | | 2022 | | 108.1 |
  | 2010 | 140.3 | | | 2023 | | 106.4 |
  | 2011 | 135.7 | | | 2024 | | 106.7 |
  | 2012 | 132.2 | | | 2025 | | 96.7 (provisional, [EEA-CARS-2025-PROV]) |

  2019 and 2020 have both bases. The NEDC → WLTP step (122.3 → 148.2 in 2019) is a change of test
  cycle, not of the fleet; a slide that joins the two lines must say so.

### 6.2 Batteries

- **[BNEF-2025]** BloombergNEF, *Lithium-Ion Battery Pack Prices Fall to $108 Per Kilowatt-Hour,
  Despite Rising Metal Prices: BloombergNEF*, press release, New York, 9 Dec 2025 (2025
  Lithium-Ion Battery Price Survey).
  [page](https://about.bnef.com/insights/commodities/lithium-ion-battery-pack-prices-fall-to-108-per-kilowatt-hour-despite-rising-metal-prices/).
  verified. "lithium-ion battery pack prices have dropped 8% since 2024 to a record low of $108
  per kilowatt-hour". "Battery electric vehicles (BEVs) packs were the cheapest in the transport
  segment at $99/kWh – the second year that they were below the $100/kWh threshold." "Average LFP
  battery pack prices across all segments came in at $81/kWh while nickel manganese cobalt (NMC)
  packs were at $128/kWh." Stationary storage $70/kWh (−45 %). China $84/kWh; North America and
  Europe 44 % and 56 % higher. No LFP/NMC cell prices are given. The release's chart
  ([image](https://assets.bbhub.io/professional/sites/44/lithium_11.png)), *Volume-weighted
  average lithium-ion battery pack and cell price split, 2013-2025*, gives the whole series in
  **real 2025 $/kWh**, one basis: "Historical prices have been updated to reflect real 2025
  dollars. Weighted average survey value for 2025 includes 320 data points from passenger cars,
  buses, commercial vehicles, two- and three-wheelers and stationary storage." Read from the bar
  labels (exact printed values):

  | Year | Pack | of which cell | of which pack (rest) |
  |---|---|---|---|
  | 2013 | 827 | 568 | 259 |
  | 2014 | 734 | 498 | 236 |
  | 2015 | 475 | 318 | 157 |
  | 2016 | 365 | 266 | 99 |
  | 2017 | 273 | 192 | 81 |
  | 2018 | 224 | 161 | 63 |
  | 2019 | 194 | 136 | 58 |
  | 2020 | 169 | 126 | 43 |
  | 2021 | 159 | 122 | 37 |
  | 2022 | 170 | 136 | 34 |
  | 2023 | 148 | 114 | 34 |
  | 2024 | 118 | 78 | 40 |
  | 2025 | 108 | 74 | 34 |

  The 2024 value here (118, real 2025 $) is not the $115/kWh BNEF announced in Dec 2024 (real
  2024 $): each survey restates the whole history in its own year's dollars. Use this one series
  rather than mixing per-year press releases. It is an all-segment average (EVs, buses,
  two-wheelers and storage), not EV-only. The public chart starts in 2013; no 2010 value is
  published in this release.
- **[IEA-GEVO-2026] battery chapter** (as above).
  - p. 96, Chapter 5: "In 2025, LFP batteries accounted for over 55% of EV batteries deployed
    globally, up from nearly 50% in 2024." EU: "more than 10% of EV battery demand in 2025";
    US share "almost halved in 2025". Figure 5.5 note: chemistry share "is based on the battery
    capacity of new electric vehicles registered"; two/three-wheelers excluded.
  - p. 101: "The latest sodium-ion cells can reach up to 175 Wh/kg, compared with up to 205 Wh/kg
    for the latest generation of LFP batteries and 265 Wh/kg for lithium nickel cobalt manganese
    oxide (NMC) batteries." The sentence opens with cells, so these read as cell-level best
    values, but the IEA does not say "cell" for LFP and NMC explicitly; "up to" means best in
    class, not fleet average.
  - p. 92: "In 2025, EV battery deployment reached 1.2 TWh".
  - p. 173: "Over the past decade, average EV battery pack energy density (Wh/kg) has increased by
    around 60%, while prices have fallen by roughly 75%."

- **[N-US-DG-2018]** Nissan North America, *2018 LEAF Dismantling Guide*, §2-1.1 "High-Voltage
  Battery Pack Specifications", PDF p. 11 (DG-11).
  [PDF](https://owners.nissanusa.com/content/techpub/ManualsAndGuides/LEAF/2018/2018-leaf-dismantling-guide.pdf).
  verified. "High-voltage battery weight US: 668.1 lbs (303 kg), Canada: 672.5 lbs (305 kg)";
  dimensions 1547 × 1188 × 264 mm; voltage "(240V - 420V usable range)". The MY2018 US LEAF is the
  ZE1 and was sold only with the 40 kWh pack; the 2019 guide repeats the same table. derived: 40 kWh
  nominal / 303 kg ≈ **132 Wh/kg at pack level** (about 0.13 kWh/kg; with the ~39.5 kWh that
  third parties compute from cell data, 130 Wh/kg). The same table gives "48" modules, which
  contradicts the 24 modules × 8 cells that secondary teardown reports give for the 40 kWh pack
  (InsideEVs, 1 Aug 2018); the module count is not used.
- **[IEA-GEVO-2025] batteries** IEA, *Global EV Outlook 2025*, "Electric vehicle batteries".
  [page](https://www.iea.org/reports/global-ev-outlook-2025/electric-vehicle-batteries). verified
  (web chapter). Pack level, relative only: "The energy density of LFP battery packs is about
  one-fifth lower by mass (Wh/kg)" and "about one-third lower by volume (Wh/L) than that of NMC
  packs." No absolute pack Wh/kg is given.
- **[IEA-BSET-2024]** IEA, *Batteries and Secure Energy Transitions*, 25 Apr 2024.
  [PDF](https://www.iea.org/files/cb39c1bf-d2b3-446d-8c35-aae6b1f3a4a0/BatteriesandSecureEnergyTransitions.pdf).
  verified. PDF p. 21: "lithium-ion batteries today have a demonstrated range of specific energies
  around 90-300 Wh/kg at the cell level". PDF p. 26: LFP "has a significantly lower energy density,
  conventionally 20-30% lower than high nickel chemistries at battery cell level". Again relative,
  not a typical absolute value per chemistry.
- **[MCK-2024]** McKinsey & Company, *The battery chemistries powering the future of electric
  vehicles* (2024).
  [page](https://www.mckinsey.com/industries/automotive-and-assembly/our-insights/the-battery-chemistries-powering-the-future-of-electric-vehicles).
  search summary (consultancy, not read in full): the NMC-LFP gap is "about 30 percent" at cell
  level, dropping "to 5 to 20 percent at pack level"; the average pack energy density of top-selling
  LFP vehicles rose from about 80 Wh/kg in 2014 to approximately 140 Wh/kg in 2023.
- **Typical pack-level Wh/kg, summary.** No primary source found that states a typical absolute
  pack value for current NMC and LFP packs. What the primaries support: best cells today up to
  ~265 Wh/kg (NMC) and ~205 Wh/kg (LFP) ([IEA-GEVO-2026] p. 101); LFP packs about 20 % lower in
  Wh/kg than NMC packs ([IEA-GEVO-2025]); a 2018 NMC-class Leaf pack at ~132 Wh/kg
  ([N-US-DG-2018], derived). CATL's 2022 Qilin claims (up to 255 Wh/kg NMC, 160 Wh/kg LFP) reached
  only through trade press (CnEVPost, 23 Jun 2022), which does not say whether they are cell- or
  pack-level; not used.

### 6.3 Charging and grid

- **[IEA-GEVO-2026] charging** (as above), p. 110, Chapter 6: "nearly 1.8 million public charging
  points were added to the global stock, representing an increase of more than 33% … The total
  stock of public charging points worldwide reached more than 7 million at the end of 2025";
  "around 11 electric LDVs worldwide per public charging point"; "4.5 kilowatts (kW) of public
  charging capacity per electric LDV". verified.
- **[EEA-ELEC-GHG]** EEA, *Greenhouse gas emission intensity of electricity generation in Europe*,
  indicator, published 10 Jul 2026.
  [page](https://www.eea.europa.eu/en/analysis/indicators/greenhouse-gas-emission-intensity-of-1).
  verified. Latest year 2024: Figure 1 (EU level) gives **183.44 g CO2e/kWh** of gross
  electricity generation (2023: 205.65; 2010: 333.90; 1990: 500.56), read from the chart's data
  source ([JSON](https://www.eea.europa.eu/++api++/en/analysis/indicators/greenhouse-gas-emission-intensity-of-1/greenhouse-gas-emission-intensity-1)).
  Text: "Generating one kilowatt hour has emitted 11% less emissions in 2024 on average than in
  2023, and 41% less than a decade ago"; "In 2024, the EU's electricity sector was 63% less GHG
  intensive than it was in 1990". This is generation, not consumption (imports are not
  counted). The country chart's data source also holds a column labeled 2025 (EU 178), but the
  chart's series are named 2024, 2010, 2000 and 1990 and the text says nothing about 2025, so that
  column is not used.
- **[EU-AFIR]** Regulation (EU) 2023/1804 on the deployment of alternative fuels infrastructure,
  and repealing Directive 2014/94/EU, 13 Sep 2023, OJ L 234, 22.9.2023.
  [ELI](http://data.europa.eu/eli/reg/2023/1804/oj). verified (OJ XHTML read from the
  Publications Office Cellar, `publications.europa.eu/resource/celex/32023R1804`; EUR-Lex
  answered scripted requests, ELI URLs included, with a WAF challenge).
  - Art. 3(1), fleet-based: "at the end of each year, starting from 2024 … for each light-duty
    battery electric vehicle registered in their territory, a total power output of at least
    1,3 kW is provided through publicly accessible recharging stations"; 0.80 kW per light-duty
    PHEV. Art. 3(2): a Member State may ask to lower it once BEVs are at least 15 % of its
    light-duty fleet.
  - Art. 3(4)(a), TEN-T core network: pools "in each direction of travel with a maximum distance
    of 60 km between them"; by 31 Dec 2025 each pool ≥ 400 kW with at least one point ≥ 150 kW;
    by 31 Dec 2027 ≥ 600 kW with at least two points ≥ 150 kW.
  - Art. 3(4)(b), comprehensive network, same 60 km: 300 kW pools with one 150 kW point on ≥ 50 %
    of the length by 31 Dec 2027 and on all of it by 31 Dec 2030; 600 kW with two 150 kW points
    by 31 Dec 2035.
  - Art. 26: applies from 13 April 2024.

### 6.4 EU regulations

EUR-Lex refused every scripted download (WAF challenge, HTTP 202), ELI URLs included. The texts
below were read as Official Journal XHTML/PDF from the Publications Office Cellar
(`http://publications.europa.eu/resource/celex/<CELEX>`), the same OJ text EUR-Lex serves; entries
cite the ELI URL. Amendments were read from the amending acts, not from a consolidated version.

- **[EU-2019/631]** Regulation (EU) 2019/631 setting CO₂ emission performance standards for new
  passenger cars and for new light commercial vehicles, and repealing Regulations (EC) No 443/2009
  and (EU) No 510/2011, 17 Apr 2019, OJ L 111, 25.4.2019, p. 13.
  [ELI](http://data.europa.eu/eli/reg/2019/631/oj). verified.
  - Art. 1(2): "From 1 January 2020, this Regulation sets an EU fleet-wide target of 95 g CO₂/km
    for the average emissions of new passenger cars … as measured until 31 December 2020 in
    accordance with Regulation (EC) No 692/2008 [NEDC] … and from 1 January 2021 measured in
    accordance with Regulation (EU) 2017/1151 [WLTP]."
  - Art. 1(4)(a): from 1 Jan 2025, "a 15 % reduction of the target in 2021". Art. 1(5)(a) as
    adopted: 37.5 % from 2030 (raised to 55 % by [EU-2023/851]).
  - Annex I, Part A, point 6.0: the "EU fleet-wide target 2021" is a WLTP value built per
    manufacturer from its WLTP-measured 2020 cars scaled by 95 g/km over its NEDC CO₂. So the 2025
    and 2030 steps are percentages of a WLTP-based 2021 reference, not of 95 g NEDC. derived:
    93.6/0.85 ≈ 49.5/0.45 ≈ 110 g/km WLTP; no act prints this number. (The EEA quotes "around
    115.1 gCO2/km (WLTP)" as the WLTP equivalent of 95 NEDC for 2020-2024, [EEA-CARS-IND]; that is
    a different construct from the 2021 reference.)
  - Art. 8(2): excess emissions premium "(Excess emissions × EUR 95) × number of newly registered
    vehicles".
- **[EU-2023/851]** Regulation (EU) 2023/851 amending Regulation (EU) 2019/631 as regards
  strengthening the CO₂ emission performance standards for new passenger cars and new light
  commercial vehicles in line with the Union's increased climate ambition, 19 Apr 2023, OJ L 110,
  25.4.2023, p. 5. [ELI](http://data.europa.eu/eli/reg/2023/851/oj). verified.
  - Art. 1(1)(a)(i): in Art. 1(5)(a), "the figure '37,5 %' is replaced by '55 %'" (cars, 2030);
    vans 31 % → 50 %.
  - New Art. 1(5a): "From 1 January 2035 … for the average emissions of the new passenger car
    fleet, an EU fleet-wide target equal to a 100 % reduction of the target in 2021".
  - New Art. 1(6): zero- and low-emission benchmark 25 % (cars) and 17 % (vans) for 2025-2029;
    the incentive ends 1 Jan 2030.
  - Review clause, Art. 15(1) as replaced: "The Commission shall, in 2026, review the
    effectiveness and impact of this Regulation … assess progress … towards achieving the
    reduction targets set out in Article 1(5a) … including as regards plug-in hybrid technologies
    … Based on that assessment, the Commission shall assess the need to review the targets set out
    in Article 1(5a)." Also: Art. 7(2) report on a real-world CO₂ adjustment mechanism by 31 Dec
    2026; Art. 14a biennial progress reports from 31 Dec 2025.
- **[EU-ID-2023/1623]** Commission Implementing Decision (EU) 2023/1623 of 3 Aug 2023, OJ L 200,
  10.8.2023, p. 5. [ELI](http://data.europa.eu/eli/dec_impl/2023/1623/oj). verified. Annex II,
  Part A, point 1 (cars, WLTP): "EU fleet-wide target 2025: 93,6 g CO₂/km"; "EU fleet-wide target
  2030: 49,5 g CO₂/km". Vans: 153.9 and 90.6 g/km.
- **[EU-2025/1214]** Regulation (EU) 2025/1214 amending Regulation (EU) 2019/631 to include an
  additional flexibility as regards the calculation of manufacturers' compliance with CO₂ emission
  performance standards for new passenger cars and new light commercial vehicles for the calendar
  years 2025 to 2027, 17 Jun 2025, OJ L 2025/1214, 19.6.2025.
  [ELI](http://data.europa.eu/eli/reg/2025/1214/oj). verified (number and date confirmed).
  New Art. 4(1a): "for the three-year period comprising the calendar years 2025 to 2027, a
  manufacturer, including when it is a member of a pool, shall ensure that its average specific
  emissions of CO₂ over that period do not exceed its specific emissions target over that period".
  The excess premium is assessed over 2025-2027 (Art. 8(1)). Recital 2: "while maintaining the
  targets for reducing CO₂ emissions".
- **[EU-COM-2025-995]** European Commission, Proposal for a Regulation amending Regulation (EU)
  2019/631 as regards CO₂ emission performance standards for new light duty vehicles and vehicle
  labelling and repealing Directive 1999/94/EC, COM(2025) 995 final, procedure 2025/0420(COD),
  16 Dec 2025 (part of the automotive package). PDF via Cellar, CELEX 52025PC0995. verified.
  - Art. 1(1)(b), replacing Art. 1(5a): "From 1 January 2035 … an EU fleet-wide target equal to a
    90% reduction of the target in 2021" (cars and vans).
  - Recitals 9-10: the 90 % holds "provided that the remaining emissions are compensated by the use
    of low-carbon steel credits or sustainable renewable fuel credits", capped at "up to 10% of the
    EU fleet-wide target of 2021".
  - Also: vans 2030 50 % → 40 %; three-year averaging for 2030-2032; super-credits for small
    EU-made EVs to 2034; proposed Art. 15(1) review "In 2035 and every five years thereafter".
- **[EP-OEIL-2025/0420]** European Parliament Legislative Observatory, procedure file
  2025/0420(COD), read 1 Nov 2026.
  [page](https://oeil.europarl.europa.eu/oeil/en/procedure-file?reference=2025/0420(COD)). verified.
  Stage "Awaiting committee decision"; committee referral 9 Feb 2026; plenary first reading
  forecast 14 Dec 2026. The EP Legislative Train page (as of 20 Sep 2026,
  [page](https://www.europarl.europa.eu/legislative-train/package-automotive-package/file-co2-emission-standards-for-new-light-duty-vehicles-and-labelling))
  gives rapporteur Massimiliano Salini (EPP), draft report 17 Apr 2026, plenary "expected on 23
  November 2026", Council general approach "Expected 11 Dec 2026".
- **[CONS-10065/26]** Council of the EU, *Proposal … amending Regulation (EU) 2019/631 – Progress
  report*, 10065/1/26 REV 1, 15 Jun 2026.
  [PDF](https://data.consilium.europa.eu/doc/document/ST-10065-2026-REV-1/en/pdf). verified.
  "Positions that have been expressed diverge widely"; "a number of delegations … wish to stick to
  the current 100% targets"; "broad support to the three-year averaging for compliance to the 2030
  target".
- **Status of the 2035 revision on 1 Nov 2026**: not adopted. The law in force is still −100 % from
  2035 ([EU-2023/851]). Open question: a secondary report (evlife.world, late Oct 2026) says two EP
  committees backed a compromise of 95 % with up to 7.5 points of steel credits; no primary page
  confirms it. Latest primary documents: OEIL (read 1 Nov 2026) and the Council progress report
  (15 Jun 2026).
- **[EU-EURO7]** Regulation (EU) 2024/1257 on type-approval of motor vehicles and engines … with
  respect to their emissions and battery durability (Euro 7), 24 Apr 2024, OJ L 2024/1257,
  8.5.2024. [ELI](http://data.europa.eu/eli/reg/2024/1257/oj). verified.
  - Dates, Art. 21 and Art. 10(4)-(5): applies "from 29 November 2026 for new types of vehicles of
    categories M₁ and N₁ … and from 29 November 2027 for new vehicles of categories M₁ and N₁".
    Small-volume manufacturers: 1 Jul 2030. Heavy duty: 29 May 2028 / 29 May 2029.
  - Brake PM₁₀ until 31 Dec 2029, Annex I Table 4 (M₁ and N₁ except N₁ Class III), mg/km per
    vehicle: PEV (battery-electric) 3; OVC-HEV (plug-in hybrid) 7; NOVC-HEV (hybrid) 7; FCV 7;
    ICEV 7. N₁ Class III: PEV 5, others 11. From 1 Jan 2030 (Table 5): left blank pending the
    Art. 18(5) review. From 1 Jan 2035 (Table 8): "3 mg/km per vehicle" for M₁ and N₁, all
    powertrains.
  - Tyre abrasion: Annex I Table 9 has no numeric limits; they come from UN WP.29, or a Commission
    delegated act if WP.29 had not adopted them by 1 Jul 2026 for C1 tyres (Art. 15(3)). Dates
    (Art. 11(4)-(6), Art. 21): C1 new types 1 Jul 2028, all C1 tyres 1 Jul 2030 (sell-off to 30
    Jun 2032); C2 1 Apr 2030 / 1 Apr 2032; C3 1 Apr 2032 / 1 Apr 2034.
  - Battery durability, Annex II Table 1 (M₁, OVC-HEV and PEV alike), energy-based minimum
    performance requirement: "80 %" from start of life to 5 years or 100 000 km, whichever comes
    first; "72 %" beyond that up to 8 years or 160 000 km. N₁ (Table 2): 75 % and 67 %.
- **[EU-IR-2025/1706]** Commission Implementing Regulation (EU) 2025/1706 of 25 Jul 2025 (exhaust
  and evaporative emission type-approval of M₁ and N₁ under 2024/1257), OJ L 2025/1706, 5.9.2025,
  [ELI](http://data.europa.eu/eli/reg_impl/2025/1706/oj); companion Implementing Regulation (EU)
  2025/1707 of 25 Jul 2025 (OBFCM/OBM, driver warning, environmental vehicle passport). verified
  (titles and dates).
- **[EU-IR-2026/1762]** Commission Implementing Regulation (EU) 2026/1762 of 13 Jul 2026 (brake
  particle emissions of M₁ and N₁ under 2024/1257), OJ L 2026/1762, 22.7.2026.
  [ELI](http://data.europa.eu/eli/reg_impl/2026/1762/oj). verified (title, dates). Also Commission
  Delegated Regulation (EU) 2026/1214 of 9 Jun 2026 (OJ 3.9.2026), which moves the Euro 7 brake
  test reference from GTR No 24 to UN Regulation No 179; limit values unchanged. Note the number
  clash: delegated 2026/1214 is not the CO₂ Regulation 2025/1214.
- **[EU-BATT]** Regulation (EU) 2023/1542 concerning batteries and waste batteries, 12 Jul 2023,
  OJ L 191, 28.7.2023, p. 1. [ELI](http://data.europa.eu/eli/reg/2023/1542/oj). verified.
  - Carbon footprint, Art. 7(1): EV-battery declaration in kg CO₂e per kWh of total energy over
    the service life, from "18 February 2025 or 12 months after the date of entry into force
    either of the delegated act or of the implementing act … whichever is the latest" (acts due
    "by 18 February 2024"). Performance classes, Art. 7(2): "18 August 2026 or 18 months after"
    the class act. Maximum threshold, Art. 7(3): "18 February 2028 or 18 months after" its act.
  - Recycled content in active materials (EV, industrial > 2 kWh, SLI), Art. 8(2)-(3): from 18 Aug
    2031 "16 % cobalt; 85 % lead; 6 % lithium; 6 % nickel"; from 18 Aug 2036 "26 % cobalt; 85 %
    lead; 12 % lithium; 15 % nickel".
  - Battery passport, Art. 77(1): "From 18 February 2027 each LMT battery, each industrial battery
    with a capacity greater than 2 kWh and each electric vehicle battery placed on the market or
    put into service shall have an electronic record ('battery passport')".
  - Annex XII Part B, recycling efficiency, lithium-based: ≥ 65 % by average weight by 31 Dec 2025,
    70 % by 31 Dec 2030 (lead-acid 75 %, 80 %). Part C, material recovery: by 31 Dec 2027 Co, Cu,
    Pb, Ni 90 %, Li 50 %; by 31 Dec 2031 Co, Cu, Pb, Ni 95 %, Li 80 %.
- **[EU-HYS-13877]** European Commission, Have Your Say initiative 13877, *Carbon footprint
  methodology for electric vehicle batteries*, Ares(2023)4174225, record read 1 Nov 2026.
  [page](https://ec.europa.eu/info/law/better-regulation/have-your-say/initiatives/13877-Carbon-footprint-methodology-for-electric-vehicle-batteries_en).
  verified (Better Regulation API record). Draft delegated act published for feedback 30 Apr
  2024; adoption stage "UPCOMING", planned Q3 2025, no adoption date. So the methodology act is
  not adopted and, by Art. 7(1)'s "whichever is the latest", the EV carbon-footprint declaration
  is not yet applicable; the class and threshold dates slide with it.
- **[EU-2025/1561]** Regulation (EU) 2025/1561 amending Regulation (EU) 2023/1542 as regards
  obligations of economic operators concerning battery due diligence policies, 18 Jul 2025, OJ L
  2025/1561, 30.7.2025. [ELI](http://data.europa.eu/eli/reg/2025/1561/oj). verified. Art. 48(1):
  "the date '18 August 2025' is replaced by '18 August 2027'"; Commission guidance moves to 26 Jul
  2026.
- **[EP-LT-OMNIBUS-VIII]** EP Legislative Train, *Omnibus VIII: industrial emissions, reporting,
  batteries*, COM(2025) 981, 2025/0397(COD), as of 20 Sep 2026.
  [page](https://www.europarl.europa.eu/legislative-train/theme-a-new-plan-for-europe-s-sustainable-prosperity-and-competitiveness/file-omnibus-viii-industrial-emissions-reporting-batteries).
  verified. Status "Tabled"; ENVI vote planned early Nov 2026. Its changes to 2023/1542 do not
  touch the carbon-footprint, passport or due-diligence dates.

### 6.5 US regulations

Federal Register pages were read through the FR API and full-text XML (the website blocks scripted
requests); page numbers come from the XML. Public Laws were read on govinfo.

- **[EPA-MP-2024]** US EPA, *Multi-Pollutant Emissions Standards for Model Years 2027 and Later
  Light-Duty and Medium-Duty Vehicles*, final rule, 89 FR 27842, 18 Apr 2024 (effective 17 Jun
  2024), FR doc. 2024-06214, RIN 2060-AV49.
  [FR](https://www.federalregister.gov/documents/2024/04/18/2024-06214/multi-pollutant-emissions-standards-for-model-years-2027-and-later-light-duty-and-medium-duty-vehicles).
  verified. Abstract: standards "will phase-in over model years 2027 through 2032", plus "battery
  durability and warranty requirements for light- duty and medium-duty electric and plug-in hybrid
  electric vehicles". p. 27907: "an industry-wide average target for the light-duty fleet of 85
  g/mile of CO2 in MY 2032", "49 percent lower than that of the MY 2026 standards". Its GHG part
  was repealed by [EPA-EF-RESC-2026]; the Tier 4 criteria-pollutant part stands, subject to
  [EPA-T4-2026].
- **[EPA-EF-PROP-2025]** US EPA, *Reconsideration of 2009 Endangerment Finding and Greenhouse Gas
  Vehicle Standards*, proposed rule, 90 FR 36288, 1 Aug 2025, FR doc. 2025-14572.
  [FR](https://www.federalregister.gov/documents/2025/08/01/2025-14572/reconsideration-of-2009-endangerment-finding-and-greenhouse-gas-vehicle-standards).
  verified (FR record).
- **[EPA-EF-RESC-2026]** US EPA, *Rescission of the Greenhouse Gas Endangerment Finding and Motor
  Vehicle Greenhouse Gas Emission Standards Under the Clean Air Act*, final rule, 91 FR 7686,
  18 Feb 2026 (effective 20 Apr 2026), FR doc. 2026-03157, RIN 2060-AW71.
  [FR](https://www.federalregister.gov/documents/2026/02/18/2026-03157/rescission-of-the-greenhouse-gas-endangerment-finding-and-motor-vehicle-greenhouse-gas-emission).
  verified. Abstract: "rescinding the Administrator's 2009 findings of contribution and
  endangerment and repealing all greenhouse gas (GHG) emission standards for light-duty,
  medium-duty, and heavy-duty vehicles and engines". Litigation: petitions in the D.C. Circuit
  (due by 20 Apr 2026, p. 7688); 40 states, counties and cities led by New York filed (NY AG
  release, 19 Mar 2026, [page](https://ag.ny.gov/press-release/2026/attorney-general-james-leads-challenge-trump-administrations-climate-rollback),
  verified); docket numbers 26-1061 (states) and 26-1037 (groups) and pending motions to delay
  briefing are from a Jones Day alert of 22 Jun 2026 (secondary). No ruling found as of 1 Nov
  2026.
- **[EPA-T4-2026]** US EPA, *Revision of Tier 4 Criteria Pollutant Standards, Part 1: Amendments
  to Phase-In Schedule for Light-Duty and Medium-Duty Vehicles*, proposed rule, 91 FR 28463,
  18 May 2026, FR doc. 2026-09905.
  [FR](https://www.federalregister.gov/documents/2026/05/18/2026-09905/revision-of-tier-4-criteria-pollutant-standards-part-1-amendments-to-phase-in-schedule-for).
  verified. Would "extend the Tier 3 standards for certain vehicles to model years (MYs) 2027 and
  2028 such that the Tier 4 standards for these vehicles would phase in starting with MY 2029". No
  final rule found on 1 Nov 2026.
- **[NHTSA-CAFE-2024]** NHTSA, *Corporate Average Fuel Economy Standards for Passenger Cars and
  Light Trucks for Model Years 2027 and Beyond and Fuel Efficiency Standards for Heavy-Duty Pickup
  Trucks and Vans for Model Years 2030 and Beyond*, final rule, 89 FR 52540, 24 Jun 2024, FR doc.
  2024-12864.
  [FR](https://www.federalregister.gov/documents/2024/06/24/2024-12864/corporate-average-fuel-economy-standards-for-passenger-cars-and-light-trucks-for-model-years-2027).
  verified. "2 percent per year for passenger cars in model years (MYs) 2027-31, 0 percent per year
  for light trucks in model years 2027-28, and 2 percent per year for light trucks in model years
  2029-31"; p. 52548: "roughly 50.4 mpg in MY 2031". Replaced by [NHTSA-SAFE3-2026].
- **[NHTSA-RESET-2025]** NHTSA, *Resetting the Corporate Average Fuel Economy Program*,
  interpretive rule, 90 FR 24518, 11 Jun 2025, FR doc. 2025-10586.
  [FR](https://www.federalregister.gov/documents/2025/06/11/2025-10586/resetting-the-corporate-average-fuel-economy-program).
  verified.
- **[PL-119-21]** Public Law 119-21 (H.R. 1, the 2025 reconciliation act), 4 Jul 2025.
  [govinfo](https://www.govinfo.gov/content/pkg/PLAW-119publ21/html/PLAW-119publ21.htm). verified.
  Sec. 40006, "Corporate Average Fuel Economy Civil Penalties" (139 Stat. 136): amends 49 U.S.C.
  32912(b) "by striking ``$5'' and inserting ``$0.00''" and (c)(1)(B) from $10 to $0.00. Sec.
  70502, "Termination of Clean Vehicle Credit" (139 Stat. 250): 30D(h) "by striking ``placed in
  service after December 31, 2032'' and inserting ``acquired after September 30, 2025''". Same
  law: 25E (used) and 45W (commercial) end after 30 Sep 2025; 30C (charging property) after 30 Jun
  2026.
- **[NHTSA-SAFE3-2025]** NHTSA, *The Safer Affordable Fuel-Efficient (SAFE) Vehicles Rule III for
  Model Years 2022 to 2031 Passenger Cars and Light Trucks*, proposed rule, 90 FR 56438, 5 Dec
  2025, FR doc. 2025-22014.
  [FR](https://www.federalregister.gov/documents/2025/12/05/2025-22014/the-safer-affordable-fuel-efficient-safe-vehicles-rule-iii-for-model-years-2022-to-2031-passenger).
  verified. "0.5 percent per year through MY 2026, followed by 0.25 percent per year through MY
  2031", "roughly 34.5 miles per gallon (mpg) in MY 2031".
- **[NHTSA-SAFE3-2026]** NHTSA, same title, final rule, 91 FR 61988, 30 Sep 2026 (effective 30 Nov
  2026), FR doc. 2026-19964.
  [FR](https://www.federalregister.gov/documents/2026/09/30/2026-19964/the-safer-affordable-fuel-efficient-safe-vehicles-rule-iii-for-model-years-2022-to-2031-passenger).
  verified. p. 61997: passenger cars "0.90 percent per year through MY 2029 followed by one percent
  per year through MY 2031", light trucks "0.51 percent per year through MY 2029 followed by one
  percent per year through MY 2031"; credit trading eliminated "beginning with credits earned in
  MY 2028". p. 61999: "roughly 34.9 mpg in MY 2031 for passenger cars and light trucks".
- **[CRA-CA-2025]** Public Laws 119-15, 119-16 and 119-17 (H.J. Res. 87, 88, 89), 12 Jun 2025,
  139 Stat. 65-67. [PL 119-16](https://www.govinfo.gov/content/pkg/PLAW-119publ16/html/PLAW-119publ16.htm)
  (ACC II), verified: "Congress disapproves the rule … ``California State Motor Vehicle and Engine
  Pollution Control Standards; Advanced Clean Cars II; Waiver of Preemption; Notice of Decision''
  (90 Fed. Reg. 642 (January 6, 2025)), and such rule shall have no force or effect." PL 119-15:
  Advanced Clean Trucks waiver; PL 119-17: Omnibus Low NOx waiver. California and 10 states sued
  the same day (CA AG release, 12 Jun 2025,
  [page](https://oag.ca.gov/news/press-releases/california-will-not-waver-defending-itself-federal-overreach-attorney-general),
  verified); *California v. United States*, N.D. Cal. No. 4:25-cv-04966-HSG (search summary). No
  merits ruling found.

### 6.6 Vehicles

- **[N-GL-LEAF-EU-2018]** Nissan Global newsroom, *Nissan LEAF tops electric car sales in Europe*,
  18 Jul 2018. [page](https://global.nissannews.com/ja-JP/releases/nissan-leaf-tops-electric-car-sales-in-europe).
  verified. "The car's larger, 40 kilowatt-hour battery delivers a combined driving cycle range of
  270 kilometers" under WLTP. This is the first primary source for the 270 km in §0; the WLTP
  consumption (17.1 kWh/100 km) still rests on ADAC/EV Database.
- **[N-GL-LEAF3]** Nissan Global newsroom, *All-new 3rd generation Nissan LEAF*, 17 Jun 2025
  (spec table 250617-01-e).
  [page](https://global.nissannews.com/en/releases/all-new-3rd-generation-nissan-leaf_tab).
  verified. 52 kWh battery (52.9 kWh usable): "130 kW (~174hp) and 345 Nm"; 75 kWh (75.1 kWh
  usable): "160 kW (~214hp) and 355 Nm"; US "estimated to deliver a maximum range of up to 303
  miles", "subject to homologation". US retail from autumn 2025; built at Tochigi and Sunderland.
- **[LEAF-ZE1-END]** Sunderland ended ZE1 production in the week of 29 Feb 2024, after more than
  270,000 cars. [electrive, 1 Mar 2024](https://electrive.com/2024/03/01/nissan-leaf-production-draws-to-a-close-in-sunderland);
  [Electrek, 29 Feb 2024](https://electrek.co/2024/02/29/nissan-ends-leaf-production-uk-new-evs/).
  secondary; no Nissan release found. The ZE1 is superseded by the third generation at both
  plants; Japan/US ZE1 end dates not verified.
- **[TOYOTA-DF-2018]** Toyota Motor Corporation, TNGA powertrain 2018, engine page (2.0 L Dynamic
  Force). [page](https://global.toyota/en/mobility/tnga/powertrain2018/engine/). verified. Maximum
  thermal efficiency "40% (Conventional Engine)" and "41% (HV Engine)", "As of February 2018". The
  deck's "about 30 % at its best" understates a modern production petrol engine's peak; "about
  40 % at its best, far less on average in real driving" matches the source.

### 6.7 Power switches (section 05, "Which switch")

Read 1 Nov 2026 from current manufacturer datasheets; the drops in volts are datasheet resistance
times current (derived). The deck's switch table is built from these rows.

#### Automotive Si IGBT traction module (400 V class)

- **[IFX-FS820]** Infineon, *FS820R08A6P2B HybridPACK Drive Module, Final Data Sheet* (V3.1, 2019-10-10). [page](https://www.infineon.com/assets/row/public/documents/10/49/infineon-fs820r08a6p2b-datasheet-en.pdf). verified.
  - Six-pack (3-phase bridge), "EDT2 IGBT and Diode", "optimized for applications with switching frequencies in the range of 10 kHz" (p. 2, description).
  - V_CES = 750 V (T_vj = 25 °C). I_CN (implemented) = 820 A; I_C nom (continuous DC, T_F = 80 °C) = 450 A; I_CRM = 1640 A (1 ms) (Table 2.1).
  - V_CE(sat), V_GE = 15 V (Table 2.2): at 450 A: 1.10 V typ / 1.35 V max (25 °C), 1.15 V typ (150 °C), 1.15 V typ (175 °C). At 820 A: 1.30 V typ (25 °C), 1.50 V typ (175 °C). **No 150 °C value at 820 A is given.**
  - Switching, inductive load, I_C = 450 A, V_CE = 400 V, V_GE = −8/+15 V, R_Gon = 2.4 Ω, R_Goff = 5.1 Ω, L_S = 20 nH:
    E_on = 13.5 / 17.5 / 18.0 mJ and E_off = 23.5 / 29.0 / 30.0 mJ at T_vj = 25 / 150 / 175 °C.
    t_r = 0.07 / 0.08 µs, t_f = 0.04 / 0.05 µs, t_d(on) = 0.28 / 0.29 µs, t_d(off) = 0.94 / 1.05 µs (25 / 150 °C).
  - T_vj op = −40…150 °C continuous; 175 °C "for 10 s within a period of 30 s, occurrence maximum 3000 times over lifetime".
  - Derived: conduction drop × current at 450 A, 150 °C ≈ 1.15 V × 450 A ≈ 0.52 kW per switch (plus diode/switching losses).

#### Automotive SiC MOSFET traction module (800 V class)

- **[IFX-FS03MR]** Infineon, *FS03MR12A6MA1B HybridPACK Drive module with CoolSiC Automotive MOSFET, Datasheet* (rev. 1.00, 2021-03-23). [page](https://www.infineon.com/assets/row/public/documents/10/49/infineon-fs03mr12a6ma1b-datasheet-en.pdf). verified. Same package as [IFX-FS820]; distributors (Arrow) list the B variant as NRND, the "L" variant FS03MR12A6MA1LB as active (search summary).
  - V_DSS = 1200 V; I_D nom = 400 A (V_GS = 15 V, T_F = 60 °C, T_vj max = 175 °C); I_D pulse = 800 A (Table 3).
  - R_DS(on) at I_D = 400 A, V_GS = 15 V: 2.75 mΩ typ / 3.70 mΩ max (25 °C), 4.00 mΩ (125 °C), 4.55 mΩ (150 °C) (Table 4).
    Derived drop at 400 A: 1.10 V typ (25 °C), 1.48 V max (25 °C), 1.82 V typ (150 °C).
  - Switching, I_D = 400 A, V_DS = 600 V, V_GS = −5/+15 V, R_G = 5.1 Ω, L_σ = 20 nH (Table 4):
    E_on = 19.48 / 19.85 / 20.16 mJ and E_off = 17.61 / 17.95 / 18.21 mJ at 25 / 125 / 150 °C.
    t_r = 79 / 69 ns, t_f = 64 / 65 ns, t_d(off) = 263 / 294 ns (25 / 150 °C). du/dt at turn-off ≈ 7.1–7.3 kV/µs.
  - T_vj op = −40…150 °C. Module stray inductance L_sCE = 8.5 nH.
  - Derived comparison with [IFX-FS820] at 150 °C (not a source claim): E_on + E_off = 46.5 mJ at 400 V × 450 A (IGBT)
    vs 38.4 mJ at 600 V × 400 A (SiC). Normalized by V·I: 0.26 vs 0.16 µJ/(V·A), about 40 % lower for SiC
    at 1.6× the blocking voltage. Gate resistors and test conditions differ; treat as an illustration only.

#### Low-voltage Si power MOSFET (12/48 V converters)

- **[IFX-IAUT300]** Infineon, *IAUT300N10S5N015 OptiMOS-5 Power-Transistor* (Rev. 1.2, 2025-02-19). [page](https://www.infineon.com/assets/row/public/documents/10/49/infineon-iaut300n10s5n015-datasheet-en.pdf). verified.
  - AEC qualified, PG-HSOF-8 (TOLL). V_(BR)DSS = 100 V; I_D = 300 A (T_C = 25 °C, V_GS = 10 V; "limited by electromigration"), 247 A (T_C = 100 °C); I_D,pulse = 1200 A.
  - R_DS(on) = 1.3 mΩ typ / 1.5 mΩ max (V_GS = 10 V, I_D = 100 A, 25 °C); 1.6 / 2.0 mΩ at V_GS = 6 V, 75 A.
    Derived drop: 0.13 V typ at 100 A; 0.39 V typ / 0.45 V max at 300 A (25 °C values; R_DS(on) rises with T_j).
  - t_d(on) = 29 ns, t_r = 15 ns, t_d(off) = 70 ns, t_f = 48 ns (V_DD = 50 V, V_GS = 10 V, I_D = 100 A, R_G = 3.5 Ω). Q_g = 166 nC typ. No E_on/E_off given.
  - T_j = −55…175 °C.

#### GaN (on-board chargers, DC/DC)

- **[IFX-IGOT65R055]** Infineon, *IGOT65R055D2 CoolGaN Transistor 650 V G5, Final datasheet* (Rev. 1.1, 2026-03-05). [page](https://www.infineon.com/assets/row/public/documents/24/49/infineon-igot65r055d2-datasheet-en.pdf). verified. Industrial/JEDEC-qualified (not AEC); one line for the slide:
  650 V (900 V transient), I_D = 29 A (T_C = 25 °C), R_DS(on) = 55 mΩ typ / 66 mΩ max at 25 °C and 120 mΩ typ at 150 °C (I_D = 7.9 A), t_r = 8 ns, t_f = 14 ns, Q_rr = 0, T_j max 150 °C.
- Automotive GaN exists: GaN Systems (now Infineon) GS-065-060-5-T-A / -B-A, 650 V, 60 A, 25 mΩ, AEC-Q101, for on-board chargers. search summary (Richardson RFPD / Infineon product page snippets); datasheet not opened.

#### Thyristor (for contrast)

- **[ABB-5STP45Y8500]** ABB (now Hitachi Energy), *Phase Control Thyristor 5STP 45Y8500*, doc. 5SYA1079-04 (Jun 2020). [page](https://macrogroup.ru/upload/iblock/920/d86iciw9b5tbbdzv1xzh7puavs7446cl/5STP-45Y8500_5SYA1079_04-Jun-20.pdf). verified (manufacturer PDF, hosted by a distributor).
  V_DRM = 8500 V; I_T(AV)M = 4450 A (half sine, T_c = 70 °C); I_T(RMS) = 6990 A; V_T = 1.78 V typ / 1.90 V max at I_T = 5000 A, T_vj = 110 °C; turn-off time t_q = 950 µs; T_vj max = 110 °C.

#### ORNL teardown of the 2012 Nissan Leaf inverter/motor

- **[ORNL-APE006-2013]** T. Burress, ORNL, *Benchmarking State-of-the-Art Technologies*, DOE VTP Annual Merit Review, project APE006 (14 May 2013). [page](https://www.energy.gov/sites/prod/files/2014/03/f13/ape006_burress_2013_o.pdf). verified.
  - Slide 8: "3 IGBTs and 3 diodes per switch (18 IGBTS and 18 diodes total)"; "Separate module for each phase"; die 0.361 mm thick, "Estimated ~1000V breakdown and 300A IGBT rating" (ORNL estimate, Z. Liang); IGBT die 15 × 15 mm, diode 14 × 14 mm.
  - Slide 10: "Published LEAF ratings verified (280 Nm and 80 kW) – Actually operated above 80 kW"; test conditions "DC-link voltage of 375 V", "fsw = 5 kHz", coolant (water–ethylene glycol) 65 °C; "Peak motor efficiency above 97% between 5,000 rpm and 9,000 rpm"; "Inverter efficiency above 99% for high speeds".
  - Slide 11: "Combined LEAF inverter/motor efficiency reached above 96%"; "Capable of operating at 80 kW continuously at 7,000 rpm with stator temperatures leveling out at about 135 C".
  - Slide 5: "LEAF and Sonata have continuous capability near their published rated power"; slide 6: "LEAF sized for EV/continuous duty"; inverter assembly 5.7 kW/L, 4.9 kW/kg (peak).
  - Low-speed/high-torque inverter efficiency appears only as a contour plot; no number is stated in the text.
- **[ORNL-APE006-2012]** T. Burress, ORNL, *Benchmarking EV and HEV Technologies* AMR poster APE006 (2012). [page](https://www.energy.gov/sites/default/files/2014/03/f10/ape006_burress_2012_p.pdf). verified. LEAF PEM: "3 IGBTs and 3 diodes per switch", "18 IGBTs and 18 diodes total", "3 separate IGBT modules".

#### Production cars that moved to SiC

- **[SYSPLUS-M3]** System Plus Consulting, *Tesla Model 3 Inverter with SiC Power Module from STMicroelectronics* (teardown report, June 2018, version 1). [page](https://www.slideshare.net/system_plus/tesla-model-3-inverter-with-sic-power-module-from-stmicroelectronics-102988042). secondary (independent teardown firm; ST/Tesla never published a joint primary).
  "the Tesla inverter is composed of 24 1-in-1 power modules assembled on a pin-fin heatsink"; "The module contains two SiC MOSFETs". Device rating not stated in the public excerpt.
- **[IFX-HYUNDAI]** Infineon press release (4 May 2021) as reproduced by Power Electronics News, *Automotive Qualified SiC Six-pack Power Module for EV Traction Inverters*. [page](https://www.powerelectronicsnews.com/automotive-qualified-sic-six-pack-power-module-for-ev-traction-inverters). secondary.
  Dr. Jin-Hwan Jung, Hyundai Motor Group, on the 800 V E-GMP: "By using traction inverters based on Infineon's CoolSiC power module, we were able to increase the range of the vehicle by more than five percent because of efficiency gains resulting from the lower losses of this SiC solution compared to Si based solution."
  Also: Vitesco won an order (March 2021) for 800 V SiC inverters for E-GMP (electrive, InsideEVs; search summary).
- **[PORSCHE-TGT]** Porsche AG Newsroom, *The new Taycan Turbo GT* (11 March 2024). [page](https://newsroom.porsche.com/en/2024/products/porsche-the-new-taycan-turbo-gt-35479.html). verified (primary press release).
  "pulse inverters with a maximum current of 900 amperes are used on the rear axle" … "For better efficiency, silicon carbide is also used as the semiconductor material in the pulse inverter." … "even more power and torque than the 600-ampere pulse inverter in the Taycan Turbo S." Note: the original 2019 Taycan was 800 V with Si IGBT inverters; SiC arrived on the rear axle in 2024.

#### Switching frequency and SiC loss reduction

- **[ABBAS-NEE-2024]** K. Abbas, H.-P. Nee (KTH), *Autonomous Gate Drivers Tailored for TCM-Based ZVS Two-Level Three-Phase Inverters for EV Drive Systems*, Energies 17 (2024) 1060, doi:10.3390/en17051060. [page](https://mdpi-res.com/d_attachment/energies/energies-17-01060/article_deploy/energies-17-01060.pdf). verified (peer-reviewed, introduction).
  "Inverters employing silicon insulated-gate bipolar transistors (IGBTs) … with a blocking voltage of 1200 V dominate the business today. … these high switching losses impose limitations on the switching frequency of inverters utilizing IGBTs, typically ranging from 5 to 20 kHz"; SiC MOSFETs allow "operation at a higher switching frequency up to a hundred kHz or more".
- Manufacturer anchor: [IFX-FS820] EDT2 IGBT "optimized for … switching frequencies in the range of 10 kHz"; ORNL ran the Leaf inverter at 5 kHz [ORNL-APE006-2013].
- **[IFX-STLA-FUSION]** T. Reiter, M. Gleich (Infineon), F. Briault (Stellantis), *750 V Si/SiC Fusion Switches for Automotive Traction Inverters* (Infineon-hosted conference paper, c. 2025/26). [page](https://www.infineon.com/assets/row/public/documents/10/54/sia26-fusion.pdf). verified.
  Measured inverter losses at 450 V DC, "a switching frequency of 10 kHz in space vector modulation", 65 °C coolant (Fig. 4). Cites [2]: "EV range gain of 3.1% to 7.3% in highway to the EPA drive cycles when transitioning from IGBT to SiC MOSFETs at a 1200 V blocking rating in an 800 V supply architecture" and [3]: "0.66% to 3.1% in highway to WLTP drive cycles at 450 V … with 750 V blocking rating". Die cost per area of SiC "still 8 to 12 times higher than for silicon IGBT/Diodes". Si/SiC Fusion modules "reduce power losses by approximately 50% in WLTP and CLTC, and by 20-45% in highway drive cycles" vs IGBT.
- No manufacturer note giving a single "SiC cuts switching loss by X %" figure with conditions was opened; the derived 40 % per-V·A figure in A2 is the cleanest datasheet-to-datasheet comparison found. A vendor claim of "around 60 %" lower inverter losses (Infineon, via automationmagazine.co.uk) is search summary only.

### 6.8 Peak and continuous rating of the Leaf ZE1 machine

- **[NISSAN-JP-SPEC]** Nissan Motor Co., *日産リーフ 主要諸元* (Leaf main specifications, ZAA-ZE1, 2017-09 model, grades S/X/G). [page](https://www3.nissan.co.jp/content/dam/Nissan/jp/vehicles/leaf/1709/pdf/leaf_specification.pdf). verified.
  原動機 (motor) 型式 EM57: **定格出力 (rated output) 85 kW**; 最高出力 (max output) 110 kW (150 PS) / 3283–9795 rpm; 最大トルク (max torque) 320 N·m (32.6 kgf·m) / 0–3283 rpm. Battery 40 kWh, 350 V.
  The sheet does not state which test defines 定格出力 (in Japanese EV registration it is the manufacturer's continuous rating; not shown to be identical to R85 30-min power).
- **[RDW-OPENDATA]** RDW (Dutch vehicle authority), *Open Data RDW: Gekentekende_voertuigen_brandstof* (dataset 8ys7-d773), field `nominaal_continu_maximumvermogen` = "Het nominaal continu maximumvermogen, uitgedrukt in kW, dat de elektromotor kan leveren" (nominal continuous maximum power of the electric motor). [page](https://opendata.rdw.nl/resource/8ys7-d773.json). verified (queried 1 Nov 2026, 1200 Leafs first registered 2018–2026).
  "NISSAN LEAF 40KWH": **90 kW** in 636 of 778 records (e.g. plate P429DT, 2018-02-14, to HPS16L, 2025-06-05); 110 kW in 142 records, all early (2018-02 to 2019-06), which look like the peak value entered in the continuous field. "NISSAN LEAF 62KWH" (e+): 90 kW in 396/396. "NISSAN LEAF 30KWH" (AZE0): 80 kW. New 2026 "NISSAN LEAF": 70 kW.
  This is per-vehicle registration data copied from the CoC/type approval, so it is the closest primary found to the EU "maximum 30 minutes power", but the RDW field name says "nominal continuous" and does not cite R85.
- **[ORNL-APE006-2013]** (see A6) for the 2012 (ZE0, 80 kW / 280 N·m) motor: "Capable of operating at 80 kW continuously at 7,000 rpm with stator temperatures leveling out at about 135 C" (coolant 65 °C, 375 V DC); i.e. continuous ≈ peak at that speed. The same slide reproduces a Nissan chart ("Power from Within", Nissan LEAF Special Edition of SAE Vehicle Electrification, p. 17, 23 Feb 2011) with labels "80 kW for 1 hour", "70 kW for 0.5 hour", "60 kW for 0.5 hour", "50 kW for 1 hour"; their exact meaning (they are curve labels) cannot be read from the text.
- **[UNECE-R85]** UN/ECE Regulation No 85, consolidated in OJ of the EU, CELEX 42014X1107(01) (published 7 Nov 2014). [page](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:42014X1107(01)); text read via mirror [lexaris](https://lexaris.de/book/version/documentflat/head/2047507). secondary (EUR-Lex HTML could not be fetched; UNECE PDF returned 403).
  - 2.4 "'Maximum net power' means the maximum value of the net power measured at full engine load."
  - 2.5 "'Maximum 30 minutes power' means the maximum net power of an electric drive train at DC voltage as defined in paragraph 5.3.1 of this Regulation, which a drive train can deliver over a period of 30 minutes as an average."
  - 5.3.1 (net power): motor conditioned at 25 ± 5 °C for ≥ 2 h; run at full power-controller setting; 3 min at 80 % of max power before measurement; whole test within 5 min.
  - 5.3.2 (30 min power): conditioned 25 ± 5 °C for ≥ 4 h; speed in a range where net power > 90 % of maximum power, recommended by the manufacturer; "The power must be in a range of ± 5 per cent of the power value at the start of the test"; "The maximum 30 minutes power is the average of the power within the 30 minutes period."

### 6.9 History of the electric car (section 01, "A short history, corrected")

Read 1 Nov 2026.

#### Corrections to the textbook slide
- "1841 Grove first rechargeable EV" is wrong on three counts. Grove built no vehicle. His 1839 Grove cell was a primary (non-rechargeable) zinc/platinum cell. His 1842 "gas voltaic battery" was the first fuel cell, not a rechargeable battery. The first rechargeable battery is Planté's lead-acid cell (1859).
- "1981 Morrison" is a typo for about 1890. Morrison built a prototype in 1887 and showed his electric carriage in public in Des Moines in September 1890.
- "1900 first vehicle exceeded 100 km/h" is off by a year. Jenatzy's *La Jamais Contente* did it on 29 April 1899, at 105.88 km/h.

#### Sources
- **[DOE-HIST]** US DOE, Rebecca Matulka, *The History of the Electric Car* (15 Sep 2014). [page](https://www.energy.gov/articles/history-electric-car). verified. The page says Morrison built his car in "about 1890": "William Morrison, a chemist who lived in Des Moines, Iowa." It says "By 1900, electric cars were at their heyday, accounting for around a third of all vehicles on the road." Other dates on the page: Kettering's electric starter 1912, Model T 1908, EV1 "discontinued it in 2001" (that is the end of the program, not of production), Tesla "announced" a sports car in 2006, and "In late 2010, the Chevy Volt and the Nissan LEAF were released in the U.S. market." The page does not mention Jedlik, Davidson, Davenport, Planté, Faure, Trouvé or the i-MiEV.
- **[CENSUS-1900]** US Census Office, *Twelfth Census (1900), Vol. X Manufactures Part 4, "Carriages and Wagons"* section, p. 255–256 incl. Table 7 (1902). [PDF](https://www2.census.gov/library/publications/decennial/1900/volume-10/volume-10-p3.pdf). verified (read the OCR text). The census reports production, not the fleet: "The 4,192 motor vehicles constructed during the census year were divided as follows: Steam carriages, 1,681 ...; electric vehicles, 1,575 ...; automobiles using hydrocarbon motors, 936." That gives electric 37.6 %, steam 40.1 % and gasoline 22.3 % of US production in the census year ending mid-1900. The often-quoted "38 %" comes from these numbers. DOE's "a third of all vehicles on the road" stretches a production share to the whole fleet, and the census gives no fleet figure. Electric cars led by value: $2.87 M of $4.90 M (59 %).
- **[LHL-JEDLIK]** Linda Hall Library, *Scientist of the Day: Ányos Jedlik* (n.d.). [page](https://www.lindahall.org/about/news/scientist-of-the-day/anyos-jedlik/). verified. "Jedlik started experimenting with electric motors in 1827." A photo caption reads "Electromagnetic rotor built by Jedlik in 1828." He built a dynamo-type "unipolar inductor" in 1861. The page does not mention a model car (Wikipedia says the date is "uncertain (late 1827 or early 1828)").
- **[SI-DAVENPORT]** Smithsonian NMAH, *Davenport electric motor, patent model, US Pat. 132* (object nmah_703302). [page](https://www.si.edu/object/nmah_703302). search summary (si.edu returned 403 to the fetcher). The snippet reads "Model to accompany US patent number 132, 'Electric Motor', issued to Thomas Davenport, 25 February 1837 ... the first US patent issued for an electric motor." The original model was lost in the 1836 Patent Office fire.
- **[ETHW-DAVENPORT]** IEEE ETHW, *Davenport's Motor*. [page](https://ethw.org/Davenport's_Motor). verified. "In 1834 he built a powerful motor that converted electric power to rotating mechanical power" and he "patented the idea in 1837." He hoped a large model could pull a train, but "battery limitations" prevented it. The page does not mention the circular-track model car of 1835.
- **[DAVIDSON]** Wikipedia, *Robert Davidson (inventor)*, citing J. S. Reid (University of Aberdeen Natural Philosophy Museum) and *Railway Times* (Sep 1842). [page](https://en.wikipedia.org/wiki/Robert_Davidson_(inventor)). secondary. Model electric locomotive 1837. The battery-powered locomotive *Galvani* (1842) was 4.9 m long and ran on zinc-acid batteries on the Edinburgh–Glasgow line in September 1842 at "upwards of four miles an hour." The year of the "1837 carriage" differs across sources (1837 or 1839).
- **[MAGLAB-PLANTE]** US National High Magnetic Field Laboratory (NSF), *Planté Battery – 1859*. [page](https://nationalmaglab.org/magnet-academy/history-of-electricity-magnetism/museum/plante-battery-1859/). verified. "Then, in 1859, Planté succeeded in inventing the first secondary, or rechargeable, battery." It credits the 1881 electrode advance "invented by French engineer Camille Faure in 1881 ... a lead paste spread thinly on metal grids."
- **[SMG-PLANTE]** Science Museum Group, *One of the First Rechargeable Batteries, about 1860* (object co36401). [page](https://collection.sciencemuseumgroup.org.uk/objects/co36401/one-of-the-first-rechargeable-batteries-about-1860-lead-acid-rechargeable-batteries). verified. "Made by Gaston Planté in London around 1860" and "The first practical lead-acid storage battery." The 1860 date is for this object. The invention date commonly given is 1859.
- **[APS-GROVE]** American Physical Society, *APS News: This Month in Physics History – October 1842: William Grove's letter to Faraday describing a fuel cell* (Sep 2019). [page](https://www.aps.org/apsnews/2019/09/grove-letter-faraday-fuel-cell). verified. Grove "wired several cells in series to make what he called a 'gas voltaic battery'" (letter to Faraday, October 1842, published in 1843). His earlier Grove cell was a primary cell, "a favorite for powering the fledgling telegraph industry." The 1839 date of the Grove cell is secondary only (Wikipedia/Chemistry World). Neither device is rechargeable, and neither is a vehicle.
- **[GWR-TROUVE]** Guinness World Records, *First electric road vehicle*. [page](https://www.guinnessworldrecords.com/world-records/739122-first-electric-road-vehicle). verified. Gustave Trouvé, Paris, "April 1881": "a British-made Coventry pedal-powered tricycle" with "a Siemens electric motor" and "lead-acid batteries." Secondary sources give 19 April 1881 on rue de Valois. Sources disagree on whether the tricycle was shown at the 1881 Exposition Internationale d'Électricité.
- **[IOWA-MORRISON]** State Historical Society of Iowa, *Goldie's History Kids at-home activity: Automobile* (n.d.). [PDF](https://history.iowa.gov/media/169/download). verified. "In 1890, Iowan William Morrison created the first successful American electric carriage (car) ... could carry up to 12 passengers, cruise at 14 miles per hour and needed to be recharged after 50 miles of driving ... first shown to the public during the 1890 Seni Om Sed parade in Des Moines." Iowa History Journal ([page](https://iowahistoryjournal.com/an-electrifying-iowan/), verified) dates the first prototype to 1887. The *Annals of Iowa* (K. McClellan) cites the *Des Moines Daily News* of 5 Sep 1890, but that is only a search summary because the site was bot-blocked.
- **[NYE-JENATZY]** Goodwood Road & Racing, Doug Nye, *A brief history of land speed record cars* (Jun 2019). [page](https://www.goodwood.com/grr/columnists/doug-nye/2019/6/a-brief-history-of-land-speed-record-cars/). secondary (respected motorsport historian). "Jenatzy returned on April 29th – 34 seconds – 105.904km/h – breaking the 100km/h barrier for the first time – 65.79mph," at Achères near Paris, 1899. Note that 1 km in 34 s is 105.88 km/h, the figure most sources quote. Some sources give 1 May 1899. The car is at the Musée national de la voiture, Compiègne, which has a 1994 replica.
- **[THF-KETTERING]** The Henry Ford, *Cadillac Engine, 1913* (artifact 205317). [page](https://www.thehenryford.org/collections/explore/artifact/205317). verified. "Cadillac introduced the electric starter in 1912." It "eliminated the difficult and sometimes dangerous work of hand-cranking an engine." "Charles Kettering, formerly an engineer with National Cash Register, developed the starter."
- **[THF-FORD]** The Henry Ford, *Ford Motor Co. Chronology, 1903–2003*. [page](https://www.thehenryford.org/collections/explore/popular-research-topics/ford-motor-co-chronology-1903-2003). verified. "Oct 1, 1908: First Model T made available to the public. Continues until 1927." "Apr 1, 1913: First experiments with assembly line begin at Highland Park Plant."
- **[SI-EV1]** Smithsonian NMAH, *EV1 Electric Car, 1997* (object nmah_1293145, cat. 2005.0061.01). [page](https://www.si.edu/object/nmah_1293145). search summary (403). The snippet says GM "began leasing a new generation of electric cars to consumers in 1996" and decided not to mass-produce it because of "projected high price and limited market." The Smithsonian car is the last of the first series, which had lead-acid batteries. The 1996–1999 production window is not confirmed from the primary record.
- **[TESLA-2008]** Tesla Motors press release, *Tesla Motors Completes $40 Million Financing ...* (19 Feb 2008), via GlobeNewswire. [page](https://www.globenewswire.com/news-release/2008/02/19/1035146/0/en/Tesla-Motors-Completes-40-Million-Financing-Led-by-Valor-Equity-Partners-and-Elon-Musk.html). search summary. "the first production Tesla Roadster was delivered to Elon Musk on February 1." A separate release, *Tesla Motors Begins Regular Production of 2008 Tesla Roadster* (17 Mar 2008, [ir.tesla.com](https://ir.tesla.com/press-release/tesla-motors-begins-regular-production-2008-tesla-roadster)), returned 403.
- **[MMC-IMIEV]** Mitsubishi Motors, *Annual Report 2011* (FY to 31 Mar 2011). [PDF](https://www.mitsubishi-motors.com/content/dam/com/ir_en/pdf/anual/2011/annual_2011_2.pdf). verified. "Following its launch in Japan in July 2009, expanded sales to Europe, Hong Kong, Australia and other countries." The MMC news release of 5 Jun 2019 ([page](https://www.mitsubishi-motors.com/en/newsrelease/2019/detail1191.html), verified) calls the i-MiEV "the first mass-produced electric vehicle in 2009."
- **[NISSAN-LEAF]** Nissan, *Nissan to make history with delivery of world's first 100% electric Nissan LEAF to California consumer* (10 Dec 2010). [page](https://global.nissannews.com/en/releases/101210-02-e). verified. The delivery was set for "Saturday, December 11, 2010" at North Bay Nissan, Petaluma, CA. Japan launch was 20 Dec 2010 (secondary).

### 6.10 Why not all cars are electric yet, and cabin heating in the cold (sections 01 and 08)

Read 1 Nov 2026. The cold-weather bill in section 08 uses 2 kW (warm cabin at about −7 °C: ADAC 1.5–2 kW,
AAA 2018 Leaf derived 1.6–2.8 kW) and 5 kW (resistive heater warming up: ANL 2012 Leaf 2.5–5.2 kW).

#### Purchase price vs. running cost / TCO
- **[IEA-GEVO26-CARS]** IEA, *Global EV Outlook 2026 – Trends in electric cars* (20 May 2026). [page](https://www.iea.org/reports/global-ev-outlook-2026/trends-in-electric-cars). verified. Europe 2025: "the average BEV price premium declined for the first time since 2021 to around 20%." The share of BEVs sold below their ICE equivalents passed 30 % (about 15 % in 2021). "about 25% of ICE models were priced below USD 30 000 compared with less than 10% of battery electric models." China 2025: nearly 70 % of BEVs sold were "already cheaper than their ICE equivalents" before incentives. US: the BEV SUV premium is "under 25%." Electric cars were 28 % of new car sales in Europe in 2025 (4.2 M) and just under 27 % in the EU.
- **[ICCT-DE-PRICES]** ICCT, Plötz, Link, Morrison, Tietge, Li, Mock, *Price and market trends of BEVs and ICEVs in Germany, 2020–2025* (Jul 2026), executive summary and p. 15. [PDF](https://theicct.org/wp-content/uploads/2026/07/ID-621-%E2%80%93-Germany-market-trends_report_final.pdf). verified. The median nominal BEV price went from €37,000 (2020) to €53,000 (2025). The median ICEV price went from €41,000 to €46,000. The median gap in 2025 is therefore about €7,000 (+15 %), but this mostly reflects a mix shift to large BEVs. "Adjusting for inflation, median BEV prices decreased by about 18%, while ICEV prices increased by about 2%." The minimum model price in 2025 was about €19,000 for a BEV and about €14,000 for an ICEV. Battery cost fell from €165–185/kWh to €130–140/kWh between 2020 and 2025. The underlying data come from ADAC.
- **[ICCT-ETC26]** ICCT, Rajon Bernard & Plummer, *The EV Transition Check 2026* (Sep 2026), pp. 1, 6–7. [PDF](https://theicct.org/wp-content/uploads/2026/09/ID-687-%E2%80%93-high-9.1-Transition-Check-2026-Research-Brief-A4-50216-v6.pdf). verified. "BEVs in the three largest car segments (medium, upper-medium, and luxury) have already reached upfront cost parity with comparable ... ICEVs." There is no parity yet in the mini, small and lower-medium segments. Affordable BEVs (<€30,000) numbered about 35 in the EU in 2025. Running cost: "BEVs are cheaper than gasoline ICEVs (33% cheaper in 2025), even for drivers relying exclusively on public charging (−5%)." The page gives no single EU-wide TCO figure for cars; TCO parity is stated only for trucks.

#### Range and charging
- **[IEA-GEVO26-CARS]** (as above). verified. "The average battery electric car range is currently almost 380 km, and this has plateaued in recent years." The sales-weighted BEV range rose about 10 % between 2020 and 2025. IEA gives an average, not a median.
- **[IEA-GEVO26-CHG]** IEA, *Global EV Outlook 2026 – Electric vehicle charging* (20 May 2026). [page](https://www.iea.org/reports/global-ev-outlook-2026/electric-vehicle-charging-chap-6-and-10). verified. "The total stock of public charging points worldwide reached more than 7 million at the end of 2025." "On average, the European Union has 11 EVs per public charging point, close to the global average." EU public capacity is "around 3 kW per electric LDV at the end of 2025."
- **[ICCT-ETC26]** (as above), p. 15. verified. "The number of public chargers in the EU has grown almost eightfold since 2020, reaching 1.16 million by June 2026." DC chargers of 150 kW or more cover 92 % of the TEN-T core network. Ad hoc prices in June 2026 averaged €0.50/kWh AC and €0.62/kWh DC, about twice private rates.
- **[ADAC-IONIQ6]** ADAC, *Hyundai Ioniq 6 im ADAC Test* (10 Aug 2026). [page](https://www.adac.de/rund-ums-fahrzeug/autokatalog/marken-modelle/hyundai/hyundai-ioniq-6-test/). verified. "Von 10 auf 80 Prozent lädt die Batterie in 18 Minuten" (800 V car, peak up to 265 kW).
- **[ADAC-EQV]** ADAC, *Test Mercedes EQV (2025)* (19 May 2025). [page](https://www.adac.de/rund-ums-fahrzeug/autokatalog/marken-modelle/mercedes-benz/mercedes-eqv/). verified. 10–80 % takes 38 min at an average of 104.9 kW (400 V van). Search summaries of other ADAC model tests give Audi Q6 e-tron about 23 min (199.8 kW avg), Mercedes GLC 400 23 min, Hyundai Ioniq 5 N 21 min. A fair range for current cars is **about 18–40 min for 10→80 %**. ADAC notes that a non-preconditioned battery in winter charges "considerably longer." In the ADAC fast-charge test of 30 Oct 2026 ([page](https://www.adac.de/rund-ums-fahrzeug/elektromobilitaet/laden/schnellladen-langstrecke-ladekurven-2026/), verified), a cold Model Y needed 56 min instead of 33, about 70 % longer.

#### Cold weather (key item for the WLTC auxiliary load)
- **[AAA-2019]** AAA, *AAA Electric Vehicle Range Testing* (Feb 2019), p. 3 (Key Findings). [PDF](https://www.aaa.com/AAA/common/AAR/files/AAA-Electric-Vehicle-Range-Testing-Report.pdf). verified. Five BEVs (2018 BMW i3s, 2018 Chevrolet Bolt, 2018 Nissan Leaf, 2017 Tesla Model S 75D, 2017 VW e-Golf) were tested to SAE J1634 on UDDS, HWFET and US06. "On average, an ambient temperature of 20°F resulted in a 12 percent decrease of combined driving range" with HVAC off. "On average, HVAC use at 20°F resulted in a 41 percent decrease of combined driving range." At 95 °F with A/C the decrease was 17 %. 2018 Nissan Leaf (pp. 41–42, Figs 33, 35), DC kWh/mi at 20 °F HVAC off / 75 °F / 20 °F HVAC on: UDDS 0.265/0.243/0.376, HWFET 0.307/0.298/0.364, US06 0.435/0.420/0.469. Combined range was 125/140/96 mi.
  - *Derived heater power (my calculation, not in the report): ΔkWh/mi (HVAC on minus off, both at 20 °F) × the cycle's mean speed.* UDDS 0.111 × 19.6 mph = **2.2 kW**, HWFET 0.057 × 48.3 mph = **2.8 kW**, US06 0.034 × 48.4 mph = **1.6 kW**, all DC at the battery. The report does not say whether the car had a heat pump. The 2018 Leaf S has a PTC heater only, while SV/SL have a hybrid heat pump plus PTC (secondary).
- **[ANL-VSS030-2012]** Argonne National Laboratory, H. Lohse-Busch & M. Duoba, *Advanced Technology Vehicle Lab Benchmarking – Level 1*, DOE Annual Merit Review, Project VSS030 (15 May 2012), slide 8 "Leaf Efficiency/Range Testing at Hot/Cold (Newest J1634 Procedures Employed)". [PDF](https://www1.eere.energy.gov/vehiclesandfuels/pdfs/merit_review_2012/veh_sys_sim/vss030_lohsebusch_2012_o.pdf). verified. "Heater and A/C cause dramatic differences in consumption. With heater and A/C consumption per minute is as important as per mile – Heater: 2.5 to 5.2 kW – A/C: 1 to 1.5 kW." The plot is a UDDS trace labeled "Cold w/heater" at 20 °F (−7 °C), climate set to 72 °F auto. The car is a 2011/2012 Leaf, whose heater is a **resistive PTC**. **This is the best primary resistive-heater number: 2.5–5.2 kW, high during warm-up and lower once the cabin is warm.**
- **[INL-LEAF13]** DOE EERE / INL / Intertek (dynamometer at ANL), *2013 Nissan Leaf – Advanced Vehicle Testing – Baseline Testing Results* (fact sheet; dyno testing from 25 Feb 2014), p. 2. [PDF](https://www.energy.gov/sites/prod/files/2015/01/f19/fact2013nissanleaf.pdf). verified. Trim is **SV**, and the 2013 SV/SL have a heat pump plus PTC (secondary, not on the sheet). The figures are AC Wh/mi from the wall. Conditions are 72 °F with climate off, 20 °F with climate "set to 72°F Auto", and 95 °F with A/C. UDDS cold start 211.7 / 458.7 Wh/mi, UDDS hot 201.4 / 369.1, HWFET 240.8 / 349.9, US06 321.6 / 425.7 (72 °F / 20 °F).
  - *Derived (my calculation): Δ × mean speed, AC at the wall.* UDDS hot 3.3 kW, UDDS cold 4.8 kW, HWFET 5.3 kW, US06 5.0 kW. Each figure includes charger loss (about 86 % efficient per p. 3) and cold-powertrain/battery losses besides HVAC, so it is an upper bound. In DC terms it is about 2.8–4.5 kW. Heat pumps of that generation work poorly at −7 °C.
- **[ADAC-HEIZ-2022]** ADAC, W. Rudschies, *Wie gut ist die Heizung im Elektroauto?* (16 Dec 2022). [page](https://www.adac.de/rund-ums-fahrzeug/elektromobilitaet/elektroauto/heizung-elektroauto/). verified. Seven cars were tested in a cold chamber at −10 °C, stationary. "Die Heizleistung ist mit 1,5 bis 2 kW so gering" is the steady-state power to hold +20 °C. Energy to warm up to +20 °C: Kona 1.5 kWh, Fiat 500e 1.5, Model Y 1.6, Zoe 1.8, e-Up 2.0, iX 2.0, ID.3 2.3 kWh. Heat pumps were fitted on the ID.3, iX, Zoe and Model Y. ADAC found no immediate advantage for the heat pump in this test.
- **[ADAC-STAU-2021]** ADAC, *Kältetest E-Auto: Wie lange halten Elektroautos im Stau aus?* (12 Feb 2021). [page](https://www.adac.de/rund-ums-fahrzeug/elektromobilitaet/elektroauto/haertetest-winter-stau/). verified. Real night at −9 to −14 °C, cabin at 22 °C, seat heating on. Average draw was "rund 2 Kilowatt" (VW e-up) and "3 Kilowatt" (Renault Zoe ZE50, heat pump). After 12 h the Zoe had used about 70 % of its battery and the e-up about 80 %.
- **[ECCC-WEVJ-2026]** Humphries & Loiselle-Lapointe (Environment and Climate Change Canada), *World Electric Vehicle Journal* 17(4):168 (2026), doi:10.3390/wevj17040168. search summary (MDPI blocked). The study compared the same model with a heat pump (MY2022) and with PTC (MY2020) on a dyno at −10, −7, 0 and 25 °C. The heat pump was more efficient in most conditions, especially at 0 °C. At −10 °C the heat pump used more energy than the PTC on cold start but less once the cabin was warm. kW values not read.
- **[NAF-2025]** NAF (Norwegian Automobile Federation), *El Prix vinter 2025 – rekkevidde* (21 Jan 2025). [page](https://www.naf.no/elbil/elprix-nytt/elprix-vinter-2025-rekkevidde). verified. "Gjennomsnittlig avvik fra WLTP-rekkevidden var i vinter 19,4 prosent." Best was Polestar 3 at −4.1 % (537 vs 560 km), worst Voyah Dream at −29.5 %. Temperatures were unusually mild, about −6 °C to +8 °C.
- **[ADAC-WINTER-2026]** ADAC, *Stresstest E-Autos im Winter* (22 Jan 2026). [page](https://www.adac.de/rund-ums-fahrzeug/elektromobilitaet/elektroauto/elektroauto-reichweite-im-winter-adac-test-2026/). verified. 14 cars in a 0 °C chamber on a motorway cycle. Motorway consumption ranged from 22.2 kWh/100 km (Model Y) to 35.3 (BYD Sealion 7). "alle konkurrenzfähigen Fahrzeuge" had heat pumps. No heater kW given.
- **Recommendation for the WLTC auxiliary load** (replacing 300 W): **about 2 kW at −7 °C** for a compact BEV with the cabin warm. Support comes from AAA's 2018 Leaf (derived 1.6–2.8 kW DC), ADAC's 1.5–2 kW steady state at −10 °C, and ADAC's 2–3 kW in the 2021 traffic-jam test. Use **about 4–5 kW for a PTC-only car during warm-up** (ANL 2012 Leaf 2.5–5.2 kW). A heat pump in steady state at −7 °C is typically **about 1–2 kW**, but the only primary source for that is ADAC's mixed-fleet 1.5–2 kW; there is no isolated heat-pump kW on a drive cycle.

#### Grid and infrastructure
- **[IEA-GEVO26-OUT]** IEA, *Global EV Outlook 2026 – Outlook for electric mobility* (20 May 2026). [page](https://www.iea.org/reports/global-ev-outlook-2026/outlook-for-electric-mobility-chap-9-11). verified. In 2025 "the global fleet of EVs consumed around 250 TWh of electricity," about 1 % of final electricity demand. In 2035 it reaches 1,700 TWh (about 5 %) in the STEPS scenario, more than 1,500 TWh (about 4 %) in CPS, and more than 3,000 TWh (about 7 %) in NZE.
- **[EC-GRID-2023]** European Commission press release IP/23/6044, *Commission sets out actions to accelerate the roll-out of electricity grids* (Brussels, 28 Nov 2023). [PDF](https://ec.europa.eu/commission/presscorner/api/files/document/print/en/ip_23_6044/IP_23_6044_EN.pdf). verified. "Electricity consumption in the EU is expected to increase by around 60% between now and 2030," with "more electric vehicles to charge" among the drivers. "With 40% of our distribution grids more than 40 years old ... €584 billion in investments are necessary." This is the EU Grid Action Plan, COM(2023) 757.
- **[ICCT-ETC26]** (as above), p. 17. verified. Smart charging is estimated to cut European peak power output by 6 % in 2035. 63 % of EU customers had a smart meter by end-2025, but only 5.5 % in Germany.

#### Battery materials and supply chain
- **[IEA-GEVO26-MFG]** IEA, *Global EV Outlook 2026 – Manufacturing and trade* (20 May 2026). [page](https://www.iea.org/reports/global-ev-outlook-2026/manufacturing-and-trade). verified. China in 2025 had "over 80% of battery cell production," "about 85% of global production of cathode active material," and "more than 90% of production of anode active material."
- **[IEA-GEVO26-BAT]** IEA, *Global EV Outlook 2026 – EV batteries* (20 May 2026). [page](https://www.iea.org/reports/global-ev-outlook-2026/electric-vehicle-batteries). verified. "EV battery deployment reached 1.2 TWh" in 2025. LFP was "over 55%" of EV batteries. The DRC "accounts for almost two-thirds of global cobalt supply." Average battery prices fell 8 % in 2025.
- **[IEA-GCMO25]** IEA, *Global Critical Minerals Outlook 2025 – Executive summary* (May 2025). [page](https://www.iea.org/reports/global-critical-minerals-outlook-2025/executive-summary). verified. China is "the dominant refiner for 19 of the 20 minerals analysed," with "an average market share of around 70%." The top-3 refiners' average share "rose from around 82% in 2020 to 86% in 2024." The 2035 outlook ([page](https://www.iea.org/reports/global-critical-minerals-outlook-2025/overview-of-outlook-for-key-minerals), verified) has China "over 60% of refined lithium and cobalt" and "around 80% of battery-grade graphite." In the GCMO 2026 executive summary ([page](https://www.iea.org/reports/global-critical-minerals-outlook-2026/executive-summary), verified), the top refiner's average share "rose to 72% in 2025."
- **[USGS-MCS26]** USGS, *Mineral Commodity Summaries 2026: Cobalt; Graphite* (Feb 2026). [cobalt PDF](https://pubs.usgs.gov/periodicals/mcs2026/mcs2026-cobalt.pdf), [graphite PDF](https://pubs.usgs.gov/periodicals/mcs2026/mcs2026-graphite.pdf). verified. "Congo (Kinshasa) was the world's leading source of mined cobalt and accounted for an estimated 73% of world total, followed by Indonesia, which accounted for 14%" in 2025 (230,000 of 310,000 t). "In 2025, China was the world's leading natural graphite supplier, producing an estimated 82% of total world production."

#### Used-car market and residual values
- **[IEA-GEVO26-CARS]** (as above). verified. Used EV sales across China, five European markets (UK, FR, DE, IT, ES) and the US "surpassed 3 million in 2025." In those European markets EVs were "roughly 4% of used car transactions in 2025, increasing from only 1% in 2021." Europe: "Battery electric car retention rates fell from a peak of about 50% in 2022 to 35% in 2025," against roughly 60 % to 50 % for the overall used market. The age basis of the retention rate is not stated on the page. US: EVs were about 2.5 % of used sales, and BEV resale values "ended 2025 roughly 25 percentage points below the overall market." China: used EVs were about 8 % of used sales, with a resale value of 42 %.

---

## 7. Gaps

- **Leaf WLTP consumption from Nissan itself** was not found. 17.1 kWh/100 km is from ADAC and EV
  Database; the 270 km WLTP range is now confirmed by Nissan's 2018 newsroom ([N-GL-LEAF-EU-2018],
  §6.6). The EEA CO₂-monitoring database (the type-approval primary source) returned 403 and was not
  retried.
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
- **IEA EV-share series is from an aggregator.** The IEA Global EV Data Explorer and its API could
  not be downloaded from a script (bot check), so the yearly series is Our World in Data's copy of
  the IEA data ([OWID-IEA-EVSHARE]). It agrees with the GEVO text for 2023-2025 except China 2025
  (53 % in the data, "almost 55%" in the report). Download the explorer CSV by hand to close this.
- **BNEF before 2013 and LFP/NMC cell prices.** The Dec 2025 release charts 2013-2025 only and
  gives LFP/NMC pack, not cell, prices. Earlier values (2010) and the chemistry split by cell are in
  the paywalled report.
- **Cell specific energy.** The IEA's 205 Wh/kg (LFP) and 265 Wh/kg (NMC) are "up to" best values
  and the report does not say "cell" for them explicitly; no national-lab fleet-average cell value
  was sourced.
- **Typical (not best-in-class) pack and cell Wh/kg for NMC and LFP.** No IEA, national-lab or
  manufacturer primary gives an absolute typical value; the IEA gives only best-cell values and
  LFP-vs-NMC ratios. ANL BatPaC outputs were not found in a citable table. The Leaf pack's 303 kg is
  verified, but its module count in the same Nissan table (48) disagrees with teardown reports (24).
- **EEA CO₂ indicator not yet updated for 2025.** The indicator (3 Aug 2026) stops at 2024; 2025
  (96.7 g/km WLTP) is provisional, from the 25 Jun 2026 news item. Final 2025 data are due later.
- **EEA electricity intensity 2025.** The indicator gives 2024 (183.44 g CO2e/kWh); a column labeled
  2025 in its country chart data (EU 178) is unexplained and not used.
- **2035 car CO₂ revision.** Not adopted as of 1 Nov 2026. A reported late-October 2026 EP committee
  compromise (95 % with up to 7.5 points of steel credits) is secondary only (evlife.world); recheck
  OEIL after the plenary (forecast 23 Nov or 14 Dec 2026) and the Council (general approach
  expected 11 Dec 2026).
- **2021 WLTP reference target.** No act prints it; ≈ 110 g/km is derived from 93.6/0.85.
- **Euro 7 tyre abrasion limit values.** Not in the Regulation; the UNECE WP.29 documents for the new
  C1 abrasion UN Regulation (reportedly adopted June 2026) returned 403. Euro 7 brake limits for
  2030-2034 are blank pending the Art. 18(5) review. The December 2025 automotive omnibus was not
  checked for changes to Euro 7 dates.
- **Battery Regulation delegated acts.** Only the EV carbon-footprint methodology act (initiative
  13877) was confirmed as not adopted; the performance-class and threshold acts were not checked
  individually.
- **US litigation.** No ruling found on the endangerment-finding rescission (D.C. Cir.; status as of
  22 Jun 2026 from a law-firm alert) or on *California v. United States* (CRA waiver
  disapprovals). SAFE III petitions for review were not searched.
- **ZE1 end of production** rests on trade press (electrive, Electrek); no Nissan release found.
- No 150 °C V_CE(sat) at the full 820 A for FS820R08A6P2B (datasheet gives 450 A at 150 °C, 820 A at 25/175 °C only).
- FS03MR12A6MA1B datasheet read is rev. 1.00 (2021); a later revision may exist; the B variant is NRND.
- No primary (ST or Tesla) document for the Model 3 SiC inverter; only the System Plus teardown.
- Hyundai E-GMP SiC: no Hyundai or Infineon primary page opened; the quote comes from a trade-press reprint.
- No manufacturer application note with a stated "SiC switching loss −X % vs IGBT" under defined conditions; the 40 % in A2 is derived.
- No numeric low-speed/high-torque inverter efficiency for the 2012 Leaf (ORNL gives contours only).
- No EU CoC or type-approval document for the Leaf ZE1 labeled "maximum 30 minutes power"; the 90 kW comes from the RDW register field "nominal continuous maximum power", and Nissan Japan's 定格出力 is 85 kW. The two do not match and the test basis of each is not stated in the source.
- R85 text read from a EUR-Lex mirror, not from EUR-Lex or UNECE directly.
- No ORNL continuous test of the ZE1 (EM57) motor was found; ORNL's continuous result is for the 2012 80 kW motor.
- No isolated heat-pump heater power (kW) for a compact BEV on a −7 °C drive cycle from a primary source. ADAC's 1.5–2 kW is stationary and mixes PTC and heat-pump cars. The ECCC 2026 WEVJ paper probably has it, but MDPI blocked access.
- The ANL D3 2012/2013 Leaf time-series (heater kW per test) was not opened. The heater numbers above come from the ANL 2012 slide and from my own Δ-energy calculation on AAA and INL data.
- The 2013 Leaf SV heat pump and the 2018 AAA Leaf trim/heater type are not confirmed from a Nissan primary.
- IEA gives an **average** BEV range (about 380 km), not a median, in GEVO 2026. No IEA median found.
- No EU-wide car TCO in EUR from ICCT 2025/2026. ICCT gives segment price parity, Germany median prices and a 33 % running-cost advantage.
- Per-mineral China refining shares for 2024/2025 (lithium, cobalt) as point values: IEA pages give only the 70 % average, 2035 projections, and >90 % for anode material. The commonly quoted figures (Li about 65 %, Co about 75 %) were not verified.
- Britannica, Smithsonian (si.edu), MDPI, the Tesla IR site and the Annals of Iowa all blocked the fetcher. Davenport, EV1, the Tesla Roadster and Davidson rest on search summaries or secondary sources.
- Exact EV1 production years (1996–1999) are not confirmed from a primary source.
- Jenatzy: no official museum (Compiègne) page found. The date (29 Apr vs 1 May 1899) and speed (105.88 vs 105.90 km/h) vary slightly across secondary sources.
- The US vehicle fleet (registrations) in 1900 was not checked against FHWA, so the "a third of vehicles on the road" claim can only be rebutted with the census production share.
