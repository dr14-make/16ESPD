"""
Stream the scripted CAN car (default) or the minimal cruise demo to a SocketCAN interface:

    mise run can                      # car on vcan0
    mise run can cruise vcan0
    julia +dyad-3.5.0 --project=. sim/can_stream.jl car vcan0

CANBus lives in the `sim/` environment (`mise run drive:setup` installs it). Use `can0` for a
PCAN-USB adapter brought up with `ip link set can0 up type can bitrate 500000`. Watch with:

    candump -ta vcan0
    candump vcan0 | cantools decode sim/car.dbc

The identifiers and layout are the teaching model's, not a manufacturer's protocol.
"""
function can_stream_usage end

(@__DIR__) in LOAD_PATH || push!(LOAD_PATH, @__DIR__)
using VehicleSystemsComponents
using DyadInterface
import CANBus
const V = VehicleSystemsComponents
kind = get(ARGS, 1, "car")
interface = get(ARGS, 2, "vcan0")
kind in ("car", "cruise") || error("choose car or cruise")
model = kind == "car" ? V.PlanarBEVCanScriptedDrive(name = :model) :
    V.Vehicle.Planar.CanCruise(name = :model)
dbc = joinpath(@__DIR__, "$kind.dbc")
V.Vehicle.Planar.can_dbc(model, dbc)
@info "decode with: candump $interface | cantools decode $dbc"
DyadInterface.run_analysis(V.RealtimeDriveSpec(; model, duration = 30.0,
    can_interface = interface, window = false))
