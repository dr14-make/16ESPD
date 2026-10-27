#!/usr/bin/env julia
#
# EPA ALPHA 2014 Mazda 2.0 L Skyactiv (LEV III fuel) -> 1.5 L maps on (N, p_m).
#
#     julia +dyad-3.5.0 --project=. scripts/alpha_engine_maps.jl [--figures DIR]
#
# Reads `data/engine/alpha/*.m` as text (it is never executed), writes the tables to
# `data/engine/`, and prints the reality-anchor checks of `docs/lecture-02-mapped-engine-plan.md`
# with every miss marked. `--figures DIR` also writes the comparison plots.
#
# Every constant carries its provenance tag (lecture plan S10).

using Printf

const FIGURES = let k = findfirst(==("--figures"), ARGS)
    k === nothing ? nothing : ARGS[k+1]
end
if FIGURES !== nothing
    using Plots
end

const ROOT = normpath(@__DIR__, "..")
const SOURCE = joinpath(ROOT, "data", "engine", "alpha", "engine_2014_Mazda_Skyactiv_2L0_LEVIII.m")
const OUT = joinpath(ROOT, "data", "engine")

# ---------------------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------------------

const V_D_SRC = 1.998e-3      # m^3, ALPHA engine displacement (EPA ALPHA)
const V_D = 1.5e-3            # m^3, hands-on engine (MathWorks; lecture plan S4)
const SCALE = V_D / V_D_SRC   # torque and fuel factor at constant BMEP and BSFC (derived)
const R_AIR = 287.05          # J/(kg K) (textbook)
const T_M = 298.15            # K, manifold air temperature (MathWorks; dyad-tasks shared table)
const AFR_S = 14.6            # stoichiometric air/fuel ratio (deck, slide 23)
const RHO_F = 0.745           # kg/L gasoline density (textbook)
const CO2_PER_FUEL = 3.09     # kg CO2 per kg gasoline at full oxidation (derived, carbon balance)

# Calibration targets
const P_REF = 95.0            # kPa, full-load manifold pressure: mid-band of 90-98 kPa (assumed)
const N_IDLE = 800.0          # rpm, idle speed (lecture plan S4)
const P_IDLE = 33.0           # kPa, idle manifold pressure at zero brake torque (brake plan 2a)

# Full-load enrichment: λ leaves 1 above X_RICH of P_REF and reaches 1 - Δλ(N) at P_REF.
# Δλ grows with speed for exhaust-component protection (assumed).
const X_RICH = 0.85
const DLAMBDA_KNOTS = [1500.0 => 0.10, 3500.0 => 0.14, 6000.0 => 0.20]

# Output grid: rpm rows x kPa columns, the `data[i, j]` = f(axis1[i], axis2[j]) layout of
# `BlockComponents.Tables.InterpolatedTable` with u1 = N and u2 = p_m.
const RPM_GRID = collect(500.0:250.0:6750.0)
const KPA_GRID = collect(0.0:2.5:105.0)

# Lecture 1 hands-on car (Lecture 1 `CAR`; mapped-engine plan M7)
const CAR = (m = 1400.0, CdA = 0.63, rho = 1.2, f_r = 0.012, i = 4.0, r = 0.31, g = 9.81)

rpm(radps) = radps * 30 / π
radps(n) = n * π / 30

# ---------------------------------------------------------------------------------------
# Parsing: the .m file is read as text; only numeric literals inside `engine.<name> = [...]`
# are accepted.
# ---------------------------------------------------------------------------------------

function m_array(text::AbstractString, name::AbstractString)
    m = match(Regex("engine\\.\\Q$(name)\\E\\s*=\\s*\\[([^\\]]*)\\]"), text)
    m === nothing && error("`engine.$name` not found in the ALPHA file")
    body = m.captures[1]
    occursin(r"[^0-9eE+\-.,;\s]", body) && error("`engine.$name` holds non-numeric content")
    rows = [filter(!isempty, split(r, r"[,\s]+")) for r in split(body, ';')]
    rows = filter(!isempty, rows)
    return [parse.(Float64, r) for r in rows]
