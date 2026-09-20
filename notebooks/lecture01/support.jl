"""
Boilerplate and house style for the lecture 1 notebooks.

Include once at the top of a notebook and call [`setup`](@ref):

    include("support.jl")
    using .Lecture01Support
    setup()

This module holds no pedagogy. Force balances, derivations and the reasoning that goes with
them stay visible in the notebook cells; what lives here is the environment bootstrap, the
plant parameter set, the sweep machinery, and the plot and readout conventions that would
otherwise be copied into ten notebooks.

There are no unit conversion helpers. The model emits km/h through `Vehicle.ToKmPerHour`, so
a notebook never converts a plotted signal after the fact.

Only `Pkg` is loaded when this file is included: the modeling packages live in the project
environment that [`setup`](@ref) resolves, so they are pulled in from inside it and every
reference to them below is resolved when a function is first called rather than here.
"""
module Lecture01Support

using Pkg

export setup, CAR,
    sweep, Sweep,
    plot_speed, plot_sweep, plot_torque, bracket_error!,
    steady_state_error, overshoot, rise_time, fopdt_fit,
    signal, resolve

# ---------------------------------------------------------------------------------------
# Plant parameters
# ---------------------------------------------------------------------------------------

"""
    CAR

The L0 vehicle parameter set, as tabulated in `docs/HANDOVER.md`.

Primitive quantities only. Everything derived from them — drag coefficient, rolling force,
tractive force limit, terminal speed, cruise torque — is arithmetic the notebooks perform in
front of the reader.

`theta_e` is expected to move into the 0.2-0.3 s range (HANDOVER Risk 1), so read it from
here rather than writing 0.04 into a cell.

| Field | Meaning | Unit |
|---|---|---|
| `m` | vehicle mass | kg |
| `CdA` | drag area | m^2 |
| `rho` | air density | kg/m^3 |
| `f_r` | rolling resistance coefficient | - |
| `r` | wheel rolling radius | m |
| `i` | total gear ratio | - |
| `T_max` | engine torque limit | N.m |
| `tau_e` | manifold-filling lag | s |
| `theta_e` | injection-to-torque transport delay | s |
| `g` | gravitational acceleration | m/s^2 |
"""
const CAR = (
    m = 1400.0,
    CdA = 0.63,
    rho = 1.2,
    f_r = 0.012,
    r = 0.31,
    i = 4.0,
    T_max = 150.0,
    tau_e = 0.3,
    theta_e = 0.04,
    g = 9.80665,
)

"""
    SPEED_KMH, TORQUE_CMD, TORQUE_DELIVERED

Default signal paths, naming the `Lecture1.CarPlant` ports and the engine's post-limiter
torque as specified in `docs/lecture-01-dyad-tasks.md`. A notebook that wraps the plant
inside an assembly passes its own path to the `sig` keyword instead.
"""
const SPEED_KMH = "v_kmh"
const TORQUE_CMD = "tau_cmd"
const TORQUE_DELIVERED = "engine.limiter.y"

# ---------------------------------------------------------------------------------------
# Environment bootstrap
# ---------------------------------------------------------------------------------------

"""
    setup(; package_path = <repository root>, backend = :gr) -> Module

Bring up the Dyad environment and load the component library, collapsing the eight bootstrap
cells of `scripts/analysis-notebook.ipynb` into one call. Returns the loaded package module,
which is also bound in `Main` under its own name.

`backend` selects the Plots backend. The default is `:gr` because these notebooks are
committed with their outputs as the lecture's fallback when a live solve stalls, and GR emits
PNGs that survive in any static viewer, where `plotly` output is JavaScript that a static
viewer drops. Pass `backend = :plotly` for an interactive working session.
"""
function setup(; package_path::AbstractString = normpath(@__DIR__, "..", ".."),
        backend::Symbol = :gr)
    install_orchestrator()
    Core.eval(@__MODULE__, :(using DyadOrchestrator))
    orchestrator = getproperty(@__MODULE__, :DyadOrchestrator)

    Base.invokelatest(orchestrator.prepare_environment, package_path)
    pkg = Base.invokelatest(orchestrator.load_package, package_path; strategy = :include)

    # `strategy = :include` loads the module without binding it anywhere, so anything that
    # looks the package up by name — `list_analyses`, and the notebook's own cells — needs
    # the binding made by hand.
    pkg_sym = Symbol(nameof(pkg))
    isdefined(Main, pkg_sym) || Core.eval(Main, :($pkg_sym = $pkg))

    install_plotting(orchestrator, backend)

    imports = :(using ModelingToolkit, OrdinaryDiffEqDefault, Plots)
    Core.eval(@__MODULE__, imports)
    Core.eval(Main, imports)
    Base.invokelatest(getproperty(@__MODULE__, :Plots).backend, backend)

    return pkg
