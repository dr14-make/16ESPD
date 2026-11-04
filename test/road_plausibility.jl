using ModelingToolkit, OpenCRG
using DyadInterface: symbolic_container, run_analysis, TransientAnalysisSpec, OptimizationLevel

"Run a road acceptance maneuver without realtime parameter overrides or a window."
road_run(model; stop = 22.0) = run_analysis(TransientAnalysisSpec(name = :road_acceptance,
    model = model, stop = stop, dtmax = 0.005, progress = false, optimize = OptimizationLevel.None()))

const HARD_STOP_TABLE = "dyad://VehicleSystemsComponents/drivers/hard_stop.csv"
const ROAD_ASSETS = "dyad://VehicleSystemsComponents/roads/"

"Build a hard-stop assembly on a position-dependent road."
road_stop(file; esp_on = 0.0) = road_run(VehicleSystemsComponents.PlanarBEVOnRoad(
    name = :mapped, table = HARD_STOP_TABLE, road_file = ROAD_ASSETS * file, esp_on = esp_on))

@testset "Samples: finite nodes and rejected unsupported geometry" begin
    for file in ("handmade_straight.crg", "handmade_straight_double.crg")
        path = joinpath(@__DIR__, "data", "opencrg", file)
        data = read_crg(path)
        road = VehicleSystemsComponents.road_grip(path; fill_missing = 0.0)
        errors = [abs(road(data.refline.start_u + (i-1)*data.refline.increment,
            data.v[j]) - data.z[i,j]) for i in axes(data.z,1), j in axes(data.z,2)
            if isfinite(data.z[i,j])]
        @info "OpenCRG finite nodes" file maximum_error = maximum(errors)
        @test maximum(errors) < 1e-9
        @test road(-100.0, 0.0) == road(0.0, 0.0)
        @test road(100.0, 100.0) == road(22.0, 1.5)
    end
    # This pinned reader does not implement the upstream minimalist file's implicit v origin.
    @test_throws "LONG_SECTION_V_RIGHT" VehicleSystemsComponents.road_grip(
        joinpath(@__DIR__, "data", "opencrg", "handmade_straight_minimalist.crg"))
    curved = joinpath(@__DIR__, "data", "opencrg", "handmade_curved.crg")
    curved_grip = VehicleSystemsComponents.road_grip(curved)
    data = read_crg(curved)
    u, v, X, Y, z = road_surface_grid(data)
    zero = findfirst(==(0.0), v)
    @test zero !== nothing
    reference_error = maximum(abs(curved_grip(X[i,zero], Y[i,zero]) - z[i,zero]) for i in axes(z,1))
    @test reference_error < 1e-9
    errors = [isfinite(z[i,j]) ? abs(curved_grip(X[i,j],Y[i,j])-z[i,j]) : -Inf
              for i in axes(z,1), j in axes(z,2)]
    node = argmax(errors)
    @info "Curved nodes" reference_error maximum_error=errors[node] node world=(X[node],Y[node])
    # The x-indexed approximation measured 0.001690; 0.002 allows an 18% margin.
    @test maximum(errors) < 0.002
    @test_throws r"road filename is empty" VehicleSystemsComponents.road_grip("")
    @test_throws r"absent_mu.crg.*does not exist" VehicleSystemsComponents.road_grip("absent_mu.crg")
    @test_throws r"handmade_straight.crg.*NaN" VehicleSystemsComponents.road_grip(
        joinpath(@__DIR__, "data", "opencrg", "handmade_straight.crg"))
    mktempdir(get(ENV, "TMPDIR", tempdir())) do dir
        original = read(VehicleSystemsComponents.road_path(ROAD_ASSETS * "ice_patch_mu.crg"), String)
        modified = joinpath(dir, "modified_mu.crg")
        write(modified, replace(original, "\$KD_DEFINITION" =>
            "\$ROAD_CRG_MODS\nREFLINE_OFFSET_X = 10\n\$!\n\$KD_DEFINITION"))
        base = VehicleSystemsComponents.road_grip(VehicleSystemsComponents.road_path(ROAD_ASSETS * "ice_patch_mu.crg"))
        shifted = VehicleSystemsComponents.road_grip(modified)
        @test shifted(480.0, 0.0) ≈ base(470.0, 0.0)
        @test shifted(440.0, 0.5) ≈ base(430.0, 0.5)
        @test shifted(500.0, -0.5) ≈ base(490.0, -0.5)
        @info "OpenCRG modifier" modifier = "REFLINE_OFFSET_X" shift_m = 10.0
        for key in ("Z", "S", "B", "SLOPE", "BANKING")
            bad = joinpath(dir, "start_" * lowercase(key) * ".crg")
            write(bad, replace(original, "\$ROAD_CRG\n" => "\$ROAD_CRG\nREFERENCE_LINE_START_" * key * " = 1\n"))
            @test_throws Regex(basename(bad) * ".*elevation data") VehicleSystemsComponents.road_grip(bad)
        end
        uniform = read(VehicleSystemsComponents.road_path(ROAD_ASSETS * "uniform_mu.crg"), String)
        for channel in ("slope", "banking")
            bad = joinpath(dir, channel * ".crg")
            write(bad, replace(uniform, "D:long section at v = -1.0,m" =>
                "D:reference line " * channel * ",rad"))
            @test_throws Regex(basename(bad) * ".*elevation data") VehicleSystemsComponents.road_grip(bad)
        end
        straight = joinpath(dir, "constant_phi.crg")
        header, _ = split(uniform, "\$\$\$\$"; limit = 2)
        header = replace(header, "#:LDFI" => "#:LDFI\nD:reference line phi,rad")
        write(straight, header * "\$\$\$\$\n" * repeat(join(lpad(v, 20) for v in ("0.0", "1.0", "1.0", "1.0")) * "\n", 3))
        @test VehicleSystemsComponents.road_grip(straight)(1.0, 0.0) ≈ 1.0
        rotated = joinpath(dir, "rotated_mu.crg")
        angle = 0.7
        write(rotated, replace(original,
            "REFERENCE_LINE_START_PHI = 0" => "REFERENCE_LINE_START_PHI = $angle",
            "REFERENCE_LINE_START_X = 420.0" => "REFERENCE_LINE_START_X = $(420*cos(angle))",
            "REFERENCE_LINE_START_Y = 0" => "REFERENCE_LINE_START_Y = $(420*sin(angle))"))
        rotated_grip = VehicleSystemsComponents.road_grip(rotated)
        for (x, y) in ((450.0, 0.2), (470.0, -0.4), (496.0, 0.0))
            @test rotated_grip(cos(angle)*x-sin(angle)*y, sin(angle)*x+cos(angle)*y) ≈ base(x,y) atol=1e-9
        end
        back = joinpath(dir, "turning_back.crg")
        header, _ = split(uniform, "\$\$\$\$"; limit = 2)
        header = replace(header, "#:LDFI" => "#:LDFI\nD:reference line phi,rad")
        write(back, header * "\$\$\$\$\n" * join([join(lpad(value,20) for value in
            (string(phi), "1.0", "1.0", "1.0")) for phi in (0.0, 0.8, 1.8)], '\n') * "\n")
        @test_throws r"turning_back.crg.*reference line turns back" VehicleSystemsComponents.road_grip(back)

    end
