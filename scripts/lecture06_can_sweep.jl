"""
Lecture 6 CAN braking phase sweep; writes assets/data/lecture06/can_stop.csv.

    julia +dyad-3.5.0 --project=. scripts/lecture06_can_sweep.jl

One cached analysis setup per architecture/period is reused across pedal offsets. Only
scalar summaries survive each solve. The CSV hash follows machine_size_sweep.jl: relative
input paths and bytes, not package versions (rerun after dependency updates).
"""
module Lecture06CanSweep

using Printf, SHA
using Revise
using VehicleSystemsComponents: Vehicle
using DyadInterface: setup_analysis, run_analysis, symbolic_container
using ModelingToolkit: toggle_namespacing

const CAN = Vehicle.Planar
const ROOT = normpath(@__DIR__, "..")
const OUT = joinpath(ROOT, "assets", "data", "lecture06", "can_stop.csv")
const PERIODS = [0.010, 0.020, 0.040]
const OFFSETS = [0.0, 0.005, 0.010, 0.020, 0.030, 0.040]
const ARCHITECTURES = ["point", "ideal", "real", "bus_brake"]
const COLUMNS = ["architecture", "period", "offset", "distance", "wheel_lock"]
const T_END = 6.0

function input_files()
    files = [@__FILE__, joinpath(ROOT, "generated", "internals.jl")]
    for subdir in ("src", "dyad/Vehicle", "generated/Vehicle")
        for (dir, _, names) in walkdir(joinpath(ROOT, subdir))
            append!(files, [joinpath(dir, n) for n in names if
                (subdir == "generated/Vehicle" ?
                    (endswith(n, "_definition.jl") || n in ("module.jl", "types.jl")) :
                    (endswith(n, ".jl") || endswith(n, ".dyad")))])
        end
    end
    return sort!(unique!(files))
end

function inputs_hash()
    ctx = SHA.SHA256_CTX()
    for f in input_files()
        SHA.update!(ctx, codeunits(relpath(f, ROOT) * "\n"))
        SHA.update!(ctx, read(f))
    end
    return bytes2hex(SHA.digest!(ctx))
end

function render(rows, hash)
    lines = ["# inputs_sha256 = $hash", join(COLUMNS, ",")]
    for r in rows
        push!(lines, @sprintf("%s,%.3f,%.3f,%.10f,%s", r.architecture, r.period,
            r.offset, r.distance, string(r.wheel_lock)))
    end
    return join(lines, "\n") * "\n"
end

function read_sweep(path = OUT)
    lines = readlines(path)
    startswith(lines[1], "# inputs_sha256 = ") || error("missing inputs_sha256 header")
    split(lines[2], ",") == COLUMNS || error("unexpected CAN sweep columns")
    rows = map(lines[3:end]) do line
        v = split(line, ",")
        length(v) == length(COLUMNS) || error("malformed CAN sweep row: $line")
        (; architecture = String(v[1]), period = parse(Float64, v[2]),
            offset = parse(Float64, v[3]), distance = parse(Float64, v[4]),
            wheel_lock = parse(Bool, v[5]))
    end
    return rows, strip(split(lines[1], "="; limit = 2)[2])
end

"Distance to the first <0.5 m/s sample, measured from this run's own pedal onset."
function summarize(run, architecture, period, offset)
    s, m = run.sol, symbolic_container(run)
    string(s.retcode) == "Success" || error("CAN sweep failed: $(s.retcode)")
    last(s.t) == T_END || error("CAN sweep ended at $(last(s.t)) s")
    vehicle = architecture == "point" ? m.reference : m.vehicle
    onset = 0.5 + offset
    times = collect(onset:0.005:T_END)
    velocity = s(times; idxs = vehicle.car.bus.vx).u
    stopped = findfirst(<(0.5), velocity)
    isnothing(stopped) && error("vehicle did not stop: $architecture, $period, $offset")
    distance = s(times[stopped]; idxs = vehicle.car.bus.x) -
        s(onset; idxs = vehicle.car.bus.x)
    lock_times = collect(onset:0.001:T_END)
    speed = s(lock_times; idxs = vehicle.car.bus.vx).u
    wheel_lock = any((:fl, :fr, :rl, :rr)) do corner
        surface = 0.31 .* s(lock_times; idxs = getproperty(vehicle.car, corner).inertia.w).u
        any((surface .< 0.1) .& (speed .> 1.5))
    end
    return (; architecture, period, offset, distance, wheel_lock)
end

function analysis_spec(architecture, period)
    if architecture == "point"
        return CAN.CanReferenceStop__Spec()
    elseif architecture == "ideal"
        return CAN.CanIdealStop__Spec()
    end
    prefix = architecture == "real" ? "Can" : "CanBusBrake"
    return getproperty(CAN, Symbol(prefix, round(Int, 1000period), "msStop__Spec"))()
end

function sweep_group!(rows, architecture, period, hash)
    spec = analysis_spec(architecture, period)
    # Match generated analysis overrides: unnamespaced model quantities, not structural
    # periods. The latter require a distinct setup for each period/architecture.
    model = toggle_namespacing(spec.model, false)
    setup = setup_analysis(spec)
    for offset in OFFSETS
        onset = 0.5 + offset
        run = run_analysis(setup, [model.pedal.start_time => onset,
            :tstops => [onset, onset + 0.1]])
        row = summarize(run, architecture, period, offset)
        push!(rows, row)
        write(OUT, render(rows, hash))
        println(row)
        flush(stdout)
        run = nothing
        GC.gc()
    end
    return nothing
end

function main()
    mkpath(dirname(OUT))
    rows = NamedTuple[]
    hash = inputs_hash()
    # Point and ideal have no transport delay; period=0 denotes their common baseline.
    for architecture in ARCHITECTURES
        for period in (architecture in ("point", "ideal") ? [0.0] : PERIODS)
            sweep_group!(rows, architecture, period, hash)
            GC.gc()
        end
    end
    println("wrote $(relpath(OUT, ROOT))")
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    Lecture06CanSweep.main()
end
