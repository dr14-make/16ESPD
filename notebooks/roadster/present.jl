# Open the Roadster presentation notebook in Pluto, from the repository root:
#
#     julia +dyad-3.5.0 notebooks/roadster/present.jl
#
# A Pluto worker process fails to load the Dyad packages with this Julia build (`TypeError:
# expected Core.CodeInfo, got SynchJulia.DNode`). This launcher loads them here first and runs
# the notebook inside this process instead of in a worker.
import Pkg
Pkg.activate(normpath(@__DIR__, "..", ".."))
include(joinpath(@__DIR__, "..", "lecture01", "support.jl"))
Lecture01Support.setup()
using PlutoUI

# Pluto is not a project dependency; it lives in the default environment.
const PLUTO_ENV = "@v#.#"
PLUTO_ENV in LOAD_PATH || push!(LOAD_PATH, PLUTO_ENV)
using Pluto

Pluto.run(notebook = joinpath(@__DIR__, "02-is-it-possible.pluto.jl"),
    workspace_use_distributed = false)
