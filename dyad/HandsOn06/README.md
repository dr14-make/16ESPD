# Hands-on 06: the bus carries coordination, the loops stay local

Open `VehicleSystemsComponents.HandsOn06` and save an exercise copy of each starter before you
edit it.

Every exercise builds on `WiringStop`: a hard ABS stop from 80 km/h, with the pedal pressed at
0.5 s. Its canvas shows the car as a real EV is split:

- The **brake ECU** (`WiringBrakeNode`) reads its brake pedal and its four wheel-speed sensors on
  its own wires, and drives the calipers on its own wires. Inside it, the wheel-only estimator
  computes speed and slip, `RegenBlend` splits the brake demand between motor and discs, and
  `AbsControlHold` holds the ABS status.
- The **VCU** (`WiringDriveNode`) reads the accelerator on its own wire and adds the regen
  request from the brake ECU.
- Only **coordination** crosses the bus: vehicle speed, the four wheel speeds, steering angle, yaw
  rate, the regen request and the held ABS status.

The model does not report the motor's actual torque back to the brake ECU.

Each stop distance is measured from the pedal press until the speed first falls below 0.5 m/s, on
a 5 ms grid. The tests check every number below to within 1 mm.

## 1a: from wires to an ideal bus

Starter: `Step1PointToPointStop`, analysis `Step1PointToPointStopTransient`.

1. Delete the direct wires `direct_regen`, `direct_steering` and `direct_yaw`.
2. Set `networked = true`.
3. Keep the pedal, wheel-speed and caliper wires: those loops stay local.

The bus backbone is already connected, so the CAN ports stay balanced while you rewire.

Reference: `Step1IdealBusStop` (also `IdealBusStop`, analysis `IdealBusStopTransient`). Both cars
stop in **28.185 m**: an ideal bus behaves exactly like wires.

## 1b: build the regen message by hand

Starter: `Step1bMissingRegenStop`, analysis `Step1bMissingRegenStopTransient`. The brake ECU does
not send the regen request yet, and a direct wire, `bypass`, stands in for it.

1. Run `Vehicle.Planar.check_can` on the starter. It reports that nobody transmits slot 6.
2. Open `WiringBrakeNode` and find the regen transmitter `regen_tx`: **slot 6, ID 272 (110h),
   period `regen_period` (= `chassis_period`), 0.1 N·m per bit, raw −32768…32767**. It reads
   `blend.tau_motor` and connects to `bus`, but exists only when `transmit_regen` is set.
3. The VCU's receiver, `CanRxReal(slot = 6, id = 272)` in `WiringDriveNode`, is already on the
   bus.
4. In the starter, on its `extends WiringStop(…)` line, set `transmit_regen = true` and
   `drive_networked = true`, so the VCU takes the regen request from the bus. Then delete
   `bypass`.

Reference: `RegenMessageStop`, analysis `RegenMessageStopTransient`. It stops in **28.185 m**,
the same as before.

## 2: two transmitters on one slot

Starter: `Step2DuplicateSlotStop`, analysis `Step2DuplicateSlotStopTransient`. Its analysis fails
until you repair it.

1. Run `check_can` before solving. IDs **272 and 273** both own slot **6**.
2. Changing only the ID does not fix it: the slot still has two owners.
3. Delete `duplicate`, `duplicate_input` and `duplicate_bus`.

Reference: `CanStop`, **29.056 m**.

## 3: architecture against period

Starter and reference: `Step3CanStop`, analysis `CanStopTransient`. Set `chassis_period` to 10,
20 and 40 ms (`Can20msStopTransient`, `Can40msStopTransient`). `Step4SlowCanStop` is the 40 ms
car. Speed, wheel speeds, steering, yaw, regen and ABS status follow this period; the dashboard
frames use 100 ms.

Compare the counterexample in the library, where the brake request crosses the bus twice:
`Vehicle.Planar.CanBusBrake10msStop`, `CanBusBrake20msStop` and `CanBusBrake40msStop`.

One stop depends on where the pedal press falls between frames. So
`assets/data/lecture06/can_stop.csv` repeats every case for six pedal-onset offsets from 0 to
40 ms; `scripts/lecture06_can_sweep.jl` writes it.

| Layout, period | Default onset [m] | Sweep mean [m] | Min–max [m] |
|---|---:|---:|---:|
| Real, 10 ms | 29.056 | 28.902 | 28.617–29.056 |
| Real, 20 ms | 30.018 | 29.496 | 28.982–30.018 |
| Real, 40 ms | 30.442 | 30.224 | 30.017–30.442 |
| Brake request on the bus, 10 ms | 30.743 | 30.100 | 28.789–30.743 |
| Brake request on the bus, 20 ms | 29.320 | 29.620 | 29.320–29.949 |
| Brake request on the bus, 40 ms | 33.934 | 33.638 | 31.792–35.779 |

The real layout costs 0.8–2.1 m against the ideal bus, because the regen request still waits for
its frame. The counterexample also waits for the brake request and the friction request; at 40 ms
it stops about 5.5 m later than the ideal bus on average. The real layout never locks a wheel; the counterexample briefly
locks a rear wheel at 10 ms with a 30 ms onset offset.

## 4: bus load at two bitrates

Use `CanStop(name = :exercise)`. In Julia, call `Vehicle.Planar.can_schedule(car; bitrate =
500_000)`, then `bitrate = 250_000`.

- Load: **13.45 %** at 500 kbit/s, **26.9 %** at 250 kbit/s.
- Worst-case response times at 500 kbit/s, by priority: 0.28, 0.43, 0.58, 0.73, 0.88, 1.03, 1.18,
  1.33, 1.48, 1.48 ms. At 250 kbit/s they double.

The schedule is calculated, not simulated: it does not change the delay in the model, which comes
from the periods.

## Wire count

Each top-level signal net counts once, the bus included; the six mechanical nets don't count.

- Hands-on starter: **22** nets point to point, **19** on the bus.
- Library car: **31** point to point (`PlanarBEVDriveEstimated` draws the estimator and blend at
  the top level), **19** on the bus (`PlanarBEVCanDrive`).

Run the `handson06` test group after compiling to check every number above.
