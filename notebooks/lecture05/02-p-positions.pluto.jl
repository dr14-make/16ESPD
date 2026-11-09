### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# ╔═╡ 3ca9a892-ae41-4a91-9e24-957c7297f301
begin
    import Pkg
    Pkg.activate(joinpath(@__DIR__, "..", ".."))
    using Plots, Printf
    plotly()
    default(fontfamily = "sans-serif", background_color = :white)
    include(joinpath(@__DIR__, "..", "..", "scripts", "p_position_table.jl"))
    using .PPositionTable: H0, LINE, read_table
end

# ╔═╡ 3ca9a892-ae41-4a91-9e24-957c7297f302
md"""
# Lecture 5 — Where the electric machine sits

A pinned WLTC comparison of **P0, P1, P2, P3 and P4**, each with a **30 kW** machine
and a **270 V** battery. This notebook reads `assets/data/lecture05/p_positions.csv`;
it does not run models. Raw fuel is the cycle's measured fuel; corrected fuel accounts
for the change in battery charge. Savings below always use **corrected** fuel, so drawing
down the battery is not counted as free fuel saving.

- **P0:** machine coupled to the engine; recuperation must also turn the engine, and there
  is no engine-off electric drive.
- **P1:** direct-crank machine, ideal coupling (ratio and efficiency 1), 540 N·m K0; no electric drive.
- **P2:** machine downstream of the engine-disconnect clutch, upstream of the transmission;
  electric drive can use the transmission ratios.
- **P3:** machine at the transmission output; engine-off drive without the transmission's
  torque multiplication.
- **P4:** separate electric axle; engine-off drive through its own reduction. This is not
  the literature's full **P4+P0** arrangement: its ideal crank starter represents only
  the engine-start function, not a second belt machine's assist or recuperation.
"""

# ╔═╡ 3ca9a892-ae41-4a91-9e24-957c7297f303
begin
    position_rows = read_table()
    @assert Set(r.position for r in position_rows) == Set(["P0", "P1", "P2", "P3", "P4"])
    @assert length(position_rows) == 5
    @assert all(r.P_rated_kW == 30 for r in position_rows)
    sort!(position_rows; by = r -> r.position)
end

# ╔═╡ 3ca9a892-ae41-4a91-9e24-957c7297f304
md"""
## 1. Three denominators, three questions

For a reference fuel consumption ``F_b``, saving is ``100(1-F_{corr}/F_b)``.

1. **H0 = 5.7175350775 L/100 km:** the engine-only car with its scheduled transmission.
2. **Line = 5.4374462426 L/100 km:** the engine-only best-BSFC-line reference. The difference
   from H0 includes the operating-point benefit; it is not all an electric-machine benefit.
3. **Line minus measured idle fuel:** subtract only the line run's measured idle fuel,
   in L/100 km, from Line (fuel at engine power ≤1 kW, including low-power creep).
   This is a **proxy**, not a simulated stop-start reference: removing
   idle fuel does not reproduce restarts, auxiliaries, clutch transients or a changed trajectory.

Both engine-only references have **no stop-start**. The measured idle share ships in
`assets/data/lecture05/baselines.csv`; no assumed idle percentage is used.
"""

# ╔═╡ 3ca9a892-ae41-4a91-9e24-957c7297f305
begin
    function measured_idle_baseline(path; line_fuel = LINE)
        row = only(filter(r -> r.baseline == "line", read_table(path)))
        isapprox(row.fuel_L100, line_fuel; atol = 1e-5, rtol = 0) || error("Line pin mismatch")
        0 <= row.idle_fuel_L100 < row.fuel_L100 || error("Invalid idle fuel")
        (; fuel_L100 = row.fuel_L100 - row.idle_fuel_L100,
            idle_fuel_L100 = row.idle_fuel_L100)
    end
    idle_baseline = measured_idle_baseline(joinpath(@__DIR__, "..", "..",
        "assets", "data", "lecture05", "baselines.csv"))
    saving(fuel, baseline) = ismissing(baseline) ? missing : 100 * (1 - fuel / baseline)
    fmt(x; digits = 2) = ismissing(x) ? "—" : @sprintf("%.*f", digits, x)
