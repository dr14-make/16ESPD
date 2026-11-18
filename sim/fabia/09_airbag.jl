# Run from repository root: julia --project=. sim/fabia/09_airbag.jl
# Airbag_1 0x050: airbag lamp (counter + XOR checksum assumed).
include("common.jl")
bench(; only = [0x5D8, 0x5D0, 0x050]) do b, echo
    step("airbag lamp off", echo, 4)
    b.airbag_lamp = true; step("airbag lamp on", echo, 4)
end
