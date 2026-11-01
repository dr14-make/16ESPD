using ModelingToolkit
import DyadInterface
using DyadInterface: simplify_model
using OrdinaryDiffEqDefault: init, step!, Rodas5P

@testset "Held driver command history" begin
    @named model = VehicleSystemsComponents.Vehicle.Planar.PlanarBEVDrive()
    sys = simplify_model(model)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); dtmax = 0.005, saveat = 0.01)
    names = (:throttle, :brake, :steer, :esp_on, :abs_on, :mu_fl, :mu_fr, :mu_rl, :mu_rr)
    outputs = (:throttle_signal, :brake_signal, :steer_signal, :esp_signal, :abs_signal,
        :mu_fl_signal, :mu_fr_signal, :mu_rl_signal, :mu_rr_signal)
    commands = [(1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0),
        (0.0, 0.2, 0.1, 0.0, 0.0, 0.7, 0.6, 0.5, 0.4),
        (0.3, 0.0, -0.1, 1.0, 1.0, 0.9, 0.8, 0.7, 0.6)]
    for values in commands
        VehicleSystemsComponents.set_driver_commands!(integ, sys; NamedTuple{names}(values)...)
        step!(integ, 0.2, true)
        for (name, value) in zip(names, values)
            @test integ.ps[getproperty(sys.driver, name)] == value
        end
        @test integ[sys.ecu.esp.enable_value] == values[4]
        @test integ[sys.ecu.abs.enable_value] == values[5]
        for (wheel, mu) in zip((:fl, :fr, :rl, :rr), values[6:9])
            w = getproperty(sys.car, wheel)
            @test integ[w.joint.fN] ≈ mu * integ[w.load.f]
        end
    end
    for (j, output) in enumerate(outputs)
        signal = getproperty(sys.driver, output)
        for (k, values) in enumerate(commands)
            times = filter(t -> (k - 1) * 0.2 + 1e-8 < t < k * 0.2 - 1e-8, integ.sol.t)
            @test all(==(values[j]), integ.sol(times; idxs = signal).u)
        end
        expected = [commands[min(searchsortedlast([0.0, 0.2, 0.4], t), 3)][j]
            for t in integ.sol.t]
        @test integ.sol(integ.sol.t; idxs = signal).u == expected
    end
    @test string(integ.sol.retcode) in ("Default", "Success")
end


using DyadOrchestrator
using DyadInterface: symbolic_container
@testset "Realtime analysis by name" begin
    @test "PlanarBEVRealtimeDrive" in DyadOrchestrator.list_analyses("VehicleSystemsComponents")
    result = DyadOrchestrator.run_analysis("VehicleSystemsComponents", "PlanarBEVRealtimeDrive")
    @test result isa DyadInterface.TransientAnalysisSolution
    sys = symbolic_container(result)
    sol = result.sol
    @test length(sol.t) <= 183
    @test sol.t[end] ≈ 3.0
    @test maximum(sol[sys.motion.vx]) > 5.0
    @test sol[sys.motion.vx][end] < maximum(sol[sys.motion.vx])
    early = filter(t -> 0.1 < t < 1.4, sol.t)
    late = filter(t -> 1.6 < t < 2.9, sol.t)
    @test all(==(1.0), sol(early; idxs = sys.driver.throttle_signal).u)
    @test all(==(0.0), sol(late; idxs = sys.driver.throttle_signal).u)
    @test all(==(0.0), sol(early; idxs = sys.driver.brake_signal).u)
    @test all(==(1.0), sol(late; idxs = sys.driver.brake_signal).u)
    for (output, expected) in ((:steer_signal, 0.0), (:esp_signal, 1.0), (:abs_signal, 1.0),
            (:mu_fl_signal, 1.0), (:mu_fr_signal, 1.0), (:mu_rl_signal, 1.0), (:mu_rr_signal, 1.0))
        @test all(==(expected), sol(sol.t; idxs = getproperty(sys.driver, output)).u)
    end
    @test DyadInterface.artifacts(result, :SimulationSolutionPlot) !== nothing
    @test size(DyadInterface.artifacts(result, :SimulationSolutionTable), 1) > 0
    @test_throws "load GLMakie" VehicleSystemsComponents.PlanarBEVRealtimeDrive(headless = false)
end
