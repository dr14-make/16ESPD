# CAN bus lecture: wiring-harness figures for "a bus trades wires for time"

Every number below was read on the cited page or PDF (November 2026). Type column:
**P** = primary (OEM, supplier, standard body, peer-reviewed, handbook, SAE paper/magazine
by an industry author). **S** = secondary (press, blog, analyst). "P (via S)" = a primary
speaker quoted in press. Quotes are kept to a few words.

## 1. Harness mass

| Figure | Car class | Year | Source | Type |
|---|---|---|---|---|
| ~35 kg, wire "over two kilometers" | high-end car | 2000 | D. J. Holt, "Electronics changing the shape of the automobile", SAE Automotive Engineering, Oct 2000, https://saemobilus.sae.org/articles/electronics-changing-shape-automobile-autooct00_02 | P (SAE magazine) |
| "around 80 pounds" (~36 kg) of copper and insulation, average loom | average | 2003 | just-auto, 15 Aug 2003 (quotes Lear, Molex, Delphi but figure is unattributed), https://www.just-auto.com/?p=4444 | S |
| "up to 50 lbs" (23 kg), typical harness | typical | 2013 | WardsAuto, B. Pope, 25 Apr 2013, https://www.wardsauto.com/vehicles/te-connectivity-driving-weight-out-of-vehicle-connectors | S |
| 45 kg, average harness, "over a thousand wires", ~1 km | average/midsize | 2013 | NXP blog, M. van der Linden (PR director), 6 Dec 2013, https://www.nxp.com/company/about-nxp/smarter-world-blog/BL-SMART-COMMUNICATION-NETWORK | P-ish (supplier marketing) |
| wire ~25 kg; full wiring system 35–42 kg; up to 60 kg in latest luxury cars | average vs luxury | 2019 | CRU (C. Wang), "What lies ahead for the automotive harness industry", Wire & Cable Conf. 2019, p. 3, https://events.crugroup.com/wireandcable/Uploads/CRU%20white%20paper%20-%20What%20lies%20ahead%20for%20the%20automotive%20harness%20industry.pdf | S (metals analyst) |
| ~60 kg if all wires laid end to end | premium cars, full-size trucks | 2020 | D. Scott & U. Hoff (Siemens), "Wired for Autonomy", SAE Mobility Engineering, Jan 2020, https://saemobilus.sae.org/content/20AVEP01_05 ; same in Siemens blog 28 Jul 2020 | P (tool vendor in SAE magazine) |
| 3.5 kg for one dashboard harness (200 cables, 50 connectors) | — | current | Leoni product page, https://www.leoni.com/markets-solutions/wiring-systems/products-solutions/low-voltage-wiring-harness | P (supplier) |

Range: **~25–60 kg**; compact/average ~25–45 kg, premium ~60 kg. Disagreement is partly
definitional (bare wire vs complete harness with connectors, clips, tape; CRU: wire is
60–70 % of system mass). Not found: a sourced compact-vs-luxury pair from one source.

## 2. Length, wires, connectors

| Figure | Car class | Year | Source | Type |
|---|---|---|---|---|
| 75 m harness (mid-1950s) → >2 km (2000) | high-end | 2000 | Holt, SAE Automotive Engineering (above) | P |
| 1960 upmarket car: ~200 m wire, ~200 connectors → "more like 2.5 kilometres", >800 wires, ~1,800 connectors | upmarket | 2003 | just-auto 2003 (above), unattributed | S |
| "about 4,000 circuits" BMW flagship would need without multiplexing | luxury | 2003 | just-auto 2003 (above), unattributed | S |
| ~1 km, >1,000 wires | average | 2013 | NXP 2013 (above) | P-ish |
| ~40 harnesses, ~700 connectors, >3,000 wires, >4 km (2.5 mi), >70 specialty cables (~10 in older cars) | premium, full-size truck | 2020 | Scott & Hoff, SAE 2020 / Siemens blog 2020 (above) | P |
| Model S "about 3 kilometers" → Model 3 1.5 km (Musk) | Tesla | 2019 | Electrek, 22 Jul 2019, https://www.electrek.co/2019/07/22/tesla-revolutionary-wiring-architecture-robots-model-y/ | P (via S), CEO claim |
| Model S "just under two miles" (Musk, "as early as 2017") | Tesla | 2023 | SlashGear, https://www.slashgear.com/1502730/cybertruck-modular-wiring-system/ | P (via S) |

Range: **~1–4+ km** per car; 1,000–3,000+ wires; ~700–1,800 connectors. The just-auto
(2.5 km / 800 wires) and NXP (1 km / >1,000 wires) figures are not mutually consistent
— treat as order of magnitude. No sourced total **pin** count found.

## 3. Share of cost/mass; "3rd heaviest / most expensive"

| Claim | Source | Type |
|---|---|---|
| "third heaviest and third costliest component", behind chassis and engine | CRU white paper 2019, p. 3 (above) | S (analyst, no study cited) |
| third-heaviest (after engine, chassis) and third most expensive | Molex article (Mouser PDF) — page timed out, seen only in search snippet; **not verified** | P (supplier), unverified |
| wiring and electronics "third most expensive component", after engine and frame | Hackaday, 27 Jul 2022, https://hackaday.com/2022/07/27/the-surprisingly-manual-process-of-building-automotive-wire-harnesses | S, unsourced |
| "one of the heaviest and most expensive" parts, **after engine and transmission** | eeNews Europe, N. Flaherty, 11 Apr 2019, quoting Leoni R&D head U. Hornfeck, https://www.eenewseurope.com/en/how-electric-vehicles-impact-cable-harness-design/ | P (via S) |

