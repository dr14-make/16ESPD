# Course material

The lecture decks, the hands-on guides and the handouts students and the lecturer use in the
room and afterwards.

## Language

**Deck**:
The slide presentation for one lecture or one hands-on session, shown by the lecturer.
_Avoid_: presentation, slideshow

**Static deck**:
A deck whose content is all written by hand and that opens from a file with nothing running.

**Live deck**:
A deck that also shows live cards, and so needs a running notebook behind it.

**Section**:
A run of consecutive slides in a deck, opened by a cover slide; the unit an author edits and a
deep link points at, by name rather than by position.
_Avoid_: chapter, part

**Slide**:
One screen within a section.

**Speaker notes**:
Everything the lecturer has for one slide, written freely; for the lecturer alone, never shown
to the room or printed.
_Avoid_: comments

**Presenter mode**:
The lecturer's own screen during a deck: the current slide's speaker notes, the next slide and
the clock.
_Avoid_: speaker view, tutor's screen, speaker page

**Block**:
One reusable piece a slide or a guide is composed from — a callout, a figure, a demo card, a
readout — the same in a static deck and in a live one.
_Avoid_: widget, element

**Live card**:
A block whose content is a published notebook cell, drawn from a running notebook.
_Avoid_: demo card (that is a block quoting a notebook's code, not running it)

**Figure**:
A plot produced by running a notebook, filling a named slot on a slide; never drawn by hand.
_Avoid_: chart, graph, image

**Diagram**:
A hand-drawn illustration — a block chain or a sketched curve — explaining an idea rather than
showing a simulation result.
_Avoid_: figure, sketch

**Screenshot**:
A capture of Dyad Studio showing what a step builds or plots; the same image appears in the
hands-on guide and in the hands-on deck.
_Avoid_: figure, image

**Hands-on guide**:
The page a student follows at their own machine to build a model step by step.
_Avoid_: handout, worksheet, hands-on page

**Step**:
One numbered stage of a hands-on guide, with a goal, the actions to take, a checkpoint to
compare against and a solution; a hands-on deck has one section per step.
_Avoid_: task, exercise

**Landing page**:
The course's front page, listing each lecture's decks, sections and guides.
_Avoid_: index, home page

**Handout**:
The printable reading version of a deck, taken away after the lecture: its slides, without
speaker notes.
_Avoid_: hands-on guide, PDF export
**Driver**:
The slot that supplies throttle, brake and steering-wheel angle to a car as causal signals.
The car owns actuator response; ESP, ABS and road grip are fixed run settings, not commands.
_Avoid_: controller, command parameters

**Scripted driver**:
A Driver implementation that samples commands from a time table on its own clock and holds
each command between ticks, without human input. A breakpoint takes effect at the first tick
at or after its time.
_Avoid_: headless driver, test loop

**Human driver**:
A Driver implementation that samples buffered pedal and steering commands on its own clock
and holds each command between ticks. The window fills the buffer from a pad or keyboard;
without a window it reads neutral. Device I/O stays outside the model equations.
_Avoid_: interactive analysis, gamepad controller


**Road grip function**:
The `RoadGrip` callable takes a wheel's world x and y position in meters and returns its
dimensionless grip multiplier. `RoadCar` loads it once with `road_grip(road_file)` and shares
it with all four wheels; each wheel evaluates it at its own frame position. It does not supply
driver commands or require road signal ports. Quadratic B-splines give C1 interpolation inside
the grid and hold edge values outside it. Straight-grid nodes are interpolated exactly; curved
roads use an x-indexed approximation away from the reference line.
_Avoid_: road socket, TableRoad, terrain controller, grip command, height map

**Road slope function**:
The `RoadSlope` callable takes the chassis center's world x and y position in meters and heading
in radians and returns tan of the road angle along that heading. `RoadBEVDrive` loads it once
with `road_height(height_file)` and passes it to `RoadGrade`, which reads the chassis frame
without applying force or torque. The world-coordinate height derivative includes curved-road
coordinate changes. Heading, not velocity direction, defines uphill even at rest or in reverse.
_Avoid_: road socket, bank force, per-wheel slope, pitch model, grade command

**OpenCRG**:
ASAM's road-grid file format. Grip uses a separate `<name>_mu.crg` file containing dimensionless
multipliers; height uses `<name>_z.crg`, including reference-line slope, banking, and start
elevation. An empty or missing file raises an error. Straight and curved reference lines are
supported while the reference line moves forward in its start frame's x. Road modifications are
applied when loading, before grip or height evaluation.
_Avoid_: grip CSV, road drawing format

**Disconnect clutch (K0)**:
The commanded clutch between the engine and the P2 machine. Opening it lets the machine drive
or regenerate with the engine disconnected; closing it transmits engine torque through the
machine-side shaft to the CVT. Its electrohydraulic actuator has a finite engagement response.
_Avoid_: launch clutch, centrifugal clutch, torque converter

**SoC-corrected fuel**:
A drive-cycle run's fuel per 100 km with the net battery energy turned into the fuel that would
replace it, at a stated engine-to-battery efficiency: a hybrid that ends the run with less charge
than it started reports more fuel than it burned, one that ends with more reports less. The
`Vehicle.SoCCorrectedFuel` block reports it in L/100 km and MJ/100 km beside the raw fuel.
_Avoid_: charge-sustaining fuel, net fuel, equivalent fuel (that is only the battery's share)

**Hybrid drive**:
`Vehicle.Electric.HybridDrive` is the battery, average converter, DC-equivalent machine,
auxiliaries, and ideal gear supplying a hybrid transmission input. It keeps `ElectricDrive`'s
`tau_ref`, `spline`, `support`, and `SoC` interface, with forwardable 30 kW, 205 N·m and
270 V, 1.4 kWh defaults from the 2011 Sonata Hybrid (ORNL-2011). Its default gear ratio is 1,
not the BEV's final-drive reduction; it does not include the engine, K0 clutch, or energy manager.
_Avoid_: hybrid powertrain, hybrid controller

**Engine-generator**:
`Vehicle.EngineGenerator` is Lecture 2's mapped engine and a Lecture 4 DC-equivalent machine
running as a generator on one shaft, with its converter, delivering DC power at the pins `p` and
`n`; engine mounts and generator housing share `support`. It takes a commanded electrical power
and a commanded engine speed: the generator torque holds the power, the engine pedal holds the
speed, and the generator unloads if the engine cannot keep up. It reports fuel mass flow, shaft
speed, electrical power, and the engine power it needs, which can drive the best-BSFC operating
line. It is the series hybrid's power unit, not the series hybrid, and holds no energy manager or
SoC logic.
_Avoid_: range extender (a sizing, not a part), APU, genset

**P2 powertrain**:
`Vehicle.P2Powertrain` composes the mapped engine, K0 disconnect clutch, `HybridDrive` and
`ControlledVariator`: the machine shares the shaft after K0 and before the variator. The
variator includes the final drive, but no launch clutch. The component exposes an output spline
and a housing `support` that the user connects in the bench. The variator is a distinct child,
so a speed-commanded variator can replace it; this is not a language-level `replaceable` feature. Lecture 5's fixed electric fixture
holds the engine stopped with fuel cut and K0 open; it is not engine-start logic or an energy manager.
In engine-only mode K0 launches the car on an engine-speed ramp.
_Avoid_: hybrid drive (that is the electric subassembly), launch device, energy manager


**Engine operating line**:
The Lecture 2 map's lowest-BSFC engine speed at each brake power, stored in
`assets/data/engine/bsfc_line.csv`. `Vehicle.OperatingLine` converts power in W to rpm;
`SpeedCommandedVariator` tries to hold that speed with total ratio 12 to 2.8, including final
drive. Lecture 5 step 2 requests pedal × 85 kW, independent of realized brake power,
with a 1000 rpm floor and a machine-side K0 lock-up ramp centered at 600 rpm. Ratio limits,
actuator lag, K0 launch slip, idle and braking leave points off the line; the line is a target,
not a guarantee or an energy manager.
_Avoid_: optimal operating point (without the requested power), efficiency controller

**Energy manager**:
`Vehicle.EnergyManager` is the P2 hybrid's rule-based supervisor, a signal block with no physics.
From the driver's torque demand at the transmission input, the shaft and engine speeds, vehicle
speed and SoC it picks electric only, engine on the best-BSFC line, charge (a load-point shift up
the line), boost, launch assist or regen through three continuous `HysteresisLatch` instances on
demand power, demand torque, shaft speed and SoC, and requests engine power, engine torque, engine
on, K0 engagement, machine torque and the friction brakes' share. It splits power by rule; it is not an optimizer (ECMS) and not a plant.
_Avoid_: hybrid controller, supervisory controller, ECMS, power split device
