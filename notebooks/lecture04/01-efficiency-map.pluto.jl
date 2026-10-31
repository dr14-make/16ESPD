### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ 6c44a3e1-3367-4336-9494-8a30dc124a47
begin
    import Pkg
    Pkg.activate(joinpath(@__DIR__, "..", ".."))
    include(joinpath(@__DIR__, "..", "lecture01", "support.jl"))
    using .Lecture01Support
    # The dyad-3.5 kernel ships Plots with the plotly backend and Kaleido, but not GR.
    VehicleSystemsComponents = setup(backend = :plotly)
    using ModelingToolkit, Plots
    using DyadInterface: symbolic_container
    using PlutoUI
    using DelimitedFiles: readdlm
    import Contour
end

# ╔═╡ ee4970e4-3c9c-4222-9c66-48d7c5668af2
md"""
# Lecture 4 — The efficiency map

The machine of build steps 1–2, a DC-equivalent machine whose flux the average converter turns
down above base speed, has no efficiency map anywhere in its source. Its losses are parts: the
armature resistance, bearing friction, iron loss, windage and a constant loss in the machine;
conduction and switching in the converter. The map is what those parts add up to, and this
notebook draws it:

1. the envelope the converter's current and voltage limits leave the machine;
2. the combined (machine + converter) efficiency over that envelope, computed by sweeping the
   models on a dyno;
3. where WLTC puts the machine on that map, driving and regenerating;
4. the map beside ORNL's measured map of the 2012 Leaf.

Every number below is read from a simulation of the Dyad models shown, except ORNL's, which are
digitized from their published figure.
"""

# ╔═╡ 8c56ef28-cc25-4ef4-8ed5-0989599ae94f
show_dyad("TestConverter")

# ╔═╡ bdfee813-f445-42dc-900e-aa92a4b2a550
md"""
### Experiment

**DC-link voltage** `V_dc`, in volts: 350 V is the ZE1 pack's nominal voltage. A sagging or
nearly empty battery gives the converter less, and the corner of the envelope moves with it.
"""

# ╔═╡ 23ab620b-3d46-4890-b359-0c166e13d2b5
@bind V_dc Slider(300.0:10.0:400.0; default = 350.0, show_value = true)

# ╔═╡ 263626fe-aef7-4320-80e2-25284114090b
begin
    PL = VehicleSystemsComponents.Vehicle.Planar
    # The sweep is shared with the lecture04 test group, which checks the bands on it.
    include(joinpath(@__DIR__, "efficiency_map.jl"))
    using .EfficiencyMap
end

