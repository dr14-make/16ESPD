# The Thevenin cell and the BMS: reference material for the 16ESPD extra session

Compiled 2026-11-12 for the theory lecture on 16 Nov 2026. It covers two short sections: the Thevenin
(1-RC) cell model and the battery management system (SoC estimation and drift, balancing, safety
limits). Material that other notes already hold is cited by tag and not repeated: the NMC OCV table
(Chen 2020 / PyBaMM), the INL Leaf pack resistances [INL-5045] in `teaching_materials.md`, and the
cell charge windows [PAN-NCR18650B], [LW-26650-2022] and the Leaf 55 °C charge pause [INL-DCFC-2015]
in `charging.md`.

Labels:

- `verified`: I opened the primary page or PDF, and the quote is taken from it.
- `read from figure`: read off a plot, with ± uncertainty.
- `secondary`: seen only in news, an aggregator, a vendor blog or a forum.
- `search summary`: seen only in a search-engine summary or an abstract listing; treat it as a lead.
- `derived`: my arithmetic or my fit on published data, with the formula or method shown.

---

## Headline numbers (for slides)

| Number | What | Source | Label |
|---|---|---|---|
| R0 ≈ 1.6 mΩ, R1 ≈ 1.1–1.9 mΩ, τ ≈ 19–29 s (C1 ≈ 10–20 kF) | 1-RC fit to 30 A, 30 s HPPC discharge pulses on a 2013 Nissan Leaf cell (33.1 Ah rated), 25 °C, pulses 1–9 (100 % down to ≈ 20 % SoC) | [ORNL-LEAF-ECM] | derived |
| τ ≈ 16–22 s | Same cell, fit to the 40 s rest that follows each pulse | [ORNL-LEAF-ECM] | derived |
| 2.5–2.6 mΩ | Same cell, 30 s pulse resistance (V before − V at 30 s)/I, mid SoC. Agrees with the INL 2.3–3.0 mΩ per cell already in the course | [ORNL-LEAF-ECM] | derived |
| 30 s discharge, 40 s rest, 10 s regen at 0.75× | Current USABC/INL EV HPPC profile, one profile per 10 % DOD step | [USABC-EV-R4] | verified |
| ≥ 1 h, or < 5 mV/h | "Default rest" before an OCV reading counts as equilibrium | [USABC-EV-R4] | verified |
| 1.2 Ah = 3.6 % of 33 Ah per day | SoC drift from a 50 mA current-sensor offset, coulomb counting only | formula below | derived |
| 0.054 % after 24 h | SoC error spread from zero-mean 10 mA current *noise* on a 1.5 Ah cell; noise averages out, an offset does not | [MOVASSAGH-2021] | verified |
| ≤ 5 % | Chinese national requirement on BMS "accumulative error of SOC estimation" for BEVs and plug-in hybrids (15 % for non-plug-in Li-ion hybrids) | [GBT-38661-2020] | verified (unofficial English translation excerpt) |
| ≤ 10 mV, ±2 °C | Same standard: cell voltage max error, temperature accuracy −20 to 65 °C | [GBT-38661-2020] | verified (same caveat) |
| ≈ 6 % vs ≈ 1 % | TI bench test: peak SoC error of plain coulomb counting (capacity not learned) vs Impedance Track | [TI-SLUAAR3] | verified |
| 0.148 V vs 0.583 V | ΔOCV/ΔSOC annotation on OCV curves of an LFP vs an NMC cell | [NEJAD-2016] | verified (figure annotation; range it spans not stated in the text I read) |
| 6.8 % vs 1.7 % SoC | SoC error from a 10 mV voltage error, LFP vs NMC, using the two slopes above | formula below | derived |
| 240 mA | TI BQ79616-Q1 internal passive balancing current, 16S, ASIL D capable | [TI-BQ79616] | verified |
| 300 mA | NXP MC33771C on-board passive balancing MOSFETs, 14 cells, ASIL D capable | [NXP-MC33771C] | verified |
| up to 200 mA | ADI LTC6813-1 passive balancing, 18 cells | [ADI-LTC6813] | search summary |
| 0.28 % | Relative capacity variation among 1100 fresh LFP cells (impedance 0.72 %) | [RUMPF-2017] | verified (abstract) |
| 1.4–3.3 h | Time to bleed 1 % of a 33 Ah cell at 240 mA … 100 mA | formula below | derived |
| ASIL D, FTTI ≤ 800 ms | Safety goal "prevent thermal run-away" (OV, UV, OC, OT); the BMS must meet "ASIL C or ASIL D" | [IFX-AN1104] | verified |
| 85.5 °C / 198.0 °C vs 124.4 °C / 256.3 °C | Self-heating onset / start of thermal runaway, NMC vs LFP 21700 cells at 100 % SoC (ARC) | [OHNESEIT-2023] | verified |
| 0 to 60 °C charge, −30 to 60 °C discharge; < 250 mA below 0 °C | LFP power-cell datasheet temperature windows | [LW-26650-2022] | verified |

