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

This notebook compares the same straight-line emergency stop **with and without ABS** and
measures the one number a driver cares about: the **braking distance**.

The vehicle starts at **25 m/s (90 km/h)**, and at 0.5 s the driver steps on the brake with a
6000 N·m demand, more than the tire can transmit. Without ABS that torque locks the wheel. With
ABS, the wheel-speed-only controller (`ABSControllerWheelOnly`) modulates the torque to keep the
wheel rolling.

The wheel model separates vehicle speed from wheel speed and calculates longitudinal slip

```math
\kappa = \frac{r\omega-v}{\max(|v|,v_\epsilon)}.
```

During braking, slip is negative. The tire reaches peak adhesion `μ_A` near `κ = -0.04` and
falls to the sliding value `μ_S` beyond `κ = -0.12`; a locked wheel sits at `κ = -1`.
"""

# ╔═╡ c09e1780-cb2b-4c19-ad89-fd1d0575486e
md"""
## Experiment

**Road friction** scales the whole tire curve: `1.0` is a dry road, about `0.5` is wet, and
`0.2` is snow.
"""

# ╔═╡ 4a25ea4b-5258-43df-9e06-94a99607359f
@bind road_mu Slider(0.2:0.1:1.0; default=1.0, show_value=true)

# ╔═╡ 724f33cb-97c6-4673-9d87-8917eb9d5cda
md"""
**ABS tuning.** The controller only measures wheel speed, so it has to estimate how fast the car
is going. While the wheel slips, it assumes the car slows down at most at `a_ref`. Set `a_ref`
much higher than the road allows (about `μ·g`) and the estimate falls too fast: the controller
under-reads the slip, releases too late, and the stop gets longer.
"""

# ╔═╡ 816bf90c-eeba-40d9-a9b2-b01ca6afcf2b
md"`a_ref` [m/s²] $(@bind a_ref Slider(2.0:1.0:14.0; default=8.0, show_value=true))"

# ╔═╡ 8fc92403-b541-46ba-9277-fdd5dab80847
begin
    V0 = 25.0
    BRAKE_TIME = 0.5
    V_STOP = 0.5
    G = 9.80665

    # Simulate the slowest possible stop with a margin so every run comes to rest. That is the
    # locked wheel, unless `a_ref` is below it: the ABS then lets the car slow at only about `a_ref`.
    stop_time(mu, a_max=Inf) = BRAKE_TIME + 1.5 * V0 / min(0.7 * mu * G, a_max) + 1.0

    """
    Distance and time from brake application until the vehicle speed first falls below
    `V_STOP`, plus the traces of speed over distance travelled since braking began.
    """
    function braking(run)
        model = symbolic_container(run)
        sol = run.sol
        t, v, s = sol.t, sol[model.body.mass.v], sol[model.body.mass.s]
        s_brake = sol(BRAKE_TIME, idxs=model.body.mass.s)
        braking_phase = t .>= BRAKE_TIME
        i_stop = findfirst(i -> braking_phase[i] && v[i] < V_STOP, eachindex(t))
        isnothing(i_stop) && error("vehicle still at $(round(v[end]; digits=2)) m/s when the run ended")
        (; model, sol,
            distance=s[i_stop] - s_brake,
            time=t[i_stop] - BRAKE_TIME,
            s=s[braking_phase] .- s_brake,
            v=v[braking_phase])
    end

    abs_braking(mu) = braking(VehicleSystemsComponents.Vehicle.ABSBrakeTransient(
        road_mu=mu, a_ref=a_ref, stop=stop_time(mu, a_ref)))
    ideal_abs_braking(mu) = braking(VehicleSystemsComponents.Vehicle.IdealBrakeTransient(
        road_mu=mu, stop=stop_time(mu)))
    locked_braking(mu) = braking(VehicleSystemsComponents.Vehicle.LockedBrakeTransient(
        road_mu=mu, stop=stop_time(mu)))
end

# ╔═╡ ebde0e45-07be-45cc-a8d1-5a028eb1741f
begin
    with_abs = abs_braking(road_mu)
    with_ideal_abs = ideal_abs_braking(road_mu)
    without_abs = locked_braking(road_mu)

    abs_model, abs_sol = with_abs.model, with_abs.sol
    ideal_abs_model, ideal_abs_sol = with_ideal_abs.model, with_ideal_abs.sol
    locked_model, locked_sol = without_abs.model, without_abs.sol

    mu_A = abs_sol.ps[abs_model.wheel.mu_A]
    mu_S = abs_sol.ps[abs_model.wheel.mu_S]
    # Constant-deceleration stops at the tire's peak and sliding friction, ignoring the brake lag.
    ideal_distance(mu) = V0^2 / (2 * mu * mu_A * G)
    sliding_distance(mu) = V0^2 / (2 * mu * mu_S * G)
end

# ╔═╡ f05016c5-aa2e-4c7b-8bf3-750021471d22
md"""
## Braking distance

