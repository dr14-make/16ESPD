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

# ╔═╡ 5ea5fa1c-b6fd-42b5-b15d-b8d547e5962f
begin
    import Pkg
    Pkg.activate(joinpath(@__DIR__, "..", ".."))
    include(joinpath(@__DIR__, "..", "lecture01", "support.jl"))
    using .Lecture01Support
    VehicleSystemsComponents = setup()
    using ModelingToolkit, Plots
    using DyadInterface: symbolic_container
    using PlutoUI
end

# ╔═╡ 2ca28fa0-0c54-4f41-95e7-acde9cd8828d
md"""
# Lecture 3 — Anti-lock braking (ABS)

This notebook compares the same straight-line braking manoeuvre with and without ABS.
The vehicle starts at **25 m/s (90 km/h)** and receives a 3000 N·m brake request at 0.5 s.

The wheel model separates vehicle speed from wheel speed and calculates longitudinal slip

```math
\kappa = \frac{r\omega-v}{\max(|v|,v_\epsilon)}.
```

During braking, slip is negative. The tire reaches peak adhesion near `κ = -0.04`; a locked wheel
moves far into the sliding region.
"""

# ╔═╡ c09e1780-cb2b-4c19-ad89-fd1d0575486e
md"""
## Experiment

Select the road-friction multiplier. `1.0` represents the dry-road tire curve; smaller values
reduce all available longitudinal tire force.
"""

# ╔═╡ 4a25ea4b-5258-43df-9e06-94a99607359f
@bind road_mu Slider(0.2:0.1:1.0; default=1.0, show_value=true)

# ╔═╡ ebde0e45-07be-45cc-a8d1-5a028eb1741f
begin
    abs_run = VehicleSystemsComponents.Vehicle.ABSBrakeTransient(road_mu=road_mu)
    locked_run = VehicleSystemsComponents.Vehicle.LockedBrakeTransient(road_mu=road_mu)

    abs_model = symbolic_container(abs_run)
    locked_model = symbolic_container(locked_run)

    abs_sol = abs_run.sol
    locked_sol = locked_run.sol
end

# ╔═╡ f05016c5-aa2e-4c7b-8bf3-750021471d22
md"""
## Vehicle response

ABS modulates brake torque to retain tire adhesion. Without modulation, the requested torque can
stop the wheel while the vehicle continues moving. The model runs for four seconds, so the distance
reported below is **distance travelled by 4 s**, not necessarily total stopping distance.
"""

# ╔═╡ 0e526996-1049-4457-92da-a4f6122b7853
begin
    speed_plot = plot(
        abs_sol.t, 3.6 .* abs_sol[abs_model.body.mass.v];
        lw=3, label="ABS", color=:steelblue,
        xlabel="time [s]", ylabel="vehicle speed [km/h]",
        title="Vehicle speed", legend=:topright,
    )
    plot!(speed_plot, locked_sol.t, 3.6 .* locked_sol[locked_model.body.mass.v];
        lw=3, ls=:dash, label="no ABS", color=:firebrick)
    vline!(speed_plot, [0.5]; color=:gray, ls=:dot, label="brake applied")
    speed_plot
end

# ╔═╡ 306de942-02bb-4126-a171-01b08501ae01
begin
    slip_plot = plot(
        abs_sol.t, abs_sol[abs_model.wheel.kappa];
        lw=3, label="ABS", color=:steelblue,
        xlabel="time [s]", ylabel="longitudinal slip κ",
        title="Wheel slip (display limited to κ ≥ -2)",
        ylims=(-2.0, 0.1), legend=:bottomleft,
    )
    plot!(slip_plot, locked_sol.t, locked_sol[locked_model.wheel.kappa];
        lw=2.5, ls=:dash, label="no ABS", color=:firebrick)
    hline!(slip_plot, [-0.04]; color=:black, ls=:dot, label="adhesion target")
    slip_plot
end

# ╔═╡ 1da46c66-fe04-45ac-ac44-9707a58a06b5
begin
    torque_plot = plot(
        abs_sol.t, abs_sol[abs_model.brake.tau_actual];
        lw=3, label="ABS", color=:steelblue,
        xlabel="time [s]", ylabel="brake torque [N·m]",
        title="Hydraulic brake response", legend=:bottomright,
    )
    plot!(torque_plot, locked_sol.t, locked_sol[locked_model.brake.tau_actual];
        lw=2.5, ls=:dash, label="no ABS", color=:firebrick)
    torque_plot
end

# ╔═╡ 6d192d2d-e574-4ca2-a12f-949911caf28e
begin
    t_report = 4.0
    comparison = (
        road_friction = road_mu,
        abs_speed_kmh = round(3.6 * abs_sol(t_report, idxs=abs_model.body.mass.v), digits=2),
        no_abs_speed_kmh = round(3.6 * locked_sol(t_report, idxs=locked_model.body.mass.v), digits=2),
        abs_slip = round(abs_sol(t_report, idxs=abs_model.wheel.kappa), digits=3),
        no_abs_slip = round(locked_sol(t_report, idxs=locked_model.wheel.kappa), digits=3),
        abs_distance_m = round(abs_sol(t_report, idxs=abs_model.body.mass.s), digits=2),
        no_abs_distance_m = round(locked_sol(t_report, idxs=locked_model.body.mass.s), digits=2),
    )
end

# ╔═╡ 479ee972-0a70-4f65-a8ba-84cb772388b3
md"""
## Interpretation

- Near `κ = -0.04`, the tire operates around peak longitudinal adhesion.
- Large negative slip means wheel circumferential speed has fallen far below vehicle speed; this is
  wheel lock in the present one-dimensional model.
- The actuator has a 30 ms hydraulic time constant, so commanded torque is not applied instantly.
- On low-friction roads, the fixed-gain controller still prevents sustained wheel lock, but its slip
  excursions grow. A production ABS would use discrete pressure build/hold/release logic and wheel
  acceleration estimates.

### Current scope

This is a single-wheel-equivalent longitudinal model. It can demonstrate ABS physics, but not ESP.
ESP additionally requires lateral tire forces, steering input, yaw dynamics, axle geometry, and
independent braking at four wheels.
"""

# ╔═╡ Cell order:
# ╟─2ca28fa0-0c54-4f41-95e7-acde9cd8828d
# ╠═5ea5fa1c-b6fd-42b5-b15d-b8d547e5962f
# ╟─c09e1780-cb2b-4c19-ad89-fd1d0575486e
# ╠═4a25ea4b-5258-43df-9e06-94a99607359f
# ╠═ebde0e45-07be-45cc-a8d1-5a028eb1741f
# ╟─f05016c5-aa2e-4c7b-8bf3-750021471d22
# ╠═0e526996-1049-4457-92da-a4f6122b7853
# ╠═306de942-02bb-4126-a171-01b08501ae01
# ╠═1da46c66-fe04-45ac-ac44-9707a58a06b5
# ╠═6d192d2d-e574-4ca2-a12f-949911caf28e
# ╟─479ee972-0a70-4f65-a8ba-84cb772388b3
