"""
Writes the theory deck's tire-model figures into `slides/decks/lecture-03/public/figures/`:

    julia +dyad-3.5.0 --project=. scripts/export_lecture03_tire_figures.jl

No simulation runs: every curve is a closed-form steady-state tire law, evaluated on a grid.

- `01-tire-models.svg`: friction against braking slip and against slip angle for a few model
  families, each with a published parameter set or fitted to the same initial stiffness;
- `01-locked-wheel-forces.svg`: a hand-drawn top view of a steered front wheel, rolling, braked
  at the peak and locked, its force against the friction circle; the rolling case shows the
  brush model's deflected tread and the pneumatic trail;
- `01-combined-slip.svg`: the planar car's tire at a fixed slip angle, its lateral force falling
  as braking slip grows to a locked wheel;
- `01-lateral-slip.svg`: the planar car's tire in pure side slip, lateral μ against slip angle,
  drawn like the longitudinal μ–slip curve: the linear start, the peak and the sliding level.

The repository's two tire laws are evaluated through `MultibodyComponents.limit_S_triple`, the
function both `Vehicle.Wheel.TireFrictionCurve` (the same cubic, written out) and
`PlanarMechanics.SlipBasedWheelJoint` use, with the parameters of `Vehicle.Wheel.SlipWheel1D`
and of the front wheels of `Vehicle.Planar.PlanarCar`. It prints every number the slides quote.

Parameter sets and their sources, cited in full in `docs/lecture-03-tire-models-research.md`:

- Magic Formula, longitudinal, dry tarmac: B = 10, C = 1.9, D = 1, E = 0.97, the "typical
  coefficients" table of MathWorks' Simscape Driveline `Tire (Magic Formula)` block;
- Magic Formula, lateral: C = 1.3, the side-force shape factor of Bakker, Nyborg and Pacejka,
  SAE 870421 (1987); D = 1, E = 0, B fitted to the planar tire's cornering stiffness;
- Burckhardt, dry asphalt: c1 = 1.2801, c2 = 23.99, c3 = 0.52, from Burckhardt, *Fahrwerktechnik:
  Radschlupf-Regelsysteme* (1993), as tabulated by Kiencke and Nielsen; scaled to a peak of 1;
- brush model with a parabolic pressure distribution (Pacejka, *Tire and Vehicle Dynamics*,
  ch. 3), one friction coefficient of 1, the Magic Formula's slip stiffness BCD = 19 for the
  longitudinal curve and the planar tire's cornering stiffness for the lateral one (Fiala).
"""

using MultibodyComponents: limit_S_triple
using Printf
using Plots

const OUT = normpath(@__DIR__, "..", "slides", "decks", "lecture-03", "public", "figures")

r2(x) = round(x; digits = 2)
r3(x) = round(x; digits = 3) + 0.0  # no "-0.0" in the printout

default(; lw = 2.5, fontfamily = "sans-serif", legend = :topright, titlefontsize = 13,
    guidefontsize = 11, tickfontsize = 10, legendfontsize = 9, left_margin = 6Plots.mm,
    bottom_margin = 5Plots.mm)

function save(plot, name)
    path = joinpath(OUT, "$name.svg")
    savefig(plot, path)
    filesize(path) > 0 || error("$name.svg was written empty")
    println("  $name.svg")
end

# Braking slip s = −κ ≥ 0 throughout; every law returns the friction magnitude.

"""`TireFrictionCurve` with `SlipWheel1D`'s defaults: peak 1.0 at 4 %, sliding 0.7 from 12 %."""
ours_1d(s) = limit_S_triple(0.04, 0.12, 1.0, 0.7, s)

const PLANAR = (; sA = 0.12, sS = 0.36, mu_A = 1.0, mu_S = 0.8, vA_min = 0.05, vS_min = 0.15)

