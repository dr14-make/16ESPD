using ModelingToolkit

import DyadInterface
using DyadInterface: AbstractAnalysisSpec, TransientAnalysisSpec, TransientAnalysisSolution, OptimizationLevel
using OrdinaryDiffEqDefault: Rodas5P, init, step!
using ModelingToolkit.SciMLBase: ReturnCode

"Supertype for wall-clock drive analysis specifications."
abstract type AbstractRealtimeDriveSpec <: AbstractAnalysisSpec end

"Drive specification for a driver-and-car assembly."
@kwdef struct RealtimeDriveSpec{M} <: AbstractRealtimeDriveSpec
    name::Symbol = :RealtimeDrive
    model::M
    overrides::Dict{ModelingToolkit.SymbolicT, ModelingToolkit.SymbolicT} =
        Dict{ModelingToolkit.SymbolicT, ModelingToolkit.SymbolicT}()
    __system::Any = nothing
    "Simulation duration; zero runs until window close or the 3600 s simulation limit."
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

const WINDOW_MISSING = "RealtimeDrive needs the drive window: load GLMakie (add it to your " *
    "Julia environment, with SimpleDirectMediaLayer for a game controller), or set window = false."

"Optional window and game-controller packages, in the order their extensions need them."
const WINDOW_PACKAGES = (
    Base.PkgId(Base.UUID("e9467ef8-e4e7-5192-8a1a-b1aee30e663a"), "GLMakie"),
    Base.PkgId(Base.UUID("98e33af6-2ee5-5afd-9e75-cbc738b767c4"), "SimpleDirectMediaLayer"),
)

"Load whichever window packages the environment stack provides; their extensions follow."
function load_window_packages!()
    for pkg in WINDOW_PACKAGES
        Base.locate_package(pkg) === nothing || Base.require(pkg)
    end
    return nothing
end

"Integrator saving one sample per frame; drives and resets share the solver settings."
drive_integrator(prob, spec) =
    init(prob, Rodas5P(); dtmax = spec.dtmax, saveat = spec.frame, save_everystep = false)

"Whether the integrator can keep stepping."
stepping(integ) = integ.sol.retcode in (ReturnCode.Default, ReturnCode.Success)

"Advance without pacing or device input; preserve the assembly's driver signals."
function unpaced_drive!(integ, sys, spec)
    spec.duration > 0 || throw(ArgumentError("RealtimeDrive without a window requires duration > 0"))
    started = time()
    step!(integ, spec.duration - integ.t, true)
    stepping(integ) || error("solver stopped: $(integ.sol.retcode)")
    return (; frames = ceil(Int, integ.t / spec.frame), wall = time() - started, integrator = integ)
end

"Disable continuous-position saves without changing discrete parameter histories."
function disable_callback_saves!(callback)
    callback === nothing && return nothing
    if callback isa ModelingToolkit.SciMLBase.CallbackSet
        foreach(disable_callback_saves!, callback.continuous_callbacks)
        foreach(disable_callback_saves!, callback.discrete_callbacks)
    else
        callback.save_positions .= false
    end
    return nothing
end

function DyadInterface.run_analysis(spec::RealtimeDriveSpec;
        run_drive = spec.window ? drive_window : unpaced_drive!)
    reset_human_commands!()
    spec.frame > 0 && spec.dtmax > 0 && spec.duration >= 0 ||
        throw(ArgumentError("RealtimeDrive requires frame > 0, dtmax > 0, and duration >= 0"))
    spec.window && isempty(methods(drive_window)) && load_window_packages!()
    spec.window && isempty(methods(drive_window)) && error(WINDOW_MISSING)
    transient(stop) = TransientAnalysisSpec(; name = spec.name, model = spec.model,
        overrides = spec.overrides, stop, dtmax = spec.dtmax, progress = false,
        optimize = OptimizationLevel.None())
    setup = DyadInterface.setup_analysis(transient(spec.duration > 0 ? spec.duration + 1.0 : 3600.0))
    sys = DyadInterface.symbolic_container(setup.prob.f)
    # MTK's clock and discontinuity callbacks otherwise add saves at solver frequency.
    # Their discrete parameter histories are saved independently of continuous positions.
    disable_callback_saves!(get(setup.prob.kwargs, :callback, nothing))
    integ = drive_integrator(setup.prob, spec)
    stats = try
        # Window methods loaded during this call exist only in a newer world.
        Base.invokelatest(run_drive, integ, sys, spec)
    catch e
        e isa InterruptException || rethrow()
        @info "drive interrupted at t = $(integ.t) s; returning what was driven"
        nothing
    end
    # A drive returns the integrator it finished on; a window reset starts a new one.
    stats === nothing || (integ = stats.integrator)
    ModelingToolkit.SciMLBase.savevalues!(integ, true)
    stats === nothing || @info "drive finished" simulation_time = integ.t stats.frames stats.wall
    p = DyadInterface.unwrap_parameters(integ.sol.prob.p)
    return TransientAnalysisSolution(transient(integ.t), DyadInterface.maybe_strip_sol(integ.sol, Val(true)),
        setup.prob.f.mass_matrix, sys, setup.f_oop, setup.f_iip, integ.sol.prob.u0, p)
end
