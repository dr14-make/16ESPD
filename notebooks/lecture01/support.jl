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
using Markdown

export setup, CAR,
    sweep, Sweep, rerun,
    plot_speed, plot_sweep, plot_torque, bracket_error!,
    save_figure, deck_figures,
    show_dyad, dyad_source, dyad_definitions,
    steady_state_error, overshoot, rise_time, crossing_time, fopdt_fit,
    signal, resolve, solution_of

# ---------------------------------------------------------------------------------------
# Plant parameters
# ---------------------------------------------------------------------------------------

"""
    CAR

The L0 vehicle parameter set, as tabulated in `docs/HANDOVER.md`.

Primitive quantities only. Everything derived from them — drag coefficient, rolling force,
tractive force limit, terminal speed, cruise torque — is arithmetic the notebooks perform in
front of the reader.

`theta_e` is the value the Dyad models ship (HANDOVER Risk 1), so read it from here rather
than writing it into a cell.

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
    theta_e = 0.3,
    g = 9.80665,
)

"""
    SPEED_KMH, TORQUE_CMD, TORQUE_DELIVERED

Default signal paths, relative to the root of a scenario analysis.

A `TransientAnalysis` runs a harness, not the plant — `Vehicle.CarPlant` has unconnected
`RealInput` ports and cannot be simulated on its own — so the root of every solution is the
harness and the plant is a subcomponent of it. These defaults assume the harness names its
plant `plant` and its torque source `cmd`; any scenario that departs from that passes its own
path to the `sig`, `commanded` or `delivered` keyword.
"""
const SPEED_KMH = "plant.v_kmh"
const TORQUE_CMD = "cmd.y"
const TORQUE_DELIVERED = "plant.engine.limiter.y"

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

    # A `using` executed from inside a running function creates its bindings in a world this
    # method cannot see, so everything that touches those bindings is a separate method
    # reached through `invokelatest`, which compiles it in the current world.
    Base.invokelatest(prepare_environment, package_path)
    check_distribution()
    pkg = Base.invokelatest(load_package, package_path)

    # `strategy = :include` loads the module without binding it anywhere, so anything that
    # looks the package up by name — `list_analyses`, and the notebook's own cells — needs
    # the binding made by hand.
    pkg_sym = Symbol(nameof(pkg))
    isdefined(Main, pkg_sym) || Core.eval(Main, :($pkg_sym = $pkg))

    Base.invokelatest(install_plotting, backend)

    imports = :(using ModelingToolkit, OrdinaryDiffEqDefault, Plots)
    Core.eval(@__MODULE__, imports)
    Core.eval(Main, imports)
    Base.invokelatest(select_backend, backend)
    Base.invokelatest(apply_house_style)

    return pkg
end

prepare_environment(package_path) = DyadOrchestrator.prepare_environment(package_path)
load_package(package_path) = DyadOrchestrator.load_package(package_path; strategy = :include)

"""
    check_distribution()

Fail before loading the library if this Julia cannot see the project's dependencies.

The lecture's `Manifest.toml` is resolved against the Dyad distribution, so on a stock Julia
the packages resolve by name but are not installed. Loading the library then dies several
frames deep inside `generated/internals.jl` on whichever dependency happens to be imported
first, which says nothing about the real cause — the wrong kernel.
"""
function check_distribution()
    absent = filter(("ModelingToolkit", "BlockComponents", "TranslationalComponents")) do name
        id = Base.identify_package(name)
        isnothing(id) || isnothing(Base.locate_package(id))
    end
    isempty(absent) && return nothing

    error("""
        This Julia cannot load the project's dependencies: $(join(absent, ", ")) \
        resolve by name but are not installed.

            running Julia $(VERSION)
            from $(Sys.BINDIR)

        The notebooks need the Dyad distribution — the `dyad-3.3.0` juliaup channel that
        `.vscode/settings.json` names in `julia.executablePath`, which is Julia 1.12.7. The
        juliaup default channel is `release`, Julia 1.12.6, and its depot does not have these
        packages installed.

        In VS Code: use the kernel picker at the top right of the notebook and choose the
        Julia 1.12.7 kernel rather than 1.12.6.
        """)
end

select_backend(backend::Symbol) = Plots.backend(backend)

"""
    apply_house_style()

