# Compatibility entry point for probe.jl; the implementation belongs to the pad extension.
# This loads transport definitions only, without GLMakie or opening a controller.
include(joinpath(@__DIR__, "..", "ext", "DualSense.jl"))
