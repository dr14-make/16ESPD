<script setup lang="ts">
// The bond layer: every card whose cell renders an input, mounted once per window and never
// shown. A widget reports its value to the kernel only once it is rendered, and Slidev mounts
// only the slides around the current one, so an input placed on a later slide would leave its
// bond `missing` and every cell downstream of it waiting.
import { onMounted } from "vue"
import PlutoCard from "./components/PlutoCard.vue"
import { live, usePluto } from "./src/pluto.session"

// Started as the deck opens, so the inputs report on the cover slide too.
onMounted(() => {
  usePluto().catch((error: unknown) => console.error("[pluto]", error))
})
</script>

<template>
  <div v-if="live" class="pluto-bond-layer" hidden>
    <PlutoCard v-for="name in live.bindCards" :key="name" :name="name" />
  </div>
</template>
