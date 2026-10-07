<script setup lang="ts">
// One box on a slide's `Grid`, holding any block: a live card, a figure, prose. `x` and `y` are
// its first column and row from zero, `w` and `h` how many it spans.
const props = defineProps<{ x: number; y: number; w: number; h: number }>()

const placement = {
  gridColumn: `${props.x + 1} / span ${props.w}`,
  gridRow: `${props.y + 1} / span ${props.h}`,
}
</script>

<template>
  <div class="course-card" :style="placement"><slot /></div>
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
</style>
