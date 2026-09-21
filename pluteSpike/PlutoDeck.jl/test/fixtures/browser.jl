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
# ╠═╡ card = "plotly"
plotly_offline = begin
    using PlutoPlotly
    enable_plutoplotly_offline()
end

# ╔═╡ a1000000-0000-4000-8000-000000000002
# ╠═╡ card = "frequency"
@bind freq html"<input type=range min=1 max=5 step=1 value=1>"

# ╔═╡ a1000000-0000-4000-8000-000000000003
cycles = ismissing(freq) ? 1 : Int(freq)

# ╔═╡ a1000000-0000-4000-8000-000000000004
# ╠═╡ card = "wave"
let t = range(0, 1; length=201)
    plot(scatter(; x=collect(t), y=sin.(2π .* cycles .* t)),
         Layout(template = plot_template))
end

# ╔═╡ a1000000-0000-4000-8000-000000000005
# ╠═╡ card = "readout"
md"""**cycles** $(cycles)"""

# ╔═╡ a1000000-0000-4000-8000-000000000006
# ╠═╡ card = "constant"
md"""the car weighs **1400 kg**"""

# ╔═╡ a1000000-0000-4000-8000-000000000007
# ╠═╡ card = "plain"
Text("<b>not bold</b> & <script>never runs</script>")

# ╔═╡ a1000000-0000-4000-8000-000000000008
@bind deck_theme html"<span></span>"

# ╔═╡ a1000000-0000-4000-8000-000000000009
plot_template = templates[coalesce(deck_theme, "light") == "dark" ? :plotly_dark : :plotly_white]

# ╔═╡ Cell order:
# ╠═a1000000-0000-4000-8000-000000000001
# ╠═a1000000-0000-4000-8000-000000000002
# ╠═a1000000-0000-4000-8000-000000000003
# ╠═a1000000-0000-4000-8000-000000000004
# ╠═a1000000-0000-4000-8000-000000000005
# ╠═a1000000-0000-4000-8000-000000000006
# ╠═a1000000-0000-4000-8000-000000000007
# ╠═a1000000-0000-4000-8000-000000000008
# ╠═a1000000-0000-4000-8000-000000000009