end

@testset "One wheel: file only, no road wiring" begin
    result = road_run(VehicleSystemsComponents.Vehicle.Planar.TestRoadWheelRig(
        name = :single, road_file = ROAD_ASSETS * "uniform_low_mu.crg"); stop = 0.5)
    s, sol = symbolic_container(result), result.sol
    @test all(isapprox.(sol[s.wheel.grip], 0.3; atol = 1e-12))
    @test sol(0.5; idxs = s.wheel.frame_a.x) > sol(0.01; idxs = s.wheel.frame_a.x)
    @test sol(0.5; idxs = s.wheel.F_z) ≈ 4000.0
end


for (mu, file) in ((1.0, "uniform_mu.crg"), (0.3, "uniform_low_mu.crg"))
    @testset "Uniform $mu: hard-stop parameter-grip equivalence" begin
        reference = road_run(VehicleSystemsComponents.PlanarBEVScripted(name = :reference,
            table = HARD_STOP_TABLE, mu = mu))
        mapped = road_stop(file; esp_on = 1.0)
        a, b = symbolic_container(reference), symbolic_container(mapped)
        # Clock callbacks save duplicate initial positions; read the actual initial state separately.
        times = 0.001:0.001:22.0
        dv = maximum(abs.(3.6 .* (reference.sol(times; idxs = a.vehicle.motion.vx) .-
            mapped.sol(times; idxs = b.vehicle.motion.vx))))
        dx = maximum(abs.(reference.sol(times; idxs = a.vehicle.car.bus.x) .-
            mapped.sol(times; idxs = b.vehicle.car.bus.x)))
        @info "Uniform road equivalence" mu maximum_speed_difference_kmh = dv maximum_x_difference_m = dx
        @test dv < 1e-3
        @test dx < 1e-3
        @test reference.sol[a.vehicle.motion.vx][1] == mapped.sol[b.vehicle.motion.vx][1] == 0.0
        @test reference.sol[a.vehicle.car.bus.x][1] == mapped.sol[b.vehicle.car.bus.x][1] == 0.0
    end
