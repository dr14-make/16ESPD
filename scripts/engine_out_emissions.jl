"""
Engine-out emissions of a port-injected gasoline engine at part load, as a trend model.

    include("scripts/engine_out_emissions.jl")
    using .EngineOutEmissions
    e = engine_out_emissions(1.05, -10.0, 0.5)   # (; HC, CO, NOx) in g per kg of fuel
    exhaust_concentrations(e, 1.05)              # (; HC_ppmC1, CO_pct, NOx_ppm)

`λ` is the excess-air factor, `Δσ` the spark advance relative to MBT in degrees (negative is
retard) and `load` the relative load from 0 to 1. Each species is a few lines that reproduce the
textbook trends (Heywood, *Internal Combustion Engine Fundamentals*, ch. 11; the Bosch figure of
HC, NOx and CO against λ for ignition angles 20°–50°). It is not a combustion model: nothing here
is simulated, and every shape coefficient is `(assumed)` unless tagged `(textbook)`.

- **CO** comes from the oxygen a rich mixture lacks. Each mole of missing O₂ leaves two moles of
  CO or H₂ unburned, and the water–gas shift splits them about 3 : 1 in favor of CO, so CO falls
  linearly with λ to a small floor just lean of 1. Spark changes it a little.
- **NOx** is thermal NO. Its λ dependence is a bell peaking at λ 1.05, where the burned gas is
  still hot and oxygen is to spare. Spark advance and load raise the peak burned-gas temperature,
  and the Zeldovich rate turns that into NOx through its activation temperature.
- **HC** is fuel hidden in crevices and wall layers, a parabola in λ with its minimum lean of 1.
  Retard lowers it, since a later burn leaves hotter gas to oxidize it in the exhaust. Toward the
  lean misfire limit, partial burns and misfires add a term that grows exponentially.

At MBT, load 0.5 the model lands in these published ranges for engine-out gas (wet basis):

| quantity                 | model     | published range | source                        |
|:-------------------------|:----------|:----------------|:------------------------------|
| NOx peak                 | ≈2900 ppm | 1000–4000 ppm   | Heywood fig. 11-2, 11-9       |
| CO at λ 0.9              | ≈4.0 %    | 2–5 %           | Heywood fig. 11-2             |
| CO at λ 1.0              | ≈0.7 %    | 0.3–1 %         | Heywood fig. 11-2             |
| HC at its minimum        | ≈1800 ppm C₁ | 1000–3000 ppm C₁ | Heywood fig. 11-2           |
| HC at λ 1.35             | ≈3600 ppm C₁ | 2500–6000 ppm C₁ | Heywood §11.4, lean limit   |
| HC as share of the fuel  | ≈1.5 %    | 1–2.5 %         | Heywood §11.4                 |

HC is counted per carbon atom (ppm C₁), as a flame-ionization detector reads it; propane- or
hexane-equivalent ppm are a third or a sixth of that. NOx mass is counted as NO₂.

The conversion from g/kg fuel to a mole fraction takes the exhaust as `1 + λ·AFR_ST` kg per kg
of fuel at a molar mass of `M_EXH`, so `x = EI / M_species · M_EXH / (1 + λ·AFR_ST)`.
"""
module EngineOutEmissions

export engine_out_emissions, exhaust_concentrations

const AFR_ST = 14.6        # stoichiometric air-fuel ratio of gasoline (textbook)
const M_EXH = 28.8         # g/mol, burned-gas molar mass (textbook, Heywood 28.5–29)
const M_CH = 13.88         # g/mol per carbon atom of CH₁.₈₇ gasoline (textbook)
const M_CO = 28.01         # g/mol (textbook)
const M_NO2 = 46.01        # g/mol; NOx mass is reported as NO₂ (textbook)
const O2_ST = 1000 * (1 + 1.87 / 4) / M_CH   # mol O₂ per kg fuel for stoichiometric burning