# ╔═╡ 302c05d9-de94-47dd-a0c7-1cda2f29c1c1
begin
    # Contour levels in percent; ORNL's color scale runs from 70 to 99.
    LEVELS = [70, 80, 85, 88, 90, 92, 94, 95, 96]
    CLIMS = (70.0, 97.0)

    """
    `Z` with every NaN cell (outside the measured or reachable region) replaced by its nearest
    value in the same column, and all-NaN columns by the nearest filled column: something to
    contour and color without tracing the region's edge. Plotly's JSON rejects NaN anyway.
    """
    function fill_nan(Z)
        F = copy(Z)
        for j in axes(F, 2)
            valid = findall(!isnan, Z[:, j])
            isempty(valid) && continue
            for i in axes(F, 1)
                isnan(F[i, j]) && (F[i, j] = Z[valid[argmin(abs.(valid .- i))], j])
            end
        end
        filled = findall(j -> !all(isnan, F[:, j]), axes(F, 2))
        for j in axes(F, 2)
            all(isnan, F[:, j]) && (F[:, j] = F[:, filled[argmin(abs.(filled .- j))]])
        end
        return F
    end

    """
    Mean of the non-NaN cells within `k` cells of each non-NaN cell. Digitized bands are flat
    steps and the contour labels leave specks; ORNL's map is drawn from this.
    """
    function box_mean(Z, k)
        M = similar(Z)
        for I in CartesianIndices(Z)
            isnan(Z[I]) && (M[I] = NaN; continue)
            w = filter(!isnan, Z[max(I[1] - k, 1):min(I[1] + k, end), max(I[2] - k, 1):min(I[2] + k, end)])
            M[I] = sum(w) / length(w)
        end
        return M
    end

    """
    Contour lines of `Z` (rows over `y`, columns over `x`) at `levels`, one polyline per piece.
    Vertices in a NaN cell of `Z` are cut out, so lines stop at the region's edge. Each level
    is labeled where it passes closest to the torque `label_y(k)`, `k` its index in `levels`,
    once in each quadrant it reaches: a label height that falls with the level keeps the labels
    of the closely spaced low-speed lines apart.
    """
    function contour_lines(x, y, Z, levels; label_y = k -> 290.0 - 22.0 * (k - 1))
        F = fill_nan(Z)
        inside(px, py) = !isnan(Z[argmin(abs.(y .- py)), argmin(abs.(x .- px))])
        map(enumerate(levels)) do (k, lv)
            pieces = Vector{Tuple{Vector{Float64}, Vector{Float64}}}()
            for line in Contour.lines(Contour.contour(x, y, permutedims(F), lv))
                lx, ly = Contour.coordinates(line)
                keep = inside.(lx, ly)
                a = 1
                while a <= length(lx)
                    keep[a] || (a += 1; continue)
                    e = something(findnext(!, keep, a), length(lx) + 1) - 1
                    e > a && push!(pieces, (lx[a:e], ly[a:e]))
                    a = e + 1
                end
            end
            labels = Tuple{Float64, Float64}[]
            for sgn in (1, -1)
                pts = [(px, py) for (lx, ly) in pieces for (px, py) in zip(lx, ly) if sgn * py > 0]
                isempty(pts) && continue
                push!(labels, pts[argmin([abs(py - sgn * label_y(k)) for (_, py) in pts])])
            end
            (; level = lv, pieces, labels)
        end
    end

    """
    Draw an efficiency map into subplot `sp`: the efficiency in percent as color on `CLIMS`,
    the `LEVELS` as labeled black lines, and the region outside the map covered by the white
    `mask` shapes.
    """
    function map_panel!(p, sp, x, y, Z; mask = Shape[], colorbar = true,
            label_y = k -> 290.0 - 22.0 * (k - 1))
        F = fill_nan(Z)
        heatmap!(p[sp], x, y, F; c = :viridis, clims = CLIMS, colorbar,
            colorbar_title = colorbar ? "combined efficiency [%]" : "", label = "")
        # Plots transposes a heatmap's matrix for a JSON writer that wrote matrices column by
        # column; the JSON 1.x on the dyad-3.5 kernel writes them row by row, so the transpose
        # is undone here or plotly draws the map on its side.
        p[sp].series_list[end][:z] = Plots.Surface(permutedims(F))
        for m in mask
            plot!(p[sp], m; color = :white, linealpha = 0, fillalpha = 1, label = "")
        end
        for c in contour_lines(x, y, Z, LEVELS; label_y)
            for (lx, ly) in c.pieces
                plot!(p[sp], lx, ly; color = :black, lw = 0.8, label = "")
            end
            annotate!(p[sp], [(xy..., text("$(c.level)", 9, :black)) for xy in c.labels])
        end
        return p
    end
end

# ╔═╡ 89bb3753-dfd2-4de3-a4a7-db262f6ddf0d
emap = efficiency_map(; V = V_dc);

# ╔═╡ 48c77b66-1b3c-4519-83d3-c421d7806fea
"White shapes over the torques the machine cannot reach: above its motoring and below its generating limit."
envelope_mask(map) = let n = collect(map.rpm)
    [Shape(vcat(n, reverse(n)), vcat(map.tau_max, fill(400.0, length(n)))),
        Shape(vcat(n, reverse(n)), vcat(map.tau_min, fill(-400.0, length(n))))]
end

# ╔═╡ 25650f35-aed9-4f13-869b-bda4e31002f3
md"""
## 1. The envelope

Asked for more current than its limit, the converter delivers `I_max` at every speed. Up to
**base speed** the field is full and the duty rises with the back-EMF: the torque is
`k·I_max` less the shaft losses, constant. At base speed the duty reaches 1 and the voltage has
run out. Above it the converter holds the duty at 1 and turns the field down as 1/ω, so the
torque falls as 1/ω and the power stays constant: **field weakening**. The machine's top speed
is set by the car, 144 km/h through the 8.193 reduction on a 0.31 m wheel.
"""

