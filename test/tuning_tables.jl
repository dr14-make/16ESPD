# Transcribed from materials/ControlTheory/tuning_methods.pdf ("Standard PID Tuning Methods",
# tbco 2/17/2012). Page and table references in the docstrings and test comments point at that
# document; every expected value below was computed by hand from those tables so that a
# mis-transcribed coefficient fails here rather than silently in notebook 08.

module TuningTables

export cohen_coon, ziegler_nichols, tyreus_luyben

"""
    check_positive(name, x)

All three tables divide by their arguments, so a non-positive or non-finite input yields
`Inf`/`NaN` gains that look like numbers in a plot. Reject them at the boundary instead.
"""
function check_positive(name::AbstractString, x::Real)
    (isfinite(x) && x > 0) ||
        throw(ArgumentError("$name must be a positive finite number, got $x"))
    return x
end

"""
    cohen_coon(K, tau, theta) -> (k, Ti, Td)

Cohen-Coon PID gains for a FOPTD plant with steady-state gain `K`, time constant `tau` and
dead time `theta`. Table 1, p.2, PID row, with `r = theta/tau` (p.1, Step 2; the document
writes the dead time as `tau_del`):

    k  = (1/(r*K)) * (4/3 + r/4)
    Ti = theta * (32 + 6r) / (13 + 8r)
    Td = theta * 4 / (11 + 2r)

`k` is returned in the reciprocal units of `K`: feeding a step test read in km/h per N.m
gives a gain in N.m per km/h, which is the unit the whole lecture's control loop uses.

Cohen-Coon is a dead-time method — `k` grows without bound as `theta` goes to zero, which is
why the plant carries an explicit transport delay.
"""
function cohen_coon(K::Real, tau::Real, theta::Real)
    check_positive("K", K)
    check_positive("tau", tau)
    check_positive("theta", theta)

    r = theta / tau
    k = (1 / (r * K)) * (4 / 3 + r / 4)
    Ti = theta * (32 + 6r) / (13 + 8r)
    Td = theta * 4 / (11 + 2r)
    return (k, Ti, Td)
end

"""
    ziegler_nichols(Ku, Pu) -> (k, Ti, Td)

Ziegler-Nichols PID gains from the ultimate gain `Ku` and ultimate period `Pu` measured at
sustained oscillation under pure proportional control. Table 2, p.2, PID row:

    k = Ku/1.7,  Ti = Pu/2,  Td = Pu/8
"""
function ziegler_nichols(Ku::Real, Pu::Real)
    check_positive("Ku", Ku)
    check_positive("Pu", Pu)
    return (Ku / 1.7, Pu / 2, Pu / 8)
end

"""
    tyreus_luyben(Ku, Pu) -> (k, Ti, Td)

Tyreus-Luyben PID gains from the same `Ku` and `Pu` pair as Ziegler-Nichols. Table 2, p.3,
PID row:

    k = Ku/2.2,  Ti = 2.2*Pu,  Td = Pu/6.3

Deliberately more conservative than Ziegler-Nichols at the same measurement: lower gain and a
much slower integrator.
"""
function tyreus_luyben(Ku::Real, Pu::Real)
    check_positive("Ku", Ku)
    check_positive("Pu", Pu)
    return (Ku / 2.2, 2.2 * Pu, Pu / 6.3)
end

end # module TuningTables

using .TuningTables

