# Run numbered scripts from the repository root: julia --project=. sim/fabia/NN_name.jl
# Optional transport packages live in sim/, as in sim/drive.jl.
(dirname(@__DIR__)) in LOAD_PATH || push!(LOAD_PATH, dirname(@__DIR__))
using VehicleSystemsComponents.FabiaProtocol
import VehicleSystemsComponents.FabiaProtocol: schedule
import CANBus
import VehicleSystemsComponents as VSC
using Printf

const IFACE = get(ENV, "FABIA_CAN", "can0")
const RESULTS = joinpath(@__DIR__, "results.txt")

function listen!(echo::Echo, iface, running)
    while running[]
        f = CANBus.recv(iface; timeout_s = 0.1)
        f === nothing && continue
        decode_echo!(echo, f.id, f.data)
    end
end

open_iface() = CANBus.Interface(CANBus.InterfaceConfig(CANBus.SOCKETCAN, IFACE, CANBus.CAN_20, 500_000))

"""
    bench(test; only = nothing, kwargs...)

Run `test(b, echo)` while every frame in `schedule(b)` is sent at its period on `IFACE`
(`FABIA_CAN` env, default can0), decoding the cluster's replies into `echo`. `only` restricts the
frames to a list of ids; `kwargs` set `Bench` fields.
"""
function bench(test::Function; only = nothing, kwargs...)
    b = Bench(; kwargs...)
    echo = Echo()
    tx, rx = VSC.can_open(IFACE), open_iface()
    running = Ref(true)
    t0 = time()
    sender = @async begin
        frames = filter(f -> only === nothing || f[1] in only, schedule(b))
        println("sending on $IFACE: ", join((string(f[1]; base = 16) for f in frames), ", "))
        due = fill(0.0, length(frames))
        while running[]
            t = time() - t0
            for (i, (id, period, build)) in enumerate(frames)
                t >= due[i] || continue
                bytes = VSC.FabiaProtocol.frame!(b, id, build, t, period)
                VSC.can_send(tx, id, bytes)
                # Skip missed slots rather than bursting to catch up after a pause.
                due[i] = max(due[i] + period, t)
            end
            sleep(max(0.001, minimum(due) - (time() - t0)))
        end
    end
    listener = @async listen!(echo, rx, running)
    try
        test(b, echo)
    finally
        running[] = false
        wait(sender); wait(listener)
        VSC.can_close(tx); CANBus.shutdown(rx)
    end
end

status(echo) = @sprintf("cluster: speed %.1f km/h (shown %.1f), coolant %.0f °C, blinker L%d R%d, fault %d, installed ABS %d airbag %d",
    echo.kmh, echo.shown_kmh, echo.coolant, echo.left, echo.right, echo.fault,
    (echo.installed >> 2) & 1, (echo.installed >> 4) & 1)

"Hold a step for `seconds`, printing the cluster echo, then ask the operator what they saw."
function step(name, echo, seconds; ask = true)
    println("\n>>> ", name)
    t_end = time() + seconds
    while time() < t_end
        sleep(1.0)
        println("    ", status(echo))
    end
    ask || return
    print("    Did the dashboard show it? [y/n/comment]: ")
    answer = something(readline(), "")
    open(RESULTS, "a") do io
        println(io, "$(basename(PROGRAM_FILE)) | $name | $answer | $(status(echo))")
    end
end
