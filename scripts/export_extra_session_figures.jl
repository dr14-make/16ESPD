"""
Writes the extra session deck's figures into `slides/decks/extra-session/public/figures/`.

    julia +dyad-3.5.0 --startup-file=no scripts/export_extra_session_figures.jl [figure ...]

Figure names as arguments (e.g. `04-cc-cv`) write only those. Two kinds of figure, neither from a
Dyad model, so none needs a notebook:

- published data redrawn from the tables in `data/extra_session/` (pack prices, OCV, charging
  curves, charging points, Mirai polarization points, the power-to-wheel chain);
- formula plots of the closed-form cell and stack models (pulse response, SoC drift, CC-CV,
  polarization curve), with their parameters as constants below.

Every value and its source is in `data/extra_session/README.md`, which points into
`docs/research_notes/Electric and hybrid vehicles/`.
"""
module ExtraSessionFigures

using Plots, Printf
import PlotlyBase, PlotlyKaleido
plotly()
include(joinpath(@__DIR__, "plotly_svg.jl"))

const ROOT = normpath(@__DIR__, "..")
const DATA = joinpath(ROOT, "data", "extra_session")
const OUT = joinpath(ROOT, "slides", "decks", "extra-session", "public", "figures")

Plots.default(; left_margin = 7Plots.mm, bottom_margin = 6Plots.mm, top_margin = 3Plots.mm,
    right_margin = 5Plots.mm, titlefontsize = 15, legendfontsize = 13, guidefontsize = 15,
    tickfontsize = 13)

const BLUE, ORANGE, GREEN, RED, GRAY = "#1f5fa8", "#d9730d", "#2e8b57", "#c0392b", "#7f7f7f"

"Rows of a CSV with a header line, as named tuples of strings; `#` lines are comments."
function read_table(name)
    lines = filter(l -> !isempty(strip(l)) && !startswith(l, "#"),
        readlines(joinpath(DATA, name)))
    header = Symbol.(split(lines[1], ','))
    return [NamedTuple{Tuple(header)}(Tuple(strip.(split(l, ',')))) for l in lines[2:end]]
end

num(s) = parse(Float64, s)
column(rows, name) = num.(getfield.(rows, name))
thousands(x) = replace(string(round(Int, x)), r"(?<=\d)(?=(\d{3})+$)" => ",")

"An axis-aligned rectangle."
box(x0, x1, y0, y1) = Shape([x0, x1, x1, x0], [y0, y0, y1, y1])

# 2013 Leaf cell, pulse 5 (≈ 60 % SoC) of the 1-RC fit to ORNL's HPPC log (bms.md §1, derived).
const LEAF_CELL = (; R0 = 1.60e-3, R1 = 1.34e-3, tau = 25.7, ocv_60 = 3.949, Q_ah = 33.1)

"""
Monotone cubic (Fritsch–Carlson) interpolation through `(x, y)`, so the 10 % OCV table gives a
curve with no overshoot and no kinks for the charge simulation to trip on.
"""
function pchip(x, y)
    n = length(x)
    h = diff(x)
    d = diff(y) ./ h
    m = similar(y)
    m[1], m[n] = d[1], d[n-1]
    for k in 2:n-1
        m[k] = d[k-1] * d[k] <= 0 ? 0.0 :
               (w1 = 2h[k] + h[k-1]; w2 = h[k] + 2h[k-1]; (w1 + w2) / (w1 / d[k-1] + w2 / d[k]))
    end
    return function (t)
        k = clamp(searchsortedlast(x, t), 1, n - 1)
        s = (t - x[k]) / h[k]
        h00, h10, h01, h11 = 2s^3 - 3s^2 + 1, s^3 - 2s^2 + s, -2s^3 + 3s^2, s^3 - s^2
        return h00 * y[k] + h10 * h[k] * m[k] + h01 * y[k+1] + h11 * h[k] * m[k+1]
    end
end

