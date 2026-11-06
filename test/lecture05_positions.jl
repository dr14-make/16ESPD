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
    @test getproperty.(rows, :position) == ["P0", "P1", "P2", "P3", "P4"]
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
    p0, p1, p2, p3, p4 = rows
    @test p0.saving_H0_pct < p1.saving_H0_pct
    @test p2.saving_H0_pct - p1.saving_H0_pct >= 5.0
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
    function values_for(model)
        merge(ModelingToolkit.initial_conditions(model), ModelingToolkit.bindings(model))
    end
    function resolved(model, p)
        d = values_for(model)
        localname = replace(string(p), string(ModelingToolkit.getname(model)) * "₊" => ""; count = 1)
        key = only(filter(k -> string(k) == localname, collect(keys(d))))
        value = d[key]
        for _ in 1:20
            value = ModelingToolkit.Symbolics.substitute(value, d)
        end
        parse(Float64, string(value))
    end
    paths = Tuple[(p,) for p in (:m, :radius, :k, :Ti, :dv_wheel, :engage_rpm,
        :engage_width_rpm, :lock_rpm, :lock_width_rpm, :N_locked)]
    append!(paths, [(:manager, p) for p in (:SoC_on, :SoC_off, :SoC_full,
        :dSoC_full, :P_line_max, :P_on, :P_off, :P_chg, :P_max, :P_regen, :v_fade)])
    append!(paths, [(:driver, :k), (:driver, :Ti), (:car, :m), (:car, :radius),
        (:roadload, :m), (:powertrain, :drive, :SoC0)])
    for path in paths
        parameter(model) = foldl(getproperty, path; init = model)
        @test resolved(reference, parameter(reference)) ≈ resolved(comparison, parameter(comparison))
    end
    @test resolved(reference, reference.tau_brake) == resolved(reference, reference.tau_max)
    @test resolved(comparison, comparison.tau_brake) == resolved(comparison, comparison.tau_max)
end
