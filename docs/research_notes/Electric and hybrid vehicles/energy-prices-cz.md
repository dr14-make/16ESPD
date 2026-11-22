# Energy cost per 100 km in Czechia: Leaf, Mirai, petrol car

Scope: Czech energy prices as of 12 November 2026, for the 16ESPD slide that compares the energy
cost per 100 km of a battery-electric Nissan Leaf 40 kWh, a hydrogen Toyota Mirai (2nd
generation) and a petrol car. Energy cost only. Fixed monthly charges, the charger hardware,
parking fees, purchase price and maintenance are excluded.

Labels: **verified** (I opened the primary page, file or dataset and read the number),
**secondary** (a news site, magazine or aggregator), **search summary** (only from a search-engine
summary), **derived** (computed from labeled inputs; the formula is given). All sources were
read on 12 November 2026.

Consumption inputs, given by the course and not re-sourced here:

- Leaf 40 kWh: WLTP 17.1 kWh/100 km at the grid, charging losses included.
- Mirai gen 2: 0.79 kg H₂/100 km (Toyota spec sheet; [TOYOTA-UK-MIRAI-SPECS-2024] in `hydrogen.md`).
- Petrol car: 5.22 L/100 km, the Lecture 2 engine on WLTC.

---

## Results

Exchange rate: **24.380 CZK/EUR**, the ČNB fixing of 11 November 2026 **[CNB-FX-2026-11-11]**.
The fixing for 12 November was not yet published when I queried it.

| Car and energy | Price used | Formula | CZK / 100 km | EUR / 100 km | Label |
|---|---|---|---|---|---|
| Leaf, at home, average household price | 7.0108 CZK/kWh **[EUROSTAT-NRG-PC-204-2026S1]** | 17.1 × 7.0108 | **119.9** | **4.92** | derived |
| Leaf, at home, D27d EV tariff, low-tariff hours | 3.514 CZK/kWh **[CEZ-D27D-2026]** | 17.1 × 3.514 | **60.1** | **2.46** | derived |
| Leaf, public DC, ČEZ ad hoc (≤ 149 kW) | 16.90 CZK/kWh **[CEZ-FUTUREGO-2026-11]** | 17.1 × 16.90 | **289.0** | **11.85** | derived |
| Leaf, public DC, PRE ad hoc (≤ 149 kW) | 13.00 CZK/kWh **[PRE-JEDNORAZOVE]** | 17.1 × 13.00 | **222.3** | **9.12** | derived |
| Mirai, ORLEN, latest reported price | 499 CZK/kg **[AKTUALNE-H2-2024]** | 0.79 × 499 | **394.2** | **16.17** | derived (price is secondary and dated January 2024) |
| Petrol, Lecture 2 engine, WLTC | 42.98 CZK/L **[CSU-CENPHMT-2026-W45]** | 5.22 × 42.98 | **224.4** | **9.20** | derived |
| Petrol, Škoda Octavia 1.5 TSI 85 kW, WLTP (C segment) | 42.98 CZK/L, 5.2–5.7 L/100 km **[SKODA-OCTAVIA-TD-2025]** | (5.2…5.7) × 42.98 | **223.5–245.0** | **9.17–10.05** | derived |

EUR column: CZK / 24.380. Eurostat also publishes the household price in euro
(0.2884 EUR/kWh, giving 17.1 × 0.2884 = 4.93 EUR/100 km); it converts at the semester's
average rate, so it differs from the 4.92 above in the last digit.

**Slide summary (rounded):** Leaf at home ≈ **120 CZK (4.9 €)**, or ≈ 60 CZK (2.5 €) on a
low-tariff EV rate; Leaf on public DC ≈ **220–290 CZK (9.1–11.9 €)**; Mirai ≈ **394 CZK (16.2 €)**;
petrol at 5.22 L/100 km ≈ **224 CZK (9.2 €)**.

Assumptions:

- **Leaf on public DC.** The 17.1 kWh/100 km WLTP figure is measured at the wall socket on AC,
  so it includes AC charging losses. DC charging losses differ (`charging.md` cites 5–15 % total
  for DC, [ADAC-LADEVERLUST-2026]); the same 17.1 kWh/100 km is applied to the DC price without
  correction. The ≤ 149 kW price band is used because the 40 kWh Leaf peaks around 46 kW on DC
  ([EVDB-LEAF40] in `charging.md`).
