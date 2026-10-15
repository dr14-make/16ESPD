#!/usr/bin/env julia
#
# EPA ALPHA 2014 Mazda 2.0 L Skyactiv (LEV III fuel) -> 1.5 L maps on (N, p_m).
#
#     julia +dyad-3.4.0 --project=. scripts/alpha_engine_maps.jl [--figures DIR]
#
# Reads `data/engine/alpha/*.m` as text (it is never executed), writes the tables to
# `data/engine/`, prints the reality-anchor checks of `docs/lecture-02-mapped-engine-plan.md`
# and exits nonzero when a banded check fails. `--figures DIR` also writes the comparison plots.
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

# Full-load manifold pressure the volumetric efficiency is calibrated to (assumed): mid-band of
# the 90-98 kPa anchor, a few kPa of throttle and air-filter loss below ambient.
const P_FL_TARGET = 95.0      # kPa

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
# Speed-density
# ---------------------------------------------------------------------------------------

"Manifold pressure [kPa] at which the cylinders draw the air for `mdot_f` [g/s] at λ = 1."
p_m_of_fuel(eta_v, n, mdot_f) = 120 * R_AIR * T_M * AFR_S * mdot_f * 1e-3 / (eta_v(n) * V_D * n) / 1e3

"Fuel flow [g/s] at λ = 1 for the air the cylinders draw at `p_m` [kPa]."
fuel_of_p_m(eta_v, n, p_m) = p_m * 1e3 * eta_v(n) * V_D * n / (120 * R_AIR * T_M * AFR_S) * 1e3

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
# Volumetric efficiency: one knot per ALPHA full-load breakpoint, set so that the λ = 1 air
# for the ALPHA full-load fuel is drawn at P_FL_TARGET. Breakpoints below 1000 rpm and the
# zero-torque rev-limit point carry no full-load information; eta_v is held beyond the ends.
# Values above 1 are expected: where ALPHA's full-load fuel is richer than λ = 1, the λ = 1
# conversion books the extra fuel as air, so this is eta_v / λ rather than a breathing figure.
# ---------------------------------------------------------------------------------------

function calibrate(s)
    keep = [k for k in eachindex(s.fl_n) if s.fl_n[k] >= 1000 && s.fl_T[k] > 0]
    ns = s.fl_n[keep]
    etas = [120 * R_AIR * T_M * AFR_S * source_fuel(s, n, T) * 1e-3 / (P_FL_TARGET * 1e3 * V_D * n)
            for (n, T) in zip(ns, s.fl_T[keep])]
    return (n = ns, eta = etas, f = n -> lin_clamped(ns, etas, n))
end

# ---------------------------------------------------------------------------------------
# Torque axis -> manifold-pressure axis, then onto the regular grid
#
# At fixed speed p_m is proportional to fuel, so each fired ALPHA column becomes a monotone
# torque-vs-p_m curve. Columns are interpolated linearly in p_m (extrapolated past their
# ends, as ALPHA itself extrapolates) and then linearly in speed.
#
# Motoring: ALPHA's lowest torque row carries zero fuel, i.e. fuel cut, and so has no p_m.
# The tables describe fueled operation only, so fuel -> 0 as p_m -> 0; below the lowest fired
# row torque is extrapolated toward p_m = 0 and floored at the closed-throttle (fuel-cut)
# torque, so the table never brakes harder than the motored engine. Deceleration fuel cut
# itself is a mode switch that reads `closed_throttle.csv`, not this table.
# ---------------------------------------------------------------------------------------

function columns(s, eta)
    cols = map(findall(>(0), s.n)) do j
        fired = findall(>(0), s.fuel[:, j])
        p = [p_m_of_fuel(eta.f, s.n[j], s.fuel[i, j]) for i in fired]
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
# levels, not to any measurement. `x` is the load as a fraction of full-load p_m, `v` the
# speed as a fraction of the grid span. λ = 1 throughout, so no enrichment CO rise.
# ---------------------------------------------------------------------------------------

load_fraction(p) = clamp(p / P_FL_TARGET, 0.0, 1.0)
speed_fraction(n) = clamp((n - first(RPM_GRID)) / (last(RPM_GRID) - first(RPM_GRID)), 0.0, 1.0)

