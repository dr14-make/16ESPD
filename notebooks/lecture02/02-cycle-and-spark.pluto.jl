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

# ╔═╡ 247c890e-472a-4ab2-a328-fed9d4130fb0
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

# ╔═╡ bd45dced-e564-43ce-8e89-0aec9a086181
md"""
# Lecture 2 · 02 — The cycle and the spark

> **Spark timing has an optimum, and it moves with speed, which is why the ECU stores a map.**

The argument starts from the ideal cycles: air alone, constant specific heats, every process
reversible. Otto adds its heat at constant volume, Diesel at constant pressure. The ideal Otto
efficiency depends on the compression ratio alone:

```math
\eta_{\text{Otto}} = 1 - r_c^{\,1-\gamma}
```
"""

# ╔═╡ 496f1b03-24b3-4382-ba75-3b91d42933a3
begin
    const GAMMA = 1.4         # air (textbook)
    const R_AIR = 287.05      # J/(kg K) (textbook)
    const CV = R_AIR / (GAMMA - 1)
    const CP = GAMMA * CV
    const P_1 = 101_325.0     # Pa, intake at ambient pressure (textbook)
    const T_1 = 298.15        # K, intake air (MathWorks)
    const H_L = 43.4e6        # J/kg, gasoline lower heating value (textbook)
    const AFR_S = 14.6        # stoichiometric (deck slide 23)
    const Q_IN = H_L / AFR_S  # J per kg of air: a stoichiometric charge burned completely

    # Task 6's single cylinder (assumed, 1.5 L class): bore 74.5 mm, stroke 85.8 mm.
    const V_SWEPT = π / 4 * 0.0745^2 * 0.0858
    const RC_OTTO = 10.5      # (assumed), as task 6
    const RC_DIESEL = 18.0    # (assumed), a typical passenger-car diesel

    const N_SEGMENT = 200

    # Geometric spacing puts the points where an isentrope curves hardest, near TDC.
    function isentrope(V1, p1, V2)
        V = exp.(range(log(V1), log(V2); length = N_SEGMENT))
        (; V, p = p1 .* (V1 ./ V) .^ GAMMA)
    end

    """
        ideal_cycle(r_c, kind) -> (; V, p, efficiency, peak)

    One air-standard cycle per kilogram of air scaled to the cylinder: `kind` is `:otto`
    (heat at constant volume) or `:diesel` (at constant pressure), both taking `Q_IN`.
    """
    function ideal_cycle(r_c, kind)
        V1 = V_SWEPT * r_c / (r_c - 1)
        V2 = V1 / r_c
        m = P_1 * V1 / (R_AIR * T_1)
        compression = isentrope(V1, P_1, V2)
        p2, T2 = compression.p[end], T_1 * r_c^(GAMMA - 1)
        if kind === :otto
            T3 = T2 + Q_IN / CV
            V3, p3 = V2, p2 * T3 / T2
        else
            T3 = T2 + Q_IN / CP
            V3, p3 = V2 * T3 / T2, p2
        end
        heat = (V = [V2, V3], p = [p2, p3])
        expansion = isentrope(V3, p3, V1)
        V = vcat(compression.V, heat.V, expansion.V, V1)
        p = vcat(compression.p, heat.p, expansion.p, P_1)
        work = sum((p[k] + p[k + 1]) / 2 * (V[k + 1] - V[k]) for k in 1:(length(V) - 1))
        (; V, p, efficiency = work / (m * Q_IN), peak = maximum(p), r_c, kind)
    end

    otto = ideal_cycle(RC_OTTO, :otto)
    diesel = ideal_cycle(RC_DIESEL, :diesel)

    deck_layout(; kwargs...) = PP.Layout(;
        template = PP.templates[:plotly_white],
        font = PP.attr(size = 15),
        margin = PP.attr(l = 70, r = 20, t = 30, b = 60),
        kwargs...)

    loop_trace(c, name; kwargs...) = PP.scatter(;
        x = round.(1e6 .* c.V; digits = 3), y = round.(c.p ./ 1e5; digits = 3), mode = "lines",
        name, line = PP.attr(width = 3), kwargs...)
