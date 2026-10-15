---
layout: home
title: Vehicle Systems & Components
hero:
  name: Vehicle Systems & Components
  tagline: Course materials — slides, notebooks and models
features:
  - title: Introduction
    details: "Week 1 · 20 min<br>Lecturers, how you pass, what the course covers, the Dyad tool, the schedule, what to install, GitHub and Git basics, and the books."
    link: /intro/index.html
    target: _self
  - title: "Hands-on: understand the car, then build it in Dyad Studio"
    details: "Session 1 · about 210 min<br>Why a controller needs a model, then the car one part at a time: each step opens with its physics — the engine's delay and lag, torque to force, drag and the force balance, top speed on paper, slip and the friction curve — then builds it and checks the predicted number. Ends with a wheel spinning on snow."
    link: /handson/lecture-01/
  - title: "Control Systems: Introduction and PID"
    details: "Session 2 · 180 min<br>The car you built, ten notebooks. The step test, open loop and closed loop, P, PI and PID, integral windup, heuristic tuning, discretization, and what happens to cruise control on ice."
    link: /lecture-01/index.html
    target: _self
  - title: "Lecture 1 build guide: the cruise controller, block by block"
    details: "Session 2 · alongside the lecture<br>What you build on your own car while the lecture runs: the loop, then P, PI and PID, the limiter and clamping anti-windup, a noisy speedometer, and the loop on ice. Each step lists its blocks, wires and the plot to expect, with two catch-up checkpoints."
    link: /lecture/lecture-01/
  - title: "Engine Control Systems: the engine and its control unit"
    details: "Session 3<br>The theory: where the vehicle's energy goes, the Otto and Diesel cycles and the stoichiometric mixture, the engine control system and its sensors, fuel injection and the pulse-width formula, ignition timing and the coil, and the λ loop around the catalyst. Ends with the mapped engine you build in the hands-on."
    link: /lecture-02/index.html
    target: _self
---

## Lecture 1, in two sessions

One car throughout: learned and built first, then controlled. Run them in this order.

Present the hands-on with the [tutor deck](./handson-01/index.html){target="_self"}; its speaker
notes carry what to say, every derivation with the numbers plugged in, and where students get
stuck.

In the lecture the students build the cruise controller on that car as you go. They follow the
[build guide](./lecture/lecture-01/); each build slide links to its step.

## Jump straight to a section

Section number is notebook number. Each link opens the deck at that point rather than at the
beginning.

1. [**The car**](./lecture-01/index.html#/the-car){target="_self"} — the step test: read K, τ and θ off the car you built
2. [**Open vs closed loop**](./lecture-01/index.html#/open-vs-closed-loop){target="_self"} — feedforward is right until the hill
3. [**Proportional**](./lecture-01/index.html#/proportional){target="_self"} — error shrinks with k but never reaches zero
4. [**Proportional-integral**](./lecture-01/index.html#/proportional-integral){target="_self"} — the integrator finds notebook 02's answer by itself
5. [**PID**](./lecture-01/index.html#/pid){target="_self"} — three terms, three jobs: present, past, future
6. [**Integral windup**](./lecture-01/index.html#/windup){target="_self"} — the hill the engine cannot climb
7. [**Derivative and noise**](./lecture-01/index.html#/derivative-and-noise){target="_self"} — small noise, steep slope, ruined command
8. [**Tuning**](./lecture-01/index.html#/tuning){target="_self"} — a gain set from one step test, without a model
9. [**Discretization**](./lecture-01/index.html#/discretization){target="_self"} — the strobe light slows down
10. [**Wheel and slip**](./lecture-01/index.html#/wheel-and-slip){target="_self"} — cruise control meets black ice

## Lecture 2: engines and their control systems

The theory deck carries the lecturer's engine slides; the notebooks will regenerate its plots from
models, one notebook at a time.

1. [**Vehicle energy**](./lecture-02/index.html#/vehicle-energy){target="_self"} — drag, rolling, slope, acceleration and the auxiliaries
2. [**Engine and cycles**](./lecture-02/index.html#/engine-and-cycles){target="_self"} — Otto and Diesel, and the stoichiometric 14.6
3. [**Engine control system**](./lecture-02/index.html#/engine-control-system){target="_self"} — sensors, ECU, actuators and the control strategies
4. [**Sensors**](./lecture-02/index.html#/sensors){target="_self"} — throttle position, temperature and air mass
5. [**Fuel injection**](./lecture-02/index.html#/fuel-injection){target="_self"} — pulse width = base × factors
6. [**Ignition**](./lecture-02/index.html#/ignition){target="_self"} — spark advance, the coil and the dwell
7. [**Emissions and lambda control**](./lecture-02/index.html#/emissions-and-lambda){target="_self"} — the λ loop and the catalyst
8. [**The mapped engine**](./lecture-02/index.html#/mapped-engine){target="_self"} — what the hands-on builds

## For the lecturer

**Two screens.** Deck on the projector, Jupyter on the laptop. Open presenter mode from the
deck's nav bar, bottom left — notes, timer and next slide.

**Every demo slide is executable.** Each one names the notebook file and the cell heading,
carries the code, and has a copy button.

**Handout.** Each deck's `handout.pdf` is published beside it: one slide per page, speaker notes
excluded.

**No network needed.** The handout PDF is the offline copy: keep it on a memory stick in case
the network or the laptop fails.

::: info All thirty-two figures are in

Every figure in the Lecture 1 deck is an executed notebook plot, saved by `save_figure` into
`slides/decks/lecture-01/public/figures/`. `npm run check` in `slides/` fails on any image a deck
references that does not exist.

:::

---

The decks are built with [Slidev](https://sli.dev), this page and the hands-on guide with
[VitePress](https://vitepress.dev).
