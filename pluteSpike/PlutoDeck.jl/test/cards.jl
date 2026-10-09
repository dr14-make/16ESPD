using UUIDs: UUID

import Pluto

using PlutoDeck: DuplicateCardsError, InvalidCardNameError, cards, list_cards, read_notebook

cell(code; metadata...) = Pluto.Cell(;
    code,
    metadata=Pluto.create_cell_metadata(Dict{String,Any}(String(k) => v for (k, v) in metadata)),
)

notebook_of(cells...) = Pluto.Notebook(collect(cells), joinpath(FIXTURES, "in-memory.jl"))

@testset "cards" begin
    @testset "a notebook publishes the cells that declare a card" begin
        published = cards(THREE_CARDS)

        @test published == Dict(
            "target-speed" => UUID("a1000000-0000-4000-8000-000000000001"),
            "speed-plot" => UUID("a1000000-0000-4000-8000-000000000003"),
            "metrics" => UUID("a1000000-0000-4000-8000-000000000004"),
        )
        @test UUID("a1000000-0000-4000-8000-000000000002") ∉ values(published)
    end

    @testset "a loaded notebook and its path give the same answer" begin
        @test cards(read_notebook(THREE_CARDS)) == cards(THREE_CARDS)
    end

    @testset "reading a notebook leaves the file untouched" begin
        before = read(THREE_CARDS)
        cards(THREE_CARDS)
        @test read(THREE_CARDS) == before
    end

    @testset "a name declared twice is refused, naming both cells" begin
        @test_throws DuplicateCardsError cards(DUPLICATE_CARDS)
        @test_throws [
            "metrics",
            "a1000000-0000-4000-8000-000000000004",
            "a1000000-0000-4000-8000-000000000005",
        ] cards(DUPLICATE_CARDS)
    end

    @testset "a card key that cannot name a card is refused" begin
        @test_throws InvalidCardNameError cards(notebook_of(cell("x = 1"; card=true)))
        @test_throws InvalidCardNameError cards(notebook_of(cell("x = 1"; card="  ")))
        @test_throws "must be a non-empty string" cards(notebook_of(cell("x = 1"; card=3)))
    end

    @testset "listing shows what a notebook publishes, in notebook order" begin
        listing = sprint(list_cards, THREE_CARDS)

        @test occursin("3 cards in", listing)
        @test occursin("@bind v_ref_kmh", listing)
        @test !occursin("scratch = 1 + 1", listing)
        names = [findfirst(name, listing) for name in ("target-speed", "speed-plot", "metrics")]
        @test issorted(first.(names))
    end

    @testset "listing reports a duplicate rather than refusing to continue" begin
        listing = sprint(list_cards, DUPLICATE_CARDS)

        @test occursin("4 cards in", listing)
        @test occursin("DUPLICATE", listing)
    end
end
