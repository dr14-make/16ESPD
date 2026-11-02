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

# ╔═╡ c3e90b92-ee53-4cec-9a9b-7ca3e79bfc21
begin
    import Pkg
    Pkg.activate(joinpath(@__DIR__, "..", ".."))
    include(joinpath(@__DIR__, "..", "lecture01", "support.jl"))
    using .Lecture01Support
    # The dyad-3.5 kernel ships Plots with the plotly backend and Kaleido, but not GR.
    VehicleSystemsComponents = setup(backend = :plotly)
    using ModelingToolkit, Plots
    using DyadInterface: symbolic_container
    using PlutoUI
end

# ╔═╡ b305a5e5-c273-4a58-ae71-75e37ea34a10
md"""
# Lecture 4 — The WLTC energy bill

The Leaf-class car of build steps 1–4 drives the WLTC class 3b cycle on the planar car: battery,
average converter and DC-equivalent machine, the 8.193 reduction and the differential to the
front wheels, and the 12 V auxiliaries on the DC link. Every link of the chain carries an energy
meter, so the bill below is read from the model, not inferred:

1. the car follows the cycle;
2. where the battery's energy went, link by link;
3. what braking gave back, against the same car braking on friction alone;
4. the same cycle in MJ/100 km against Lecture 2's engine car, phase by phase.

Every number below is read from a simulation of the Dyad models shown.
"""

# ╔═╡ a88fdb0a-1b29-4ac0-a7fc-13a1fb48c09e
show_dyad("ElectricDrive")

# ╔═╡ d437be24-68e8-4471-aa6e-92c37a0d9d8a
md"""
### Experiment

**12 V auxiliaries** `P_aux`: 300 W is a car on a test cycle with the climate control off; a
heater or the air conditioning takes kilowatts.
"""

# ╔═╡ a5bc76d8-c4e0-40a5-bea6-00163894eff8
@bind P_aux Slider(0.0:100.0:3000.0; default = 300.0, show_value = true)

# ╔═╡ edde5ee9-5758-48c1-85d2-ea3e5b03f05f
md"""
**Regeneration fade** `v_fade`: below this speed, in km/h, the machine's share of braking fades
to zero and the friction brakes take over $(@bind v_fade Select([5.0 => "5 km/h", 10.0 => "10 km/h", 20.0 => "20 km/h", 40.0 => "40 km/h"]; default = 10.0))
"""

# ╔═╡ 5e358178-01db-40b3-810c-d16a3fc1d7f0
begin
    PL = VehicleSystemsComponents.Vehicle.Planar

    # Lecture 2's engine car on the same cycle: 5.22 L/100 km (HandsOn02.MappedCarWLTC on
    # branch feat/handson02-wltc-bonus, docs/lecture-02-handson-step07-wltc-plan.md), petrol at
    # 0.745 kg/L and H_l = 43.4 MJ/kg.
    # Per-phase figures from the same reference run, in the same plan.
    engine = (; L_per_100km = 5.22, phases = [6.30, 5.14, 4.59, 5.41], rho = 0.745, H_l = 43.4)
    engine_MJ = engine.L_per_100km * engine.rho * engine.H_l

    "WLTC class 3b phases: name, start and end [s]."
    PHASES = [("Low", 0.0, 589.0), ("Medium", 589.0, 1022.0), ("High", 1022.0, 1477.0),
        ("Extra High", 1477.0, 1800.0)]

    "Run the BEV over WLTC and read every meter at the end, in kWh, with the distance in km."
    function energy_bill(; kwargs...)
        r = PL.PlanarBEVWLTCTransient(; kwargs...)
        m = symbolic_container(r)
        s = r.sol
        kWh(x) = s[x][end] / 3.6e6
        E = (; cells = kWh(m.E_cells), dc = kWh(m.E_dc), dc_out = kWh(m.E_dc_out),
            dc_in = kWh(m.E_dc_in), R0 = kWh(m.E_R0), aux = kWh(m.E_aux), conv = kWh(m.E_conv),
            motor = kWh(m.E_motor), shaft_out = kWh(m.E_shaft_out),
            shaft_in = kWh(m.E_shaft_in), road = kWh(m.E_road), brake = kWh(m.E_brake),
            tire = kWh(m.E_tire), dkin = (s[m.E_kin][end] - s[m.E_kin][1]) / 3.6e6)
        phases = map(PHASES) do (name, a, b)
            dkm = (s(b, idxs = m.car.bus.x) - s(a, idxs = m.car.bus.x)) / 1000
            (; name, km = dkm, dc = (s(b, idxs = m.E_dc) - s(a, idxs = m.E_dc)) / 3.6e6)
        end
        return (; r, m, s, E, phases, km = s[m.car.bus.x][end] / 1000)
    end
