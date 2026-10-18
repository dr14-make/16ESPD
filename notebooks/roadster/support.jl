"""
Rigs, readouts and plot recipes for the Roadster presentation notebook.

Include after `Lecture01Support`, into the same module, and after `setup()`, which loads the
modeling and plotting packages this module uses:

    include("support.jl")
    using .RoadsterSupport

Every Dyad analysis is run once at load to build its problem. A slider then calls
[`solve_with`](@ref), which `remake`s that problem and solves it with the analysis's own
tolerances, so a move costs milliseconds rather than a model rebuild.
"""
module RoadsterSupport

using Markdown
using ModelingToolkit
using OrdinaryDiffEqDefault: remake, solve
using DyadInterface: symbolic_container
using Plots
using PlutoUI: details
using ..Lecture01Support: dyad_source

export V60, G0, LAYOUTS, Rig, solve_with, signal_path, first_crossing, t60, air_used,
    binding_limit, blowdown_marks, hop_apex, hover_time, limit_map,
    nozzle_closed_form, blowdown_closed_form, hover_closed_form, fan_power_closed_form,
    scoreboard, verdict_row, html_table, dyad_fold, car_panel_style, fmt

"60 mph in m/s."
const V60 = 26.8224
"Standard gravity."
const G0 = 9.80665

"Drive layouts as the launch analysis parameterizes them."
const LAYOUTS = Dict(
    "RWD" => (share = 0.55, h_over_L = 0.17),
    "AWD" => (share = 1.0, h_over_L = 0.0),
)

"""
    Rig(name, analysis; kwargs...)

The problem behind `analysis(; kwargs...)`, its solution over the analysis's full time span as
`default`, and the analysis's tolerances. `name` labels the rig.

The analysis is run only to `start + 1e-6`. With automatic discontinuity detection, a solve
leaves its callbacks' discrete state in the problem's parameters, and a `remake` of a problem
solved to the end can start with its branches where that solve left them. A problem solved for
a microsecond restarts from the initial state.
"""
struct Rig
    name::Symbol
    prob::Any
    sys::Any
    default::Any
    solve_kwargs::NamedTuple
end

function Rig(name::Symbol, analysis; kwargs...)
    spec = getfield(parentmodule(analysis), Symbol(nameof(analysis), :Spec))(; kwargs...)
    result = analysis(; progress = false, kwargs..., stop = spec.start + 1e-6)
    prob = remake(result.sol.prob; tspan = (spec.start, spec.stop))
    solve_kwargs = (abstol = spec.abstol, reltol = spec.reltol)
    return Rig(name, prob, symbolic_container(result), solve(prob; solve_kwargs...), solve_kwargs)
end

Base.show(io::IO, rig::Rig) = print(io, "Rig(:", rig.name, ")")

"Walk a dotted path down a compiled system."
signal_path(sys, path::AbstractString) =
    reduce((node, s) -> getproperty(node, Symbol(s)), split(path, "."); init = sys)

function parameter_symbol(rig::Rig, key::Symbol)
    sym = getproperty(rig.sys, key)
    any(isequal(sym), ModelingToolkit.parameters(rig.sys)) ||
        throw(ArgumentError("`$key` is not a tunable parameter of the $(rig.name) rig"))
    return sym
end

"""
    solve_with(rig; kwargs...) -> solution

`remake` the rig's problem with `kwargs` as values of the analysis's top-level parameters and
solve it. Every parameter not named keeps the value the rig was built with.
"""
function solve_with(rig::Rig; kwargs...)
    p = [parameter_symbol(rig, k) => float(v) for (k, v) in kwargs]
    return solve(remake(rig.prob; p); rig.solve_kwargs...)
end

# ---------------------------------------------------------------------------------------
# Readouts
# ---------------------------------------------------------------------------------------

