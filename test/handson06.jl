using Test
using VehicleSystemsComponents
using DyadInterface: symbolic_container
import ModelingToolkit

const H06 = VehicleSystemsComponents.HandsOn06
const H06CAN = VehicleSystemsComponents.Vehicle.Planar
@testset "HandsOn06 visible wire counts" begin
    for (name, expected) in (("Step1PointToPointStop", 23), ("Step1IdealBusStop", 17))
        source = read(joinpath(@__DIR__, "..", "dyad", "HandsOn06", name * ".dyad"), String)
        links = collect(eachmatch(r"connect\(([^)]*)\)\s*\{\^(\w+)\}", source))
        @test length(links) - 6 == expected
    end
end



@testset "HandsOn06 topology exercises" begin
    for constructor in (H06.Step1PointToPointStop, H06.Step1IdealBusStop,
                        H06.IdealBusStop, H06.PedalMessageStop, H06.Step3CanStop,
                        H06.CanStop, H06.Can20msStop, H06.Can40msStop,
                        H06.Step4SlowCanStop)
        @test H06CAN.check_can(constructor(name = :exercise)) isa ModelingToolkit.System
    end
    for (constructor, fragment) in (
        (H06.Step1bMissingPedalStop, "nobody transmits"),
        (H06.Step2DuplicateSlotStop, "both transmit on slot 12"),
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
    @test fast.load ≈ 0.1495
    @test slow.load ≈ 0.299
    response_ms = [0.28, 0.43, 0.58, 0.73, 0.88, 1.03,
                   1.18, 1.33, 1.48, 1.63, 1.78, 1.78]
    @test [f.response_time for f in fast.frames] ≈ response_ms ./ 1000
    @test [f.response_time for f in slow.frames] ≈ 2 .* response_ms ./ 1000
end

# Library checkpoints use a 5 ms crossing grid, dtmax=0.005 and reltol=1e-7.
const H06_STOP_DISTANCE_PINS = (
    CanStopTransient = 30.742977497,
    Can20msStopTransient = 29.320221625,
    Can40msStopTransient = 33.933638581,
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

@testset "HandsOn06 measured checkpoints" begin
    for (name, expected) in pairs(H06_STOP_DISTANCE_PINS)
        run = getproperty(H06, name)()
        @test isapprox(h06_stop_distance(run), expected; atol = 1e-3, rtol = 0)
    end
    direct = H06.Step1PointToPointStopTransient()
    ideal = H06.Step1IdealBusStopTransient()
    dd, di = h06_stop_distance(direct), h06_stop_distance(ideal)
    @test dd ≈ 28.184672610 atol = 1e-3
    @test di ≈ 28.184675576 atol = 1e-3
    @test isapprox(dd, di; atol = 1e-5, rtol = 0)
    md, mi = symbolic_container(direct), symbolic_container(ideal)
    # The clock callback saves a duplicate t=0; use the continuous held history after its first tick.
    ts = collect(0.01:0.005:6.0)
    @test maximum(abs.(direct.sol(ts; idxs = md.car.bus.vx).u .-
                       ideal.sol(ts; idxs = mi.car.bus.vx).u)) < 5e-5
    repaired = H06.PedalMessageStopTransient()
    mr = symbolic_container(repaired)
    @test h06_stop_distance(repaired) ≈ 28.184673581 atol = 1e-3
    @test maximum(abs.(repaired.sol(ts; idxs = mr.pedal_rx.y).u .-
                       repaired.sol(ts; idxs = mr.torque_response.y).u)) < 1e-8
end
