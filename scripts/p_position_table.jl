"""
Reproduce the pinned 30 kW WLTC position comparison, one simulation at a time.
Run with julia +dyad-3.5.0 --project=. scripts/p_position_table.jl.
"""
module PPositionTable
using SHA
const ROOT = normpath(joinpath(@__DIR__, ".."))
const TABLE = joinpath(ROOT, "assets/data/lecture05/p_positions.csv")
const H0 = 5.71753646
const LINE = 5.43744462
const COLUMNS = (:position, :P_rated_kW, :fuel_raw_L100, :fuel_corr_L100, :energy_MJ100,
    :saving_H0_pct, :saving_line_pct, :E_regen_MJ, :E_recovered_MJ, :electric_drive_s, :starts, :fuel_resumptions,
    :SoC_start, :SoC_end, :max_speed_error_kmh, :definitions_sha256)

"Transitive package-local definitions referenced by a generated bench and its analysis."
function definition_files(bench)
    generated = joinpath(ROOT, "generated")
    index = Dict{String, String}()
    for (dir, _, files) in walkdir(generated), file in files
        endswith(file, "_definition.jl") || continue
        relative = relpath(joinpath(dir, file), generated)
        name = replace(relative, "_definition.jl" => "", '/' => '.')
        index["VehicleSystemsComponents." * name] = joinpath(dir, file)
    end
    pending = ["VehicleSystemsComponents.Lecture5." * bench,
        "VehicleSystemsComponents.Lecture5." * bench * "Transient"]
    visited = Set{String}()
    while !isempty(pending)
        name = pop!(pending)
        name in visited && continue
        push!(visited, name)
        file = index[name]
        namespace = join(split(name, '.')[1:end-1], '.')
        for reference in eachmatch(r"\b[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*\s*\(", read(file, String))
            candidate = strip(chop(reference.match))
            qualified = startswith(candidate, "VehicleSystemsComponents.") ? candidate : namespace * "." * candidate
            haskey(index, qualified) && push!(pending, qualified)
        end
    end
    sort!([index[name] for name in visited])
end

"Fingerprint the bench's transitive generated package-local dependency closure."
function definitions_hash(position)
    benches = Dict("P0" => "CoupledHybridWLTC", "P1" => "P1HybridWLTC", "P2" => "P2HybridWLTC",
        "P3" => "OutputHybridWLTC", "P4" => "P4HybridWLTC")
    io = IOBuffer()
    for file in definition_files(benches[position])
        write(io, relpath(file, ROOT), '\n', read(file), '\n')
    end
    bytes2hex(sha256(take!(io)))
end

function metrics(run, position; P_rated_kW = 30.0)
    m = Main.symbolic_container(run)
    s = run.sol
    string(s.retcode) == "Success" && s.t[end] == 1800.0 || error("incomplete $position run")
    ts = collect(0.0:0.05:1800.0)
    at(x) = s(ts, idxs = x).u
    integrate(y) = sum((y[1:end-1] .+ y[2:end]) ./ 2) * 0.05
    on = at(m.manager.engine_on) .> 0.5
    v = at(m.kmh.y)
    soc = at(m.powertrain.SoC)
    corr = last(s[m.meter.fuel_corr])
    (; position, P_rated_kW, fuel_raw_L100 = last(s[m.meter.fuel_raw]),
        fuel_corr_L100 = corr, energy_MJ100 = last(s[m.meter.energy_corr]),
        saving_H0_pct = 100 * (1 - corr / H0), saving_line_pct = 100 * (1 - corr / LINE),
        E_regen_MJ = last(s[m.E_regen]) / 1e6,
        E_recovered_MJ = integrate(max.(-at(m.powertrain.E) .* at(m.powertrain.i), 0.0) .* (at(m.manager.tau_dem) .< 0.0)) / 1e6,
        electric_drive_s = integrate(Float64.((.!on) .& (v .> 1.0) .& (at(m.manager.tau_drive) .> 1.0))),
        starts = count(==(1), diff(at(m.powertrain.engine_speed) .* (30 / pi) .>= s.prob.ps[m.powertrain.firing_rpm])),
        fuel_resumptions = count(==(1), diff(on)), SoC_start = first(soc), SoC_end = last(soc),
        max_speed_error_kmh = maximum(abs.(v .- at(m.trace.y))),
        definitions_sha256 = definitions_hash(position))
end

function read_table(path = TABLE)
    lines = readlines(path)
    names = Symbol.(split(first(lines), ','))
    [NamedTuple{Tuple(names)}(Tuple(names[i] in (:position, :baseline, :definitions_sha256) ? x : parse(Float64, x)
        for (i, x) in enumerate(split(line, ',')))) for line in lines[2:end] if !isempty(line)]
end

"Measure the line car's low-power fuel share; this is a proxy, not a stop/start simulation."
function generate_baselines(L)
    run = Base.invokelatest(L.P2OperatingLineWLTCTransient)
    m, s = Main.symbolic_container(run), run.sol
    string(s.retcode) == "Success" || error("line baseline failed")
    ts = collect(0.0:0.05:1800.0)
    at(x) = s(ts, idxs = x).u
    power = at(m.powertrain.engine_torque) .* at(m.powertrain.engine_speed)
    fuel = at(m.powertrain.mdot_fuel) .* (power .<= 1000.0)
    idle_mass = sum((fuel[1:end-1] .+ fuel[2:end]) ./ 2) * 0.05
    idle = 1e8 * idle_mass / (745.0 * last(s[m.meter.s]))
    open(joinpath(dirname(TABLE), "baselines.csv"), "w") do io
        println(io, "baseline,fuel_L100,idle_fuel_L100")
        println(io, "line,", last(s[m.meter.fuel_raw]), ',', idle)
    end
end

function generate()
    L = Main.VehicleSystemsComponents.Lecture5
    cases = [("P0", L.CoupledHybridWLTCTransient), ("P1", L.P1HybridWLTCTransient), ("P2", L.P2HybridWLTCTransient),
        ("P3", L.OutputHybridWLTCTransient), ("P4", L.P4HybridWLTCTransient)]
    mkpath(dirname(TABLE))
    open(TABLE, "w") do io
        println(io, join(COLUMNS, ','))
        for (position, analysis) in cases
            row = metrics(Base.invokelatest(analysis), position)
            println(io, join(getproperty.(Ref(row), COLUMNS), ','))
            flush(io)
            println(row)
            GC.gc(true)
        end
    end
    generate_baselines(L)
end
end

if abspath(PROGRAM_FILE) == @__FILE__
    using Revise
    using VehicleSystemsComponents, DyadInterface
    Revise.revise()
    PPositionTable.generate()
end