ei_nox(n, p) = 3.0 + 32.0 * load_fraction(p)^2 * (0.8 + 0.2 * speed_fraction(n))
ei_hc(n, p) = 7.0 + 15.0 * (1 - load_fraction(p))^2 * (1 - 0.5 * speed_fraction(n))
ei_co(n, p) = 60.0 + 40.0 * (1 - load_fraction(p))^2

# ---------------------------------------------------------------------------------------
# Tables
# ---------------------------------------------------------------------------------------

function build(s, eta)
    cols = columns(s, eta)
    grid(f) = [f(n, p) for n in RPM_GRID, p in KPA_GRID]
    fuel = grid((n, p) -> fuel_of_p_m(eta.f, n, p))
    return (
        cols = cols,
        torque = grid((n, p) -> torque_at(cols, n, p)),
        fuel = fuel,
        hc = grid((n, p) -> ei_hc(n, p)) .* fuel ./ 1e3,
        co = grid((n, p) -> ei_co(n, p)) .* fuel ./ 1e3,
        nox = grid((n, p) -> ei_nox(n, p)) .* fuel ./ 1e3,
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

function write_columns(path, header, cols...)
    open(path, "w") do io
        println(io, join(header, ","))
        for row in zip(cols...)
            println(io, join((@sprintf("%.6g", x) for x in row), ","))
        end
    end
    println("wrote $(relpath(path, ROOT))")
end

function write_tables(s, eta, t)
    write_grid(joinpath(OUT, "torque_Nm.csv"), t.torque, "(EPA ALPHA, derived)")
    write_grid(joinpath(OUT, "fuel_gps.csv"), t.fuel, "(derived)")
    write_grid(joinpath(OUT, "hc_gps.csv"), t.hc, "(assumed)")
    write_grid(joinpath(OUT, "co_gps.csv"), t.co, "(assumed)")
    write_grid(joinpath(OUT, "nox_gps.csv"), t.nox, "(assumed)")
    fl = [(n, T) for (n, T) in zip(s.fl_n, s.fl_T)]
    write_columns(joinpath(OUT, "full_load.csv"), ["rpm", "torque_Nm", "p_m_kPa"],
        first.(fl), last.(fl),
        [n > 0 ? p_m_of_fuel(eta.f, n, source_fuel(s, n, T)) : NaN for (n, T) in fl])
    write_columns(joinpath(OUT, "closed_throttle.csv"), ["rpm", "torque_Nm"], s.ct_n, s.ct_T)
    write_columns(joinpath(OUT, "eta_v.csv"), ["rpm", "eta_v"], eta.n, eta.eta)
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
        co2_km = CO2_PER_FUEL * f / v * 1e3)
end

