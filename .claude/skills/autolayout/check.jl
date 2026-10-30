# Find layout defects in a rendered diagram: diagonal wire segments, crossings, overlapping wires,
# wires through blocks or instance labels, labels over other blocks, anything outside the outline,
# blocks whose label draws sideways or mirrored, `_links` entries no declaration or `connect`
# points to, boxes not shaped like the library icon placed in them, and wires from one port that
# share a trunk and split with no junction dot.
#
# Usage: julia +dyad-3.5.0 check.jl <file.dyad> <Component> <render.svg>
#
# Wires come from the SVG (diagram coordinates, rounded to whole units); blocks from the `_links`
# placements of the component and of every base it extends inside this library, by a qualified
# name or by a bare name defined in the same directory. A base outside the library is named in a
# `note` line and its parts go unchecked. `#` comments in the metadata JSON are dropped before it
# is parsed. Placements written inline on a
# declaration or `connect` are not read, so they count as a problem until moved into `_links`.
# Each default `$(instance)` label is estimated as a box from y2 + 0.07 h to y2 + 0.2 h, 0.11 h wide
# per character. Custom `labels` are estimated the same way, so read the render for those.
#
# A wire running exactly along a block's edge, as one leaving or reaching a bottom-center port
# sideways does, is a graze, not a hit. A wire is not checked against the block of a port it ends at,
# but is checked against that block's label. Wires that leave one port and overlap are fine where
# the render draws a junction dot on their shared trunk, and a `branch` where it does not, since
# the split then reads as a bend. Wires sharing a trunk count one crossing per point. The component's own ports may straddle the 0..1000
# outline. A wire looping around its target, and labels drawn above a block (Constant names, Gain
# `k=`), show only in the PNG. Studio draws an icon at its own aspect ratio, centered in the box,
# while ports sit on the box edges, so a box shaped unlike its icon detaches the ports in Studio
# though the render (which stretches the icon) looks fine; only icons from this library are checked,
# against their SVG's viewBox. Exit status is the number of problems, so a non-zero exit is a
# finding, not a crash.
using JSON, OrderedCollections

dyad_path, component, svg_path = ARGS

problems = 0

function report(kind, what...)
    kind in ("graze", "note") || (global problems += 1)
    println(join((kind, what...), " "))
end

body_of(text, name) = match(Regex("^(?:\\w+ )*component $name\\b.*?^end\\b", "ms"), text)

# The `dyad/` directory; a base `Lib.A.B.Name` is defined in a file under `dyad/A/B/`.
root = let d = dirname(abspath(dyad_path))
    while basename(d) != "dyad" && dirname(d) != d
        d = dirname(d)
    end
    d
end

library = match(r"^name\s*=\s*\"(\w+)\""m, read(joinpath(dirname(root), "Project.toml"), String))[1]

function body_in(dir, name)
    isdir(dir) || return nothing
    for f in readdir(dir; join=true)
        endswith(f, ".dyad") || continue
        b = body_of(read(f, String), name)
        b === nothing || return b.match
    end
    nothing
end
function find_base(qualified)
    parts = split(qualified, '.')
    body_in(joinpath(root, parts[2:end-1]...), parts[end])
end
"Body and directory of a base named in an `extends` inside `dir`: qualified, or bare in the same module."
function locate(base, dir)
    occursin('.', base) || return body_in(dir, base), dir
    parts = split(base, '.')
    parts[1] == library || return nothing, dir
    find_base(base), joinpath(root, parts[2:end-1]...)
end

"Drop `#` comments, which JSON does not allow, from text outside JSON strings."
function strip_comments(json)
    out, instr, esc, skip = IOBuffer(), false, false, false
    for c in json
        if skip
            c == '\n' || continue
            skip = false
        elseif instr
            if esc
                esc = false
            elseif c == '\\'
                esc = true
            elseif c == '"'
                instr = false
            end
        elseif c == '#'
            skip = true
            continue
        elseif c == '"'
            instr = true
        end
        write(out, c)
    end
    String(take!(out))
end

"Width/height of the library icon a type draws with, or `nothing` for an icon from elsewhere."
function icon_aspect(type, dir)
    parts = split(type, '.')
    length(parts) > 1 && parts[1] != library && return nothing
    text = length(parts) > 1 ? find_base(type) : body_in(dir, type)
    text === nothing && return nothing
    icon = match(r"\"default\"\s*:\s*\"dyad://(\w+)/([^\"]+\.svg)\"", text)
    if icon === nothing
        base = match(r"^\s*extends\s+([\w.]+)"m, text)
        return base === nothing ? nothing : icon_aspect(base[1], dir)
    end
    icon[1] == library || return nothing
    svg = joinpath(dirname(root), "assets", icon[2])
    isfile(svg) || return 1.0
    view = match(r"viewBox=\"[-\d.]+[ ,]+[-\d.]+[ ,]+([\d.]+)[ ,]+([\d.]+)\"", read(svg, String))
    view === nothing ? 1.0 : parse(Float64, view[1]) / parse(Float64, view[2])
end

