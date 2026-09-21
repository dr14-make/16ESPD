# Writes the fixture notebooks in this directory.
#
# Pluto owns its file format and rewrites any notebook it opens into canonical form, so the
# fixtures are written by Pluto's own writer rather than by hand. Cell ids are fixed, so
# regenerating a fixture produces the same file unless the Pluto version stamp changes.
#
#     julia --project=. test/fixtures/generate.jl

import Pkg
Pkg.activate(joinpath(@__DIR__, "..", ".."))

using UUIDs: UUID
import Pluto

const CELL_IDS = UUID[UUID("a1000000-0000-4000-8000-" * lpad(i, 12, '0')) for i in 1:10]

carded(index, card, code) = Pluto.Cell(;
    cell_id=CELL_IDS[index],
    code,
    metadata=Pluto.create_cell_metadata(Dict{String,Any}("card" => card)),
)

uncarded(index, code) = Pluto.Cell(; cell_id=CELL_IDS[index], code)

three_carded_cells() = [
    carded(1, "target-speed", "@bind v_ref_kmh html\"<input type=range min=60 max=160 value=110>\""),
    uncarded(2, "scratch = 1 + 1"),
    carded(3, "speed-plot", "plot(t, v; label=\"v(t)\")"),
    carded(4, "metrics", "md\"\"\"**overshoot** \$(round(overshoot; digits=1)) %\"\"\""),
]

function write_fixture(name, cells)
    path = joinpath(@__DIR__, name)
    Pluto.save_notebook(Pluto.Notebook(cells, path))
    @info "wrote" path
end

# A bond starts as `missing` until a browser reports a widget's value, so every cell that
# reads one has to stand on its own before that happens.
runnable_cells() = [
    carded(1, "frequency", "@bind freq html\"<input type=range min=1 max=10 value=1>\""),
    uncarded(2, "cycles = coalesce(freq, 1)"),
    carded(3, "samples", "samples = round.(sin.(range(0, 2\u03c0; length=9)[1:8] .* cycles); digits=3)"),
    carded(4, "readout", "md\"\"\"**freq** \$(cycles), **samples** \$(length(samples))\"\"\""),
]

# What the browser harness drives. Between them these cells cover every path a card can take:
# a side-effecting preamble, a Julia-defined widget writing back, two cells downstream of it, a
# `published_to_js` payload reached through the <pluto-cell> ancestor, a text/plain body that
# must not be parsed as markup, one card that no bond can reach, and the theme bond the deck
# writes without any element ever reporting it.
browser_cells() = [
    carded(1, "plotly", """
    plotly_offline = begin
        using PlutoPlotly
        enable_plutoplotly_offline()
    end"""),
    carded(2, "frequency", "@bind freq html\"<input type=range min=1 max=5 step=1 value=1>\""),
    uncarded(3, "cycles = ismissing(freq) ? 1 : Int(freq)"),
    carded(4, "wave", """
    let t = range(0, 1; length=201)
        plot(scatter(; x=collect(t), y=sin.(2\u03c0 .* cycles .* t)),
             Layout(template = plot_template))
    end"""),
    carded(5, "readout", "md\"\"\"**cycles** \$(cycles)\"\"\""),
    carded(6, "constant", "md\"\"\"the car weighs **1400 kg**\"\"\""),
    carded(7, "plain", "Text(\"<b>not bold</b> & <script>never runs</script>\")"),
    uncarded(8, "@bind deck_theme html\"<span></span>\""),
    uncarded(9,
        "plot_template = templates[coalesce(deck_theme, \"light\") == \"dark\" ? :plotly_dark : :plotly_white]"),
]

write_fixture("three-cards.jl", three_carded_cells())
write_fixture("runnable.jl", runnable_cells())
write_fixture("browser.jl", browser_cells())
write_fixture("duplicate-cards.jl",
    push!(three_carded_cells(), carded(5, "metrics", "md\"a second cell claiming the same card\"")))