"""
Force of `SlipBasedWheelJoint` per unit normal load, resolved in the wheel frame, for wheel
speed `v` along the heading, braking slip `s` = −κ and slip angle `α`: the friction magnitude
follows the slip speed, normalized by the wheel's circumferential speed, and the force points
against the slip velocity.
"""
function planar_force(s, α; v = 20.0, p = PLANAR)
    rω = v * (1 - s)
    vx_slip = v - rω
    vy_slip = v * tan(α)
    v_slip = hypot(vx_slip, vy_slip) + 1e-4
    vA = max(p.vA_min, p.sA * abs(rω))
    vS = max(p.vS_min, p.sS * abs(rω))
    mu = limit_S_triple(vA, vS, p.mu_A, p.mu_S, v_slip)
    return (; mu, Fx = mu * vx_slip / v_slip, Fy = mu * vy_slip / v_slip)
end
planar_long(s) = planar_force(s, 0.0).mu
planar_lat(α) = planar_force(0.0, α).mu

magic(x; B, C, D, E) = D * sin(C * atan(B * x - E * (B * x - atan(B * x))))
const MF_X = (; B = 10.0, C = 1.9, D = 1.0, E = 0.97)
mf_long(s) = magic(s; MF_X...)

const BURCKHARDT_DRY = (; c1 = 1.2801, c2 = 23.99, c3 = 0.52)
burckhardt_raw(s; c1, c2, c3) = c1 * (1 - exp(-c2 * s)) - c3 * s
const S_BURCKHARDT = log(BURCKHARDT_DRY.c1 * BURCKHARDT_DRY.c2 / BURCKHARDT_DRY.c3) /
                     BURCKHARDT_DRY.c2
const MU_BURCKHARDT = burckhardt_raw(S_BURCKHARDT; BURCKHARDT_DRY...)
burckhardt(s) = burckhardt_raw(s; BURCKHARDT_DRY...) / MU_BURCKHARDT

"""
Brush model, parabolic pressure, one friction coefficient: `stiffness` is the initial slope per
unit theoretical slip `σ` and normal load; full sliding from `|σ| = 3μ / stiffness`.
"""
function brush(σ; stiffness, mu = 1.0)
    θσ = stiffness * abs(σ) / (3mu)
    return θσ >= 1 ? mu : mu * (3θσ - 3θσ^2 + θσ^3)
end
const MF_SLIP_STIFFNESS = MF_X.B * MF_X.C * MF_X.D
# Pacejka's theoretical slip under braking: σ = κ / (1 + κ), unbounded as the wheel locks.
brush_long(s) = s >= 1 ? 1.0 : brush(s / (1 - s); stiffness = MF_SLIP_STIFFNESS)

# The planar tire's cubic rises with slope 1.5 / sA per unit tan α at zero slip.
const CORNERING_STIFFNESS = 1.5 / PLANAR.sA
linear_lat(α) = CORNERING_STIFFNESS * tan(α)
fiala_lat(α) = brush(tan(α); stiffness = CORNERING_STIFFNESS)
const MF_Y = (; C = 1.3, D = 1.0, E = 0.0, B = CORNERING_STIFFNESS / 1.3)
mf_lat(α) = magic(tan(α); MF_Y...)

peak(f, xs) = (i = argmax(f.(xs)); (xs[i], f(xs[i])))

const S = collect(range(0.0, 1.0; length = 2001))
const A = deg2rad.(collect(range(0.0, 20.0; length = 801)))

println("Braking slip −κ, each law's peak and its value at a locked wheel:")
for (label, f) in (("ours, TireFrictionCurve", ours_1d), ("planar car, front", planar_long),
    ("Magic Formula, dry tarmac", mf_long), ("Burckhardt, dry asphalt (scaled)", burckhardt),
    ("brush, μ = 1", brush_long))
    s, mu = peak(f, S)
    println("  $label: peak μ $(r3(mu)) at −κ = $(r3(s)); locked μ $(r3(f(1.0)))")
end
println("  Burckhardt unscaled: peak μ $(r3(MU_BURCKHARDT)) at −κ = $(r3(S_BURCKHARDT)), ",
    "locked $(r3(burckhardt_raw(1.0; BURCKHARDT_DRY...)))")
