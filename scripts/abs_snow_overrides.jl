# Parameter-override runs at road_mu = 0.3 behind docs/abs-efficiency-research.md.
# Run from the repo root: julia +dyad-3.4.0 --project=. scripts/abs_snow_overrides.jl
using VehicleSystemsComponents, ModelingToolkit
using UUIDs
const OT = Base.require(Base.PkgId(UUID("b1df2697-797e-41e3-8120-5422d3b24e4a"), "OrdinaryDiffEqTsit5"))
const Tsit5 = OT.Tsit5
const solve = OT.solve
const V = VehicleSystemsComponents.Vehicle
const H = VehicleSystemsComponents.HandsOn03
function dist(build, mu; ov = Dict(), stop = 25.0)
    @named m = build(road_mu = mu)
    sys = mtkcompile(m)
    pmap = [getproperty_path(sys, k) => v for (k, v) in ov]
    prob = ODEProblem(sys, pmap, (0.0, stop))
    sol = solve(prob, Tsit5(); dtmax = 1e-3)
    d = V.braking_distance(sol.t, sol[sys.body.mass.s], sol[sys.body.mass.v])
    return d
end
function getproperty_path(sys, path::String)
    x = sys
    for p in split(path, '.')
        x = getproperty(x, Symbol(p))
    end
    x
end
cases = [
  ("locked", H.PedalStop, Dict()),
  ("locked muS0.9", H.PedalStop, Dict("wheel.mu_S" => 0.9)),
  ("locked muS0.95 sA0.15 sS0.5", H.PedalStop, Dict("wheel.mu_S" => 0.95, "wheel.sAdhesion" => 0.15, "wheel.sSlide" => 0.5)),
  ("wheelonly", H.ABSStopWheelOnly, Dict()),
  ("wheelonly rates x0.3", H.ABSStopWheelOnly, Dict("abs.k_inc" => 0.3*1.16e7, "abs.k_dec" => 0.3*5.8e7)),
  ("wheelonly a_minus x0.3", H.ABSStopWheelOnly, Dict("abs.a_minus" => 0.3*12, "abs.a_plus" => 0.3*3)),
  ("wheelonly rates+a x0.3", H.ABSStopWheelOnly, Dict("abs.k_inc" => 0.3*1.16e7, "abs.k_dec" => 0.3*5.8e7, "abs.a_minus" => 0.3*12, "abs.a_plus" => 0.3*3)),
  ("wheelonly lambda_1 0.08", H.ABSStopWheelOnly, Dict("abs.lambda_1" => 0.08)),
  ("wheelonly valve 10ms", H.ABSStopWheelOnly, Dict("valve_f.T_v" => 0.01, "valve_r.T_v" => 0.01)),
  ("wheelonly a_ref 2.4", H.ABSStopWheelOnly, Dict("est.a_ref" => 2.4)),
  ("wheelonly muS0.9", H.ABSStopWheelOnly, Dict("wheel.mu_S" => 0.9)),
  ("wheelonly muS0.95 sA0.15 sS0.5", H.ABSStopWheelOnly, Dict("wheel.mu_S" => 0.95, "wheel.sAdhesion" => 0.15, "wheel.sSlide" => 0.5)),
  ("slipABS", H.ABSStop, Dict()),
]
for (name, b, ov) in cases
    try
        d = dist(b, 0.3; ov = ov)
        println(rpad(name, 36), round(d, digits = 2)); flush(stdout)
    catch e
        println(rpad(name, 36), "ERROR ", sprint(showerror, e)[1:min(end, 300)]); flush(stdout)
    end
end
