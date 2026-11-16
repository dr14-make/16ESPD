### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# Outside Pluto, use each widget's default value.
macro bind(def, element)
    return quote
        local iv = try
            Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value
        catch
            b -> missing
        end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 2564b1f9-f4ef-48b9-aafe-a0dfca4eaa01
begin
    cost_per_100km(consumption, price) = consumption * price

    function yearly_saving(; km_per_year, home_share, home_price, dc_price,
            ev_consumption, petrol_price, petrol_consumption, ev_service,
            petrol_service, other_difference)
        ev_bill = cost_per_100km(ev_consumption,
            home_share * home_price + (1 - home_share) * dc_price)
        petrol_bill = cost_per_100km(petrol_consumption, petrol_price)
        return km_per_year / 100 * (petrol_bill - ev_bill) +
            petrol_service - ev_service - other_difference
    end

    function breakeven_year(price_gap, saving; years = Inf)
        saving <= 0 && return nothing
        crossing = max(0.0, price_gap / saving)
        return crossing <= years ? crossing : nothing
    end
end

# ╔═╡ 2564b1f9-f4ef-48b9-aafe-a0dfca4eaa02
begin
    import Pkg
    Pkg.activate(joinpath(@__DIR__, "..", ".."))
    using Plots, PlutoUI
    plotly()
end

# ╔═╡ 2564b1f9-f4ef-48b9-aafe-a0dfca4eaa03
begin
    const LEAF_SOCKET_KWH = 17.1 # Course Leaf WLTP input, charging losses included.
    const HOME_CZK_KWH = 7.0108 # EUROSTAT-NRG-PC-204-2026S1
    const HOME_LOW_CZK_KWH = 3.514 # CEZ-D27D-2026
    const DC_LOW_CZK_KWH = 13.00 # PRE-JEDNORAZOVE
    const DC_HIGH_CZK_KWH = 16.90 # CEZ-FUTUREGO-2026-11
    const DC_MID_CZK_KWH = (DC_LOW_CZK_KWH + DC_HIGH_CZK_KWH) / 2
    const PETROL_CZK_L = 42.98 # CSU-CENPHMT-2026-W45
    const PETROL_L_100KM = 5.22 # Course Lecture 2 engine, WLTC.
    const ASSUMED_PRICE_GAP = 200_000
    const ASSUMED_KM_YEAR = 20_000
    const ASSUMED_HOME_SHARE = 0.8
    const ASSUMED_EV_SERVICE = 5_000
    const ASSUMED_PETROL_SERVICE = 10_000
    const ASSUMED_OTHER_DIFFERENCE = 0
    const DEFAULT_YEARS = 15
end

# ╔═╡ 2564b1f9-f4ef-48b9-aafe-a0dfca4eaa04
md"""
# Your own bill, and when it pays back

Extra session · November 16, 2026 · Exercise 4

Replace the numbers with your family's next car and charging plan. All money is in CZK.
The purchase gap, distance, charging share, servicing, and other yearly difference are
**assumed, set your own**. They are not measured course results.

### Energy defaults: prices checked November 12, 2026

| Input | Default | Source and date |
|:--|--:|:--|
| Leaf, at the socket | 17.1 kWh/100 km | Course WLTP input, includes charging losses |
| Home electricity | 7.0108 CZK/kWh | [EUROSTAT-NRG-PC-204-2026S1](https://ec.europa.eu/eurostat/databrowser/view/nrg_pc_204/default/table), Czech household average, first half of 2026, all taxes |
| Public DC | 14.95 CZK/kWh | Midpoint of [PRE-JEDNORAZOVE](https://www.pre.cz/cs/domacnosti/emobilita/verejne-dobijeni/chci-dobijet-jednorazove/) (13.00, undated) and [CEZ-FUTUREGO-2026-11](https://www.futurego.cz/cenik) (16.90, valid November 3, 2026); ad hoc, ≤149 kW |
| Petrol | 42.98 CZK/L | [CSU-CENPHMT-2026-W45](https://data.csu.gov.cz/datastat/info/SADA/CENPHMT), Natural 95, week 45, November 2–8, 2026 |
| Petrol consumption | 5.22 L/100 km | Course Lecture 2 engine, WLTC |

D27d low tariff is **3.514 CZK/kWh**, [CEZ-D27D-2026](https://www.cez.cz/webpublic/file/edee/ceniky/moo_ele_cez_online_na_1_rok_30012026_012026.pdf),
ČEZ distribution area, 2026 price list; monthly charges excluded. Try it as your home price.
The same socket consumption is used for DC without a charging-loss correction, as in the deck.
"""

