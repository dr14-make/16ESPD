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

# ╔═╡ 326839a7-adb0-422c-9d8e-9ef49d8c4e81
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

# ╔═╡ 98446dd2-2a4b-4d0a-926d-55a6123b1f96
md"""
# Lecture 2 · 12 — The mapped engine

> **The hands-on engine is a set of measured tables and one state, the manifold pressure. This
> notebook reads both.**

The tables in `data/engine/` are the US EPA's ALPHA map of a 2014 Mazda 2.0 L Skyactiv, scaled
to a 1.5 L four-cylinder and re-gridded over engine speed `N` and manifold pressure `p_m`
(`data/engine/README.md` says how). The manifold pressure comes from `Engine.AirPath`, run here
through `Engine.AirPathTransient` with the throttle and the speed prescribed.

Every plot and table below is one the theory deck shows.
"""

# ╔═╡ d7ceb053-cfa4-463a-8be4-6e38c5d3f58e
begin
    const DATA = joinpath(@__DIR__, "..", "..", "data", "engine")

    """
        read_map(file) -> (; rpm, kpa, z)

    One `data/engine/` grid: `z[i, j]` is the value at `rpm[i]`, `kpa[j]`.
    """
    function read_map(file)
        lines = filter(!isempty, readlines(joinpath(DATA, file)))
        kpa = parse.(Float64, split(lines[1], ",")[2:end])
        rows = [parse.(Float64, split(l, ",")) for l in lines[2:end]]
        (; rpm = first.(rows), kpa, z = permutedims(reduce(hcat, [r[2:end] for r in rows])))
    end

    """
        read_curve(file) -> NamedTuple of columns

    A `data/engine/` file with one header row and numeric columns; rows at 0 rpm are dropped.
    """
    function read_curve(file)
        lines = filter(!isempty, readlines(joinpath(DATA, file)))
        names = Symbol.(split(lines[1], ","))
        rows = [parse.(Float64, split(l, ",")) for l in lines[2:end]]
        rows = filter(r -> r[1] > 0, rows)
        NamedTuple{Tuple(names)}(Tuple([r[k] for r in rows] for k in eachindex(names)))
    end

    # Plotly takes a matrix as a list of rows; `nothing` is a gap.
    rows_of(z) = [[isfinite(v) ? round(v; sigdigits = 5) : nothing for v in z[i, :]] for i in axes(z, 1)]

    deck_layout(; kwargs...) = PP.Layout(;
        template = PP.templates[:plotly_white],
        font = PP.attr(size = 15),
        margin = PP.attr(l = 70, r = 20, t = 30, b = 60),
        kwargs...)

    torque = read_map("torque_Nm.csv")
    fuel = read_map("fuel_gps.csv")
    lambda = read_map("lambda.csv")
    eta_v = read_map("eta_v.csv")
    full_load = read_curve("full_load.csv")
    @assert torque.rpm == fuel.rpm == lambda.rpm == eta_v.rpm && torque.kpa == fuel.kpa
end

# ╔═╡ 7380554f-fe79-40e1-86f5-2854bd0fb37f
md"""
## The torque map: what an ECU stores

Brake torque `T_e(N, p_m)` is the table the mapped engine reads every step. An ECU holds
hundreds of tables like it, each over two operating variables.
"""

# ╔═╡ 333fa2d4-7dd5-4243-95ee-951dd76d8d98
# ╠═╡ card = "torque-map"
PP.plot(
    PP.surface(; x = torque.kpa, y = torque.rpm, z = rows_of(torque.z),
        colorscale = "Viridis", showscale = false),
    deck_layout(;
        margin = PP.attr(l = 0, r = 0, t = 0, b = 0),
        scene = PP.attr(
            xaxis = PP.attr(title = "p_m [kPa]", dtick = 25),
            yaxis = PP.attr(title = "N [rpm]", dtick = 2000),
            zaxis = PP.attr(title = "T_e [N·m]", dtick = 50),
            camera = PP.attr(eye = PP.attr(x = 1.5, y = -1.6, z = 0.8)))))