end

# ╔═╡ 6c67b803-dd3d-4e05-a042-7ec804e28ca2
bev = energy_bill(; P_aux, v_fade);

# ╔═╡ 30c2d17e-2e7e-4b68-a978-af808a48fb82
md"""
## 1. The car follows the cycle

The driver is a PI controller on the speed error, and its output is a machine torque. Driving,
the machine gives it. Braking, the machine turns generator and charges the battery; below
`v_fade` its share fades out and the front friction brakes take the rest, so the car stops
without rolling back and is held at every stop. WLTC never brakes harder than 1.5 m/s², which
the machine covers alone, so above the fade all braking is regenerative. The split is one block,
`TorqueSplit`, between the driver and the drive:
"""

# ╔═╡ 2e0845a0-20c1-415f-ae34-f481c14a5ae9
show_dyad("TorqueSplit")

# ╔═╡ 79ece26f-0274-4945-a761-8ecf4f9e1550
tracking_plot = let
    (; s, m) = bev
    ts = 0:0.5:1800
    v = 3.6 .* s(ts, idxs = m.car.bus.vx).u
    ref = s(ts, idxs = m.trace.y).u
    P = s(ts, idxs = m.P_dc).u ./ 1e3
    p = plot(layout = (2, 1), size = (960, 560), link = :x)
    plot!(p[1], ts, ref; label = "WLTC trace", color = :gray, lw = 2.5, ylabel = "speed [km/h]",
        legend = :topleft)
    plot!(p[1], ts, v; label = "car", color = 1, lw = 1.2)
    plot!(p[2], ts, P; label = "", color = 2, lw = 1, ylabel = "battery power [kW]",
        xlabel = "time [s]")
    hline!(p[2], [0.0]; color = :black, lw = 0.5, label = "")
    p
end

# ╔═╡ 8bf2b979-4cd2-4c05-b68b-d5b78c36ed0a
let
    (; s, m, km) = bev
    v = 3.6 .* s[m.car.bus.vx]
    md"""
    Distance **$(round(km; digits = 3)) km** against the trace's 23.266 km; worst speed error
    **$(round(maximum(abs, v .- s[m.trace.y]); digits = 2)) km/h**; battery power from
    **$(round(minimum(s[m.P_dc]) / 1e3; digits = 1)) kW** (charging) to
    **$(round(maximum(s[m.P_dc]) / 1e3; digits = 1)) kW**, against the pack's 110 kW.
    """
end

# ╔═╡ 4bb1606d-d10a-44d8-8746-781f74ab6be5
md"""
## 2. Where the energy went

Each bar is one link's loss over the cycle, per kilometer. Together they are what left the
cells: drag and rolling resistance at the road, the friction brakes and tire slip at the wheels,
the machine, the converter, the battery's own resistance and the auxiliaries. The reduction and
the differential are ideal and cost nothing. The balance is not forced: every link has its own
meter, and the sum closes on the battery to the solver's tolerance.
"""

# ╔═╡ 934dce9c-050e-4c30-8d4f-898c16e1666d
bill_plot = let
    (; E, km) = bev
    names = ["road load", "machine", "auxiliaries", "battery R₀", "converter", "tire slip",
        "friction brakes"]
    vals = [E.road, E.motor, E.aux, E.R0, E.conv, E.tire, E.brake] ./ km .* 1000
    p = bar(1:length(vals), vals; xticks = (1:length(vals), names), color = 1, label = "",
        ylabel = "energy over WLTC [Wh/km]", size = (960, 420),
        title = "out of the cells: $(round(E.cells / km * 1000; digits = 1)) Wh/km")
    annotate!(p, [(k, v + 2, text("$(round(v; digits = 1))", 10, :bottom))
                  for (k, v) in enumerate(vals)])
    ylims!(p, 0, 1.15 * maximum(vals))
    p
