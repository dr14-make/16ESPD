"""
Export real switched-model traces for the Lecture 4 oscilloscope component.
    julia +dyad-3.5.0 --project=. scripts/export_lecture04_scope_traces.jl

Choppers: last four 20 kHz periods (buck 1.8–2 ms, boost 5.8–6 ms).
H-bridge: 20–60 ms, two 50 Hz cycles after 20 load time constants.
Each variant uses 1401 uniformly spaced interpolated samples; all numbers are
rounded to four significant digits. Gate retains the real model's finite ramps
between 0 and 1, rather than inventing an ideal binary switching waveform.
Square-wave operation uses the existing bench's saturated reference m = 20.
Reference/carrier are included in both bridge variants to keep channel names fixed.
"""
const SCOPE_EXPORT_DESCRIPTION = nothing

using Revise
using VehicleSystemsComponents
using DyadInterface: symbolic_container
using JSON
Revise.revise()

const E = VehicleSystemsComponents.Vehicle.Electric
const OUT = joinpath(@__DIR__, "..", "slides", "decks", "lecture-04", "public", "scope")

function variant(run, label, a, b, signals)
    s, m = run.sol, symbolic_container(run)
    string(s.retcode) == "Success" || error("$label: $(s.retcode)")
    ts = range(a, b; length = 1401)
    channels = map(signals) do (name, label, unit, signal)
        y = Float64.(s(ts, idxs = signal(m)).u)
        all(isfinite, y) || error("nonfinite channel $name")
        (; name, label, unit, y = round.(y; sigdigits = 4))
    end
    (; label, t = round.(collect(ts) .- a; sigdigits = 4), channels)
end

function save_scope(name, title, bench, variants)
    payload = (; title, source = "VehicleSystemsComponents.Vehicle.Electric.$bench, scripts/export_lecture04_scope_traces.jl", variants)
    path = joinpath(OUT, "$name.json")
    open(io -> JSON.print(io, payload), path, "w")
    filesize(path) < 150_000 || error("$name exceeds 150 kB")
    println("$name.json: $(filesize(path)) bytes")
end

function main()
    mkpath(OUT)
    chopper_signals = [
        ("gate", "gate", "", m -> m.chopper.pwm.y),
        ("v_sw", "switch node", "V", m -> m.chopper.v_sw),
        ("i_L", "inductor current", "A", m -> m.chopper.i_L),
        ("v_out", "output", "V", m -> m.chopper.v_out),
    ]
    for (name, bench, analysis, stop) in (
            ("buck", "TestBuckChopper", E.BuckChopperTransient, 2e-3),
            ("boost", "TestBoostChopper", E.BoostChopperTransient, 6e-3))
        variants = [variant(analysis(d = d), "d = $d", stop - 4 / 20e3, stop, chopper_signals)
                    for d in (0.25, 0.5, 0.75)]
        save_scope(name, "$(uppercasefirst(name)) chopper, 48 V in, 20 kHz", bench, variants)
    end
    bridge_signals = [
        ("v_ab", "output voltage", "V", m -> m.bridge.v_ab),
        ("i_load", "load current", "A", m -> m.bridge.i_ab),
        ("reference", "reference", "", m -> m.bridge.u),
        ("carrier", "carrier", "", m -> m.bridge.pwm_a.carrier),
    ]
    variants = [variant(E.HBridgeTransient(m = m), label, 0.02, 0.06, bridge_signals)
                for (m, label) in ((20.0, "square wave"), (0.8, "sine PWM, m = 0.8"))]
    save_scope("hbridge", "H-bridge, 350 V DC, 50 Hz, 1 kHz carrier", "TestHBridge", variants)
end
main()
