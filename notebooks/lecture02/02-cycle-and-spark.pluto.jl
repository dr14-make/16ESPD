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

    # Task 6's single cylinder (assumed, 1.5 L class).
    const BORE = 0.0745
    const STROKE = 0.0858
    const V_SWEPT = π / 4 * BORE^2 * STROKE
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

# ╔═╡ f0dca466-d105-4443-8b28-e98da2485499
md"""
## Pressure against crank angle

Until task 6's `SingleCylinder` exists, the same cylinder in a few lines: one zone with
``\gamma`` = 1.3 (textbook), the 10.5 compression ratio and bore and stroke of the ideal loop above,
a 140 mm connecting rod (assumed), and the heat released by a Wiebe function with ``a`` = 5,
``m`` = 2 over 50° of crank (textbook, unverified), starting 1 ms after the spark (assumed). Heat
leaves to walls at 450 K by Woschni's correlation with its coefficient tripled, standing in for
its combustion term (assumed). The charge is that of the operating point below: 3000 rpm, half the
full-load air charge, stoichiometric, 320 K at inlet valve closing (assumed).

```math
\frac{dp}{d\theta} = \frac{\gamma - 1}{V}\left(Q\,\frac{dx_b}{d\theta} - \frac{dQ_w}{d\theta}\right)
  - \gamma\,\frac{p}{V}\,\frac{dV}{d\theta},
\qquad x_b = 1 - e^{-a\left((\theta - \theta_0)/\Delta\theta\right)^{m + 1}}
```

MBT is the spark that gets the most work out of the closed cycle; the figure also fires 15°
earlier and 15° later, beside the motored cylinder. The traces are **idealized, drawn from
textbook trends**: nothing knocks, so the early spark's peak is smooth where the scan's is ragged.
"""

# ╔═╡ 888dda8d-5a7e-4625-8813-1c4c8ae3e51e
begin
    # The model lives outside the notebook so that the illustrations notebook can reuse it.
    const Trends = include(joinpath(@__DIR__, "..", "..", "scripts", "si_torque_trends.jl"))
    const RPM_DECK = 3000          # speed of the operating point (assumed)
    const OP_DECK = Trends.operating_point(RPM_DECK, LOAD_DECK)

    const GAMMA_BURN = 1.3         # unburned and burned mixture (textbook, task 6)
    const CONROD = 0.140           # m (assumed, task 6)
    const WIEBE_A = 5.0            # (textbook, unverified; task 6)
    const WIEBE_M = 2.0            # (textbook, unverified; task 6)
    const BURN = 50.0              # deg of crank for the whole burn (textbook, unverified; task 6)
    const T_IGN = 1e-3             # s, spark to start of burn (assumed, task 6)
    const T_IVC = 320.0            # K, charge at inlet valve closing (assumed)
    const T_WALL = 450.0           # K (assumed)
    const WOSCHNI = 3 * 130.0      # Woschni's coefficient, tripled for its combustion term (assumed)

    const V_CLEAR = V_SWEPT / (RC_OTTO - 1)
    const CRANK = STROKE / 2
    piston_area = π * BORE^2 / 4
    rod_term(θ) = sqrt(CONROD^2 - (CRANK * sind(θ))^2)
    cyl_V(θ) = V_CLEAR + piston_area * (CONROD + CRANK - CRANK * cosd(θ) - rod_term(θ))
    cyl_dV(θ) = piston_area * CRANK * sind(θ) * (1 + CRANK * cosd(θ) / rod_term(θ)) * π / 180
    wall_area(θ) = 2piston_area + 4cyl_V(θ) / BORE

    """
        cylinder(σ; fired = true) -> (; θ, p, work, heat, θ_peak, p_peak)

    Pressure [Pa] from BDC to BDC, crank angle `θ` in degrees after TDC, by fourth-order
    Runge–Kutta in 0.2° steps, for a spark `σ` degrees BTDC at the operating point.
    """
    function cylinder(σ; fired = true, dθ = 0.2)
        rpm, p_ivc = RPM_DECK, 1e3 * OP_DECK.p_m_kPa
        m = p_ivc * cyl_V(-180) / (R_AIR * T_IVC)
        heat = fired ? m / AFR_S * H_L : 0.0
        θ0 = -σ + 6rpm * T_IGN
        function burn_rate(θ)
            θ <= θ0 && return 0.0
            x = (θ - θ0) / BURN
            WIEBE_A * (WIEBE_M + 1) * x^WIEBE_M / BURN * exp(-WIEBE_A * x^(WIEBE_M + 1))
        end
        u_mean = 2 * STROKE * rpm / 60
        function wall_loss(θ, p)
            T = p * cyl_V(θ) / (m * R_AIR)
            h = WOSCHNI * BORE^-0.2 * (p / 1e5)^0.8 * T^-0.55 * (2.28u_mean)^0.8
            h * wall_area(θ) * (T - T_WALL) / 6rpm
        end
        f(θ, p) = (GAMMA_BURN - 1) / cyl_V(θ) * (heat * burn_rate(θ) - wall_loss(θ, p)) -
                  GAMMA_BURN * p / cyl_V(θ) * cyl_dV(θ)
        θ = collect(-180.0:dθ:180.0)
        p = similar(θ)
        p[1] = p_ivc
        for k in 1:(length(θ) - 1)
            k1 = f(θ[k], p[k])
            k2 = f(θ[k] + dθ / 2, p[k] + dθ / 2 * k1)
            k3 = f(θ[k] + dθ / 2, p[k] + dθ / 2 * k2)
            k4 = f(θ[k] + dθ, p[k] + dθ * k3)
            p[k + 1] = p[k] + dθ / 6 * (k1 + 2k2 + 2k3 + k4)
        end
        work = sum((p[k] + p[k + 1]) / 2 * (cyl_V(θ[k + 1]) - cyl_V(θ[k])) for k in 1:(length(θ) - 1))
        return (; θ, p, work, heat, θ_peak = θ[argmax(p)], p_peak = maximum(p))
    end

    const MBT_CYLINDER = let sparks = 20.0:0.5:55.0
        sparks[argmax([cylinder(σ).work for σ in sparks])]
    end
    spark_runs = (
        early = (σ = MBT_CYLINDER + 15, run = cylinder(MBT_CYLINDER + 15)),
        mbt = (σ = MBT_CYLINDER, run = cylinder(MBT_CYLINDER)),
        late = (σ = MBT_CYLINDER - 15, run = cylinder(MBT_CYLINDER - 15)),
        motored = cylinder(0; fired = false))
