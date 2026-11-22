using Test
using VehicleSystemsComponents
using DyadInterface: symbolic_container
import ModelingToolkit

const H06 = VehicleSystemsComponents.HandsOn06
const H06CAN = VehicleSystemsComponents.Vehicle.Planar

@testset "HandsOn06 local safety wiring" begin
    source = read(joinpath(@__DIR__, "..", "dyad", "HandsOn06", "WiringNodes.dyad"), String)
    @test occursin("connect(accelerator_response.y, drive.accelerator_request)", source)
    @test occursin("connect(brake_response.y, ecu.brake_request)", source)
    @test !occursin("CanPedalNode", source)
    @test !occursin("CanBlendNode", source)
    # Count visible inherited top-level signal nets, excluding six mechanical nets.
    canvas = split(source, "partial component WiringStop"; limit = 2)[2]
    @test length(collect(eachmatch(r"connect\(", canvas))) - 6 == 19
    direct = read(joinpath(@__DIR__, "..", "dyad", "HandsOn06", "Step1PointToPointStop.dyad"), String)
    @test length(collect(eachmatch(r"connect\(", direct))) == 3
end

@testset "HandsOn06 topology exercises" begin
    for constructor in (H06.Step1PointToPointStop, H06.Step1IdealBusStop,
                        H06.IdealBusStop, H06.RegenMessageStop, H06.Step3CanStop,
                        H06.CanStop, H06.Can20msStop, H06.Can40msStop,
                        H06.Step4SlowCanStop)
        @test H06CAN.check_can(constructor(name = :exercise)) isa ModelingToolkit.System
    end
    for (constructor, fragment) in (
        (H06.Step1bMissingRegenStop, "nobody transmits"),
        (H06.Step2DuplicateSlotStop, "both transmit on slot 6"),
    )
        err = try
            H06CAN.check_can(constructor(name = :exercise))
            nothing
        catch e
            e
        end
        @test err isa ArgumentError
        @test occursin(fragment, sprint(showerror, err))
    end
end

@testset "HandsOn06 bitrate experiment" begin
    car = H06.CanStop(name = :exercise)
    fast = H06CAN.can_schedule(car; bitrate = 500_000)
    slow = H06CAN.can_schedule(car; bitrate = 250_000)
    @test fast.load > 0
    @test slow.load ≈ 2 * fast.load
    @test [f.response_time for f in slow.frames] ≈ 2 .* [f.response_time for f in fast.frames]
    @test fast.load ≈ 0.1345
    @test slow.load ≈ 0.269
    @test [f.response_time for f in fast.frames] ≈
        [0.28, 0.43, 0.58, 0.73, 0.88, 1.03, 1.18, 1.33, 1.48, 1.48] ./ 1000
end

const H06_STOP_DISTANCE_PINS = (
    CanStopTransient = 29.056,
    Can20msStopTransient = 30.018,
    Can40msStopTransient = 30.442,
)

function h06_stop_distance(run)
    m, sol = symbolic_container(run), run.sol
    @test string(sol.retcode) == "Success"
    ts = collect(0.5:0.005:6.0)
    speeds = sol(ts; idxs = m.car.bus.vx).u
    @test all(isfinite, speeds)
    stopped = findfirst(<(0.5), speeds)
    @test stopped !== nothing
    stopped === nothing && return NaN
    distance = sol(ts[stopped]; idxs = m.car.bus.x) - sol(0.5; idxs = m.car.bus.x)
    println("HandsOn06 ", nameof(typeof(run)), " distance=", distance)
    return distance
end

@testset "HandsOn06 local-loop stops and ideal equivalence" begin
    for (name, expected) in pairs(H06_STOP_DISTANCE_PINS)
        distance = h06_stop_distance(getproperty(H06, name)())
        @test isapprox(distance, expected; atol = 1e-3, rtol = 0)
    end
    direct = H06.Step1PointToPointStopTransient()
    ideal = H06.Step1IdealBusStopTransient()
    dd, di = h06_stop_distance(direct), h06_stop_distance(ideal)
    @test dd ≈ 28.185 atol = 1e-3
    @test di ≈ 28.185 atol = 1e-3
    @test isapprox(dd, di; atol = 1e-5, rtol = 0)
    md, mi = symbolic_container(direct), symbolic_container(ideal)
    ts = collect(0.01:0.005:6.0)
    @test maximum(abs.(direct.sol(ts; idxs = md.car.bus.vx).u .-
                       ideal.sol(ts; idxs = mi.car.bus.vx).u)) < 5e-5
    repaired = H06.RegenMessageStopTransient()
    mr = symbolic_container(repaired)
    @test h06_stop_distance(repaired) ≈ 28.185 atol = 1e-3
    @test isapprox(h06_stop_distance(repaired), di; atol = 1e-5, rtol = 0)
    @test maximum(abs.(repaired.sol(ts; idxs = mr.drive.regen_rx.y).u .-
                       repaired.sol(ts; idxs = mr.ecu.regen).u)) < 1e-8
end

@testset "HandsOn06 bus-in-loop counterexample" begin
    # These analyses remain library-owned; compare both architectures without
    # asserting a monotonic period/distance relation for sampled ABS.
    for name in (:CanBusBrake10msStop, :CanBusBrake20msStop, :CanBusBrake40msStop)
        @test isdefined(H06CAN, name)
        if isdefined(H06CAN, name)
            run = getproperty(H06CAN, name)()
            @test string(run.sol.retcode) == "Success"
        end
    end
    include("../scripts/lecture06_can_sweep.jl")
    rows, hash = Lecture06CanSweep.read_sweep()
    @test hash == Lecture06CanSweep.inputs_hash()
    expected = (("real", .01, 28.902, 28.617, 29.056),
                ("real", .02, 29.496, 28.982, 30.018),
                ("real", .04, 30.224, 30.017, 30.442),
                ("bus_brake", .01, 30.100, 28.789, 30.743),
                ("bus_brake", .02, 29.620, 29.320, 29.949),
                ("bus_brake", .04, 33.638, 31.792, 35.779))
    for (architecture, period, mean_pin, min_pin, max_pin) in expected
        distances = [r.distance for r in rows if r.architecture == architecture && r.period == period]
        @test sum(distances) / length(distances) ≈ mean_pin atol = 1e-3
        @test minimum(distances) ≈ min_pin atol = 1e-3
        @test maximum(distances) ≈ max_pin atol = 1e-3
    end
end
