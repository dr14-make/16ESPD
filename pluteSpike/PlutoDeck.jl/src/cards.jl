"The cell metadata key a cell uses to publish itself to a deck."
const CARD_METADATA_KEY = "card"

"""
    DuplicateCardsError(notebook_path, duplicates)

A card name is declared by more than one cell, so it addresses no single cell.
"""
struct DuplicateCardsError <: Exception
    notebook_path::String
    duplicates::Vector{Pair{String,Vector{UUID}}}
end

function Base.showerror(io::IO, err::DuplicateCardsError)
    println(io, "DuplicateCardsError: ", err.notebook_path, " declares a card name more than once.")
    for (name, cell_ids) in err.duplicates
        println(io, "  \"", name, "\" is declared by ", length(cell_ids), " cells: ",
            join(cell_ids, ", "))
    end
    print(io, "Give each of those cells its own card name, or remove the key from all but one.")
end

"""
    InvalidCardNameError(notebook_path, cell_id, value)

A cell carries a `card` key whose value cannot name a card.
"""
struct InvalidCardNameError <: Exception
    notebook_path::String
    cell_id::UUID
    value::Any
end

function Base.showerror(io::IO, err::InvalidCardNameError)
    print(io, "InvalidCardNameError: cell ", err.cell_id, " of ", err.notebook_path,
        " declares ", CARD_METADATA_KEY, " = ", repr(err.value),
        ". A card name must be a non-empty string.")
end

"""
    read_notebook(path) -> Pluto.Notebook

Parse a notebook file without running it.

`load_notebook` takes a backup and saves the notebook back over the original; Pluto owns that
file and autosaves it, and a second writer racing that autosave corrupts a lecturer's notebook.
`load_notebook_nobackup` only reads.
"""
read_notebook(path::AbstractString) =
    Pluto.load_notebook_nobackup(String(path); skip_nbpkg=true)

"Card names with the cells declaring them, in notebook order, duplicates included."
function _declared_cards(notebook::Pluto.Notebook)::Vector{Pair{String,Pluto.Cell}}
    declared = Pair{String,Pluto.Cell}[]
    for cell in notebook.cells
        haskey(cell.metadata, CARD_METADATA_KEY) || continue
        name = cell.metadata[CARD_METADATA_KEY]
        if !(name isa AbstractString) || isempty(strip(name))
            throw(InvalidCardNameError(notebook.path, cell.cell_id, name))
        end
        push!(declared, String(name) => cell)
    end
    return declared
end

"""
    cards(notebook) -> Dict{String,UUID}

The cards a notebook publishes, mapped to the cells that declare them. `notebook` is either a
path or a loaded `Pluto.Notebook`.

A cell publishes itself by carrying `card = "some-name"` in its own Pluto metadata. A cell
without the key is scratch work and cannot reach a slide.

Throws `DuplicateCardsError` if a name is declared twice, and `InvalidCardNameError` if a
`card` key holds anything but a non-empty string.
"""
function cards(notebook::Pluto.Notebook)::Dict{String,UUID}
    by_name = Dict{String,Vector{UUID}}()
    for (name, cell) in _declared_cards(notebook)
        push!(get!(Vector{UUID}, by_name, name), cell.cell_id)
    end

    duplicates = sort!([name => cell_ids for (name, cell_ids) in by_name if length(cell_ids) > 1];
        by=first)
    isempty(duplicates) || throw(DuplicateCardsError(notebook.path, duplicates))

    return Dict{String,UUID}(name => only(cell_ids) for (name, cell_ids) in by_name)
end

cards(notebook_path::AbstractString) = cards(read_notebook(notebook_path))

"""
    list_cards([io], notebook)

Print what a notebook publishes, in notebook order, one line per declared card.

Pluto's UI cannot set the `card` key, so the key is added by hand and this is how an author
checks the result. Unlike [`cards`](@ref) it reports duplicates rather than refusing to
continue, since seeing the clash is the point.
"""
function list_cards(io::IO, notebook::Pluto.Notebook)
    declared = _declared_cards(notebook)
    println(io, length(declared), " card", length(declared) == 1 ? "" : "s", " in ", notebook.path)

    seen = Set{String}()
    width = maximum(length(name) for (name, _) in declared; init=0)
    for (name, cell) in declared
        duplicate = name in seen
        push!(seen, name)
        println(io, "  ", rpad(name, width), "  ", cell.cell_id, "  ",
            duplicate ? "DUPLICATE  " : "", _code_summary(cell.code))
    end
    return nothing
end

list_cards(io::IO, notebook_path::AbstractString) = list_cards(io, read_notebook(notebook_path))
list_cards(notebook::Union{Pluto.Notebook,AbstractString}) = list_cards(stdout, notebook)

function _code_summary(code::AbstractString, width::Int=56)
    line = strip(first(split(code, '\n'; limit=2)))
    return length(line) > width ? string(first(line, width - 3), "...") : line
end