---

## 1. Thevenin (1-RC) cell model

### What it adds to V = E − I·R

The course model is V = E − I·R. The Thevenin cell keeps an OCV(SoC) source and a series R0, and adds
one R1‖C1 branch. For a current step I (discharge positive) from rest:

    V(t) = OCV(SoC) − I·R0 − I·R1·(1 − e^(−t/τ)),   τ = R1·C1

and after the current stops, the RC voltage decays as I·R1·(1 − e^(−t_p/τ))·e^(−(t − t_p)/τ). So the
cell shows an instant drop (R0), a slow sag over tens of seconds (R1, τ), and slow recovery at rest,
which is why a voltage read under load or shortly after load is not the OCV.

### Sources

**[PLETT-2015]** Gregory L. Plett, *Battery Management Systems, Volume I: Battery Modeling*, Artech
House (Artech House power engineering series), 2015. ISBN 978-1-63081-023-8 (ebook 978-1-63081-024-5).
Label: `verified` for the bibliographic data and the chapter title "2. Equivalent-Circuit Models"
(university library catalog TOC: https://vufind.katalog.k.utb.cz/Record/kn-ocn978618037/TOC). I did
not read the book; it is the standard textbook reference for the equivalent-circuit model, and the
ORNL code below cites it for its SoC (coulomb counting) equation.

**[HU-2012]** Xiaosong Hu, Shengbo Li, Huei Peng, "A comparative study of equivalent circuit models for
Li-ion batteries", *Journal of Power Sources* 198 (2012) 359–367, doi:10.1016/j.jpowsour.2011.10.013.
Label: `verified` for the bibliographic data (Semantic Scholar API); `search summary` for content: it
compares twelve lumped models on two Li-ion cell types at three temperatures, fitted by multi-swarm
particle swarm optimization. ScienceDirect returned 403; I could not read the abstract or the ranking
of models, so do not quote which model it recommends from this note.

**[NEJAD-2016]** S. Nejad, D. T. Gladwin, D. A. Stone, "A systematic review of lumped-parameter
equivalent circuit models for real-time estimation of lithium-ion battery states", *Journal of Power
Sources* 316 (2016) 183–196, doi:10.1016/j.jpowsour.2016.03.042. Accepted manuscript:
https://eprints.whiterose.ac.uk/id/eprint/113902/ . Label: `verified` (accepted manuscript). Quotes:

- Abstract: the models compared "include the Combined model, Rint model, two hysteresis models,
  Randles' model, a modified Randles' model and two resistor-capacitor (RC) network models with and
  without hysteresis included. Two variations of the lithium-ion cell chemistry, namely the lithium-ion
  iron phosphate (LiFePO4) and lithium nickel-manganese-cobalt oxide (LiNMC) are used".
- Table 1 test cells: LiFePO4 3300 mAh, 3.2 V nominal, 3.65 V end of charge, 2.0 V end of discharge,
  30 mΩ; LiNMC 3600 mAh, 3.65 V, 4.2 V, 2.75 V, 20 mΩ. These are 18650-size laboratory cells, not
  automotive cells.
- Search summary of its conclusion (I did not locate the sentence in the manuscript text): "both RC
  model structures provide the best dynamic performance".

**[USABC-EV-R4]** USABC / INL, *Battery Test Manual for Electric Vehicles, Revision 4*, INL/MIS-25-83864,
October 2025. https://uscar.org/download/247/usabc-manuals/16391/electric-vehicle-test-manual.pdf .
Label: `verified`. It supersedes INL/EXT-15-34184 Rev. 3 (June 2015), which I did not open. Quotes:

- "The objective of this test is to determine the 30-second discharge-pulse and the 10-second
  regen-pulse power capabilities at each 10% depth of discharge increment relative to the BOL
  operating capacity … Between the set of discharge and regen pulses, the device is discharged to the
  next 10% increment based on operating capacity using the C/3 rate."
- Table 2, HPPC test profile: 30 s at relative current 1.00; 40 s at 0; 10 s at −0.75.
- "Additional data from the HPPC test includes the voltage response curves, from which the fixed
  (ohmic) cell resistance and cell polarization resistance as a function of capacity removed can be
  determined assuming sufficient resolution to reliably establish cell voltage response time
  constants".
- "Default rest [h] – a fixed rest period determined at BOL, it is at least one hour, or the time
  needed to achieve thermal and voltage equilibrium (e.g., rate of change less than 1°C/hour or less
  than 5 mV/h)."
- "The voltages during each rest period are recorded to establish the cell's OCV (open-circuit
  voltage) behavior."
- §4.4.2: "resistance can be calculated using a V/I calculation at each 10% increment."

