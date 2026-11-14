# Published data for the extra session deck, *Energy on Board*

Data behind the extra session's figures. None of it comes from a course model. The figures are
drawn by

    julia +dyad-3.5.0 --project=. --startup-file=no scripts/export_extra_session_figures.jl [figure ...]

into `slides/decks/extra-session/public/figures/`. Each value is copied from a research note in
`docs/research_notes/Electric and hybrid vehicles/`, which names the source, the page or table
read and its verification label; change a value only together with that note. Two figures also
draw course benches: `04-leaf-chademo.svg` sets `CCCVLeafCharge` beside the Fastned curve, and
`03-soc-drift.svg` is `SoCDriftDays` on the 33.1 A·h cell.

## Files

| File | Content | Figure | Note, source |
|---|---|---|---|
| `pack_price_split.csv` | Li-ion pack price, all segments, real 2025 $/kWh, split into cell and rest of pack, 2013–2025 | `01-pack-price.svg` | `teaching_materials.md` §6.2, [BNEF-2025] |
| `nmc_ocv_chen2020.csv` | OCV of the LG M50 NMC 811 cell at 10 % SoC steps, derived from the PyBaMM Chen2020 set | `02-ocv-soc.svg`, `04-cc-cv.svg` | `teaching_materials.md` §3.4, [CHEN-2020] |
| `leaf_c3_discharge.csv` | 2013 Leaf pack voltage at C/3 against SoC, per series element, loaded | `02-ocv-soc.svg` | `teaching_materials.md` §3.2, [INL-5045] |
| `fastned_charge_curves.csv` | DC charging power against SoC for the Leaf 40 kWh, ID.3 Pro S, Model Y LR 2025+ and IONIQ 5 84 kWh | `04-leaf-chademo.svg`, `04-dc-curves.svg` | `charging.md` §2(d), [FASTNED-CURVES] |
| `eafo_charging_points.csv` | public charging points by AFIR power class, Czechia and EU27, 2024, 2025, Sep 2026 | `04-network.svg` | `charging.md` §8, [EAFO-CZ], [EAFO-EU27] |
| `mirai_polarization.csv` | 2017 Mirai stack mapping points, per cell | `05-polarization.svg` | `pem-polarization.md` §4.1, [ANL-MIRAI-2018] |
| `agora_efficiency_chain.csv` | step efficiencies from renewable electricity to wheel, BEV and FCEV | `07-efficiency-chain.svg` | `hydrogen.md` §5, [AGORA-SYNCOST-2018] |
| `chemistry_iea_bnef.csv` | best-in-class cell Wh/kg for NMC, LFP, sodium-ion; 2025 pack $/kWh for NMC and LFP | `01-chemistry.svg` | `teaching_materials.md` §6.2, [IEA-GEVO-2026] p. 101, [BNEF-2025] |
| `runaway_ohneseit.csv` | self-heating onset and start of thermal runaway, 21700 NMC, NCA, LFP at 100 % SoC | `03-runaway.svg` | `bms.md` §4, [OHNESEIT-2023] Table 10 |
| `ageing_nmc.csv` | NMC cycle life to 80 % by SoC window; calendar capacity loss by storage SoC and temperature | `01-ageing.svg` | `battery-terms.md`, [PREGER-2020] Fig. 2a, [KEIL-2016] Fig. 2b |
| `rate_capability_m50.csv` | simulated discharge of an LG M50-class cell at 0.2–3 C: voltage curves, charge and energy delivered | `01-rate-capability.svg` | `battery-terms.md` §7, PyBaMM DFN, [CHEN-2020] |
| `adac_charging_losses.csv` | AC losses at 2.3, 4.1 and 11 kW for five cars; in-car DC losses for four cars at 23 °C and 0 °C | `04-charging-losses.svg` | `charging.md` §4, [ADAC-LADEVERLUST-2026] |
| `degradation.csv` | capacity fade per year by charging habit; capacity lost at 50,000 mi, L2 against DC | `04-degradation.svg` | `charging.md` §7, [GEOTAB-2026], [INL-DCFC-2015] |
| `h2_stations.csv` | hydrogen stations by world region, end 2024; public car stations in Germany and Czechia | `06-station-counts.svg` | `hydrogen.md` §3, [LBST-H2STATIONS-2025], [ECOMENTO-DE-50-2026], [SYSLOG-ORLEN-2026] |
| `h2_closures_de.csv` | closures of public hydrogen stations in Germany, 2024–2025 | `06-station-counts.svg` | `hydrogen.md` §3, [H2M-CLOSURES-2025], [SOLARSERVER-DE-36-2026] |
| `fcev_sales_2025.csv` | fuel-cell vehicles sold in 2025 by market | `06-fcev-sales.svg` | `hydrogen.md` §4, [ARGUS-SNE-2026] |
| `cost_per_100km_cz.csv` | energy cost per 100 km in Czechia: Leaf at home and on DC, petrol, Mirai | `06-cost-per-100km.svg` | `energy-prices-cz.md`, results table, [ORLEN-TZ-2023-06-28], [AKTUALNE-H2-2024] |
| `h2_emissions_iea.csv` | kg CO₂-eq per kg H₂ by production route | `07-h2-emissions.svg` | `hydrogen.md` §5, [IEA-H2-DEF-2023] |
| `fcev_hybridization.csv` | fuel-cell kW, buffer-battery kWh and H₂ kg of four FCEVs | `07-fcev-hybridization.svg` | `hydrogen.md` §4, [TOYOTA-UK-MIRAI-SPECS-2024], [HYUNDAI-NEXO-2025], [HONDA-CRV-EFCEV-2024], [HYUNDAI-XCIENT-2025] |