function pack_price_plot()
    rows = read_table("pack_price_split.csv")
    year, pack, cell, rest = (column(rows, c) for c in (:year, :pack, :cell, :rest))
    all(pack .== cell .+ rest) || error("pack_price_split.csv: cell + rest ≠ pack")
    p = plot(; xlabel = "year", ylabel = "Li-ion pack price [\$/kWh, real 2025]",
        size = (960, 640), legend = :topright, xticks = year[1]:1:year[end],
        xlims = (year[1] - 0.6, year[end] + 0.6), ylims = (0, 1.1 * maximum(pack)))
    for (k, (x, c, r)) in enumerate(zip(year, cell, rest))
        plot!(p, box(x - 0.38, x + 0.38, 0, c); color = BLUE, linecolor = BLUE,
            label = k == 1 ? "cell" : "")
        plot!(p, box(x - 0.38, x + 0.38, c, c + r); color = "#9dbbe0", linecolor = "#9dbbe0",
            label = k == 1 ? "rest of pack" : "")
    end
    annotate!(p, [(x, t, text("$(round(Int, t))", 12, :bottom)) for (x, t) in zip(year, pack)])
    return p
end

function ocv_soc_plot()
    nmc = read_table("nmc_ocv_chen2020.csv")
    leaf = read_table("leaf_c3_discharge.csv")
    soc, ocv = column(nmc, :soc_pct), column(nmc, :ocv_v)
    f = pchip(soc, ocv)
    s = range(0, 100; length = 401)
    p = plot(; xlabel = "state of charge [%]", ylabel = "voltage per cell [V]",
        size = (960, 640), legend = :bottomright, xlims = (0, 100), ylims = (2.4, 4.3),
        xticks = 0:10:100)
    plot!(p, box(10, 90, 2.4, 4.3); color = GRAY, fillalpha = 0.10, lw = 0,
        label = "Leaf window 10–90 %")
    plot!(p, s, f.(s); color = BLUE, lw = 3, label = "NMC 811 (LG M50) OCV, derived")
    scatter!(p, soc, ocv; color = BLUE, ms = 5, label = "")
    plot!(p, column(leaf, :soc_pct), column(leaf, :v_per_element); color = ORANGE, lw = 2.5,
        ls = :dash, marker = :diamond, ms = 6, label = "2013 Leaf, loaded at C/3 (INL)")
    return p
end

"""
The ORNL Leaf cell through one USABC EV HPPC profile: 30 s at `I`, 40 s rest, 10 s at −0.75 `I`,
discharge positive, with the OCV held at its pulse-5 rest value (0.25 A·h leaves, about 3 mV of
OCV).
"""
function pulse_response()
    (; R0, R1, tau, ocv_60) = LEAF_CELL
    I = 30.0
    current(t) = 0 <= t < 30 ? I : 70 <= t < 80 ? -0.75I : 0.0
    dt = 0.2
    t = collect(-10:dt:150)
    i = current.(t)
    v1 = zeros(length(t))
    for k in 2:length(t)
        # Exact update of v1' = (R1 i − v1)/τ for the current held over the step.
        a = exp(-dt / tau)
        v1[k] = a * v1[k-1] + (1 - a) * R1 * i[k-1]
    end
    v = ocv_60 .- R0 .* i .- v1
    return (; t, i, v, v1, ocv = ocv_60, R0)
end

function pulse_response_plot()
    r = pulse_response()
    sag = r.v1[findfirst(>=(30), r.t)] * 1e3
    @printf("  pulse: R0 I = %.1f mV, sag by 30 s = %.1f mV, total %.1f mV\n",
        r.R0 * 30e3, sag, r.R0 * 30e3 + sag)
    mv(x) = (x - r.ocv) * 1e3
    top = plot(r.t, r.i; color = BLUE, lw = 2.5, label = "", ylabel = "current [A]",
        ylims = (-30, 40), yticks = ([-22.5, 0, 30], ["−22.5", "0", "30"]), xformatter = _ -> "", legend = :none)
    hline!(top, [0]; color = GRAY, lw = 1, label = "")
    annotate!(top, [(15, 33, text("discharge 30 A, 30 s", 12, :bottom)),
        (50, 3, text("rest 40 s", 12, :bottom)),
        (82, -24, text("regen 22.5 A, 10 s", 12, :left))])
    bottom = plot(; xlabel = "time [s]", ylabel = "v − OCV [mV]", ylims = (-90, 50),
        legend = :bottomright)
    hline!(bottom, [0]; color = GRAY, lw = 1, ls = :dot, label = "OCV = 3.949 V")
    plot!(bottom, r.t, mv.(r.ocv .- r.R0 .* r.i); color = GRAY, lw = 2, ls = :dash,
        label = "Lecture 4: E − R₀ i")
    plot!(bottom, r.t, mv.(r.v); color = ORANGE, lw = 3, label = "Thevenin cell")
    annotate!(bottom, [(1, -24, text("R₀I = 48 mV", 12, :left)),
        (31, -62, text("+ 27.7 mV sag by 30 s", 12, :left)),
        (100, 12, text("recovery, τ₁ = 25.7 s", 12, :left))])
    return plot(top, bottom; layout = grid(2, 1; heights = [0.35, 0.65]), size = (960, 680),
        xlims = (-10, 150), link = :x)
