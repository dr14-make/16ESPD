"""
    Deck(path, notebook_path, cards)

A live deck: a Slidev deck whose headmatter names the notebook it runs against, as
`pluto.notebook`, relative to the deck file. `cards` resolves every card that notebook declares
to the cell that publishes it.
"""
struct Deck
    path::String
    notebook_path::String
    cards::Dict{String,UUID}
end

"A deck that names no notebook PlutoDeck can open."
struct DeckLoadError <: Exception
    path::String
    problem::String
end

Base.showerror(io::IO, err::DeckLoadError) =
    print(io, "DeckLoadError: ", err.path, ": ", err.problem)

"""
    load_deck(path) -> Deck

Read the notebook a Slidev deck names in its headmatter, and the cards that notebook declares.
"""
function load_deck(path::AbstractString)::Deck
    deck_path = abspath(String(path))
    isfile(deck_path) || throw(DeckLoadError(deck_path, "no such file"))

    headmatter = match(r"\A---\r?\n(.*?)\r?\n---\r?$"ms, read(deck_path, String))
    parsed = headmatter === nothing ? nothing : YAML.load(headmatter[1])
    pluto = parsed isa AbstractDict ? get(parsed, "pluto", nothing) : nothing
    reference = pluto isa AbstractDict ? get(pluto, "notebook", nothing) : nothing
    reference isa AbstractString || throw(DeckLoadError(deck_path,
        "the headmatter names no notebook; a live deck carries pluto: { notebook: path/to/notebook.jl }"))

    notebook_path = normpath(joinpath(dirname(deck_path), reference))
    isfile(notebook_path) || throw(DeckLoadError(deck_path, "pluto.notebook: no such file: $notebook_path"))
    return Deck(deck_path, notebook_path, cards(notebook_path))
end