const CO_SHARE = 0.75      # share of the oxygen deficit left as CO; the rest is H₂ (textbook)
const LAMBDA_CO = 1.02     # CO reaches its floor just lean of 1: mixing, dissociation (assumed)
const CO_LEAN = 20.0       # g/kg fuel, CO floor on the lean side (assumed)
const CO_SPARK = 0.005     # 1/deg, ≈15 % less CO at 30° retard, as the Bosch figure (assumed)

const NOX_REF = 75.0       # g/kg fuel at the λ peak, MBT, load 0.5 (assumed, ≈2900 ppm)
const LAMBDA_NOX = 1.05    # λ of the NOx peak (textbook)
const W_NOX = 0.10         # half width of the bell at half height (assumed, Bosch figure)
const T_ACT = 69_090.0     # K, activation temperature of N₂ + O → NO, Zeldovich (textbook)
const T_REF = 2600.0       # K, peak burned-gas temperature at MBT, load 0.5 (assumed)
const DT_SPARK = 3.0       # K per degree of advance (assumed: 30° retard ≈ 0.4 × NOx, Bosch)
const DT_LOAD = 150.0      # K per unit load: less residual gas at high load (assumed)

const HC_REF = 15.0        # g/kg fuel at the minimum, MBT, load 0.5 (textbook 10–25)
const LAMBDA_HC = 1.10     # λ of the HC minimum (assumed, Bosch figure 1.1–1.2)
const A_HC = 12.0          # curvature: HC doubles from the minimum to λ 0.8 (assumed)
const HC_SPARK = 0.015     # 1/deg, ≈35 % less HC at 30° retard (assumed, Bosch figure)
const HC_LOAD = 0.4        # relative HC rise per unit load reduction (assumed)
const LAMBDA_LIM = 1.35    # lean misfire limit at load 0.5 (textbook 1.3–1.4)
const LIM_LOAD = 0.10      # the limit moves lean with load: less residual gas (assumed)
const HC_MISFIRE = 10.0    # g/kg fuel added at the misfire limit (assumed)
const D_MISFIRE = 0.04     # λ over which the misfire term grows e-fold (assumed)

"""
    engine_out_emissions(λ, Δσ, load) -> (; HC, CO, NOx)

Emission indices in g per kg of fuel at excess-air factor `λ`, spark advance `Δσ` degrees from
MBT and relative load `load` (0–1). Meant for λ 0.75–1.45, Δσ −40…+15°, load 0.1–1.
"""
function engine_out_emissions(λ, Δσ, load)
    CO = (1 + CO_SPARK * Δσ) * (2 * CO_SHARE * O2_ST * M_CO * max(LAMBDA_CO - λ, 0) + CO_LEAN)

    T_burned = T_REF + DT_SPARK * Δσ + DT_LOAD * (load - 0.5)
    zeldovich = exp(T_ACT / T_REF - T_ACT / T_burned)
    NOx = NOX_REF * zeldovich / (1 + ((λ - LAMBDA_NOX) / W_NOX)^2)

    λ_limit = LAMBDA_LIM + LIM_LOAD * (load - 0.5)
    quench = HC_REF * exp(HC_SPARK * Δσ) * (1 - HC_LOAD * (load - 0.5)) * (1 + A_HC * (λ - LAMBDA_HC)^2)
    HC = quench + HC_MISFIRE * exp((λ - λ_limit) / D_MISFIRE)

    return (; HC, CO, NOx)
end

"""
    exhaust_concentrations(e, λ) -> (; HC_ppmC1, CO_pct, NOx_ppm)

Wet mole fractions of the emission indices `e` from [`engine_out_emissions`](@ref) at `λ`.
"""
function exhaust_concentrations(e, λ)
    mol_exhaust = 1000 * (1 + λ * AFR_ST) / M_EXH   # mol of exhaust per kg of fuel
    return (;
        HC_ppmC1 = 1e6 * e.HC / M_CH / mol_exhaust,
        CO_pct = 100 * e.CO / M_CO / mol_exhaust,
        NOx_ppm = 1e6 * e.NOx / M_NO2 / mol_exhaust)
end

end
