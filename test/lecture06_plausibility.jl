# Lecture 6 multiplexing benches: each receiver must recover its own sender's message from the
# shared wire, and only that one.

using DyadInterface: symbolic_container

const _L6 = VehicleSystemsComponents.Lecture6

@testset "Lecture 6 frequency division" begin
    r = _L6.FrequencyDivisionBenchTransient()
    s, m = r.sol, symbolic_container(r)
    @test string(s.retcode) == "Success"
    ts = 0.5:0.001:4.0
    # The Butterworth filter's group delay at these message frequencies, sqrt(2) / (2π · 10 Hz).
    lag = sqrt(2) / (2π * 10.0)
    for (message, recovered) in ((m.speed.y, m.filter_speed.y), (m.engine.y, m.filter_engine.y))
        y = s(ts; idxs = recovered).u
        @test maximum(abs, y .- s(ts .- lag; idxs = message).u) < 0.01
        @test maximum(abs, y .- s(ts; idxs = message).u) < 0.06
    end
end

@testset "Lecture 6 time division" begin
    f_frame = 10.0
    # The window where the receiver clock sine is beyond ±0.95 closes acos(0.95) / 2π of a frame
    # after the slot's middle; just after it the hold shows the wire at that instant.
    close = acos(0.95) / 2π
    function samples(r, f_rx)
        s, m = r.sol, symbolic_container(r)
        out = []
        for (hold, offset) in ((m.hold_speed.y, 0.25), (m.hold_engine.y, 0.75)),
                k in 0:floor(Int, 4.0 * f_rx) - 1
            t = (k + offset + close) / f_rx
            slot = mod(f_frame * t, 1.0)
            # A sample near a slot boundary mixes both senders; it shows neither cleanly.
            min(slot, abs(slot - 0.5), 1 - slot) < 0.08 && continue
            sent = slot < 0.5 ? m.speed.y : m.engine.y
            push!(out, (; own = (slot < 0.5) == (offset < 0.5),
                held = s(t + 0.005 / f_rx; idxs = hold), wire = s(t; idxs = sent)))
        end
        return s, out
    end

    @testset "in step: each receiver holds its own slot" begin
        s, out = samples(_L6.TimeDivisionBenchTransient(), f_frame)
        @test string(s.retcode) == "Success"
        @test length(out) == 80
        @test all(o -> o.own, out)
        @test maximum(o -> abs(o.held - o.wire), out) < 0.01
    end

    @testset "drifting clock: receivers hold whichever slot is on the wire" begin
        s, out = samples(_L6.TimeDivisionDriftTransient(), 10.25)
        @test string(s.retcode) == "Success"
        @test count(o -> !o.own, out) >= 20
        @test maximum(o -> abs(o.held - o.wire), out) < 0.01
    end
end

@testset "Lecture 6 code division" begin
    r = _L6.CodeDivisionBenchTransient()
    s, m = r.sol, symbolic_container(r)
    @test string(s.retcode) == "Success"
    # Bit k is sent over [k - 1, k] and held by the receiver over [k, k + 1].
    held = collect(1.5:1.0:7.5)
    sent = collect(0.5:1.0:6.5)
    for (bits, receiver) in ((m.bits_a.y, m.receiver_a), (m.bits_b.y, m.receiver_b))
        @test maximum(abs, s(held; idxs = receiver.bit).u .- s(sent; idxs = bits).u) < 0.06
    end
    @test maximum(abs, s(held; idxs = m.receiver_c.bit).u) < 0.06
    @test maximum(abs, s(0.0:0.01:8.0; idxs = m.wire.y).u) <= 2.0
end
