# Lecture 4 efficiency map: the combined (machine + converter) efficiency of build steps 1–2,
# swept on the dyno bench exactly as notebook 01 sweeps it, against the lecture plan's three
# bands from ORNL's measured map of the 2012 Leaf. The ORNL motor is the 80 kW / 280 N·m
# first-generation machine, so the bands check shape and level, not a fit.

using DyadInterface: symbolic_container

include("../notebooks/lecture04/efficiency_map.jl")
using .EfficiencyMap

@testset "Lecture 4 efficiency map: ORNL's bands" begin
    emap = efficiency_map()
    eta(n, T) = eta_at(emap, n, T)

    # Mid speed, mid torque: 94–96 %.
    for (n, T) in [(4000, 100), (5000, 100), (7300, 85)]
        @test 0.94 <= eta(n, T) <= 0.96
    end

    # Near zero torque: 70–80 %. At 5 N·m the model sits at the band's bottom edge; at 3000 rpm,
    # where the 200 W constant loss weighs most against 1.6 kW at the shaft, it is just under.
    for n in (5000, 7000, 9000)
        @test 0.70 <= eta(n, 5.0) <= 0.80
    end
    @test eta(3000, 5.0) ≈ 0.691 atol = 0.005

    # Low speed, high torque: ORNL measured about 80 %; the model gives 86 %. The machine alone
    # is at 88 %, inside ORNL's motor-only map, while the average converter's losses track only
    # the current and keep it at 97.5 % with 113 V out, where ORNL's inverter falls into the 80s.
    for (n, T) in [(900, 180), (1000, 220)]
        @test eta(n, T) ≈ 0.862 atol = 0.005
        @test_broken 0.78 <= eta(n, T) <= 0.82
    end

    # The swept map agrees with the bench held at one operating point.
    r = VehicleSystemsComponents.Vehicle.Electric.ConverterTransient(rpm_start = 5000.0,
        rpm_end = 5000.0, I_ref = 120.0)
    m = symbolic_container(r)
    tau, P_in = r.sol[m.machine.tau][end], r.sol[m.converter.P_in][end]
    @test eta(5000, tau) ≈ combined_eta(tau * 5000 * pi / 30, P_in) atol = 1e-4

    # Regenerating mid map is as efficient as motoring.
    @test 0.94 <= eta(5000, -100.0) <= 0.96
end
