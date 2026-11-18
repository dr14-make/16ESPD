# Run from repository root: julia --project=. sim/fabia/00_listen.jl

# Send nothing; print what the cluster reports for 10 s.
include("common.jl")
bench(; only = UInt32[]) do b, echo
    step("listen only, no frames sent", echo, 10; ask = false)
end
