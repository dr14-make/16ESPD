"""
Writes the theory deck's ESP figures, the planar car in the FMVSS 126 sine-with-dwell without
ESP, with ESP braking directly and with ESP through four ABS channels, and in a split-µ stop,
into `slides/decks/lecture-03/public/figures/`:

    julia +dyad-3.5.0 --project=. scripts/export_lecture03_esp_figures.jl

It runs `Lecture3.SineWithDwellRunTransient` at every amplitude of the test,
`Lecture3.ESPSineWithDwellTransient` with ESP off at 180° and with ESP on at every amplitude,
braking directly and through ABS (`abs_on = 1`, `Ki = 1e5`, as in
`notebooks/lecture03/03-esp.pluto.jl`), and `Lecture3.SplitMuStopTransient` in its four
configurations, all Tsit5 with dtmax 5 ms and no load transfer. It prints every number the
slides quote. The clocked analyses take about 30 s each, so a full run takes about ten minutes.

The dyad-3.5 kernel has no GR, so the figures go through Plots' plotly backend and Kaleido at
their own size, by `save_svg` in `scripts/plotly_svg.jl`.
"""

using VehicleSystemsComponents
using DyadInterface: symbolic_container
using Plots
import PlotlyBase, PlotlyKaleido

plotly()
include("plotly_svg.jl")

const L3 = VehicleSystemsComponents.Lecture3
const fmvss126_metrics = VehicleSystemsComponents.Vehicle.Planar.fmvss126_metrics
const OUT = normpath(@__DIR__, "..", "slides", "decks", "lecture-03", "public", "figures")
const A_REF = deg2rad(21.63)
const AMPLITUDES = (32.0, 76.0, 97.0, 141.0, 180.0, 220.0, 270.0)
const T = collect(range(0.0, 6.0; length = 1201))
# Okabe–Ito blue and vermilion, and gray: apart without red-green vision.
const CASES = [
    (76.0, "76°: pass", colorant"#0072B2", :solid),
    (180.0, "180°: oversteer, spins", colorant"#D55E00", :solid),
    (270.0, "270°: understeer", colorant"#555555", :dash),
]

trapz(t, x) = sum((x[1:end-1] .+ x[2:end]) .* diff(t)) / 2
r2(x) = round(x; digits = 2)
r1(x) = round(x; digits = 1)

"""Sampled signals of one sine-with-dwell run, with its FMVSS 126 metrics; the solution is dropped."""
function sine_with_dwell(analysis; kwargs...)
    result = analysis(; stop = 6.0, kwargs...)
    sol, model = result.sol, symbolic_container(result)
    s = model.car.bus
    has_esp = analysis === L3.ESPSineWithDwellTransient
    get(x) = sol(T, idxs = x).u
    m = fmvss126_metrics(T, get(s.delta_sw), get(s.r), get(s.y); A = A_REF)
    kappa = [get(k) for k in (s.kappa_fl, s.kappa_fr, s.kappa_rl, s.kappa_rr)]
    data = (; t = T, x = get(s.x), y = get(s.y), psi = get(s.psi), r = get(s.r),
        beta = get(s.beta), swa = get(s.delta_sw), vx = get(s.vx), kappa,
        kappa_min = minimum(minimum, kappa),
        r_ref = has_esp ? get(model.ecu.esp.r_ref) : nothing,
        tau = has_esp ?
            [get(model.car.tau_fl), get(model.car.tau_fr), get(model.car.tau_rl),
             get(model.car.tau_rr)] : nothing)
    return data, m
end

function report(label, d, m)
    println("  $label: YRR(1.00) $(round(m.yrr_1_00; digits = 3)), ",
        "YRR(1.75) $(round(m.yrr_1_75; digits = 3)), y(1.07) $(r2(m.y_bos_1_07)) m, ",
        "max |β| $(r1(rad2deg(maximum(abs, d.beta))))°, end speed $(r1(d.vx[end])) m/s, ",
        "min κ $(round(d.kappa_min; digits = 3)), ",
        "pass $(m.passes_stability && m.passes_responsiveness)")
end

println("No ESP:")
passive = Dict(a => sine_with_dwell(L3.SineWithDwellRunTransient; A_sw = deg2rad(a))
               for a in AMPLITUDES)
