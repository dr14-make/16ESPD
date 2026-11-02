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
    first, second = replay(), replay()
    for (j, output) in enumerate((:throttle_signal, :brake_signal, :steer_signal))
        signal = getproperty(sys.driver, output)
        @test first[signal] == second[signal]
        for (t, expected) in ((0.007, (0.0, 0.0, 0.0)), (0.012, (1.0, 0.0, 0.0)),
                              (0.027, (1.0, 0.0, 0.0)), (0.032, (0.0, 0.2, 0.1)),
                              (0.047, (0.0, 0.2, 0.1)), (0.052, (0.3, 0.0, -0.1)))
            @test first(t; idxs = signal) == expected[j]
        end
        # Changing the live buffer cannot change returned history.
        VehicleSystemsComponents.reset_human_commands!()
        @test first(0.052; idxs = signal) == (0.3, 0.0, -0.1)[j]
    end
    @test first.t == second.t
    @test first.u == second.u
    VehicleSystemsComponents.set_human_commands!(throttle = 1, brake = 1, steer = 1)
    neutral = VehicleSystemsComponents.PlanarBEVByHandDrive(window = false, duration = 0.1)
    ns = symbolic_container(neutral)
    for signal in (ns.driver.throttle_signal, ns.driver.brake_signal, ns.driver.steer_signal)
        @test all(iszero, neutral.sol[signal])
    end
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
    @test_throws "load GLMakie" VehicleSystemsComponents.PlanarBEVRealtimeDrive(window = true)
    @test_throws "duration > 0" VehicleSystemsComponents.PlanarBEVRealtimeDrive(duration = 0)
end

@testset "Hard-stop preset and fixed run settings" begin
    result = VehicleSystemsComponents.PlanarBEVRealtimeDrive(
        model = VehicleSystemsComponents.PlanarBEVScripted(; name = :hard_stop,
            table = "dyad://VehicleSystemsComponents/drivers/hard_stop.csv"))
    sys, sol = symbolic_container(result), result.sol
    for t in (0.0, 9.0, 18.99, 19.0, 19.01, 22.0)
        @test sol(t; idxs = sys.driver.throttle_signal) == (t < 9 ? 1.0 : 0.0)
        @test sol(t; idxs = sys.driver.brake_signal) == (t < 19 ? 0.0 : 1.0)
        @test sol(t; idxs = sys.driver.steer_signal) == 0.0
    end
    @test round(3.6sol(22.0; idxs = sys.vehicle.motion.vx); digits = 1) == 0.0
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
