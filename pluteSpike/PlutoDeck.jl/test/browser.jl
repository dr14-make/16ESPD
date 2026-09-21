# The deck, driven in real headless Chrome against a real kernel.
#
# Everything here is asserted through the DOM the browser actually built, over HTTP, because the
# two bugs that cost this project the most were invisible to anything less: a missing `process`
# shim that Node supplies for free, and a static handler that was never exercised because the
# page had been loaded from disk.

include("devtools.jl")

using PlutoDeck: load_deck, serve, shutdown!, start_session

const BROWSER_NOTEBOOK = joinpath(FIXTURES, "browser.jl")

"""
The deck the browser drives, in a directory of its own.

Pluto rewrites every notebook it opens, so a fixture is copied out of the repository before a
kernel is pointed at it.
"""
function browser_workspace()
    workspace = mktempdir()
    cp(BROWSER_NOTEBOOK, joinpath(workspace, "browser.jl"))
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
        session = start_session(deck.notebook_path; io=nothing)
        server = serve(deck, session; port=0, listenany=true)

        try
            with_browser() do browser
                view = page(browser)
                navigate(browser, view, server.url; before=RECORD_CARD_SOURCES)

                @testset "the deck is served over HTTP, not loaded from disk" begin
                    @test evaluate(browser, view, "location.protocol") == "http:"
                    @test evaluate(browser, view, "location.origin") == server.url
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

                @testset "no card is showing a Julia error" begin
                    # A cell that threw renders as `<jlerror>`, reports `live` like any other
                    # card, and logs nothing — so neither `data-source` nor the console says
                    # anything is wrong, and the deck looks healthy showing six error boxes.
                    @test evaluate(browser, view,
                        """document.querySelectorAll(".card jlerror").length""") == 0
                end

                @testset "the deck reports no console error at all" begin
                    @test problems(browser, view) == String[]
                end

                @testset "the harness can see a missing browser shim" begin
                    # The one failure a Node-side harness cannot reach: importing the Rainbow
                    # bundle without `process` defined. The 404 page is a document on the deck's
                    # own origin whose module graph is empty, so the import runs unshimmed.
                    bare = page(browser)
                    navigate(browser, bare, "$(server.url)/not-a-page")

                    unshimmed = evaluate(browser, bare, """
                        import("/vendor/rainbow.esm.js").then(() => "imported", (error) => String(error))
                        """)

                    @test occursin("process is not defined", unshimmed)
                end
            end
        finally
            close(server)
            shutdown!(session)
        end
    end
end
