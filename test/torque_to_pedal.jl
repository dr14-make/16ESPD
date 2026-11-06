# Included by lecture05_plausibility.jl; run test/runtests.jl lecture05.
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
    @testset "interpolated CSV reproduces torque" begin
        rows = split.(readlines(TTP.MAP_FILE)[2:end], ',')
        grid = [parse(Float64, rows[i][j+1]) for i in eachindex(rows), j in eachindex(TTP.TORQUES)]
        errors = Float64[]
        for n in (1025.0, 2525.0, 4025.0, 6025.0), tau in (20.5, 60.5, 100.5)
            i = clamp(searchsortedlast(TTP.SPEEDS, n), 1, length(TTP.SPEEDS)-1)
            j = searchsortedlast(TTP.TORQUES, tau)
            a = (n - TTP.SPEEDS[i]) / (TTP.SPEEDS[i+1] - TTP.SPEEDS[i])
            b = tau - TTP.TORQUES[j]
            pedal = (1-a) * ((1-b)*grid[i,j] + b*grid[i,j+1]) + a * ((1-b)*grid[i+1,j] + b*grid[i+1,j+1])
            actual = TTP.fired_torque(m, n, TTP.steady_pressure(n, pedal))
            high = TTP.fired_torque(m, n, TTP.steady_pressure(n, 1.0))
            push!(errors, abs(actual - min(tau, high)))
        end
        @test maximum(errors) < 0.5
        @info "Interpolated torque inverse" max_error_Nm=maximum(errors)
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
    @testset "inverse against steady Dyad engine" begin
        for (rpm, tau) in ((1250.0, 20.0), (3000.0, 60.0), (4500.0, 100.0))
            pedal = TTP.inverse_pedal(m, rpm, tau)
            r = VehicleSystemsComponents.Vehicle.Engine.MappedEngineDynoTransient(
                rpm = rpm, pedal_cmd = pedal, stop = 8.0, progress = false)
            engine = symbolic_container(r).engine
            @test string(r.sol.retcode) == "Success"
            @test r.sol(8.0, idxs = engine.tau_e) ≈ tau atol = 0.5
        end
    end

end
