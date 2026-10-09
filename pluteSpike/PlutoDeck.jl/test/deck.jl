using PlutoDeck: DeckLoadError, Deck, load_deck

const ONE_CARD = """
---
pluto:
  notebook: NOTEBOOK
---

<PlutoCard name="metrics" />
"""

@testset "deck" begin
    @testset "a deck's headmatter names its notebook, resolved against the deck file" begin
        deck = load_deck(LECTURE_DECK)

        @test deck isa Deck
        @test deck.path == LECTURE_DECK
        @test deck.notebook_path == realpath(THREE_CARDS)
    end

    @testset "an absolute notebook reference is taken as given" begin
        @test load_deck(deck_file(ONE_CARD)).notebook_path == realpath(THREE_CARDS)
    end

    @testset "the Slidev fixture deck names the live suite's notebook" begin
        @test load_deck(joinpath(SLIDES, FIXTURE_DECK)).notebook_path ==
            realpath(joinpath(FIXTURES, "browser.jl"))
    end

    @testset "a notebook reached through a symlink is named by the file Pluto opens" begin
        linked = joinpath(mktempdir(), "fixtures")
        symlink(FIXTURES, linked)
        @test load_deck(deck_file(ONE_CARD; notebook=joinpath(linked, "three-cards.jl"))).notebook_path ==
            realpath(THREE_CARDS)
    end

    @testset "a deck that names no notebook it can open says so" begin
        @test_throws ["no such file"] load_deck(joinpath(FIXTURES, "absent.md"))
        @test_throws ["names no notebook"] load_deck(deck_file("# A slide\n"))
        @test_throws ["names no notebook"] load_deck(deck_file("---\ntitle: x\n---\n"))
        @test_throws ["names no notebook"] load_deck(deck_file("---\npluto: x\n---\n"))
        @test_throws ["names no notebook"] load_deck(deck_file("---\npluto:\n  notebook: 7\n---\n"))
        @test_throws ["pluto.notebook: no such file"] load_deck(
            deck_file(ONE_CARD; notebook=joinpath(FIXTURES, "absent.jl")))
    end
end
