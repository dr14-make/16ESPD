# Published data for the extra session deck, *Energy on Board*

Data behind the extra session's figures. None of it comes from a course model. The figures are
drawn by

    julia +dyad-3.5.0 --startup-file=no scripts/export_extra_session_figures.jl [figure ...]

into `slides/decks/extra-session/public/figures/`. Each value is copied from a research note in
`docs/research_notes/Electric and hybrid vehicles/`, which names the source, the page or table
read and its verification label; change a value only together with that note.

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

The formula plots take their parameters from the notes directly, as constants in the script:
the Leaf cell's 1-RC fit (R₀ 1.60 mΩ, R₁ 1.34 mΩ, τ₁ 25.7 s, OCV 3.949 V at pulse 5, 33.1 A·h;
`bms.md` §1, [ORNL-LEAF-ECM], derived) for `02-pulse-response.svg` and `04-cc-cv.svg`; the
drift numbers of `bms.md` §2 (50 mA offset, 10 mA noise [MOVASSAGH-2021], 5 % [GBT-38661-2020])
for `03-soc-drift.svg`; and the recommended slide curve of `pem-polarization.md` §1
([PUKRUSHPAN-2003], b₁₁ = 0.005139) for `05-polarization.svg`.

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
