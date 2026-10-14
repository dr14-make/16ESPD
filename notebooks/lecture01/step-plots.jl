# Renders the plot images of the Lecture 1 build guide and deck from the `Lecture1.StepNN` models.
# Run from the repository root: julia --project notebooks/lecture01/step-plots.jl
const OUT = normpath(@__DIR__, "..", "..", "slides", "images", "lecture-01")
mkpath(OUT)
include(joinpath(@__DIR__, "support.jl"))
using .Lecture01Support
Lecture01Support.setup()
using Plots
const L = VehicleSystemsComponents.Lecture1

Plots.default(size = (990, 528), lw = 2.5, titlefontsize = 14, guidefontsize = 12,
    legendfontsize = 9, left_margin = 5Plots.mm, bottom_margin = 5Plots.mm,
    right_margin = 3Plots.mm, top_margin = 2Plots.mm, legend = :bottomright)

sig(r, p) = signal(r, p)
function speedplot(r, title; demand = true, kw...)
    plt = plot(sig(r, "plant.v_kmh")...; label = "plant.v_kmh", title,
        xlabel = "time [s]", ylabel = "speed [km/h]", kw...)
    demand && plot!(plt, sig(r, "demand.y")...; label = "demand.y", ls = :dash, color = :gray)
    plt
end
function twin!(plt, r, path; ylabel, color = :darkorange)
    ax = twinx(plt)
    plot!(ax, sig(r, path)...; label = path, ylabel, color, legend = :topright)
    plt
end
save(plt, name) = (savefig(plt, joinpath(OUT, name * ".png")); println("saved ", name))
report(r, name, paths...) = for p in paths
    t, y = sig(r, p)
    println(rpad(name, 28), rpad(p, 32), " final ", round(y[end], digits = 3),
        "  max ", round(maximum(y), digits = 3), "  min ", round(minimum(y), digits = 3))
end

r = L.Step01.CarStepTestTransient()
report(r, "step01", "plant.v_kmh")
save(plot(sig(r, "plant.v_kmh")...; label = "plant.v_kmh",
    title = "Step 1a — CarStepTestTransient: torque step at 50 s",
    xlabel = "time [s]", ylabel = "speed [km/h]"), "step01-step-test-plot")

r = L.Step03.CruiseLoopTransient()
report(r, "step03", "plant.v_kmh")
save(speedplot(r, "Step 3 — CruiseLoopTransient: P only, steady-state error"), "step03-p-plot")

function climbplot(r, title)
    l = @layout [a; b]
    p1 = plot(sig(r, "plant.v_kmh")...; label = "plant.v_kmh", ylabel = "speed [km/h]",
        title, legend = :topright)
    plot!(p1, sig(r, "demand.y")...; label = "demand.y", ls = :dash, color = :gray)
    p2 = plot(sig(r, "controller.y")...; label = "controller.y", ylabel = "",
        xlabel = "time [s]", legend = :topright)
    plot!(p2, sig(r, "controller.integrator.y")...; label = "controller.integrator.y")
    plot(p1, p2; layout = l, link = :x, size = (990, 640))
end
r6c = L.Step06c.CruiseClimbTransient()
report(r6c, "step06c", "plant.v_kmh", "controller.y", "controller.integrator.y")
r6d = L.Step06d.CruiseClimbTransient()
report(r6d, "step06d", "plant.v_kmh", "controller.y", "controller.integrator.y")
p6c = climbplot(r6c, "Step 6c — CruiseClimbTransient: the integrator winds up")
p6d = climbplot(r6d, "Step 6d — CruiseClimbTransient: clamping")
for i in 1:2
    lo = min(ylims(p6c[i])[1], ylims(p6d[i])[1]); hi = max(ylims(p6c[i])[2], ylims(p6d[i])[2])
    ylims!(p6c[i], lo, hi); ylims!(p6d[i], lo, hi)
end
save(p6c, "step06-windup-plot"); save(p6d, "step06-clamping-plot")

r7 = L.Step07.NoisyCruiseTransient()
report(r7, "step07 wd0", "plant.v_kmh", "controller.y")
r7k = rerun(r7, "controller.wd" => 1.0, "controller.xd0" => 0.0)
report(r7k, "step07 wd1", "plant.v_kmh", "controller.y", "controller.derivative.x")
q1 = plot(sig(r7k, "controller.y")...; label = "controller.y",
    title = "Step 7 — NoisyCruiseTransient, wd = 1", xlabel = "time [s]",
    ylabel = "torque command [N.m]", legend = :topright)
q0 = plot(sig(r7, "controller.y")...; label = "controller.y",
    title = "Step 7 — NoisyCruiseTransient, wd = 0", xlabel = "time [s]",
    ylabel = "torque command [N.m]", legend = :topright)
lo = min(ylims(q1)[1], ylims(q0)[1]); hi = max(ylims(q1)[2], ylims(q0)[2])
ylims!(q1, lo, hi); ylims!(q0, lo, hi)
save(q1, "step07-noisy-plot"); save(q0, "step07-wd0-plot")

function stacked(r, title, lower; lowlabel, xl = (0, 40))
    p1 = plot(sig(r, "plant.v_kmh")...; label = "plant.v_kmh", ylabel = "speed [km/h]", title,
        legend = :right, xlims = xl)
    plot!(p1, sig(r, "demand.y")...; label = "demand.y", ls = :dash, color = :gray)
    p2 = plot(sig(r, lower)...; label = lower, ylabel = lowlabel, xlabel = "time [s]",
        color = :darkorange, legend = :right, xlims = xl)
    plot(p1, p2; layout = @layout([a; b]), link = :x, size = (990, 640))
end
r = L.Step04.CruiseLoopTransient()
save(stacked(r, "Step 4 — CruiseLoopTransient: PI reaches the setpoint", "controller.integrator.y";
    lowlabel = "integrator state"), "step04-pi-plot")
r = L.Step05.CruiseLoopTransient()
save(stacked(r, "Step 5 — CruiseLoopTransient: PID", "controller.y";
    lowlabel = "torque command [N.m]"), "step05-pid-plot")

r = L.Step10.SlipCruiseTransient()
p1 = plot(sig(r, "plant.wheel_kmh")...; label = "plant.wheel_kmh", color = :darkorange,
    title = "Step 10 — SlipCruiseTransient: ice patch from 4 to 12 s", ylabel = "speed [km/h]",
    legend = :topright)
plot!(p1, sig(r, "plant.v_kmh")...; label = "plant.v_kmh", color = 1)
vspan!(p1, [4, 12]; color = :lightblue, alpha = 0.25, label = "ice")
p2 = plot(sig(r, "plant.v_kmh")...; label = "plant.v_kmh", color = 1, ylabel = "speed [km/h]",
    xlabel = "time [s]", legend = :topright)
plot!(p2, sig(r, "plant.wheel_kmh")...; label = "plant.wheel_kmh", color = :darkorange)
vspan!(p2, [4, 12]; color = :lightblue, alpha = 0.25, label = "")
ylims!(p2, 85, 115)
save(plot(p1, p2; layout = @layout([a; b]), link = :x, size = (990, 640)), "step10-ice-patch-plot")
