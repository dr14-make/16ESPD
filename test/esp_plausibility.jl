using DyadInterface: symbolic_container

using ModelingToolkit: ODEProblem
using DyadInterface: simplify_model
using OrdinaryDiffEqDefault: Rodas5P, solve

function ackermann_case(; delta_in = 0.1, ackermann = 1.0, tau_load = 0.0)
    model = VehicleSystemsComponents.Vehicle.Planar.TestAckermannSteering(
        name = :model, delta_in = delta_in, ackermann = ackermann, tau_load = tau_load)
    simplified = simplify_model(model)
    problem = ODEProblem(simplified, [], (0.0, 1.0))
    return solve(problem, Rodas5P(); dtmax = 0.005), model
end

function planar_open_loop_case(; stop = 5.0, kwargs...)
    result = VehicleSystemsComponents.Lecture3.PlanarOpenLoopTransient(; stop, kwargs...)
    return result.sol, symbolic_container(result)
end


function sine_with_dwell_case(; A_sw, stop = 6.0, kwargs...)
    result = VehicleSystemsComponents.Lecture3.SineWithDwellRunTransient(; A_sw, stop, kwargs...)
    return result.sol, symbolic_container(result)
end

@testset "FMVSS 126 metric helper" begin
    t = collect(0.0:0.01:5.0)
    swa = [ti < 1.0 ? 0.0 : min(0.2 * (ti - 1.0), 0.5) for ti in t]
    r = [ti <= 2.0 ? exp(2.0 * (ti - 2.0)) : exp(-log(2.0) * (ti - 2.0)) for ti in t]
    y = 2.0 .* t
    metrics = VehicleSystemsComponents.Vehicle.Planar.fmvss126_metrics(
        t, swa, r, y; A = 0.1)
    expected_bos = 1.0 + deg2rad(5.0) / 0.2
    @test metrics.t_bos ≈ expected_bos atol = 1e-12
    @test metrics.t_cos ≈ 2.9285714285714284 atol = 1e-12
    @test metrics.r_peak ≈ 1.0 atol = 1e-12
    @test metrics.yrr_1_00 ≈ exp(-log(2.0) * (metrics.t_cos + 1.0 - 2.0)) atol = 1e-5
    @test metrics.yrr_1_75 ≈ exp(-log(2.0) * (metrics.t_cos + 1.75 - 2.0)) atol = 1e-5
    @test metrics.y_bos_1_07 ≈ 2.0 * (expected_bos + 1.07) atol = 1e-12
    @test metrics.passes_stability
    @test metrics.passes_responsiveness
end

@testset "Passive sine-with-dwell plausibility" begin
    expected = Dict(
        32.0 => (0.00, 0.00, 1.15),
        76.0 => (0.00, 0.00, 2.53),
        97.0 => (1.37, 1.37, 3.08),
        141.0 => (1.01, 1.01, 3.69),
        180.0 => (0.93, 0.93, 3.73),
        220.0 => (0.85, 0.85, 3.63),
        270.0 => (0.00, 0.00, 3.45),
    )
    measurements = map(sort(collect(keys(expected)))) do amplitude
        sol, model = sine_with_dwell_case(A_sw = deg2rad(amplitude))
        metrics = VehicleSystemsComponents.Vehicle.Planar.fmvss126_metrics(
            sol.t, sol[model.sensors.delta_sw], sol[model.sensors.r], sol[model.sensors.y];
            A = deg2rad(21.63))
        beta_max = maximum(abs, sol[model.sensors.beta])
        target = expected[amplitude]
        @test metrics.yrr_1_00 ≈ target[1] atol = 0.05
        @test metrics.yrr_1_75 ≈ target[2] atol = 0.05
        @test metrics.y_bos_1_07 ≈ target[3] atol = 0.1
        if amplitude in (32.0, 76.0, 270.0)
            @test metrics.passes_stability
        elseif amplitude in (97.0, 141.0, 180.0)
            @test !metrics.passes_stability
            @test rad2deg(beta_max) > 45.0
        end
        amplitude == 270.0 && @test rad2deg(beta_max) < 10.0
        (; amplitude, metrics.yrr_1_00, metrics.yrr_1_75, metrics.y_bos_1_07,
           beta_max_deg = rad2deg(beta_max), end_speed = sol[model.sensors.vx][end])
    end
    @info "Task 4 passive sine-with-dwell measurements" measurements
end


@testset "Ackermann steering plausibility" begin
    left_sol, left = ackermann_case()
    tight_sol, tight = ackermann_case(delta_in = 0.2)

    left_angle = left_sol(1.0, idxs = left.linkage.delta_left)
    right_angle = left_sol(1.0, idxs = left.linkage.delta_right)
    tight_left = tight_sol(1.0, idxs = tight.linkage.delta_left)
    tight_right = tight_sol(1.0, idxs = tight.linkage.delta_right)

    @test cot(right_angle) - cot(left_angle) ≈ 1.55 / 2.7 atol = 1e-6
    @test (left_angle + right_angle) / 2 ≈ 0.1000816 atol = 1e-6
    @test (tight_left + tight_right) / 2 ≈ 0.2006351 atol = 1e-6
end

