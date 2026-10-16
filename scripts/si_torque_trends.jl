"""
Brake torque and efficiency of the 1.5 L hands-on engine against λ and spark advance, as a trend
model of the form Dyad task 2's `TorqueProduction` will compute (lecture plan S3).

    include("scripts/si_torque_trends.jl")
    using .SITorqueTrends
    op = operating_point(3000, 0.5)          # 3000 rpm, half the full-load air charge
    brake(1.1, -10.0, op)                    # (; torque, efficiency, bsfc)

The structure is the MathWorks SI Core Engine's: inner torque scaled by a λ multiplier and a
spark-retard multiplier, then friction and pumping taken off,

    T_i = T_i0 · M_σ(Δσ) · M_λ(λ) · min(1, 1/λ)
    T_e = T_i − V_d/(4π) · (FMEP(N) + p_exh − p_m)

with the air charge held, so `min(1, 1/λ)` is the share of the fuel that finds oxygen. At λ = 1
and MBT the model returns the hands-on engine's map (`data/engine/`) exactly; everything away
from that point is the shape of `M_λ` and `M_σ`, which are `(assumed)` as task 2 states them:

- `M_λ` is 1.03 at λ 0.88 (rich power), 1 at λ 1, 1.04 at λ 1.1 (lean efficiency) and falls to 0
  at the lean misfire limit near λ 1.6, joined by a monotone cubic so each peak sits on its node.
- `M_σ = 1 − c_σ·Δσ²` with `c_σ` = 3.5·10⁻⁴ /deg²: 3.5 % of inner torque at 10° from MBT, about
  4.4 % of brake torque at half load (anchor 2–5 % of torque). Task 2's suggested 4·10⁻⁴ costs
  just over 5 % of brake torque there, since friction does not shrink with the spark.
- `FMEP` is the Barnes-Moss SI correlation scaled by `k_f` = 0.6 (task 2, decision D3).

`sigma_mbt` stands for task 2's MBT spark-advance table as one smooth function `(assumed)`: 10° at
idle, rising with speed and falling with load, anchored to 36° at 3000 rpm and half the full-load
air charge, where notebook 02's single-zone Wiebe cylinder finds MBT. Task 6 will replace it.

Nothing here is simulated or measured; every coefficient is tagged.
"""
module SITorqueTrends

export M_lambda, M_sigma, sigma_mbt, friction_torque, map_point, operating_point, brake

const AFR_S = 14.6            # stoichiometric air-fuel ratio (deck slide 23)
const H_L = 43.4e6            # J/kg, gasoline lower heating value (textbook)
const V_D = 1.5e-3            # m³, displacement (plan S4)
const P_A = 101.325           # kPa, ambient (textbook)
const P_EXH = 1.05 * P_A      # kPa, exhaust back pressure (assumed, task 2)
const K_F = 0.6               # Barnes-Moss scale for a modern engine (assumed, task 2 D3)
const C_SIGMA = 3.5e-4        # 1/deg², spark-retard curvature (assumed)
const P_REF = 95.0            # kPa, full-load manifold pressure (assumed, data/engine/README.md)

const LAMBDA_NODES = [0.65, 0.70, 0.75, 0.80, 0.88, 1.00, 1.10, 1.20, 1.30, 1.40, 1.50, 1.60]
const M_NODES = [0.870, 0.920, 0.960, 0.995, 1.030, 1.000, 1.040, 1.035, 1.010, 0.950, 0.800, 0.0]

const MAPS = joinpath(@__DIR__, "..", "data", "engine")

"""
    pchip(x, y) -> f

Fritsch–Carlson monotone cubic through the points: no overshoot, and a node where the slope
changes sign is an extremum of `f`.
"""
function pchip(x, y)
    n, h = length(x), diff(x)
    δ = diff(y) ./ h
    d = zeros(n)
    d[1], d[n] = δ[1], δ[end]
    for k in 2:(n - 1)
        if δ[k - 1] * δ[k] > 0
            w1, w2 = 2h[k] + h[k - 1], h[k] + 2h[k - 1]
            d[k] = (w1 + w2) / (w1 / δ[k - 1] + w2 / δ[k])
        end
    end
    return function (xq)
        k = clamp(searchsortedlast(x, xq), 1, n - 1)
        t = (xq - x[k]) / h[k]
        (1 + 2t) * (1 - t)^2 * y[k] + t * (1 - t)^2 * h[k] * d[k] +
            t^2 * (3 - 2t) * y[k + 1] + t^2 * (t - 1) * h[k] * d[k + 1]
    end
