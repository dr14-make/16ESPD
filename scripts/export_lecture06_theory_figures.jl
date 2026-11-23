"""
Writes the Lecture 6 deck's theory figures into `slides/decks/lecture-06/public/figures/`.

    julia +dyad-3.5.0 --project=. scripts/export_lecture06_theory_figures.jl [figure ...]

Each figure is computed from a closed-form formula on its slide, with no Dyad model and no
notebook. Figure names as arguments (e.g. `08-phase-lag`) export only those.

- `04-bus-length`: the longest bus at which a bit's round trip still reaches the sample point.
- `05-frame-time`: the worst-case length of a classic base data frame against its data bytes.
- `05-frame-bits`: one whole frame on the wire, 1A0h carrying 87 km/h, with its CRC-15 computed
  and its stuff bits inserted.
- `06-quantization`: a ramp sent through 8 raw bits at factor 1 and at factor 0.1.
- `07-tec`: the transmit error counter of a node with a permanent and with an intermittent fault.
- `08-sample-hold`: a braking car's speed against what a receiver holds at three periods.
- `08-worst-case`: the critical instant of each frame in the deck's three-frame set.
- `08-load-vs-bitrate`: bus load and worst-case response time of that set against the bit rate.
- `08-phase-lag`: the phase a pure delay costs a sinusoid, against its frequency.
"""
module Lecture06TheoryFigures

using Plots
import PlotlyBase, PlotlyKaleido
plotly()
include(joinpath(@__DIR__, "plotly_svg.jl"))

const ROOT = normpath(@__DIR__, "..")
const OUT = joinpath(ROOT, "slides", "decks", "lecture-06", "public", "figures")

# Okabe–Ito: distinguishable under the common color-vision deficiencies.
const COLORS = ["#0072B2", "#E69F00", "#009E73", "#CC79A7"]

# Sized to read on a projected slide with the figure in half the slide's width.
Plots.default(; left_margin = 8Plots.mm, bottom_margin = 6Plots.mm, top_margin = 3Plots.mm,
    right_margin = 5Plots.mm, guidefontsize = 20, tickfontsize = 18, legendfontsize = 18,
    grid = true, gridalpha = 0.25)

# Bus length: a dominant edge from one end must reach the far end and the far node's own
# dominant bit must travel back before the sender samples. The electronics in that loop are two
# transceiver loop delays (TX driver + RX comparator, ≈ 150 ns each, typical datasheet value)
# and the two controllers (≈ 25 ns each).
const NS_PER_M = 5.0
const LOOP_NS = 2 * 150.0 + 2 * 25.0

"Longest bus [m] at `bitrate` [bit/s] with the sample point at fraction `sp` of the bit."
max_length(bitrate, sp) = max(0.0, (sp * 1e9 / bitrate - LOOP_NS) / (2 * NS_PER_M))

const RULE_OF_THUMB = [1e6 => 40, 500e3 => 100, 250e3 => 250, 125e3 => 500]

function bus_length_plot()
    rates = exp10.(range(5, 6; length = 200))
    kbit = rates ./ 1e3
    early, late = max_length.(rates, 0.75), max_length.(rates, 0.875)
    p = plot(; size = (900, 620), xscale = :log10, yscale = :log10,
        xlabel = "bit rate [kbit/s]", ylabel = "longest bus [m]", legend = :topright,
        xticks = ([100, 125, 250, 500, 1000], ["100", "125", "250", "500", "1000"]),
        yticks = ([20, 50, 100, 200, 500, 1000], ["20", "50", "100", "200", "500", "1000"]),
        xlims = (100, 1000), ylims = (20, 1000))
    plot!(p, kbit, late; fillrange = early, fillalpha = 0.25, color = COLORS[1], lw = 0,
        label = "")
    plot!(p, kbit, late; color = COLORS[1], lw = 3, label = "sample point 87.5 %")
    plot!(p, kbit, early; color = COLORS[1], lw = 3, ls = :dash, label = "sample point 75 %")
    scatter!(p, first.(RULE_OF_THUMB) ./ 1e3, last.(RULE_OF_THUMB); color = COLORS[2],
        markersize = 10, markerstrokecolor = :black, label = "rule of thumb")
    return p
end

# Classic base data frame with n data bytes: 47 fixed bits plus the data; stuffing can add one
# bit per four after the first over the 34 + 8n stuffed bits (SOF to the end of the CRC).
frame_bits(n) = 8n + 47
worst_frame_bits(n) = 8n + 47 + fld(34 + 8n - 1, 4)

