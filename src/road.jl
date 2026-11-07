using OpenCRG, DataInterpolationsND, ForwardDiff, ModelingToolkit

"Resolve a package road asset or an explicit filesystem path."
function road_path(file::AbstractString)
    prefix = "dyad://VehicleSystemsComponents/"
    startswith(file, prefix) ? joinpath(@__DIR__, "..", "assets", file[length(prefix)+1:end]) : file
end

"Quadratic B-spline dimension and its nodal collocation matrix, used to fit road coefficients."
function road_dimension(axis)
    length(axis) >= 3 || error("a road grid needs at least three nodes per axis")
    knots = [first(axis); [(axis[j] + axis[j+1]) / 2 for j in 2:length(axis)-2]; last(axis)]
    dim = DataInterpolationsND.BSplineInterpolationDimension(knots, 2;
        t_eval = axis, max_derivative_order_eval = 2,
        extrapolation = DataInterpolationsND.ExtrapolationType.Constant)
    matrix = hcat([collect(DataInterpolationsND.BasisFunctionVector(dim, i, 0))
                   for i in eachindex(axis)]...)
    return dim, matrix
end

"Innermost real value of a possibly nested `ForwardDiff.Dual`."
primal(x::ForwardDiff.Dual) = primal(ForwardDiff.value(x))
primal(x::Real) = x

"""
    quadratic_basis(breaks, t) -> (i, b0, b1, b2)

Nonzero basis values of the clamped quadratic B-spline on strictly increasing `breaks` at `t`:
coefficients `i`, `i+1`, `i+2` carry weights `b0`, `b1`, `b2`. Outside the breaks `t` is held at
the nearer edge, so the spline keeps its edge value and has zero slope there. Generic in the
number type of `t`, including `ForwardDiff.Dual`, and allocation-free.
"""
@inline function quadratic_basis(breaks::Vector{Float64}, t)
    m = length(breaks)
    @inbounds first_break, last_break = breaks[1], breaks[m]
    # Compare primal values: on the edge itself the spline's one-sided slope applies in every direction.
    value = primal(t)
    held = value < first_break ? first_break + zero(t) : value > last_break ? last_break + zero(t) : t
    i = clamp(searchsortedlast(breaks, value), 1, m - 1)
    @inbounds begin
        left, right = breaks[i], breaks[i+1]
        before, after = breaks[max(i - 1, 1)], breaks[min(i + 2, m)]
    end
    # Cox-de Boor for degree 2; the clamped end knots repeat the first and last breaks.
    scale = 1 / (right - left)
    n0, n1 = (right - held) * scale, (held - left) * scale
    w0 = n0 / (right - before)
    w1 = n1 / (after - left)
    return i, (right - held) * w0, (held - before) * w0 + (after - held) * w1, (held - left) * w1
end

"""
    RoadSurface(x0, y0, c, s, u0, u_breaks, v_breaks, coefficients, center, heading)

Edge-held C1 quadratic B-spline road surface of world `(x, y)`. World points are rotated by the
start heading (`c`, `s`) about the reference-line start `(x0, y0)` into along-road `u` (offset by
`u0`) and lateral `v`. Empty `center` and `heading` mean a straight reference line; otherwise
they are spline coefficients over `u_breaks` of the reference line's lateral offset and heading in
the start frame, and `v` is measured from that line along its normal. Calls with numbers run the
spline; calls with symbolic arguments stay one opaque term.
"""
struct RoadSurface <: Function
    x0::Float64
    y0::Float64
    c::Float64
    s::Float64
    u0::Float64
    u_breaks::Vector{Float64}
    v_breaks::Vector{Float64}
    coefficients::Matrix{Float64}
    center::Vector{Float64}
    heading::Vector{Float64}
end

(surface::RoadSurface)(x, y) = road_lookup(surface, x, y)

"Evaluate a fitted road surface at world x and y."
function road_lookup(surface::RoadSurface, x, y)
    dx, dy = x - surface.x0, y - surface.y0
    u = surface.c * dx + surface.s * dy + surface.u0
    v = -surface.s * dx + surface.c * dy
    i, a0, a1, a2 = quadratic_basis(surface.u_breaks, u)
    if !isempty(surface.center)
        center, heading = surface.center, surface.heading
        @inbounds v = cos(a0 * heading[i] + a1 * heading[i+1] + a2 * heading[i+2]) *
            (v - (a0 * center[i] + a1 * center[i+1] + a2 * center[i+2]))
    end
    j, b0, b1, b2 = quadratic_basis(surface.v_breaks, v)
    C = surface.coefficients
    @inbounds return a0 * (b0 * C[i, j] + b1 * C[i, j+1] + b2 * C[i, j+2]) +
        a1 * (b0 * C[i+1, j] + b1 * C[i+1, j+1] + b2 * C[i+1, j+2]) +
        a2 * (b0 * C[i+2, j] + b1 * C[i+2, j+1] + b2 * C[i+2, j+2])
end

