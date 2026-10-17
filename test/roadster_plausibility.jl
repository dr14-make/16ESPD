using DyadInterface: symbolic_container
using OrdinaryDiffEqDefault: remake, solve

const ROADSTER_V60 = 26.8224
const ROADSTER_G = 9.80665
const ROADSTER_GRIP = 0.98
const ROADSTER_MU = 1.26

function roadster_launch(; kwargs...)
    result = VehicleSystemsComponents.Roadster.RoadsterLaunchTransient(; kwargs...)
    return result.sol, symbolic_container(result)
end

function first_crossing(sol, signal, target)
    values = sol[signal]
    i = findfirst(>=(target), values)
    i === nothing && return Inf
    i == firstindex(values) && return sol.t[i]
    t0, t1 = sol.t[i-1], sol.t[i]
    y0, y1 = values[i-1], values[i]
    return t0 + (target - y0) * (t1 - t0) / (y1 - y0)
end

@testset "Roadster tire-only launch plausibility" begin
    awd_sol, awd = roadster_launch(share = 1.0, h_over_L = 0.0)
    rwd_sol, rwd = roadster_launch()
    t60_awd = first_crossing(awd_sol, awd.v, ROADSTER_V60)
    t60_rwd = first_crossing(rwd_sol, rwd.v, ROADSTER_V60)

    @testset "closed-form anchors" begin
        t60_awd_closed = ROADSTER_V60 / (ROADSTER_GRIP * ROADSTER_MU * ROADSTER_G)
        a_rwd_over_g = ROADSTER_GRIP * ROADSTER_MU * 0.55 /
                       (1 - ROADSTER_GRIP * ROADSTER_MU * 0.17)
        t60_rwd_closed = ROADSTER_V60 / (a_rwd_over_g * ROADSTER_G)
        drive_force = ROADSTER_GRIP * ROADSTER_MU * 2000 * ROADSTER_G
        drive_power = drive_force * ROADSTER_V60

        @test t60_awd_closed ≈ 2.2150337019 rtol = 1e-9
        @test t60_rwd_closed ≈ 3.1819321588 rtol = 1e-9
        @test drive_force ≈ 24.2185e3 rtol = 1e-6
        @test drive_power ≈ 649.598e3 rtol = 1e-6
    end

    @testset "acceptance bands" begin
        @test 2.20 <= t60_awd <= 2.35
        @test 3.15 <= t60_rwd <= 3.45

        masses = (1700.0, 2000.0, 2350.0)
        mass_times = map(masses) do mass
            sol, model = roadster_launch(m = mass)
            first_crossing(sol, model.v, ROADSTER_V60)
        end
        mass_spread = (maximum(mass_times) - minimum(mass_times)) / mass_times[2]
        @test mass_spread < 0.03

        t60_awd_exact = first_crossing(awd_sol, awd.v, ROADSTER_V60)
        drive_power_at_60 = awd_sol(t60_awd_exact, idxs = awd.motor.P)
        @test drive_power_at_60 < 1.0e6
        @test drive_power_at_60 ≈ 650e3 rtol = 0.04

        sample_times = range(0.1, min(t60_rwd, t60_awd), length = 200)
        for (sol, model) in ((rwd_sol, rwd), (awd_sol, awd))
            slip = [sol(t, idxs = model.wheel.kappa) for t in sample_times]
            @test minimum(slip) >= 0.02
            @test maximum(slip) <= 0.05
        end
    end
end