end

"""
SoC error of coulomb counting on a 33 A·h cell: a 50 mA offset, reset to zero by an OCV
reading on the days in `resets`; and the ±1σ spread of zero-mean 10 mA noise, Movassagh's
0.0544 % at 24 h on 1.5 A·h, scaled by capacity and growing as √t.
"""
function soc_drift_plot(; resets = [2.0, 4.0, 6.0])
    Q, offset = 33.0, 0.050
    rate = offset * 24 / Q * 100                # % per day
    days = range(0, 7; length = 1401)
    since_reset(d) = (k = findlast(<=(d), resets); k === nothing ? d : d - resets[k])
    err = [rate * since_reset(d) for d in days]
    sigma = 0.0544 * (1.5 / Q) .* sqrt.(days)
    @printf("  drift: %.2f %%/day; noise σ after 7 d %.4f %%\n", rate, sigma[end])
    p = plot(; xlabel = "time [days]", ylabel = "SoC error [%]", size = (960, 640),
        legend = :topright, xlims = (0, 7), ylims = (-1.4, 14), xticks = 0:7)
    plot!(p, days, rate .* days; color = BLUE, lw = 2, ls = :dot,
        label = "50 mA offset, never reset")
    plot!(p, days, sigma; fillrange = -sigma, color = GREEN, fillalpha = 0.5, lw = 1,
        label = "10 mA noise, ±1σ")
    plot!(p, days, err; color = BLUE, lw = 3, label = "50 mA offset, OCV reset")
    hline!(p, [5]; color = RED, lw = 2, ls = :dash, label = "GB/T 38661: 5 %")
    vline!(p, resets; color = GRAY, lw = 1.5, ls = :dash, label = "OCV reset")
    annotate!(p, [(1.0, rate + 0.4, text("3.6 %/day", 12, :right, :bottom, BLUE)),
        (0.1, -0.35, text("noise: ±$(@sprintf("%.4f", sigma[end])) % at 7 days", 12, :left,
            :top, GREEN))])
    return p
end

"""
CC-CV charge of the section 02 Thevenin cell from rest at 10 % SoC, with the NMC 811 OCV curve:
CC at `c_rate`, CV at `v_max`, stop at `C/end_div`.
"""
function cc_cv(; c_rate = 0.5, v_max = 4.20, end_div = 50, soc0 = 0.10, dt = 2.0)
    (; R0, R1, tau, Q_ah) = LEAF_CELL
    nmc = read_table("nmc_ocv_chen2020.csv")
    ocv = let f = pchip(column(nmc, :soc_pct), column(nmc, :ocv_v)); s -> f(100s) end
    Q = Q_ah * 3600
    i_cc, i_end = c_rate * Q_ah, Q_ah / end_div
    t, soc, v1 = 0.0, soc0, 0.0
    out = (; t = Float64[], i = Float64[], v = Float64[], ocv = Float64[], soc = Float64[])
    t_cv = NaN
    while true
        # Charging current positive; terminal voltage v = OCV + R0 i + v1.
        i = ocv(soc) + R0 * i_cc + v1 < v_max ? i_cc : (v_max - ocv(soc) - v1) / R0
        isnan(t_cv) && i < i_cc && (t_cv = t)
        push!(out.t, t); push!(out.i, i); push!(out.v, ocv(soc) + R0 * i + v1)
        push!(out.ocv, ocv(soc)); push!(out.soc, soc)
        i <= i_end && break
        a = exp(-dt / tau)
        v1 = a * v1 + (1 - a) * R1 * i
        soc += i * dt / Q
        t += dt
    end
    k = findfirst(>=(t_cv), out.t)
    return (; out..., t_cv, soc_cv = out.soc[k], ocv_cv = out.ocv[k], i_cc, i_end, c_rate,
        v_max)
end

