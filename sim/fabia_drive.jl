"""
Stream the 36-second scripted Fabia cluster demonstration to SocketCAN:

    mise run fabia             # can0
    mise run fabia vcan0
    julia +dyad-3.5.0 --project=. sim/fabia_drive.jl can0

Bring up physical CAN at 500 kbit/s before running. CANBus is loaded from the
stacked sim environment (`mise run drive:setup`). No window or controller is needed.
"""
function fabia_drive_usage end

(@__DIR__) in LOAD_PATH || push!(LOAD_PATH, @__DIR__)
using VehicleSystemsComponents
using DyadInterface
import CANBus
const V = VehicleSystemsComponents
interface = get(ARGS, 1, "can0")
model = V.PlanarBEVFabiaScriptedDrive(name = :model)
DyadInterface.run_analysis(V.RealtimeDriveSpec(; model, duration = 36.0,
    can_interface = interface, window = false))
