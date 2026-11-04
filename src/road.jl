using OpenCRG, DataInterpolationsND

"Resolve a package road asset or an explicit filesystem path."
function road_path(file::AbstractString)
    prefix = "dyad://VehicleSystemsComponents/"
    startswith(file, prefix) ? joinpath(@__DIR__, "..", "assets", file[length(prefix)+1:end]) : file
end

"Quadratic B-spline dimension and its nodal collocation matrix, evaluated by DataInterpolationsND."
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

"Load a straight OpenCRG grid and fit a C1 quadratic spline through its finite grid nodes."
function road_surface(file::AbstractString; fill_missing = nothing)
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
    for m in eachmatch(r"(?im)^\s*REFERENCE_LINE_START_(?:SLOPE|BANKING)\s*=\s*([^\s!]+)", header)
        value = tryparse(Float64, m.captures[1])
        value == 0.0 || error("$file: elevation data (slope or banking start value) is not grip")
    end
    any(p -> isfinite(p) && p != r.start_phi, data.phi) &&
        error("$file: curved reference line phi differs from REFERENCE_LINE_START_PHI")
    (data.slope !== nothing || data.banking !== nothing ||
        r.start_z != 0 || r.start_slope != 0 || r.start_banking != 0) &&
        error("$file: elevation data (slope, banking, or reference-line start elevation) is not grip")
    if any(isnan, data.z)
        fill_missing === nothing && error("$file: grip grid contains NaN")
        isfinite(fill_missing) || error("$file: fill_missing must be finite")
        replace!(data.z, NaN => Float64(fill_missing))
    end
    # The reader leaves absent heading samples as NaN, even for a straight reference line.
    replace!(data.phi, NaN => r.start_phi)
    u, v, X, Y, z = OpenCRG.road_surface_grid(data)
    all(isfinite, z) || error("$file: grip grid contains nonfinite values after modifiers")
    all(>(0), diff(u)) && all(>(0), diff(v)) || error("$file: grid axes must increase")
    phi = atan(Y[end,1] - Y[1,1], X[end,1] - X[1,1])
    x0, y0 = X[1,1] + sin(phi)*v[1], Y[1,1] - cos(phi)*v[1]
    du, au = road_dimension(u)
    dv, av = road_dimension(v)
    coefficients = (au \ z) / transpose(av)
    surface = DataInterpolationsND.NDInterpolation(coefficients, (du, dv))
    return (; surface, x0, y0, phi, u0 = first(u))
end


"Extract a road surface callable from loaded structural road data."
road_interpolator(data) = data.surface
"Extract a straight reference-line coordinate from loaded structural road data."
road_coordinate(data, index) = (data.x0, data.y0, data.phi, data.u0)[index]
