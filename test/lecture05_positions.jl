using SHA
using DyadInterface: symbolic_container
include("../scripts/p_position_table.jl")
const POSITION_ENGINE_PEAK = Ref{Float64}(NaN)

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


@testset "Generated position dependency closure" begin
    files = PPositionTable.definition_files("P2HybridWLTC")
    names = basename.(files)
    for name in ("P2Variator", "DriveCycle", "PlanarCar", "PlanarRoadLoad",
            "HysteresisLatch", "ToKmPerHour", "TorqueToPedal", "OperatingLine")
        @test name * "_definition.jl" in names
    end
    @test !("BeltDrive_definition.jl" in names)
    @test "BeltDrive_definition.jl" in basename.(PPositionTable.definition_files("CoupledHybridWLTC"))
    @test occursin("BlockComponents.Continuous.LimPID", read(only(filter(
        f -> basename(f) == "P2HybridWLTC_definition.jl", files)), String))
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
    for (row, pin) in zip(rows, (4.8178093394, 4.5113793080, 4.0865140557,
            4.0794804768, 4.0865885501))
        @test row.fuel_corr_L100 ≈ pin atol = 1e-9 rtol = 0
    end

    @testset "P4 live run matches pin" begin
        run = VehicleSystemsComponents.Lecture5.P4HybridWLTCTransient()
        live = PPositionTable.metrics(run, "P4")
        m = symbolic_container(run)
        POSITION_ENGINE_PEAK[] = maximum(run.sol.ps[
            m.powertrain.engine.torque_map.full_load.table.interpolator].obj[].u)
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
    comparisons = (L.OutputHybridWLTC(name = :output),
        L.CoupledHybridWLTC(name = :coupled), L.P1HybridWLTC(name = :p1),
        L.P4HybridWLTC(name = :p4))
    function values_for(model)
        merge(ModelingToolkit.initial_conditions(model), ModelingToolkit.bindings(model))
    end
    function resolved_value(model, p)
        d = values_for(model)
        localname = replace(string(p), string(ModelingToolkit.getname(model)) * "₊" => ""; count = 1)
        key = only(filter(k -> string(k) == localname, collect(keys(d))))
        value = d[key]
        for _ in 1:20
            value = ModelingToolkit.Symbolics.substitute(value, d)
        end
        value
    end
    resolved(model, p) = parse(Float64, string(resolved_value(model, p)))
    # Planning capacity must follow a machine-size override at the plant interface.
    for constructor in (L.CoupledHybridWLTC, L.OutputHybridWLTC, L.P4HybridWLTC)
        nominal = constructor(name = :nominal)
        smaller = constructor(name = :smaller, powertrain = (; drive = (; T_max = 20.0)))
        @test resolved(smaller, smaller.machine_limit.k) < resolved(nominal, nominal.machine_limit.k)
        @test resolved(smaller, smaller.machine_limit.k) / resolved(nominal, nominal.machine_limit.k) ≈
            20.0 / resolved(nominal, nominal.powertrain.drive.T_max)
    end
    paths = Tuple[(p,) for p in (:m, :radius, :k, :Ti, :tau_brake, :dv_wheel,
        :engage_rpm, :engage_width_rpm, :lock_rpm, :lock_width_rpm)]
    push!(paths, (:speed_command, :N_locked))
    append!(paths, [(:manager, p) for p in (:SoC_on, :SoC_off, :SoC_full,
        :dSoC_full, :P_line_max, :P_on, :P_off, :P_chg, :P_max, :P_regen, :v_fade,
        :tau_coupled_on, :tau_coupled_off, :dP_boost, :P_peak, :P_dis,
        :SoC_dis_on, :SoC_dis_off, :T_max, :w_idle, :w_on, :w_off,
        :tau_traction, :dtau, :dSoC_boost, :latch_time)])
    append!(paths, [(:driver, :k), (:driver, :Ti), (:driver, :y_min),
        (:car, :m), (:car, :radius), (:roadload, :m), (:powertrain, :drive, :SoC0)])
    for comparison in comparisons
        @testset "$(ModelingToolkit.getname(comparison)) shared defaults" begin
            for path in paths
                parameter(model) = foldl(getproperty, path; init = model)
                @test resolved(reference, parameter(reference)) ≈ resolved(comparison, parameter(comparison))
            end
        end
    end
    full_load_peak = POSITION_ENGINE_PEAK[]
    @test resolved(reference, reference.tau_max) ≈ 355.233567 atol = 1e-9 rtol = 0
    @test resolved(reference, reference.tau_max) ≈
        full_load_peak + resolved(reference, reference.powertrain.drive.T_max) atol = 1e-9 rtol = 0
    for model in (reference, comparisons...)
        @testset "$(ModelingToolkit.getname(model)) ceilings" begin
            @test resolved(model, model.tau_brake) ≈ 355.233567 atol = 1e-9 rtol = 0
            @test resolved(model, model.driver.y_min) ≈ -355.233567 atol = 1e-9 rtol = 0
            @test resolved(model, model.driver.y_max) ≈ resolved(model, model.tau_max)
            table = model.powertrain.engine.torque_map.full_load.table
            defaults = values_for(table)
            key = only(filter(k -> string(k) == "interpolator", collect(keys(defaults))))
            data = ModelingToolkit.Symbolics.value(defaults[key])
            @test maximum(data.u) ≈ full_load_peak atol = 1e-9 rtol = 0
            if model !== reference
                @test resolved(model, model.tau_engine_peak) ≈ full_load_peak atol = 1e-9 rtol = 0
                machine = resolved(model, model.T_max)
                if model === comparisons[1] || model === comparisons[4]
                    machine *= resolved(model, model.reduction) / resolved(model, model.i_launch)
                else
                    machine *= resolved(model, model.i_crank) * resolved(model, model.eta_crank)
                end
                @test resolved(model, model.tau_max) ≈ full_load_peak + machine atol = 1e-9 rtol = 0
            end
        end
    end
end
