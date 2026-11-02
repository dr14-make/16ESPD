# Real-world context for Lecture 4: EV market, battery prices, EU car CO₂

Published data behind three figures of the Lecture 4 deck. None of it comes from a course model.
The figures are drawn by

    julia +dyad-3.5.0 --startup-file=no scripts/export_lecture04_context_figures.jl

which `scripts/export_lecture04_figures.jl` also runs last. Each source is described, with the
page or table read and its verification label, in
`docs/research_notes/Electric and hybrid vehicles/teaching_materials.md` §6, under the key given
here. Values were read in October–November 2026; change a value only together with that note.

## Files

| File | Content | Figure | Source |
|---|---|---|---|
| `ev_sales_share.csv` | electric share of new-car sales, %, BEV + PHEV, 2015–2025, for China, Europe (the IEA's region), the United States and the world | `01-ev-share.svg` | [OWID-IEA-EVSHARE] |
| `eu_new_car_co2.csv` | average CO₂ of new cars registered in the EU (with Iceland from 2018, Norway from 2019), g/km, by test cycle; 2025 provisional | `01-eu-co2.svg` | [EEA-CARS-IND], [EEA-CARS-2025-PROV] |
| `eu_co2_targets.csv` | the EU fleet-wide targets for new cars, g/km, with their test cycle | `01-eu-co2.svg` | [EU-443], [EU-2019/631], [EU-2023/851], [EU-ID-2023/1623], [EEA-CARS-IND], [EU-COM-2025-995] |
| `battery_pack_price.csv` | volume-weighted average Li-ion pack price, all segments, $/kWh in real 2025 dollars, 2013–2025 | `06-battery-price.svg` | [BNEF-2025] |

## Notes on reading them

- **EV share.** Our World in Data's copy of the IEA Global EV Data Explorer (data updated 15 Jun
  2026, cited as the IEA's *Global EV Outlook 2026*), a secondary source: the explorer itself could
  not be downloaded from a script. It agrees with the Outlook's text for 2023–2025 except China
  2025, where the data say 53 % and the report "almost 55%".
- **CO₂ test cycles.** Until 2020 the EEA reports the fleet on NEDC; from 2021 on WLTP; 2019 and
  2020 on both. The step from 122.3 (NEDC) to 148.2 g/km (WLTP) in 2019 is the change of test
  cycle, not of the fleet.
- **CO₂ targets.** 130 g/km NEDC for 2015–2019 (Regulation (EC) 443/2009, phased in from 2012);
  95 g/km NEDC from 2020 (Regulation (EU) 2019/631); for 2021–2024 the EEA's WLTP equivalent of
  95 NEDC, about 115.1 g/km, so that the WLTP fleet line has a target on its own cycle; 93.6 g/km
  for 2025–2029 and 49.5 g/km for 2030–2034 (Implementing Decision (EU) 2023/1623, as the 15 %
  and 55 % cuts of 2019/631 as amended by 2023/851); 0 g/km from 2035 (2023/851). The 11 g/km row
  is the Commission's proposal COM(2025) 995, a 90 % cut of the 2021 reference of about 110 g/km
  (derived: 93.6 / 0.85), not adopted on 1 Nov 2026.
- **Battery prices.** One survey, one dollar basis: BNEF's December 2025 release restates the whole
  series in real 2025 dollars, so its 2024 value (118) is not the $115 announced in December 2024
  in 2024 dollars. Values are the printed bar labels of the release's chart. The average covers
  every segment (cars, buses, two-wheelers, stationary storage), not cars alone; BEV packs alone
  averaged $99/kWh in 2025.
