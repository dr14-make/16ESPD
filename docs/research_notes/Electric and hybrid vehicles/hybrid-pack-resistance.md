# Internal resistance of the 2011 Sonata Hybrid pack, for HybridDrive's R0

Question: what is a defensible, sourced value for the series resistance `R0` of a ≈ 1.4 kWh, 270 V
lithium-ion full-hybrid pack, specifically the 2011 Hyundai Sonata Hybrid's, for the Lecture 5
`HybridDrive` battery (constant `E`, series `R0`, capacity `Q_nom`)? Today
`R0 = 0.1·E/350 ≈ 0.077 Ω`, the Leaf pack's 0.1 Ω scaled by series count only.

Source labels follow `teaching_materials.md` (same folder): **verified** (I opened the primary file
and read the number), **read from figure** (verified source, value read off a plot, with the
reading tolerance), **derived** (computed from verified inputs, method given), **estimate**
(derived with an assumption that is not sourced). All sources were read on 5 November 2026.

---

## Short answer

**Recommended `R0 = 0.33 Ω`** for the whole pack: Idaho National Laboratory's (INL) measured
10-second discharge pulse resistance of a new 2011 Sonata Hybrid pack in the middle of its charge
window. Two cars were tested; both new packs measured 0.32–0.38 Ω across 30–60 % depth of
discharge (DOD), charge and discharge alike ([INL-3539], [INL-4932]).

- **Conditions**: beginning of test (new, 4,100–5,700 mi), HPPC per the FreedomCAR power-assist
  manual, resistance taken at the end of a 10 s pulse, 30–60 % DOD. Test temperature is not stated
  in either report.
- **Confidence**: high that the new pack's 10 s pulse resistance is 0.32–0.38 Ω mid-window (two
  cars, two labs, and it reproduces INL's own 10 s power figures, see Derivation). Medium that
  10 s resistance is the right value for a model with no RC pair: a 10 s value includes
  charge-transfer and diffusion polarization, so it overstates the loss of sub-second transients.
  The car's own on-road voltage sag puts the effective resistance for short pulses at roughly
  0.14–0.20 Ω (estimate, below).
- **What it changes**: at 110 A the I²R loss rises from 0.93 kW (0.077 Ω) to 4.0 kW (0.33 Ω),
  4.3×. The current `R0` is 4.3× below the measured value and lets the model pack deliver about
  4.5× its measured 10 s discharge power.

Recommendation for the code (not edited here): replace `R0 = 0.1·E/350` with
`R0 = 0.33·E/270`, tagged `(INL) 10 s discharge pulse resistance, new pack, 30–60 % DOD`. The
`E/270` factor keeps series-count scaling at fixed cells (72 × 4.6 mΩ) if `V_nom` is changed, and
is exactly 0.33 Ω at the 270 V default. Run 0.2 Ω as the sensitivity case for short-pulse
behavior.

---

## The pack

| Quantity | Value | Source |
|---|---|---|
| Cell maker, chemistry | LG Chem, lithium-ion polymer, manganese spinel | verified [INL-3539] App. A; [ORNL-2011] "Technical Accomplishments (5)" |
| Cells | 72 | verified [INL-3539] App. A |
| Cell rated capacity | 5.3 Ah | verified [INL-3539] App. A, Table 1 |
| Cell / pack nominal voltage | 3.75 V / 270 V | verified [INL-3539] App. A |
| Configuration | 72 in series, 1 string (72 × 3.75 V = 270 V, pack Ah = cell Ah) | derived |
| HPPC cell voltage limits | 2.4 V min, 4.3 V max (pack 172.8 V / 309.6 V) | verified [INL-3539] Table 2; pack derived |
| Measured capacity, new | 5.29 Ah, 1,394 Wh (car 3539); 5.26 Ah, 1,395 Wh (car 4932), C/1 | verified [INL-3539], [INL-4932] Table 1 |
| Motor rating | 30 kW (ORNL), 34 kW (INL appendix "manufacturer's peak power rating") | verified [ORNL-2011], [INL-3539] App. A |
| Pack rated power | not published by Hyundai or the labs in what I found | — |

