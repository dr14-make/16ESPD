# Lecture 3 preparation — 2D vehicle, ABS and ESP foundation

## Current state

The repository contains a validated one-dimensional ABS example:

- `dyad/Vehicle/BrakeActuator.dyad`
- `dyad/Vehicle/ABSController.dyad`
- `dyad/Vehicle/ABSBrakeTest.dyad`
- `notebooks/lecture03/01-abs.jl`

Available analyses under `VehicleSystemsComponents.Vehicle`:

```julia
ABSBrakeTransient()
LockedBrakeTransient()
ABSControllerTransient()
BrakeActuatorTransient()
```

The braking analyses accept a road-friction multiplier:

```julia
VehicleSystemsComponents.Vehicle.ABSBrakeTransient(road_mu = 0.3)
VehicleSystemsComponents.Vehicle.LockedBrakeTransient(road_mu = 0.3)
```

The current model separates wheel and vehicle speeds and models longitudinal slip, but it cannot
represent lateral motion, steering response, yaw, or ESP.

## Recommended direction

Create a new 2D vehicle rather than replacing the existing 1D car. Keep the 1D model for
longitudinal lessons and regression tests.

Use `MultibodyComponents.PlanarMechanics` for a four-wheel planar vehicle with:

- longitudinal and lateral position and velocity,
- heading and yaw rate,
- four independent wheel rotational states,
- front-wheel steering,
- longitudinal and lateral tire slip,
- combined-slip friction limiting,
- four independent brake actuators,
- optional four-channel ABS.

`MultibodyComponents.PlanarMechanics.SlipBasedWheelJoint` already supplies longitudinal and lateral
slip velocities, longitudinal and lateral tire forces, and a combined friction limit. The standard
library also contains `PlanarMechanics.examples.TwoTrackModelTest`, which is a useful topology
reference but should not be copied without validating its parameters and signs.

## Bill of materials

### Reuse

- `MultibodyComponents.PlanarMechanics.World`
- `MultibodyComponents.PlanarMechanics.Body` for chassis mass and yaw inertia
- `MultibodyComponents.PlanarMechanics.FixedTranslation` for wheel locations
- `MultibodyComponents.PlanarMechanics.Revolute` or prescribed front steering
- `MultibodyComponents.PlanarMechanics.SlipBasedWheelJoint` for combined-slip tire contact
- `RotationalComponents.Components.Inertia` for each wheel
- existing `Vehicle.BrakeActuator`
- existing `Vehicle.ABSController`

Add `MultibodyComponents` to the project dependencies before compiling the new model.

### Custom components

1. **Four-wheel planar car**
   - rigid chassis,
   - realistic wheelbase and track width,
   - chassis mass and yaw inertia,
   - four tire contact locations,
   - steerable front wheels and fixed rear wheels,
   - static front/rear normal-load distribution initially.

2. **Wheel-slip adapter**
   - convert each tire's longitudinal slip velocity to normalized slip ratio:

     ```math
     \kappa_i = \frac{r\omega_i-v_{long,i}}
                      {\max(|v_{long,i}|,v_\epsilon)}
     ```

   - provide wheel-specific feedback to ABS.

3. **Four-channel ABS**
   - one controller and brake actuator per wheel,
   - common driver demand with front/rear brake bias,
   - independent torque release when a wheel approaches lock.

4. **Steering-and-braking test**
   - initialize the vehicle at road speed with matching wheel speeds,
   - apply a steering input,
   - begin hard braking during the turn,
   - simulate with and without ABS.

## Initial model fidelity

Start with:

- flat road,
- constant static wheel loads,
- no suspension, pitch, or roll,
- combined longitudinal/lateral tire friction,
- four wheel-speed states,
- prescribed steering angle,
- independent ABS channels.

This is sufficient to demonstrate that locked tires lose lateral force and steering authority.
Dynamic longitudinal load transfer can be added next. Suspension and body roll are not required for
the first handling comparison.

## Validation and assembly sequence

1. Install/import `MultibodyComponents` and compile the unchanged workspace.
2. Validate one `SlipBasedWheelJoint` under simultaneous longitudinal and lateral motion.
3. Assemble chassis and four freely rolling wheels.
4. Validate straight free rolling and conservation of momentum.
5. Add front steering and validate a constant-radius turn.
6. Add brakes and demonstrate wheel lock during the turn.
7. Add four independent ABS channels.
8. Compare ABS and no-ABS trajectories.
9. Extend the Lecture 3 Pluto notebook with the 2D results.

Do not proceed to the next assembly increment until the current one simulates and its expected
physical behavior has been checked.

## Handling comparison outputs

Plot and compare:

- vehicle trajectory in the x-y plane,
- heading and yaw rate,
- longitudinal and lateral vehicle speeds,
- body sideslip angle,
- four normalized wheel-slip ratios,
- individual longitudinal and lateral tire forces,
- individual brake torques,
- path deviation during braking.

Expected qualitative result: without ABS, wheel lock moves the tires onto the sliding plateau and
reduces lateral control authority. With ABS, the tires remain closer to peak adhesion and retain more
ability to follow the steered path.

## ESP path after ABS

The same 2D car forms the foundation for ESP. Add:

1. a reference yaw-rate model based on steering angle and speed,
2. measured yaw-rate and body-sideslip feedback,
3. a yaw-moment controller,
4. selective individual-wheel braking,
5. understeer and oversteer test manoeuvres.

ESP should follow validation of the four-wheel combined-slip model and four-channel ABS.
