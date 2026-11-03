using ModelingToolkit: Symbolics

const HUMAN_COMMANDS = Ref((0.0, 0.0, 0.0))

"Set the human driver's throttle and brake fractions and steering-wheel angle in radians."
function set_human_commands!(; throttle, brake, steer)
    HUMAN_COMMANDS[] = (Float64(throttle), Float64(brake), Float64(steer))
    return nothing
end

"Clear the human driver's command buffer to neutral."
function reset_human_commands!()
    HUMAN_COMMANDS[] = (0.0, 0.0, 0.0)
    return nothing
end

# Sampled time prevents symbolic evaluation from hoisting a buffer read to a constant.
_human_command(sampled_time, channel) = HUMAN_COMMANDS[][Int(channel)]
Symbolics.@register_symbolic _human_command(sampled_time::Real, channel::Real)::Real
