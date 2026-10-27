"""
Writes the checkpoint figures of the Lecture 3 live build into `slides/images/lecture-03/`.

    julia +dyad-3.5.0 --project=. scripts/export_lecture03_build_figures.jl

Runs the reference solutions in `dyad/HandsOn03/` and the library analyses beside them, and
saves one SVG per build step. It also draws `03-abs-cycle-ours.svg` into the deck's diagrams: two
cycles of the snow run in the hand-drawn style of `03-abs-cycle.svg`, Bosch's cycle, so the
control-cycle slide can set them side by side. `slides/scripts/images.mjs` copies the folder into the lecture-03
deck and the build guide page.
"""

using VehicleSystemsComponents, Plots
using DyadInterface: symbolic_container, ODEAlg

const V = VehicleSystemsComponents.Vehicle
const H = VehicleSystemsComponents.HandsOn03
const OUT = normpath(@__DIR__, "..", "slides", "images", "lecture-03")
const G = 9.80665
const T_PEAK = 1.0 * 1400 * G * 0.31
# Wheel pressure at which the two calipers of HydraulicBrakedWheel put T_PEAK on the wheel.
const P_PEAK = T_PEAK / (49.0e-5 + 19.9e-5) + 0.5e5
const BAR = 1e-5
const DIAGRAMS = normpath(@__DIR__, "..", "slides", "decks", "lecture-03", "public", "diagrams")

stop_time(mu, a_max = Inf) = 0.5 + 1.5 * 25 / min(0.7 * mu * G, a_max) + 1.0
# A 2 ms grid resolves the true-slip ABS's 26 Hz ripple and keeps each SVG a few hundred kB.
function trace(run, f; dt = 0.002, from = 0.0, to = run.sol.t[end])
    ts = collect(from:dt:to)
    return ts, run.sol(ts, idxs = f(symbolic_container(run))).u
end
in_bar((t, p)) = (t, BAR .* p)

default(; size = (900, 520), lw = 2.5, fontfamily = "sans-serif", legend = :topright,
    titlefontsize = 13, guidefontsize = 11, tickfontsize = 10, legendfontsize = 10,
    left_margin = 6Plots.mm, bottom_margin = 4Plots.mm)

function save(plot, name)
    path = joinpath(OUT, "$name.svg")
    savefig(plot, path)
    filesize(path) > 0 || error("$name.svg was written empty")
    println("  $name.svg")
end

mkpath(OUT)

pedal_stop = H.PedalStopTransient()
let (t, v) = trace(pedal_stop, m -> m.body.mass.v), (_, w) = trace(pedal_stop, m -> m.wheel.inertia.w),
    (_, kappa) = trace(pedal_stop, m -> m.wheel.kappa)
    d = V.braking_distance(pedal_stop)
    p1 = plot(t, 3.6 .* v; label = "car", color = :firebrick, ylabel = "speed [km/h]",
        title = "Hydraulic pedal stop: $(round(d; digits = 1)) m from 90 km/h")
    plot!(p1, t, 3.6 .* 0.31 .* w; label = "wheel (ω·r)", color = :black, ls = :dash)
    p2 = plot(t, kappa; label = "wheel.kappa", color = :firebrick, ylabel = "slip [–]",
        xlabel = "time [s]", ylims = (-1.05, 0.05), legend = :right)
    save(plot(p1, p2; layout = (2, 1), size = (900, 620)), "step02-locked-stop")
end

