# Boots a Pluto server for the spike and publishes its connection details.
#
# The secret stays on: Pluto accepts websockets from any origin, so a server without one
# lets any page the browser visits run Julia on this machine.
import Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()
using Pluto

const PORT = parse(Int, get(ENV, "PLUTE_PLUTO_PORT", "1235"))

session = Pluto.ServerSession()
session.options.server.port = PORT
session.options.server.launch_browser = false
session.options.security.require_secret_for_access = true
session.options.security.require_secret_for_open_links = true

write(joinpath(@__DIR__, ".session"), string(PORT, "\n", session.secret))
@info "Pluto starting" port = PORT version = pkgversion(Pluto)

Pluto.run(session)
