# Tell the cluster ABS and airbag units are fitted (Verbauliste_1 0x5D8, Systeminfo_1 0x5D0),
# then retry the ABS and airbag lamps. Watch "installed ABS/airbag" in the echo: it is the
# cluster's own list (0x520) and shows whether it accepted the message.
include("common.jl")
bench(; only = [0x5D8, 0x5D0, 0x1A0, 0x5A0, 0x4A0, 0x050], send_installed = true, send_airbag = true) do b, echo
    step("installed list sent, all lamps off", echo, 6)
    b.abs_lamp = true; step("ABS lamp on", echo, 4); b.abs_lamp = false
    b.asr_lamp = true; step("ASR/ESP lamp on", echo, 4); b.asr_lamp = false
    b.brake_lamp = true; step("brake (EBV) lamp on", echo, 4); b.brake_lamp = false
    b.airbag_lamp = true; step("airbag lamp on", echo, 4); b.airbag_lamp = false
end
