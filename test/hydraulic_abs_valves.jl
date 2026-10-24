using Test
using Statistics
using DyadInterface: symbolic_container

const _HV = VehicleSystemsComponents.Vehicle
const _HH = VehicleSystemsComponents.HandsOn03
const _HB = VehicleSystemsComponents.Vehicle.Brake

@testset "Hydraulic ABS valves" begin
    open_loop = _HB.TestModulatorOpenLoopTransient()
    mo = symbolic_container(open_loop)
    rate(a, b) = (open_loop.sol(b, idxs = mo.wheel.port.p) - open_loop.sol(a, idxs = mo.wheel.port.p)) / (b - a) / 1e5
    @test 300 < rate(0.02, 0.08) < 1000
    @test abs(rate(0.22, 0.27)) < 1
    @test 400 < -rate(0.30, 0.36) < 1000
    @test abs(rate(0.40, 0.45)) < 1
    @test 30 < rate(0.50, 0.64) < 150
    @test all(open_loop.sol[mo.wheel.port.p] .<= open_loop.sol[mo.source.port.p] .+ 0.2e5)
    @test 4e5 <= minimum(open_loop.sol[mo.modulator.p_lpa]) <= maximum(open_loop.sol[mo.modulator.p_lpa]) <= 10.5e5

    cutoff = _HV.TestABSValveControllerLowSpeedTransient()
    mc = symbolic_container(cutoff)
    @test cutoff.sol(0.01, idxs = mc.controller.phase_out) < -0.5
    @test cutoff.sol(0.11, idxs = mc.controller.phase_out) > 1.5
    @test cutoff.sol(0.11, idxs = mc.controller.inlet) == 1.0
    @test cutoff.sol(0.11, idxs = mc.controller.outlet) == 0.0
    @test cutoff.sol(0.11, idxs = mc.controller.motor) == 0.0


    inactive = _HH.HydraulicABSStopTransient(pedal = 0.3)
    baseline = _HH.PedalStopTransient(pedal = 0.3)
    @test _HV.braking_distance(inactive) ≈ _HV.braking_distance(baseline) atol = 0.1
    @test all(inactive.sol[symbolic_container(inactive).controller.phase_out] .> 1.5)

    for (mu, stop) in ((1.0, 6.0), (0.5, 7.0), (0.3, 11.0))
        run = _HH.HydraulicABSStopTransient(road_mu = mu, stop = stop)
        @test isfinite(_HV.braking_distance(run))
        m = symbolic_container(run)
        t, v = run.sol.t, run.sol[m.body.mass.v]
        phase = run.sol[m.controller.phase_out]
        pressure = run.sol[m.wheel.caliper_f.p]
        active = (t .>= 0.5) .& (v .> 1.5) .& (phase .< 1.5)
        @test all(pressure .<= run.sol[m.master.p_mc] .+ 0.2e5)
        @test mean(pressure[active]) / 1e5 ≈ mu * 62 rtol = 0.25
        dumps = t[findall(diff(phase .< -0.5) .== 1) .+ 1]
        dumps = dumps[dumps .> 0.5]
        frequency = (length(dumps) - 1) / (dumps[end] - dumps[1])
        @test 2 <= frequency <= 15
        @test Set(round.(Int, phase[active])) ⊇ Set((-1, 1))
        x = run.sol[m.master.x_rod][active]
        @test maximum(x) - minimum(x) >= 0.5e-3
    end

    # Existing torque-level controller regressions remain independent of the valve controller.
    @test _HV.braking_distance(_HV.IdealBrakeTransient()) ≈ 34.4453 atol = 0.05
    @test _HV.braking_distance(_HV.ABSBrakeTransient()) ≈ 38.6980 atol = 0.05

    failed = _HH.HydraulicABSStopTransient(road_mu = 0.3, pump_enabled = 0.0, stop = 8.5)
    mf = symbolic_container(failed)
    @test maximum(failed.sol[mf.modulator_f.V_lpa]) >= 0.999 * 5.3e-6
    lock = failed.sol[mf.wheel.kappa] .< -0.5
    i_lock = findfirst(lock)
    @test !isnothing(i_lock)
    @test all(lock[i_lock:end])
    @test failed.sol[mf.modulator_f.accumulator_acceptance_filtered][end] < 1e-3
end
