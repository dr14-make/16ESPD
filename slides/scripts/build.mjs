// Builds every deck into dist/<deck>/ with its handout PDF beside it, as the site publishes them.
import { build, decks } from "./decks.mjs"

for (const deck of decks()) build(deck, { pdf: true })
