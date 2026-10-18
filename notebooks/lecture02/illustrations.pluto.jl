### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# ╔═╡ 7635b61c-86fb-4a32-99de-86a0c84a2c00
begin
    import Pkg
    Pkg.activate(joinpath(@__DIR__, "..", ".."))

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

    import PlutoPlotly as PP
end

# ╔═╡ 88324f20-40ae-4205-872b-e284cfea7231
md"""
# Lecture 2 · Illustrations

> **Idealized characteristics, drawn from explicit curves, for the slides whose source pictures
> are scans.**

Nothing here is simulated. Every curve is a hand-written function or a table read from a
datasheet, chosen to show the shape a slide talks about. Where a curve stands for a real part,
the cell says which one and where its numbers come from.
"""

# ╔═╡ fe0c7b71-22dc-487d-8b16-3e5338bb7c35
begin
    # The deck's diagram palette (slides/decks/*/public/diagrams/*.svg): ink, muted ink, accent
    # and warning. The blues ramp from the accent, dark to light, for ordered series.
    const INK = "#16202c"
    const MUTED = "#4a5a6b"
    const ACCENT = "#1f5fa8"
    const WARN = "#a75d00"
    const BLUES = ["#0d3263", "#1f5fa8", "#3d7cc0", "#6497cf", "#8cb0dc"]
    const FONT = "Avenir Next, Nunito Sans, ui-sans-serif, system-ui, sans-serif"

    "Axis styling as a plain `Dict`, so it can be merged into a subplot axis without losing its domain."
    axis(title; kwargs...) = Dict{Symbol, Any}(:showline => true, :linecolor => MUTED,
        :linewidth => 1, :ticks => "outside", :tickcolor => MUTED, :gridcolor => "#e6e9ed",
        :zeroline => false, :title => Dict(:text => title, :standoff => 6), kwargs...)

    deck_layout(; kwargs...) = PP.Layout(;
        template = PP.templates[:plotly_white],
        font = PP.attr(; family = FONT, size = 15, color = INK),
        margin = PP.attr(l = 80, r = 20, t = 30, b = 60),
        kwargs...)

    line(color; width = 3, kwargs...) = PP.attr(; color, width, kwargs...)
end

# ╔═╡ e3db3aee-e2bc-444b-a63c-0af24549c725
md"""
## Sensor classification

One panel per entry in the slide's list. The top row is the **characteristic curve**, output
signal `S` against measured variable `X`; the bottom row is the **type of output signal**
against time.

- *Continuous, linear*: a throttle potentiometer, 0.5 V closed to 4.5 V at 90°, the usual span
  on a 5 V supply. Idealized: no dead band, no wear.
- *Continuous, non-linear*: the Bosch Motorsport NTC M12, its ten datasheet points, joined by
  straight lines in `ln R` between neighbors.
- *Discontinuous*: a switching (two-step) λ sensor, about 0.9 V rich and 0.1 V lean with the
  jump at λ = 1. Idealized as a steep tanh step, the one the λ figures below use too.
- *Amplitude*: the potentiometer's voltage through a tip-in, 10° to 60° in 0.2 s.
- *Frequency*: a Hall wheel-speed sensor on a 48-tooth ring, the wheel accelerating from about
  30 to 60 km/h, so the pulse rate rises from 200 to 400 Hz. Compressed in time to show it.
- *Pulse duration*: a fixed 100 Hz carrier whose duty cycle carries the value, here falling from
  80 % to 20 %.
"""

# ╔═╡ ae73992e-135c-425f-84c1-e95e9bf9a229
begin
    const NOTES = joinpath(@__DIR__, "..", "..", "docs", "research_notes",
        "Engine control systems", "teaching_materials.md")

    "The Bosch NTC M12 resistance table, as `teaching_materials.md` transcribes the datasheet."
    function ntc_m12()
        row = only(filter(l -> occursin("Bosch NTC M12", l), readlines(NOTES)))
        table = match(r"R\(T\):(.*?)\. Accuracy", row)[1]
        pairs = map(split(table, ";")) do entry
            numbers = [parse(Float64, replace(m.match, "−" => "-", "," => ""))
                for m in eachmatch(r"−?[\d,]+", replace(entry, "**" => ""))]
            numbers[1] => numbers[2]
        end
        (; T_C = first.(pairs), R_ohm = last.(pairs))
    end

    ntc = ntc_m12()

    "Linear interpolation of `ln R` between datasheet neighbors."
    function ntc_R(T)
        k = clamp(searchsortedlast(ntc.T_C, T), 1, length(ntc.T_C) - 1)
        T0, T1 = ntc.T_C[k], ntc.T_C[k + 1]
        exp(log(ntc.R_ohm[k]) + (T - T0) / (T1 - T0) * (log(ntc.R_ohm[k + 1]) - log(ntc.R_ohm[k])))
    end

    tps_V(angle_deg) = 0.5 + 4.0 * angle_deg / 90
    "Switching λ sensor voltage, task 5's `LambdaSensorSwitching` without its lag (deck slide 58)."
    lambda_V(λ) = 0.1 + 0.4 * (1 + tanh((1 - λ) / 0.005))

    """
        square(edges, duty) -> (t, u)

    A 0/1 pulse train as step-line vertices: one period from each edge to the next, high for
    `duty(k)` of period `k`.
    """
    function square(edges, duty)
        t, u = Float64[], Float64[]
        for k in 1:(length(edges) - 1)
            t0, T = edges[k], edges[k + 1] - edges[k]
            append!(t, (t0, t0 + duty(k) * T))
            append!(u, (1.0, 0.0))
        end
        push!(t, edges[end])
        push!(u, 0.0)
        t, u
    end

    # Hall wheel speed: frequency ramps linearly 200 → 400 Hz over 50 ms; edges where the
    # accumulated phase f0 t + ½ ḟ t² crosses each whole tooth.
    hall_edges = let f0 = 200.0, f1 = 400.0, T = 0.05
        a = (f1 - f0) / T
        n = floor(Int, f0 * T + a * T^2 / 2)
        [(-f0 + sqrt(f0^2 + 2a * k)) / a for k in 0:n]
    end
    hall = square(hall_edges, k -> 0.5)

    pwm_edges = collect(0.0:0.010:0.100)
    pwm_duty(k) = 0.8 - 0.6 * (k - 1) / (length(pwm_edges) - 2)
    pwm = square(pwm_edges, pwm_duty)
end

# ╔═╡ 7d59eb8b-81be-41d9-9f57-b4bad7e95e1c
# ╠═╡ card = "sensor-classification"
let
    titles = ["continuous, linear", "continuous, non-linear", "discontinuous",
        "amplitude", "frequency", "pulse duration"]
    p = PP.make_subplots(; rows = 2, cols = 3, subplot_titles = reshape(titles, 1, :),
        horizontal_spacing = 0.11, vertical_spacing = 0.26)

    angle = collect(0.0:1.0:90.0)
    PP.add_trace!(p, PP.scatter(; x = angle, y = tps_V.(angle), mode = "lines",
        line = line(ACCENT), name = "throttle potentiometer"); row = 1, col = 1)

    T = collect(-40.0:1.0:130.0)
    PP.add_trace!(p, PP.scatter(; x = T, y = round.(ntc_R.(T) ./ 1000; sigdigits = 4),
        mode = "lines", line = line(ACCENT), name = "NTC M12"); row = 1, col = 2)
    PP.add_trace!(p, PP.scatter(; x = ntc.T_C, y = ntc.R_ohm ./ 1000, mode = "markers",
        marker = PP.attr(; size = 8, color = INK), name = "NTC M12 datasheet"); row = 1, col = 2)

    λ = collect(0.95:0.0005:1.05)
    PP.add_trace!(p, PP.scatter(; x = λ, y = round.(lambda_V.(λ); digits = 4), mode = "lines",
        line = line(ACCENT), name = "two-step λ sensor"); row = 1, col = 3)

    t = collect(0.0:0.005:1.0)
    tip_in(t) = 10 + 50 * clamp((t - 0.3) / 0.2, 0, 1)
    PP.add_trace!(p, PP.scatter(; x = t, y = tps_V.(tip_in.(t)), mode = "lines",
        line = line(ACCENT), name = "potentiometer voltage"); row = 2, col = 1)

    PP.add_trace!(p, PP.scatter(; x = round.(hall[1] .* 1000; digits = 4), y = 5 .* hall[2],
        mode = "lines", line = line(ACCENT; width = 2, shape = "hv"), name = "Hall output");
        row = 2, col = 2)

    PP.add_trace!(p, PP.scatter(; x = round.(pwm[1] .* 1000; digits = 4), y = 5 .* pwm[2],
        mode = "lines", line = line(ACCENT; width = 2, shape = "hv"), name = "PWM output");
        row = 2, col = 3)

    PP.relayout!(p; template = PP.templates[:plotly_white],
        font = PP.attr(; family = FONT, size = 15, color = INK), showlegend = false,
        margin = PP.attr(l = 60, r = 16, t = 56, b = 52))
    axes = (
        xaxis = axis("throttle angle [°]"; dtick = 30),
        yaxis = axis("voltage [V]"; range = [0, 5]),
        xaxis2 = axis("temperature [°C]"; dtick = 40),
        yaxis2 = axis("resistance [kΩ]"; range = [0, 50]),
        xaxis3 = axis("λ"; dtick = 0.05),
        yaxis3 = axis("voltage [V]"; range = [0, 1]),
        xaxis4 = axis("time [s]"; dtick = 0.5),
        yaxis4 = axis("voltage [V]"; range = [0, 5]),
        xaxis5 = axis("time [ms]"; dtick = 25),
        yaxis5 = axis("voltage [V]"; range = [-0.3, 5.5], dtick = 5),
        xaxis6 = axis("time [ms]"; dtick = 50),
        yaxis6 = axis("voltage [V]"; range = [-0.3, 5.5], dtick = 5))
    for (name, style) in pairs(axes)
        merge!(p.Plot.layout[name], style)
    end
    for a in p.Plot.layout.annotations
        a[:font] = PP.attr(; size = 16, color = INK)
    end
    p