# ╔═╡ 3cb1f373-af79-4d0b-b685-804f8a23229d
envelope = let
    rpm = collect(1.0:1.0:RPM_MAX)
    full = ramp_line(last(CURRENTS), rpm; V = V_dc)
    # Base speed: where the converter starts to weaken the field. Above it the field falls as
    # 1/ω, so field·rpm at the first weakened point is the corner itself, not a point past it.
    i = findfirst(<(0.999), full.field)
    (; rpm, full, n_base = full.field[i] * rpm[i])
end;

# ╔═╡ 0e27565e-4372-4915-ba42-bf2bc1efdc83
envelope_plot = let
    # Every 10th rpm: the curves are smooth, and the SVG carries every point.
    rpm, tau = envelope.rpm[1:10:end], envelope.full.tau[1:10:end]
    n_base = envelope.n_base
    P = tau .* rpm .* pi ./ 30 ./ 1e3
    p = plot(layout = (2, 1), size = (960, 600), link = :x, legend = :right)
    for (sp, top) in ((1, 400.0), (2, 130.0))
        plot!(p[sp], Shape([0, n_base, n_base, 0], [0, 0, top, top]); color = 1,
            fillalpha = 0.10, linealpha = 0, label = "")
        plot!(p[sp], Shape([n_base, RPM_MAX, RPM_MAX, n_base], [0, 0, top, top]); color = 2,
            fillalpha = 0.10, linealpha = 0, label = "")
        vline!(p[sp], [n_base]; color = :black, ls = :dash, lw = 1, label = "")
        vline!(p[sp], [RPM_MAX]; color = :black, ls = :dot, lw = 1, label = "")
        ylims!(p[sp], 0, top)
    end
    plot!(p[1], rpm, tau; color = :black, lw = 2.5, label = "", ylabel = "shaft torque [N·m]")
    plot!(p[2], rpm, P; color = :black, lw = 2.5, label = "", ylabel = "shaft power [kW]",
        xlabel = "machine speed [rpm]")
    plot!(p[1], rpm[rpm .> n_base], tau[findfirst(>(n_base), rpm)] .* n_base ./ rpm[rpm .> n_base];
        color = :gray, ls = :dash, lw = 1, label = "1/ω")
    annotate!(p[1], [
        (n_base / 2, 380, text("constant torque", 11, :center)),
        (n_base / 2, 352, text("full field, duty rising", 9, :center)),
        ((n_base + RPM_MAX) / 2, 380, text("field weakening: constant power", 11, :center)),
        ((n_base + RPM_MAX) / 2, 352, text("duty at 1, field falling as 1/ω", 9, :center)),
        (n_base, 20, text(" base speed $(round(Int, n_base)) rpm", 10, :left)),
        (RPM_MAX, 20, text("max speed $(round(Int, RPM_MAX)) rpm ", 10, :right)),
    ])
    annotate!(p[2], [
        (n_base, 118, text(" $(round(P[findfirst(>=(n_base), rpm)]; digits = 1)) kW at base speed", 10, :left)),
    ])
    xlims!(p[1], 0, RPM_MAX + 100)
    xlims!(p[2], 0, RPM_MAX + 100)
    p
end

# ╔═╡ b1fb1251-8c9a-4729-b491-721b1d0545d5
let
    (; rpm, full, n_base) = envelope
    md"""
    At $(V_dc) V the converter's $(full.I) A give **$(round(full.tau[findfirst(>=(1000), rpm)]; digits = 1)) N·m**
    at 1000 rpm, the voltage runs out at **$(round(Int, n_base)) rpm** (the ZE1's base speed is
    3283 rpm at 350 V), and at $(round(Int, RPM_MAX)) rpm the field is down to
    **$(round(full.field[end]; digits = 3))** and the torque to **$(round(full.tau[end]; digits = 1)) N·m**.
    The dip below 100 rpm is the machine's constant loss `C`, a torque `C/ω` that fades to zero
    below `w_reg` so that standstill costs no infinite torque.
    """
end

