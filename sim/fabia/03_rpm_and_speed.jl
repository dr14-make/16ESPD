# Engine and brake frames together: a short drive.
include("common.jl")
bench(; only = [0x280, 0x288, 0x1A0, 0x5A0, 0x4A0]) do b, echo
    for (kmh, rpm) in ((0, 800), (50, 2500), (100, 3000), (0, 800))
        b.kmh, b.rpm = kmh, rpm
        step("$kmh km/h at $rpm rpm", echo, 6)
    end
end
