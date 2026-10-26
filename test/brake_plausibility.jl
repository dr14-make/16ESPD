using DyadInterface: symbolic_container

@testset "Brake force-chain plausibility" begin
    result = VehicleSystemsComponents.Vehicle.Brake.ForceChainTransient()
    sol = result.sol
    model = symbolic_container(result)

    pedal_forces = [50.0, 100.0, 170.0, 232.0, 500.0]
    expected_bar = [19.5, 37.3, 62.3, 84.3, 103.4]
    for (force, expected) in zip(pedal_forces, expected_bar)
        pressure_bar = sol(force / 100.0, idxs=model.master.p_mc) / 1e5
        @test pressure_bar ≈ expected rtol=0.02
    end

    # The ramp is 100 N/s, and the booster input is 3.5 times pedal force.
    cut_in_pedal_force = 40.0 / 3.5
    p_below = sol((cut_in_pedal_force - 1.0) / 100.0, idxs=model.master.p_mc)
    p_above = sol((cut_in_pedal_force + 1.0) / 100.0, idxs=model.master.p_mc)
    @test p_below == 0.0
    @test p_above > 0.0

    A_mc = pi * 0.025^2 / 4
    slope_boosted = (sol(2.0, idxs=model.master.p_mc) -
                     sol(1.0, idxs=model.master.p_mc)) / 100.0
    slope_runout = (sol(5.0, idxs=model.master.p_mc) -
                    sol(3.0, idxs=model.master.p_mc)) / 200.0
    @test slope_boosted ≈ 5.0 * 3.5 / A_mc rtol=0.02
    @test slope_runout ≈ 3.5 / A_mc rtol=0.02

    for t in range(0.0, 5.0, length=11)
        @test sol(t, idxs=model.pedal.x_ped) ≈ 8.75e-3 rtol=1e-8
    end

    no_vacuum = VehicleSystemsComponents.Vehicle.Brake.ForceChainTransient(p_vac=101325.0)
    no_vacuum_model = symbolic_container(no_vacuum)
    booster_force_no_vacuum = no_vacuum.sol[no_vacuum_model.booster.F_out]
    @test all(booster_force_no_vacuum .>= 0.0)

    p_no_vacuum = no_vacuum.sol(5.0, idxs=no_vacuum_model.master.p_mc)
    expected_no_vacuum = (3.5 * 500.0 - 315.0) / A_mc
    @test p_no_vacuum ≈ expected_no_vacuum rtol=0.02
    @test p_no_vacuum / 1e5 ≈ 29.2 rtol=0.02
end


@testset "Hydraulic brake-stop plausibility" begin
    for (pedal, expected_bar, expected_tau) in ((0.3, 55.1, 3760.0), (0.6, 89.0, 6100.0))
        result = VehicleSystemsComponents.Vehicle.Brake.HydraulicStopTransient(pedal=pedal, stop=6.0)
        sol = result.sol
        model = symbolic_container(result)
        pressure = sol[model.master.p_mc]
        torque = sol[model.wheel.caliper_f.tau] .+ sol[model.wheel.caliper_r.tau]
        volume = sol[model.master.V_disp]
        @test maximum(pressure) / 1e5 ≈ expected_bar rtol=0.03
        @test maximum(torque) ≈ expected_tau rtol=0.03
        @test 3e-6 < maximum(volume) < 5e-6
        if pedal == 0.3
            @test minimum(sol[model.wheel.kappa]) > -0.04
        else
            @test minimum(sol[model.wheel.kappa]) < -0.99
        end
    end
end