# ╔═╡ b1d1088a-eb1a-4bac-98e1-d1302a2e9123
md"""
## 2. The efficiency map

The same dyno bench, run once per output current from −332 A to +332 A, 63 ramps in all. Along
each ramp every saved point is a steady operating point: the current is held, the field and
duty are algebraic, and the only transient is the rotor's J dω/dt, which is handed back to the
shaft. At each speed the DC-link power is then resampled onto a regular torque grid, and the
combined efficiency is the shaft power over the DC-link power while motoring, the DC-link power
over the shaft power while generating. Nothing in the models is a map; this is.
"""

# ╔═╡ 5f65ee53-fe98-42d2-936f-4e72171c28ab
map_plot = let
    p = plot(size = (960, 600), xlabel = "machine speed [rpm]", ylabel = "shaft torque [N·m]",
        title = "machine + converter at $(round(Int, emap.V)) V: motoring above zero, generating below")
    map_panel!(p, 1, collect(emap.rpm), collect(emap.torque), 100 .* emap.eta;
        mask = envelope_mask(emap))
    plot!(p, emap.rpm, emap.tau_max; color = :black, lw = 2, label = "")
    plot!(p, emap.rpm, emap.tau_min; color = :black, lw = 2, label = "")
    hline!(p, [0.0]; color = :white, lw = 0.5, label = "")
    xlims!(p, 0, RPM_MAX); ylims!(p, -340, 340)
    p
end

# ╔═╡ 9de5f689-a602-4f10-ae56-c99c8db187e3
md"""
### The plan's three bands

ORNL's measured map of the 2012 Leaf sets three bands for the combined efficiency (lecture plan,
reality anchors): 94–96 % mid speed and mid torque, about 80 % at low speed and high torque, and
70–80 % near zero torque.
"""

# ╔═╡ 46c2c26d-dbd4-4653-be5d-593b3443e24a
BANDS = [
    (name = "mid map", band = (94, 96), points = [(4000, 100), (5000, 100), (7300, 85)]),
    (name = "low speed, high torque", band = (78, 82), points = [(900, 180), (1000, 220)]),
    (name = "near zero torque (5 N·m)", band = (70, 80), points = [(3000, 5), (5000, 5), (7000, 5), (9000, 5)]),
];

# ╔═╡ a31a4b57-277c-41a5-840e-26bc86e070fa
let
    rows = String[]
    for b in BANDS, (n, T) in b.points
        e = 100 * eta_at(emap, n, T)
        ok = b.band[1] <= e <= b.band[2] ? "in" : "**outside**"
        push!(rows, "| $(b.name) | $n | $T | $(round(e; digits = 1)) | $(b.band[1])–$(b.band[2]) | $ok |")
    end
    n80 = let ns = 300.0:10.0:3000.0
        ns[findfirst(n -> eta_at(emap, n, 220.0) >= 0.80, ns)]
    end
    Markdown.parse("""
    | band | rpm | N·m | model η [%] | ORNL band [%] | |
    |:---|---:|---:|---:|---:|:---|
    $(join(rows, "\n"))

    The middle of the map lands in ORNL's 94–96 % band, and the near-zero-torque floor in its
    70–80 % band, at its bottom edge: at 5 N·m the model gives 69–72 %, just under 70 % at
    3000 rpm, where the constant loss weighs most against the shaft power.

    Low speed and high torque misses: the model gives about 86 % where ORNL measured 80 %, six
    points high, and reaches 80 % at 220 N·m only at $(round(Int, n80)) rpm. The machine alone
    sits at the low end of ORNL's motor-only map there (88 % at 1000 rpm and 220 N·m against
    ORNL's 88–93 %), so the gap is the converter: its losses track only the current, and it stays
    at 97.5 % with 113 V out, where ORNL's measured inverter falls into the 80s below about
    1000 rpm. ORNL's machine also gave only 280 N·m, so 180 N·m was 64 % of its peak against 56 %
    of this one's, and copper loss grows with the square of that share. The parameters stay as
    they are, fitted to the motor-only and inverter-only maps: the miss shows what an average
    converter with current-proportional losses leaves out at low output voltage. The lecture
    plan lists the gap under Known limits.
    """)