end

# ╔═╡ 8e961556-33b7-4a94-90d8-c1aa2374d526
md"""
## The ideal Otto loop

Compression ratio 10.5 (assumed, task 6's single cylinder), intake at ambient, and the heat of a
stoichiometric charge burned completely: `H_l / AFR_s` = 2.97 MJ per kilogram of air. With no
heat loss, no dissociation and an instant burn, the ideal loop peaks at roughly three times the
pressure of a real one; the fired cycle of task 6 will stand beside it.
"""

# ╔═╡ f51da762-8b3b-41e3-b41a-c8cb8883938e
# ╠═╡ card = "otto-pv"
let
    corners = (1, N_SEGMENT, N_SEGMENT + 2, length(otto.V) - 1)
    labels = [(otto.V[k], otto.p[k], string(n)) for (n, k) in enumerate(corners)]
    PP.plot(
        [
            loop_trace(otto, "Otto, r_c = $(RC_OTTO)"),
            PP.scatter(; x = [round(1e6v; digits = 3) for (v, _, _) in labels],
                y = [round(p / 1e5; digits = 3) for (_, p, _) in labels],
                text = [l for (_, _, l) in labels], mode = "markers+text", textposition = "top right",
                marker = PP.attr(size = 9, color = "black"), showlegend = false, hoverinfo = "skip"),
        ],
        deck_layout(; xaxis_title = "cylinder volume [cm³]", yaxis_title = "pressure [bar]",
            showlegend = false,
            annotations = [PP.attr(x = 0.97, y = 0.95, xref = "paper", yref = "paper", showarrow = false,
                xanchor = "right", align = "right",
                text = "r<sub>c</sub> = $(RC_OTTO)<br>η = 1 − r<sub>c</sub><sup>1−γ</sup> = $(round(100otto.efficiency; digits = 1)) %")]))
end

# ╔═╡ f89f72ec-6fd7-4d0b-bd14-9436255e9162
md"""
## Diesel beside Otto

The same heat per kilogram of air, added at constant pressure, at a diesel's compression ratio
of 18 (assumed). Compressing air alone lets the diesel use the higher ratio; adding the heat while
the piston already moves costs some of what that ratio buys.
"""

# ╔═╡ 283a705e-5ab0-4310-bf4b-bc0d26b39971
# ╠═╡ card = "diesel-pv"
let
    # Numbered as the deck's Diesel slide numbers them, 1–2 being the suction stroke.
    corners = (1, N_SEGMENT, N_SEGMENT + 2, length(diesel.V) - 1)
    PP.plot(
        [
            loop_trace(otto, "Otto, r_c = $(RC_OTTO): η = $(round(100otto.efficiency; digits = 1)) %";
                line = PP.attr(width = 2, dash = "dash", color = "gray")),
            loop_trace(diesel, "Diesel, r_c = $(round(Int, RC_DIESEL)): η = $(round(100diesel.efficiency; digits = 1)) %"),
            PP.scatter(; x = [round(1e6diesel.V[k]; digits = 3) for k in corners],
                y = [round(diesel.p[k] / 1e5; digits = 3) for k in corners],
                text = ["2", "3", "4", "5"], mode = "markers+text", textposition = "top right",
                marker = PP.attr(size = 9, color = "black"), showlegend = false, hoverinfo = "skip"),
        ],
        deck_layout(; xaxis_title = "cylinder volume [cm³]", yaxis_title = "pressure [bar]",
            legend = PP.attr(x = 0.98, xanchor = "right", y = 0.98)))
end

