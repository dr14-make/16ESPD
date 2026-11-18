# Run from repository root: julia --project=. sim/fabia/10_all.jl
# Everything at once: 100 km/h, 3000 rpm, left indicator, ABS lamp.
include("common.jl")
bench() do b, echo
    b.kmh, b.rpm, b.left, b.abs_lamp = 100, 3000, true, true
    step("100 km/h, 3000 rpm, left indicator, ABS lamp", echo, 8)
end