- **Leaf DC connector.** The 40 kWh Leaf charges on CHAdeMO. Ionity and Tesla Superchargers offer
  CCS only, so those two networks are listed below for context but not used for the Leaf. This is
  general knowledge and was **not verified** from an operator page in this note.
- **Home, D27d low tariff.** Only the per-kWh components are counted (energy, distribution, tax,
  system services); the monthly standing charge and breaker charge are excluded. It assumes all
  charging falls in low-tariff hours. The POZE renewables levy is zero on this price list, because
  the price list charges the lower of two POZE options and the per-breaker option is 0.00 in 2026.
  Distribution prices are those of the ČEZ Distribuce area; PRE and EG.D areas differ.
- **Mirai.** 499 CZK/kg is the newest ORLEN price I could find, reported in January 2024. Whether
  it still holds in November 2026 is unknown; see the gaps.

---

## Public DC prices, ad hoc (no registration or subscription), for context

| Network | Ad hoc DC price | Source | Label |
|---|---|---|---|
| ČEZ (Futurego), own and partner stations | 16.90 CZK/kWh ≤ 149 kW; 22.90 CZK/kWh ≥ 150 kW; incl. VAT; valid from 3 Nov 2026 | [CEZ-FUTUREGO-2026-11] | verified |
| PRE (PRE POINT), one-off charging | 13 CZK/kWh DC ≤ 149 kW (10.74 excl. VAT); 15 CZK/kWh UFC > 149 kW | [PRE-JEDNORAZOVE] | verified (page undated) |
| E.ON Drive | 10.50 CZK/kWh day, 8.50 CZK/kWh night, group 1 (≤ 100 kW), unregistered | [AUTOHLED-NABIJENI-2026] | secondary |
| Tesla Supercharger, non-Tesla cars | ~13.20 CZK/kWh peak (09–22), ~8.45 CZK/kWh off-peak (22–09) | [AUTOHLED-NABIJENI-2026] | secondary (the article says it could not check these against Tesla's site) |
| Ionity, direct/ad hoc | "up to CZK 22.68 /kWh", from 1 July 2026 | [IONITY-PRICES-2026] | verified |

E.ON's own press release of 1 April 2026 gives 9.50 / 8.00 CZK/kWh (day/night) for ≤ 100 kW and
says the tariff structure is the same for registered and unregistered customers, but it does not
say whether those figures are the unregistered price or whether they include VAT
**[EON-TZ-2026-04-01]**. Its press release does not settle which E.ON figure is ad hoc, so E.ON is
not used in the results table.

---

## Sources

- **[CNB-FX-2026-11-11]** Česká národní banka, *Kurzy devizového trhu*, daily fixing no. 217 of
  11.11.2026, https://www.cnb.cz/cs/financni-trhy/devizovy-trh/kurzy-devizoveho-trhu/kurzy-devizoveho-trhu/denni_kurz.txt?date=12.11.2026.
  **verified**. Row: "EMU|euro|1|EUR|24,380" (EMU, euro, 1 EUR = 24.380 CZK). The query for
  12.11.2026 returned the 11.11.2026 fixing, the latest published at the time.

- **[EUROSTAT-NRG-PC-204-2026S1]** Eurostat, *Electricity prices for household consumers -
  bi-annual data (from 2007 onwards)*, dataset nrg_pc_204, updated 2026-10-19,
  https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/nrg_pc_204?geo=CZ&nrg_cons=KWH2500-4999&currency=EUR&currency=NAC&tax=I_TAX&unit=KWH&lastTimePeriod=2&format=JSON.
  **verified** (read through the API). Czechia, band DC (2,500–4,999 kWh/year), all taxes and
  levies included (I_TAX):

  | Semester | CZK/kWh | EUR/kWh |
  |---|---|---|
  | 2025-S2 | 7.845 | 0.3217 |
  | 2026-S1 | **7.0108** | **0.2884** |

  The all-taxes price includes energy, network charges, taxes and levies. euenergyprices.eu
  shows the same 28.84 ct/kWh for H1 2026 (secondary).

- **[CEZ-D27D-2026]** ČEZ Prodej, *Ceník elektřiny pro domácnosti – Elektřina Online na 1 rok*,
  distribution area ČEZ Distribuce, commercial prices valid from 30. 1. 2026, distribution prices
  from 1. 1. 2026, https://www.cez.cz/webpublic/file/edee/ceniky/moo_ele_cez_online_na_1_rok_30012026_012026.pdf.
  **verified**. Column D27d, "Elektromobilita" (EV tariff):
  - Row 27, "Nízký tarif (řádky 1 + 4 + 21 + 22)" (low tariff, sum of energy, distribution,
    electricity tax and system services): **3 513,94 Kč/MWh** incl. 21 % VAT (2 904,08 excl. VAT).
  - Row 26, high tariff: 6 338,44 Kč/MWh incl. VAT.
  - "Tučně uvedené ceny jsou s 21% DPH a ceny v závorce bez DPH." (Prices in bold include 21 %
    VAT; prices in brackets exclude VAT.)

- **[CEZ-FUTUREGO-2026-11]** ČEZ, Futurego price list, https://www.futurego.cz/cenik. **verified**.
  Unregistered customers, "Vlastní a Partnerské DS" (ČEZ's own and partner stations):
  ≤ 49 kW 11,90 Kč/kWh; ≤ 149 kW **16,90 Kč/kWh**; ≥ 150 kW 22,90 Kč/kWh.
  "Ceny jsou uvedeny včetně DPH." (Prices include VAT.) "Ceník platný od 3. 11. 2026" (price
  list valid from 3 November 2026). The page labels bands by power, not AC/DC; reading the
  ≤ 149 kW band as DC is my inference. The registered "Basic" tariff (no monthly fee) is
  12,90 Kč/kWh ≤ 149 kW in ČEZ's 1.10.2026 price list PDF
  (https://www.cez.cz/webpublic/file/edee/2026/10/novy-cenik-1.10.2026.pdf, verified).

- **[PRE-JEDNORAZOVE]** Pražská energetika, *Chci dobíjet jednorázově* (I want to charge once),
  https://www.pre.cz/cs/domacnosti/emobilita/verejne-dobijeni/chci-dobijet-jednorazove/.
  **verified**, page undated. AC (do 49 kW) "10 Kč/kWh" (8,26 Kč bez DPH); DC (do 149 kW)
  **"13 Kč/kWh"** ("10,74 Kč bez DPH", 10.74 CZK excl. VAT); UFC (nad 149 kW) "15 Kč/kWh"
  (12,40 Kč bez DPH).

- **[EON-TZ-2026-04-01]** E.ON Energie, press release "Nové ceníky E.ON Drive: nabíjení na 70 %
  dobíjecích stanic bude za 9,50 Kč za kW", 1 April 2026,
  https://www.eon.cz/pro-media/pro-media-tiskove-zpravy/nove-ceniky-e-on-drive-nabijeni-na-70-dobijecich-stanic-bude-za-9,50-kc-za-kw/.
  **verified**. "za cenu 9,5 Kč za kWh ve dne a za 8 Kč v noci" (9.5 CZK/kWh by day and 8 CZK at
  night) for 0–100 kW; night is 20:00–8:00. Prices for 101–200 kW and 200+ kW are not given.

- **[AUTOHLED-NABIJENI-2026]** J. Zelinka, "Ceny nabíjení elektromobilů v Česku 2026: kompletní
  přehled všech operátorů", Autohled.cz, published 25 March 2026, "Poslední aktualizace:
  5. října 2026" (last updated 5 October 2026),
  https://www.autohled.cz/magazin/ceny-nabijeni-elektromobilu-v-cesku-2026-kompletni-prehled-vsech-operatoru/10864.
  **secondary**. E.ON Drive unregistered, group 1 (≤ 100 kW): 10,50 Kč by day, 8,50 Kč at night;
  the article notes "Web E.ON uvádí pro neregistrované ve skupině 3 přes den 20,00 Kč" (E.ON's
  website gives 20.00 CZK by day for unregistered users in group 3). Tesla, non-Tesla cars:
  ~13,20 Kč peak (09–22), ~8,45 Kč off-peak (22–09), from February 2026 data the author could not
  check against Tesla's site. It also estimates a low-tariff home price of 3,50–4,50 Kč/kWh for
  D27d in 2026, consistent with [CEZ-D27D-2026].

- **[IONITY-PRICES-2026]** IONITY, "Why are charging prices changing across Europe?",
  https://www.ionity.eu/et/lood/why-are-charging-prices-changing-across-europe. **verified**.
  Czech Republic: "Subscription prices from CZK 12.00 /kWh", "Direct/ad-hoc prices up to
  CZK 22.68 /kWh", "from 1 July 2026". The direct price is a ceiling, not a fixed rate.

- **[CSU-CENPHMT-2026-W45]** Český statistický úřad, DataStat dataset CENPHMT, *Průměrné
  spotřebitelské ceny pohonných hmot - týdenní* (average consumer fuel prices, weekly), CSV
  distribution https://data.csu.gov.cz/opendata/sady/CENPHMT/distribuce/csv (dataset page
  https://data.csu.gov.cz/datastat/info/SADA/CENPHMT), selection last changed 2026-11-10.
  **verified**. Row: "Benzin automobilový bezolovnatý Natural 95 oktanu", "45. týden 2026",
  **42.98** Kč/litr (Natural 95 unleaded petrol, week 45 of 2026, 2–8 November). Prior weeks:
  W44 43.82, W43 45.33. ČSÚ weekly prices are valid as of the Monday of the stated week.
  Cross-check: CCS reported 42,39 Kč/l on 4 November 2026 ("Litr nejprodávanějšího benzinu
  Natural 95 se tak nyní prodává v průměru za 42,39 Kč", ČTK / České noviny, 5 Nov 2026,
  https://www.ceskenoviny.cz/zpravy/benzin-v-cr-od-minuleho-tydne-zlevnil-o-korunu-cena-nafty-stagnovala/2897723,
  secondary).

- **[AKTUALNE-H2-2024]** "Kilo za pět stovek. Provoz vodíkových pump v Česku musíme dotovat,
  říká Orlen", Aktuálně.cz, 10 January 2024,
  https://zpravy.aktualne.cz/ekonomika/auto/skokove-zdrazeni-vodiku-v-cesku-provoz-plnicich-stanic-je-pr/r~ff2e8dfaaef511ee8b4e0cc47ab5f122/.
  **secondary**. ORLEN raised the hydrogen price at Praha-Barrandov and Litvínov from 278 CZK and
  "zvedla na 499 korun" (raised it to 499 CZK) per kg, citing the end of the introductory price.
- **[ORLEN-TZ-2023-06-28]** ORLEN Unipetrol press release, 28 June 2023,
  https://www.orlen.cz/pro-media/orlen-unipetrol-otevrel-dalsi-verejnou-vodikovou-stanici,-je-soucasti-cerpaci-stanice-orlen-benzina.
  **verified**. "Cena vodíku na čerpacích stanicích ORLEN Benzina byla stanovena na 278 korun za
  jeden kilogram." (The hydrogen price at ORLEN Benzina stations was set at 278 CZK per kg.)
  This is the superseded introductory price; at 278 CZK/kg the Mirai would cost
  0.79 × 278 = 219.6 CZK (9.01 €) per 100 km (derived).

- **[SKODA-OCTAVIA-TD-2025]** Škoda Auto, *Octavia – Technické údaje*, dated 23. 6. 2025,
  https://cdn.skoda-storyboard.com/2025/06/TD-Octavia-cz_f35d2142.pdf. **verified**. Octavia
  (hatchback), petrol: "Spotřeba – kombinovaná (WLTP) [l/100 km]" 1,5 TSI/85 kW **5,2–5,7**;
  1,5 TSI/85 kW mHEV (A) 4,9–5,4; 1,5 TSI/110 kW 5,3–5,8; 1,5 TSI/110 kW mHEV (A) 4,9–5,4. The
  Octavia is a C-segment car; it is used here as a typical C-segment WLTP figure, not as the
  course's engine.

---

## Gaps

1. **Hydrogen price is stale.** No ORLEN price for 2025 or 2026 was found; 499 CZK/kg dates from
   January 2024 and is secondary. ORLEN's own station page or a call to ORLEN Unipetrol would
   settle it. The Mirai figure is the least certain number on the slide.
2. **Tesla Supercharger CZ** prices are secondary only (tesla.com returned HTTP 403).
3. **E.ON Drive ad hoc price** is unresolved: the press release (9.50 / 8.00) and Autohled
   (10.50 / 8.50 unregistered) differ, and neither the release's VAT status nor its applicability
   to unregistered users is stated.
4. **PRE one-off page** carries no validity date.
5. **ERÚ** was not used: it publishes the regulated component (2,352 CZK/MWh for low voltage in
   2026, search summary), not an all-in household price. The D27d price is one supplier's offer
   in one distribution area; other suppliers and the PRE and EG.D areas differ.
6. **ČNB fixing for 12 November 2026** was not yet published; 11 November is used.
7. **CHAdeMO-only access** of the 40 kWh Leaf (excluding Ionity and Tesla) is stated from general
   knowledge, not from a cited source.
