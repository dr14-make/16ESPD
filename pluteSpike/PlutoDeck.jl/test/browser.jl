# The deck, driven in real headless Chrome against a real kernel `present` brought up.
#
# Everything here is asserted through the DOM the browser actually built, over HTTP, because the
# two bugs that cost this project the most were invisible to anything less: a missing `process`
# shim that Node supplies for free, and a static handler that was never exercised because the
# page had been loaded from disk.

include("devtools.jl")

import Pluto
import Sockets

using PlutoDeck: Session, load_deck, present, serve

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
    ;(window.__sources[name] ??= []).push([record.oldValue, record.target.dataset.source])
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
const SLIDE_POSITION = """document.getElementById("slide-position").textContent"""

"""
The plot card on the slide that is hidden when the deck first paints.

The deck places the plot cell on both slides, so a bare selector matches the copy on the slide
that is showing — which is the one that would still be drawn if a shared payload were broken.
"""
const HIDDEN_PLOT = """document.querySelectorAll('[data-card="wave"]')[1]"""

"Whether the cue panel is showing."
const CUES_SHOWING = """!document.getElementById("speaker-cues").hidden"""

"What the cue panel is reading out, as a lecturer sees it."
const CUE_TEXT = """document.getElementById("cue-body").textContent"""

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
                    @test all(first(transitions) == ["placeholder", "live"]
                              for transitions in values(sources))
                end

                @testset "a card with no content yet is labelled rather than blank" begin
                    card = JSON.parse(evaluate(browser, view, """
                        (async () => {
                          const { Card } = await import("/card.js")
                          const card = new Card({ name: "speed-plot", paint: () => {} })
                          return JSON.stringify({
                            source: card.element.dataset.source,
                            label: card.element.textContent.trim(),
                          })
                        })()
                        """))

                    @test card["source"] == "placeholder"
                    @test card["label"] == "speed-plot"
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
                    @test evaluate(browser, view, """document.getElementById("previous-slide").disabled""") === true

                    click(browser, view, "#next-slide")

                    @test evaluate(browser, view, CURRENT_SLIDE) == 1
                    @test evaluate(browser, view, SLIDE_POSITION) == "2 / 2"
                    @test evaluate(browser, view, """document.getElementById("next-slide").disabled""") === true

                    click(browser, view, "#previous-slide")

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
                        """document.getElementById("kernel-status").textContent""") == "kernel ready"

                    # The states a live kernel does not pass through are asserted against the
                    # mapping itself: taking the kernel down to see "offline" would end the run.
                    states = JSON.parse(evaluate(browser, view, """
                        (async () => {
                          const { kernelStatus } = await import("/status.js")
                          return JSON.stringify({
                            cold: kernelStatus({ process: null }).state,
                            starting: kernelStatus({ process: "starting" }).state,
                            ready: kernelStatus({ process: "ready" }).state,
                            dropped: kernelStatus({ connected: false, process: "ready" }).state,
                            gone: kernelStatus({ process: "no_process" }).state,
                            refused: kernelStatus({ failure: "no websocket" }).state,
                          })
                        })()
                        """))

                    @test states == Dict(
                        "cold" => "connecting",
                        "starting" => "connecting",
                        "ready" => "ready",
                        "dropped" => "offline",
                        "gone" => "offline",
                        "refused" => "error",
                    )
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

                @testset "a burst of bond changes is one notebook update, not six" begin
                    # Six sequential updates are six reactive runs, and the first five see bonds
                    # that are still `missing`. Driven against a stub worker rather than the
                    # kernel, because what is under test is the batching, not the round trip.
                    updates = JSON.parse(evaluate(browser, view, """
                        (async () => {
                          const { Kernel } = await import("/kernel.js")
                          const updates = []
                          const kernel = new Kernel({
                            getState: () => ({ cell_results: {}, bonds: {}, published_objects: {} }),
                            isIdle: () => true,
                            _update_notebook_state: (mutate) => {
                              const notebook = { bonds: {} }
                              mutate(notebook)
                              updates.push(Object.keys(notebook.bonds))
                            },
                          })
                          const names = ["a", "b", "c", "d", "e", "f"]
                          await Promise.all(names.map((name, index) => kernel.setBond(name, index)))
                          return JSON.stringify(updates)
                        })()
                        """))

                    @test updates == [["a", "b", "c", "d", "e", "f"]]
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
                        """document.querySelector("#deck-nav #toggle-cues").textContent"""))

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
                        """document.getElementById("toggle-cues").getAttribute("aria-pressed")""") == "true"

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
                    cue = """document.getElementById("cue-body")"""

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
                    @test evaluate(browser, view, """
                        getComputedStyle(document.getElementById("speaker-cues")).position
                        """) == "fixed"
                    @test evaluate(browser, view, """
                        (() => {
                          const panel = document.getElementById("speaker-cues")
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
                        """!!document.querySelector("#cue-body .cue-absent")""") === true

                    press(browser, view, "ArrowLeft")
                    @test occursin(CUE_SENTENCE, evaluate(browser, view, CUE_TEXT))

                    press(browser, view, "c")
                end

                @testset "cue text never reaches a slide, nor the cards the deck publishes" begin
                    # The room is looking at the same screen the lecturer is: a cue that leaks
                    # onto a slide, or into a card, is the one failure worse than no cues.
                    @test !occursin(CUE_SENTENCE,
                        evaluate(browser, view, """document.getElementById("slides").textContent"""))
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

                        press(browser, offline, "c")
                        @test evaluate(browser, offline, CUES_SHOWING) === true
                        @test occursin(CUE_SENTENCE, evaluate(browser, offline, CUE_TEXT))

                        press(browser, offline, "ArrowRight")
                        @test evaluate(browser, offline, CURRENT_SLIDE) == 1
                        @test evaluate(browser, offline,
                            """!!document.querySelector("#cue-body .cue-absent")""") === true

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
                        """document.querySelector("#cue-body .cue-absent")?.textContent ?? "" """)

                    @test evaluate(browser, view, CUES_SHOWING) === true
                    # The path and the reason, because the lecturer is the only one who can put
                    # the file back and a blank panel tells them nothing to do it with.
                    @test occursin(joinpath("notes", "wave.md"), absence)
                    @test occursin("could not be read", absence)
                end

                @testset "the deck reports no console error at all" begin
                    @test problems(browser, view) == String[]
                end

                @testset "the harness can see a missing browser shim" begin
                    # The one failure a Node-side harness cannot reach: importing the Rainbow
                    # bundle without `process` defined. The 404 page is a document on the deck's
                    # own origin whose module graph is empty, so the import runs unshimmed.
                    bare = page(browser)
                    navigate(browser, bare, "$url/not-a-page")

                    unshimmed = evaluate(browser, bare, """
                        import("/vendor/rainbow.esm.js").then(() => "imported", (error) => String(error))
                        """)

                    @test occursin("process is not defined", unshimmed)
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