end

# ╔═╡ 1ce08079-23cd-438d-8214-79ebc6ecea59
let
    @assert ntc.R_ohm[ntc.T_C .== 20.0] == [2500.0] "R(20 °C) must read 2500 Ω"
    @assert all(ntc_R.(ntc.T_C) .≈ ntc.R_ohm) "the NTC line must pass through every datasheet point"
    @assert lambda_V(0.98) > 0.8 && lambda_V(1.02) < 0.15 "the λ sensor must switch within ±2 %"
    @assert 9 <= length(hall_edges) - 1 <= 16 "the wheel-speed panel should show 9–16 pulses"
    md"""
    **NTC M12** $(round(Int, maximum(ntc.R_ohm))) Ω at $(round(Int, minimum(ntc.T_C))) °C to
    $(round(Int, minimum(ntc.R_ohm))) Ω at $(round(Int, maximum(ntc.T_C))) °C.
    **Wheel-speed pulses** $(length(hall_edges) - 1) in 50 ms.
    """
end

# ╔═╡ 92c0fdf5-76b3-4fa4-8002-5df10c824489
md"""
## Rolling resistance against speed and tire pressure

The engineeringtoolbox.com chart the source deck carried is a plot of one empirical fit for car
tires on dry asphalt,

```math
f = 0.005 + \frac{1}{p}\left(0.01 + 0.0095\left(\frac{v}{100}\right)^2\right),
```

with `p` the tire pressure in bar and `v` the speed in km/h. Drawing the fit itself gives the
same five curves with nothing scanned. It is a fit, valid from about 10 to 140 km/h; Lecture 1's
constant 0.012 sits on the 2–3 bar curves at town speeds.
"""

# ╔═╡ 3948eff6-60d0-44f7-8b26-9653dd89565d
rolling_f(v_kmh, p_bar) = 0.005 + (0.01 + 0.0095 * (v_kmh / 100)^2) / p_bar

# ╔═╡ c641e16a-e6dd-4c36-96cd-51ac4e0614bf
# ╠═╡ card = "rolling-vs-speed"
let v = collect(10.0:2.0:140.0), pressures = [1.0, 1.5, 2.0, 3.0, 4.0]
    label(p) = "$(isinteger(p) ? Int(p) : p) bar"
    traces = [PP.scatter(; x = v, y = round.(rolling_f.(v, p); digits = 6), mode = "lines",
                  name = label(p), line = line(BLUES[k]))
              for (k, p) in enumerate(pressures)]
    ends = [PP.attr(; x = 140, y = rolling_f(140, p), xanchor = "left", text = label(p),
                showarrow = false, xshift = 6, font = PP.attr(; color = INK))
            for p in pressures]
    PP.plot(traces, deck_layout(;
        showlegend = false,
        margin = PP.attr(l = 80, r = 64, t = 30, b = 60),
        annotations = ends,
        xaxis = axis("speed [km/h]"; range = [0, 145], dtick = 20),
        yaxis = axis("rolling resistance coefficient f [–]";
            range = [0, 0.036], dtick = 0.005, tickformat = ".3f")))
end

# ╔═╡ 8f2346ea-1348-45c6-8f57-d4c8e5015409
let
    @assert isapprox(rolling_f(100, 2), 0.01475; atol = 1e-9) "the fit reads 0.01475 at 2 bar, 100 km/h"
    @assert isapprox(rolling_f(140, 1), 0.03362; atol = 1e-5) "the fit reads about 0.034 at 1 bar, 140 km/h"
    ratio = rolling_f(10, 1) / rolling_f(10, 3)
    md"""
    **At 10 km/h** 1 bar gives $(round(ratio; digits = 2)) × the coefficient at 3 bar; **at
    140 km/h** $(round(rolling_f(140, 1) / rolling_f(140, 3); digits = 2)) ×.
    """
end

# ╔═╡ 4847d6cb-f506-4620-b8dd-df28fe29b1fe
md"""
## Engine and ignition slides: interim figures

These stand in for scanned plots on Lecture 2's engine, ignition and λ slides until the Dyad
models can draw them. Each is **idealized, drawn from textbook trends**: explicit functions with
every coefficient tagged (textbook) or (assumed), never a run of a Dyad model. Each section names
the Dyad task whose model replaces its figure; the slide then changes one `<CardExport>` line.

Torque and efficiency come from `scripts/si_torque_trends.jl`, the form task 2's
`TorqueProduction` takes (lecture plan S3), anchored on the hands-on engine's maps in
`data/engine/`. Notebook 02 draws slide 52's torque and fuel consumption from the same module.
"""

# ╔═╡ cb4510f1-3f0c-48d1-9463-c80c37a075dc
const Trends = include(joinpath(@__DIR__, "..", "..", "scripts", "si_torque_trends.jl"))

# ╔═╡ 7a0e2e3f-22f0-4c98-a767-ab72a9815758
md"""
### Power and efficiency against the mixture (slide 02.6)

At the hands-on engine's best point, 3000 rpm and 77.5 kPa (99 N·m and 35.7 % at λ = 1, the star
on the efficiency map), the air charge is held and the fuel varied. Power follows the inner
torque ``M_\lambda(\lambda)\,\min(1, 1/\lambda)`` less friction; efficiency divides the same
torque by the fuel. Rich, the fuel that finds no oxygen is wasted; lean, all of it burns, but in
less charge. ``M_\lambda`` is task 2's shape (assumed): 1.03 at λ 0.88, 1 at λ 1, 1.04 at λ 1.1.

Replaced by: Dyad task 2, a λ sweep of `MeanValueEngine` on `EngineDyno` (notebook 03).
"""