end

function install_orchestrator()
    isnothing(Base.identify_package("DyadOrchestrator")) || return nothing

    support_env = "@dyad-orchestrator-support"
    support_env in LOAD_PATH || splice!(LOAD_PATH, 2:1, [support_env])

    # `Pkg.activate` has no scoped form, so the caller's project is restored by hand.
    original_project = Base.active_project()
    try
        Pkg.activate(support_env[2:end]; shared = true)
        Pkg.add(Pkg.PackageSpec(; name = "DyadOrchestrator", version = "0.12.0"))
    finally
        Pkg.activate(original_project)
    end
    return nothing
end

# Only what the chosen backend needs: `add_package` writes into the package's `Project.toml`,
# which the Dyad compiler also owns.
function install_plotting(orchestrator, backend::Symbol)
    wanted = backend === :plotly ? ["Plots", "PlotlyBase", "PlotlyKaleido"] : ["Plots"]
    absent = filter(p -> isnothing(Base.identify_package(p)), wanted)
    isempty(absent) || Base.invokelatest(orchestrator.add_package, absent)
    return nothing
end

# ---------------------------------------------------------------------------------------
# Signal access
# ---------------------------------------------------------------------------------------

"""
    resolve(x, path) -> symbolic

Walk a dotted signal or parameter path (`"engine.limiter.y"`) down a system, problem or
solution and return the symbolic variable it names.

Symbols taken from an *uncompiled* system carry the root system's name as an extra prefix and
`remake` rejects them, so resolution always happens against the compiled system that a
problem or solution carries.
"""
resolve(x, path::Union{AbstractString, Symbol}) = resolve_in(system_of(x), path)

function resolve_in(sys, path::Union{AbstractString, Symbol})
    return reduce(split(String(path), "."); init = sys) do node, segment
        try
            getproperty(node, Symbol(segment))
        catch
            throw(ArgumentError("""
                No signal or parameter `$path` in this model (failed at `$segment`).

                A Dyad `structural parameter` — `with_I`, `with_D`, `theta_e` — is baked in
                when the component is constructed and is not reachable this way. Rebuild the
                model with a different value instead.
                """))
        end
    end
end

"""
    system_of(x) -> compiled System

The compiled system behind a solution, a problem, or a system.

Field lookups rather than `hasproperty`, because `getproperty` on an MTK system searches the
model hierarchy and a subcomponent named `f` would answer for the problem's function field.
"""
function system_of(x)
    x isa ModelingToolkit.AbstractSystem && return x
    hasfield(typeof(x), :prob) && return system_of(getfield(x, :prob))
    hasfield(typeof(x), :f) && return getfield(x, :f).sys
    throw(ArgumentError("cannot find a compiled system in a $(typeof(x))"))
end

"""
    signal(sol, path) -> (t, y)

The time base and the samples of one signal, as plain vectors.
"""
function signal(sol, path::Union{AbstractString, Symbol})
    return (collect(sol.t), collect(sol[resolve(sol, path)]))
end

# ---------------------------------------------------------------------------------------
# Parameter sweeps
# ---------------------------------------------------------------------------------------

"""
    Sweep

The result of [`sweep`](@ref): the compiled system, the parameter that was varied, the values
it took, and one solution per value. Iterating yields `(value, solution)` pairs.
"""
struct Sweep
    sys::Any
    param::Any
    name::String
    values::Vector
    sols::Vector
end

Base.length(sw::Sweep) = length(sw.values)
Base.iterate(sw::Sweep, state = 1) =
    state > length(sw) ? nothing : ((sw.values[state], sw.sols[state]), state + 1)

