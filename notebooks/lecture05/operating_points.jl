"""
Engine operating points of a car run, and the fuel figures the Lecture 5 hybrid is compared on.

Notebook `01-operating-points.pluto.jl` draws them on the BSFC map of `bsfc_map.jl`, and
`test/lecture05_plausibility.jl` checks the extraction against the map tables. Every car,
conventional or hybrid, goes through the same functions, so their figures compare like for like.
"""
module OperatingPoints

include(joinpath(@__DIR__, "..", "..", "scripts", "bsfc_line.jl"))
using .BsfcLine: read_line, power_kw

export RHO_PETROL, P_MIN_KW, FUEL_MIN_KG_S, WLTC_PHASES, operating_points, fuel_metrics,
    line_bsfc, fuel_cells, fueled, phase_fuel

"Petrol density [kg/L] (Hands-on 02)."
const RHO_PETROL = 0.745

# The best-BSFC line starts at 1 kW; below it BSFC grows without bound towards idle, so fuel
# burned there is counted as idle fuel rather than given a BSFC.
const P_MIN_KW = 1.0

# A stopped engine's fuel flow settles at solver round-off, below 1e-9 kg/s; idle burns about
# 1e-4 kg/s. Samples below this floor are an engine that is off, not an operating point.
const FUEL_MIN_KG_S = 1e-6

"WLTC class 3b phases: name, start and end [s]."
const WLTC_PHASES = [("Low", 0.0, 589.0), ("Medium", 589.0, 1022.0), ("High", 1022.0, 1477.0),
    ("Extra High", 1477.0, 1800.0)]

const LINE = read_line()

"Which samples of operating points `op` the engine was fueled in."
fueled(op) = op.fuel_g .> FUEL_MIN_KG_S * 1e3 * op.dt

"BSFC [g/kWh] of the best-BSFC line at power `P_kw` [kW], linear between rows and clamped."
function line_bsfc(P_kw)
    P, b = LINE.power_kw, LINE.bsfc
    x = clamp(P_kw, first(P), last(P))
    k = clamp(searchsortedlast(P, x), 1, length(P) - 1)
    return b[k] + (x - P[k]) / (P[k+1] - P[k]) * (b[k+1] - b[k])
end

"""
    operating_points(sol; speed, torque, fuel, vehicle_speed, dt = 0.1)

Engine operating points of solution `sol`, sampled at the midpoints of `dt`-second intervals so
that each sample stands for `dt` seconds of the run and sums over samples are time integrals.

The keywords are the solution's symbolic variables for engine speed [rad/s], engine brake
torque [N·m], fuel mass flow [kg/s] and vehicle speed [km/h]. Returns per-sample `t`, `rpm`,
`torque`, `power_kw`, `fuel_g` (grams burned over the sample's interval) and `bsfc` [g/kWh,
`NaN` at or below `P_MIN_KW`], with the run's `km` and `dt`.
"""
# One-second samples alias with the engine's fast fuel transients, fuel cut and K0 launch, and
# miss about 1 % of WLTC fuel; at 0.1 s the sum matches the integrated fuel to 0.03 %.
function operating_points(sol; speed, torque, fuel, vehicle_speed, dt = 0.1)
    t0, t1 = first(sol.t), last(sol.t)
    n = floor(Int, (t1 - t0) / dt + 1e-9)
    t = t0 .+ dt .* ((1:n) .- 0.5)
    at(x) = collect(sol(t; idxs = x).u)
    w, tau, mdot, v = at(speed), at(torque), at(fuel), at(vehicle_speed)
    rpm = w .* 30 ./ pi
    P = power_kw.(rpm, tau)
    bsfc = [p > P_MIN_KW ? m * 3.6e6 / p : NaN for (p, m) in zip(P, mdot)]
    return (; t, rpm, torque = tau, power_kw = P, fuel_g = mdot .* 1e3 .* dt, bsfc,
        km = sum(v) * dt / 3600, dt)
end

