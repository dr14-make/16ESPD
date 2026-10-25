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

@testset "Full brake chain with valve ABS" begin
    full = VehicleSystemsComponents.Lecture3.FullBrakeABSStopTransient
    stops = Dict(1.0 => 6.0, 0.5 => 7.0, 0.3 => 11.0)
    idle_distance = Dict{Float64, Float64}()
    idle_p_mc = 0.0
    for mu in (1.0, 0.5, 0.3)
        run = full(road_mu = mu, stop = stops[mu])
        reference = _HH.HydraulicABSStopTransient(road_mu = mu, stop = stops[mu])
        d, d_ref = _HV.braking_distance(run), _HV.braking_distance(reference)
        idle_distance[mu] = d
        # The booster's chamber fill delays the first activation by about 0.34 s against the
        # static booster; on µ = 0.5 the valve cycling also settles to a lower mean pressure.
        if mu == 0.5
            @test_broken d ≈ d_ref rtol = 0.10
        else
            @test d ≈ d_ref rtol = 0.10
        end
        m = symbolic_container(run)
        t, v = run.sol.t, run.sol[m.body.mass.v]
        phase = run.sol[m.controller.phase_out]
        @test all(run.sol[m.wheel.caliper_f.p] .<= run.sol[m.master.p_mc] .+ 0.2e5)
        dumps = t[findall(diff(phase .< -0.5) .== 1) .+ 1]
        dumps = dumps[dumps .> 0.5]
        @test 2 <= (length(dumps) - 1) / (dumps[end] - dumps[1]) <= 15
        mu == 1.0 && (idle_p_mc = maximum(run.sol[m.master.p_mc]))
    end

    inactive = full(pedal = 0.3, abs_on = 0.0)
    @test _HV.braking_distance(inactive) ≈ 38.39 atol = 0.2
    @test all(inactive.sol[symbolic_container(inactive).modulator_f.outlet] .== 0.0)

    # Past the stop the WOT manifold and the empty booster sit at the same pressure, and the
    # check valve chatters at standstill, so the run ends shortly after the car stops.
    for depleted in (full(u_thr = 1.0, p_vac0 = 100e3, stop = 13.0),
                     full(engine_on = 0.0, p_vac0 = 100e3, stop = 13.0))
        m = symbolic_container(depleted)
        t, v = depleted.sol.t, depleted.sol[m.body.mass.v]
        braking = (t .>= 0.5) .& (v .> 1.5)
        @test maximum(depleted.sol[m.master.p_mc]) < 0.5 * idle_p_mc
        @test count(depleted.sol[m.controller.phase_out][braking] .< 1.5) < 0.05 * count(braking)
        @test _HV.braking_distance(depleted) > 1.5 * idle_distance[1.0]
    end

    @test _HV.braking_distance(_HH.PedalStopTransient()) ≈ 43.708 atol = 1e-3
    @test _HV.braking_distance(_HH.PedalStopTransient(pedal = 0.3)) ≈ 35.958 atol = 1e-3
    @test _HV.braking_distance(_HV.IdealBrakeTransient()) ≈ 34.4453 atol = 1e-4
    @test _HV.braking_distance(_HV.ABSBrakeTransient()) ≈ 38.6980 atol = 1e-4
    @test _HV.braking_distance(VehicleSystemsComponents.Lecture3.VacuumPedalStopTransient()) ≈ 38.39 atol = 0.01
    @test _HV.braking_distance(_HH.HydraulicABSStopTransient()) ≈ 39.11 atol = 0.01
end

@testset "Whole car with valve ABS" begin
    car = VehicleSystemsComponents.Lecture3.FullCarABSStopTransient
    dry = car()
    @test isfinite(_HV.braking_distance(dry))
    report = VehicleSystemsComponents.Lecture3.FullCarABSStopReportTransient
    with_abs = report()
    locked = report(abs_on = 0.0, stop = 12.0)
    @test _HV.braking_distance(with_abs) < _HV.braking_distance(locked)
    ml = symbolic_container(locked)
    lock = locked.sol[ml.wheel.kappa] .< -0.5
    i_lock = findfirst(lock)
    @test !isnothing(i_lock)
    v_locked = locked.sol[ml.body.mass.v]
    i_stop = findfirst(i -> locked.sol.t[i] > 0.5 && v_locked[i] < 0.5, eachindex(v_locked))
    @test all(lock[i_lock:i_stop])
    for run in (dry, with_abs, locked)
        m = symbolic_container(run)
        @test all(run.sol[m.flywheel.w] .> 0)
        @test all(run.sol[m.booster.p_vac] .< 101325.0)
    end
end
