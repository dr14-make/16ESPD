"""
Exports the Lecture 2 notebooks' deck cells into the theory deck, as one HTML page per cell.

    julia +dyad-3.4.0 --project=. scripts/export_deck_cards.jl [notebook.pluto.jl ...]

With no argument it exports every notebook in `notebooks/lecture02/` that has a cell carrying
`card` metadata, each in a Julia process of its own, so no notebook sees another's globals.
`mise run cards:lecture-02` runs it that way.

A notebook runs top to bottom as a script, as its headless check does, and the value of each
cell whose metadata reads `card = "<name>"` is written to
`slides/decks/lecture-02/public/cards/<notebook>/<name>.html`:

- a PlutoPlotly plot becomes a page that draws the same Plotly figure, zoom and hover included,
  with the plotly.js build PlutoPlotly itself loads, copied once to `cards/plotly-esm-min.mjs`;
- anything that renders as HTML, such as a table, becomes a page holding that HTML.

The slides embed a page with `<CardExport notebook="…" name="…" />`, which takes the same two
names as a live card's `<PlutoCard>`. A page holds no time stamp and its figure JSON is written
with sorted keys, so rerunning on unchanged notebooks and data rewrites identical bytes. Pages of
cards a notebook no longer declares are deleted.
"""

using Artifacts: artifact_meta, artifact_path

const ROOT = normpath(@__DIR__, "..")
const NOTEBOOKS = joinpath(ROOT, "notebooks", "lecture02")
const OUT = joinpath(ROOT, "slides", "decks", "lecture-02", "public", "cards")
const CELL = r"^# ╔═╡ ([0-9a-f-]{36})$"
const CARD = r"^# ╠═╡ card = \"([^\"]+)\"$"
const PLUTOPLOTLY = Base.PkgId(Base.UUID("8e989ff0-3d88-8e9f-f020-2b208a939ff0"), "PlutoPlotly")

"""
    cells(path) -> (header, [(card, code), ...])

The code before the first cell, and every cell in file order with its card name or `nothing`.
"""
function cells(path)
    header, found = String[], Tuple{Union{Nothing, String}, Vector{String}}[]
    for line in readlines(path)
        startswith(line, "# ╔═╡ Cell order:") && break
        if occursin(CELL, line)
            push!(found, (nothing, String[]))
        elseif isempty(found)
            push!(header, line)
        elseif (m = match(CARD, line)) !== nothing
            found[end] = (m[1], found[end][2])
        else
            push!(found[end][2], line)
        end
    end
    return join(header, "\n"), [(card, join(code, "\n")) for (card, code) in found]
end

has_cards(path) = any(!isnothing(card) for (card, _) in cells(path)[2])

function export_notebook(path)
    stem = replace(basename(path), ".pluto.jl" => "")
    header, all_cells = cells(path)
    include_string(Main, header, path)
    exported = Dict{String, String}()
    for (card, code) in all_cells
        value = include_string(Main, code, path)
        isnothing(card) && continue
        haskey(exported, card) && error("$stem declares card \"$card\" twice")
        exported[card] = Base.invokelatest(page, stem, card, value)
    end
    isempty(exported) && error("$stem declares no card")

    dir = joinpath(OUT, stem)
    mkpath(dir)
    for file in readdir(dir)
        endswith(file, ".html") && !haskey(exported, file[1:(end - 5)]) && rm(joinpath(dir, file))
    end
    for (card, html) in sort!(collect(exported))
        write(joinpath(dir, "$card.html"), html)
        println("  $stem/$card.html")
    end
    Base.invokelatest(copy_plotly)
    return nothing
end

function page(stem, card, value)
    title = "$stem · $card"
    if nameof(typeof(value)) === :PlutoPlot
        plot = getfield(value, :Plot)
        figure = canonical_json(parentmodule(typeof(plot)).JSON.lower(plot), parentmodule(typeof(plot)).JSON)
        return plot_page(title, figure)
    elseif showable(MIME("text/html"), value)
        return html_page(title, repr(MIME("text/html"), value))
    end
    error("card \"$card\" of $stem is a $(typeof(value)), neither a PlutoPlotly plot nor HTML")