"A number for a slide: rounded to `digits`, or a dash when it is not finite."
fmt(x, digits = 2) = !isfinite(x) ? "—" : digits == 0 ? string(round(Int, x)) : string(round(x; digits))

"First time `signal` reaches `target`, linearly interpolated between solver steps; `Inf` if never."
function first_crossing(sol, signal, target)
    values = sol[signal]
    i = findfirst(>=(target), values)
    i === nothing && return Inf
    i == firstindex(values) && return sol.t[i]
    t0, t1 = sol.t[i-1], sol.t[i]
    y0, y1 = values[i-1], values[i]
    return t0 + (target - y0) * (t1 - t0) / (y1 - y0)
end

"0–60 mph time of a launch solution."
t60(sol, sys) = first_crossing(sol, sys.v, V60)

"Air mass drawn from the tank between t = 0 and `t`."
air_used(sol, sys, t; tank = "tank") =
    sol(0.0, idxs = signal_path(sys, tank).m_g) - sol(t, idxs = signal_path(sys, tank).m_g)

"""
    binding_limit(sol, sys; until) -> NamedTuple

Share of `0..until` during which each limit sets the delivered wheel torque: the traction
request (the tire), the torque ceiling, or the power ceiling.
"""
function binding_limit(sol, sys; until, samples = 400)
    ts = range(0.0, until; length = samples)
    tau = sol(ts, idxs = sys.motor.tau).u
    request = sol(ts, idxs = sys.motor.tau_cmd).u
    w = sol(ts, idxs = sys.motor.w).u
    T_max, P_max, w_eps = sol.ps[sys.motor.T_max], sol.ps[sys.motor.P_max], sol.ps[sys.motor.w_eps]
    caps = [(request[i], T_max, P_max / max(w[i], w_eps)) for i in eachindex(ts)]
    which = [argmin(c) for c in caps]
    share(k) = count(==(k), which) / samples
    return (tire = share(1), torque = share(2), power = share(3))
end

"""
    blowdown_marks(sol, sys; nozzle = "nozzle") -> (F0, t80, t50)

Initial thrust and the times at which thrust first falls below 80 % and 50 % of it. Thrust only
falls during a wide-open blowdown, so each time is bracketed on the solver steps and then
bisected on the interpolant.
"""
function blowdown_marks(sol, sys; nozzle = "nozzle")
    F = signal_path(sys, nozzle).F
    f = sol[F]
    F0 = f[1]
    function below(level)
        i = findfirst(<(level * F0), f)
        i === nothing && return Inf
        lo, hi = sol.t[i-1], sol.t[i]
        for _ in 1:40
            mid = (lo + hi) / 2
            sol(mid, idxs = F) < level * F0 ? (hi = mid) : (lo = mid)
        end
        return hi
    end
    return (; F0, t80 = below(0.8), t50 = below(0.5))
end

"Highest altitude of a hop, on a dense grid between solver steps."
function hop_apex(sol, sys; path = "hop.altitude", samples = 4001)
    ts = range(sol.t[1], sol.t[end]; length = samples)
    hs = sol(ts, idxs = signal_path(sys, path)).u
    i = argmax(hs)
    return (apex = hs[i], t_apex = ts[i])
end

"""
    hover_time(sol, sys) -> Float64

Time at which the hover valve saturates after the car reaches its altitude target. Past that
point the tank cannot hold `m·g` and the car sinks. `NaN` if the car never climbs.
"""
function hover_time(sol, sys)
    ts = range(sol.t[1], sol.t[end]; length = 30_001)
    altitude = sol(ts, idxs = sys.hover.altitude).u
    command = sol(ts, idxs = sys.hover.command).u
    i_up = findfirst(>=(0.95 * sol.ps[sys.target]), altitude)
    i_up === nothing && return NaN
    i_sat = findnext(>=(1), command, i_up)
    return i_sat === nothing ? Inf : ts[i_sat]
end

# ---------------------------------------------------------------------------------------
# Closed forms
# ---------------------------------------------------------------------------------------