end

# ╔═╡ 3ca9a892-ae41-4a91-9e24-957c7297f306
begin
    md"""
    Measured line idle fuel: **$(fmt(idle_baseline.idle_fuel_L100; digits = 4)) L/100 km**.
    Line-minus-idle proxy: **$(fmt(idle_baseline.fuel_L100; digits = 4)) L/100 km**.
    """
end

# ╔═╡ 3ca9a892-ae41-4a91-9e24-957c7297f307
begin
    table_headers = ["Position / kW", "Raw fuel", "Corr. fuel", "vs H0 %", "vs Line %",
        "vs Line−idle %", "Stored MJ", "Req. MJ", "Electric s", "Starts"]
    table_values = [["$(r.position) / $(fmt(r.P_rated_kW; digits = 0))",
        fmt(r.fuel_raw_L100), fmt(r.fuel_corr_L100),
        fmt(saving(r.fuel_corr_L100, H0)), fmt(saving(r.fuel_corr_L100, LINE)),
        fmt(saving(r.fuel_corr_L100, idle_baseline.fuel_L100)), fmt(r.E_recovered_MJ), fmt(r.E_regen_MJ),
        fmt(r.electric_drive_s; digits = 1), fmt(r.starts; digits = 0)] for r in position_rows]
    Markdown.parse("| " * join(table_headers, " | ") * " |\n|" *
        join(fill("---", length(table_headers)), "|") * "|\n" *
        join(["| " * join(row, " | ") * " |" for row in table_values], "\n"))
end

# ╔═╡ 3ca9a892-ae41-4a91-9e24-957c7297f308
position_table_plot = let
    n = length(table_headers)
    p = plot(; xlims = (0.5, n + 0.5), ylims = (-1, 6), size = (1800, 500),
        axis = false, ticks = false, legend = false, grid = false,
        title = "WLTC • 30 kW / 270 V • corrected-fuel savings", titlefontsize = 16)
    for (j, header) in enumerate(table_headers)
        annotate!(p, j, 5.2, text(header, 11, :black, :center))
    end
    for (i, row) in enumerate(table_values)
        hline!(p, [5.0 - i]; color = "#dddddd", linewidth = 1)
        for (j, value) in enumerate(row)
            annotate!(p, j, 5.4 - i, text(value, 12, :black, :center))
        end
    end
    annotate!(p, (n + 1) / 2, -0.65,
        text("Fuel: L/100 km • Stored: battery recovery during braking; Req.: requested regen • Electric: engine-off drive", 10, :gray, :center))
    p
end

# ╔═╡ 3ca9a892-ae41-4a91-9e24-957c7297f309
md"""
## 2. Energy, modes and tracking

| Position | Available modes |
|---|---|
| P0 | Stop/start, line, load-point charging, belt-limited assist, regen with engine drag |
| P1 | Stop/start, line, load-point charging, direct-crank assist, regen with engine drag |
| P2 | Stop/start, electric drive, sailing, line, charging, boost, engine-decoupled regen |
| P3 | Starter-assisted stop/start, electric drive, sailing, line, charging, boost, engine-decoupled regen |
| P4 | Starter-assisted stop/start, rear electric drive, sailing, line, charging, boost, engine-decoupled regen |

Recovered energy (`E_recovered_MJ`) integrates positive battery stored-power inflow during
negative driver demand, excluding engine-driven charging in traction. `E_regen_MJ` is
requested regen before machine, converter and belt losses. Neither is fuel saving by itself. Electric-drive time counts
engine-off operation above 1 km/h with drive torque above 1 N·m. Starts count engine speed crossing the firing band's lower edge upward after being below it,
including the initial cranking start. Fuel resumptions count engine-latch rising edges separately.
P0/P1 disable electric-drive mode; measured engine-unlatched traction can still occur in the manager's torque deadband.

The energy meter is charge-corrected MJ/100 km. SoC endpoints and maximum absolute WLTC
speed error make battery use and trace tracking visible alongside fuel consumption.
"""

