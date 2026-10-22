# Hands-on 03 checkpoints.

const _V = VehicleSystemsComponents.Vehicle

@testset "Hands-on 03 braking_distance" begin
    # 25 m/s, 0.5 s of coasting at constant speed, then 8 m/s² to rest: 25²/16 = 39.0625 m.
    t = collect(range(0, 4, length = 400_001))
    v = [ti < 0.5 ? 25.0 : max(25.0 - 8.0 * (ti - 0.5), 0.0) for ti in t]
    s = [0.0; cumsum((v[1:end-1] .+ v[2:end]) ./ 2 .* diff(t))]
    # Stops counting at 0.5 m/s, (0.5)²/16 short of the full stop.
    @test _V.braking_distance(t, s, v) ≈ 25^2 / 16 - 0.5^2 / 16 atol = 1e-3
    @test _V.braking_distance(t, s, v; v_stop = 1e-9) ≈ 25^2 / 16 atol = 1e-3
    # Counted from t_brake: starting 0.25 s earlier adds 0.25 s at 25 m/s.
    @test _V.braking_distance(t, s, v; t_brake = 0.25) - _V.braking_distance(t, s, v) ≈ 6.25 atol = 1e-6
    @test_throws ErrorException _V.braking_distance(t[1:1000], s[1:1000], v[1:1000])
end
