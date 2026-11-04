# Lecture 5 best-BSFC operating line (scripts/bsfc_line.jl), the line the CVT holds the engine on.

include("../scripts/bsfc_line.jl")
using .BsfcLine

@testset "Lecture 5 best-BSFC line" begin
    m = load_maps()
    rows = [parse.(Float64, split(l, ',')) for l in readlines(LINE_FILE)[2:end]]
    power, rpm, torque, bsfc = (getindex.(rows, k) for k in 1:4)

    @testset "the committed file is what the script writes" begin
        @test read(LINE_FILE, String) == render_line(operating_line(m))
    end

    @testset "speed rises with power, idle to peak" begin
        @test all(diff(power) .> 0)
        @test issorted(rpm)
        @test rpm[end] > rpm[1]
        @test first(power) == 1.0
        peak = maximum(n -> reachable_torque(m, n) * n * pi / 30e3, BsfcLine.SPEEDS)
        @test last(power) ≈ peak atol = 1e-3
        @test RPM_IDLE <= first(rpm) && last(rpm) <= RPM_MAX
    end

    @testset "every point is a reachable operating point" begin
        @test all(isapprox.(torque .* rpm .* pi ./ 30e3, power; rtol = 1e-4))
        @test all(torque .<= reachable_torque.(Ref(m), rpm) .+ 1e-3)
    end

    # Independent of the script's search: BSFC at the table nodes themselves, under full load and
    # inside the speed range. Between nodes BSFC is a ratio of linear functions along each axis,
    # so no point of the bilinear map is lower than its lowest node or full-load cap point.
    @testset "the line reaches the map's minimum BSFC [g/kWh]" begin
        fl(n) = BsfcLine.lin(m.fl_rpm, m.fl_T, n)
        node_min = minimum(m.fuel[i, j] * 3600 / (m.torque[i, j] * n * pi / 30e3)
                           for (i, n) in enumerate(m.rpm), j in eachindex(m.kpa)
                           if RPM_IDLE <= n <= RPM_MAX && 0 < m.torque[i, j] <= fl(n))
        best = global_min_bsfc(m)
        line_min = minimum(bsfc)
        @info "Best-BSFC line" node_min best line_min
        @test best.bsfc <= node_min + 1e-6
        @test node_min - best.bsfc < 1.0
        # 1 kW power steps and 5 rpm speed steps leave the line just above the true minimum.
        @test line_min - best.bsfc < 0.5
        @test line_min >= best.bsfc - 0.01
        @test 225 <= line_min <= 260
    end
end
