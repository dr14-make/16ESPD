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
   line.

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

The run is sampled every second. Each sample is an operating point: engine speed, brake torque,
and the fuel burned over that second, so a point the car holds for a minute weighs sixty times
one it passes through. On the map, nearby points are pooled into cells 100 rpm by 4 N·m, drawn at
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
  BSFC has no finite value.

A run that burns no fuel, such as a hybrid driving electrically, draws no bubbles and shows —
for every figure it has nothing to average over.
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
            "$(fmt(pct(f.idle), "%.0f %%")) |"
        end
        return Markdown.parse("""
        | car | L/100 km | fuel-weighted BSFC [g/kWh] | cycle BSFC [g/kWh] | near the line | idle |
        |---|---|---|---|---|---|
        $(join(rows, "\n"))
        """)
    end
end

# ╔═╡ 83d8353a-efa7-4de9-b0d8-757ee57a790e
md"""
## 3. The conventional car over WLTC

The reference is the hybrid's own car with its electric machine out of the loop: the
disconnect clutch K0 closed and the machine's torque held at zero, so the engine drives the
wheels alone through the same CVT, on the same planar car, over the same WLTC trace. Same car,
same driveline; only the hybrid's electric path differs.

**The run plugs in below.** Replace `nothing` with the engine-only analysis read through
`operating_points`:

```julia
conventional = let
    r = <engine-only analysis>()
    m = symbolic_container(r)
    operating_points(r.sol; speed = m.<engine speed, rad/s>, torque = m.<brake torque, N·m>,
        fuel = m.<fuel mass flow, kg/s>, vehicle_speed = m.<vehicle speed, km/h>)
end
```

Until it does, the figure and table stay empty and the export skips the deck figure.
"""

# ╔═╡ 69b442a8-4e97-4698-88ca-1dcb53e7e3b4
conventional = nothing

# ╔═╡ 0f2fe490-96eb-4da3-ab7b-ea77d2a9cc99
conventional_plot =
    conventional === nothing ? nothing : fuel_map_plot(["conventional" => conventional])

# ╔═╡ 97148512-0b3d-48a8-b16e-902317f8b074
conventional === nothing ? md"*The engine-only run is not plugged in yet.*" :
metrics_table(["conventional" => conventional])

# ╔═╡ 68fe97ba-ef21-48b3-a7f6-ebd05f5baf66
md"""
## Checking the tools on a bench run

The same extraction and figures on Hands-on 02's wide-open-throttle launch, `MappedCarWOT`:
the pedal floored from rest for two minutes. It is not a drive cycle, so its L/100 km means
nothing; it is here because it sweeps the engine up the full-load curve, where the best-BSFC
line joins it at high power, and so exercises every part of the figure.
"""

# ╔═╡ e21cafa1-c9d6-4871-9d1d-9bf81b713bf5
show_dyad("MappedCarWOT")

# ╔═╡ 23700ca7-2fd0-4d90-85e7-ffc353592f5b
wot = let
    r = VehicleSystemsComponents.HandsOn02.MappedCarWOTTransient()
    m = symbolic_container(r)
    operating_points(r.sol; speed = m.car.engine.speed.w, torque = m.car.engine.torque.tau,
        fuel = m.car.engine.mdot_fuel, vehicle_speed = m.car.v_kmh)
end;

# ╔═╡ 8c1d80a9-7dba-42da-99c1-a4553d783dc5
wot_plot = fuel_map_plot(["WOT launch" => wot]; title = "Bench check: WOT launch, 120 s")

# ╔═╡ 2ef46c54-c651-470c-9a69-8d3d5135756c
metrics_table(["WOT launch" => wot])

# ╔═╡ Cell order:
# ╠═b73eabb3-6f85-4bf0-a1fe-ae942c72e812
# ╟─6ae424ff-0e49-4156-84af-263b2f433afd
# ╟─f250b3b6-7262-43b6-8c3e-54702fd5210a
# ╠═bafe1eb3-a400-4e40-b1d5-285d90c9b202
# ╟─3a573707-da7d-435d-94f8-140ded4ca6dc
# ╠═7de0c0a5-a781-4f55-9800-9205b4317d82
# ╟─83d8353a-efa7-4de9-b0d8-757ee57a790e
# ╠═69b442a8-4e97-4698-88ca-1dcb53e7e3b4
# ╠═0f2fe490-96eb-4da3-ab7b-ea77d2a9cc99
# ╠═97148512-0b3d-48a8-b16e-902317f8b074
# ╟─68fe97ba-ef21-48b3-a7f6-ebd05f5baf66
# ╟─e21cafa1-c9d6-4871-9d1d-9bf81b713bf5
# ╠═23700ca7-2fd0-4d90-85e7-ffc353592f5b
# ╠═8c1d80a9-7dba-42da-99c1-a4553d783dc5
# ╠═2ef46c54-c651-470c-9a69-8d3d5135756c
