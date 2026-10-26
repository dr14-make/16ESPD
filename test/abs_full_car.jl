# Lecture 3 FullCarABSStop: the whole car of FullCarVacuumStop with step 03's slip ABS, through a
# lift-off stop from the 90 km/h cruise at the pedal that locks the wheel without ABS.
#
# Alone: julia +dyad-3.4.0 --project=. -e 'using Test, VehicleSystemsComponents;
#     include("test/abs_full_car.jl")'

using Test
using VehicleSystemsComponents
using DyadInterface: symbolic_container
using Statistics: median

@testset "Lecture 3 FullCarABSStop" begin
    L3 = VehicleSystemsComponents.Lecture3
    V = VehicleSystemsComponents.Vehicle
    stop_time(mu) = 0.5 + 1.5 * 25 / (0.7 * mu * 9.81) + 1

    # Held open, the valves leave FullCarVacuumStop's brake chain.
    @test V.braking_distance(L3.FullCarABSStopTransient(pedal = 0.3, abs_on = 0.0)) ≈ 39.18 atol = 0.05

    for (mu, d_abs, d_locked) in ((1.0, 34.82, 45.37), (0.5, 64.67, 86.60), (0.3, 106.80, 138.60))
        on = L3.FullCarABSStopTransient(road_mu = mu, stop = stop_time(mu))
        off = L3.FullCarABSStopTransient(road_mu = mu, abs_on = 0.0, stop = stop_time(mu))
        @test string(on.sol.retcode) == "Success"
        @test string(off.sol.retcode) == "Success"
        d_on, d_off = V.braking_distance(on), V.braking_distance(off)
        @test d_on ≈ d_abs atol = 0.1
        @test d_off ≈ d_locked atol = 0.1
        @test d_on < d_off

        m = symbolic_container(on)
        t, v = on.sol.t, on.sol[m.body.mass.v]
        @test abs(v[end]) < 0.01
        win = (t .>= 1.0) .& (v .> 3.0)
        kappa = on.sol[m.wheel.kappa][win]
        @test abs(median(kappa) + 0.04) < 0.01
        @test all(-0.06 .< kappa .< 0.0)
        @test minimum(on.sol[m.wheel.inertia.w][win]) > 5.0

        mo = symbolic_container(off)
        tf, vf = off.sol.t, off.sol[mo.body.mass.v]
        @test median(off.sol[mo.wheel.kappa][(tf .>= 1.0) .& (vf .> 3.0)]) < -0.9
    end
end