foreach(a -> report("$(a)°", passive[a]...), AMPLITUDES)

println("ESP braking directly:")
esp = Dict(a => sine_with_dwell(L3.ESPSineWithDwellTransient; A_sw = deg2rad(a))
           for a in AMPLITUDES)
foreach(a -> report("$(a)°", esp[a]...), AMPLITUDES)

println("ESP through four ABS channels:")
esp_abs = Dict(a => sine_with_dwell(L3.ESPSineWithDwellTransient; A_sw = deg2rad(a),
                   abs_on = 1.0, Ki = 1e5)
               for a in AMPLITUDES)
foreach(a -> report("$(a)°", esp_abs[a]...), AMPLITUDES)

const A_ESP = 180.0
println("ESP off, same harness:")
off, m_off = sine_with_dwell(L3.ESPSineWithDwellTransient; A_sw = deg2rad(A_ESP), esp_on = 0.0)
report("$(A_ESP)°", off, m_off)
on, m_on = esp[A_ESP]

mkpath(OUT)

# Top view: the path of the center of gravity, and the car's outline every 0.4 s.
const CAR_LENGTH, CAR_WIDTH = 4.6, 1.8
function outline(x, y, psi)
    c, s = cos(psi), sin(psi)
    corners = [(CAR_LENGTH / 2, CAR_WIDTH / 2), (-CAR_LENGTH / 2, CAR_WIDTH / 2),
        (-CAR_LENGTH / 2, -CAR_WIDTH / 2), (CAR_LENGTH / 2, -CAR_WIDTH / 2),
        (CAR_LENGTH / 2, CAR_WIDTH / 2)]
    return [x + c * u - s * v for (u, v) in corners], [y + s * u + c * v for (u, v) in corners]
end
function draw_car!(p, d, color; every = 80, from = 1.0, until = Inf)
    for i in 1:every:length(d.t)
        from <= d.t[i] <= until || continue
        plot!(p, outline(d.x[i], d.y[i], d.psi[i])...; seriestype = :shape,
            fillcolor = color, fillalpha = 0.25, linecolor = color, lw = 1.5, label = "")
    end
end

traj = plot(; xlabel = "x [m]", ylabel = "y [m]", aspect_ratio = :equal,
    title = "Sine-with-dwell from 80 km/h, no ESP: seen from above",
    legend = :bottomleft, size = (960, 360), dpi = 100, left_margin = 4Plots.mm,
    bottom_margin = 4Plots.mm, xlims = (20, 132), ylims = (-17, 9))
for (amp, label, color, ls) in CASES
    d, _ = passive[amp]
    plot!(traj, d.x, d.y; lw = 2.5, color, ls, label)
    draw_car!(traj, d, color)
end
save_svg(traj, joinpath(OUT, "05-swd-path.svg"))
println("  05-swd-path.svg")

# Steering-wheel angle and yaw rate over time, with the two FMVSS 126 check instants.
_, m_ref = passive[CASES[1][1]]
swa_plot = plot(; ylabel = "steering wheel [°]", legend = false,
    title = "Sine-with-dwell, no ESP: steering and yaw rate", ylims = (-300, 330))
yaw_plot = plot(; xlabel = "time [s]", ylabel = "yaw rate [°/s]", legend = :bottomleft)
for (amp, label, color, ls) in CASES
    d, _ = passive[amp]
    plot!(swa_plot, d.t, rad2deg.(d.swa); lw = 2.5, color, ls, label = "")
    plot!(yaw_plot, d.t, rad2deg.(d.r); lw = 2.5, color, ls, label)
end
for p in (swa_plot, yaw_plot)
    vline!(p, [m_ref.t_cos]; color = :gray, ls = :dot, label = "")
    vline!(p, [m_ref.t_cos + 1.0, m_ref.t_cos + 1.75]; color = :black, ls = :dot, label = "")
end
hline!(yaw_plot, [0.0]; color = :gray, lw = 1, label = "")
for (t, text) in ((m_ref.t_cos, "steering ends"), (m_ref.t_cos + 1.0, "+1.00 s"),
                  (m_ref.t_cos + 1.75, "+1.75 s"))
    annotate!(swa_plot, t + 0.05, 250, Plots.text(text, 8, :left, :gray25))
