# Optional import-only checks: run explicitly with sim/ instantiated. Never opens a window or pad.
using Test
push!(LOAD_PATH, joinpath(@__DIR__, "..", "sim"))
using VehicleSystemsComponents
using ModelingToolkit
using ModelingToolkit: remake
import DyadInterface
using OrdinaryDiffEqDefault: init, step!, Rodas5P
using GLMakie
@test Base.get_extension(VehicleSystemsComponents, :VehicleSystemsComponentsGLMakieExt) !== nothing
@test Base.get_extension(VehicleSystemsComponents, :VehicleSystemsComponentsPadExt) === nothing
using SimpleDirectMediaLayer

@testset "Optional drive extensions without devices" begin
    win = Base.get_extension(VehicleSystemsComponents, :VehicleSystemsComponentsGLMakieExt)
    @test win !== nothing
    padext = Base.get_extension(VehicleSystemsComponents, :VehicleSystemsComponentsPadExt)
    @test padext !== nothing
    @named model = VehicleSystemsComponents.PlanarBEVByHand()
    setup = DyadInterface.setup_analysis(DyadInterface.TransientAnalysisSpec(;
        model, stop = 4.0, optimize = DyadInterface.OptimizationLevel.None(), progress = false))
    sys = DyadInterface.symbolic_container(setup.prob.f)
    spec = VehicleSystemsComponents.RealtimeDriveSpec(; model, duration = 3.0, window = false)
    integ = init(setup.prob, Rodas5P(); dtmax = 0.005, saveat = spec.frame, save_everystep = false)
    initial = remake(integ.sol.prob; p = deepcopy(integ.p), u0 = copy(integ.u))
    ctx = win.context(integ, sys)
    controls = win.Controls()
    controls.throttle = 1.0
    win.apply!(integ, sys, ctx, controls, 0.0)
    step!(integ, 0.2, true)
    fresh = win.fresh_integrator(initial, spec)
    @test fresh.t == 0.0
    @test fresh.sol(0.0; idxs = sys.driver.throttle_signal) == 0.0
    @test integ.sol(0.05; idxs = sys.driver.throttle_signal) == 1.0
    controls.throttle, controls.brake = 0.0, 0.2
    win.apply!(fresh, sys, ctx, controls, 0.0)
    step!(fresh, 0.1, true)
    @test fresh.sol(0.05; idxs = sys.driver.throttle_signal) == 0.0
    @test integ.sol(0.05; idxs = sys.driver.throttle_signal) == 1.0
    @test issorted(fresh.sol.t)
    @test all(h -> issorted(h.t), fresh.sol.discretes)
    @test length(win.car_shapes(ctx, ctx.snapshot(fresh))[2]) == 4
    @named scripted = VehicleSystemsComponents.PlanarBEVScripted()
    viewer_setup = DyadInterface.setup_analysis(DyadInterface.TransientAnalysisSpec(;
        model = scripted, stop = 0.1, optimize = DyadInterface.OptimizationLevel.None(), progress = false))
    viewer_sys = DyadInterface.symbolic_container(viewer_setup.prob.f)
    viewer = init(viewer_setup.prob, Rodas5P(); dtmax = 0.005)
    viewer_ctx = win.context(viewer, viewer_sys)
    @test ctx.snapshot(integ).throttle == 1.0
    @test ctx.snapshot(fresh).brake == 0.2
    @test viewer_ctx.snapshot(viewer).throttle == 1.0
    @test viewer_ctx.snapshot(viewer).brake == 0.0
    @test !viewer_ctx.by_hand
    @test win.apply!(viewer, viewer_sys, viewer_ctx, controls, 0.0) === nothing
    @test length(win.car_shapes(viewer_ctx, viewer_ctx.snapshot(viewer))[2]) == 4
    ds = padext.DualSense
    pad = ds.Pad(C_NULL, "in-memory test", true,
        ds.PadState(0, 0, 0, 0, 0, 0, 0x08, 0), 0, 0, ds.TriggerOff(), ds.TriggerOff(),
        (0, 0, 0), 0, zeros(UInt8, 47), 0)
    session = padext.PadSession(pad, UInt32(0), 0x08)
    controls.paused = true
    padext.feedback!(session, ctx.snapshot(integ), controls, 0.0)
    ds.fill_common!(pad.effect, pad)
    @test pad.motor_low == pad.motor_high == 0
    @test pad.effect[11] == pad.effect[22] == 0x05
    @test ds.encode(ds.Feedback(2, 0.0)) == ds.encode(ds.TriggerOff())
    @test ds.encode(ds.Vibration(2, 1.0, 25))[10] == 25
    empty!(win.WARMED)
    failing_ctx = merge(ctx, (; snapshot = i -> error("forced warm-up failure")))
    @test_throws "forced warm-up failure" win.window!(fresh, sys, spec, nothing;
        run_window = (i, s, spec, pad) -> win.warm_up!(i, s, failing_ctx, pad))
    @test VehicleSystemsComponents.HUMAN_COMMANDS[] == (0.0, 0.0, 0.0)
    @test_throws "forced window creation failure" win.window!(fresh, sys, spec, nothing;
        run_window = function (i, s, spec, pad)
            VehicleSystemsComponents.set_human_commands!(throttle = 1, brake = 1, steer = 1)
            error("forced window creation failure")
        end)
    @test VehicleSystemsComponents.HUMAN_COMMANDS[] == (0.0, 0.0, 0.0)
    win.warm_up!(fresh, sys, ctx, nothing)
    @test VehicleSystemsComponents.HUMAN_COMMANDS[] == (0.0, 0.0, 0.0)
    @test fresh.t == 0.1
    include(joinpath(@__DIR__, "..", "sim", "drive.jl"))
    @test isdefined(@__MODULE__, :main)
    # A runner can replace its integrator after reset; finalization must return that session.
    @eval VehicleSystemsComponents function unpaced_drive!(i, s, spec)
        win = Base.get_extension(@__MODULE__, :VehicleSystemsComponentsGLMakieExt)
        initial = remake(i.sol.prob; p = deepcopy(i.p), u0 = copy(i.u))
        set_human_commands!(throttle = 1.0, brake = 0.0, steer = 0.0)
        step!(i, 0.2, true)
        fresh = win.fresh_integrator(initial, spec)
        set_human_commands!(throttle = 0.0, brake = 0.2, steer = 0.0)
        step!(fresh, 0.1, true)
        return (; frames = 1, wall = 0.1, integrator = fresh)
    end
    result = VehicleSystemsComponents.PlanarBEVByHandDrive(window = false, duration = 3)
    rs = DyadInterface.symbolic_container(result)
    @test result.sol.t[end] ≈ 0.1
    @test result.sol(0.05; idxs = rs.driver.throttle_signal) == 0.0
    @test result.sol(0.05; idxs = rs.driver.brake_signal) == 0.2
end
