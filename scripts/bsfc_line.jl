#!/usr/bin/env julia
#
# Best-BSFC operating line of the Lecture 2 mapped engine, for the Lecture 5 CVT (issue #112).
#
#     julia +dyad-3.5.0 --project=. scripts/bsfc_line.jl
#
# Reads the engine tables `scripts/alpha_engine_maps.jl` wrote to `data/engine/` (the same
# tables `Engine.EngineMapData` carries for `MappedEngine`) and writes
# `assets/data/engine/bsfc_line.csv`, which Dyad reads as
# `dyad://VehicleSystemsComponents/data/engine/bsfc_line.csv`.
#
# Method. The engine model reads torque and fuel flow bilinearly on the (N, p_m) grid and caps
# torque at the full-load curve (`TorqueMap`, `FuelMap`). At a fixed speed both are piecewise
# linear in p_m, so the p_m giving a torque T is found exactly on that polyline, and BSFC follows
# from the fuel flow there. For each requested power P on a 1 kW grid from 1 kW to peak power,
# every speed on a 5 rpm grid from idle to the rev cut where P/ω fits under the reachable torque
# is scored, and the lowest BSFC is kept. The raw argmin jumps where BSFC is nearly flat along a
# power hyperbola, so the speeds are made non-decreasing in power by isotonic regression
# (pool-adjacent-violators) and snapped back to the speed grid; torque and BSFC are then
# recomputed at those speeds, so every row is an operating point the engine model really has.

module BsfcLine

using Printf

export ROOT, LINE_FILE, RPM_IDLE, RPM_MAX, load_maps, operating_line, render_line,
    bsfc_at, reachable_torque, global_min_bsfc

const ROOT = normpath(@__DIR__, "..")
const MAPS = joinpath(ROOT, "data", "engine")
const LINE_FILE = joinpath(ROOT, "assets", "data", "engine", "bsfc_line.csv")

# Speed range: the idle speed the engine tests settle at, and FuelCutLogic's `rev_cut_rpm`.
const RPM_IDLE = 800.0
const RPM_MAX = 6500.0
const RPM_STEP = 5.0
const POWER_STEP_KW = 1.0

function read_grid(path)
    lines = readlines(path)
    kpa = parse.(Float64, split(lines[1], ',')[2:end])
    rows = [parse.(Float64, split(l, ',')) for l in lines[2:end] if !isempty(l)]
    rpm = first.(rows)
    Z = permutedims(reduce(hcat, (r[2:end] for r in rows)))
    return rpm, kpa, Z
end

function read_curve(path)
    rows = [parse.(Float64, split(l, ',')[1:2]) for l in readlines(path)[2:end] if !isempty(l)]
    return first.(rows), last.(rows)
end

"The torque and fuel tables and the full-load curve, as `MappedEngine` uses them."
function load_maps(dir = MAPS)
    rpm, kpa, torque = read_grid(joinpath(dir, "torque_Nm.csv"))
    rpm_f, kpa_f, fuel = read_grid(joinpath(dir, "fuel_gps.csv"))
    (rpm_f, kpa_f) == (rpm, kpa) || error("torque and fuel tables are on different grids")
    fl_rpm, fl_T = read_curve(joinpath(dir, "full_load.csv"))
    return (; rpm, kpa, torque, fuel, fl_rpm, fl_T)
end

"Linear interpolation clamped at the ends, as the Dyad tables are."
function lin(xs, ys, x)
    x = clamp(x, first(xs), last(xs))
    k = clamp(searchsortedlast(xs, x), 1, length(xs) - 1)
    t = (x - xs[k]) / (xs[k+1] - xs[k])
    return ys[k] + t * (ys[k+1] - ys[k])
end

"Torque and fuel columns over the p_m axis at speed `n` [rpm]."
function columns(m, n)
    n = clamp(n, first(m.rpm), last(m.rpm))
    i = clamp(searchsortedlast(m.rpm, n), 1, length(m.rpm) - 1)
    t = (n - m.rpm[i]) / (m.rpm[i+1] - m.rpm[i])
    col(Z) = (1 - t) .* view(Z, i, :) .+ t .* view(Z, i + 1, :)
    return col(m.torque), col(m.fuel)
end

"Largest brake torque at `n` [rpm]: the map at its top p_m, capped at the full-load curve."
reachable_torque(m, n) = min(lin(m.fl_rpm, m.fl_T, n), last(columns(m, n)[1]))

"""
    bsfc_at(m, n, T) -> (; p_kpa, fuel_gps, bsfc)

Manifold pressure, fuel flow [g/s] and BSFC [g/kWh] where the map gives torque `T` > 0 at speed
`n` [rpm]; `nothing` when `T` is above the reachable torque. Torque rises with p_m wherever it
is positive, so the first crossing of the polyline is the operating point.
"""
function bsfc_at(m, n, T)
    T > 0 || return nothing
    T <= reachable_torque(m, n) || return nothing
    τ, f = columns(m, n)
    j = findfirst(k -> τ[k] < T <= τ[k+1], 1:length(τ)-1)
    j === nothing && return nothing
    w = (T - τ[j]) / (τ[j+1] - τ[j])
    p = m.kpa[j] + w * (m.kpa[j+1] - m.kpa[j])
    fuel = f[j] + w * (f[j+1] - f[j])
    return (; p_kpa = p, fuel_gps = fuel, bsfc = fuel * 3600 / (T * n * pi / 30 / 1e3))