ModelingToolkit.Symbolics.@register_symbolic road_lookup(surface::RoadSurface, x, y)

"Load an OpenCRG grid and fit its edge-held world-coordinate [`RoadSurface`](@ref)."
function road_surface(file::AbstractString; fill_missing = nothing, elevation = false)
    kind = elevation ? "height" : "grip"
    path = road_path(file)
    isempty(file) && error("$(repr(file)): road filename is empty")
    isfile(path) || error("$file: road file does not exist")
    data = try
        OpenCRG.read_crg(path)
    catch e
        error("$file: $(sprint(showerror, e))")
    end
    r = data.refline
    # The pinned reader recognizes the standard _S/_B keys, not these spelled-out aliases.
    header = first(split(read(path, String), "\$\$\$\$"; limit = 2))
    if elevation
        occursin(r"(?im)^\s*REFERENCE_LINE_START_(?:SLOPE|BANKING)\s*=", header) &&
            error("$file: unsupported start slope/banking alias; use REFERENCE_LINE_START_S or REFERENCE_LINE_START_B")
    end
    if !elevation
        for m in eachmatch(r"(?im)^\s*REFERENCE_LINE_START_(?:SLOPE|BANKING)\s*=\s*([^\s!]+)", header)
            value = tryparse(Float64, m.captures[1])
            value == 0.0 || error("$file: elevation data (slope or banking start value) is not grip")
        end
        (data.slope !== nothing || data.banking !== nothing ||
            r.start_z != 0 || r.start_slope != 0 || r.start_banking != 0) &&
            error("$file: elevation data (slope, banking, or reference-line start elevation) is not grip")
    end
    if any(isnan, data.z)
        fill_missing === nothing && error("$file: $kind grid contains NaN")
        isfinite(fill_missing) || error("$file: fill_missing must be finite")
        replace!(data.z, NaN => Float64(fill_missing))
    end
    # The reader leaves absent heading samples as NaN, even for a straight reference line.
    replace!(data.phi, NaN => r.start_phi)
    try
        u, v, X, Y, z = OpenCRG.road_surface_grid(data)
        all(isfinite, z) || error("$kind grid contains nonfinite values after modifiers")
        all(>(0), diff(u)) && all(>(0), diff(v)) || error("grid axes must increase")
        # Grid columns are affine in v, including the reader's corner-normal rescaling.
        # Extrapolate them to v=0 rather than choosing an offset grid column.
        cx = X[:,1] .- v[1] .* (X[:,end] .- X[:,1]) ./ (v[end] - v[1])
        cy = Y[:,1] .- v[1] .* (Y[:,end] .- Y[:,1]) ./ (v[end] - v[1])
        mods = data.mods
        anchored = any(f -> getfield(mods, f) !== nothing,
            (:refpoint_x, :refpoint_y, :refpoint_z, :refpoint_phi))
        phi = anchored ? something(mods.refpoint_phi, 0.0) :
            r.start_phi + something(mods.refline_offset_phi, 0.0)
        c, s = cos(phi), sin(phi)
        xaxis = c .* (cx .- cx[1]) .+ s .* (cy .- cy[1])
        center = -s .* (cx .- cx[1]) .+ c .* (cy .- cy[1])
        all(>(0), diff(xaxis)) || error("reference line turns back in its start frame")
        dv, av = road_dimension(v)
        # Preserve the straight-road spline and its original arc-length indexing exactly.
        straight = maximum(abs.(center)) <= 1e-12 * max(1.0, last(xaxis))
        axis = straight ? u : xaxis
        du, au = road_dimension(axis)
        coefficients = (au \ z) / transpose(av)
        u_breaks, v_breaks = collect(Float64, du.t), collect(Float64, dv.t)
        if straight
            return RoadSurface(cx[1], cy[1], c, s, first(u), u_breaks, v_breaks, coefficients,
                Float64[], Float64[])
        end
        heading = [atan(center[min(i+1,end)] - center[max(i-1,1)],
                        xaxis[min(i+1,end)] - xaxis[max(i-1,1)]) for i in eachindex(xaxis)]
        return RoadSurface(cx[1], cy[1], c, s, 0.0, u_breaks, v_breaks, coefficients,
            au \ center, au \ heading)
    catch e
        error("$file: $(sprint(showerror, e))")
    end
end

"Load an OpenCRG grip file once and return a C1 callable of world x and y, holding grid edges."
road_grip(file::AbstractString; fill_missing = nothing) =
    road_surface(file; fill_missing, elevation = false)

"Load height and return (world x, world y, heading radians) to tan of the along-heading road angle."
function road_height(file::AbstractString; fill_missing = nothing)
    height = road_surface(file; fill_missing, elevation = true)
    return (x, y, psi) -> road_directional_slope(height, x, y, psi)
end

"Evaluate a surface's directional derivative numerically, keeping spline lookup out of symbolic tracing."
road_directional_slope(height::Function, x, y, psi) = ForwardDiff.derivative(t ->
    height(x + t * cos(psi), y + t * sin(psi)), zero(x + y + psi))

