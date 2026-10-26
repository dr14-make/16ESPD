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

function esp_sine_with_dwell_case(; A_sw, stop = 6.0, kwargs...)
    result = VehicleSystemsComponents.Lecture3.ESPSineWithDwellTransient(; A_sw, stop, kwargs...)
    return result.sol, symbolic_container(result)
end

function esp_steer_ramp_case(; stop = 8.0, kwargs...)
    result = VehicleSystemsComponents.Lecture3.ESPSteerRampTransient(; stop, kwargs...)
    return result.sol, symbolic_container(result)
end

trapezoidal_integral(t, x) = sum((x[1:end-1] .+ x[2:end]) .* diff(t)) / 2

@testset "Continuous ESP plausibility" begin
    amplitudes = (32.0, 76.0, 97.0, 141.0, 180.0, 220.0, 270.0)
    measurements = map(amplitudes) do amplitude
        sol, model = esp_sine_with_dwell_case(A_sw = deg2rad(amplitude))
        metric_times = collect(0.0:0.002:6.0)
        metrics = VehicleSystemsComponents.Vehicle.Planar.fmvss126_metrics(
            metric_times, sol(metric_times; idxs = model.sensors.delta_sw),
            sol(metric_times; idxs = model.sensors.r), sol(metric_times; idxs = model.sensors.y);
            A = deg2rad(21.63))
        beta_max = maximum(abs, sol[model.sensors.beta])
        min_kappa = minimum(vcat(sol[model.sensors.kappa_fl], sol[model.sensors.kappa_fr],
                                  sol[model.sensors.kappa_rl], sol[model.sensors.kappa_rr]))
        @test metrics.passes_stability
        amplitude >= 108.15 && @test metrics.passes_responsiveness
        @test rad2deg(beta_max) < 10.0
        amplitude >= 97.0 && @test 12.0 <= sol[model.sensors.vx][end] <= 16.0
        amplitude >= 97.0 && @test min_kappa < -0.9
        if amplitude == 180.0
            t_start = 1.0 + 0.5 / 0.7
            t_end = 1.0 + 1.0 / 0.7 + 0.5 + 1.5
            t_int = collect(range(t_start, t_end; length = 1001))
            integrals = [trapezoidal_integral(t_int, sol(t_int; idxs = tau)) for tau in
                         (model.car.tau_fl, model.car.tau_fr, model.car.tau_rl, model.car.tau_rr)]
            @test argmax(integrals) == 1
            @info "Task 5 oversteer torque integrals" integrals
        end
        (; amplitude, metrics.yrr_1_00, metrics.yrr_1_75, metrics.y_bos_1_07,
           beta_max_deg = rad2deg(beta_max), end_speed = sol[model.sensors.vx][end], min_kappa)
    end

    for amplitude in amplitudes
        passive_sol, passive = sine_with_dwell_case(
            A_sw = deg2rad(amplitude), reltol = 1e-12, abstol = 1e-14,
            dtmax = 0.001, saveat = 0.001)
        off_sol, off = esp_sine_with_dwell_case(
            A_sw = deg2rad(amplitude), esp_on = 0.0, reltol = 1e-12, abstol = 1e-14,
            dtmax = 0.001, saveat = 0.001)
        metric_times = collect(0.0:0.001:6.0)
        passive_metrics = VehicleSystemsComponents.Vehicle.Planar.fmvss126_metrics(
            metric_times, passive_sol(metric_times; idxs = passive.sensors.delta_sw),
            passive_sol(metric_times; idxs = passive.sensors.r),
            passive_sol(metric_times; idxs = passive.sensors.y); A = deg2rad(21.63))
        off_metrics = VehicleSystemsComponents.Vehicle.Planar.fmvss126_metrics(
            metric_times, off_sol(metric_times; idxs = off.sensors.delta_sw),
            off_sol(metric_times; idxs = off.sensors.r),
            off_sol(metric_times; idxs = off.sensors.y); A = deg2rad(21.63))
        @test off_metrics.yrr_1_00 ≈ passive_metrics.yrr_1_00 atol = 1e-6
        @test off_metrics.yrr_1_75 ≈ passive_metrics.yrr_1_75 atol = 1e-6
        @test off_metrics.y_bos_1_07 ≈ passive_metrics.y_bos_1_07 atol = 1e-6
    end

    ramp_on_sol, ramp_on = esp_steer_ramp_case()
    ramp_off_sol, ramp_off = esp_steer_ramp_case(esp_on = 0.0)
    t_int = collect(range(0.0, 8.0; length = 1601))
    ramp_integrals = [trapezoidal_integral(t_int, ramp_on_sol(t_int; idxs = tau)) for tau in
                      (ramp_on.car.tau_fl, ramp_on.car.tau_fr, ramp_on.car.tau_rl, ramp_on.car.tau_rr)]
    shortfall_on = minimum(ramp_on_sol[ramp_on.sensors.r] .- ramp_on_sol[ramp_on.esp.r_ref])
    shortfall_off = minimum(ramp_off_sol[ramp_off.sensors.r] .- ramp_off_sol[ramp_off.esp.r_ref])
    @test ramp_integrals[3] > 10.0 * maximum(ramp_integrals[[1, 2, 4]])
    @test abs(shortfall_on) <= 0.7 * abs(shortfall_off)
    @info "Task 5 continuous ESP measurements" measurements ramp_integrals shortfall_on shortfall_off
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
    brake_lt_sol, brake_lt = planar_open_loop_case(
        stop = 3.0, T_cmd = 500.0, h_cg = 0.55,
        brake_fl = 1.0, brake_fr = 1.0, brake_rl = 1.0, brake_rr = 1.0)
    right_sol, right = planar_open_loop_case(
        stop = 3.0, T_cmd = 500.0, brake_fr = 1.0, brake_rr = 1.0)

    @test maximum(abs.(coast_sol[coast.sensors.r])) < 1e-6
    @test maximum(abs.(brake_sol[brake.sensors.r])) < 1e-6
    @test brake_sol(2.0, idxs = brake.sensors.ax) ≈ -4.185 rtol = 0.01
    @test brake_lt_sol(2.0, idxs = brake_lt.car.loads.dN_fl) ≈ 640.0 atol = 10.0
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