Note for slides: the 12 V start/stop manual (INL/EXT-12-26503 Rev. 1, May 2015, `verified`) uses a
different profile (1 s discharge, 40 s rest, 10 s regen at −0.33), so "the HPPC test" is not one fixed
profile; cite the EV manual.

**[ORNL-LEAF-ECM]** batterysim (ORNL), *equiv-circ-model*, GitHub, MIT license, last commit 34752e7
(2023-08-03). https://github.com/batterysim/equiv-circ-model . Label: `verified` for the README and
the data file; the RC values in the table below are `derived` (my fit). README: "an equivalent circuit
model (ECM) developed for a 2013 Nissan Leaf battery cell and module … Model parameters are determined
from hybrid pulse power characterization (HPPC) and discharge tests conducted at ORNL. The battery cell
and module specifications were provided by NREL." `examples/cell/params.py`: "rated capacity for the
battery cell is stated as 33.1 Ah".

Data file `examples/data/cell-low-current-hppc-25c-2.csv` (Bitrode log, 1 s sampling, 1 mV
resolution). What the log shows, read from the step records: charge to 4.200 V, 3600 s rest
(4.182 V), then per SoC step: −30 A for 30 s, 40 s rest, +22.5 A for 10 s (0.75 × 30 A, the USABC EV
profile above), −10 A for 1080 s (3.0 Ah, ≈ C/3 by 10 % of capacity), 3600 s rest. Ten pulse sets;
the last C/3 step ends at 3.000 V.

My fit (`derived`), per discharge pulse k: R0 = (V_rest − a)/I and R1 = b/I from a least-squares fit of
V(t) = a − b·(1 − e^(−t/τ)) to the 30 s pulse samples (t = 0.5…30 s, I = 30 A); separately, τ from a
fit of V(t) = a − b·e^(−t/τ) to the 40 s rest after the pulse; "R30" = (V_rest − V(30 s))/I. SoC at
pulse k is nominally 100 % − (k − 1)·≈10 % (3.0 Ah steps plus the small net pulse charge, on 30–33 Ah).

| Pulse | V_rest (V) | R0 (mΩ) | R1 (mΩ) | τ, pulse fit (s) | C1 = τ/R1 (F) | τ, rest fit (s) | R30 (mΩ) |
|---|---|---|---|---|---|---|---|
| 1 | 4.182 | 1.85 | 1.85 | 19.4 | 10 505 | 16.9 | 3.33 |
| 2 | 4.086 | 1.64 | 1.25 | 19.5 | 15 611 | 17.1 | 2.63 |
| 3 | 4.048 | 1.62 | 1.74 | 24.8 | 14 286 | 22.0 | 2.87 |
| 4 | 3.984 | 1.58 | 1.08 | 19.4 | 17 915 | 16.2 | 2.47 |
| 5 | 3.949 | 1.60 | 1.34 | 25.7 | 19 205 | 21.2 | 2.53 |
| 6 | 3.909 | 1.60 | 1.34 | 27.3 | 20 301 | 16.6 | 2.53 |
| 7 | 3.869 | 1.61 | 1.36 | 27.2 | 19 937 | 17.4 | 2.53 |
| 8 | 3.802 | 1.61 | 1.48 | 29.4 | 19 919 | 17.6 | 2.53 |
| 9 | 3.723 | 1.61 | 1.24 | 22.6 | 18 134 | 18.6 | 2.57 |
| 10 | 3.531 | 1.70 | 7.94 | 89.9 | 11 317 | 17.1 | 3.97 |

Caveats: pulse 10 (≈ 10 % SoC) does not fit one RC branch (OCV curvature at low SoC); exclude it. A
30 s window cannot pin τ well when τ is near 30 s, which is why the pulse and rest fits differ by a
few seconds; τ is "about 20 s" for this cell, not a precise number. R0 here includes everything faster
than the first 0.5 s sample. A 1 mV resolution on a ≈ 48 mV step gives about ±2 % on R0. The repo's own
code fits two time constants to the 1 h rest after each C/3 step instead; I did not run it.

Suggested slide set (pulse 5, ≈ 60 % SoC): R0 = 1.60 mΩ, R1 = 1.34 mΩ, τ = 25.7 s, C1 ≈ 19 kF. For
I = 30 A: instant drop I·R0 = 48 mV; RC sag after 30 s = I·R1·(1 − e^(−30/25.7)) = 27.7 mV; total
75.7 mV, against 75.9 mV measured (R30 = 2.53 mΩ). `derived`.

**[BD-THEVENIN]** Battery Design (batterydesign.net), "Thevenin Model", undated, no author shown.
https://www.batterydesign.net/modelling/thevenin-model/ . Label: `secondary`. It says "a typical τ1
in the 5-10 s range" and gives a hypothetical large-cell example (R0 2.0 mΩ, R1 1.2 mΩ, τ1 18 s,
C1 ≈ 15 kF). It cites no papers. The Leaf fit above gives ≈ 20 s, so do not use its 5–10 s claim.