# ╔═╡ a9055122-aff8-4359-814f-8bbd6e45bf38
let
    @assert isapprox(otto.efficiency, 1 - RC_OTTO^(1 - GAMMA); rtol = 2e-3) "Otto loop work disagrees with 1 − r_c^(1−γ)"
    cutoff = 1 + Q_IN / (CP * T_1 * RC_DIESEL^(GAMMA - 1))
    closed_form = 1 - RC_DIESEL^(1 - GAMMA) * (cutoff^GAMMA - 1) / (GAMMA * (cutoff - 1))
    @assert isapprox(diesel.efficiency, closed_form; rtol = 2e-3) "Diesel loop work disagrees with its closed form"
    @assert diesel.efficiency < 1 - RC_DIESEL^(1 - GAMMA) "at equal r_c, Diesel must trail Otto"
    md"""
    **Otto** η = $(round(100otto.efficiency; digits = 1)) %, peak $(round(otto.peak / 1e5; digits = 0)) bar.
    **Diesel** η = $(round(100diesel.efficiency; digits = 1)) %, peak $(round(diesel.peak / 1e5; digits = 0)) bar,
    cut-off ratio $(round(cutoff; digits = 2)).
    """
end

# ╔═╡ c752564c-a8e4-4273-9f8b-a92d44ca0c9c
md"""
## Spark timing and the exhaust

The deck's slide on ignition timing and exhaust gases shows HC, NOx and CO against λ, one line
per ignition angle α``_z`` from 20° to 50° before TDC. The curves below are drawn from an
**assumed trend model**, `scripts/engine_out_emissions.jl`: a few lines per species with the
shapes of Heywood ch. 11 and of that figure, not a simulation and not a measurement.

```math
\begin{aligned}
\mathrm{EI}_{CO} &= (1 + 0.005\,\Delta\sigma)\,\bigl(2 \cdot 0.75 \cdot n_{O_2,st}\,M_{CO}\,\max(1.02 - \lambda,\ 0) + 20\bigr) \\
\mathrm{EI}_{NO_x} &= 75 \cdot \frac{e^{T_a/T_{ref} - T_a/T_b}}{1 + \bigl((\lambda - 1.05)/0.1\bigr)^2},
  \qquad T_b = 2600 + 3\,\Delta\sigma + 150\,(L - 0.5) \\
\mathrm{EI}_{HC} &= 15\,e^{0.015\,\Delta\sigma}\,\bigl(1 - 0.4\,(L - 0.5)\bigr)\bigl(1 + 12\,(\lambda - 1.1)^2\bigr)
  + 10\,e^{(\lambda - \lambda_{lim})/0.04}
\end{aligned}
```

in g per kg of fuel, with Δσ the advance from MBT in degrees, ``L`` the relative load,
``n_{O_2,st}`` = 105.7 mol of O₂ per kg of gasoline, ``T_a`` = 69 090 K the Zeldovich activation
temperature (textbook), ``T_{ref}`` = 2600 K and ``\lambda_{lim} = 1.35 + 0.1\,(L - 0.5)`` the
lean misfire limit (textbook 1.3–1.4). CO is the oxygen a rich mixture lacks, three quarters of it
left as CO and the rest as H₂ (textbook). NOx grows with the burned-gas temperature, which
advance and load raise. HC is fuel left in crevices, burned off in a hotter exhaust when the spark
is late, and it climbs steeply once the flame starts to fail lean. Every other number is
(assumed), chosen to match the shapes of the original figure.

MBT at the figure's operating point is taken as 50° before TDC (assumed: the fuel consumption on
the deck's next slide still falls at 50°), so the four lines are 0, 10, 20 and 30° of retard. The
figure plots g per kg of fuel; the original plots g/kWh, which divides by work instead of fuel.
"""