end

# ╔═╡ 30815e0e-f523-4902-b831-6a18a637c754
md"""
## 3. Where WLTC puts the machine

The Leaf-class car of steps 1–5 with regenerative braking (`PlanarBEVRegenWLTC`) drives WLTC
class 3b, and its machine's speed and torque are read once a second. Each dot is one second of
the cycle, driving or braking. The map is the 350 V map; on the cycle the battery's terminal
voltage moves between 336 and 358 V, which shifts the corner by a few percent and the
efficiency inside the envelope by much less.
"""

# ╔═╡ 0b3fd999-30a8-4d5d-ae5a-1a2bb062a3de
wltc = let
    r = PL.PlanarBEVRegenWLTCTransient()
    m = symbolic_container(r)
    ts = 0.0:1.0:1800.0
    rpm = r.sol(ts, idxs = m.drive.machine.w).u .* 30 ./ pi
    tau = r.sol(ts, idxs = m.drive.machine.tau).u
    P_in = r.sol(ts, idxs = m.drive.converter.P_in).u
    P_mech = tau .* rpm .* pi ./ 30
    moving = rpm .> 50
    mot = moving .& (P_mech .> 0) .& (P_in .> 0)
    gen = moving .& (P_mech .< 0) .& (P_in .< 0)
    (; rpm, tau, P_in, P_mech, mot, gen,
        eta_mot = sum(P_mech[mot]) / sum(P_in[mot]), eta_gen = sum(P_in[gen]) / sum(P_mech[gen]))
end;

# ╔═╡ 7fa3b4c5-d987-42f0-9fb5-436efd9aab73
wltc_plot = let
    (; rpm, tau, mot, gen) = wltc
    p = plot(size = (960, 600), xlabel = "machine speed [rpm]", ylabel = "shaft torque [N·m]",
        title = "WLTC class 3b on the map, one dot per second", legend = :bottomright)
    map_panel!(p, 1, collect(emap.rpm), collect(emap.torque), 100 .* emap.eta;
        mask = envelope_mask(emap))
    plot!(p, emap.rpm, emap.tau_max; color = :black, lw = 2, label = "")
    plot!(p, emap.rpm, emap.tau_min; color = :black, lw = 2, label = "")
    scatter!(p, rpm[mot], tau[mot]; ms = 2.5, color = :white, markerstrokecolor = :black,
        markerstrokewidth = 0.5, label = "driving")
    scatter!(p, rpm[gen], tau[gen]; ms = 2.5, color = :orangered, markerstrokecolor = :black,
        markerstrokewidth = 0.5, label = "regenerating")
    xlims!(p, 0, RPM_MAX); ylims!(p, -340, 340)
    p
end

# ╔═╡ c698a095-74a1-49df-81c4-ffbf6104f632
let
    (; tau, mot, gen, eta_mot, eta_gen) = wltc
    pct(x) = round(100 * x; digits = 1)
    md"""
    WLTC asks the machine for at most **$(round(maximum(tau); digits = 0)) N·m** driving and
    **$(round(-minimum(tau); digits = 0)) N·m** braking, a third of what it can give. Half of the
    driving seconds sit below **$(round(sort(tau[mot])[end ÷ 2]; digits = 0)) N·m**, at the bottom
    of the map where the fixed losses take their share: the energy-weighted combined efficiency
    over the cycle is **$(pct(eta_mot)) %** driving and **$(pct(eta_gen)) %** regenerating, below the
    map's 95 % peak. That is why the near-zero-torque band matters more for the energy bill than
    the peak island: the cycle lives where the map is worst.
    """
end

# ╔═╡ a54ac7a3-dc08-41df-b95a-b0a0cb69e069
md"""
## 4. Against ORNL's measured Leaf map

Oak Ridge National Laboratory benchmarked the 2012 Nissan Leaf's motor and inverter on a dyno
and published the combined (motor + inverter) efficiency map: T. Burress, *Benchmarking
State-of-the-Art Technologies*, DOE Vehicle Technologies Annual Merit Review 2013, project
APE006, slide 12
([PDF](https://www.energy.gov/sites/prod/files/2014/03/f13/ape006_burress_2013_o.pdf)). It was
measured at a 375 V DC link, 5 kHz switching and 65 °C coolant.

The right panel below is that map redrawn from values digitized off the published figure
(`data/ornl_leaf/`, written by `scripts/digitize_ornl_leaf_map.py`; within about one point), each
value averaged over ±200 rpm and ±5 N·m to wash out the figure's contour labels. It
is the **80 kW / 280 N·m first-generation motor** of the 2012 car, not the 110 kW / 320 N·m ZE1
machine this model is parameterized for, so the comparison is of shape and level, not a fit.
"""