end

# ╔═╡ b04a2afc-0f7e-48f4-a442-a26a5b1e1b0a
# ╠═╡ card = "pressure-vs-crank"
let window = -60 .<= spark_runs.motored.θ .<= 90
    θ = spark_runs.motored.θ[window]
    bar(r) = round.(r.p[window] ./ 1e5; digits = 3)
    deg(σ) = isinteger(σ) ? string(Int(σ)) : string(σ)
    fired = ((spark_runs.early, "early", "#a75d00"), (spark_runs.mbt, "MBT", "#1f5fa8"),
        (spark_runs.late, "late", "#86b6ef"))
    traces = [PP.scatter(; x = θ, y = bar(spark_runs.motored), mode = "lines", name = "motored",
        line = PP.attr(width = 2, dash = "dash", color = "gray"),
        hovertemplate = "motored, %{x:.0f}°: %{y:.1f} bar<extra></extra>")]
    for (s, label, color) in fired
        name = "$label $(deg(s.σ))°"
        push!(traces, PP.scatter(; x = θ, y = bar(s.run), mode = "lines", name,
            line = PP.attr(; width = 3, color),
            hovertemplate = "$label, %{x:.0f}°: %{y:.1f} bar<extra></extra>"))
    end
    sparks = [s for (s, _, _) in fired]
    at(r, θq) = r.p[argmin(abs.(r.θ .- θq))] / 1e5
    push!(traces, PP.scatter(; x = [-s.σ for s in sparks], y = [round(at(s.run, -s.σ); digits = 3) for s in sparks],
        mode = "markers", marker = PP.attr(size = 11, color = "white", line = PP.attr(width = 2.5,
            color = [c for (_, _, c) in fired])),
        showlegend = false, hovertemplate = "spark at %{x:.1f}°<extra></extra>"))
    m = spark_runs.mbt.run
    PP.plot(traces, deck_layout(;
        xaxis = PP.attr(title = "crank angle [° after TDC]", range = [-60, 90], dtick = 15),
        yaxis = PP.attr(title = "pressure [bar]",
            range = [0, 10 * ceil(1.1 * spark_runs.early.run.p_peak / 1e6)]),
        margin = PP.attr(l = 70, r = 20, t = 76, b = 60),
        legend = PP.attr(orientation = "h", x = 0.5, xanchor = "center", y = 1.02, yanchor = "bottom",
            title = PP.attr(text = "spark, ° BTDC:")),
        shapes = [PP.attr(type = "line", x0 = 0, x1 = 0, yref = "paper", y0 = 0, y1 = 1,
            line = PP.attr(color = "gray", width = 1, dash = "dot"))],
        annotations = [PP.attr(x = m.θ_peak, y = m.p_peak / 1e5, ax = 80, ay = -6, xanchor = "left",
            text = "peak at $(round(m.θ_peak; digits = 1))° after TDC",
            font = PP.attr(color = "#1f5fa8"), arrowcolor = "#1f5fa8")]))