const BITRATES = [125e3 => "125 kbit/s", 250e3 => "250 kbit/s", 500e3 => "500 kbit/s",
    1e6 => "1 Mbit/s"]

function frame_time_plot()
    n = 0:8
    p = plot(; size = (900, 620), xlabel = "data bytes", ylabel = "worst-case frame time [µs]",
        legend = :topleft, legendtitle = "worst case (max stuffing)", legendtitlefontsize = 16,
        xticks = 0:8, xlims = (-0.3, 8.6), ylims = (0, 1150))
    for (k, (rate, label)) in enumerate(BITRATES)
        t = worst_frame_bits.(n) ./ rate .* 1e6
        plot!(p, n, t; color = COLORS[k], lw = 3, marker = :circle, markersize = 6,
            markerstrokewidth = 0, label)
        annotate!(p, 8.15, t[end], text("$(round(Int, t[end]))", 16, :left, COLORS[k]))
    end
    return p
end

# Bremse_1 (1A0h) from section 06's DBC: 8 data bytes, vehicle speed at bit 17, 15 bits, Intel,
# factor 0.01 km/h. The 4-bit counter at bit 56 is 0 and every other bit is 0.
const SPEED_ID = 0x1A0
const SPEED_KMH = 87
const SPEED_RAW = round(Int, SPEED_KMH / 0.01)
const CRC15_POLY = 0x4599

bits_of(x, n) = [Int((x >> (n - k)) & 1) for k in 1:n]

"CAN's CRC-15 over `bits`, initial value 0."
function crc15(bits)
    crc = 0
    for b in bits
        feedback = b ⊻ ((crc >> 14) & 1)
        crc = (crc << 1) & 0x7fff
        feedback == 1 && (crc ⊻= CRC15_POLY)
    end
    return crc
end

"""
    wire_frame()

The bits of the 1A0h frame as sent: levels (0 dominant), whether each is a stuff bit, the field
each belongs to, and the CRC.
"""
function wire_frame()
    payload = UInt64(SPEED_RAW) << 17
    data = [bits_of((payload >> 8k) & 0xff, 8) for k in 0:7]
    fields = Pair{String, Vector{Int}}["SOF" => [0], "ID" => bits_of(SPEED_ID, 11),
        "RTR" => [0], "IDE" => [0], "r0" => [0], "DLC" => bits_of(8, 4)]
    append!(fields, ["data $k" => data[k + 1] for k in 0:7])
    crc = crc15(reduce(vcat, last.(fields)))
    push!(fields, "CRC" => bits_of(crc, 15))
    level, stuff, field = Int[], Bool[], String[]
    run, prev = 0, -1
    for (name, bits) in fields, b in bits
        push!(level, b); push!(stuff, false); push!(field, name)
        run = b == prev ? run + 1 : 1
        prev = b
        # A stuff bit starts the next run; after the CRC's last bit it still goes in.
        if run == 5
            push!(level, 1 - b); push!(stuff, true); push!(field, name)
            run, prev = 1, 1 - b
        end
    end
    for (name, bits) in ["CRC del" => [1], "ACK" => [0], "ACK del" => [1], "EOF" => ones(Int, 7),
            "IFS" => ones(Int, 3)], b in bits
        push!(level, b); push!(stuff, false); push!(field, name)
    end
    return (; level, stuff, field, crc, data = [evalpoly(2, reverse(d)) for d in data])
end

const STUFF_COLOR = "#D55E00"

function frame_group(name)
    name in ("SOF", "ID", "RTR") && return "ID", COLORS[1]
    name in ("IDE", "r0", "DLC") && return "DLC", COLORS[2]
    startswith(name, "data") && return name, COLORS[3]
    name == "CRC" && return "CRC", COLORS[4]
    return "end", "#999999"
end

