# Lecture 3 FullCarVacuumStop: the vacuum booster fed by the mapped engine's manifold, through a
# lift-off stop from the 90 km/h cruise.
#
# Alone: julia +dyad-3.4.0 --project=. -e 'using Test, VehicleSystemsComponents;
#     include("test/vacuum_full_car.jl")'

using Test
using VehicleSystemsComponents
using DyadInterface: symbolic_container

@testset "Lecture 3 FullCarVacuumStop" begin
    run = VehicleSystemsComponents.Lecture3.FullCarVacuumStopTransient()
    m = symbolic_container(run)
    sol = run.sol
    t, v = sol.t, sol[m.body.mass.v]
    @test string(sol.retcode) == "Success"

    d = VehicleSystemsComponents.Vehicle.braking_distance(run)
    @test d ≈ 39.18 atol = 0.05
    @test abs(v[end]) < 0.01

    i_stop = findfirst(k -> t[k] >= 0.5 && v[k] < 0.5, eachindex(t))
    # The rear chamber needs about 0.1 s to fill past the return-spring preload.
    stopping = findall(k -> 0.6 <= t[k] <= t[i_stop], eachindex(t))
    assist = sol[m.booster.F_out] .- sol[m.booster.F_in]
    @test minimum(assist[stopping]) > 0
    @test minimum(assist[stopping[t[stopping] .>= 1.0]]) > 2e3

    p_m = sol[m.engine.p_m]
    @test maximum(p_m) < 101325.0
    @test maximum(p_m[stopping]) < 35e3
end
