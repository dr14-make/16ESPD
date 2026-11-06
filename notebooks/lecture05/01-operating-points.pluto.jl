### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# ╔═╡ b73eabb3-6f85-4bf0-a1fe-ae942c72e812
begin
    import Pkg
    Pkg.activate(joinpath(@__DIR__, "..", ".."))
    include(joinpath(@__DIR__, "..", "lecture01", "support.jl"))
    using .Lecture01Support
    # The dyad-3.5 kernel ships Plots with the plotly backend and Kaleido, but not GR.
    VehicleSystemsComponents = setup(backend = :plotly)
    using ModelingToolkit, Plots, Printf
    using DyadInterface: symbolic_container
    include(joinpath(@__DIR__, "operating_points.jl"))
    using .OperatingPoints
    include(joinpath(@__DIR__, "bsfc_map.jl"))
    using .BsfcMap
end

# ╔═╡ 6ae424ff-0e49-4156-84af-263b2f433afd
md"""
# Lecture 5 — Where the engine burns its fuel

Lecture 2's mapped engine has one speed and torque where each power costs least: the best-BSFC
line. A car driving WLTC asks for small powers most of the time, and wherever the driveline puts
the engine for them is where its fuel goes. This notebook draws the engine's operating points on
its BSFC map, each cell of the map as a bubble whose area is the fuel burned there, and reads
off the figures a hybrid is compared on:

1. the map: contours, full-load curve and the best-BSFC line;
2. the conventional car over WLTC: where its fuel goes;
3. the figures: L/100 km, the fuel-weighted mean BSFC, and the share of fuel burned near the
   line;
4. the P2 hybrid over the same WLTC, on the same map;
5. three powertrains phase by phase: the conventional car, the same car with its CVT on the
   line, and the hybrid.

Every number below is read from a simulation of the Dyad models shown.
"""

# ╔═╡ f250b3b6-7262-43b6-8c3e-54702fd5210a
md"""
## 1. The map

BSFC contours in g/kWh over engine speed and brake torque, under the full-load curve. The blue
line is the best-BSFC line: for each power from 1 kW to peak, the speed and torque where that
power costs the least fuel. The dotted curves are constant power.
"""

# ╔═╡ bafe1eb3-a400-4e40-b1d5-285d90c9b202
map_plot = bsfc_map_plot()

# ╔═╡ 3a573707-da7d-435d-94f8-140ded4ca6dc
md"""
## 2. How the fuel is counted

The run is sampled every 0.1 s. Each sample is an operating point: engine speed, brake torque,
and the fuel burned over that interval, so a point the car holds for a minute weighs as much as
600 samples it passes through. On the map, nearby points are pooled into cells 100 rpm by 4 N·m, drawn at
their fuel-weighted center, with an area proportional to the grams burned there.

From the samples:

- **L/100 km**: all the fuel burned, at $(RHO_PETROL) kg/L, over the distance driven;
- **fuel-weighted mean BSFC**: each sample's BSFC weighted by the fuel it burned, over the
  samples above $(P_MIN_KW) kW. It answers "a typical gram of this car's fuel was burned at
  what BSFC?";
- **cycle BSFC**: the same fuel over the engine work it delivered;
- **near the line**: the share of all fuel burned within 10 g/kWh of the best-BSFC line's BSFC
  at the same power. A CVT that held the engine exactly on the line would score 100 % less the
  idle share; this is the number the hybrid is compared on;
- **idle**: the share burned at or below $(P_MIN_KW) kW, idling at stops and creeping, where
  BSFC has no finite value;
- **engine fueled**: the share of the run's time the engine burned fuel at all.

Only fueled samples are operating points: a hybrid's engine standing still while the machine
drives adds no bubble and no fuel. A run that burns no fuel draws no bubbles and shows — for
every figure it has nothing to average over.
"""