Set the figure defaults every plot in this lecture inherits: a 16:9 landscape canvas and
margins wide enough for the axis labels.

The deck caps a figure by its height, so a landscape default is what keeps an exported figure
legible on the slide it lands on. The margins are not cosmetic either — at the default of
zero, a two-digit y-axis and its label are cropped by the edge of the canvas.
"""
function apply_house_style()
    Plots.default(;
        size = (960, 540),
        left_margin = 7Plots.mm,
        bottom_margin = 6Plots.mm,
        top_margin = 3Plots.mm,
        right_margin = 5Plots.mm,
        titlefontsize = 12,
        legendfontsize = 9,
    )
    return nothing
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
function install_plotting(backend::Symbol)
    wanted = backend === :plotly ? ["Plots", "PlotlyBase", "PlotlyKaleido"] : ["Plots"]
    absent = filter(p -> isnothing(Base.identify_package(p)), wanted)
    isempty(absent) || DyadOrchestrator.add_package(absent)
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

                Available there: $(join(available_names(node), ", "))

                A Dyad `structural parameter` — `with_I`, `with_D`, `theta_e` — is baked in
                when the component is constructed and is not reachable this way either;
                rebuild the model with a different value instead of reaching for it here.
                """))
        end
    end
end

"""
    available_names(node) -> Vector{String}

Subcomponents, unknowns and parameters reachable one level down from `node`, for the error
message above. A wrong signal path is the most common mistake a notebook makes, and the fix
is almost always visible in this list.
"""
function available_names(node)
    node isa ModelingToolkit.AbstractSystem || return String[]
    names = String[]
    append!(names, string.(nameof.(ModelingToolkit.get_systems(node))))
    for v in vcat(ModelingToolkit.unknowns(node), ModelingToolkit.parameters(node))
        name = replace(string(v), "(t)" => "")
        occursin("₊", name) || push!(names, name)
    end
    return sort!(unique!(names))
end

"""
    solution_of(x) -> ODESolution

The solver result behind a Dyad analysis result, or the solution itself.

A Dyad analysis returns an `AbstractAnalysisSolution` that wraps the solution in `.sol`.
Everything downstream works on the solution, so the unwrapping happens once, here.

Field lookups rather than `hasproperty` throughout this section, because `getproperty` on an
MTK system searches the model hierarchy and a subcomponent named `sol` or `f` would answer
for the wrapper's own field.
"""
solution_of(x) = hasfield(typeof(x), :sol) ? getfield(x, :sol) : x

"""
    system_of(x) -> compiled System

The compiled system behind an analysis result, a solution, a problem, or a system.
"""
function system_of(x)
    x isa ModelingToolkit.AbstractSystem && return x
    hasfield(typeof(x), :sol) && return system_of(getfield(x, :sol))
    hasfield(typeof(x), :prob) && return system_of(getfield(x, :prob))
    hasfield(typeof(x), :f) && return getfield(x, :f).sys
    throw(ArgumentError("cannot find a compiled system in a $(typeof(x))"))
end

"""
    problem_of(x) -> ODEProblem

The problem behind an analysis result or a solution. This is what [`sweep`](@ref) varies, so
that a sweep started from a Dyad analysis still compiles the model only once: re-running the
analysis per point would recompile it every time.
"""
function problem_of(x)
    sol = solution_of(x)
    hasfield(typeof(sol), :prob) && return getfield(sol, :prob)
    throw(ArgumentError("cannot find an ODEProblem in a $(typeof(x))"))
end

"""
    signal(sol, path) -> (t, y)

The time base and the samples of one signal, as plain vectors. Accepts a Dyad analysis result
or a bare solution.
"""
function signal(sol, path::Union{AbstractString, Symbol})
    s = solution_of(sol)
    return (collect(s.t), collect(s[resolve(s, path)]))
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

`model` is a Dyad analysis result, an `ODEProblem`, or an uncompiled or compiled system;
`param` is a dotted path (`"controller.k"`) or a symbolic taken from the compiled system.
`tspan` is required only when `model` is a system. Remaining keywords go to the solver.

