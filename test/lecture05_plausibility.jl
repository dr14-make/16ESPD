using DyadInterface: symbolic_container

@testset "hybrid drive" begin
    run = VehicleSystemsComponents.Lecture5.HybridDriveDynoTransient()
    @test string(run.sol.retcode) == "Success"
    d = symbolic_container(run).drive
    ps = run.sol.ps
    @test ps[d.machine.T_max] == 205.0
    @test ps[d.machine.w_base] * 30 / pi ≈ 1397.458 atol = 0.001
    @test ps[d.machine.V_nom] == 270.0
    @test ps[d.battery.E] * ps[d.battery.Q_nom] / 3.6e6 ≈ 1.4 rtol = 0.05
    @test run.sol[d.SoC][1] ≈ 0.6
    @test ps[d.battery.R0] ≈ 0.1 * 270 / 350
    @test ps[d.reduction.ratio] == 1.0
    # Independent Leaf-based scaling and the unchanged machine's quadratic design equation.
    scale = 30 / 110
    R = 0.05 * (270 / 350)^2 / scale
    w = 30e3 / 205
    losses = (0.5 + 1.0) * scale + 300 / (10100pi / 30)^3 * scale * w^2 + 200scale / w
    k = (270 + sqrt(270^2 - 4w * R * (205 + losses))) / (2w)
    for (p, expected) in ((d.machine.R, R), (d.machine.L, 0.01R),
            (d.machine.J, 0.05scale), (d.machine.T_f, 0.5scale),
            (d.machine.K_i, scale), (d.machine.k_w, 300 / (10100pi / 30)^3 * scale),
            (d.machine.C, 200scale), (d.machine.tau_loss_base, losses), (d.machine.k, k),
            (d.converter.I_max, (205 + losses) / k))
        @test ps[p] ≈ expected rtol = 1e-12
    end
    ts = collect(0.5:0.01:22.0)
    at(x) = run.sol(ts, idxs = x).u
    torque, power = at(d.machine.tau), at(d.machine.P_mech)
    rpm, field = at(d.machine.w) .* (30 / pi), at(d.converter.field)
    @test maximum(torque) ≈ 205.0 rtol = 0.05
    @test maximum(power) ≈ 30e3 rtol = 0.05
    # Report a reproducible loaded corner: first sample with >0.1% field weakening.
    corner = rpm[findfirst(<(0.999), field)]
    @test 1300 < corner < 1450
    @info "30 kW hybrid envelope" peak_torque=maximum(torque) peak_power=maximum(power) nominal_corner_rpm=ps[d.w_base]*30/pi loaded_corner_rpm=corner energy_kWh=ps[d.battery.E]*ps[d.battery.Q_nom]/3.6e6
    for rpm0 in (200, 700, 1400, 2000, 3000, 4000)
        t = rpm0 == 4000 ? 22.0 : rpm0 == 200 ? 0.5 : 1 + (rpm0 - 200) / 190
        @info "30 kW dyno" rpm=rpm0 torque=run.sol(t, idxs=d.machine.tau) power=run.sol(t, idxs=d.machine.P_mech)
    end
    # Algebraic residual follows the default relative solver tolerance (about 1e-6).
    @test all(isapprox.(at(d.converter.P_in), at(d.converter.P_out) .+ at(d.converter.P_loss); rtol=1e-5))
    @test all(isapprox.(at(d.battery.v), ps[d.battery.E] .- ps[d.battery.R0] .* at(d.battery.i); atol=1e-8))
    @test run.sol[d.SoC][end] < run.sol[d.SoC][1]
    # Held final speed removes rotor acceleration and electrical storage terms.
    t = 22.0
    value(x) = run.sol(t, idxs=x)
    @test value(d.machine.P_elec) ≈ value(d.machine.P_mech) + value(d.machine.P_loss) rtol=1e-8

    # ICCT-2022 Fig. 6 compares 15 kW positions. Halve torque, not speed, to keep the
    # transmission-input speed range fixed; this is a sizing comparison, not a measured map.
    small = VehicleSystemsComponents.Lecture5.HybridDriveDynoTransient(P_rated=15e3, T_max=102.5)
    @test string(small.sol.retcode) == "Success"
    s = symbolic_container(small).drive
    @test small.sol.ps[s.machine.w_base] ≈ ps[d.machine.w_base]
    @test small.sol.ps[s.machine.T_max] == 102.5
    @test small.sol.ps[s.machine.C] ≈ ps[d.machine.C] / 2
    @test small.sol.ps[s.machine.R] ≈ 2 * ps[d.machine.R]
    @test small.sol.ps[s.converter.I_max] ≈ ps[d.converter.I_max] / 2
    @test small.sol.ps[s.battery.E] * small.sol.ps[s.battery.Q_nom] / 3.6e6 ≈ 1.4
    small_torque = small.sol(ts, idxs=s.machine.tau).u
    small_power = small.sol(ts, idxs=s.machine.P_mech).u
    small_rpm = small.sol(ts, idxs=s.machine.w).u .* (30 / pi)
    small_field = small.sol(ts, idxs=s.converter.field).u
    @test maximum(small_torque) ≈ 102.5 rtol=0.05
    @test maximum(small_power) ≈ 15e3 rtol=0.05
    small_corner = small_rpm[findfirst(<(0.999), small_field)]
    @test 1300 < small_corner < 1450
    @info "15 kW hybrid envelope" peak_torque=maximum(small_torque) peak_power=maximum(small_power) loaded_corner_rpm=small_corner
    for rpm0 in (200, 700, 1400, 2000, 3000, 4000)
        t = rpm0 == 4000 ? 22.0 : rpm0 == 200 ? 0.5 : 1 + (rpm0 - 200) / 190
        @info "15 kW dyno" rpm=rpm0 torque=small.sol(t, idxs=s.machine.tau) power=small.sol(t, idxs=s.machine.P_mech)
    end
end