end

m_vector(text, name) = reduce(vcat, m_array(text, name))
m_matrix(text, name) = permutedims(reduce(hcat, m_array(text, name)))

function read_alpha(path = SOURCE)
    text = read(path, String)
    a = (
        fl_w = m_vector(text, "full_throttle_speed_radps"),
        fl_T = m_vector(text, "full_throttle_torque_Nm"),
        ct_w = m_vector(text, "closed_throttle_speed_radps"),
        ct_T = m_vector(text, "closed_throttle_torque_Nm"),
        w = m_vector(text, "fuel_map_speed_radps"),
        T = m_vector(text, "fuel_map_torque_Nm"),
        gps = m_matrix(text, "fuel_map_gps"),
    )
    disp = parse(Float64, match(r"engine\.displacement_L\s*=\s*([0-9.]+)", text).captures[1])
    disp ≈ V_D_SRC * 1e3 || error("displacement $disp L, expected $(V_D_SRC * 1e3) L")
    size(a.gps) == (length(a.T), length(a.w)) || error("fuel map is $(size(a.gps))")
    return a
end

# ---------------------------------------------------------------------------------------
# Interpolation
# ---------------------------------------------------------------------------------------

"Piecewise-linear interpolation, linear extrapolation beyond the ends."
function lin(xs, ys, x)
    k = clamp(searchsortedlast(xs, x), 1, length(xs) - 1)
    t = (x - xs[k]) / (xs[k+1] - xs[k])
    return ys[k] + t * (ys[k+1] - ys[k])
end

"Piecewise-linear interpolation, held constant beyond the ends."
lin_clamped(xs, ys, x) = lin(xs, ys, clamp(x, first(xs), last(xs)))

"Bilinear interpolation of `Z[i, j] = f(xs[i], ys[j])`, clamped to the grid."
function bilin(xs, ys, Z, x, y)
    x = clamp(x, first(xs), last(xs))
    y = clamp(y, first(ys), last(ys))
    i = clamp(searchsortedlast(xs, x), 1, length(xs) - 1)
    j = clamp(searchsortedlast(ys, y), 1, length(ys) - 1)
    s = (x - xs[i]) / (xs[i+1] - xs[i])
    t = (y - ys[j]) / (ys[j+1] - ys[j])
    return (1 - s) * (1 - t) * Z[i, j] + s * (1 - t) * Z[i+1, j] +
           (1 - s) * t * Z[i, j+1] + s * t * Z[i+1, j+1]
end

"Root of a function increasing on [lo, hi] by bisection."
function bisect(f, lo, hi; tol = 1e-9)
    f(lo) > 0 && return lo
    f(hi) < 0 && return hi
    while hi - lo > tol
        mid = (lo + hi) / 2
        f(mid) < 0 ? (lo = mid) : (hi = mid)
    end
    return (lo + hi) / 2
end

# ---------------------------------------------------------------------------------------
# Scaling to 1.5 L at constant BMEP and BSFC
# ---------------------------------------------------------------------------------------

function scale(a)
    return (
        fl_n = rpm.(a.fl_w), fl_T = a.fl_T .* SCALE,
        ct_n = rpm.(a.ct_w), ct_T = a.ct_T .* SCALE,
        n = rpm.(a.w), T = a.T .* SCALE, fuel = a.gps .* SCALE,   # fuel[i, j]: torque i, speed j
    )
end

full_load_torque(s, n) = lin_clamped(s.fl_n, s.fl_T, n)
closed_throttle_torque(s, n) = lin_clamped(s.ct_n, s.ct_T, n)
source_fuel(s, n, T) = bilin(s.n, s.T, permutedims(s.fuel), n, T)

