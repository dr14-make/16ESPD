using ModelingToolkit
import DyadInterface
using DyadInterface: simplify_model, symbolic_container
using OrdinaryDiffEqDefault: init, step!, Rodas5P
using DyadOrchestrator

@testset "Clocked human command history and replay" begin
    VehicleSystemsComponents.reset_human_commands!()
    @named model = VehicleSystemsComponents.PlanarBEVByHand(esp_on = 0.0, abs_on = 0.0, mu = 0.7)
    sys = simplify_model(model)
    prob = ODEProblem(sys, [], (0.0, 1.0))
    function replay()
        VehicleSystemsComponents.reset_human_commands!()
        integ = init(prob, Rodas5P(); dtmax = 0.005, saveat = 0.001)
        step!(integ, 0.005, true)
        commands = [(1.0, 0.0, 0.0), (0.0, 0.2, 0.1), (0.3, 0.0, -0.1)]
        for values in commands
            VehicleSystemsComponents.set_human_commands!(; NamedTuple{(:throttle, :brake, :steer)}(values)...)
            step!(integ, 0.02, true)
        end
        return integ.sol
    end
    first_replay, second_replay = replay(), replay()
    for (j, output) in enumerate((:throttle_signal, :brake_signal, :steer_signal))
        signal = getproperty(sys.driver, output)
        @test first_replay[signal] == second_replay[signal]
        for (t, expected) in ((0.007, (0.0, 0.0, 0.0)), (0.012, (1.0, 0.0, 0.0)),
                              (0.027, (1.0, 0.0, 0.0)), (0.032, (0.0, 0.2, 0.1)),
                              (0.047, (0.0, 0.2, 0.1)), (0.052, (0.3, 0.0, -0.1)))
            @test first_replay(t; idxs = signal) == expected[j]
        end
        # Changing the live buffer cannot change returned history.
        VehicleSystemsComponents.reset_human_commands!()
        @test first_replay(0.052; idxs = signal) == (0.3, 0.0, -0.1)[j]
    end
    @test first_replay.t == second_replay.t
    @test first_replay.u == second_replay.u
    VehicleSystemsComponents.set_human_commands!(throttle = 1, brake = 1, steer = 1)
    neutral = VehicleSystemsComponents.PlanarBEVByHandDrive(window = false, duration = 0.1)
    ns = symbolic_container(neutral)
    for signal in (ns.driver.throttle_signal, ns.driver.brake_signal, ns.driver.steer_signal)
        @test all(iszero, neutral.sol[signal])
    end
end

@testset "By-hand analysis forwards its road files to the car and the window" begin
    V = VehicleSystemsComponents
    roads = "dyad://VehicleSystemsComponents/roads/"
    plain = V.__dyad_base_analysis_spec(V.PlanarBEVByHandDrive__Spec(; window = false))
    @test plain.road_file == plain.height_file == ""
    @test V.drive_model(plain) === plain.model
    @test V.drive_road(plain) === nothing
    files = (; road_file = roads * "uniform_low_mu.crg", height_file = roads * "ramp_hold_z.crg")
    spec = V.__dyad_base_analysis_spec(V.PlanarBEVByHandDrive__Spec(; window = false, files...))
    @test (spec.road_file, spec.height_file) == values(files)
    road = V.drive_road(spec)
    @test !road.grip_varies && road.height_varies
    @test all(≈(0.3), road.grip)
    @test V.drive_road(V.__dyad_base_analysis_spec(V.PlanarBEVByHandDrive__Spec(;
        road_file = roads * "ice_patch_mu.crg"))).grip_varies
    result = V.PlanarBEVByHandDrive(; window = false, duration = 3.0, mu = 0.9, files...)
    rs, sol = symbolic_container(result), result.sol
    @test sol.t[end] ≈ 3.0
    for wheel in (:fl, :fr, :rl, :rr)
        w = getproperty(rs.vehicle.car, wheel)
        @test sol(3.0; idxs = w.grip) ≈ 0.3
        @test sol.prob.ps[w.mu_scale] == 0.9
    end
    @test sol(3.0; idxs = rs.vehicle.roadgrade.grade) ≈ 0.02
    # Released pedals on an uphill grade: the car rolls back.
    @test sol(3.0; idxs = rs.vehicle.motion.vx) < -0.01
    @test all(isfinite, sol.u[end])
end