# ╔═╡ 74f775b3-43af-4e34-853a-c0b6bf0066f6
ornl = let
    dir = joinpath(@__DIR__, "..", "..", "data", "ornl_leaf")
    raw = readdlm(joinpath(dir, "combined_efficiency_pct.csv"), ',', String)
    num(s) = s == "NaN" ? NaN : parse(Float64, s)
    edge = readdlm(joinpath(dir, "max_test_condition.csv"), ',', Float64; skipstart = 1)
    (; torque = num.(raw[1, 2:end]), rpm = num.(raw[2:end, 1]),
        eta = permutedims(num.(raw[2:end, 2:end])), edge_rpm = edge[:, 1], edge_tau = edge[:, 2])
end;

# ╔═╡ 7af0b862-5b41-479e-a00f-f005df660051
ornl_plot = let
    p = plot(layout = (1, 2), size = (1240, 540), link = :y,
        plot_title = "model (110 kW ZE1-class machine) vs ORNL measured 2012 Leaf (80 kW / 280 N·m first-generation motor): shape and level, not a fit",
        plot_titlefontsize = 12)
    keep = emap.torque .>= 0
    map_panel!(p, 1, collect(emap.rpm), collect(emap.torque[keep]), 100 .* emap.eta[keep, :];
        mask = envelope_mask(emap)[1:1], colorbar = false, label_y = k -> 265.0 - 22.0 * (k - 1))
    plot!(p[1], emap.rpm, emap.tau_max; color = :black, lw = 2, label = "")
    first_rpm = ornl.rpm[findfirst(j -> any(!isnan, ornl.eta[:, j]), axes(ornl.eta, 2))]
    map_panel!(p, 2, ornl.rpm, ornl.torque, box_mean(ornl.eta, 2); label_y = k -> 265.0 - 22.0 * (k - 1), mask = [
        Shape(vcat(ornl.edge_rpm, reverse(ornl.edge_rpm)),
            vcat(ornl.edge_tau, fill(400.0, length(ornl.edge_tau)))),
        Shape([0, first_rpm, first_rpm, 0], [-10, -10, 400, 400])])
    plot!(p[2], ornl.edge_rpm, ornl.edge_tau; color = :black, lw = 2, label = "")
    n80 = 3000.0:50.0:10000.0
    for sp in 1:2
        plot!(p[sp], n80, 80e3 ./ (n80 .* pi ./ 30); color = :gray, ls = :dash, lw = 1.2,
            label = "")
        xlims!(p[sp], 0, 10000); ylims!(p[sp], 0, 330)
        xlabel!(p[sp], "machine speed [rpm]")
    end
    ylabel!(p[1], "shaft torque [N·m]")
    title!(p[1], "model: machine + average converter, 350 V")
    title!(p[2], "ORNL: motor + inverter, 375 V (digitized, smoothed)")
    annotate!(p[2], [(9900, 92, text("80 kW", 9, :gray, :right))])
    p
end

# ╔═╡ 06b3d519-ffdc-4168-9945-f5e96cac7d0a
md"""
Points ORNL's figure labels, read by eye from its contour labels (research note
`teaching_materials.md` §2.3, ±150 rpm, ±10 N·m, ±1 point), beside the digitized map at the same
point and the model:
"""

# ╔═╡ 1e99096d-eb38-404c-a735-34626616e8ff
ORNL_READ = [(900, 180, 80), (2000, 250, 87), (2400, 230, 89), (2850, 245, 90), (3500, 80, 94),
    (4900, 105, 95), (7300, 85, 96), (8600, 55, 95), (9600, 50, 94), (5750, 57, 94),
    (3400, 42, 93), (2900, 34, 92), (4850, 23, 92), (2500, 26, 91), (1900, 10, 87)];