println("  planar car's peak in κ: −$(r3(PLANAR.sA / (1 + PLANAR.sA))) (σ = $(PLANAR.sA)), ",
    "sliding from −$(r3(PLANAR.sS / (1 + PLANAR.sS)))")
println("  brush slip stiffness $(MF_SLIP_STIFFNESS) per unit slip, full sliding from ",
    "σ = $(r3(3 / MF_SLIP_STIFFNESS)), −κ = $(r3(3 / MF_SLIP_STIFFNESS / (1 + 3 / MF_SLIP_STIFFNESS)))")
println("Slip angle α, each law's peak:")
println("  cornering stiffness $(CORNERING_STIFFNESS) per rad and unit load, ",
    "$(r3(CORNERING_STIFFNESS * π / 180)) per degree; MF lateral B = $(r3(MF_Y.B))")
for (label, f) in (("planar car", planar_lat), ("Magic Formula, C = 1.3", mf_lat),
    ("Fiala brush", fiala_lat))
    α, mu = peak(f, A)
    println("  $label: peak μ_y $(r3(mu)) at α = $(round(rad2deg(α); digits = 1))°")
end
println("  planar car: peak at α = $(round(rad2deg(atan(PLANAR.sA)); digits = 1))°, ",
    "sliding from $(round(rad2deg(atan(PLANAR.sS)); digits = 1))°; Fiala full sliding from ",
    "$(round(rad2deg(atan(3 / CORNERING_STIFFNESS)); digits = 1))°")

mkpath(OUT)

const STYLE = (
    ours = (color = :royalblue, ls = :solid),
    planar = (color = :royalblue, ls = :dash),
    mf = (color = :firebrick, ls = :solid),
    burckhardt = (color = :darkorange, ls = :solid),
    brush = (color = :gray35, ls = :dot),
    linear = (color = :gray35, ls = :dashdot),
)

long = plot(; xlabel = "braking slip −κ [–]", ylabel = "friction coefficient μ_x [–]",
    title = "Braking: μ against slip", ylims = (0, 1.12), xlims = (0, 1), legend = :bottomright)
for (label, f, st) in (("ours: TireFrictionCurve", ours_1d, STYLE.ours),
    ("planar car (front)", planar_long, STYLE.planar),
    ("Magic Formula, dry tarmac", mf_long, STYLE.mf),
    ("Burckhardt, dry asphalt", burckhardt, STYLE.burckhardt),
    ("brush, one μ", brush_long, STYLE.brush))
    plot!(long, S, f.(S); label, st...)
end
lat = plot(; xlabel = "slip angle α [°]", ylabel = "lateral μ_y [–]", title = "Cornering: μ against α",
    ylims = (0, 1.12), xlims = (0, 20), legend = :bottomright)
αd = rad2deg.(A)
plot!(lat, αd, min.(linear_lat.(A), 1.12); label = "linear, C_α", STYLE.linear...)
plot!(lat, αd, planar_lat.(A); label = "planar car", STYLE.planar...)
plot!(lat, αd, mf_lat.(A); label = "Magic Formula, C = 1.3", STYLE.mf...)
plot!(lat, αd, fiala_lat.(A); label = "Fiala brush", STYLE.brush...)
fig = plot(long, lat; layout = grid(1, 2, widths = [0.6, 0.4]), size = (960, 400), dpi = 100)
save(fig, "01-tire-models")

const ALPHA_DEG = 4.0
const ALPHA = deg2rad(ALPHA_DEG)
const KAPPA_ABS = 0.08
cases = (
    rolling = planar_force(0.0, ALPHA),
    abs = planar_force(KAPPA_ABS, ALPHA),
    locked = planar_force(1.0, ALPHA),
)
println("Front wheel at α = $(ALPHA_DEG)°, 20 m/s, forces per unit normal load in the wheel frame:")
for (name, c) in pairs(cases)
    # Across the path: the component perpendicular to the travel direction.
    across = c.Fy * cos(ALPHA) - c.Fx * sin(ALPHA)
    along = c.Fx * cos(ALPHA) + c.Fy * sin(ALPHA)
    println("  $name: |F|/F_z $(r3(c.mu)), F_x $(r3(c.Fx)), F_y $(r3(c.Fy)); ",
        "against the travel $(r3(along)), across it $(r3(across)), ",
        "direction $(round(rad2deg(atan(c.Fy, c.Fx)); digits = 1))° from the heading")
