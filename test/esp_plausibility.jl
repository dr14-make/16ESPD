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
