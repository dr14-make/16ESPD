# Lecture 1 — the hands-on first, with its theory inside it

## Goal

Students build the car before they control it, and learn each part's physics at the moment they
build it. The hands-on moves ahead of the PID lecture and carries the theory itself; the PID
lecture points back to it instead of repeating it.

Success: the session opens with why and what before any formula; every hands-on step opens with
the theory it needs, in plain language with every formula derived and every number worked in the
tutor notes; every checkpoint number is predicted before it is built; and every place the PID
deck relies on that physics links to the exact hands-on slide.

## Sequence

| # | Session | Material | Min |
|---|---|---|---|
| 1 | Hands-on: understand the car, then build it | `docs/handson/lecture-01/`, `docs/slides/handson-01/` | ~210 |
| 2 | Introduction and PID | `docs/slides/lecture-01/` | 90 |

## The hands-on deck

Horizontal index N is still step N, so the page's deep links hold. Part 1 opens with "Why we are
here" (cruise control needs to know the car it drives), "What we are building today" (the engine
→ gear and wheel → body → speedometer chain, and the 246 km/h and 10 km/h the day ends on) and
the input / disturbance / state / output vocabulary. Each step then opens with its theory:

| Step | Theory slides |
|---|---|
| 01 | two kinds of wire: signals and mechanical joints |
| 02 | what happens when you press the pedal; the lag as a closing gap; the step-02 numbers worked in advance; why every push needs a fixed support; the Padé delay before the plot; why the lags are kept |
| 03 | F = T·i/r from the gear and the lever rule |
| 04 | the four forces; drag's v² from air pushed aside per second; rolling resistance and the 500 N check |
| 05 | the force balance; the nine parameters; top speed and cruise torques on paper; the car's time constant; after the plot, why 246 km/h is wrong |
| 06 | the wheel's hidden mass, J/r², from kinetic energy |
| 07 | the slope as part of the weight, gradient as tan α, the 2023 N > 1935 N climb |
| 08 | ideal rolling and what it assumes; slip ratio and the friction curve drawn from the model's equation |
| 10 | engine limit against tire limit; at the end, every predicted number and the hand-off to the lecture |

Every formula is derived on its slide, and the tutor notes repeat each calculation with the
numbers substituted. Timings grow from 165 to about 210 minutes; the deck suggests a break after
step 05.

## The PID deck

Front matter: one "car you built" slide maps each `MyCar` component to its course model. Section
01 keeps the full-throttle run, the step test and the K, τ, θ fit. Section 10 loses "what ideal
rolling assumes"; beats one and two become recaps. Wherever a slide relies on the hands-on's
physics — the lags, the car's time constant, the 40.1 N·m cruise torque, the 10 % hill, the
wheel's inertia, the friction curve, the open-loop standing start — a grey
"↩ Hands-on step NN" line links to the slide. Every figure slot stays.

## Out of scope

The notebooks are unchanged.