# ╔═╡ 7de0c0a5-a781-4f55-9800-9205b4317d82
begin
    CAR_COLORS = ["#c0392b", "#2e8b57", "#8e44ad"]

    """
        fuel_map_plot(cars; title)

    The BSFC map with each car's fuel cells drawn on it; `cars` is a vector of
    `label => operating_points(...)`. All cars share one bubble scale.
    """
    function fuel_map_plot(cars; title = "Where the fuel goes over WLTC")
        length(cars) <= length(CAR_COLORS) ||
            error("$(length(cars)) cars but $(length(CAR_COLORS)) colors in CAR_COLORS")
        cells = [fuel_cells(op) for (_, op) in cars]
        scale = maximum(c -> maximum(c.fuel_g; init = 0.0), cells)
        p = bsfc_map_plot(; title)
        for ((label, _), c, color) in zip(cars, cells, CAR_COLORS)
            fuel_bubbles!(p, c; scale, color, label)
        end
        return p
    end

    "The fuel figures of `cars` (as for `fuel_map_plot`) as a table; — where there is none."
    function metrics_table(cars)
        fmt(x, spec) = ismissing(x) ? "—" : Printf.format(Printf.Format(spec), x)
        rows = map(cars) do (label, op)
            f = fuel_metrics(op)
            pct(x) = ismissing(x) ? x : 100x
            "| $label | $(fmt(f.L_per_100km, "%.2f")) | $(fmt(f.bsfc_mean, "%.0f")) | " *
            "$(fmt(f.bsfc_cycle, "%.0f")) | $(fmt(pct(f.near_line), "%.0f %%")) | " *
            "$(fmt(pct(f.idle), "%.0f %%")) | $(fmt(pct(f.fueled_time), "%.0f %%")) |"
        end
        return Markdown.parse("""
        | car | L/100 km | fuel-weighted BSFC [g/kWh] | cycle BSFC [g/kWh] | near the line | idle | engine fueled |
        |---|---|---|---|---|---|---|
        $(join(rows, "\n"))
        """)
    end
end

# ╔═╡ 83d8353a-efa7-4de9-b0d8-757ee57a790e
md"""
## 3. The conventional car over WLTC

The reference is the hybrid's own car with its electric machine removed: no torque, losses
or inertia, so the engine drives the wheels alone through K0 and the same CVT, on the same planar
car, over the same WLTC trace. Same car, same driveline; only the hybrid's electric path differs.

The run is `Lecture5.P2EngineWLTCTransient`: a PI driver's demand is the engine's pedal, the
CVT sets its ratio from the same pedal on its schedule. K0 launches the car as a centrifugal
clutch would, engaging as the engine passes 1300 rpm, and stays locked once the shaft behind it
turns faster than about 880 rpm.
"""

# ╔═╡ 90e62a3f-a0e0-49a4-b30a-611aa4837112
show_dyad("P2WLTC")

# ╔═╡ 69b442a8-4e97-4698-88ca-1dcb53e7e3b4
conventional_run = VehicleSystemsComponents.Lecture5.P2EngineWLTCTransient();

# ╔═╡ 2ef46c54-c651-470c-9a69-8d3d5135756c
conventional = let
    m = symbolic_container(conventional_run)
    operating_points(conventional_run.sol; speed = m.powertrain.engine_speed,
        torque = m.powertrain.engine_torque, fuel = m.powertrain.mdot_fuel,
        vehicle_speed = m.kmh.y)
end;

# ╔═╡ 0f2fe490-96eb-4da3-ab7b-ea77d2a9cc99
conventional_plot = fuel_map_plot(["conventional" => conventional])

# ╔═╡ 97148512-0b3d-48a8-b16e-902317f8b074
metrics_table(["conventional" => conventional])

# ╔═╡ 8c1d80a9-7dba-42da-99c1-a4553d783dc5
let
    m = symbolic_container(conventional_run)
    meter = round(conventional_run.sol[m.meter.fuel_raw][end]; digits = 2)
    sampled = round(fuel_metrics(conventional).L_per_100km; digits = 2)
    md"""
    The run's own fuel meter, integrating the fuel flow as it solves, reads $meter L/100 km; the
    samples above give $sampled.
    """
