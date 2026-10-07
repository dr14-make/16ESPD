"""
    Deck(path, notebook_path, cards)

A loaded live deck: a Slidev deck whose headmatter names the notebook it runs against, as
`pluto.notebook`. Every card the deck places by a literal name resolves to a cell of
`notebook_path`; `cards` carries that resolution for the whole notebook, including cards the
deck does not use.

Where a card sits, and what the slide around it says, belong to Slidev. The deck is read here
only to find its notebook and to refuse a card name no cell declares before a kernel starts.
"""
struct Deck
    path::String
    notebook_path::String
    cards::Dict{String,UUID}
end

"""
    DeckLoadError(path, problems, hints)

A deck cannot be loaded. `problems` lists every fault found, each naming what a human has to
fix and where; `hints` carries context that helps fix them but is not itself a fault.
"""
struct DeckLoadError <: Exception
    path::String
    problems::Vector{String}
    hints::Vector{String}
end

DeckLoadError(path::AbstractString, problems::Vector{String}) =
    DeckLoadError(path, problems, String[])

function Base.showerror(io::IO, err::DeckLoadError)
    println(io, "DeckLoadError: ", err.path, " cannot be loaded.")
    for problem in err.problems
        println(io, "  ", problem)
    end
    for hint in err.hints
        println(io, hint)
    end
    print(io, length(err.problems), " problem", length(err.problems) == 1 ? "" : "s", " found.")
end

"""
A card placed by a literal name, its attributes free to wrap across lines. `:name=\"…\"` binds an
expression, which only the browser can resolve.
"""
const PLACED_CARD = r"<PlutoCard\b[^>]*?(?<![:\w-])name=([\"'])(.*?)\1"

"""
    load_deck(path) -> Deck

Load a Slidev deck, read its notebook from the headmatter and resolve every card placed in any
Markdown file of the deck's folder against that notebook.

Slidev resolves a deck's `src:` imports itself, and every section it can reach lives in the
deck's folder.

Every fault is collected before anything is thrown, so one load reports everything that is
wrong with a hand-authored deck rather than one fault per attempt.
"""
function load_deck(path::AbstractString)::Deck
    deck_path = abspath(String(path))
    isfile(deck_path) || throw(DeckLoadError(deck_path, ["no such file"]))

    problems = String[]
    notebook_path = _headmatter_notebook(problems, deck_path)

    # Card names cannot be resolved without the notebook, and reporting every placement as
    # unresolved when the notebook path is simply wrong buries the one fault that matters.
    (isempty(problems) && notebook_path !== nothing) || throw(DeckLoadError(deck_path, problems))

    published = cards(notebook_path)
    hints = _resolve_cards!(problems, _placed_cards(dirname(deck_path)), published, notebook_path)
    isempty(problems) || throw(DeckLoadError(deck_path, problems, hints))

    return Deck(deck_path, notebook_path, published)
end

"The notebook `pluto.notebook` names in the deck's headmatter, resolved against the deck file."
function _headmatter_notebook(problems::Vector{String}, deck_path::String)
    lines = readlines(deck_path)
    close_at = findnext(==("---"), lines, 2)
    if isempty(lines) || lines[1] != "---" || close_at === nothing
        push!(problems, "the deck has no headmatter: it must open with a `---` block naming pluto.notebook")
        return nothing
    end

    headmatter = try
        YAML.load(join(lines[2:(close_at - 1)], "\n"))
    catch err
        err isa InterruptException && rethrow()
        push!(problems, "the deck's headmatter is not valid YAML: " * sprint(showerror, err))
        return nothing
    end

    pluto = headmatter isa AbstractDict ? get(headmatter, "pluto", nothing) : nothing
    reference = pluto isa AbstractDict ? get(pluto, "notebook", nothing) : nothing
    if reference === nothing
        push!(problems, "the deck's headmatter: \"pluto.notebook\" is missing; " *
            "a live deck names its notebook as pluto: { notebook: path/to/notebook.jl }")
        return nothing
    elseif !(reference isa AbstractString) || isempty(strip(reference))
        push!(problems, "the deck's headmatter: \"pluto.notebook\" must be a non-empty string, got $(repr(reference))")
        return nothing
    end

    resolved = normpath(joinpath(dirname(deck_path), reference))
    isfile(resolved) || push!(problems, "the deck's headmatter: \"pluto.notebook\": no such file: $resolved")
    return resolved
end

"Every card placed by a literal name in a Markdown file under `folder`, with the `file:line` it is written at."
function _placed_cards(folder::String)
    placed = Pair{String,String}[]
    for (root, directories, files) in walkdir(folder)
        filter!(!in(("public", "node_modules")), directories)
        for file in filter(endswith(".md"), files)
            path = joinpath(root, file)
            text = read(path, String)
            for found in eachmatch(PLACED_CARD, text)
                line = count(==('\n'), SubString(text, 1, found.offset)) + 1
                push!(placed, found[2] => "$(relpath(path, folder)):$line")
            end
        end
    end
    return placed
end

"Report every placed card no cell publishes, and return the hints that help place them."
function _resolve_cards!(problems::Vector{String}, placed::Vector{Pair{String,String}},
        published::Dict{String,UUID}, notebook_path::String)
    unresolved = false
    for (name, where) in placed
        haskey(published, name) && continue
        unresolved = true
        push!(problems, "$where: no cell of $notebook_path declares card = \"$name\"")
    end
    unresolved || return String[]

    return [isempty(published) ?
        "That notebook publishes no cards at all: a cell publishes itself by carrying card = \"some-name\" in its own metadata." :
        "That notebook publishes: " * join(("\"$name\"" for name in sort!(collect(keys(published)))), ", ") * "."]
end
