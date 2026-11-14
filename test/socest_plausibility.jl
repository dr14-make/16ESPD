using DyadInterface: simplify_model
using ModelingToolkit
using OrdinaryDiffEqDefault: solve, Tsit5

const _SE = VehicleSystemsComponents.Vehicle.Electric
const _SE_Q = 40.0e3 * 3600.0 / 350.0

function _se_run(stop; kwargs...)
    model = _SE.SoCDriftDays(; name = :socbench, kwargs...)
    sys = simplify_model(model)
    sol = solve(ODEProblem(sys, [], (0.0, stop)), Tsit5();
        reltol = 1e-9, abstol = 1e-11, saveat = 60.0)
    @test string(sol.retcode) == "Success"
    return sol, sys
end

@testset "SoC estimator: three days of drive and equilibrium rest" begin
    s, m = _se_run(3 * 86400.0)
    at(t, x) = s(t, idxs = x)
    for day in 0:2
        start = day * 86400.0
        e1 = at(start + 1800, m.error)
        e2 = at(start + 5400, m.error)
        @test (e2 - e1) ≈ -0.05 * 3600 / _SE_Q atol = 2e-9
        @test at(start + 7200, m.soc_true) ≈ 0.9 - (day + 1) * 5 * 7200 / _SE_Q atol = 2e-8
        @test abs(at(start + 10740, m.error)) > 0.001
        @test abs(at(start + 10860, m.error)) < 1e-8
        @test abs(at(start + 10860, m.battery.v1)) < 1e-9
        @test at(start + 10860, m.estimated_soc) ≈ at(start + 10860, m.soc_true) atol = 1e-8
        println("SoC day $(day + 1): drive slope=$((e2-e1)) SoC/h, pre-reset=$(at(start+10740,m.error)), residual=$(at(start+10860,m.error))")
    end
    @test at(259200, m.soc_true) ≈ 0.6375 atol = 2e-8
end

@testset "SoC estimator: exercise 2, 50 mA continuous drift" begin
    # Sample before the final solve time: the endpoint save precedes the last clock callback.
    # 0.2 A keeps the physical pack in its valid SoC range for the full exercise.
    s, m = _se_run(114 * 3600.0 + 120.0; I_drive = 0.2, t_drive = 500000.0,
        period = 600000.0, dt = 60.0)
    at(t, x) = s(t, idxs = x)
    slope = (at(100 * 3600, m.error) - at(10 * 3600, m.error)) / 90
    expected = -0.05 / (_SE_Q / 3600)
    @test slope ≈ expected atol = 1e-10
    @test slope ≈ -0.05 / 114.3 rtol = 2e-4
    @test at(114 * 3600, m.error) ≈ -0.049875 atol = 2e-8
    @test 0.05 / abs(slope) ≈ 114.2857142857 atol = 1e-4
    @test at(114 * 3600, m.soc_true) ≈ 0.7005 atol = 2e-8
    println("SoC exercise 2: slope=$slope SoC/h, error at 114 h=$(at(114*3600,m.error)), 5 percent at $(0.05/abs(slope)) h")
end

@testset "SoC estimator: short rests do not accumulate or reset" begin
    s, m = _se_run(21600.0; t_drive = 5400.0, period = 7200.0,
        SoC0_est = 0.8, dt = 60.0)
    for t in [5340.0, 7140.0, 12540.0, 14340.0, 19740.0, 21540.0]
        @test s(t, idxs = m.error) ≈ -0.1 - 0.05 * t / _SE_Q atol = 2e-8
    end
    println("SoC interrupted rests: final error=$(s(21540, idxs=m.error)); initial mismatch retained")
end

@testset "SoC estimator: charging sign, zero bias, measured rest threshold" begin
    s, m = _se_run(7320.0; I_drive = -1.0, t_drive = 8000.0,
        period = 10000.0, I_offset = -0.05, dt = 60.0)
    @test s(7200, idxs = m.soc_true) ≈ 0.9175 atol = 1e-8
    @test s(7200, idxs = m.error) ≈ 0.000875 atol = 1e-8
    s, m = _se_run(12000.0; I_offset = 0.0, dt = 60.0)
    @test abs(s(5400, idxs = m.error)) < 1e-8
    @test abs(s(10860, idxs = m.error)) < 1e-8
    s, m = _se_run(7320.0; I_drive = 0.0, I_offset = 0.2,
        SoC0_est = 0.8, dt = 60.0)
    @test s(7200, idxs = m.error) ≈ -0.1 - 0.2 * 7200 / _SE_Q atol = 1e-8
    s, m = _se_run(7200.0; I_drive = 0.0, SoC0_est = 0.7, dt = 60.0)
    @test s(3540, idxs = m.estimated_soc) ≈ 0.7 - 0.05 * 3540 / _SE_Q atol = 1e-8
    @test s(3660, idxs = m.estimated_soc) ≈ 0.9 atol = 1e-8
end
