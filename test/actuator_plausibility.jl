using DyadInterface: symbolic_container

const Lecture2 = VehicleSystemsComponents.Lecture2
const RHO_FUEL = 740.0
const LIFT_STOP = 0.05e-3
const T_START = 0.5e-3

function injector_run(; t_pulse = 3e-3, kwargs...)
    result = Lecture2.InjectorPulseTransient(; t_pulse, stop = T_START + t_pulse + 3e-3, kwargs...)
    model = symbolic_container(result)
    sol = result.sol
    return (t = sol.t, i = sol[model.injector.solenoid.i], lift = sol[model.injector.lift],
            mdot = sol[model.injector.mdot_f], fuel = sol[model.fuel_mass.y][end],
            v_switch = sol[model.transistor.v], t_pulse, retcode = sol.retcode)
end

"""
    fuel_line(U, pulses) -> (; offset, q_cm3_min, residual)

Straight line through fuel per pulse against pulse width: its zero-fuel intercept is the dead
time the ECU adds to every pulse, its slope the flow with the needle open.
"""
function fuel_line(U, pulses)
    fuel = [injector_run(; U_batt = U, t_pulse = tp).fuel for tp in pulses]
    X = hcat(ones(length(pulses)), pulses)
    a, b = X \ fuel
    return (offset = -a / b, q_cm3_min = b / RHO_FUEL * 60e6,
            residual = maximum(abs.(X * [a, b] .- fuel) ./ fuel))
end

function throttle_run(; kwargs...)
    result = Lecture2.ThrottlePedalStepTransient(; kwargs...)
    model = symbolic_container(result)
    sol = result.sol
    return (t = sol.t, u = sol[model.etc.u_thr], cmd = sol[model.command.y],
            i = sol[model.etc.i_motor], phi = sol[model.etc.phi], retcode = sol.retcode)
end

function sensor_sweep(; kwargs...)
    result = Lecture2.ThrottleSensorSweepTransient(; kwargs...)
    model = symbolic_container(result)
    sol = result.sol
    return (V1 = sol[model.tps.V1], V2 = sol[model.tps.V2], sum = sol[model.track_sum.y])
end

@testset "Fuel injector against the EV14 anchors (task 4)" begin
    nominal = injector_run()
    @test string(nominal.retcode) == "Success"

    @testset "needle lift saturates at the armature stop" begin
        @test isapprox(maximum(nominal.lift), LIFT_STOP; rtol = 0.02)
        held = (nominal.t .> T_START + 1.5e-3) .& (nominal.t .< T_START + nominal.t_pulse)
        @test all(x -> isapprox(x, LIFT_STOP; rtol = 0.002), nominal.lift[held])
    end

    @testset "static flow at 3 bar" begin
        @test isapprox(maximum(nominal.mdot) / RHO_FUEL * 60e6, 146.0; rtol = 0.05)
    end

    @testset "pickup kink: the current falls while the needle moves" begin
        on = T_START .< nominal.t .< T_START + nominal.t_pulse
        di = diff(nominal.i[on])
        @test any(<(0), di)
        dent = findfirst(<(0), di)
        @test nominal.lift[on][dent] > 0
    end

    @testset "dead time is the offset of a straight fuel line" begin
        line_14 = fuel_line(14.0, collect(2e-3:1e-3:8e-3))
        @test 0.6e-3 <= line_14.offset <= 1.0e-3
        @test line_14.residual < 0.02
        @test isapprox(line_14.q_cm3_min, 146.0; rtol = 0.05)
        # At 8 V the needle needs about 2.8 ms to open, so its straight line starts there.
        line_8 = fuel_line(8.0, collect(4e-3:1e-3:8e-3))
        @test 1.5e-3 <= line_8.offset <= 2.5e-3
        @test line_8.residual < 0.02
    end

    @testset "flyback clamps at the driver's Zener" begin
        @test 60.0 <= maximum(nominal.v_switch) <= 80.0
        @test injector_run(t_pulse = 3e-3).i[end] < 0.01
    end
end

@testset "Throttle position sensor plausibility" begin
    healthy = sensor_sweep()
    @test all(v -> 0.45 <= v <= 4.55, healthy.V1)
    @test all(v -> 0.45 <= v <= 4.55, healthy.V2)
    @test all(s -> abs(s - 5.0) < 0.05, healthy.sum)
    worn = sensor_sweep(R_wiper1 = 5e4)
    @test any(s -> abs(s - 5.0) > 0.25, worn.sum)
end

@testset "Electronic throttle position loop" begin
    run = throttle_run()
    @test string(run.retcode) == "Success"
    u_0 = run.u[1]
    step = (run.t .>= 0.1) .& (run.t .<= 0.6)
    t, u = run.t[step], run.u[step]
    rise = t[findfirst(>=(u_0 + 0.9 * (0.6 - u_0)), u)] - t[findfirst(>=(u_0 + 0.1 * (0.6 - u_0)), u)]
    @test rise < 0.1
    @test maximum(u) < 0.6 + 0.05 * (0.6 - u_0)
    @test abs(run.u[end] - 0.1) < 0.002
    @test maximum(abs, run.i) <= 14.0 / 1.5 + 1e-6

    @testset "limp-home smoothing does not set the answer" begin
        # Ramping to 0.03 crosses limp home, where the spring preload changes sign.
        coarse = throttle_run(u_end = 0.03)
        fine = throttle_run(u_end = 0.03, eps_lh = 0.0035 / 2)
        travel = 0.6 - 0.03
        @test maximum(abs.(coarse.u .- fine.u)) < 0.02 * travel
        @test abs(coarse.u[end] - fine.u[end]) < 0.02 * travel
    end
end