# ╔═╡ 3ca9a892-ae41-4a91-9e24-957c7297f310
Markdown.parse("""
| Position | Corrected MJ/100 km | SoC start | SoC end | Max speed error [km/h] |
|---|---|---|---|---|
$(join(["| $(r.position) | $(fmt(r.energy_MJ100)) | $(fmt(r.SoC_start; digits = 4)) | $(fmt(r.SoC_end; digits = 4)) | $(fmt(r.max_speed_error_kmh)) |" for r in position_rows], "\n"))
""")

# ╔═╡ 3ca9a892-ae41-4a91-9e24-957c7297f311
md"""
## 3. Compare with the literature, not with a universal target

The ICCT 2022 review supports approximate WLTC context bands of **P0 4–9%**, **P2 12–25%**,
**P3 15–25%**, and **P4+P0 about 15.5%** (against FWD). These summarize different studies,
not confidence intervals for this model or a single equal-power experiment.

- ICCT Fig. 6 (Schaeffler): mostly **15–16 kW, 48 V**, versus a **12 V stop-start** car;
  P0 3.8–6.6%, P2 11.9–15.8%, P3 15.3%, P4+P0 15.5%.
- ICCT Table 4 (Chalmers): versus **no stop-start**; WLTC P0 7.5–8.9%, P2 20.5–25.2%,
  P3 20.6–26.6% across the reported powers. The rounded bands above are teaching summaries.
- Here: **30 kW, 270 V**, the same teaching car with different machine positions, compared
  with its own **no-stop-start** engine baselines. Power, voltage, transmission, control,
  battery and reference fuel all differ. The line-minus-idle number only probes denominator
  sensitivity; it must not be relabeled a stop-start simulation or a like-for-like ICCT result.

Source: Dornoff et al., *Mild-hybrid vehicles: a near term technology trend for CO₂ emissions
reduction*, July 2022, [ICCT white paper](https://theicct.org/wp-content/uploads/2022/07/mild-hybrid-emissions-jul22.pdf),
Fig. 6 and Table 4. Local research: `docs/research_notes/Electric and hybrid vehicles/teaching_materials.md`, §5.
"""

# ╔═╡ 3ca9a892-ae41-4a91-9e24-957c7297f312
Markdown.parse("""
## Pinned definition fingerprints

`definitions_sha256` identifies the generated definitions used to produce each CSV row;
this notebook reads the pinned results rather than checking them against a newly compiled model.

| Position | definitions_sha256 |
|---|---|
$(join(["| $(r.position) | `$(r.definitions_sha256)` |" for r in position_rows], "\n"))
""")

# ╔═╡ Cell order:
# ╠═3ca9a892-ae41-4a91-9e24-957c7297f301
# ╟─3ca9a892-ae41-4a91-9e24-957c7297f302
# ╠═3ca9a892-ae41-4a91-9e24-957c7297f303
# ╟─3ca9a892-ae41-4a91-9e24-957c7297f304
# ╠═3ca9a892-ae41-4a91-9e24-957c7297f305
# ╟─3ca9a892-ae41-4a91-9e24-957c7297f306
# ╠═3ca9a892-ae41-4a91-9e24-957c7297f307
# ╠═3ca9a892-ae41-4a91-9e24-957c7297f308
# ╟─3ca9a892-ae41-4a91-9e24-957c7297f309
# ╠═3ca9a892-ae41-4a91-9e24-957c7297f310
# ╟─3ca9a892-ae41-4a91-9e24-957c7297f311
# ╠═3ca9a892-ae41-4a91-9e24-957c7297f312