Braking distance is measured from the moment the driver presses the pedal (0.5 s) until the car
falls below 0.5 m/s. The dotted gray curve is the best possible stop: a constant deceleration of
`μ·μ_A·g`, which the tire delivers only if it is held exactly at its adhesion peak for the whole
stop.
"""

# ╔═╡ ef0d4e60-8da0-4180-868f-16e80a2481f9
begin
    distance_plot = plot(
        with_abs.s, 3.6 .* with_abs.v;
        lw=3, label="ABS", color=:steelblue,
        xlabel="distance since brake applied [m]", ylabel="vehicle speed [km/h]",
        title="Speed over braking distance", legend=:topright,
    )
    plot!(distance_plot, with_ideal_abs.s, 3.6 .* with_ideal_abs.v;
        lw=3, label="ideal ABS (true slip)", color=:seagreen)
    plot!(distance_plot, without_abs.s, 3.6 .* without_abs.v;
        lw=3, ls=:dash, label="no ABS (locked)", color=:firebrick)
    let d = ideal_distance(road_mu), s = range(0, d; length=200)
        plot!(distance_plot, s, 3.6 .* sqrt.(max.(V0^2 .- 2 * road_mu * mu_A * G .* s, 0.0));
            lw=2, ls=:dot, color=:gray, label="ideal (peak μ)")
    end
    vline!(distance_plot, [with_abs.distance]; color=:steelblue, ls=:dot, label="")
    vline!(distance_plot, [with_ideal_abs.distance]; color=:seagreen, ls=:dot, label="")
    vline!(distance_plot, [without_abs.distance]; color=:firebrick, ls=:dot, label="")
    distance_plot
end

# ╔═╡ 6d192d2d-e574-4ca2-a12f-949911caf28e
let
    r(x) = round(x; digits=1)
    delta = with_abs.distance - without_abs.distance
    verdict = delta < 0 ?
        "ABS shortens the stop by **$(r(-delta)) m**." :
        "ABS **lengthens** the stop by **$(r(delta)) m**: this controller releases more braking than it needs to."
    Markdown.parse("""
    | | braking distance [m] | time to stop [s] | mean deceleration [m/s²] |
    |---|---:|---:|---:|
    | ABS | $(r(with_abs.distance)) | $(round(with_abs.time; digits=2)) | $(r(V0^2 / (2 * with_abs.distance))) |
    | ideal ABS (true slip) | $(r(with_ideal_abs.distance)) | $(round(with_ideal_abs.time; digits=2)) | $(r(V0^2 / (2 * with_ideal_abs.distance))) |
    | no ABS (locked) | $(r(without_abs.distance)) | $(round(without_abs.time; digits=2)) | $(r(V0^2 / (2 * without_abs.distance))) |
    | ideal at peak `μ_A` | $(r(ideal_distance(road_mu))) | | $(r(road_mu * mu_A * G)) |
    | locked at sliding `μ_S` | $(r(sliding_distance(road_mu))) | | $(r(road_mu * mu_S * G)) |

    $verdict
    """)
end

# ╔═╡ 5185b6bd-a789-4ff9-87d7-2717b0dc9451
md"""
## What the wheel is doing