# ╔═╡ 2564b1f9-f4ef-48b9-aafe-a0dfca4eaa05
md"""
## Your inputs

**Assumed, set your own:**

EV purchase price minus combustion car price (CZK): $(@bind price_gap NumberField(-500_000:5_000:1_000_000; default = ASSUMED_PRICE_GAP))

Distance (km/year): $(@bind km_per_year NumberField(0:1_000:100_000; default = ASSUMED_KM_YEAR))

Home charging share (0–1; rest is public DC): $(@bind home_share Slider(0:0.05:1; default = ASSUMED_HOME_SHARE, show_value = true))

EV servicing (CZK/year): $(@bind ev_service NumberField(0:500:100_000; default = ASSUMED_EV_SERVICE))

Combustion car servicing (CZK/year): $(@bind petrol_service NumberField(0:500:100_000; default = ASSUMED_PETROL_SERVICE))

Other yearly difference, EV minus combustion car (CZK/year; positive costs the EV more): $(@bind other_difference NumberField(-100_000:500:100_000; default = ASSUMED_OTHER_DIFFERENCE))

**Energy: use your bill or today's price and record its source and date.**

Home (CZK/kWh): $(@bind home_price NumberField(0:0.0001:50; default = HOME_CZK_KWH))

DC (CZK/kWh): $(@bind dc_price NumberField(0:0.05:50; default = DC_MID_CZK_KWH))

EV at the socket (kWh/100 km): $(@bind ev_consumption NumberField(1:0.1:60; default = LEAF_SOCKET_KWH))

Petrol (CZK/L): $(@bind petrol_price NumberField(0:0.01:100; default = PETROL_CZK_L))

Petrol consumption (L/100 km): $(@bind petrol_consumption NumberField(1:0.01:30; default = PETROL_L_100KM))

Years shown: $(@bind years_shown Slider(1:15; default = DEFAULT_YEARS, show_value = true))
"""

# ╔═╡ 2564b1f9-f4ef-48b9-aafe-a0dfca4eaa06
begin
    inputs = (; price_gap, km_per_year, home_share, home_price, dc_price,
        ev_consumption, petrol_price, petrol_consumption, ev_service,
        petrol_service, other_difference)
    function saving_for(p)
        return yearly_saving(; (k => v for (k, v) in pairs(p) if k != :price_gap)...)
    end
    saving = saving_for(inputs)
    crossing = breakeven_year(price_gap, saving; years = years_shown)
    home_cost = cost_per_100km(ev_consumption, home_price)
    dc_cost = cost_per_100km(ev_consumption, dc_price)
    petrol_cost = cost_per_100km(petrol_consumption, petrol_price)
    mixed_cost = home_share * home_cost + (1 - home_share) * dc_cost
    ev_yearly = km_per_year / 100 * mixed_cost + ev_service + other_difference
    petrol_yearly = km_per_year / 100 * petrol_cost + petrol_service
    crossing_text = isnothing(crossing) ? "never within $(years_shown) years" :
        "$(round(crossing; digits = 2)) years"
end

