
# Snapshot paths resolve against the working directory, so pin every test entry point here.
cd(@__DIR__)

using VehicleSystemsComponents
using Test
    
include("tuning_tables.jl")
include("plausibility_helpers.jl")
include("esp_plausibility.jl")
include("brake_plausibility.jl")
include("engine_plausibility.jl")
include("actuator_plausibility.jl")
include("roadster_plausibility.jl")
include("abs_handson_plausibility.jl")
include("hydraulic_abs_valves.jl")

include("../generated/tests.jl")