@testset "Planar car coast and braking plausibility" begin
    coast_sol, coast = planar_open_loop_case()
    brake_sol, brake = planar_open_loop_case(
        stop = 3.0, T_cmd = 500.0,
        brake_fl = 1.0, brake_fr = 1.0, brake_rl = 1.0, brake_rr = 1.0)
    right_sol, right = planar_open_loop_case(
        stop = 3.0, T_cmd = 500.0, brake_fr = 1.0, brake_rr = 1.0)

    @test maximum(abs.(coast_sol[coast.sensors.r])) < 1e-6
    @test maximum(abs.(brake_sol[brake.sensors.r])) < 1e-6
    @test brake_sol(2.0, idxs = brake.sensors.ax) ≈ -4.185 rtol = 0.01
    @test right_sol[right.sensors.psi][end] < 0.0
end


@testset "Steady-state cornering and low-speed Ackermann plausibility" begin
    L = 2.7
    K_us = 2.0387e-3
    steady_delta = (0.005, 0.010, 0.020, 0.030)
    steady_runs = map(steady_delta) do delta
        sol, model = planar_open_loop_case(stop = 4.0, delta_sw_final = 16.0 * delta)
        r = sol(4.0, idxs = model.sensors.r)
        vx = sol(4.0, idxs = model.sensors.vx)
        beta = sol(4.0, idxs = model.sensors.beta)
        r_formula = vx * delta / (L + K_us * vx^2)
        (; delta, r, vx, beta, r_formula,
           relative_error = r / r_formula - 1.0,
           K_fit = (vx * delta / r - L) / vx^2)
    end

    for run in steady_runs
        @test abs(run.relative_error) < 0.02
    end
    @test steady_runs[1].K_fit ≈ K_us rtol = 0.10
    @test steady_runs[2].K_fit ≈ K_us rtol = 0.10
    @test rad2deg(steady_runs[4].beta) ≈ -0.69 atol = 0.05

    ramp_sol, ramp = planar_open_loop_case(
        stop = 8.0, delta_sw_final = deg2rad(13.5) * 7.5,
        t_ramp = 7.5, t_steer = 0.5)
    lateral_acceleration = ramp_sol[ramp.sensors.vx] .* ramp_sol[ramp.sensors.r]
    crossing = findfirst(>=(0.3 * 9.81), lateral_acceleration)
    @test !isnothing(crossing)
    amplitude = ramp_sol[ramp.sensors.delta_sw][crossing]
    @test rad2deg(amplitude) ≈ 21.6 atol = 1.0
    @test maximum(abs.(lateral_acceleration)) <= 1.01 * 9.81

    ack_sol, ack = planar_open_loop_case(
        stop = 4.0, v0 = 3.0, delta_sw_final = 3.2, ackermann = 1.0)
    parallel_sol, parallel = planar_open_loop_case(
        stop = 4.0, v0 = 3.0, delta_sw_final = 3.2, ackermann = 0.0)
    ack_difference = abs(ack_sol(4.0, idxs = ack.sensors.alpha_fl) -
                         ack_sol(4.0, idxs = ack.sensors.alpha_fr))
    parallel_difference = abs(parallel_sol(4.0, idxs = parallel.sensors.alpha_fl) -
                              parallel_sol(4.0, idxs = parallel.sensors.alpha_fr))
    ack_speed = ack_sol(4.0, idxs = ack.sensors.vx)
    parallel_speed = parallel_sol(4.0, idxs = parallel.sensors.vx)

    @test ack_difference < 0.002
    @test parallel_difference > 0.018
    @test ack_speed - parallel_speed >= 0.02

    @info "Task 3 cornering measurements" steady_runs amplitude_deg = rad2deg(amplitude) max_lateral_g = maximum(abs.(lateral_acceleration)) / 9.81 ack_alpha_fl = ack_sol(4.0, idxs = ack.sensors.alpha_fl) ack_alpha_fr = ack_sol(4.0, idxs = ack.sensors.alpha_fr) ack_difference ack_speed parallel_alpha_fl = parallel_sol(4.0, idxs = parallel.sensors.alpha_fl) parallel_alpha_fr = parallel_sol(4.0, idxs = parallel.sensors.alpha_fr) parallel_difference parallel_speed
end



function planar_wheel_case(; kwargs...)
    result = VehicleSystemsComponents.Vehicle.Planar.PlanarWheelRigTransient(; kwargs...)
    return result.sol, symbolic_container(result)
end

@testset "Planar wheel plausibility" begin
    peak_sol, peak = planar_wheel_case(vy = 2.4)
    locked_sol, locked = planar_wheel_case(vy = 2.4, tau = 10000.0)
    corner_sol, corner = planar_wheel_case(vy = 1.2, tau = 1000.0)

    locked_lateral_ratio = abs(locked_sol[locked.wheel.F_y][end] / peak_sol[peak.wheel.F_y][end])
    friction_circle_ratio = hypot(corner_sol[corner.wheel.F_x][end],
                                  corner_sol[corner.wheel.F_y][end]) / 4000.0

    @test locked_lateral_ratio ≈ 381.3 / 3999.8 atol = 0.001
    @test friction_circle_ratio ≈ 3974.0 / 4000.0 atol = 0.001
    @test friction_circle_ratio <= 1.0
end