end

"""
Brush model in pure side slip (Pacejka, ch. 3): parabolic pressure over the patch `ξ = x/a` in
[−1, 1], leading edge at ξ = 1. The tread tip sticks to the road and deflects in proportion to
the distance from the leading edge until the deflection force reaches μ times the local pressure;
behind that point it slides. Returns the force density per `μ F_z / a` along the patch, the
lateral force per `μ F_z`, the resultant's position ξ (negative: behind the center) and where
sliding starts.
"""
function brush_patch(tanα; stiffness = CORNERING_STIFFNESS, n = 401)
    θσ = stiffness * tanα / 3
    ξ = collect(range(-1.0, 1.0; length = n))
    q = @. 0.75 * min(2θσ * (1 - ξ), 1 - ξ^2)
    w = fill(step(range(-1.0, 1.0; length = n)), n)
    w[[1, end]] ./= 2
    Fy = sum(w .* q)
    return (; ξ, q, Fy, ξ_res = sum(w .* ξ .* q) / Fy, ξ_slide = min(2θσ - 1, 1.0))
end
patch = brush_patch(tan(ALPHA))
println("Brush model at α = $(ALPHA_DEG)°, same cornering stiffness, μ = 1: F_y $(r3(patch.Fy)) μF_z ",
    "(closed form $(r3(fiala_lat(ALPHA)))), sliding behind ξ = $(r3(patch.ξ_slide)), ",
    "resultant at ξ = $(r3(patch.ξ_res)): pneumatic trail $(r3(-patch.ξ_res)) a ",
    "(a/3 = 0.333 a in the small-angle limit)")

