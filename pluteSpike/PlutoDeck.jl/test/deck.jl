using PlutoDeck: DeckLoadError, Deck, DuplicateCardsError, cards, load_deck

"""
A Slidev deck in its own directory, so a relative notebook reference resolves from somewhere
real. `NOTEBOOK` in `body` and in every file `beside` it stands for `notebook`.
"""
function deck_file(body::AbstractString; notebook::AbstractString=THREE_CARDS,
        beside::Dict{String,String}=Dict{String,String}())
    directory = mktempdir()
    for (name, contents) in beside
        mkpath(joinpath(directory, dirname(name)))
        write(joinpath(directory, name), replace(contents, "NOTEBOOK" => notebook))
    end
    path = joinpath(directory, "slides.md")
    write(path, replace(body, "NOTEBOOK" => notebook))
    return path
end

const ONE_CARD = """
---
pluto:
  notebook: NOTEBOOK
---

## Metrics

<Grid>
  <Card :x="0" :y="0" :w="12" :h="3"><PlutoCard name="metrics" /></Card>
</Grid>
"""

"The Slidev fixture deck the browser suite drives."
const SLIDEV_FIXTURE = normpath(joinpath(@__DIR__, "..", "..", "..", "slides", "pluto-fixture", "fixture.md"))

@testset "deck" begin
    @testset "a deck's headmatter names its notebook, resolved against the deck file" begin
        deck = load_deck(LECTURE_DECK)

        @test deck isa Deck
        @test deck.path == LECTURE_DECK
        @test deck.notebook_path == THREE_CARDS
        @test deck.cards == cards(THREE_CARDS)
    end

    @testset "an absolute notebook reference is taken as given" begin
        @test load_deck(deck_file(ONE_CARD)).notebook_path == THREE_CARDS
    end

    @testset "a card the notebook does not publish names itself, its file and its line" begin
        unknown = joinpath(FIXTURES, "unknown-card.md")

        @test_throws DeckLoadError load_deck(unknown)
        @test_throws ["unknown-card.md:13", "\"metrcis\"", "three-cards.jl"] load_deck(unknown)
        @test_throws "That notebook publishes: \"metrics\", \"speed-plot\", \"target-speed\"" load_deck(unknown)

        err = try load_deck(unknown) catch err; err end
        @test occursin("1 problem found", sprint(showerror, err))
    end

    @testset "a card in a section the deck imports is checked where it is written" begin
        path = deck_file("""
            ---
            pluto:
              notebook: NOTEBOOK
            src: ./sections/first.md
            ---

            ---
            src: sections/second.md
            ---
            """; beside=Dict(
                "sections/first.md" => """
                    # First

                    <PlutoCard name="metrics" />
                    """,
                "sections/second.md" => """
                    # Second

                    <Card :x="0" :y="0" :w="4" :h="3"><PlutoCard   name='speed-plt' /></Card>
                    """))

        @test_throws ["sections/second.md:3", "\"speed-plt\""] load_deck(path)
    end

    @testset "a section the deck imports that is not there is a fault of the deck" begin
        path = deck_file("""
            ---
            pluto:
              notebook: NOTEBOOK
            ---

            ---
            src: ./sections/gone.md
            ---
            """)

        @test_throws ["slides.md:7", "\"src\": no such file", "gone.md"] load_deck(path)
    end

    @testset "a bound name is left to the browser: only a literal can be checked at load" begin
        path = deck_file("""
            ---
            pluto:
              notebook: NOTEBOOK
            ---

            <PlutoCard :name="picked" />
            """)

        @test load_deck(path).notebook_path == THREE_CARDS
    end

    @testset "a notebook publishing nothing says so" begin
        notebook = joinpath(mktempdir(), "scratch.jl")
        Pluto.save_notebook(Pluto.Notebook([cell("scratch = 1 + 1")], notebook))

        @test_throws "publishes no cards at all" load_deck(deck_file(ONE_CARD; notebook))
    end

    @testset "a notebook that declares a name twice is refused by name" begin
        @test_throws DuplicateCardsError load_deck(deck_file(ONE_CARD; notebook=DUPLICATE_CARDS))
    end

    @testset "the Slidev fixture deck fails on exactly the card it misnames on purpose" begin
        # The fixture carries one unknown name so the browser suite can show what a card does with
        # one; anything else unresolved there is a fixture that has drifted from its notebook.
        err = try load_deck(SLIDEV_FIXTURE) catch err; err end

        @test err isa DeckLoadError
        @test length(err.problems) == 1
        @test occursin("\"not-in-the-notebook\"", only(err.problems))
    end

    @testset "a structural fault names the deck rather than throwing a parse error" begin
        @test_throws ["no such file"] load_deck(joinpath(FIXTURES, "absent.md"))
        @test_throws ["no headmatter"] load_deck(deck_file("# A slide\n"))
        @test_throws ["headmatter is not valid YAML"] load_deck(deck_file("---\npluto: [\n---\n"))
        @test_throws ["\"pluto.notebook\"", "missing"] load_deck(deck_file("---\ntitle: x\n---\n"))
        @test_throws ["\"pluto.notebook\"", "missing"] load_deck(deck_file("---\npluto: x\n---\n"))
        @test_throws ["\"pluto.notebook\" must be a non-empty string", "7"] load_deck(
            deck_file("---\npluto:\n  notebook: 7\n---\n"))
        @test_throws ["\"pluto.notebook\": no such file"] load_deck(
            deck_file(ONE_CARD; notebook=joinpath(FIXTURES, "absent.jl")))
    end
end