end

# ╔═╡ 67be1b5f-5ab6-4c1a-af7c-1fcdd5430268
let
    (; E, km) = bev
    Whkm(x) = round(x / km * 1000; digits = 1)
    pct(x, y) = round(100 * x / y; digits = 0)
    links = E.road + E.brake + E.tire + E.motor + E.conv + E.R0 + E.aux + E.dkin
    md"""
    | | Wh/km | kWh/100 km |
    |:---|---:|---:|
    | out of the cells | $(Whkm(E.cells)) | $(round(E.cells / km * 100; digits = 2)) |
    | **at the battery terminals (DC consumption)** | **$(Whkm(E.dc))** | **$(round(E.dc / km * 100; digits = 2))** |
    | discharged at the terminals | $(Whkm(E.dc_out)) | |
    | charged back by braking | $(Whkm(E.dc_in)) | |
    | traction at the reduction output | $(Whkm(E.shaft_out)) | |
    | braking taken back at the reduction output | $(Whkm(E.shaft_in)) | |

    Braking returned **$(pct(E.shaft_in, E.shaft_out)) %** of the traction energy to the shaft,
    and **$(pct(E.dc_in, E.shaft_in)) %** of that reached the battery: the battery got back
    **$(pct(E.dc_in, E.shaft_out)) %** of the traction energy, against the plan's 18–25 %,
    derived from Boretti's UDDS efficiencies and an ideal reduction. The links sum to the cells' energy within
    **$(round(abs(links - E.cells) / E.cells; sigdigits = 2))** of it. The plan's band for the
    DC consumption is 120–155 Wh/km.
    """
end

# ╔═╡ 625ff731-e4e1-4c83-a1c9-5642bb74ee0a
md"""
## 3. What braking gave back

The same car on the same cycle, braking on its friction brakes alone: `v_fade` set far above
any speed the car reaches, so the machine's braking share is zero everywhere.
"""

# ╔═╡ ee5f32f6-71ad-4014-9e8f-f46e65f6a8b6
friction_only = energy_bill(; P_aux, v_fade = 1e9);

# ╔═╡ 5fd48332-231f-4cda-952f-3af75b41434d
let
    b, f = bev.E, friction_only.E
    km, kmf = bev.km, friction_only.km
    Whkm(x, d) = round(x / d * 1000; digits = 1)
    saved = round(Int, 100 * (1 - (b.dc / km) / (f.dc / kmf)))
    Markdown.parse("""
    | Wh/km | regenerating | friction brakes only |
    |:---|---:|---:|
    | traction at the reduction output | $(Whkm(b.shaft_out, km)) | $(Whkm(f.shaft_out, kmf)) |
    | braking taken back at the reduction output | $(Whkm(b.shaft_in, km)) | $(Whkm(f.shaft_in, kmf)) |
    | charged back at the battery terminals | $(Whkm(b.dc_in, km)) | $(Whkm(f.dc_in, kmf)) |
    | burned in the friction brakes | $(Whkm(b.brake, km)) | $(Whkm(f.brake, kmf)) |
    | **at the battery terminals, net** | **$(Whkm(b.dc, km))** | **$(Whkm(f.dc, kmf))** |

    Without regeneration the car would take $(Whkm(f.dc, kmf)) Wh/km, outside the plan's
    120–155 band: regeneration saves **$(saved) %**.
    The friction brakes then burn all of the braking energy, more than the battery gets back with
    regeneration: the machine, converter and pack lose a few percent of it on the way back. With
    regeneration the friction brakes burn only what the fade below `v_fade` leaves them, where
    the car has almost no kinetic energy left.
    """)
end

# ╔═╡ d9bf6b12-bd5f-40fc-aba6-f509ebef4af0
regen_plot = let
    vals = [bev.E.dc / bev.km * 1000, friction_only.E.dc / friction_only.km * 1000]
    p = bar(1:2, vals; xticks = (1:2, ["regenerating", "friction brakes only"]),
        color = [1, 2], label = "", bar_width = 0.5, size = (960, 420),
        ylabel = "at the battery terminals [Wh/km]")
    plot!(p, Shape([0.5, 2.5, 2.5, 0.5], [120, 120, 155, 155]); color = :gray,
        fillalpha = 0.15, linealpha = 0, label = "plan's band, 120–155 Wh/km")
    annotate!(p, [(k, v + 3, text("$(round(v; digits = 1))", 10, :bottom))
                  for (k, v) in enumerate(vals)])
    ylims!(p, 0, 1.2 * maximum(vals))
    p
