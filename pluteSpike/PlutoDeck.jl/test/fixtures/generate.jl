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

const CELL_IDS = UUID.([
    "a1000000-0000-4000-8000-000000000001",
    "a1000000-0000-4000-8000-000000000002",
    "a1000000-0000-4000-8000-000000000003",
    "a1000000-0000-4000-8000-000000000004",
    "a1000000-0000-4000-8000-000000000005",
])

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

write_fixture("three-cards.jl", three_carded_cells())
write_fixture("duplicate-cards.jl",
    push!(three_carded_cells(), carded(5, "metrics", "md\"a second cell claiming the same card\"")))