end

"""
    canonical_json(x, JSON) -> String

JSON with every object's keys sorted. Plotly figures are nested `Dict`s, whose iteration order
is not part of their contract, so a byte-stable page cannot rely on it.
"""
function canonical_json(x, JSON)
    io = IOBuffer()
    write_json(io, x, JSON)
    return String(take!(io))
end

function write_json(io, x, JSON)
    if x isa AbstractDict
        print(io, "{")
        for (k, (key, v)) in enumerate(sort!([string(key) => v for (key, v) in x]; by = first))
            k > 1 && print(io, ",")
            print(io, JSON.json(key), ":")
            write_json(io, v, JSON)
        end
        print(io, "}")
    elseif x isa Union{AbstractVector, Tuple}
        print(io, "[")
        for (k, v) in enumerate(x)
            k > 1 && print(io, ",")
            write_json(io, v, JSON)
        end
        print(io, "]")
    elseif x isa AbstractFloat && !isfinite(x)
        print(io, "null")
    elseif x isa Union{Nothing, Missing, Bool, Number, AbstractString, Symbol}
        print(io, JSON.json(x))
    else
        lowered = JSON.lower(x)
        lowered === x && error("cannot write a $(typeof(x)) as JSON")
        write_json(io, lowered, JSON)
    end
end

const GENERATED = "<!-- Written by scripts/export_deck_cards.jl from a notebook cell; edit the notebook and rerun it. -->"

plot_page(title, figure) = """
    <!doctype html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>$title</title>
    $GENERATED
    <style>
    html, body { margin: 0; height: 100%; overflow: hidden; background: #fff; }
    #plot { width: 100%; height: 100%; }
    </style>
    </head>
    <body>
    <div id="plot"></div>
    <script type="module">
    import Plotly from "../plotly-esm-min.mjs"
    const figure = $figure
    const plot = document.getElementById("plot")
    // A slide that is not on screen can hold this page at zero size, where Plotly measures every
    // label as zero wide; the plot is drawn once it has a size, and redrawn when that changes.
    let drawn = false
    new ResizeObserver(() => {
      if (plot.clientWidth === 0 || plot.clientHeight === 0) return
      if (drawn) return Plotly.Plots.resize(plot)
      drawn = true
      Plotly.newPlot(plot, figure.data, figure.layout, { ...figure.config, displaylogo: false })
    }).observe(plot)
    </script>
    </body>
    </html>
    """

html_page(title, body) = """
    <!doctype html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>$title</title>
    $GENERATED
    <style>
    html, body { margin: 0; background: #fff; color: #181818; }
    body { font-family: "Avenir Next", "Nunito Sans", ui-sans-serif, system-ui, sans-serif; font-size: 15px; line-height: 1.35; }
    </style>
    </head>
    <body>
    $body
    </body>
    </html>
    """

"The plotly.js build PlutoPlotly loads, so an exported page draws as the notebook does."
function copy_plotly()
    plutoplotly = Base.loaded_modules[PLUTOPLOTLY]
    toml = joinpath(pkgdir(plutoplotly), "Artifacts.toml")
    tree = artifact_path(Base.SHA1(artifact_meta("plotly-esm-min", toml)["git-tree-sha1"]))
    write(joinpath(OUT, "plotly-esm-min.mjs"), read(joinpath(tree, "plotly-esm-min.mjs")))
    return nothing
end

if isempty(ARGS)
    notebooks = filter(has_cards, sort!(filter(endswith(".pluto.jl"), readdir(NOTEBOOKS; join = true))))
    for notebook in notebooks
        println(relpath(notebook, ROOT))
        run(`$(Base.julia_cmd()) --project=$ROOT $(@__FILE__) $notebook`)
    end
else
    foreach(export_notebook ∘ abspath, ARGS)
end