end

# ╔═╡ 9787e0bc-535c-4fa1-8976-44483466618c
md"""
## 4. The P2 hybrid over WLTC

The same car again, now with its 30 kW machine between K0 and the CVT and the 1.4 kWh battery
behind it. A rule-based energy manager splits the driver's demand: the machine alone at low
power, with the engine stopped and K0 open; the engine on the best-BSFC line when it runs,
raised by a charging power when the battery is low; the machine boosting above 30 kW.

The run is `Lecture5.P2HybridWLTCTransient`. Its engine is counted exactly as the conventional
car's, with one rule more: a sample where the engine burns no fuel is not an operating point.
"""

# ╔═╡ 0003fcda-4991-4345-b0f0-f5b0156e19de
show_dyad("P2HybridWLTC")

# ╔═╡ fe85c7f0-1a45-4d88-9922-e7172b05e1fc
hybrid_run = VehicleSystemsComponents.Lecture5.P2HybridWLTCTransient();

# ╔═╡ 1f637b28-ea41-458a-8ce5-dfbe19c7b392
hybrid = let
    m = symbolic_container(hybrid_run)
    operating_points(hybrid_run.sol; speed = m.powertrain.engine_speed,
        torque = m.powertrain.engine_torque, fuel = m.powertrain.mdot_fuel,
        vehicle_speed = m.kmh.y)
end;

# ╔═╡ 50b26404-8bc1-450a-9985-077712a1dff8
comparison_plot = fuel_map_plot(["conventional" => conventional, "P2 hybrid" => hybrid];
    title = "Where the fuel goes over WLTC: conventional and P2 hybrid")

# ╔═╡ 1217a993-a0fd-4f33-add1-b1dabe49fb2c
metrics_table(["conventional" => conventional, "P2 hybrid" => hybrid])

# ╔═╡ ff17e7f9-2de5-4a28-ba98-6b81a7a7bd8f
let
    m = symbolic_container(hybrid_run)
    s = hybrid_run.sol
    r2(x) = round(x; digits = 2)
    raw, corr = r2(s[m.meter.fuel_raw][end]), r2(s[m.meter.fuel_corr][end])
    soc0, soc1 = round.((s[m.powertrain.SoC][1], s[m.powertrain.SoC][end]); digits = 3)
    E = r2(s[m.meter.E_batt_MJ][end])
    md"""
    The hybrid's meter reads $raw L/100 km of fuel burned. Its battery started at SoC $soc0 and
    ended at $soc1, $E MJ out of its store (negative: stored), so part of that fuel is still
    in the battery. Charged at the meter's engine-to-battery efficiency, the SoC-corrected
    figure is **$corr L/100 km**, the number the hybrid is compared on.

    On the map, the hybrid's bubbles leave the low-load corner, where the conventional car
    burns at 300 g/kWh and more: that load either goes electric, with the engine stopped, or is
    raised up the line while the machine charges.
    """
end

# ╔═╡ 5e17f09b-da5c-4a1d-809d-e121bcb291b1
md"""
## 5. Three powertrains, phase by phase

Between the two sits the conventional car with its CVT on the best-BSFC line instead of its
pedal schedule, `Lecture5.P2OperatingLineWLTCTransient`: the line without the battery. Each
run's meter integrates fuel, the battery's stored energy and distance; read at the WLTC's
phase boundaries, each phase is charged its fuel plus the fuel equivalent of the battery energy
it drew, over the distance it drove. The conventional cars draw none; the hybrid's phases sum,
weighted by distance, to its SoC-corrected figure.
"""

# ╔═╡ bacbb042-92a3-4ac9-8a81-2a7be9424a32
line_run = VehicleSystemsComponents.Lecture5.P2OperatingLineWLTCTransient();

# ╔═╡ b59c4118-52ce-4b96-b1a6-011337029474
phases = [label => phase_fuel(run.sol, symbolic_container(run).meter)
          for (label, run) in ("conventional" => conventional_run,
              "CVT on the line" => line_run, "P2 hybrid, SoC-corrected" => hybrid_run)];

