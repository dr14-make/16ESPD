using PlutoDeck: CardPlacement, DeckLoadError, Deck, DuplicateCardsError, cards, load_deck

"A deck file in its own directory, so a relative notebook reference resolves from somewhere real."
function deck_file(body::AbstractString; notebook::AbstractString=THREE_CARDS)
    path = joinpath(mktempdir(), "temp.deck.json")
    write(path, replace(body, "NOTEBOOK" => escape_string(notebook)))
    return path
end

const ONE_CARD = """
{
  "notebook": "NOTEBOOK",
  "slides": [{ "cards": [{ "card": "metrics", "x": 0, "y": 0, "w": 12, "h": 3 }] }]
}
"""

@testset "deck" begin
    @testset "a valid deck loads into a typed structure" begin
        deck = load_deck(joinpath(FIXTURES, "lecture.deck.json"))

        @test deck isa Deck
        @test deck.notebook_path == THREE_CARDS
        @test length(deck.slides) == 2
        @test deck.slides[1].cards == [
            CardPlacement("target-speed", 0, 0, 4, 2, nothing),
            CardPlacement("speed-plot", 4, 0, 8, 6, nothing),
        ]
        @test only(deck.slides[2].cards).name == "metrics"
        @test only(deck.slides[2].cards).snapshot === nothing
        @test deck.preamble == String[]
        @test deck.cards == cards(THREE_CARDS)
    end

    @testset "an absolute notebook reference is taken as given" begin
        @test load_deck(deck_file(ONE_CARD)).notebook_path == THREE_CARDS
    end

    @testset "a card the notebook does not publish names itself and its slide" begin
        unknown = joinpath(FIXTURES, "unknown-card.deck.json")

        @test_throws DeckLoadError load_deck(unknown)
        @test_throws ["slide 2", "metrcis", "three-cards.jl"] load_deck(unknown)
        @test_throws "That notebook publishes: \"metrics\", \"speed-plot\", \"target-speed\"" load_deck(unknown)

        err = try load_deck(unknown) catch err; err end
        @test occursin("1 problem found", sprint(showerror, err))
    end

    @testset "a notebook publishing nothing says so" begin
        notebook = joinpath(mktempdir(), "scratch.jl")
        Pluto.save_notebook(Pluto.Notebook([cell("scratch = 1 + 1")], notebook))

        @test_throws "publishes no cards at all" load_deck(deck_file(ONE_CARD; notebook))
    end

    @testset "a notebook that declares a name twice is refused by name" begin
        @test_throws DuplicateCardsError load_deck(deck_file(ONE_CARD; notebook=DUPLICATE_CARDS))
    end

    @testset "malformed geometry is rejected at load" begin
        @test_throws ["\"w\" must be", "got 0"] load_deck(deck_file("""
            { "notebook": "NOTEBOOK",
              "slides": [{ "cards": [{ "card": "metrics", "x": 0, "y": 0, "w": 0, "h": 3 }] }] }
            """))
        @test_throws ["\"x\" must be", "got -1"] load_deck(deck_file("""
            { "notebook": "NOTEBOOK",
              "slides": [{ "cards": [{ "card": "metrics", "x": -1, "y": 0, "w": 4, "h": 3 }] }] }
            """))
        @test_throws ["\"h\" must be", "got 2.5"] load_deck(deck_file("""
            { "notebook": "NOTEBOOK",
              "slides": [{ "cards": [{ "card": "metrics", "x": 0, "y": 0, "w": 4, "h": 2.5 }] }] }
            """))
        @test_throws ["\"w\" must be", "\"4\""] load_deck(deck_file("""
            { "notebook": "NOTEBOOK",
              "slides": [{ "cards": [{ "card": "metrics", "x": 0, "y": 0, "w": "4", "h": 3 }] }] }
            """))
    end

    @testset "cards that cannot be laid out where the deck puts them are refused" begin
        @test_throws ["slide 1", "\"metrics\" (columns 0-5, rows 0-2)",
                      "overlaps \"speed-plot\" (columns 4-11, rows 2-5)"] load_deck(deck_file("""
            { "notebook": "NOTEBOOK",
              "slides": [{ "cards": [
                { "card": "metrics", "x": 0, "y": 0, "w": 6, "h": 3 },
                { "card": "speed-plot", "x": 4, "y": 2, "w": 8, "h": 4 }] }] }
            """))

        @test_throws ["slide 2", "\"metrics\" reaches column 14 of a 12-column grid"] load_deck(deck_file("""
            { "notebook": "NOTEBOOK",
              "slides": [
                { "cards": [{ "card": "speed-plot", "x": 0, "y": 0, "w": 12, "h": 3 }] },
                { "cards": [{ "card": "metrics", "x": 6, "y": 0, "w": 8, "h": 3 }] }] }
            """))
    end

    @testset "cards that share a column or a row but no area are placed" begin
        # Edges touching is what a deck looks like when it is right: the card below starts on
        # the row the card above ends, and the card beside it starts on the column it ends.
        deck = load_deck(deck_file("""
            { "notebook": "NOTEBOOK",
              "slides": [{ "cards": [
                { "card": "target-speed", "x": 0, "y": 0, "w": 4, "h": 2 },
                { "card": "metrics", "x": 0, "y": 2, "w": 4, "h": 3 },
                { "card": "speed-plot", "x": 4, "y": 0, "w": 8, "h": 5 }] }] }
            """))

        @test length(only(deck.slides).cards) == 3
    end

    @testset "every fault in one file is reported by one load" begin
        err = try
            load_deck(deck_file("""
                { "notebook": "NOTEBOOK",
                  "slides": [
                    { "cards": [{ "card": "metrics", "x": 0, "y": 0, "w": 0, "h": 3 },
                                { "card": "speed-plot", "y": 0, "w": 4, "h": 3 }] },
                    { "cards": [{ "card": "target-speed", "x": 0, "y": 0, "w": 4, "h": 0 }] }
                  ] }
                """))
            nothing
        catch err
            err
        end

        @test err isa DeckLoadError
        @test length(err.problems) == 3
        message = sprint(showerror, err)
        @test occursin("slide 1, card 1 (\"metrics\"): \"w\"", message)
        @test occursin("slide 1, card 2 (\"speed-plot\"): missing key \"x\"", message)
        @test occursin("slide 2, card 1 (\"target-speed\"): \"h\"", message)
        @test occursin("3 problems found", message)
    end

    @testset "a mistyped key is named rather than ignored" begin
        @test_throws ["unknown key \"width\""] load_deck(deck_file("""
            { "notebook": "NOTEBOOK",
              "slides": [{ "cards": [{ "card": "metrics", "x": 0, "y": 0, "width": 4, "w": 4, "h": 3 }] }] }
            """))
        @test_throws ["unknown key \"heading\""] load_deck(deck_file("""
            { "notebook": "NOTEBOOK",
              "slides": [{ "heading": "Cruise control", "cards": [] }] }
            """))
    end

    @testset "a slide carries the deck's own title for it, or none" begin
        deck = load_deck(deck_file("""
            { "notebook": "NOTEBOOK",
              "slides": [
                { "title": "Proportional",
                  "cards": [{ "card": "metrics", "x": 0, "y": 0, "w": 4, "h": 3 }] },
                { "cards": [{ "card": "speed-plot", "x": 0, "y": 0, "w": 4, "h": 3 }] }
              ] }
            """))

        @test deck.slides[1].title == "Proportional"
        @test deck.slides[2].title === nothing
    end

    @testset "a title that is not a name is refused rather than rendered" begin
        @test_throws ["slide 1", "\"title\" must be a non-empty string", "got 7"] load_deck(deck_file("""
            { "notebook": "NOTEBOOK",
              "slides": [{ "title": 7,
                           "cards": [{ "card": "metrics", "x": 0, "y": 0, "w": 4, "h": 3 }] }] }
            """))
    end

    @testset "a per-card snapshot reference is carried, not interpreted" begin
        deck = load_deck(deck_file("""
            { "notebook": "NOTEBOOK",
              "slides": [{ "cards": [
                { "card": "metrics", "x": 0, "y": 0, "w": 4, "h": 3, "snapshot": "metrics.html" }] }] }
            """))

        @test only(only(deck.slides).cards).snapshot == "metrics.html"
    end

    @testset "a preamble names cards that are rendered before any slide and shown on none" begin
        deck = load_deck(deck_file("""
            { "notebook": "NOTEBOOK",
              "preamble": ["speed-plot", "target-speed"],
              "slides": [{ "cards": [{ "card": "metrics", "x": 0, "y": 0, "w": 4, "h": 3 }] }] }
            """))

        @test deck.preamble == ["speed-plot", "target-speed"]
        @test only(only(deck.slides).cards).name == "metrics"
    end

    @testset "a preamble card the notebook does not publish is refused like any other" begin
        @test_throws ["preamble 1", "declares card = \"plotly\""] load_deck(deck_file("""
            { "notebook": "NOTEBOOK",
              "preamble": ["plotly"],
              "slides": [{ "cards": [{ "card": "metrics", "x": 0, "y": 0, "w": 4, "h": 3 }] }] }
            """))
        @test_throws ["\"preamble\" must be an array"] load_deck(deck_file("""
            { "notebook": "NOTEBOOK", "preamble": "speed-plot",
              "slides": [{ "cards": [{ "card": "metrics", "x": 0, "y": 0, "w": 4, "h": 3 }] }] }
            """))
        @test_throws ["preamble 2", "must be a non-empty card name"] load_deck(deck_file("""
            { "notebook": "NOTEBOOK", "preamble": ["speed-plot", ""],
              "slides": [{ "cards": [{ "card": "metrics", "x": 0, "y": 0, "w": 4, "h": 3 }] }] }
            """))
    end

    @testset "a structural fault names the deck rather than throwing a parse error" begin
        @test_throws ["not valid JSON"] load_deck(deck_file("{ \"notebook\": "))
        @test_throws ["the deck", "missing key \"slides\""] load_deck(deck_file("""
            { "notebook": "NOTEBOOK" }
            """))
        @test_throws ["the deck", "\"notebook\""] load_deck(deck_file("""
            { "slides": [] }
            """))
        @test_throws ["\"slides\" must be an array"] load_deck(deck_file("""
            { "notebook": "NOTEBOOK", "slides": {} }
            """))
        @test_throws ["slide 1", "must be a JSON object"] load_deck(deck_file("""
            { "notebook": "NOTEBOOK", "slides": ["a slide"] }
            """))
        @test_throws ["no such file"] load_deck(joinpath(FIXTURES, "absent.deck.json"))
        @test_throws ["\"notebook\": no such file"] load_deck(
            deck_file(ONE_CARD; notebook=joinpath(FIXTURES, "absent.jl")))
    end
end