present = H.ABSStopTransient(T_p = 0.0)
ahead = H.ABSStopTransient()
let
    d_a, d_c = V.braking_distance(present), V.braking_distance(ahead)
    p1 = plot(; ylabel = "front wheel pressure [bar]", ylims = (0, 100), legend = :bottomright,
        title = "Your ABS: $(round(d_a; digits = 1)) m without look-ahead, $(round(d_c; digits = 1)) m with it")
    plot!(p1, in_bar(trace(ahead, m -> m.master.p_mc))...; label = "master cylinder", color = :gray, lw = 1.5)
    plot!(p1, in_bar(trace(present, m -> m.wheel.caliper_f.p))...; label = "A: T_p = 0", color = :darkorange)
    plot!(p1, in_bar(trace(ahead, m -> m.wheel.caliper_f.p))...; label = "C: T_p = 30 ms", color = :steelblue)
    hline!(p1, [BAR * P_PEAK]; color = :gray, ls = :dot, label = "tire peak")
    p2 = plot(; ylabel = "slip [–]", xlabel = "time [s]", ylims = (-0.4, 0.02), legend = :bottomright)
    plot!(p2, trace(present, m -> m.wheel.kappa)...; label = "A", color = :darkorange, lw = 1.5)
    plot!(p2, trace(ahead, m -> m.wheel.kappa)...; label = "C", color = :steelblue, lw = 1.5)
    hline!(p2, [-0.04]; color = :gray, ls = :dot, label = "peak −0.04")
    hline!(p2, [-0.12]; color = :gray, ls = :dash, label = "sliding −0.12")
    save(plot(p1, p2; layout = (2, 1), size = (900, 620), xlims = (0, 4.5)), "step03-abs-torque-slip")
end

# Snow, where each dump empties the caliper and the wheel spins back up past +a_plus: all three
# phases show.
snow = H.ABSStopWheelOnlyTransient(road_mu = 0.3, stop = stop_time(0.3, 8.0))
let win = (1.0, 2.5), zoom(f) = trace(snow, f; dt = 5e-4, from = win[1], to = win[2]),
    (t, phase) = zoom(m -> m.abs.phase), (_, p) = zoom(m -> m.abs.p_cmd),
    (_, p_w) = zoom(m -> m.wheel.caliper_f.p),
    (_, v) = zoom(m -> m.body.mass.v), (_, v_w) = zoom(m -> m.est.v_w),
    (_, v_ref) = zoom(m -> m.est.v_ref)
    d = V.braking_distance(snow)
    p1 = plot(; ylabel = "pressure [bar]", ylims = (0, 30), legend = :topright,
        title = "Your three-phase ABS, wheel speed only, μ = 0.3: $(round(d; digits = 1)) m")
    # One shaded span per phase run; the colors match the state diagram on the slide.
    # Okabe–Ito blue, yellow and vermilion: apart for every common color-vision deficiency.
    shades = Dict(-1 => (colorant"#D55E00", "dump"), 0 => (colorant"#F0E442", "hold"),
        1 => (colorant"#0072B2", "build"))
    seen = Set{Int}()
    k = 1
    while k !== nothing
        ph = round(Int, phase[k])
        e = something(findnext(x -> round(Int, x) != ph, phase, k), length(t))
        color, name = shades[ph]
        vspan!(p1, [t[k], t[e]]; color, alpha = ph == 0 ? 0.35 : 0.2, lw = 0,
            label = ph in seen ? "" : name)
        push!(seen, ph)
        k = e < length(t) ? e : nothing
    end
    plot!(p1, t, BAR .* p; label = "allowed (abs.p_cmd)", color = :black, lw = 2)
    plot!(p1, t, BAR .* p_w; label = "front caliper", color = :steelblue, lw = 1.5, ls = :dash)
    p2 = plot(; ylabel = "speed [km/h]", xlabel = "time [s]", legend = :bottomleft)
    plot!(p2, t, 3.6 .* v; label = "car (speed.v)", color = :black)
    plot!(p2, t, 3.6 .* v_w; label = "wheel (ω·r)", color = :gray, lw = 1.5)
    plot!(p2, t, 3.6 .* v_ref; label = "estimate (est.v_ref)", color = :purple, ls = :dash)
    save(plot(p1, p2; layout = (2, 1), size = (900, 620), xlims = win), "step04-phase-cycle")
end

