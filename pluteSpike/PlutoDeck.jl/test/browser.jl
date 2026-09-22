# The deck, driven in real headless Chrome against a real kernel `present` brought up.
#
# Everything here is asserted through the DOM the browser actually built, over HTTP, because the
# two bugs that cost this project the most were invisible to anything less: a missing `process`
# shim that Node supplies for free, and a static handler that was never exercised because the
# page had been loaded from disk.

include("devtools.jl")

import Pluto
import Sockets

using PlutoDeck: Session, frontend_directory, load_deck, present, serve

const BROWSER_NOTEBOOK = joinpath(FIXTURES, "browser.jl")

"How long `present` may take to serve its first page, in seconds. A cold kernel is most of it."
const PRESENT_TIMEOUT = 300.0

"How long `present` may take to bring its kernel down after the interrupt, in seconds."
const SHUTDOWN_TIMEOUT = 60.0

"How long the page may take to report the websocket it cannot open, in seconds."
const OFFLINE_REPORT_TIMEOUT = 30.0

"""
The deck the browser drives, in a directory of its own.

Pluto rewrites every notebook it opens, so a fixture is copied out of the repository before a
kernel is pointed at it.
"""
function browser_workspace()
    workspace = mktempdir()
    cp(BROWSER_NOTEBOOK, joinpath(workspace, "browser.jl"))
    # Every construct the reveal.js deck's own notes use, so that what renders here is what a
    # lecturer already writes. Long enough to overflow the panel, which is the normal case.
    mkpath(joinpath(workspace, "notes"))
    write(joinpath(workspace, "notes", "wave.md"), CUE_MARKDOWN)
    # The plot is placed on both slides on purpose, and it is the second placement every
    # assertion about it reads. One cell rendered twice is the case that breaks a payload the
    # two draws share, and the second copy is also painted while its slide is hidden, which is
    # what tells `visibility: hidden` apart from `display: none`.
    write(joinpath(workspace, "browser.deck.json"), """
    {
      "notebook": "browser.jl",
      "preamble": ["plotly"],
      "slides": [
        {
          "title": "A wave you can drive",
          "notes": "notes/wave.md",
          "cards": [
            { "card": "frequency", "x": 0, "y": 0, "w": 4, "h": 2 },
            { "card": "readout", "x": 4, "y": 0, "w": 4, "h": 2 },
            { "card": "wave", "x": 0, "y": 2, "w": 8, "h": 6 }
          ]
        },
        {
          "cards": [
            { "card": "wave", "x": 0, "y": 0, "w": 8, "h": 6 },
            { "card": "constant", "x": 8, "y": 0, "w": 4, "h": 2 },
            { "card": "plain", "x": 8, "y": 2, "w": 4, "h": 2 }
          ]
        }
      ]
    }
    """)
    return load_deck(joinpath(workspace, "browser.deck.json"))
end

"""
The cues the browser reads, carrying the markdown a cue is actually written in.

`CUE_SENTENCE` is asserted against the rendered panel, and against everywhere it must not
appear: a cue is for the lecturer, and the room is looking at the same screen.
"""
const CUE_SENTENCE = "nothing here is precomputed"

const CUE_MARKDOWN = """
**Beat:** the wave, and the slider that drives it. ~4 minutes.

Open on *one* cycle and say what the axis is before touching anything. Then drag `freq` and
let the room watch the period halve. Drag [the slider](https://example.invalid/cue) rather
than typing a number — the point is that the kernel re-runs while they watch.

- start at one cycle
  - read the axis out loud
  - ask what four cycles will look like *before* dragging
- drag to four
  - the readout card follows, and so does the plot
- if the plot does not move, the kernel is still warming; keep talking

The sentence to land is that **$CUE_SENTENCE**: drag the slider and the whole notebook re-runs
between one frame and the next. That is the difference between this and a slide with a picture
of a plot on it.

**If a student asks** why the plot is interactive at all, it is Plotly, and the modebar is
theirs to use — zoom is not a trap.

**If the kernel dies** mid-lecture, these cues keep rendering, because the browser parsed
them. That is the whole reason they are not a notebook cell.
"""

"""
    kernel_less_session(notebook_path) -> Session

A session naming a Pluto server that is not there.

The deck the overlay is designed for: cues are worth most in the minutes before a kernel exists
or after one has been killed, and only an unreachable Pluto proves they survive it. The URL
names a port nothing is listening on, so the websocket is refused rather than answered by
something else.
"""
kernel_less_session(notebook_path::AbstractString) = Session(
    Pluto.ServerSession(),
    Pluto.RunningPlutoServer(nothing, @task nothing),
    Pluto.Notebook(Pluto.Cell[], notebook_path),
    "http://localhost:$(free_port())",
    "no-secret",
)

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