function cc_cv_plot()
    r = cc_cv()
    m = r.t ./ 60
    @printf("  cc-cv: CC %.2f A to %.1f min at SoC %.1f %% (OCV %.3f V); end %.0f min, %.0f mA, SoC %.1f %%, OCV %.3f V\n",
        r.i_cc, r.t_cv / 60, 100r.soc_cv, r.ocv_cv, m[end], 1e3r.i[end], 100r.soc[end],
        r.ocv[end])
    tmax = 10 * ceil(m[end] / 10) + 5
    cv = r.t_cv / 60
    common = (; xlims = (0, tmax), xticks = 0:15:tmax)
    pi_ = plot(m, r.i; color = BLUE, lw = 3, label = "", ylabel = "current [A]",
        ylims = (0, 19), xformatter = _ -> "", legend = :none, common...)
    hline!(pi_, [r.i_end]; color = GRAY, ls = :dot, lw = 1.5, label = "")
    annotate!(pi_, [(cv / 2, r.i_cc + 0.5, text(@sprintf("CC %.2f A = 0.5C", r.i_cc), 12,
            :bottom)),
        (tmax - 2, r.i_end + 0.4, text(@sprintf("stop at C/50 = %.2f A", r.i_end), 12, :right,
            :bottom))])
    pv = plot(m, r.v; color = ORANGE, lw = 3, label = "terminal v", ylabel = "voltage [V]",
        ylims = (3.2, 4.35), legend = :topleft, xformatter = _ -> "", common...)
    plot!(pv, m, r.ocv; color = ORANGE, lw = 2, ls = :dash, label = "OCV")
    hline!(pv, [r.v_max]; color = GRAY, ls = :dot, lw = 1.5, label = "")
    annotate!(pv, cv - 1, 4.22, text(@sprintf("CV at 4.20 V from %.0f min →", cv), 12, :right, :bottom))
    ps = plot(m, 100 .* r.soc; color = GREEN, lw = 3, label = "", ylabel = "SoC [%]",
        xlabel = "time [min]", ylims = (0, 105), yticks = 0:25:100, legend = :none, common...)
    for q in (pi_, pv, ps)
        vline!(q, [cv]; color = GRAY, ls = :dash, lw = 1.5, label = "")
    end
    return plot(pi_, pv, ps; layout = grid(3, 1; heights = [0.3, 0.38, 0.32]),
        size = (960, 760), link = :x)
end

function charge_curves()
    rows = read_table("fastned_charge_curves.csv")
    cars = unique(getfield.(rows, :car))
    return [(car, column(filter(r -> r.car == car, rows), :soc_pct),
        column(filter(r -> r.car == car, rows), :kw)) for car in cars]
end

function leaf_chademo_plot()
    car, soc, kw = only(filter(c -> startswith(c[1], "Leaf"), charge_curves()))
    p = plot(soc, kw; color = ORANGE, lw = 3, marker = :circle, ms = 6, label = "",
        legend = :none, xlabel = "state of charge [%]", ylabel = "charging power [kW]",
        size = (960, 640),
        xlims = (0, 100), ylims = (0, 55), xticks = 0:10:100)
    for (s, k, place) in [(17, 42.2, :top), (60, 45.63, :bottom), (70, 32.75, :left),
        (80, 26.03, :left), (90, 20.17, :left)]
        label = text(string(k), 12, place)
        place === :left ? annotate!(p, s + 1.5, k, label) :
        annotate!(p, s, k + (place === :top ? -1.2 : 1.2), label)
    end
    annotate!(p, 38, 49, text("peak 45.63 kW at 57 and 60 %", 12, :center, :bottom))
    return p
end

function dc_curves_plot()
    labels = Dict("Leaf 40 kWh" => "Nissan Leaf 40 kWh (CHAdeMO)",
        "ID.3 Pro S 77 kWh" => "VW ID.3 Pro S 77 kWh, 400 V",
        "Model Y LR 2025+" => "Tesla Model Y LR 2025+, 400 V",
        "IONIQ 5 84 kWh" => "Hyundai IONIQ 5 84 kWh, 800 V")
    colors = Dict("Leaf 40 kWh" => ORANGE, "ID.3 Pro S 77 kWh" => BLUE,
        "Model Y LR 2025+" => RED, "IONIQ 5 84 kWh" => GREEN)
    p = plot(; xlabel = "state of charge [%]", ylabel = "charging power [kW]",
        size = (960, 640), legend = :topright, xlims = (0, 100), ylims = (0, 300),
        xticks = 0:10:100)
    for car in ["IONIQ 5 84 kWh", "Model Y LR 2025+", "ID.3 Pro S 77 kWh", "Leaf 40 kWh"]
        _, soc, kw = only(filter(c -> c[1] == car, charge_curves()))
        plot!(p, soc, kw; color = colors[car], lw = 3, marker = :circle, ms = 4,
            label = labels[car])
    end
    return p
