using ModelingToolkit, OpenCRG, ForwardDiff
using DyadInterface: symbolic_container, run_analysis, TransientAnalysisSpec, OptimizationLevel
using OrdinaryDiffEqDefault: solve, Rodas5P
using SymbolicIndexingInterface: setp
using ModelingToolkit: remake

const HEIGHT_ASSETS = "dyad://VehicleSystemsComponents/roads/"
"Analytic raised-cosine hill derivative, including flat approaches."
hill_slope(x) = 240 <= x <= 400 ? 0.08sin(2pi*(x-240)/160) : 0.0
"Run the coast-down preset with one height file and no window."
hills_run(file) = run_analysis(TransientAnalysisSpec(name = :hills_acceptance,
    model = VehicleSystemsComponents.PlanarBEVOnRoad(name = :mapped,
        height_file = HEIGHT_ASSETS * file), stop = 22.0, dtmax = 0.005,
    progress = false, optimize = OptimizationLevel.None()))

@testset "Height reader: analytic directional slopes" begin
    for (file, axis, phi, offset, analytic, bound) in (
        ("flat_z.crg", 0.0:1.0:2.0, 0.0, 0.0, x -> 0.0, 1e-12),
        # C1 joins to flat approaches have a second-derivative jump: measured 5.554e-4
        # at nodes and 2.301e-4 at midpoints; 6e-4 allows an 8% margin at the join.
        ("hill_z.crg", 220.0:1.0:420.0, 0.0, 0.0, hill_slope, 6e-4),
        ("hill_across_z.crg", 220.0:1.0:420.0, pi/2, -280.0, hill_slope, 6e-4),
        ("ramp_z.crg", 0.0:250.0:500.0, 0.0, 0.0, x -> 0.02, 1e-12),
        ("ramp_hold_z.crg", -250.0:250.0:250.0, 0.0, 0.0, x -> 0.02, 1e-12))
        slope = VehicleSystemsComponents.road_height(HEIGHT_ASSETS * file)
        for psi in (0.0, pi/2, pi, pi/4), between in (false, true)
            points = between ? (axis[1:end-1] .+ step(axis)/2) : axis
            errors = [abs(slope(x*cos(phi), x*sin(phi)+offset, psi) -
                analytic(x)*cos(psi-phi)) for x in points]
            @info "Height reader error" file psi between maximum_error=maximum(errors) bound
            @test maximum(errors) < bound
        end
        @test all(isfinite, ForwardDiff.gradient(q -> slope(q...), [280.1, 0.1, 0.3]))
    end
    @test_throws r"\"\".*empty" VehicleSystemsComponents.road_height("")
    @test_throws r"absent_z.crg.*does not exist" VehicleSystemsComponents.road_height("absent_z.crg")
    nanfile = joinpath(@__DIR__, "data", "opencrg", "handmade_straight.crg")
    @test_throws r"handmade_straight.crg.*height grid contains NaN" VehicleSystemsComponents.road_height(nanfile)
    @test isfinite(VehicleSystemsComponents.road_height(nanfile; fill_missing = 0.0)(1.,0.,0.))
    mktempdir(get(ENV, "TMPDIR", tempdir())) do dir
        source = read(VehicleSystemsComponents.road_path(HEIGHT_ASSETS * "flat_z.crg"), String)
        combined = joinpath(dir, "reference_elevation.crg")
        write(combined, replace(source, "\$ROAD_CRG\n" => "\$ROAD_CRG\nREFERENCE_LINE_START_Z = 3\nREFERENCE_LINE_START_S = 0.02\nREFERENCE_LINE_START_B = 0.03\n"))
        height = VehicleSystemsComponents.road_surface(combined; elevation = true)
        slope = VehicleSystemsComponents.road_height(combined)
        @test height(1.0,0.5) ≈ 3.035 atol=1e-12
        @test slope(1.0,0.5,0.0) ≈ 0.02 atol=1e-12
        @test slope(1.0,0.5,pi/2) ≈ 0.03 atol=1e-12
        alias = joinpath(dir, "alias_z.crg")
        write(alias, replace(source, "\$ROAD_CRG\n" => "\$ROAD_CRG\nREFERENCE_LINE_START_SLOPE = 0.02\n"))
        @test_throws r"alias_z.crg.*unsupported start" VehicleSystemsComponents.road_height(alias)
    end
