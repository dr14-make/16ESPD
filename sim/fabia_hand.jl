# Drive the by-hand car in a window (keyboard or pad) while it drives a Fabia cluster:
#     julia +dyad-3.5.0 --project=. sim/fabia_hand.jl [interface]    # default can0
(@__DIR__) in LOAD_PATH || push!(LOAD_PATH, @__DIR__)
using VehicleSystemsComponents
using DyadInterface: run_analysis
using GLMakie
using SimpleDirectMediaLayer
import CANBus

const V = VehicleSystemsComponents
run_analysis(V.RealtimeDriveSpec(; model = V.PlanarBEVByHandFabia(name = :model),
    window = true, can_interface = get(ARGS, 1, "can0")))
