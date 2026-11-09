"""
Sweeps the P2 hybrid's machine size over WLTC and writes `assets/data/lecture05/machine_size.csv`.

    julia +dyad-3.5.0 --project=. scripts/machine_size_sweep.jl [P_kW ...]

Each size runs `Lecture5.P2HybridWLTC` with its parameters overridden in Julia, the `.dyad`
source untouched, and everything that is a machine limit derived from its rated power `P`:

- the drive: `P_rated = P`, `T_max = P / W_CORNER`, so the field-weakening corner stays where
  the default machine has it and only the torque scales, and `V_design` the pack's terminal
  voltage at rated input, as the 15 kW dyno case of `test/lecture05_plausibility.jl` designs it;
- the manager's `T_max` and `P_max` equal to the drive's, and its regenerative-power ceiling
  `P_regen = P`;
- the driver's drive ceiling `tau_max` = drive `T_max` + the engine's full-load peak, checked
  after every run against the engine table the run solved with.

The driver's braking ceiling `tau_brake`, friction and regen together, stays at the default
model's value. The pack and every other manager parameter are fixed: its demand-power
thresholds, charging power and line cap are strategy and engine settings, not machine limits. A
row whose run does not end charge-sustaining (`SOC_BAND`) or does not follow the trace
(`SPEED_ERROR_MAX`) is still written, flagged.

Every default this file derives from is read from the default model's parameters
(`DEFAULTS`); the 30 kW size runs that model unchanged. The first line of the file records the
SHA-256 of the code, generated definitions and data the runs read, so a test can tell when the
file is stale; the suite does not rerun the sweep. The hash does not cover package versions, so
rerun the sweep after a package update. The file is rewritten after every size, so sizes named
as arguments rerun only those and keep the other rows while the hash still matches.
"""
module MachineSizeSweep

using Printf, SHA
using VehicleSystemsComponents: Lecture5
using DyadInterface: symbolic_container
using ModelingToolkit: initial_conditions
using ModelingToolkit.SymbolicUtils: unwrap_const

const ROOT = normpath(@__DIR__, "..")
const OUT = joinpath(ROOT, "assets", "data", "lecture05", "machine_size.csv")
const SIZES_KW = [8.0, 15.0, 22.0, 30.0, 40.0]
const COLUMNS = ["P_rated", "T_max", "fuel_raw", "fuel_corr", "energy_corr", "saving_vs_H0_pct",
    "SoC_end", "max_speed_error", "starts", "flag"]

"Numeric parameter defaults of the uncompiled default `P2HybridWLTC`, by dotted path."
function default_parameters()
    sys = Lecture5.P2HybridWLTC(; name = :P2HybridWLTC)
    return Dict(replace(string(k), "₊" => ".") => Float64(unwrap_const(v))
                for (k, v) in initial_conditions(sys) if unwrap_const(v) isa Real)
end

const DEFAULTS = default_parameters()
"Field-weakening corner [rad/s] of the default machine, `P_rated / T_max`."
const W_CORNER = DEFAULTS["powertrain.drive.P_rated"] / DEFAULTS["powertrain.drive.T_max"]
"Open-circuit voltage [V] of the fixed pack."
const V_PACK = DEFAULTS["powertrain.drive.E"]
"Internal resistance [Ω] of the fixed pack."
const R_PACK = DEFAULTS["powertrain.drive.R0"]
# The machine efficiency at rated input that the loaded design voltage assumes. No model
# parameter carries it; `main` checks that it reproduces the default `V_design`.
const ETA_DESIGN = 0.9
"The engine's full-load peak torque [N·m]: the default driver ceiling less the machine's."
const FULL_LOAD_PEAK = DEFAULTS["tau_max"] - DEFAULTS["powertrain.drive.T_max"]
"The driver's braking ceiling [N·m], friction and regen together, the same at every size."
const TAU_BRAKE = DEFAULTS["tau_brake"]
"The engine's peak power [W], as the energy manager carries it."
const P_ENGINE_PEAK = DEFAULTS["manager.P_peak"]
"H0's WLTC fuel [L/100 km], the conventional baseline; the Lecture 5 tests pin H0 to it."
const H0_L100 = 5.7175350775
const SOC_BAND = 0.02
const SPEED_ERROR_MAX = 2.0
"The run's span [s]: one WLTC class 3b."
const T_END = 1800.0