# ╔═╡ 2564b1f9-f4ef-48b9-aafe-a0dfca4eaa07
md"""
## The bill

| Energy only | CZK/100 km |
|:--|--:|
| EV at home | $(round(home_cost; digits = 1)) |
| EV on DC | $(round(dc_cost; digits = 1)) |
| EV with your charging share | $(round(mixed_cost; digits = 1)) |
| Petrol car | $(round(petrol_cost; digits = 1)) |

Deck check: Leaf home **120**, DC **222–289**, petrol **224 CZK/100 km**.
Your annual saving with the EV is **$(round(saving; digits = 0)) CZK**.
Break-even: **$(crossing_text)**.

Prices, distance, and yearly bills stay constant. No loan interest, discounting, resale,
battery replacement, or charger purchase is included. Add recurring differences above.
The common combustion car purchase price is subtracted from both curves: the EV starts at
the price gap and the combustion car at zero. A crossing is interpolated within the year.
If yearly saving is zero or negative, no payback is reported.
"""

# ╔═╡ 2564b1f9-f4ef-48b9-aafe-a0dfca4eaa08
cumulative_plot = let
    t = range(0, years_shown; length = 181)
    p = plot(t, petrol_yearly .* t; label = "Combustion car", lw = 2,
        xlabel = "Years", ylabel = "Cumulative cost relative to common purchase price [CZK]",
        size = (960, 450), legend = :topleft)
    plot!(p, t, price_gap .+ ev_yearly .* t; label = "EV", lw = 2)
    if !isnothing(crossing)
        vline!(p, [crossing]; label = "Break-even: $(round(crossing; digits = 2)) years",
            linestyle = :dash, color = :black)
        scatter!(p, [crossing], [petrol_yearly * crossing]; label = "", color = :black)
    else
        title!(p, "Never within $(years_shown) years")
    end
    p
end

# ╔═╡ 2564b1f9-f4ef-48b9-aafe-a0dfca4eaa09
md"""
## Which input matters most?

Change one money, distance, consumption, or charging-share input by **−20% and +20%**,
leaving the others fixed. Home share is limited to 0–1. Zero stays zero; years shown is
only a display limit, not a cost input. Bars end at the resulting break-even years.
Results beyond the horizon are placed at **N+1** and labeled with their actual year;
“none” means no payback at any year. Ranking uses the uncapped years, with no payback
ranked as an infinite effect. Equal effects share the top rank.
"""

# ╔═╡ 2564b1f9-f4ef-48b9-aafe-a0dfca4eaa10
begin
    sensitivity_labels = ["Purchase gap", "Km per year", "Home charging share", "Home price",
        "DC price", "EV consumption", "Petrol price", "Petrol consumption", "EV servicing",
        "Combustion servicing", "Other yearly difference"]
    sensitivity = map(collect(keys(inputs)), sensitivity_labels) do key, label
        results = map((0.8, 1.2)) do factor
            value = getproperty(inputs, key) * factor
            key == :home_share && (value = clamp(value, 0, 1))
            changed = merge(inputs, NamedTuple{(key,)}((value,)))
            breakeven_year(changed.price_gap, saving_for(changed))
        end
        lo, hi = results
        effect = if isnothing(lo) && isnothing(hi)
            0.0
        elseif isnothing(lo) || isnothing(hi)
            Inf
        else
            abs(hi - lo)
        end
        (; label, lo, hi, effect)
    end
    sort!(sensitivity; by = row -> row.effect, rev = true)
    top_effect = first(sensitivity).effect
    top_inputs = join([row.label for row in sensitivity if row.effect == top_effect], ", ")
    sensitivity_sentence = top_effect == 0 ?
        "None of these changes moves the break-even year with the current inputs." :
        "The input moving the break-even year most is: $(top_inputs)."
end

