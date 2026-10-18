### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ 2bc9e014-70e5-4fae-9f67-1863951789c4
begin
    import Pkg
    Pkg.activate(joinpath(@__DIR__, "..", ".."))
    include(joinpath(@__DIR__, "..", "lecture01", "support.jl"))
    using .Lecture01Support

    # PlutoPlotly is no dependency of the library, so it comes from a shared environment stacked
    # behind the project: the project's Manifest stays the library's own.
    let env = "@lecture02-plotly"
        env in LOAD_PATH || push!(LOAD_PATH, env)
        if isnothing(Base.identify_package("PlutoPlotly"))
            project = Base.active_project()
            try
                Pkg.activate(env[2:end]; shared = true)
                Pkg.add(Pkg.PackageSpec(; name = "PlutoPlotly", version = "0.6.6"))
            finally
                Pkg.activate(project)
            end
        end
    end

    # Not bound as `VehicleSystemsComponents`: run as a script, that global would collide with
    # the module of the same name that `setup` defines in `Main`.
    library = setup()
    using PlutoUI
    import PlutoPlotly as PP
    const Lecture2 = library.Lecture2
end

# ╔═╡ 99fcbb1c-83a7-4529-a3ad-baf8c68be994
md"""
# Lecture 2 · 09 — Sensors

> **The ECU knows only what its sensors tell it, through their characteristic curves.**

The coolant and intake-air temperature sensors are NTC thermistors: their resistance falls
steeply as they warm. This notebook starts from a real one, the Bosch Motorsport NTC M12, whose
datasheet gives its resistance at ten temperatures. It then turns to the sensor the ECU trusts
most, the throttle position sensor, and to the electronic throttle that closes a loop on it.
"""

# ╔═╡ c04b178f-8993-4690-8dff-a1274c185947
begin
    const NOTES = joinpath(@__DIR__, "..", "..", "docs", "research_notes",
        "Engine control systems", "teaching_materials.md")

    """
        bosch_ntc_m12() -> (; T_C, R_ohm)

    The datasheet table as `teaching_materials.md` transcribes it, in its row for the NTC M12:
    `R(T): −40 °C 45,313 Ω; −20 15,462; …`.
    """
    function bosch_ntc_m12()
        row = only(filter(l -> occursin("Bosch NTC M12", l), readlines(NOTES)))
        table = match(r"R\(T\):(.*?)\. Accuracy", row)[1]
        pairs = map(split(table, ";")) do entry
            numbers = [replace(m.match, "−" => "-", "," => "")
                for m in eachmatch(r"−?[\d,]+", replace(entry, "**" => ""))]
            parse(Float64, numbers[1]) => parse(Float64, numbers[2])
        end
        (; T_C = first.(pairs), R_ohm = last.(pairs))
    end

    ntc = bosch_ntc_m12()

    # Steinhart–Hart through three datasheet points: 1/T = a + b ln R + c (ln R)³.
    function steinhart_hart(T_C, R)
        L = log.(R)
        A = hcat(ones(3), L, L .^ 3)
        a, b, c = A \ (1 ./ (T_C .+ 273.15))
        R_of_T(T) = begin
            y = (a - 1 / (T + 273.15)) / c
            x = sqrt((b / (3c))^3 + y^2 / 4)
            exp(cbrt(x - y / 2) - cbrt(x + y / 2))
        end
        R_of_T
    end
    anchors = findall(in((-20.0, 20.0, 100.0)), ntc.T_C)
    ntc_fit = steinhart_hart(ntc.T_C[anchors], ntc.R_ohm[anchors])

    deck_layout(; kwargs...) = PP.Layout(;
        template = PP.templates[:plotly_white],
        font = PP.attr(size = 15),
        margin = PP.attr(l = 80, r = 20, t = 30, b = 60),
        kwargs...)
end

# ╔═╡ 90f13bf7-988b-4e9d-97d1-17de6b3136ff
md"""
## The NTC characteristic

The datasheet points, and a Steinhart–Hart curve fitted through three of them (−20, 20 and
100 °C). On a logarithmic axis the curve is nearly straight: the resistance roughly halves
every 20 °C.
"""