function frame_bits_plot()
    f = wire_frame()
    n = length(f.level)
    groups = first.(frame_group.(f.field))
    labels = Dict("ID" => "ID $(uppercase(string(SPEED_ID; base = 16)))h", "DLC" => "DLC 8",
        "CRC" => "CRC $(uppercase(string(f.crc; base = 16)))h", "end" => "ACK, EOF")
    for k in 0:7
        labels["data $k"] = uppercase(string(f.data[k + 1]; base = 16, pad = 2)) * "h"
    end
    half = cld(n, 2)
    rows = [0:(half - 1), half:(n - 1)]
    lo, hi = 0.15, 0.85
    p = plot(; layout = (2, 1), size = (900, 620), legend = false)
    for (r, span) in enumerate(rows)
        x0, x1 = first(span), last(span) + 1
        plot!(p[r]; xlims = (x0, x1), ylims = (-0.05, 1.45),
            yticks = ([lo, hi], ["0 dom", "1 rec"]), xticks = x0:10:x1, grid = false,
            xlabel = r == 2 ? "bit on the wire" : "")
        i = first(span)
        while i <= last(span)
            j = i
            while j < last(span) && groups[j + 2] == groups[i + 1]
                j += 1
            end
            g, color = frame_group(f.field[i + 1])
            alpha = startswith(g, "data") && isodd(parse(Int, g[end:end])) ? 0.4 : 0.22
            plot!(p[r], Shape([i, j + 1, j + 1, i], [0, 0, 1, 1]); color, fillalpha = alpha,
                lw = 0, label = "")
            # A field split across the rows is named once, in the row holding most of it.
            2(j - i + 1) > count(==(g), groups) && annotate!(p[r], (i + j + 1) / 2, 1.2,
                text(labels[g], 15, g == "end" ? :black : color))
            i = j + 1
        end
        for k in span
            f.stuff[k + 1] || continue
            plot!(p[r], Shape([k, k + 1, k + 1, k], [0, 0, 1, 1]); color = STUFF_COLOR,
                fillalpha = 0.8, lw = 0, label = "")
        end
        y = [b == 0 ? lo : hi for b in f.level[span .+ 1]]
        plot!(p[r], [collect(span); x1], [y; y[end]]; seriestype = :steppost, color = :black,
            lw = 2, label = "")
    end
    annotate!(p[2], (n - 6.5), 0.5, text("$(count(f.stuff)) stuff bits", 15, STUFF_COLOR))
    return p
end

# 8 raw bits either way: factor 1 reaches 255; factor 0.1 is ten times finer but stops at 25.5.
const RAW_MAX = 255

received(v, factor) = clamp(round(Int, v / factor), 0, RAW_MAX) * factor

function quantization_plot()
    t = range(0, 10; length = 4001)
    v = 3.0 .* t
    p = plot(; size = (900, 620), xlabel = "time [s]", ylabel = "value", legend = :topleft,
        xlims = (0, 10), ylims = (0, 31), xticks = 0:2:10, yticks = 0:5:30)
    plot!(p, t, v; color = :black, lw = 2, ls = :dash, label = "sent")
    plot!(p, t, received.(v, 1.0); seriestype = :steppost, color = COLORS[1], lw = 3,
        label = "factor 1: 0 to 255")
    plot!(p, t, received.(v, 0.1); seriestype = :steppost, color = COLORS[2], lw = 3,
        label = "factor 0.1: 0 to 25.5")
    annotate!(p, 9.9, 25.5 - 1.3, text("25.5", 16, :right, COLORS[2]))
    return p
end

# Transmit error counter: +8 per failed send, −1 per good one, never below 0.
const TEC_LIMITS = [96 => "warning 96", 128 => "error passive > 127", 256 => "bus off > 255"]

function tec(failed)
    c, trace = 0, [0]
    for f in failed
        c = f ? c + 8 : max(c - 1, 0)
        push!(trace, c)
        c > 255 && break
    end
    return trace
end

function tec_plot()
    attempts = 60
    permanent = tec(trues(attempts))
    # One failure in nine sends: the eight good ones pay back exactly what it added.
    intermittent = tec([k % 9 == 1 for k in 1:attempts])
    p = plot(; size = (900, 620), xlabel = "send attempts", ylabel = "TEC", legend = :topleft,
        xlims = (0, attempts), ylims = (0, 290), xticks = 0:10:attempts,
        yticks = [0, 32, 64, 96, 128, 192, 256])
    for (level, label) in TEC_LIMITS
        hline!(p, [level]; color = :gray, lw = 1.5, ls = :dash, label = "")
        annotate!(p, attempts - 0.5, level + 9, text(label, 15, :right, :gray))
    end
    plot!(p, 0:(length(permanent) - 1), permanent; seriestype = :steppost, color = COLORS[1],
        lw = 3, label = "permanent fault")
    plot!(p, 0:attempts, intermittent; seriestype = :steppost, color = COLORS[2], lw = 3,
        label = "1 failure in 9")
    k = length(permanent) - 1
    scatter!(p, [k], [permanent[end]]; color = COLORS[1], markersize = 9,
        markerstrokecolor = :black, label = "")
    annotate!(p, k + 1, permanent[end] - 16,
        text("bus off after $k failures", 15, :left, COLORS[1]))
    return p
