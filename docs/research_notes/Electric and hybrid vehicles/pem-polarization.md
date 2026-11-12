# PEM fuel-cell polarization curve, hydrogen consumption and efficiency (slide data)

Research note for 16ESPD (CTU Prague), theory slides for the fuel-cell lecture on Monday 16 Nov 2026.
Compiled 2026-11-12. This note adds to section 6 of `hydrogen.md` and corrects one point in it (b₁₁, see §2).

**Verification labels** (same as `hydrogen.md`)
- `verified`: I opened the primary page or PDF myself, and the quote is copied from it.
- `read from figure`: the value was read off a chart, with ± uncertainty.
- `secondary`: the value comes from a source that quotes the primary, which I could not open.
- `search summary`: I saw only a search-engine snippet.
- `derived`: my own arithmetic on labeled inputs. The formula is shown.

---

## 1. Recommended slide curve

**Model.** The Pukrushpan stack-voltage model for the 75 kW Ford P2000 stack, with the membrane coefficient
**b₁₁ = 0.005139** (thesis value, see §2), evaluated at one operating point:

- stack temperature T = 80 °C (353.15 K), the model's nominal temperature;
- cathode pressure p_ca = 2.5 bar (the middle of the 1–4 bar fit data);
- fully humidified gases and membrane, λ_m = 14;
- oxygen excess ratio 2, so p_O2 = 0.1173 (p_ca − p_sat), and anode at the same pressure, p_H2 = p_ca − p_sat;
- p_sat(80 °C) = 0.474 bar.

With these assumptions the Nernst and v₀ terms cancel to a constant, E − v₀ = 0.950 V, at any T and pressure (`derived`, §2.3).
That also matches the ≈ 0.95 V intercept of the thesis's own fitted curves (Fig. 3.7, `read from figure`, ±0.02 V).

**Slide formula** (`derived` from the `verified` equations of [PUKRUSHPAN-2003], i in A/cm²):

> V_cell(i) = 0.950 − 0.178 · (1 − e^(−10·i)) − 0.1575 · i − i · (0.390 · i / 2.2)²
>
> activation (saturating Tafel substitute) · ohmic · concentration

| Term | Value at 80 °C, 2.5 bar | Origin |
|---|---|---|
| E − v₀ | 0.950 V | 1.229 − 0.279, the pressure and temperature terms cancel |
| v_a | 0.1781 V | Eq. (3.21), quadratic in (p_O2/0.1173 + p_sat) = 2.5 |
| c₁ | 10 cm²/A | Eq. (3.21) |
| R_ohm = t_m/σ_m | 0.1575 Ω·cm² | t_m = 0.01275 cm, σ_m = (0.005139·14 − 0.00326)·exp[350(1/303 − 1/353.15)] = 0.0810 S/cm |
| c₂ | 0.390 | Eq. (3.21), branch for (p_O2/0.1173 + p_sat) ≥ 2 |
| i_max, c₃ | 2.2 A/cm², 2 | Eq. (3.21) |

**Values** (`derived`; script logic in §2.3):

| i (A/cm²) | V_cell (V) | activation | ohmic | concentration | η_LHV = V/1.253 | η_HHV = V/1.481 | p (W/cm²) |
|---|---|---|---|---|---|---|---|
| 0.1 | **0.822** | 0.112 | 0.016 | 0.000 | 65.6 % | 55.5 % | 0.08 |
| 0.5 | **0.690** | 0.177 | 0.079 | 0.004 | 55.1 % | 46.6 % | 0.35 |
| 1.0 | **0.583** | 0.178 | 0.158 | 0.031 | 46.5 % | 39.4 % | 0.58 |
| 1.5 | **0.430** | 0.178 | 0.236 | 0.106 | 34.3 % | 29.0 % | 0.64 |

(Activation is shown here as v_act − v₀, the part that grows with current.)

**How to present it.**
- This is a 1999-era stack with a thick membrane. 0.58 V at 1 A/cm² is right for that stack: at 3 bar the same model gives 0.608 V, at 3.5 bar 0.628 V (`derived`).
- Overlay the measured 2017 Toyota Mirai points from §4 (≈ 0.74 V at 0.95 A/cm²). The gap is mostly the ohmic term: 0.16 V at 1 A/cm² for the P2000 membrane.
  The thinner membrane is one of the three causes Toyota gives for the Mirai gain (§4.2).
