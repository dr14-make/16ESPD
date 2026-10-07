<script setup lang="ts">
// PROTOTYPE. The spike's readout, drawn over every slide in every window: kernel status, which
// cards are mounted in which render context, and the last bond writes this window sent.
import { probe } from "./pluto.session"
import PlutoCard from "./components/PlutoCard.vue"

// Slidev mounts only the slides around the current one, and a widget reports its value only
// once rendered: inputs on unvisited slides would stay `missing` and the simulation would never
// run. PlutoDeck has no such gap because it mounts every slide at once.
const PREAMBLE = ["gain-d", "grade", "antiwindup"]
</script>

<template>
  <div hidden>
    <PlutoCard v-for="name in PREAMBLE" :key="name" :name="name" :x="0" :y="0" :w="1" :h="1" />
  </div>
  <aside class="spike-probe">
    <strong>kernel</strong> {{ probe.status }} <span v-if="probe.error">· {{ probe.error }}</span>
    <div>
      <strong>mounted</strong>
      <span v-for="(n, key) in probe.mounts" :key="key" v-show="n !== 0"> {{ key }}×{{ n }}</span>
    </div>
    <div>
      <strong>bond writes</strong>
      <span v-for="w in probe.bondWrites.slice(0, 4)" :key="w.at + w.name">
        {{ w.at }} {{ w.name }}={{ w.value }};
      </span>
    </div>
  </aside>
</template>

<style>
.spike-probe {
  position: absolute;
  inset-inline: 0;
  inset-block-end: 0;
  z-index: 100;
  padding: 0.2rem 0.6rem;
  font: 10px/1.4 ui-monospace, monospace;
  background: rgb(255 240 200 / 0.92);
  color: #333;
  pointer-events: none;
}
</style>