The distance follows from the slip. Each ABS cycle the wheel starts to lock, the controller
releases, the wheel spins back up, and pressure is rebuilt. Any time spent far from the
adhesion peak, whether deep in slip or with too little torque, is braking force lost.
"""

# ╔═╡ 0e526996-1049-4457-92da-a4f6122b7853
begin
    speed_plot = plot(
        abs_sol.t, 3.6 .* abs_sol[abs_model.body.mass.v];
        lw=3, label="ABS vehicle", color=:steelblue,
        xlabel="time [s]", ylabel="speed [km/h]",
        title="Vehicle and wheel speed", legend=:topright,
    )
    plot!(speed_plot, abs_sol.t,
        3.6 .* abs_sol.ps[abs_model.radius] .* abs_sol[abs_model.wheel.inertia.w];
        lw=1.5, label="ABS wheel surface", color=:steelblue, alpha=0.5)
    plot!(speed_plot, locked_sol.t, 3.6 .* locked_sol[locked_model.body.mass.v];
        lw=3, ls=:dash, label="no ABS vehicle", color=:firebrick)
    vline!(speed_plot, [BRAKE_TIME]; color=:gray, ls=:dot, label="brake applied")
    xlims!(speed_plot, 0, BRAKE_TIME + max(with_abs.time, without_abs.time) + 0.5)
    speed_plot
end

# ╔═╡ 306de942-02bb-4126-a171-01b08501ae01
begin
    slip_plot = plot(
        abs_sol.t, abs_sol[abs_model.wheel.kappa];
        lw=2, label="ABS", color=:steelblue,
        xlabel="time [s]", ylabel="longitudinal slip κ",
        title="Wheel slip", ylims=(-1.1, 0.1), legend=:bottomleft,
    )
    plot!(slip_plot, locked_sol.t, locked_sol[locked_model.wheel.kappa];
        lw=2.5, ls=:dash, label="no ABS", color=:firebrick)
    hline!(slip_plot, [-0.04]; color=:black, ls=:dot, label="adhesion peak")
    xlims!(slip_plot, 0, BRAKE_TIME + max(with_abs.time, without_abs.time) + 0.5)
    slip_plot
end

# ╔═╡ 1da46c66-fe04-45ac-ac44-9707a58a06b5
begin
    torque_plot = plot(
        abs_sol.t, abs_sol[abs_model.wheel.brake.tau_actual];
        lw=2, label="ABS", color=:steelblue,
        xlabel="time [s]", ylabel="brake torque [N·m]",
        title="Brake torque at the caliper", legend=:bottomright,
    )
    plot!(torque_plot, locked_sol.t, locked_sol[locked_model.wheel.brake.tau_actual];
        lw=2.5, ls=:dash, label="no ABS", color=:firebrick)
    friction_limit = road_mu * mu_A * abs_sol.ps[abs_model.wheel.F_z] * abs_sol.ps[abs_model.radius]
    hline!(torque_plot, [friction_limit]; color=:black, ls=:dot, label="tire limit at peak μ")
    xlims!(torque_plot, 0, BRAKE_TIME + max(with_abs.time, without_abs.time) + 0.5)
    torque_plot
end

# ╔═╡ 9b98e3c7-6727-4467-b897-a0c4ac62d760
md"""
### Where on the tire curve the wheel operates

