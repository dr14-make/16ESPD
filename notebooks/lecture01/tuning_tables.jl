"""
The three heuristic PID tuning tables of `materials/ControlTheory/tuning_methods.pdf`
("Standard PID Tuning Methods", tbco 2/17/2012), transcribed. Page and table references in the
docstrings below point at that document.

Notebook 08 applies these to the car, and `test/tuning_tables.jl` checks every coefficient
against values computed by hand from the same document. Transcription is where a silent error
would hide, so the table a lecture runs on is the table the test suite guards.
"""

module TuningTables

export cohen_coon, ziegler_nichols, tyreus_luyben

"""
    check_positive(name, x)

All three tables divide by their arguments, so a non-positive or non-finite input yields
`Inf`/`NaN` gains that look like numbers in a plot. Reject them at the boundary instead.
"""
function check_positive(name::AbstractString, x::Real)
    (isfinite(x) && x > 0) ||
        throw(ArgumentError("$name must be a positive finite number, got $x"))
    return x
end

"""
    cohen_coon(K, tau, theta) -> (k, Ti, Td)

Cohen-Coon PID gains for a FOPTD plant with steady-state gain `K`, time constant `tau` and
dead time `theta`. Table 1, p.2, PID row, with `r = theta/tau` (p.1, Step 2; the document
writes the dead time as `tau_del`):

    k  = (1/(r*K)) * (4/3 + r/4)
    Ti = theta * (32 + 6r) / (13 + 8r)
    Td = theta * 4 / (11 + 2r)

`k` is returned in the reciprocal units of `K`: feeding a step test read in km/h per N.m
gives a gain in N.m per km/h, which is the unit the whole lecture's control loop uses.

Cohen-Coon is a dead-time method — `k` grows without bound as `theta` goes to zero, which is
why the plant carries an explicit transport delay.
"""
function cohen_coon(K::Real, tau::Real, theta::Real)
    check_positive("K", K)
    check_positive("tau", tau)
    check_positive("theta", theta)

    r = theta / tau
    k = (1 / (r * K)) * (4 / 3 + r / 4)
    Ti = theta * (32 + 6r) / (13 + 8r)
    Td = theta * 4 / (11 + 2r)
    return (k, Ti, Td)
end

"""
    ziegler_nichols(Ku, Pu) -> (k, Ti, Td)

Ziegler-Nichols PID gains from the ultimate gain `Ku` and ultimate period `Pu` measured at
sustained oscillation under pure proportional control. Table 2, p.2, PID row:

    k = Ku/1.7,  Ti = Pu/2,  Td = Pu/8
"""
function ziegler_nichols(Ku::Real, Pu::Real)
    check_positive("Ku", Ku)
    check_positive("Pu", Pu)
    return (Ku / 1.7, Pu / 2, Pu / 8)
end

"""
    tyreus_luyben(Ku, Pu) -> (k, Ti, Td)

Tyreus-Luyben PID gains from the same `Ku` and `Pu` pair as Ziegler-Nichols. Table 2, p.3,
PID row:

    k = Ku/2.2,  Ti = 2.2*Pu,  Td = Pu/6.3

Deliberately more conservative than Ziegler-Nichols at the same measurement: lower gain and a
much slower integrator.
"""
function tyreus_luyben(Ku::Real, Pu::Real)
    check_positive("Ku", Ku)
    check_positive("Pu", Pu)
    return (Ku / 2.2, 2.2 * Pu, Pu / 6.3)
end

end # module TuningTables