# The component's own ports: a `connect` names them bare, and a part's ports as `part.port`.
own = Set{String}()
# tag => width/height of the library icon its declaration draws with
aspects = Dict{String,Float64}()

"`_links` of a component body, its library bases' entries first, so its own override them."
function links_of(text, dir, seen=Set{String}())
    links = OrderedDict{String,Any}()
    for c in eachmatch(r"^\s*connect\(([^)]*)\)"m, text), arg in split(c[1], ',')
        occursin('.', arg) || push!(own, strip(arg))
    end
    for e in eachmatch(r"^\s*extends\s+([\w.]+)"m, text)
        base = e[1]
        base in seen && continue
        push!(seen, base)
        btext, bdir = locate(base, dir)
        if btext === nothing
            report("note", "base $base is outside this library; its parts are not checked")
        else
            merge!(links, links_of(btext, bdir, seen))
        end
    end
    meta = match(r"^metadata (\{.*?^\})\s*$"ms, text)
    declarations = meta === nothing ? text : text[1:prevind(text, meta.offset)]
    if occursin(r"\{\s*\"Dyad\"\s*:\s*\{\s*\"(placement|edges)\""m, declarations)
        name = something(match(r"component (\w+)", text), ["?"])[1]
        report("inline", name, "places parts inline; move them into `_links` with `{^tag}`s")
    end
    for d in eachmatch(r"^\s*(?:\w+\s+)*\w+\s*=\s*([A-Za-z][\w.]*)\(.*\{\^(\w+)\}"m, declarations)
        aspect = icon_aspect(d[1], dir)
        aspect === nothing || (aspects[d[2]] = aspect)
    end
    meta === nothing && return links
    parsed = try
        JSON.parse(strip_comments(meta[1]); dicttype=OrderedDict{String,Any})
    catch err
        name = something(match(r"component (\w+)", text), ["?"])[1]
        report("metadata", name, "is not valid JSON, so its layout is unchecked:",
               first(sprint(showerror, err), 200))
        return links
    end
    for (tag, link) in get(parsed, "_links", Dict())
        if occursin("{^$tag}", declarations)
            links[tag] = link
        else
            # an inherited part takes its placement from the base, whatever this entry says
            report("dead", tag, "has no `{^$tag}` here, so the renderer ignores its entry")
        end
    end
    for t in eachmatch(r"\{\^(\w+)\}", replace(declarations, r"^\s*connect\(.*$"m => ""))
        haskey(links, t[1]) || report("unplaced", t[1], "has no `_links` entry, so it draws at a default position")
    end
    links
end

body = body_of(read(dyad_path, String), component)
body === nothing && (println(stderr, "component $component not found in $dyad_path"); exit(1))
links = links_of(body.match, dirname(abspath(dyad_path)))

blocks, labels, ports = Pair{String,NTuple{4,Real}}[], Pair{String,NTuple{4,Real}}[], Set{String}()
for (name, link) in links
    placement = get(get(link, "Dyad", Dict()), "placement", Dict())
    for (layer, b) in placement
        b isa AbstractDict && haskey(aspects, name) || continue
        w, h = abs(b["x2"] - b["x1"]), abs(b["y2"] - b["y1"])
        rot = mod(get(b, "rot", 0), 180) == 90
        isapprox(rot ? h / w : w / h, aspects[name]; rtol=0.01) ||
            report("aspect", name, layer, "box $(w)x$(h) for a $(round(aspects[name]; digits=2)):1 icon;",
                   "Studio keeps the icon's shape, so its ports leave it")
    end
    box = get(placement, "diagram", nothing)
    box === nothing && continue
    x1, x2 = minmax(box["x1"], box["x2"])
    y1, y2 = minmax(box["y1"], box["y2"])
    push!(blocks, name => (x1, y1, x2, y2))
    if name in own || haskey(placement, "icon")  # the component's own ports draw no label
        push!(ports, name)
    else
        h, cx, cy = y2 - y1, (x1 + x2) / 2, (y1 + y2) / 2
        half = 0.055 * h * length(name)
        # Offsets from the block center; glyphs start a little below the edge, leaving room for a
        # bottom port's wire stub. A flipped block draws the label above, and rotation turns it
        # about the center (y grows down, so rot 90 puts it on the left).
        lx, ly = (-half, half), (0.57 * h, 0.7 * h)
        box["y1"] > box["y2"] && (ly = (-0.7 * h, -0.57 * h))
        rot = mod(get(box, "rot", 0), 360)
        lx, ly = rot == 90 ? ((-ly[2], -ly[1]), lx) : rot == 180 ? ((-lx[2], -lx[1]), (-ly[2], -ly[1])) :
                 rot == 270 ? (ly, (-lx[2], -lx[1])) : (lx, ly)
        push!(labels, name => (cx + lx[1], cy + ly[1], cx + lx[2], cy + ly[2]))
        rot == 0 || report("rotated", name, "rot=$rot")
        (box["x1"] > box["x2"] || box["y1"] > box["y2"]) && report("mirrored", name)
    end
end