- Efficiency on the same axis: η_LHV ≈ μ_f · V_cell / 1.253 (§5). Fuel utilization μ_f ≈ 1 is assumed in the table.
- If the slide needs one-line constants instead of the five-term model, see §3. The Larminie & Dicks constants could **not** be verified.

---

## 2. Pukrushpan model and the b₁₁ verdict

### 2.1 Sources

**[PUKRUSHPAN-2003]** J. T. Pukrushpan, *Modeling and Control of Fuel Cell Systems and Fuel Processors*, PhD dissertation,
Mechanical Engineering, University of Michigan, 2003. Author-hosted PDF:
https://public.websites.umich.edu/~annastef/FuelCellPdf/pukrushpan_thesis.pdf (opened 2026-11-12). Label: `verified`.
The Springer book (Pukrushpan, Stefanopoulou, Peng, *Control of Fuel Cell Power Systems*, 2004) is built on this thesis. I did not open the book.

**[PUKRUSHPAN-JDSMC-2004]** J. T. Pukrushpan, H. Peng, A. G. Stefanopoulou, "Control-Oriented Modeling and Analysis for Automotive
Fuel Cell Systems", *ASME J. Dyn. Sys., Meas., Control* 126 (2004) 14–25.
Author copy: https://public.websites.umich.edu/~annastef/papers/Pukrushpan2004JDSMC.pdf. Label: `verified`.

**[SPRINGER-1991]** T. E. Springer, T. A. Zawodzinski, S. Gottesfeld, "Polymer electrolyte fuel cell model",
*J. Electrochem. Soc.* 138(8) (1991) 2334–2342. Paywalled; not opened. Label: `secondary` (quoted by [PUKRUSHPAN-2003] as its ref. [100]).

### 2.2 Verdict: b₁₁ = 0.005139. The 0.05139 in the JDSMC paper is a misprint.

Four independent checks agree.

1. **The thesis states 0.005139 twice, with the arithmetic** ([PUKRUSHPAN-2003], §3.1.5, p. 32, `verified`):
   > "b1 = b11 (14) − b12 = 0.005139(14) − 0.00326 = 0.068686 (3.20)
   > where b11 = 0.005139 and b12 = 0.00326 given in [100] are used. The value of b2 = 350 is, however,
   > modified from the one given in [100] to match the data."

   Eq. (3.21) on the same page repeats "b1 = 0.005139λm − 0.00326". Ref. [100] is Springer et al. (1991).
2. **The JDSMC paper prints the other value** ([PUKRUSHPAN-JDSMC-2004], Eq. 8, p. 17, `verified`):
   > "b 11⫽0.05139, b 12⫽0.00326, b 2 ⫽350"

   The paper says it uses the Nafion 117 values of its ref. [6]: "where the value of t m , b 11 and b 12 for the Nafion 117 membrane [6] are used, and b 2 is adjusted to fit our fuel cell data."
   So it claims the same Springer values as the thesis. One digit was dropped in typesetting.
3. **The thesis's own ohmic-loss plot fixes the magnitude** ([PUKRUSHPAN-2003], Fig. 3.9, p. 33, "Ohmic overvoltage for 80 °C", `read from figure`):
   the line reaches ≈ 0.29 V (±0.01) at ≈ 1.83 A/cm², so R_ohm ≈ 0.158 Ω·cm².
   - With b₁₁ = 0.005139: R_ohm = **0.1575 Ω·cm²** (`derived`). This matches the plot.
   - With b₁₁ = 0.05139: R_ohm = 0.0151 Ω·cm², which would give only 0.028 V at 1.83 A/cm².
4. **The model with 0.005139 reproduces the thesis's fitted curves** (Fig. 3.7, 94 °C, 1–4 bar, `read from figure`, ±0.02 V; model `derived`):

   | Case at 94 °C | Fig. 3.7 (read) | Model, b₁₁ = 0.005139 | Model, b₁₁ = 0.05139 |
   |---|---|---|---|
   | 4 bar, 0.5 A/cm² | ≈ 0.75 | 0.747 | 0.816 |
   | 4 bar, 1.0 A/cm² | ≈ 0.66 | 0.650 | 0.787 |
   | 1 bar, 1.0 A/cm² | ≈ 0.40 | 0.399 | 0.536 |
   | 1 bar, curve reaches 0 V | ≈ 1.52 A/cm² | ≈ 1.5 A/cm² (0.018 V at 1.5) | 0.224 V at 1.5 |

   The 0.05139 value is 0.07–0.14 V too high against the paper's own data.