end

@testset "Curved height: world-coordinate chain rule" begin
    file = joinpath(@__DIR__, "data", "opencrg", "handmade_curved.crg")
    height = VehicleSystemsComponents.road_surface(file; elevation = true)
    slope = VehicleSystemsComponents.road_height(file)
    _, _, X, Y, _ = road_surface_grid(read_crg(file))
    errors = Float64[]
    for i in 3:size(X,1)-2, j in 2:size(X,2)-1, psi in (0., pi/2, pi, pi/4)
        x, y, h = X[i,j], Y[i,j], 1e-5
        finite_difference = (height(x+h*cos(psi), y+h*sin(psi)) -
            height(x-h*cos(psi), y-h*sin(psi)))/(2h)
        push!(errors, abs(slope(x,y,psi)-finite_difference))
    end
    @info "Curved height finite difference" maximum_error=maximum(errors)
    # A 1e-5 m central difference measured 7.3e-12; 1e-7 allows cancellation near knots.
    @test maximum(errors) < 1e-7
    x, y = X[5,2], Y[5,2]
    q = [x,y,0.4]
    gradient = ForwardDiff.gradient(p -> slope(p...), q)
    h = 1e-5
    finite_gradient = [(slope((q .+ h.*(1:3 .== j))...) -
        slope((q .- h.*(1:3 .== j))...))/(2h) for j in 1:3]
    @info "Curved nested AD" maximum_error=maximum(abs.(gradient.-finite_gradient))
    @test maximum(abs.(gradient.-finite_gradient)) < 1e-7
end

@testset "Coasting hill, transverse hill, ramp, and flat" begin
    flat = hills_run("flat_z.crg")
    hill = hills_run("hill_z.crg")
    across = hills_run("hill_across_z.crg")
    a, b, c = symbolic_container(flat), symbolic_container(hill), symbolic_container(across)
    times = collect(0.001:0.01:22.0)
    for result in (flat, hill, across)
        @test string(result.sol.retcode) == "Success"
    end
    grade = hill.sol(times; idxs = b.vehicle.roadload.grade)
    force = hill.sol(times; idxs = b.vehicle.roadload.roadload.gradeforce.f)
    mass = hill.sol.ps[b.vehicle.m]
    gravity = hill.sol.ps[b.vehicle.roadload.g]
    expected = mass * gravity .* sin.(atan.(grade))
    relative_error = maximum(abs.(force.-expected))/maximum(abs.(expected))
    @info "Hill grade force" peak_grade=maximum(abs.(grade)) relative_error
    @test all(isapprox.(force, expected; rtol = 1e-6, atol = 1e-12))
    # Four wheel inertias and one motor reflected through the reduction, with no fitted terms.
    wheel_inertia = sum(hill.sol.ps[getproperty(b.vehicle.car, wheel).J] for wheel in (:fl,:fr,:rl,:rr))
    motor_inertia = hill.sol.ps[b.vehicle.drive.machine.J]
    ratio = hill.sol.ps[b.vehicle.ratio]
    radius = hill.sol.ps[b.vehicle.radius]
    effective_mass = mass + (wheel_inertia + motor_inertia*ratio^2)/radius^2
    factor = mass/effective_mass
    for t in (12.5, 13.0, 14.0, 16.0, 17.0)
        h = 0.01
        acceleration(result, sys) = (result.sol(t+h; idxs=sys.vehicle.motion.vx) -
            result.sol(t-h; idxs=sys.vehicle.motion.vx))/(2h)
        extra = acceleration(hill,b) - acceleration(flat,a)
        g = hill.sol(t; idxs=b.vehicle.roadload.grade)
        prediction = -factor*gravity*sin(atan(g))
        @info "Hill extra acceleration" t effective_mass factor grade=g measured=extra prediction error=abs(extra-prediction)
        # Different speeds change drag; tire slip and actuator dynamics prevent exact rigid rolling.
        # The observed worst discrepancy is 0.017 m/s²; 0.025 leaves margin without fitting mass.
        @test abs(extra-prediction) < 0.025
        @test sign(extra) == -sign(g)
    end
    cross_grade = maximum(abs.(across.sol(times; idxs=c.vehicle.roadload.grade)))
    dv = maximum(abs.(3.6 .* (across.sol(times; idxs=c.vehicle.motion.vx) .-
        flat.sol(times; idxs=a.vehicle.motion.vx))))
    dx = maximum(abs.(across.sol(times; idxs=c.vehicle.car.bus.x) .-
        flat.sol(times; idxs=a.vehicle.car.bus.x)))
    @info "Transverse hill equivalence" cross_grade dv dx
    @test cross_grade < 1e-9
    @test dv < 1e-3
    @test dx < 1e-3
    @test maximum(abs.(flat.sol(times; idxs=a.vehicle.roadload.grade))) < 1e-12
    # Captured on d5083ea before height wiring, with this coast-down preset and solver settings,
    # and a converter that clipped its current hard. The rounded limit takes 0.1 A off full
    # throttle, 0.011 km/h and 0.028 m by the end of the run, so the comparison sharpens it.
    reference = reduce(hcat, [parse.(Float64, split(line)) for line in
        eachline(joinpath(@__DIR__, "data", "hills_flat_reference.tsv"))])
    sharp = remake(flat.sol.prob; p = deepcopy(flat.sol.prob.p))
    setp(a, a.vehicle.drive.converter.delta_i)(sharp, 1e-3)
    sharp_sol = solve(sharp, Rodas5P(); dtmax = 0.005)
    @test string(sharp_sol.retcode) == "Success"
    baseline_dv = maximum(abs.(3.6 .* (sharp_sol(reference[1,:]; idxs=a.vehicle.motion.vx) .- reference[2,:])))
    baseline_dx = maximum(abs.(sharp_sol(reference[1,:]; idxs=a.vehicle.car.bus.x) .- reference[3,:]))
    @info "Pre-height flat equivalence" baseline_dv baseline_dx
    # The runtime callable changes the solver path; separate-process differences exceed 1e-9.
    @test baseline_dv < 1e-3
    @test baseline_dx < 1e-3
    ramp = VehicleSystemsComponents.road_height(HEIGHT_ASSETS * "ramp_z.crg")
    @test maximum(abs(ramp(x,0.,0.)-0.02) for x in 0.:1.:499.) < 1e-12
    ramp_run = hills_run("ramp_z.crg")
    ramp_sys = symbolic_container(ramp_run)
    ramp_grade_error = maximum(abs.(ramp_run.sol(times; idxs=ramp_sys.vehicle.roadload.grade) .- 0.02))
    @info "Slope-channel ramp grade" ramp_grade_error
    @test ramp_grade_error < 1e-12
