# Bremse_1/2/3 (0x1A0, 0x5A0, 0x4A0): speedometer. Compare the needle with the cluster echo.
include("common.jl")
bench(; only = [0x1A0, 0x5A0, 0x4A0]) do b, echo
    for kmh in (30, 60, 100, 0)
        b.kmh = kmh
        step("speedometer at $kmh km/h", echo, 6)
    end
end
