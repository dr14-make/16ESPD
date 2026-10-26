using Test
using VehicleSystemsComponents
using DyadInterface: symbolic_container

const _H3_TCS = VehicleSystemsComponents.HandsOn03

@testset "Hands-on 03 bonus: hydraulic traction control" begin
    without_tcs = _H3_TCS.TCSStartTransient(tcs_enabled = 0.0)
    with_tcs = _H3_TCS.TCSStartTransient(tcs_enabled = 1.0)
    m_off = symbolic_container(without_tcs)
    m_on = symbolic_container(with_tcs)

    v_off = without_tcs.sol(10.0, idxs = m_off.car.body.mass.v)
    v_on = with_tcs.sol(10.0, idxs = m_on.car.body.mass.v)
    kappa_off = without_tcs.sol(10.0, idxs = m_off.car.wheel.kappa)
    kappa_on = with_tcs.sol(10.0, idxs = m_on.car.wheel.kappa)

    ts = range(3.0, 10.0, length = 7001)
    controlled_slip = with_tcs.sol(ts, idxs = m_on.car.wheel.kappa).u

    @info "Hydraulic TCS standing start at 10 s" v_off v_on kappa_off kappa_on
    @test sum(controlled_slip .< 0.12) / length(controlled_slip) > 0.85
    @test abs(kappa_on - 0.04) < 0.03
    @test kappa_off > 1.0
    @test v_on > v_off
end
