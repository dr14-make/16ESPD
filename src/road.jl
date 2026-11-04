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
function road_surface(file::AbstractString)
    path = road_path(file)
    if isempty(file) || !isfile(path)
        path = road_path("dyad://VehicleSystemsComponents/roads/uniform_mu.crg")
    end
    data = OpenCRG.read_crg(path)
    # Inspect section presence too: an explicitly empty MODS block must also be rejected.
    bytes = read(path)
    header = String(bytes[1:OpenCRG.find_header_end(bytes)-1])
    occursin(r"(?im)^\s*\$ROAD_CRG_MODS\b", header) &&
        error("$file: \$ROAD_CRG_MODS is unsupported for a straight table road")
    sections = OpenCRG.group_sections(OpenCRG.split_lines(bytes[1:OpenCRG.find_header_end(bytes)-1]))
    _, channels = OpenCRG.parse_kd_definition(sections["KD_DEFINITION"])
    any(c -> c.kind == :phi, channels) &&
        error("$file: reference line phi channel is unsupported (curved reference line)")
    r = data.refline
    u = collect(range(r.start_u; step = r.increment, length = size(data.z, 1)))
    v = data.v
    all(>(0), diff(u)) && all(>(0), diff(v)) || error("$file: grid axes must increase")
    # Upstream handmade samples contain missing heights. They are not grip measurements;
    # retain every finite node and use zero for missing nodes when testing those fixtures.
    z = map(x -> isfinite(x) ? x : 0.0, data.z)
    du, au = road_dimension(u)
    dv, av = road_dimension(v)
    coefficients = (au \ z) / transpose(av)
    surface = DataInterpolationsND.NDInterpolation(coefficients, (du, dv))
    return (; surface, x0 = r.start_x, y0 = r.start_y, phi = r.start_phi, u0 = r.start_u)
end


"Extract a road surface callable from loaded structural road data."
road_interpolator(data) = data.surface
"Extract a straight reference-line coordinate from loaded structural road data."
road_coordinate(data, index) = (data.x0, data.y0, data.phi, data.u0)[index]