# ╔═╡ 89b9520e-51b4-4935-9306-54c576ef875c
# ╠═╡ card = "power-efficiency-vs-afr"
let op = Trends.map_point(3000, 77.5), afr_s = 14.6
    afr = collect(10.0:0.05:20.0)
    runs = [Trends.brake(a / afr_s, 0, op) for a in afr]
    power, eff = getfield.(runs, :power), getfield.(runs, :efficiency)
    ip, ie, i1 = argmax(power), argmax(eff), argmin(abs.(afr .- afr_s))
    pct(y) = round.(100 .* y ./ maximum(y); digits = 2)
    peak(i, y, text, color, ax, xanchor) = PP.attr(; x = afr[i], y = pct(y)[i], text, ax,
        ay = -30, xanchor, arrowcolor = color, font = PP.attr(; color))
    label(a, y, text, color) = PP.attr(; x = a, y = pct(y)[argmin(abs.(afr .- a))], text,
        showarrow = false, xanchor = "right", yshift = 14, font = PP.attr(; color))
    λ_ticks = 0.7:0.1:1.3
    traces = [
        PP.scatter(; x = afr, y = pct(power), mode = "lines", name = "power", line = line(ACCENT),
            customdata = round.(power ./ 1e3; digits = 2),
            hovertemplate = "AFR %{x:.1f}: %{y:.1f} % of max power, %{customdata:.1f} kW<extra></extra>"),
        PP.scatter(; x = afr, y = pct(eff), mode = "lines", name = "brake efficiency",
            line = line(WARN), customdata = round.(100 .* eff; digits = 2),
            hovertemplate = "AFR %{x:.1f}: %{y:.1f} % of max efficiency, η = %{customdata:.1f} %<extra></extra>"),
        PP.scatter(; x = [afr[ip], afr[ie], afr_s], y = [100, 100, pct(eff)[i1]],
            mode = "markers", marker = PP.attr(; size = 9, color = [ACCENT, WARN, INK]),
            showlegend = false, hoverinfo = "skip"),
        PP.scatter(; x = [10, 20], y = [nothing, nothing], xaxis = "x2", showlegend = false,
            hoverinfo = "skip"),
    ]
    PP.plot(traces, deck_layout(;
        margin = PP.attr(l = 70, r = 20, t = 60, b = 60),
        showlegend = false,
        xaxis = axis("air-fuel ratio [kg/kg]"; range = [10, 20], dtick = 1),
        xaxis2 = axis("λ"; overlaying = "x", side = "top", range = [10, 20],
            tickvals = round.(afr_s .* λ_ticks; digits = 3), ticktext = string.(λ_ticks)),
        yaxis = axis("% of maximum"; range = [55, 117], tickvals = 60:10:100),
        shapes = [PP.attr(; type = "line", x0 = afr_s, x1 = afr_s, y0 = 55, y1 = 117,
            line = PP.attr(; color = MUTED, width = 1.5, dash = "dot"))],
        annotations = [
            peak(ip, power, "max power, λ $(round(afr[ip] / afr_s; digits = 2))", ACCENT, 10, "right"),
            peak(ie, eff, "max efficiency, λ $(round(afr[ie] / afr_s; digits = 2))", WARN, -10, "left"),
            label(19.6, power, "power", ACCENT),
            label(19.6, eff, "brake efficiency", WARN),
            PP.attr(; x = afr_s, y = pct(eff)[i1], ax = -15, ay = 110, xanchor = "right",
                text = "λ = 1: η = $(round(100 * op.eta_b; digits = 1)) %",
                arrowcolor = INK, font = PP.attr(; size = 13, color = INK))]))
end

# ╔═╡ ee5941f2-1f3c-4ec4-9e18-2fbe5efbe221
let op = Trends.map_point(3000, 77.5), λ = 0.65:0.001:1.40
    runs = [Trends.brake(l, 0, op) for l in λ]
    λ_power = λ[argmax(getfield.(runs, :power))]
    λ_eff = λ[argmax(getfield.(runs, :efficiency))]
    η_1 = Trends.brake(1.0, 0, op).efficiency
    η_max = maximum(getfield.(runs, :efficiency))
    @assert 0.85 <= λ_power <= 0.90 "power must peak rich, at λ 0.85–0.90; found $λ_power"
    @assert 1.05 <= λ_eff <= 1.10 "efficiency must peak lean, at λ 1.05–1.10; found $λ_eff"
    @assert isapprox(η_1, 0.357; atol = 5e-4) "λ = 1 must give the map's 35.7 %; found $η_1"
    md"""
    **Power** peaks at λ $(λ_power), AFR $(round(14.6λ_power; digits = 1)); **efficiency** at
    λ $(λ_eff), AFR $(round(14.6λ_eff; digits = 1)), with $(round(100η_max; digits = 1)) %
    against $(round(100η_1; digits = 1)) % at λ = 1.
    """
end

# ╔═╡ a1e7bc12-5bae-4eec-b2f7-8d6c4b49dfe8
md"""
### Ignition advance against speed and load (slide 06.2)

A distributor's two mechanisms, with the shapes of the Bosch figure the slide carried. The
**centrifugal** advance depends on speed alone: 7° BTDC up to 1200 rpm, 21° at 3000 rpm, 27° from
5500 rpm (textbook, read off the figure). The **vacuum** advance depends on load through the
manifold low pressure, ambient minus manifold: none below 150 mbar, rising to 13° at 350 mbar
(assumed, so the sum reproduces the figure). Part load, line 1, runs at high vacuum and gets both;
at full load, line 2, there is almost no vacuum and the centrifugal advance acts alone. The low
pressure along line 1 is a monotone cubic through points read off the figure.

Replaced by: Dyad task 6, the MBT advance that `SparkSweep` finds on `SingleCylinder` at part and
full load (notebook 02).
"""

# ╔═╡ 26cc9c6c-e335-4b03-b72e-d51effecc50a
begin
    centrifugal_advance(rpm) = Trends.interpolate([0.0, 1200, 3000, 5500, 7000], [7.0, 7, 21, 27, 27], rpm)
    vacuum_advance(Δp_mbar) = 13 * clamp((Δp_mbar - 150) / 200, 0, 1)
    const PART_LOAD_VACUUM = Trends.pchip([600.0, 900, 1200, 1500, 2300, 3000, 3800, 4800, 5500, 6000],
        [0.0, 40, 140, 400, 620, 560, 400, 230, 150, 120])
    full_load_vacuum(rpm) = 150 * (rpm - 600) / 5400
    const ADVANCE_RPM = collect(600.0:20.0:6000.0)
    advance_lines = (
        part = (vacuum = PART_LOAD_VACUUM.(ADVANCE_RPM),),
        full = (vacuum = full_load_vacuum.(ADVANCE_RPM),))
    advance(line) = centrifugal_advance.(ADVANCE_RPM) .+ vacuum_advance.(line.vacuum)
end

# ╔═╡ d4714c17-3940-4b5d-a6c3-103813f3f7e7
# ╠═╡ card = "advance-curves"
let rpm = ADVANCE_RPM
    lines = ((advance_lines.part, "1 part load", ACCENT, "solid"),
        (advance_lines.full, "2 full load", INK, "dash"))
    traces = Any[]
    for (k, (l, name, color, dash)) in enumerate(lines)
        push!(traces, PP.scatter(; x = rpm, y = round.(advance(l); digits = 3), mode = "lines", name,
            legendgroup = name, line = line(color; dash),
            hovertemplate = "$name, %{x:.0f} rpm: %{y:.1f}° BTDC<extra></extra>"))
        push!(traces, PP.scatter(; x = rpm, y = round.(l.vacuum; digits = 2), mode = "lines", name,
            legendgroup = name, showlegend = false, xaxis = "x2", yaxis = "y2",
            line = line(color; dash),
            hovertemplate = "$name, %{x:.0f} rpm: %{y:.0f} mbar<extra></extra>"))
    end
    Δp = collect(0.0:5.0:700.0)
    push!(traces, PP.scatter(; x = Δp, y = vacuum_advance.(Δp), mode = "lines",
        name = "vacuum unit", showlegend = false, xaxis = "x3", yaxis = "y3", line = line(WARN),
        hovertemplate = "%{x:.0f} mbar: +%{y:.1f}°<extra></extra>"))
    unit_band = [PP.attr(; type = "line", xref = "x2", yref = "y2", x0 = 600, x1 = 6000, y0 = y,
                     y1 = y, line = PP.attr(; color = WARN, width = 1, dash = "dot"))
                 for y in (150, 350)]
    PP.plot(identity.(traces), deck_layout(;
        margin = PP.attr(l = 64, r = 16, t = 40, b = 56),
        legend = PP.attr(orientation = "h", x = 0, y = 1.1),
        xaxis = axis(""; domain = [0, 0.6], range = [600, 6000], dtick = 1000, matches = "x2",
            showticklabels = false, anchor = "y"),
        yaxis = axis("advance [° BTDC]"; domain = [0.5, 1], range = [0, 40], dtick = 10, anchor = "x"),
        xaxis2 = axis("engine speed [rpm]"; domain = [0, 0.6], range = [600, 6000], dtick = 1000,
            anchor = "y2"),
        yaxis2 = axis("low pressure [mbar]"; domain = [0, 0.4], range = [0, 700], dtick = 200,
            anchor = "x2"),
        xaxis3 = axis("low pressure [mbar]"; domain = [0.74, 1], range = [0, 700], dtick = 300,
            anchor = "y3"),
        yaxis3 = axis("vacuum advance [°]"; domain = [0.25, 0.85], range = [0, 15], dtick = 5,
            anchor = "x3"),
        shapes = unit_band,
        annotations = [PP.attr(; x = 0.87, y = 0.97, xref = "paper", yref = "paper",
            showarrow = false, text = "advance against load", font = PP.attr(; size = 15, color = INK))]))