# ---------------------------------------------------------------------------------------
# Air path, shared with the Dyad air path (`eta_v_coeffs.csv`):
#
#   eta_v(N, p_m) = eta_fl(N) * (1 - k + k * p_m / P_REF)
#   eta_fl(N)     = c0 + c1 * ν + c2 * ν^2,     ν = N / 1000 rpm, N clamped to the grid
#   λ(N, p_m)     = 1 - Δλ(N) * clamp((p_m / P_REF - X_RICH) / (1 - X_RICH), 0, 1)
#   ṁ_cyl         = eta_v * p_m * V_d * N / (120 * R * T_m)
#   ṁ_f           = ṁ_cyl / (AFR_s * λ)
#
# eta_fl is the full-load breathing curve, a least-squares fit to the ALPHA full-load fuel at
# P_REF. The load factor lowers eta_v at part load, as late intake-valve closing and residual
# gas do; k is set so that zero brake torque at N_IDLE falls at P_IDLE. With 0 < k < 1,
# eta_v * p_m rises strictly with p_m and λ only falls, so each fuel flow has one p_m.
# ---------------------------------------------------------------------------------------

nu(n) = clamp(n, first(RPM_GRID), last(RPM_GRID)) / 1000
eta_fl(m, n) = m.c[1] + m.c[2] * nu(n) + m.c[3] * nu(n)^2
eta_v(m, n, p) = eta_fl(m, n) * (1 - m.k + m.k * p / P_REF)
lambda(n, p) = 1 - lin_clamped(first.(DLAMBDA_KNOTS), last.(DLAMBDA_KNOTS), n) *
                   clamp((p / P_REF - X_RICH) / (1 - X_RICH), 0.0, 1.0)

"Cylinder air flow [g/s] at speed `n` [rpm] and manifold pressure `p` [kPa]."
cyl_air(m, n, p) = eta_v(m, n, p) * p * 1e3 * V_D * n / (120 * R_AIR * T_M) * 1e3

"Fuel flow [g/s] for the cylinder air at `p` [kPa] and the mixture λ(N, p_m)."
fuel_of_p_m(m, n, p) = cyl_air(m, n, p) / (AFR_S * lambda(n, p))

"Manifold pressure [kPa] at which the engine burns `mdot_f` [g/s]."
p_m_of_fuel(m, n, mdot_f) = bisect(p -> fuel_of_p_m(m, n, p) - mdot_f, 0.0, 1000.0)

full_load_points(s) = [(n, T) for (n, T) in zip(s.fl_n, s.fl_T)
                       if 1000 <= n <= last(RPM_GRID) && T > 0]

function calibrate(s)
    pts = full_load_points(s)
    # At P_REF the load factor is 1, so eta_v = eta_fl there.
    req = [120 * R_AIR * T_M * AFR_S * lambda(n, P_REF) * source_fuel(s, n, T) * 1e-3 /
           (P_REF * 1e3 * V_D * n) for (n, T) in pts]
    A = [f(nu(n)) for (n, _) in pts, f in (_ -> 1.0, identity, x -> x^2)]
    c = A \ req
    eta_idle = 120 * R_AIR * T_M * AFR_S * source_fuel(s, N_IDLE, 0.0) * 1e-3 /
               (P_IDLE * 1e3 * V_D * N_IDLE)
    fl = (c = c, k = 0.0)
    k = (1 - eta_idle / eta_fl(fl, N_IDLE)) / (1 - P_IDLE / P_REF)
    0 < k < 1 || error("load factor k = $k leaves (0, 1): cylinder air would not rise with p_m")
    all(eta_fl(fl, n) > 0 for n in RPM_GRID) || error("eta_fl is not positive on the grid")
    return (c = c, k = k, fl_n = first.(pts), req = req)
end