end

# ╔═╡ de7086b7-0f27-49da-bb95-442cf9c86f0c
md"""
## 4. Against the engine car

The same cycle in MJ/100 km. The engine car is Lecture 2's: its reference run burns
5.22 L/100 km of petrol, and petrol carries 0.745 kg/L × 43.4 MJ/kg. The electric car's bar is
the energy at its battery terminals; at the wall, a 10–15 % charging loss comes on top.

The comparison is the course's own, not a label: Lecture 2's car weighs 1400 kg, this one
1500 kg, and neither carries a heater or air conditioning. Most of the difference is the
engine's efficiency, about 30 % at its best, against a chain that loses a few percent per link
and gets braking energy back.
"""

# ╔═╡ 6d8fa9f3-d715-459a-b96c-a71f5c19e9b0
mj_plot = let
    (; E, km) = bev
    bev_MJ = E.dc * 3.6 / km * 100
    wall_MJ = bev_MJ / 0.87
    names = ["engine car, fuel", "BEV, at the wall (−13 % charging)", "BEV, at the battery"]
    vals = [engine_MJ, wall_MJ, bev_MJ]
    p = bar(1:3, vals; xticks = (1:3, names), color = [3, :lightgray, 1], label = "",
        ylabel = "energy over WLTC [MJ/100 km]", size = (960, 420))
    annotate!(p, [(k, v + 3, text("$(round(v; digits = 1))", 10, :bottom))
                  for (k, v) in enumerate(vals)])
    ylims!(p, 0, 1.15 * maximum(vals))
    p
end

# ╔═╡ 97a2ec88-3835-4c19-a464-92d68c1542cb
let
    r1(x) = round(x; digits = 1)
    MJ(L) = L * engine.rho * engine.H_l
    MJ_bev(p) = p.dc * 3.6 / p.km * 100
    rows = join(["| $(p.name) | $(r1(MJ(L))) | $(r1(MJ_bev(p))) | $(r1(MJ(L) / MJ_bev(p))) |"
                 for (p, L) in zip(bev.phases, engine.phases)], "\n")
    Markdown.parse("""
    By phase, each car at its own mass, in MJ/100 km:

    | phase | engine car, fuel | BEV, at the battery | ratio |
    |:---|---:|---:|---:|
    $rows

    The gap is widest in town. There the engine runs far below its best efficiency and every stop
    turns the car's kinetic energy into heat; the electric chain loses little at part load and
    gives most of that kinetic energy back. On the motorway drag dominates both bills, and the
    ratio narrows.
    """)
end
# ╔═╡ 48163d2d-0340-48a4-8d7e-4830bfb92543
md"""
## 5. In the cold

The bill above carries 300 W of auxiliaries: a car on a test cycle with the climate control off.
In winter the cabin heater joins them. The same car on the same cycle with `P_aux` raised to a
measured heater power, everything else unchanged:

- **2 kW**, a warm cabin at about −7 °C to −10 °C: ADAC measured 1.5–2 kW to hold +20 °C at
  −10 °C (seven cars, 2022), and AAA's 2018 Leaf at −7 °C used 1.6–2.8 kW more with the heater
  on (derived from AAA 2019, at the battery);
- **5 kW**, a resistive (PTC) heater warming a cold cabin: Argonne measured 2.5–5.2 kW in a
  2011/12 Leaf on a city cycle at −7 °C (ANL 2012).

Only the heater changes here. A cold pack's higher resistance, denser air and stiffer tires
cost more again; none of them is in the model.
"""

# ╔═╡ f0e913e8-bb65-418c-beab-9f050b70dc84
COLD_LOADS = [("test cycle, climate off", 300.0), ("warm cabin, about −7 °C", 2000.0),
    ("resistive heater warming up", 5000.0)];

# ╔═╡ d74a167a-f59e-49c2-8f70-865eac9ae86b
cold = [(; name, P, b = energy_bill(; P_aux = P, v_fade)) for (name, P) in COLD_LOADS];