let mus = [1.0, 0.5, 0.3]
    rows = map(mus) do mu
        [V.braking_distance(H.PedalStopTransient(road_mu = mu, stop = stop_time(mu))),
         V.braking_distance(H.ABSStopTransient(road_mu = mu, stop = stop_time(mu))),
         V.braking_distance(H.ABSStopWheelOnlyTransient(road_mu = mu, stop = stop_time(mu, 8.0))),
         V.braking_distance(V.ABSBrakeTransient(road_mu = mu, stop = stop_time(mu, 8.0),
             alg = ODEAlg.Tsit5(), dtmax = 1e-3))]
    end
    table = permutedims(reduce(hcat, rows))
    labels = ["locked, pedal 0.6" "ABS, true slip" "ABS, wheel only (yours)" "ABS, wheel only (library, 5 ms)"]
    groups = ["μ = 1.0", "μ = 0.5", "μ = 0.3"]
    p = plot(; xlabel = "", ylabel = "braking distance [m]", legend = :topleft,
        title = "Braking distance from 90 km/h", xticks = (1:3, groups), ylims = (0, 165))
    colors = [:firebrick, :seagreen, :purple, :steelblue]
    w = 0.2
    for j in 1:4
        x = (1:3) .+ (j - 2.5) * w
        bar!(p, x, table[:, j]; bar_width = w, label = labels[j], color = colors[j], lw = 0)
        annotate!(p, [(x[i], table[i, j] + 4, text(string(round(table[i, j]; digits = 1)), 8)) for i in 1:3])
    end
    save(p, "step05-surfaces")
    for (mu, row) in zip(mus, eachrow(table))
        println("  μ $mu: ", join(round.(row; digits = 1), " · "))
    end
end