"""
Top view of one steered wheel, travel straight up the page. Hand-written SVG: the contact patch,
the arrows, the angle arc and the friction circle read better drawn than plotted.
"""
function locked_wheel_svg(cases, patch)
    W, H = 960, 470
    R = 110.0
    L, Wd = 92.0, 30.0       # half length and width of the drawn tire, in px
    A = 70.0                 # half length of the drawn contact patch (not to scale)
    DEFLECT = 24.0           # drawn tread deflection at the force density's maximum
    io = IOBuffer()
    blue, red, gray, ink, tread = "#4169e1", "#b22222", "#7f7f7f", "#262626", "#2e8b57"
    print(io, """
    <svg xmlns="http://www.w3.org/2000/svg" width="$W" height="$H" viewBox="0 0 $W $H" font-family="sans-serif">
    <rect width="$W" height="$H" fill="#ffffff"/>
    <defs>
    """)
    for (id, c) in (("ink", ink), ("blue", blue), ("red", red), ("gray", gray), ("tread", tread))
        print(io, """<marker id="h-$id" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="$c"/></marker>\n""")
    end
    print(io, "</defs>\n")
    arrow(x1, y1, x2, y2, color, id; w = 3.5, dash = "") = print(io,
        """<line x1="$(r2(x1))" y1="$(r2(y1))" x2="$(r2(x2))" y2="$(r2(y2))" stroke="$color" stroke-width="$w"$(dash == "" ? "" : " stroke-dasharray=\"$dash\"") marker-end="url(#h-$id)"/>\n""")
    # "F_y" and "μ_A" are written with SVG subscripts.
    sub(s, size) = replace(s, r"_(\w+)" => SubstitutionString(
        "<tspan baseline-shift=\"sub\" font-size=\"$(round(Int, 0.7size))\">\\1</tspan>"))
    text(x, y, s; size = 15, color = ink, anchor = "middle", weight = "normal") = print(io,
        """<text x="$(r2(x))" y="$(r2(y))" font-size="$size" fill="$color" text-anchor="$anchor" font-weight="$weight">$(sub(s, size))</text>\n""")
    poly(pts; fill = "none", stroke = ink, w = 1.0, extra = "") = print(io,
        """<polygon points="$(join(["$(r2(x)),$(r2(y))" for (x, y) in pts], " "))" fill="$fill" stroke="$stroke" stroke-width="$w" $extra/>\n""")
    polyline(pts; stroke = ink, w = 1.0, extra = "") = print(io,
        """<polyline points="$(join(["$(r2(x)),$(r2(y))" for (x, y) in pts], " "))" fill="none" stroke="$stroke" stroke-width="$w" $extra/>\n""")

    titles = ("(a) rolling, steered", "(b) braking at the peak, ABS", "(c) the same wheel, locked")
    deg = round(Int, ALPHA_DEG)
    captions = (
        (@sprintf("tread sticks and bends: F_y = %.2f μF_z,", patch.Fy),
            @sprintf("acting a trail t = %.2f a behind the center", -patch.ξ_res)),
        (@sprintf("κ = −%.2f: F_x = %.2f F_z, F_y = %.2f F_z", KAPPA_ABS, cases.abs.Fx, cases.abs.Fy),
            @sprintf("resultant %.2f F_z, at the circle's edge", cases.abs.mu)),
        (@sprintf("κ = −1: the whole patch slides at v; %.2f F_z", cases.locked.mu),
            "straight back along −v, nothing across the path"),
    )
    for k in 1:3
        cx, cy = 160.0 + 320.0 * (k - 1), 225.0
        text(cx, 28, titles[k]; size = 17, weight = "bold")
        print(io, """<circle cx="$cx" cy="$cy" r="$R" fill="#f4f6fb" stroke="$gray" stroke-width="1.5" stroke-dasharray="6 4"/>\n""")
        print(io, """<circle cx="$cx" cy="$cy" r="$(r2(0.8R))" fill="none" stroke="$gray" stroke-width="1" stroke-dasharray="2 4"/>\n""")
        # Wheel frame on screen (y grows downward): h the heading, turned left by α; n its left.
        hx, hy = -sin(ALPHA), -cos(ALPHA)
        nx, ny = -cos(ALPHA), sin(ALPHA)
        at(u, v) = (cx + u * hx + v * nx, cy + u * hy + v * ny)
        poly([at(L, Wd / 2), at(L, -Wd / 2), at(-L, -Wd / 2), at(-L, Wd / 2)];
            fill = "#d9d9d9", stroke = ink, w = 1.2)
        poly([at(A, Wd / 2), at(A, -Wd / 2), at(-A, -Wd / 2), at(-A, Wd / 2)];
            fill = "#ffffff", stroke = ink, w = 1.0, extra = "stroke-dasharray=\"3 2\"")
        polyline([at(-1.32R, 0), at(1.32R, 0)]; w = 1.2, extra = "stroke-dasharray=\"8 5\"")
        text(at(1.36R, 0)[1] - 4, at(1.36R, 0)[2] - 4, "heading"; size = 13, anchor = "end")
        # Travel: a thin line through the center, and v drawn beside the wheel to keep it clear.
        polyline([(cx, cy + 1.32R), (cx, cy - 1.32R)]; stroke = gray, w = 1.2)
        arrow(cx + 0.8R, cy + 0.25R, cx + 0.8R, cy - 0.55R, gray, "gray"; w = 3)
        text(cx + 0.8R + 8, cy - 0.45R, "v"; size = 15, color = gray, anchor = "start", weight = "bold")
        text(cx + 5, cy - 1.25R, "travel"; size = 13, color = gray, anchor = "start")
        ra = 1.0R
        print(io, """<path d="M $(cx) $(r2(cy - ra)) A $ra $ra 0 0 0 $(r2(cx + ra * hx)) $(r2(cy + ra * hy))" fill="none" stroke="$ink" stroke-width="1.2"/>\n""")
        text(cx - 0.06R, cy - 1.05R, "α"; size = 15, anchor = "end")
        if k == 1
            # Tread tips: deflected toward the wheel's left, more and more toward the rear.
            tips = [at(A * ξ, DEFLECT * q / maximum(patch.q)) for (ξ, q) in zip(patch.ξ, patch.q)]
            poly(vcat([at(A, 0.0), at(-A, 0.0)], reverse(tips)); fill = tread, stroke = "none",
                extra = "fill-opacity=\"0.18\"")
            polyline(tips; stroke = tread, w = 2.2)
            for ξ in -0.8:0.2:0.8
                i = argmin(abs.(patch.ξ .- ξ))
                polyline([at(A * ξ, 0.0), tips[i]]; stroke = tread, w = 1)
            end
            text(at(-A, 0)[1] - 2, at(-A, 0)[2] + 30, "tread, deflection exaggerated"; size = 12,
                color = tread, anchor = "middle")
            # The resultant acts the trail behind the center, across the wheel.
            px, py = at(A * patch.ξ_res, 0.0)
            arrow(px, py, px + patch.Fy * R * nx, py + patch.Fy * R * ny, blue, "blue"; w = 4.5)
            text(px + patch.Fy * R * nx + 2, py + patch.Fy * R * ny - 14, "F_y"; color = blue,
                anchor = "middle", weight = "bold")
            # Trail marker: from the center back to the force's line of action, beside the tire.
            t1, t2 = at(0.0, -Wd / 2 - 8), at(A * patch.ξ_res, -Wd / 2 - 8)
            polyline([at(0.0, -Wd / 2 - 3), at(0.0, -Wd / 2 - 13)]; w = 1.2)
            polyline([at(A * patch.ξ_res, -Wd / 2 - 3), at(A * patch.ξ_res, -Wd / 2 - 13)]; w = 1.2)
            polyline([t1, t2]; w = 1.5)
            text(t1[1] + 8, (t1[2] + t2[2]) / 2 + 5, "trail t"; size = 14, anchor = "start", weight = "bold")
            print(io, """<circle cx="$(r2(cx))" cy="$(r2(cy))" r="2.5" fill="$ink"/>\n""")
        elseif k == 2
            c = cases.abs
            arrow(cx, cy, cx - c.Fx * hx * R, cy - c.Fx * hy * R, blue, "blue"; w = 2.5, dash = "5 3")
            arrow(cx, cy, cx + c.Fy * nx * R, cy + c.Fy * ny * R, blue, "blue"; w = 2.5, dash = "5 3")
            text(cx - c.Fx * hx * R + 26, cy - c.Fx * hy * R + 4, "F_x"; color = blue, anchor = "start")
            text(cx + c.Fy * nx * R - 4, cy + c.Fy * ny * R - 10, "F_y"; color = blue, anchor = "end")
            ex, ey = (-c.Fx * hx + c.Fy * nx) * R, (-c.Fx * hy + c.Fy * ny) * R
            arrow(cx, cy, cx + ex, cy + ey, blue, "blue"; w = 4.5)
            text(cx + ex - 8, cy + ey - 8, "F"; color = blue, anchor = "end", weight = "bold")
        else
            c = cases.locked
            ex, ey = (-c.Fx * hx + c.Fy * nx) * R, (-c.Fx * hy + c.Fy * ny) * R
            arrow(cx, cy, cx + ex, cy + ey, red, "red"; w = 4.5)
            text(cx + ex + 24, cy + ey + 4, "F, along −v"; color = red, anchor = "start", weight = "bold")
        end
        text(cx, cy + R + 50, captions[k][1]; size = 14)
        text(cx, cy + R + 70, captions[k][2]; size = 14)
    end
    text(W / 2, H - 10, "dashed circle μ_A F_z, the most the tire gives; dotted μ_S F_z, sliding. " *
        "α = $(deg)°, 20 m/s. (a) brush model, Pacejka ch. 3; (b), (c) the planar car's tire.";
        size = 12, color = gray)
    print(io, "</svg>\n")
    return String(take!(io))