"Air and nozzle constants shared by the closed forms; the Dyad `ColdGasNozzle` and `AirTank` defaults."
const AIR = (gamma = 1.4, R = 287.05, c_p = 1005.0, p_a = 101325.0, T0 = 293.15,
    A_t = 1.286e-3, p_close = 2e5)

"Choked mass flow, exhaust speed and thrust at tank state `(p, T)`, throat `A_t`."
function nozzle_closed_form(p, T; A_t = AIR.A_t)
    (; gamma, R, c_p, p_a) = AIR
    mdot = A_t * p * sqrt(gamma / (R * T)) * (2 / (gamma + 1))^((gamma + 1) / (2 * (gamma - 1)))
    v_e = sqrt(2 * c_p * T * (1 - (p_a / p)^((gamma - 1) / gamma)))
    return (; mdot, v_e, F = mdot * v_e)
end

"""
    blowdown_closed_form(t; p0, V, n, A_t) -> NamedTuple

Thrust of a wide-open polytropic blowdown at time `t`, without simulation. With `x = m/m0`,
choked flow gives `ṁ = ṁ0·x^((n+1)/2)`, so `dx/dt = −x^((n+1)/2)/τ` with `τ = m0/ṁ0`, which
integrates in closed form. Zero once the tank falls below the valve cutoff.
"""
function blowdown_closed_form(t; p0 = 380e5, V = 0.6, n = 1.4, A_t = AIR.A_t)
    m0 = p0 * V / (AIR.R * AIR.T0)
    tau = m0 / nozzle_closed_form(p0, AIR.T0; A_t).mdot
    beta = (n + 1) / 2
    x = n == 1 ? exp(-t / tau) : (1 + (beta - 1) * t / tau)^(-1 / (beta - 1))
    p, T = p0 * x^n, AIR.T0 * x^(n - 1)
    p < AIR.p_close && return (; x, p, F = 0.0, m = m0 * x)
    return (; x, p, F = nozzle_closed_form(p, T; A_t).F, m = m0 * x)
end

"""
    hover_closed_form(m; p0, V, n) -> seconds

Quasi-steady hover endurance: the flow that holds `m·g` is `ṁ = m·g/v_e`, so the time is
`(m0/(m·g))·∫ v_e(x) dx` from the mass fraction at which full-open thrust drops below `m·g` up
to 1.
"""
function hover_closed_form(m; p0 = 380e5, V = 0.6, n = 1.4, A_t = AIR.A_t, intervals = 4000)
    m0 = p0 * V / (AIR.R * AIR.T0)
    state(x) = nozzle_closed_form(p0 * x^n, AIR.T0 * x^(n - 1); A_t)
    state(1.0).F < m * G0 && return 0.0
    lo, hi = 1e-6, 1.0
    for _ in 1:60
        mid = (lo + hi) / 2
        state(mid).F >= m * G0 ? (hi = mid) : (lo = mid)
    end
    xs = range(hi, 1.0; length = intervals + 1)
    ve = [state(x).v_e for x in xs]
    integral = step(xs) * (sum(ve) - (ve[1] + ve[end]) / 2)
    return m0 * integral / (m * G0)
end

"Fan shaft power to hold `dp` under a skirt with gap `gap`; the `SuctionFan` defaults."
fan_power_closed_form(dp, gap; C_d = 0.6, perimeter = 10.0, rho = 1.2, eta = 0.6) =
    C_d * perimeter * gap * sqrt(2 * dp / rho) * dp / eta

# ---------------------------------------------------------------------------------------
# Plots
# ---------------------------------------------------------------------------------------

