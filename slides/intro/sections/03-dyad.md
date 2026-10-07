---
routeAlias: dyad
---

## The tool: Dyad

<div class="grid grid-cols-[2fr_3fr] gap-8 text-sm">
<div>

All modeling in this course is done in **Dyad**, by JuliaHub: you draw or write a model of a physical system, and it simulates it. Together we build **one library of vehicle components** and test different vehicle systems on it.

Focus: the car's **1D (longitudinal) motion**.

#### Components

engine · electric motor · wheels · transmission · brakes · driver

#### Systems we simulate on them

ABS, ESP and TCS · electric drive and its control · hybrid architecture · adaptive cruise control

</div>
<div>

<figure>
  <img src="/img/dyad-studio.png" class="max-h-80 mx-auto" alt="Dyad Studio showing the car model twice: as a block diagram of engine, driveline and body on the left, and as Dyad code on the right.">
  <figcaption class="text-center opacity-75">The car you build in the first practical: the same model as a diagram and as code.</figcaption>
</figure>

Documentation: [help.juliahub.com/dyad/dev](https://help.juliahub.com/dyad/dev/)

First practical: <a href="../handson/lecture-01/index.html">build the car in Dyad</a>.

</div>
</div>

<!--
**Say:** one tool for the modeling practicals. Dyad is a modeling language and a VS Code extension: you place components like engine, gear and wheel, connect them, and simulate. Underneath it is Julia, but you will mostly draw and write models, not program.

**Point at:** the screenshot. Every block in the diagram is a line of code on the right, and every wire is a `connect`. You can work in either view.

**Say:** we stay in one dimension — the car moving forward and back. That is enough for the engine, the drivetrain, braking, traction and cruise control, and it keeps the models small enough to understand completely. The autonomous-vehicle practical is the exception: it uses the CARLA simulator.
-->