---

## 2. SoC estimation and drift

### Coulomb counting and why it drifts

SoC(t) = SoC(0) − (1/Q)·∫ I dt. A constant current-sensor offset I_off integrates linearly:
ΔSoC = I_off·t/Q. Zero-mean noise only grows as √t and stays small.

Worked number (`derived`): I_off = 50 mA, t = 24 h, Q = 33 Ah (Leaf cell) →
ΔQ = 0.050 A × 24 h = 1.2 Ah → ΔSoC = 1.2/33 = 3.6 % per day, all in one direction. The offset is
"seen" whenever the car is awake (driving, charging, preconditioning), so a week of use without a
correction can eat a GB/T-sized 5 % error budget twice over.

**[MOVASSAGH-2021]** K. Movassagh, S. A. Raihan, B. Balasingam, K. Pattipati, "A Critical Look at
Coulomb Counting Towards Improving the Kalman Filter Based State of Charge Tracking Algorithms in
Rechargeable Batteries", arXiv:2101.05435 (Jan 2021; marked as submitted to IEEE TCST; a related
version appeared in *Energies* 2021 per search summary). https://arxiv.org/abs/2101.05435 . Label:
`verified` (arXiv HTML). Quotes: "For time-cumulative errors, the standard deviation of the error keeps
increasing with time"; with an assumed 1.5 Ah cell and 10 mA current-noise standard deviation, Table II
gives SoC error standard deviations of 0.0111 % after 1 h, 0.0544 % after 24 h and 1.0399 % after
1 year (Δ = 1 s); "it is often suggested to rest the battery before taking the voltage measurement for
SOC lookup". The paper treats noise, not bias; the contrast with the 3.6 %/day offset above is mine.

**[PLETT-ECEA5732]** University of Colorado Boulder, course page "ECEA 5732 Battery State-of-Charge
(SOC) Estimation", instructor Gregory Plett.
https://www.colorado.edu/ecee/online-masters/curriculum/power-electronics/ecea-5732-battery-state-charge-soc-estimation .
Label: `verified`. Quote: "What do we do if the current-sensor has a dc bias error, as is often the
case?"

**[TI-SLUAAR3]** Nick Richards, *Battery Gauging Algorithm Comparison*, Texas Instruments application
note SLUAAR3, December 2023. https://www.ti.com/lit/SLUAAR3 . Label: `verified`. Portable-battery
gauges, not automotive, but the mechanisms are the same. Quotes:

- "The main issue with coulomb counting is knowing what the starting amount of charge is in the
  battery. Thus, full charge is needed to initialize SOC, otherwise SOC is unknown."
- "The peak error for coulomb counting is about 6% for both test 1 and 2, assuming the FCC was not
  learned. … The peak error for Impedance Track is about 1% for both test 1 and 2." Voltage correlation
  alone: "around 20% for test 1 and 17% for test 2".
- Impedance Track: "Self-discharge is frequently compensated by OCV readings".

**[MPS-SOC]** A. Rodriguez, M. Á. Sánchez, T. Hudson, "Optimizing State-of-Charge (SOC) Accuracy and
Battery Management System Design", Monolithic Power Systems, undated.
https://www.monolithicpower.com/en/learning/resources/optimizing-state-of-charge-accuracy-and-battery-management-system-design .
Label: `verified` (vendor article). Quotes: "In all scenarios, the BM current measurement offset was
20mA"; "any error in the current measurement causes the SOC to drift over time"; "Note that LFP
chemistry is more sensitive to voltage measurement inaccuracy because of its flat OCV"; OCV
"corrections may be infrequent since they only occur during relaxation periods." No numeric SoC error
in the text (only in figures).

### OCV reset at rest, and how long rest takes

- USABC defines a usable rest as "at least one hour, or the time needed to achieve thermal and voltage
  equilibrium (e.g., … less than 5 mV/h)" [USABC-EV-R4], `verified`.
- [NEJAD-2016] used "a 60 minute rest" before each OCV point, and notes that for LFP "the hysteresis
  level decreases with increasing rest period", which "requires for a long rest period for the cell to
  reach an equilibrium potential". `verified`.
- A TI E2E blog post says LiFePO4 "have a very long relaxation time, so we can increase the data flash
  parameter 'OCV wait time' to 18000 seconds (5 hours)". `search summary` (TI E2E blog "Giving more
  life to LiFePO4 batteries", https://e2e.ti.com/blogs_/archives/b/fullycharged/posts/giving-more-life-to-lifepo4-batteries ; not opened).
