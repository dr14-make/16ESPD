using ModelingToolkit, OpenCRG, Random
import DataInterpolationsND, ForwardDiff
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
        # Beyond the grid and its blend the road takes the default grip.
        @test road(-100.0, 0.0) == 1.0
        @test road(100.0, 100.0) == 1.0
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
        base = VehicleSystemsComponents.road_grip(ROAD_ASSETS * "ice_patch_mu.crg")
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
            write(bad, replace(uniform, r"D:long section at v = [^,]*,m" =>
                "D:reference line " * channel * ",rad"; count = 1))
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

"""
Evaluate a fitted road's coefficients with DataInterpolationsND, independently of its own
evaluator, on the file's grid; NaN beyond it.
"""
function reference_surface(road)
    D = DataInterpolationsND
    dimension(breaks) = D.BSplineInterpolationDimension(breaks, 2;
        extrapolation = D.ExtrapolationType.Constant)
    du, dv = dimension(road.u_breaks), dimension(road.v_breaks)
    surface = D.NDInterpolation(road.coefficients, (du, dv))
    curved = !isempty(road.center)
    center = D.NDInterpolation(curved ? road.center : zeros(length(road.u_breaks) + 1), (du,))
    heading = D.NDInterpolation(curved ? road.heading : zeros(length(road.u_breaks) + 1), (du,))
    return (x, y) -> begin
        u = road.c * (x - road.x0) + road.s * (y - road.y0) + road.u0
        v = -road.s * (x - road.x0) + road.c * (y - road.y0)
        v = curved ? cos(heading(u)) * (v - center(u)) : v
        on_grid = road.u_breaks[1] <= u <= road.u_breaks[end] &&
            road.v_breaks[1] <= v <= road.v_breaks[end]
        on_grid ? surface(u, v) : NaN
    end
end

lookup_allocations(f, args...) = (f(args...); @allocated f(args...))

@testset "Lookup: reference spline on the grid, no allocation" begin
    V = VehicleSystemsComponents
    rng = Xoshiro(1)
    files = vcat([ROAD_ASSETS * f for f in ("hill_z.crg", "ramp_hold_z.crg", "ice_patch_mu.crg")],
        [joinpath(@__DIR__, "data", "opencrg", f) for f in ("handmade_straight.crg", "handmade_curved.crg")])
    for file in files
        road = V.road_surface(file; elevation = true, fill_missing = 0.0)
        reference = reference_surface(road)
        box = V.road_extent(file; margin = 20.0)
        points = [(box.x[1] + (box.x[2] - box.x[1]) * rand(rng), box.y[1] + (box.y[2] - box.y[1]) * rand(rng))
                  for _ in 1:2000]
        filter!(p -> !isnan(reference(p...)), points)
        # Values on the first and last along-road nodes, where the blend starts. The reference's
        # slope there depends on which side its interval search lands, so slopes are compared
        # inside only; the blend testset checks the edges.
        edges = filter(p -> !isnan(reference(p...)), vec([
            (road.x0 + road.c * u - road.s * v, road.y0 + road.s * u + road.c * v)
            for u in road.u_breaks[[1, end]] .- road.u0,
                v in range(road.v_breaks[1], road.v_breaks[end]; length = 5)]))
        scale = max(1.0, maximum(abs(reference(p...)) for p in vcat(points, edges)))
        gradient(f, x, y) = ForwardDiff.gradient(q -> f(q[1], q[2]), [x, y])
        value_error = maximum(abs(road(p...) - reference(p...)) for p in vcat(points, edges))
        slope_error = maximum(maximum(abs, gradient(road, p...) .- gradient(reference, p...)) for p in points)
        @info "Road lookup against DataInterpolationsND" file = basename(file) value_error slope_error
        @test value_error < 1e-12 * scale
        @test slope_error < 1e-12 * scale
    end
    grip, slope = V.road_grip(ROAD_ASSETS * "ice_patch_mu.crg"), V.road_height(ROAD_ASSETS * "hill_z.crg")
    # Beyond the blend the road is flat at its default height, so the grade is exactly zero.
    @test slope(1.0e4, 0.0, 0.0) == 0.0
    dual = ForwardDiff.Dual{typeof(ForwardDiff.Tag(sin, Float64))}(470.3, 1.0)
    for y in (0.1, 1.9, 5.0)
        @test lookup_allocations(grip, 470.3, y) == 0
        @test lookup_allocations(grip, dual, y) == 0
        @test lookup_allocations(slope, 470.3, y, 0.2) == 0
        @test lookup_allocations(slope, dual, y, 0.2) == 0
    end
end