svg = read(svg_path, String)
paths = [[(round(Int, parse(Float64, p[1])), round(Int, parse(Float64, p[2])))
          for p in eachmatch(r"(-?[\d.]+) (-?[\d.]+)", d[1])]
         for d in eachmatch(r"<path d=\"(M [^\"]*)\" stroke-stroke", svg)]
segs = [(i, a, b) for (i, p) in enumerate(paths) for (a, b) in zip(p, p[2:end]) if a != b]
ends = [Set([p[1], p[end]]) for p in paths]
# junction dots, which the renderer also draws where separate `connect`s from one port split
dots = [(round(Int, parse(Float64, c[1])), round(Int, parse(Float64, c[2])))
        for c in eachmatch(r"<circle cx=\"(-?[\d.]+)\" cy=\"(-?[\d.]+)\" r=\"5\"", svg)]
"A wire is named by its end points, the port centers it joins; the SVG carries no `connect` tag."
wire(i) = "wire $(paths[i][1])-$(paths[i][end])"

"Whether two boxes share interior area."
overlaps((a1, b1, a2, b2), (c1, d1, c2, d2)) = max(a1, c1) < min(a2, c2) && max(b1, d1) < min(b2, d2)
for (lname, lbox) in labels, (bname, bbox) in blocks
    lname != bname && overlaps(lbox, bbox) && report("label-over-block", lname, "label covers", bname)
end

for (name, (x1, y1, x2, y2)) in blocks
    lo, hi = name in ports ? (-50, 1050) : (0, 1000)  # own ports straddle the outline
    (x1 < lo || y1 < lo || x2 > hi || y2 > hi) && report("outside", name, (x1, y1, x2, y2))
end
for (i, p) in enumerate(paths)
    any(v -> !(-50 <= v <= 1050), Iterators.flatten(p)) && report("outside", wire(i), p)
end

for (i, a, b) in segs
    a[1] != b[1] && a[2] != b[2] && report("diagonal", wire(i), a, b)
end

# Wires sharing a trunk cross another wire at one point; that is one crossing on screen.
crossed = Set{Tuple{Int,Int}}()
# wires leaving one port that overlap => whether a junction dot sits on their shared trunk
trunks = Dict{Tuple{Int,Int},Bool}()
for x in eachindex(segs), y in x+1:lastindex(segs)
    (i, a, b), (j, c, d) = segs[x], segs[y]
    i == j && continue
    vert1, vert2 = a[1] == b[1], c[1] == d[1]
    if vert1 != vert2
        (p, q), (r, s) = vert1 ? ((a, b), (c, d)) : ((c, d), (a, b))
        lo, hi = minmax(r[1], s[1])
        ylo, yhi = minmax(p[2], q[2])
        point = (p[1], r[2])
        if lo < p[1] < hi && ylo < r[2] < yhi && !(point in crossed)
            push!(crossed, point)
            report("cross", wire(i), "and", wire(j), point)
        end
    elseif vert1 && a[1] == c[1] || !vert1 && a[2] == c[2]
        k = vert1 ? 2 : 1
        lo1, hi1 = minmax(a[k], b[k])
        lo2, hi2 = minmax(c[k], d[k])
        max(lo1, lo2) < min(hi1, hi2) || continue
        if isempty(ends[i] ∩ ends[j])
            report("overlap", wire(i), "and", wire(j), a, b)
        else
            dotted = any(p -> p[3-k] == a[3-k] && max(lo1, lo2) <= p[k] <= min(hi1, hi2), dots)
            trunks[(i, j)] = get(trunks, (i, j), false) || dotted
        end
    end
end

for ((i, j), dotted) in trunks
    dotted || report("branch", wire(i), "and", wire(j), "share a trunk with no junction dot;",
                     "list every end in one `connect`")
end

"A port's wire end sits a few units off its block's edge."
inside((x1, y1, x2, y2), pt; margin=5) =
    x1 - margin <= pt[1] <= x2 + margin && y1 - margin <= pt[2] <= y2 + margin

"`:hit` if the segment passes through the box's interior, `:graze` if it runs along its edge."
function hits((x1, y1, x2, y2), a, b)
    if a[1] == b[1]
        fixed, (lo, hi), (flo, fhi), (slo, shi) = a[1], minmax(a[2], b[2]), (x1, x2), (y1, y2)
    else
        fixed, (lo, hi), (flo, fhi), (slo, shi) = a[2], minmax(a[1], b[1]), (y1, y2), (x1, x2)
    end
    (max(lo, slo) >= min(hi, shi) || !(flo <= fixed <= fhi)) && return nothing
    return flo < fixed < fhi ? :hit : :graze
end

for (i, a, b) in segs
    a[1] != b[1] && a[2] != b[2] && continue
    for (kind, boxes) in (("block", blocks), ("label", labels))
        for (name, box) in boxes
            # the wire's own port sits in this block
            kind == "block" && any(e -> inside(box, e), ends[i]) && continue
            result = hits(box, a, b)
            if result === :hit
                report("through-$kind", name, wire(i), a, b)
            elseif result === :graze && kind == "label"
                report("graze", name, wire(i), a, b)
            end
        end
    end
end

println("$problems problem(s)")
exit(min(problems, 255))
