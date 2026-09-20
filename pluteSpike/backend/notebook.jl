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

# ╔═╡ a1000000-0000-4000-8000-000000000001
begin
    using Markdown

    # docs/HANDOVER.md, L0 vehicle parameter set — same numbers as notebooks/lecture01/support.jl
    CAR = (
        m = 1400.0, CdA = 0.63, rho = 1.2, f_r = 0.012, r = 0.31,
        i = 4.0, T_max = 150.0, tau_e = 0.3, theta_e = 0.04, g = 9.80665,
    )

    c_drag = 0.5 * CAR.rho * CAR.CdA
    F_roll = CAR.f_r * CAR.m * CAR.g

    "Forward-Euler run of the longitudinal car under a PID cruise controller in km/h."
    function simulate(; v0_kmh = 90.0, v_ref_kmh = 110.0, Kp = 2.0, Ki = 0.1, Kd = 0.0,
                        grade_pct = 0.0, antiwindup = true, t_end = 200.0, dt = 0.02)
        n = round(Int, t_end / dt) + 1
        alpha = atan(grade_pct / 100)
        nd = max(1, round(Int, CAR.theta_e / dt))
        buf = zeros(nd)
        bi = 1

        v = v0_kmh / 3.6
        Te = 0.0
        I = 0.0
        e_prev = v_ref_kmh - v0_kmh

        t = Vector{Float64}(undef, n)
        vk = Vector{Float64}(undef, n)
        Tc = Vector{Float64}(undef, n)
        Td = Vector{Float64}(undef, n)

        for k in 1:n
            v_kmh = 3.6v
            e = v_ref_kmh - v_kmh
            de = (e - e_prev) / dt
            I += e * dt
            u = Kp * e + Ki * I + Kd * de
            u_sat = clamp(u, 0.0, CAR.T_max)
            if antiwindup && u != u_sat
                I -= e * dt          # stop integrating into the stop
            end
            e_prev = e

            t[k] = (k - 1) * dt
            vk[k] = v_kmh
            Tc[k] = u_sat
            Td[k] = Te

            u_del = buf[bi]; buf[bi] = u_sat; bi = bi % nd + 1
            Te += dt * (u_del - Te) / CAR.tau_e

            F = Te * CAR.i / CAR.r - c_drag * v^2 - F_roll * cos(alpha) - CAR.m * CAR.g * sin(alpha)
            v = max(v + dt * F / CAR.m, 0.0)
        end
        (; t, v_kmh = vk, T_cmd = Tc, T_del = Td, v_ref = v_ref_kmh)
    end

    "Downsampled series as a JSON string — `worker.execute` only carries simple types."
    function series_json(s, npts = 400)
        ismissing(s) && return "null"
        n = length(s.t)
        idx = 1:max(1, cld(n, npts)):n
        col(v, d) = join((string(round(v[i], digits = d)) for i in idx), ",")
        string("{\"t\":[", col(s.t, 3),
               "],\"v\":[", col(s.v_kmh, 3),
               "],\"Tc\":[", col(s.T_cmd, 3),
               "],\"Td\":[", col(s.T_del, 3),
               "],\"vref\":", round(s.v_ref, digits = 3), "}")
    end
end

# ╔═╡ 00000000-0000-0208-1991-000000000000
# ╠═╡ code_folded = true
begin
    using AbstractPlutoDingetjes
	function eval_in_pluto(x::String)
		id = PlutoRunner.moduleworkspace_count[]
		new_workspace_name = Symbol("workspace#", id)
		Core.eval(getproperty(Main, new_workspace_name), Meta.parse(x))
	end
	AbstractPlutoDingetjes.Display.with_js_link(eval_in_pluto)
end

# ╔═╡ a1000000-0000-4000-8000-000000000000
md"""
# Cruise control — live spike

Driven from the slide deck over `@plutojl/rainbow`. The five `@bind` cells below are the
inputs the deck writes; `sim` and `metrics` are the outputs it reads.
"""

# ╔═╡ a1000000-0000-4000-8000-000000000002
@bind v_ref_kmh html"<input type=range min=60 max=160 step=1 value=110>"

# ╔═╡ a1000000-0000-4000-8000-000000000003
@bind Kp html"<input type=range min=0 max=20 step=0.1 value=2>"

