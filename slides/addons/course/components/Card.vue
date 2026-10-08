<script setup lang="ts">
// One box on a slide's `Grid`, holding any block: a live card, a figure, prose. `x` and `y` are
// its first column and row from zero, `w` and `h` how many it spans.
import { inject } from "vue"
import { GRID } from "../grid.key"

const props = defineProps<{ x: number; y: number; w: number; h: number }>()

const grid = inject(GRID, null)

// A card past the grid's edge lands in an implicit track no other card shares, which skews the
// whole slide without a word, so it shows where it is instead of what it holds.
function misplacement(): string | null {
  if (grid === null) {
    return "a Card belongs inside a Grid"
  }
  const { x, y, w, h } = props
  const fits = x >= 0 && y >= 0 && w >= 1 && h >= 1 && x + w <= grid.cols && y + h <= grid.rows
  return fits ? null : `Card x=${x} y=${y} w=${w} h=${h} does not fit a ${grid.cols} × ${grid.rows} Grid`
}

const misplaced = misplacement()

const placement = {
  gridColumn: `${props.x + 1} / span ${props.w}`,
  gridRow: `${props.y + 1} / span ${props.h}`,
}
</script>

<template>
  <div class="course-card" :style="placement" :data-misplaced="misplaced !== null || undefined">
    <p v-if="misplaced !== null">{{ misplaced }}</p>
    <slot v-else />
  </div>
</template>

<style>
.course-card {
  border: 1px solid #8884;
  border-radius: 6px;
  padding: 0.6rem;
  /* Grid items default to min-height:auto, which lets content push a box past its span. */
  min-inline-size: 0;
  min-block-size: 0;
  overflow: auto;
  font-size: 0.8rem;
}

/* A block that cannot show what it was asked to marks itself `data-fault`, and its box reads as
   one that does not fit. */
.course-card:is([data-misplaced], :has(> [data-fault])) {
  border: 2px solid #d33;
  color: #d33;
}
</style>