@testset "Beyond the grid: C1 blend to the default value" begin
    V = VehicleSystemsComponents
    ice = V.road_grip(ROAD_ASSETS * "ice_patch_mu.crg")
    # The patch grid is 2 m wide; beside it the grip returns to the uniform 1.0.
    @test ice(475.0, 0.0) < 0.31
    @test ice(475.0, 1.0) ≈ ice(475.0, 0.0)
    @test 0.31 < ice(475.0, 2.0) < 1.0
    @test ice(475.0, 3.0) == ice(475.0, -3.0) == ice(475.0, 50.0) == 1.0
    @test ice(600.0, 0.0) == ice(300.0, 0.0) == 1.0
    custom = V.road_grip(ROAD_ASSETS * "ice_patch_mu.crg"; default_grip = 0.5, blend_width = 4.0)
    @test custom(475.0, 5.0) == 0.5
    @test custom(475.0, 0.0) == ice(475.0, 0.0)
    @test_throws "blend width" V.road_grip(ROAD_ASSETS * "ice_patch_mu.crg"; blend_width = 0.0)
    ramp = V.road_surface(ROAD_ASSETS * "ramp_z.crg"; elevation = true)
    @test ramp(510.0, 0.0) == ramp(250.0, 5.0) == 0.0
    @test ramp(500.0, 0.0) ≈ 10.0
    gradient(f, x, y) = ForwardDiff.gradient(q -> f(q[1], q[2]), [x, y])
    for road in (ice, ramp, V.road_surface(ROAD_ASSETS * "hill_z.crg"; elevation = true))
        # Value and gradient agree on both sides of the grid edge and of the blend's far end.
        u_edges = (road.u_breaks[1], road.u_breaks[end])
        v_edges = (road.v_breaks[1], road.v_breaks[end])
        across = [(u, 0.5 * sum(v_edges)) for u in (u_edges..., u_edges[1] - 2.0, u_edges[2] + 2.0)]
        append!(across, [(0.5 * sum(u_edges), v) for v in (v_edges..., v_edges[1] - 2.0, v_edges[2] + 2.0)])
        world(u, v) = (road.x0 + road.c * (u - road.u0) - road.s * v,
                       road.y0 + road.s * (u - road.u0) + road.c * v)
        h = 1e-7
        for (u, v) in across, (du, dv) in ((1.0, 0.0), (0.0, 1.0))
            inner, outer = world(u - h * du, v - h * dv), world(u + h * du, v + h * dv)
            @test road(inner...) ≈ road(outer...) atol = 1e-5
            @test gradient(road, inner...) ≈ gradient(road, outer...) atol = 1e-4
        end
        # ForwardDiff agrees with a central difference inside the blend band.
        for (u, v) in ((u_edges[2] + 0.7, 0.5 * sum(v_edges)), (0.5 * sum(u_edges), v_edges[1] - 1.3))
            x, y = world(u, v)
            e = 1e-6
            fd = [(road(x + e, y) - road(x - e, y)) / 2e, (road(x, y + e) - road(x, y - e)) / 2e]
            @test gradient(road, x, y) ≈ fd atol = 1e-6
        end
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

@testset "Road mesh: what is drawn is what the car feels" begin
    V = VehicleSystemsComponents
    extent = V.road_extent(ROAD_ASSETS * "ice_patch_mu.crg"; margin = 5.0)
    @test all(extent.x .≈ (415.0, 535.0))
    @test all(extent.y .≈ (-6.0, 6.0))
    hill, ice = ROAD_ASSETS * "hill_z.crg", ROAD_ASSETS * "ice_patch_mu.crg"
    x, y = 430.0:2.5:520.0, -3.0:0.5:3.0
    mesh = V.road_mesh(hill; grip_file = ice, x, y)
    nx, ny = length(x), length(y)
    @test mesh.x == collect(x) && mesh.y == collect(y)
    @test size(mesh.height) == size(mesh.grip) == (nx, ny)
    @test length(mesh.vertices) == nx * ny
    @test length(mesh.faces) == 2 * (nx - 1) * (ny - 1)
    @test all(f -> all(in(1:nx*ny), f), mesh.faces)
    @test all(mesh.vertices[i + (j - 1) * nx] == (x[i], y[j], mesh.height[i, j])
              for i in 1:nx, j in 1:ny)
    # Counter-clockwise seen from +z: the z-up frame, not a mirrored one.
    @test all(mesh.faces) do (a, b, c)
        p, q, r = mesh.vertices[a], mesh.vertices[b], mesh.vertices[c]
        (q[1] - p[1]) * (r[2] - p[2]) - (q[2] - p[2]) * (r[1] - p[1]) > 0
    end
    grip = V.road_grip(ice)
    height = V.road_surface(hill; elevation = true)
    for (i, j) in ((1, 1), (11, 7), (20, 3), (nx, ny))
        @test mesh.grip[i, j] == grip(x[i], y[j])
        @test mesh.height[i, j] == height(x[i], y[j])
    end
    @test minimum(mesh.grip) < 0.3 && maximum(mesh.grip) ≈ 1.0
    flat = V.road_mesh(ROAD_ASSETS * "flat_z.crg"; x = -50.0:10.0:50.0, y = -5.0:5.0:5.0)
    @test all(iszero, flat.height)
    @test all(==(1.0), flat.grip)
    # Without a height file the road is flat and the sampling box is the grip file's alone.
    grip_only = V.road_mesh(nothing; grip_file = ice)
    @test all(iszero, grip_only.height)
    @test all(extrema(grip_only.x) .≈ V.road_extent(ice).x)
    @test all(extrema(grip_only.y) .≈ V.road_extent(ice).y)
    @test V.road_extent(V.road_surface(ice)) == V.road_extent(ice)
    @test_throws ArgumentError V.road_mesh(nothing)
    default_axes = V.road_mesh(ROAD_ASSETS * "hill_across_z.crg")
    @test length(default_axes.vertices) <= 170_000
    @test first(default_axes.x) < -600 && last(default_axes.y) > 140
end

@testset "Library remains headless" begin
    @test !any(p -> p.name in ("GLMakie", "SimpleDirectMediaLayer"), keys(Base.loaded_modules))
end