The model's `Q_nom = 1.4 kWh / 270 V = 5.19 Ah` agrees with the 5.3 Ah rating within 2 %.

---

## Evidence

All resistances are **pack** values, from the HPPC test (FreedomCAR power-assist manual,
DOE/ID-11069, procedures 3.2 and 3.3), taken "at the end of the 10-second pulse interval". The
reports plot resistance against energy discharged from full; DOD ≈ Wh / 1,394. Plot readings carry
±0.01 Ω.

| Pack (new) | Pulse | 10–20 % DOD | 30–60 % DOD | 70–80 % DOD | Last point | Source |
|---|---|---|---|---|---|---|
| Car 3539 (5,730 mi) | discharge 10 s | 0.32–0.34 | **0.32–0.34** | 0.36–0.40 | 0.50 at 92 % DOD | read from figure [INL-3539] Fig. 4 |
| Car 3539 | charge 10 s | 0.32–0.34 | 0.32–0.35 | 0.36–0.39 | 0.48 at 93 % DOD | read from figure [INL-3539] Fig. 2 |
| Car 4932 (4,123 mi) | discharge 10 s | 0.34–0.35 | **0.34–0.38** | 0.40–0.43 | 0.46 at 82 % DOD | read from figure [INL-4932] Fig. 4 |
| Car 4932 | charge 10 s | 0.35–0.36 | 0.34–0.38 | 0.39–0.42 | 0.45 at 84 % DOD | read from figure [INL-4932] Fig. 2 |

Aged packs, same figures, 300–600 Wh discharged: car 3539 at 160,116 mi 0.50–0.56 Ω, car 4932 at
120,507 mi 0.44–0.48 Ω (discharge 10 s; read from figure).