# ╔═╡ 951025b0-6e13-4223-b802-7600f96078b9
md"""
## Brake efficiency

With the fuel map beside it, each cell of the torque map has an efficiency: the brake power over
the fuel's heat flow, `η_b = T_e ω / (ṁ_f H_l)`, with the lower heating value `H_l` = 43.4 MJ/kg
of gasoline (textbook). The contour is drawn over speed and torque, the way engine maps are
usually shown, by reading each speed row of the tables at fixed torques.
"""

# ╔═╡ 2000f351-1f93-4f0c-9670-8c5c83a379bc
begin
    const H_L = 43.4e6          # J/kg, gasoline lower heating value (textbook)
    rad_per_s(rpm) = rpm * π / 30

    power_W = torque.z .* rad_per_s.(torque.rpm)
    efficiency = [power_W[i, j] > 0 && fuel.z[i, j] > 0 ? power_W[i, j] / (fuel.z[i, j] / 1e3 * H_L) : NaN
        for i in axes(power_W, 1), j in axes(power_W, 2)]
    bsfc = 1e3 * 3600 ./ (efficiency .* H_L / 1e3) # g/kWh

    best = argmax(replace(efficiency, NaN => -Inf))
    peak = (; rpm = torque.rpm[best[1]], kpa = torque.kpa[best[2]], torque = torque.z[best],
        efficiency = efficiency[best], bsfc = bsfc[best])
end

# ╔═╡ 73ef85b6-2048-43e4-acde-b0ff92cc0483
begin
    """
    Linear interpolation of `y(x)` at `xq` over the rising part of a speed row, `NaN` outside it.
    """
    function along_row(x, y, xq)
        last_rise = something(findfirst(k -> x[k + 1] <= x[k], 1:(length(x) - 1)), length(x))
        x, y = x[1:last_rise], y[1:last_rise]
        (xq < x[1] || xq > x[end]) && return NaN
        k = clamp(searchsortedlast(x, xq), 1, length(x) - 1)
        y[k] + (y[k + 1] - y[k]) * (xq - x[k]) / (x[k + 1] - x[k])
    end

    torque_axis = 5.0:2.5:160.0
    efficiency_by_torque = [begin
            fired = findall(j -> torque.z[i, j] > 0 && isfinite(efficiency[i, j]), axes(torque.z, 2))
            length(fired) < 2 ? NaN : along_row(torque.z[i, fired], efficiency[i, fired], tq)
        end for tq in torque_axis, i in eachindex(torque.rpm)]
end

# ╔═╡ 9b595d42-0fac-4b4b-a8db-85c29494bdd6
# ╠═╡ card = "efficiency-map"
PP.plot(
    [
        PP.contour(; transpose = false, x = torque.rpm, y = collect(torque_axis), z = rows_of(100 .* efficiency_by_torque),
            contours = PP.attr(start = 10, size = 2, var"end" = 36, showlabels = true,
                labelfont = PP.attr(size = 12, color = "white")),
            colorscale = "Viridis", colorbar = PP.attr(title = "η_b [%]"), name = "η_b",
            hovertemplate = "%{x:.0f} rpm, %{y:.1f} N·m: %{z:.1f} %<extra></extra>"),
        PP.scatter(; x = full_load.rpm, y = full_load.torque_Nm, mode = "lines",
            line = PP.attr(color = "black", width = 3), name = "full load"),
        PP.scatter(; x = [peak.rpm], y = [peak.torque], mode = "markers+text",
            marker = PP.attr(symbol = "star", size = 18, color = "white", line = PP.attr(width = 1.5, color = "black")),
            text = ["$(round(100peak.efficiency; digits = 1)) % · $(round(Int, peak.bsfc)) g/kWh"],
            textposition = "top center", textfont = PP.attr(color = "white", size = 15),
            name = "best point"),
    ],
    deck_layout(; xaxis_title = "N [rpm]", yaxis_title = "T_e [N·m]", showlegend = false,
        yaxis_range = [0, 160]))

