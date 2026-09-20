using Test

using PlutoDeck

const FIXTURES = joinpath(@__DIR__, "fixtures")
const THREE_CARDS = joinpath(FIXTURES, "three-cards.jl")
const DUPLICATE_CARDS = joinpath(FIXTURES, "duplicate-cards.jl")
const RUNNABLE = joinpath(FIXTURES, "runnable.jl")
const LECTURE_DECK = joinpath(FIXTURES, "lecture.deck.json")

@testset "PlutoDeck" begin
    include("cards.jl")
    include("deck.jl")
    include("server.jl")
    include("session.jl")
    include("browser.jl")
end
