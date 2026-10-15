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
- *Discontinuous*: a switching (two-step) λ sensor, about 0.85 V rich and 0.1 V lean with the
  jump at λ = 1. Idealized as a steep logistic step.
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
    lambda_V(λ) = 0.1 + 0.75 / (1 + exp((λ - 1) / 0.004))

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
