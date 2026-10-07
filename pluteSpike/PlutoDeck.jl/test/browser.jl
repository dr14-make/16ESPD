# Live cards, driven in real headless Chrome: a Slidev deck naming the `pluto` addon, served by
# `slidev dev`, against a real kernel `present` brought up.
#
# Everything here is asserted through the DOM the browser actually built, over HTTP, because the
# two bugs that cost this project the most were invisible to anything less: a missing `process`
# shim that Node supplies for free, and a static handler that was never exercised because the
# page had been loaded from disk.

include("devtools.jl")

import Sockets

using PlutoDeck: present

const BROWSER_NOTEBOOK = joinpath(FIXTURES, "browser.jl")

"The Slidev workspace, and the fixture deck in it that this suite drives."
const SLIDES = normpath(joinpath(@__DIR__, "..", "..", "..", "slides"))
const FIXTURE_DECK = joinpath("pluto-fixture", "fixture.md")

"How long `present` may take to serve its first page, in seconds. A cold kernel is most of it."
const PRESENT_TIMEOUT = 300.0

"How long `slidev dev` may take to answer, in seconds."
const SLIDEV_TIMEOUT = 60.0

"How long `present` may take to bring its kernel down after the interrupt, in seconds."
const SHUTDOWN_TIMEOUT = 60.0

"""
The deck `present` serves the session and the card index for, in a directory of its own.

Pluto rewrites every notebook it opens, so a fixture is copied out of the repository before a
kernel is pointed at it. The slides are the Slidev fixture's; this file only names the notebook.
"""
function browser_workspace()
    workspace = mktempdir()
    cp(BROWSER_NOTEBOOK, joinpath(workspace, "browser.jl"))
    path = joinpath(workspace, "browser.deck.json")
    write(path, """{ "notebook": "browser.jl", "slides": [] }""")
    return path
end

"""
    free_port() -> Int

A port nothing is listening on.

`present` takes its port as given, so that a port in use is an error rather than a deck quietly
served somewhere else. Nothing can hold one open for it, so the gap between letting go here and
`present` binding there is a race — lost, it fails the run rather than hiding.
"""
function free_port()
    socket = Sockets.listen(Sockets.localhost, 0)
    port = Int(Sockets.getsockname(socket)[2])
    close(socket)
    return port
end

"Whether something is answering on `url` yet."
function serving(url::AbstractString)
    try
        return HTTP.get(url; retry=false, status_exception=false, connect_timeout=1).status == 200
    catch
        return false
    end
end

"Wait for `url` to answer, failing with `process`'s output if it exits or takes too long."
function await_serving(url::AbstractString, process::Base.Process, log::AbstractString, timeout::Real)
    deadline = time() + timeout
    while !serving(url)
        Base.process_running(process) ||
            error("the process exited before it served $url:\n", read(log, String))
        time() > deadline &&
            error("nothing served $url within $(timeout)s:\n", read(log, String))
        sleep(0.2)
    end
end

"""
    with_present(body, deck_path) -> String

Run `body(url)` against a deck `present` is serving, and stop it the way its own last line
says to, however `body` ends.

Returns how `present` stopped rather than anything `body` produced, which asserts through
`@testset` as it goes: `"interrupt"` when the interrupt alone ended it cleanly, `"exit <code>"`
when it ended on its own terms but not cleanly, and `"kill"` when it had to be killed. Either
of the last two is a shutdown that did not finish.

In a process of its own, because blocking until interrupted is the whole of `present`'s
contract: one call brings up the kernel, the server and the pages, and Ctrl-C takes all three
down again.
"""
function with_present(body, deck_path::AbstractString)
    port = free_port()
    url = "http://localhost:$port"
    log = tempname()
    process = run(pipeline(`$(Base.julia_cmd()) --startup-file=no
            --project=$(Base.active_project())
            -e "using PlutoDeck; present(ARGS[1]; port = parse(Int, ARGS[2]))"
            $deck_path $port`; stdout=log, stderr=log); wait=false)

    stopped = ""
    try
        await_serving("$url/api/deck", process, log, PRESENT_TIMEOUT)
        body(url)
    finally
        kill(process, Base.SIGINT)
        killed = timedwait(() -> !Base.process_running(process), SHUTDOWN_TIMEOUT) !== :ok
        killed && kill(process)
        wait(process)
        stopped = killed ? "kill" :
            process.exitcode == 0 ? "interrupt" : "exit $(process.exitcode)"
        # What threw is in the process's own output, and it goes in the message rather than
        # beside it: a trace passed as a log value is shown middle-elided, and the elided middle
        # is the part that names what threw.
        stopped == "interrupt" ||
            @warn "present did not stop cleanly ($stopped), and said:\n" * read(log, String)
    end
    return stopped
