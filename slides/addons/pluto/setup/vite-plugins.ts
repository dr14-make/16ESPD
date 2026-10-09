import type { ResolvedSlidevOptions } from "@slidev/types"
import { sessionPlugin } from "../src/session.plugin.ts"

export default function setup(options: ResolvedSlidevOptions) {
  return [
    sessionPlugin({
      entry: options.entry,
      headmatter: () => options.data.headmatter,
      live: options.mode === "dev",
    }),
  ]
}