The tire's friction coefficient `μ` is a function of slip alone. It rises to the adhesion
peak `μ_A` near `κ = -0.04`, then falls to the sliding value `μ_S` from `κ = -0.12` onwards.
Each dot below is one millisecond of the stop, so dense regions are where the wheel spends its
time. A good ABS keeps its dots clustered at the peak. The plot shows slip down to `-0.3`;
the friction stays at `μ_S` all the way to the locked wheel at `κ = -1`.
"""

# ╔═╡ 8210d0e8-3c03-4f19-ad31-140b8a39a92c
friction_plot = let
    samples(run, model, sol) = begin
        t = BRAKE_TIME:0.001:(BRAKE_TIME + run.time)
        (sol(t, idxs=model.wheel.kappa).u, sol(t, idxs=model.wheel.tire.mu).u)
    end
    abs_kappa, abs_mu = samples(with_abs, abs_model, abs_sol)
    locked_kappa, locked_mu = samples(without_abs, locked_model, locked_sol)

    # μ depends on κ alone, so the samples of both runs sorted by κ trace the model's curve.
    curve_kappa = [abs_kappa; locked_kappa]
    order = sortperm(curve_kappa)
    curve_mu = [abs_mu; locked_mu][order]

    near_peak = count(k -> 0.02 <= -k <= 0.08, abs_kappa) / length(abs_kappa)
    sliding = count(k -> -k >= 0.12, abs_kappa) / length(abs_kappa)

    r(x) = round(x; digits=2)
    p = plot(
        curve_kappa[order], curve_mu;
        lw=2, color=:gray, label="tire curve (μ_A = $(r(road_mu * mu_A)), μ_S = $(r(road_mu * mu_S)))",
        xlabel="longitudinal slip κ", ylabel="friction coefficient μ",
        title="ABS: $(round(Int, 100near_peak)) % of the stop near the peak, $(round(Int, 100sliding)) % sliding",
        xlims=(-0.3, 0.005), legend=:bottomleft,
    )
    scatter!(p, locked_kappa, locked_mu;
        ms=3, msw=0, alpha=0.3, color=:firebrick, label="no ABS")
    scatter!(p, abs_kappa, abs_mu;
        ms=3, msw=0, alpha=0.3, color=:steelblue, label="ABS")
    vline!(p, [-0.04]; color=:black, ls=:dot, label="adhesion peak")
    annotate!(p, -0.29, -road_mu * mu_S + 0.06,
        text("no ABS: sits at κ = -1, μ = μ_S (off the left edge)", 8, :left, :firebrick))
    p
end

# ╔═╡ b93db903-d64f-458b-a015-93b7b92ba637
md"""
## Braking distance across road surfaces

The same stop repeated from dry asphalt down to snow, using the ABS tuning selected above. The
gray band is bounded by the two constant-friction stops: peak adhesion below it, full sliding
above it.
"""

# ╔═╡ d88841c5-0c60-494f-b63d-9f18fcf30b90
begin
    sweep_mu = collect(0.2:0.1:1.0)
    sweep_abs = [abs_braking(mu).distance for mu in sweep_mu]
    sweep_ideal_abs = [ideal_abs_braking(mu).distance for mu in sweep_mu]
    sweep_locked = [locked_braking(mu).distance for mu in sweep_mu]
end

# ╔═╡ b141561d-487a-4d4c-8725-8d42808ab781
begin
    sweep_plot = plot(
        sweep_mu, ideal_distance.(sweep_mu);
        fillrange=sliding_distance.(sweep_mu), fillalpha=0.15, color=:gray, lw=1,
        label="ideal … sliding", xlabel="road friction multiplier",
        ylabel="braking distance [m]", title="Braking distance from 90 km/h",
        legend=:topright,
    )
    plot!(sweep_plot, sweep_mu, sweep_abs;
        lw=3, marker=:circle, color=:steelblue, label="ABS")
    plot!(sweep_plot, sweep_mu, sweep_ideal_abs;
        lw=3, marker=:diamond, color=:seagreen, label="ideal ABS (true slip)")
    plot!(sweep_plot, sweep_mu, sweep_locked;
        lw=3, ls=:dash, marker=:square, color=:firebrick, label="no ABS (locked)")
    vline!(sweep_plot, [road_mu]; color=:black, ls=:dot, label="selected μ")
    sweep_plot
end

# ╔═╡ 53a89ecf-62d1-4310-9051-f37ceba0e833
let
    r(x) = round(x; digits=1)
    rows = join(("| $(mu) | $(r(a)) | $(r(i)) | $(r(l)) | $(r(a - l)) | $(r(ideal_distance(mu))) |"
                 for (mu, a, i, l) in zip(sweep_mu, sweep_abs, sweep_ideal_abs, sweep_locked)), "\n")
    Markdown.parse("""
    | road μ | ABS [m] | ideal ABS [m] | no ABS [m] | ABS − no ABS [m] | peak-μ bound [m] |
    |---:|---:|---:|---:|---:|---:|
    $rows
    """)
end

# ╔═╡ 479ee972-0a70-4f65-a8ba-84cb772388b3
md"""
## Interpretation

