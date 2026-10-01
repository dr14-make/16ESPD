
# Snapshot paths resolve against the working directory, so pin every test entry point here.
cd(@__DIR__)

using VehicleSystemsComponents
using Test
    
include("tuning_tables.jl")
include("brake_plausibility.jl")
include("../generated/tests.jl")