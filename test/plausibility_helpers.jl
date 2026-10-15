# Derived metrics shared by the plausibility suites. Each takes a time vector and a signal.

"""
    rise_time(t, y, frac; t0 = first(t)) -> Float64

Time after `t0` at which `y` first covers `frac` of its change from `y(t0)` to its final value,
in either direction. `frac = 0.632` gives a first-order time constant.
"""
function rise_time(t, y, frac; t0 = first(t))
    i0 = findfirst(>=(t0), t)
    y0, y1 = y[i0], y[end]
    target = y0 + frac * (y1 - y0)
    i = findfirst(k -> k >= i0 && sign(y1 - y0) * (y[k] - target) >= 0, eachindex(y))
    # Interpolate inside the crossing step so the result does not depend on the save grid.
    i == i0 && return 0.0
    w = (target - y[i-1]) / (y[i] - y[i-1])
    return t[i-1] + w * (t[i] - t[i-1]) - t0
end

"""
    max_rate(t, y) -> Float64

Largest absolute slope of `y` between consecutive samples.
"""
max_rate(t, y) = maximum(abs.(diff(y) ./ diff(t)))

"""
    cycle_frequency(t, y) -> Float64

Mean frequency of the oscillation in `y`, from the zero crossings of `y` minus its mean.
"""
function cycle_frequency(t, y)
    d = y .- sum(y) / length(y)
    crossings = [t[k] for k in 2:length(d) if signbit(d[k-1]) != signbit(d[k])]
    length(crossings) < 3 && return 0.0
    return (length(crossings) - 1) / 2 / (crossings[end] - crossings[1])
end