"Whether the deck is answering on `url` yet."
function serving(url::AbstractString)
    try
        return HTTP.get(url; retry=false, status_exception=false, connect_timeout=1).status == 200
    catch
        return false
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
down again. Composing `start_session` and `serve` by hand covers everything about it except
that composition.
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
        deadline = time() + PRESENT_TIMEOUT
        while !serving("$url/api/deck")
            Base.process_running(process) ||
                error("present exited before it served $url:\n", read(log, String))
            time() > deadline &&
                error("present did not serve $url within $(PRESENT_TIMEOUT)s:\n", read(log, String))
            sleep(0.2)
        end
        body(url)
    finally
        kill(process, Base.SIGINT)
        killed = timedwait(() -> !Base.process_running(process), SHUTDOWN_TIMEOUT) !== :ok
        killed && kill(process)
        wait(process)
        stopped = killed ? "kill" :
            process.exitcode == 0 ? "interrupt" : "exit $(process.exitcode)"
        # A shutdown that did not finish reads as `exit 1` and nothing else, and what threw is
        # in the process's own output — which every other path here already reports. It goes in
        # the message rather than beside it, because a trace passed as a log value is shown
        # middle-elided and the elided middle is the part that names what threw.
        stopped == "interrupt" ||
            @warn "present did not stop cleanly ($stopped), and said:\n" * read(log, String)
    end
    return stopped
end

"""
Record every `data-source` a card passes through, from before the deck's own scripts run.

By the time the harness can evaluate anything the deck has long since replaced its placeholders,
so the transition has to be recorded as it happens rather than looked for afterwards.
"""
const RECORD_CARD_SOURCES = """
window.__sources = {}
new MutationObserver((records) => {
  for (const record of records) {
    const name = record.target.dataset?.card
    if (name === undefined) continue
    const seen = (window.__sources[name] ??= [])
    const source = record.target.dataset.source
    // A repaint rewrites `live` over `live`, which is a mutation and not a transition.
    if (seen[seen.length - 1] !== source) seen.push(source)
  }
}).observe(document, {
  subtree: true, attributes: true, attributeOldValue: true, attributeFilter: ["data-source"],
})
"""

"""
Count every DOM change inside each card from here on.

A card that repaints when an unrelated cell re-runs is not a correctness bug but a performance
one — repainting rebuilds the card's scripts against whatever payload they read — so it shows up
as work done, not as a wrong value.
"""
const COUNT_CARD_MUTATIONS = """
(() => {
  window.__mutations = {}
  for (const card of document.querySelectorAll(".card")) {
    const name = card.dataset.card
    window.__mutations[name] = 0
    new MutationObserver((records) => { window.__mutations[name] += records.length })
      .observe(card, { childList: true, subtree: true, characterData: true })
  }
  return true
})()
"""

"Which slide is showing, counting from zero, or -1 if none is."
const CURRENT_SLIDE =
    """[...document.querySelectorAll(".slide")].findIndex((s) => s.dataset.current === "true")"""

"The position the chrome reports, which is what a keyboard move announces."
const SLIDE_POSITION = element("deck-nav >>> .position") * ".textContent"

"""
The plot card on the slide that is hidden when the deck first paints.

The deck places the plot cell on both slides, so a bare selector matches the copy on the slide
that is showing — which is the one that would still be drawn if a shared payload were broken.
"""
const HIDDEN_PLOT = """document.querySelectorAll('[data-card="wave"]')[1]"""

"Whether the cue panel is showing. `open` is the whole of the overlay's state."
const CUES_SHOWING = """document.querySelector("cue-overlay").hasAttribute("open")"""

"The overlay itself, which is the element that scrolls its own overflow."
const CUE_PANEL = """document.querySelector("cue-overlay")"""

"What the cue panel is reading out, as a lecturer sees it."
const CUE_BODY = element("cue-overlay >>> .cue-body")
const CUE_TEXT = CUE_BODY * ".textContent"

"The speaker page renders the same cues through the same renderer, in a root of its own."
const SPEAKER_CUE_BODY = element("speaker-page >>> .cue-body")
const SPEAKER_CUE_TEXT = SPEAKER_CUE_BODY * ".textContent"

"""
The speaker window's own chrome: which slide it believes the deck is on, and whether it still
believes anything at all.

`SPEAKER_READY` is the statement the module sets after it has subscribed, because a page's
`load` fires while its module is still evaluating and the harness would otherwise assert
against a document that is listening to nothing.
"""
const SPEAKER_STATE = element("speaker-page >>> .state") * ".textContent"
const SPEAKER_POSITION = element("speaker-page >>> .position") * ".textContent"
const SPEAKER_SLIDE = element("speaker-page >>> h1") * ".textContent"
const SPEAKER_READY = """'deck' in document.body.dataset"""

"""
Silence a deck window without closing it.

A window that is closed or reloaded says so on `pagehide`, so only a deck that stops talking
without saying anything — crashed, killed, or a laptop that went to sleep — is left to the
staleness timer, and that is the case a handshake alone cannot see.
"""
const MUTE_DECK = """
(() => {
  BroadcastChannel.prototype.postMessage = () => {}
  return true
})()
"""

"How long to allow for a silence to be called stale: `STALE_MS` and then some."
const LOST_TIMEOUT = 30.0

"""
Put a select, a textarea and a contenteditable on the slide that is showing.

The deck's own cards carry a range input and nothing else, so the widgets a notebook may hand
a slide — `PlutoUI.Select`, `PlutoUI.TextField`, any cell returning editable HTML — have to be
planted to be pressed against. Each one is somewhere a lecturer types, and every key the deck
listens to is a character one of them is owed.
"""
const PLANT_WIDGETS = """
(() => {
  const host = document.createElement("div")
  host.id = "planted-widgets"
  host.innerHTML = `
    <select id="planted-select"><option>one</option><option>two</option></select>
    <textarea id="planted-textarea"></textarea>
    <div id="planted-contenteditable" contenteditable="true">a cue in progress</div>`
  document.querySelector('.slide[data-current="true"]').append(host)
  return true
})()
"""