end

# ╔═╡ 7665de7d-a613-45a6-be33-cf29b356d2c7
let part = advance(advance_lines.part), full = advance(advance_lines.full)
    at(rpm) = findfirst(==(rpm), ADVANCE_RPM)
    @assert part[at(800)] == full[at(800)] == 7 "both lines must idle at 7° BTDC"
    @assert all(part[at(1600):at(4500)] .> full[at(1600):at(4500)] .+ 5) "part load must advance more than full load at mid speed"
    peak_rpm = ADVANCE_RPM[argmax(part)]
    @assert 33 <= maximum(part) <= 37 && 3000 <= peak_rpm <= 4200 "part load must peak at 33–37° near 3000–4200 rpm"
    @assert abs(part[at(5500)] - full[at(5500)]) < 1 "the lines must meet near 5500 rpm"
    md"""
    **Part load** peaks at $(round(maximum(part); digits = 1))° BTDC at $(round(Int, peak_rpm)) rpm;
    **full load** reaches $(round(full[end]; digits = 1))° at 6000 rpm; both idle at 7°.
    """
end

# ╔═╡ c999f430-7ecd-4907-8971-c34fcd0a5ddd
md"""
### The spark-advance map (slide 06.5)

The MBT advance over speed and manifold pressure, as task 2's `TorqueProduction` holds it: about
10° BTDC at idle, more with speed, because the flame needs about the same time at any speed and
that time spans more crank angle, and less with load, because a denser charge burns faster
(assumed shape). It is anchored to 36° at 3000 rpm and half the full-load air charge, the MBT
that notebook 02's single-zone Wiebe cylinder computes at the operating point of slides 50–52, so
the map, the pressure traces and the λ figures share one MBT there. That puts high speed and light
load near 48°, above the 35° task 2 suggested.

```math
\sigma_{\mathrm{MBT}} = 10 + 38\left(1 - e^{-(N - 800)/1000}\right)\left(1.1 - 0.5\,\frac{p_m}{100\ \mathrm{kPa}}\right)
```

A production map also holds the knock limit below MBT at high load and low speed, which gives the
scanned map its ridges; this one does not.

Replaced by: Dyad task 2's `sigma_mbt` table, then task 6's `SparkSweep` MBT beside it.
"""

# ╔═╡ 9a6a263a-f956-4b00-aa7d-6461e088ac58
# ╠═╡ card = "advance-map"
let kpa = collect(20.0:5.0:100.0), rpm = collect(800.0:200.0:6400.0)
    z = [round(Trends.sigma_mbt(n, p); digits = 2) for n in rpm, p in kpa]
    PP.plot(
        PP.contour(; x = rpm, y = kpa, z = [z[i, :] for i in axes(z, 1)], colorscale = "Blues",
            zmin = 5, zmax = 50, contours = PP.attr(; start = 10, size = 5, :end => 45,
                showlabels = true, labelfont = PP.attr(; size = 13, color = INK)),
            line = PP.attr(; color = INK, width = 1),
            colorbar = PP.attr(; title = PP.attr(; text = "° BTDC"), thickness = 12),
            hovertemplate = "%{x:.0f} rpm, %{y:.0f} kPa: %{z:.1f}° BTDC<extra></extra>"),
        deck_layout(;
            margin = PP.attr(l = 70, r = 10, t = 16, b = 56),
            xaxis = axis("engine speed [rpm]"; dtick = 1000),
            yaxis = axis("p<sub>m</sub> [kPa] (load)"; dtick = 20)))
end

# ╔═╡ 63ecd2e9-638d-4905-abf9-27e413e5ca15
let σ = Trends.sigma_mbt, op = Trends.operating_point(3000, 0.5)
    rpm, kpa = 800.0:200.0:6400.0, 20.0:5.0:100.0
    @assert isapprox(σ(800, 33), 10; atol = 0.5) "idle MBT must be about 10°"
    @assert isapprox(σ(3000, op.p_m_kPa), 36; atol = 0.5) "the map must read the Wiebe MBT, 36°, at the slides' operating point"
    @assert all(issorted(σ.(rpm, p)) for p in kpa) "advance must not fall with speed"
    @assert all(issorted(σ.(n, kpa); rev = true) for n in rpm) "advance must not rise with load"
    md"""
    **MBT** $(round(σ(800, 33); digits = 1))° at idle (800 rpm, 33 kPa),
    $(round(σ(3000, op.p_m_kPa); digits = 1))° at 3000 rpm and $(round(op.p_m_kPa; digits = 1)) kPa,
    $(round(σ(6000, 20); digits = 1))° at 6000 rpm and 20 kPa.
    """
end

# ╔═╡ 475fa2ff-5c13-49d0-a720-1cf7f02acc7b
md"""
### Two-step λ control: the limit cycle (slide 07.3)

A loop in plain Julia, stepped every millisecond. The controller's fuel factor ``u`` sets the
cylinder λ; a transport delay of 0.2 s carries it to the sensor (idle, assumed within task 5's
0.15–0.35 s); the switching sensor below turns it into a voltage behind a 70 ms lag (assumed,
task 5); and the controller acts on the sign of that voltage against 0.45 V (task 5),

```math
s = \tanh\!\left(\frac{V - 0.45\ \mathrm{V}}{0.05\ \mathrm{V}}\right), \qquad
u = 1 + F - k_j\,s, \qquad \dot F = -k_r\,s,
```

a jump ``k_j`` = 1.5 % at each switch and a ramp ``k_r`` = 6 %/s between (assumed, tuned to the
slide's 2–3 %). The open-loop mixture is 3 % lean (assumed), and the ramp has removed that within
the first second. Task 5's defaults, a 3 % jump and 5 %/s, swing λ by about +5/−2 % in this loop.

The oscillation is a true limit cycle, not a drawing of one: the controller only knows rich or
lean, so it cannot settle, and each half period lasts as long as the delay plus the sensor's
switching time. The post-catalyst shift of panels a and b on the scan is left out.

Replaced by: Dyad task 5, `LambdaLoop` with `TwoStepLambdaController` and
`LambdaSensorSwitching` (notebook 06).
"""

# ╔═╡ 64cce6e7-3580-40f8-951f-e7123bd9c050
begin
    const LAMBDA_DELAY = 0.20   # s, injection to sensor at idle (assumed, task 5 band 0.15–0.35 s)
    const SENSOR_LAG = 0.07     # s (assumed, task 5)
    const V_REF = 0.45          # V, switching level (task 5)
    const EPS_V = 0.05          # V, width of the controller's switch (assumed)
    const K_JUMP = 0.015        # (assumed, tuned to ±2–3 %)
    const K_RAMP = 0.06         # 1/s (assumed, tuned to ±2–3 %)
    const LAMBDA_OPEN = 1.03    # open-loop mixture error (assumed)

    """
        two_step(; dt, t_end) -> (; t, λ, V, u)

    Cylinder λ, sensor voltage [V] and fuel factor of the two-step loop, by explicit Euler steps.
    """
    function two_step(; dt = 1e-3, t_end = 4.0)
        n, delay = round(Int, t_end / dt) + 1, round(Int, LAMBDA_DELAY / dt)
        t = collect(0:(n - 1)) .* dt
        λ, V, u = zeros(n), zeros(n), zeros(n)
        F, v = 0.0, lambda_V(LAMBDA_OPEN)
        for k in 1:n
            s = tanh((v - V_REF) / EPS_V)
            u[k] = 1 + F - K_JUMP * s
            λ[k] = LAMBDA_OPEN / u[k]
            V[k] = v
            v += dt / SENSOR_LAG * (lambda_V(k > delay ? λ[k - delay] : LAMBDA_OPEN) - v)
            F -= K_RAMP * s * dt
        end
        return (; t, λ, V, u)
    end

    lambda_loop = two_step()
end

