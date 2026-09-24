import HTTP
import JSON
import PlutoPlotly

using PlutoDeck: DeckServer, Session, frontend_directory, load_deck

"""
A `Session` with nothing running behind it.

Every route this file exercises reads the session as data, so a server and a kernel would
only buy thirty seconds of start-up per assertion. `test/session.jl` drives the same routes
against a real one.
"""
fake_session() = Session(
    Pluto.ServerSession(),
    Pluto.RunningPlutoServer(nothing, @task nothing),
    Pluto.Notebook([cell("x = 1")], THREE_CARDS),
    "http://localhost:1234",
    "s3cr3t42",
)

"A package root holding a built bundle, which is the only form a frontend is served in."
function package_root(; bundle::Bool=true)
    root = mktempdir()
    mkdir(joinpath(root, "frontend"))
    if bundle
        mkdir(joinpath(root, "frontend-dist"))
        write(joinpath(root, "frontend-dist", "index.html"), "<!DOCTYPE html>")
    end
    return root
end

request(handler, target) = handler(HTTP.Request("GET", target))

@testset "server" begin
    @testset "serving refuses a bundle that was never built" begin
        # `frontend/` holds TypeScript, so a missing bundle is a deck with nothing to serve
        # rather than one that quietly falls back to source.
        root = package_root(; bundle=false)

        @test !PlutoDeck._holds_a_bundle(joinpath(root, "frontend-dist"))
        @test !PlutoDeck._holds_a_bundle(mkdir(joinpath(root, "frontend-dist")))
    end

    @testset "the package as shipped serves a bundle that exists" begin
        @test isdir(frontend_directory())
        @test isfile(joinpath(frontend_directory(), "index.html"))
        @test isfile(joinpath(frontend_directory(), "speaker.html"))
    end

    @testset "the bundle's Plotly is the version a plot cell will ask for" begin
        # A plot cell reads `window.plutoplotly_imports[get_plotly_version()]` and falls
        # through to esm.sh for any other key — silently, so the deck works at a desk and every
        # plot on it is blank in a lecture room. A bumped PlutoPlotly has to move
        # `plotly.js-dist-min` in `frontend/package.json` with it, and this is what says so.
        page = read(joinpath(frontend_directory(), "index.html"), String)
        declared = match(r"rel=\"plotly-source\"[^>]*data-version=\"([^\"]+)\"", page)

        @test declared !== nothing
        @test declared[1] == string(PlutoPlotly.get_plotly_version())
    end

    @testset "every library a plot script imports by URL is one the deck serves" begin
        # PlutoPlotly's scripts import lodash and interact.js from a CDN by absolute URL, with a
        # top-level await, so a specifier the import map does not name is a plot card that draws
        # nothing in a room with no wifi. The browser suite covers it too, but only where Chrome
        # is installed and only after a cold kernel; this costs nothing and always runs.
        #
        # Read out of the installed PlutoPlotly rather than written down, so a release that
        # moves a URL fails here naming the one that drifted.
        imported = Set{String}()
        for (root, _, files) in walkdir(joinpath(pkgdir(PlutoPlotly), "src")), file in files
            text = read(joinpath(root, file), String)
            for matched in eachmatch(r"import\(\s*[\"'](https://[^\"']+)[\"']\s*\)", text)
                push!(imported, matched[1])
            end
        end

        page = read(joinpath(frontend_directory(), "index.html"), String)
        declared = match(r"<script type=\"importmap\">(.*?)</script>"s, page)

        # A PlutoPlotly that stops importing by URL has to fail here rather than pass vacuously.
        @test !isempty(imported)
        @test declared !== nothing
        @test imported ⊆ keys(JSON.parse(declared[1])["imports"])
    end

    @testset "the bundle carries no vendored dependency" begin
        # Every dependency comes from npm and is bundled; `frontend/vendor/` is gone.
        @test !isdir(joinpath(PlutoDeck.PACKAGE_ROOT, "frontend", "vendor"))
    end

    handler = PlutoDeck._handler(frontend_directory(), load_deck(LECTURE_DECK), fake_session())

    @testset "the root path serves the deck page" begin
        response = request(handler, "/")

        @test response.status == 200
        @test HTTP.header(response, "Content-Type") == "text/html; charset=utf-8"
        @test occursin("PlutoDeck", String(response.body))
    end

    @testset "an asset is served with its own content type" begin
        entry = only(filter(startswith("deck.entry-"), readdir(frontend_directory())))
        style = only(filter(endswith(".css"), readdir(frontend_directory())))

        @test HTTP.header(request(handler, "/" * entry), "Content-Type") == "text/javascript; charset=utf-8"
        @test HTTP.header(request(handler, "/" * style), "Content-Type") == "text/css; charset=utf-8"
    end

    @testset "a content-hashed asset is cached hard, and the page that names it is not" begin
        root = package_root()
        write(joinpath(root, "frontend-dist", "deck.entry-A1B2C3D4.js"), "export {}")
        serving = PlutoDeck._handler(frontend_directory(root), load_deck(LECTURE_DECK), fake_session())

        @test occursin("immutable",
            HTTP.header(request(serving, "/deck.entry-A1B2C3D4.js"), "Cache-Control"))
        @test HTTP.header(request(serving, "/index.html"), "Cache-Control") == "no-store"
    end

    @testset "/api/session carries what the browser needs to reach Pluto" begin
        response = request(handler, "/api/session")
        body = JSON.parse(String(response.body))

        @test response.status == 200
        @test HTTP.header(response, "Content-Type") == "application/json; charset=utf-8"
        @test body["plutoUrl"] == "http://localhost:1234"
        @test body["secret"] == "s3cr3t42"
        @test occursin(body["notebook_id"], body["editUrl"])
        @test occursin(body["secret"], body["editUrl"])
    end

    @testset "/api/deck carries the validated deck, cards resolved to cells" begin
        response = request(handler, "/api/deck")
        body = JSON.parse(String(response.body))

        @test response.status == 200
        @test body["notebook"] == THREE_CARDS
        @test body["preamble"] == []
        @test length(body["slides"]) == 2
        @test body["slides"][1]["cards"][1] ==
            Dict("card" => "target-speed", "x" => 0, "y" => 0, "w" => 4, "h" => 2, "snapshot" => nothing)
        @test body["cards"]["metrics"] == "a1000000-0000-4000-8000-000000000004"
    end

    @testset "/api/deck carries a slide's cues as markdown, and says so when it has none" begin
        path = deck_file("""
            { "notebook": "NOTEBOOK",
              "slides": [
                { "notes": "notes/proportional.md",
                  "cards": [{ "card": "metrics", "x": 0, "y": 0, "w": 4, "h": 3 }] },
                { "cards": [{ "card": "speed-plot", "x": 0, "y": 0, "w": 4, "h": 3 }] }
              ] }
            """; beside=Dict("notes/proportional.md" => "hold **Kp** at 2"))
        serving = PlutoDeck._handler(frontend_directory(), load_deck(path), fake_session())
        slides = JSON.parse(String(request(serving, "/api/deck").body))["slides"]

        @test slides[1]["notes"]["markdown"] == "hold **Kp** at 2"
        @test slides[1]["notes"]["path"] == joinpath(dirname(path), "notes", "proportional.md")
        @test slides[2]["notes"] === nothing
    end

    @testset "a cue rewritten five minutes before a lecture costs a refresh, not a restart" begin
        path = deck_file("""
            { "notebook": "NOTEBOOK",
              "slides": [{ "notes": "notes/cue.md",
                           "cards": [{ "card": "metrics", "x": 0, "y": 0, "w": 4, "h": 3 }] }] }
            """; beside=Dict("notes/cue.md" => "the first wording"))
        deck = load_deck(path)
        serving = PlutoDeck._handler(frontend_directory(), deck, fake_session())
        cue(handling) = JSON.parse(String(request(handling, "/api/deck").body))["slides"][1]["notes"]

        @test cue(serving)["markdown"] == "the first wording"

        # The same loaded deck, the same server: only the file on disk changed, which is the
        # whole point of holding the path rather than the text.
        write(only(deck.slides).notes, "the second wording")

        @test cue(serving)["markdown"] == "the second wording"
    end

    @testset "cues that have gone missing since load are reported, not served as empty" begin
        path = deck_file("""
            { "notebook": "NOTEBOOK",
              "slides": [{ "notes": "notes/cue.md",
                           "cards": [{ "card": "metrics", "x": 0, "y": 0, "w": 4, "h": 3 }] }] }
            """; beside=Dict("notes/cue.md" => "still here"))
        deck = load_deck(path)
        serving = PlutoDeck._handler(frontend_directory(), deck, fake_session())
        rm(only(deck.slides).notes)

        response = request(serving, "/api/deck")
        notes = JSON.parse(String(response.body))["slides"][1]["notes"]

        @test response.status == 200
        @test !haskey(notes, "markdown")
        @test occursin("cue.md", notes["error"])
    end

    @testset "an absent file is the only 404" begin
        response = request(handler, "/does-not-exist.js")

        @test response.status == 404
        @test occursin("not found", String(response.body))
    end

    @testset "a path escaping the frontend directory is refused" begin
        @test request(handler, "/../Project.toml").status == 403
        @test request(handler, "/%2e%2e/Project.toml").status == 403
    end

    @testset "a handler that throws is a logged 500, never a silent 404" begin
        response = @test_logs (:error,) match_mode = :any request(handler, "/%00")

        @test response.status == 500
        @test occursin("server error", String(response.body))
    end
end
