using SHA
using DyadInterface: symbolic_container
include("../scripts/p_position_table.jl")
using .PPositionTable

@testset "Belt power directions" begin
    V = VehicleSystemsComponents.Vehicle
    for demand in (40.0, -40.0)
        bench = V.TestBeltDrive(; name = :bench, demand)
        run = V.BeltDriveTransient(model = bench)
        s, m = run.sol, symbolic_container(run)
        @test string(s.retcode) == "Success"
        expected = demand > 0 ? 4000 * (1 - 0.96) : 4000 * (1 / 0.96 - 1)
        @test last(s[m.belt.P_loss]) ≈ expected atol = 1e-6
        @test maximum(abs.(s[m.belt.w_a] .- 2.5 .* s[m.belt.w_b])) < 1e-8
        @test minimum(s[m.belt.P_loss]) >= 0
    end
end


@testset "Lecture 5 position table" begin
    rows = PPositionTable.read_table()
    @test getproperty.(rows, :position) == ["P0", "P2", "P3", "P4"]
    for row in rows
        @test row.definitions_sha256 == PPositionTable.definitions_hash(row.position)
        @test row.P_rated_kW == 30.0
        @test abs(row.SoC_end - row.SoC_start) <= 0.02
        @test row.max_speed_error_kmh <= 1.6
        @test row.fuel_raw_L100 > 0
        @test row.energy_MJ100 ≈ row.fuel_corr_L100 * 0.745 * 43.4
        @test row.saving_H0_pct ≈ 100 * (1 - row.fuel_corr_L100 / PPositionTable.H0)
        @test row.saving_line_pct ≈ 100 * (1 - row.fuel_corr_L100 / PPositionTable.LINE)
    end
    p0, p2, p3, p4 = rows
    savings = [r.saving_H0_pct for r in (p2, p3, p4)]
    gap = minimum(savings) - p0.saving_H0_pct
    @test gap >= 5.0
    @test maximum(savings) - minimum(savings) <= gap / 2
    @test p0.E_regen_MJ < p2.E_regen_MJ
    @test p2.E_regen_MJ < min(p3.E_regen_MJ, p4.E_regen_MJ)
    @test p3.electric_drive_s > 0
    @test p4.electric_drive_s > 0
    @test p2.fuel_corr_L100 ≈ 4.086344 atol = 1e-5 rtol = 0

    @testset "P4 live run matches pin" begin
        run = VehicleSystemsComponents.Lecture5.P4HybridWLTCTransient()
        live = PPositionTable.metrics(run, "P4")
        for column in (:fuel_raw_L100, :fuel_corr_L100, :energy_MJ100,
                :E_regen_MJ, :SoC_start, :SoC_end, :max_speed_error_kmh)
            @test getproperty(live, column) ≈ getproperty(p4, column) rtol = 1e-5 atol = 1e-7
        end
        @test live.starts == p4.starts
        @test live.electric_drive_s ≈ p4.electric_drive_s atol = 0.1
    end
end