"""
    sweep(model, param, vals; tspan = nothing, alg = nothing, kwargs...) -> Sweep

Solve `model` once per value in `vals`, varying `param`.

`model` is an uncompiled system, a compiled system, or an `ODEProblem`; `param` is a dotted
path (`"controller.k"`) or a symbolic taken from the compiled system. `tspan` is required
unless `model` is already a problem. Remaining keywords go to the solver.

The model is compiled and the `ODEProblem` built exactly once, and each point `remake`s that
problem, which reuses the generated right-hand side rather than regenerating it. MTK
compilation dominates the cost of these models, so a version that rebuilt per point would
make an n-point sweep n times as slow — five notebooks sweep, and the whole notebook set is
executed end to end before each lecture.
"""
function sweep(model, param, vals; tspan = nothing, alg = nothing, kwargs...)
    prob = as_problem(model, tspan)
    sys = system_of(prob)
    sym = param isa Union{AbstractString, Symbol} ? resolve_in(sys, param) : param

    any(isequal(sym), ModelingToolkit.parameters(sys)) || throw(ArgumentError("""
        `$param` is not a tunable parameter of this model, so `remake` cannot vary it.

        Structural parameters (`with_I`, `with_D`, `theta_e`) and variables are not sweepable:
        a structural parameter changes the equations, so each value needs its own model.
        """))

    sols = map(vals) do v
        solve_problem(remake(prob; p = [sym => v]), alg; kwargs...)
    end

    return Sweep(sys, sym, last(split(string(sym), "₊")), collect(vals), sols)
end

function as_problem(model, tspan)
    model isa ModelingToolkit.AbstractSystem || return model
    isnothing(tspan) && throw(ArgumentError(
        "`tspan` is required when sweeping a system rather than an existing ODEProblem"))
    sys = ModelingToolkit.isscheduled(model) ? model : mtkcompile(model)
    return ODEProblem(sys, [], tspan)
end

solve_problem(prob, ::Nothing; kwargs...) = solve(prob; kwargs...)
solve_problem(prob, alg; kwargs...) = solve(prob, alg; kwargs...)

# ---------------------------------------------------------------------------------------
# Plot recipes
# ---------------------------------------------------------------------------------------

const SPEED_AXIS = (xlabel = "time [s]", ylabel = "speed [km/h]")
const TORQUE_AXIS = (xlabel = "time [s]", ylabel = "torque [N.m]")

"""
    plot_speed(sol; setpoint = nothing, sig = SPEED_KMH, label = "speed", kwargs...)

Speed against time, with the setpoint drawn as a dashed line when there is one.
"""
function plot_speed(sol; setpoint = nothing, sig = SPEED_KMH, label = "speed", kwargs...)
    t, y = signal(sol, sig)
    plt = Plots.plot(t, y; label, lw = 2, SPEED_AXIS..., kwargs...)
    draw_setpoint!(plt, setpoint)
    return plt
end

"""
    plot_sweep(sw; sig = SPEED_KMH, setpoint = nothing, name = sw.name, kwargs...)

The family of runs from a [`sweep`](@ref) on one axes, shaded along a colour ramp from the
lowest parameter value to the highest so the family reads as an ordering rather than as five
unrelated colours. Each legend entry is the parameter value that produced the curve.
"""
function plot_sweep(sw::Sweep; sig = SPEED_KMH, setpoint = nothing, name = sw.name, kwargs...)
    ramp = Plots.palette(:viridis, max(length(sw), 2))
    plt = Plots.plot(; SPEED_AXIS..., kwargs...)
    for (n, (value, sol)) in enumerate(sw)
        t, y = signal(sol, sig)
        Plots.plot!(plt, t, y; label = "$name = $(pretty(value))", color = ramp[n], lw = 2)
    end
    draw_setpoint!(plt, setpoint)
    return plt
end

"""
    plot_torque(sol; commanded = TORQUE_CMD, delivered = TORQUE_DELIVERED,
                limit = CAR.T_max, kwargs...)

Commanded and delivered torque on one axes, with the engine's torque limit drawn on.

The limit line is not decoration: a command far above it is the failure the lecture returns to
in notebooks 06 and 08, and it is invisible unless the ceiling is on the plot.
"""
function plot_torque(sol; commanded = TORQUE_CMD, delivered = TORQUE_DELIVERED,
        limit = CAR.T_max, kwargs...)
    plt = Plots.plot(; TORQUE_AXIS..., kwargs...)
    if !isnothing(commanded)
        t, y = signal(sol, commanded)
        Plots.plot!(plt, t, y; label = "commanded", lw = 2, color = :steelblue)
    end
    if !isnothing(delivered)
        t, y = signal(sol, delivered)
        Plots.plot!(plt, t, y; label = "delivered", lw = 2, color = :darkorange)
    end
    isnothing(limit) || Plots.hline!(plt, [limit];
        label = "limit $(pretty(limit)) N.m", ls = :dash, lw = 2, color = :firebrick)
    return plt
