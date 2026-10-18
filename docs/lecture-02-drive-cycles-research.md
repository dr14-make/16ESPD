# Lecture 2, section 09 (drive cycles): sources for every number

Backs `slides/decks/lecture-02/sections/09-drive-cycles.md`. The WLTC facts follow the hands-on
step 07 plan (`lecture-02-handson-step07-wltc-plan.md`, PR #77) and keep its numbers. Tags as in
the sensors research note: **(verified)** read in the primary document, **(search summary)** seen
only in a secondary page or search result, **(computed)** produced by the `illustrations` notebook
from committed data and pinned there by an assertion, **(derived)** arithmetic on verified numbers.

## Data

- **WLTC class 3b**: `assets/data/drive_cycles/wltc_class3b.csv`, transcribed from Regulation
  (EU) 2017/1151, Annex XXI, Sub-Annex 1, Tables A1/7, A1/9, A1/11, A1/12; per-phase and total
  checksums equal Table A1/13 (verified); value for value equal to JRC's `V_class3b.txt` (verified,
  EUPL, not copied). Provenance and attribution in the folder's README.
- **NEDC**: generated from UNECE Regulation No 83, Annex 4a, Table 1 (ECE-15, 25 operations) and
  Table 2 (EUDC, 21 operations), OJ L 42, 15.2.2012, CELEX 42012X0215(01) (verified). The EPA's
  own `ececol.txt` differs from Table 1 (it ignores the gear-change holds), so it is not used.
- **FTP-75, HWFET, US06**: the US EPA's dynamometer drive schedules, public domain (verified).

## Numbers on the slides

