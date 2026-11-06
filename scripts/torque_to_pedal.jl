#!/usr/bin/env julia
# Steady feed-forward inverse of the default MappedEngine.
# Run: julia +dyad-3.5.0 --project=. scripts/torque_to_pedal.jl
# No simulation or non-stdlib dependencies. The vacuum take-off is assumed capped;
# throttle/manifold transients, fuel cut, rev limiting and engine start are NOT inverted.
# Regenerate after changing EngineMapData, AirPath, Throttle, CylinderAirflow or PedalMap.
# test/runtests.jl lecture05 checks three inverse points against the steady Dyad engine
# within 0.5 N.m, so stale air-path defaults do not pass on analytic round trips alone.
module TorqueToPedalMap

using Printf
include("bsfc_line.jl")

const ROOT = BsfcLine.ROOT
const MAP_FILE = joinpath(ROOT, "assets", "data", "engine", "torque_to_pedal.csv")
const SPEEDS = collect(800.0:50.0:6500.0)
const TORQUES = collect(0.0:1.0:180.0)

# Literal defaults from Throttle, CylinderAirflow, AirPath and PedalMap.
const P_AMBIENT = 101325.0
const R_AIR = 287.05
const TEMPERATURE = 298.15
const GAMMA = 1.4
const PI_LINEAR = 0.95
const ALPHA_STOP = 0.122173
const AREA_IDLE = 7.4e-6
const BORE = 0.05
const DISCHARGE = 0.8
const DISPLACEMENT = 1.5e-3
const PEDAL_EXPONENT = 1.5

function flow_function(p)
    ratio = max(p / P_AMBIENT, (2 / (GAMMA + 1))^(GAMMA / (GAMMA - 1)))
    psi(r) = sqrt(2 * GAMMA / (GAMMA - 1) * (r^(2 / GAMMA) - r^((GAMMA + 1) / GAMMA)))
    return ratio > PI_LINEAR ? psi(PI_LINEAR) * (1 - ratio) / (1 - PI_LINEAR) : psi(ratio)
end

function cylinder_flow(n, p)
    nu = clamp(n, 500.0, 6750.0) / 1000
    eta = (0.777026 + 0.148753 * nu - 0.020452 * nu^2) *
          (1 - 0.898877 + 0.898877 * p / 95000.0)
    return eta * p * DISPLACEMENT * n / (120 * R_AIR * TEMPERATURE)
end

function throttle_flow(pedal, p)
    alpha = ALPHA_STOP + clamp(pedal, 0, 1)^PEDAL_EXPONENT * (pi / 2 - ALPHA_STOP)
    area = AREA_IDLE + pi * BORE^2 / 4 * (1 - cos(alpha) / cos(ALPHA_STOP))
    return DISCHARGE * area * P_AMBIENT / sqrt(R_AIR * TEMPERATURE) * flow_function(p)
end

"Steady manifold pressure [Pa], from mdot_thr = mdot_cyl, capped vacuum take-off."
function steady_pressure(n, pedal)
    lo, hi = 0.0, P_AMBIENT
    for _ in 1:60
        p = (lo + hi) / 2
        if throttle_flow(pedal, p) > cylinder_flow(n, p)
            lo = p
        else
            hi = p
        end
    end
    return (lo + hi) / 2
end

"Steady fired brake torque; does not apply FuelCutLogic."
function fired_torque(m, n, p)
    tau, _ = BsfcLine.columns(m, n)
    return min(BsfcLine.lin(m.kpa, tau, p / 1000), BsfcLine.lin(m.fl_rpm, m.fl_T, n))
end

"Invert the first rising torque crossing, then area, plate angle and progressive pedal."
function inverse_pedal(m, n, request,
                       p_lo = steady_pressure(n, 0.0), p_hi = steady_pressure(n, 1.0))
    target = clamp(request, fired_torque(m, n, p_lo), fired_torque(m, n, p_hi))
    # The first crossing chooses the smallest throttle on the full-load torque plateau.
    lo, hi = p_lo, p_hi
    for _ in 1:60
        p = (lo + hi) / 2
        if fired_torque(m, n, p) < target
            lo = p
        else
            hi = p
        end
    end
    p = (lo + hi) / 2
    area = cylinder_flow(n, p) * sqrt(R_AIR * TEMPERATURE) /
           (DISCHARGE * P_AMBIENT * flow_function(p))
    cosine = (1 - (area - AREA_IDLE) / (pi * BORE^2 / 4)) * cos(ALPHA_STOP)
    throttle = clamp((acos(clamp(cosine, -1, 1)) - ALPHA_STOP) / (pi / 2 - ALPHA_STOP), 0, 1)
    return throttle^(1 / PEDAL_EXPONENT)
end

function render_map(m = BsfcLine.load_maps())
    io = IOBuffer()
    println(io, "speed_rpm,", join(TORQUES, ','))
    for n in SPEEDS
        p_lo, p_hi = steady_pressure(n, 0.0), steady_pressure(n, 1.0)
        @printf(io, "%.1f", n)
        for tau in TORQUES
            @printf(io, ",%.9f", inverse_pedal(m, n, tau, p_lo, p_hi))
        end
        println(io)
    end
    return String(take!(io))
end

function main()
    mkpath(dirname(MAP_FILE))
    write(MAP_FILE, render_map())
    println("wrote $(relpath(MAP_FILE, ROOT)): $(length(SPEEDS) * length(TORQUES)) points")
end
end # module

if abspath(PROGRAM_FILE) == @__FILE__
    TorqueToPedalMap.main()
end
