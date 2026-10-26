import DyadInterface

"""
    braking_distance(result; t_brake = 0.5, v_stop = 0.5) -> Float64
    braking_distance(t, s, v; t_brake = 0.5, v_stop = 0.5) -> Float64

Distance the car travels from the brake application at `t_brake` until its speed first falls
below `v_stop`, the definition the Lecture 3 notebook, hands-on and tests share.

`result` is a transient analysis result (or its `sol`) whose model has a `body.mass` holding
position and speed. The second form takes the time, position and speed traces directly. Errors
with the final speed when the run ends before the car stops: lengthen `stop` and run again.
"""
function braking_distance(result; t_brake = 0.5, v_stop = 0.5)
    model = DyadInterface.symbolic_container(result)
    sol = hasproperty(result, :sol) ? result.sol : result
    s_brake = sol(t_brake, idxs = model.body.mass.s)
    return braking_distance(sol.t, sol[model.body.mass.s], sol[model.body.mass.v];
        t_brake, v_stop, s_brake)
end

function braking_distance(t, s, v; t_brake = 0.5, v_stop = 0.5, s_brake = nothing)
    if isnothing(s_brake)
        k = clamp(searchsortedlast(t, t_brake), 1, length(t) - 1)
        s_brake = s[k] + (t_brake - t[k]) / (t[k+1] - t[k]) * (s[k+1] - s[k])
    end
    i_stop = findfirst(i -> t[i] >= t_brake && v[i] < v_stop, eachindex(t))
    isnothing(i_stop) &&
        error("the car is still at $(round(v[end]; digits = 2)) m/s when the run ends; lengthen `stop`")
    return s[i_stop] - s_brake
end
