"""
The Lecture 5 engine map figure: BSFC contours of the Lecture 2 mapped engine over speed and
brake torque, under its full-load curve, with the best-BSFC line of `scripts/bsfc_line.jl` and
constant-power curves; and cars' fuel drawn on it as bubbles.

`scripts/export_lecture05_figures.jl` and notebook `01-operating-points.pluto.jl` both draw
the map through `bsfc_map_plot`, so the deck's figures and the notebook's match. Include
`operating_points.jl` into the same module first: the map is read through its `BsfcLine`.
"""
module BsfcMap

using Plots, Contour, Printf
using ..OperatingPoints.BsfcLine: load_maps, operating_line, global_min_bsfc, bsfc_at,
    reachable_torque, torque_for, RPM_IDLE, RPM_MAX

export bsfc_map_plot, fuel_bubbles!, LINE_COLOR

# Contour levels [g/kWh] and the speed [rpm] each is labeled at; the low-load contours run close
# together, so their labels are staggered along them.
const LEVELS = [235 => 2750, 240 => 1500, 250 => 2600, 260 => 4800, 280 => 2700, 300 => 1400,
    350 => 2200, 400 => 3000, 500 => 3800]
# Constant-power curves [kW] and the speed [rpm] each is labeled at, clear of the legend.
const POWERS = [20 => 5100, 40 => 6250, 60 => 6250, 80 => 6250]
const LINE_COLOR = "#1f5fa8"

# Sized to read on a projected slide with the figure at two-thirds of the slide's width.
const FONTS = (; left_margin = 8Plots.mm, bottom_margin = 5Plots.mm, top_margin = 2Plots.mm,
    right_margin = 3Plots.mm, titlefontsize = 22, guidefontsize = 21, tickfontsize = 19,
    legendfontsize = 19)

"""
BSFC on the (speed, torque) grid, and a copy whose cells above the reachable torque repeat the
column's last reachable value: the contour tracer then runs straight up out of the map instead
of along its edge, and the pieces outside are dropped afterwards.
"""
function bsfc_grid(m, rpm, torque)
    Z = [something(bsfc_at(m, n, T), (; bsfc = NaN)).bsfc for n in rpm, T in torque]
    F = copy(Z)
    for i in axes(F, 1)
        last_valid = findlast(!isnan, view(Z, i, :))
        last_valid === nothing && continue
        F[i, last_valid+1:end] .= Z[i, last_valid]
        first_valid = findfirst(!isnan, view(Z, i, :))
        F[i, 1:first_valid-1] .= Z[i, first_valid]
    end
    return Z, F
end

function contour_pieces(rpm, torque, Z, F, level)
    inside(x, y) = !isnan(Z[argmin(abs.(rpm .- x)), argmin(abs.(torque .- y))])
    pieces = Tuple{Vector{Float64}, Vector{Float64}}[]
    for line in Contour.lines(Contour.contour(rpm, torque, F, level))
        xs, ys = Contour.coordinates(line)
        keep = inside.(xs, ys)
        a = 1
        while a <= length(xs)
            keep[a] || (a += 1; continue)
            e = something(findnext(!, keep, a), length(xs) + 1) - 1
            e > a && push!(pieces, (xs[a:e], ys[a:e]))
            a = e + 1
        end
    end
    return pieces
end

"""
    bsfc_map_plot(; title = "BSFC contours [g/kWh]")

The engine's BSFC contours, full-load curve, best-BSFC line with the map's minimum marked, and
the 20–80 kW constant-power curves.
"""
function bsfc_map_plot(; title = "BSFC contours [g/kWh]")
    m = load_maps()
    line = operating_line(m)
    best = global_min_bsfc(m)
    rpm = collect(RPM_IDLE:25.0:RPM_MAX)
    torque = collect(2.0:1.0:155.0)
    Z, F = bsfc_grid(m, rpm, torque)

    p = plot(; size = (1280, 620), xlims = (RPM_IDLE, RPM_MAX), ylims = (0, 160),
        title, xlabel = "engine speed [rpm]", ylabel = "brake torque [N·m]",
        legend = :bottomright, grid = true, gridalpha = 0.25, FONTS...)
    for (P, x) in POWERS
        n = filter(n -> torque_for(P, n) <= 160, rpm)
        plot!(p, n, torque_for.(P, n); color = :gray, ls = :dot, lw = 1, label = "")
        annotate!(p, x, torque_for(P, x) + 5, text("$P kW", 17, :gray, :right))
    end
    for (level, x_label) in LEVELS
        pieces = contour_pieces(rpm, torque, Z, F, level)
        for (xs, ys) in pieces
            plot!(p, xs, ys; color = :black, lw = 0.8, label = "")
        end
        isempty(pieces) && continue
        xs, ys = pieces[argmax(length.(first.(pieces)))]
        # A contour can cross the label's speed twice; the label goes on its lower branch.
        near = findall(x -> abs(x - x_label) <= 50, xs)
        k = isempty(near) ? argmin(abs.(xs .- x_label)) : near[argmin(ys[near])]
        annotate!(p, xs[k], ys[k], text("$level", 16, :black))
    end
    plot!(p, rpm, reachable_torque.(Ref(m), rpm); color = :black, lw = 2.5, label = "full load")
    plot!(p, [r.rpm for r in line], [r.torque for r in line]; color = LINE_COLOR, lw = 3.5,
        label = "best-BSFC line")
    scatter!(p, [best.rpm], [best.torque]; color = LINE_COLOR, markersize = 9,
        markerstrokecolor = :white, markerstrokewidth = 2, label = "")
    annotate!(p, best.rpm + 120, best.torque - 9,
        text(@sprintf("min %.0f g/kWh", best.bsfc), 19, :black, :left))
    return p
end

# The largest bubble's diameter [px]; areas scale with grams, so it is the largest cell's.
const BUBBLE_MAX = 34.0

"""
    fuel_bubbles!(p, cells; scale = maximum(cells.fuel_g), color, label)

Draw fuel `cells` (`rpm`, `torque`, `fuel_g`, as `OperatingPoints.fuel_cells` gives them) on
`p` as bubbles whose area is the fuel burned in the cell. Give every car on one figure the same
`scale` [g], the grams a `BUBBLE_MAX` bubble stands for, so equal areas mean equal fuel. No
cells draw nothing.
"""
function fuel_bubbles!(p, cells; scale = maximum(cells.fuel_g; init = 0.0), color, label)
    isempty(cells.fuel_g) && return p
    ms = BUBBLE_MAX .* sqrt.(cells.fuel_g ./ scale)
    scatter!(p, cells.rpm, cells.torque; markersize = ms, color, markeralpha = 0.45,
        markerstrokecolor = color, markerstrokewidth = 1, label)
    return p
end

end # module
