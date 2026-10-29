# Lecture 4 steps 04 and 06: the battery-electric car on the planar WLTC bench and its energy
# bill. The car must drive the cycle, land its battery DC consumption in the plan's band, and
# meter every link of the chain so that the links add up to what left the cells.

using DyadInterface: symbolic_container

const _BEV_PL = VehicleSystemsComponents.Vehicle.Planar
const _BEV_H4 = VehicleSystemsComponents.HandsOn04

# Lecture 2's engine car on the same cycle: 5.22 L/100 km (HandsOn02.MappedCarWLTC, branch
# feat/handson02-wltc-bonus, docs/lecture-02-handson-step07-wltc-plan.md §5), petrol at
# 0.745 kg/L (Hands-on 02) and H_l = 43.4 MJ/kg (Lecture 2 tasks, textbook).
const _ENGINE_MJ_PER_100KM = 5.22 * 0.745 * 43.4

const _WLTC_KM = 23.266

# Road load of the 1500 kg course car, integrated over the trace itself: what a car that follows
# the trace exactly would spend on drag and rolling resistance.
function _bev_trace_road_energy()
    rows = split.(readlines(joinpath(pkgdir(VehicleSystemsComponents), "assets", "data",
        "drive_cycles", "wltc_class3b.csv"))[2:end], ',')
    v = parse.(Float64, last.(rows)) ./ 3.6
    E = 0.0
    for k in 1:length(v)-1, j in 0:99
        u = v[k] + (v[k+1] - v[k]) * (j + 0.5) / 100
        E += (0.5 * 1.2 * 0.63 * u^2 + 0.012 * 1500 * 9.80665) * u / 100
    end
    return E
end

function _bev_bill(run)
    m = symbolic_container(run)
    s = run.sol
    e(x) = s[x][end]
    E = (; cells = e(m.E_cells), dc = e(m.E_dc), dc_out = e(m.E_dc_out), dc_in = e(m.E_dc_in),
        R0 = e(m.E_R0), aux = e(m.E_aux), conv = e(m.E_conv), motor = e(m.E_motor),
        shaft_out = e(m.E_shaft_out), shaft_in = e(m.E_shaft_in), road = e(m.E_road),
        brake = e(m.E_brake), tire = e(m.E_tire), dkin = e(m.E_kin) - s[m.E_kin][1])
    return (; km = e(m.speed.px) / 1000, E)
end

_bev_links(E) = E.road + E.brake + E.tire + E.motor + E.conv + E.R0 + E.aux + E.dkin

function _bev_stops(t, ref; min_len = 2.0)
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

const _bev_run = _BEV_PL.PlanarBEVWLTCTransient()

@testset "Lecture 4 step 04: the BEV follows WLTC on the planar bench" begin
    run = _bev_run
    m = symbolic_container(run)
    s = run.sol
    @test string(s.retcode) == "Success"
    @test s.t[end] == 1800.0
    v_kmh = 3.6 .* s[m.speed.v_x]
    ref = s[m.trace.y]
    # Measured 1.63 km/h at worst, inside WLTP's ±2 km/h everywhere.
    @test maximum(abs, v_kmh .- ref) < 2.0
    # Measured 2.6e-5 of the trace.
    @test s[m.speed.px][end] / 1000 ≈ _WLTC_KM rtol = 5e-4
    @test maximum(abs, s[m.speed.py]) < 1e-6
    # The machine's braking share fades out before standstill, so the car never reverses and the
    # friction brakes hold it at every stop.
    @test minimum(v_kmh) > -1e-3
    stops = _bev_stops(s.t, ref)
    @test length(stops) == 8
    for (t0, t1) in stops
        held = (s.t .>= t0 + 1.0) .& (s.t .<= t1)
        @test maximum(abs, v_kmh[held]) < 1e-3
    end
    # The driver never needs more than the machine has: 117 of 320 N·m at most.
    @test maximum(abs, s[m.driver.y]) < 320.0
    # The drive divides the torque command by the field, so the machine gives what the split
    # asks for at any speed, weakened field included (measured 0.19 N·m, the current loop's lag).
    weak = s[m.drive.converter.field] .< 0.9
    @test count(weak) > 100
    @test maximum(abs, s[m.drive.machine.tau_em][weak] .- s[m.split.tau_motor][weak]) < 1.0
    # Battery current and voltage stay on the pack's sane branch, and SoC falls by the cycle's
    # 3.1 kWh of 40.
    @test minimum(s[m.drive.battery.v]) > 300.0
    @test s[m.drive.SoC][end] ≈ 0.9 - 3.126 / 40 atol = 1e-3
