---
routeAlias: front-matter
layout: cover
---

# CAN bus

<h1 class="!text-5xl !-mt-4 opacity-70">Multiplexing in car electronic systems</h1>

Vehicle Systems &amp; Components — Lecture 6

A bus trades wires for time: every signal on it arrives late, quantized and on a schedule, and the
car has to be designed so that this does not matter.

<div class="text-xs opacity-60 mt-12">

<kbd>→</kbd> <kbd>Space</kbd> next &nbsp;·&nbsp; <kbd>←</kbd> previous &nbsp;·&nbsp;
<kbd>O</kbd> overview &nbsp;·&nbsp; <kbd>G</kbd> go to slide &nbsp;·&nbsp;
presenter mode from the nav bar, bottom left

</div>

<!--
Welcome to Lecture 6, on the CAN bus. CAN stands for Controller Area Network. It is the network
that lets the electronic control units of a car, the ECUs, talk to each other over one pair of
wires instead of a wire per signal.

The sentence on the slide is the whole lecture in one line. A bus saves wires, but it is not free.
A signal that used to arrive on its own wire, instantly and exactly, now arrives in a message: a
little late, rounded to a fixed resolution, and only as often as the sender sends it. The car has
to be designed so that none of that matters. Today you see both halves: the wires that disappear,
and the price in time.

You do that on the car you already know: the planar battery-electric car from Lecture 4, with the
ABS and ESP from Lecture 3. Its ECUs talk over a CAN bus, and you measure what the bus costs the
ABS when the car brakes hard.

The small line at the bottom is for browsing the slides on your own: the arrow keys and the space
bar move, O opens the overview, and G jumps to a slide.
-->

---

## The sections

| # | Section | What it covers | Build |
|---|---|---|---|
| <Link to="multiplexing">01</Link> | Multiplexing | frequency, time and code sharing; the meeting room; wired against bused | |
| <Link to="osi-layers">02</Link> | The OSI model | the seven layers one by one, mapped onto CAN; CAN is not a post office | |
| <Link to="networks-in-a-car">03</Link> | Networks in a car | high- and low-speed CAN, LIN, gateways; CAN FD, FlexRay, Ethernet | |
| <Link to="physical-layer">04</Link> | Physical layer | CAN_H and CAN_L, termination, topology, bit timing | |
| <Link to="frame-and-arbitration">05</Link> | Frame and arbitration | the fields, bit stuffing, who wins, acknowledgement | |
| <Link to="signals">06</Link> | Signals | DBC files, scaling, byte order, counters and checksums | 01 put the car's signals on the bus |
| <Link to="errors">07</Link> | Errors | error frames, error counters, bus-off | 02 a broken bus, and `check_can` |
| <Link to="timing">08</Link> | Timing | message periods, latency, bus load, response time | 03 period against stopping distance · 04 bus load |
| <Link to="diagnostics">09</Link> | Diagnostics | finding a broken wire; OBD-II, UDS, ISO-TP | |
| <Link to="wrap-up">10</Link> | Wrap-up | a real Škoda Fabia cluster on the simulated bus | |

<!--
Here is the plan for today: nine sections and a wrap-up. The first column links to each section,
and the last column names the build at its end.

Section 01 is multiplexing: the three ways to share one medium, the meeting room with strict
speaking rules, which is the picture we use all lecture long, and what a bus saves in a car.
Section 02 is the layer model network engineers use, one layer at a time, mapped onto CAN.
Section 03 shows the networks of real cars: high- and low-speed CAN, LIN, gateways, and what came
after.

Sections 04 and 05 are how CAN works on the wire: the two signal lines, the frame, and the rule
that decides who may talk.

Sections 06 to 08 are where you build. In section 06 you put the car's signals onto the bus, with
the scaling a real message uses. In section 07 you meet a broken bus. In section 08 you measure the
price: how the message period moves the ABS stopping distance, and how full the bus is.

Section 09 is diagnostics, how a workshop talks to the car. In the wrap-up, the simulated car
drives a real instrument cluster from a Škoda Fabia.
-->