# ---------------------------------------------------------------------------------------
# Torque axis -> manifold-pressure axis, then onto the regular grid
#
# At fixed speed fuel rises strictly with p_m, so each fired ALPHA column becomes a monotone
# torque-vs-p_m curve. Columns are interpolated linearly in p_m (extrapolated past their
# ends, as ALPHA itself extrapolates) and then linearly in speed.
#
# Motoring: ALPHA's lowest torque row carries zero fuel, i.e. fuel cut, and so has no p_m.
# The tables describe fueled operation only, so fuel -> 0 as p_m -> 0; below the lowest fired
# row torque is extrapolated toward p_m = 0 and floored at the closed-throttle (fuel-cut)
# torque, so the table never brakes harder than the motored engine. Deceleration fuel cut
# itself is a mode switch that reads `closed_throttle.csv`, not this table.
# ---------------------------------------------------------------------------------------

function columns(s, m)
    cols = map(findall(>(0), s.n)) do j
        fired = findall(>(0), s.fuel[:, j])
        p = [p_m_of_fuel(m, s.n[j], s.fuel[i, j]) for i in fired]
        issorted(p; lt = <=) || error("fuel not strictly rising with torque at $(s.n[j]) rpm")
        (n = s.n[j], p = p, T = s.T[fired], floor = closed_throttle_torque(s, s.n[j]))
    end
    return cols
end

column_torque(c, p) = max(lin(c.p, c.T, p), c.floor)

function torque_at(cols, n, p)
    ns = [c.n for c in cols]
    k = clamp(searchsortedlast(ns, n), 1, length(ns) - 1)
    t = clamp((n - ns[k]) / (ns[k+1] - ns[k]), 0, 1)
    return (1 - t) * column_torque(cols[k], p) + t * column_torque(cols[k+1], p)
end

# ---------------------------------------------------------------------------------------
# Engine-out emissions (assumed): emission index [g/kg fuel] times fuel flow. Shapes follow the
# textbook trends (Heywood ch. 11); magnitudes are set to typical stoichiometric engine-out
# levels, not to any measurement. `x` is the load as a fraction of P_REF, `v` the speed as a
# fraction of the grid span. Enrichment raises CO (oxygen-starved) and HC and lowers NOx.
# ---------------------------------------------------------------------------------------

load_fraction(p) = clamp(p / P_REF, 0.0, 1.0)
speed_fraction(n) = clamp((n - first(RPM_GRID)) / (last(RPM_GRID) - first(RPM_GRID)), 0.0, 1.0)

ei_nox(n, p) = (3.0 + 32.0 * load_fraction(p)^2 * (0.8 + 0.2 * speed_fraction(n))) *
               max(0.2, 1 - 4 * (1 - lambda(n, p)))
ei_hc(n, p) = 7.0 + 15.0 * (1 - load_fraction(p))^2 * (1 - 0.5 * speed_fraction(n)) +
              50.0 * (1 - lambda(n, p))
ei_co(n, p) = 60.0 + 40.0 * (1 - load_fraction(p))^2 + 3000.0 * (1 - lambda(n, p))

# ---------------------------------------------------------------------------------------
# Tables
# ---------------------------------------------------------------------------------------

grid(f) = [f(n, p) for n in RPM_GRID, p in KPA_GRID]

function build(s, m)
    cols = columns(s, m)
    fuel = grid((n, p) -> fuel_of_p_m(m, n, p))
    return (
        cols = cols,
        torque = grid((n, p) -> torque_at(cols, n, p)),
        fuel = fuel,
        lambda = grid(lambda),
        eta_v = grid((n, p) -> eta_v(m, n, p)),
        hc = grid(ei_hc) .* fuel ./ 1e3,
        co = grid(ei_co) .* fuel ./ 1e3,
        nox = grid(ei_nox) .* fuel ./ 1e3,
    )
end

table(t, Z, n, p) = bilin(RPM_GRID, KPA_GRID, Z, n, p)

"Manifold pressure at which the torque table gives `T` at speed `n` (torque rises with p_m)."
p_for_torque(t, n, T) = bisect(p -> table(t, t.torque, n, p) - T, first(KPA_GRID), last(KPA_GRID))