end
yaw = plot(swa_plot, yaw_plot; layout = grid(2, 1, heights = [0.38, 0.62]),
    link = :x, size = (960, 540), dpi = 100, left_margin = 6Plots.mm)
save_svg(yaw, joinpath(OUT, "05-swd-yaw-rate.svg"))
println("  05-swd-yaw-rate.svg")

const ESP_OFF = ("ESP off", :firebrick, :dash)
const ESP_ON = ("ESP on", :royalblue, :solid)

traj = plot(; xlabel = "x [m]", ylabel = "y [m]", aspect_ratio = :equal,
    title = "Sine-with-dwell at 180° from 80 km/h: seen from above",
    legend = :bottomleft, size = (960, 360), dpi = 100, left_margin = 4Plots.mm,
    bottom_margin = 4Plots.mm, xlims = (20, 132), ylims = (-17, 9))
for ((label, color, ls), d) in ((ESP_OFF, off), (ESP_ON, on))
    plot!(traj, d.x, d.y; lw = 2.5, color, ls, label)
    draw_car!(traj, d, color)
end
save_svg(traj, joinpath(OUT, "05-swd-esp-path.svg"))
println("  05-swd-esp-path.svg")

# Yaw rate against the reference, and the brake torque ESP puts on each wheel.
yaw_plot = plot(; ylabel = "yaw rate [°/s]", legend = :bottomleft,
    title = "Sine-with-dwell at 180°: yaw rate and the wheel ESP brakes")
plot!(yaw_plot, on.t, rad2deg.(on.r_ref); lw = 2, color = :gray40, ls = :dot,
    label = "reference")
for ((label, color, ls), d) in ((ESP_OFF, off), (ESP_ON, on))
    plot!(yaw_plot, d.t, rad2deg.(d.r); lw = 2.5, color, ls, label)
end
hline!(yaw_plot, [0.0]; color = :gray, lw = 1, label = "")
const WHEELS = (("front left", :darkorange), ("front right", :seagreen),
    ("rear left", :purple), ("rear right", :gray30))
tau_plot = plot(; xlabel = "time [s]", ylabel = "brake torque [N·m]", legend = :topright)
for (k, (label, color)) in enumerate(WHEELS)
    plot!(tau_plot, on.t, on.tau[k]; lw = 2.5, color, label)
end
for p in (yaw_plot, tau_plot)
    vline!(p, [m_on.t_cos]; color = :gray, ls = :dot, label = "")
    vline!(p, [m_on.t_cos + 1.0, m_on.t_cos + 1.75]; color = :black, ls = :dot, label = "")
end
fig = plot(yaw_plot, tau_plot; layout = grid(2, 1, heights = [0.55, 0.45]),
    link = :x, size = (960, 540), dpi = 100, left_margin = 6Plots.mm)
save_svg(fig, joinpath(OUT, "05-swd-esp-yaw.svg"))
println("  05-swd-esp-yaw.svg")

# Brake work per wheel, ∫τ dt, over the reversal and the dwell, where the car oversteers.
window = (1.0 + 0.5 / 0.7) .<= on.t .<= (1.0 + 1.0 / 0.7 + 0.5 + 1.5)
println("  brake work at 180° [FL, FR, RL, RR] N·m·s: ",
    [round(trapz(on.t[window], tau[window])) for tau in on.tau])

# ESP braking directly against ESP through ABS: the braked wheels' slip, and the speed kept.
const DIRECT = ("ESP braking directly", :firebrick, :dash)
const THROUGH_ABS = ("ESP through ABS", :royalblue, :solid)
slip_plot = plot(; xlabel = "time [s]", ylabel = "lowest wheel slip κ", ylims = (-1.05, 0.05),
    title = "180°: the most-braked wheel", legend = :bottomleft)
for ((label, color, ls), d) in ((DIRECT, esp[A_ESP][1]), (THROUGH_ABS, esp_abs[A_ESP][1]))
    plot!(slip_plot, d.t, minimum.(zip(d.kappa...)); lw = 2.5, color, ls, label)