# ╔═╡ 888dda8d-5a7e-4625-8813-1c4c8ae3e51f
# ╠═╡ card = "two-step-cycle"
let r = lambda_loop, k = 1:5:length(lambda_loop.t)
    t = round.(r.t[k]; digits = 3)
    panel(y, n, name, color, unit) = PP.scatter(; x = t, y, mode = "lines", name,
        xaxis = "x$n", yaxis = "y$n", line = line(color; width = 2.5),
        hovertemplate = "%{x:.2f} s: %{y:.3f} $unit<extra></extra>")
    traces = [
        panel(round.(r.V[k]; digits = 4), 1, "sensor voltage", ACCENT, "V"),
        panel(round.(100 .* (r.u[k] .- 1); digits = 3), 2, "fuel correction", INK, "%"),
        panel(round.(r.λ[k]; digits = 4), 3, "λ in the cylinder", WARN, ""),
    ]
    guide(n, y) = PP.attr(; type = "line", xref = "x$n", yref = "y$n", x0 = 0, x1 = 4, y0 = y,
        y1 = y, line = PP.attr(; color = MUTED, width = 1, dash = "dot"))
    rows = ((1, "sensor [V]", [0, 1], 0.5), (2, "fuel corr. [%]", [-4, 6], 2),
        (3, "λ", [0.96, 1.05], 0.02))
    axes = Dict{Symbol, Any}()
    for (n, title, range, dtick) in rows
        top = 1 - (n - 1) * 0.35
        axes[Symbol("xaxis$n")] = axis(n == 3 ? "time [s]" : ""; range = [0, 4], dtick = 0.5,
            anchor = "y$n", showticklabels = n == 3)
        n < 3 && (axes[Symbol("xaxis$n")][:matches] = "x3")
        axes[Symbol("yaxis$n")] = axis(title; domain = [top - 0.29, top], range, dtick,
            anchor = "x$n")
    end
    PP.plot(traces, deck_layout(;
        axes...,
        showlegend = false,
        hovermode = "x unified",
        margin = PP.attr(l = 80, r = 20, t = 16, b = 56),
        shapes = [guide(1, V_REF), guide(3, 1.0)]))
end

# ╔═╡ a1992a7f-f4c9-42d2-94b2-e4c14e16a2b7
let r = lambda_loop, steady = lambda_loop.t .>= 2
    λ = r.λ[steady]
    excursion = maximum(abs.(λ .- 1))
    rising = [r.t[k] for k in 2:length(r.t) if r.t[k] >= 2 && r.V[k - 1] < V_REF <= r.V[k]]
    period = (rising[end] - rising[1]) / (length(rising) - 1)
    @assert 0.02 <= excursion <= 0.03 "λ must swing ±2–3 % about 1, found $(round(100excursion; digits = 2)) %"
    @assert minimum(λ) < 1 < maximum(λ) "λ must cross 1 every cycle"
    @assert 0.5 <= 1 / period <= 5 "the limit cycle must run at 0.5–5 Hz, found $(1 / period) Hz"
    md"""
    **λ** swings from $(round(minimum(λ); digits = 3)) to $(round(maximum(λ); digits = 3)) once
    the bias is removed; the cycle repeats every $(round(period; digits = 2)) s,
    $(round(1 / period; digits = 2)) Hz.
    """
end

# ╔═╡ b1988eb2-5414-4334-9929-f071764c410a
md"""
### Oxygen sensor characteristics (slide 07.4)

Left, the switching ZrO₂ sensor as task 5's `LambdaSensorSwitching` states it: 0.9 V rich, 0.1 V
lean (deck slide 58), a tanh step 0.005 wide in λ so the jump spans λ 0.98–1.02 (derived), with
no temperature dependence. The same function drives the sensor in the loop above and the
discontinuous panel of the sensor classification. Right, the broadband sensor for comparison:
the Bosch LSU 4.9's pump current is continuous in λ, read from the Bosch Motorsport datasheet as
`teaching_materials.md` transcribes it.

Replaced by: Dyad task 5, `LambdaSensorSwitching` and `LambdaSensorWideband` under a λ ramp
(notebook 06).
"""

# ╔═╡ d8d499f6-e837-4b54-80f7-f0473f4b1505
lsu49 = let
    row = only(filter(l -> occursin("**Bosch LSU 4.9 wideband**", l), readlines(NOTES)))
    table = match(r"Ip→λ table: (.*?)\. Nernst", row)[1]
    pairs = map(split(table, ";")) do entry
        numbers = [parse(Float64, replace(m.match, "−" => "-"))
            for m in eachmatch(r"−?\d+(\.\d+)?", replace(entry, "**" => ""))]
        numbers[1] => numbers[2]
    end
    (; Ip_mA = first.(pairs), λ = last.(pairs))
end

# ╔═╡ f22bbfeb-f558-41f2-ba35-0af2f82658a8
# ╠═╡ card = "lambda-sensors"
let λ = collect(0.95:0.0005:1.05), wide = lsu49.λ .<= 2.0
    traces = [
        PP.scatter(; x = λ, y = round.(lambda_V.(λ); digits = 4), mode = "lines",
            name = "switching sensor", line = line(ACCENT),
            hovertemplate = "λ %{x:.3f}: %{y:.2f} V<extra></extra>"),
        PP.scatter(; x = lsu49.λ[wide], y = lsu49.Ip_mA[wide], mode = "lines+markers",
            name = "LSU 4.9", xaxis = "x2", yaxis = "y2", line = line(WARN),
            marker = PP.attr(; size = 7, color = INK),
            hovertemplate = "λ %{x:.3f}: %{y:.3f} mA<extra></extra>"),
    ]
    PP.plot(traces, deck_layout(;
        showlegend = false,
        margin = PP.attr(l = 64, r = 16, t = 40, b = 56),
        xaxis = axis("λ"; domain = [0, 0.42], range = [0.95, 1.05], dtick = 0.025, anchor = "y"),
        yaxis = axis("sensor voltage [V]"; range = [0, 1], dtick = 0.2, anchor = "x"),
        xaxis2 = axis("λ"; domain = [0.64, 1], range = [0.6, 2.0], dtick = 0.4, anchor = "y2"),
        yaxis2 = axis("pump current [mA]"; range = [-2.2, 1.4], dtick = 0.5, anchor = "x2"),
        shapes = [PP.attr(; type = "line", xref = "x", yref = "y", x0 = 0.95, x1 = 1.05,
            y0 = V_REF, y1 = V_REF, line = PP.attr(; color = MUTED, width = 1, dash = "dash"))],
        annotations = [
            PP.attr(; x = 0.21, y = 1.08, xref = "paper", yref = "paper", showarrow = false,
                text = "two-step ZrO₂", font = PP.attr(; size = 15, color = INK)),
            PP.attr(; x = 0.82, y = 1.08, xref = "paper", yref = "paper", showarrow = false,
                text = "broadband LSU 4.9", font = PP.attr(; size = 15, color = INK)),
            PP.attr(; x = 1.045, y = V_REF, xref = "x", yref = "y", yshift = 10, xanchor = "right",
                showarrow = false, text = "U<sub>reg</sub>", font = PP.attr(; size = 14, color = MUTED))]))
end

# ╔═╡ 92e1073d-c083-4677-b228-2aec37f9a434
let fine = 0.95:0.0001:1.05
    slope = abs.(diff(lambda_V.(fine)))
    λ_jump = fine[argmax(slope)]
    @assert abs(λ_jump - 1) <= 0.0005 "the sensor must jump at λ = 1, found $λ_jump"
    @assert lambda_V(0.98) > 0.85 && lambda_V(1.02) < 0.15 "the sensor must read about 0.9 V rich and 0.1 V lean"
    @assert issorted(lsu49.Ip_mA) && issorted(lsu49.λ) "the LSU table must rise with λ"
    @assert lsu49.λ[lsu49.Ip_mA .== 0] == [1.003] "the LSU pump current must cross zero at λ 1.003"
    md"""
    **Switching** $(round(lambda_V(0.98); digits = 2)) V at λ 0.98, $(round(lambda_V(1.02); digits = 2))
    V at λ 1.02, steepest at λ $(round(λ_jump; digits = 4)). **LSU 4.9** $(length(lsu49.λ))
    datasheet points, λ $(first(lsu49.λ)) to $(last(lsu49.λ)).
    """
end

