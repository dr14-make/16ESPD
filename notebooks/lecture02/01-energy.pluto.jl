### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ 42dab4d1-8c98-411b-8e85-a87d2c131ef2
begin
    import Pkg
    Pkg.activate(joinpath(@__DIR__, "..", ".."))
    include(joinpath(@__DIR__, "..", "lecture01", "support.jl"))
    using .Lecture01Support

    # PlutoPlotly is no dependency of the library, so it comes from a shared environment stacked
    # behind the project: the project's Manifest stays the library's own.
    let env = "@lecture02-plotly"
        env in LOAD_PATH || push!(LOAD_PATH, env)
        if isnothing(Base.identify_package("PlutoPlotly"))
            project = Base.active_project()
            try
                Pkg.activate(env[2:end]; shared = true)
                Pkg.add(Pkg.PackageSpec(; name = "PlutoPlotly", version = "0.6.6"))
            finally
                Pkg.activate(project)
            end
        end
    end

    # Not bound as `VehicleSystemsComponents`: run as a script, that global would collide with
    # the module of the same name that `setup` defines in `Main`.
    library = setup()
    using ModelingToolkit: ModelingToolkit, initial_conditions
    import PlutoPlotly as PP
end

# ╔═╡ bcf17731-8a0f-4d2a-b0c2-096333078412
md"""
# Lecture 2 · 01 — Where the energy goes

> **Before asking how an engine makes energy, ask where the car spends it.**

On a flat road at steady speed the engine works against two forces: aerodynamic drag, which
grows with the square of the speed, and rolling resistance, which hardly changes with it.

```math
F_V = \tfrac{1}{2}\,\rho\,c_x S_x\,v^2, \qquad F_F = m\,g\,f_k
```

The car is Lecture 1's, with the parameter values of `Vehicle.VehicleBody`.
"""

# ╔═╡ 4a1649e6-f9bc-470e-aeda-7e1c2c4de72c
begin
    "The default of parameter `name` in a library component, read without compiling it."
    default_value(component, name) = ModelingToolkit.SymbolicUtils.unwrap_const(
        only(v for (k, v) in initial_conditions(component(; name = :c)) if string(k) == name))

    car = NamedTuple(Symbol(p) => default_value(library.Vehicle.VehicleBody, p)
        for p in ("m", "CdA", "rho", "f_r", "g"))

    rolling_N = car.m * car.g * car.f_r
    drag_N(v) = 0.5 * car.rho * car.CdA * v^2
    crossover = sqrt(rolling_N / (0.5 * car.rho * car.CdA))   # m/s
    kmh(v) = 3.6v
    ratio_130 = drag_N(130 / 3.6) / rolling_N

    deck_layout(; kwargs...) = PP.Layout(;
        template = PP.templates[:plotly_white],
        font = PP.attr(size = 15),
        margin = PP.attr(l = 70, r = 20, t = 30, b = 60),
        kwargs...)
end

# ╔═╡ ba28e806-ddbc-46ec-93af-6f6052fa00b6
md"""
## Drag against rolling resistance

Rolling resistance is drawn flat, as `VehicleBody` models it: a constant `f_r`. On a real tire
it creeps up with speed (slide 01.3), which moves the crossover a little higher still.
"""

# ╔═╡ 377c24ae-5a8b-4eda-af81-3bc347bd3d39
# ╠═╡ card = "drag-and-rolling"
let v = collect(0.0:0.5:45.0)
    PP.plot(
        [
            PP.scatter(; x = kmh.(v), y = round.(drag_N.(v); digits = 2), mode = "lines",
                name = "drag F_V", line = PP.attr(width = 3)),
            PP.scatter(; x = kmh.(v), y = fill(round(rolling_N; digits = 2), length(v)), mode = "lines",
                name = "rolling F_F", line = PP.attr(width = 3)),
            PP.scatter(; x = [kmh(crossover)], y = [rolling_N], mode = "markers+text",
                marker = PP.attr(size = 12, color = "black"),
                text = ["$(round(crossover; digits = 1)) m/s = $(round(Int, kmh(crossover))) km/h"],
                textposition = "top left", showlegend = false),
            PP.scatter(; x = [130, 130], y = [rolling_N, drag_N(130 / 3.6)], mode = "lines+text",
                line = PP.attr(color = "gray", dash = "dot", width = 2),
                text = ["", "$(round(ratio_130; digits = 1))× at 130 km/h"],
                textposition = "top left", showlegend = false),
        ],
        deck_layout(; xaxis_title = "speed [km/h]", yaxis_title = "force [N]",
            xaxis_range = [0, 162], legend = PP.attr(x = 0.02, y = 0.98)))
end