- **Locked wheel.** A locked wheel slides at `μ_S = 0.7`, so its stop is close to the
  "sliding" bound. It is also the stop in which the driver cannot steer.
- **Peak-μ bound.** Holding the tire exactly at its adhesion peak `κ ≈ -0.04` for the whole
  stop gives the "ideal" curve, about 27 % shorter than the locked stop on this tire. No
  controller reaches it, because the brake needs time to respond.
- **How this ABS works.** Like a real ABS computer, the controller runs every 5 ms. It releases
  the brake when the *predicted* slip, the slip 30 ms ahead, passes the peak. That lead covers
  the 30 ms the brake hydraulics take to respond. It remembers the torque at which the wheel
  started to lock, releases only to 60 % of it, then quickly reapplies to 85 % and creeps up from
  there. Most of the stop is spent just below the peak.
- **Ideal ABS (true slip)** runs the same kind of logic but reads the true slip and vehicle
  speed. It shows what the logic can do with perfect sensing.
- **This ABS (wheel speed only).** On a dry road it stops about 11 % shorter than the locked
  wheel, which is what real cars achieve (10–13 %). On slippery roads the gain shrinks, and in
  the sweep above it turns into a small loss at `μ = 0.3`. The cause is the speed estimate: a
  fixed `a_ref` is far more deceleration than a slippery road allows, so the estimated vehicle
  speed falls faster than the car really slows down. Move the `a_ref` slider to see it: at
  10 m/s² the ABS also loses at `μ = 0.2` and on a wet road (`μ = 0.5`). Real ABS computers
  learn the road's deceleration instead of assuming it.
- **Why ABS still matters when the gain is small:** a rolling wheel can steer, a locked one
  cannot.

### Current scope

This is a single-wheel-equivalent longitudinal model without load transfer. It can demonstrate
ABS physics, but not ESP. ESP additionally requires lateral tire forces, steering input, yaw
dynamics, axle geometry, and independent braking at four wheels.
"""

# ╔═╡ Cell order:
# ╟─2ca28fa0-0c54-4f41-95e7-acde9cd8828d
# ╠═5ea5fa1c-b6fd-42b5-b15d-b8d547e5962f
# ╟─c09e1780-cb2b-4c19-ad89-fd1d0575486e
# ╠═4a25ea4b-5258-43df-9e06-94a99607359f
# ╟─724f33cb-97c6-4673-9d87-8917eb9d5cda
# ╟─816bf90c-eeba-40d9-a9b2-b01ca6afcf2b
# ╠═8fc92403-b541-46ba-9277-fdd5dab80847
# ╠═ebde0e45-07be-45cc-a8d1-5a028eb1741f
# ╟─f05016c5-aa2e-4c7b-8bf3-750021471d22
# ╠═ef0d4e60-8da0-4180-868f-16e80a2481f9
# ╟─6d192d2d-e574-4ca2-a12f-949911caf28e
# ╟─5185b6bd-a789-4ff9-87d7-2717b0dc9451
# ╠═0e526996-1049-4457-92da-a4f6122b7853
# ╠═306de942-02bb-4126-a171-01b08501ae01
# ╠═1da46c66-fe04-45ac-ac44-9707a58a06b5
# ╟─9b98e3c7-6727-4467-b897-a0c4ac62d760
# ╠═8210d0e8-3c03-4f19-ad31-140b8a39a92c
# ╟─b93db903-d64f-458b-a015-93b7b92ba637
# ╠═d88841c5-0c60-494f-b63d-9f18fcf30b90
# ╠═b141561d-487a-4d4c-8725-8d42808ab781
# ╟─53a89ecf-62d1-4310-9051-f37ceba0e833
# ╟─479ee972-0a70-4f65-a8ba-84cb772388b3
