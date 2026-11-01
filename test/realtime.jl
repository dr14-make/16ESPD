using ModelingToolkit
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
        @test integ.ps[sys.driver.throttle] == values[1]
        @test integ.ps[sys.driver.esp_on] == values[4]
    end
    for (j, output) in enumerate(outputs)
        signal = getproperty(sys.driver, output)
        for (k, values) in enumerate(commands)
            times = filter(t -> (k - 1) * 0.2 + 1e-8 < t < k * 0.2 - 1e-8, integ.sol.t)
            @test all(==(values[j]), integ.sol(times; idxs = signal).u)
        end
    end
    @test string(integ.sol.retcode) in ("Default", "Success")
end