"Terminal voltage [V] of the fixed pack delivering `P` [W] to a machine of `ETA_DESIGN`."
design_voltage(P) = (V_PACK + sqrt(V_PACK^2 - 4 * R_PACK * P / ETA_DESIGN)) / 2

"Machine torque limit [N·m] of a machine rated `P` [W] with its corner at `W_CORNER`."
torque_limit(P) = P / W_CORNER

"Degree of hybridization of a machine rated `P` [W] beside the engine."
doh(P) = P / (P + P_ENGINE_PEAK)

"""
The files the runs read: the library's code, the compiled Vehicle components, the
bench and the data tables. Only component definitions count, so a component added to the
library or a test generated for one leaves the hash alone.
"""
function input_files()
    files = String[]
    for (dir, _, names) in walkdir(joinpath(ROOT, "generated", "Vehicle"))
        append!(files, joinpath.(dir, filter(endswith("_definition.jl"), names)))
    end
    src = joinpath(ROOT, "src")
    append!(files, joinpath.(src, filter(endswith(".jl"), readdir(src))))
    append!(files, joinpath.(ROOT, [
        "generated/internals.jl",
        "generated/Lecture5/module.jl",
        "generated/Lecture5/types.jl",
        "generated/Lecture5/P2HybridWLTC_definition.jl",
        "generated/Lecture5/P2HybridWLTCTransient_definition.jl",
        "assets/data/engine/bsfc_line.csv",
        "assets/data/engine/torque_to_pedal.csv",
        "assets/data/drive_cycles/wltc_class3b.csv",
    ]))
    return sort!(files)
end

"SHA-256 over the input files' repository paths and contents, independent of checkout location."
function inputs_hash()
    ctx = SHA.SHA256_CTX()
    for f in input_files()
        SHA.update!(ctx, codeunits(relpath(f, ROOT) * "\n"))
        SHA.update!(ctx, read(f))
    end
    return bytes2hex(SHA.digest!(ctx))
end

"The CSV text of `rows`; fixed decimals keep reruns byte-identical."
function render(rows, hash)
    lines = ["# inputs_sha256 = $hash", join(COLUMNS, ",")]
    for r in rows
        push!(lines, @sprintf("%.0f,%.4f,%.6f,%.6f,%.4f,%.3f,%.5f,%.4f,%d,%s", r.P_rated,
            r.T_max, r.fuel_raw, r.fuel_corr, r.energy_corr, r.saving_vs_H0_pct, r.SoC_end,
            r.max_speed_error, r.starts, r.flag))
    end
    return join(lines, "\n") * "\n"
end

"""
    read_sweep(path = OUT)

The rows of a sweep file as a vector of named tuples with the `COLUMNS` fields, and the
`inputs_sha256` its first line records.
"""
function read_sweep(path = OUT)
    lines = readlines(path)
    hash = strip(split(lines[1], "=")[2])
    header = Symbol.(split(lines[2], ","))
    rows = map(lines[3:end]) do line
        v = split(line, ",")
        vals = [k == :flag ? String(x) : k == :starts ? parse(Int, x) : parse(Float64, x)
                for (k, x) in zip(header, v)]
        NamedTuple{Tuple(header)}(Tuple(vals))
    end
    return rows, hash
end

"A flag naming each check the run fails, `ok` when it passes them all."
function run_flag(dSoC, max_error)
    flags = String[]
    abs(dSoC) > SOC_BAND && push!(flags, "soc_not_sustained")
    max_error > SPEED_ERROR_MAX && push!(flags, "speed_error")
    return isempty(flags) ? "ok" : join(flags, "+")
end

function run_size(P)
    T = torque_limit(P)
    overrides = Dict{String, Any}("powertrain.drive.P_rated" => P,
        "powertrain.drive.T_max" => T, "powertrain.drive.V_design" => design_voltage(P),
        "manager.T_max" => T, "manager.P_max" => P, "manager.P_regen" => P)
    model = Lecture5.P2HybridWLTC(; name = :P2HybridWLTC, tau_max = T + FULL_LOAD_PEAK,
        tau_brake = TAU_BRAKE, __overrides = overrides)
    return Lecture5.P2HybridWLTCTransient(; model)