function write_grid(path, Z, tag)
    open(path, "w") do io
        println(io, "rpm \\ p_m_kPa,", join(KPA_GRID, ","))
        for (i, n) in enumerate(RPM_GRID)
            println(io, n, ",", join((@sprintf("%.6g", z) for z in Z[i, :]), ","))
        end
    end
    println("wrote $(relpath(path, ROOT))  $tag")
end

function write_rows(path, header, rows)
    open(path, "w") do io
        println(io, join(header, ","))
        for row in rows
            println(io, join((x isa Real ? @sprintf("%.6g", x) : string(x) for x in row), ","))
        end
    end
    println("wrote $(relpath(path, ROOT))")
end

"Write the Dyad structural parameters consumed by Engine.MappedEngine."
function write_dyad_tables(path, s, t)
    values(v) = "[" * join((@sprintf("%.9g", x) for x in v), ", ") * "]"
    matrix(Z) = "[" * join((values(view(Z, i, :)) for i in axes(Z, 1)), ",\n      ") * "]"
    curve_data(v) = matrix(hcat(v, v))
    open(path, "w") do io
        println(io, "\"Generated by scripts/alpha_engine_maps.jl; do not edit by hand.\"")
        println(io, "component EngineMapData")
        println(io, "  structural parameter rpm_axis::Real[:] = ", values(RPM_GRID))
        println(io, "  structural parameter kpa_axis::Real[:] = ", values(KPA_GRID))
        for (name, Z) in (("torque", t.torque), ("fuel", t.fuel), ("lambda", t.lambda),
                          ("hc", t.hc), ("co", t.co), ("nox", t.nox))
            println(io, "  structural parameter $(name)_data::Real[:, :] = ", matrix(Z))
        end
        println(io, "  structural parameter curve_axis::Real[:] = [0.0, 1.0]")
        println(io, "  structural parameter full_load_rpm::Real[:] = ", values(s.fl_n))
        println(io, "  structural parameter full_load_data::Real[:, :] = ", curve_data(s.fl_T))
        println(io, "  structural parameter closed_rpm::Real[:] = ", values(s.ct_n))
        println(io, "  structural parameter closed_data::Real[:, :] = ", curve_data(s.ct_T))
        println(io, "end")
    end
    println("wrote $(relpath(path, ROOT))  (generated)")
end

function write_tables(s, m, t)
    write_grid(joinpath(OUT, "torque_Nm.csv"), t.torque, "(EPA ALPHA, derived)")
    write_grid(joinpath(OUT, "fuel_gps.csv"), t.fuel, "(derived)")
    write_grid(joinpath(OUT, "lambda.csv"), t.lambda, "(assumed)")
    write_grid(joinpath(OUT, "eta_v.csv"), t.eta_v, "(derived)")
    write_grid(joinpath(OUT, "hc_gps.csv"), t.hc, "(assumed)")
    write_grid(joinpath(OUT, "co_gps.csv"), t.co, "(assumed)")
    write_grid(joinpath(OUT, "nox_gps.csv"), t.nox, "(assumed)")
    write_rows(joinpath(OUT, "eta_v_coeffs.csv"), ["name", "value", "unit", "tag"], [
        ("c0", m.c[1], "-", "(derived)"),
        ("c1", m.c[2], "1/krpm", "(derived)"),
        ("c2", m.c[3], "1/krpm^2", "(derived)"),
        ("k", m.k, "-", "(derived)"),
        ("p_ref", P_REF, "kPa", "(assumed)"),
        ("n_min", first(RPM_GRID), "rpm", "(assumed)"),
        ("n_max", last(RPM_GRID), "rpm", "(assumed)"),
        ("x_rich", X_RICH, "-", "(assumed)"),
        (("dlambda_$(Int(n))rpm", d, "-", "(assumed)") for (n, d) in DLAMBDA_KNOTS)...,
        ("R", R_AIR, "J/(kg K)", "(textbook)"),
        ("T_m", T_M, "K", "(MathWorks)"),
        ("V_d", V_D, "m^3", "(MathWorks)"),
        ("AFR_s", AFR_S, "-", "(deck)"),
    ])
    write_rows(joinpath(OUT, "full_load.csv"), ["rpm", "torque_Nm", "p_m_kPa", "lambda", "eta_v"],
        [begin
            p = n > 0 ? p_m_of_fuel(m, n, source_fuel(s, n, T)) : NaN
            (n, T, p, n > 0 ? lambda(n, p) : NaN, n > 0 ? eta_v(m, n, p) : NaN)
        end for (n, T) in zip(s.fl_n, s.fl_T)])
    write_rows(joinpath(OUT, "closed_throttle.csv"), ["rpm", "torque_Nm"], zip(s.ct_n, s.ct_T))
    write_dyad_tables(joinpath(ROOT, "dyad", "Vehicle", "Engine", "EngineMapData.dyad"), s, t)
