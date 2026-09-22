import assert from "node:assert/strict"
import { test } from "node:test"
import { Following, HEARTBEAT_MS, STALE_MS } from "./position.channel.ts"
import type { FollowReport } from "./position.channel.ts"

const CHANNEL = "plutodeck-position"

/** A deck window's side of the channel, without the `window` a `Position` would need. */
function deckWindow(deck: string, source: string) {
  const channel = new BroadcastChannel(CHANNEL)
  return {
    at: (index: number) => {
      channel.postMessage({ type: "at", deck, source, index })
    },
    gone: () => {
      channel.postMessage({ type: "gone", deck, source, index: 0 })
    },
    close: () => {
      channel.close()
    },
  }
}

function follow(deck: string, t: { after: (fn: () => void) => void }) {
  const reports: FollowReport[] = []
  const following = new Following(deck, (report) => reports.push(report))
  t.after(() => {
    following.stop()
  })
  return { reports, last: () => reports[reports.length - 1] }
}

/** `BroadcastChannel` delivers on a later turn, so an assertion waits one out. */
const settled = (): Promise<void> => new Promise((resolve) => setTimeout(resolve, 50))

test("a page with no deck talking says so rather than showing a slide", async (t) => {
  const { last } = follow("waiting.deck.json", t)
  await settled()

  assert.equal(last()?.status, "waiting")
  assert.equal(last()?.index, null)
  assert.equal(last()?.decks, 0)
})

test("a deck announcing itself is followed to the slide it names", async (t) => {
  const { last } = follow("live.deck.json", t)
  const deck = deckWindow("live.deck.json", "window-a")

  deck.at(3)
  await settled()

  assert.equal(last()?.status, "live")
  assert.equal(last()?.index, 3)
  assert.equal(last()?.decks, 1)
  deck.close()
})

test("a deck naming another path is ignored, not followed", async (t) => {
  const { last } = follow("mine.deck.json", t)
  const other = deckWindow("someone-elses.deck.json", "window-b")

  other.at(5)
  await settled()

  // The channel name is shared by every deck server on this origin; the path is the only guard.
  assert.equal(last()?.status, "waiting")
  assert.equal(last()?.index, null)
  other.close()
})

test("two deck windows on one page are counted, not interleaved silently", async (t) => {
  const { last } = follow("two.deck.json", t)
  const first = deckWindow("two.deck.json", "window-c")
  const second = deckWindow("two.deck.json", "window-d")

  first.at(0)
  second.at(1)
  await settled()

  // Same origin and same path, so only the per-window source tells them apart — and a page that
  // can only follow whichever spoke last has to say so rather than flip.
  assert.equal(last()?.decks, 2)
  first.close()
  second.close()
})

test("a window that announces its departure is dropped without waiting for the timer", async (t) => {
  const { last } = follow("closing.deck.json", t)
  const deck = deckWindow("closing.deck.json", "window-e")

  deck.at(2)
  await settled()
  assert.equal(last()?.status, "live")

  deck.gone()
  await settled()

  // `pagehide` is what keeps a reload from costing a whole staleness window.
  assert.equal(last()?.status, "lost")
  // The cues stay on the slide the deck last named; it is the chrome that changes.
  assert.equal(last()?.index, 2)
  deck.close()
})

test("a deck that goes quiet without saying so is called stale, on the timer", async (t) => {
  const { last } = follow("quiet.deck.json", t)
  const deck = deckWindow("quiet.deck.json", "window-f")

  deck.at(4)
  await settled()
  assert.equal(last()?.status, "live")

  // A missed beat is a busy main thread repainting every card, so a single one must not be
  // read as a deck that is gone.
  await new Promise((resolve) => setTimeout(resolve, HEARTBEAT_MS + 200))
  assert.equal(last()?.status, "live", "one missed heartbeat is not a lost deck")

  await new Promise((resolve) => setTimeout(resolve, STALE_MS + HEARTBEAT_MS))

  assert.equal(last()?.status, "lost")
  assert.equal(last()?.index, 4)
  deck.close()
})
