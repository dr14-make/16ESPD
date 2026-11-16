# Motor_5 0x480: MIL, EPC, glow plug (checksum assumed XOR of bytes 0..6).
include("common.jl")
bench(; only = [0x280, 0x480]) do b, echo
    b.rpm = 800
    step("engine lamps off, idle", echo, 4)
    b.mil = true;  step("check-engine (MIL) on", echo, 4); b.mil = false
    b.epc = true;  step("EPC on", echo, 4); b.epc = false
    b.glow = true; step("glow-plug lamp on", echo, 4); b.glow = false
end