# ╔═╡ f26c7d12-7cd8-4dc3-84db-e829ca6df65d
let
    @assert 20 < crossover < 22 "crossover $(crossover) m/s outside 20–22 m/s"
    @assert 2.5 < ratio_130 < 3.5 "drag over rolling at 130 km/h $(ratio_130) outside 2.5–3.5"
    md"""
    **Rolling resistance** $(round(rolling_N; digits = 1)) N. **Crossover**
    $(round(crossover; digits = 1)) m/s ($(round(kmh(crossover); digits = 1)) km/h). **Drag at
    130 km/h** $(round(ratio_130; digits = 2))× rolling.
    """
end

# ╔═╡ 28030cce-2bb4-4f2e-b3dc-1a2dd529cc31
md"""
## Rolling resistance coefficients

The coefficient depends on the tire and the surface. The table is `rolling_resistance.csv`
beside this notebook, from engineeringtoolbox.com; the highlighted row holds Lecture 1's `f_r`.
"""

# ╔═╡ 9e4fa0bc-aa47-453c-b8a5-8c3ee3186b2d
begin
    "Rows of a small CSV whose quoted fields may hold commas."
    function read_csv(path)
        split_row(line) = [strip(m.match, '"') for m in eachmatch(r"\"[^\"]*\"|[^,]+", line)]
        lines = filter(!isempty, readlines(path))
        names = Symbol.(split_row(lines[1]))
        [NamedTuple{Tuple(names)}(Tuple(split_row(l))) for l in lines[2:end]]
    end

    coefficients = map(read_csv(joinpath(@__DIR__, "rolling_resistance.csv"))) do r
        (; c_min = parse(Float64, r.c_min), c_max = parse(Float64, r.c_max), surface = String(r.surface))
    end
    holds_f_r(r) = r.c_min <= car.f_r <= r.c_max
end

# ╔═╡ c930b987-56bb-465f-8d50-5bd32528b073
# ╠═╡ card = "rolling-table"
let
    format(r) = r.c_min == r.c_max ? "$(r.c_min)" : "$(r.c_min) – $(r.c_max)"
    rows = map(coefficients) do r
        mark = holds_f_r(r) ? """ class="ours" """ : ""
        "<tr$mark><td>$(format(r))</td><td>$(r.surface)</td></tr>"
    end
    HTML("""
    <table class="rolling">
    <thead><tr><th>f<sub>k</sub></th><th>wheel and surface</th></tr></thead>
    <tbody>$(join(rows, "\n"))</tbody>
    </table>
    <style>
    .rolling { border-collapse: collapse; font-variant-numeric: tabular-nums; width: 100%; }
    .rolling th, .rolling td { padding: 0.12em 0.6em; border-bottom: 1px solid #ddd; text-align: left; }
    .rolling td:first-child { white-space: nowrap; text-align: right; }
    .rolling thead th { border-bottom: 2px solid #888; }
    .rolling .ours { background: #fff3c4; font-weight: 600; }
    </style>
    """)
end

# ╔═╡ 6ccaa19b-27a2-41d7-a43a-2d02b8ff36af
let
    ours = filter(holds_f_r, coefficients)
    @assert length(ours) == 1 "f_r = $(car.f_r) must fall in exactly one row"
    @assert occursin("ordinary car tires", only(ours).surface) "f_r must be an ordinary car tire's"
end

# ╔═╡ 94cbd2fb-cb91-4abf-ba25-8ef131a4450e
md"""
## What comes later

With Dyad task 8 (`Vehicle.RoadLoadMeter`, `DriveCycleTransient`) this notebook drives the car
over WLTC and the EPA highway cycle: power per term against speed, cumulative energy per term,
energy per kilometer per cycle, and a `C_r` slider over this table's surfaces.
"""

# ╔═╡ Cell order:
# ╠═42dab4d1-8c98-411b-8e85-a87d2c131ef2
# ╟─bcf17731-8a0f-4d2a-b0c2-096333078412
# ╠═4a1649e6-f9bc-470e-aeda-7e1c2c4de72c
# ╟─ba28e806-ddbc-46ec-93af-6f6052fa00b6
# ╠═377c24ae-5a8b-4eda-af81-3bc347bd3d39
# ╠═f26c7d12-7cd8-4dc3-84db-e829ca6df65d
# ╟─28030cce-2bb4-4f2e-b3dc-1a2dd529cc31
# ╠═9e4fa0bc-aa47-453c-b8a5-8c3ee3186b2d
# ╠═c930b987-56bb-465f-8d50-5bd32528b073
# ╠═6ccaa19b-27a2-41d7-a43a-2d02b8ff36af
# ╟─94cbd2fb-cb91-4abf-ba25-8ef131a4450e