The model is compiled and the `ODEProblem` built exactly once, and each point `remake`s that
problem, which reuses the generated right-hand side rather than regenerating it. MTK
compilation dominates the cost of these models, so a version that rebuilt per point would
make an n-point sweep n times as slow — five notebooks sweep, and the whole notebook set is
executed end to end before each lecture.
"""
function sweep(model, param, vals; tspan = nothing, alg = nothing, kwargs...)
    prob = as_problem(model, tspan)
    sys = system_of(prob)
    sym = tunable(sys, param)

    sols = map(vals) do v
        solve_problem(remake(prob; p = [sym => v]), alg; kwargs...)
    end

    return Sweep(sys, sym, last(split(string(sym), "₊")), collect(vals), sols)
end

"""
    rerun(model, overrides::Pair...; tspan = nothing, alg = nothing, kwargs...) -> solution

Re-solve `model` with `overrides` applied, reusing its compiled right-hand side exactly as
[`sweep`](@ref) does.

`model` is anything `sweep` accepts and each override pairs a dotted path or a symbolic with
its new value. This is the route to a parameter the scenario does not expose as one of its
own — `LimPID`'s derivative-filter initial state `xd0`, which `CruiseLoop` leaves at the
library default. The result is itself a valid `sweep` input, so a sweep can vary its own
parameter on top of these.
"""
function rerun(model, overrides::Pair...; tspan = nothing, alg = nothing, kwargs...)
    prob = as_problem(model, tspan)
    sys = system_of(prob)
    p = [tunable(sys, first(o)) => last(o) for o in overrides]
    return solve_problem(remake(prob; p), alg; kwargs...)
end

"""
    tunable(sys, param) -> symbolic

Resolve `param` against `sys` and check that `remake` can vary it.
"""
function tunable(sys, param)
    sym = param isa Union{AbstractString, Symbol} ? resolve_in(sys, param) : param
    any(isequal(sym), ModelingToolkit.parameters(sys)) || throw(ArgumentError("""
        `$param` is not a tunable parameter of this model, so `remake` cannot vary it.

        Structural parameters (`with_I`, `with_D`, `theta_e`) and variables are not sweepable:
        a structural parameter changes the equations, so each value needs its own model.
        """))
    return sym
end

function as_problem(model, tspan)
    if model isa ModelingToolkit.AbstractSystem
        isnothing(tspan) && throw(ArgumentError(
            "`tspan` is required when sweeping a system rather than an existing ODEProblem"))
        sys = ModelingToolkit.isscheduled(model) ? model : mtkcompile(model)
        return ODEProblem(sys, [], tspan)
    end
    hasfield(typeof(model), :sol) && return problem_of(model)
    hasfield(typeof(model), :prob) && return problem_of(model)
    return model
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
    # One shade more than the family needs, with the brightest dropped: viridis ends in a
    # yellow that is unreadable on the white background a slide and a handout both have.
    ramp = Plots.palette(:viridis, max(length(sw), 2) + 1)
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
# Dyad source
#
# A notebook that plots a model's behaviour without ever showing the model asks the reader to
# take the physics on trust. These pull the declaration straight out of `dyad/`, so the source
# is carried in the executed output and a student reading the committed notebook sees it
# without needing the repository checked out.
# ---------------------------------------------------------------------------------------

"""
    DYAD_DIR

The Dyad sources, which are the authority on every model these notebooks run.
"""
const DYAD_DIR = normpath(@__DIR__, "..", "..", "dyad")

const _DECL = r"^(?:partial\s+|test\s+|external\s+)*(?:component|analysis|connector|type)\s+([A-Za-z_]\w*)"

"""
    dyad_definitions() -> Vector{String}

Every definition name declared under `dyad/`, sorted. Useful when a name in a notebook no
longer matches the models.
"""
function dyad_definitions()
    names = String[]
    for (root, _, files) in walkdir(DYAD_DIR), f in files
        endswith(f, ".dyad") || continue
        for line in eachline(joinpath(root, f))
            m = match(_DECL, line)
            isnothing(m) || push!(names, m.captures[1])
        end
    end
    return sort!(unique!(names))
end

"""
    dyad_source(name) -> (path, first_line, text)

The Dyad declaration of `name`, lifted from `dyad/` with its docstring attached.

