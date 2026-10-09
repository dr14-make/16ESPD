// Live cards, driven in real headless Chromium: the fixture deck served by `slidev dev`, against
// the real kernel it starts. Run with `npm run test:live`; it needs Julia, so it stays out of
// `npm test` and CI.
//
// Everything is asserted through the DOM a real browser built, over HTTP: a missing `process` shim
// that Node supplies for free, and a static handler never exercised because the page was loaded
// from disk, were both invisible to anything less.
import assert from "node:assert/strict"
import { execFileSync, spawn } from "node:child_process"
import type { ChildProcess } from "node:child_process"
import { copyFileSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs"
import { createServer } from "node:net"
import { tmpdir } from "node:os"
import { basename, dirname, join, resolve } from "node:path"
import { after, before, describe, it } from "node:test"
import { setTimeout as sleep } from "node:timers/promises"
import { chromium } from "playwright-chromium"
import type { Browser, BrowserContext, Page } from "playwright-chromium"
import { supervise } from "../src/kernel.launcher.ts"

const SLIDES = resolve(import.meta.dirname, "../../..")
const FIXTURE = join(SLIDES, "decks/pluto-fixture/fixture.md")
const NOTEBOOK = join(SLIDES, "decks/pluto-fixture/browser.jl")
const KERNEL = join(SLIDES, "addons/pluto/kernel")

/**
 * A Pluto server the way an editor extension starts one for authoring: no secret, and nothing to
 * do with any deck. It exits when its stdin closes, which is how `supervise` stops it.
 */
const PLUTO_WITHOUT_SECRET = `
  import Pkg; Pkg.instantiate(); import Pluto
  port, notebook = ARGS
  @async (read(stdin); exit())
  Pluto.run(; host="127.0.0.1", port=parse(Int, port), notebook=[notebook],
    launch_browser=false, dismiss_update_notification=true,
    require_secret_for_access=false, require_secret_for_open_links=false)
`

/** Julia starting Pluto, and Pluto starting the notebook's worker, from cold. */
const KERNEL_TIMEOUT = 300_000
const SLIDEV_TIMEOUT = 60_000
const SHUTDOWN_TIMEOUT = 60_000
/** A module script delays `load` until it has evaluated, and the deck's awaits its kernel. */
const NAVIGATION_TIMEOUT = 180_000

/**
 * Resolve nothing but the loopback, so a fetch off this machine fails the way it would in a
 * lecture hall with no wifi. A plot falls through to esm.sh when the bundled Plotly version and
 * the notebook's disagree, and PlutoPlotly imports lodash and interact.js from a CDN outright;
 * with wifi, neither can be told from working. See issue 028.
 */
const NO_NETWORK = "--host-resolver-rules=MAP * ~NOTFOUND, EXCLUDE localhost, EXCLUDE 127.0.0.1"

/**
 * The twoslash client Slidev bundles patches a FloatingVue no deck installs, and logs that it
 * failed to: the one console error a page logs before any deck code has run.
 */
const SLIDEV_NOISE = "Failed to patch FloatingVue"

/** Slidev keeps the slides around the current one mounted with `display: none`. */
const SHOWING_SLIDE = '.slidev-page:not([style*="display: none"])'
/** Every copy of the frequency slider, on slides and in the bond layer alike. */
const FREQUENCY_COPIES = '[data-card="frequency"] bond input'

/**
 * Record every `data-source` each card passes through, from before the deck's own scripts run:
 * by the time the suite can evaluate anything, the placeholders are long gone. A card is created
 * already carrying its first source, so its insertion counts as well as every change after it.
 */
const RECORD_CARD_SOURCES = `(() => {
  const record = (card) => {
    const seen = (card.__sources ??= [])
    const source = card.dataset.source
    // A repaint rewrites live over live, which is a mutation and not a transition.
    if (seen[seen.length - 1] !== source) seen.push(source)
  }
  new MutationObserver((records) => {
    for (const r of records) {
      if (r.type === "attributes") record(r.target)
      for (const node of r.addedNodes) {
        if (!(node instanceof Element)) continue
        if (node.matches("[data-card]")) record(node)
        node.querySelectorAll("[data-card]").forEach(record)
      }
    }
  }).observe(document, {
    subtree: true, childList: true, attributes: true, attributeFilter: ["data-source"],
  })
})()`

/**
 * Record every `FileReader.readAsDataURL` the page performs. The one call issue 027 traced cost
 * the renderer ~7.1 GB and left no other trace: the bytes are Blink strings, and the URL never
 * reaches the DOM.
 */
const WATCH_DATA_URLS = `(() => {
  window.__dataUrls = []
  const original = FileReader.prototype.readAsDataURL
  FileReader.prototype.readAsDataURL = function (blob) {
    window.__dataUrls.push({ type: blob?.type ?? "", size: blob?.size ?? 0 })
    return original.call(this, blob)
  }
})()`

interface Process {
  child: ChildProcess
  output: () => string
  /** How the process ended: `"0"`, another exit code, or the signal that killed it. */
  exited: Promise<string>
}

function start(command: string, args: string[], cwd: string, env = process.env): Process {
  const child = spawn(command, args, { cwd, env, stdio: ["ignore", "pipe", "pipe"] })
  let output = ""
  const collect = (chunk: Buffer) => (output += chunk.toString())
  child.stdout.on("data", collect)
  child.stderr.on("data", collect)
  const exited = new Promise<string>((done) =>
    child.once("exit", (code, signal) => {
      done(code === null ? String(signal) : String(code))
    }),
  )
  return { child, output: () => output, exited }
}

const running = (process: Process) =>
  process.child.exitCode === null && process.child.signalCode === null

/** Poll `holds` until it is truthy. A deck is eventually-true in every direction. */
async function until(what: string, holds: () => unknown, timeout = 120_000, process?: Process) {
  const deadline = Date.now() + timeout
  while (!(await holds())) {
    if (process !== undefined && !running(process)) {
      throw new Error(`waiting for ${what}: the process exited, and said:\n${process.output()}`)
    }
    if (Date.now() > deadline) {
      const said = process === undefined ? "" : `, and the process said:\n${process.output()}`
      throw new Error(`waiting for ${what}: still false after ${timeout / 1000}s${said}`)
    }
    await sleep(100)
  }
}

/** Stop `process` with `signal`, killing it if it outlives `grace`; reports how it ended. */
async function stop(process: Process, signal: NodeJS.Signals, grace: number): Promise<string> {
  if (!running(process)) {
    return `exit ${await process.exited}`
  }
  process.child.kill(signal)
  const ended = await Promise.race([process.exited, sleep(grace).then(() => undefined)])
  if (ended === undefined) {
    process.child.kill("SIGKILL")
    await process.exited
    return "kill"
  }
  return ended === "0" ? "interrupt" : `exit ${ended}`
}

/**
 * `slidev dev` takes its port as given, so a port in use is an error rather than a deck served
 * elsewhere. The gap between releasing this one and Slidev binding it is a race; lost, it fails
 * the run rather than hiding.
 */
async function freePort(): Promise<number> {
  const server = createServer().listen(0, "127.0.0.1")
  await new Promise((done) => server.once("listening", done))
  const address = server.address()
  await new Promise((done) => server.close(done))
  assert.ok(address !== null && typeof address !== "string")
  return address.port
}

/**
 * The fixture deck, naming a copy of its notebook, in a directory of its own beside the fixture.
 * Pluto rewrites the notebook it opens, so the kernel gets a copy; the deck stays inside the
 * workspace so Slidev resolves its addons.
 */
function workspace(): { deck: string; notebook: string } {
  const notebook = join(mkdtempSync(join(tmpdir(), "pluto-live-")), "browser.jl")
  copyFileSync(NOTEBOOK, notebook)
  const named = /^ {2}notebook: .*$/m
  const source = readFileSync(FIXTURE, "utf8")
  assert.match(source, named, `${FIXTURE} names no notebook to point at the copy`)
  const deck = join(mkdtempSync(join(dirname(FIXTURE), ".browser-")), basename(FIXTURE))
  writeFileSync(deck, source.replace(named, `  notebook: ${notebook}`))
  return { deck, notebook }
}

/** Every Julia process descended from `root`: the server and each notebook's worker. */
function juliaProcesses(root: number): number[] {
  const table = execFileSync("ps", ["-A", "-o", "pid=,ppid=,comm="], { encoding: "utf8" })
  const rows = table
    .split("\n")
    .map((line) => line.trim().split(/\s+/))
    .map(([pid, ppid, command]) => ({ pid: Number(pid), ppid: Number(ppid), command }))
  const tree = [root]
  for (const pid of tree) {
    tree.push(...rows.filter((row) => row.ppid === pid).map((row) => row.pid))
  }
  return rows.filter((row) => tree.includes(row.pid) && row.command === "julia").map((r) => r.pid)
}

/** Whether `pid` has not exited; a zombie has, and only awaits its reaping. */
function alive(pid: number): boolean {
  try {
    const state = execFileSync("ps", ["-o", "stat=", "-p", String(pid)], { encoding: "utf8" })
    return !state.trim().startsWith("Z")
  } catch {
    return false
  }
}

/** Every console error, uncaught exception and browser log error `page` produces. */
function watchProblems(page: Page): string[] {
  const problems: string[] = []
  page.on("console", (message) => {
    if (message.type() === "error" || message.type() === "assert") {
      problems.push(`console.${message.type()}: ${message.text()}`)
    }
  })
  // A DOMException thrown in the page arrives with an empty `stack`, so the name and message
  // are what identify it.
  page.on("pageerror", (error) => problems.push(`uncaught ${String(error)}`))
  return problems
}

/**
 * Every bond write `page` sends to Pluto. The websocket is the only place a write the kernel
 * receives differs from one a widget merely attempted, since Rainbow drops a write that changes
 * nothing. The frame is MessagePack, whose strings are their own bytes, so reading it as Latin-1
 * finds the names in it.
 */
function watchBondWrites(page: Page): string[] {
  const writes: string[] = []
  page.on("websocket", (socket) =>
    socket.on("framesent", ({ payload }) => {
      const text = typeof payload === "string" ? payload : payload.toString("latin1")
      if (text.includes("update_notebook") && text.includes("bonds")) {
        writes.push(text)
      }
    }),
  )
  return writes
}

/**
 * Every Plotly version a plot cell the kernel sent `page` asks for, read off the websocket, since
 * a painted card keeps no copy of the script that drew it.
 */
function watchPlotlyVersionsAsked(page: Page): Set<string> {
  const asked = new Set<string>()
  page.on("websocket", (socket) =>
    socket.on("framereceived", ({ payload }) => {
      const text = typeof payload === "string" ? payload : payload.toString("latin1")
      for (const [, version] of text.matchAll(/plutoplotly_imports\?\.\['([^']+)'\]/g)) {
        asked.add(version ?? "")
      }
    }),
  )
  return asked
}

/**
 * The resident size of every renderer, in kilobytes. The renderer 027 measured held 7.0 GB of
 * Blink strings against a 40.6 MB JavaScript heap, so only the process's own resident size sees
 * this class of bug, and only Linux publishes it in `/proc`.
 */
async function rendererResidentKb(browser: Browser): Promise<number[]> {
  const cdp = await browser.newBrowserCDPSession()
  const { processInfo } = await cdp.send("SystemInfo.getProcessInfo")
  await cdp.detach()
  return processInfo
    .filter((info) => info.type === "renderer")
    .flatMap((info) => {
      try {
        const rss = /VmRSS:\s+(\d+) kB/.exec(readFileSync(`/proc/${info.id}/status`, "utf8"))
        return rss?.[1] === undefined ? [] : [Number(rss[1])]
      } catch {
        return []
      }
    })
}

/**
 * Move the frequency slider on the showing slide the way a hand would, through the event Pluto's
 * bond listener waits on, and return the value it settled on.
 */
function moveTheSlider(page: Page, value: number): Promise<string> {
  const slider = page.locator(`${SHOWING_SLIDE} ${FREQUENCY_COPIES}`)
  return slider.evaluate((input: HTMLInputElement, to) => {
    input.value = to
    input.dispatchEvent(new Event("input", { bubbles: true }))
    return input.value
  }, String(value))
}

const sliderValues = (page: Page) =>
  page
    .locator(FREQUENCY_COPIES)
    .evaluateAll((inputs: HTMLInputElement[]) => inputs.map((i) => i.value))

const copiesShow = async (page: Page, value: number) =>
  (await sliderValues(page)).every((shown) => shown === String(value))

const readoutShows = (page: Page, cycles: number) =>
  page.evaluate(
    (text) => document.querySelector('[data-card="readout"]')?.textContent.includes(text),
    `cycles ${cycles}`,
  )

const allLive = (page: Page) =>
  page
    .locator(".pluto-card")
    .evaluateAll((cards: HTMLElement[]) => cards.every((c) => c.dataset.source === "live"))

const frequencyWrites = (writes: string[]) => writes.filter((w) => w.includes("freq")).length

describe("a live deck in a real browser", () => {
  const { deck, notebook } = workspace()
  let slidev: Process | undefined
  let browser: Browser | undefined
  let context: BrowserContext
  let view: Page
  let url: string
  let viewProblems: string[]
  let viewWrites: string[]
  let viewPlotlyAsked: Set<string>
  let mutations: Awaited<ReturnType<typeof countCardMutations>>
  /** Every Julia process this run started, once its kernel is up. */
  let julia: number[] = []

  before(async () => {
    const port = await freePort()
    url = `http://localhost:${port}`
    const args = [deck, "--port", String(port), "--open", "false"]
    slidev = start(join(SLIDES, "node_modules/.bin/slidev"), args, SLIDES)
    const serving = () => fetch(url).then((r) => r.ok, () => false)
    await until(`slidev to serve ${url}`, serving, SLIDEV_TIMEOUT, slidev)

    // Every assertion runs in a browser that can reach nothing but this machine, so "the plot
    // draws" is a statement about a lecture hall with no wifi rather than about this desk. The
    // full Chromium rather than the headless shell, which refuses the wake lock Slidev requests.
    browser = await chromium.launch({ channel: "chromium", args: [NO_NETWORK] })
    context = await browser.newContext()
    view = await context.newPage()
    viewProblems = watchProblems(view)
    viewWrites = watchBondWrites(view)
    viewPlotlyAsked = watchPlotlyVersionsAsked(view)
    await view.addInitScript(RECORD_CARD_SOURCES + ";" + WATCH_DATA_URLS)
    await view.goto(`${url}/#/2`, { timeout: NAVIGATION_TIMEOUT })

    const kernelUp = () => view.evaluate(() => document.body.dataset.kernel === "ready")
    await until("slidev to bring the kernel up", kernelUp, KERNEL_TIMEOUT, slidev)
    julia = slidev.child.pid === undefined ? [] : juliaProcesses(slidev.child.pid)
  })

  after(async () => {
    await browser?.close()
    if (slidev !== undefined) {
      await stop(slidev, "SIGTERM", SHUTDOWN_TIMEOUT)
    }
    // Only a run that failed to stop its kernel leaves one here for the next run to trip over.
    for (const pid of julia.filter(alive)) {
      process.kill(pid, "SIGKILL")
    }
    rmSync(dirname(deck), { recursive: true, force: true })
    rmSync(dirname(notebook), { recursive: true, force: true })
  })

  it("is served over HTTP, not loaded from disk", async () => {
    assert.equal(await view.evaluate(() => location.protocol), "http:")
    assert.equal(await view.evaluate(() => location.origin), url)
  })

  it("shows every card's live output", async () => {
    // `every` over no cards is true, so the count comes first. Eleven: four cards on the second
    // slide, five on the third, and the two inputs in the bond layer. The fourth slide opts out
    // of preloading.
    const cards = view.locator(".pluto-card")
    await until("every card to mount", async () => (await cards.count()) === 11)
    await until("every card to go live", () => allLive(view))
    assert.equal(await view.evaluate(() => document.body.dataset.kernel), "ready")
    const readout = view.locator('.slidev-page [data-card="readout"]').first()
    assert.equal((await readout.textContent())?.trim(), "cycles 1")
  })

  it("shows a placeholder on a card before it is live", async () => {
    const sources = await view.evaluate<string[][]>(
      '[...document.querySelectorAll(".pluto-card")].map((c) => c.__sources ?? [])',
    )
    assert.equal(sources.length, 11)
    for (const seen of sources) {
      assert.deepEqual(seen, ["placeholder", "live"])
    }
  })

  it("reports every input's value with no slide visited", async () => {
    // The plot reads `amplitude` with no fallback for `missing`, and its only slide opts out of
    // preloading, so the plot draws here only if the bond layer reported the input.
    assert.equal(await view.locator('.slidev-page [data-card="amplitude"]').count(), 0)
    assert.deepEqual(
      await view
        .locator(".pluto-bond-layer .pluto-card")
        .evaluateAll((cards: HTMLElement[]) => cards.map((c) => c.dataset.card).sort()),
      ["amplitude", "frequency"],
    )
    const line = view.locator('.slidev-page [data-card="wave"] path.js-line')
    await until(
      "the plot to draw from an input on an unvisited slide",
      async () => (await line.count()) > 0,
    )
  })

  it("puts no shadow root between a card's output and the document", async () => {
    // Pluto's renderer resolves a `published_to_js` payload through `closest("pluto-cell")`, and
    // the addon's stylesheet reaches card output from the document; neither crosses a shadow
    // boundary. A card would report `live` and draw nothing, with a clean console.
    const shadowed = await view.locator(".pluto-card").evaluateAll((cards) => {
      const found = new Set<string>()
      for (const card of cards) {
        for (let node: Element | null = card; node !== null; node = node.parentElement) {
          if (node.shadowRoot !== null) {
            found.add(node.tagName.toLowerCase())
          }
        }
      }
      return [...found]
    })
    assert.deepEqual(shadowed, [])
    assert.equal(
      await view
        .locator(".pluto-card-body pluto-cell")
        .evaluateAll((cells) => cells.every((cell) => cell.closest("pluto-cell") === cell)),
      true,
    )
  })

  it("renders a Plotly card interactive, which is the published_to_js path", async () => {
    await until(
      "both copies of the plot to draw",
      async () => (await view.locator('[data-card="wave"] .js-plotly-plot').count()) === 2,
    )
    assert.ok((await view.locator('[data-card="wave"] .modebar').count()) > 0)
  })

  it("draws the lines of a plot placed on two slides on both", async () => {
    // One cell, two cards, one published payload. A draw that writes to what it was given breaks
    // the next one, which then holds its data with nothing drawn.
    const drawn = await view
      .locator('[data-card="wave"]')
      .evaluateAll((cards) => cards.map((card) => card.querySelectorAll("path.js-line").length))
    assert.equal(drawn.length, 2)
    for (const lines of drawn) {
      assert.ok(lines > 0)
    }
  })

  it("sizes a figure to its card on a scaled slide", async () => {
    // Slidev scales a slide with a transform; layout sizes on both sides free the ratio of it.
    const filled = () =>
      view.locator(`${SHOWING_SLIDE} [data-card="wave"]`).evaluate((card) => {
        const plot = card.querySelector<HTMLElement>(".js-plotly-plot")
        const body = card.querySelector<HTMLElement>(".pluto-card-body")
        if (plot === null || body === null) {
          return false
        }
        const ratios = [plot.offsetWidth / body.offsetWidth, plot.offsetHeight / body.offsetHeight]
        return ratios.every((ratio) => ratio >= 0.98 && ratio <= 1.02)
      })
    const transform = view.locator("#slide-content").evaluate((s) => getComputedStyle(s).transform)
    assert.notEqual(await transform, "none")
    assert.ok(await filled())

    // The copy on the next slide was painted while hidden, at no size at all.
    await view.keyboard.press("ArrowRight")
    await until("the deck to page forward", () => view.evaluate(() => location.hash === "#/3"))
    await until("the plot painted while hidden to fill its card once shown", filled)
    await view.keyboard.press("ArrowLeft")
    await until("the deck to page back", () => view.evaluate(() => location.hash === "#/2"))
  })

  it("serves Plotly from the deck, never importing it out of a string", async () => {
    // Shipped through notebook state, the library arrives as a string and PlutoPlotly imports it
    // from a `data:` URL of 4.76 MB of base64, which Chrome answers with gigabytes. See issue 027.
    assert.equal(
      await view.locator('link[rel="plotly-source"]').evaluate((l: HTMLLinkElement) => l.href),
      `${url}/pluto/plotly.min.js`,
    )
    // Appended by the loader rather than written into the page, so this also says a card asked.
    assert.equal(await view.locator('script[src$="/pluto/plotly.min.js"]').count(), 1)
    const scripts = 'window.__dataUrls.filter((r) => r.type.includes("javascript"))'
    assert.deepEqual(await view.evaluate<unknown[]>(scripts), [])
  })

  it("draws a plot with the Plotly version the deck serves, not one off a CDN", async () => {
    // A plot cell reads `window.plutoplotly_imports[<version>]` and falls through to esm.sh for
    // any other key, which with the network cut draws nothing at all.
    const source = view.locator('link[rel="plotly-source"]')
    const version = await source.evaluate((l: HTMLElement) => l.dataset.version)
    const imports = await view.evaluate<string[]>("Object.keys(window.plutoplotly_imports ?? {})")
    assert.deepEqual(imports, [version])
    // The key a plot cell asks for is the one PlutoPlotly picked in Julia, so a bumped PlutoPlotly
    // has to move `plotly.js-dist-min` and the link's `data-version` with it.
    assert.ok(viewPlotlyAsked.size > 0)
    assert.deepEqual([...viewPlotlyAsked], [version])
  })

  it(
    "keeps the renderer a browser tab, not a memory incident",
    { skip: process.platform !== "linux" && "the renderer's resident size is read from /proc" },
    async () => {
      // The bound allows for Slidev and Vite's dev client.
      assert.ok(browser !== undefined)
      const resident = await rendererResidentKb(browser)
      assert.ok(resident.length > 0)
      assert.ok(Math.max(...resident) < 800 * 1024, `renderers hold ${resident.join(", ")} kB`)
    },
  )

  it("says where a card past the grid's edge is instead of what it holds", async () => {
    const misplaced = view.locator(".course-card[data-misplaced]")
    assert.equal(await misplaced.count(), 1)
    const text = (await misplaced.textContent()) ?? ""
    assert.ok(text.includes("x=10 y=10 w=4 h=2 does not fit a 12 × 12 Grid"), text)
    assert.ok(!text.includes("past the grid's edge"), text)
  })

  it("renders a plain-text body as text, not as markup", async () => {
    const plain = view.locator('[data-card="plain"]').first()
    assert.ok(((await plain.textContent()) ?? "").includes("<b>not bold</b>"))
    assert.equal(await plain.locator("b, script").count(), 0)
  })

  it("draws a card's math rather than leaving the dollars the cell was written in", async () => {
    // The markup is the kernel's own: PlutoRunner's Markdown writer marks the display formula up
    // as `p.tex` and the two inline ones as `span.tex`.
    const formula = view.locator('.slidev-page [data-card="formula"]').first()
    assert.equal(await formula.locator("p.tex").count(), 1)
    assert.equal(await formula.locator("span.tex").count(), 2)
    await until(
      "every formula on the card to be typeset",
      async () => (await formula.locator("mjx-container svg").count()) === 3,
    )
    assert.equal(await formula.locator("mjx-container[display=true]").count(), 1)
    // Slidev's reset makes an SVG a block, which breaks the sentence at each inline formula.
    assert.ok(
      await formula
        .locator("span.tex svg")
        .evaluateAll((svgs) => svgs.every((svg) => getComputedStyle(svg).display === "inline")),
    )
    // SVG output is glyph paths; a screen reader reads the assistive MathML beside each one.
    assert.equal(await formula.locator("mjx-assistive-mml math").count(), 3)
    const text = (await formula.textContent()) ?? ""
    assert.ok(!text.includes("$"), text)
    assert.ok(!text.includes("frac"), text)
  })

  it("serves MathJax from the deck, never fetching it from a network", async () => {
    assert.equal(
      await view.locator('link[rel="mathjax-source"]').evaluate((l: HTMLLinkElement) => l.href),
      `${url}/pluto/tex-svg-full.js`,
    )
    assert.equal(await view.locator('script[src$="/pluto/tex-svg-full.js"]').count(), 1)
    const sources = await view
      .locator("script[src]")
      .evaluateAll((scripts: HTMLScriptElement[]) => scripts.map((s) => s.src))
    assert.ok(sources.every((src) => src.startsWith(url)), sources.join("\n"))
  })

  it("lets an arrow key inside a widget drive the widget, not the deck", async () => {
    // A lecturer nudging a gain one step must not be thrown onto the next slide for it.
    const slider = view.locator(`.slidev-page ${FREQUENCY_COPIES}`).first()
    await slider.focus()
    const before = await slider.inputValue()
    await view.keyboard.press("ArrowRight")
    assert.equal(await view.evaluate(() => location.hash), "#/2")
    assert.notEqual(await slider.inputValue(), before)
    await slider.blur()
  })

  it("writes a Julia-defined widget's value back to the kernel", async () => {
    mutations = await countCardMutations(view)
    assert.equal(await moveTheSlider(view, 4), "4")
    await until("the readout to follow the slider", () => readoutShows(view, 4))
  })

  it("does not repaint a card when an unrelated cell re-runs", async () => {
    // Repainting rebuilds a card's scripts against whatever payload they read: work, not a
    // wrong value.
    const counts = await mutations.jsonValue()
    assert.ok((counts.readout ?? 0) > 0)
    assert.ok((counts.wave ?? 0) > 0)
    assert.ok((counts["formula-live"] ?? 0) > 0)
    assert.equal(counts.constant, 0)
    assert.equal(counts.plain, 0)
    assert.equal(counts.formula, 0)
  })

  it("still draws a formula on a card that re-ran", async () => {
    // A repaint replaces what MathJax drew, and MathJax finds its own output by `contains`, so
    // the next pass has to draw the new body rather than leave the delimiters.
    const live = view.locator('[data-card="formula-live"]').first()
    await until("the live formula card to follow the slider", async () =>
      ((await live.textContent()) ?? "").includes("cycles 4"),
    )
    await until(
      "the repainted formula to be drawn again",
      async () => (await live.locator("mjx-container svg defs path[d]").count()) > 0,
    )
    assert.ok(!((await live.textContent()) ?? "").includes("$"))
  })

  it("brings every copy of a widget to its bond, sending one write", async () => {
    // The slider sits on two slides and in the bond layer; a copy left behind is a slider that
    // disagrees with the plot on the next slide.
    assert.equal(await view.locator(FREQUENCY_COPIES).count(), 3)
    const before = frequencyWrites(viewWrites)
    assert.equal(await moveTheSlider(view, 5), "5")
    await until("the readout to follow the slider", () => readoutShows(view, 5))
    // A copy that followed by re-sending would write after the run settles, so the count is read
    // once a second write has had time to be collected, sent and settled.
    await sleep(2000)
    assert.deepEqual(await sliderValues(view), ["5", "5", "5"])
    assert.equal(frequencyWrites(viewWrites) - before, 1)
  })

  describe("presenter mode, opened beside a room already running", () => {
    // A window opened on its own reports its inputs, as some window must; the guarantee covers
    // one opened beside the audience's.
    let presenter: Page
    let presenterProblems: string[]
    let presenterWrites: string[]

    before(async () => {
      presenter = await context.newPage()
      presenterProblems = watchProblems(presenter)
      presenterWrites = watchBondWrites(presenter)
      await presenter.goto(`${url}/#/presenter/2`, { timeout: NAVIGATION_TIMEOUT })
    })

    // A page in a background tab gets no animation frames, which Plotly draws on.
    after(() => view.bringToFront())

    it("renders live cards, and opening it writes no bonds", async () => {
      const cards = presenter.locator(".pluto-card")
      await until(
        "the presenter's cards to go live",
        async () => (await cards.count()) > 0 && (await allLive(presenter)),
      )
      const line = presenter.locator('[data-card="wave"] path.js-line')
      await until("the presenter's plot to draw", async () => (await line.count()) > 0)
      assert.ok(await copiesShow(presenter, 5))
      // Long enough for the bond layer's widgets to have reported, had they been going to write.
      await sleep(3000)
      assert.deepEqual(presenterWrites, [])
    })

    it("moves a widget's copies in one window when it moves in the other", async () => {
      assert.equal(await moveTheSlider(view, 3), "3")
      await until("the presenter's sliders to follow the audience window's", () =>
        copiesShow(presenter, 3),
      )
      assert.deepEqual(presenterWrites, [])
    })

    it("reports no console error of its own", () => {
      assert.deepEqual(presenterProblems.filter((p) => !p.includes(SLIDEV_NOISE)), [])
    })
  })

  it("follows the deck into dark mode with a Julia-rendered plot", async () => {
    // A plot's paper is in the payload the kernel sent, so this asserts the whole pipe: a media
    // query in the browser, the `deck_theme` bond, a template chosen in Julia, a repaint.
    const plot = `document.querySelector('.slidev-page [data-card="wave"] .js-plotly-plot')`
    const paper = () => view.evaluate<unknown>(`${plot}?.layout?.template?.layout?.paper_bgcolor`)
    assert.equal(await paper(), "white")
    await view.emulateMedia({ colorScheme: "dark" })
    await until(
      "the plot to repaint against the dark template",
      async () => (await paper()) === "rgb(17,17,17)",
    )
  })

  it("names a card the notebook does not declare", async () => {
    // Last of the tests that read the second slide, since this pages away from it.
    await view.evaluate(() => (location.hash = "#/5"))
    const unknown = view.locator('.slidev-page [data-card="not-in-the-notebook"]')
    await until("the unknown card to report itself", () =>
      unknown.evaluateAll((cards: HTMLElement[]) => cards[0]?.dataset.source === "unknown"),
    )
    assert.equal(
      (await unknown.first().textContent())?.trim(),
      'the notebook declares no card "not-in-the-notebook"',
    )
  })

  it("shows a Julia error on no card", async () => {
    // A cell that threw renders as `<jlerror>`, reports `live` like any other card, and logs
    // nothing.
    assert.equal(await view.locator(".pluto-card jlerror").count(), 0)
  })

  it("reports no console error of its own", () => {
    assert.deepEqual(viewProblems.filter((p) => !p.includes(SLIDEV_NOISE)), [])
  })

  describe("stopping", () => {
    let stopped: string

    before(async () => {
      await browser?.close()
      // What a terminal sends slidev on Ctrl-C when its stdin is not a terminal.
      stopped =
        slidev === undefined ? "never started" : await stop(slidev, "SIGINT", SHUTDOWN_TIMEOUT)
    })

    it("leaves no Julia process behind", async () => {
      // The Pluto server and the notebook's worker, at least.
      assert.ok(julia.length >= 2, `the kernel ran as ${julia.join(", ")}`)
      assert.notEqual(stopped, "kill", "slidev outlived an interrupt")
      await until("every Julia process to exit", () => !julia.some(alive), 10_000)
    })
  })
})

describe("a live deck attached to a running Pluto server", () => {
  const { deck, notebook } = workspace()
  let pluto: ReturnType<typeof supervise> | undefined
  let plutoOutput = ""
  let plutoUrl: string
  let slidev: Process | undefined
  let browser: Browser | undefined
  let page: Page
  /** The attached server and its notebook's worker, which the deck must leave running. */
  let attached: number[] = []

  before(async () => {
    const plutoPort = await freePort()
    plutoUrl = `http://127.0.0.1:${plutoPort}`
    const args = ["--startup-file=no", `--project=${KERNEL}`, "-e", PLUTO_WITHOUT_SECRET]
    pluto = supervise(process.env.JULIA ?? "julia", [...args, String(plutoPort), notebook], (l) => {
      plutoOutput += `${l}\n`
    })
    let plutoExited = false
    void pluto.exited.then(() => (plutoExited = true))
    // Pluto opens its notebooks before it listens, so a list that answers names this one.
    const listing = async () => {
      if (plutoExited) {
        throw new Error(`Pluto exited, and said:\n${plutoOutput}`)
      }
      return fetch(`${plutoUrl}/notebooklist`).then((r) => r.ok, () => false)
    }
    await until("Pluto to list its notebooks", listing, KERNEL_TIMEOUT)

    const port = await freePort()
    const url = `http://localhost:${port}`
    const env = { ...process.env, PLUTO_URL: plutoUrl, PLUTO_SECRET: "" }
    const slidevArgs = [deck, "--port", String(port), "--open", "false"]
    slidev = start(join(SLIDES, "node_modules/.bin/slidev"), slidevArgs, SLIDES, env)
    const serving = () => fetch(url).then((r) => r.ok, () => false)
    await until(`slidev to serve ${url}`, serving, SLIDEV_TIMEOUT, slidev)

    browser = await chromium.launch({ channel: "chromium", args: [NO_NETWORK] })
    page = await (await browser.newContext()).newPage()
    await page.goto(`${url}/#/2`, { timeout: NAVIGATION_TIMEOUT })
    const kernelUp = () => page.evaluate(() => document.body.dataset.kernel === "ready")
    await until("the attached kernel to come up", kernelUp, KERNEL_TIMEOUT, slidev)
    attached = pluto.pid === undefined ? [] : juliaProcesses(pluto.pid)
  })

  after(async () => {
    await browser?.close()
    if (slidev !== undefined) {
      await stop(slidev, "SIGTERM", SHUTDOWN_TIMEOUT)
    }
    await pluto?.stop()
    for (const pid of attached.filter(alive)) {
      process.kill(pid, "SIGKILL")
    }
    rmSync(dirname(deck), { recursive: true, force: true })
    rmSync(dirname(notebook), { recursive: true, force: true })
  })

  it("starts no Julia of its own", () => {
    assert.ok(slidev?.child.pid !== undefined)
    assert.deepEqual(juliaProcesses(slidev.child.pid), [])
  })

  it("warns in the terminal that the server has no secret", () => {
    assert.match(slidev?.output() ?? "", /\[pluto\] warning: .*no secret/)
  })

  it("shows every card's live output", async () => {
    const cards = page.locator(".pluto-card")
    await until("every card to mount", async () => (await cards.count()) === 11)
    await until("every card to go live", () => allLive(page))
  })

  describe("stopping", () => {
    let stopped: string

    before(async () => {
      await browser?.close()
      stopped =
        slidev === undefined ? "never started" : await stop(slidev, "SIGINT", SHUTDOWN_TIMEOUT)
    })

    it("leaves the attached server running", async () => {
      assert.notEqual(stopped, "kill", "slidev outlived an interrupt")
      assert.ok(attached.length >= 2, `the attached kernel ran as ${attached.join(", ")}`)
      assert.deepEqual(attached.filter((pid) => !alive(pid)), [])
      assert.ok((await fetch(`${plutoUrl}/ping`)).ok)
    })

    it("lets whoever started the server stop it", async () => {
      await pluto?.stop()
      await until("the attached server to exit", () => !attached.some(alive), 10_000)
    })
  })
})

/**
 * Count every DOM change inside each card on a slide from here on. A card that repaints when an
 * unrelated cell re-runs is a performance bug, visible only as work done.
 */
function countCardMutations(page: Page) {
  return page.evaluateHandle(() => {
    const counts: Record<string, number> = {}
    for (const card of document.querySelectorAll<HTMLElement>(".slidev-page .pluto-card")) {
      const name = card.dataset.card ?? ""
      counts[name] ??= 0
      new MutationObserver((records) => {
        counts[name] = (counts[name] ?? 0) + records.length
      }).observe(card, { childList: true, subtree: true, characterData: true })
    }
    return counts
  })
}