# ╔═╡ bebff999-e9b4-4bf6-9591-72288aaef549
let
    @assert 34 < 100peak.efficiency < 37 "peak brake efficiency $(100peak.efficiency) % outside 34–37 %"
    @assert 225 < peak.bsfc < 240 "minimum BSFC $(peak.bsfc) g/kWh outside 225–240 g/kWh"
    md"""
    **Best point:** $(round(100peak.efficiency; digits = 1)) % brake efficiency,
    $(round(peak.bsfc; digits = 1)) g/kWh, at $(round(Int, peak.rpm)) rpm,
    $(peak.kpa) kPa and $(round(peak.torque; digits = 1)) N·m.
    """
end

# ╔═╡ 082563ef-a482-497f-af0a-ef3d9c09a482
md"""
## Volumetric efficiency: the speed-density table

An ECU without an air-mass meter computes the air from the manifold pressure:
`ṁ_cyl = η_v(N, p_m) · p_m V_d N / (120 R T_m)`. `η_v` is the table it needs, and the air path
uses exactly this one. Idle sits low on it, at the pressure the air path settles to with the
throttle closed at 800 rpm; full load sits along the top.
"""

# ╔═╡ 6d5fdaed-1bde-4816-b0ca-eb4d357b7fc3
begin
    const AirPathTransient = library.Vehicle.Engine.AirPathTransient
    const IDLE_OMEGA = rad_per_s(800)

    idle_run = AirPathTransient(; u0 = 0.0, du = 0.0, omega = IDLE_OMEGA, p_m0 = 101325.0, stop = 3.0)
    p_idle = last(signal(idle_run, "air.p_m")[2])
end

# ╔═╡ 1c7df0d9-7f64-451a-8cfd-63e01f015776
# ╠═╡ card = "eta-v-map"
PP.plot(
    [
        PP.contour(; transpose = false, x = eta_v.rpm, y = eta_v.kpa, z = rows_of(permutedims(eta_v.z)),
            contours = PP.attr(start = 0.2, size = 0.1, var"end" = 1.0, showlabels = true,
                labelfont = PP.attr(size = 12, color = "white")),
            colorscale = "Viridis", colorbar = PP.attr(title = "η_v"), name = "η_v",
            hovertemplate = "%{x:.0f} rpm, %{y:.1f} kPa: %{z:.2f}<extra></extra>"),
        PP.scatter(; x = full_load.rpm, y = full_load.p_m_kPa, mode = "lines",
            line = PP.attr(color = "black", width = 3), name = "full load"),
        PP.scatter(; x = [800], y = [p_idle / 1e3], mode = "markers+text",
            marker = PP.attr(symbol = "circle", size = 14, color = "white", line = PP.attr(width = 2, color = "black")),
            text = ["idle $(round(p_idle / 1e3; digits = 1)) kPa"], textposition = "middle right",
            textfont = PP.attr(color = "white", size = 15), name = "idle"),
    ],
    deck_layout(; xaxis_title = "N [rpm]", yaxis_title = "p_m [kPa]", showlegend = false,
        yaxis_range = [10, 108]))

# ╔═╡ 145fede2-3fd9-4500-964d-df7e9858c984
let
    @assert 30e3 < p_idle < 36e3 "idle manifold pressure $(p_idle / 1e3) kPa outside 30–36 kPa"
    i800 = findfirst(==(750.0), eta_v.rpm)
    @assert 0.3 < along_row(eta_v.kpa, eta_v.z[i800, :], p_idle / 1e3) < 0.45 "η_v at idle outside 0.30–0.45"
end

# ╔═╡ 758ac07c-105b-4af3-8d96-b486ab82f60c
md"""
## Target air-fuel ratio

The fuel map is the air map divided by a target: `ṁ_f = ṁ_cyl / (AFR_s λ)` with
`AFR_s` = 14.6 (deck slide 23). `lambda.csv` holds λ = 1 below 85 % of the 95 kPa full-load
pressure and richens above it, deepest at high speed, to keep the exhaust valves and the
catalyst cool. The table shows every second speed row and the load columns around the step.
"""

