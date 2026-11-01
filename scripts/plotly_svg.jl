"""
    save_svg(p, path)

Save the plotly-backend plot `p` as SVG through Kaleido at `p`'s own size.

The dyad-3.5 kernel ships Plots' plotly backend with Kaleido, not GR. Plots hands Kaleido no
size, so Kaleido would draw every figure at 700 x 500; the plot is converted here and its size
passed on. Plotly simplifies lines at screen resolution, which draws smooth curves as polygons;
that is switched off. Plots also gives a plotly figure one legend, placed on the whole figure by
the last subplot's `legend` (so a last subplot with `legend = false` hides every legend);
`place_legends!` instead draws each subplot's legend inside its own axes, as GR does.

Include it after `using Plots` and `plotly()`, with PlotlyBase and PlotlyKaleido imported.
"""
function save_svg(p, path)
    Plots.prepare_output(p)
    width, height = p[:size]
    figure = Plots.plotlybase_syncplot(p)
    for trace in figure.data
        haskey(trace.fields, :line) && (trace["line.simplify"] = false)
    end
    place_legends!(figure, p)
    PlotlyKaleido.is_running() || PlotlyKaleido.restart()
    PlotlyKaleido.savefig(path, figure; width, height, format = "svg")
    filesize(path) > 0 || error("$(basename(path)) was written empty")
    return path
end

const LEGEND_CORNERS = Dict(:topleft => ("left", "top"), :topright => ("right", "top"),
    :bottomleft => ("left", "bottom"), :bottomright => ("right", "bottom"))

function place_legends!(figure, p)
    width, height = p[:size]
    layout = figure.layout.fields
    inset_x, inset_y = 8 / width, 8 / height
    n = 0
    for sp in p.subplots
        x_idx, y_idx = length(p.subplots) > 1 ? Plots.plotly_link_indicies(p, sp) : ("", "")
        traces = filter(t -> get(t.fields, :xaxis, "x") == "x$x_idx" &&
                             get(t.fields, :yaxis, "y") == "y$y_idx", figure.data)
        pos = sp[:legend_position]
        if !haskey(LEGEND_CORNERS, pos)
            pos === :none || error("legend position $pos is not placed inside the axes")
            foreach(t -> t["showlegend"] = false, traces)
            continue
        end
        n += 1
        name = n == 1 ? "legend" : "legend$n"
        foreach(t -> t["legend"] = name, traces)
        xd = layout[Symbol("xaxis$x_idx")][:domain]
        yd = layout[Symbol("yaxis$y_idx")][:domain]
        xanchor, yanchor = LEGEND_CORNERS[pos]
        layout[Symbol(name)] = Dict(
            :bgcolor => "rgba(255, 255, 255, 1.000)",
            :bordercolor => "rgba(0, 0, 0, 1.000)",
            :borderwidth => 1,
            :traceorder => "normal",
            :tracegroupgap => 0,
            :font => Plots.plotly_font(Plots.legendfont(sp)),
            :xanchor => xanchor, :yanchor => yanchor,
            :x => xanchor == "left" ? xd[1] + inset_x : xd[2] - inset_x,
            :y => yanchor == "top" ? yd[2] - inset_y : yd[1] + inset_y)
    end
    layout[:showlegend] = n > 0
    return figure
end