@testset "Scripted analysis by name" begin
    @test "PlanarBEVRealtimeDrive" in DyadOrchestrator.list_analyses("VehicleSystemsComponents")
    result = DyadOrchestrator.run_analysis("VehicleSystemsComponents", "PlanarBEVRealtimeDrive")
    @test result isa DyadInterface.TransientAnalysisSolution
    sys, sol = symbolic_container(result), result.sol
    @test sol.t[end] ≈ 22.0
    for t in (0.0, 4.5, 8.99, 9.0, 9.01, 18.99, 19.0, 22.0)
        @test sol(t; idxs = sys.driver.throttle_signal) == (t < 9 ? 1.0 : 0.0)
        @test sol(t; idxs = sys.driver.brake_signal) == 0.0
        @test sol(t; idxs = sys.driver.steer_signal) == 0.0
    end
    @test round(3.6sol(9.0; idxs = sys.vehicle.motion.vx); digits = 1) == 105.6
    @test round(sol(9.0; idxs = sys.vehicle.roadload.F)) == 502
    @test round(3.6sol(19.0; idxs = sys.vehicle.motion.vx); digits = 1) == 94.5
    @test DyadInterface.artifacts(result, :SimulationSolutionPlot) !== nothing
    @test size(DyadInterface.artifacts(result, :SimulationSolutionTable), 1) > 0
    # A load path providing GLMakie would open a real window instead of raising.
    @test_throws "load GLMakie" let saved = copy(LOAD_PATH)
        try
            append!(empty!(LOAD_PATH), ["@", "@stdlib"])
            VehicleSystemsComponents.PlanarBEVRealtimeDrive(window = true)
        finally
            append!(empty!(LOAD_PATH), saved)
        end
    end
    @test_throws "duration > 0" VehicleSystemsComponents.PlanarBEVRealtimeDrive(duration = 0)
end

@testset "Hard-stop preset and fixed run settings" begin
    result = VehicleSystemsComponents.PlanarBEVRealtimeDrive(
        model = VehicleSystemsComponents.PlanarBEVOnRoad(; name = :hard_stop,
            table = "dyad://VehicleSystemsComponents/drivers/hard_stop.csv"))
    sys, sol = symbolic_container(result), result.sol
    for t in (0.0, 9.0, 18.99, 19.0, 19.01, 22.0)
        @test sol(t; idxs = sys.driver.throttle_signal) == (t < 9 ? 1.0 : 0.0)
        @test sol(t; idxs = sys.driver.brake_signal) == (t < 19 ? 0.0 : 1.0)
        @test sol(t; idxs = sys.driver.steer_signal) == 0.0
    end
    @test round(3.6sol(22.0; idxs = sys.vehicle.motion.vx); digits = 1) == 0.0
    for (t, signal, before, after) in ((9.0, sys.driver.throttle_signal, 1.0, 0.0),
                                     (19.0, sys.driver.brake_signal, 0.0, 1.0))
        @test sol(t - 1e-6; idxs = signal) == before
        @test sol(t; idxs = signal) == after
        @test sol(t + 1e-6; idxs = signal) == after
    end
    for signal in (sys.driver.throttle_signal, sys.driver.brake_signal, sys.driver.steer_signal)
        @test all(0:2199) do k
            tick = k * 0.01
            held = sol(tick; idxs = signal)
            all(f -> sol(tick + f * 0.01; idxs = signal) == held, (0.25, 0.5, 0.75))
        end
    end
    tau_max = sol.prob.ps[sys.vehicle.tau_max]
    lag = sys.vehicle.torque_response
    switch_times = 8.95:0.0001:9.05
    @test all(t -> 0.0 <= sol(t; idxs = lag.u) <= tau_max, switch_times)
    @test all(t -> -1e-8 <= sol(t; idxs = lag.y) <= tau_max + 1e-8, switch_times)
    @test round(sol(9.0; idxs = lag.y)) == tau_max
    configured = VehicleSystemsComponents.PlanarBEVRealtimeDrive(duration = 0.1, esp_on = 0.0, abs_on = 0.0, mu = 0.7)
    cs = symbolic_container(configured)
    @test configured.sol.prob.ps[cs.vehicle.ecu.esp_on] == 0.0
    @test configured.sol.prob.ps[cs.vehicle.ecu.abs_on] == 0.0
    for wheel in (:fl, :fr, :rl, :rr)
        w = getproperty(cs.vehicle.car, wheel)
        @test configured.sol.prob.ps[w.mu_scale] == 0.7
        @test configured.sol.prob.ps[w.joint.mu_A] == 0.7
    end
    @test !any(p -> p.name in ("GLMakie", "SimpleDirectMediaLayer"), keys(Base.loaded_modules))
end

@testset "Brake held at standstill for 60 s stays finite" begin
    @named held = VehicleSystemsComponents.PlanarBEVByHand(mu = 1.0)
    hs = simplify_model(held)
    for on in (1.0, 0.0)
        prob = ODEProblem(hs, [hs.esp_on => on, hs.abs_on => on], (0.0, 1e7))
        @test prob.ps[hs.vehicle.ecu.esp_on] == on
        @test prob.ps[hs.vehicle.ecu.abs_on] == on
        VehicleSystemsComponents.reset_human_commands!()
        integ = init(prob, Rodas5P(); dtmax = 0.005, save_everystep = false)
        VehicleSystemsComponents.set_human_commands!(throttle = 0, brake = 1, steer = 0)
        while integ.t < 60.0 && string(integ.sol.retcode) in ("Default", "Success")
            step!(integ, 1 / 60, true)
        end
        VehicleSystemsComponents.reset_human_commands!()
        @test string(integ.sol.retcode) in ("Default", "Success")
        @test integ.t >= 60.0
        @test all(isfinite, integ.u)
        @test abs(integ[hs.vehicle.motion.vx]) < 1e-6
    end
end