"""
    fuel_metrics(op; band = 10.0)

The fuel figures of operating points `op`:

- `L_per_100km`, from the fuel burned and the distance driven;
- `bsfc_mean`, the fuel-weighted mean BSFC [g/kWh] over the samples above `P_MIN_KW`;
- `bsfc_cycle`, fuel above `P_MIN_KW` over the engine work there [g/kWh];
- `near_line`, the share of all fuel burned within `band` g/kWh of the best-BSFC line's BSFC at
  the same power;
- `idle`, the share of all fuel burned at or below `P_MIN_KW`;
- `fueled_time`, the share of the run's time the engine was fueled (`fueled`).

A figure that has nothing to average, such as the BSFC of a run that burned no fuel, is
`missing`.
"""
function fuel_metrics(op; band = 10.0)
    total = sum(op.fuel_g; init = 0.0)
    loaded = op.power_kw .> P_MIN_KW
    f, b, P = op.fuel_g[loaded], op.bsfc[loaded], op.power_kw[loaded]
    burned = sum(f; init = 0.0)
    near = abs.(b .- line_bsfc.(P)) .<= band
    share(x) = total > 0 ? x / total : missing
    return (; fuel_g = total, km = op.km,
        L_per_100km = 100 * total / 1e3 / RHO_PETROL / op.km,
        bsfc_mean = burned > 0 ? sum(f .* b) / burned : missing,
        bsfc_cycle = burned > 0 ? burned / (sum(P) * op.dt / 3600) : missing,
        near_line = share(sum(f[near]; init = 0.0)),
        idle = share(total - burned),
        fueled_time = sum(fueled(op); init = 0) / max(length(op.fuel_g), 1))
end

"""
    fuel_cells(op; drpm = 100.0, dtorque = 4.0)

The fuel of `op` gathered into cells `drpm` rpm by `dtorque` N·m wide: per cell the
fuel-weighted mean speed and torque and the grams burned there, largest cell first. Only
`fueled` samples count, so a hybrid's engine-off time adds no cells and a run that burned no
fuel has none.
"""
function fuel_cells(op; drpm = 100.0, dtorque = 4.0)
    acc = Dict{Tuple{Int, Int}, NTuple{3, Float64}}()
    for (n, T, g, on) in zip(op.rpm, op.torque, op.fuel_g, fueled(op))
        on || continue
        key = (floor(Int, n / drpm), floor(Int, T / dtorque))
        sn, sT, sg = get(acc, key, (0.0, 0.0, 0.0))
        acc[key] = (sn + g * n, sT + g * T, sg + g)
    end
    cells = sort!([(rpm = sn / sg, torque = sT / sg, fuel_g = sg) for (sn, sT, sg) in values(acc)];
        by = c -> -c.fuel_g)
    return (; rpm = Float64[c.rpm for c in cells], torque = Float64[c.torque for c in cells],
        fuel_g = Float64[c.fuel_g for c in cells])
end

"""
    phase_fuel(sol, meter; phases = WLTC_PHASES)

SoC-corrected fuel [L/100 km] of each phase of a run metered by a `Vehicle.SoCCorrectedFuel`
`meter` (its symbolic subsystem in `sol`), and of the whole run. Each phase is charged the fuel
burned in it plus the fuel equivalent of the battery energy drawn in it, at the meter's own
`eta_eb`, `H_u` and `rho_f`, over the distance driven in it; the phases weighted by distance
sum to the run's corrected fuel. Returns a vector of `(; name, km, L_per_100km)`, the whole run
last as `"WLTC"`.
"""
function phase_fuel(sol, meter; phases = WLTC_PHASES)
    eta, H_u, rho = (sol.ps[getproperty(meter, k)] for k in (:eta_eb, :H_u, :rho_f))
    at(x, t) = sol(t; idxs = x)
    rows = map([phases; ("WLTC", first(sol.t), last(sol.t))]) do (name, a, b)
        d(x) = at(x, b) - at(x, a)
        m = d(meter.m_fuel) + d(meter.E_batt) / (eta * H_u)
        km = d(meter.s) / 1e3
        (; name, km, L_per_100km = 100 * m / rho * 1e3 / km)
    end
    return rows
end

end # module