end

function summarize(run)
    s, m = run.sol, symbolic_container(run)
    string(s.retcode) == "Success" || error("run ended with retcode $(s.retcode)")
    (first(s.t), last(s.t)) == (0.0, T_END) || error("run spans $(extrema(s.t)), not 0..$T_END s")
    drive, manager = m.powertrain.drive, m.manager
    # The problem stores the table's interpolator inside a FunctionWrapper; obj[] is the table.
    full_load = s.ps[m.powertrain.engine.torque_map.full_load.table.interpolator].obj[]
    peak = maximum(full_load.u)
    isapprox(peak, FULL_LOAD_PEAK; atol = 1e-9, rtol = 0) ||
        error("engine full-load peak $peak is not FULL_LOAD_PEAK $FULL_LOAD_PEAK")
    T = s.ps[drive.T_max]
    P = s.ps[drive.P_rated]
    s.ps[manager.T_max] == T && s.ps[manager.P_max] == P && s.ps[manager.P_regen] == P ||
        error("manager envelope differs from the drive's")
    s.ps[m.tau_brake] == TAU_BRAKE || error("braking ceiling $(s.ps[m.tau_brake]) moved")
    isapprox(s.ps[m.tau_max], T + peak; atol = 1e-9, rtol = 0) ||
        error("driver ceiling $(s.ps[m.tau_max]) is not T_max + full-load peak $(T + peak)")
    ts = collect(0.0:0.05:T_END)
    at(x) = s(ts, idxs = x).u
    soc = at(m.powertrain.SoC)
    on = at(manager.engine_on) .> 0.5
    max_error = maximum(abs.(3.6 .* at(m.car.bus.vx) .- at(m.trace.y)))
    row = (; P_rated = P, T_max = T, fuel_raw = last(s[m.meter.fuel_raw]),
        fuel_corr = last(s[m.meter.fuel_corr]), energy_corr = last(s[m.meter.energy_corr]),
        saving_vs_H0_pct = 100 * (1 - last(s[m.meter.fuel_corr]) / H0_L100),
        SoC_end = soc[end], max_speed_error = max_error, starts = count(diff(on) .== 1),
        flag = run_flag(soc[end] - soc[1], max_error))
    return row
end

function main(sizes_kW = SIZES_KW)
    # The 30 kW row is the model's own defaults; the derivation must land on them exactly.
    P0 = DEFAULTS["powertrain.drive.P_rated"]
    P0 == 30e3 && DEFAULTS["manager.P_regen"] == P0 && DEFAULTS["manager.P_max"] == P0 &&
        DEFAULTS["manager.T_max"] == DEFAULTS["powertrain.drive.T_max"] &&
        isapprox(torque_limit(P0), DEFAULTS["powertrain.drive.T_max"]; rtol = 1e-12) &&
        isapprox(design_voltage(P0), DEFAULTS["powertrain.drive.V_design"]; rtol = 1e-12) ||
        error("the size derivation does not reproduce the default model's 30 kW machine")
    issubset(sizes_kW, SIZES_KW) || error("sizes must be among $SIZES_KW kW")
    hash = inputs_hash()
    kept = isfile(OUT) ? read_sweep() : ([], "")
    rows = Any[r for r in (last(kept) == hash ? first(kept) : []) if !(r.P_rated / 1e3 in sizes_kW)]
    for P_kW in sizes_kW
        run = P_kW == 30.0 ? Lecture5.P2HybridWLTCTransient() : run_size(1e3P_kW)
        row = summarize(run)
        println(row)
        flush(stdout)
        push!(rows, row)
        sort!(rows; by = r -> r.P_rated)
        write(OUT, render(rows, hash))
        run = nothing
        GC.gc()
    end
    missing_kW = setdiff(SIZES_KW, [r.P_rated / 1e3 for r in rows])
    isempty(missing_kW) || @warn "sizes not yet in the file: $missing_kW kW"
    println("wrote $(relpath(OUT, ROOT))")
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    MachineSizeSweep.main(isempty(ARGS) ? MachineSizeSweep.SIZES_KW : parse.(Float64, ARGS))
end