end

"""
    bracket_error!(plt, sol; setpoint, sig = SPEED_KMH, at = nothing)

Mark the steady-state error on an existing speed plot as a bracket between the settled value
and the setpoint, annotated with its size.

`at` is the time to draw the bracket at, and defaults to three quarters of the way through the
run, which is past settling for the step scenarios in this lecture.
"""
function bracket_error!(plt, sol; setpoint, sig = SPEED_KMH, at = nothing)
    t, y = signal(sol, sig)
    settled = settled_value(t, y)
    err = setpoint - settled
    x = isnothing(at) ? first(t) + 0.75 * (last(t) - first(t)) : at

    Plots.plot!(plt, [x, x], [settled, setpoint];
        label = "", lw = 2, color = :firebrick, marker = :hline, ms = 8)
    Plots.annotate!(plt, x, (settled + setpoint) / 2,
        Plots.text("  error $(pretty(err)) km/h", 9, :left, :firebrick))
    return plt
end

function draw_setpoint!(plt, setpoint)
    isnothing(setpoint) && return plt
    Plots.hline!(plt, [setpoint];
        label = "setpoint $(pretty(setpoint))", ls = :dash, lw = 2, color = :black)
    return plt
end

pretty(x::Real) = isinteger(x) ? string(Int(round(x))) : string(round(x; sigdigits = 3))
pretty(x) = string(x)

# ---------------------------------------------------------------------------------------
# Readouts
#
# Each takes either a solution or a bare `(t, y)` pair, so the arithmetic can be exercised
# against an analytically known curve without a model in the way.
# ---------------------------------------------------------------------------------------

"""
    steady_state_error(sol, setpoint; sig = SPEED_KMH, window = 0.1)
    steady_state_error(t, y, setpoint; window = 0.1)

Setpoint minus settled value, in the units of the signal. Positive means the loop settled
short, which is the sign a proportional controller always has against a load.

The settled value is the mean over the last `window` fraction of the run, so a solver's
uneven final sample does not set the answer on its own.
"""
steady_state_error(sol, setpoint; sig = SPEED_KMH, window = 0.1) =
    steady_state_error(signal(sol, sig)..., setpoint; window)

steady_state_error(t::AbstractVector, y::AbstractVector, setpoint; window = 0.1) =
    setpoint - settled_value(t, y; window)

function settled_value(t::AbstractVector, y::AbstractVector; window = 0.1)
    cutoff = last(t) - window * (last(t) - first(t))
    tail = @view y[searchsortedfirst(t, cutoff):end]
    return isempty(tail) ? last(y) : sum(tail) / length(tail)
end

"""
    overshoot(sol, setpoint; sig = SPEED_KMH, y0 = nothing)
    overshoot(t, y, setpoint; y0 = nothing)

Peak excursion past the setpoint, as a percentage of the commanded step. `y0` defaults to the
signal's initial value, which is the pre-step cruise speed in every scenario here.

Zero when the response never crosses the setpoint, so a sluggish run reports no overshoot
rather than a negative one.
"""
overshoot(sol, setpoint; sig = SPEED_KMH, y0 = nothing) =
    overshoot(signal(sol, sig)..., setpoint; y0)

function overshoot(t::AbstractVector, y::AbstractVector, setpoint; y0 = nothing)
    step = setpoint - (isnothing(y0) ? first(y) : y0)
    iszero(step) && throw(ArgumentError("overshoot is undefined for a zero-size step"))
    peak = step > 0 ? maximum(y) : minimum(y)
    return max(0.0, 100 * (peak - setpoint) / step)
end

