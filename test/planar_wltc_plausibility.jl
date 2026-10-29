# The Lecture 3 planar car on WLTC: the bench every Lecture 4 and 5 car runs on. Road load reaches
# the chassis through `PlanarRoadLoad`, so at constant speed the car must need exactly the
# longitudinal car's road load, and over the cycle it must drive the trace's distance and hold
# still at every stop.

using DyadInterface: symbolic_container

const _PL = VehicleSystemsComponents.Vehicle.Planar

# `Vehicle.RoadLoad` on the flat at 1500 kg, the planar car's mass.
_road_load(v) = 0.5 * 1.2 * 0.63 * v^2 + 0.012 * 1500 * 9.80665
const _radius = 0.31

function _wltc_traces(run)
    m = symbolic_container(run)
    s = run.sol
    return (; t = s.t, ref = s[m.trace.y], v_kmh = 3.6 .* s[m.car.bus.vx], x = s[m.car.bus.x],
        y = s[m.car.bus.y], drive = s[m.to_drive.y], brake = s[m.to_brake.y])
end

_trapz(t, y) = sum((y[1:end-1] .+ y[2:end]) ./ 2 .* diff(t))

# Each stretch where the trace is zero for at least `min_len` seconds, as (start, stop) times.
function _stops(t, ref; min_len = 2.0)
    windows = Tuple{Float64,Float64}[]
    i = 1
    while i <= length(t)
        if ref[i] == 0
            j = i
            while j < length(t) && ref[j+1] == 0
                j += 1
            end
            t[j] - t[i] >= min_len && push!(windows, (t[i], t[j]))
            i = j + 1
        else
            i += 1
        end
    end
    return windows
end

@testset "Planar WLTC: constant-speed road load matches the longitudinal car" begin
    for v_set in (50.0, 100.0)
        run = _PL.PlanarCruiseTransient(; v_set)
        m = symbolic_container(run)
        s = run.sol
        @test string(s.retcode) == "Success"
        v = s[m.car.bus.vx][end]
        @test 3.6 * v ≈ v_set atol = 0.01
        # The adapter applies the longitudinal law at the sensed speed ...
        @test s[m.roadload.F][end] ≈ _road_load(v) rtol = 1e-9
        # ... and at steady state the front axle's drive torque carries all of it.
        @test 2 * s[m.driver.y][end] / _radius ≈ _road_load(v) rtol = 1e-6
        @test s[m.to_brake.y][end] == 0
    end
end

@testset "Planar WLTC: road load resolved in a chassis turned off the world axis" begin
    # A chassis heading 0.5 rad off the world x axis coasts down from 30 m/s beside the
    # longitudinal car's VehicleBody of the same 1500 kg; measured agreement 2.4e-13 m/s.
    run = _PL.PlanarRoadLoadTransient()
    m = symbolic_container(run)
    s = run.sol
    @test string(s.retcode) == "Success"
    ts = range(0, 60, length = 601)
    v_planar = s(ts, idxs = m.vel.v_x).u
    @test v_planar ≈ s(ts, idxs = m.reference.mass.v).u atol = 1e-9
    # It slows along its heading and nowhere else.
    @test maximum(abs, s(ts, idxs = m.vel.v_y).u) < 1e-9
    @test maximum(abs, s(ts, idxs = m.body.phi).u .- 0.5) < 1e-9
    @test atan(s(60.0, idxs = m.body.r[2]), s(60.0, idxs = m.body.r[1])) ≈ 0.5 atol = 1e-9
    @test s[m.roadload.F][1] ≈ _road_load(30.0) rtol = 1e-12
    @test v_planar[end] < 16.0
end

@testset "Planar WLTC: distance and standstill" begin
    run = _PL.PlanarWLTCTransient()
    @test string(run.sol.retcode) == "Success"
    @test run.sol.t[end] == 1800.0
    (; t, ref, v_kmh, x, y, drive, brake) = _wltc_traces(run)
    trace_km = _trapz(t, ref) / 3600
    @test trace_km ≈ 23.27 rtol = 1e-3
    # Acceptance: within 1 % of the cycle; measured 3e-5 of the trace.
    @test x[end] / 1000 ≈ 23.27 rtol = 0.01
    @test x[end] / 1000 ≈ trace_km rtol = 5e-4
    # Straight line: no lateral drift.
    @test maximum(abs, y) < 1e-6
    # Drive and brake come from one signal split by sign, never both at once.
    @test !any((drive .> 0) .& (brake .> 0))
    stops = _stops(t, ref)
    @test length(stops) == 8
    for (t0, t1) in stops
        held = (t .>= t0 + 1.0) .& (t .<= t1)
        # One second into every stop the car is held, not creeping.
        @test maximum(abs, v_kmh[held]) < 1e-3
    end
    # A friction brake cannot reverse the car.
    @test minimum(v_kmh) > -1e-3

    # Small maximum step: more Jacobians evaluated near standstill, same run.
    fine = _PL.PlanarWLTCTransient(dtmax = 0.05)
    @test string(fine.sol.retcode) == "Success"
    @test _wltc_traces(fine).x[end] ≈ x[end] rtol = 1e-5
end

@testset "Planar WLTC: an exact-rest start hits MultibodyComponents.jl#185" begin
    # The bench starts the wheels `dv_wheel` ahead of the body. From exact rest every slip speed
    # is zero and the joint's Jacobian is NaN at t = 0. When this passes, the upstream fix has
    # shipped and `dv_wheel` can go.
    rest = _PL.PlanarWLTCTransient(stop = 20.0,
        model = _PL.PlanarWLTC(name = :PlanarWLTC, dv_wheel = 0.0))
    @test_broken string(rest.sol.retcode) == "Success"
end
