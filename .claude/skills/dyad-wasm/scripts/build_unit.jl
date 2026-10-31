# Build one model into a dyad-cosim-1 unit.
#   julia build_unit.jl <spec.jl> <out_dir>
# Run with the build env (SKILL.md step 1) as the active project. `spec.jl` loads the library and
# defines:
#   NAME            unit name, also the output file stem
#   build_model()   the uncompiled System (pass `name = :model`)
#   INPUTS          paths the page sets between steps (tunable parameters or top-level inputs)
#   OUTPUTS         paths the page reads, observed variables included
using DyadWasm, JSON
include(joinpath(@__DIR__, "patches.jl"))
include(abspath(ARGS[1]))
out = abspath(ARGS[2])
mkpath(out)

# Only the inputs are exposed: every other tunable becoming an FMI parameter is what blows up
# inference on a multibody model (blockers #6).
KEEP_TUNABLE[] = INPUTS

model = build_model()
t = @elapsed built = DyadWasm.build_component(model; name = NAME, expose_inputs = INPUTS,
    expose_outputs = OUTPUTS, solver = "rodas5p", instances = 1)
write(joinpath(out, "$NAME.wasm"), built.bytes)
write(joinpath(out, "$NAME.manifest.json"), JSON.json(built.manifest, 2))
println("built $NAME in $(round(t, digits = 1)) s: $(length(built.bytes)) bytes, solver ",
        built.manifest["solver"]["name"], ", tier ", built.manifest["tier"])