end

path = joinpath(OUT, "01-locked-wheel-forces.svg")
write(path, locked_wheel_svg(cases, patch))
println("  01-locked-wheel-forces.svg")

const S_COMBINED = collect(range(0.0, 1.0; length = 2001))
comb = [planar_force(s, ALPHA) for s in S_COMBINED]
across = [c.Fy * cos(ALPHA) - c.Fx * sin(ALPHA) for c in comb]
println("Planar tire at α = $(ALPHA_DEG)°, F_y/F_z against braking slip:")
for s in (0.0, 0.04, 0.08, 0.107, 0.2, 0.5, 0.9, 1.0)
    c = planar_force(s, ALPHA)
    println("  −κ = $s: F_x $(r3(c.Fx)), F_y $(r3(c.Fy)), across the path ",
        "$(r3(c.Fy * cos(ALPHA) - c.Fx * sin(ALPHA)))")
end
cs = plot(; xlabel = "braking slip −κ [–]", ylabel = "force / F_z [–]",
    title = "Planar car's tire at α = $(round(Int, ALPHA_DEG))°: braking takes the lateral force away",
    size = (960, 400), dpi = 100, xlims = (0, 1), ylims = (-0.05, 1.05), legend = :right)
plot!(cs, S_COMBINED, getfield.(comb, :Fx); label = "F_x, braking", color = :royalblue)
plot!(cs, S_COMBINED, getfield.(comb, :Fy); label = "F_y, across the wheel", color = :firebrick)
plot!(cs, S_COMBINED, across; label = "across the path", color = :firebrick, ls = :dash)
vline!(cs, [PLANAR.sA / (1 + PLANAR.sA)]; color = :gray, ls = :dot, label = "")
annotate!(cs, PLANAR.sA / (1 + PLANAR.sA) + 0.01, 0.06,
    Plots.text("peak, −κ = 0.107", 9, :left, :gray25))
