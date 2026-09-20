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
    write(joinpath(workspace, "browser.deck.json"), """
    {
      "notebook": "browser.jl",
      "preamble": ["plotly"],
      "slides": [
        {
          "cards": [
            { "card": "frequency", "x": 0, "y": 0, "w": 4, "h": 2 },
            { "card": "wave", "x": 4, "y": 0, "w": 8, "h": 6 }
          ]
        },
        {
          "cards": [
            { "card": "readout", "x": 0, "y": 0, "w": 4, "h": 2 },
            { "card": "constant", "x": 4, "y": 0, "w": 4, "h": 2 },
            { "card": "plain", "x": 8, "y": 0, "w": 4, "h": 2 }
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
                    @test evaluate(browser, view, """document.querySelectorAll(".card").length""") == 6
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
