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
        road = VehicleSystemsComponents.road_surface(path)
        errors = [abs(road.surface(data.refline.start_u + (i-1)*data.refline.increment,
            data.v[j]) - data.z[i,j]) for i in axes(data.z,1), j in axes(data.z,2)
            if isfinite(data.z[i,j])]
        @info "OpenCRG finite nodes" file maximum_error = maximum(errors)
        @test maximum(errors) < 1e-9
        @test road.surface(-100.0, 0.0) == road.surface(0.0, 0.0)
        @test road.surface(100.0, 100.0) == road.surface(22.0, 1.5)
    end
    # This pinned reader does not implement the upstream minimalist file's implicit v origin.
    @test_throws "LONG_SECTION_V_RIGHT" VehicleSystemsComponents.road_surface(
        joinpath(@__DIR__, "data", "opencrg", "handmade_straight_minimalist.crg"))
    curved = joinpath(@__DIR__, "data", "opencrg", "handmade_curved.crg")
    @test_throws Regex(basename(curved) * ".*reference line phi") VehicleSystemsComponents.road_surface(curved)
    mktempdir(get(ENV, "TMPDIR", tempdir())) do dir
        original = read(VehicleSystemsComponents.road_path(ROAD_ASSETS * "uniform_mu.crg"), String)
        modified = joinpath(dir, "modified_mu.crg")
        write(modified, replace(original, "\$KD_DEFINITION" => "\$ROAD_CRG_MODS\n\$!\n\$KD_DEFINITION"))
        @test_throws r"modified_mu.crg.*ROAD_CRG_MODS" VehicleSystemsComponents.road_surface(modified)
    end
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

@testset "Ice patch: ABS on and off the patch" begin
    result = road_stop("ice_patch_mu.crg")
    s, sol = symbolic_container(result), result.sol
    times = collect(19.1:0.01:22.0)
    grip = collect(sol(times; idxs = s.road.grip_fl))
    active = collect(sol(times; idxs = s.vehicle.ecu.front_active))
    on = grip .< 0.4
    before = (times .< 19.3) .& (grip .> 0.99)
    after = (times .> 20.5) .& (grip .> 0.99)
    @test any(on) && any(before) && any(after)
    @test any(active[on] .> 0.5)
    p = s.vehicle.ecu.abs.abs.fl.modulator.p
    @test sol(19.5; idxs = p) < sol(19.2; idxs = p) / 2
    @info "Ice patch ABS" patch_x_m = (446,450,462,466) on_times = extrema(times[on]) before_active = maximum(active[before]) after_active = maximum(active[after]) pressure_before = sol(19.2;idxs=p) pressure_on = sol(19.5;idxs=p)
    # Deliberately enforce the issue's literal requirement: today's hard stop also needs ABS on dry.
    @test all(active[before] .< 0.5)
    @test all(active[after] .< 0.5)
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
    @test mapped.sol(19.5; idxs = s.road.grip_fr) < 0.4
    @test mapped.sol(19.5; idxs = s.road.grip_fl) > 0.95
    @test mapped.sol(19.5; idxs = s.vehicle.motion.r) > 0.0
end

@testset "Library remains headless" begin
    @test !any(p -> p.name in ("GLMakie", "SimpleDirectMediaLayer"), keys(Base.loaded_modules))
end