- The Leaf HPPC log above shows the relaxation directly: after the first C/3 step the voltage rises from
  4.049 V at end of discharge to 4.077 V after 60 s and 4.086 V after 3600 s [ORNL-LEAF-ECM], `verified`
  (read from the CSV). So a reading after one minute is still 9 mV short of the 1 h value.

### The LFP flat-OCV problem and hysteresis

**[NEJAD-2016]**, `verified`: "within the useable SOC range of 20% to 80%, the OCV curve for the
LiFePO4 chemistry is fairly flat. This implies that for those OCV-based SOC estimators, even a small
error in the voltage measurement within this region can result in a large deviation from the actual
SOC value." And: "the hysteresis level for the LiFePO4 chemistry is considerably higher than that for
the LiNMC chemistry." Fig. 3 annotates ΔOCV/ΔSOC = 0.148 V (LiFePO4) and 0.583 V (LiNMC); the
extracted text does not say over which SoC span the slope was taken. The hysteresis plots (Fig. 3b, d)
have axes up to 60 mV (LFP) and 25 mV (NMC); I did not read values off them.

`derived`: SoC error per voltage error = ΔV/(ΔOCV/ΔSOC). For 10 mV (the GB/T maximum cell-voltage
error): LFP 0.010/0.148 = 6.8 %, NMC 0.010/0.583 = 1.7 %. For a 2 mV AFE-class error on LFP: 1.4 %.
These use an average slope; on the LFP plateau itself the local slope is smaller and the error larger.

Vendor claims, `secondary`: ACCURE blog says LFP charge/discharge OCV curves differ by "typically
5–25 mV" even after long rests and that plateau SoC errors can exceed ±15 %
(https://www.accure.net/blogs/battery-hysteresis-effect ;
https://www.accure.net/blogs/state-of-charge-soc-estimation-errors-for-lfp-batteries-can-exceed-15). Not
opened; listed as leads only.

### Kalman filters in production BMSs

**[PLETT-2004]** Gregory L. Plett, "Extended Kalman filtering for battery management systems of
LiPB-based HEV battery packs", *Journal of Power Sources* 134 (2004): Part 1. Background, 252–261,
doi:10.1016/j.jpowsour.2004.02.031; Part 2. Modeling and identification, 262–276,
doi:10.1016/j.jpowsour.2004.02.032; Part 3. State and parameter estimation, 277–292,
doi:10.1016/j.jpowsour.2004.02.033. Label: `verified` for the bibliographic data (Semantic Scholar
API); `search summary` for content: Part 1 proposes "A method based on extended Kalman filtering … for a
lithium ion polymer battery pack" to estimate "battery state of charge, power fade, capacity fade, and
instantaneous available power". Abstracts are elided by the publisher in the APIs and ScienceDirect
returned 403.

I found no primary source that states that production BMSs use Kalman filters, nor an OEM statement of
the algorithm in a named car. Plett's patents and the Toyota bias-estimation patent US 10,408,880
(search summary) show industrial use, but I did not open them.

### SoC accuracy targets

**[GBT-38661-2020]** GB/T 38661-2020, *Technical Specifications of Battery Management System for
Electric Vehicles*, issued 2020-03-31, implemented 2020-10-01. English translation excerpt on
chinesestandard.net: https://www.chinesestandard.net/PDF.aspx/GBT38661-2020 . Label: `verified`, but
from a commercial translator's excerpt, not the official Chinese text. Quotes, §5.5: "For pure electric
vehicles, and hybrid electric vehicles that can be externally charged, the accumulative error of SOC
estimation of the battery management system shall be not more than 5%." "For hybrid electric vehicles
that cannot be externally charged, the accumulative error of SOC estimation of the li-ion battery
management system shall be not more than 15%". §5.4 (paraphrased by the fetch tool, not word for
word): cell voltage ±0.5 % FS with absolute maximum error 10 mV; pack current ±2 % FS (Li-ion); pack
voltage ±1 % FS; temperature ±2 °C from −20 to 65 °C, ±3 °C outside it.

For "±3–5 %" as a typical automotive claim I found no better primary source than this 5 % requirement.

---

## 3. Cell balancing

### Why cells drift apart

**[IFX-AN1104]** (full entry in §4), `verified`: "High-voltage batteries are built out of many single
cells in series, which inevitably have production variances, such as differences in battery capacity.
If cell balancing is not present, the two most unbalanced cells define how much of the battery pack
can be utilized in terms of working range. The cell with the highest state of charge … will limit the
total charge of the whole series, whilst the cell with the lowest state of charge … will limit the
operating time."

