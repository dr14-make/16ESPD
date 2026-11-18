# Run from repository root: julia --project=. sim/fabia/05_brake_lamps.jl
# Bremse_1 0x1A0: ABS, ASR/ESP and brake warning lamps, one at a time.
include("common.jl")
bench(; only = [0x5D8, 0x5D0, 0x1A0, 0x5A0, 0x4A0]) do b, echo
    step("all brake lamps off", echo, 4)
    b.abs_lamp = true;  step("ABS lamp on", echo, 4);  b.abs_lamp = false
    b.asr_lamp = true;  step("ASR/ESP lamp on", echo, 4); b.asr_lamp = false
    b.brake_lamp = true; step("brake (EBV) lamp on", echo, 4); b.brake_lamp = false
end
