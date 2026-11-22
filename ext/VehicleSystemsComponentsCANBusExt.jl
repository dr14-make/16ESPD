module VehicleSystemsComponentsCANBusExt
using VehicleSystemsComponents
import CANBus

mutable struct SocketSender
    interface::CANBus.Interface
    dropped::Int
    failing_since::Float64
end
VehicleSystemsComponents.can_open_loaded(name::String) = SocketSender(
    CANBus.Interface(CANBus.InterfaceConfig(CANBus.SOCKETCAN, name, CANBus.CAN_20, 500_000)), 0, NaN)

# A physical adapter's transmit buffer holds only a few frames, so a short burst can fail with
# ENOBUFS; CANBus reports that and a downed interface with the same error, so the wait per frame is
# short and only a failure that lasts a whole second stops the run.
const SEND_WAIT = 0.005
const SEND_GIVE_UP = 1.0

function VehicleSystemsComponents.can_send(sender::SocketSender, id, bytes)
    frame = CANBus.Frame(UInt32(id), bytes)
    deadline = time() + SEND_WAIT
    while true
        try
            CANBus.send(sender.interface, frame)
            sender.failing_since = NaN
            return nothing
        catch err
            err isa CANBus.Errors.CANBusIOError || rethrow()
            time() < deadline || break
            Libc.systemsleep(0.0005)
        end
    end
    sender.dropped += 1
    isnan(sender.failing_since) && (sender.failing_since = time())
    time() - sender.failing_since > SEND_GIVE_UP &&
        error("CAN: every transmit failed for $(SEND_GIVE_UP) s; is the interface up?")
    return nothing
end

function VehicleSystemsComponents.can_close(sender::SocketSender)
    sender.dropped > 0 && @warn "CAN transmit buffer full; frames dropped" sender.dropped
    CANBus.shutdown(sender.interface)
end
end