@testset "Roadster suction plausibility" begin
    area = 4.0
    perimeter = 10.0
    discharge = 0.6
    efficiency = 0.6
    density = 1.2
    mass = 2000.0

    fan_result = VehicleSystemsComponents.Roadster.SuctionFanTransient()
    fan_sol = fan_result.sol
    fan = symbolic_container(fan_result)
    hold_result = VehicleSystemsComponents.Roadster.SuctionFanInvertedHoldTransient()
    hold_sol = hold_result.sol
    hold = symbolic_container(hold_result)

    @testset "closed-form fan anchors" begin
        dp_full_closed = 4700 * ROADSTER_G / area
        leakage(dp, gap) = discharge * perimeter * gap * sqrt(2 * dp / density)
        fan_power(dp, gap) = leakage(dp, gap) * dp / efficiency
        dp_hold_closed = mass * ROADSTER_G / area

        dp_full_measured = fan_sol(0.0, idxs = fan.fan.dp)
        power_3mm_measured = fan_sol(0.0, idxs = fan.fan.power)
        fan_10mm_result = VehicleSystemsComponents.Roadster.SuctionFanTransient(gap = 0.010)
        fan_10mm_sol = fan_10mm_result.sol
        fan_10mm = symbolic_container(fan_10mm_result)
        power_10mm_measured = fan_10mm_sol(0.0, idxs = fan_10mm.fan.power)
        dp_hold_measured = hold_sol(0.0, idxs = hold.fan.dp)
        power_hold_measured = hold_sol(0.0, idxs = hold.fan.power)

        @test dp_full_measured ≈ dp_full_closed rtol = 0.005
        @test power_3mm_measured ≈ fan_power(dp_full_closed, 0.003) rtol = 0.02
        @test power_10mm_measured ≈ fan_power(dp_full_closed, 0.010) rtol = 0.02
        @test dp_hold_measured ≈ dp_hold_closed rtol = 0.02
        @test power_hold_measured ≈ fan_power(dp_hold_closed, 0.003) rtol = 0.02
        @test hold_sol(0.0, idxs = hold.hold_force) ≈ 0.0 atol = 0.1
    end

    @testset "full-suction launch" begin
        rwd_sol, rwd = roadster_launch(fan_cmd = 1.0)
        awd_sol, awd = roadster_launch(fan_cmd = 1.0, share = 1.0, h_over_L = 0.0)
        t60_rwd = first_crossing(rwd_sol, rwd.v, ROADSTER_V60)
        t60_awd = first_crossing(awd_sol, awd.v, ROADSTER_V60)
        @test 1.5 <= t60_rwd <= 1.7
        @test 1.5 <= t60_awd <= 1.7

        wheel_radius = 0.35
        torque_limit = 12000.0
        expected_force = torque_limit / wheel_radius
        expected_accel_g = expected_force / (mass * ROADSTER_G)
        @test expected_force ≈ 34.3e3 rtol = 0.01
        @test expected_accel_g ≈ 1.75 rtol = 0.01

        for (sol, model, t60) in ((rwd_sol, rwd, t60_rwd), (awd_sol, awd, t60_awd))
            sample_times = range(0.0, t60, length = 200)
            delivered = [sol(t, idxs = model.motor.tau) for t in sample_times]
            requested = [sol(t, idxs = model.motor.tau_cmd) for t in sample_times]
            speed = [sol(t, idxs = model.motor.w) for t in sample_times]
            power_ceiling = [1.0e6 / max(w, 1.0) for w in speed]
            @test all(isapprox.(delivered, torque_limit; rtol = 1e-8, atol = 1e-6))
            @test minimum(requested .- delivered) > 0
            @test minimum(power_ceiling .- delivered) > 0
        end
    end

    @testset "wheel-torque sweep" begin
        torque_values = 12000.0:2000.0:20000.0
        sweep_times = map(torque_values) do torque
            sol, model = roadster_launch(fan_cmd = 1.0, T_max = torque)
            first_crossing(sol, model.v, ROADSTER_V60)
        end
        @test all(diff(sweep_times) .< 0)
        @test all(isfinite, sweep_times)
    end
end

@testset "Roadster traction control is tolerance-independent" begin
    # Past the adhesion peak the tire curve falls, so a request that ignores slip lets the wheel
    # run away the moment a coarse step lands beyond it. The launch must not depend on step size.
    layouts = (rwd = (;), awd = (share = 1.0, h_over_L = 0.0))
    for (layout, geometry) in pairs(layouts), fan_cmd in (0.0, 1.0)
        tight_sol, model = roadster_launch(; fan_cmd, geometry...)
        t60_tight = first_crossing(tight_sol, model.v, ROADSTER_V60)
        loose_runs = (
            "solver defaults" => solve(remake(tight_sol.prob)),
            "abstol 1e-6, reltol 1e-3" => first(roadster_launch(;
                fan_cmd, geometry..., abstol = 1e-6, reltol = 1e-3)),
            "abstol 1e-4, reltol 1e-2" => first(roadster_launch(;
                fan_cmd, geometry..., abstol = 1e-4, reltol = 1e-2)),
        )
        @testset "$layout, fan_cmd = $fan_cmd, $name" for (name, sol) in loose_runs
            t60 = first_crossing(sol, model.v, ROADSTER_V60)
            @test t60 ≈ t60_tight rtol = 0.01
            @test maximum(sol[model.wheel.kappa]) < 0.1
        end
    end