# ╔═╡ e3d8c8b0-98db-474b-a42e-449c4b1117e9
# ╠═╡ card = "ntc-curve"
let T = collect(-40.0:1.0:130.0)
    PP.plot(
        [
            PP.scatter(; x = T, y = round.(ntc_fit.(T); sigdigits = 5), mode = "lines",
                name = "Steinhart–Hart fit", line = PP.attr(width = 3)),
            PP.scatter(; x = ntc.T_C, y = ntc.R_ohm, mode = "markers", name = "Bosch NTC M12 datasheet",
                marker = PP.attr(size = 10, color = "black")),
        ],
        deck_layout(; xaxis_title = "temperature [°C]", yaxis_title = "resistance [Ω]",
            yaxis_type = "log", yaxis_dtick = 1, yaxis_exponentformat = "SI",
            legend = PP.attr(x = 0.98, xanchor = "right", y = 0.98)))
end

# ╔═╡ 81dcb403-100c-4c08-99a3-a5c65ddfb2ac
let
    @assert length(ntc.T_C) == 10 "the datasheet row holds $(length(ntc.T_C)) points, not 10"
    @assert ntc.R_ohm[ntc.T_C .== 20.0] == [2500.0] "R(20 °C) must read 2500 Ω"
    errors = abs.(ntc_fit.(ntc.T_C) ./ ntc.R_ohm .- 1)
    @assert maximum(errors) < 0.03 "Steinhart–Hart misses the datasheet by $(round(100maximum(errors); digits = 1)) %"
    md"""
    **Datasheet span** $(round(Int, maximum(ntc.R_ohm))) Ω at $(round(Int, minimum(ntc.T_C))) °C to
    $(round(Int, minimum(ntc.R_ohm))) Ω at $(round(Int, maximum(ntc.T_C))) °C. **Fit error**
    at most $(round(100maximum(errors); digits = 1)) %.
    """
end

# ╔═╡ 9290f55c-9569-4d9b-b5d6-b02687bc1974
md"""
## The throttle position sensor

The classic throttle position sensor is a potentiometer on the throttle shaft. Deck slide 34
draws one with two tracks: two wipers on one shaft, each tapping its own resistive track between
the ECU's 5 V reference and ground. `Vehicle.Engine.ThrottlePositionSensor` builds that circuit
from the standard library: two `Potentiometer`s whose wiper position is the plate angle over its
83° of travel, an end resistor at each end of each track, and an ECU input on each wiper.

Two details carry the diagnosis. The end resistors keep a healthy wiper away from the supply and
from ground, so a healthy track reads between 0.5 V and 4.5 V, and a reading outside that window
is a short or an open circuit. And the second track is wired the other way round, so its voltage
falls while the first rises: their sum stays at 5 V at every angle. A worn spot or a bad contact
moves one track and not the other, and the sum leaves its window. That sum is what the ECU's
plausibility check watches.

Every resistance in the model is *(assumed)*: no supplier publishes a throttle-body sensor's
values. The 0.5–4.5 V window is the common automotive convention.
"""

# ╔═╡ 32af266f-f964-411c-b979-88a2f4e3f396
show_dyad("ThrottlePositionSensor")

# ╔═╡ 58a4f3f0-90d1-4267-87d2-51a2ce4b56be
begin
    const PHI_SPAN_DEG = 83.0
    const WORN_R_WIPER = 50e3

    "Both tracks and their sum against the plate angle from the closed stop, in degrees."
    function tps_sweep(; R_wiper1 = 10.0)
        run = Lecture2.ThrottleSensorSweepTransient(; R_wiper1)
        t, phi = signal(run, "angle.y")
        (; deg = rad2deg.(phi), V1 = last(signal(run, "tps.V1")), V2 = last(signal(run, "tps.V2")),
            sum = last(signal(run, "track_sum.y")))
    end
    healthy = tps_sweep()
    worn = tps_sweep(R_wiper1 = WORN_R_WIPER)
    # The ECU's window around the 5 V sum (assumed).
    const SUM_WINDOW = (4.75, 5.25)
end

# ╔═╡ d4ae1cb4-49de-4221-8968-6b99d5321d49
md"""
The sweep turns the plate from 5° before the closed stop to 5° past wide open. Beyond the travel
the wipers sit at the ends of their tracks, so the voltages stay put. The dashed curves are the
same sensor with track 1 worn: its wiper contact grown from 10 Ω to 50 kΩ, against the ECU's
100 kΩ input. Track 1 alone reads low; the sum gives it away.
"""

