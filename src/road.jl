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

"Load an OpenCRG grip file once and return a C1 callable of world x and y, holding grid edges."
function road_grip(file::AbstractString; fill_missing = nothing)
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
    try
        u, v, X, Y, z = OpenCRG.road_surface_grid(data)
        all(isfinite, z) || error("grip grid contains nonfinite values after modifiers")
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
        surface = DataInterpolationsND.NDInterpolation((au \ z) / transpose(av), (du, dv))
        if straight
            return (x, y) -> surface(c * (x-cx[1]) + s * (y-cy[1]) + first(u),
                -s * (x-cx[1]) + c * (y-cy[1]))
        end
        heading = [atan(center[min(i+1,end)] - center[max(i-1,1)],
                        xaxis[min(i+1,end)] - xaxis[max(i-1,1)]) for i in eachindex(xaxis)]
        center_y = DataInterpolationsND.NDInterpolation(au \ center, (du,))
        direction = DataInterpolationsND.NDInterpolation(au \ heading, (du,))
        return (x, y) -> begin
            local_x = c * (x-cx[1]) + s * (y-cy[1])
            local_y = -s * (x-cx[1]) + c * (y-cy[1])
            surface(local_x, cos(direction(local_x)) * (local_y - center_y(local_x)))
        end
    catch e
        error("$file: $(sprint(showerror, e))")
    end
end