# ╔═╡ a1000000-0000-4000-8000-000000000004
@bind Ki html"<input type=range min=0 max=2 step=0.01 value=0.1>"

# ╔═╡ a1000000-0000-4000-8000-000000000005
@bind Kd html"<input type=range min=0 max=20 step=0.1 value=0>"

# ╔═╡ a1000000-0000-4000-8000-000000000006
@bind grade_pct html"<input type=range min=-8 max=12 step=0.5 value=0>"

# ╔═╡ a1000000-0000-4000-8000-000000000007
@bind antiwindup html"<input type=checkbox checked>"

# ╔═╡ a1000000-0000-4000-8000-000000000008
sim = if any(ismissing, (v_ref_kmh, Kp, Ki, Kd, grade_pct, antiwindup))
    missing
else
    simulate(; v_ref_kmh = float(v_ref_kmh), Kp = float(Kp), Ki = float(Ki),
               Kd = float(Kd), grade_pct = float(grade_pct), antiwindup = Bool(antiwindup))
end

# ╔═╡ a1000000-0000-4000-8000-00000000000a
series_out = Text(ismissing(sim) ? "null" : series_json(sim, 400))

# ╔═╡ a1000000-0000-4000-8000-000000000009
metrics = if ismissing(sim)
    HTML("<em>waiting for the deck to send inputs…</em>")
else
    v = sim.v_kmh
    r = sim.v_ref
    tail = v[max(1, end - 500):end]
    sse = r - sum(tail) / length(tail)
    peak = maximum(v)
    over = r > v[1] ? max(0.0, (peak - r) / (r - v[1])) * 100 : 0.0
    band = 0.02 * abs(r - v[1])
    settle_i = findlast(i -> abs(v[i] - r) > max(band, 0.1), eachindex(v))
    settle = settle_i === nothing ? 0.0 : sim.t[min(settle_i + 1, length(sim.t))]
    satfrac = count(x -> x >= CAR.T_max - 1e-9, sim.T_cmd) / length(sim.T_cmd) * 100
    row(k, val, u) = string("<tr><th>", k, "</th><td>", val, "</td><td>", u, "</td></tr>")
    HTML(string("<table class=\"metrics\">",
        row("steady-state error", round(sse, digits = 2), "km/h"),
        row("overshoot", round(over, digits = 1), "%"),
        row("settling time (2%)", round(settle, digits = 1), "s"),
        row("peak speed", round(peak, digits = 1), "km/h"),
        row("torque saturated", round(satfrac, digits = 1), "% of run"),
        "</table>"))
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
AbstractPlutoDingetjes = "6e696c72-6542-2067-7265-42206c756150"
Markdown = "d6f4376e-aef5-505a-96c1-9c027394607a"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.12.7-dyad"
manifest_format = "2.0"
project_hash = "0f4cb9553f2010da541b45d69c49bde082209354"

[[deps.AbstractPlutoDingetjes]]
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.4.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.JuliaSyntaxHighlighting]]
deps = ["StyledStrings"]
uuid = "ac6e5ff7-fb65-4e79-a425-ec3bc9c03011"
version = "1.12.0"

[[deps.Markdown]]
deps = ["Base64", "JuliaSyntaxHighlighting", "StyledStrings"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.StyledStrings]]
uuid = "f489334b-da3d-4c2e-b8f0-e476e12c162b"
version = "1.11.0"
"""

# ╔═╡ Cell order:
# ╟─a1000000-0000-4000-8000-000000000000
# ╟─a1000000-0000-4000-8000-000000000001
# ╠═a1000000-0000-4000-8000-000000000002
# ╠═a1000000-0000-4000-8000-000000000003
# ╠═a1000000-0000-4000-8000-000000000004
# ╠═a1000000-0000-4000-8000-000000000005
# ╠═a1000000-0000-4000-8000-000000000006
# ╠═a1000000-0000-4000-8000-000000000007
# ╠═a1000000-0000-4000-8000-000000000008
# ╠═00000000-0000-0208-1991-000000000000
# ╟─a1000000-0000-4000-8000-00000000000a
# ╠═a1000000-0000-4000-8000-000000000009
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