@testset "Quasi-static load-transfer plausibility" begin
    sol, model = planar_open_loop_case(stop = 4.0, delta_sw_final = 0.48, h_cg = 0.55)
    dN = [sol(t; idxs = load) for t in sol.t, load in
          (model.car.loads.dN_fl, model.car.loads.dN_fr,
           model.car.loads.dN_rl, model.car.loads.dN_rr)]
    Fz = [sol(t; idxs = load) for t in sol.t, load in
          (model.car.fl.F_z, model.car.fr.F_z, model.car.rl.F_z, model.car.rr.F_z)]
    @test maximum(abs, vec(sum(dN; dims = 2))) <= 1e-6
    @test maximum(abs, vec(sum(Fz; dims = 2)) .- 1500.0 * 9.81) <= 1e-6
    @test vec(dN[end, :]) ≈ [-1134.0, 1153.0, -924.0, 905.0] atol = 2.0
    @info "Task 7 steady load-transfer measurements" dN = vec(dN[end, :]) F_z = vec(Fz[end, :])
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


@testset "Four-channel ABS plausibility" begin
    straight_result = VehicleSystemsComponents.Lecture3.ABSStraightStopTransient()
    straight = symbolic_container(straight_result)
    straight_sol = straight_result.sol
    straight_t = collect(range(0.5, 6.0; length = 1101))
    straight_v = straight_sol(straight_t; idxs = straight.sensors.vx)
    stop_index = findfirst(<(0.5), straight_v)
    @test !isnothing(stop_index)
    stop_time = straight_t[stop_index]
    stop_distance = straight_sol(stop_time; idxs = straight.sensors.x) -
                    straight_sol(0.5; idxs = straight.sensors.x)
    moving = straight_v .> 3.0
    straight_min_kappa = minimum(vcat([
        straight_sol(straight_t[moving]; idxs = kappa) for kappa in
        (straight.sensors.kappa_fl, straight.sensors.kappa_fr,
         straight.sensors.kappa_rl, straight.sensors.kappa_rr)]...))
    @test_broken stop_distance <= 32.0
    @test straight_min_kappa >= -0.2
    @test maximum(abs, straight_sol[straight.sensors.r]) < 1e-8

    amplitudes = (32.0, 97.0, 141.0, 180.0, 270.0)
    abs_measurements = map(amplitudes) do amplitude
        result = VehicleSystemsComponents.Lecture3.ESPSineWithDwellTransient(
            A_sw = deg2rad(amplitude), abs_on = 1.0, Ki = 1e5)
        model = symbolic_container(result)
        sol = result.sol
        times = collect(0.0:0.002:6.0)
        metrics = VehicleSystemsComponents.Vehicle.Planar.fmvss126_metrics(
            times, sol(times; idxs = model.sensors.delta_sw),
            sol(times; idxs = model.sensors.r), sol(times; idxs = model.sensors.y);
            A = deg2rad(21.63))
        moving_times = times[sol(times; idxs = model.sensors.vx) .> 3.0]
        min_kappa = minimum(vcat([
            sol(moving_times; idxs = kappa) for kappa in
            (model.sensors.kappa_fl, model.sensors.kappa_fr,
             model.sensors.kappa_rl, model.sensors.kappa_rr)]...))
        @test metrics.passes_stability
        amplitude >= 108.15 && @test metrics.y_bos_1_07 >= 1.83
        @test min_kappa >= -0.2
        task5_speed = Dict(32.0 => 21.4071, 97.0 => 14.5723, 141.0 => 13.6283,
                           180.0 => 13.3570, 270.0 => 13.3900)[amplitude]
        amplitude >= 97.0 && @test sol[model.sensors.vx][end] >= task5_speed + 2.0
        (; amplitude, metrics.yrr_1_00, metrics.yrr_1_75, metrics.y_bos_1_07,
           beta_max_deg = rad2deg(maximum(abs, sol[model.sensors.beta])),
           end_speed = sol[model.sensors.vx][end], min_kappa)
    end

    load_transfer_amplitudes = (97.0, 180.0, 270.0)
    load_transfer_measurements = map(load_transfer_amplitudes) do amplitude
        result = VehicleSystemsComponents.Lecture3.ESPSineWithDwellTransient(
            A_sw = deg2rad(amplitude), esp_on = 1.0, abs_on = 1.0,
            Ki = 1e5, h_cg = 0.55)
        model = symbolic_container(result)
        sol = result.sol
        times = collect(0.0:0.002:6.0)
        metrics = VehicleSystemsComponents.Vehicle.Planar.fmvss126_metrics(
            times, sol(times; idxs = model.sensors.delta_sw),
            sol(times; idxs = model.sensors.r), sol(times; idxs = model.sensors.y);
            A = deg2rad(21.63))
        min_kappa = minimum(vcat([
            sol(times; idxs = kappa) for kappa in
            (model.sensors.kappa_fl, model.sensors.kappa_fr,
             model.sensors.kappa_rl, model.sensors.kappa_rr)]...))
        @test metrics.passes_stability
        @test metrics.passes_responsiveness
        @test min_kappa >= -0.2
        (; amplitude, metrics.yrr_1_00, metrics.yrr_1_75, metrics.y_bos_1_07,
           end_speed = sol[model.sensors.vx][end], min_kappa)
    end

    function split_measurement(; select_low, esp_on)
        result = VehicleSystemsComponents.Lecture3.SplitMuStopTransient(
            select_low = select_low, esp_on = esp_on)
        model = symbolic_container(result)
        sol = result.sol
        times = collect(range(0.0, 6.0; length = 1201))
        speeds = sol(times; idxs = model.sensors.vx)
        index = something(findfirst(<(3.0), speeds), length(times))
        t_metric = times[index]
        (; heading_deg = rad2deg(sol(t_metric; idxs = model.sensors.psi)),
           offset = sol(t_metric; idxs = model.sensors.y),
           distance = sol(t_metric; idxs = model.sensors.x),
           end_speed = speeds[end])
    end
    abs_only = split_measurement(select_low = 0.0, esp_on = 0.0)
    select_low = split_measurement(select_low = 1.0, esp_on = 0.0)
    esp_pi = split_measurement(select_low = 1.0, esp_on = 1.0)
    @test abs_only.heading_deg > 15.0
    @test abs(select_low.heading_deg) < abs(abs_only.heading_deg)
    @test abs(esp_pi.heading_deg) < 5.0
    @test esp_pi.distance > select_low.distance
    @info "Task 6 ABS measurements" stop_distance straight_min_kappa abs_measurements load_transfer_measurements abs_only select_low esp_pi