# ╔═╡ 40d4fc61-4460-417e-8461-63dbe73c7623
# ╠═╡ card = "tps-tracks"
let
    x = round.(healthy.deg; digits = 3)
    v(y) = round.(y; digits = 4)
    PP.plot(
        [
            PP.scatter(; x, y = v(healthy.V1), mode = "lines", name = "track 1, V1",
                line = PP.attr(width = 3, color = "#1e88e5")),
            PP.scatter(; x, y = v(healthy.V2), mode = "lines", name = "track 2, V2",
                line = PP.attr(width = 3, color = "#e53935")),
            PP.scatter(; x, y = v(healthy.sum), mode = "lines", name = "V1 + V2: what the ECU checks",
                line = PP.attr(width = 3, color = "#43a047")),
            PP.scatter(; x, y = v(worn.V1), mode = "lines", name = "V1, worn track 1",
                line = PP.attr(width = 2, color = "#1e88e5", dash = "dash")),
            PP.scatter(; x, y = v(worn.sum), mode = "lines", name = "V1 + V2, worn track 1",
                line = PP.attr(width = 2, color = "#43a047", dash = "dash")),
        ],
        deck_layout(; xaxis_title = "plate angle from the closed stop [°]", yaxis_title = "voltage [V]",
            yaxis_range = [0, 5.6], xaxis_range = [first(x), last(x)],
            shapes = [
                PP.attr(type = "rect", xref = "paper", x0 = 0, x1 = 1, y0 = SUM_WINDOW[1], y1 = SUM_WINDOW[2],
                    fillcolor = "#43a047", opacity = 0.12, line_width = 0),
                PP.attr(type = "rect", xref = "paper", x0 = 0, x1 = 1, y0 = 0.5, y1 = 4.5,
                    fillcolor = "#90a4ae", opacity = 0.08, line_width = 0),
            ],
            legend = PP.attr(orientation = "h", x = 0, y = 1.02, yanchor = "bottom", font = PP.attr(size = 13)),
            margin = PP.attr(l = 70, r = 20, t = 70, b = 60)))
end

# ╔═╡ a2497ace-abe6-4fb3-8598-077672bcac31
let
    inside(v) = 0.45 <= v <= 4.55
    @assert all(inside, healthy.V1) && all(inside, healthy.V2) "a healthy track left the 0.5–4.5 V window"
    @assert all(s -> SUM_WINDOW[1] < s < SUM_WINDOW[2], healthy.sum) "the healthy sum left its window"
    @assert any(s -> !(SUM_WINDOW[1] < s < SUM_WINDOW[2]), worn.sum) "the worn track passes the plausibility check"
    flagged = healthy.deg[findfirst(s -> !(SUM_WINDOW[1] < s < SUM_WINDOW[2]), worn.sum)]
    md"""
    **Healthy tracks** $(round(minimum(healthy.V1); digits = 3))–$(round(maximum(healthy.V1); digits = 3)) V,
    **sum** $(round(minimum(healthy.sum); digits = 3))–$(round(maximum(healthy.sum); digits = 3)) V:
    the ECU inputs pull it $(round(Int, 1e3(5 - maximum(healthy.sum))))–$(round(Int, 1e3(5 - minimum(healthy.sum)))) mV below 5 V. **Worn track 1** leaves the sum's
    $(SUM_WINDOW[1])–$(SUM_WINDOW[2]) V window from $(round(flagged; digits = 1))° on.
    """
end

# ╔═╡ e56e8d7b-43ac-4abd-a34a-a592fd02bbd8
md"""
## Drive by wire: the electronic throttle

With electronic throttle control the pedal has the sensor, and the throttle is an actuator the
ECU positions. `Vehicle.Engine.ElectronicThrottle` is that actuator, closed around its own
position sensor:

- a DC motor (`ElectricalComponents` resistance, inductance and `RotationalEMF`), driven by an
  H-bridge that applies up to ± the battery voltage;
- a gearbox onto the plate shaft, where the plate inertia, the return spring, the end stops and
  the bearing friction act;
- the `ThrottlePositionSensor` on the shaft, read through both tracks into the ECU's position
  estimate `u_meas = ½ + (V1 − V2) / 8 V`;
- a PID position loop from the commanded opening to the motor voltage.

The return spring has a **limp-home** position: unpowered, the plate rests 6° open, held there by
two preloaded springs that push back from either side. A motor failure leaves the engine enough
air to limp to a garage. The preload also means the motor works against a torque that changes
sign at limp home, which is why the position loop needs integral action. Every motor, gear,
spring and controller value is *(assumed)*, at the scale of a 50 mm passenger-car throttle body.
"""