Verdict: the "3rd" claim is **widely repeated industry lore with no original study found**;
sources disagree on what ranks above it (chassis vs transmission). No sourced % of vehicle
cost for the harness alone was found (Hackaday's "half of cost in the electrical system by
2030" is for all electrics and unsourced).

## 4. Multiplexing / CAN: history and before-after

| Figure | Source | Type |
|---|---|---|
| Bosch: "reduction of wiring harnesses was just a by-product, but not the driving force" of CAN; Kiencke started 1983; presented SAE Detroit Feb 1986; Mercedes uses CAN in upper-class cars "since 1991"; BMW 7 series 1995: five ECUs on CAN | CiA, "History of CAN technology", https://www.can-cia.org/can-knowledge/history-of-can-technology | P (CiA) |
| Peugeot 307 (two CAN buses) vs non-multiplexed 306: wires 635 → 370 (−40 %) | Navet, Song, Simonot-Lion, Wilwert, "Trends in automotive communication systems", Proc. IEEE 93(6), 2005, p. 1207; repeated in Navet & Simonot-Lion, ch. 4 of *Automotive Embedded Systems Handbook*, CRC 2008. Their cited origin: Y. Martin, L'argus de l'automobile no. 3969, Mar 2005 | P (peer-reviewed), original is press |
| LANs in the four doors of a BMW cut weight by 15 kg (1998 press release, quoted via Leen & Heffernan, IEEE Computer 35(1), 2002) | Navet et al. 2005, p. 1204; CRC 2008 ch. 4 | P citing press release |
| luxury cars: up to 2,500 signals exchanged by up to 70 ECUs | Navet et al. 2005, p. 1204 | P |
| Toyota Century (1982) door multiplex, 64 signals: 46 wires → 10 (incl. 2 optical fibers) | Matsuzaki & Baba (Toyota), SAE 840492, 1984, https://saemobilus.sae.org/content/840492 | P (OEM SAE paper) |
| Body-network design goals −20 % harness, −10 % cost, "fulfilled"; 4-node 40 kbit/s network in series since 1995 (car not named) | Voss & Butscher (TEMIC), SAE 960121, 1996, https://saemobilus.sae.org/content/960121/ | P (supplier SAE paper) |
| BMW 850i body multiplex | Mahalek, SAE 920225, 1992 — abstract has no numbers | P, no figure |

Not found: any quantified W140 or BMW 850 before/after figure (only "first CAN in Mercedes
production 1991"). The research note `pptx-audit.md` suggested Navet & Simonot-Lion cite
"≈50 kg / ≈5 km"; **neither the 2005 paper nor the 2008 chapter contains those numbers**.

## 5. Zonal / Tesla (mostly marketing or CEO claims)

| Figure | Source | Type |
|---|---|---|
| Model Y target "just 100 meters" (Electrek's reading of a patent, not a Musk quote) | Electrek 2019 (above) | S |
| Model Y "300-plus feet" (Musk, "allegedly", earnings call) | SlashGear (above) | S, hedged |
| Cybertruck vs Model 3: "high-powered harness mass went down by 84 percent"; 368 vs 273 end points; 155 vs 490 wires (P. Bannon, Tesla) | ASSEMBLY Magazine, 26 Apr 2024, https://www.assemblymag.com/articles/98504-teslas-new-cybertruck-features-modular-wiring | P (via S), OEM claim |
| SVA up-integration: 20 % less harness weight; harnesses ≤2.5 m | Aptiv white paper "Smart Vehicle Architecture", 2020, https://www.aptiv.com/docs/default-source/white-papers/2020_aptiv_whitepaper_sva.pdf | P, marketing |
| SUV ICE→BEV conversion adds 13 kg wiring, >300 m wire; zone control removes >9 kg; full SVA further −8 % weight, 600 cut leads, >900 m wire | Aptiv, 30 Sep 2021, https://www.aptiv.com/en/insights/article/getting-vehicle-architectures-from-ice-to-bev-and-beyond | P, marketing (one OEM study) |
| 3–5 zone control units per vehicle; savings not quantified | Leoni product page (above) | P |

## Suggested slide use

1. Lead with one primary, dated number per axis: **"premium car: ~40 harnesses, ~700
   connectors, >3,000 wires, ~4 km, ~60 kg"** (Scott & Hoff, SAE Mobility Engineering 2020),
   and add "average car ~25–45 kg" (CRU 2019 / NXP 2013) to show the range.
2. The before-after that is peer-reviewed: **Peugeot 306 → 307: 635 → 370 wires (−40 %)
   with two CAN buses** (Navet et al., Proc. IEEE 2005, after L'argus 2005). Optionally the
   1982 Toyota door: 46 → 10 wires.
3. Be honest about motivation: quote CiA that wiring savings were "a by-product" of CAN —
   Bosch wanted ECUs to share real-time data. That supports the lecture's point: the bus buys
   fewer wires *and* sharing, at the price of time on a shared medium.
4. Say "often cited as the 3rd heaviest part" only with "industry estimate", or drop it.
   Present Tesla/Aptiv figures as "manufacturer claims", not measurements.
