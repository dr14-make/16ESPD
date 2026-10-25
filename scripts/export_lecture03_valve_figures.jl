"""
Writes the theory deck's valve-level ABS figure, one `HandsOn03.HydraulicABSStop` stop from
25 m/s on a dry road (µ 1.0, pedal 0.6), into `slides/decks/lecture-03/public/figures/`:

    julia +dyad-3.4.0 --project=. scripts/export_lecture03_valve_figures.jl

The figure stacks the master-cylinder and front-wheel pressures, the inlet, outlet and pump
commands of the valve controller, and the master-cylinder rod travel `x_rod`, whose ripple is
the pedal kickback. It prints every number the slide quotes. The run is Rodas5P with dtmax 1 ms
and takes about half a minute warm, a minute and a half with compilation.
"""

using VehicleSystemsComponents
using DyadInterface: symbolic_container
using Plots

const H3 = VehicleSystemsComponents.HandsOn03
const OUT = normpath(@__DIR__, "..", "slides", "decks", "lecture-03", "public", "figures")
const T = collect(range(0.0, 6.0; length = 6001))
const BRAKE_TIME = 0.5
const BAR = 1e5

r1(x) = round(x; digits = 1)
r2(x) = round(x; digits = 2)

result = H3.HydraulicABSStopTransient()
sol, model = result.sol, symbolic_container(result)
get(x) = sol(T, idxs = x).u
v = get(model.body.mass.v)
p_mc = get(model.master.p_mc) ./ BAR
p_f = get(model.wheel.caliper_f.p) ./ BAR
inlet = get(model.controller.inlet)
outlet = get(model.controller.outlet)
motor = get(model.controller.motor)
x_rod = get(model.master.x_rod) .* 1e3

distance = VehicleSystemsComponents.Vehicle.braking_distance(result)
is = something(findfirst(i -> T[i] > BRAKE_TIME && v[i] < 0.5, eachindex(T)), length(T))
ia = findfirst(i -> T[i] > BRAKE_TIME && motor[i] > 0.5, eachindex(T))
ilast = findlast(i -> i <= is && motor[i] > 0.5, eachindex(T))
cycling = ia:ilast
dumps = count(i -> outlet[i] > 0.5 && outlet[i - 1] <= 0.5, (ia + 1):ilast)
cycle_time = T[ilast] - T[ia]

println("HydraulicABSStop, µ 1.0, pedal 0.6:")
println("  stopping distance $(r2(distance)) m, at rest at $(r2(T[is])) s")
println("  ABS first active $(round(Int, 1000 * (T[ia] - BRAKE_TIME))) ms after the pedal, ",
    "cycling until $(r2(T[ilast])) s")
println("  $(dumps) dumps in $(r2(cycle_time)) s, $(r1(dumps / cycle_time)) Hz")
println("  master pressure peak $(r1(maximum(p_mc))) bar, ",
    "$(r1(minimum(p_mc[cycling])))–$(r1(maximum(p_mc[cycling]))) bar while cycling")
println("  front wheel pressure peak $(r1(maximum(p_f))) bar, ",
    "$(r1(minimum(p_f[cycling])))–$(r1(maximum(p_f[cycling]))) bar while cycling")
println("  x_rod $(r2(minimum(x_rod[cycling])))–$(r2(maximum(x_rod[cycling]))) mm while cycling, ",
    "$(r2(x_rod[ia])) mm when ABS starts")

window = 1:min(is + 100, length(T))
t = T[window]
pressure = plot(t, p_mc[window]; lw = 2, color = :gray30, label = "master cylinder p_mc",
    ylabel = "pressure [bar]", legend = :topright,
    title = "Valve-level ABS, dry road: pressures, valve commands and the pedal kickback")
plot!(pressure, t, p_f[window]; lw = 2, color = :royalblue, label = "front wheel")
# The commands are offset so the three on/off traces do not overlap; 1 is open or on.
valves = plot(; ylabel = "command", yticks = false, legend = false, ylims = (-0.2, 3.6))
for (u, offset, color, name) in ((inlet, 2.4, :seagreen, "inlet, 1 open"),
        (outlet, 1.2, :firebrick, "outlet, 1 open"), (motor, 0.0, :darkorange, "pump motor"))
    plot!(valves, t, u[window] .+ offset; lw = 1.5, color)
    annotate!(valves, t[1] + 0.02, offset + 0.55, Plots.text(name, 8, :left, color))
end
travel = plot(t, x_rod[window]; lw = 2, color = :purple, label = "", xlabel = "time [s]",
    ylabel = "x_rod [mm]")
fig = plot(pressure, valves, travel; layout = grid(3, 1, heights = [0.42, 0.28, 0.30]),
    link = :x, size = (960, 600), dpi = 100, left_margin = 6Plots.mm, bottom_margin = 3Plots.mm)
mkpath(OUT)
savefig(fig, joinpath(OUT, "03-valve-abs-cycle.svg"))
println("  03-valve-abs-cycle.svg")