end

"""
    with_slidev(body, api_url)

Run `body(url)` against `slidev dev` serving the fixture deck, its `/api` proxied to `api_url`,
and stop it however `body` ends.
"""
function with_slidev(body, api_url::AbstractString)
    port = free_port()
    url = "http://localhost:$port"
    log = tempname()
    slidev = joinpath(SLIDES, "node_modules", ".bin", "slidev")
    command = setenv(`$slidev $FIXTURE_DECK --port $port --open false`,
        merge(ENV, Dict("PLUTODECK_URL" => api_url)); dir=SLIDES)
    process = run(pipeline(command; stdout=log, stderr=log); wait=false)
    try
        await_serving(url, process, log, SLIDEV_TIMEOUT)
        body(url)
    finally
        kill(process)
        wait(process)
    end
end

"""
Record every `data-source` each card passes through, from before the deck's own scripts run.

By the time the harness can evaluate anything the deck has long since replaced its placeholders,
so the transition has to be recorded as it happens. A card is created already carrying its
first source, so its insertion is recorded as well as every change after it.
"""
const RECORD_CARD_SOURCES = """
;(() => {
  const record = (card) => {
    const seen = (card.__sources ??= [])
    const source = card.dataset.source
    // A repaint rewrites `live` over `live`, which is a mutation and not a transition.
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
  }).observe(document, { subtree: true, childList: true, attributes: true, attributeFilter: ["data-source"] })
})()
"""

"""
Record every `FileReader.readAsDataURL` this page performs, before anything can perform one.

The one call issue 027 traced cost the renderer ~7.1 GB, and it left no other trace: the bytes
it retained are Blink strings rather than JavaScript objects, and the URL is never written to
the DOM. Wrapping the call is what makes its absence assertable.
"""
const WATCH_DATA_URLS = """
;(() => {
  window.__dataUrls = []
  const original = FileReader.prototype.readAsDataURL
  FileReader.prototype.readAsDataURL = function (blob) {
    window.__dataUrls.push({ type: blob?.type ?? "", size: blob?.size ?? 0 })
    return original.call(this, blob)
  }
})()
"""

"""
Record every bond write this page sends to Pluto, before anything can send one.

A write is an `update_notebook` message carrying a `bonds` patch, and the websocket is the only
place a write the kernel receives can be told apart from one a widget merely attempted: Rainbow
drops a write that changes nothing before it reaches the wire. The message is MessagePack, whose
strings are their own bytes, so reading the frame as text is enough to find the names in it.
"""
const WATCH_BOND_WRITES = """
;(() => {
  window.__bondWrites = []
  const send = WebSocket.prototype.send
  WebSocket.prototype.send = function (data) {
    const text = typeof data === "string" ? data
      : data instanceof Blob ? "" : new TextDecoder("latin1").decode(data)
    if (text.includes("update_notebook") && text.includes("bonds")) window.__bondWrites.push(text)
    return send.call(this, data)
  }
})()
"""

"""
Count every DOM change inside each card on a slide from here on.

A card that repaints when an unrelated cell re-runs is not a correctness bug but a performance
one — repainting rebuilds the card's scripts against whatever payload they read — so it shows up
as work done, not as a wrong value.
"""
const COUNT_CARD_MUTATIONS = """
(() => {
  window.__mutations = {}
  for (const card of document.querySelectorAll(".slidev-page .pluto-card")) {
    const name = card.dataset.card
    window.__mutations[name] ??= 0
    new MutationObserver((records) => { window.__mutations[name] += records.length })
      .observe(card, { childList: true, subtree: true, characterData: true })
  }
  return true
})()
"""