end

@testset "Roadster cold-gas tank and nozzle plausibility" begin
    p0 = 380e5
    V = 0.6
    T0 = 293.15
    R_air = 287.05
    gamma = 1.4
    c_p = 1005.0
    p_a = 101325.0
    p_close = 2e5
    A_t = 1.286e-3

    adiabatic_result = VehicleSystemsComponents.Roadster.ColdGasThrustStandTransient(n = 1.4)
    adiabatic_sol = adiabatic_result.sol
    adiabatic = symbolic_container(adiabatic_result)
    isothermal_result = VehicleSystemsComponents.Roadster.ColdGasThrustStandTransient(n = 1.0)
    isothermal_sol = isothermal_result.sol
    isothermal = symbolic_container(isothermal_result)

    m0_closed = p0 * V / (R_air * T0)
    choked_factor = (2 / (gamma + 1)) ^ ((gamma + 1) / (2 * (gamma - 1)))
    mdot0_closed = A_t * p0 * sqrt(gamma / (R_air * T0)) * choked_factor
    ve0_closed = sqrt(2 * c_p * T0 * (1 - (p_a / p0) ^ ((gamma - 1) / gamma)))
    thrust0_closed = mdot0_closed * ve0_closed
    pressure_half_closed = p0 * 0.5 ^ 1.4
    t_lo, t_hi = 0.0, 15.0
    for _ in 1:60
        t_mid = (t_lo + t_hi) / 2
        adiabatic_sol(t_mid, idxs = adiabatic.tank.m_g) > m0_closed / 2 ? (t_lo = t_mid) : (t_hi = t_mid)
    end
    t_half = (t_lo + t_hi) / 2
    pressure_half_measured = adiabatic_sol(t_half, idxs = adiabatic.tank.p)

    function blowdown_quadrature(n; intervals = 200_000)
        mass_fraction_cutoff = (p_close / p0) ^ (1 / n)
        dx = (1 - mass_fraction_cutoff) / intervals
        integral = 0.0
        for i in 0:intervals
            x = mass_fraction_cutoff + i * dx
            temperature = T0 * x ^ (n - 1)
            pressure = p0 * x ^ n
            exhaust_speed = sqrt(2 * c_p * temperature *
                                 (1 - (p_a / pressure) ^ ((gamma - 1) / gamma)))
            integral += (i == 0 || i == intervals ? 0.5 : 1.0) * exhaust_speed
        end
        impulse = m0_closed * dx * integral
        air_used = m0_closed * (1 - mass_fraction_cutoff)
        return impulse, air_used
    end

    function simulated_blowdown(sol, model; samples = 20_001)
        ts = range(0.0, 15.0, length = samples)
        forces = [sol(t, idxs = model.nozzle.F) for t in ts]
        masses = [sol(t, idxs = model.tank.m_g) for t in ts]
        impulse = sum((forces[1:end-1] .+ forces[2:end]) .* diff(ts)) / 2
        return impulse, masses[1] - masses[end]
    end

    impulse_adiabatic_closed, air_adiabatic_closed = blowdown_quadrature(1.4)
    impulse_isothermal_closed, air_isothermal_closed = blowdown_quadrature(1.0)
    impulse_adiabatic, air_adiabatic = simulated_blowdown(adiabatic_sol, adiabatic)
    impulse_isothermal, air_isothermal = simulated_blowdown(isothermal_sol, isothermal)

    m0_measured = adiabatic_sol(0.0, idxs = adiabatic.tank.m_g)
    mdot0_measured = adiabatic_sol(0.0, idxs = adiabatic.nozzle.mdot)
    ve0_measured = adiabatic_sol(0.0, idxs = adiabatic.nozzle.v_e)
    thrust0_measured = adiabatic_sol(0.0, idxs = adiabatic.nozzle.F)

    @test m0_measured ≈ m0_closed rtol = 0.005
    @test thrust0_measured ≈ thrust0_closed rtol = 0.01
    @test mdot0_measured ≈ mdot0_closed rtol = 0.01
    @test ve0_measured ≈ ve0_closed rtol = 0.01
    @test pressure_half_closed ≈ 0.379 * p0 rtol = 0.01
    @test pressure_half_measured ≈ pressure_half_closed rtol = 0.01
    @test impulse_adiabatic ≈ impulse_adiabatic_closed rtol = 0.02
    @test air_adiabatic ≈ air_adiabatic_closed rtol = 0.02
    @test impulse_adiabatic ≈ 146.6e3 rtol = 0.02
    @test air_adiabatic ≈ 264.8 rtol = 0.02
    @test impulse_isothermal ≈ impulse_isothermal_closed rtol = 0.02
    @test air_isothermal ≈ air_isothermal_closed rtol = 0.02
    @test impulse_isothermal > impulse_adiabatic