| Claim | Value | Source |
|---|---|---|
| WLTC 3b duration, distance, average, max | 1800 s, 23.27 km, 46.5 km/h, 131.3 km/h | computed; DieselNet's table agrees |
| WLTC 3b phases (s, km, average km/h) | 589/3.095/18.9, 433/4.756/39.5, 455/7.162/56.7, 323/8.254/92.0 | computed; DieselNet (search summary) agrees |
| WLTC hardest 1 s acceleration | 1.67 m/s² at 1029 s | computed; plan PR #77 |
| WLTC standstill | 13 % (226 s between zero samples; DieselNet's 242 s is also 13 %) | computed |
| NEDC | 1180 s, 11.03 km, 33.6 km/h, 120 km/h, 24 % standstill | computed from R83's tables |
| NEDC hardest acceleration | 1.04 m/s² | R83 Table 1, operation 2 (verified) |
| R83's stated distances | ECE-15 1.013 km (the operations give 1.018), EUDC 6.955 km | R83 §6.1.1–6.1.2 (verified) |
| FTP-75 | 1874 s, 17.77 km, 34.1 km/h, 91.2 km/h, 18 % | computed from EPA's `ftpcol.txt` |
| HWFET | 765 s, 16.51 km, 77.7 km/h, 96.4 km/h, 1 % | computed from `hwycol.txt` |
| US06 | 600 s, 12.89 km, 77.3 km/h, 129.2 km/h, 7 % | computed from `us06col.txt` (DieselNet lists 596 s) |
| JC08 | 1204 s, 8.171 km, 24.4 km/h (34.8 without idle), 81.6 km/h | DieselNet JC08 page (search summary) |
| JC08 standstill ≈ 30 % | 1 − 24.4/34.8 | derived |
| CADC urban, rural, motorway 130 | 993/1082/1068 s; 4.874/17.275/28.737 km; 17.7/57.5/96.9 km/h; 57.3/111.1/131.4 km/h | DieselNet Artemis page (search summary) |
| WLTC classes | class 1 PMR ≤ 22, class 2 ≤ 34, class 3 > 34 W/kg; 3a/3b at 120 km/h; PMR on mass in running order − 75 kg | DieselNet; 2017/1151 Sub-Annex 1 via PR #77 |
| Hands-on car class | 86.8 kW / 1400 kg = 62 W/kg, v_max ≈ 190 km/h → 3b | PR #77 plan |
| WLTC built from driving data | ≈ 765 000 km from EU+CH, US, India, Korea, Japan | JRC97024 (search summary) |
| Road load F = f0 + f1 v + f2 v², units N, N/(km/h), N/(km/h)² | | 2017/1151 Sub-Annex 4 §2.4 (verified) |
| Lecture 1 car's road load | f0 = 164.8 N, f1 = 0, f2 = 0.0292 N/(km/h)² | derived from `dyad/HandsOn/Body.dyad`; pinned |
| Fuel computed from exhaust carbon | | 2017/1151 Sub-Annex 7 §6 (verified) |
| Trace tolerance ±2 km/h, ±1 s | | MathWorks, citing 2017/1151 Sub-Annex 6 §1.2.6.6 (search summary; not read in the regulation) |
| WLTP: new models Sept 2017, all new cars Sept 2018 | | European Commission MEMO/17/2821 (verified) |
| RDE with PEMS; NOx CF 2.1 (168 vs 80 mg/km), new models Sept 2017, all new cars Sept 2019 | | MEMO/17/2821 (verified) |
| Gap 39 % in 2017, more than four times 2001 | | ICCT "From laboratory to road", 2018 update (Jan 2019), via Zemo Partnership (search summary) |
| Dieselgate: NOV 18 Sept 2015, test detection, NOx up to 40× | | US EPA, "Learn about Volkswagen violations" (search summary) |
| Japan: WLTC labels for new models from Oct 2018, JC08 phased in by Oct 2011 | | JAMA, Motor Industry of Japan 2019; DieselNet JC08 (search summary) |
| US 5-cycle since 2008: FTP, HWFET, US06, SC03, cold FTP | | 40 CFR 600; ACEEE fact sheet (search summary) |
| Backward vs forward models | | Wipke, Cuddy, Burch, IEEE Trans. Veh. Technol. 48 (1999) 1751–1761 (abstract) |
| Driveline comparison 5.63/5.26/4.93 L/100 km, 130/121/113 g/km; 116 s out of torque; Mazda2 label 5.3 L/100 km, 120 g/km | | PR #77 plan, section 4 |

## Not sourced

- That Japan's WLTC label leaves out the Extra High phase: only a Japanese magazine says so, so the
  slide says only that Japan replaced JC08 by the WLTC.

## Links

- Regulation (EU) 2017/1151, consolidated text: <https://gesetze.legal/eu/vo_eu_2017_1151/unteranhang_1>
  (Sub-Annexes 1, 4, 6, 7)
- UNECE Regulation No 83: <https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:42012X0215(01)>
- EPA drive schedules: <https://www.epa.gov/vehicle-and-fuel-emissions-testing/dynamometer-drive-schedules>
- DieselNet: <https://dieselnet.com/standards/cycles/wltp.php>, `jp_jc08.php`, `artemis.php`,
  `ece_eudc.php` (cite only, © ECOpoint)
- European Commission, MEMO/17/2821: <https://ec.europa.eu/commission/presscorner/detail/en/MEMO_17_2821>
- ICCT 2018 update, reported by Zemo Partnership:
  <https://www.zemo.org.uk/news-events/news,icct-report-finds-narrowing-of-gap-between-stated-and-real-world-fuel-econo_3906.htm>
- US EPA on Volkswagen: <https://www.epa.gov/vw/learn-about-volkswagen-violations>
- JRC on WLTP development: <https://publications.jrc.ec.europa.eu/repository/handle/JRC97024>
- JAMA: <https://www.jama.or.jp/library/publish/mioj/ebook/bookdata_e/pageindices/index39.html>
- ADVISOR: <https://research-hub.nrel.gov/en/publications/advisor-21-a-user-friendly-advanced-powertrain-simulation-using-a-2/>