The formula plots take their parameters from the notes directly, as constants in the script:
the Leaf cell's 1-RC fit (R₀ 1.60 mΩ, R₁ 1.34 mΩ, τ₁ 25.7 s, OCV 3.949 V at pulse 5, 33.1 A·h;
`bms.md` §1, [ORNL-LEAF-ECM], derived) for `02-pulse-response.svg` and `04-cc-cv.svg`; the
noise band of `03-soc-drift.svg` (10 mA [MOVASSAGH-2021]; `bms.md` §2); the recommended slide curve of `pem-polarization.md` §1
([PUKRUSHPAN-2003], b₁₁ = 0.005139) for `05-polarization.svg`; the course Leaf pack at the end
of CC (96 cells, 4.20 V, 143 A, R_pack ≈ 0.1 Ω, so 14 V of I·R; C/20 = 3.3 A; `charging.md` §1,
computed) for `04-cv-budget.svg`; and P = U·I at a 500 A cable, I²R ∝ I² (`charging.md` §6,
computed) for `04-voltage-class.svg`.

## Notes on reading them

- **Fastned curves.** Fastned's pages hold one value per 1 % SoC; the note copied only the 10 %
  grid, each series' first and last point and its peak, so the figures join those points with
  straight lines. The ID.3 and IONIQ 5 series start at 3 %, but their first values were not
  copied; the plotted lines start at 10 %.
- **Mirai.** The 421–438 A cluster is one row at its mid current, 1.815 A/cm². Current density
  uses ANL's assumed 237 cm² cell area, not a Toyota figure.
- **Agora.** The chain's intermediate values (95, 85.5, …) are the products of the printed step
  efficiencies (derived); the totals 69 % and 26 % are Agora's printed ones.
- **Assumptions of the formula plots.** CC-CV: 0.5C (16.55 A) from rest at 10 % SoC, CV at
  4.20 V, stop at C/50; the Leaf cell's R₀, R₁, τ₁ with the NMC 811 OCV curve (monotone cubic
  through the 10 % table). Pulse: OCV held at 3.949 V through the profile. Drift: OCV resets on
  days 2, 4 and 6, an illustrative schedule; the note gives no reset interval.
- **Stations.** LBST's world counts include depot and bus stations (its Germany 113 too), so
  they are not comparable with H2 MOBILITY's public car count; the figure keeps them in separate
  panels. "Über 80" is drawn as a bar at 80 labeled "over 80". The 3 and 6 closures of 2024 are
  search-summary figures.
- **Cost per 100 km.** The Mirai range runs from ORLEN's 278 CZK/kg (2023, verified) to 499
  CZK/kg (January 2024, secondary, the newest found); no 2025–2026 price exists in the notes.
- **FCEV sizing.** The fuel-cell figures are not on one basis: Mirai is stack maximum output,
  Nexo net system output, CR-V "estimated power output", XCIENT "fuel cell system".
