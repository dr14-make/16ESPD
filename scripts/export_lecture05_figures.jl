"""
Writes the Lecture 5 deck's engine figures into `slides/decks/lecture-05/public/figures/`.

    julia +dyad-3.5.0 --project=. scripts/export_lecture05_figures.jl [figure ...]

`05-bsfc-line`: BSFC contours of the Lecture 2 mapped engine over speed and brake torque, under
its full-load curve, with the best-BSFC operating line of `scripts/bsfc_line.jl` and a few
constant-power curves. Computed from the map tables, with no Dyad model.

The figures in `NOTEBOOK_FIGURES` come from running their notebook in
`notebooks/lecture05/` top to bottom with its controls at their defaults, in a module of its
own: a notebook assigns the global `VehicleSystemsComponents`, which would collide with the
package `setup()` loads into `Main`. A notebook figure that is still `nothing` is skipped with a
warning. Figure names as arguments export only those.

The notebooks include this file for `bsfc_map_plot` and `operating_points!`, so both figures
draw the map the same way.
"""
module Lecture05Figures

using Plots, Contour, Printf
import PlotlyBase, PlotlyKaleido
plotly()
include(joinpath(@__DIR__, "plotly_svg.jl"))
include(joinpath(@__DIR__, "bsfc_line.jl"))
using .BsfcLine

const OUT = joinpath(ROOT, "slides", "decks", "lecture-05", "public", "figures")
const LEVELS = [235, 240, 250, 260, 280, 300, 350, 400, 500]
const LINE_COLOR = "#1f5fa8"

Plots.default(; left_margin = 6Plots.mm, bottom_margin = 3Plots.mm, top_margin = 2Plots.mm,
    right_margin = 3Plots.mm, titlefontsize = 16, guidefontsize = 15, tickfontsize = 13,
    legendfontsize = 13)

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
        legend = :bottomright,
        grid = true, gridalpha = 0.25)
    for P in (20, 40, 60, 80)
        n = filter(n -> torque_for(P, n) <= 160, rpm)
        plot!(p, n, torque_for.(P, n); color = :gray, ls = :dot, lw = 1, label = "")
        x = min(n[end], 6250.0)
        annotate!(p, x, torque_for(P, x) + 4, text("$P kW", 11, :gray, :right))
    end
    for level in LEVELS
        pieces = contour_pieces(rpm, torque, Z, F, level)
        for (xs, ys) in pieces
            plot!(p, xs, ys; color = :black, lw = 0.8, label = "")
        end
        isempty(pieces) && continue
        xs, ys = pieces[argmax(length.(first.(pieces)))]
        k = cld(length(xs), 3)
        annotate!(p, xs[k], ys[k], text("$level", 10, :black))
    end
    plot!(p, rpm, reachable_torque.(Ref(m), rpm); color = :black, lw = 2.5, label = "full load")
    plot!(p, [r.rpm for r in line], [r.torque for r in line]; color = LINE_COLOR, lw = 3.5,
        label = "best-BSFC line")
    scatter!(p, [best.rpm], [best.torque]; color = LINE_COLOR, markersize = 9,
        markerstrokecolor = :white, markerstrokewidth = 2, label = "")
    annotate!(p, best.rpm + 120, best.torque - 9,
        text(@sprintf("min %.0f g/kWh", best.bsfc), 13, :black, :left))
    return p
end

bsfc_line_plot() = bsfc_map_plot()

# The largest bubble's diameter [px]; areas scale with grams, so it is the largest cell's.
const BUBBLE_MAX = 34.0

"""
    operating_points!(p, cells; scale = maximum(cells.fuel_g), color = LINE_COLOR, label)

Draw fuel `cells` (`rpm`, `torque`, `fuel_g`, as `OperatingPoints.fuel_cells` gives them) on
`p` as bubbles whose area is the fuel burned in the cell. Give every car on one figure the same
`scale` [g], the grams a `BUBBLE_MAX` bubble stands for, so equal areas mean equal fuel.
"""
function operating_points!(p, cells; scale = maximum(cells.fuel_g), color = LINE_COLOR, label)
    ms = BUBBLE_MAX .* sqrt.(cells.fuel_g ./ scale)
    scatter!(p, cells.rpm, cells.torque; markersize = ms, color, markeralpha = 0.45,
        markerstrokecolor = color, markerstrokewidth = 1, label)
    return p
end

const NOTEBOOKS = joinpath(ROOT, "notebooks", "lecture05")
const NOTEBOOK_FIGURES = Dict(
    "01-operating-points.pluto.jl" => ["05-operating-points-conventional" => :conventional_plot],
)

function export_notebook(notebook, figures)
    mod = Core.eval(Main, :(module $(Symbol("Notebook_", replace(notebook, r"\W" => "_"))) end))
    Base.include(mod, joinpath(NOTEBOOKS, notebook))
    for (name, plot) in figures
        p = Core.eval(mod, plot)
        if p === nothing
            @warn "$name: the notebook's `$plot` is `nothing`; not exported"
            continue
        end
        path = Base.invokelatest(save_svg, p, joinpath(OUT, "$name.svg"))
        println("wrote $(relpath(path, ROOT))")
    end
end

function main(wanted = String[])
    known = ["05-bsfc-line"; [n for fs in values(NOTEBOOK_FIGURES) for (n, _) in fs]]
    unknown = setdiff(wanted, known)
    isempty(unknown) || error("no such figure: $(join(sort!(unknown), ", "))")
    want(name) = isempty(wanted) || name in wanted
    mkpath(OUT)
    if want("05-bsfc-line")
        path = save_svg(bsfc_line_plot(), joinpath(OUT, "05-bsfc-line.svg"))
        println("wrote $(relpath(path, ROOT))")
    end
    for (notebook, figures) in sort!(collect(NOTEBOOK_FIGURES))
        figures = filter(f -> want(first(f)), figures)
        isempty(figures) || export_notebook(notebook, figures)
    end
end

end # module

# A notebook that includes this file gets its own copy of the module, not the program's.
if abspath(PROGRAM_FILE) == (@__FILE__) && parentmodule(Lecture05Figures) === Main
    Lecture05Figures.main(ARGS)
end
