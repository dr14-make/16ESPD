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
    sciml = ModelingToolkit.SciMLBase
    @test VehicleSystemsComponents.disable_callback_saves!(nothing) === nothing
    callback = sciml.DiscreteCallback((u, t, i) -> false, i -> nothing)
    VehicleSystemsComponents.disable_callback_saves!(callback)
    @test !any(callback.save_positions)
    callback2 = sciml.DiscreteCallback((u, t, i) -> false, i -> nothing)
    VehicleSystemsComponents.disable_callback_saves!(sciml.CallbackSet(callback2))
    @test !any(callback2.save_positions)
    @test !win.drive_complete((; t = 3599.0), (; duration = 0.0))
    @test win.drive_complete((; t = 3600.0), (; duration = 0.0))

    @named model = VehicleSystemsComponents.PlanarBEVByHand(esp_on = 0.0, abs_on = 0.0, mu = 0.6)
    setup = DyadInterface.setup_analysis(DyadInterface.TransientAnalysisSpec(;
        model, stop = 4.0, optimize = DyadInterface.OptimizationLevel.None(), progress = false))
    sys = DyadInterface.symbolic_container(setup.prob.f)
    spec = VehicleSystemsComponents.RealtimeDriveSpec(; model, duration = 3.0, window = false)
    integ = VehicleSystemsComponents.drive_integrator(setup.prob, spec)
    @testset "First drive after warm-up" begin
        VehicleSystemsComponents.reset_human_commands!()
        empty!(win.WARMED)
        integ = win.warm_up!(integ, sys, win.context(integ, sys), nothing; spec)
        @test VehicleSystemsComponents.HUMAN_COMMANDS[] == (0.0, 0.0, 0.0)
        VehicleSystemsComponents.set_human_commands!(throttle = 1, brake = 0, steer = 0)
        step!(integ, 0.2, true)
        @test integ.sol(0.05; idxs = sys.driver.throttle_signal) == 1.0
        @test integ.sol(0.2; idxs = sys.vehicle.motion.vx) > 0.1
        sampled_speed = integ.sol(0.195; idxs = sys.vehicle.ecu.abs.speed_sampler.y)
        live_speed = integ.sol(0.195; idxs = sys.vehicle.motion.vx)
        @test sampled_speed ≈ live_speed atol = 0.02
        @test sampled_speed > 0.1
    end
    VehicleSystemsComponents.reset_human_commands!()
    integ = VehicleSystemsComponents.drive_integrator(setup.prob, spec)
    initial = remake(integ.sol.prob; p = deepcopy(integ.p), u0 = copy(integ.u))
    ctx = win.context(integ, sys)
    @test !win.drive_complete((; t = 18.9), (; duration = 22.0))
    @test win.drive_complete((; t = 22.0), (; duration = 22.0))
    @test !win.drive_complete((; t = 0.0), spec)
    controls = win.Controls(; ctx.esp_on, ctx.abs_on)
    @test !controls.esp
    @test !controls.abs
    @test ctx.mu == 0.6
    @test !win.abs_cycling((; demand = 1000, tfl = 0, tfr = 0, trl = 0, trr = 0), controls)
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
    function reset_runner(i, s, spec)
        initial = remake(i.sol.prob; p = deepcopy(i.p), u0 = copy(i.u))
        VehicleSystemsComponents.set_human_commands!(throttle = 1.0, brake = 0.0, steer = 0.0)
        step!(i, 0.2, true)
        fresh = win.fresh_integrator(initial, spec)
        VehicleSystemsComponents.set_human_commands!(throttle = 0.0, brake = 0.2, steer = 0.0)
        step!(fresh, 0.1, true)
        return (; frames = 1, wall = 0.1, integrator = fresh)
    end
    result = DyadInterface.run_analysis(spec; run_drive = reset_runner)
    rs = DyadInterface.symbolic_container(result)
    @test result.sol.t[end] ≈ 0.1
    @test result.sol(0.05; idxs = rs.driver.throttle_signal) == 0.0
    @test result.sol(0.05; idxs = rs.driver.brake_signal) == 0.2
end
