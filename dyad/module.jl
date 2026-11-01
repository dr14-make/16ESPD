using ModelingToolkit
using ModelingToolkit: t_nounits as t, setp

"Held driver commands whose updates are recorded in the solution's parameter time series."
function DriverCommands(; name)
    ps = @discretes begin
        (throttle(t) = 0.0), [description = "Throttle pedal"]
        (brake(t) = 0.0), [description = "Brake pedal"]
        (steer(t) = 0.0), [description = "Steering-wheel angle"]
    end
    ys = @variables begin
        (throttle_signal(t)), [output = true]
        (brake_signal(t)), [output = true]
        (steer_signal(t)), [output = true]
    end
    # Register one discrete clock without polling or device I/O inside the equations.
    affect = ModelingToolkit.ImperativeAffect((m, o, ctx, integ) -> m;
        modified = (; throttle, brake, steer))
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
        idx = ModelingToolkit.SymbolicIndexingInterface.timeseries_parameter_index(sys, p)
        push!(clocks, idx.timeseries_idx)
    end
    for clock in clocks
        ModelingToolkit.SciMLBase.save_discretes!(integ, clock; skip_duplicates = false)
    end
    # Only discrete parameters changed; reinitializing continuous states restores their defaults.
    ModelingToolkit.SciMLBase.u_modified!(integ, false)
    return nothing
end

import DyadInterface
using DyadInterface: AbstractAnalysisSpec, TransientAnalysisSpec, TransientAnalysisSolution, OptimizationLevel
using OrdinaryDiffEqDefault: Rodas5P, init, step!

"Supertype for wall-clock drive analysis specifications."
abstract type AbstractRealtimeDriveSpec <: AbstractAnalysisSpec end

"Drive specification for a driver-and-car assembly."
@kwdef struct RealtimeDriveSpec{M} <: AbstractRealtimeDriveSpec
    name::Symbol = :RealtimeDrive
    model::M
    overrides::Dict{ModelingToolkit.SymbolicT, ModelingToolkit.SymbolicT} =
        Dict{ModelingToolkit.SymbolicT, ModelingToolkit.SymbolicT}()
    __system::Any = nothing
    duration::Float64 = 0.0
    frame::Float64 = 1 / 60
    dtmax::Float64 = 0.005
    window::Bool = false
    esp_on::Float64 = 1.0
    abs_on::Float64 = 1.0
    mu::Float64 = 1.0
end

DyadInterface.is_runnable(T::Type{<:AbstractRealtimeDriveSpec}) =
    !isabstracttype(T) && !(nameof(T) in (:RealtimeDrive__Spec, :RealtimeDriveSpec))

"Interactive driver loop supplied by optional window and controller extensions."
function drive_window end

"Advance without pacing or device input; preserve the assembly's driver signals."
function unpaced_drive!(integ, sys, spec)
    spec.duration > 0 || throw(ArgumentError("RealtimeDrive without a window requires duration > 0"))
    started = time()
    step!(integ, spec.duration - integ.t, true)
    string(integ.sol.retcode) in ("Default", "Success") ||
        error("solver stopped: $(integ.sol.retcode)")
    return (; frames = ceil(Int, integ.t / spec.frame), wall = time() - started)
end

function DyadInterface.run_analysis(spec::RealtimeDriveSpec)
    spec.frame > 0 && spec.dtmax > 0 && spec.duration >= 0 ||
        throw(ArgumentError("RealtimeDrive requires frame > 0, dtmax > 0, and duration >= 0"))
    if spec.window && isempty(methods(drive_window))
        error("RealtimeDrive needs the drive window: load GLMakie, or set window = false.")
    end
    horizon = spec.duration > 0 ? spec.duration + 1.0 : 3600.0
    tspec = TransientAnalysisSpec(; name = spec.name, model = spec.model,
        overrides = spec.overrides, stop = horizon, dtmax = spec.dtmax, progress = false,
        optimize = OptimizationLevel.None())
    setup = DyadInterface.setup_analysis(tspec)
    sys = DyadInterface.symbolic_container(setup.prob.f)
    # MTK's clock and discontinuity callbacks otherwise add saves at solver frequency.
    # Their discrete parameter histories are saved independently of continuous positions.
    callbacks = setup.prob.kwargs[:callback]
    for cb in (callbacks.continuous_callbacks..., callbacks.discrete_callbacks...)
        cb.save_positions .= false
    end
    integ = init(setup.prob, Rodas5P(); dtmax = spec.dtmax, saveat = spec.frame,
        save_everystep = false)
    stats = try
        if !spec.window
            unpaced_drive!(integ, sys, spec)
        else
            applicable(drive_window, integ, sys, spec) || error(
                "RealtimeDrive needs the drive window: load GLMakie, or set window = false.")
            drive_window(integ, sys, spec)
        end
    catch e
        e isa InterruptException || rethrow()
        @info "drive interrupted at t = $(integ.t) s; returning what was driven"
        nothing
    end
    if stats !== nothing && hasproperty(stats, :integrator)
        integ = stats.integrator
    end
    ModelingToolkit.SciMLBase.savevalues!(integ, true)
    stats === nothing || @info "drive finished" simulation_time = integ.t stats.frames stats.wall
    done = TransientAnalysisSpec(; name = spec.name, model = spec.model,
        overrides = spec.overrides, stop = integ.t, dtmax = spec.dtmax, progress = false,
        optimize = OptimizationLevel.None())
    p = DyadInterface.unwrap_parameters(integ.sol.prob.p)
    return TransientAnalysisSolution(done, DyadInterface.maybe_strip_sol(integ.sol, Val(true)),
        setup.prob.f.mass_matrix, sys, setup.f_oop, setup.f_iip, integ.sol.prob.u0, p)
end

