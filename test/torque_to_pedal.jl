# Standalone, stdlib-only: julia --project=. test/torque_to_pedal.jl
# Include separately from lecture05_plausibility.jl; no engine simulation required.
using Test
include("../scripts/torque_to_pedal.jl")
const TTP = TorqueToPedalMap

@testset "Lecture 5 steady torque-to-pedal inverse" begin
    m = TTP.BsfcLine.load_maps()
    @testset "committed CSV is deterministic and complete" begin
        @test read(TTP.MAP_FILE, String) == TTP.render_map(m)
        rows = split.(readlines(TTP.MAP_FILE)[2:end], ',')
        @test length(rows) == length(TTP.SPEEDS)
        @test all(r -> length(r) == 1 + length(TTP.TORQUES), rows)
        @test all(r -> all(x -> 0 <= parse(Float64, x) <= 1, r[2:end]), rows)
    end
    @testset "inverse reproduces reachable fired torque" begin
        for n in (800.0, 1250.0, 3000.0, 4500.0, 6400.0)
            low = TTP.fired_torque(m, n, TTP.steady_pressure(n, 0.0))
            high = TTP.fired_torque(m, n, TTP.steady_pressure(n, 1.0))
            pedals = [TTP.inverse_pedal(m, n, tau) for tau in TTP.TORQUES]
            @test all(diff(pedals) .>= -1e-12)
            for tau in (0.0, 20.0, 60.0, 100.0, 150.0, 180.0)
                pedal = TTP.inverse_pedal(m, n, tau)
                p = TTP.steady_pressure(n, pedal)
                @test 0 <= pedal <= 1
                @test TTP.throttle_flow(pedal, p) ≈ TTP.cylinder_flow(n, p) atol = 1e-12
                @test TTP.fired_torque(m, n, p) ≈ clamp(tau, low, high) atol = 1e-7
            end
            @test TTP.inverse_pedal(m, n, 1e6) ≈ TTP.inverse_pedal(m, n, high) atol = 1e-10
        end
    end
end