"""
    rise_time(sol, setpoint; sig = SPEED_KMH, y0 = nothing, from = 0.1, to = 0.9)
    rise_time(t, y, setpoint; y0 = nothing, from = 0.1, to = 0.9)

Time to cross from `from` to `to` of the commanded step, by default the 10%-90% rise.

`NaN` when the response never reaches the upper level, which is the honest answer for a
proportional loop that settles short of its setpoint.
"""
rise_time(sol, setpoint; sig = SPEED_KMH, y0 = nothing, from = 0.1, to = 0.9) =
    rise_time(signal(sol, sig)..., setpoint; y0, from, to)

function rise_time(t::AbstractVector, y::AbstractVector, setpoint;
        y0 = nothing, from = 0.1, to = 0.9)
    start = isnothing(y0) ? first(y) : y0
    step = setpoint - start
    iszero(step) && throw(ArgumentError("rise time is undefined for a zero-size step"))
    rising = step > 0
    return crossing_time(t, y, start + to * step; rising) -
           crossing_time(t, y, start + from * step; rising)
end

"""
    crossing_time(t, y, level; rising = true) -> Float64

Time at which `y` first reaches `level`, linearly interpolated between the two samples that
bracket it. `NaN` if it never does.
"""
function crossing_time(t::AbstractVector, y::AbstractVector, level; rising = true)
    idx = findfirst(v -> rising ? v >= level : v <= level, y)
    isnothing(idx) && return NaN
    idx == 1 && return float(t[1])
    y0, y1 = y[idx - 1], y[idx]
    y1 == y0 && return float(t[idx])
    return t[idx - 1] + (level - y0) / (y1 - y0) * (t[idx] - t[idx - 1])
end

"""
    fopdt_fit(sol; output = SPEED_KMH, input = TORQUE_CMD, t0 = nothing, A = nothing)
    fopdt_fit(t, y, A, t0) -> (K, tau, theta)

Read the three FOPTD parameters off an open-loop step response, by the construction in
`materials/ControlTheory/tuning_methods.pdf` (p.1, Step 2):

    t2 = time at half the total output change B
    t3 = time at (1 - 1/e) of it
    t1 = (t2 - ln(2)*t3) / (1 - ln(2))
    K = B/A,  tau = t3 - t1,  theta = t1 - t0

The same document supplies the Cohen-Coon table that notebook 08 feeds these three numbers
into, so the fit and the tuning rule rest on one definition rather than two that happen to
agree.

The document writes the second landmark as `0.632`, which is `1 - 1/e` rounded. The `t1`
formula multiplies an error in that landmark by `tau*ln(2)/(1 - ln(2))`, about 2.26 times the
time constant, so on this car's 60 s `tau` the rounding alone reports 0.045 s of dead time.
That is the size of `theta_e` itself, so the exact constant is used here.

`A` is the size of the input step and `t0` the time it was applied; both are measured off the
`input` signal when not given.
"""
function fopdt_fit(sol; output = SPEED_KMH, input = TORQUE_CMD, t0 = nothing, A = nothing)
    t, y = signal(sol, output)
    if isnothing(A) || isnothing(t0)
        measured_t0, measured_A = step_of(signal(sol, input)...)
        t0 = something(t0, measured_t0)
        A = something(A, measured_A)
    end
    return fopdt_fit(t, y, A, t0)
end

function fopdt_fit(t::AbstractVector, y::AbstractVector, A::Real, t0::Real)
    iszero(A) && throw(ArgumentError("a zero-size input step carries no gain information"))

    y_before = y[clamp(searchsortedlast(t, t0), 1, length(y))]
    B = settled_value(t, y) - y_before
    rising = B > 0

    t2 = crossing_time(t, y, y_before + 0.5B; rising)
    t3 = crossing_time(t, y, y_before + (1 - exp(-1)) * B; rising)
    (isnan(t2) || isnan(t3)) && throw(ArgumentError(
        "the response never settles within the run: extend the simulation window"))

    t1 = (t2 - log(2) * t3) / (1 - log(2))
    return (B / A, t3 - t1, t1 - t0)
end

"""
    step_of(t, u) -> (t0, A)

Time and size of the single step in an input signal, taken at its largest sample-to-sample
jump.
"""
function step_of(t::AbstractVector, u::AbstractVector)
    length(u) < 2 && throw(ArgumentError("input signal has no step in it"))
    idx = argmax(abs.(diff(u)))
    return (float(t[idx]), last(u) - first(u))
end

end # module Lecture01Support
