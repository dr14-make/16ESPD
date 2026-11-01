# The battery-electric car against published Leaf data: road load, coasting, regen and braking

Scope: checks the Lecture 4 battery-electric car's road load, coast-down, mass and inertia, lift-off
regeneration, regen–friction blending and stopping distance against published data for the Nissan
Leaf ZE1 (2018 onward), whose numbers the drive carries. It answers items 1–8 of "Validate against
researched data" in the drive-simulator session's observations report
(`sim/regen-braking-observations.md` on `feat/dualsense-driver`). Leaf numbers already sourced in
`teaching_materials.md` (same folder) are cited by their tags there ([N-JP-ZE1], [N-GL-ZE1],
[EPA-TCL], [ANL-2013]) and not repeated.

Source labels follow `teaching_materials.md`: **verified** (I opened the primary page or file and read
the number), **derived** (computed from verified inputs, method given), **secondary** (a reputable
magazine or aggregator, not the manufacturer or a lab), **search summary** (from a search-engine
summary or an abstract; full text not read), and **(assumed)** where nothing was found. All sources
were read on 31 October 2026.

Model values come from `origin/main` at b4b9e34, computed from the parameters by hand, by integrating
the road-load law (`scripts` below), or from one simulation of `PlanarBEVHardStop`. Items 7 and 8
were re-run after the planar ABS recalibration, which also turned the ABS rule on in the hard
stops (PR #162); their model values are from that run.

---

## Headline verdicts

| # | Item | Verdict |
|---|---|---|
| 1 | Road-load force vs EPA target A, B, C | **disagrees in shape**: +29 % at 20 km/h, agrees at 50 km/h (+2 %), −13 % at 100 km/h, −16 % at 130 km/h |
| 2 | Drag area CdA = 0.63 m² | **agrees** with Cd 0.28 times an estimated frontal area (the frontal area itself is unsourced) |
| 3 | Rolling resistance f_r = 0.012 | **disagrees**: the Leaf's OE tire is EU label class B (≤ 0.0077); 0.012 is class E |
| 4 | Coast-down times | 100 → 60 km/h **agrees** (−1 to −3 %); 100 → 20 km/h **disagrees** (−13 to −15 %; −28 % with the drivable model's machine drag) |
| 5 | Mass 1500 kg, wheel inertia 1 kg·m² | **agree** (Japanese curb mass 1490–1520 kg; measured 15″ wheel 0.77 kg·m²) |
| 6 | Lift-off regeneration | **disagrees**: the model has none; Nissan gives up to 0.2 g in e-Pedal, and the 2013 Leaf coasts in D about 2.8× faster than its coast-down alone |
| 7 | Blending strategy | series blending **agrees** with the Leaf's cooperative brake, and the hard stops withdraw regen while the ABS acts on a front wheel, as production does; **disagrees** on one point: the friction remainder ignores which axle regen acts on |
| 8 | 100 → 0 km/h dry stopping distance | **agrees within 7 %**: model 41.5 m (41.6 m friction only) vs 39 m measured on the ZE1 |

---

## Sources

- **[EPA-TCL]** US EPA, *Data on Cars Used for Testing Fuel Economy*
  ([page](https://www.epa.gov/compliance-and-fuel-economy-data/data-cars-used-testing-fuel-economy)),
  files `18tstcar-2018-10-24.xlsx`, `19tstcar-2020-10-02.xlsx`, `21-tstcar-2022-04-15.xlsx`,
  `22-testcar-2023-06-13.xlsx`, columns "Target Coef A (lbf)", "Target Coef B (lbf/mph)",
  "Target Coef C (lbf/mph\*\*2)", "Equivalent Test Weight (lbs.)". **verified**. Rows used: Nissan
  (NSX), "LEAF", test vehicle ID KWB115 (the 40 kWh car; KWC511 is the 62 kWh Leaf Plus):

  | Model years | ETW (lb) | A (lbf) | B (lbf/mph) | C (lbf/mph²) |
  |---|---|---|---|---|
  | 2018 | 3750 | 25.16 | 0.3639 | 0.01904 |
  | 2018, 2019 | 3750 | 26.06 | 0.3000 | 0.01965 |
  | 2018, 2019, 2021, 2022 | 3875 | 25.89 | 0.3449 | 0.01945 |

- **[N-JP-ZE1]** Nissan Japan ZE1 specification sheet, catalog 1709
  ([PDF](https://www3.nissan.co.jp/content/dam/Nissan/jp/vehicles/leaf/1709/pdf/leaf_specification.pdf)).
  **verified**: length 4480 mm, width 1790 mm, height 1540 mm, curb mass 1490 / 1510 / 1520 kg,
  tires 205/55R16 91V or 215/50R17 91V, front and rear ventilated discs, "回生協調ブレーキ:
  電動型制御ブレーキ" (cooperative regenerative brake, electrically controlled).
- **[N-GL-ZE1]** Nissan newsroom, release 170906-01-e: Cd 0.28. **verified** (in `teaching_materials.md`).
- **[EPREL-612557]** EU product database EPREL, registration 612557, Dunlop ENASAVE EC300 215/50R17
  91V, class C1 ([product sheet](https://eprel.ec.europa.eu/informationsheet/Fiche_612557_EN.pdf),
  [API record](https://eprel.ec.europa.eu/api/products/tyres/612557)). **verified**: fuel
  efficiency class B, wet grip class C, 70 dB, under Delegated Regulation (EU) 2020/740.
- **[EU-2020/740]** Regulation (EU) 2020/740 on the labeling of tyres, Annex I Part A, as published by
  the UK National Archives
  ([text](https://www.legislation.gov.uk/eur/2020/740/annex/I/data.htm?view=plain); EUR-Lex refused a
  scripted download). **verified**: C1 rolling-resistance classes in N/kN: A ≤ 6.5, B 6.6–7.7,
  C 7.8–9.0, D 9.1–10.5, E ≥ 10.6.
- **[AMS-2018]** auto motor und sport, "Nissan Leaf (2019) im Test"
  ([article](https://www.auto-motor-und-sport.de/test/nissan-leaf-ii-2019/),
  [technical data](https://www.auto-motor-und-sport.de/test/nissan-leaf-ii-2019/technische-daten/)).
  Magazine instrumented test of a 40 kWh Leaf, test date 05/2018, on Dunlop Enasave EC300
  215/50 R17 V. **verified** in the article text: "39 Meter Bremsweg aus Tempo 100". The measurement
  table (39.0 m / 9.9 m/s² and 39.5 m / 9.8 m/s²) sits behind a login: **search summary**.
- **[ANL-2013]** Argonne/INL, *2013 Nissan Leaf, Advanced Vehicle Testing – Baseline Testing Results*
  ([PDF](https://www.energy.gov/sites/prod/files/2015/01/f19/fact2013nissanleaf.pdf)). **verified**,
  p. 2 and notes 7–9: braking 60 → 0 mph on a dry surface 121.0 ft (3.12 s) at 50 % SoC and 115.2 ft
  (3.03 s) at 100 % SoC; "No battery charging occurred during most of the brake events; this implies
  that during a full brake request, the friction brakes are predominantly used"; coasting in Drive
  60 → 10 mph on a dry surface, 55.6 s, 2480.4 ft, 14.0 kW peak and 78.6 Wh into the battery;
  track coast-down A = 31.911 lb, B = 0.11588 lb/mph, C = 0.0177568 lb/mph². The car is the
  first-generation AZE0 (80 kW, 205/55R16 Bridgestone Ecopia EP422, F/R 58/42).
- **[N-EPEDAL]** Nissan Global newsroom, "e-Pedal: Easy driving using only the accelerator pedal",
  6 Dec 2017 ([page](https://global.nissannews.com/en/releases/e-pedal-easy-driving-using-only-the-accelerator-pedal)).
  **verified**: "Easing off the accelerator pedal creates a deceleration force (max 0.2G) comparable to
  stepping on the brake pedal"; "When the accelerator is fully released, regenerative and friction
  brakes are applied automatically".
- **[N-OM]** Nissan Leaf owner's manual, 2025, "Regenerative brake system"
  ([page](https://www.nissan.com.cy/ownership/car-owner-manual/manuals/iom/leaf/0ze2/e0/2025/regenerative-brake-system-1.shtml)).
  **verified**: "In the D (Drive) position, when the accelerator is released, the regenerative brake
  system provides some deceleration"; regen is reduced when the battery is full or its temperature
  is high or low. No number.
- **[FUJIKI-2011]** N. Fujiki, Y. Koike, Y. Itou, G. Suzuki, S. Gotoh (Nissan), Y. Ohtani,
  T. Yamaguchi (Hitachi Automotive Systems), "Development of an Electrically-Driven Intelligent Brake
  System for EV", EVTeC 2011, paper 20117211
  ([record](https://go.fisita.com/store/papers/evtec11/20117211)). **verified abstract**: an
  electrically driven brake that combines regeneration with conventional braking performance, and
  how the target brake force is set so regeneration does not compromise braking. Full text not read.
- **[FORD-770]** P. J. Curran, D. S. Crombez, A. Perach (Ford Global Technologies), "System and method
  for regenerative and antiskid braking within an electric vehicle", US 7,281,770 B1, filed 2000
  ([Google Patents](https://patents.google.com/patent/US7281770B1/en)). **verified**: the system
  "selectively disable[s] the regenerative braking function only when an antiskid braking event is
  detected at either of" the driven wheels, and keeps both friction and regen when the ABS acts on
  the non-driven wheels.
- **[FORD-358]** Ford Global Technologies, "Regenerative braking in the presence of an antilock braking
  system control event", US 9,156,358 B2, filed 2013
  ([Google Patents](https://patents.google.com/patent/US9156358B2/en)). **verified**, background:
  "during an ABS event regenerative braking is disabled to avoid destabilizing the vehicle". The
  invention instead lets the motor carry one frequency band of the ABS torque.
- **[TRB-SR286]** Transportation Research Board, *Tires and Passenger Vehicle Fuel Economy*, Special
  Report 286, National Academies, 2006
  ([read online, ch. 3](https://www.nationalacademies.org/read/11620/chapter/5)). **verified**: new
  tires "between 0.007 and 0.014" (p. 48); new original-equipment tires about 0.006–0.01 (p. 74);
  speed has a small influence within normal driving (pp. 46, 73).
- **[UBYSZ-2010]** A. Ubysz, "Problems of rotational mass in passenger vehicles", *Transport
  Problems* 5(1), 2010, Table 3
  ([PDF](http://transportproblems.polsl.pl/pl/archiwum/2010/zeszyt1/2010t5z1_04.pdf)). **verified**:
  wheel (steel rim + tire) inertia 0.391 kg·m² (165/70R13), 0.604 (175/65R14), 0.71 (175/70R14),
  0.774 (195/60R15, dynamic radius 298 mm); the tire carries 72–77 % of it.
- **[GAO-EHSANI-2001]** Y. Gao, M. Ehsani, SAE 2001-01-2478. **search summary** (in
  `teaching_materials.md` §4.4).
- **Scripts** (not committed; the numbers are reproducible from the formulas given): the road-load
  and coast-down integration is RK4 at 1 ms on `F(v)/M`; the stopping distance is
  `PlanarBEVHardStop` with `v0` and `P_charge` overridden, measured as `test/regen_plausibility.jl`'s
  `_rg_stop` does (from 0.5 s to the first sample under 0.5 m/s). The same script reproduces the
  test's 27.10 m and 26.94 m at 80 km/h.

---

## 1. Road-load force against the EPA coast-down targets

The model's law, `PlanarRoadLoad` defaults: F = ½ · 1.2 · 0.63 · v² + 0.012 · 1500 · 9.80665
= 0.378 v² + 176.5 N. The EPA rows converted to SI (1 lbf = 4.44822 N, 1 mph = 0.44704 m/s):

| Row | A (N) | B (N/(m/s)) | C (N/(m/s)²) | ETW (kg) |
|---|---|---|---|---|
| MY18, ETW 3750, (a) | 111.9 | 3.621 | 0.4238 | 1701 |
| MY18/19, ETW 3750, (b) | 115.9 | 2.985 | 0.4374 | 1701 |
| MY18–22, ETW 3875 | 115.2 | 3.432 | 0.4329 | 1758 |

| Speed | Model F (N) | EPA F (N), three rows | Source | Model ÷ EPA | Verdict |
|---|---|---|---|---|---|
| 20 km/h | 188.2 | 145.1 / 146.0 / 147.6 | [EPA-TCL] verified; F derived | 1.28–1.30 | disagrees |
| 50 km/h | 249.4 | 244.0 / 241.8 / 246.3 | same | 1.01–1.03 | agrees |
| 80 km/h | 363.2 | 401.7 / 398.2 / 405.2 | same | 0.90–0.91 | disagrees |
| 100 km/h | 468.2 | 539.5 / 536.3 / 544.5 | same | 0.86–0.87 | disagrees |
| 130 km/h | 669.4 | 795.3 / 794.1 / 803.6 | same | 0.83–0.84 | disagrees |

The three EPA rows agree with each other within 2 %, so the spread of the source is narrow and the
model sits outside it everywhere except near 50 km/h. The shape is the problem, not the level: the
model's constant term (176.5 N) is 1.5× EPA's A (112–116 N), and its v² term (0.378) is 0.87× EPA's C
(0.424–0.437), with no linear term against EPA's B of 3.0–3.6 N/(m/s) (97 N at 100 km/h).

Two caveats on reading EPA's coefficients as physics. A coast-down's A, B and C lump every loss that
decelerates the car in neutral: tire rolling resistance and its speed dependence, wheel-bearing and
brake drag, and the driveline, which on a single-reduction EV includes the motor's spin losses (its
rotor stays connected). So C/(½ρ) = 0.71–0.73 m² overstates the aerodynamic CdA, and A/(m g) =
0.0067–0.0069 is an upper bound on the tire's f_r. Second, the drivable model adds the machine's own
spin losses on top of the law (`DCMachine`: T_f + K_i + k_w ω² + C/ω, about 1.5–2.9 N·m at the shaft,
**51–76 N at the wheels**: 76 N at 20 km/h, 51 N at 100 km/h). Model law plus machine drag is 264 N at
20 km/h (1.81× EPA) and 519 N at 100 km/h (0.96×).

At WLTC speeds the two laws nearly cancel out: over WLTC class 3b at 1500 kg the course law needs
139.4 Wh/km of positive traction energy at the wheel and EPA's mean A, B, C need 148.8 Wh/km
(derived, same 1 Hz backward calculation as `teaching_materials.md` §4.1), so the course car is 6 %
light on WLTC, mostly from the motorway phase. Braking energy is the same, 36.2 Wh/km.

## 2. Drag area

| Quantity | Model | Published | Source | Ratio / difference | Verdict |
|---|---|---|---|---|---|
| Cd | — (CdA only) | 0.28 | [N-GL-ZE1] verified | — | — |
| Width × height | — | 1.790 m × 1.540 m = 2.757 m² | [N-JP-ZE1] verified | — | — |
| Frontal area A | 2.25 m² implied by 0.63 / 0.28 | not published; 0.80–0.85 × width × height = 2.21–2.34 m² | factor (assumed), no primary source found for the Leaf or for the factor | implied A is 0.816 × W × H | within the estimate's spread |
| CdA | 0.63 m² | 0.62–0.66 m² | derived from the two rows above | 0.96–1.02 | agrees (on an assumed frontal-area factor) |
| C/(½ρ) from the coast-down | 0.63 m² | 0.71–0.73 m² | [EPA-TCL], derived | 0.86–0.89 | not comparable: an upper bound that includes tire and driveline v² losses |

CdA agrees as far as it can be checked; no change proposed. The Leaf's frontal area remains a gap.

## 3. Rolling resistance

| Quantity | Model | Published | Source | Ratio | Verdict |
|---|---|---|---|---|---|
| f_r, Leaf OE tire (Dunlop Enasave EC300 215/50R17 91V, the tire of [AMS-2018]'s test car) | 0.012 | label class B: 0.0066–0.0077 | [EPREL-612557] + [EU-2020/740] verified | 1.56–1.82 | disagrees |
| 0.012 on the EU scale | 12 N/kN | class E (≥ 10.6 N/kN), the worst class | [EU-2020/740] verified | — | — |
| f_r, new OE passenger tires | 0.012 | 0.006–0.010 | [TRB-SR286] p. 74 verified | 1.2–2.0 | disagrees |
| f_r, all new passenger tires | 0.012 | 0.007–0.014, most near 0.010 | [TRB-SR286] p. 48 verified | inside the range | within the spread |
| A/(m g) from the coast-down (upper bound on f_r) | 0.012 | 0.0067–0.0069 at ETW | [EPA-TCL], derived | 1.74–1.79 | disagrees |

Label values are drum measurements under UN R117 Annex 6 (ISO 28580); on a real road surface the
rolling loss is 5–20 % higher ([TRB-SR286] p. 47), which still leaves the Leaf's tire at about
0.007–0.009. The 16-inch OE tire's label (205/55R16 91V, 40 kWh S/X trims) was not found. Verdict:
0.012 is a generic textbook value, not the Leaf's; it disagrees with everything specific to the car.

## 4. Coast-down times

From EPA's A, B, C at the row's ETW, against the model. "Model law" is `PlanarRoadLoad` alone with
the car's 1500 kg plus four wheels at 1 kg·m² (effective 1541.6 kg). "Drivable" adds what the
drivable model and the WLTC benches also carry: the machine rotor (0.05 kg·m² through 8.193 / 0.31 m,
34.9 kg) and the machine's spin losses with zero torque command.

| Case | 100 → 60 km/h (s) | 100 → 20 km/h (s) | Source |
|---|---|---|---|
| EPA, MY18 ETW 3750 (a) | 48.1 | 142.3 | [EPA-TCL], derived |
| EPA, MY18/19 ETW 3750 (b) | 48.5 | 143.1 | same |
| EPA, MY18–22 ETW 3875 | 49.2 | 145.4 | same |
| Model law, 1541.6 kg | 47.7 | 124.2 | derived |
| Drivable, 1576.5 kg + machine drag | 42.6 | 103.9 | derived |

| Quantity | Model | Published | Ratio | Verdict |
|---|---|---|---|---|
| 100 → 60 km/h, model law | 47.7 s | 48.1–49.2 s | 0.97–0.99 | agrees |
| 100 → 20 km/h, model law | 124.2 s | 142.3–145.4 s | 0.85–0.87 | disagrees |
| 100 → 60 km/h, drivable | 42.6 s | 48.1–49.2 s | 0.87–0.89 | disagrees |
| 100 → 20 km/h, drivable | 103.9 s | 142.3–145.4 s | 0.71–0.73 | disagrees |

The high-speed half agrees because the model's low C and high A cancel there; below 60 km/h the high
constant term decelerates the model car too fast. So the model car in neutral slows down *faster*
than the Leaf in neutral, not slower. The session's impression that the drag "does not seem real"
comes from item 6, not from the road load: a Leaf in D also regenerates on lift-off.

## 5. Mass and inertia

| Quantity | Model | Published | Source | Ratio / difference | Verdict |
|---|---|---|---|---|---|
| Curb mass | 1500 kg | 1490 / 1510 / 1520 kg (Japan, S / X / G) | [N-JP-ZE1] verified | −1.3 % to +0.7 % | agrees |
| Curb mass, EU | 1500 kg | 1545–1580 kg, probably with a 75 kg driver | ADAC, secondary (`teaching_materials.md` §1.2) | — | within the spread |
| EPA test weight | 1500 kg | 1701 / 1758 kg | [EPA-TCL] verified | 0.85–0.88 | not a like quantity: ETW is a test mass |
| Wheel + tire inertia | 1.0 kg·m² | 0.774 kg·m² for 195/60R15 on a steel rim (r_d 298 mm), rising with size; a 205/55R16 (r ≈ 0.316 m) would be around 0.85–0.95 (extrapolated) | [UBYSZ-2010] Table 3 verified; extrapolation derived | +5 % to +29 % | within the spread |

Effect on the coast-down (model law, derived):

| Change | Effective mass (kg) | 100 → 60 km/h (s) | 100 → 20 km/h (s) |
|---|---|---|---|
| As modeled (1500 kg, J = 1) | 1541.6 | 47.7 | 124.2 |
| Curb 1490 kg | 1531.6 | 47.5 | 123.9 |
| J = 0.77 kg·m² | 1532.0 | 47.4 | 123.4 |
| No wheel inertia | 1500.0 | 46.4 | 120.8 |
| Mass at ETW 1701 kg (rolling force scales too) | 1742.6 | 50.5 | 128.6 |

Mass and inertia move the coast-down by under 1 % within their sourced ranges, and even the 13 %
heavier test mass moves it by only 4–6 %, because the rolling term scales with mass as well. They do
not explain item 4's 15 % gap. No change proposed.

## 6. Lift-off regeneration

| Quantity | Model | Published | Source | Verdict |
|---|---|---|---|---|
| Lift-off deceleration, e-Pedal (ZE1) | 0 | up to 0.2 g (1.96 m/s²), friction brakes added near standstill and on low grip | [N-EPEDAL] verified | disagrees |
| Lift-off deceleration, D (ZE1) | 0 | "some deceleration", no number | [N-OM] verified | disagrees (not quantified) |
| Lift-off deceleration, B mode (ZE1) | 0 | stronger than D, weaker than e-Pedal; no number | reviews, search summary | not found (assumed) |
| Coasting in D, 60 → 10 mph, 2013 Leaf (AZE0) | — | 55.6 s, 756 m, 0.40 m/s² mean | [ANL-2013] verified | — |
| Same speeds on the 2013 Leaf's own track coast-down, no regen | — | 154.4 s, 2103 m | [ANL-2013] A, B, C at ETW 1701 kg, derived | — |
| Implied lift-off regen in D, 2013 Leaf | 0 | 0.25 m/s² (0.025 g) as a constant equivalent; ≈ 0.36 m/s² at 60 mph from the 14.0 kW peak at 85 % path efficiency | derived | disagrees |
| Same coast on the model law / drivable | 130.0 s / 107.4 s | 55.6 s | derived | disagrees |

The 2013 numbers close on themselves: 155 Wh of kinetic energy (1600 kg, 60 → 10 mph), less about
63 Wh of road load over 756 m, leaves 92 Wh at the wheels against the 78.6 Wh that reached the
battery, an 85 % path. So the measured D-mode coast is a regen of about 0.25 m/s² on top of the road
load. No ZE1 D or B-mode number was found from a primary source.

## 7. Brake blending

| Aspect | Model (`RegenBlend` + `ABSUnit`) | Production | Source | Verdict |
|---|---|---|---|---|
| Blending type | series: the machine takes the demand first, friction the remainder | series (cooperative) regen through an electrically driven brake that meters the hydraulic pressure against the regen | [N-JP-ZE1] verified; [FUJIKI-2011] verified abstract; [GAO-EHSANI-2001] search summary | agrees |
| Friction remainder per axle | `(tau_demand − tau_regen) · ratio / 4` to each wheel: the front axle, which already carries all the regen, gets the same friction share as the rear | friction is distributed per axle so the total front/rear force stays near the ideal (load-proportional) distribution; regen counts against the driven axle's share | [GAO-EHSANI-2001] search summary (series braking for "optimal energy recovery" maximizes regen within front/rear distribution limits); the Leaf's own front/rear balance was **not found** (assumed) | disagrees |
| Regen during an ABS event on the regen axle | withdrawn on the hard stops (`RegenBlend(abs_rule = true)`, `withdraw = 1`): the ceiling decays with 30 ms while `ABSUnit.front_active` reports a front brake held below its demand, and returns with 0.5 s; the rear axle does not trigger it. The drivable `PlanarBEVDrive` does not use the rule and holds regen | withdrawn: regen is disabled when the ABS acts on a driven wheel and kept when it acts on the non-driven axle | [FORD-770] verified; [FORD-358] background verified ("during an ABS event regenerative braking is disabled") | agrees on the hard stops |
| Regen in a full (panic) stop | the machine takes 0.84 % of the braking energy on the 80 km/h hard stop, 1.0 % from 100 km/h (28.7 % with `withdraw = 0`, whose front wheels turn backward) | the 2013 Leaf charged its battery in almost none of its 60 → 0 mph stops: "the friction brakes are predominantly used" | [ANL-2013] note 7 verified | agrees |

`RegenBlend` + `ABSUnit` is the textbook series strategy; with `abs_rule` it has the regen–ABS
coordination, and it still lacks the per-axle distribution of the remainder. Without the rule
(`withdraw = 0`, and the drivable `PlanarBEVDrive`) regen alone drives the front slip past the ABS
threshold, the ABS releases the front friction brakes, and on the hard stop the front wheels end up
turning backward.

## 8. Stopping distance, 100 → 0 km/h, dry

Model values from `PlanarBEVHardStop` (μ_A = 1.0, pedal at 0.5 s with a 0.1 s ramp, distance from
0.5 s to the first sample under 0.5 m/s), at its own 80 km/h and with `v0` set to 100 km/h:

| Run | Distance | Mean deceleration v₀²/2d | Machine's share of braking energy |
|---|---|---|---|
| 80 km/h, regen (`P_charge` = 80.5 kW, `withdraw` = 1) | 27.10 m | 9.11 m/s² | 0.008 |
| 80 km/h, friction only (`P_charge` = 0) | 26.94 m | 9.17 m/s² | 0.002 |
| 100 km/h, regen | 41.48 m | 9.30 m/s² | 0.010 |
| 100 km/h, friction only | 41.57 m | 9.28 m/s² | 0.002 |

| Quantity | Model | Published | Source | Ratio | Verdict |
|---|---|---|---|---|---|
| 100 → 0 km/h, ZE1 | 41.5 m (regen) / 41.6 m (friction) | 39 m (39.0 and 39.5 m, 9.8–9.9 m/s²) | [AMS-2018] magazine instrumented test; 39 m verified, the two runs search summary | 1.06 / 1.07 | agrees within 7 % |
| 60 → 0 mph (96.6 km/h), 2013 Leaf | — | 36.9 m at 50 % SoC, 35.1 m at 100 % SoC (9.75 / 10.2 m/s²) | [ANL-2013] verified (national-lab track test) | — | — |
| Same, scaled to 80 km/h at equal mean deceleration | 27.1 / 26.9 m | 25.3 m | derived | 1.07 / 1.06 | agrees within 7 % |
| Same, scaled to 100 km/h | 41.5 / 41.6 m | 39.6 m | derived | 1.05 / 1.05 | agrees within 5 % |

The model stops at 0.93–0.95 g where the Leaf stops at about 1.0 g. With regen withdrawn under ABS
the blend is nearly neutral: 0.16 m longer than friction alone from 80 km/h, 0.09 m shorter from
100 km/h. The remaining 2–3 m to the real car includes the 0.1 s pedal ramp and the sampled pressure
build-up. Lecture 3's own straight ABS stop, 26.5 m from 80 km/h, now passes its distance check in
`test/esp_plausibility.jl` (25–27 m).

---

## Proposed changes (only where the model disagrees)

### R1. Road load of the battery-electric car from the Leaf's EPA coast-down (items 1, 3, 4)

Lowering `f_r` alone to the tire's 0.0077 ([EPREL-612557], [EU-2020/740]) would fix the low-speed end
but make 100 km/h worse (455 N vs 540 N), because the course law has no term for the speed-dependent
tire, bearing and driveline losses that the Leaf's coast-down contains. Two options:

- **Adopt EPA's A, B, C for the BEV benches.** Give `RoadLoad` / `PlanarRoadLoad` a linear term
  (default 0, so Lectures 1–3 are unchanged) and set the BEV's road load to the KWB115 mean:
  A = 114.3 N, B = 3.35 N/(m/s), C = 0.431 N/(m/s)² ([EPA-TCL]). It is the only sourced road load for
  this car. WLTC traction at the wheel rises from 139.4 to 148.8 Wh/km (+6.7 %), which also closes
  the plan's "course road load is ~15 % below the Leaf's coastdown". In the drivable model and the
  WLTC benches the machine's spin losses (about 50 N at 100 km/h) then overlap the coast-down's
  driveline share; that overlap would be a stated known limit.
- **Keep the course law and relabel it.** Mark `f_r = 0.012` and `CdA = 0.63` as an effective pair
  `(assumed)` that matches the Leaf's coast-down within 3 % at 50 km/h and 13 % at 100 km/h, and
  keep S6's equal footing with Lecture 2's engine car.

I would pick the first for the battery-electric car, because S6 promises "Leaf-class numbers" and
this is the one road-load quantity with a primary Leaf source. It costs S6's identical road load
across lectures, which the energy-bill slide then has to state (or Lecture 2's car gets the same
law).

What it moves: `PlanarBEVWLTC`, `PlanarBEVRegenWLTC` and the drivable `PlanarBEVDrive`;
`test/bev_plausibility.jl` (131.2 Wh/km at the battery, and 47.2 against the engine car's
168.8 MJ/100 km) and `test/regen_plausibility.jl`'s WLTC set (23.85 % recovered share, braking
energy); `planar_wltc_plausibility.jl` if the planar WLTC bench shares the defaults; the Lecture 4
deck's energy-bill figures and the plan's WLTC reality anchors (139 Wh/km traction, 25–26 % braking
/ traction, which would fall to 24 %). Not `PlanarBEVHardStop`, which has no road load.

### R2. Lift-off regeneration in the drivable model (item 6)

Add a lift-off regen to the drivable model's pedal map (not to `RegenBlend`, whose contract is the
brake demand): a negative torque request at zero accelerator pedal. Sourced targets: up to 0.2 g in
an e-Pedal mode ([N-EPEDAL]); for D, about 0.025 g average and 0.037 g at 60 mph on the 2013 Leaf
(derived from [ANL-2013]). The ZE1's D and B levels were not found, so a D-mode level would be
`(derived)` from the 2013 car or `(assumed)`. Through `RegenBlend` it still obeys the charge-power and
fade limits.

What it moves: only the drivable model (`PlanarBEVDrive`, `sim/plant.jl`, the wasm build). The WLTC
benches follow the cycle with a PI driver that already commands braking torque, and the hard stop
has no throttle.

### R3. Per-axle friction remainder and regen withdrawal under ABS (item 7)

Two changes to the brake chain, each sourced:

1. Distribute the friction remainder per axle: compute each axle's friction share from a front/rear
   brake balance, minus the regen on the driven axle, instead of `(tau_demand − tau_regen) · ratio / 4`
   to every wheel ([GAO-EHSANI-2001], search summary). The Leaf's balance was not found; the static
   load split of the planar car (front 55.6 %, from `a` = 1.2 m and `b` = 1.5 m) or [ANL-2013]'s
   58/42 would be the `(assumed)` / `(INL)` starting point.
2. Withdraw regen while the ABS modulates a wheel of the regen (front) axle, and hand that axle to
   friction under ABS control; keep regen while only the rear is under ABS ([FORD-770]; consistent
   with [FORD-358]'s background and [ANL-2013]'s full-stop observation).

What it moves: `RegenBlend` (and a signal from `ABSUnit` to it), `PlanarBEVHardStop` (its docstring's
65 % front-grip statement and its energy split), `test/regen_plausibility.jl`'s hard-stop sets (49.3 %
machine share, 176.9 / 181.8 kJ, front friction held under 5 N·m, 36.22 m vs 38.82 m), the drivable
model, and the Lecture 4 deck's motor-versus-friction hard-stop figures. `PlanarBEVRegenWLTC` barely
moves: WLTC never triggers the ABS and friction carries 0.004 % of its braking.

Status: change 2 is `RegenBlend(abs_rule = true)`, on by default in `PlanarBEVHardStop`,
`PlanarBEVLowGripStop` and their hands-on copies, not in the drivable `PlanarBEVDrive`. Change 1 is
not made.

### R4. Stopping distance (item 8)

The 1.5× gap sits mostly in Lecture 3's friction braking and ABS, not in regen: friction alone stops
the model in 59 m against the Leaf's 39 m. The sourced target is a mean deceleration of
9.8–10.2 m/s² on dry asphalt ([AMS-2018], [ANL-2013]), i.e. 25–26 m from 80 km/h and 39–40 m from
100 km/h with μ_A = 1.0. The fix belongs to Lecture 3's ABS (`ABSUnit` thresholds, its front-axle
modulation, and whether the planar car's `load_transfer = false` default under-loads the front
axle); this note does not establish the cause. R3 should be redone against the corrected ABS.

What it moves: `Lecture3.ABSStraightStop` and its `@test_broken` in `test/esp_plausibility.jl`, the
ABS tests (`abs_full_car.jl`, `abs_handson_plausibility.jl`), the Lecture 3 deck's stop figures, and
through them `PlanarBEVHardStop`, `test/regen_plausibility.jl` and the Lecture 4 hard-stop figures.

Status: done by the planar ABS recalibration (release at the tire peaks, 80 ms prediction, 90 %
pressure retention): 26.5 m from 80 km/h for the ABS alone, 41.5 m from 100 km/h for the
battery-electric car, item 8 above.

---

## Gaps

- **ZE1 lift-off deceleration in D and B mode**: no number from Nissan or a lab. Only the e-Pedal
  maximum (0.2 g) and the 2013 Leaf's D-mode coast are sourced.
- **Leaf frontal area**: not published by Nissan; the CdA check rests on an assumed
  width × height factor.
- **Leaf front/rear brake balance and its ABS–regen logic**: not found. The production strategy above
  is from Ford's patents and a general cooperative-braking source; the Leaf-specific evidence is the
  2013 car's "friction brakes are predominantly used" in a full stop.
- **EU label of the 16-inch OE tire** (205/55R16 91V on the S and X trims): not found.
- **Measured inertia of a 205/55R16 wheel**: only a 15-inch measurement; the 16-inch value is
  extrapolated.
- **A primary ZE1 stopping distance**: the 39 m is a magazine test; the national-lab measurement is
  of the 2013 car.