**[RUMPF-2017]** K. Rumpf, M. Naumann, A. Jossen, "Experimental investigation of parametric
cell-to-cell variation and correlation based on 1100 commercial lithium-ion cells", *Journal of Energy
Storage* 14 (2017) 224–243, doi:10.1016/j.est.2017.09.010. TUM portal:
https://portal.fis.tum.de/en/publications/experimental-investigation-of-parametric-cell-to-cell-variation-a/ .
Label: `verified` (abstract on the TUM portal). Quotes: "The determined relative variation of capacity
and impedance is small: 0.28% and 0.72% respectively"; "The variation of the cell impedance allows no
conclusion about the variation of the cell capacity." Cells: 1100 fresh LiFePO4/graphite cells from
two batches.

**[SCHUSTER-2015]** S. F. Schuster, M. J. Brand, P. Berg, M. Gleissenberger, A. Jossen, "Lithium-ion
cell-to-cell variation during battery electric vehicle operation", *Journal of Power Sources* 297 (2015)
242–251, doi:10.1016/j.jpowsour.2015.08.001. Label: `verified` for bibliographic data (OpenAlex);
`search summary` for content: cells taken from BEV packs after use; the authors' later dissertation
says the initial production variation "is generally increased in multi-cell battery applications with
the progress of aging". I could not open the paper (403) or the TUM dissertation (bot wall), so I have
no aged-pack spread number.

Self-discharge as a driver, `derived` and weak: [NEJAD-2016] states that in the Randles' model "𝑅d models
the cell's no-load self-discharge (typically ~ 70k Ω)" (`verified`). For a 3.7 V cell that is
3.7/70 000 = 53 µA, i.e. 0.038 Ah per 30 days, ≈ 1.1 % per month of a 3.6 Ah cell. The value is a
generic modeling figure, not a measured self-discharge spread; what unbalances a pack is the
*difference* in self-discharge between cells, which I have no source for.

Temperature: no primary source found giving a number for temperature-gradient-driven imbalance; the
mechanism (warmer cells self-discharge and age faster) is a gap.

### Passive balancing: AFE balancing currents

**[TI-BQ79616]** Texas Instruments, BQ79616-Q1 product page, https://www.ti.com/product/BQ79616-Q1
(datasheet SLUSE81E, Aug 2020 – Nov 2023, not opened). Label: `verified`. Quotes: "Balancing current at
240mA"; "Number of series cells (max) 16"; "+/- 1.5mV ADC accuracy"; "Systematic capability up to ASIL
D"; "Hardware capability up to ASIL D".

**[TI-SLVAE87]** Taylor Vogt, *BQ7961x-Q1 Design Recommendations for High Voltage Automotive BMS*, TI
user's guide SLVAE87B, December 2020, revised June 2025. Label: `verified`. Quotes: "The device
integrates internal cell balancing MOSFETs (CBFET) across each CB channel to enable passive cell
balancing." "The balancing current is determined by the cell voltage, the external resistor in series
with the CB pin, and the internal CBFET RDS(ON)." I_CB = V_CELL/(R_DS(ON) + 2·R_CB) (Eq. 2). "Passive
balancing dissipates heat to the die, increasing the die temperature as balancing current increases."

**[NXP-MC33771C]** NXP, MC33771C product page, https://nxp.com/products/MC33771C . Label: `verified`.
Quotes: "Onboard 300mA Low Rdson passive cell balancing MOSFETs with diagnostics"; "14 Cell Voltage
Measurement Channels"; "0.8 mV maximum total voltage measurement error"; "Support ISO 26262, up to ASIL
D safety capability".

**[ADI-LTC6813]** Analog Devices, LTC6813-1 product page and datasheet,
https://www.analog.com/en/products/ltc6813-1.html . Label: `search summary` (analog.com timed out three
times). Summary: "Passive Cell Balancing Up to 200mA (Max) with Programmable Pulse-Width Modulation",
18 cells.

`derived`, balancing time: bleeding 1 % of a 33 Ah cell (0.33 Ah) takes 0.33/0.24 = 1.4 h at 240 mA,
0.33/0.30 = 1.1 h at 300 mA, 0.33/0.10 = 3.3 h at 100 mA. Power per cell at 240 mA and 3.7 V is
0.89 W, all heat, which is why the AFE pauses balancing on die temperature.

Leaf balancing: a repair-manual excerpt (search summary) says the Leaf LBC "detects the voltage of each
cell" and turns on "bypass switches to discharge cells" with excess capacity; a MyNissanLeaf forum
teardown names a 430 Ω bypass resistor and "less than a 10 ma" balancing load (`secondary`). If true,
1 % of 33 Ah would take 33 h, i.e. balancing that only works over many parking periods. Treat as a
lead, not a slide number.

### Active vs passive

**[UZAIR-2021]** M. Uzair, G. Abbas, S. Hosain, "Characteristics of Battery Management Systems of
Electric Vehicles with Consideration of the Active and Passive Cell Balancing Process", *World Electric
Vehicle Journal* 12(3) (2021) 120, doi:10.3390/wevj12030120, CC-BY. Label: `verified` (abstract via
OpenAlex). Quote: "a comparative study is also carried out for active and passive cell balance
technique in MATLAB/Simulink with an eight cell battery pack … The result shows that the active cell
balancing technique is more advantageous than passive balancing for electrical vehicles". This is a
simulation review, and the AFE pages above show production parts are passive.