A `.dyad` file holds several definitions, so the block runs from the declaration — including
any `\"\"\"` docstring immediately above it — to the `end` that closes it at column zero.
"""
function dyad_source(name::AbstractString)
    for (root, _, files) in walkdir(DYAD_DIR), f in files
        endswith(f, ".dyad") || continue
        path = joinpath(root, f)
        lines = readlines(path)
        start = findfirst(l -> (m = match(_DECL, l)) !== nothing && m.captures[1] == name, lines)
        isnothing(start) && continue
        # Take the docstring above the declaration when there is one.
        first_line = start
        if start > 1 && rstrip(lines[start - 1]) == "\"\"\""
            opening = findlast(i -> startswith(lines[i], "\"\"\""), 1:(start - 2))
            isnothing(opening) || (first_line = opening)
        end
        stop = findfirst(i -> rstrip(lines[i]) == "end", start:length(lines))
        isnothing(stop) && throw(ErrorException("`$name` in $path is not closed by `end` at column 0"))
        stop = start + stop - 1
        rel = relpath(path, normpath(DYAD_DIR, ".."))
        return (rel, first_line, join(lines[first_line:stop], "\n"))
    end
    near = filter(n -> occursin(lowercase(name), lowercase(n)), dyad_definitions())
    hint = isempty(near) ? "" : "\nDid you mean: " * join(first(near, 5), ", ")
    throw(ArgumentError("no Dyad definition named `$name` under dyad/.$hint"))
end

"""
    show_dyad(name)

Render the Dyad declaration of `name` in the notebook, headed by the file and line it came
from so a reader can go and edit the real thing.
"""
function show_dyad(name::AbstractString)
    rel, line, text = dyad_source(name)
    return Markdown.parse("**`$name`** — [`$rel`]($(joinpath("..", "..", rel))) line $line\n\n```julia\n$text\n```")
end

# ---------------------------------------------------------------------------------------
# Figure export
# ---------------------------------------------------------------------------------------

"""
    DECK_DIR

The reveal.js deck that consumes these figures. Its `index.html` is the authoritative list of
figure names: each slot is an `<img src="assets/figures/...">` that renders as a hatched
placeholder until the file exists.
"""
const DECK_DIR = normpath(@__DIR__, "..", "..", "docs", "slides", "lecture-01")

const _DECK_FIGURES = Ref{Union{Nothing, Set{String}}}(nothing)

"""
    deck_figures() -> Set{String}

Every figure file the deck references, read out of its markup. Empty when the deck is absent,
which disables the name check in [`save_figure`](@ref) rather than failing on its absence.
"""
function deck_figures()
    cached = _DECK_FIGURES[]
    isnothing(cached) || return cached
    index = joinpath(DECK_DIR, "index.html")
    names = isfile(index) ?
        Set{String}(m.captures[1] for m in eachmatch(r"assets/figures/([\w\-.]+)", read(index, String))) :
        Set{String}()
    _DECK_FIGURES[] = names
    return names
end

"""
    save_figure(plt, name) -> String

Write `plt` into the deck's figure directory and return the path.

`name` is the deck's own slug — `save_figure(plt, "03-gain-family")` — and `.svg` is appended
when no extension is given. SVG stays sharp on a projector and in the deck's `?print-pdf`
handout.

The name is checked against the slots the deck actually references, because a typo is
otherwise silent in both directions: the notebook writes a file nothing loads, and the slide
goes on rendering a placeholder. Near misses are listed in the error.
"""
function save_figure(plt, name::AbstractString)
    file = any(endswith(name, e) for e in (".svg", ".png")) ? String(name) : name * ".svg"
    expected = deck_figures()
    if !isempty(expected) && file ∉ expected
        stem = String(first(split(file, '.')))
        parts = [p for p in split(stem, '-') if length(p) > 3]
        near = sort!([f for f in expected if any(occursin(p, f) for p in parts)])
        hint = isempty(near) ? "" : "\nDid you mean: " * join(first(near, 5), ", ")
        throw(ArgumentError("`$file` is not a figure slot in the deck; nothing would load it.$hint"))
    end
    dir = joinpath(DECK_DIR, "assets", "figures")
    mkpath(dir)
    path = joinpath(dir, file)
    Plots.savefig(plt, path)
    return path
end

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
