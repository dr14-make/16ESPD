using Test
using VehicleSystemsComponents
using DyadInterface: symbolic_container

const _H3_TCS = VehicleSystemsComponents.HandsOn03

function brake_energy(run, model)
    ts = range(0.0, 10.0, length = 10001)
    tau_f = run.sol(ts, idxs = model.car.wheel.caliper_f.tau_friction).u
    tau_r = run.sol(ts, idxs = model.car.wheel.caliper_r.tau_friction).u
    omega = run.sol(ts, idxs = model.car.wheel.inertia.w).u
    power = (tau_f .+ tau_r) .* omega
    return sum((power[1:end-1] .+ power[2:end]) .* 0.5 .* diff(ts))
end

@testset "Hands-on 03 bonus: brake and engine TCS" begin
    settings = ((:off, 0.0, 0.0), (:brake, 1.0, 0.0),
                (:engine, 0.0, 1.0), (:both, 1.0, 1.0))
    runs = Dict(name => _H3_TCS.TCSStartTransient(brake_enabled = brake,
                                                  engine_enabled = engine)
                for (name, brake, engine) in settings)
    models = Dict(name => symbolic_container(runs[name]) for (name, _, _) in settings)

    value(name, variable) = runs[name].sol(10.0, idxs = variable(models[name]))
    speed(name) = value(name, m -> m.car.body.mass.v)
    slip(name) = value(name, m -> m.car.wheel.kappa)
    rpm(name) = value(name, m -> m.car.flywheel.w) * 30 / pi
    ratio(name) = value(name, m -> m.car.variator.ratio)
    energy = Dict(name => brake_energy(runs[name], models[name]) for (name, _, _) in settings)

    @info "TCS standing starts at 10 s" results =
        [(name, speed(name), slip(name), rpm(name), ratio(name), energy[name])
         for (name, _, _) in settings]

    @test all(string(run.sol.retcode) == "Success" for run in values(runs))
    @test speed(:brake) > speed(:off)
    @test speed(:engine) > speed(:brake)
    @test slip(:off) > 1.0

    for name in (:engine, :both)
        ts = range(7.0, 10.0, length = 3001)
        kappa = runs[name].sol(ts, idxs = models[name].car.wheel.kappa).u
        @test maximum(abs.(kappa .- 0.04)) < 0.02
        @test ratio(name) ≈ 12.0 atol = 0.01
    end

    @test energy[:off] < 1.0
    @test energy[:engine] < 1.0
    @test energy[:brake] > energy[:both] > 0.0
end