"""
    limit_map(sol, sys; until, title) -> Plot

Force at the wheel against speed: the tire line `mu_A·F_z`, the torque cap `T_max/r`, the
power cap `P_max/(ω·r)` and the delivered tire force. The lowest curve is the binding limit.
"""
function limit_map(sol, sys; until, title = "Which limit binds?")
    ts = range(0.0, until; length = 400)
    v = sol(ts, idxs = sys.v).u
    Fz = sol(ts, idxs = sys.axle.F_z).u
    Fx = sol(ts, idxs = sys.wheel.F_x).u
    w = sol(ts, idxs = sys.motor.w).u
    r = sol.ps[sys.radius]
    mu = sol.ps[sys.mu_A]
    T_max, P_max = sol.ps[sys.motor.T_max], sol.ps[sys.motor.P_max]
    kN(x) = x ./ 1e3
    p = plot(v, kN(mu .* Fz); lw = 2, color = :seagreen, label = "tire limit μ_A·F_z",
        xlabel = "speed [m/s]", ylabel = "force at the wheel [kN]", title,
        legend = :outerright, xlims = (0, V60 * 1.02), ylims = (0, max(60, 1.15 * maximum(kN(mu .* Fz)))))
    hline!(p, [T_max / r / 1e3]; lw = 2, color = :darkorange, label = "torque cap T_max/r")
    plot!(p, v, kN(P_max ./ (max.(w, 1.0) .* r)); lw = 2, color = :purple,
        label = "power cap P_max/(ω·r)")
    plot!(p, v, kN(Fx); lw = 4, color = :black, alpha = 0.6, label = "delivered")
    vline!(p, [V60]; color = :gray, ls = :dot, label = "60 mph")
    return p
end

# ---------------------------------------------------------------------------------------
# Scoreboard and display
# ---------------------------------------------------------------------------------------

const CHIP = Dict(
    :yes => ("yes", "#2e7d32"),
    :no => ("no", "#c62828"),
    :pending => ("—", "#757575"),
)

"""
    verdict_row(claim, tesla, model, verdict) -> NamedTuple

One scoreboard row. `verdict` is `:yes`, `:no` or `:pending`.
"""
verdict_row(claim, tesla, model, verdict::Symbol) = (; claim, tesla, model, verdict)

# Pluto styles output tables as data: monospaced and right-aligned. These tables hold prose.
const TABLE_STYLE = """
<style>
pluto-output table.roadster-table { font-family: inherit !important; font-size: 0.92rem;
  width: 100%; border-collapse: collapse; table-layout: fixed; margin: 0.4em 0; }
pluto-output table.roadster-table th, pluto-output table.roadster-table td {
  font-family: inherit !important; text-align: left !important; vertical-align: top;
  white-space: normal !important; overflow-wrap: anywhere; padding: 3px 8px; }
pluto-output table.roadster-table td.num, pluto-output table.roadster-table th.num {
  text-align: right !important; font-variant-numeric: tabular-nums; }
pluto-output table.roadster-table tbody tr:nth-child(odd) { background: #8881; }
pluto-output table.roadster-table p { margin: 0; }
</style>
"""

inline_html(x) = replace(strip(Markdown.html(Markdown.parse(string(x)))), r"^<p>|</p>$" => "")

"""
    html_table(header, rows; widths, numeric) -> HTML

A left-aligned table in the slide's text font. Each cell is inline Markdown. `widths` gives CSS
column widths; the columns in `numeric` are right-aligned.
"""
function html_table(header, rows; widths = nothing, numeric = Int[])
    cls(j) = j in numeric ? " class=\"num\"" : ""
    cols = widths === nothing ? "" :
        "<colgroup>" * join("<col style=\"width:$w\">" for w in widths) * "</colgroup>"
    head = join("<th$(cls(j))>$(inline_html(h))</th>" for (j, h) in enumerate(header))
    body = join(("<tr>" * join("<td$(cls(j))>$(inline_html(c))</td>" for (j, c) in enumerate(r)) *
                 "</tr>" for r in rows), "\n")
    return HTML("""<table class="roadster-table">$cols<thead><tr>$head</tr></thead>
    <tbody>$body</tbody></table>$TABLE_STYLE""")