end

# ╔═╡ 10c1ba82-7ed5-4802-9297-62be020cde6e
let (e, m, l) = (spark_runs.early.run, spark_runs.mbt.run, spark_runs.late.run)
    @assert 12 <= m.θ_peak <= 20 "MBT's peak pressure must sit 12–20° after TDC, found $(m.θ_peak)°"
    @assert e.p_peak > m.p_peak > l.p_peak > spark_runs.motored.p_peak "peak pressure must fall with retard"
    @assert e.θ_peak < m.θ_peak < l.θ_peak "the peak must move later with retard"
    @assert m.work > max(e.work, l.work) "MBT must give the most work"
    md"""
    **MBT** at $(MBT_CYLINDER)° BTDC: peak $(round(m.p_peak / 1e5; digits = 1)) bar at
    $(round(m.θ_peak; digits = 1))° after TDC, gross indicated efficiency
    $(round(100m.work / m.heat; digits = 1)) %. **15° early** $(round(e.p_peak / 1e5; digits = 1)) bar at
    $(round(e.θ_peak; digits = 1))°; **15° late** $(round(l.p_peak / 1e5; digits = 1)) bar at
    $(round(l.θ_peak; digits = 1))°; **motored** $(round(spark_runs.motored.p_peak / 1e5; digits = 1)) bar.
    Each spark gives $(round(100e.work / m.work; digits = 1)) % and $(round(100l.work / m.work; digits = 1)) %
    of MBT's work.
    """
end

# ╔═╡ 23dce16c-5ebc-46e1-ba66-4889053b496d
md"""
## Torque and fuel consumption against λ

The slide after the emissions pairs them with torque and specific fuel consumption, over the same
λ axis and for the same four ignition angles, MBT at 50°, at the same relative load. The curves
come from `scripts/si_torque_trends.jl`, the structure task 2's `TorqueProduction` takes (lecture
plan S3, the MathWorks SI Core Engine's): inner torque scaled by a λ multiplier and a
spark-retard multiplier, then friction and pumping ``T_f`` taken off,

```math
T_e = \left(T_{e,0} + T_f\right) M_\sigma(\Delta\sigma)\,M_\lambda(\lambda)\,\min(1, 1/\lambda) - T_f,
\qquad M_\sigma = 1 - 0.0004\,\Delta\sigma^2 .
```

The air charge is held at the operating point: 3000 rpm (assumed) and half the full-load air
charge, which is the relative load 0.5 of the emission figure and
$(round(OP_DECK.p_m_kPa; digits = 1)) kPa on the hands-on engine's maps. At λ = 1 and MBT the
curves return those maps' torque and efficiency, $(round(OP_DECK.T_e; digits = 1)) N·m and
$(round(100OP_DECK.eta_b; digits = 1)) %; ``T_f`` is task 2's Barnes-Moss friction ×0.6 plus pumping. ``M_\lambda`` and
``M_\sigma`` are task 2's (assumed) shapes, so torque peaks rich and consumption is lowest lean by
construction. The curves are **idealized, drawn from textbook trends**.

The scan's lines lie closer together, because its MBT moves with λ; here MBT stays at 50° at
every λ, as in the emission model. The cylinder above puts MBT at this point at
$(MBT_CYLINDER)°, and the spark-advance map on slide 06.5 at
$(round(Int, Trends.sigma_mbt(RPM_DECK, OP_DECK.p_m_kPa)))°: the three are separate assumptions
until task 6 computes one.
"""