"Every card on the page, on a slide or in the bond layer."
const CARDS = """[...document.querySelectorAll(".pluto-card")]"""

"The cards in the bond layer, which no slide shows."
const LAYER_CARDS = """[...document.querySelectorAll(".pluto-bond-layer .pluto-card")]"""

"The card whose cell carries math, in both the shapes PlutoRunner marks up."
const FORMULA_CARD = """document.querySelector('.slidev-page [data-card="formula"]')"""

"Every copy of the frequency slider, on slides and in the bond layer alike."
const FREQUENCY_COPIES = """[...document.querySelectorAll('[data-card="frequency"] bond input')]"""

"Whether every copy of the frequency slider shows `value`."
copies_show(value) = FREQUENCY_COPIES * """.every((i) => i.value === "$value")"""

"Whether the readout shows `cycles` cycles."
readout_shows(cycles) =
    """document.querySelector('[data-card="readout"]').textContent.includes("cycles $cycles")"""

"The slide that is showing. Slidev keeps the slides around it mounted with `display: none`."
const SHOWING_SLIDE = """.slidev-page:not([style*="display: none"])"""

"How many bond writes this page has sent that name the frequency."
const FREQUENCY_WRITES = """window.__bondWrites.filter((w) => w.includes("freq")).length"""

"""
Move the copy of the frequency slider on the slide that is showing to `value` the way a hand
would, through the event Pluto's bond listener waits on, and return the value it settled on.
"""
move_the_slider(value) = """
(() => {
  const input = document.querySelector('$SHOWING_SLIDE [data-card="frequency"] bond input')
  input.value = "$value"
  input.dispatchEvent(new Event("input", { bubbles: true }))
  return input.value
})()
"""

"""
The twoslash client Slidev bundles patches a FloatingVue that no deck installs, and logs that it
failed to: the one console error a page logs before any deck code has run.
"""
const SLIDEV_NOISE = r"Failed to patch FloatingVue"