function checks(s, eta, t)
    rows = Any[]
    band!(name, lo, hi, x, pred; fmt = "%.1f") =
        push!(rows, (name, "$(lo)–$(hi)", pred, Printf.format(Printf.Format(fmt), x), lo <= x <= hi))
    note!(name, band, x, pred) = push!(rows, (name, band, pred, x, missing))

    band!("Peak brake torque [N·m]", 145, 155, maximum(s.fl_T), "150.2")

    fired_in_envelope = [(s.n[j], s.T[i]) for j in eachindex(s.n), i in eachindex(s.T)
                         if s.n[j] > 0 && s.fuel[i, j] > 0 && 0 < s.T[i] <= full_load_torque(s, s.n[j])]
    bsfc_src = minimum(source_fuel(s, n, T) * 3600 / (T * radps(n) / 1e3) for (n, T) in fired_in_envelope)
    bsfc_tab = minimum(t.fuel[i, j] * 3600 / (t.torque[i, j] * radps(n) / 1e3)
                       for (i, n) in enumerate(RPM_GRID), j in eachindex(KPA_GRID)
                       if 0 < t.torque[i, j] <= full_load_torque(s, n))
    band!("Minimum BSFC, source [g/kWh]", 225, 260, bsfc_src, "232"; fmt = "%.0f")
    band!("Minimum BSFC, (N, p_m) tables [g/kWh]", 225, 260, bsfc_tab, "232"; fmt = "%.0f")

    p_idle = p_for_torque(t, 750, 0.0)
    band!("Idle fuel, 750 rpm, 0 N·m [L/h]", 0.4, 0.9, lph(table(t, t.fuel, 750, p_idle)), "0.45";
        fmt = "%.2f")
    band!("Idle fuel, source map [L/h]", 0.4, 0.9, lph(source_fuel(s, 750, 0.0)), "0.45"; fmt = "%.2f")

    for (v, lo, hi, pred) in ((50, 3, 4, "3.4"), (90, 4, 5.5, "4.6"), (130, 6, 8, "7.0"))
        c = cruise(t, v)
        band!(@sprintf("Cruise %d km/h, %.0f rpm, %.1f N·m [L/100 km]", v, c.n, c.T), lo, hi, c.l100,
            pred; fmt = "%.2f")
        note!(@sprintf("  CO₂ at %d km/h [g/km]; p_m [kPa]", v), "—",
            @sprintf("%.0f; %.1f", c.co2_km, c.p), "")
    end

    for (label, n, p) in (("full load, 3000 rpm", 3000.0, P_FL_TARGET),
                          ("90 km/h cruise", cruise(t, 90).n, cruise(t, 90).p))
        P = table(t, t.torque, n, p) * radps(n) / 1e3
        bs(Z) = @sprintf("%.1f", table(t, Z, n, p) * 3600 / P)
        note!("HC / CO / NOx at $label [g/kWh] (assumed)", "—",
            join((bs(t.hc), bs(t.co), bs(t.nox)), " / "), "")
    end

    p_fl = [p_m_of_fuel(eta.f, n, source_fuel(s, n, T))
            for (n, T) in zip(s.fl_n, s.fl_T) if 1000 <= n <= last(RPM_GRID) && T > 0]
    band!("Full-load p_m, min over 1000–6750 rpm [kPa]", 90, 98, minimum(p_fl), "calibrates η_v")
    band!("Full-load p_m, max over 1000–6750 rpm [kPa]", 90, 98, maximum(p_fl), "calibrates η_v")
    note!("η_v range (calibrated)", "≤ ~1.05 physical NA", @sprintf("%.2f–%.2f", extrema(eta.eta)...), "")

    p0 = p_for_torque(t, 800, 0.0)
    note!("p_m at 0 N·m, 800 rpm [kPa] (report only)", "30–36",
        @sprintf("%.1f", p0), "brake plan 2a")
    note!("η_v that puts 0 N·m at 33 kPa, 800 rpm", "—", @sprintf("%.2f", eta.f(800) * p0 / 33), "")

    errs = Dict(true => Float64[], false => Float64[])
    for c in t.cols, (p, T) in zip(c.p, c.T)
        (first(RPM_GRID) <= c.n <= last(RPM_GRID) && c.floor < T <= full_load_torque(s, c.n)) ||
            continue
        f_src = fuel_of_p_m(eta.f, c.n, p)
        f_tab = table(t, t.fuel, c.n, p_for_torque(t, c.n, T))
        push!(errs[T >= 0], (f_tab - f_src) / f_src)
    end
    e = errs[true]
    band!(@sprintf("Round-trip fuel, T ≥ 0, max |error|, %d points [%%]", length(e)), 0, 5,
        100 * maximum(abs, e), "a few %")
    note!("Round-trip fuel, T ≥ 0, RMS error [%]", "—",
        @sprintf("%.2f", 100 * sqrt(sum(abs2, e) / length(e))), "")
    e = errs[false]
    note!(@sprintf("Round-trip fuel, fired T < 0, max |error|, %d points [%%]", length(e)), "—",
        @sprintf("%.1f", 100 * maximum(abs, e)), "")

    println()
    println(rpad("Check", 58), rpad("Band", 22), rpad("Predicted", 16), rpad("Measured", 16), "Result")
    for (name, band, pred, x, ok) in rows
        result = ismissing(ok) ? "report" : ok ? "pass" : "MISS"
        println(rpad(name, 58), rpad(band, 22), rpad(pred, 16), rpad(x, 16), result)
    end
    return all(r -> ismissing(r[5]) || r[5], rows)
end

