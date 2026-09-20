using Test

using PlutoDeck

const FIXTURES = joinpath(@__DIR__, "fixtures")
const THREE_CARDS = joinpath(FIXTURES, "three-cards.jl")
const DUPLICATE_CARDS = joinpath(FIXTURES, "duplicate-cards.jl")

@testset "PlutoDeck" begin
    include("cards.jl")
    include("deck.jl")
end
