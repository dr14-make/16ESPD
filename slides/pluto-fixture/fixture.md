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
# The browser suite presents a copy, since Pluto rewrites the notebook it opens; this names the
# notebook the fixture's cards are checked against.
pluto:
  notebook: ../../pluteSpike/PlutoDeck.jl/test/fixtures/browser.jl
---

# Live cards

The deck the PlutoDeck.jl browser suite drives, against `test/fixtures/browser.jl`. This cover
has no cards.

---

## A wave you can drive

<Grid>
  <Card :x="0" :y="0" :w="4" :h="2"><PlutoCard name="frequency" /></Card>
  <Card :x="4" :y="0" :w="4" :h="2"><PlutoCard name="readout" /></Card>
  <Card :x="0" :y="2" :w="8" :h="8"><PlutoCard name="wave" /></Card>
  <Card :x="8" :y="0" :w="4" :h="5"><PlutoCard name="formula" /></Card>
</Grid>

---

## The same wave again

<Grid>
  <Card :x="0" :y="0" :w="8" :h="8"><PlutoCard name="wave" /></Card>
  <Card :x="8" :y="0" :w="4" :h="2"><PlutoCard name="constant" /></Card>
  <Card :x="8" :y="2" :w="4" :h="2"><PlutoCard name="plain" /></Card>
  <Card :x="8" :y="4" :w="4" :h="3"><PlutoCard name="formula-live" /></Card>
  <Card :x="0" :y="8" :w="4" :h="2"><PlutoCard name="frequency" /></Card>
  <Card :x="10" :y="10" :w="4" :h="2">past the grid's edge</Card>
</Grid>

---
preload: false
---

## An input no other slide carries

Never mounted until it is visited, which is what the bond layer is for.

<Grid>
  <Card :x="0" :y="0" :w="4" :h="2"><PlutoCard name="amplitude" /></Card>
</Grid>

---
preload: false
---

## A card the notebook does not declare

What a card shows when its name is mistyped.

<Grid>
  <Card :x="0" :y="0" :w="4" :h="2"><PlutoCard name="not-in-the-notebook" /></Card>
</Grid>