end

const SPEEDS = collect(RPM_IDLE:RPM_STEP:RPM_MAX)

power_kw(n, T) = T * n * pi / 30 / 1e3
torque_for(P_kw, n) = P_kw * 1e3 / (n * pi / 30)

"Peak power over the speed range and the speed it is reached at, on the speed grid."
function peak_power(m)
    P, k = findmax(n -> power_kw(n, reachable_torque(m, n)), SPEEDS)
    return P, SPEEDS[k]
end

"Lowest BSFC over the whole reachable map in the speed range: (; bsfc, rpm, torque, power_kw)."
function global_min_bsfc(m)
    best = (; bsfc = Inf, rpm = NaN, torque = NaN, power_kw = NaN)
    for n in SPEEDS
        τ, _ = columns(m, n)
        # BSFC is a ratio of two linear functions on each p_m segment, so it is monotone there:
        # its minimum at this speed sits on a table node or on the reachable-torque cap.
        for T in (filter(>(0), τ)..., reachable_torque(m, n))
            r = bsfc_at(m, n, T)
            r !== nothing && r.bsfc < best.bsfc &&
                (best = (; bsfc = r.bsfc, rpm = n, torque = T, power_kw = power_kw(n, T)))
        end
    end
    return best
end

"Lowest-BSFC speed for power `P_kw` on the speed grid, or `nothing` when P is out of reach."
function raw_argmin(m, P_kw)
    best, best_n = Inf, nothing
    for n in SPEEDS
        r = bsfc_at(m, n, torque_for(P_kw, n))
        r !== nothing && r.bsfc < best && ((best, best_n) = (r.bsfc, n))
    end
    return best_n
end

"Least-squares non-decreasing fit to `y` (pool-adjacent-violators)."
function isotonic(y)
    blocks = Tuple{Float64, Int}[]
    for v in y
        push!(blocks, (v, 1))
        while length(blocks) > 1 && blocks[end-1][1] > blocks[end][1]
            (a, na), (b, nb) = blocks[end-1], blocks[end]
            pop!(blocks)
            blocks[end] = ((a * na + b * nb) / (na + nb), na + nb)
        end
    end
    return reduce(vcat, (fill(v, n) for (v, n) in blocks))
end

"Smallest grid speed at which power `P_kw` is reachable."
min_feasible_speed(m, P_kw) =
    SPEEDS[findfirst(n -> torque_for(P_kw, n) <= reachable_torque(m, n), SPEEDS)]

"""
    operating_line(m) -> Vector of (; power_kw, rpm, torque, bsfc, raw_rpm)

The best-BSFC line, monotone in speed, from 1 kW to peak power (see the file header).
"""
function operating_line(m)
    P_peak, n_peak = peak_power(m)
    powers = [collect(POWER_STEP_KW:POWER_STEP_KW:floor(P_peak)); P_peak]
    raw = [P == P_peak ? n_peak : raw_argmin(m, P) for P in powers]
    fitted = isotonic(raw)
    speeds = Float64[]
    for (P, n) in zip(powers, fitted)
        n = RPM_IDLE + RPM_STEP * round((n - RPM_IDLE) / RPM_STEP)
        n = max(n, min_feasible_speed(m, P), isempty(speeds) ? RPM_IDLE : speeds[end])
        push!(speeds, n)
    end
    return map(zip(powers, speeds, raw)) do (P, n, n_raw)
        T = torque_for(P, n)
        r = bsfc_at(m, n, T)
        r === nothing && error("line point $(P) kW at $(n) rpm is out of the map")
        (; power_kw = P, rpm = n, torque = T, bsfc = r.bsfc, raw_rpm = n_raw)
    end
end

"The CSV text of the line; fixed decimals keep reruns byte-identical."
function render_line(line)
    io = IOBuffer()
    println(io, "power_kW,speed_rpm,torque_Nm,bsfc_g_per_kWh")
    for r in line
        @printf(io, "%.3f,%.1f,%.3f,%.2f\n", r.power_kw, r.rpm, r.torque, r.bsfc)
    end
    return String(take!(io))
end

function main()
    m = load_maps()
    line = operating_line(m)
    mkpath(dirname(LINE_FILE))
    write(LINE_FILE, render_line(line))
    g = global_min_bsfc(m)
    moved = count(r -> r.rpm != r.raw_rpm, line)
    println("wrote $(relpath(LINE_FILE, ROOT)): $(length(line)) points, ",
        @sprintf("%.1f–%.1f kW", first(line).power_kw, last(line).power_kw))
    @printf("map minimum BSFC %.2f g/kWh at %.0f rpm, %.1f N·m (%.1f kW)\n",
        g.bsfc, g.rpm, g.torque, g.power_kw)
    @printf("line minimum BSFC %.2f g/kWh; %d of %d speeds moved to make the line monotone\n",
        minimum(r -> r.bsfc, line), moved, length(line))
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    BsfcLine.main()
end
