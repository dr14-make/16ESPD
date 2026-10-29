# Switching and PWM models

For models whose sources switch thousands of times a run: choppers, bridges, PWM. The car runs
average models (the plan's "never stack time scales"); these live beside it.

## The gate is a continuous function of time

- Carrier: a triangle built with `mod(time, 1/f_sw)`; compare the reference against it.
- Each gate edge ramps linearly over `t_sw` instead of jumping. The ramp is what makes the model
  solvable without an event per edge, and the overlap of voltage and current during it is the
  switching loss.
- A switch is a stdlib `VariableResistor` moved between `R_on` and `R_off` on a log scale,
  `R = R_on^u * R_off^(1 - u)`, so the edge spends its time evenly across the decades. Ground its
  heat port.
- The stdlib has a diode: `ElectricalComponents.Analog.Semiconductors.Diode`. Read its default
  card (`Ids`, `Vt`, `Maxexp`) to predict the forward drop before simulating.

## Solver

Rodas5P with `dtmax` below `t_sw`, so no edge is stepped over. Prove the choice with a sensitivity
check: the switching loss changes by less than your tolerance when `dtmax` is halved and doubled.
Anchor the ripple against its formula (buck: `ΔI = V_out (1 - d) / (L f_sw)`) — a stepped-over
edge shows as ripple that is too small.

## Losses are states

Integrate input, output and each loss as an energy state (`der(E_in) = P_in`). Efficiency and
loss figures are then exact over the window, and the energy balance is an anchor that closes to
the solver tolerance. Summing power over the save grid aliases with the switching frequency.

## Inductive loads need freewheeling paths

A resistor switch feeding an inductor sits mid-edge near `sqrt(R_on R_off)`, and the inductor
forces its full current through it: the output spikes to kilovolts. Every switch on an inductive
load gets an antiparallel diode, and the buck its freewheeling diode.

## Spectra

Save on a uniform grid (`saveat = 1/f_sample`) over a whole number of fundamental periods after the
start-up transient, and take the DFT of that window. Anchor the result:

- square wave: the `4 V / (n π)` series;
- naturally sampled PWM: the Bessel-series sideband amplitudes around each carrier multiple
  (Mohan's table), the fundamental at `m_a V_dc`.