end
hline!(slip_plot, [-0.2]; color = :black, ls = :dot, label = "")
annotate!(slip_plot, 0.1, -0.15, Plots.text("κ = −0.2", 8, :left, :gray25))
speed_plot = plot(; xlabel = "steering-wheel amplitude [°]", ylabel = "speed at 6 s [m/s]",
    title = "Speed kept through the test", legend = :bottomleft, ylims = (0, 24),
    xticks = collect(AMPLITUDES))
for ((label, color, ls), runs) in ((DIRECT, esp), (THROUGH_ABS, esp_abs))
    plot!(speed_plot, collect(AMPLITUDES), [runs[a][1].vx[end] for a in AMPLITUDES];
        lw = 2.5, color, ls, marker = :circle, ms = 5, label)
end
hline!(speed_plot, [22.22]; color = :gray, ls = :dot, label = "entry, 80 km/h")
fig = plot(slip_plot, speed_plot; layout = (1, 2), size = (960, 400), dpi = 100,
    left_margin = 5Plots.mm, bottom_margin = 5Plots.mm)
save_svg(fig, joinpath(OUT, "05-esp-abs.svg"))
println("  05-esp-abs.svg")

# Split-µ stop: left wheels on dry asphalt, right wheels on ice, full braking, wheel straight.
const SPLIT = (
    (label = "ABS only", color = :firebrick, ls = :solid,
     knobs = (select_low = 0.0, esp_on = 0.0)),
    (label = "ABS + rear select-low", color = :darkorange, ls = :solid,
     knobs = (select_low = 1.0, esp_on = 0.0)),
    (label = "select-low + ESP, P", color = :mediumpurple, ls = :dash,
     knobs = (select_low = 1.0, esp_on = 1.0, Ki = 0.0)),
    (label = "select-low + ESP, PI", color = :royalblue, ls = :solid,
     knobs = (select_low = 1.0, esp_on = 1.0)),
)
function split_mu(knobs)
    result = L3.SplitMuStopTransient(; stop = 6.0, knobs...)
    sol, s = result.sol, symbolic_container(result).car.bus
    get(x) = sol(T, idxs = x).u
    d = (; t = T, x = get(s.x), y = get(s.y), psi = get(s.psi), vx = get(s.vx))
    i = something(findfirst(<(3.0), d.vx), length(T))
    return (; d..., i_stop = i)
end
println("Split-µ stop, read when the car falls below 3 m/s:")
split = [split_mu(c.knobs) for c in SPLIT]
for (c, d) in zip(SPLIT, split)
    i = d.i_stop
    println("  $(c.label): heading $(r1(rad2deg(d.psi[i])))°, offset $(r1(d.y[i])) m, ",
        "distance $(r1(d.x[i])) m, at $(r2(d.t[i])) s")
end

path_plot = plot(; xlabel = "x [m]", ylabel = "y [m], dry side up", aspect_ratio = :equal,
    title = "Split-µ stop from 80 km/h, seen from above", legend = :topleft,
    xlims = (-2, 115), ylims = (-4, 26))
heading_plot = plot(; xlabel = "time [s]", ylabel = "heading [°]", legend = false,
    title = "Heading")
for (c, d) in zip(SPLIT, split)
    i = d.i_stop
    plot!(path_plot, d.x[1:i], d.y[1:i]; lw = 2.5, c.color, c.ls, label = c.label)
    draw_car!(path_plot, (; t = d.t[1:i], x = d.x[1:i], y = d.y[1:i], psi = d.psi[1:i]),
        c.color; every = 100, from = 0.5)
    plot!(heading_plot, d.t[1:i], rad2deg.(d.psi[1:i]); lw = 2.5, c.color, c.ls)
end
vline!(heading_plot, [0.5]; color = :gray, ls = :dot)
fig = plot(path_plot, heading_plot; layout = grid(1, 2, widths = [0.68, 0.32]),
    size = (960, 360), dpi = 100, left_margin = 5Plots.mm, bottom_margin = 5Plots.mm)
save_svg(fig, joinpath(OUT, "05-split-mu.svg"))
println("  05-split-mu.svg")
PlotlyKaleido.kill_kaleido()
