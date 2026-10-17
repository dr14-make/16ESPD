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
