using DyadInterface: symbolic_container

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
