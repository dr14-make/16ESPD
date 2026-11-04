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


**Road**:
The socket that takes each wheel's world x and y position and returns its grip multiplier.
It does not supply driver commands. Uniform grip uses PlanarCar's `mu` parameter without a Road
implementation.
_Avoid_: terrain controller, grip command

**Table road**:
A Road implementation evaluating a straight-reference-line grip grid at each wheel position.
Quadratic B-spline interpolation is C1 inside the grid and holds the edge value outside it.
It agrees with other OpenCRG tools at finite grid nodes, not necessarily between nodes.
_Avoid_: bilinear road, height map

**OpenCRG**:
ASAM's road-grid file format. Grip uses a separate `<name>_mu.crg` file containing dimensionless
multipliers, not height; a missing grip file means 1. Straight grids are supported here;
reference-line phi channels and road modifications are rejected.
_Avoid_: grip CSV, road drawing format
