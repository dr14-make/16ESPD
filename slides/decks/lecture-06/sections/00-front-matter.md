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
Welcome to Lecture 6. Today's topic is the CAN bus.

Three words first. An ECU, an electronic control unit, is a small computer that runs one function of
the car, such as the brakes or the motor. A signal is one value that an ECU measures or commands,
such as the vehicle speed. A bus is one shared pair of wires that many ECUs connect to. CAN, short
for Controller Area Network, is the bus that almost every car uses.

The sentence on the slide is the whole lecture in one line: a bus trades wires for time. Without a
bus, every signal has its own wire and arrives at once and exactly. On a bus, the signal travels in
a message. It arrives a little late. It is rounded to a fixed step, which the slide calls quantized.
And it is refreshed only as often as the message is sent. The car has to be designed so that none of
this matters.

You see both halves today on a car you know: the battery-electric car from Lecture 4, with the ABS
and ESP from Lecture 3. You put its ECUs on a CAN bus, and you measure what the bus costs the ABS in
a hard stop.

The small line at the bottom is for browsing the slides on your own.
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
This is the plan for today: nine sections and a wrap-up. The last column shows where you build.

Sections 01 to 03 set the scene. Section 01 explains how many signals can share one wire. It also
introduces a picture that we use all lecture long: a meeting room with strict speaking rules.
Section 02 is the layer model that engineers use to describe any network. Section 03 shows the
networks inside real cars.

Sections 04 and 05 show how CAN works on the wire: the electrical signal, the message, and the rule
that decides who may send.

In sections 06 to 08 you build. In section 06 you put the car's signals on the bus. In section 07
you find a mistake in a bus that is wired wrongly. In section 08 you measure the price: how the bus
changes the ABS stopping distance, and how full the bus is.

Section 09 shows how a workshop talks to the car. In the wrap-up, the simulated car drives a real
instrument cluster from a Škoda Fabia.
-->
