<script setup lang="ts">
// A notebook cell exported by scripts/export_deck_cards.jl, shown until live cards reach this
// deck. It takes the two names a `<PlutoCard>` takes, so switching to the live card is a rename.
// The page sits under the deck's base, which a build sets to /16ESPD/lecture-02/.
const props = withDefaults(defineProps<{ notebook: string; name: string; height?: string }>(), {
  height: "22rem",
})

const src = `${import.meta.env.BASE_URL}cards/${props.notebook}/${props.name}.html`
</script>

<template>
  <iframe class="card-export" :src="src" :title="`${notebook} · ${name}`" :style="{ height }" />
</template>

<style>
.card-export {
  display: block;
  width: 100%;
  border: 0;
  background: #fff;
}
</style>