@testset "browser" begin
    if chrome_binary() === nothing
        @warn "no Chrome on PATH; live cards go unverified in the only place they can be verified"
        @test_skip "live cards render against a live kernel in a real browser"
    elseif !isfile(joinpath(SLIDES, "node_modules", ".bin", "slidev"))
        @warn "the Slidev workspace is not installed; run `npm ci` in $SLIDES"
        @test_skip "live cards render in a Slidev deck"
    else
        presented = with_present(browser_workspace()) do api
            with_slidev(api) do url
            # Every assertion below is made on a browser that can reach nothing but this
            # machine, so "the plot draws" is a statement about a lecture hall with no wifi
            # rather than about this desk. A deck that let any library come off a CDN would fail
            # here and pass everywhere else.
            with_browser(; arguments=[NO_NETWORK]) do browser
                view = page(browser)
                navigate(browser, view, "$url/#/2";
                    before=RECORD_CARD_SOURCES * WATCH_DATA_URLS * WATCH_BOND_WRITES)

                @testset "the deck is served over HTTP, not loaded from disk" begin
                    @test evaluate(browser, view, "location.protocol") == "http:"
                    @test evaluate(browser, view, "location.origin") == url
                end

                @testset "every card shows its cell's live output" begin
                    # `every` over no cards is true, so the count comes first: an assertion that
                    # passes against an empty DOM is how a page that never rendered looks healthy.
                    # Eleven: four cards on the second slide, five on the third, and the two
                    # inputs in the bond layer. The fourth slide opts out of preloading.
                    await(browser, view, "$CARDS.length === 11"; what="every card to mount")
                    await(browser, view, """$CARDS.every((c) => c.dataset.source === "live")""";
                        what="every card to go live")
                    @test evaluate(browser, view, "document.body.dataset.kernel") == "ready"

                    @test evaluate(browser, view,
                        """document.querySelector('.slidev-page [data-card="readout"]').textContent.trim()""") ==
                        "cycles 1"
                end

                @testset "a card is a placeholder before it is live" begin
                    sources = JSON.parse(evaluate(browser, view,
                        "JSON.stringify($CARDS.map((c) => c.__sources ?? []))"))

                    @test length(sources) == 11
                    @test all(==(["placeholder", "live"]), sources)
                end

                @testset "every input reports its value with no slide visited" begin
                    # The plot reads `amplitude` with no fallback for `missing`, and the only
                    # slide carrying that input opts out of preloading, so the plot draws on
                    # this slide only if the bond layer reported the input's value.
                    @test evaluate(browser, view,
                        """document.querySelectorAll('.slidev-page [data-card="amplitude"]').length""") == 0
                    @test JSON.parse(evaluate(browser, view,
                        "JSON.stringify($LAYER_CARDS.map((c) => c.dataset.card).sort())")) ==
                        ["amplitude", "frequency"]
                    await(browser, view,
                        """document.querySelector('.slidev-page [data-card="wave"] path.js-line')""";
                        what="the plot to draw from an input on an unvisited slide")
                end

                @testset "nothing between a card's output and the document is a shadow root" begin
                    # Pluto's renderer resolves a `published_to_js` payload through
                    # `root_node.closest("pluto-cell")`, and `closest` does not cross a shadow
                    # boundary; the addon's stylesheet reaches a card's output from the
                    # document, and a document stylesheet does not either. A card would report
                    # `live` and draw nothing, with a clean console.
                    @test evaluate(browser, view, """
                        (() => {
                          const shadowed = []
                          for (const card of $CARDS) {
                            for (let node = card; node !== null; node = node.parentElement) {
                              if (node.shadowRoot !== null) shadowed.push(node.tagName.toLowerCase())
                            }
                          }
                          return JSON.stringify([...new Set(shadowed)])
                        })()
                        """) == "[]"

                    @test evaluate(browser, view, """
                        [...document.querySelectorAll(".pluto-card-body pluto-cell")]
                          .every((cell) => cell.closest("pluto-cell") === cell)
                        """) === true
                end

                @testset "a Plotly card renders interactive, which is the published_to_js path" begin
                    # PlutoPlotly ships the plot data through `published_to_js`, so a plot on
                    # screen is proof that a card reaches `notebook.published_objects` through
                    # its <pluto-cell> ancestor.
                    await(browser, view,
                        """document.querySelectorAll('[data-card="wave"] .js-plotly-plot').length === 2""";
                        what="both copies of the plot to draw")
                    @test evaluate(browser, view,
                        """!!document.querySelector('[data-card="wave"] .modebar')""") === true
                end

                @testset "a plot placed on two slides draws its lines on both" begin
                    # One cell, two cards, and one payload Pluto published for that cell. A draw
                    # that writes to what it was given breaks the next one after the traces are
                    # attached, so the card arrives holding its data with nothing drawn.
                    drawn = JSON.parse(evaluate(browser, view, """
                        JSON.stringify([...document.querySelectorAll('[data-card="wave"]')]
                          .map((card) => card.querySelectorAll("path.js-line").length))
                        """))

                    @test length(drawn) == 2
                    @test all(>(0), drawn)
                end

                @testset "a figure is as wide and as tall as its card on a scaled slide" begin
                    # Slidev scales a slide to the window with a transform, and a plot sized off
                    # its transformed rectangle is drawn at that scale inside its card. Layout
                    # sizes on both sides, so the ratio is free of the scale.
                    filled = """
                        (() => {
                          const card = document.querySelector('$SHOWING_SLIDE [data-card="wave"]')
                          const plot = card.querySelector(".js-plotly-plot")
                          const body = card.querySelector(".pluto-card-body")
                          return [plot.offsetWidth / body.offsetWidth, plot.offsetHeight / body.offsetHeight]
                        })()
                        """
                    @test evaluate(browser, view,
                        "getComputedStyle(document.querySelector('#slide-content')).transform") != "none"
                    @test all(ratio -> 0.98 <= ratio <= 1.02, evaluate(browser, view, filled))

                    # The copy on the next slide was painted while hidden, at no size at all.
                    press(browser, view, "ArrowRight")
                    await(browser, view, """location.hash === "#/3" """; what="the deck to page forward")
                    await(browser, view, "$filled.every((ratio) => ratio > 0.98 && ratio < 1.02)";
                        what="the plot painted while hidden to fill its card once shown")
                    press(browser, view, "ArrowLeft")
                    await(browser, view, """location.hash === "#/2" """; what="the deck to page back")
                end

                @testset "Plotly is served by the deck, never imported out of a string" begin
                    # The library reaches the browser as a file, over HTTP. Shipped through
                    # notebook state instead it arrives as a *string*, and PlutoPlotly invents
                    # a URL for it — `data:text/javascript` plus 4.76 MB of base64, which
                    # Chrome answers with gigabytes. See issue 027.
                    @test evaluate(browser, view,
                        """document.head.querySelector('link[rel="plotly-source"]').href""") ==
                        "$url/pluto/plotly.min.js"

                    # Appended by the loader rather than written into the page, so this is also
                    # what says a card asked for the library.
                    @test evaluate(browser, view, """
                        [...document.querySelectorAll("script[src]")]
                          .filter((s) => s.src.endsWith("/pluto/plotly.min.js")).length
                        """) == 1

                    @test JSON.parse(evaluate(browser, view,
                        "JSON.stringify(window.__dataUrls.filter((r) => r.type.includes('javascript')))")) == []
                end

                @testset "a plot draws with the version the deck serves, not one off a CDN" begin
                    # A plot cell reads `window.plutoplotly_imports[<version>]` and falls
                    # through to esm.sh for any other key. With the network cut, a plot that
                    # fell through draws nothing at all.
                    version = evaluate(browser, view,
                        """document.head.querySelector('link[rel="plotly-source"]').dataset.version""")
                    @test evaluate(browser, view,
                        "JSON.stringify(Object.keys(window.plutoplotly_imports ?? {}))") ==
                        JSON.json([version])
                end

                # `/proc` is the only instrument that sees these bytes, and it is Linux's.
                if Sys.islinux()
                    @testset "the renderer is a browser tab, not a memory incident" begin
                        # Read from the process rather than from `performance.memory`: the
                        # bytes a `data:` import retains are Blink strings, which no JS-heap
                        # reading sees. See issue 027 and `renderer_rss`. The bound allows for
                        # Slidev and Vite's dev client.
                        resident = renderer_rss(browser)
                        @test !isempty(resident)
                        @test maximum(resident) < 800 * 1024
                    end
                else
                    @test_skip "the renderer's resident size is read from /proc"
                end

                @testset "a card past the grid's edge says where it is instead of what it holds" begin
                    misplaced = """[...document.querySelectorAll(".course-card[data-misplaced]")]"""
                    @test evaluate(browser, view, "$misplaced.length") == 1
                    text = evaluate(browser, view, "$misplaced[0].textContent")
                    @test occursin("x=10 y=10 w=4 h=2 does not fit a 12 × 12 Grid", text)
                    @test !occursin("past the grid's edge", text)
                end

                @testset "a plain-text body renders as text, not as markup" begin
                    plain = """document.querySelector('[data-card="plain"]')"""

                    @test occursin("<b>not bold</b>", evaluate(browser, view, "$plain.textContent"))
                    @test evaluate(browser, view, "$plain.querySelector('b, script') === null") === true
                end

                @testset "a card's math is drawn, not left as the dollars the cell was written in" begin
                    # The markup is the kernel's own: PlutoRunner overrides Julia's Markdown
                    # HTML writer, so `Markdown.html` wrote the display paragraph and
                    # `Markdown.htmlinline` the two inline spans.
                    @test evaluate(browser, view, "$FORMULA_CARD.querySelectorAll('p.tex').length") == 1
                    @test evaluate(browser, view, "$FORMULA_CARD.querySelectorAll('span.tex').length") == 2

                    await(browser, view,
                        "$FORMULA_CARD.querySelectorAll('mjx-container svg').length === 3";
                        what="every formula on the card to be typeset")

                    @test evaluate(browser, view,
                        "$FORMULA_CARD.querySelectorAll('mjx-container[display=true]').length") == 1
                    # Slidev's reset makes an SVG a block, which breaks the sentence at each
                    # inline formula.
                    @test evaluate(browser, view, """
                        [...$FORMULA_CARD.querySelectorAll('span.tex svg')]
                          .every((svg) => getComputedStyle(svg).display === "inline")
                        """) === true

                    # SVG output is glyph paths and says nothing to a screen reader. What one
                    # reads is the assistive MathML beside each container.
                    @test evaluate(browser, view,
                        "$FORMULA_CARD.querySelectorAll('mjx-assistive-mml math').length") == 3

                    text = evaluate(browser, view, "$FORMULA_CARD.textContent")
                    @test !occursin("\$", text)
                    @test !occursin("frac", text)
                end

                @testset "MathJax is served by the deck, never fetched from a network" begin
                    @test evaluate(browser, view,
                        """document.head.querySelector('link[rel="mathjax-source"]').href""") ==
                        "$url/pluto/tex-svg-full.js"
                    @test evaluate(browser, view, """
                        [...document.querySelectorAll("script[src]")]
                          .filter((s) => s.src.endsWith("/pluto/tex-svg-full.js")).length
                        """) == 1
                    @test evaluate(browser, view, """
                        [...document.querySelectorAll("script[src]")]
                          .every((s) => s.src.startsWith(location.origin))
                        """) === true
                end

                @testset "an arrow key inside a widget drives the widget, not the deck" begin
                    # A range input is driven with the keys the deck navigates by, so a lecturer
                    # nudging a gain one step must not be thrown onto the next slide for it.
                    slider = """document.querySelector('.slidev-page [data-card="frequency"] bond input')"""
                    focus(browser, view, """.slidev-page [data-card="frequency"] bond input""")
                    before = evaluate(browser, view, "$slider.value")

                    press(browser, view, "ArrowRight")

                    @test evaluate(browser, view, "location.hash") == "#/2"
                    @test evaluate(browser, view, "$slider.value") != before
                    evaluate(browser, view, "document.activeElement.blur()")
                end

                @testset "a Julia-defined widget writes its value back to the kernel" begin
                    @test evaluate(browser, view, COUNT_CARD_MUTATIONS) === true
                    @test evaluate(browser, view, move_the_slider(4)) == "4"

                    await(browser, view, readout_shows(4);
                        what="the readout to follow the slider")
                end

                @testset "a card does not repaint when an unrelated cell re-runs" begin
                    mutations = JSON.parse(evaluate(browser, view, "JSON.stringify(window.__mutations)"))

                    @test mutations["readout"] > 0
                    @test mutations["wave"] > 0
                    @test mutations["formula-live"] > 0
                    @test mutations["constant"] == 0
                    @test mutations["plain"] == 0
                    @test mutations["formula"] == 0
                end

                @testset "a formula on a card that re-ran is still drawn" begin
                    # A repaint replaces what MathJax drew, and MathJax finds its own output by
                    # `contains` — so the pass that follows has to draw the new body rather than
                    # leave the card holding the delimiters it was given.
                    live = """document.querySelector('[data-card="formula-live"]')"""
                    await(browser, view, "$live.textContent.includes(\"cycles 4\")";
                        what="the live formula card to follow the slider")
                    await(browser, view,
                        "$live.querySelectorAll('mjx-container svg defs path[d]').length > 0";
                        what="the repainted formula to be drawn again")
                    @test !occursin("\$", evaluate(browser, view, "$live.textContent"))
                end

                @testset "every copy of a widget follows its bond, and only one write is sent" begin
                    # The slider sits on two slides and in the bond layer. Moving the copy on
                    # the slide that is showing must bring the others to the kernel's value, or
                    # the lecturer pages forward to a slider that disagrees with the plot.
                    @test evaluate(browser, view, "$FREQUENCY_COPIES.length") == 3
                    before = evaluate(browser, view, FREQUENCY_WRITES)

                    @test evaluate(browser, view, move_the_slider(5)) == "5"
                    await(browser, view, readout_shows(5);
                        what="the readout to follow the slider")
                    # A copy that followed by re-sending the value would write after the run
                    # settles, not during it, so the count is read once the queue has had time
                    # to collect, write and settle a second write.
                    sleep(2)

                    @test JSON.parse(evaluate(browser, view,
                        "JSON.stringify($FREQUENCY_COPIES.map((input) => input.value))")) == ["5", "5", "5"]
                    @test evaluate(browser, view, FREQUENCY_WRITES) - before == 1
                end

                @testset "presenter mode renders live cards, and opening it writes no bonds" begin
                    # Opened beside a room already running, which is what the guarantee covers.
                    # A window opened on its own reports its inputs, as some window must.
                    presenter = page(browser)
                    navigate(browser, presenter, "$url/#/presenter/2"; before=WATCH_BOND_WRITES)

                    await(browser, presenter,
                        """document.querySelectorAll('.pluto-card').length > 0 &&
                           [...document.querySelectorAll('.pluto-card')].every((c) => c.dataset.source === "live")""";
                        what="the presenter's cards to go live")
                    @test evaluate(browser, presenter,
                        """document.querySelectorAll('[data-card="wave"] path.js-line').length""") > 0
                    @test evaluate(browser, presenter, copies_show(5)) === true

                    # Long enough for the bond layer's widgets to have reported, had they been
                    # going to write.
                    sleep(3)
                    @test evaluate(browser, presenter, "window.__bondWrites.length") == 0

                    @testset "a widget moved in one window moves its copies in the other" begin
                        @test evaluate(browser, view, move_the_slider(3)) == "3"
                        await(browser, presenter,
                            copies_show(3);
                            what="the presenter's sliders to follow the audience window's")
                        @test evaluate(browser, presenter, "window.__bondWrites.length") == 0
                    end

                    @test filter(!contains(SLIDEV_NOISE), problems(browser, presenter)) == String[]

                    # A page in a background tab gets no animation frames, which Plotly draws on.
                    command(browser, "Page.bringToFront"; session=view)
                end

                @testset "a Julia-rendered plot follows the deck into dark mode" begin
                    # The one thing no stylesheet can reach: a plot's paper is in the payload the
                    # kernel sent. The deck writes `deck_theme`, the notebook picks its template
                    # off it, and the card repaints — so this asserts the whole pipe, from a
                    # media query in the browser to a color chosen in Julia.
                    paper = """document.querySelector('.slidev-page [data-card="wave"] .js-plotly-plot')
                                 ?.layout?.template?.layout?.paper_bgcolor"""
                    @test evaluate(browser, view, paper) == "white"

                    command(browser, "Emulation.setEmulatedMedia", Dict("features" =>
                        [Dict("name" => "prefers-color-scheme", "value" => "dark")]); session=view)

                    await(browser, view, """$paper === "rgb(17,17,17)" """;
                        what="the plot to repaint against the dark template")
                end

                @testset "no card is showing a Julia error" begin
                    # A cell that threw renders as `<jlerror>`, reports `live` like any other
                    # card, and logs nothing.
                    @test evaluate(browser, view, """document.querySelectorAll(".pluto-card jlerror").length""") == 0
                end

                @testset "the deck reports no console error of its own" begin
                    @test filter(!contains(SLIDEV_NOISE), problems(browser, view)) == String[]
                end
            end
            end
        end

        @testset "an interrupt is the whole of stopping a deck" begin
            # The lifecycle `present` prints as its last line, and the only one a lecturer has.
            # What the shutdown closes is a two-gigabyte worker; that it is gone is asserted in
            # `session.jl`, from the process that owns it.
            @test presented == "interrupt"
        end
    end
end
