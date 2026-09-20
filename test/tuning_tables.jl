# The tables themselves live next to the notebook that applies them, so notebook 08 and this
# suite run the same transcription. Every expected value below was computed by hand from
# materials/ControlTheory/tuning_methods.pdf, so a mis-copied coefficient fails here rather
# than silently in front of a lecture hall.

include("../notebooks/lecture01/tuning_tables.jl")
using Test
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