end

# ---------------------------------------------------------------------------------------
# Reality-anchor checks (docs/lecture-02-mapped-engine-plan.md)
# ---------------------------------------------------------------------------------------

lph(gps) = gps * 3.6 / RHO_F
l_per_100km(gps, v) = gps / 1e3 / RHO_F / v * 1e5

function cruise(t, v_kmh)
    v = v_kmh / 3.6
    F = CAR.m * CAR.g * CAR.f_r + 0.5 * CAR.rho * CAR.CdA * v^2
    n = v / CAR.r * CAR.i * 30 / π
    T = F * CAR.r / CAR.i
    p = p_for_torque(t, n, T)
    f = table(t, t.fuel, n, p)
    return (n = n, T = T, p = p, fuel = f, l100 = l_per_100km(f, v),
        co2_km = CO2_PER_FUEL * f / v * 1e3, lambda = table(t, t.lambda, n, p))
end

function checks(s, m, t)
    rows = Any[]
    fmt(f, x) = Printf.format(Printf.Format(f), x)
    band!(name, lo, hi, x, pred; f = "%.1f") =
        push!(rows, (name, "$(lo)–$(hi)", pred, fmt(f, x), lo <= x <= hi))
    note!(name, band, x, pred = "") = push!(rows, (name, band, pred, x, missing))

    band!("Peak brake torque [N·m]", 145, 155, maximum(s.fl_T), "150.2")

    fired_in_envelope = [(s.n[j], s.T[i]) for j in eachindex(s.n), i in eachindex(s.T)
                         if s.n[j] > 0 && s.fuel[i, j] > 0 && 0 < s.T[i] <= full_load_torque(s, s.n[j])]
    bsfc_src = minimum(source_fuel(s, n, T) * 3600 / (T * radps(n) / 1e3) for (n, T) in fired_in_envelope)
    bsfc_tab = minimum(t.fuel[i, j] * 3600 / (t.torque[i, j] * radps(n) / 1e3)
                       for (i, n) in enumerate(RPM_GRID), j in eachindex(KPA_GRID)
                       if 0 < t.torque[i, j] <= full_load_torque(s, n))
    band!("Minimum BSFC, source [g/kWh]", 225, 260, bsfc_src, "232"; f = "%.0f")
    band!("Minimum BSFC, (N, p_m) tables [g/kWh]", 225, 260, bsfc_tab, "232"; f = "%.0f")

    p_idle = p_for_torque(t, 750, 0.0)
    band!("Idle fuel, 750 rpm, 0 N·m [L/h]", 0.4, 0.9, lph(table(t, t.fuel, 750, p_idle)), "0.45";
        f = "%.2f")
    band!("Idle fuel, source map [L/h]", 0.4, 0.9, lph(source_fuel(s, 750, 0.0)), "0.45"; f = "%.2f")

    for (v, lo, hi, pred) in ((50, 3, 4, "3.3"), (90, 4, 5.5, "4.6"), (130, 6, 8, "7.0"))
        c = cruise(t, v)
        band!(@sprintf("Cruise %d km/h, %.0f rpm, %.1f N·m [L/100 km]", v, c.n, c.T), lo, hi, c.l100,
            pred; f = "%.2f")
        band!(@sprintf("  λ at %d km/h cruise", v), 1, 1, c.lambda, "1"; f = "%.3f")
        note!(@sprintf("  CO₂ at %d km/h [g/km]; p_m [kPa]", v), "—", @sprintf("%.0f; %.1f", c.co2_km, c.p))
    end

    for (label, n, p) in (("full load, 3000 rpm", 3000.0, P_REF),
                          ("90 km/h cruise", cruise(t, 90).n, cruise(t, 90).p))
        P = table(t, t.torque, n, p) * radps(n) / 1e3
        bs(Z) = @sprintf("%.1f", table(t, Z, n, p) * 3600 / P)
        note!("HC / CO / NOx at $label [g/kWh] (assumed)", "—", join((bs(t.hc), bs(t.co), bs(t.nox)), " / "))
    end

    p0 = p_for_torque(t, N_IDLE, 0.0)
    band!("p_m at 0 N·m, 800 rpm [kPa]", 30, 36, p0, "33 (calibrates k)")
    note!("  η_v there", "0.4–0.6", @sprintf("%.2f", eta_v(m, N_IDLE, p0)))

    fl = [(n, p_m_of_fuel(m, n, source_fuel(s, n, T))) for (n, T) in full_load_points(s)]
    for (n, p) in fl
        band!(@sprintf("Full-load p_m, %.0f rpm [kPa] (λ %.2f, η_v %.3f)", n, lambda(n, p),
            eta_v(m, n, p)), 90, 98, p, "95")
    end
    eta_fl_max = maximum(eta_v(m, n, p) for (n, p) in fl)
    band!("Full-load η_v, max", 0, 1.05, eta_fl_max, "≤ 1.05"; f = "%.3f")

    errs = Dict(true => Float64[], false => Float64[])
    for c in t.cols, (p, T) in zip(c.p, c.T)
        (first(RPM_GRID) <= c.n <= last(RPM_GRID) && c.floor < T <= full_load_torque(s, c.n)) ||
            continue
        f_src = fuel_of_p_m(m, c.n, p)
        f_tab = table(t, t.fuel, c.n, p_for_torque(t, c.n, T))
        push!(errs[T >= 0], (f_tab - f_src) / f_src)
    end
    e = errs[true]
    band!(@sprintf("Round-trip fuel, T ≥ 0, max |error|, %d points [%%]", length(e)), 0, 5,
        100 * maximum(abs, e), "a few %")
    note!("Round-trip fuel, T ≥ 0, RMS error [%]", "—",
        @sprintf("%.2f", 100 * sqrt(sum(abs2, e) / length(e))))
    e = errs[false]
    note!(@sprintf("Round-trip fuel, fired T < 0, max |error|, %d points [%%]", length(e)), "—",
        @sprintf("%.1f", 100 * maximum(abs, e)))

    println()
    @printf("η_v(N, p_m) = (%.4f %+.4f ν %+.5f ν²) (1 - %.4f + %.4f p_m/%.0f kPa),  ν = N/1000 rpm\n",
        m.c..., m.k, m.k, P_REF)
    println()
    println(rpad("Check", 62), rpad("Band", 12), rpad("Predicted", 20), rpad("Measured", 16), "Result")
    for (name, band, pred, x, ok) in rows
        result = ismissing(ok) ? "report" : ok ? "pass" : "MISS"
        println(rpad(name, 62), rpad(band, 12), rpad(pred, 20), rpad(x, 16), result)
    end
    misses = count(r -> r[5] === false, rows)
    println("\n$misses banded check(s) missed")
    return misses