# ╔═╡ 2564b1f9-f4ef-48b9-aafe-a0dfca4eaa11
sensitivity_plot = let
    cap = years_shown + 1
    position(x) = isnothing(x) ? cap : min(x, cap)
    caption(x) = isnothing(x) ? "none" : "$(round(x; digits = 1)) yr"
    n = length(sensitivity)
    p = plot(; size = (960, 600), xlabel = "Break-even year (N+1 = outside view)",
        yticks = (1:n, [r.label for r in sensitivity]), yflip = true,
        xlims = (0, cap + 2), ylims = (0.5, n + 0.5), legend = :bottomright)
    for (i, row) in enumerate(sensitivity)
        a, b = position(row.lo), position(row.hi)
        plot!(p, [a, b], [i, i]; color = :gray, lw = 7, label = "")
        scatter!(p, [a], [i - 0.12]; color = 1, label = i == 1 ? "−20%" : "")
        scatter!(p, [b], [i + 0.12]; color = 2, label = i == 1 ? "+20%" : "")
        annotate!(p, a, i - 0.28, text(caption(row.lo), 8))
        annotate!(p, b, i + 0.28, text(caption(row.hi), 8))
    end
    if !isnothing(crossing)
        vline!(p, [crossing]; linestyle = :dash, color = :black, label = "Current")
    end
    p
end

# ╔═╡ 2564b1f9-f4ef-48b9-aafe-a0dfca4eaa12
md"""$(sensitivity_sentence)"""

# ╔═╡ 2564b1f9-f4ef-48b9-aafe-a0dfca4eaa13
begin
    @assert abs(cost_per_100km(LEAF_SOCKET_KWH, HOME_CZK_KWH) - 120) <= 1
    @assert abs(cost_per_100km(LEAF_SOCKET_KWH, DC_LOW_CZK_KWH) - 222) <= 1
    @assert abs(cost_per_100km(LEAF_SOCKET_KWH, DC_HIGH_CZK_KWH) - 289) <= 1
    @assert abs(cost_per_100km(PETROL_L_100KM, PETROL_CZK_L) - 224) <= 1
    @assert isnothing(breakeven_year(200_000, 0))
    @assert isnothing(breakeven_year(200_000, -20_000))
    @assert breakeven_year(200_000, 20_000) == 10
    @assert breakeven_year(200_000, 30_000) ≈ 6 + 2 / 3
    @assert isnothing(breakeven_year(200_000, 20_000; years = 9))
    println("EV payback assertions passed.")
    println("Costs [CZK/100 km]: home=$(round(home_cost; digits=1)), DC=$(round(dc_cost; digits=1)), petrol=$(round(petrol_cost; digits=1))")
    println("Annual saving: $(round(saving; digits=2)) CZK; break-even: $(crossing_text)")
    println(sensitivity_sentence)
end

# ╔═╡ Cell order:
# ╠═2564b1f9-f4ef-48b9-aafe-a0dfca4eaa01
# ╠═2564b1f9-f4ef-48b9-aafe-a0dfca4eaa02
# ╠═2564b1f9-f4ef-48b9-aafe-a0dfca4eaa03
# ╟─2564b1f9-f4ef-48b9-aafe-a0dfca4eaa04
# ╟─2564b1f9-f4ef-48b9-aafe-a0dfca4eaa05
# ╠═2564b1f9-f4ef-48b9-aafe-a0dfca4eaa06
# ╟─2564b1f9-f4ef-48b9-aafe-a0dfca4eaa07
# ╠═2564b1f9-f4ef-48b9-aafe-a0dfca4eaa08
# ╟─2564b1f9-f4ef-48b9-aafe-a0dfca4eaa09
# ╠═2564b1f9-f4ef-48b9-aafe-a0dfca4eaa10
# ╠═2564b1f9-f4ef-48b9-aafe-a0dfca4eaa11
# ╟─2564b1f9-f4ef-48b9-aafe-a0dfca4eaa12
# ╠═2564b1f9-f4ef-48b9-aafe-a0dfca4eaa13