# ╔═╡ d4bc26b6-c9c0-4caf-a10a-bebba7f7a894
begin
    const AFR_S = 14.6
    afr = AFR_S .* lambda.z

    "Green at stoichiometric, through yellow, to red at the richest cell of the map."
    function afr_color(a, richest)
        stops = ((0.0, (99, 190, 123)), (0.5, (255, 235, 132)), (1.0, (248, 105, 107)))
        x = clamp((AFR_S - a) / (AFR_S - richest), 0, 1)
        k = x <= 0.5 ? 1 : 2
        (x0, c0), (x1, c1) = stops[k], stops[k + 1]
        f = (x - x0) / (x1 - x0)
        "rgb($(join(round.(Int, c0 .+ f .* (c1 .- c0)), ",")))"
    end

    table_rpm = 1000.0:500.0:6500.0
    table_kpa = [30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 85.0, 90.0, 95.0, 100.0]
end

# ╔═╡ 010e344e-dba2-4890-a0a5-7b8969e578ba
# ╠═╡ card = "afr-table"
let
    richest = minimum(afr)
    rows = map(table_rpm) do n
        i = findfirst(==(n), lambda.rpm)
        cells = map(table_kpa) do p
            a = afr[i, findfirst(==(p), lambda.kpa)]
            """<td style="background:$(afr_color(a, richest))">$(round(a; digits = 1))</td>"""
        end
        "<tr><th>$(Int(n))</th>$(join(cells))</tr>"
    end
    head = join("<th>$(Int(p))</th>" for p in table_kpa)
    HTML("""
    <table class="afr-map">
    <thead><tr><th class="corner">rpm \\ kPa</th>$head</tr></thead>
    <tbody>$(join(rows, "\n"))</tbody>
    </table>
    <style>
    .afr-map { border-collapse: collapse; font-variant-numeric: tabular-nums; margin: 0 auto; }
    .afr-map th, .afr-map td { border: 1px solid #fff; padding: 0.15em 0.55em; text-align: center; }
    .afr-map td { color: #222; }
    .afr-map thead th { border-bottom: 2px solid #888; }
    .afr-map tbody th { border-right: 2px solid #888; text-align: right; }
    .afr-map .corner { font-weight: normal; font-size: 0.8em; }
    </style>
    """)
end

# ╔═╡ ca810a8b-4689-4e00-adaf-2ab50f7853ae
let
    below = lambda.kpa .< 0.85 * 95
    @assert all(lambda.z[:, below] .== 1) "λ must be 1 below 85 % of 95 kPa"
    @assert 0.78 < minimum(lambda.z) < 0.82 "richest λ $(minimum(lambda.z)) outside 0.78–0.82"
    i_low, i_high = findfirst(==(1500.0), lambda.rpm), findfirst(==(6000.0), lambda.rpm)
    @assert lambda.z[i_high, end] < lambda.z[i_low, end] "enrichment must deepen with speed"
end

# ╔═╡ ffdf7f3a-25d1-4153-9b1b-ff1ab9c7198f
md"""
## Base pulse width

The base pulse width is the fuel for one cylinder's cycle over the injector's static flow. A
four-stroke cylinder fires once every two revolutions, so with `n_cyl` = 4 injectors
`t_base = ṁ_f · 120 / (n_cyl N q_inj)`. The injector is a Bosch EV14 at its smallest
listed flow, 146 cm³/min at 3 bar (Bosch), with gasoline at 740 kg/m³ (textbook). The dashed
line is where the pulse fills the whole cycle, 720° of crank: beyond it this injector cannot
deliver the fuel.
"""

# ╔═╡ bb78386e-5f89-4fbe-a854-45a41ee72d9d
begin
    const N_CYL = 4
    const RHO_F = 740.0                     # kg/m³ (textbook)
    const Q_INJ = 146e-6 / 60 * RHO_F * 1e3 # g/s, Bosch EV14 146 cm³/min

    pulse_ms = [1e3 * fuel.z[i, j] * 120 / (N_CYL * fuel.rpm[i] * Q_INJ)
        for i in eachindex(fuel.rpm), j in eachindex(fuel.kpa)]
    duty = pulse_ms ./ (1e3 .* 120 ./ fuel.rpm)
    idle_pulse = pulse_ms[findfirst(==(750.0), fuel.rpm), findfirst(==(32.5), fuel.kpa)]
