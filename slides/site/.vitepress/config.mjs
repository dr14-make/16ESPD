import { defineConfig } from "vitepress"

export default defineConfig({
  title: "Vehicle Systems & Components",
  description: "Course materials — slides, notebooks and models",
  base: "/16ESPD/",
  outDir: "../dist",
  // The theme offsets a heading for the fixed nav bar only once the page has hydrated; a deep link
  // opened cold, as the decks' links into the guide are, is scrolled by the browser alone.
  head: [["style", {}, "html { scroll-padding-top: calc(var(--vp-nav-height) + 24px) }"]],
  markdown: { image: { lazyLoading: true } },
  themeConfig: {
    outline: [2, 3],
  },
})