end

function network_plot()
    rows = read_table("eafo_charging_points.csv")
    classes = unique(getfield.(rows, :class))
    colors = ["#c6d9ef", "#6b9fd4", "#1f5fa8", "#fbd3a8", "#f5a25d", "#d9730d", "#8c3b06"]
    years = ["2024", "2025", "2026"]
    ticklabels = ["2024", "2025", "Sep 2026"]
    panels = map(enumerate(["Czechia", "EU27"])) do (n, region)
        scale = region == "EU27" ? 1e-3 : 1.0
        # The EU panel runs on past its bars to hold the legend.
        p = plot(; title = region, xticks = (1:3, ticklabels),
            xlims = (0.4, region == "EU27" ? 5.9 : 3.6),
            ylabel = region == "EU27" ? "public charging points [thousands]" :
                     "public charging points",
            legend = n == 2 ? :topright : :none)
        totals = Float64[]
        for (x, year) in enumerate(years)
            r = filter(r -> r.region == region && r.year == year, rows)
            counts = [num(only(filter(q -> q.class == c, r)).points) for c in classes]
            total = sum(counts)
            dc = sum(counts[startswith.(classes, "DC")])
            fast = sum(counts[[c in ("DC 150–350 kW", "DC ≥ 350 kW") for c in classes]])
            push!(totals, total)
            y = 0.0
            for (k, c) in enumerate(counts)
                plot!(p, box(x - 0.32, x + 0.32, y, y + c * scale); color = colors[k],
                    linecolor = colors[k], label = x == 1 ? classes[k] : "")
                y += c * scale
            end
            annotate!(p, [(x, y * 1.02, text(thousands(total), 13, :bottom)),
                (x, y * 1.10, text(@sprintf("DC %.1f %%", 100dc / total), 12, :bottom)),
                (x, y * 1.18, text(@sprintf("≥150: %.1f %%", 100fast / total), 12,
                    :bottom))])
        end
        ylims!(p, 0, 1.32 * maximum(totals) * scale)
        p
    end
    return plot(panels...; layout = grid(1, 2; widths = [0.38, 0.62]), size = (1200, 620),
        left_margin = 9Plots.mm)
end

"Pukrushpan's P2000 cell at 80 °C, 2.5 bar, λ_m = 14 (pem-polarization.md §1), i in A/cm²."
polarization_losses(i) = (; act = 0.178 * (1 - exp(-10i)), ohm = 0.1575i,
    conc = i * (0.390i / 2.2)^2)
cell_voltage(i) = (l = polarization_losses(i); 0.950 - l.act - l.ohm - l.conc)

