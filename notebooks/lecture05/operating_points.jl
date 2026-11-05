"""
Engine operating points of a car run, and the fuel figures the Lecture 5 hybrid is compared on.

Notebook `01-operating-points.pluto.jl` draws them on the BSFC map of `bsfc_map.jl`, and
`test/lecture05_plausibility.jl` checks the extraction against the map tables. Every car,
conventional or hybrid, goes through the same functions, so their figures compare like for like.
"""
module OperatingPoints

include(joinpath(@__DIR__, "..", "..", "scripts", "bsfc_line.jl"))
using .BsfcLine: read_line, power_kw

export RHO_PETROL, P_MIN_KW, operating_points, fuel_metrics, line_bsfc, fuel_cells

"Petrol density [kg/L] (Hands-on 02)."
const RHO_PETROL = 0.745

# The best-BSFC line starts at 1 kW; below it BSFC grows without bound towards idle, so fuel
# burned there is counted as idle fuel rather than given a BSFC.
const P_MIN_KW = 1.0

const LINE = read_line()

"BSFC [g/kWh] of the best-BSFC line at power `P_kw` [kW], linear between rows and clamped."
function line_bsfc(P_kw)
    P, b = LINE.power_kw, LINE.bsfc
    x = clamp(P_kw, first(P), last(P))
    k = clamp(searchsortedlast(P, x), 1, length(P) - 1)
    return b[k] + (x - P[k]) / (P[k+1] - P[k]) * (b[k+1] - b[k])
end

"""
    operating_points(sol; speed, torque, fuel, vehicle_speed, dt = 1.0)

Engine operating points of solution `sol`, sampled at the midpoints of `dt`-second intervals so
that each sample stands for `dt` seconds of the run and sums over samples are time integrals.

The keywords are the solution's symbolic variables for engine speed [rad/s], engine brake
torque [N·m], fuel mass flow [kg/s] and vehicle speed [km/h]. Returns per-sample `t`, `rpm`,
`torque`, `power_kw`, `fuel_g` (grams burned over the sample's interval) and `bsfc` [g/kWh,
`NaN` at or below `P_MIN_KW`], with the run's `km` and `dt`.
"""
function operating_points(sol; speed, torque, fuel, vehicle_speed, dt = 1.0)
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
- `idle`, the share of all fuel burned at or below `P_MIN_KW`.

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
        idle = share(total - burned))
end

"""
    fuel_cells(op; drpm = 100.0, dtorque = 4.0)

The fuel of `op` gathered into cells `drpm` rpm by `dtorque` N·m wide: per cell the
fuel-weighted mean speed and torque and the grams burned there, largest cell first. Cells that
burned nothing are left out, so a run that burned no fuel has no cells.
"""
function fuel_cells(op; drpm = 100.0, dtorque = 4.0)
    acc = Dict{Tuple{Int, Int}, NTuple{3, Float64}}()
    for (n, T, g) in zip(op.rpm, op.torque, op.fuel_g)
        g > 0 || continue
        key = (floor(Int, n / drpm), floor(Int, T / dtorque))
        sn, sT, sg = get(acc, key, (0.0, 0.0, 0.0))
        acc[key] = (sn + g * n, sT + g * T, sg + g)
    end
    cells = sort!([(rpm = sn / sg, torque = sT / sg, fuel_g = sg) for (sn, sT, sg) in values(acc)];
        by = c -> -c.fuel_g)
    return (; rpm = Float64[c.rpm for c in cells], torque = Float64[c.torque for c in cells],
        fuel_g = Float64[c.fuel_g for c in cells])
end

end # module