# ╔═╡ 971bbe80-cf23-46f5-81d8-399515962b55
show_dyad("ElectronicThrottle")

# ╔═╡ 9e4e67b7-f6d7-45d3-bc35-e6b8a27ddfd1
md"""
The pedal steps from limp home to 60 % open at 0.1 s, holds, and ramps back to 10 % from 0.6 s.
The pedal map is one to one, so this is the throttle's own loop and nothing of the torque
structure.
"""

# ╔═╡ 6a1efd3b-3357-4a1b-bacb-1443656d636d
begin
    "Commanded and measured plate angle (deg), true plate angle, motor current and the TPS tracks."
    function etc_run(; kwargs...)
        run = Lecture2.ThrottlePedalStepTransient(; kwargs...)
        t, cmd = signal(run, "command.y")
        (; t, cmd = PHI_SPAN_DEG .* cmd, meas = PHI_SPAN_DEG .* last(signal(run, "etc.u_thr")),
            phi = rad2deg.(last(signal(run, "etc.phi"))), i = last(signal(run, "etc.i_motor")),
            V1 = last(signal(run, "etc.V1")), V2 = last(signal(run, "etc.V2")))
    end

    """
        etc_figure(runs; tps = false) -> PlutoPlotly plot

    Plate angle against command, and motor current below it, on one time axis. `runs` pairs a run
    with a label and a dash; with `tps` a third panel shows both TPS tracks of the first run.
    """
    function etc_figure(runs; tps = false)
        r(y; d = 3) = round.(y; digits = d)
        rows = tps ? 3 : 2
        traces = Any[]
        lead = first(first(runs))
        push!(traces, PP.scatter(; x = r(lead.t), y = r(lead.cmd; d = 2), mode = "lines", name = "commanded",
            line = PP.attr(width = 2, color = "#9e9e9e", dash = "dot")))
        for (run, label, dash) in runs
            push!(traces, PP.scatter(; x = r(run.t), y = r(run.meas; d = 2), mode = "lines",
                name = "measured by the TPS$label", line = PP.attr(; width = 3, color = "#1e88e5", dash)))
            push!(traces, PP.scatter(; x = r(run.t), y = r(run.i), mode = "lines", name = "motor current$label",
                xaxis = "x2", yaxis = "y2", line = PP.attr(; width = 3, color = "#e53935", dash)))
        end
        if tps
            push!(traces, PP.scatter(; x = r(lead.t), y = r(lead.V1), mode = "lines", name = "V1",
                xaxis = "x3", yaxis = "y3", line = PP.attr(width = 2, color = "#3949ab")))
            push!(traces, PP.scatter(; x = r(lead.t), y = r(lead.V2), mode = "lines", name = "V2",
                xaxis = "x3", yaxis = "y3", line = PP.attr(width = 2, color = "#8e24aa")))
        end
        domains = tps ? ([0.58, 1.0], [0.29, 0.52], [0.0, 0.23]) : ([0.42, 1.0], [0.0, 0.34])
        titles = ("plate angle [°]", "current [A]", "TPS [V]")
        axes = Dict{Symbol, Any}()
        for row in 1:rows
            suffix = row == 1 ? "" : string(row)
            axes[Symbol("xaxis$suffix")] = row == rows ? PP.attr(anchor = "y$suffix", title = "time [s]") :
                PP.attr(anchor = "y$suffix", matches = "x$rows", showticklabels = false)
            axes[Symbol("yaxis$suffix")] = PP.attr(domain = domains[row], anchor = "x$suffix",
                title = PP.attr(text = titles[row], font = PP.attr(size = 13)))
        end
        PP.plot(identity.(traces), deck_layout(; axes...,
            legend = PP.attr(x = 0.98, xanchor = "right", y = 0.98, font = PP.attr(size = 13)),
            margin = PP.attr(l = 70, r = 20, t = 10, b = 50)))
    end

    etc = etc_run()
end

# ╔═╡ f2ac8c90-2eae-4b68-ab18-6bdf2f4acf9e
# ╠═╡ card = "etc-step"
etc_figure([(etc, "", "solid")])

