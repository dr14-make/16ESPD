import type { ResolvedSlidevOptions } from "@slidev/types"
import { kernelPlugin } from "../src/kernel.plugin.ts"

export default function setup(options: ResolvedSlidevOptions) {
  // Slidev serves its page in `slidev dev` and `slidev export` as it assembled it, without Vite's
  // HTML transform, so the `%BASE_URL%` in `index.html` is filled in here.
  options.utils.indexHtml = options.utils.indexHtml.replaceAll("%BASE_URL%", options.base ?? "/")
  return [
    kernelPlugin({
      entry: options.entry,
      headmatter: () => options.data.headmatter,
      live: options.mode === "dev",
    }),
  ]
}
