# Hands-on 06 — messages coordinate; local loops brake

Open `VehicleSystemsComponents.HandsOn06`; save an exercise copy. The inherited
`WiringStop` canvas exposes the brake ECU, VCU, local pedals, wheels and calipers.
Both pedal gains retain the 50 ms response. The brake ECU owns the wheel-only
estimator, `RegenBlend(abs_rule=true)` and held ABS control; friction is local.
The VCU adds its wired accelerator to the received nonpositive regen request.
No actual-motor-torque feedback is modeled.

## 1a — wires to ideal bus

Starter: `Step1PointToPointStop` / `Step1PointToPointStopTransient`.
Delete `direct_regen`, `direct_steering`, `direct_yaw`; set `networked=true`.
Keep the pedal, wheel-speed and caliper wires. Reference: `Step1IdealBusStop`,
alias `IdealBusStop`, analysis `IdealBusStopTransient`. Both stop at **28.185 m**;
the distance match is 1e-5 m and speed match 5e-5 m/s at 1e-9 solve tolerances.
The preconnected monitoring backbone keeps acausal CAN ports balanced; this is
not an initially disconnected-bus starter. Unused direct inputs are zero-bound.

## 1b — hand-built regen message, inside the nodes

Starter: `Step1bMissingPedalStop` (historical name; no pedal message exists),
with its same-named `Transient` analysis. `ecu.regen_tx` is absent;
`drive.regen_rx` is present inside the VCU but bypassed by the top-level `bypass`.
`Vehicle.Planar.check_can` reports the missing sender. Open `WiringBrakeNode`:
add the supplied conditional `CanTxReal` and its two connections by enabling
`transmit_regen=true` in the exercise copy. Its fields are **slot 6, ID 272,
period `regen_period=chassis_period`, scale 0.1 N.m, raw -32768..32767**.
Wire `blend.tau_motor` to `regen_tx.u`, and `regen_tx.bus` to `bus`.
Inside `WiringDriveNode`, `CanRxReal(slot=6,id=272)` already joins the bus.
Delete `bypass` and set `drive_networked=true` to select its output.
Reference: `PedalMessageStop` / `PedalMessageStopTransient`, **28.185 m**.

## 2 — ownership is not arbitration

Starter: `Step2DuplicateSlotStop` / `Step2DuplicateSlotStopTransient`.
Run `check_can` before solving: IDs **272/273** both own slot **6**.
Changing only the ID does not repair ownership. Delete `duplicate`,
`duplicate_input`, `duplicate_bus`. Reference: `CanStop`, **29.056 m**.
The supplied starter analysis is intentionally invalid until repaired.

## 3 — architecture and period

Starter/reference: `Step3CanStop` / `CanStopTransient`; change `chassis_period`
to 10/20/40 ms (`Can20msStopTransient`, `Can40msStopTransient`).
`Step4SlowCanStop` is also the 40 ms example. Speed, wheels, steering, yaw and
regen follow this period; dashboard is 100 ms. ABS-active and friction are
internal wires. Compare library `Vehicle.Planar.CanBusBrake10msStop`,
`CanBusBrake20msStop`, `CanBusBrake40msStop`.

| Layout / period | Default [m] | Sweep mean [m] | Min–max [m] |
|---|---:|---:|---:|
| Real / 10 ms | 29.056 | 28.902 | 28.617–29.056 |
| Real / 20 ms | 30.018 | 29.496 | 28.982–30.018 |
| Real / 40 ms | 30.442 | 30.224 | 30.017–30.442 |
| Bus-brake / 10 ms | 30.743 | 30.100 | 28.789–30.743 |
| Bus-brake / 20 ms | 29.320 | 29.620 | 29.320–29.949 |
| Bus-brake / 40 ms | 33.934 | 33.638 | 31.792–35.779 |

The counterexample loses metres by transporting brake demand and friction over CAN; the real layout avoids that delay, though delayed regen still costs distance.
Six onset offsets span 0–40 ms in `assets/data/lecture06/can_stop.csv`, generated
by `scripts/lecture06_can_sweep.jl`; tests assert its input hash and these numbers.
No real-layout lock was sampled; the counterexample briefly meets the rear-lock
criterion at 10 ms / 30 ms offset, recorded rather than retuned.

## 4 — bitrate schedule

Starter/reference: `CanStop(name=:exercise)`. In Julia call
`Vehicle.Planar.can_schedule(car; bitrate=500_000)`, then `bitrate=250_000`.
Loads are **0.1215 / 0.243**. Ordered response bounds at 500 kbit/s are
`[0.30,0.45,0.60,0.75,0.90,1.05,1.20,1.35,1.35]` ms; at 250 they double.
This analytical schedule does not alter the model's sampled transport delay.

Run `handson06` after compilation. Default stops use onset 0.5 s to first speed
below 0.5 m/s on a 5 ms grid; absolute pins are asserted within 1 mm.
Wire convention: each top-level signal `connect` net counts once, including buses,
excluding six mechanical nets. Expanded direct/bus: **22/19**; library estimated
point-to-point/bus: **31/19** (the former expands estimator/blend internals).
Studio rendering of inherited metadata still needs a visual check.