# ╔═╡ f5f461a2-7ac9-41e4-a7d8-86170ac5af3c
three_powertrains_plot = let
    colors = [CAR_COLORS[1], CAR_COLORS[3], CAR_COLORS[2]]
    names = [r.name for r in last(first(phases))]
    w = 0.26
    p = plot(; size = (1280, 620), xticks = (1:length(names), names), ylims = (0, 8.2),
        ylabel = "fuel [L/100 km]", title = "WLTC fuel by phase", legend = :topright,
        grid = true, gridalpha = 0.25, left_margin = 8Plots.mm, bottom_margin = 5Plots.mm,
        titlefontsize = 22, guidefontsize = 21, tickfontsize = 19, legendfontsize = 17)
    for (k, ((label, rows), color)) in enumerate(zip(phases, colors))
        x = (1:length(rows)) .+ (k - 2) * w
        y = [r.L_per_100km for r in rows]
        bar!(p, x, y; bar_width = w, color, linecolor = color, label)
        annotate!(p, [(xi, yi + 0.12, text(@sprintf("%.2f", yi), 13, :bottom, :black))
                      for (xi, yi) in zip(x, y)])
    end
    p
end

# ╔═╡ 4eef3b84-3623-4165-9273-18325a17645e
let
    names = [r.name for r in last(first(phases))]
    rows = map(phases) do (label, rs)
        "| $label | " * join([@sprintf("%.2f", r.L_per_100km) for r in rs], " | ") * " |"
    end
    km = [@sprintf("%.2f", r.km) for r in last(first(phases))]
    Markdown.parse("""
    | L/100 km | $(join(names, " | ")) |
    |---|$(repeat("---:|", length(names)))
    $(join(rows, "\n"))
    | distance [km] | $(join(km, " | ")) |
    """)
end

# ╔═╡ Cell order:
# ╠═b73eabb3-6f85-4bf0-a1fe-ae942c72e812
# ╟─6ae424ff-0e49-4156-84af-263b2f433afd
# ╟─f250b3b6-7262-43b6-8c3e-54702fd5210a
# ╠═bafe1eb3-a400-4e40-b1d5-285d90c9b202
# ╟─3a573707-da7d-435d-94f8-140ded4ca6dc
# ╠═7de0c0a5-a781-4f55-9800-9205b4317d82
# ╟─83d8353a-efa7-4de9-b0d8-757ee57a790e
# ╟─90e62a3f-a0e0-49a4-b30a-611aa4837112
# ╠═69b442a8-4e97-4698-88ca-1dcb53e7e3b4
# ╠═2ef46c54-c651-470c-9a69-8d3d5135756c
# ╠═0f2fe490-96eb-4da3-ab7b-ea77d2a9cc99
# ╠═97148512-0b3d-48a8-b16e-902317f8b074
# ╟─8c1d80a9-7dba-42da-99c1-a4553d783dc5
# ╟─9787e0bc-535c-4fa1-8976-44483466618c
# ╟─0003fcda-4991-4345-b0f0-f5b0156e19de
# ╠═fe85c7f0-1a45-4d88-9922-e7172b05e1fc
# ╠═1f637b28-ea41-458a-8ce5-dfbe19c7b392
# ╠═50b26404-8bc1-450a-9985-077712a1dff8
# ╠═1217a993-a0fd-4f33-add1-b1dabe49fb2c
# ╟─ff17e7f9-2de5-4a28-ba98-6b81a7a7bd8f
# ╟─5e17f09b-da5c-4a1d-809d-e121bcb291b1
# ╠═bacbb042-92a3-4ac9-8a81-2a7be9424a32
# ╠═b59c4118-52ce-4b96-b1a6-011337029474
# ╠═f5f461a2-7ac9-41e4-a7d8-86170ac5af3c
# ╟─4eef3b84-3623-4165-9273-18325a17645e