"Move the frequency slider the way a hand would, through the event Pluto's bond listener waits on."
const MOVE_THE_SLIDER = """
(() => {
  const input = document.querySelector('[data-card="frequency"] bond input')
  input.value = "4"
  input.dispatchEvent(new Event("input", { bubbles: true }))
  return input.value
})()
"""

@testset "browser" begin
    if chrome_binary() === nothing
        @warn "no Chrome on PATH; the deck goes unverified in the only place it can be verified"
        @test_skip "the deck renders against a live kernel in a real browser"
    else
        deck = browser_workspace()

        presented = with_present(deck.path) do url
            with_browser() do browser
                view = page(browser)
                navigate(browser, view, url; before=RECORD_CARD_SOURCES)

                @testset "the deck is served over HTTP, not loaded from disk" begin
                    @test evaluate(browser, view, "location.protocol") == "http:"
                    @test evaluate(browser, view, "location.origin") == url
                end

                @testset "every card shows its cell's live output" begin
                    # `every` over no cards is true, so the count comes first: an assertion that
                    # passes against an empty DOM is how a page that never rendered looks healthy.
                    # Seven placements over six cells, the plot being placed on both slides.
                    @test evaluate(browser, view, """document.querySelectorAll(".card").length""") == 7
                    await(browser, view,
                        """[...document.querySelectorAll(".card")].every((c) => c.dataset.source === "live")""";
                        what="every card to go live")

                    @test evaluate(browser, view,
                        """document.querySelector('[data-card="readout"]').textContent.trim()""") == "cycles 1"
                end

                @testset "a card is a placeholder before it is live" begin
                    sources = JSON.parse(evaluate(browser, view, "JSON.stringify(window.__sources)"))

                    @test sort(collect(keys(sources))) ==
                        ["constant", "frequency", "plain", "plotly", "readout", "wave"]
                    @test all(transitions == ["placeholder", "live"]
                              for transitions in values(sources))
                end

                @testset "nothing between a card's output and the document is a shadow root" begin
                    # Two separate mechanisms break the moment one appears, both of them
                    # silently. Pluto's renderer resolves a `published_to_js` payload through
                    # `root_node.closest("pluto-cell")`, and `closest` does not cross a shadow
                    # boundary; `deck.css` reaches a card's output from the document, and a
                    # document stylesheet does not either. A card would report `live` and draw
                    # nothing, with a clean console. `LightDomElement` is what holds the rule and
                    # this is what says so out loud.
                    @test evaluate(browser, view, """
                        (() => {
                          const shadowed = []
                          for (const card of document.querySelectorAll(".card")) {
                            for (let node = card; node !== null; node = node.parentElement) {
                              if (node.shadowRoot !== null) shadowed.push(node.tagName.toLowerCase())
                            }
                          }
                          return JSON.stringify([...new Set(shadowed)])
                        })()
                        """) == "[]"

                    # The chrome is the other half of the same rule: it holds no cards, so it is
                    # free to encapsulate, and it does.
                    @test evaluate(browser, view, """
                        ["deck-chrome", "deck-nav", "cue-overlay"]
                          .every((tag) => document.querySelector(tag).shadowRoot !== null)
                        """) === true

                    # A card's output has the ancestor `execute_scripttags` looks for, reachable
                    # by the call it actually makes.
                    @test evaluate(browser, view, """
                        [...document.querySelectorAll(".card-body pluto-cell")]
                          .every((cell) => cell.closest("pluto-cell") === cell)
                        """) === true
                end

                @testset "a Plotly card renders interactive, which is the published_to_js path" begin
                    # PlutoPlotly ships both the library and the plot data through
                    # `published_to_js`, so a plot on screen is proof that a card reaches
                    # `notebook.published_objects` through its <pluto-cell> ancestor.
                    #
                    # Awaited rather than read: a card whose payload has not arrived yet holds
                    # its placeholder rather than painting a body it cannot resolve, so a plot
                    # appears some runs after every card first reports `live`.
                    await(browser, view,
                        """document.querySelectorAll('[data-card="wave"] .js-plotly-plot').length === 2""";
                        what="both copies of the plot to draw")
                    @test evaluate(browser, view,
                        """!!document.querySelector('[data-card="wave"] .js-plotly-plot')""") === true
                    @test evaluate(browser, view,
                        """!!document.querySelector('[data-card="wave"] .modebar')""") === true
                    @test evaluate(browser, view,
                        """document.querySelectorAll('[data-card="wave"] svg').length""") > 0
                end

                @testset "a plain-text body renders as text, not as markup" begin
                    plain = """document.querySelector('[data-card="plain"]')"""

                    @test occursin("<b>not bold</b>", evaluate(browser, view, "$plain.textContent"))
                    @test evaluate(browser, view, "$plain.querySelector('b, script') === null") === true
                end

                @testset "a slide is headed by the deck's title for it, or numbered" begin
                    headings = JSON.parse(evaluate(browser, view,
                        """JSON.stringify([...document.querySelectorAll(".slide h2")].map((h) => h.textContent))"""))

                    @test headings == ["A wave you can drive", "Slide 2"]
                    @test evaluate(browser, view,
                        """document.querySelectorAll('.slide[data-titled="true"]').length""") == 1
                end

                @testset "the deck pages through its slides by pointer" begin
                    @test evaluate(browser, view, CURRENT_SLIDE) == 0
                    @test evaluate(browser, view, SLIDE_POSITION) == "1 / 2"
                    @test evaluate(browser, view,
                        element("deck-nav >>> button.previous") * ".disabled") === true

                    click(browser, view, "deck-nav >>> button.next")

                    @test evaluate(browser, view, CURRENT_SLIDE) == 1
                    @test evaluate(browser, view, SLIDE_POSITION) == "2 / 2"
                    @test evaluate(browser, view,
                        element("deck-nav >>> button.next") * ".disabled") === true

                    click(browser, view, "deck-nav >>> button.previous")

                    @test evaluate(browser, view, CURRENT_SLIDE) == 0
                end

                @testset "the deck pages through its slides by keyboard" begin
                    press(browser, view, "ArrowRight")
                    @test evaluate(browser, view, CURRENT_SLIDE) == 1

                    press(browser, view, "ArrowLeft")
                    @test evaluate(browser, view, CURRENT_SLIDE) == 0

                    press(browser, view, "PageDown")
                    @test evaluate(browser, view, CURRENT_SLIDE) == 1

                    press(browser, view, "PageUp")
                    @test evaluate(browser, view, CURRENT_SLIDE) == 0
                end

                @testset "the deck stops at its ends rather than wrapping round" begin
                    press(browser, view, "ArrowLeft")
                    @test evaluate(browser, view, CURRENT_SLIDE) == 0

                    press(browser, view, "PageDown")
                    press(browser, view, "ArrowRight")
                    @test evaluate(browser, view, CURRENT_SLIDE) == 1

                    press(browser, view, "PageUp")
                end

                @testset "an arrow key inside a widget drives the widget, not the deck" begin
                    # A range input is driven with the keys the deck navigates by, so a lecturer
                    # nudging a gain one step must not be thrown onto the next slide for it.
                    slider = """document.querySelector('[data-card="frequency"] bond input')"""
                    focus(browser, view, """[data-card="frequency"] bond input""")
                    before = evaluate(browser, view, "$slider.value")

                    press(browser, view, "ArrowRight")

                    @test evaluate(browser, view, CURRENT_SLIDE) == 0
                    @test evaluate(browser, view, "$slider.value") != before
                end

                @testset "a slide that is not showing keeps its cards' geometry" begin
                    # `display: none` would collapse these to zero width, and a Plotly card
                    # painted at zero width draws a graph that size — which is why the plot
                    # read here is the copy on the slide that is hidden when it first paints.
                    @test evaluate(browser, view, CURRENT_SLIDE) == 0
                    @test evaluate(browser, view, """
                        getComputedStyle($HIDDEN_PLOT.closest(".slide")).visibility
                        """) == "hidden"

                    @test evaluate(browser, view, "$HIDDEN_PLOT.offsetWidth") > 200
                    @test evaluate(browser, view, """
                        Math.round($HIDDEN_PLOT.querySelector(".js-plotly-plot")
                          .getBoundingClientRect().width)
                        """) > 200
                end

                @testset "a plot placed on two slides draws its lines on both" begin
                    # One cell, two cards, and one payload Pluto published for that cell. A draw
                    # that writes to what it was given breaks the next one *after* the traces
                    # are attached, so the card arrives holding its data with nothing drawn —
                    # which is a plot that rendered by every other measure this suite takes.
                    drawn = JSON.parse(evaluate(browser, view, """
                        JSON.stringify([...document.querySelectorAll('[data-card="wave"]')]
                          .map((card) => card.querySelectorAll("path.js-line").length))
                        """))

                    @test length(drawn) == 2
                    @test all(>(0), drawn)
                end

                @testset "a figure is as tall as the card the deck gave it" begin
                    # `h` is a hint until something tells the figure how tall its box is: a
                    # Plotly graph given no height draws itself 400 px whatever it sits in.
                    # `deck.css` gives the chain under a figure card an explicit height, and
                    # this is the only assertion that notices it stop matching — a 400 px plot
                    # still draws its lines, still reports `live`, and still answers every
                    # other selector in this suite.
                    #
                    # Against the body rather than the card, which also carries the padding and
                    # the border, so the ratio does not move with either.
                    filled = JSON.parse(evaluate(browser, view, """
                        JSON.stringify([...document.querySelectorAll('[data-card="wave"]')]
                          .map((card) => card.querySelector(".js-plotly-plot").getBoundingClientRect().height
                                       / card.querySelector(".card-body").getBoundingClientRect().height))
                        """))

                    @test length(filled) == 2
                    @test all(ratio -> 0.98 <= ratio <= 1.02, filled)
                end

                @testset "the chrome carries one global kernel state" begin
                    await(browser, view, """document.body.dataset.kernel === "ready" """;
                        what="the chrome to report the kernel ready")
                    @test evaluate(browser, view,
                        element("deck-chrome >>> .status") * ".textContent") == "kernel ready"

                    # The chrome colors itself off the same state rather than off a second
                    # reading of the kernel. The states a live kernel never passes through are
                    # pinned in `frontend/src/kernel.status.test.ts`: taking the kernel down to
                    # see "offline" would end this run.
                    @test evaluate(browser, view,
                        element("deck-chrome") * """.dataset.kernel""") == "ready"
                end

                @testset "a Julia-defined widget writes its value back to the kernel" begin
                    @test evaluate(browser, view, COUNT_CARD_MUTATIONS) === true
                    @test evaluate(browser, view,
                        """!!document.querySelector('[data-card="frequency"] bond input[type=range]')""") === true
                    @test evaluate(browser, view, MOVE_THE_SLIDER) == "4"

                    await(browser, view,
                        """document.querySelector('[data-card="readout"]').textContent.includes("cycles 4")""";
                        what="the readout to follow the slider")
                end

                @testset "a card does not repaint when an unrelated cell re-runs" begin
                    mutations = JSON.parse(evaluate(browser, view, "JSON.stringify(window.__mutations)"))

                    @test mutations["readout"] > 0
                    @test mutations["wave"] > 0
                    @test mutations["constant"] == 0
                    @test mutations["plain"] == 0
                    @test mutations["plotly"] == 0
                end

                @testset "a Julia-rendered plot follows the deck into dark mode" begin
                    # The one thing no stylesheet can reach: a plot's paper is in the payload
                    # the kernel sent. The deck writes `deck_theme`, the notebook picks its
                    # template off it, and the card repaints — so this asserts the whole pipe,
                    # from a media query in the browser to a color chosen in Julia.
                    # Read off the template the kernel sent rather than off a pixel: it is the
                    # payload that has to change, and a rendered color would also pass if the
                    # deck had reached in and repainted the figure itself.
                    # Optional all the way down: a repainting card holds no plot for a moment,
                    # and a poll that throws there is a harness bug, not a deck one.
                    paper = """document.querySelector('[data-card="wave"] .js-plotly-plot')
                                 ?.layout?.template?.layout?.paper_bgcolor"""
                    @test evaluate(browser, view, paper) == "white"

                    command(browser, "Emulation.setEmulatedMedia", Dict("features" =>
                        [Dict("name" => "prefers-color-scheme", "value" => "dark")]); session=view)

                    await(browser, view, """$paper === "rgb(17,17,17)" """;
                        what="the plot to repaint against the dark template")

                    # Both placements repaint, against one payload: the case 017 broke.
                    drawn = JSON.parse(evaluate(browser, view, """
                        JSON.stringify([...document.querySelectorAll('[data-card="wave"]')]
                          .map((card) => card.querySelectorAll("path.js-line").length))
                        """))
                    @test all(>(0), drawn)
                end

                @testset "no card is showing a Julia error" begin
                    # A cell that threw renders as `<jlerror>`, reports `live` like any other
                    # card, and logs nothing — so neither `data-source` nor the console says
                    # anything is wrong, and the deck looks healthy showing six error boxes.
                    @test evaluate(browser, view,
                        """document.querySelectorAll(".card jlerror").length""") == 0
                end

                @testset "a key puts the slide's cues over it, and takes them away again" begin
                    @test evaluate(browser, view, CUES_SHOWING) === false
                    # A key nothing names is a key nobody presses, so the chrome carries it
                    # the way it carries the buttons that move the deck.
                    @test occursin("(C)", evaluate(browser, view,
                        element("deck-nav >>> button.cues") * ".textContent"))

                    # The cue key follows the rule the arrow keys already do: a lecturer typing
                    # in a widget is typing, not opening a panel over the slide.
                    focus(browser, view, """[data-card="frequency"] bond input""")
                    press(browser, view, "c")
                    @test evaluate(browser, view, CUES_SHOWING) === false

                    evaluate(browser, view, "document.activeElement.blur()")
                    press(browser, view, "c")
                    @test evaluate(browser, view, CUES_SHOWING) === true
                    @test occursin(CUE_SENTENCE, evaluate(browser, view, CUE_TEXT))
                    @test evaluate(browser, view,
                        element("deck-nav >>> button.cues") * """.getAttribute("aria-pressed")""") == "true"

                    press(browser, view, "c")
                    @test evaluate(browser, view, CUES_SHOWING) === false
                end

                @testset "a key inside any other widget drives that widget, not the deck" begin
                    # A panel thrown over the slide mid-sentence lands on the room, not on
                    # the lecturer who typed.
                    @test evaluate(browser, view, PLANT_WIDGETS) === true

                    @testset "$selector" for selector in
                            ("#planted-select", "#planted-textarea", "#planted-contenteditable")
                        focus(browser, view, selector)

                        press(browser, view, "c")
                        @test evaluate(browser, view, CUES_SHOWING) === false

                        press(browser, view, "ArrowRight")
                        @test evaluate(browser, view, CURRENT_SLIDE) == 0
                    end

                    evaluate(browser, view, """document.getElementById("planted-widgets").remove()""")
                end

                @testset "a cue renders as markdown, not as the text a lecturer typed" begin
                    press(browser, view, "c")
                    cue = CUE_BODY

                    @test evaluate(browser, view, "$cue.querySelectorAll('strong').length") > 0
                    @test evaluate(browser, view, "$cue.querySelectorAll('em').length") > 0
                    @test evaluate(browser, view, "$cue.querySelector('code').textContent") == "freq"
                    @test evaluate(browser, view, "$cue.querySelector('a').getAttribute('href')") ==
                        "https://example.invalid/cue"
                    # The nested list is the construct a hand-written parser renders flat, with
                    # no error, in front of a room — which is why one is vendored.
                    @test evaluate(browser, view, "$cue.querySelectorAll('ul ul > li').length") == 3
                    @test !occursin("**", evaluate(browser, view, CUE_TEXT))
                end

                @testset "the panel scrolls its own overflow rather than the page" begin
                    # Several hundred words is the normal length of a cue, and the panel is
                    # fixed over a slide whose geometry must not move to make room for it.
                    @test evaluate(browser, view,
                        """getComputedStyle($CUE_PANEL).position""") == "fixed"
                    @test evaluate(browser, view, """
                        (() => {
                          const panel = $CUE_PANEL
                          return panel.scrollHeight > panel.clientHeight
                        })()
                        """) === true
                end

                @testset "paging with the cues open moves them to the new slide" begin
                    @test evaluate(browser, view, CURRENT_SLIDE) == 0

                    press(browser, view, "ArrowRight")

                    @test evaluate(browser, view, CURRENT_SLIDE) == 1
                    @test evaluate(browser, view, CUES_SHOWING) === true
                    # Slide 2 names no cues, and an empty panel is indistinguishable from a
                    # panel that failed to render.
                    @test !occursin(CUE_SENTENCE, evaluate(browser, view, CUE_TEXT))
                    @test evaluate(browser, view,
                        "!!" * element("cue-overlay >>> .cue-body .cue-absent")) === true

                    press(browser, view, "ArrowLeft")
                    @test occursin(CUE_SENTENCE, evaluate(browser, view, CUE_TEXT))

                    press(browser, view, "c")
                end

                @testset "cue text never reaches a slide, nor the cards the deck publishes" begin
                    # The room is looking at the same screen the lecturer is: a cue that leaks
                    # onto a slide, or into a card, is the one failure worse than no cues.
                    @test !occursin(CUE_SENTENCE,
                        evaluate(browser, view, """document.querySelector("main.slides").textContent"""))
                    @test evaluate(browser, view, """
                        (async () => {
                          const deck = await fetch("/api/deck").then((r) => r.json())
                          return JSON.stringify(deck.cards).includes($(repr(CUE_SENTENCE)))
                        })()
                        """) === false
                end

                @testset "the cues render with no kernel to reach at all" begin
                    # The case the design is built around, and the only one a live kernel
                    # cannot stage: Pluto has to be somewhere the websocket cannot reach. A
                    # second server over the same deck, so what is under test is the page
                    # rather than a second `present` — and a page of its own, because this one
                    # logs a refusal every few seconds and the deck's own console must stay
                    # asserted to be silent.
                    offline_deck = serve(deck, kernel_less_session(deck.notebook_path); listenany=true)
                    try
                        offline = page(browser)
                        navigate(browser, offline, offline_deck.url)
                        # The load event fires while the deck's module is still running, so
                        # what is waited for is the statement after the key listener is bound.
                        await(browser, offline, """'kernel' in document.body.dataset""";
                            what="the deck to finish wiring itself up")

                        # Every card labelled rather than blank is what says the deck built
                        # itself whole, rather than stopping where the kernel should have been.
                        @test evaluate(browser, offline, """
                            [...document.querySelectorAll(".card")]
                              .every((card) => card.dataset.source === "placeholder")
                            """) === true
                        # Labelled with its own name rather than blank: the chrome carries the
                        # one explanation, and a card says which card it is still waiting for.
                        @test evaluate(browser, offline, """
                            [...document.querySelectorAll(".card")]
                              .every((card) => card.textContent.trim() === card.dataset.card)
                            """) === true

                        press(browser, offline, "c")
                        @test evaluate(browser, offline, CUES_SHOWING) === true
                        @test occursin(CUE_SENTENCE, evaluate(browser, offline, CUE_TEXT))

                        press(browser, offline, "ArrowRight")
                        @test evaluate(browser, offline, CURRENT_SLIDE) == 1
                        @test evaluate(browser, offline,
                            "!!" * element("cue-overlay >>> .cue-body .cue-absent")) === true

                        press(browser, offline, "ArrowLeft")
                        @test occursin(CUE_SENTENCE, evaluate(browser, offline, CUE_TEXT))

                        # Pluto's client retries its websocket forever, so `connect` never
                        # returns and the chrome stays on "connecting": the console is the only
                        # place the refusal shows, and it is what says the kernel really was
                        # out of reach rather than quietly reached after all.
                        @test timedwait(OFFLINE_REPORT_TIMEOUT) do
                            any(contains("WebSocket connection to"), problems(browser, offline))
                        end === :ok
                    finally
                        close(offline_deck)
                    end
                end

                # Opened once and carried through the testsets below: what a reload of the
                # deck must not cost is this page, so it cannot be rebuilt between assertions.
                # The link is read rather than clicked — a new tab is a target the harness has
                # not attached to, and the href and the target are assertable on their own.
                speaker = page(browser)
                navigate(browser, speaker, "$url/speaker.html")
                await(browser, speaker, SPEAKER_READY;
                    what="the speaker window to subscribe to the deck")

                @testset "the chrome offers the speaker window as a link, not as a key" begin
                    # `window.open` from a key handler is the call browsers block, and the
                    # whole reason the on-slide overlay exists. A link is the viewer's click.
                    @test evaluate(browser, view,
                        element("deck-chrome >>> .speaker-link") * ".href") == "$url/speaker.html"
                    @test evaluate(browser, view,
                        element("deck-chrome >>> .speaker-link") * ".target") == "_blank"
                end

                @testset "the speaker window carries the cues and none of the deck" begin
                    await(browser, speaker, """document.body.dataset.deck === "live" """;
                        what="the speaker window to hear the deck it was opened from")

                    @test evaluate(browser, speaker, SPEAKER_POSITION) == "1 / 2"
                    @test evaluate(browser, speaker, SPEAKER_SLIDE) == "A wave you can drive"
                    @test occursin(CUE_SENTENCE, evaluate(browser, speaker, SPEAKER_CUE_TEXT))
                    # Markdown, from the same renderer the overlay uses rather than a second
                    # one: a nested list is what a hand-written parser flattens silently.
                    @test evaluate(browser, speaker,
                        elements("speaker-page >>> .cue-body ul ul > li") * ".length") == 3

                    # No cards, no kernel, no Rainbow bundle: that is what keeps this a second
                    # page rather than a second renderer, and what lets it outlive a kernel.
                    @test evaluate(browser, speaker, """document.querySelectorAll(".card").length""") == 0
                    @test evaluate(browser, speaker,
                        """!("kernel" in document.body.dataset)""") === true
                end

                @testset "paging the deck moves the speaker window with it" begin
                    press(browser, view, "ArrowRight")

                    await(browser, speaker, """$SPEAKER_POSITION === "2 / 2" """;
                        what="the speaker window to follow the deck to slide 2")
                    # Slide 2 names no cues, and an empty page is indistinguishable from one
                    # that failed to render.
                    @test evaluate(browser, speaker,
                        "!!" * element("speaker-page >>> .cue-body .cue-absent")) === true
                    @test !occursin(CUE_SENTENCE, evaluate(browser, speaker, SPEAKER_CUE_TEXT))
                    @test evaluate(browser, speaker, SPEAKER_SLIDE) == "Slide 2"

                    press(browser, view, "ArrowLeft")
                    await(browser, speaker, """$SPEAKER_POSITION === "1 / 2" """;
                        what="the speaker window to follow the deck back")
                    @test occursin(CUE_SENTENCE, evaluate(browser, speaker, SPEAKER_CUE_TEXT))
                end

                @testset "the overlay still works while the speaker window is open" begin
                    # The second window is the comfortable path, not a replacement: a lecturer
                    # who finds the hall mirrors its projector falls back to the overlay.
                    press(browser, view, "c")
                    @test evaluate(browser, view, CUES_SHOWING) === true
                    @test occursin(CUE_SENTENCE, evaluate(browser, view, CUE_TEXT))
                    @test evaluate(browser, speaker, SPEAKER_POSITION) == "1 / 2"

                    press(browser, view, "c")
                    @test evaluate(browser, view, CUES_SHOWING) === false
                end

                @testset "a deck that has gone quiet is reported, not left looking live" begin
                    # `BroadcastChannel` has no presence and no disconnect event, so a slide
                    # number that was true once sits there looking live — in front of a room,
                    # against a deck that was closed a minute ago.
                    @test evaluate(browser, view, MUTE_DECK) === true

                    await(browser, speaker, """document.body.dataset.deck === "lost" """;
                        what="the speaker window to call its slide number stale",
                        timeout=LOST_TIMEOUT)

                    @test occursin("gone", evaluate(browser, speaker, SPEAKER_STATE))
                    # The cues stay: the lecturer is still talking to that slide, and it is the
                    # chrome's job to say that nothing is confirming it any more.
                    @test occursin(CUE_SENTENCE, evaluate(browser, speaker, SPEAKER_CUE_TEXT))
                    @test evaluate(browser, speaker, SPEAKER_POSITION) == "1 / 2"
                end

                @testset "a reloaded deck re-establishes the link, speaker window untouched" begin
                    # Planted on the page rather than counted from outside: what has to survive
                    # is this document, and a reload of it would take the mark with it.
                    @test evaluate(browser, speaker,
                        """(() => { window.speakerGeneration = "first"; return true })()""") === true

                    navigate(browser, view, url)
                    await(browser, view, """document.body.dataset.kernel === "ready" """;
                        what="the reloaded deck to find the kernel still running")

                    await(browser, speaker, """document.body.dataset.deck === "live" """;
                        what="the speaker window to hear the reloaded deck",
                        timeout=LOST_TIMEOUT)

                    press(browser, view, "ArrowRight")
                    await(browser, speaker, """$SPEAKER_POSITION === "2 / 2" """;
                        what="the reloaded deck to drive the speaker window")
                    press(browser, view, "ArrowLeft")

                    @test evaluate(browser, speaker, "window.speakerGeneration") == "first"
                    # One deck, reloaded, is not two decks: a window says so on its way out, so
                    # the page it was driving does not spend a staleness window blaming it.
                    @test !occursin("deck windows", evaluate(browser, speaker, SPEAKER_STATE))
                end

                @testset "two decks driving one speaker window are visible, not interleaved" begin
                    # Sent on the wire rather than by opening a second deck: what the follower
                    # has to handle is a second `source` on the channel, and a second live deck
                    # would also write the theme bond and re-run the notebook under every
                    # assertion that follows. The channel name is position.js's, so a rename
                    # fails here rather than going quiet.
                    @test evaluate(browser, view, """
                        (() => {
                          new BroadcastChannel("plutodeck-position").postMessage({
                            type: "at", deck: $(repr(deck.path)), source: "a-second-deck", index: 1,
                          })
                          return true
                        })()
                        """) === true

                    await(browser, speaker, """$SPEAKER_STATE.includes("2 deck windows")""";
                        what="the speaker window to report both decks")
                    # The slide number is not asserted here on purpose: two decks that
                    # disagree are two heartbeats overwriting each other, and that flipping is
                    # what the warning exists to make visible rather than to hide.

                    # The warning has to clear itself, or the lecturer closes a window and the
                    # page goes on telling them to close a window.
                    await(browser, speaker, """!$SPEAKER_STATE.includes("deck windows")""";
                        what="the second deck to age out of the speaker window",
                        timeout=LOST_TIMEOUT)
                    await(browser, speaker, """$SPEAKER_POSITION === "1 / 2" """;
                        what="the remaining deck to put the speaker window back on its slide")
                end

                @testset "opened with nothing driving it, the speaker window says so" begin
                    # A cold open is the case a handshake cannot answer, and slide one's cues
                    # shown as though they were live is the lie the whole design refuses. The
                    # server is kernel-less as well, because this page must never need one.
                    #
                    # On a port of its own, and that is not a detail: `listenany` starts from
                    # the default port and would take back the one the offline deck above was
                    # served on. That deck's page is still open and still announcing itself —
                    # a page outlives the server that sent it — so this page would pair with it
                    # over a shared origin and be anything but cold.
                    lonely = serve(deck, kernel_less_session(deck.notebook_path);
                        port=free_port(), listenany=true)
                    try
                        cold = page(browser)
                        navigate(browser, cold, "$(lonely.url)/speaker.html")
                        await(browser, cold, SPEAKER_READY;
                            what="the speaker window to subscribe with no deck to hear")

                        @test evaluate(browser, cold, """document.body.dataset.deck""") == "waiting"
                        @test evaluate(browser, cold, SPEAKER_POSITION) == "—"
                        @test !occursin(CUE_SENTENCE, evaluate(browser, cold, SPEAKER_CUE_TEXT))
                        @test occursin("No deck window", evaluate(browser, cold, SPEAKER_STATE))

                        @test problems(browser, cold) == String[]
                    finally
                        close(lonely)
                    end
                end

                @testset "a cue rewritten before a lecture costs a refresh, not a restart" begin
                    # `test/server.jl` asserts the payload changes; what is asserted here is
                    # that a browser refresh is the whole of the lecturer's side of it. Waiting
                    # for "ready" is both the guard against pressing a key at a half-built page
                    # and the assertion that the refresh reached the kernel already running.
                    write(first(deck.slides).notes, "the **rewritten** cue, minutes before the room fills")

                    navigate(browser, view, url)
                    await(browser, view, """document.body.dataset.kernel === "ready" """;
                        what="the refreshed deck to find the kernel still running")
                    press(browser, view, "c")

                    @test evaluate(browser, view, CUES_SHOWING) === true
                    @test occursin("the rewritten cue", evaluate(browser, view, CUE_TEXT))
                    @test !occursin(CUE_SENTENCE, evaluate(browser, view, CUE_TEXT))
                end

                @testset "a cue file deleted under a running deck is reported, not blank" begin
                    rm(first(deck.slides).notes)

                    navigate(browser, view, url)
                    await(browser, view, """document.body.dataset.kernel === "ready" """;
                        what="the refreshed deck to find the kernel still running")
                    press(browser, view, "c")
                    absence = evaluate(browser, view,
                        element("cue-overlay >>> .cue-body .cue-absent") * """?.textContent ?? "" """)

                    @test evaluate(browser, view, CUES_SHOWING) === true
                    # The path and the reason, because the lecturer is the only one who can put
                    # the file back and a blank panel tells them nothing to do it with.
                    @test occursin(joinpath("notes", "wave.md"), absence)
                    @test occursin("could not be read", absence)
                end

                @testset "the deck reports no console error at all" begin
                    @test problems(browser, view) == String[]
                end

                @testset "the bundle imports into a page that defines nothing for it" begin
                    # The 404 page is a document on the deck's own origin whose module graph is
                    # empty, so nothing has run ahead of the import and no shim can be hiding the
                    # failure. Why the import would fail unbundled is in `frontend/build.mjs`,
                    # where the substitution that prevents it lives.
                    bare = page(browser)
                    navigate(browser, bare, "$url/not-a-page")

                    entry = only(filter(startswith("deck.entry-"), readdir(frontend_directory())))
                    imported = evaluate(browser, bare, """
                        import("/$entry").then(() => "imported", (error) => String(error))
                        """)

                    @test imported == "imported"
                end
            end
        end

        @testset "an interrupt is the whole of stopping a deck" begin
            # The lifecycle `present` prints as its last line, and the only one a lecturer has.
            # Anything else here says the shutdown it runs on the way out did not finish, and
            # what that shutdown closes is a two-gigabyte worker. That the worker itself is
            # gone is asserted in `session.jl`, from the process that owns it.
            @test presented == "interrupt"
        end
    end
end