end

@testset "Brake and steer: ABS keeps the car steerable" begin
    function brake_and_steer_case(abs_on)
        result = VehicleSystemsComponents.Lecture3.BrakeAndSteerTransient(abs_on = abs_on)
        model = symbolic_container(result)
        sol = result.sol
        times = collect(0.0:0.002:6.0)
        x = sol(times; idxs = model.sensors.x).u
        y = sol(times; idxs = model.sensors.y).u
        speed = hypot.(sol(times; idxs = model.sensors.vx).u, sol(times; idxs = model.sensors.vy).u)
        moving = (speed .> 3.0) .& (times .> 0.5)
        x_obstacle = sol(0.5; idxs = model.sensors.x) + 25.0
        front_kappa = min.(sol(times; idxs = model.sensors.kappa_fl).u,
                           sol(times; idxs = model.sensors.kappa_fr).u)
        (; y_obstacle = y[findfirst(>=(x_obstacle), x)],
           y_stop = y[something(findfirst(i -> times[i] > 0.5 && speed[i] < 0.05,
                                          eachindex(times)), length(times))],
           kappa_min = minimum(front_kappa[moving]))
    end
    with_abs = brake_and_steer_case(1.0)
    locked = brake_and_steer_case(0.0)
    @test with_abs.y_obstacle >= 5 * abs(locked.y_obstacle)
    @test with_abs.y_stop >= 5 * abs(locked.y_stop)
    @test with_abs.y_obstacle > 2.5
    @test locked.kappa_min < -0.95
    @test with_abs.kappa_min > -0.2
    @info "Brake and steer measurements" with_abs locked
end
