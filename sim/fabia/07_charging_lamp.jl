# Run from repository root: julia --project=. sim/fabia/07_charging_lamp.jl
# BSG_Kombi 0x470 bit 7: battery/charging lamp.
include("common.jl")
bench(; only = [0x470, 0x570]) do b, echo
    step("charging lamp off", echo, 4)
    b.charging = true; step("charging lamp on", echo, 4)
    b.charging = false; step("charging lamp off again", echo, 4)
end
