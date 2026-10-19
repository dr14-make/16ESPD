# Drive cycles

Speed traces at 1 Hz, one row per second from t = 0. Each file has a single header row and no
comment lines, because `DyadData` reads CSVs with `header = 1`: a comment line would become the
header. A Dyad model reaches a file here as `dyad://VehicleSystemsComponents/data/drive_cycles/<file>`.

| File | Cycle | Columns | Rows | Source | License |
|---|---|---|---|---|---|
| `wltc_class3b.csv` | WLTC class 3b (Low 3, Medium 3b, High 3b, Extra-high 3) | `t_s,v_kmh` | 1801 (0…1800 s) | Regulation (EU) 2017/1151, Annex XXI, Sub-Annex 1 | EU legislation, reuse with attribution |
| `ftp75.csv` | US EPA FTP-75 (UDDS plus the 505 s hot-start repeat, soak removed) | `t_s,v_mph` | 1875 (0…1874 s) | US EPA, `ftpcol.txt` | US government work, public domain |
| `hwfet.csv` | US EPA Highway Fuel Economy Test | `t_s,v_mph` | 766 (0…765 s) | US EPA, `hwycol.txt` | public domain |
| `us06.csv` | US EPA US06 supplemental FTP | `t_s,v_mph` | 601 (0…600 s) | US EPA, `us06col.txt` | public domain |

The EPA files keep EPA's own unit, mph, so each value is the published one unchanged. The NEDC
has no file: it is a short piecewise-linear definition, generated in
`notebooks/lecture02/illustrations.pluto.jl` from UNECE Regulation No 83, Annex 4a, Tables 1 and 2.

## WLTC class 3b

Transcribed from the consolidated text of Regulation (EU) 2017/1151, Annex XXI, Sub-Annex 1, read
at <https://gesetze.legal/eu/vo_eu_2017_1151/unteranhang_1> (October 2026): Table A1/7 (Low 3,
0–589 s), A1/9 (Medium 3b, 590–1022 s), A1/11 (High 3b, 1023–1477 s) and A1/12 (Extra-high 3,
1478–1800 s). The tables were reformatted to CSV and the decimal comma changed to a point; no
value was changed. The same tables are Annex 1 of UN GTR No. 15.

Checked against the regulation's own checksums (Table A1/13, the sum of the 1 Hz speeds):

| Phase | Checksum, Table A1/13 | This file |
|---|---|---|
| Low | 11140.3 | 11140.3 |
| Medium | 17121.2 | 17121.2 |
| High | 25782.2 | 25782.2 |
| Extra High | 29714.9 | 29714.9 |
| Total | 83758.6 | 83758.6 |

Also checked: maximum 131.3 km/h; distance 23 266 m, by phase 3095 / 4756 / 7162 / 8254 m
(DieselNet's WLTC table); and value for value equal to the JRC `wltp` project's
`wltp/cycles/V_class3b.txt`, which is EUPL-licensed and so was used only for the comparison, not
copied.

Attribution: © European Union, <https://eur-lex.europa.eu>. EU legal texts on EUR-Lex may be
reused for any purpose unless stated otherwise (EUR-Lex legal notice; Commission Decision
2011/833/EU); the tables were reformatted to CSV.

## EPA cycles

Downloaded from <https://www.epa.gov/vehicle-and-fuel-emissions-testing/dynamometer-drive-schedules>
in October 2026. The two header lines of each text file were replaced by one CSV header; the
numbers are unchanged. SHA-256 of the downloads:

| File | SHA-256 |
|---|---|
| `ftpcol.txt` | 9791a45a7fb2415de0bf01948b96e8aeff499bfd63744a8c6ca781ae88826f8a |
| `hwycol.txt` | e48e278a40312dfe84d31b5f448b601e7046c72487a6a20d3db1d4f85fb3e10a |
| `us06col.txt` | 84e9d8cc16fcd4ee3c30c3880f333eb25b61352e56f24e453411a7245c725ad2 |