function polarization_plot()
    i = collect(range(0, 2.2; length = 441))
    l = polarization_losses.(i)
    a = 0.950 .- getfield.(l, :act)
    b = a .- getfield.(l, :ohm)
    v = cell_voltage.(i)
    k = argmax(i .* v)
    @printf("  polarization: V(0.1, 0.5, 1, 1.5) = %s; max power %.3f W/cm² at %.2f A/cm²; V(2.2) = %.3f\n",
        join((@sprintf("%.3f", cell_voltage(x)) for x in (0.1, 0.5, 1.0, 1.5)), ", "),
        i[k] * v[k], i[k], v[end])
    mirai = read_table("mirai_polarization.csv")
    p = plot(; xlabel = "current density [A/cm²]", ylabel = "cell voltage [V]",
        size = (960, 640), legend = :bottomleft, xlims = (0, 2.45), ylims = (0, 1.0),
        xticks = 0:0.5:2.0, grid = false)
    plot!(p, i, fill(0.950, length(i)); fillrange = a, color = "#f5a25d", fillalpha = 0.45,
        lw = 0, label = "activation")
    plot!(p, i, a; fillrange = b, color = "#6b9fd4", fillalpha = 0.45, lw = 0,
        label = "ohmic")
    plot!(p, i, b; fillrange = v, color = "#b39ddb", fillalpha = 0.55, lw = 0,
        label = "concentration")
    plot!(p, [0, 2.2], [0.950, 0.950]; color = GRAY, lw = 1.5, ls = :dash, label = "")
    plot!(p, i, v; color = :black, lw = 3, label = "P2000 model, 80 °C, 2.5 bar")
    scatter!(p, column(mirai, :i_a_per_cm2), column(mirai, :v_cell); yerror = 0.014,
        color = RED, ms = 6, markerstrokecolor = RED, label = "2017 Mirai stack, ANL")
    annotate!(p, 2.18, 0.962, text("0.950 V", 12, :right, :bottom, GRAY))
    # A second Plots axis does not survive the Kaleido export, and Plots drops annotations
    # outside the axes, so the η scale is drawn by hand inside a widened x range.
    plot!(p, [2.2, 2.2], [0, 1.0]; color = :black, lw = 1, label = "")
    for eta in 0:10:70
        y = eta / 100 * 1.253
        plot!(p, [2.2, 2.225], [y, y]; color = :black, lw = 1, label = "")
        annotate!(p, 2.235, y, text("$eta", 13, :left))
    end
    annotate!(p, 2.3, 0.985, text("η<sub>LHV</sub> [%]", 14, :center, :bottom))
    return p
end

function efficiency_chain_plot()
    rows = read_table("agora_efficiency_chain.csv")
    printed = Dict("BEV" => 69, "FCEV" => 26)
    chains = ["BEV", "FCEV"]
    n = [count(r -> r.chain == c, rows) + 1 for c in chains]
    panels = map(chains) do chain
        r = filter(r -> r.chain == chain, rows)
        steps = ["renewable electricity"; String.(getfield.(r, :step))]
        eff = [100.0; column(r, :efficiency_pct)]
        left = cumprod(eff ./ 100) .* 100
        m = length(steps)
        color = chain == "BEV" ? BLUE : GREEN
        p = plot(; title = chain, xlims = (0, 118), ylims = (0.4, m + 0.6),
            yticks = (1:m, reverse([k == 1 ? s : "$s ×$(round(Int, e)) %"
                                    for (k, (s, e)) in enumerate(zip(steps, eff))])),
            xticks = 0:20:100, legend = :none)
        for (k, x) in enumerate(left)
            y = m + 1 - k
            plot!(p, box(0, x, y - 0.36, y + 0.36); color, linecolor = color,
                fillalpha = k == m ? 1.0 : 0.55)
            label = k == m ? "$(printed[chain]) %" : k == 1 ? "100" : @sprintf("%.1f", x)
            annotate!(p, x + 1.2, y, text(label, k == m ? 15 : 12, :left))
        end
        @printf("  %s: %.1f %% (printed %d %%)\n", chain, left[end], printed[chain])
        abs(left[end] - printed[chain]) < 0.5 || error("$chain chain ≠ printed total")
        p
    end
    xlabel!(panels[end], "energy left [% of the renewable electricity]")
    return plot(panels...; layout = grid(2, 1; heights = n ./ sum(n)), size = (960, 700),
        left_margin = 4Plots.mm)
end

const FIGURES = [
    "01-pack-price" => pack_price_plot,
    "02-ocv-soc" => ocv_soc_plot,
    "02-pulse-response" => pulse_response_plot,
    "03-soc-drift" => soc_drift_plot,
    "04-cc-cv" => cc_cv_plot,
    "04-leaf-chademo" => leaf_chademo_plot,
    "04-dc-curves" => dc_curves_plot,
    "04-network" => network_plot,
    "05-polarization" => polarization_plot,
    "07-efficiency-chain" => efficiency_chain_plot,
]

function main(wanted = String[])
    unknown = setdiff(wanted, first.(FIGURES))
    isempty(unknown) || error("no such figure: $(join(sort!(unknown), ", "))")
    mkpath(OUT)
    for (name, make) in FIGURES
        isempty(wanted) || name in wanted || continue
        path = save_svg(make(), joinpath(OUT, "$name.svg"))
        println("  $name.svg  $(filesize(path) ÷ 1000) kB")
    end
    PlotlyKaleido.kill_kaleido()
end

end

ExtraSessionFigures.main(ARGS)
