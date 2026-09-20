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

# ╔═╡ a1000000-0000-4000-8000-0000000000b2
using PlutoPlotly

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

# ╔═╡ a1000000-0000-4000-8000-0000000000b1
script_probe = HTML("""
<div class="probe">inert</div>
<script>
  const el = currentScript.parentElement.querySelector(".probe");
  el.textContent = "SCRIPT EXECUTED";
  el.dataset.ran = "yes";
</script>
""")

# ╔═╡ a1000000-0000-4000-8000-0000000000b4
plotly_offline = enable_plutoplotly_offline()

# ╔═╡ 5927cc14-0a9e-4f8a-b136-023484d00017
@bind freq html"<input type=range min=0.2 max=5 step=0.1 value=1>"

# ╔═╡ a1000000-0000-4000-8000-0000000000b3
plotly_demo = let f = ismissing(freq) ? 1.0 : float(freq), t = 0:0.02:10
    plot(
        scatter(x = t, y = sin.(f .* t), mode = "lines"),
        Layout(title = "sin($(round(f, digits = 1)) · t)",
               yaxis = attr(range = [-1.1, 1.1]),
               margin = attr(l = 40, r = 10, t = 40, b = 30)),
    )
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
AbstractPlutoDingetjes = "6e696c72-6542-2067-7265-42206c756150"
Markdown = "d6f4376e-aef5-505a-96c1-9c027394607a"
PlutoPlotly = "8e989ff0-3d88-8e9f-f020-2b208a939ff0"

[compat]
PlutoPlotly = "~0.6.6"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.12.7-dyad"
manifest_format = "2.0"
project_hash = "094ed33ef5823319d450f0c187d184eb4d58706a"

[[deps.AbstractPlutoDingetjes]]
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.4.0"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "PrecompileTools", "Random"]
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.31.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.12.1"
weakdeps = ["StyledStrings"]

    [deps.ColorTypes.extensions]
    StyledStringsExt = "StyledStrings"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "Requires", "Statistics", "TensorCore"]
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.11.0"

    [deps.ColorVectorSpace.extensions]
    SpecialFunctionsExt = "SpecialFunctions"

    [deps.ColorVectorSpace.weakdeps]
    SpecialFunctions = "276daf66-3868-5448-9aa4-cd146d93841b"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.13.1"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.3.0+1"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
git-tree-sha1 = "9e2f36d3c96a820c678f2f1f1782582fcf685bae"
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"
version = "1.9.1"

[[deps.DocStringExtensions]]
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.5"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.7.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.FixedPointNumbers]]
deps = ["Random", "Statistics"]
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.6"

[[deps.HashArrayMappedTries]]
uuid = "076d061b-32b6-4027-95e0-9a2c6f6d7e74"
version = "0.2.0"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "d1a86724f81bcd184a38fd284ce183ec067d71a0"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "1.0.0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JuliaSyntaxHighlighting]]
deps = ["StyledStrings"]
uuid = "ac6e5ff7-fb65-4e79-a425-ec3bc9c03011"
version = "1.12.0"

[[deps.LaTeXStrings]]
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.4.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "OpenSSL_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.15.0+0"

[[deps.LibGit2]]
deps = ["LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"
version = "1.11.0"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "OpenSSL_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.9.0+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "OpenSSL_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.3+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.12.0"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.Markdown]]
deps = ["Base64", "JuliaSyntaxHighlighting", "StyledStrings"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"
version = "1.11.0"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2025.11.4"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.3.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.29+0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.5.6+0"

[[deps.OrderedCollections]]
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.2"

[[deps.Parameters]]
deps = ["OrderedCollections", "UnPack"]
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.6"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.12.1"
weakdeps = ["REPL"]

    [deps.Pkg.extensions]
    REPLExt = "REPL"

[[deps.PlotlyBase]]
deps = ["ColorSchemes", "Colors", "Dates", "DelimitedFiles", "DocStringExtensions", "JSON", "LaTeXStrings", "Logging", "Parameters", "Pkg", "REPL", "Requires", "Statistics", "UUIDs"]
uuid = "a03496cd-edff-5a9b-9e67-9cda94a718b5"
version = "0.8.23"

    [deps.PlotlyBase.extensions]
    DataFramesExt = "DataFrames"
    DistributionsExt = "Distributions"
    IJuliaExt = "IJulia"
    JSON3Ext = "JSON3"

    [deps.PlotlyBase.weakdeps]
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    Distributions = "31c24e10-a181-5473-b8eb-7969acd0382f"
    IJulia = "7073ff75-c697-5162-941a-fcdaad2a7d2a"
    JSON3 = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"

[[deps.PlutoPlotly]]
deps = ["AbstractPlutoDingetjes", "Artifacts", "ColorSchemes", "Colors", "Dates", "Downloads", "HypertextLiteral", "InteractiveUtils", "LaTeXStrings", "Markdown", "Pkg", "PlotlyBase", "PrecompileTools", "Reexport", "ScopedValues", "Scratch", "TOML"]
git-tree-sha1 = "2b9e3d771adfe535a4fdda855f4741fdaacd3f7f"
uuid = "8e989ff0-3d88-8e9f-f020-2b208a939ff0"
version = "0.6.6"

    [deps.PlutoPlotly.extensions]
    PlotlyKaleidoExt = "PlotlyKaleido"
    UnitfulExt = "Unitful"

    [deps.PlutoPlotly.weakdeps]
    PlotlyKaleido = "f2990250-8cf9-495f-b13a-cce12b45703c"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.PrecompileTools]]
deps = ["Preferences"]
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.3.4"

[[deps.Preferences]]
deps = ["TOML"]
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.5.2"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.REPL]]
deps = ["InteractiveUtils", "JuliaSyntaxHighlighting", "Markdown", "Sockets", "StyledStrings", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.Reexport]]
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.1"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.ScopedValues]]
deps = ["HashArrayMappedTries", "Logging"]
uuid = "7e506255-f358-4e82-b7e4-beb19740aa63"
version = "1.6.2"

[[deps.Scratch]]
deps = ["Dates"]
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.3.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"
version = "1.11.0"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

    [deps.Statistics.weakdeps]
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.StyledStrings]]
uuid = "f489334b-da3d-4c2e-b8f0-e476e12c162b"
version = "1.11.0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Tricks]]
git-tree-sha1 = "311349fd1c93a31f783f977a71e8b062a57d4101"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.13"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.UnPack]]
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.3.1+2"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.15.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.64.0+1"

[[deps.p7zip_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.7.0+0"
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
# ╠═a1000000-0000-4000-8000-0000000000b1
# ╠═a1000000-0000-4000-8000-0000000000b2
# ╠═a1000000-0000-4000-8000-0000000000b4
# ╠═5927cc14-0a9e-4f8a-b136-023484d00017
# ╠═a1000000-0000-4000-8000-0000000000b3
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