ModelingToolkit.Symbolics.@register_symbolic road_directional_slope(height::Function, x, y, psi)

"""
    road_extent(files...; margin = 20.0) -> (; x = (xmin, xmax), y = (ymin, ymax))

World bounding box, in meters, of the grids of one or more OpenCRG `files`, grown by `margin` on
every side. Use it to pick the sampling window for [`road_mesh`](@ref) without guessing.
"""
function road_extent(files::AbstractString...; margin = 20.0)
    isempty(files) && throw(ArgumentError("road_extent needs at least one road file"))
    xs, ys = Float64[], Float64[]
    for file in files
        data = OpenCRG.read_crg(road_path(file))
        replace!(data.phi, NaN => data.refline.start_phi)
        _, _, X, Y, _ = OpenCRG.road_surface_grid(data)
        push!(xs, extrema(X)...)
        push!(ys, extrema(Y)...)
    end
    return (; x = (minimum(xs) - margin, maximum(xs) + margin),
              y = (minimum(ys) - margin, maximum(ys) + margin))
end

"""
    road_axes(files...; margin = 20.0, max_points = 160_000, min_step = 0.25) -> (; x, y)

Evenly spaced world sample axes over [`road_extent`](@ref) with one spacing on both axes, no
finer than `min_step` meters and with at most about `max_points` grid points.
"""
function road_axes(files::AbstractString...; margin = 20.0, max_points = 160_000, min_step = 0.25)
    box = road_extent(files...; margin)
    wx, wy = box.x[2] - box.x[1], box.y[2] - box.y[1]
    step = max(min_step, sqrt(wx * wy / max_points))
    return (; x = range(box.x[1], box.x[2]; length = max(2, ceil(Int, wx / step) + 1)),
              y = range(box.y[1], box.y[2]; length = max(2, ceil(Int, wy / step) + 1)))
end

"""
    road_mesh(height_file; grip_file = nothing, x, y)
        -> (; x, y, vertices, faces, height, grip)

Sample a road on the world grid `x` by `y` (meters) for drawing.

Heights and grips come from the same fitted, edge-held callables the car evaluates
([`road_surface`](@ref), behind [`road_height`](@ref) and [`road_grip`](@ref)), not from the raw
CRG nodes, so the picture is what the tires feel, including the held edges beyond a file's grid.
Without `grip_file` the grip is one everywhere. `x` and `y` default to [`road_axes`](@ref) over
both files.

Everything is in the CRG world frame: right-handed and z-up, x and y the planar car's world
coordinates. Returns plain arrays:

- `x::Vector{Float64}` (length `nx`), `y::Vector{Float64}` (length `ny`): the sample axes.
- `height::Matrix{Float64}`, `grip::Matrix{Float64}` (`nx` by `ny`): `height[i, j]` is the road
  elevation and `grip[i, j]` the grip multiplier at `(x[i], y[j])`; ready for a top-view
  `heatmap(x, y, grip)`.
- `vertices::Vector{NTuple{3, Float64}}`: `(x[i], y[j], height[i, j])` at linear index
  `i + (j - 1) * nx`, so `vec(height)` and `vec(grip)` are per-vertex values.
- `faces::Vector{NTuple{3, Int}}`: two counter-clockwise triangles (seen from +z) per grid cell,
  1-based indices into `vertices`.

A y-up scene such as the multibody world takes each vertex through `(x, y, z) -> (x, z, -y)`, a
proper rotation about x. The swap `(x, z, y)` is a mirror: it reverses face winding and the sign
of yaw.
"""
function road_mesh(height_file::AbstractString; grip_file = nothing,
        x = nothing, y = nothing)
    if x === nothing || y === nothing
        files = grip_file === nothing ? (height_file,) : (height_file, grip_file)
        axes = road_axes(files...)
        x = something(x, axes.x)
        y = something(y, axes.y)
    end
    xs, ys = collect(Float64, x), collect(Float64, y)
    nx, ny = length(xs), length(ys)
    nx >= 2 && ny >= 2 || throw(ArgumentError("road_mesh needs at least two samples per axis"))
    elevation = road_surface(height_file; elevation = true)
    height = Float64[elevation(xi, yi) for xi in xs, yi in ys]
    grip = if grip_file === nothing
        ones(nx, ny)
    else
        surface = road_surface(grip_file)
        Float64[surface(xi, yi) for xi in xs, yi in ys]
    end
    vertices = vec([(xs[i], ys[j], height[i, j]) for i in 1:nx, j in 1:ny])
    index(i, j) = i + (j - 1) * nx
    faces = NTuple{3, Int}[]
    sizehint!(faces, 2 * (nx - 1) * (ny - 1))
    for j in 1:ny-1, i in 1:nx-1
        push!(faces, (index(i, j), index(i + 1, j), index(i + 1, j + 1)))
        push!(faces, (index(i, j), index(i + 1, j + 1), index(i, j + 1)))
    end
    return (; x = xs, y = ys, vertices, faces, height, grip)
end