end


@testset "Roadster thrust launch and vertical flight plausibility" begin
    valve_closed, closed_model = roadster_launch(thrust_cmd = 0.0)
    baseline, baseline_model = roadster_launch()
    @test maximum(abs.(valve_closed[closed_model.v] .-
                       baseline(valve_closed.t, idxs = baseline_model.v))) < 1e-8

    launch_cases = (
        tires_thrust = (; thrust_cmd = 1.0),
        suction_thrust = (; thrust_cmd = 1.0, fan_cmd = 1.0),
        thrust_200_l = (; thrust_cmd = 1.0, fan_cmd = 1.0, tank_volume = 0.2),
    )
    launch_results = map(launch_cases) do config
        sol, model = roadster_launch(; config...)
        t60 = first_crossing(sol, model.v, ROADSTER_V60)
        air = sol(0.0, idxs = model.tank.m_g) - sol(t60, idxs = model.tank.m_g)
        (; t60, air)
    end
    @test 0.5 <= launch_results.suction_thrust.t60 <= 0.6
    @test launch_results.tires_thrust.t60 < 0.81
    @test launch_results.suction_thrust.t60 < 0.59
    @test launch_results.thrust_200_l.t60 > 0.59

    initial_sol, initial_model = roadster_launch(thrust_cmd = 1.0)
    tire_force = ROADSTER_GRIP * ROADSTER_MU * 0.55 * 2000 * ROADSTER_G
    expected_a0 = (tire_force + 80e3) / 2000
    measured_a0 = initial_sol(1e-4, idxs = initial_model.axle.a)
    @test measured_a0 ≈ expected_a0 rtol = 0.02

    fractions = collect(0.0:0.1:1.0)
    expected_best = Dict((:rwd, 0.0) => 0.0, (:rwd, 1.0) => 0.0,
                         (:awd, 0.0) => 0.1, (:awd, 1.0) => 0.0)
    for (layout, geometry) in ((:rwd, (;)), (:awd, (; share = 1.0, h_over_L = 0.0))),
        fan_cmd in (0.0, 1.0)
        times = map(fractions) do down_fraction
            sol, model = roadster_launch(; thrust_cmd = 1.0, fan_cmd, down_fraction,
                                         geometry...)
            first_crossing(sol, model.v, ROADSTER_V60)
        end
        @test fractions[argmin(times)] == expected_best[(layout, fan_cmd)]
    end

    hop_result = VehicleSystemsComponents.Roadster.Hop(t_b = 0.413)
    hop_sol = hop_result.sol
    hop = symbolic_container(hop_result)
    hop_apex = maximum(hop_sol[hop.hop.altitude])
    hop_air = hop_sol(0.0, idxs = hop.hop.tank.m_g) -
              hop_sol(0.413, idxs = hop.hop.tank.m_g)
    @test hop_apex ≈ 8.0 atol = 0.15
    @test 40 <= hop_air <= 70

    # Initial hover flow is thrust divided by exhaust speed; this anchors the 3--8 s estimate.
    hover_result = VehicleSystemsComponents.Roadster.Hover()
    hover_sol = hover_result.sol
    hover = symbolic_container(hover_result)
    hover_flow_closed = 2000 * ROADSTER_G / hover_sol(0.0, idxs = hover.hover.nozzle.v_e)
    @test hover_flow_closed ≈ 28.3 rtol = 0.02
end
