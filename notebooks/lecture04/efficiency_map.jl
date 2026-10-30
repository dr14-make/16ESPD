"""
The combined (machine + converter) efficiency map of build steps 1–2, swept on the library's
dyno bench `Vehicle.Electric.ConverterTransient`.

Notebook `01-efficiency-map.pluto.jl` draws it, and `test/efficiency_map_plausibility.jl`
checks the lecture plan's three efficiency bands on the same sweep, so the map the deck shows is
the map the test suite guards.
"""
module EfficiencyMap

using VehicleSystemsComponents: Vehicle
using DyadInterface: symbolic_container

export RPM_MAX, CURRENTS, ramp_line, combined_eta, efficiency_map, eta_at

# The machine speed at the car's 144 km/h top speed (lecture plan, reality anchors).
const RPM_MAX = 10100.0

# Output currents of the sweep, dense near zero where the near-zero-torque band lives; the
# largest is the converter's limit.
const CURRENTS = let c = [0.0, 0.5, 1, 1.5, 2, 3, 4, 5, 6, 8, 10, 12, 15, 20, 25, 30, 40, 50,
        60, 70, 80, 100, 120, 140, 160, 180, 200, 230, 260, 290, 315, 332.2]
    vcat(-reverse(c[2:end]), c)
end

"""
    ramp_line(I, rpm; V = 350.0, rpm_end = RPM_MAX)

One dyno ramp of `ConverterTransient` from standstill to `rpm_end`, asked for output current
`I`, read at the speeds `rpm` as steady operating points: shaft torque, DC-link power, field and
duty. The current is held and the field and duty are algebraic, so the only transient along the
ramp is the rotor's `J dω/dt`, which a steady operating point delivers at the shaft instead.
"""
function ramp_line(I, rpm; V = 350.0, rpm_end = RPM_MAX)
    r = Vehicle.Electric.ConverterTransient(; I_ref = I, V, rpm_start = 0.0, rpm_end)
    string(r.sol.retcode) == "Success" || error("ramp at $I A: $(r.sol.retcode)")
    m = symbolic_container(r)
    M, C = m.machine, m.converter
    # `TestConverter` ramps over 100 s, starting at t = 1 s.
    w_dot = rpm_end * pi / 30 / 100
    at(x) = r.sol(1 .+ rpm ./ rpm_end .* 100, idxs = x).u
    return (; I, tau = at(M.tau) .+ r.sol.ps[M.J] * w_dot, P_in = at(C.P_in),
        field = at(C.field), d = at(C.d))
end

"""
    combined_eta(P_mech, P_in)

Combined efficiency from shaft power and DC-link power: shaft out over link in while motoring,
link out over shaft in while generating. Where the two do not flow the same way the losses
take all of the power and no efficiency is defined; it is reported as 0.
"""
function combined_eta(P_mech, P_in)
    P_mech > 0 && P_in > 0 && return P_mech / P_in
    P_mech < 0 && P_in < 0 && return P_in / P_mech
    return 0.0
end

"""
    efficiency_map(; V = 350.0, rpm = 50.0:50.0:RPM_MAX, torque = -330.0:2.0:330.0)

Sweep the machine and converter over `CURRENTS`, one dyno ramp per current, and resample onto
the `torque` grid at every speed. At one speed the DC-link power is smooth and monotonic in
shaft torque, so it is interpolated linearly in torque and the efficiency computed from it.
`eta` and `P_in` are indexed `[torque, rpm]`; torques no current reaches are NaN.
"""
function efficiency_map(; V = 350.0, rpm = 50.0:50.0:RPM_MAX, torque = -330.0:2.0:330.0)
    lines = [ramp_line(I, collect(rpm); V) for I in CURRENTS]
    P_in = fill(NaN, length(torque), length(rpm))
    eta = fill(NaN, length(torque), length(rpm))
    for j in eachindex(rpm)
        taus, Ps = [l.tau[j] for l in lines], [l.P_in[j] for l in lines]
        issorted(taus) || error("torque not monotonic in current at $(rpm[j]) rpm")
        for (i, T) in enumerate(torque)
            k = searchsortedfirst(taus, T)
            (k == 1 || k > length(taus)) && continue
            f = (T - taus[k - 1]) / (taus[k] - taus[k - 1])
            P_in[i, j] = Ps[k - 1] + f * (Ps[k] - Ps[k - 1])
            eta[i, j] = combined_eta(T * rpm[j] * pi / 30, P_in[i, j])
        end
    end
    return (; V, rpm, torque, P_in, eta, lines, tau_max = last(lines).tau,
        tau_min = first(lines).tau)
end

"""
    eta_at(map, n, T)

Combined efficiency of a swept `map` at `n` rpm and `T` N·m, from its DC-link power
interpolated bilinearly.
"""
function eta_at(map, n, T)
    (; rpm, torque, P_in) = map
    j = clamp(searchsortedlast(rpm, n), 1, length(rpm) - 1)
    i = clamp(searchsortedlast(torque, T), 1, length(torque) - 1)
    a = (n - rpm[j]) / (rpm[j + 1] - rpm[j])
    b = (T - torque[i]) / (torque[i + 1] - torque[i])
    P = (1 - a) * (1 - b) * P_in[i, j] + a * (1 - b) * P_in[i, j + 1] +
        (1 - a) * b * P_in[i + 1, j] + a * b * P_in[i + 1, j + 1]
    return combined_eta(T * n * pi / 30, P)
end

end
