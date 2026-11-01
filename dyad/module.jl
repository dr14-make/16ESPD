using ModelingToolkit
using ModelingToolkit: t_nounits as t, setp

"Held driver commands whose updates are recorded in the solution's parameter time series."
function DriverCommands(; name)
    ps = @discretes begin
        (throttle(t) = 0.0), [description = "Throttle pedal"]
        (brake(t) = 0.0), [description = "Brake pedal"]
        (steer(t) = 0.0), [description = "Steering-wheel angle"]
        (esp_on(t) = 1.0), [description = "ESP enable"]
        (abs_on(t) = 1.0), [description = "ABS enable"]
        (mu_fl(t) = 1.0), [description = "Front-left road friction"]
        (mu_fr(t) = 1.0), [description = "Front-right road friction"]
        (mu_rl(t) = 1.0), [description = "Rear-left road friction"]
        (mu_rr(t) = 1.0), [description = "Rear-right road friction"]
    end
    ys = @variables begin
        (throttle_signal(t)), [output = true]
        (brake_signal(t)), [output = true]
        (steer_signal(t)), [output = true]
        (esp_signal(t)), [output = true]
        (abs_signal(t)), [output = true]
        (mu_fl_signal(t)), [output = true]
        (mu_fr_signal(t)), [output = true]
        (mu_rl_signal(t)), [output = true]
        (mu_rr_signal(t)), [output = true]
    end
    # Register one discrete clock without polling or device I/O inside the equations.
    affect = ModelingToolkit.ImperativeAffect((m, o, ctx, integ) -> m;
        modified = (; throttle, brake, steer, esp_on, abs_on, mu_fl, mu_fr, mu_rl, mu_rr))
    clock = ModelingToolkit.SymbolicDiscreteCallback(t < 0, affect)
    return System([y ~ p for (y, p) in zip(ys, ps)], t, ys, ps;
        name, discrete_events = [clock])
end

"Set supplied driver commands between steps and save their discrete parameter clock."
function set_driver_commands!(integ, sys; kwargs...)
    clocks = Set{Int}()
    for (key, value) in kwargs
        value === nothing && continue
        p = getproperty(sys.driver, key)
        setp(sys, p)(integ, Float64(value))
        idx = ModelingToolkit.get_index_cache(sys).discrete_idx[ModelingToolkit.unwrap(p)]
        push!(clocks, idx.clock_idx)
    end
    for clock in clocks
        ModelingToolkit.SciMLBase.save_discretes!(integ, clock; skip_duplicates = false)
    end
    # Only discrete parameters changed; reinitializing continuous states restores their defaults.
    ModelingToolkit.SciMLBase.u_modified!(integ, false)
    return nothing
end