end

# ╔═╡ b0772b75-aec0-4f15-894d-5654974d3dfd
# ╠═╡ card = "pulse-width-map"
PP.plot(
    [
        PP.contour(; transpose = false, x = fuel.rpm, y = fuel.kpa, z = rows_of(permutedims(pulse_ms)),
            contours = PP.attr(start = 2, size = 2, var"end" = 30, showlabels = true,
                labelfont = PP.attr(size = 12, color = "white")),
            colorscale = "Viridis", colorbar = PP.attr(title = "t_base [ms]"), name = "t_base",
            hovertemplate = "%{x:.0f} rpm, %{y:.1f} kPa: %{z:.2f} ms<extra></extra>"),
        PP.contour(; transpose = false, x = fuel.rpm, y = fuel.kpa, z = rows_of(permutedims(duty)),
            contours = PP.attr(start = 1, var"end" = 1, size = 1, coloring = "none",
                showlabels = true, labelfont = PP.attr(size = 13, color = "white")),
            line = PP.attr(color = "white", width = 3, dash = "dash"), showscale = false,
            name = "720° crank", hoverinfo = "skip"),
    ],
    deck_layout(; xaxis_title = "N [rpm]", yaxis_title = "p_m [kPa]", showlegend = false,
        yaxis_range = [10, 105]))

# ╔═╡ af4001c8-4262-4d76-96fe-7394584cdff5
let
    @assert 1.5 < idle_pulse < 4 "idle base pulse $(idle_pulse) ms outside 1.5–4 ms"
    md"""
    **Idle** (750 rpm, 32.5 kPa): $(round(idle_pulse; digits = 2)) ms. **Longest pulse**:
    $(round(maximum(pulse_ms); digits = 1)) ms, $(round(100maximum(duty))) % of the cycle.
    """
end

# ╔═╡ 08300fe9-e21d-409b-add0-5ff6345312cc
md"""
## What a mass-air-flow meter sees on a tip-in

A MAF sits upstream of the throttle, so it reads the throttle flow `ṁ_thr`, not the flow into
the cylinders `ṁ_cyl`. When the throttle snaps open at 3000 rpm, air rushes in to fill the
manifold: the throttle flow overshoots while `p_m` rises, then both settle to the same value.
This is the air path's own tip-in case, run from the overrun pressure.
"""

# ╔═╡ 527a998a-85e2-4ad0-a890-b4beef7b285c
begin
    const TIP_IN_OMEGA = rad_per_s(3000)
    overrun = AirPathTransient(; u0 = 0.0, du = 0.0, omega = TIP_IN_OMEGA, p_m0 = p_idle, stop = 2.0)
    p_overrun = last(signal(overrun, "air.p_m")[2])
    tip_in = AirPathTransient(; u0 = 0.0, du = 1.0, t_step = 0.5, omega = TIP_IN_OMEGA,
        p_m0 = p_overrun, stop = 2.0)
    tip_t, mdot_thr = signal(tip_in, "air.mdot_thr")
    _, mdot_cyl = signal(tip_in, "air.mdot_cyl")
end

# ╔═╡ cf7793ee-6c23-45a7-8810-9d5a64c644b0
# ╠═╡ card = "maf-tip-in"
let window = findall(t -> 0.45 <= t <= 0.75, tip_t)
    ms = round.(1e3 .* (tip_t[window] .- 0.5); digits = 1)
    PP.plot(
        [
            PP.scatter(; x = ms, y = round.(1e3 .* mdot_thr[window]; sigdigits = 5), mode = "lines",
                name = "ṁ_thr (what a MAF reads)", line = PP.attr(width = 3)),
            PP.scatter(; x = ms, y = round.(1e3 .* mdot_cyl[window]; sigdigits = 5), mode = "lines",
                name = "ṁ_cyl (into the cylinders)", line = PP.attr(width = 3, dash = "dash")),
        ],
        deck_layout(; xaxis_title = "time after the throttle opens [ms]", yaxis_title = "air flow [g/s]",
            legend = PP.attr(x = 0.98, xanchor = "right", y = 0.5)))
