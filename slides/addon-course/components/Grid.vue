<script setup lang="ts">
// A slide's grid, which `Card`s are placed on by column and row. It fills the slide below its
// heading.
import { provide } from "vue"
import { GRID } from "../grid.key"

const props = withDefaults(defineProps<{ cols?: number; rows?: number }>(), { cols: 12, rows: 12 })

provide(GRID, { cols: props.cols, rows: props.rows })

// Fixed tracks: a card spans a number of these and keeps that size whatever it holds, so
// nothing reflows when a live card's content arrives.
const tracks = {
  gridTemplateColumns: `repeat(${props.cols}, minmax(0, 1fr))`,
  gridTemplateRows: `repeat(${props.rows}, minmax(0, 1fr))`,
}
</script>

<template>
  <div class="course-grid" :style="tracks"><slot /></div>
</template>

<style>
.course-grid {
  display: grid;
  gap: 0.5rem;
  block-size: calc(100% - 4rem);
}
</style>