# ╔═╡ 5899b91d-9a95-4b60-9720-969504ab481a
md"""
## Sensors section: the 60−2 crank wheel (section 04)

A 60−2 trigger wheel has 60 tooth positions 6° apart with two teeth removed: 58 teeth, then a
gap of 18° between tooth edges, three pitches (derived). The gap is the once-per-revolution
reference, and crank angle is counted from the first tooth after it. One tooth passes per 6°, so
the tooth frequency in Hz equals the engine speed in rpm (derived).

Each tooth is idealized as a Gaussian bump in the flux through the sensor,
``\Phi(\theta) = \sum_k e^{-(\theta - \theta_k)^2 / 2\sigma^2}``, with σ = 1.2° (assumed) so that
a tooth is about half a pitch wide, as on the Bosch Motorsport IS-C reference wheel (tooth 4.1 mm,
gap 4.3 mm).

- An **inductive (VR)** sensor's voltage follows ``d\Phi/dt = \omega\, d\Phi/d\theta``: its
  amplitude grows with speed and its zero crossings, at the tooth centers, do not move with speed
  (Woodward MotoHawk VR documentation). It is drawn relative to its peak at 3000 rpm.
- A **Hall** sensor switches where the field crosses a fixed threshold, here half a tooth's peak:
  the same edges at any speed, and a signal from standstill (Bosch Motorsport, *Drehzahlsensoren*).
- The **cam** sensor turns at half speed and sees one window per 720° cycle; where the window sits
  is set by the cam wheel (assumed here: 30° to 210°).
"""

# ╔═╡ ca1ca354-9221-4ac0-832e-a3278771a768
begin
    const PITCH = 6.0         # ° per tooth position on a 60−2 wheel
    const TOOTH_SIGMA = 1.2   # °, width of one tooth's flux bump (assumed)
    const RPM_REF = 3000.0    # the VR voltage is drawn relative to its peak at this speed

    "Tooth centers [°] over the given revolutions, tooth 1 at 0°: 58 teeth, then the gap."
    tooth_centers(revs) = [360r + PITCH * k for r in revs for k in 0:57]
    const TEETH = tooth_centers(-1:2)

    bump(x) = exp(-(x / TOOTH_SIGMA)^2 / 2)
    flux(θ) = sum(bump(θ - c) for c in TEETH)
    dflux(θ) = sum(-(θ - c) / TOOTH_SIGMA^2 * bump(θ - c) for c in TEETH)
    const DFLUX_PEAK = maximum(abs ∘ dflux, 0.0:0.01:360.0)

    "VR voltage relative to its peak at `RPM_REF`: v ∝ ω dΦ/dθ."
    vr(θ, rpm) = rpm / RPM_REF * dflux(θ) / DFLUX_PEAK
    "Hall output, 1 while the field exceeds half a tooth's peak."
    hall_out(θ) = flux(θ) > 0.5 ? 1.0 : 0.0
    const CAM_WINDOW = (30.0, 210.0)  # ° of the 720° cycle (assumed)
    cam(θ) = CAM_WINDOW[1] <= mod(θ, 720) < CAM_WINDOW[2] ? 1.0 : 0.0

    "A 0/1 signal sampled on `θ` as step-line vertices: only the samples where it changes."
    function steps(f, θ)
        x, y = [θ[1]], [f(θ[1])]
        for t in θ[2:end]
            v = f(t)
            v == y[end] && continue
            push!(x, t)
            push!(y, v)
        end
        push!(x, θ[end])
        push!(y, y[end])
        round.(x; digits = 2), y
    end
end

# ╔═╡ 996bcf9b-cc10-40c1-86d8-9d41a3332d9b
# ╠═╡ card = "crank-vr-hall"
let θ = collect(-48.0:0.05:48.0)
    rows = (
        (1, "VR, 3000 rpm", round.(vr.(θ, 3000); digits = 4), ACCENT),
        (2, "VR, 300 rpm", round.(vr.(θ, 300); digits = 4), ACCENT),
    )
    traces = Any[PP.scatter(; x = θ, y, mode = "lines", name, xaxis = "x$n", yaxis = "y$n",
                     line = line(color; width = 2.5),
                     hovertemplate = "%{x:.1f}°: %{y:.2f}<extra>$name</extra>")
                 for (n, name, y, color) in rows]
    hx, hy = steps(hall_out, θ)
    push!(traces, PP.scatter(; x = hx, y = hy, mode = "lines", name = "Hall", xaxis = "x3",
        yaxis = "y3", line = line(INK; width = 2.5, shape = "hv"),
        hovertemplate = "%{x:.1f}°: %{y}<extra>Hall, any speed</extra>"))
    axes = Dict{Symbol, Any}()
    for (n, title, range) in ((1, "VR 3000 rpm", [-1.2, 1.7]), (2, "VR 300 rpm", [-1.2, 1.7]),
        (3, "Hall", [-0.2, 1.3]))
        top = 1 - (n - 1) * 0.34
        axes[Symbol("xaxis$n")] = axis(n == 3 ? "crank angle from tooth 1 [°]" : "";
            range = [-48, 48], dtick = 12, anchor = "y$n", showticklabels = n == 3)
        n < 3 && (axes[Symbol("xaxis$n")][:matches] = "x3")
        axes[Symbol("yaxis$n")] = axis(title; domain = [top - 0.28, top], range,
            dtick = 1, anchor = "x$n")
    end
    gap = PP.attr(; type = "rect", xref = "x3", yref = "paper", x0 = -15, x1 = -3, y0 = 0, y1 = 1,
        fillcolor = WARN, opacity = 0.12, line = PP.attr(; width = 0))
    note(n, y, text; color = INK) = PP.attr(; xref = "x$n", yref = "y$n", x = 47, y,
        xanchor = "right", showarrow = false, text, font = PP.attr(; size = 13, color))
    PP.plot(identity.(traces), deck_layout(;
        axes...,
        showlegend = false,
        margin = PP.attr(l = 80, r = 16, t = 28, b = 56),
        shapes = [gap],
        annotations = [
            PP.attr(; xref = "x3", yref = "paper", x = -9, y = 1.0, yanchor = "bottom",
                showarrow = false, text = "gap: two teeth missing",
                font = PP.attr(; size = 14, color = WARN)),
            note(1, 1.45, "amplitude ∝ speed"; color = MUTED),
            note(2, 1.45, "one tenth: hard to read at cranking"; color = MUTED),
            note(3, 1.18, "same edges at any speed, from 0 rpm"; color = MUTED)]))
end

# ╔═╡ c9d26062-2cf3-4764-a527-abc952a7ebcc
# ╠═╡ card = "crank-cam-phase"
let θ = collect(0.0:0.02:720.0)
    cx, cy = steps(hall_out, θ)
    kx, ky = steps(cam, θ)
    traces = [
        PP.scatter(; x = cx, y = cy, mode = "lines", name = "crank (Hall)", xaxis = "x1",
            yaxis = "y1", line = line(INK; width = 1.5, shape = "hv"), hoverinfo = "skip"),
        PP.scatter(; x = kx, y = ky, mode = "lines", name = "cam", xaxis = "x2", yaxis = "y2",
            line = line(ACCENT; width = 2.5, shape = "hv"),
            hovertemplate = "%{x:.0f}°: %{y}<extra>cam</extra>"),
    ]
    revolution(x) = PP.attr(; type = "line", xref = "x2", yref = "paper", x0 = x, x1 = x,
        y0 = 0, y1 = 1, line = PP.attr(; color = MUTED, width = 1, dash = "dot"))
    gap(x) = PP.attr(; type = "rect", xref = "x2", yref = "paper", x0 = x - 15, x1 = x - 3,
        y0 = 0, y1 = 1, fillcolor = WARN, opacity = 0.25, line = PP.attr(; width = 0))
    label(x, y, text; color = INK, xanchor = "center") = PP.attr(; xref = "x2", yref = "paper",
        x, y, xanchor, showarrow = false, text, font = PP.attr(; size = 14, color))
    PP.plot(traces, deck_layout(;
        showlegend = false,
        margin = PP.attr(l = 80, r = 16, t = 36, b = 56),
        xaxis = axis(""; range = [0, 720], dtick = 90, matches = "x2", showticklabels = false,
            anchor = "y1"),
        yaxis = axis("crank"; domain = [0.55, 0.95], range = [-0.2, 1.3], dtick = 1,
            anchor = "x1"),
        xaxis2 = axis("crank angle over one cycle [°]"; range = [0, 720], dtick = 90,
            anchor = "y2"),
        yaxis2 = axis("cam"; domain = [0, 0.4], range = [-0.2, 1.3], dtick = 1, anchor = "x2"),
        shapes = [revolution.((360.0, 720.0))..., gap.((360.0, 720.0))...],
        annotations = [
            label(180, 1.02, "revolution 1"), label(540, 1.02, "revolution 2"),
            label(351, 0.47, "gap"; color = WARN), label(711, 0.47, "gap"; color = WARN,
                xanchor = "right"),
            label(220, 0.36, "cam high: revolution 1 of the cycle"; color = ACCENT,
                xanchor = "left")]))
