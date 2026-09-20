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
# ╠═╡ card = "target-speed"
@bind v_ref_kmh html"<input type=range min=60 max=160 value=110>"

# ╔═╡ a1000000-0000-4000-8000-000000000002
scratch = 1 + 1

# ╔═╡ a1000000-0000-4000-8000-000000000003
# ╠═╡ card = "speed-plot"
plot(t, v; label="v(t)")

# ╔═╡ a1000000-0000-4000-8000-000000000004
# ╠═╡ card = "metrics"
md"""**overshoot** $(round(overshoot; digits=1)) %"""

# ╔═╡ Cell order:
# ╠═a1000000-0000-4000-8000-000000000001
# ╠═a1000000-0000-4000-8000-000000000002
# ╠═a1000000-0000-4000-8000-000000000003
# ╠═a1000000-0000-4000-8000-000000000004