end

const M_LAMBDA = pchip(LAMBDA_NODES, M_NODES)

"λ multiplier on inner torque per unit of fuel burned; 1 at λ = 1."
M_lambda(λ) = M_LAMBDA(clamp(λ, first(LAMBDA_NODES), last(LAMBDA_NODES)))

"Spark-retard multiplier on inner torque at `Δσ` degrees from MBT (negative is retard)."
M_sigma(Δσ) = max(0.0, 1 - C_SIGMA * Δσ^2)

"MBT spark advance in degrees BTDC at `rpm` and manifold pressure `p_m_kPa`."
sigma_mbt(rpm, p_m_kPa) = 10 + 38 * (1 - exp(-max(rpm - 800, 0) / 1000)) * (1.1 - 0.5 * p_m_kPa / 100)

"Friction and pumping torque in N·m: Barnes-Moss FMEP plus the exhaust-to-manifold pressure step."
function friction_torque(rpm, p_m_kPa)
    n = rpm / 1000
    fmep = K_F * (97 + 15n + 5n^2)                     # kPa
    return V_D / (4π) * 1e3 * (fmep + P_EXH - p_m_kPa)
end

"One speed row of a `data/engine/` table as `(kpa, values)`; `rpm` must be a breakpoint."
function map_row(file, rpm)
    lines = readlines(joinpath(MAPS, file))
    kpa = parse.(Float64, split(lines[1], ",")[2:end])
    for line in lines[2:end]
        cells = split(line, ",")
        parse(Float64, cells[1]) == rpm && return kpa, parse.(Float64, cells[2:end])
    end
    error("$file has no row at $rpm rpm")
end

function interpolate(x, y, xq)
    k = clamp(searchsortedlast(x, xq), 1, length(x) - 1)
    return y[k] + (xq - x[k]) / (x[k + 1] - x[k]) * (y[k + 1] - y[k])
end

"""
    map_point(rpm, p_m_kPa) -> (; rpm, p_m_kPa, T_e, mdot_f, eta_b)

Brake torque [N·m], fuel flow [kg/s] and brake efficiency of the hands-on engine's maps at one
speed breakpoint and manifold pressure. The maps must run at λ = 1 there, which the model takes
as MBT.
"""
function map_point(rpm, p_m_kPa)
    λ = interpolate(map_row("lambda.csv", rpm)..., p_m_kPa)
    λ == 1 || error("the map runs at λ = $λ at $rpm rpm, $p_m_kPa kPa; the model needs λ = 1")
    T_e = interpolate(map_row("torque_Nm.csv", rpm)..., p_m_kPa)
    mdot_f = interpolate(map_row("fuel_gps.csv", rpm)..., p_m_kPa) / 1e3
    return (; rpm, p_m_kPa, T_e, mdot_f, eta_b = T_e * rpm * π / 30 / (mdot_f * H_L))
end

"""
    operating_point(rpm, load) -> (; rpm, p_m_kPa, T_e, mdot_f, eta_b)

The [`map_point`](@ref) at relative air charge `load`: the manifold pressure where `η_v · p_m` is
`load` times its value at `P_REF`.
"""
function operating_point(rpm, load)
    kpa, eta_v = map_row("eta_v.csv", rpm)
    charge = eta_v .* kpa
    return map_point(rpm, interpolate(charge, kpa, load * interpolate(kpa, charge, P_REF)))
end

"""
    brake(λ, Δσ, op) -> (; torque, efficiency, bsfc, power)

Brake torque [N·m], efficiency [–], BSFC [g/kWh] and power [W] at `op`'s air charge and speed,
with the fuel set for `λ` and the spark `Δσ` degrees from MBT. BSFC is `NaN` where the engine
makes no torque.
"""
function brake(λ, Δσ, op)
    ω = op.rpm * π / 30
    T_f = friction_torque(op.rpm, op.p_m_kPa)
    T_i = (op.T_e + T_f) * M_sigma(Δσ) * M_lambda(λ) * min(1, 1 / λ)
    T_e = T_i - T_f
    mdot_f = op.mdot_f / λ
    return (; torque = T_e, efficiency = T_e * ω / (mdot_f * H_L),
        bsfc = T_e > 0 ? 3.6e9 * mdot_f / (T_e * ω) : NaN, power = T_e * ω)
end

end