# Two snow cycles of build 04's PhaseABS, drawn on the layout of 03-abs-cycle.svg (Bosch's,
# sketched): the same panels, band colors and legend, so the slide can compare them side by side.
let (t0, t1) = (1.166, 1.5015), tw(f) = trace(snow, f; dt = 5e-4, from = t0, to = t1),
    (t, phase) = tw(m -> m.abs.phase), (_, v) = tw(m -> m.body.mass.v),
    (_, v_w) = tw(m -> m.est.v_w), (_, v_ref) = tw(m -> m.est.v_ref),
    (_, a_w) = tw(m -> m.abs.a_w), (_, p) = tw(m -> m.abs.p_cmd),
    X(x) = 90 + (x - t0) / (t1 - t0) * 510
    fmt(x) = string(round(x; digits = 1))
    path(xs, ys) = "M" * join(("$(fmt(X(a))) $(fmt(b))" for (a, b) in zip(xs, ys)), " L")
    # On snow every dump comes from the deceleration threshold; the slip never nears lambda_1, so
    # the speed panel is scaled to the two speeds alone.
    lo, hi = minimum(v_w), maximum(v)
    Vy(x) = 110 - (x - lo) / (hi - lo) * 70
    Ay(a) = 175 - 3.0a
    plo, phi = extrema(BAR .* p)
    Py(x) = 300 - (x - plo) / (phi - plo) * 60
    fills = Dict(1 => "#e2eef8", 0 => "#fcf9d8", -1 => "#f8dccb")
    names = Dict(1 => "build", 0 => "hold", -1 => "dump")
    io = IOBuffer()
    print(io, """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 620 358" width="620" height="358">
  <style>
    text { font-family: sans-serif; fill: #16202c; }
    .ax { stroke: #4a5a6b; stroke-width: 1.5; fill: none; }
    .thr { stroke: #4a5a6b; stroke-width: 1.5; fill: none; stroke-dasharray: 6 5; }
    .veh { stroke: #16202c; stroke-width: 3; fill: none; stroke-dasharray: 10 6; }
    .whl { stroke: #1f5fa8; stroke-width: 3; fill: none; }
    .prs { stroke: #16202c; stroke-width: 3.5; fill: none; }
    .pw { font-size: 11px; font-weight: 600; fill: #4a5a6b; }
    .lbl { font-size: 15px; fill: #4a5a6b; }
    .v { font-size: 15px; font-weight: 600; }
    .wl { font-size: 15px; font-weight: 600; fill: #1f5fa8; }
  </style>
  <defs>
    <pattern id="cy-hatch-ours" width="10" height="10" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
      <path d="M0 0 V10" stroke="#d55e00" stroke-width="1.6" stroke-opacity="0.45"/></pattern>
  </defs>
  <g transform="translate(0 18)">
""")
    k = 1
    while k < length(t)
        ph = round(Int, phase[k])
        e = something(findnext(x -> round(Int, x) != ph, phase, k), length(t))
        x0, x1 = X(t[k]), X(t[e])
        println(io, "  <rect x=\"$(fmt(x0))\" y=\"28\" width=\"$(fmt(x1 - x0))\" height=\"280\" fill=\"$(fills[ph])\"/>")
        ph == -1 && println(io, "  <rect x=\"$(fmt(x0))\" y=\"28\" width=\"$(fmt(x1 - x0))\" height=\"280\" fill=\"url(#cy-hatch-ours)\"/>")
        k > 1 && println(io, "  <path d=\"M$(fmt(x0)) 28 V308\" stroke=\"#8a99a8\" stroke-width=\"1\"/>")
        x1 - x0 >= 30 && println(io, "  <text x=\"$(fmt((x0 + x1) / 2))\" y=\"20\" text-anchor=\"middle\" class=\"pw\">$(names[ph])</text>")
        k = e
    end
    println(io, "  <path class=\"veh\" d=\"", path(t, Vy.(v)), "\"/>")
    println(io, "  <path class=\"whl\" d=\"", path(t, Vy.(v_w)), "\"/>")
    for (a, label, dy) in ((3.0, "+3", -2), (-12.0, "−12", 5))
        println(io, "  <path class=\"thr\" d=\"M90 $(fmt(Ay(a))) H600\"/>")
        println(io, "  <text x=\"84\" y=\"$(fmt(Ay(a) + dy))\" text-anchor=\"end\" class=\"v\">$label</text>")
    end
    println(io, "  <path class=\"ax\" d=\"M90 $(fmt(Ay(0))) H600\"/>")
    println(io, "  <text x=\"84\" y=\"$(fmt(Ay(0) + 13))\" text-anchor=\"end\" class=\"lbl\">0</text>")
    println(io, "  <path class=\"whl\" d=\"", path(t, Ay.(a_w)), "\"/>")
    println(io, "  <path class=\"prs\" d=\"", path(t, Py.(BAR .* p)), "\"/>")
    print(io, """  <text x="10" y="60" class="v">speed</text>
  <text x="10" y="140" class="v">wheel</text>
  <text x="10" y="158" class="v">accel.</text>
  <text x="10" y="276" class="v">pressure</text>
  <text x="596" y="$(fmt(Vy(v[end]) - 8))" text-anchor="end" class="v">car</text>
  <text x="596" y="$(fmt(Vy(v_w[end]) + 22))" text-anchor="end" class="wl">wheel</text>
  <text x="84" y="$(fmt(Py(phi) + 5))" text-anchor="end" class="lbl">$(round(Int, phi))</text>
  <text x="84" y="$(fmt(Py(plo) + 5))" text-anchor="end" class="lbl">$(round(Int, plo)) bar</text>
  <rect x="90" y="320" width="16" height="16" fill="#8fbfe0"/>
  <text x="114" y="333" class="lbl">build</text>
  <rect x="170" y="320" width="16" height="16" fill="#f0e442"/>
  <text x="194" y="333" class="lbl">hold</text>
  <rect x="250" y="320" width="16" height="16" fill="#e89a6a"/>
  <rect x="250" y="320" width="16" height="16" fill="url(#cy-hatch-ours)"/>
  <text x="274" y="333" class="lbl">dump</text>
  <text x="340" y="333" class="lbl">time →  two cycles, $(round(t1 - t0; digits = 2)) s</text>
  </g>
</svg>
""")
    path_out = joinpath(DIAGRAMS, "03-abs-cycle-ours.svg")
    write(path_out, String(take!(io)))
    println("  03-abs-cycle-ours.svg: pressure $(round(plo; digits = 1)) to $(round(phi; digits = 1)) bar, ",
        "a_w $(round(minimum(a_w); digits = 1)) to $(round(maximum(a_w); digits = 1)) m/s²")
end
