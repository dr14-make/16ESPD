# The Pluto server behind a live deck, which the addon's dev server starts and stops:
#
#     julia --project=kernel kernel/pluto.jl <port> <secret> <notebook>...
#
# Every notebook opens with execution allowed: one parked waiting for permission waits on a
# button in Pluto's editor, which no deck can reach. The secret guards access and open links
# alike, because Pluto accepts websockets from any origin and a server without one lets any page
# the browser visits run Julia on this machine.

import Pkg
Pkg.instantiate()
import Pluto

port, secret, notebooks... = ARGS

options = Pluto.Configuration.from_flat_kwargs(;
    host="127.0.0.1",
    port=parse(Int, port),
    notebook=notebooks,
    launch_browser=false,
    dismiss_update_notification=true,
    require_secret_for_access=true,
    require_secret_for_open_links=true,
)

# Stopping is the dev server closing this pipe, or dying, which closes it too. `exit` runs the
# atexit hooks that stop Pluto's workers.
@async begin
    read(stdin)
    exit()
end

Pluto.run(Pluto.ServerSession(; secret, options))
