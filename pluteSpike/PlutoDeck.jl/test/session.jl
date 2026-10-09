import HTTP
import JSON
import Pluto

using PlutoDeck: SessionStartError, edit_url, in_temp_dir, load_deck, shutdown!, start_session,
    write_session_file

"The cell of `runnable.jl` that reads the `freq` bond."
const SAMPLES_CELL = Base.UUID("a1000000-0000-4000-8000-000000000003")

"A notebook and a deck of its own, outside the repository, since Pluto rewrites what it opens."
function workspace_deck()
    path = deck_file("""
        ---
        pluto:
          notebook: runnable.jl
        ---

        <PlutoCard name="frequency" />
        <PlutoCard name="samples" />

        ---

        <PlutoCard name="readout" />
        """; beside=Dict("runnable.jl" => read(RUNNABLE, String)))
    return load_deck(path)
end

"""
    bond_round_trip(session, symbol, value, cell_id) -> Bool

Whether setting a bond re-runs the cell that reads it.

An HTTP 200 is not a health check — the spike twice served one over a dead kernel. The only
honest probe changes a bond and confirms a watched cell's `last_run_timestamp` advances.
"""
function bond_round_trip(session, symbol::Symbol, value, cell_id)
    watched = session.notebook.cells_dict[cell_id]
    before = watched.output.last_run_timestamp

    session.notebook.bonds[symbol] = Pluto.BondValue(value)
    Pluto.set_bond_values_reactive(;
        session=session.pluto, notebook=session.notebook,
        bound_sym_names=[symbol], run_async=false)

    return watched.output.last_run_timestamp > before
end

@testset "session" begin
    @testset "a notebook that is not there is refused before Pluto starts" begin
        @test_throws SessionStartError start_session(joinpath(FIXTURES, "nothing-here.jl"))
    end

    deck = workspace_deck()
    session = start_session(deck.notebook_path; io=nothing)
    workspace = Pluto.WorkspaceManager.get_workspace((session.pluto, session.notebook);
        allow_creation=false)

    try
        @testset "the kernel reaches ready with every cell terminal" begin
            @test session.notebook.process_status == Pluto.ProcessStatus.ready
            @test all(cell -> !cell.queued && !cell.running, session.notebook.cells)
            @test !any(cell -> cell.errored, session.notebook.cells)
        end

        @testset "the notebook runs from the file the deck names" begin
            @test session.notebook.path == deck.notebook_path
            @test !in_temp_dir(session)
        end

        @testset "a bond change re-runs the cell that reads it" begin
            @test bond_round_trip(session, :freq, 4, SAMPLES_CELL)
        end

        @testset "the session file points the browser straight at Pluto, for its owner alone" begin
            file = write_session_file(deck, session)

            @test dirname(file) == dirname(deck.path)
            @test JSON.parse(read(file, String)) ==
                Dict("plutoUrl" => session.url, "secret" => session.secret)
            @test filemode(file) & 0o777 == 0o600
            @test !isfile(file * ".partial")
        end

        @testset "the editor link opens the notebook" begin
            @test HTTP.get(edit_url(session)).status == 200
        end
    finally
        shutdown!(session)
    end

    @testset "shutting down leaves no worker behind" begin
        @test !Base.process_running(workspace.worker.proc)
        @test !isopen(session.server.http_server)
        @test isempty(session.pluto.notebooks)
    end
end
