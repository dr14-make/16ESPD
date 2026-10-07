---
theme: default
title: Live cards — browser fixture
# `fixture.md` rather than `slides.md`, so the workspace does not build and publish it as a deck.
routerMode: hash
transition: none
# The browser suite cuts the network, so anything Slidev fetches off a CDN by default — a stylesheet
# off Google Fonts, its favicon — would be a console error.
fonts:
  provider: none
favicon: "data:,"
addons:
  - ./addon-pluto
---

# Live cards

The deck the PlutoDeck.jl browser suite drives, against `test/fixtures/browser.jl`. This cover
has no cards.

---

## A wave you can drive

<Grid>
  <PlutoCard name="frequency" :x="0" :y="0" :w="4" :h="2" />
  <PlutoCard name="readout" :x="4" :y="0" :w="4" :h="2" />
  <PlutoCard name="wave" :x="0" :y="2" :w="8" :h="8" />
  <PlutoCard name="formula" :x="8" :y="0" :w="4" :h="5" />
</Grid>

---

## The same wave again

<Grid>
  <PlutoCard name="wave" :x="0" :y="0" :w="8" :h="8" />
  <PlutoCard name="constant" :x="8" :y="0" :w="4" :h="2" />
  <PlutoCard name="plain" :x="8" :y="2" :w="4" :h="2" />
  <PlutoCard name="formula-live" :x="8" :y="4" :w="4" :h="3" />
  <PlutoCard name="frequency" :x="0" :y="8" :w="4" :h="2" />
</Grid>

---
preload: false
---

## An input no other slide carries

Never mounted until it is visited, which is what the bond layer is for.

<Grid>
  <PlutoCard name="amplitude" :x="0" :y="0" :w="4" :h="2" />
</Grid>