save(cs, "01-combined-slip")

const A_LAT = deg2rad.(collect(range(0.0, 30.0; length = 1201)))
α_peak = atan(PLANAR.sA)
α_slide = atan(PLANAR.sS)
println("Planar tire in pure side slip: peak μ_y $(r3(planar_lat(α_peak))) at ",
    "$(round(rad2deg(α_peak); digits = 1))°, sliding $(r3(planar_lat(α_slide))) from ",
    "$(round(rad2deg(α_slide); digits = 1))°; at 2°: linear $(r3(linear_lat(deg2rad(2)))), ",
    "tire $(r3(planar_lat(deg2rad(2))))")
ls = plot(; xlabel = "slip angle α [°]", ylabel = "lateral friction coefficient μ_y [–]",
    title = "Cornering: the same curve, against slip angle", size = (640, 420), dpi = 100,
    xlims = (0, 30), ylims = (0, 1.12), legend = :bottomright)
vspan!(ls, [rad2deg(α_peak), 30]; color = :firebrick, alpha = 0.07, label = "more angle, less force")
A_LIN = filter(α -> linear_lat(α) <= 1.12, A_LAT)
plot!(ls, rad2deg.(A_LIN), linear_lat.(A_LIN); label = "F_y = C_α α, small angles", STYLE.linear...)
plot!(ls, rad2deg.(A_LAT), planar_lat.(A_LAT); label = "planar car's tire", color = :black)
scatter!(ls, [rad2deg(α_peak)], [planar_lat(α_peak)]; color = :firebrick, ms = 6, label = "")
annotate!(ls, rad2deg(α_peak) + 1, 1.05,
    Plots.text("peak μ_y = 1.0 at α = $(round(rad2deg(α_peak); digits = 1))°", 9, :left, :firebrick))
annotate!(ls, 29.5, planar_lat(α_slide) - 0.06,
    Plots.text("sliding μ_y = $(r2(planar_lat(α_slide))) from $(round(Int, rad2deg(α_slide)))°", 9,
        :right, :gray25))
save(ls, "01-lateral-slip")