end

# ╔═╡ 27c76275-ba77-4373-8f54-fdb2f5f14b64
let fine = -45.0:0.01:45.0
    edges = [fine[k] for k in 2:length(fine) if hall_out(fine[k - 1]) != hall_out(fine[k])]
    high = [(edges[k], edges[k + 1]) for k in 1:2:(length(edges) - 1) if hall_out(edges[k] + 0.01) == 1]
    widths = [b - a for (a, b) in high]
    centers = [round((a + b) / 2; digits = 2) for (a, b) in high]
    @assert count(c -> -45 < c < 45, TEETH) == length(high) "every tooth must give one Hall pulse"
    @assert all(abs.(centers .- round.(centers ./ PITCH) .* PITCH) .< 0.02) "Hall pulses must center on the teeth"
    @assert 2.4 <= minimum(widths) && maximum(widths) <= 3.4 "a tooth must be about half a pitch wide"
    gap_edges = [c for c in centers if -20 < c < 1]
    @assert isapprox(gap_edges, [-18.0, 0.0]; atol = 0.02) "the gap must span 18° between tooth centers"
    zero = [θ for θ in -45.0:0.001:45.0 if vr(θ - 0.0005, 3000) > 0 >= vr(θ + 0.0005, 3000)]
    @assert all(abs.(zero .- round.(zero ./ PITCH) .* PITCH) .< 0.01) "VR must cross zero at tooth centers"
    @assert isapprox(maximum(abs ∘ (θ -> vr(θ, 300)), fine) * 10, maximum(abs ∘ (θ -> vr(θ, 3000)), fine))
    md"""
    **Hall pulses** $(round(minimum(widths); digits = 2))–$(round(maximum(widths); digits = 2))° wide
    of a 6° pitch; **VR** zero crossings on the tooth centers; the gap spans
    $(round(gap_edges[2] - gap_edges[1]; digits = 1))° between tooth centers. Tooth frequency at 800 rpm:
    $(round(Int, 800 / 60 * 360 / PITCH)) Hz.
    """
end

# ╔═╡ 8df692b9-0099-4095-9d85-16675cb87f83
md"""
## Misfire in the crank speed (section 04)

A four-cylinder crank in plain Julia: one inertia ``J`` driven by four firings per cycle and held
back by a constant load equal to the mean torque, with no speed controller. Each firing delivers
its work ``W = \bar T \pi`` as a half-sine of torque over the 180° after its TDC, and the speed
follows from the energy balance along the crank angle, with no time stepping,

```math
\tfrac12 J \omega^2(\theta) = \tfrac12 J \omega_0^2 + \int_0^\theta (T_\mathrm{gas} - \bar T)\,d\theta' .
```

``J`` = 0.15 kg·m² and ``\bar T`` = 50 N·m are assumed, as in the research note: a missed firing
removes ``W`` = 157 J, and the dip ``\Delta\omega \approx W / (J\omega)`` is about 5 rad/s (2.4 %)
at 2000 rpm and 1.7 rad/s (0.27 %) at 6000 rpm (derived). The firing order is 1-3-4-2; cylinder 4,
the third firing, misfires. Below the speed, the ECU's view: the speed each cylinder's 180° segment
gains, from its end against its start, which the ECU reads off the tooth periods there.

Idealized: no compression torque, no torsional vibration, no wheel tolerances, which is where a
real detector's difficulty at high speed comes from.
"""

# ╔═╡ c949f048-159f-4c96-8c70-2a9e6c1eef22
begin
    const J_CRANK = 0.15            # kg·m², crank, flywheel and clutch (assumed)
    const T_MEAN = 50.0             # N·m, mean torque and load (assumed)
    const W_FIRE = T_MEAN * π       # J per firing: four firings share the cycle's 4π
    const FIRING_ORDER = [1, 3, 4, 2]
    const MISFIRE_EVENT = 3         # the third firing in the run, cylinder 4

    "Work [J] the firings have delivered by crank angle `θ` [rad], the misfiring one left out."
    function gas_work(θ)
        sum(k + 1 == MISFIRE_EVENT ? 0.0 : W_FIRE / 2 * (1 - cos(min(θ - k * π, π)))
            for k in 0:floor(Int, θ / π))
    end

    """
        misfire_run(rpm) -> (; θ_deg, ω, Δω_pct, segment_mid, segment_gain_pct, ω0)

    Crank speed over two cycles from `rpm`, and the speed each 180° segment gains, in % of the
    starting speed.
    """
    function misfire_run(rpm; dθ_deg = 0.5)
        ω0 = rpm * π / 30
        θ_deg = collect(0.0:dθ_deg:1440.0)
        ω = [sqrt(ω0^2 + 2 * (gas_work(deg2rad(t)) - T_MEAN * deg2rad(t)) / J_CRANK) for t in θ_deg]
        per = round(Int, 180 / dθ_deg)
        gain = [100 * (ω[(k + 1) * per + 1] - ω[k * per + 1]) / ω0 for k in 0:7]
        (; θ_deg, ω, Δω_pct = 100 .* (ω ./ ω0 .- 1), segment_mid = 180.0 .* (0:7) .+ 90,
            segment_gain_pct = gain, ω0)
    end

    misfire_runs = (misfire_run(2000), misfire_run(6000))
end

# ╔═╡ 8627240b-ee7d-4378-8739-24102aee09bf
# ╠═╡ card = "misfire-dip"
let speeds = ((misfire_runs[1], "2000 rpm", ACCENT, -22), (misfire_runs[2], "6000 rpm", WARN, 22))
    traces = Any[]
    for (r, name, color, offset) in speeds
        k = 1:4:length(r.θ_deg)
        push!(traces, PP.scatter(; x = r.θ_deg[k], y = round.(r.Δω_pct[k]; digits = 4),
            mode = "lines", name, legendgroup = name, line = line(color),
            hovertemplate = "%{x:.0f}°: %{y:.2f} %<extra>$name</extra>"))
        push!(traces, PP.bar(; x = r.segment_mid .+ offset, y = round.(r.segment_gain_pct; digits = 4),
            width = 40, name, legendgroup = name, showlegend = false, xaxis = "x2", yaxis = "y2",
            marker = PP.attr(; color),
            hovertemplate = "%{y:.2f} %<extra>$name</extra>"))
    end
    mids = 180.0 .* (0:7) .+ 90
    cylinders = ["cyl $(FIRING_ORDER[mod1(k, 4)])" for k in 1:8]
    PP.plot(identity.(traces), deck_layout(;
        margin = PP.attr(l = 80, r = 16, t = 36, b = 56),
        legend = PP.attr(; orientation = "h", x = 0.99, xanchor = "right", y = 1.08),
        barmode = "overlay",
        xaxis = axis(""; range = [0, 1440], dtick = 180, matches = "x2", anchor = "y",
            showticklabels = false),
        yaxis = axis("speed change [%]"; domain = [0.5, 1], range = [-3, 0.8], dtick = 1,
            anchor = "x"),
        xaxis2 = axis("180° segment, firing order 1-3-4-2"; range = [0, 1440], anchor = "y2",
            tickvals = mids, ticktext = cylinders),
        yaxis2 = axis("gain per segment [%]"; domain = [0, 0.4], range = [-3, 0.8],
            dtick = 1, anchor = "x2"),
        shapes = [PP.attr(; type = "rect", xref = "x2", yref = "paper", x0 = 360, x1 = 540,
            y0 = 0, y1 = 1, fillcolor = WARN, opacity = 0.08, line = PP.attr(; width = 0))],
        annotations = [PP.attr(; xref = "x2", yref = "paper", x = 450, y = 1.0,
            yanchor = "bottom", showarrow = false, text = "cylinder 4 misfires",
            font = PP.attr(; size = 14, color = WARN))]))
end

