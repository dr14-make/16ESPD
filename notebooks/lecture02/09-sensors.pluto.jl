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

# ╔═╡ 2bc9e014-70e5-4fae-9f67-1863951789c4
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
    import PlutoPlotly as PP
end

# ╔═╡ 99fcbb1c-83a7-4529-a3ad-baf8c68be994
md"""
# Lecture 2 · 09 — Sensors

> **The ECU knows only what its sensors tell it, through their characteristic curves.**

The coolant and intake-air temperature sensors are NTC thermistors: their resistance falls
steeply as they warm. This notebook starts from a real one, the Bosch Motorsport NTC M12, whose
datasheet gives its resistance at ten temperatures.
"""

# ╔═╡ c04b178f-8993-4690-8dff-a1274c185947
begin
    const NOTES = joinpath(@__DIR__, "..", "..", "docs", "research_notes",
        "Engine control systems", "teaching_materials.md")

    """
        bosch_ntc_m12() -> (; T_C, R_ohm)

    The datasheet table as `teaching_materials.md` transcribes it, in its row for the NTC M12:
    `R(T): −40 °C 45,313 Ω; −20 15,462; …`.
    """
    function bosch_ntc_m12()
        row = only(filter(l -> occursin("Bosch NTC M12", l), readlines(NOTES)))
        table = match(r"R\(T\):(.*?)\. Accuracy", row)[1]
        pairs = map(split(table, ";")) do entry
            numbers = [replace(m.match, "−" => "-", "," => "")
                for m in eachmatch(r"−?[\d,]+", replace(entry, "**" => ""))]
            parse(Float64, numbers[1]) => parse(Float64, numbers[2])
        end
        (; T_C = first.(pairs), R_ohm = last.(pairs))
    end

    ntc = bosch_ntc_m12()

    # Steinhart–Hart through three datasheet points: 1/T = a + b ln R + c (ln R)³.
    function steinhart_hart(T_C, R)
        L = log.(R)
        A = hcat(ones(3), L, L .^ 3)
        a, b, c = A \ (1 ./ (T_C .+ 273.15))
        R_of_T(T) = begin
            y = (a - 1 / (T + 273.15)) / c
            x = sqrt((b / (3c))^3 + y^2 / 4)
            exp(cbrt(x - y / 2) - cbrt(x + y / 2))
        end
        R_of_T
    end
    anchors = findall(in((-20.0, 20.0, 100.0)), ntc.T_C)
    ntc_fit = steinhart_hart(ntc.T_C[anchors], ntc.R_ohm[anchors])

    deck_layout(; kwargs...) = PP.Layout(;
        template = PP.templates[:plotly_white],
        font = PP.attr(size = 15),
        margin = PP.attr(l = 80, r = 20, t = 30, b = 60),
        kwargs...)
end

# ╔═╡ 90f13bf7-988b-4e9d-97d1-17de6b3136ff
md"""
## The NTC characteristic

The datasheet points, and a Steinhart–Hart curve fitted through three of them (−20, 20 and
100 °C). On a logarithmic axis the curve is nearly straight: the resistance roughly halves
every 20 °C.
"""

# ╔═╡ e3d8c8b0-98db-474b-a42e-449c4b1117e9
# ╠═╡ card = "ntc-curve"
let T = collect(-40.0:1.0:130.0)
    PP.plot(
        [
            PP.scatter(; x = T, y = round.(ntc_fit.(T); sigdigits = 5), mode = "lines",
                name = "Steinhart–Hart fit", line = PP.attr(width = 3)),
            PP.scatter(; x = ntc.T_C, y = ntc.R_ohm, mode = "markers", name = "Bosch NTC M12 datasheet",
                marker = PP.attr(size = 10, color = "black")),
        ],
        deck_layout(; xaxis_title = "temperature [°C]", yaxis_title = "resistance [Ω]",
            yaxis_type = "log", yaxis_dtick = 1, yaxis_exponentformat = "SI",
            legend = PP.attr(x = 0.98, xanchor = "right", y = 0.98)))
end

# ╔═╡ 81dcb403-100c-4c08-99a3-a5c65ddfb2ac
let
    @assert length(ntc.T_C) == 10 "the datasheet row holds $(length(ntc.T_C)) points, not 10"
    @assert ntc.R_ohm[ntc.T_C .== 20.0] == [2500.0] "R(20 °C) must read 2500 Ω"
    errors = abs.(ntc_fit.(ntc.T_C) ./ ntc.R_ohm .- 1)
    @assert maximum(errors) < 0.03 "Steinhart–Hart misses the datasheet by $(round(100maximum(errors); digits = 1)) %"
    md"""
    **Datasheet span** $(round(Int, maximum(ntc.R_ohm))) Ω at $(round(Int, minimum(ntc.T_C))) °C to
    $(round(Int, minimum(ntc.R_ohm))) Ω at $(round(Int, maximum(ntc.T_C))) °C. **Fit error**
    at most $(round(100maximum(errors); digits = 1)) %.
    """
end

# ╔═╡ 246f87e4-9e08-4535-a003-3820a4141a8b
md"""
## What comes later

With Dyad task 10 (`Vehicle.Engine.NTCSensor`, `HotFilmMAF`) this notebook adds the divider
voltage the ECU reads beside this curve, the sensitivity peak where `R` equals the pull-up, the
ECU's inverse lookup, and the hot-film meter: its inner loop, its step response closed against
open loop, and its output over the air path's tip-in from notebook 12.
"""

# ╔═╡ Cell order:
# ╠═2bc9e014-70e5-4fae-9f67-1863951789c4
# ╟─99fcbb1c-83a7-4529-a3ad-baf8c68be994
# ╠═c04b178f-8993-4690-8dff-a1274c185947
# ╟─90f13bf7-988b-4e9d-97d1-17de6b3136ff
# ╠═e3d8c8b0-98db-474b-a42e-449c4b1117e9
# ╠═81dcb403-100c-4c08-99a3-a5c65ddfb2ac
# ╟─246f87e4-9e08-4535-a003-3820a4141a8b
