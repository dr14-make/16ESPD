using Test

using PlutoDeck

const FIXTURES = joinpath(@__DIR__, "fixtures")
const THREE_CARDS = joinpath(FIXTURES, "three-cards.jl")
const DUPLICATE_CARDS = joinpath(FIXTURES, "duplicate-cards.jl")
const RUNNABLE = joinpath(FIXTURES, "runnable.jl")
const LECTURE_DECK = joinpath(FIXTURES, "lecture.md")

"The Slidev workspace, and the fixture deck in it that the browser suite drives."
const SLIDES = normpath(joinpath(@__DIR__, "..", "..", "..", "slides"))
const FIXTURE_DECK = joinpath("pluto-fixture", "fixture.md")

"""
A Slidev deck in its own directory, so a relative notebook reference resolves from somewhere
real. `NOTEBOOK` in `body` stands for `notebook`; `beside` holds the other files of the folder.
"""
function deck_file(body::AbstractString; notebook::AbstractString=THREE_CARDS,
        beside::Dict{String,String}=Dict{String,String}())
    directory = mktempdir()
    for (name, contents) in beside
        mkpath(joinpath(directory, dirname(name)))
        write(joinpath(directory, name), contents)
    end
    path = joinpath(directory, "slides.md")
    write(path, replace(body, "NOTEBOOK" => notebook))
    return path
end

@testset "PlutoDeck" begin
    include("cards.jl")
    include("deck.jl")
    include("server.jl")
    include("session.jl")
    include("browser.jl")
end