# ╔═╡ c1969337-80c0-4973-9f3c-55007c101609
let
    digitized(n, T) = let i = argmin(abs.(ornl.torque .- T)), j = argmin(abs.(ornl.rpm .- n))
        ornl.eta[i, j]
    end
    rows = map(ORNL_READ) do (n, T, e)
        m = 100 * eta_at(emap, n, T)
        "| $n | $T | $e | $(digitized(n, T)) | $(round(m; digits = 1)) | $(round(m - e; digits = 1)) |"
    end
    Markdown.parse("""
    | rpm | N·m | ORNL, read [%] | ORNL, digitized [%] | model [%] | model − ORNL |
    |---:|---:|---:|---:|---:|---:|
    $(join(rows, "\n"))

    The shapes agree: efficiency climbs steeply out of the low-speed, high-torque corner, a
    plateau above 90 % covers most of the envelope from about 2000 rpm, and it collapses toward
    the zero-torque axis. Mid map, the two agree to about a point. Three differences:

    - **The peak island.** ORNL's 96 % island sits at 6000–9000 rpm just under the 80 kW line,
      where the model gives 94 %; the model's peak, 95.8 %, sits at 3000–4500 rpm. The model's
      iron loss and windage grow with speed with nothing to offset them, while the measured
      inverter's efficiency keeps rising with output voltage.
    - **Low speed, high torque.** The model is 4–6 points better than ORNL there: the
      converter's miss from section 2.
    - **Low speed, light load.** At 1900 rpm and 10 N·m the model is 8 points worse: its constant
      200 W, bearing friction and iron loss take 0.5 kW out of 2 kW, where the measured machine
      lost about 0.3 kW.

    The model's envelope is wider because its machine is: 320 N·m and 110 kW against 280 N·m
    and 80 kW.
    """)
end

# ╔═╡ Cell order:
# ╟─ee4970e4-3c9c-4222-9c66-48d7c5668af2
# ╠═6c44a3e1-3367-4336-9494-8a30dc124a47
# ╟─8c56ef28-cc25-4ef4-8ed5-0989599ae94f
# ╟─bdfee813-f445-42dc-900e-aa92a4b2a550
# ╟─23ab620b-3d46-4890-b359-0c166e13d2b5
# ╠═263626fe-aef7-4320-80e2-25284114090b
# ╠═302c05d9-de94-47dd-a0c7-1cda2f29c1c1
# ╠═89bb3753-dfd2-4de3-a4a7-db262f6ddf0d
# ╠═48c77b66-1b3c-4519-83d3-c421d7806fea
# ╟─25650f35-aed9-4f13-869b-bda4e31002f3
# ╠═3cb1f373-af79-4d0b-b685-804f8a23229d
# ╟─0e27565e-4372-4915-ba42-bf2bc1efdc83
# ╟─b1fb1251-8c9a-4729-b491-721b1d0545d5
# ╟─b1d1088a-eb1a-4bac-98e1-d1302a2e9123
# ╟─5f65ee53-fe98-42d2-936f-4e72171c28ab
# ╟─9de5f689-a602-4f10-ae56-c99c8db187e3
# ╠═46c2c26d-dbd4-4653-be5d-593b3443e24a
# ╟─a31a4b57-277c-41a5-840e-26bc86e070fa
# ╟─30815e0e-f523-4902-b831-6a18a637c754
# ╠═0b3fd999-30a8-4d5d-ae5a-1a2bb062a3de
# ╟─7fa3b4c5-d987-42f0-9fb5-436efd9aab73
# ╟─c698a095-74a1-49df-81c4-ffbf6104f632
# ╟─a54ac7a3-dc08-41df-b95a-b0a0cb69e069
# ╠═74f775b3-43af-4e34-853a-c0b6bf0066f6
# ╟─7af0b862-5b41-479e-a00f-f005df660051
# ╟─06b3d519-ffdc-4168-9945-f5e96cac7d0a
# ╠═1e99096d-eb38-404c-a735-34626616e8ff
# ╟─c1969337-80c0-4973-9f3c-55007c101609
