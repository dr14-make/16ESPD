using DyadInterface: symbolic_container

const _K0 = VehicleSystemsComponents.Vehicle

function _k0_run(; command = 1.0, demand = 100.0, slip_start = 100.0)
    bench = _K0.TestDisconnectClutch(; name = :bench, command, demand, slip_start)
    return _K0.DisconnectClutchTransient(model = bench)
end

@testset "Lecture 5: K0 actuator and torque capacity" begin
    run = _k0_run()
    m, s = symbolic_container(run), run.sol
    T = s.ps[m.clutch.actuator_time]
    peak_rows = split.(readlines(joinpath(@__DIR__, "../data/engine/full_load.csv"))[2:end], ',')
    peak = maximum(parse(Float64, row[2]) for row in peak_rows)
    capacity = s[m.clutch.tau_capacity][end]
    nominal = s.ps[m.clutch.tau_max]
    @test nominal == 230.0
    @test capacity >= 1.5 * peak
    @test s[m.clutch.position][1] == 0.0
    @test s(0.1 + T * log(10), idxs = m.clutch.position) ≈ 0.9 atol = 1e-6
    rise = rise_time(s.t, s[m.clutch.position], 0.9; t0 = 0.1)
    @test rise <= 0.35
    @test all(0 .<= s[m.clutch.capacity_fraction] .<= 1)
    @test all(s[m.clutch.tau] .* s[m.clutch.w_slip] .>= 0)
    # Both free inertias accelerate together; transmitted torque is demand * J_load / J_total.
    expected_tau = 100.0 * 1.5 / (1.5 + 0.15)
    @test s[m.clutch.tau][end] ≈ expected_tau atol = 1e-5
    @test abs(s[m.clutch.w_slip][end]) < 1.0
    @test s[m.clutch.w_slip][end] ≈
        s.ps[m.clutch.w_regularization] * atanh(expected_tau / capacity) atol = 1e-6
    println("K0: peak=$(peak) N.m, nominal=$(nominal) N.m, capacity=$(capacity) N.m, " *
        "t90=$(rise) s, slip=$(s[m.clutch.w_slip][end]) rad/s")
end

@testset "Lecture 5: K0 open over signed slip through 300 rad/s" begin
    max_open = 0.0
    for slip in (-300.0, -100.0, 0.0, 100.0, 300.0)
        run = _k0_run(command = 0.0, demand = 0.0, slip_start = slip)
        m, s = symbolic_container(run), run.sol
        torque = maximum(abs, s[m.clutch.tau])
        max_open = max(max_open, torque)
        @test torque < 1.0
        @test s[m.clutch.w_slip][1] ≈ slip atol = 1e-10
        @test maximum(abs, s[m.clutch.w_slip]) <= 300.0 + 1e-8
        @test all(s[m.clutch.position] .== 0)
    end
    println("K0: maximum open torque=$(max_open) N.m")
end

@testset "Lecture 5: K0 near-lock under mapped-engine peak demand" begin
    run = _k0_run(demand = 150.234)
    m, s = symbolic_container(run), run.sol
    @test abs(s[m.clutch.w_slip][end]) < 1.0
    @test abs(s[m.clutch.tau][end]) < s[m.clutch.tau_capacity][end]
    @test s[m.clutch.tau][end] ≈ 150.234 / 1.1 atol = 1e-5
    println("K0: peak-demand settled slip=$(s[m.clutch.w_slip][end]) rad/s")
end