end

"Wheel ABS release/hold activity, excluding ordinary pressure build and regen-fade tracking."
function road_abs_activity(sol, times, s, wheel)
    channel = getproperty(s.vehicle.ecu.abs.abs, wheel).modulator
    collect(sol(times; idxs = channel.phase)) .< 0.5
end

@testset "Moderate stop: half-g dry braking without ABS" begin
    result = road_run(VehicleSystemsComponents.PlanarBEVScripted(name = :moderate,
        table = "dyad://VehicleSystemsComponents/drivers/moderate_stop.csv", esp_on = 0.0); stop = 26.0)
    s, sol = symbolic_container(result), result.sol
    g = (sol(19.5; idxs = s.vehicle.motion.vx) - sol(21.5; idxs = s.vehicle.motion.vx)) / (2 * 9.81)
    @info "Moderate dry stop" pedal = 0.227 deceleration_g = g
    @test 0.48 < g < 0.52
    for wheel in (:fl, :rl)
        @test !any(road_abs_activity(sol, 19.005:0.005:26.0, s, wheel))
    end
end

@testset "Ice patch: ABS on and off the patch" begin
    result = road_run(VehicleSystemsComponents.PlanarBEVOnRoad(name = :moderate_patch,
        table = "dyad://VehicleSystemsComponents/drivers/moderate_stop.csv",
        road_file = ROAD_ASSETS * "ice_patch_mu.crg", esp_on = 0.0); stop = 26.0)
    s, sol = symbolic_container(result), result.sol
    times = collect(19.005:0.005:26.0)
    for wheel in (:fl, :rl)
        grip = collect(sol(times; idxs = getproperty(s.vehicle.car, wheel).grip))
        x = collect(sol(times; idxs = getproperty(s.vehicle.car, wheel).frame_a.x))
        active = road_abs_activity(sol, times, s, wheel)
        on = grip .< 0.4
        before = x .< 454.0
        dry_return = findfirst((x .> 495.0) .& (abs.(grip .- 1.0) .< 1e-6))
        after = times .>= times[dry_return] + 0.3
        @test any(on) && any(before) && any(after)
        @test any(active[on])
        @test !any(active[before])
        @test !any(active[after])
        @test times[findfirst(x .>= 455.0)] >= 19.5
        last_active = findlast(active)
        dropout = max(0.0, times[last_active] + 0.005 - times[dry_return])
        @info "Ice patch wheel" wheel patch_entry_s = times[findfirst(x .>= 455.0)] patch_exit_s = times[findfirst(x .>= 495.0)] low_grip_times = extrema(times[on]) active_times = extrema(times[active]) dry_return_s = times[dry_return] dropout_s = dropout
    end
end

@testset "One-sided patch: yaw sign agrees with SplitMuStop" begin
    mapped = road_stop("right_patch_mu.crg")
    reference = road_run(VehicleSystemsComponents.Lecture3.SplitMuStop(name = :split,
        load_transfer = false); stop = 6.0)
    s, a = symbolic_container(mapped), symbolic_container(reference)
    times = 19.0:0.01:22.0
    yaw = mapped.sol(times; idxs = s.vehicle.motion.r)
    split_yaw = reference.sol(0.01:0.01:6.0; idxs = a.motion.r)
    peak, split_peak = yaw[argmax(abs.(yaw))], split_yaw[argmax(abs.(split_yaw))]
    heading = mapped.sol(22.0; idxs = s.vehicle.car.bus.psi)
    @info "Split grip yaw" peak_yaw_rad_s = peak heading_change_rad = heading split_mu_peak_rad_s = split_peak
    @test peak > 0.01
    @test sign(peak) == sign(split_peak)
    @test heading > 0.01
    @test mapped.sol(19.5; idxs = s.vehicle.car.fr.grip) < 0.4
    @test mapped.sol(19.5; idxs = s.vehicle.car.fl.grip) > 0.95
    @test mapped.sol(19.5; idxs = s.vehicle.motion.r) > 0.0
end

@testset "Library remains headless" begin
    @test !any(p -> p.name in ("GLMakie", "SimpleDirectMediaLayer"), keys(Base.loaded_modules))
end