# ╔═╡ dda179a4-cfb9-4e69-846e-4a7145320cb8
begin
    # The model lives outside the notebook so that the mapped engine can reuse it.
    const Emissions = include(joinpath(@__DIR__, "..", "..", "scripts", "engine_out_emissions.jl"))
    const SIGMA_MBT = 50                 # degrees BTDC at the figure's point (assumed)
    const ALPHA_Z = (20, 30, 40, 50)     # ignition angles of the original figure, degrees BTDC
    const LAMBDA_AXIS = 0.75:0.01:1.40
    const LOADS = 0.2:0.1:0.8
    const LOAD_DECK = 0.5

    emission_curves(load) = Dict(α => [Emissions.engine_out_emissions(λ, α - SIGMA_MBT, load)
                                       for λ in LAMBDA_AXIS] for α in ALPHA_Z)
end

# ╔═╡ 0a8954d9-9ede-4149-9d5d-3f178a19d4d3
# ╠═╡ card = "emissions-vs-lambda"
let
    species = ((:HC, "HC"), (:NOx, "NO<sub>x</sub>"), (:CO, "CO"))
    ranges = (HC = [0, 80], NOx = [0, 125], CO = [0, 1300])
    colors = ("#86b6ef", "#3987e5", "#1c5cab", "#0d366b")
    dashes = ("solid", "dot", "dashdot", "dash")
    # One array per trace, in trace order, as a restyle step takes them.
    ys(curves) = [round.(getfield.(curves[α], s); digits = 2) for (s, _) in species for α in ALPHA_Z]

    x = collect(LAMBDA_AXIS)
    deck = ys(emission_curves(LOAD_DECK))
    traces = [PP.scatter(; x, y = deck[(p - 1) * length(ALPHA_Z) + a], mode = "lines",
                  name = "α<sub>z</sub> = $(α)°", legendgroup = "$α", showlegend = p == 1,
                  xaxis = "x$p", yaxis = "y$p",
                  line = PP.attr(width = 2.5, color = colors[a], dash = dashes[a]),
                  hovertemplate = "α<sub>z</sub> $(α)°, λ %{x:.2f}: %{y:.1f} g/kg<extra></extra>")
              for p in eachindex(species) for (a, α) in enumerate(ALPHA_Z)]

    gap = 0.07
    width = (1 - 2gap) / 3
    axes = Dict{Symbol, Any}()
    for (p, (s, label)) in enumerate(species)
        left = (p - 1) * (width + gap)
        axes[Symbol("xaxis$p")] = PP.attr(domain = [left, left + width], range = [0.75, 1.4],
            dtick = 0.1, title = "excess-air factor λ", anchor = "y$p")
        axes[Symbol("yaxis$p")] = PP.attr(range = ranges[s], anchor = "x$p",
            title = "$label [g/kg fuel]")
    end

    steps = [PP.attr(label = string(load), method = "restyle",
                 args = [Dict("y" => ys(emission_curves(load)))]) for load in LOADS]
    PP.plot(traces, deck_layout(;
        axes...,
        hovermode = "closest",
        margin = PP.attr(l = 70, r = 20, t = 40, b = 20),
        legend = PP.attr(orientation = "h", x = 0.5, xanchor = "center", y = 1.14),
        sliders = [PP.attr(active = findfirst(==(LOAD_DECK), LOADS) - 1, steps = steps,
            currentvalue = PP.attr(prefix = "relative load "), pad = PP.attr(t = 40),
            len = 0.5, x = 0.25)]))
end