end

"""
    scoreboard(rows) -> HTML

The claim-against-model panel, fixed in the bottom-right corner so it stays in view in present
mode. It starts collapsed to its summary line and sits above the car panel, which
[`car_panel_style`](@ref) pins below it.
"""
function scoreboard(rows)
    done = count(r -> r.verdict != :pending, rows)
    yes = count(r -> r.verdict == :yes, rows)
    body = join(map(rows) do r
        label, color = CHIP[r.verdict]
        """<tr><td>$(inline_html(r.claim))</td><td>$(inline_html(r.tesla))</td>
        <td><b>$(inline_html(r.model))</b></td>
        <td><span class="chip" style="background:$color">$label</span></td></tr>"""
    end, "\n")
    return HTML("""
    <aside class="roadster-scoreboard">
    <details><summary><b>Claim vs model</b> · $yes of $done possible</summary>
    <table class="roadster-table"><colgroup><col style="width:36%"><col style="width:24%">
    <col style="width:28%"><col style="width:12%"></colgroup>
    <thead><tr><th>claim</th><th>Tesla</th><th>model</th><th></th></tr></thead>
    <tbody>$body</tbody></table></details>
    </aside>
    $TABLE_STYLE
    <style>
    aside.roadster-scoreboard { position: fixed; right: 12px; bottom: 64px; width: 380px;
      max-height: 55vh; overflow-y: auto; z-index: 50; line-height: 1.2;
      background: var(--main-bg-color, white); border: 1px solid #9994; border-radius: 8px;
      padding: 4px 8px; box-shadow: 0 2px 8px #0003; }
    aside.roadster-scoreboard table.roadster-table { font-size: 10.5px; margin: 4px 0 0 0; }
    aside.roadster-scoreboard table.roadster-table td,
    aside.roadster-scoreboard table.roadster-table th { padding: 1px 3px; }
    aside.roadster-scoreboard .chip { color: white; border-radius: 8px; padding: 0 6px; }
    aside.roadster-scoreboard summary { cursor: pointer; font-size: 12px; }
    </style>
    """)
end

"""
    car_panel_style(cell_id) -> HTML

CSS that pins the output of the car-slider cell `cell_id` under the scoreboard. The sliders
cannot live in the scoreboard cell itself: every result the scoreboard shows depends on them.
"""
car_panel_style(cell_id::AbstractString) = HTML("""
<style>
pluto-cell[id="$cell_id"] > pluto-output { position: fixed; right: 12px; bottom: 12px;
  width: 380px; z-index: 51; font-size: 12px; background: var(--main-bg-color, white);
  border: 1px solid #9994; border-radius: 8px; padding: 4px 8px; box-shadow: 0 2px 8px #0003; }
pluto-cell[id="$cell_id"] > pluto-output p { margin: 2px 0; }
</style>
""")

# Diagram placement metadata is editor state, not model, and would fill the slide.
function strip_metadata(text)
    lines = split(text, "\n")
    keep = String[]
    depth = 0
    for line in lines
        if depth == 0 && startswith(lstrip(line), "metadata {")
            depth = count('{', line) - count('}', line)
            continue
        elseif depth > 0
            depth += count('{', line) - count('}', line)
            continue
        end
        push!(keep, line)
    end
    return join(keep, "\n")
end

"""
    dyad_fold(names...) -> details

The Dyad declarations of `names`, without diagram metadata, folded under one summary line so
a slide shows the model only when the lecturer opens it.
"""
function dyad_fold(names::AbstractString...)
    parts = map(names) do name
        rel, line, text = dyad_source(name)
        "**`$name`**, `$rel` line $line\n\n```julia\n$(strip_metadata(text))\n```"
    end
    return details("Dyad source: " * join(names, ", "), Markdown.parse(join(parts, "\n\n")))
end

end
