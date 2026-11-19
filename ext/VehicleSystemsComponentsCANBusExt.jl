module VehicleSystemsComponentsCANBusExt
using VehicleSystemsComponents
import CANBus

struct SocketSender
    interface::CANBus.Interface
end
VehicleSystemsComponents.can_open_loaded(name::String) = SocketSender(
    CANBus.Interface(CANBus.InterfaceConfig(CANBus.SOCKETCAN, name, CANBus.CAN_20, 500_000)))
# A physical adapter's transmit buffer holds only a few frames, so a catch-up burst after a pause
# fails with ENOBUFS; waiting for the bus to drain keeps the stream alive, dropping as a last resort.
function VehicleSystemsComponents.can_send(sender::SocketSender, id, bytes)
    frame = CANBus.Frame(UInt32(id), bytes)
    for _ in 1:200
        try
            return CANBus.send(sender.interface, frame)
        catch err
            err isa CANBus.Errors.CANBusIOError || rethrow()
            Libc.systemsleep(0.0005)
        end
    end
    @warn "CAN transmit buffer stayed full; dropping frames" id maxlog = 1
    return nothing
end
VehicleSystemsComponents.can_close(sender::SocketSender) = CANBus.shutdown(sender.interface)
end
