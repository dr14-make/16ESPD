# BSG_Kombi 0x470: turn indicators, blinked by the sender at ~1.5 Hz.
include("common.jl")
bench(; only = [0x470, 0x570]) do b, echo
    b.left = true;  step("left indicator blinking", echo, 5)
    b.left = false; b.right = true; step("right indicator blinking", echo, 5)
    b.right = false; b.hazard = true; step("hazard (both) blinking", echo, 5)
    b.hazard = false; step("all indicators off", echo, 3)
end