end

@testset "Lecture 4 step 06: battery DC consumption on WLTC" begin
    (; km, E) = _bev_bill(_bev_run)
    Wh_per_km = E.dc / 3600 / km
    # Plan band: Leaf WLTP 171 Wh/km at the wall less 10–15 % charging loss, on a road load
    # about 15 % below the Leaf's.
    @test 120.0 <= Wh_per_km <= 155.0
    # Measured 131.2 Wh/km.
    @test Wh_per_km ≈ 131.24 atol = 0.05
    # The same cycle in MJ/100 km: 47.2 against the engine car's 168.8, 3.6 times less.
    MJ_per_100km = E.dc / 1e6 / km * 100
    @test MJ_per_100km ≈ 47.25 atol = 0.05
    @test _ENGINE_MJ_PER_100KM ≈ 168.78 atol = 0.01
    @test 3.5 < _ENGINE_MJ_PER_100KM / MJ_per_100km < 3.7
end

@testset "Lecture 4 step 06: the links add up to the battery energy" begin
    run = _bev_run
    m = symbolic_container(run)
    (; km, E) = _bev_bill(run)
    # Each link is metered on its own, so the balance is a check of the model; measured 3e-9.
    @test abs(_bev_links(E) - E.cells) / E.cells < 1e-6
    # What left the cells is what coulomb counting saw, at the open-circuit voltage.
    ps = run.sol.ps
    @test E.cells ≈ ps[m.drive.battery.E] * ps[m.drive.battery.Q_nom] *
                    (0.9 - run.sol[m.drive.SoC][end]) rtol = 1e-9
    @test E.dc ≈ E.dc_out - E.dc_in rtol = 1e-9
    @test E.cells - E.R0 ≈ E.dc rtol = 1e-9
    # The car follows the trace, so its road load is the trace's own: measured 0.08 % above.
    @test E.road ≈ _bev_trace_road_energy() rtol = 2e-3
    # 300 W for 1800 s, less the DC-DC converter's 10 ms start.
    @test E.aux ≈ 300.0 * 1800.0 rtol = 1e-4
    # Each loss is positive, and each link is a few percent of the chain: machine 0.41 kWh,
    # converter 0.05 kWh, battery 0.07 kWh, tire slip 0.04 kWh of 3.1 kWh.
    for loss in (E.motor, E.conv, E.R0, E.tire, E.brake)
        @test loss > 0
    end
    @test 0.05 < E.motor / E.dc_out < 0.15
    @test 0.005 < E.conv / E.dc_out < 0.03
    # Braking: 27 % of the traction energy at the shaft comes back through it, and 89 % of that
    # reaches the battery. Friction takes only the fade below 10 km/h, under 1 % of it.
    @test 0.25 < E.shaft_in / E.shaft_out < 0.29
    @test 0.85 < E.dc_in / E.shaft_in < 0.93
    @test E.brake < 0.01 * E.shaft_in
    @test abs(E.dkin) < 1e-6 * E.cells
end

@testset "Lecture 4 steps 04 and 06: the hands-on reference is the library car" begin
    lib = _bev_run
    step4 = _BEV_H4.BEVWLTCTransient()
    bill = _BEV_H4.BEVEnergyBillTransient()
    @test string(step4.sol.retcode) == "Success"
    @test string(bill.sol.retcode) == "Success"
    ts = range(0, 1800, length = 3601)
    ml, m4, mb = symbolic_container(lib), symbolic_container(step4), symbolic_container(bill)
    v_lib = lib.sol(ts, idxs = ml.speed.v_x).u
    # The meters add states, which moves the solver's steps by a hair (measured 3.6e-5 m/s).
    @test step4.sol(ts, idxs = m4.speed.v_x).u ≈ v_lib atol = 1e-4
    @test bill.sol(ts, idxs = mb.speed.v_x).u ≈ v_lib atol = 1e-9
    (; km, E) = _bev_bill(bill)
    @test E.dc / 3600 / km ≈ 131.24 atol = 0.05
    @test abs(_bev_links(E) - E.cells) / E.cells < 1e-6
end
