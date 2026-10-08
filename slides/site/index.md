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
    details: "Session 2 · 90 min<br>The car you built, ten notebooks. The step test, open loop and closed loop, P, PI and PID, integral windup, heuristic tuning, discretization, and what happens to cruise control on ice."
    link: /lecture-01/index.html
    target: _self
---

## Lecture 1, in two sessions

One car throughout: learned and built first, then controlled. Run them in this order.

Present the hands-on with the [tutor deck](./handson-01/index.html){target="_self"}; its speaker
notes carry what to say, every derivation with the numbers plugged in, and where students get
stuck.

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
