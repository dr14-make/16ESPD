# Snapshot paths resolve against the working directory, so pin every test entry point here.
cd(@__DIR__)

using Test

# One process holding every group's compiled models and solutions outgrows a 30 GB machine, so
# a full run gives each group its own child process and its memory back when that child exits.
const GROUPS = [
    "tuning" => ["tuning_tables.jl"],
    "esp" => ["esp_plausibility.jl"],
    "brake" => ["brake_plausibility.jl"],
    "engine" => ["engine_plausibility.jl"],
    "actuator" => ["actuator_plausibility.jl"],
    "roadster" => ["roadster_plausibility.jl"],
    "abs" => ["abs_handson_plausibility.jl", "abs_full_car.jl"],
    "tcs" => ["tcs_bonus.jl"],
    "vacuum" => ["vacuum_booster_plausibility.jl", "vacuum_full_car.jl"],
    "lecture04" => ["machine_plausibility.jl", "converter_plausibility.jl", "battery_plausibility.jl"],
    "switching" => ["switching_plausibility.jl"],
    "planar_wltc" => ["planar_wltc_plausibility.jl"],
    "generated" => ["../generated/tests.jl"],
]

const REPORT_ENV = "VSC_TEST_REPORT"

function requested_groups()
    raw = isempty(ARGS) ? [get(ENV, "TEST_GROUPS", "")] : ARGS
    names = filter(!isempty, strip.(mapreduce(a -> split(a, ','), vcat, raw; init = [])))
    known = first.(GROUPS)
    unknown = setdiff(names, known)
    isempty(unknown) ||
        error("unknown test group(s) $(join(unknown, ", ")); known: $(join(known, ", "))")
    return names
end

function run_group(name)
    files = Dict(GROUPS)[name]
    counts = try
        ts = @testset "$name" begin
            include("plausibility_helpers.jl")
            foreach(include, files)
        end
        c = Test.get_test_counts(ts)
        (pass = c.passes + c.cumulative_passes,
            fail = c.fails + c.cumulative_fails,
            error = c.errors + c.cumulative_errors,
            broken = c.broken + c.cumulative_broken)
    catch e
        e isa Test.TestSetException || rethrow()
        (pass = e.pass, fail = e.fail, error = e.error, broken = e.broken)
    end
    peak_mb = Sys.maxrss() / 2^20
    println("Group $name peak memory: $(round(Int, peak_mb)) MB")
    report = get(ENV, REPORT_ENV, "")
    isempty(report) ||
        write(report, join((counts.pass, counts.fail, counts.error, counts.broken, peak_mb), ' '))
    return counts.fail + counts.error == 0
end

function run_children()
    project = Base.active_project()
    rows = []
    for (name, _) in GROUPS
        report = tempname()
        cmd = `$(Base.julia_cmd()) --project=$project --color=yes $(@__FILE__) $name`
        printstyled("\n── test group $name ──\n"; bold = true)
        started = time()
        proc = run(ignorestatus(addenv(cmd, REPORT_ENV => report)))
        elapsed = time() - started
        fields = isfile(report) ? split(read(report, String)) : String[]
        rm(report; force = true)
        push!(rows, (; name, proc, elapsed, fields))
    end

    println("\nTest groups | Pass  Fail  Error  Broken  Peak MB   Time  Status")
    ok = true
    for (; name, proc, elapsed, fields) in rows
        passed = success(proc)
        ok &= passed
        status = passed ? "ok" :
                 proc.termsignal != 0 ? "killed (signal $(proc.termsignal))" :
                 "failed (exit $(proc.exitcode))"
        p, f, e, b, mb = length(fields) == 5 ? fields : fill("?", 5)
        mb = mb == "?" ? mb : string(round(Int, parse(Float64, mb)))
        println(rpad(name, 12), "| ", lpad(p, 5), lpad(f, 6), lpad(e, 7), lpad(b, 8),
            lpad(mb, 9), lpad(string(round(Int, elapsed), "s"), 7), "  ", status)
    end
    total = sum(r -> r.elapsed, rows)
    println("Total time: $(round(Int, total)) s")
    return ok
end

const groups = requested_groups()
if isempty(groups)
    run_children() || exit(1)
else
    using VehicleSystemsComponents
    all(map(run_group, groups)) || exit(1)
end
