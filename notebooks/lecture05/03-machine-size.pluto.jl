### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# ╔═╡ 4c2dc3ee-01ad-443e-9f29-781606d9db3a
begin
    import Pkg
    Pkg.activate(joinpath(@__DIR__, "..", ".."))
    include(joinpath(@__DIR__, "..", "lecture01", "support.jl"))
    using .Lecture01Support
    # The dyad-3.5 kernel ships Plots with the plotly backend and Kaleido, but not GR.
    VehicleSystemsComponents = setup(backend = :plotly)
    using Plots, Printf
    include(joinpath(@__DIR__, "..", "..", "scripts", "machine_size_sweep.jl"))
    using .MachineSizeSweep: read_sweep, doh, H0_L100, P_ENGINE_PEAK, SOC_BAND,
        SPEED_ERROR_MAX, W_CORNER
end

# ╔═╡ 46b5778d-b745-403c-bfd1-d577d805f4b7
md"""
# Lecture 5 — How big a machine?

The degree of hybridization is the machine's share of the car's power,
``\mathrm{DOH} = P_{EM} / (P_{EM} + P_{ICE})``. The P2 hybrid of notebook 01 has a 30 kW
machine beside Lecture 2's $(round(P_ENGINE_PEAK / 1e3; digits = 1)) kW engine,
DOH ≈ $(round(Int, 100doh(30e3))) %. This notebook asks what the machine's
size buys over WLTC: the same car and energy manager with machines from 8 to 40 kW, each
compared on its SoC-corrected fuel against the conventional car's
$(round(H0_L100; digits = 2)) L/100 km.

Every WLTC run takes minutes, so the sweep is not run here: `scripts/machine_size_sweep.jl`
runs it and writes `assets/data/lecture05/machine_size.csv`, which this notebook reads.
"""

# ╔═╡ 4f88bed4-e9f8-48c9-bc46-21da962d2af7
md"""
## 1. What changes with the size

Only the machine. For a machine rated ``P``:

- the drive's rated power is ``P`` and its torque limit ``T_{max} = P / \omega_c``, with the
  corner ``\omega_c`` = $(round(W_CORNER * 30 / pi; digits = 1)) rpm of the 30 kW, 205 N·m
  machine: a smaller machine has less torque over the same speed range;
- the machine is designed at the pack's terminal voltage when it draws its rated power, as
  the 30 kW one is: a smaller machine sags the pack less;
- the energy manager's machine limits ``T_{max}`` and ``P_{max}`` are the drive's, and so is
  its ceiling on regenerative power, ``P_{regen} = P``;
- the driver's drive-torque ceiling is the machine's ``T_{max}`` plus the engine's full-load
  peak, so a smaller machine also lowers what the driver can ask for. Its braking ceiling,
  friction and regen together, is the same at every size.

The pack, 1.4 kWh, and every other setting of the energy manager stay as they are: its
demand-power thresholds, charging power and the engine line's cap belong to the strategy and
the engine, not the machine, and the manager is not retuned per size. A run that does not end within $(SOC_BAND) of its starting SoC, or
falls more than $(SPEED_ERROR_MAX) km/h behind the trace, is still listed, flagged.
"""

# ╔═╡ 9ed45e72-6d34-4a42-880a-05c1b370f4f1
sweep, sweep_hash = read_sweep();

# ╔═╡ 51e7def9-6260-48f9-a4bc-6314fd0271b3
let
    rows = map(sweep) do r
        P = r.P_rated / 1e3
        "| $(@sprintf("%.0f", P)) | $(@sprintf("%.1f", r.T_max)) | " *
        "$(@sprintf("%.0f %%", 100doh(1e3P))) | $(@sprintf("%.3f", r.fuel_raw)) | " *
        "$(@sprintf("%.3f", r.fuel_corr)) | $(@sprintf("%.1f", r.energy_corr)) | " *
        "$(@sprintf("%.1f %%", r.saving_vs_H0_pct)) | $(@sprintf("%.3f", r.SoC_end)) | " *
        "$(@sprintf("%.2f", r.max_speed_error)) | $(r.starts) | $(r.flag) |"
    end
    Markdown.parse("""
    | machine [kW] | T_max [N·m] | DOH | raw [L/100 km] | SoC-corrected [L/100 km] | [MJ/100 km] | saving | SoC at end | max speed error [km/h] | engine starts | flag |
    |---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
    $(join(rows, "\n"))
    """)
