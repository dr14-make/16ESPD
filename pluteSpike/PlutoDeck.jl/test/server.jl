import HTTP
import JSON

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

"A package root laid out like an installed or a checked-out package."
function package_root(; bundle::Bool=false, source::Bool=true)
    root = mktempdir()
    source && mkdir(joinpath(root, "frontend"))
    if bundle
        mkdir(joinpath(root, "frontend-dist"))
        write(joinpath(root, "frontend-dist", "index.html"), "<!DOCTYPE html>")
    end
    return root
end

request(handler, target) = handler(HTTP.Request("GET", target))

@testset "server" begin
    @testset "a checkout serves its source, and a bundle only when forced" begin
        root = package_root(; bundle=true)

        @test frontend_directory(root) == joinpath(root, "frontend")
        withenv("JULIA_PLUTODECK_FORCE_BUNDLED" => "ja") do
            @test frontend_directory(root) == joinpath(root, "frontend-dist")
            @test frontend_directory(root; allow_bundled=false) == joinpath(root, "frontend")
        end
    end

    @testset "an empty frontend-dist is a leftover directory, not a bundle" begin
        root = package_root(; bundle=false)
        mkdir(joinpath(root, "frontend-dist"))

        withenv("JULIA_PLUTODECK_FORCE_BUNDLED" => "ja") do
            @test frontend_directory(root) == joinpath(root, "frontend")
        end
    end

    @testset "the package as shipped serves a frontend that exists" begin
        @test isdir(frontend_directory())
        @test isfile(joinpath(frontend_directory(), "index.html"))
    end

    handler = PlutoDeck._handler(frontend_directory(), load_deck(LECTURE_DECK), fake_session())

    @testset "the root path serves the deck page" begin
        response = request(handler, "/")

        @test response.status == 200
        @test HTTP.header(response, "Content-Type") == "text/html; charset=utf-8"
        @test occursin("PlutoDeck", String(response.body))
    end

    @testset "an asset is served with its own content type" begin
        @test HTTP.header(request(handler, "/deck.js"), "Content-Type") == "text/javascript; charset=utf-8"
        @test HTTP.header(request(handler, "/deck.css"), "Content-Type") == "text/css; charset=utf-8"
    end

    @testset "a development asset is never cached" begin
        @test HTTP.header(request(handler, "/deck.js"), "Cache-Control") == "no-store"
    end

    @testset "a content-hashed bundled asset is cached hard" begin
        root = package_root(; bundle=true)
        write(joinpath(root, "frontend-dist", "deck.a1b2c3d4.js"), "export {}")
        bundled = withenv(() -> frontend_directory(root), "JULIA_PLUTODECK_FORCE_BUNDLED" => "ja")
        serving = PlutoDeck._handler(bundled, load_deck(LECTURE_DECK), fake_session())

        @test occursin("immutable", HTTP.header(request(serving, "/deck.a1b2c3d4.js"), "Cache-Control"))
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