# ---------------------------------------------------------------------------------------
# Figures
# ---------------------------------------------------------------------------------------

function figures(dir, s, eta, t)
    mkpath(dir)
    seq = Plots.cgrad(:Blues)
    fl_p = [n > 0 ? p_m_of_fuel(eta.f, n, source_fuel(s, n, T)) : NaN for (n, T) in zip(s.fl_n, s.fl_T)]
    keep = (s.fl_n .>= first(RPM_GRID)) .& (s.fl_T .> 0)

    src_n = filter(>(0), s.n)
    src = [source_fuel(s, n, T) for T in s.T, n in src_n]
    a = Plots.contourf(src_n, s.T, src; c = seq, levels = 20, colorbar_title = "fuel [g/s]",
        xlabel = "speed [rpm]", ylabel = "brake torque [N·m]",
        title = "Source: ALPHA fuel, scaled to 1.5 L", titlefontsize = 10)
    Plots.plot!(a, s.fl_n, s.fl_T; color = :black, lw = 2, label = "full load")
    Plots.plot!(a, s.ct_n, s.ct_T; color = :black, lw = 2, ls = :dash, label = "closed throttle")

    b = Plots.contourf(RPM_GRID, KPA_GRID, permutedims(t.torque); c = seq, levels = 20,
        colorbar_title = "torque [N·m]", xlabel = "speed [rpm]", ylabel = "p_m [kPa]",
        title = "Derived: T_e(N, p_m)", titlefontsize = 10)
    Plots.contour!(b, RPM_GRID, KPA_GRID, permutedims(t.torque); levels = [0.0], color = :white,
        lw = 2, label = "")
    Plots.plot!(b, s.fl_n[keep], fl_p[keep]; color = :black, lw = 2, label = "full load")

    c = Plots.contourf(RPM_GRID, KPA_GRID, permutedims(t.fuel); c = seq, levels = 20,
        colorbar_title = "fuel [g/s]", xlabel = "speed [rpm]", ylabel = "p_m [kPa]",
        title = "Derived: ṁ_f(N, p_m), with the mapped ALPHA points", titlefontsize = 10,
        ylims = (first(KPA_GRID), last(KPA_GRID)))
    Plots.plot!(c, s.fl_n[keep], fl_p[keep]; color = :black, lw = 2, label = "full load")

    for (j, col) in enumerate(t.cols)
        Plots.scatter!(c, fill(col.n, length(col.p)), col.p; ms = 2, color = :black,
            markerstrokewidth = 0, label = j == 1 ? "ALPHA points" : "")
    end

    d = Plots.plot(eta.n, eta.eta; marker = :circle, color = :black, lw = 2, label = "",
        xlabel = "speed [rpm]", ylabel = "η_v [-]", title = "Calibrated η_v (λ = 1 air)",
        titlefontsize = 10, xlims = (first(RPM_GRID), last(RPM_GRID)))
    Plots.hline!(d, [1.0]; color = :gray, ls = :dot, label = "")

    fig = Plots.plot(a, b, c, d; layout = (2, 2), size = (1200, 900), margin = 4Plots.mm)
    Plots.savefig(fig, joinpath(dir, "alpha-maps.png"))

    em = [Plots.contourf(RPM_GRID, KPA_GRID, [ei(n, p) for p in KPA_GRID, n in RPM_GRID];
        c = seq, levels = 20, colorbar_title = "$name [g/kg fuel]", xlabel = "speed [rpm]",
        ylabel = "p_m [kPa]", title = "$name emission index (assumed)", titlefontsize = 10)
          for (name, ei) in (("HC", ei_hc), ("CO", ei_co), ("NOx", ei_nox))]
    Plots.savefig(Plots.plot(em...; layout = (1, 3), size = (1500, 420), margin = 6Plots.mm),
        joinpath(dir, "emissions.png"))
    println("wrote figures to $dir")
end

# ---------------------------------------------------------------------------------------

function main()
    s = scale(read_alpha())
    eta = calibrate(s)
    t = build(s, eta)
    write_tables(s, eta, t)
    FIGURES === nothing || figures(FIGURES, s, eta, t)
    return checks(s, eta, t)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main() || exit(1)
end