end

# Braking from 80 km/h with the deceleration building to 10 m/s² over about 80 ms.
const DECEL_KMH_S = 36.0
const JERK_S = 0.08
speed(t) = t <= 0 ? 80.0 : 80.0 - DECEL_KMH_S * (t - JERK_S * (1 - exp(-t / JERK_S)))

const PERIODS_MS = [10, 20, 40]

"""
What a receiver holds at `t` [s], as `CanLink` models it: sampled on the clock tick, delivered
one tick later (`UnitDelay`), then held, so the value is always 1 to 2 periods old.
"""
held(t, period) = round(speed(period * (fld(t, period) - 1)) / 0.01) * 0.01

function sample_hold_plot()
    t = range(0, 0.3; length = 3001)
    p = plot(; size = (900, 620), xlabel = "time [ms]", ylabel = "vehicle speed [km/h]",
        legend = :bottomleft, xlims = (0, 300), ylims = (71, 80.5), xticks = 0:50:300)
    plot!(p, 1e3 .* t, speed.(t); color = :black, lw = 3, label = "measured by the brake ECU")
    for (k, period) in enumerate(PERIODS_MS)
        plot!(p, 1e3 .* t, held.(t, period / 1e3); seriestype = :steppost, color = COLORS[k],
            lw = 3, label = "received, $period ms period")
    end
    # On the slowest trace: each sample, and an arrow to the tick at which the receiver gets it.
    slow, k = PERIODS_MS[end], length(PERIODS_MS)
    ticks = 0:slow:(300 - slow)
    for tk in ticks
        v = speed(tk / 1e3)
        plot!(p, [tk, tk + slow], [v, v]; color = COLORS[k], lw = 1.5, arrow = true, label = "")
    end
    scatter!(p, collect(ticks), speed.(ticks ./ 1e3); color = COLORS[k], markersize = 7,
        markerstrokecolor = :black, label = "$slow ms: sampled, delivered one period later")
    return p
end

# The deck's three-frame set: 8 data bytes each, IDs and periods from section 08.
const FRAME_SET = [(id = 0x070, period = 10e-3), (id = 0x1A0, period = 10e-3),
    (id = 0x300, period = 100e-3)]

hexid(id) = uppercase(string(id; base = 16, pad = 3)) * "h"

"""
    response_times(frames, bitrate)

Bus load and per-frame blocking, queuing and response time [s], as `can_schedule` computes them:
`frames` sorted by priority, all 8 bytes, worst-case stuffing.
"""
function response_times(frames, bitrate)
    c = worst_frame_bits(8) / bitrate
    load = sum(c / f.period for f in frames)
    rows = map(enumerate(frames)) do (i, f)
        blocking = i < length(frames) ? c : 0.0
        wait = blocking
        while true
            next = blocking +
                sum((ceil((wait + 1 / bitrate) / h.period) * c for h in frames[1:i-1]); init = 0.0)
            abs(next - wait) < 1e-14 && break
            wait = next
        end
        (; f..., c, blocking, wait, response = wait + c)
    end
    return (; load, frames = rows)
end

ms(x) = string(round(x; digits = 2))

function worst_case_plot()
    bitrate = 500e3
    rows = response_times(FRAME_SET, bitrate).frames
    m = length(rows)
    color = Dict(r.id => COLORS[k] for (k, r) in enumerate(rows))
    p = plot(; size = (900, 620), xlabel = "time after the frame is queued [ms]",
        ylabel = "worst case of", legend = false, xlims = (0, 1.2), ylims = (0.35, m + 0.7),
        xticks = 0:0.27:0.81, yticks = ((m:-1:1) .+ 0.225, [hexid(r.id) for r in rows]))
    vline!(p, [0]; color = :black, lw = 2)
    for (k, r) in enumerate(rows)
        y = m + 1 - k
        c, wait = 1e3 * r.c, 1e3 * r.wait
        hp = [(id = h.id, tag = "") for h in rows[1:k-1]
              for _ in 1:ceil(Int, (r.wait + 1 / bitrate) / h.period)]
        queue = [(r.blocking > 0 ? [(id = rows[end].id, tag = " = B")] : []); hp;
            (id = r.id, tag = " = C")]
        for (n, q) in enumerate(queue)
            x, own = (n - 1) * c, q.id == r.id
            plot!(p, Shape([x, x + c, x + c, x], [y, y, y + 0.45, y + 0.45]);
                color = color[q.id], fillalpha = own ? 1.0 : 0.35, linecolor = :black, lw = 1)
            annotate!(p, x + c / 2, y + 0.225,
                text(hexid(q.id) * q.tag, 15, own ? :white : :black))
        end
        plot!(p, [0, wait], [y - 0.1, y - 0.1]; color = :black, lw = 2, arrow = true)
        annotate!(p, wait / 2, y - 0.27, text("w = $(ms(wait))", 15))
        annotate!(p, 1e3 * r.response + 0.02, y + 0.225,
            text("R = $(ms(1e3 * r.response)) ms", 16, :left))
    end
    return p