# ╔═╡ 4a7938e8-74c3-49be-a234-ef4a83a162ae
let
    e = Emissions.engine_out_emissions
    c = Emissions.exhaust_concentrations
    fine = 0.75:0.001:1.40
    λ_nox = fine[argmax([e(λ, 0, LOAD_DECK).NOx for λ in fine])]
    λ_hc = fine[argmin([e(λ, 0, LOAD_DECK).HC for λ in fine])]
    nox_105 = [e(1.05, α - SIGMA_MBT, LOAD_DECK).NOx for α in ALPHA_Z]
    co_rich = [e(λ, α - SIGMA_MBT, LOAD_DECK).CO for α in ALPHA_Z, λ in 0.8:0.01:1.0]
    @assert 1.03 <= λ_nox <= 1.12 "NOx must peak at λ 1.03–1.12, found $λ_nox"
    @assert 1.0 < λ_hc <= 1.2 "HC minimum must lie lean of 1, at most at 1.2, found $λ_hc"
    @assert all(diff(nox_105) .> 0) "NOx at λ 1.05 must rise with advance: $nox_105"
    @assert all(diff(co_rich; dims = 2) .< 0) "CO must fall over λ 0.8–1.0 at every advance"

    nox_peak = c(e(λ_nox, 0, LOAD_DECK), λ_nox).NOx_ppm
    co_09 = c(e(0.9, 0, LOAD_DECK), 0.9).CO_pct
    hc_min = c(e(λ_hc, 0, LOAD_DECK), λ_hc).HC_ppmC1
    hc_lim = c(e(1.35, 0, LOAD_DECK), 1.35).HC_ppmC1
    retard = nox_105[1] / nox_105[end]
    @assert 1000 <= nox_peak <= 4000 "NOx peak must be 1000–4000 ppm, found $nox_peak"
    @assert 2 <= co_09 <= 5 "CO at λ 0.9 must be 2–5 %, found $co_09"
    @assert 1000 <= hc_min <= 3000 "HC minimum must be 1000–3000 ppm C1, found $hc_min"
    @assert 2500 <= hc_lim <= 6000 "HC at λ 1.35 must be 2500–6000 ppm C1, found $hc_lim"
    @assert 0.3 <= retard <= 0.6 "30° of retard must leave 0.3–0.6 of the NOx, found $retard"
    md"""
    At MBT and half load: NOx peaks at λ $(λ_nox) with $(round(Int, nox_peak)) ppm; CO at λ 0.9 is
    $(round(co_09; digits = 1)) %; HC is lowest at λ $(λ_hc) with $(round(Int, hc_min)) ppm C₁
    and reaches $(round(Int, hc_lim)) ppm C₁ at λ 1.35. At λ 1.05, NOx for α``_z`` 20…50° is
    $(join(round.(Int, nox_105), ", ")) g/kg: 30° of retard leaves $(round(retard; digits = 2)) of it.
    """
end

# ╔═╡ 85aada20-329a-4835-bb86-06dffbb020b0
md"""
## What comes later

With Dyad task 6 (`Vehicle.Engine.SingleCylinder`, `SparkSweep`) this notebook fires the cycle:
a motored loop, the fired loop at MBT beside this ideal one, pressure against crank angle around
MBT, IMEP against spark advance at three speeds, the knock proxy, and indicated against ideal
efficiency. The same cylinder with a burned-gas zone and Zeldovich kinetics then computes NOx
against spark advance from physics, beside the assumed trend above.
"""

# ╔═╡ Cell order:
# ╠═247c890e-472a-4ab2-a328-fed9d4130fb0
# ╟─bd45dced-e564-43ce-8e89-0aec9a086181
# ╠═496f1b03-24b3-4382-ba75-3b91d42933a3
# ╟─8e961556-33b7-4a94-90d8-c1aa2374d526
# ╠═f51da762-8b3b-41e3-b41a-c8cb8883938e
# ╟─f89f72ec-6fd7-4d0b-bd14-9436255e9162
# ╠═283a705e-5ab0-4310-bf4b-bc0d26b39971
# ╠═a9055122-aff8-4359-814f-8bbd6e45bf38
# ╟─c752564c-a8e4-4273-9f8b-a92d44ca0c9c
# ╠═dda179a4-cfb9-4e69-846e-4a7145320cb8
# ╠═0a8954d9-9ede-4149-9d5d-3f178a19d4d3
# ╠═4a7938e8-74c3-49be-a234-ef4a83a162ae
# ╟─85aada20-329a-4835-bb86-06dffbb020b0
