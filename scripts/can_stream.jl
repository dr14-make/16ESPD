"""
Stream the scripted CAN car (default) or the minimal cruise demo:

    julia +dyad-3.5.0 --project=. -e 'using Pkg; Pkg.add("CANBus")'
    julia +dyad-3.5.0 --project=. scripts/can_stream.jl car vcan0
    julia +dyad-3.5.0 --project=. scripts/can_stream.jl cruise vcan0

Use can0 instead of vcan0 for a configured PCAN-USB SocketCAN interface.
In another terminal:

    candump vcan0
    candump vcan0 | cantools decode agent_outputs/car.dbc

Configure interface bitrate and dashboard-compatible identifiers separately before attaching
physical hardware. The generated teaching layout is not a vehicle manufacturer's protocol.
"""
function can_stream_usage end

using Revise
using VehicleSystemsComponents
using DyadInterface
Revise.revise()
const V = VehicleSystemsComponents
kind = get(ARGS, 1, "car")
interface = get(ARGS, 2, "vcan0")
kind in ("car", "cruise") || error("choose car or cruise")
model = kind == "car" ? V.PlanarBEVCanScriptedDrive(name = :model) :
    V.Vehicle.Planar.CanCruise(name = :model)
mkpath(joinpath(@__DIR__, "..", "agent_outputs"))
V.Vehicle.Planar.can_dbc(model, joinpath(@__DIR__, "..", "agent_outputs", "$kind.dbc"))
DyadInterface.run_analysis(V.RealtimeDriveSpec(; model, duration = 30.0,
    can_interface = interface, window = false))