end

const RATES = [125e3, 250e3, 500e3, 1e6]

sig3(x) = string(round(x; sigdigits = 3))

function load_vs_bitrate_plot()
    # The rates double from one to the next, so evenly spaced positions are a log scale; plotly
    # would place annotations on a log axis in log units.
    x = eachindex(RATES)
    results = response_times.(Ref(FRAME_SET), RATES)
    load = [100 * r.load for r in results]
    resp(i) = [1e3 * r.frames[i].response for r in results]
    ticks = (x, ["125", "250", "500", "1000"])
    p = plot(; layout = (2, 1), size = (900, 720), link = :x)
    plot!(p[1]; xticks = (x, fill("", length(x))), xlims = (0.45, 4.6), ylims = (0, 27),
        ylabel = "bus load [%]", legend = false)
    plot!(p[1], x, load; color = COLORS[3], lw = 3, marker = :circle, markersize = 7,
        markerstrokewidth = 0)
    for (xi, y) in zip(x, load)
        annotate!(p[1], xi + 0.06, y + 2.2, text(sig3(y), 15, :left, COLORS[3]))
    end
    plot!(p[2]; xticks = ticks, xlims = (0.45, 4.6), ylims = (0, 3.8),
        xlabel = "bit rate [kbit/s]", ylabel = "worst-case R [ms]", legend = :topright)
    # 1A0h and 300h have the same R at every rate, so they share one line.
    for (k, (i, label, dx, dy, align)) in enumerate([(1, "070h", -0.06, -0.12, :right),
            (2, "1A0h, 300h", 0.06, 0.3, :left)])
        r = resp(i)
        plot!(p[2], x, r; color = COLORS[k], lw = 3, marker = :circle, markersize = 7,
            markerstrokewidth = 0, label)
        for (xi, y) in zip(x, r)
            annotate!(p[2], xi + dx, y + dy, text(sig3(y), 15, align, COLORS[k]))
        end
    end
    return p
end

const DELAYS_MS = [5, 10, 20, 40]

function phase_lag_plot()
    f = range(0, 10; length = 201)
    p = plot(; size = (900, 620), xlabel = "frequency [Hz]", ylabel = "phase lag [°]",
        legend = :topleft, xlims = (0, 10.9), ylims = (0, 150), xticks = 0:2:10, yticks = 0:30:150)
    for (k, tau) in enumerate(DELAYS_MS)
        phi = 360 .* f .* tau ./ 1e3
        plot!(p, f, phi; color = COLORS[k], lw = 3, label = "τ = $tau ms")
        annotate!(p, 10.1, phi[end], text("$(round(Int, phi[end]))°", 16, :left, COLORS[k]))
    end
    return p
end

const FIGURES = Dict("04-bus-length" => bus_length_plot, "05-frame-time" => frame_time_plot,
    "05-frame-bits" => frame_bits_plot, "06-quantization" => quantization_plot,
    "07-tec" => tec_plot, "08-sample-hold" => sample_hold_plot,
    "08-worst-case" => worst_case_plot, "08-load-vs-bitrate" => load_vs_bitrate_plot,
    "08-phase-lag" => phase_lag_plot)

function main(wanted = String[])
    wanted = isempty(wanted) ? sort!(collect(keys(FIGURES))) : wanted
    unknown = setdiff(wanted, keys(FIGURES))
    isempty(unknown) || error("no such figure: $(join(sort!(unknown), ", "))")
    mkpath(OUT)
    for name in wanted
        path = save_svg(FIGURES[name](), joinpath(OUT, "$name.svg"))
        println("wrote $(relpath(path, ROOT))")
    end
end

end # module

Lecture06TheoryFigures.main(ARGS)