end

# ╔═╡ b040a18d-3b33-4df3-819c-4319d4f8fecb
md"""
## 2. Fuel saving against machine size

Each point is one WLTC run, its saving the SoC-corrected fuel against the conventional car's.
A hollow point is a flagged run.
"""

# ╔═╡ e7b7578c-9354-4cfe-b2f7-1f31b28c416f
doh_plot = let
    P = [r.P_rated / 1e3 for r in sweep]
    y = [r.saving_vs_H0_pct for r in sweep]
    ok = [r.flag == "ok" for r in sweep]
    color = "#2e8b57"
    p = plot(P, y; size = (1280, 620), color, lw = 3, label = "",
        xlabel = "machine rated power [kW]", ylabel = "WLTC fuel saving vs conventional [%]",
        title = "Fuel saving against machine size, SoC-corrected", xlims = (0, 45),
        ylims = (0, 1.25 * maximum(y)), xticks = P, legend = :bottomright, grid = true,
        gridalpha = 0.25, left_margin = 8Plots.mm, bottom_margin = 5Plots.mm,
        titlefontsize = 22, guidefontsize = 21, tickfontsize = 19, legendfontsize = 19)
    scatter!(p, P[ok], y[ok]; color, markersize = 10, markerstrokecolor = :white,
        markerstrokewidth = 2, label = "charge-sustaining run")
    any(.!ok) && scatter!(p, P[.!ok], y[.!ok]; color = :white, markersize = 10,
        markerstrokecolor = color, markerstrokewidth = 3, label = "flagged run")
    for (Pi, yi) in zip(P, y)
        Pi in (15.0, 30.0) || continue
        annotate!(p, Pi, yi + 0.06 * maximum(y), text(@sprintf("%.0f kW: %.1f %%, DOH %.0f %%",
            Pi, yi, 100doh(1e3Pi)), 17, :black, :bottom))
    end
    p
end

# ╔═╡ 428264eb-8a3a-48cf-97b7-692a9315cd56
let
    P = [r.P_rated / 1e3 for r in sweep]
    y = [r.saving_vs_H0_pct for r in sweep]
    f1(x) = round(x; digits = 1)
    best = argmax(y)
    steps = join(["$(f1(P[k])) → $(f1(P[k+1])) kW: $(y[k+1] >= y[k] ? "+" : "−")" *
                  "$(f1(abs(y[k+1] - y[k]))) points" for k in 1:length(P)-1], "; ")
    flagged = [r for r in sweep if r.flag != "ok"]
    flag_text = isempty(flagged) ? "Every run ends charge-sustaining and follows the trace." :
        join(["The $(f1(r.P_rated / 1e3)) kW run is flagged ($(r.flag)): it ends at SoC " *
              "$(round(r.SoC_end; digits = 3)) and falls up to " *
              "$(round(r.max_speed_error; digits = 1)) km/h behind the trace. Its saving is " *
              "SoC-corrected, but a manager tuned for that machine would be needed for a fair " *
              "number." for r in flagged], " ")
    md"""
    The largest saving is $(f1(y[best])) % at $(f1(P[best])) kW. Size by size the saving
    moves $steps. $flag_text

    The file was written from inputs hashing to `$(first(sweep_hash, 12))…`; the Lecture 5
    tests check that hash against the current code, generated definitions, data and manifest.
    """
end

# ╔═╡ Cell order:
# ╠═4c2dc3ee-01ad-443e-9f29-781606d9db3a
# ╟─46b5778d-b745-403c-bfd1-d577d805f4b7
# ╟─4f88bed4-e9f8-48c9-bc46-21da962d2af7
# ╠═9ed45e72-6d34-4a42-880a-05c1b370f4f1
# ╟─51e7def9-6260-48f9-a4bc-6314fd0271b3
# ╟─b040a18d-3b33-4df3-819c-4319d4f8fecb
# ╠═e7b7578c-9354-4cfe-b2f7-1f31b28c416f
# ╟─428264eb-8a3a-48cf-97b7-692a9315cd56
