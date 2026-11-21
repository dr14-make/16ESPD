# Hands-on 06 — replace the harness with messages

Open `VehicleSystemsComponents.HandsOn06` in Studio. The car, ECU nodes,
actuator and wheel wires are expanded on the canvas. Save a copy before each
exercise. Connections are tagged and outside structural `if` statements.

## 1 — point-to-point to shared bus

Run `HandsOn06.Step1PointToPointStopTransient` first (80 km/h, brake ramp at
0.5 s). Its model starts with `networked=false`, `ideal=true`. Follow the six
direct signal wires from motion/brake/blend to their consumers. The connected
bus backbone initially monitors rather than controls the direct-input nodes.

Delete `direct_speed`, `direct_abs`, `direct_steering`, `direct_yaw`,
`direct_friction`, and `direct_torque`. Replace `w4` with
`connect(torque_response.y, pedal.tau_ref)` and set `networked=true`.
Unused direct inputs are zero-bound inside the nodes. The finished reference
is `HandsOn06.IdealBusStop`, analysis `HandsOn06.IdealBusStopTransient`
(alias of the expanded `HandsOn06.Step1IdealBusStop`). Set `ideal=false`
to introduce sample/quantize/delay/hold. The estimator uses four wheel speeds,
not the body's true velocity.

## 1b — manually repair a missing pedal message

`HandsOn06.Step1bMissingPedalStop` has no pedal sender. Its visible `pedal_rx`
subscribes to slot **12**, ID **192**, but its output is unconnected. `w4`
is a runnable bypass into `ManualBlendNode.tau_ref`; that node has no hidden
pedal receiver. The starter defaults to `ideal=true`, and its supplied
`HandsOn06.Step1bMissingPedalStopTransient` demonstrates the bypass.
`VehicleSystemsComponents.Vehicle.Planar.check_can` diagnoses the missing sender.

Add `CanTxReal(slot=12, id=192, ideal=ideal, period=chassis_period, scale=0.1,
raw_min=-32768, raw_max=32767)`. Drive its `u` with `torque_response.y` and
join its bus to the backbone. Delete the bypass and connect `pedal_rx.y` to
`blend.tau_ref`. Check the bus before solving. Finished expanded reference:
`HandsOn06.PedalMessageStop`, analysis `HandsOn06.PedalMessageStopTransient`.
It also defaults to ideal transport; set `ideal=false` to compare sampling.

## 2 — duplicate ownership is not arbitration

Call `VehicleSystemsComponents.Vehicle.Planar.check_can` on
`HandsOn06.Step2DuplicateSlotStop(name=:exercise)`. Two senders own slot
**12**, IDs **192** and **193**. Changing only the ID does not fix ownership.
Delete `duplicate` and its two wires, then check again.
`HandsOn06.Step2DuplicateSlotStopTransient` is intentionally invalid until
that repair; do not solve the starter. The repaired topology can be compared
with `HandsOn06.CanStop` (`HandsOn06.Step3CanStop`), or with the explicit
sender/receiver reference `HandsOn06.PedalMessageStop`.

## 3 — sample-period experiment

`HandsOn06.CanStopTransient` is the finished 10 ms car, based on the expanded
`HandsOn06.Step3CanStop`. `HandsOn06.Can20msStopTransient` and
`HandsOn06.Can40msStopTransient` structurally extend that same car with
20 ms and 40 ms chassis periods. `HandsOn06.Step4SlowCanStopTransient` remains
the expanded 40 ms example, not the bitrate experiment. Wheel and pedal
periods follow the chassis period; friction and motor requests remain 20 ms,
dashboard 100 ms. All use library CAN nodes and the wheel-only estimator.
The physical brake and tire laws are unchanged. Use `OptimizationLevel.None()`.
Real brake ECUs send status and wheel-speed frames every 10–20 ms; 40 ms is
the deliberately too-slow-bus case. `chassis_period` sets speed, steering,
yaw, held ABS-active, all four wheel speeds and the pedal request. The brake
node holds ABS control active across pressure cycles, clearing on brake release
or estimated speed below 0.5 m/s; it does not change ABS tuning.

## 4 — bitrate / schedule experiment

Keep the 10 ms model and compare the analytical schedules:

```julia
P = VehicleSystemsComponents.Vehicle.Planar
car = VehicleSystemsComponents.HandsOn06.CanStop(name=:exercise)
fast = P.can_schedule(car; bitrate=500_000)
slow = P.can_schedule(car; bitrate=250_000)
fast.load, slow.load
[f.response_time * 1000 for f in fast.frames]
[f.response_time * 1000 for f in slow.frames]
```

Lower bitrate doubles serialization, blocking and response bounds at fixed
message periods. It does not change the transport model's fixed sample delay;
this is an analytical schedule experiment, not a bit-level arbitration,
stuffing, collision or bus-off simulation.

## Checkpoints

Stop distances below are measured checkpoints asserted by `test/handson06.jl`.
Distance is measured from brake onset at 0.5 s to the first speed below
0.5 m/s on a 5 ms grid. Analyses use `dtmax=0.005`, `reltol=1e-7`.

| Reference / setting | Checkpoint |
|---|---:|
| `HandsOn06.CanStopTransient`, 10 ms | 30.742977497 m |
| `HandsOn06.Can20msStopTransient`, 20 ms | 29.320221625 m |
| `HandsOn06.Can40msStopTransient`, 40 ms | 33.933638581 m |
| 10 ms schedule, 500 kbit/s | load 0.1495 |
| 10 ms schedule, 250 kbit/s | load 0.299 |
| Step 1 direct / ideal stop | 28.184673 / 28.184676 m |
| Step 1b finished manual pedal stop | 28.184674 m |

At 500 kbit/s the ordered response bounds are
`[0.28, 0.43, 0.58, 0.73, 0.88, 1.03, 1.18, 1.33, 1.48, 1.63, 1.78, 1.78]` ms;
at 250 kbit/s they double. Longer chassis periods do not imply monotonically
longer stop distances for this sampled ABS controller.

Run the registered `handson06` test group after source compilation. Tests
assert the known distance/schedule pins, direct-versus-ideal equivalence,
missing/duplicate diagnostics and ideal manual-receiver tracking. The direct/ideal distance match uses 1e-5 m and speed uses 5e-5 m/s;
absolute stopping checkpoints use 1 mm. Their ideal analyses use 1e-9 solver
tolerances. Canvas wires are orthogonal; the direct-wired diagram is denser
than the bus diagram.

Wire-count convention: count each top-level `connect` signal net once, including
the monitoring/measurement bus, excluding six mechanical connections. The
expanded dual-mode starter/reference have 23 / 17 signal nets. The library
point-to-point estimator car has 28 versus 17 in the library CAN car; its
estimator and hold are expanded rather than enclosed in the brake node.