Power figures the labs computed from the same tests ("calculated value based on selected battery
voltage limits and at 50% SOC"):

| Pack, state | 10 s discharge power, 50 % DOD | 10 s charge power, 50 % DOD | Source |
|---|---|---|---|
| Car 3539, new | 48.9 kW | 34.1 kW | verified [INL-3539] Table 2, App. A |
| Car 3539, aged | 23.4 kW | 29.3 kW | verified [INL-3539] Table 2 |
| Car 4932, new | 46.2 kW | 30.2 kW | verified [INL-4932] Table 2 |
| Car 4932, aged | 29.9 kW | 29.8 kW | verified [INL-4932] Table 2 |

On-road peaks (dynamometer, new car 4932, reported in [INL-3539] App. A):

| Test | Peak discharge power | Minimum pack voltage | Source |
|---|---|---|---|
| Full-throttle acceleration | 43.3 kW (10 s average 26.5 kW) | 246.5 V | verified [INL-3539] App. A |
| UDDS | 39.3 kW | 252.7 V | verified [INL-3539] App. A |
| US06 | 43.5 kW | 256.4 V | verified [INL-3539] App. A |

Timescale reference, a different cell: on a 20 Ah LiFePO₄ pouch cell at 5C and 25 °C, DC
discharge resistance rises from 1.31 mΩ at 0.1 s (taken as ohmic) to 2.12 mΩ at 10 s, +62 %;
charge +52 % ([BARAI-2018] Table 1). Search summary for the Sonata cell itself: no published ohmic
(≤ 0.1 s) or 1 s resistance of the LG Chem 5.3 Ah cell was found.

---

## Derivation

**Recommended value.** The four new-pack curves at 30–60 % DOD span 0.32–0.38 Ω; the discharge
curves, which govern motoring, give 0.32–0.34 Ω (car 3539) and 0.34–0.38 Ω (car 4932). 0.33 Ω sits
at the low-middle of that band. Per cell, 0.33 Ω / 72 = 4.6 mΩ at 10 s (derived).

**Check against INL's own power figures.** HPPC discharge power at the minimum-voltage limit is
`P = V_min (OCV − V_min) / R`. OCV at 50 % DOD is ≈ 274 V (read from [INL-3539] Fig. 1, C/1
discharge at ≈ 700 Wh; at 5.3 A the C/1 sag is under 2 V). With V_min = 72 × 2.4 = 172.8 V and
R = 0.33 Ω: P = 172.8 × 101.2 / 0.33 = 53 kW, against 48.9 and 46.2 kW reported (derived; 8–15 %
high, within the spread of the OCV reading and of R between the cars). Charge at V_max = 309.6 V:
P = 309.6 × 35.6 / 0.33 = 33 kW, against 34.1 and 30.2 kW reported. The resistance and the power
tables agree. With today's 0.077 Ω the same formula gives 227 kW discharge and 143 kW charge, 4.6×
and 4.2× what the pack does. The matched-load limit V²/(4R) is 57 kW at 0.33 Ω, but it does not
apply: the 2.4 V cell limit (172.8 V) binds before the matched-load voltage of 137 V.

**Short-pulse estimate from the road data (estimate).** If the minimum pack voltage coincided with
the peak power and OCV was ≈ 280 V (≈ 40 % DOD; the starting SoC is not reported), then
R ≈ (OCV − V_min) / (P / V_min): acceleration (280 − 246.5) / 176 A = 0.19 Ω, UDDS 27.3 / 156 A =
0.18 Ω, US06 23.6 / 170 A = 0.14 Ω. These are loose: peak power and minimum voltage need not
fall in the same sample, OCV is assumed, and the pulses are a few seconds. They agree in direction
with [BARAI-2018]: a pulse shorter than 10 s sees roughly 0.6× the 10 s resistance, i.e. ≈ 0.2 Ω.

**Why series scaling from the Leaf fails.** Pack R = n_series · R_cell / n_parallel. Scaling the
Leaf's 0.1 Ω by 270/350 keeps the Leaf's 2 mΩ, 56 Ah cells, two in parallel: a ≈ 30 kWh pack at 72 in series. The
same-chemistry-family scaling at fixed specific resistance (2 mΩ · 56 Ah / 5.3 Ah = 21 mΩ per
cell, × 72 = 1.5 Ω) overshoots the other way by 4.6×. HEV cells are built for power: 4.6 mΩ at
5.3 Ah is ≈ 24 mΩ·Ah against the Leaf model's ≈ 110 mΩ·Ah. Neither scaling replaces the measurement.

---

## SoC and temperature

- **SoC**: across 40–70 % SoC (30–60 % DOD), the new packs' 10 s resistance varies by ±3–6 %
  around its mid value (0.32–0.34 Ω on car 3539, 0.34–0.38 Ω on car 4932). It rises steeply only
  below ≈ 20 % SoC (0.45–0.50 Ω at the last points, 82–93 % DOD). A constant `R0` is adequate for a
  charge-sustaining hybrid held at `SoC0 = 0.6`.
- **Temperature**: neither report states the HPPC temperature, and no Sonata data at other
  temperatures were found. Li-ion pulse resistance rises substantially below room temperature
  (unsourced here), so 0.33 Ω applies to a warm pack only.
- **Age**: after 120,000–160,000 mi the mid-window resistance was 0.44–0.56 Ω, +30–75 %, and
  10 s discharge power fell 35–52 %. The recommendation is for a new pack.

---

## What the recommendation changes

| Quantity | R0 = 0.077 Ω (today) | R0 = 0.2 Ω (short-pulse case) | R0 = 0.33 Ω (recommended) |
|---|---|---|---|
| I²R loss at 110 A | 0.93 kW | 2.4 kW | 4.0 kW |
| Terminal voltage at 110 A, E = 270 V | 261.5 V | 248 V | 233.7 V |
| Battery efficiency at 110 A discharge | 96.9 % | 91.9 % | 86.6 % |
| Current for 30 kW at the terminals | 115 A | 122 A | 133 A |
| Loss at 30 kW at the terminals | 1.0 kW | 3.0 kW | 5.8 kW |
| 10 s discharge power to 172.8 V | 218 kW | 84 kW | 51 kW (INL measured 46–49 kW) |

All derived from `v = E − R0·i` with E = 270 V. Battery efficiency is terminal power over
`E·i`; a charge-sustaining cycle pays it twice (charge, then discharge), so the round trip at
110 A drops from ≈ 94 % to ≈ 76 %. That lowers the hybrid's fuel saving on WLTC; how much depends
on the energy manager's power split and needs a run, not an estimate here.

`R0 = 0.1·E/350` should change: it is unsourced, physically mis-scaled, and 4.3× below the
measured value. The `HybridDrive` docstring's caveat ("small high-power hybrid cells may sag
more") is confirmed by the INL data.

---

## Uncertain

- **Ohmic vs 10 s.** No ohmic or 1 s resistance for the Sonata pack or its cell was found. The
  0.6× ratio rests on one LiFePO₄ cell ([BARAI-2018]) and loose road data. A model with an RC pair
  would take R0 ≈ 0.2 Ω and put the remaining ≈ 0.13 Ω in the RC branch (estimate).
- **HPPC temperature and pulse current**: not stated in either report; the footnote says only that
  the measured capacity "was used to determine the magnitude of current".
- **Pack rated power**: no Hyundai or lab rating found; the INL 10 s capability is the only power
  figure for the pack.
- **Plot readings**: ±0.01 Ω; the reports give no resistance tables.

---

## Sources

- **[INL-3539]** T. Gray, M. Shirk, J. Wishart, *2011 Hyundai Sonata 3539 – Hybrid Electric
  Vehicle Battery Test Results*, INL/EXT-14-32109, September 2014. Testing by Intertek Testing
  Services NA. [PDF](https://inldigitallibrary.inl.gov/sites/sti/sti/6236936.pdf),
  [OSTI 1164856](https://www.osti.gov/biblio/1164856). **verified**: Table 1 (capacity), Table 2
  (HPPC power, voltage limits), Figs. 1–5 (p. 2–4), Appendix A (p. 12–13: LG Chem, lithium-ion
  polymer, 5.3 Ah, 270 V, 3.75 V, 72 cells; on-road results from car 4932's baseline).
- **[INL-4932]** T. Gray, M. Shirk, J. Wishart, *2011 Hyundai Sonata 4932 – Hybrid Electric
  Vehicle Battery Test Results*, INL/EXT-13-29679, July 2013. Testing by ECOtality North America.
  [PDF](https://www.osti.gov/servlets/purl/1097169),
  [OSTI 1097169](https://www.osti.gov/biblio/1097169). **verified**: Table 1, Table 2, Figs. 1–4
  (p. 1–4). Testing ended at 120,507 mi after a drivetrain malfunction (footnote 3).
- **[ORNL-2011]** T. Burress, ORNL, *Benchmarking State-of-the-Art Technologies*, DOE VTP Annual
  Merit Review, APE006, 2011.
  [PDF](https://www.energy.gov/sites/prod/files/2014/03/f10/ape006_burress_2011_o.pdf).
  **verified**: "Technical Accomplishments (5)": 30 kW machine, "270 V lithium polymer battery by
  LG Chem", manganese spinel, 1.4 kWh. No battery resistance or power rating.
- **[BARAI-2018]** A. Barai, K. Uddin, W. D. Widanage, A. McGordon, P. Jennings, "A study of the
  influence of measurement timescale on internal resistance characterisation methodologies for
  lithium-ion cells", *Scientific Reports* 8, 21 (2018).
  [Article](https://pmc.ncbi.nlm.nih.gov/articles/PMC5758786/). **verified** (Table 1, 5C
  values); 20 Ah LiFePO₄ pouch cell, not the Sonata's chemistry.
