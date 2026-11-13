using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

# Events need MTK callbacks, which have no Dyad relation syntax.
function CCCVCharger(; name, I_cc = 143.0, V_max = 96 * 4.20,
        I_cut = (40000 / 350) / 50)
    @parameters I_cc=I_cc V_max=V_max I_cut=I_cut
    @named p = VehicleSystemsComponents.__Dyad__Pin()
    @named n = VehicleSystemsComponents.__Dyad__Pin()
    @variables current(t) [output = true]
    @variables v(t) regulator(t)=0.0
    @variables phase(t)=1.0 [irreducible = true, output = true]
    eqs = [v ~ p.v - n.v,
        p.i ~ -current, n.i ~ current,
        current ~ ifelse(phase < 2.5, regulator, 0.0),
        D(regulator) ~ (min(I_cc, max(0.0, 100000.0 * (V_max - v))) - regulator) / 0.001,
        D(phase) ~ 0.0]
    events = [
        ModelingToolkit.SymbolicContinuousCallback(
            [v ~ V_max - I_cc / 100000.0 - 0.000001],
            (f = (m, o, c, i) -> (; phase = 2.0), modified = (; phase));
            affect_neg = nothing),
        ModelingToolkit.SymbolicContinuousCallback(
            [ifelse(phase > 1.5, regulator - I_cut, I_cc) ~ 0.0],
            (f = (m, o, c, i) -> (; phase = 3.0), modified = (; phase)))]

    System(eqs, t, [current, phase, v, regulator], [I_cc, V_max, I_cut];
        name, systems = [p, n], continuous_events = events)
end