end

@testset "Brake held at standstill on a 2% grade for 60 s" begin
    held = run_analysis(TransientAnalysisSpec(name = :ramp_hold,
        model = VehicleSystemsComponents.PlanarBEVOnRoad(name = :ramp_hold,
            height_file = HEIGHT_ASSETS * "ramp_hold_z.crg",
            table = "dyad://VehicleSystemsComponents/drivers/brake_hold.csv"),
        stop = 60.0, dtmax = 0.005, progress = false, optimize = OptimizationLevel.None()))
    hs, sol = symbolic_container(held), held.sol
    @test string(sol.retcode) == "Success"
    @test sol.t[end] ≈ 60.0
    @test all(u -> all(isfinite, u), sol.u)
    @test all(==(1.0), sol[hs.driver.brake_signal])
    grade = sol(30.0; idxs = hs.vehicle.roadload.grade)
    vx = sol(30.0:1.0:60.0; idxs = hs.vehicle.motion.vx)
    drift = sol(60.0; idxs = hs.vehicle.car.bus.x)
    @info "Ramp brake hold" grade vx_end = vx[end] drift
    @test grade ≈ 0.02 atol = 1e-9
    # A slip tire holds a grade only by creeping; 294 N of grade force at mu = 1 and the brake's
    # 1 rad/s regularization predict a few mm/s backwards; 1.5 mm/s measured.
    @test all(v -> -0.005 < v <= 0.0, vx)
    @test -0.3 < drift <= 0.0
end

@testset "Height loading remains headless" begin
    @test !any(p -> p.name in ("GLMakie", "SimpleDirectMediaLayer"), keys(Base.loaded_modules))
end