---

## 4. Safety limits and functional safety

**[IFX-AN1104]** Infineon, *FuSa in a Nutshell: BMS application with AURIX™ TC4xx*, application note
AN1104, V 1.0, 2025-10-24.
https://www.infineon.cn/assets/row/public/documents/10/42/infineon-fusa-in-a-nutshell-bms-application-with-aurix-tc4xx-applicationnotes-en.pdf .
Label: `verified`. It says it is "for training purposes only and is not to be taken as a blueprint".
Quotes:

- "To prevent thermal runaway, a battery-disconnect-unit (BDU) can disconnect the battery cell from
  the supply. To provide these safety features, the BMS needs to fulfill the ASIL C or ASIL D
  requirements, depending on the safety category of the cells used."
- "SG1: Prevent thermal run-away of the battery cells due to OV, UV, OC, OT. In general, Faut [sic]
  Tolerant Time Interval (FTTI) is <= 800ms and safety rating assigned is ASIL D"
- "SG2: Avoid of electric shock because of crash or HV insulation loss. In general, FTTI is <=30ms and
  safety rating assigned is ASIL B"
- "If cell OV, UV, OC or OT is detected, the system shall go to a safe state by interrupting the HV
  circuit within FTTI (i.e., disconnecting the HV battery from any source of charge)."
- Temperature sensing: "accurate measurement in the expected temperature range (-45°C to 85°C)";
  "The highest accuracy is required in the range of overtemperature alarm and pre-warning (40°C to
  70°C)."

**[MAXIM-LEAF-2018]** Maxim Integrated press release "Nissan Integrates Maxim's Battery Monitoring IC
Into New Nissan LEAF", PR Newswire, 2018-09-20, via https://ycharts.com/news/story/PRN-SF13104-20180920 .
Label: `verified`. Quote: "single-chip, ASIL D-rated battery monitoring IC". Part number not named in
the text I read.

ISO 26262 itself (ISO 26262:2018, *Road vehicles — Functional safety*) is paywalled and not opened;
ASIL is assigned per hazard from severity, exposure and controllability, so "the BMS is ASIL D" is
shorthand for "its thermal-runaway safety goal is ASIL D". A review, Haghbin et al., "Automotive
Battery Pack Standards and Design Characteristics: A Review", *Discover Applied Sciences* 7 (2025) 731,
arXiv:2503.12566 (`search summary`), lists "SG1: battery shall not get fire, ASIL D … SG4: battery
shall not allow over-charge, ASIL C".

### Voltage, current, temperature windows

Cell-level windows come from the cell datasheet; the BMS enforces them with margin.