# ╔═╡ ad434ab9-efbc-4951-8d25-27ce93df4d04
let
    step = findall(t -> 0.1 <= t <= 0.6, etc.t)
    t, y = etc.t[step], etc.meas[step]
    y0, y1 = etc.meas[1], 0.6PHI_SPAN_DEG
    t10 = t[findfirst(>=(y0 + 0.1(y1 - y0)), y)]
    t90 = t[findfirst(>=(y0 + 0.9(y1 - y0)), y)]
    overshoot = (maximum(y) - y1) / (y1 - y0)
    hold = etc.i[findlast(<=(0.6), etc.t)]
    @assert t90 - t10 < 0.1 "10–90 % rise $(t90 - t10) s slower than 100 ms"
    @assert overshoot < 0.05 "overshoot $(100overshoot) % above 5 %"
    @assert abs(etc.meas[end] - etc.cmd[end]) < 0.2 "steady error $(etc.meas[end] - etc.cmd[end])° above 0.2°"
    md"""
    **10–90 % rise** $(round(1e3(t90 - t10); digits = 0)) ms, **overshoot**
    $(round(100overshoot; digits = 1)) %, **peak current** $(round(maximum(etc.i); digits = 2)) A (the
    H-bridge saturates at 14 V over 1.5 Ω), **holding current** at 60 % $(round(hold; digits = 2)) A.
    The true plate angle ends $(round(etc.phi[end] - etc.meas[end]; digits = 2))° away from what the
    ECU measures: the error of the loaded TPS tracks, which the loop cannot see.
    """
end

# ╔═╡ 5babba76-5e0f-4bcb-b8ac-9c441ba106f8
md"""
The controller gain is the knob. A low gain is slow; a high one is fast until the H-bridge runs
out of voltage, and then only the current limit is left. The dashed curves follow the slider; the
bottom panel shows the two TPS tracks of the solid run, mirror images of each other.

position gain `k` [V per unit opening] $(@bind k_etc Slider([10.0, 20.0, 40.0, 80.0, 160.0]; default = 40.0, show_value = true))
"""

# ╔═╡ 54ebb35a-4b9d-4ba1-a707-fb10b17bcc99
etc_figure([(etc, "", "solid"), (etc_run(k = k_etc), ", k = $(k_etc)", "dash")]; tps = true)

# ╔═╡ 246f87e4-9e08-4535-a003-3820a4141a8b
md"""
## What comes later

With Dyad task 10 (`Vehicle.Engine.NTCSensor`, `HotFilmMAF`) this notebook adds the NTC's
divider voltage the ECU reads beside its curve, the sensitivity peak where `R` equals the
pull-up, the ECU's inverse lookup, and the hot-film meter: its inner loop, its step response
closed against open loop, and its output over the air path's tip-in from notebook 12.
"""

# ╔═╡ Cell order:
# ╠═2bc9e014-70e5-4fae-9f67-1863951789c4
# ╟─99fcbb1c-83a7-4529-a3ad-baf8c68be994
# ╠═c04b178f-8993-4690-8dff-a1274c185947
# ╟─90f13bf7-988b-4e9d-97d1-17de6b3136ff
# ╠═e3d8c8b0-98db-474b-a42e-449c4b1117e9
# ╠═81dcb403-100c-4c08-99a3-a5c65ddfb2ac
# ╟─9290f55c-9569-4d9b-b5d6-b02687bc1974
# ╠═32af266f-f964-411c-b979-88a2f4e3f396
# ╠═58a4f3f0-90d1-4267-87d2-51a2ce4b56be
# ╟─d4ae1cb4-49de-4221-8968-6b99d5321d49
# ╠═40d4fc61-4460-417e-8461-63dbe73c7623
# ╠═a2497ace-abe6-4fb3-8598-077672bcac31
# ╟─e56e8d7b-43ac-4abd-a34a-a592fd02bbd8
# ╠═971bbe80-cf23-46f5-81d8-399515962b55
# ╟─9e4e67b7-f6d7-45d3-bc35-e6b8a27ddfd1
# ╠═6a1efd3b-3357-4a1b-bacb-1443656d636d
# ╠═f2ac8c90-2eae-4b68-ab18-6bdf2f4acf9e
# ╠═ad434ab9-efbc-4951-8d25-27ce93df4d04
# ╟─5babba76-5e0f-4bcb-b8ac-9c441ba106f8
# ╠═54ebb35a-4b9d-4ba1-a707-fb10b17bcc99
# ╟─246f87e4-9e08-4535-a003-3820a4141a8b
