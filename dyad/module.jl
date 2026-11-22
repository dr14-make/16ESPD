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
    can_interface::String = ""
    esp_on::Float64 = 1.0
    abs_on::Float64 = 1.0
    mu::Float64 = 1.0
    "OpenCRG grip asset for a model with a road car; empty keeps the model's own."
    road_file::String = ""
    "OpenCRG height asset for a model with a road car; empty keeps the model's own."
    height_file::String = ""
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

"""
    drive_model(spec)

The spec's model, rebuilt with the spec's `road_file` and `height_file` when it names either.

Road files are structural parameters of the car, and an analysis cannot pass its parameters to
a structural parameter of its model: the `model` field is built without them, and a structural
modification would arrive as a run-time override the built system has no variable for. So the
files reach the model here instead: its constructor is called again under the same name with the
named files. Any other structural setting of a passed-in model returns to its default.
"""
function drive_model(spec)
    files = (; (k => getfield(spec, k) for k in (:road_file, :height_file)
                if !isempty(getfield(spec, k)))...)
    isempty(files) && return spec.model
    meta = ModelingToolkit.get_gui_metadata(spec.model)
    meta === nothing && throw(ArgumentError(
        "$(nameof(spec.model)): road files need a model built by a component constructor"))
    constructor = getglobal(meta.type.mod, meta.type.name)
    return constructor(; name = nameof(spec.model), files...)
end

"""
    drive_road(spec) -> Union{Nothing, NamedTuple}

Static road layer for a drive window, sampled once by [`road_mesh`](@ref) from the spec's road
files: `nothing` when the spec names neither, otherwise the sample axes `x` and `y`, the
`height` and `grip` matrices, and `grip_varies` and `height_varies`, which say whether a grip map
and height contours carry any information.
"""
function drive_road(spec)
    isempty(spec.road_file) && isempty(spec.height_file) && return nothing
    given(file) = isempty(file) ? nothing : file
    (; x, y, height, grip) = road_mesh(given(spec.height_file); grip_file = given(spec.road_file))
    varies(values) = ((low, high) = extrema(values); high - low > 1e-6)
    return (; x, y, height, grip, grip_varies = varies(grip), height_varies = varies(height))
end

include("can_stream.jl")

"Integrator saving one sample per frame; drives and resets share the solver settings."
function drive_integrator(prob, spec)
    return init(prob, Rodas5P(); dtmax = spec.dtmax, saveat = spec.frame,
        save_everystep = false)
end

"Whether the integrator can keep stepping."
stepping(integ) = integ.sol.retcode in (ReturnCode.Default, ReturnCode.Success)

"Advance without pacing or device input; preserve the assembly's driver signals."
function unpaced_drive!(integ, sys, spec)
    spec.duration > 0 || throw(ArgumentError("RealtimeDrive without a window requires duration > 0"))
    started = time()
    can_step!(integ, spec.duration - integ.t, sys)
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
        run_drive = spec.window ? drive_window : unpaced_drive!,
        open_can = can_open, can_paced = true)
    reset_human_commands!()
    spec.frame > 0 && spec.dtmax > 0 && spec.duration >= 0 ||
        throw(ArgumentError("RealtimeDrive requires frame > 0, dtmax > 0, and duration >= 0"))
    spec.window && isempty(methods(drive_window)) && load_window_packages!()
    spec.window && isempty(methods(drive_window)) && error(WINDOW_MISSING)
    model = drive_model(spec)
    transient(stop) = TransientAnalysisSpec(; name = spec.name, model,
        overrides = spec.overrides, stop, dtmax = spec.dtmax, progress = false,
        optimize = OptimizationLevel.None())
    setup = DyadInterface.setup_analysis(transient(spec.duration > 0 ? spec.duration + 1.0 : 3600.0))
    sys = DyadInterface.symbolic_container(setup.prob.f)
    # MTK's clock and discontinuity callbacks otherwise add saves at solver frequency.
    # Their discrete parameter histories are saved independently of continuous positions.
    disable_callback_saves!(get(setup.prob.kwargs, :callback, nothing))
    stream = isempty(spec.can_interface) ? nothing : CanStream(
        Vehicle.Planar.can_layout(model), open_can(spec.can_interface); paced = can_paced)
    integ = nothing
    stats = try
        task_local_storage(:vehicle_can_stream, stream) do
            integ = drive_integrator(setup.prob, spec)
            Base.invokelatest(run_drive, integ, sys, spec)
        end
    catch e
        e isa InterruptException && integ !== nothing || rethrow()
        @info "drive interrupted at t = $(integ.t) s; returning what was driven"
        nothing
    finally
        if stream !== nothing
            Base.invokelatest(can_close, stream.transport)
            @info "CAN stream finished" stream.sent stream.late stream.max_lateness
        end
    end
    # A drive returns the integrator it finished on; a window reset starts a new one.
    stats === nothing || (integ = stats.integrator)
    ModelingToolkit.SciMLBase.savevalues!(integ, true)
    stats === nothing || @info "drive finished" simulation_time = integ.t stats.frames stats.wall
    p = DyadInterface.unwrap_parameters(integ.sol.prob.p)
    return TransientAnalysisSolution(transient(integ.t), DyadInterface.maybe_strip_sol(integ.sol, Val(true)),
        setup.prob.f.mass_matrix, sys, setup.f_oop, setup.f_iip, integ.sol.prob.u0, p)
end
