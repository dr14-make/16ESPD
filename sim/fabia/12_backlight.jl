# Run from repository root: julia --project=. sim/fabia/12_backlight.jl
# BSG_Kombi 0x470 Kl.58d: instrument illumination dimming, what the cluster sees when the
# parking/tail lights are switched on.
include("common.jl")
bench(; only = [0x470, 0x570]) do b, echo
    for pct in (0, 30, 70, 100, 0)
        b.dimming = pct
        step("backlight dimming $pct %", echo, 4)
    end
end