@testset "PID tuning tables" begin
    @testset "Cohen-Coon" begin
        # K = 1, tau = 2, theta = 1  ->  r = theta/tau = 1/2
        #   k  = (1/(0.5*1)) * (4/3 + 0.5/4) = 2 * (32/24 + 3/24) = 2 * 35/24 = 35/12
        #   Ti = 1 * (32 + 6*0.5)/(13 + 8*0.5) = 35/17
        #   Td = 1 * 4/(11 + 2*0.5)            = 4/12 = 1/3
        k, Ti, Td = cohen_coon(1.0, 2.0, 1.0)
        @test k ≈ 35 / 12
        @test Ti ≈ 35 / 17
        @test Td ≈ 1 / 3

        # K = 2, tau = 10, theta = 2  ->  r = 1/5
        #   k  = (1/(0.2*2)) * (4/3 + 0.2/4) = 2.5 * (80/60 + 3/60) = 2.5 * 83/60 = 83/24
        #   Ti = 2 * (32 + 1.2)/(13 + 1.6) = 2 * 33.2/14.6 = 332/73
        #   Td = 2 * 4/(11 + 0.4)          = 8/11.4        = 40/57
        k, Ti, Td = cohen_coon(2.0, 10.0, 2.0)
        @test k ≈ 83 / 24
        @test Ti ≈ 332 / 73
        @test Td ≈ 40 / 57

        # k scales as 1/K: the table's only appearance of K is the leading 1/(rK).
        @test cohen_coon(4.0, 10.0, 2.0)[1] ≈ cohen_coon(2.0, 10.0, 2.0)[1] / 2
        @test cohen_coon(4.0, 10.0, 2.0)[2] ≈ cohen_coon(2.0, 10.0, 2.0)[2]

        # More dead time relative to the time constant buys less gain. A swapped numerator and
        # denominator in `r` reverses this.
        gains = [cohen_coon(1.0, 10.0, theta)[1] for theta in (0.5, 1.0, 2.0, 5.0)]
        @test issorted(gains; rev = true)

        # Ti and Td are both proportional to theta at fixed r, so doubling tau and theta
        # together doubles them and leaves k alone.
        k1, Ti1, Td1 = cohen_coon(1.0, 10.0, 2.0)
        k2, Ti2, Td2 = cohen_coon(1.0, 20.0, 4.0)
        @test k2 ≈ k1
        @test Ti2 ≈ 2 * Ti1
        @test Td2 ≈ 2 * Td1
    end

    @testset "Ziegler-Nichols" begin
        # Ku = 34, Pu = 8  ->  k = 34/1.7 = 20, Ti = 8/2 = 4, Td = 8/8 = 1
        @test all(ziegler_nichols(34.0, 8.0) .≈ (20.0, 4.0, 1.0))

        # Ku = 420, Pu = 2.2 (the theta_e = 0.3 s operating point of HANDOVER's Risk 1)
        #   k = 420/1.7 = 4200/17,  Ti = 2.2/2 = 1.1,  Td = 2.2/8 = 0.275
        k, Ti, Td = ziegler_nichols(420.0, 2.2)
        @test k ≈ 4200 / 17
        @test Ti ≈ 1.1
        @test Td ≈ 0.275

        # Ti/Td = 4 for every (Ku, Pu): (Pu/2)/(Pu/8). Catches a swapped Ti and Td column.
        @test ziegler_nichols(100.0, 3.0)[2] / ziegler_nichols(100.0, 3.0)[3] ≈ 4
    end

    @testset "Tyreus-Luyben" begin
        # Ku = 22, Pu = 6.3  ->  k = 22/2.2 = 10, Ti = 2.2*6.3 = 13.86, Td = 6.3/6.3 = 1
        @test all(tyreus_luyben(22.0, 6.3) .≈ (10.0, 13.86, 1.0))

        # Ku = 420, Pu = 2.2  ->  k = 420/2.2 = 2100/11, Ti = 4.84, Td = 2.2/6.3 = 22/63
        k, Ti, Td = tyreus_luyben(420.0, 2.2)
        @test k ≈ 2100 / 11
        @test Ti ≈ 4.84
        @test Td ≈ 22 / 63

        # Ti rises with Pu rather than falling — the one column where Tyreus-Luyben multiplies
        # where Ziegler-Nichols divides.
        @test tyreus_luyben(100.0, 4.0)[2] ≈ 8.8
    end

    @testset "Tyreus-Luyben is the conservative reading of one measurement" begin
        Ku, Pu = 420.0, 2.2
        k_zn, Ti_zn, Td_zn = ziegler_nichols(Ku, Pu)
        k_tl, Ti_tl, Td_tl = tyreus_luyben(Ku, Pu)
        @test k_tl < k_zn
        @test Ti_tl > Ti_zn
        @test Td_tl > Td_zn
    end

    @testset "domain errors" begin
        @test_throws ArgumentError cohen_coon(1.0, 10.0, 0.0)
        @test_throws ArgumentError cohen_coon(0.0, 10.0, 1.0)
        @test_throws ArgumentError cohen_coon(1.0, -10.0, 1.0)
        @test_throws ArgumentError cohen_coon(1.0, Inf, 1.0)
        @test_throws ArgumentError ziegler_nichols(0.0, 2.0)
        @test_throws ArgumentError ziegler_nichols(10.0, 0.0)
        @test_throws ArgumentError tyreus_luyben(-1.0, 2.0)
        @test_throws ArgumentError tyreus_luyben(10.0, NaN)
    end
end