end

# ╔═╡ 2400138b-ca84-4c0c-9b71-6cb01e401786
let
    peak_thr, settled = maximum(mdot_thr), mdot_thr[end]
    @assert peak_thr > 2settled "throttle flow overshoot $(peak_thr / settled)× below 2×"
    @assert isapprox(settled, mdot_cyl[end]; rtol = 0.01) "throttle and cylinder flow must settle together"
    md"""
    **Peak throttle flow** $(round(1e3peak_thr; digits = 0)) g/s against **settled**
    $(round(1e3settled; digits = 1)) g/s: $(round(peak_thr / settled; digits = 1))× overshoot.
    """
end

# ╔═╡ f6258036-ffb4-4634-b197-46259212d338
md"""
## Lecture 1's lag, from physics

Lecture 1's `IdealEngine` put a fixed 0.3 s first-order lag between the torque command and the
torque. In the mapped engine the lag is the manifold filling, and its time constant is not fixed:
it shortens as the cylinders pump faster. Below, a small throttle step at 800 rpm (idle) and at
3000 rpm held at the same manifold pressure, so speed is the only difference, normalized to
their final rise, beside the `IdealEngine` lag.
"""

# ╔═╡ 25721990-70aa-475c-87fe-4e42f2db9fe0
begin
    """
        lag_step(omega, u0) -> (; t, y, tau, p_before)

    A small throttle step from a settled manifold: `y` is `p_m` normalized to its rise, `tau`
    the time to 63 % of it.
    """
    function lag_step(omega, u0; du = 0.005, t_step = 1.0)
        run = AirPathTransient(; u0, du, t_step, omega, p_m0 = p_idle, stop = t_step + 1.0)
        t, p = signal(run, "air.p_m")
        before = p[findlast(<=(t_step), t)]
        y = (p .- before) ./ (p[end] - before)
        k = findfirst(i -> t[i] > t_step && y[i] >= 1 - exp(-1), eachindex(t))
        tau = t[k - 1] + (1 - exp(-1) - y[k - 1]) / (y[k] - y[k - 1]) * (t[k] - t[k - 1]) - t_step
        after = t .>= t_step
        (; t = t[after] .- t_step, y = y[after], tau, p_before = before)
    end

    # Throttle that holds 3000 rpm at the idle manifold pressure, found by bisection on this model.
    const U_HOLD_3000 = 0.0547

    step_800 = lag_step(IDLE_OMEGA, 0.0)
    step_3000 = lag_step(rad_per_s(3000), U_HOLD_3000)

    "The default of parameter `name` in a library component, read without compiling it."
    default_value(component, name) = ModelingToolkit.SymbolicUtils.unwrap_const(
        only(v for (k, v) in initial_conditions(component(; name = :c)) if string(k) == name))

    tau_e = default_value(library.Vehicle.IdealEngine, "tau_e")
end

# ╔═╡ 8fdf831b-1afd-4c71-bad7-bc71adfb15e8
# ╠═╡ card = "manifold-lag"
let
    t_lag = collect(0.0:0.005:1.0)
    trace(s, label) = PP.scatter(; x = s.t, y = round.(s.y; digits = 4), mode = "lines",
        name = "$label, τ = $(round(s.tau; digits = 3)) s", line = PP.attr(width = 3))
    PP.plot(
        [
            trace(step_800, "800 rpm"),
            trace(step_3000, "3000 rpm"),
            PP.scatter(; x = t_lag, y = round.(1 .- exp.(-t_lag ./ tau_e); digits = 4), mode = "lines",
                name = "Lecture 1 IdealEngine, τ = $(tau_e) s",
                line = PP.attr(width = 3, dash = "dash", color = "gray")),
        ],
        deck_layout(; xaxis_title = "time after the throttle step [s]",
            yaxis_title = "p_m, normalized", xaxis_range = [0, 1], yaxis_range = [0, 1.05],
            legend = PP.attr(x = 0.98, xanchor = "right", y = 0.05, yanchor = "bottom")))
