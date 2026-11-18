# Run from repository root: julia --project=. sim/fabia/08_coolant.jl
# Motor_2 0x288: coolant temperature gauge.
include("common.jl")
bench(; only = [0x280, 0x288]) do b, echo
    b.rpm = 800
    for T in (50, 90, 120)
        b.coolant = T
        step("coolant gauge at $T °C", echo, 6)
    end
end