Physical sanity check (`derived`): with 0.005139, σ_m = 0.081 S/cm at 80 °C and λ = 14. That is the usual order for hydrated Nafion.
With 0.05139 it would be 0.84 S/cm, about ten times too high.

`hydrogen.md` §6 calls 0.005139 "the value I recall from the original Springer et al. (1991) correlation". It is now confirmed via the thesis quote above.
Springer's own temperature coefficient (1268 K, from memory) was **not** verified. The thesis says only that b₂ = 350 was "modified from the one given in [100]".

### 2.3 Full equation set and how the slide numbers were computed

From [PUKRUSHPAN-2003] Eq. (3.18) and (3.21), `verified`. The thesis states that "pca (bar) is the cathode pressure, psat (bar) is water saturation pressure".
The JDSMC paper states the Nernst pressures in atm. The thesis divides by 1.01325, so both are consistent.

- v_fc = E − [v₀ + v_a(1 − e^(−c₁ i))] − i·R_ohm − i·(c₂ i / i_max)^c₃
- E = 1.229 − 8.5×10⁻⁴ (T − 298.15) + 4.308×10⁻⁵ T [ln(p_H2/1.01325) + ½ ln(p_O2/1.01325)]
  (JDSMC prints 4.3085×10⁻⁵, which is used here.)
- v₀ = 0.279 − 8.5×10⁻⁴ (T − 298.15) + 4.308×10⁻⁵ T [ln((p_ca − p_sat)/1.01325) + ½ ln(0.1173 (p_ca − p_sat)/1.01325)]
- v_a = (−1.618×10⁻⁵ T + 1.618×10⁻²) x² + (1.8×10⁻⁴ T − 0.166) x + (−5.8×10⁻⁴ T + 0.5736), with x = p_O2/0.1173 + p_sat
- c₂ = (7.16×10⁻⁴ T − 0.622) x + (−1.45×10⁻³ T + 1.68) for x < 2 atm; otherwise (8.66×10⁻⁵ T − 0.068) x + (−1.6×10⁻⁴ T + 0.54)
- σ_m = (0.005139 λ_m − 0.00326) exp[350 (1/303 − 1/T)], R_ohm = t_m/σ_m
- c₁ = 10, i_max = 2.2, c₃ = 2

**Why E − v₀ = 0.950 V** (`derived`). With p_H2 = p_ca − p_sat and p_O2 = 0.1173 (p_ca − p_sat), the log terms in E and v₀ are identical. So does the temperature term.
What remains is 1.229 − 0.279 = 0.950 V.

**Membrane thickness.** Table 4.1 of the thesis (`verified`) gives "tm membrane thickness 0.01275 cm", "n number of cell in fuel cell stack 381", "Afc fuel cell active area 280 cm2".
Eq. (3.21) prints "tm = 0.0125". Using 0.0125 changes R_ohm to 0.154 Ω·cm² and V(1 A/cm²) by +0.003 V, which does not matter for the slide.

**Inputs not in the source.** p_sat(80 °C) = 0.474 bar comes from a standard vapor-pressure fit, not from the thesis. The full-humidity, equal-pressure anode assumption is mine.
The paper's regression assumption ("cathode gas is fully humidified and oxygen excess ratio … is regulated at 2") is `verified` in [PUKRUSHPAN-JDSMC-2004] p. 17.

**Open discrepancy (minor).** Thesis Fig. 3.8 (activation overvoltage, 80 °C) starts at ≈ 0.28 V (`read from figure`, ±0.01). The printed v₀ at 80 °C evaluates to 0.20–0.24 V.
Its saturated values (≈ 0.55 V at 1 bar to ≈ 0.40 V at 4 bar) fit 0.279 + v_a better. The cell-voltage curves (Fig. 3.7) are matched, so this affects only how v_act is split from E, not V_cell.
Do not plot v_act alone from the printed v₀ without noting this.

**Validity.** JDSMC p. 17, `verified`: "Note also that the coefficients in Equation (8) are derived from experimental data for a specific stack.
To model a different stack, the same basis functions in Equations (2)–(7) may be used but the coefficients need to be determined using data from the new stack."
JDSMC also notes that flooding "is currently not captured in our model".

