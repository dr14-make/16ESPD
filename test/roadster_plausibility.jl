using DyadInterface: symbolic_container

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