- LFP [LW-26650-2022] (Lithium Werks ANR26650M1B, 08/2022), `verified`: 3.3 V nominal; "Recommended
  Fast Charge Voltage 3.6 V"; "Minimum Voltage / HPPC Pulse 2 V / 1.6 V"; discharge "Temperature -30 ºC
  to 60 ºC"; "Temperature Range (Charging current at <250mA when under 0ºC 0 ºC to 60 ºC"; "Max
  Continuous Discharge Current 52 A (20C rate)"; "Max Continuous Charge Current 10 A (4C rate)".
- Layered-oxide 18650 [PAN-NCR18650B], see `charging.md`: charge 0 to +45 °C, 4.20 V CV.
- Leaf pack: "battery temperatures above 55°C will cause a charge event to pause" [INL-DCFC-2015],
  see `charging.md`.
- [NEJAD-2016] Table 1, `verified`: LFP 2.0–3.65 V, NMC 2.75–4.2 V.

Why no charging below 0 °C: lithium plating, sourced in `charging.md` [DAS-2024].

### Thermal runaway onset by chemistry

**[OHNESEIT-2023]** S. Ohneseit, P. Finster, C. Floras, N. Lubenau, N. Uhlmann, H. J. Seifert, "Thermal
and Mechanical Safety Assessment of Type 21700 Lithium-Ion Batteries with NMC, NCA and LFP
Cathodes–Investigation of Cell Abuse by Means of Accelerating Rate Calorimetry (ARC)", *Batteries*
9(5) (2023) 237, doi:10.3390/batteries9050237, CC-BY. KIT copy:
https://publikationen.bibliothek.kit.edu/1000160506 . Label: `verified`. Onset = self-heating rate
"> 0.02 °C/min"; start of thermal runaway = "exothermal and >1 °C step skipped in data log"
(Table 3). Table 10, "Average critical temperatures for SOC 100 for all cells with their standard
deviation" (heat-wait-seek, ARC):

| Cell (≈ capacity) | Onset (°C) | CID trigger (°C) | Venting (°C) | Start TR (°C) | Max (°C) |
|---|---|---|---|---|---|
| NMC (≈ 5 Ah) | 85.5 ± 4.9 | 91.9 ± 1.2 | 121.5 ± 5.8 | 198.0 ± 0.2 | 591.6 ± 20.9 |
| NCA-HE I (≈ 5 Ah) | 95.3 ± 0.4 | 112.3 ± 0.2 | 133.3 ± 1.8 | 203.1 ± 0.6 | 644.3 ± 160.1 |
| NCA-HP (≈ 4 Ah) | 95.5 ± 5.1 | 108.2 ± 2.5 | 131.5 ± 0.9 | 202.6 ± 1.3 | 676.6 ± 98.3 |
| LFP (≈ 3 Ah) | 124.4 ± 14.4 | 163.5 ± 5.0 | 168.8 ± 1.8 | 256.3 ± 10.3 | 498.6 ± 43.9 |

(Capacities from the text: "The capacity of NMC and NCA-HE cells was comparable and close to 5 Ah,
NCA-HP was nearly 4 Ah and LFP about 3 Ah." NCA-HE II omitted here.) Abstract: "LFP cells reacted, as
expected, more slowly and at significantly higher temperatures"; "at SOC 0 and SOC 30 for LFP cells
and at SOC 0 for the other cell chemistries, no thermal runaway occurred until 350 °C."

**[GOLUBKOV-2014]** A. W. Golubkov et al., "Thermal-runaway experiments on consumer Li-ion batteries
with metal-oxide and olivin-type cathodes", *RSC Advances* 4(7) (2014) 3633–3642,
doi:10.1039/c3ra45748f, CC-BY. Label: `verified` (abstract via OpenAlex): 18650 cells with LiFePO4,
NMC and LCO/NMC blend cathodes; "Cell temperatures up to 850 °C and a gas release of up to 0.27 mol
were measured." Per-chemistry onset temperatures not read (RSC returned 403).

**[SCHOEBERL-2026]** J. Schöberl et al., "Modeling the variability of thermal runaway behavior in
large-format cylindrical cells with NMC-811 and LFP cathodes: A simulation study", *Journal of Power
Sources* 668 (2026) 239206, doi:10.1016/j.jpowsour.2025.239206, CC-BY. Abstract `verified` (OpenAlex):
"thermal runaway propagation by heat transfer is unlikely in the case of a LFP cell chemistry". The
4680 ARC values T1 ≈ 109 °C (NMC-811) vs ≈ 159 °C (LFP), T2 ≈ 183 °C vs ≈ 239 °C are `search summary`.

---

## 5. BMS architecture (optional)

The parts above give the modular master/slave layout directly: a cell monitoring unit / AFE per module
(BQ79616: 6–16 cells; MC33771C: 14 cells; LTC6813: 18 cells) measures cell voltages and temperatures and
runs passive balancing, and talks over an isolated daisy chain to a pack controller that does SoC,
contactor (BDU) control and safety. TI SLVAE87B: "isolated, bidirectional, daisy chain ports supports
both capacitor- and transformer-based isolation … for centralized or distribution architectures
commonly found in the xEV powertrain system" (`verified`). Infineon AN1104: "To control and balance the
single cells, the CMU unit is used. It measures the voltage and the temperature of the cells and
operates the balancing between the cells" (`verified`).

---

## Gaps

1. Hu, Li, Peng 2012 and Plett 2004: bibliographic data verified, but abstracts and findings not read
   (publisher 403, abstracts elided in APIs). Do not quote their conclusions from this note.
2. No published, peer-reviewed 1-RC parameter table for an automotive NMC/LMO cell was opened; the
   R0/R1/τ values are my fit to ORNL's Leaf cell data. The repo's own two-time-constant fit was not run.
3. No primary source states that production BMSs use Kalman filters, or names the algorithm in a
   specific car.
4. Only one SoC-accuracy requirement (GB/T 38661, 5 %), read from a translator's excerpt. No OEM
   accuracy claim.
5. No aged-pack capacity spread number: Schuster 2015 and the TUM dissertation were blocked. Fresh-cell
   spread (0.28 %, LFP) is verified.
6. No measured cell-to-cell self-discharge difference, and no number for temperature-driven imbalance.
7. LTC6813 (200 mA) is a search summary: analog.com timed out.
8. Leaf LBC balancing current (430 Ω, < 10 mA) is forum-only; the official service-manual page was
   unreachable.
9. LFP hysteresis magnitude in mV: only axis ranges from [NEJAD-2016] and a vendor blog; no value read.
10. ISO 26262 text not opened; ASIL ratings come from the Infineon note (ASIL D thermal runaway, ASIL B
    shock) and a review (ASIL C overcharge, search summary).