---

## 3. Larminie & Dicks textbook form: not verified

**[LARMINIE-DICKS-2003]** J. Larminie, A. Dicks, *Fuel Cell Systems Explained*, 2nd ed., Wiley, 2003, ISBN 0-470-84857-X. Ch. 3 ("Operational fuel cell voltages").
3rd ed.: A. L. Dicks, D. A. J. Rand, Wiley, 2018, ISBN 978-1-118-61352-8.

- **Form** (`secondary`; quoted by many papers, e.g. OPEM docs, https://pypi.org/project/opem/):
  V = E − (i + i_n)·r − A·ln((i + i_n)/i₀) + B·ln(1 − (i + i_n)/i_L), or with the empirical mass-transport term −m·exp(n·i). i_n is the internal (crossover) current.
- **Ballard Mark V at 70 °C** (the book's Table 3.3, per search): r = 2.45×10⁻⁴ kΩ·cm², m = 2.11×10⁻⁵ V, n = 8×10⁻³ cm²/mA. Label: `search summary` only.
  The snippet credits Larminie & Dicks via B. Gou, W. K. Na, B. Diong, *Fuel Cells: Modeling, Control, and Applications*, CRC Press, 2010, Table 3.3. I could not open either book.
  E (≈ 1.031 V) and A (≈ 0.03 V) for this set did not appear in any snippet.
- **"Typical low-temperature PEMFC" constants** (E ≈ 1.2 V, A ≈ 0.06 V, i₀, i_n, r, m, n) were **not found** in any openable source.
  Values I recall, to **check against the book before use** (not verified, not used in this note): E = 1.2 V, i_n = 2 mA/cm², r = 3.0×10⁻⁵ kΩ·cm², i₀ = 0.067 mA/cm², A = 0.06 V, m = 3×10⁻⁵ V, n = 8×10⁻³ cm²/mA.
- **OPEM** code example (already in `hydrogen.md` §6, `verified` as code): 23-cell stack, E0 = 1.178 V, A = 0.06 V, RM = 0.0018 Ω, i₀ = 0.00654 A, i_L = 100 A, i_n = 0.23 A, T = 328.15 K.
  These constants are per stack, in A, so they cannot be compared per cm².

Access notes. The Internet Archive copy (1st ed. 2000) is lending-restricted, and fetching its text was refused. MDPI (Computers 7(4):60, which may quote the table) returned 403.
Unofficial PDF copies of the book turned up in search; I did not use them.

---

## 4. Measured automotive data: Toyota Mirai

### 4.1 Mirai gen 1 (2017), Argonne chassis-dynamometer test

**[ANL-MIRAI-2018]** H. Lohse-Busch, M. Duoba, K. Stutenberg, S. Iliev, M. Kern, *Technology Assessment of a Fuel Cell Vehicle: 2017 Toyota Mirai*,
Report ANL/ESD-18/12, Argonne National Laboratory, June 2018. https://publications.anl.gov/anlpubs/2018/06/144774.pdf (opened 2026-11-12).
Label: `verified` for text, `read from figure` for points.

Slide 37, "FUEL CELL POLARIZATION CURVE", `verified` text:
> "Stack and cell assumptions: • 237 cm2 active area (1) • 370 cells in stack"
> "(1) B. James, NREL, "Fuel Cell Systems Analysis", 2017 DOE FCTO AMR, Project ID# FC163"

The 237 cm² is ANL's assumption, taken from a DOE cost-analysis study, not a Toyota figure. The density axis on the plot is stack current / 237.
Slide 15 (`verified`): "370 cells in stack", "114kW*, 3.1 kW/L, 2.0 kW/kg". Slide 16: "Open Circuit Voltage is around 315V."

Steady-state "stack mapping data" (red circles), `read from figure`: ±5 A, ±5 V stack (±0.014 V/cell). Cell voltage = stack V / 370.

| Stack current (A) | i (A/cm², /237) | Stack V | V_cell |
|---|---|---|---|
| 12 | 0.05 | 315 | 0.85 |
| 76 | 0.32 | 289 | 0.78 |
| 150 | 0.63 | 276 | 0.75 |
| 189 | 0.80 | 276 | 0.75 |
| 225 | 0.95 | 273 | 0.74 |
| 267 | 1.13 | 267 | 0.72 |
| 300 | 1.27 | 261 | 0.71 |
| 331 | 1.40 | 246 | 0.66 |
| 373 | 1.57 | 244 | 0.66 |
| 389 | 1.64 | 240 | 0.65 |
| 421–438 | 1.78–1.85 | 252 | 0.68 |

- The points are not one isotherm or isobar: the car's controller changes pressure and flow with load. So the top-end points sit above the trend.
- The 10 Hz drive-cycle cloud follows the same band up to ≈ 450 A.
- At ≈ 440 A × 252 V ≈ 110 kW, consistent with the stack maximum the companion paper reports (below).
- Slide-ready comparison at ≈ 1 A/cm²: **Mirai gen 1 ≈ 0.74 V vs P2000 model 0.58 V**.

**[LOHSE-BUSCH-IJHE-2020]** H. Lohse-Busch et al., "Automotive fuel cell stack and system efficiency and fuel consumption based on vehicle testing on a chassis dynamometer
at minus 18 °C to positive 35 °C temperatures", *Int. J. Hydrogen Energy* (2020). Accepted manuscript: https://www.osti.gov/servlets/purl/1606353. Label: `verified`.
> "The 114.6 kW FC stack …" "The measured FC stack peak efficiency is 66.0%. The measured FC system peak efficiency is 63.7%."
> "The maximum power output of the FC stack was measured at around 110 to 114 kW, depending on the thermal conditions."
> "The energy content of hydrogen is based on the Lower Heating Value (LHV) of 119.96 MJ/kg"

Stack efficiency is defined there as ∫V·I dt / ∫ṁ_H2·LHV dt (Eq. 1), so it includes purge and crossover losses, i.e. μ_f < 1.

### 4.2 Mirai gen 1 stack design (Toyota)

**[YOSHIDA-KOJIMA-2015]** T. Yoshida, K. Kojima, "Toyota MIRAI Fuel Cell Vehicle and Progress Toward a Future Hydrogen Society", *Electrochem. Soc. Interface* 24(2) (Summer 2015) 45–49.
https://www.electrochem.org/dl/interface/sum/sum15/sum15_p45_49.pdf. Label: `verified`.
> "The 3-D fine mesh flow-field, new PtCo catalyst, and a reduction in membrane thickness lowered gas transport, activation, and electronic resistances, respectively, resulting in dramatic improvements in performance. The current density of the MIRAI fuel cell is 2.4 times larger compared to the 2008 model"

Its comparison table lists "400 cells, dual line stack" (2008) vs "370 cells, single line stack" (Mirai). No active area or polarization numbers are given.

### 4.3 Mirai gen 2 (2020)

**[TOYOTA-JSPMI-2021]** Toyota Motor Corp. (T. Takahashi et al.), 「第2世代燃料電池システムの開発」 ("Development of the second-generation fuel cell system"),
56th Machine Promotion Award summary, JSPMI. https://www.jspmi.or.jp/system/file/3/1381/N56-07.pdf. Label: `verified` (Japanese; translation mine).
> 「FC スタックは 330 枚のセルからなり」 (the FC stack consists of 330 cells)
> 「最大出力を第 1 世代の 114kW から 128kW に向上（セル当たりの出力 26%向上）」 (max output raised from 114 kW to 128 kW; output per cell +26 %)
> 「電極面積当たりの出力を 15%向上」「さらに最大電流を 20%向上させることで積層セル数を第 1 世代の 370 セルから 330 セルへ」
> (output per electrode area +15 %; with max current +20 %, the cell count went from 370 to 330)

- `derived`: per-cell area ratio gen 2 / gen 1 ≈ 1.26/1.15 ≈ 1.10.
- With ANL's 237 cm² assumption for gen 1, that suggests ≈ 260 cm² for gen 2. This rests on an assumed gen-1 area; **do not put it on a slide as a Toyota number**.
- No open-access gen-2 polarization data was found. SwRI's gen-2 polarization curve exists only as a figure on a summary page (see `hydrogen.md` §6, `search summary`).
  The Toyota J. Electrochem. Soc. paper (doi:10.1149/1945-7111/ac662d) is paywalled.

---

## 5. Hydrogen consumption (Faraday) and voltage efficiency

**Faraday's law** (`derived` from constants; F = 96485.33 C/mol, M_H2 = 2.01588 g/mol):
ṁ_H2 = N · I · M_H2 / (2F), since each H₂ gives 2 electrons and every cell in series passes the same current I.

| Stack | N | g/h per A of stack current |
|---|---|---|
| Mirai gen 2 | 330 | **12.41** (confirms `hydrogen.md` §6) |
| Mirai gen 1 | 370 | 13.92 |
| Ford P2000 (Pukrushpan model) | 381 | 14.33 |

Formula: N × 3600 s/h × 2.01588 / (2 × 96485.33).

**Per unit electric energy** (`derived`): ṁ/P = M_H2 / (2F · V_cell), independent of N.

| V_cell | g H₂ per kWh_el |
|---|---|
| 0.6 V | 62.7 |
| 0.7 V | 53.7 |
| 0.8 V | 47.0 |

**Voltage → efficiency.**

**[NETL-FCH7-2004]** EG&G Technical Services, *Fuel Cell Handbook*, 7th ed., U.S. DOE / NETL, November 2004, §2.1, pp. 2-8 to 2-9.
https://www.netl.doe.gov/File%20Library/research/coal/energy%20systems/fuel%20cells/FCHandbook7.pdf. Label: `verified`.
> "the thermal efficiency of an actual fuel cell operating at a voltage of Vcell, based on the higher heating value of hydrogen, is given by
> η = 0.83 x Vcell / Eideal = 0.83 x Vcell /1.229 = 0.675 x Vcell (2-19)"
> "This efficiency is also referred to as the voltage efficiency. However, in fuel cells, the fuel is typically not completely converted. To arrive at the net cell efficiency, the voltage efficiency must be multiplied by the fuel utilization."

- HHV form (`derived`): 0.675 × V = V / 1.481. Equivalently E_HHV = ΔH/(2F) = 285.8 kJ/mol / (2F) = **1.481 V**, using the handbook's "285.8 kJ/mole".
- LHV form (`derived`): E_LHV = 241.8 kJ/mol / (2F) = **1.253 V**.
  The same result follows from ANL's LHV 119.96 MJ/kg × 2.01588 g/mol = 241.8 kJ/mol. So η_LHV = μ_f · V_cell / 1.253.
- The deck's 33.3 kWh/kg gives 1.252 V. `hydrogen.md` rounds to 1.253; the difference is immaterial.
- Larminie & Dicks write the same relation as "μ_f · V_c / 1.25" (LHV) and "/1.48" (HHV). That is the textbook form usually quoted, but I did not verify it in the book (§3).

**Cross-check with the Mirai** (`derived`): ANL's 66.0 % peak stack efficiency (LHV) corresponds to μ_f·V_cell ≈ 0.660 × 1.253 = 0.83 V.
That fits the ≈ 0.78–0.85 V cells measured at low load (§4.1) with μ_f close to 1.

---

## Gaps

1. **Larminie & Dicks constants not verified.** No openable source gave the book's typical-PEM set (E, A, i₀, i_n, r, m, n). The Ballard Mark V r, m, n are `search summary` only.
   Check Table 3.3 (2nd ed., Ch. 3) in the department's copy before quoting any of them. The recommended slide curve does not depend on them.
2. **Springer et al. (1991) not opened.** b₁₁ = 0.005139 and b₁₂ = 0.00326 are verified through the thesis's quote of it. Springer's own b₂ was not checked.
3. **Springer book (2004) not opened.** The verdict rests on the thesis, the JDSMC paper's own figures and arithmetic. It is not known whether the book repeats the JDSMC misprint.
4. **Thesis Fig. 3.8 vs printed v₀** differs by ≈ 0.05 V in absolute activation loss (§2.3). Cell voltage is unaffected.
5. **Mirai active area is an assumption**: 237 cm² is ANL's value, citing the DOE/NREL cost study, not Toyota. The gen-2 area (~260 cm²) is only `derived` from it.
6. **No open gen-2 polarization data.** SwRI's figure and Toyota's JES paper (doi:10.1149/1945-7111/ac662d) were not accessible.
7. **Mirai points read from a figure**, ±0.014 V/cell. ANL's underlying 10 Hz data are not public in the report.
8. **Membrane label.** The thesis calls t_m = 0.01275 cm "Nafion 117". Nafion 117's nominal dry thickness is usually given as ≈ 0.018 cm (≈ 7 mil), so 0.0127 cm looks more like Nafion 115.
   I did not verify this; it does not change the model, which is a fit.
