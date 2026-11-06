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
    @test p0.E_recovered_MJ < p2.E_recovered_MJ
    @test p2.E_recovered_MJ < min(p3.E_recovered_MJ, p4.E_recovered_MJ)
    @test p3.electric_drive_s > 0
    @test p4.electric_drive_s > 0
    @test p2.fuel_corr_L100 ≈ 4.0863417765 atol = 1e-9 rtol = 0

    @testset "P4 live run matches pin" begin
        run = VehicleSystemsComponents.Lecture5.P4HybridWLTCTransient()
        live = PPositionTable.metrics(run, "P4")
        for column in (:fuel_raw_L100, :fuel_corr_L100, :energy_MJ100,
                :E_regen_MJ, :E_recovered_MJ, :SoC_start, :SoC_end, :max_speed_error_kmh)
            @test getproperty(live, column) ≈ getproperty(p4, column) rtol = 1e-5 atol = 1e-7
        end
        @test live.starts == p4.starts
        @test live.electric_drive_s ≈ p4.electric_drive_s atol = 0.1
    end
end
@testset "Compiled position bench shared defaults" begin
    using ModelingToolkit
    L = VehicleSystemsComponents.Lecture5
    reference = L.P2HybridWLTC(name = :reference)
    comparison = L.OutputHybridWLTC(name = :comparison)
    function shared_defaults(a, b; exclude = Set{Symbol}())
        da, db = ModelingToolkit.defaults(a), ModelingToolkit.defaults(b)
        pa = Dict(Symbol(ModelingToolkit.getname(p)) => p for p in ModelingToolkit.parameters(a))
        pb = Dict(Symbol(ModelingToolkit.getname(p)) => p for p in ModelingToolkit.parameters(b))
        for name in intersect(keys(pa), keys(pb))
            name in exclude && continue
            va, vb = da[pa[name]], db[pb[name]]
            for _ in 1:20
                va = ModelingToolkit.Symbolics.substitute(va, da)
                vb = ModelingToolkit.Symbolics.substitute(vb, db)
            end
            @test isequal(va, vb)
        end
    end
    shared_defaults(reference, comparison; exclude = Set([:tau_max, :tau_brake]))
    for field in (:driver, :manager, :car, :roadload, :meter, :line, :demand_line)
        shared_defaults(getproperty(reference, field), getproperty(comparison, field);
            exclude = field == :driver ? Set([:y_max, :y_min]) : Set{Symbol}())
    end
    shared_defaults(reference.powertrain.drive, comparison.powertrain.drive; exclude = Set([:ratio]))
    @test ModelingToolkit.defaults(reference.powertrain.drive)[reference.powertrain.drive.SoC0] == 0.6
end