end

# ╔═╡ 564eecb3-f824-4049-94eb-fc7f15aee140
let
    @assert 0.12 < step_800.tau < 0.18 "τ at 800 rpm $(step_800.tau) s outside 0.12–0.18 s"
    @assert 0.025 < step_3000.tau < 0.045 "τ at 3000 rpm $(step_3000.tau) s outside 0.025–0.045 s"
    @assert abs(step_3000.p_before - p_idle) < 500 "3000 rpm step must start at the idle pressure"
    md"""
    **τ at 800 rpm** $(round(step_800.tau; digits = 3)) s, **at 3000 rpm**
    $(round(step_3000.tau; digits = 3)) s, both from $(round(p_idle / 1e3; digits = 1)) kPa.
    """
end

# ╔═╡ 5255ee46-e805-48c1-9389-da90b2ca8392
md"""
## What comes later

The mapped engine itself (mapped-engine tasks 3 and 4) adds the cells that run it: torque and
fuel through a coast-down with fuel cut-off, and the fuel and CO₂ of steady cruises at 50, 90 and
130 km/h. Notebook 09 overlays the `HotFilmMAF` sensor on the tip-in trace.
"""

# ╔═╡ Cell order:
# ╠═326839a7-adb0-422c-9d8e-9ef49d8c4e81
# ╟─98446dd2-2a4b-4d0a-926d-55a6123b1f96
# ╠═d7ceb053-cfa4-463a-8be4-6e38c5d3f58e
# ╟─7380554f-fe79-40e1-86f5-2854bd0fb37f
# ╠═333fa2d4-7dd5-4243-95ee-951dd76d8d98
# ╟─951025b0-6e13-4223-b802-7600f96078b9
# ╠═2000f351-1f93-4f0c-9670-8c5c83a379bc
# ╠═73ef85b6-2048-43e4-acde-b0ff92cc0483
# ╠═9b595d42-0fac-4b4b-a8db-85c29494bdd6
# ╠═bebff999-e9b4-4bf6-9591-72288aaef549
# ╟─082563ef-a482-497f-af0a-ef3d9c09a482
# ╠═6d5fdaed-1bde-4816-b0ca-eb4d357b7fc3
# ╠═1c7df0d9-7f64-451a-8cfd-63e01f015776
# ╠═145fede2-3fd9-4500-964d-df7e9858c984
# ╟─758ac07c-105b-4af3-8d96-b486ab82f60c
# ╠═d4bc26b6-c9c0-4caf-a10a-bebba7f7a894
# ╠═010e344e-dba2-4890-a0a5-7b8969e578ba
# ╠═ca810a8b-4689-4e00-adaf-2ab50f7853ae
# ╟─ffdf7f3a-25d1-4153-9b1b-ff1ab9c7198f
# ╠═bb78386e-5f89-4fbe-a854-45a41ee72d9d
# ╠═b0772b75-aec0-4f15-894d-5654974d3dfd
# ╠═af4001c8-4262-4d76-96fe-7394584cdff5
# ╟─08300fe9-e21d-409b-add0-5ff6345312cc
# ╠═527a998a-85e2-4ad0-a890-b4beef7b285c
# ╠═cf7793ee-6c23-45a7-8810-9d5a64c644b0
# ╠═2400138b-ca84-4c0c-9b71-6cb01e401786
# ╟─f6258036-ffb4-4634-b197-46259212d338
# ╠═25721990-70aa-475c-87fe-4e42f2db9fe0
# ╠═8fdf831b-1afd-4c71-bad7-bc71adfb15e8
# ╠═564eecb3-f824-4049-94eb-fc7f15aee140
# ╟─5255ee46-e805-48c1-9389-da90b2ca8392