end

# ---------------------------------------------------------------------------------------
# Figures
# ---------------------------------------------------------------------------------------

function figures(dir, s, m, t)
    mkpath(dir)
    seq = Plots.cgrad(:Blues)
    fl = [(n, p_m_of_fuel(m, n, source_fuel(s, n, T))) for (n, T) in full_load_points(s)]
    contour(Z, label, title) = Plots.contourf(RPM_GRID, KPA_GRID, permutedims(Z); c = seq,
        levels = 20, colorbar_title = label, xlabel = "speed [rpm]", ylabel = "p_m [kPa]",
        title = title, titlefontsize = 10, ylims = (first(KPA_GRID), last(KPA_GRID)))
    full_load!(plt) = Plots.plot!(plt, first.(fl), last.(fl); color = :black, lw = 2,
        label = "full load")

    src_n = filter(>(0), s.n)
    src = [source_fuel(s, n, T) for T in s.T, n in src_n]
    a = Plots.contourf(src_n, s.T, src; c = seq, levels = 20, colorbar_title = "fuel [g/s]",
        xlabel = "speed [rpm]", ylabel = "brake torque [N·m]",
        title = "Source: ALPHA fuel, scaled to 1.5 L", titlefontsize = 10)
    Plots.plot!(a, s.fl_n, s.fl_T; color = :black, lw = 2, label = "full load")
    Plots.plot!(a, s.ct_n, s.ct_T; color = :black, lw = 2, ls = :dash, label = "closed throttle")

    b = contour(t.torque, "torque [N·m]", "Derived: T_e(N, p_m)")
    Plots.contour!(b, RPM_GRID, KPA_GRID, permutedims(t.torque); levels = [0.0], color = :white,
        lw = 2)
    full_load!(b)

    c = contour(t.fuel, "fuel [g/s]", "Derived: ṁ_f(N, p_m), with the mapped ALPHA points")
    full_load!(c)
    for (j, col) in enumerate(t.cols)
        Plots.scatter!(c, fill(col.n, length(col.p)), col.p; ms = 2, color = :black,
            markerstrokewidth = 0, label = j == 1 ? "ALPHA points" : "")
    end

    d = Plots.plot(; xlabel = "speed [rpm]", ylabel = "η_v [-]", titlefontsize = 10,
        title = "η_v(N, p_m) and the full-load points it fits", legend = :bottomright)
    for (p, ls) in ((P_IDLE, :dot), (60.0, :dash), (P_REF, :solid))
        Plots.plot!(d, RPM_GRID, [eta_v(m, n, p) for n in RPM_GRID]; color = :black, ls = ls,
            lw = 2, label = "p_m = $(p) kPa")
    end
    Plots.scatter!(d, m.fl_n, m.req; color = :black, ms = 4, label = "ALPHA full load at λ(N, 95)")

    e = contour(t.lambda, "λ [-]", "λ(N, p_m) (assumed)")

    fig = Plots.plot(a, b, c, d, e; layout = (2, 3), size = (1800, 950), margin = 5Plots.mm, left_margin = 12Plots.mm)
    Plots.savefig(fig, joinpath(dir, "alpha-maps.png"))

    em = [contour(grid(ei), "$name [g/kg fuel]", "$name emission index (assumed)")
          for (name, ei) in (("HC", ei_hc), ("CO", ei_co), ("NOx", ei_nox))]
    Plots.savefig(Plots.plot(em...; layout = (1, 3), size = (1500, 420), margin = 6Plots.mm),
        joinpath(dir, "emissions.png"))
    println("wrote figures to $dir")
end

# ---------------------------------------------------------------------------------------

function main()
    s = scale(read_alpha())
    m = calibrate(s)
    t = build(s, m)
    write_tables(s, m, t)
    FIGURES === nothing || figures(FIGURES, s, m, t)
    return checks(s, m, t)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