# ╔═╡ b04a2afc-0f7e-48f4-a442-a26a5b1e1b0b
# ╠═╡ card = "torque-bsfc-vs-lambda"
let
    colors = ("#86b6ef", "#3987e5", "#1c5cab", "#0d366b")
    dashes = ("solid", "dot", "dashdot", "dash")
    x = collect(LAMBDA_AXIS)
    runs = Dict(α => [Trends.brake(λ, α - SIGMA_MBT, OP_DECK) for λ in LAMBDA_AXIS] for α in ALPHA_Z)
    panels = ((:torque, "torque [N·m]", "N·m", [0, 80]), (:bsfc, "BSFC [g/kWh]", "g/kWh", [200, 700]))
    traces = [PP.scatter(; x, y = round.(getfield.(runs[α], q); digits = 2), mode = "lines",
                  name = "α<sub>z</sub> = $(α)°", legendgroup = "$α", showlegend = p == 1,
                  xaxis = "x$p", yaxis = "y$p",
                  line = PP.attr(width = 2.5, color = colors[a], dash = dashes[a]),
                  hovertemplate = "α<sub>z</sub> $(α)°, λ %{x:.2f}: %{y:.0f} $unit<extra></extra>")
              for (p, (q, _, unit, _)) in enumerate(panels) for (a, α) in enumerate(ALPHA_Z)]
    axes = Dict{Symbol, Any}()
    for (p, (_, title, _, range)) in enumerate(panels)
        top = p == 1 ? 1.0 : 0.46
        axes[Symbol("xaxis$p")] = Dict{Symbol, Any}(:range => [0.75, 1.4], :dtick => 0.1,
            :anchor => "y$p", :title => p == 2 ? "excess-air factor λ" : "",
            :showticklabels => p == 2)
        axes[Symbol("yaxis$p")] = Dict{Symbol, Any}(:domain => [top - 0.46, top], :range => range,
            :anchor => "x$p", :title => title)
    end
    axes[:xaxis1][:matches] = "x2"
    PP.plot(traces, deck_layout(;
        axes...,
        hovermode = "closest",
        margin = PP.attr(l = 70, r = 20, t = 40, b = 56),
        legend = PP.attr(orientation = "h", x = 0.5, xanchor = "center", y = 1.1)))
end

# ╔═╡ 92e1073d-c083-4677-b228-2aec37f9a435
let fine = 0.75:0.001:1.40
    at(α, λ) = Trends.brake(λ, α - SIGMA_MBT, OP_DECK)
    λ_torque = [fine[argmax([at(α, λ).torque for λ in fine])] for α in ALPHA_Z]
    λ_bsfc = [fine[argmin([at(α, λ).bsfc for λ in fine])] for α in ALPHA_Z]
    @assert all(0.85 .<= λ_torque .<= 0.90) "torque must peak rich, at λ 0.85–0.90: $λ_torque"
    @assert all(1.0 .< λ_bsfc .<= 1.15) "BSFC must be lowest lean, at λ 1.0–1.15: $λ_bsfc"
    @assert all(issorted([at(α, λ).torque for α in ALPHA_Z]) for λ in LAMBDA_AXIS) "advance up to MBT must raise torque at every λ"
    mbt = at(SIGMA_MBT, 1.0)
    @assert isapprox(mbt.torque, OP_DECK.T_e; rtol = 1e-9) "λ = 1 at MBT must return the map's torque"
    @assert isapprox(mbt.efficiency, OP_DECK.eta_b; rtol = 1e-9) "λ = 1 at MBT must return the map's efficiency"
    bsfc_min = [minimum(at(α, λ).bsfc for λ in fine) for α in ALPHA_Z]
    md"""
    At $(RPM_DECK) rpm and $(round(OP_DECK.p_m_kPa; digits = 1)) kPa, λ = 1 and MBT give
    $(round(mbt.torque; digits = 1)) N·m and $(round(Int, mbt.bsfc)) g/kWh
    (η $(round(100mbt.efficiency; digits = 1)) %). Torque peaks at λ $(λ_torque[end]) for every
    angle; BSFC is lowest at λ $(join(λ_bsfc, ", ")), $(join(round.(Int, bsfc_min), ", ")) g/kWh
    for α``_z`` $(join(ALPHA_Z, ", "))°. Ten degrees of retard cost
    $(round(100 * (1 - at(SIGMA_MBT - 10, 1.0).torque / mbt.torque); digits = 1)) % of the brake torque.
    """
end

# ╔═╡ 85aada20-329a-4835-bb86-06dffbb020b0
md"""
## What comes later

With Dyad task 6 (`Vehicle.Engine.SingleCylinder`, `SparkSweep`) this notebook fires the cycle:
a motored loop, the fired loop at MBT beside this ideal one, pressure against crank angle around
MBT in place of the few-line cylinder above, IMEP against spark advance at three speeds, the knock
proxy, and indicated against ideal efficiency. With Dyad task 2 (`MeanValueEngine` on
`EngineDyno`), a λ × spark sweep replaces the torque and fuel-consumption trends. The same cylinder with a burned-gas zone and Zeldovich kinetics then computes NOx
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
# ╟─f0dca466-d105-4443-8b28-e98da2485499
# ╠═888dda8d-5a7e-4625-8813-1c4c8ae3e51e
# ╠═b04a2afc-0f7e-48f4-a442-a26a5b1e1b0a
# ╠═10c1ba82-7ed5-4802-9297-62be020cde6e
# ╟─23dce16c-5ebc-46e1-ba66-4889053b496d
# ╠═b04a2afc-0f7e-48f4-a442-a26a5b1e1b0b
# ╠═92e1073d-c083-4677-b228-2aec37f9a435
# ╟─85aada20-329a-4835-bb86-06dffbb020b0