# ╔═╡ 49a07b58-ec4c-4e7c-bdb4-1ee50e41e835
cold_plot = let
    Whkm = [c.b.E.dc / c.b.km * 1000 for c in cold]
    names = ["$(round(Int, c.P)) W: $(c.name)" for c in cold]
    p = bar(1:length(cold), Whkm; xticks = (1:length(cold), names),
        color = [1, :darkorange, :firebrick], label = "", bar_width = 0.55, size = (960, 420),
        ylabel = "at the battery terminals [Wh/km]",
        title = "WLTC with the auxiliaries at a cabin heater's power")
    annotate!(p, [(k, v + 4, text("$(round(v; digits = 1)) Wh/km", 10, :bottom))
                  for (k, v) in enumerate(Whkm)])
    ylims!(p, 0, 1.2 * maximum(Whkm))
    p
end

# ╔═╡ f1e07c11-00d4-49e0-9f08-6128d9a30f60
let
    r1(x) = round(x; digits = 1)
    base = cold[1].b.E.dc / cold[1].b.km * 1000
    rows = map(cold) do c
        w = c.b.E.dc / c.b.km * 1000
        aux = c.b.E.aux / c.b.km * 1000
        "| $(c.name) | $(round(Int, c.P)) | $(r1(aux)) | $(r1(w)) | +$(round(Int, 100 * (w / base - 1))) | $(round(Int, 40e3 / w)) |"
    end
    Markdown.parse("""
    | auxiliaries | P_aux [W] | auxiliaries [Wh/km] | at the terminals [Wh/km] | vs 300 W [%] | range on 40 kWh [km] |
    |:---|---:|---:|---:|---:|---:|
    $(join(rows, "\n"))

    A heater's power is per hour, not per kilometer: over the WLTC's 23.3 km in 30 minutes,
    every kilowatt adds about 21 Wh/km. The range column is the pack's 40 kWh over the bill,
    my arithmetic, with no reserve: it compares the rows, it is not a range forecast. AAA's
    five cars at −7 °C lost 41 % of their range with the heater on.
    """)
end


# ╔═╡ Cell order:
# ╟─b305a5e5-c273-4a58-ae71-75e37ea34a10
# ╠═c3e90b92-ee53-4cec-9a9b-7ca3e79bfc21
# ╟─a88fdb0a-1b29-4ac0-a7fc-13a1fb48c09e
# ╟─d437be24-68e8-4471-aa6e-92c37a0d9d8a
# ╟─a5bc76d8-c4e0-40a5-bea6-00163894eff8
# ╟─edde5ee9-5758-48c1-85d2-ea3e5b03f05f
# ╠═5e358178-01db-40b3-810c-d16a3fc1d7f0
# ╠═6c67b803-dd3d-4e05-a042-7ec804e28ca2
# ╟─30c2d17e-2e7e-4b68-a978-af808a48fb82
# ╟─2e0845a0-20c1-415f-ae34-f481c14a5ae9
# ╟─79ece26f-0274-4945-a761-8ecf4f9e1550
# ╟─8bf2b979-4cd2-4c05-b68b-d5b78c36ed0a
# ╟─4bb1606d-d10a-44d8-8746-781f74ab6be5
# ╟─934dce9c-050e-4c30-8d4f-898c16e1666d
# ╟─67be1b5f-5ab6-4c1a-af7c-1fcdd5430268
# ╟─625ff731-e4e1-4c83-a1c9-5642bb74ee0a
# ╠═ee5f32f6-71ad-4014-9e8f-f46e65f6a8b6
# ╟─5fd48332-231f-4cda-952f-3af75b41434d
# ╟─d9bf6b12-bd5f-40fc-aba6-f509ebef4af0
# ╟─de7086b7-0f27-49da-bb95-442cf9c86f0c
# ╟─6d8fa9f3-d715-459a-b96c-a71f5c19e9b0
# ╟─97a2ec88-3835-4c19-a464-92d68c1542cb
# ╟─48163d2d-0340-48a4-8d7e-4830bfb92543
# ╠═f0e913e8-bb65-418c-beab-9f050b70dc84
# ╟─d74a167a-f59e-49c2-8f70-865eac9ae86b
# ╟─49a07b58-ec4c-4e7c-bdb4-1ee50e41e835
# ╟─f1e07c11-00d4-49e0-9f08-6128d9a30f60
