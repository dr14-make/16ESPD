# Motor_1 0x280 alone: tachometer.
include("common.jl")
bench(; only = [0x280]) do b, echo
    for rpm in (1000, 3000, 6000, 0)
        b.rpm = rpm
        step("tachometer at $rpm rpm", echo, 5)
    end
end
