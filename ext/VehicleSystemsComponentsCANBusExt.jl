module VehicleSystemsComponentsCANBusExt
using VehicleSystemsComponents
import CANBus

struct SocketSender
    interface::CANBus.Interface
end
VehicleSystemsComponents.can_open_loaded(name::String) = SocketSender(
    CANBus.Interface(CANBus.InterfaceConfig(CANBus.SOCKETCAN, name, CANBus.CAN_20, 500_000)))
VehicleSystemsComponents.can_send(sender::SocketSender, id, bytes) =
    CANBus.send(sender.interface, CANBus.Frame(UInt32(id), bytes))
VehicleSystemsComponents.can_close(sender::SocketSender) = CANBus.shutdown(sender.interface)
end