# ╔═╡ bb5c3017-7a60-4a7e-9a52-a70d9d917ba8
let (low, high) = misfire_runs
    dip(r) = r.ω0 - r.ω[findfirst(==(540.0), r.θ_deg)]
    @assert isapprox(W_FIRE, 157.08; atol = 0.01) "a firing must carry 157 J"
    @assert isapprox(dip(low), W_FIRE / (J_CRANK * low.ω0); rtol = 0.03) "the 2000 rpm dip must be W/(Jω)"
    @assert isapprox(dip(low), 5.0; atol = 0.15) "the 2000 rpm dip must be about 5 rad/s"
    @assert isapprox(dip(high), 1.67; atol = 0.05) "the 6000 rpm dip must be about 1.7 rad/s"
    @assert isapprox(100 * dip(low) / low.ω0, 2.4; atol = 0.1) "2000 rpm: about 2.4 %"
    @assert isapprox(100 * dip(high) / high.ω0, 0.27; atol = 0.02) "6000 rpm: about 0.27 %"
    @assert argmin(low.segment_gain_pct) == argmin(high.segment_gain_pct) == MISFIRE_EVENT "the misfiring segment must stand out"
    @assert all(abs.(low.segment_gain_pct[[1, 2, 4, 5, 6, 7, 8]]) .< 1e-6) "a firing segment must gain nothing"
    md"""
    **Dip** $(round(dip(low); digits = 2)) rad/s ($(round(100 * dip(low) / low.ω0; digits = 2)) %)
    at 2000 rpm, $(round(dip(high); digits = 2)) rad/s ($(round(100 * dip(high) / high.ω0; digits = 2)) %)
    at 6000 rpm. **Misfiring segment** loses $(round(-minimum(low.segment_gain_pct); digits = 2)) % at
    2000 rpm, $(round(-minimum(high.segment_gain_pct); digits = 3)) % at 6000 rpm.
    """
end

# ╔═╡ 744b13c3-5c7d-45e1-ac03-e1fb95dc6ebd
md"""
## The MAP sensor's transfer line (section 04)

The Bosch Motorsport PS-AA, its 0.1–1.15 bar variant at a 5 V supply, as its datasheet states it:
4,048 mV/bar with an offset of −4.8 mV, ratiometric, so the output spans 0.4 V at 10 kPa to
4.65 V at 115 kPa. A reading outside that span comes from no healthy sensor: a short or an open
wire. Marked on the line: the hands-on engine's idle at 33 kPa and full load at 95 kPa (the
`eta-v-map` lines), and ambient pressure, 100 kPa, which a MAP sensor reads before the engine
turns (derived voltages: 1.33, 3.84 and 4.04 V).
"""

# ╔═╡ 4b59056c-86d4-47ee-a13e-e6c5b5b5d47d
begin
    const PSAA_SLOPE = 4.048       # V/bar, Bosch Motorsport PS-AA 1.15 bar datasheet
    const PSAA_OFFSET = -0.0048    # V
    const PSAA_SPAN = (10.0, 115.0) # kPa
    psaa_V(kPa) = PSAA_SLOPE * kPa / 100 + PSAA_OFFSET
end

# ╔═╡ 7a0ff0b0-36b0-4cd5-aff0-16877e762328
# ╠═╡ card = "map-transfer"
let kPa = collect(PSAA_SPAN[1]:0.5:PSAA_SPAN[2])
    lo, hi = psaa_V.(PSAA_SPAN)
    points = ((33.0, "idle"), (95.0, "full load"), (100.0, "ambient"))
    band(y0, y1) = PP.attr(; type = "rect", xref = "paper", yref = "y", x0 = 0, x1 = 1, y0, y1,
        fillcolor = WARN, opacity = 0.15, line = PP.attr(; width = 0))
    PP.plot([
            PP.scatter(; x = kPa, y = round.(psaa_V.(kPa); digits = 4), mode = "lines",
                name = "PS-AA", line = line(ACCENT),
                hovertemplate = "%{x:.1f} kPa: %{y:.3f} V<extra></extra>"),
            PP.scatter(; x = first.(points), y = round.(psaa_V.(first.(points)); digits = 3),
                mode = "markers+text", text = ["$(n) $(round(psaa_V(p); digits = 2)) V" for (p, n) in points],
                textposition = ["middle right", "top left", "middle right"],
                marker = PP.attr(; size = 10, color = INK), name = "operating points",
                hovertemplate = "%{x:.0f} kPa: %{y:.2f} V<extra></extra>"),
        ], deck_layout(;
            showlegend = false,
            margin = PP.attr(l = 70, r = 16, t = 16, b = 56),
            xaxis = axis("manifold pressure [kPa]"; range = [0, 140], dtick = 20),
            yaxis = axis("output at 5 V supply [V]"; range = [0, 5], dtick = 1),
            shapes = [band(0, lo), band(hi, 5)],
            annotations = [
                PP.attr(; x = 138, y = lo / 2, xanchor = "right", showarrow = false,
                    text = "below $(round(lo; digits = 2)) V: fault", font = PP.attr(; size = 13, color = WARN)),
                PP.attr(; x = 2, y = (hi + 5) / 2, xanchor = "left", showarrow = false,
                    text = "above $(round(hi; digits = 2)) V: fault", font = PP.attr(; size = 13, color = WARN))]))
end

# ╔═╡ Cell order:
# ╠═7635b61c-86fb-4a32-99de-86a0c84a2c00
# ╟─88324f20-40ae-4205-872b-e284cfea7231
# ╠═fe0c7b71-22dc-487d-8b16-3e5338bb7c35
# ╟─e3db3aee-e2bc-444b-a63c-0af24549c725
# ╠═ae73992e-135c-425f-84c1-e95e9bf9a229
# ╠═7d59eb8b-81be-41d9-9f57-b4bad7e95e1c
# ╠═1ce08079-23cd-438d-8214-79ebc6ecea59
# ╟─92c0fdf5-76b3-4fa4-8002-5df10c824489
# ╠═3948eff6-60d0-44f7-8b26-9653dd89565d
# ╠═c641e16a-e6dd-4c36-96cd-51ac4e0614bf
# ╠═8f2346ea-1348-45c6-8f57-d4c8e5015409
# ╟─4847d6cb-f506-4620-b8dd-df28fe29b1fe
# ╠═cb4510f1-3f0c-48d1-9463-c80c37a075dc
# ╟─7a0e2e3f-22f0-4c98-a767-ab72a9815758
# ╠═89b9520e-51b4-4935-9306-54c576ef875c
# ╠═ee5941f2-1f3c-4ec4-9e18-2fbe5efbe221
# ╟─a1e7bc12-5bae-4eec-b2f7-8d6c4b49dfe8
# ╠═26cc9c6c-e335-4b03-b72e-d51effecc50a
# ╠═d4714c17-3940-4b5d-a6c3-103813f3f7e7
# ╠═7665de7d-a613-45a6-be33-cf29b356d2c7
# ╟─c999f430-7ecd-4907-8971-c34fcd0a5ddd
# ╠═9a6a263a-f956-4b00-aa7d-6461e088ac58
# ╠═63ecd2e9-638d-4905-abf9-27e413e5ca15
# ╟─475fa2ff-5c13-49d0-a720-1cf7f02acc7b
# ╠═64cce6e7-3580-40f8-951f-e7123bd9c050
# ╠═888dda8d-5a7e-4625-8813-1c4c8ae3e51f
# ╠═a1992a7f-f4c9-42d2-94b2-e4c14e16a2b7
# ╟─b1988eb2-5414-4334-9929-f071764c410a
# ╠═d8d499f6-e837-4b54-80f7-f0473f4b1505
# ╠═f22bbfeb-f558-41f2-ba35-0af2f82658a8
# ╠═92e1073d-c083-4677-b228-2aec37f9a434
# ╟─5899b91d-9a95-4b60-9720-969504ab481a
# ╠═ca1ca354-9221-4ac0-832e-a3278771a768
# ╠═996bcf9b-cc10-40c1-86d8-9d41a3332d9b
# ╠═c9d26062-2cf3-4764-a527-abc952a7ebcc
# ╠═27c76275-ba77-4373-8f54-fdb2f5f14b64
# ╟─8df692b9-0099-4095-9d85-16675cb87f83
# ╠═c949f048-159f-4c96-8c70-2a9e6c1eef22
# ╠═8627240b-ee7d-4378-8739-24102aee09bf
# ╠═bb5c3017-7a60-4a7e-9a52-a70d9d917ba8
# ╟─744b13c3-5c7d-45e1-ac03-e1fb95dc6ebd
# ╠═4b59056c-86d4-47ee-a13e-e6c5b5b5d47d
# ╠═7a0ff0b0-36b0-4cd5-aff0-16877e762328
