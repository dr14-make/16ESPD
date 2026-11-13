# Source/metadata audit only: no generated model loading, compilation, or simulation.
using Test, JSON, TOML

module ExtraCanvasAudit
using JSON, TOML

# Explicit exceptions only. Keys are fully qualified component names. Values are exact
# stripped relation lines or port endpoints (e.g. "sensor.y"). Do not wildcard these.
# Equations implementing constitutive behavior belong here; canvas wiring does not.
const KEPT_RELATIONS = Dict{String,Set{String}}(
    "VehicleSystemsComponents.Vehicle.Electric.SoCCounter" => Set(["quiet = quiet_value.y", "rest_time = rest_gate.y", "estimate = estimate_gate.y"]),
    "VehicleSystemsComponents.Vehicle.Electric.BalancingString" => Set([
        "v_min = minimum.y",
        "v_max = maximum.y",
        "Ah_out = discharge.y",
    ]),
    "VehicleSystemsComponents.Vehicle.Electric.BleedCell" => Set([
        "I_bleed = shunt.i",
        "P_bleed = v * I_bleed",
    ]),
    "VehicleSystemsComponents.Vehicle.Electric.CCCVCharger" => Set{String}(["v = voltage.v"]),
    "VehicleSystemsComponents.Vehicle.Electric.PackThermal" => Set{String}(["E_in = in_energy.y", "E_out = out_energy.y"]),
    "VehicleSystemsComponents.Vehicle.Electric.PassiveBalancer" => Set([
        "initial voltage_filter.y = voltage",
        "initial delta_filter.y = voltage - minimum_voltage",
        "initial latch.y = 0.0",
        "measured_voltage = voltage_filter.y",
        "measured_delta = delta_filter.y",
        "fraction = latch.y",
        "delta_threshold = delta_level.y",
        "top_threshold = top_level.y",
        "request = demand.y",
    ]),
    "VehicleSystemsComponents.Vehicle.Electric.SoCEstimator" => Set([
        "I_measured = measured.y",
    ]),
    "VehicleSystemsComponents.Vehicle.Electric.ThermalCharge" => Set{String}(["initial link.v = battery.E", "throughput = throughput_integrator.y"]),
    "VehicleSystemsComponents.Vehicle.Electric.TheveninCell" => Set([
        "initial capacitor.v = 0.0",
        "E = series_count.y",
        "i = current.i",
        "v1 = capacitor.v",
    ]),
    "VehicleSystemsComponents.Vehicle.Planar.PlanarBEVTheveninWLTC" => Set([
        "P_dc = drive.battery.v * drive.battery.i",
        "P_shaft = drive.machine.P_mech",
        "der(E_cells) = drive.battery.E * drive.battery.i",
        "der(E_dc) = P_dc",
        "der(E_dc_out) = max(P_dc, 0.0)",
        "der(E_dc_in) = max(-P_dc, 0.0)",
        "der(E_RC) = drive.battery.v1 * drive.battery.i",
        "der(E_R0) = drive.battery.R0 * drive.battery.i ^ 2",
        "der(E_aux) = drive.aux.v * drive.aux.i",
        "der(E_conv) = drive.converter.P_loss",
        "der(E_motor) = drive.machine.P_loss",
        "der(E_shaft_out) = max(P_shaft, 0.0)",
        "der(E_shaft_in) = max(-P_shaft, 0.0)",
        "der(E_road) = roadload.F * car.bus.vx",
        "der(E_brake) = car.fl.brake.tau_friction * car.fl.brake.w + car.fr.brake.tau_friction * car.fr.brake.w + car.rl.brake.tau_friction * car.rl.brake.w + car.rr.brake.tau_friction * car.rr.brake.w",
        "der(E_tire) = car.fl.joint.f_long * car.fl.joint.v_slip_long + car.fl.joint.f_lat * car.fl.joint.v_slip_lat + car.fr.joint.f_long * car.fr.joint.v_slip_long + car.fr.joint.f_lat * car.fr.joint.v_slip_lat + car.rl.joint.f_long * car.rl.joint.v_slip_long + car.rl.joint.f_lat * car.rl.joint.v_slip_lat + car.rr.joint.f_long * car.rr.joint.v_slip_long + car.rr.joint.f_lat * car.rr.joint.v_slip_lat",
        "E_kin = 0.5 * m * (car.body.v[1] ^ 2 + car.body.v[2] ^ 2) + 0.5 * car.Iz * car.body.w ^ 2 + 0.5 * car.J * (car.fl.inertia.w ^ 2 + car.fr.inertia.w ^ 2 + car.rl.inertia.w ^ 2 + car.rr.inertia.w ^ 2) + 0.5 * drive.machine.J * drive.machine.rotor.w ^ 2 + 0.5 * drive.machine.L * drive.machine.inductor.i ^ 2",
        "initial car.body.r = [0, 0]",
        "initial car.body.v = [0, 0]",
        "initial car.body.phi = 0.0",
        "initial car.body.w = 0.0",
        "initial car.fl.inertia.w = dv_wheel / radius",
        "initial car.fr.inertia.w = dv_wheel / radius",
        "initial car.rl.inertia.w = dv_wheel / radius",
        "initial car.rr.inertia.w = dv_wheel / radius",
        "initial car.fl.inertia.phi = 0.0",
        "initial car.fr.inertia.phi = 0.0",
        "initial car.rl.inertia.phi = 0.0",
        "initial car.rr.inertia.phi = 0.0",
        "initial car.fl.brake.tau_actual = 0.0",
        "initial car.fr.brake.tau_actual = 0.0",
        "initial car.rl.brake.tau_actual = 0.0",
        "initial car.rr.brake.tau_actual = 0.0",
        "initial drive.converter.i_out = 0.0",
        "initial E_cells = 0.0",
        "initial E_dc = 0.0",
        "initial E_dc_out = 0.0",
        "initial E_dc_in = 0.0",
        "initial E_RC = 0.0",
        "initial E_R0 = 0.0",
        "initial E_aux = 0.0",
        "initial E_conv = 0.0",
        "initial E_motor = 0.0",
        "initial E_shaft_out = 0.0",
        "initial E_shaft_in = 0.0",
        "initial E_road = 0.0",
        "initial E_brake = 0.0",
        "initial E_tire = 0.0",
    ]),
)
# Unused telemetry and intentionally free physical attachments. No input exemptions.
const OPEN_PORTS = Dict{String,Set{String}}(
    "VehicleSystemsComponents.Vehicle.Electric.TestBleedCell" => Set(["battery.p"]),
    "VehicleSystemsComponents.Vehicle.Electric.BleedCell" => Set(["cell.SoC", "cell.stored_current", "cell.stored_voltage"]),
    "VehicleSystemsComponents.Vehicle.Electric.CCCV800V" => Set(["battery.SoC", "battery.stored_current", "battery.stored_voltage", "charger.current", "charger.phase"]),
    "VehicleSystemsComponents.Vehicle.Electric.CCCVLeafCharge" => Set(["battery.SoC", "battery.stored_current", "battery.stored_voltage", "charger.current", "charger.phase"]),
    "VehicleSystemsComponents.Vehicle.Electric.RapidgateTwoCharges" => Set(["battery.SoC", "battery.dissipated", "battery.stored_voltage", "charger.current", "charger.phase"]),
    "VehicleSystemsComponents.Vehicle.Electric.SoCDriftDays" => Set(["battery.stored_voltage"]),
    "VehicleSystemsComponents.Vehicle.Electric.TestPackThermal" => Set(["pack.T"]),
    "VehicleSystemsComponents.Vehicle.Electric.TestPassiveBalancer" => Set(["channel.bleed"]),
    "VehicleSystemsComponents.Vehicle.Electric.TestThermalTheveninCell" => Set(["battery.SoC", "battery.dissipated", "battery.stored_current", "battery.stored_voltage"]),
    "VehicleSystemsComponents.Vehicle.Electric.TestTheveninCell" => Set(["battery.SoC", "battery.stored_current", "battery.stored_voltage"]),
    "VehicleSystemsComponents.Vehicle.Electric.ThermalACvsDC" => Set(["ac.stage", "dc.stage"]),
    "VehicleSystemsComponents.Vehicle.Electric.ThermalCharge" => Set(["battery.SoC", "battery.dissipated", "battery.stored_voltage", "charger.current", "charger.phase"]),
    "VehicleSystemsComponents.Vehicle.Electric.TheveninElectricDrive" => Set(["battery.stored_current", "battery.stored_voltage"]),
    "VehicleSystemsComponents.Vehicle.Planar.PlanarBEVTheveninWLTC" => Set(["car.spin_rl", "car.spin_rr", "car.wheel_fl", "car.wheel_fr", "car.wheel_rl", "car.wheel_rr", "drive.SoC", "motion.ax", "motion.ay", "motion.beta", "motion.delta_sw", "motion.psi", "motion.r", "motion.vy", "motion.x", "motion.y"]),
)

function code_only(text)
    replace(text, r"\"\"\"[\s\S]*?\"\"\"|\"(?:\\.|[^\"\\])*\"|#[^\n]*" =>
        s -> replace(s, r"[^\n]" => c -> repeat(" ", ncodeunits(c))))
end
function component_sections(source)
    starts = collect(eachmatch(r"(?m)^[ \t]*(?:(?:test|partial|external) )?component (\w+)", code_only(source)))
    [(; name = component.captures[1], offset = component.offset,
        text = source[component.offset:(index < length(starts) ?
            prevind(source, starts[index + 1].offset) : lastindex(source))])
     for (index, component) in enumerate(starts)]
end

function nested_connections(file, text)
    violations = Tuple{String,Int,String}[]
    blocks = String[]
    for (number, raw) in enumerate(split(code_only(text), '\n'))
        line = strip(raw)
        startswith(line, "metadata ") && continue
        opener = match(r"^(if|for|while|when)\s", line)
        if !isnothing(opener)
            push!(blocks, opener.captures[1])
        elseif line == "end" && !isempty(blocks)
            pop!(blocks)
        end
        "if" in blocks && occursin(r"\bconnect\s*\(", line) &&
            push!(violations, (file, number, raw))
    end
    violations
end

# Local and reference declarations are indexed by namespace.
definitions = Dict{String,Any}()
connectors = Set{String}()
function index_components(root, prefix; local_source)
    for (dir, _, names) in walkdir(root), name in names
        endswith(name, ".dyad") || continue
        file = joinpath(dir, name)
        source = read(file, String)
        # relpath(root, root) is ".", not a namespace segment.
        namespace = join([prefix; filter(x -> x != ".", splitpath(relpath(dir, root)))], ".")
        for m in eachmatch(r"(?m)^connector (\w+)", code_only(source))
            push!(connectors, namespace * "." * m.captures[1])
        end
        for c in component_sections(source)
            key = namespace * "." * c.name
            # Analyses and functions are not members of the component type.
            boundary = match(r"(?m)^(?:analysis|function|connector|type)\s", code_only(c.text))
            text = isnothing(boundary) ? c.text : c.text[1:prevind(c.text, boundary.offset)]
            definitions[key] = (; c..., text, file, namespace, local_source,
                first_line = count(==('\n'), source[1:prevind(source, c.offset)]))
        end
    end
end
index_components(joinpath(@__DIR__, "..", "dyad"), "VehicleSystemsComponents"; local_source = true)
project = TOML.parsefile(joinpath(@__DIR__, "..", "Project.toml"))
for library in keys(project["deps"])
    entry = Base.find_package(library)
    isnothing(entry) && error("Project dependency $library is not installed")
    source = joinpath(dirname(dirname(entry)), "dyad")
    isdir(source) && index_components(source, library; local_source = false)
end
function resolve_type(type, owner)
    haskey(definitions, type) && return type
    namespace = split(definitions[owner].namespace, '.')
    while !isempty(namespace)
        candidate = join([namespace; type], ".")
        haskey(definitions, candidate) && return candidate
        pop!(namespace)
    end
    nothing
end
function bases(key)
    [m.captures[1] for m in eachmatch(r"(?m)^\s*extends\s+([\w.]+)", code_only(definitions[key].text))]
end
function declarations(key)
    text = first(split(code_only(definitions[key].text), r"(?m)^relations\s*$"; limit = 2))
    Dict(m.captures[1] => m.captures[2] for m in
        eachmatch(r"(?m)^\s*(\w+)\s*=\s*([\w.]+)(?:@\[[^\n]*?\])?\s*\(", text))
end
member_cache = Dict{String,Dict{String,Tuple{String,String}}}()
function members(key, seen = Set{String}())
    haskey(member_cache, key) && return member_cache[key]
    key in seen && error("Cyclic component inheritance: $key")
    result = Dict{String,Tuple{String,String}}()
    for base in bases(key)
        parent = resolve_type(base, key)
        isnothing(parent) && error("Unresolved base $base in $key")
        merge!(result, members(parent, union(seen, [key])))
    end
    for (name, type) in declarations(key)
        result[name] = (type, key)
    end
    member_cache[key] = result
end

function meta_of(text)
    m = match(r"(?s)metadata (\{.*?\})\nend", text)
    isnothing(m) ? nothing : JSON.parse(m.captures[1])
end
placement(links, name, kind) = get(get(get(get(links, name, Dict()), "Dyad", Dict()), "placement", Dict()), kind, nothing)

# Studio draws a component from its own metadata merged over its bases'.
own_meta(key) = something(meta_of(definitions[key].text), Dict{String,Any}())
meta_cache = Dict{String,Any}()
function merged_meta(key)
    get!(meta_cache, key) do
        links, labels = Dict{String,Any}(), nothing
        for base in bases(key)
            parent = resolve_type(base, key)
            isnothing(parent) && continue
            l, lab = merged_meta(parent)
            merge!(links, l)
            isnothing(lab) || (labels = lab)
        end
        meta = own_meta(key)
        merge!(links, get(meta, "_links", Dict{String,Any}()))
        lab = get(get(meta, "Dyad", Dict{String,Any}()), "labels", nothing)
        (links, isnothing(lab) ? labels : lab)
    end
end
# Maps a point of a child's 0-1000 icon frame onto the parent canvas; a box with x1 > x2
# or y1 > y2 is mirrored and "rot" turns it clockwise.
function on_canvas(box, u, v)
    for _ in 1:(mod(Int(get(box, "rot", 0)), 360) ÷ 90)
        u, v = 1000 - v, u
    end
    (box["x1"] + (box["x2"] - box["x1"]) * u / 1000, box["y1"] + (box["y2"] - box["y1"]) * v / 1000)
end
is_component(type, owner) = !isnothing(resolve_type(type, owner))
# Connectors the Dyad language defines; library connectors are indexed from source.
builtin_connectors = Set(("RealInput", "RealOutput", "BooleanInput", "BooleanOutput",
    "IntegerInput", "IntegerOutput", "ClockInput", "ClockOutput", "Spline", "Pin", "Frame", "Frame2D", "Frame3D", "Flange", "HeatPort"))
function is_connector(type, owner)
    type in builtin_connectors && return true
    namespace = split(definitions[owner].namespace, '.')
    while true
        join([namespace; type], ".") in connectors && return true
        isempty(namespace) && return false
        pop!(namespace)
    end
end
function canvas(key)
    links, _ = merged_meta(key)
    ports, blocks = Dict{String,Tuple{Float64,Float64}}(), Dict{String,Any}()
    unresolved = String[]
    for (name, (type, owner)) in members(key)
        box = placement(links, name, "diagram")
        isnothing(box) && is_connector(type, owner) && (box = placement(links, name, "icon"))
        isnothing(box) && continue
        if is_component(type, owner)
            child = resolve_type(type, owner)
            child_links, child_labels = merged_meta(child)
            for (port, (ptype, powner)) in members(child)
                is_component(ptype, powner) && continue
                icon = something(placement(child_links, port, "icon"), placement(child_links, port, "diagram"), Some(nothing))
                isnothing(icon) && continue
                is_connector(ptype, powner) || (push!(unresolved, "$name.$port::$ptype"); continue)
                ports[name * "." * port] = on_canvas(box, (icon["x1"] + icon["x2"]) / 2, (icon["y1"] + icon["y2"]) / 2)
            end
            anchors = something(child_labels, [Dict("x" => 500, "y" => 1100)])
            label_ys = [on_canvas(box, l["x"], l["y"])[2] for l in anchors]
            x1, x2 = minmax(box["x1"], box["x2"])
            y1, y2 = minmax(box["y1"], box["y2"])
            # Reserve a 40-unit label band, centered on each label anchor.
            blocks[name] = isempty(label_ys) ? (x1, y1, x2, y2) :
                (x1, min(y1, minimum(label_ys) - 20), x2, max(y2, maximum(label_ys) + 20))
        elseif is_connector(type, owner)
            ports[name] = ((box["x1"] + box["x2"]) / 2, (box["y1"] + box["y2"]) / 2)
        else
            push!(unresolved, "$name::$type")
        end
    end
    wires = Tuple{String,Vector{Tuple{Float64,Float64}}}[]
    junctions = Tuple{String,Float64,Float64}[]
    function collect_connects(k)
        for base in bases(k)
            parent = resolve_type(base, k)
            isnothing(parent) || collect_connects(parent)
        end
        # An untagged connect has no metadata and is drawn as one straight edge per target.
        for c in eachmatch(r"connect\(([^)]*)\)(?:\s*\{\^(\w+)\})?", code_only(definitions[k].text))
            ends = strip.(split(c.captures[1], ','))
            tag = something(c.captures[2], "untagged connect(" * c.captures[1] * ")")
            dyad = get(get(links, tag, Dict()), "Dyad", Dict())
            js = [(j["x"], j["y"]) for j in get(dyad, "junctions", [])]
            append!(junctions, [(tag, x, y) for (x, y) in js])
            point(i) = i < 0 ? js[-i] : get(ports, ends[i], nothing)
            for edge in get(dyad, "edges", [Dict("S" => 1, "E" => i, "M" => []) for i in 2:length(ends)])
                a, b = point(edge["S"]), point(edge["E"])
                if isnothing(a) || isnothing(b)
                    push!(unresolved, "wire $tag: " * join(ends[[i for i in (edge["S"], edge["E"]) if i > 0]], " -> "))
                    continue
                end
                push!(wires, (tag, [a; [(m["x"], m["y"]) for m in edge["M"]]; b]))
            end
        end
    end
    collect_connects(key)
    (; blocks, wires, junctions, unresolved)
end


const ELECTRIC_COMPONENTS = ("TheveninCell", "TestTheveninCell", "TheveninElectricDrive",
    "CCCVCharger", "CCCVLeafCharge", "CCCV800V", "SoCEstimator", "SoCCounter",
    "SoCDriftDays", "BleedCell", "PassiveBalancer", "BalancingString", "PackThermal",
    "ThermalTheveninCell", "ThermalCharge", "ThermalDerating", "RapidgateTwoCharges", "ThermalACvsDC")
const REQUESTED_FILES = Set(vcat([joinpath(@__DIR__, "..", "dyad", "Vehicle", "Electric", n * ".dyad") for n in ELECTRIC_COMPONENTS],
    [joinpath(@__DIR__, "..", "dyad", "Vehicle", "Planar", "PlanarBEVTheveninWLTC.dyad")]))
const ROOTS = sort!([k for (k, c) in definitions if c.local_source &&
    (any(normpath(c.file) == normpath(f) for f in REQUESTED_FILES) ||
     startswith(k, "VehicleSystemsComponents.Vehicle.Blocks."))])


# Equation blocks deliberately expose scalar signal connectors, not internal wiring.
is_equation_block(key) = startswith(key, "VehicleSystemsComponents.Vehicle.Blocks.")
function equation_block_issues(key)
    issues = String[]
    text = code_only(definitions[key].text)
    sections = split(text, r"(?m)^relations\s*$"; limit = 2)
    body = length(sections) == 2 ? first(split(sections[2], r"(?m)^metadata\s"; limit = 2)) : ""
    lines = filter(l -> !isempty(l) && l != "end", strip.(split(body, '\n')))
    length(lines) == 1 && occursin(r"^y\s*=\s*\S", first(lines)) ||
        push!(issues, "equation block must have exactly one y = expr relation")
    occursin(r"\b(?:variable|initial|guess|der|if|elseif|else|when|for|while|connect|extends)\b", text) &&
        push!(issues, "equation block must be stateless and contain no control-flow or wiring")
    icon = get(get(get(own_meta(key), "Dyad", Dict()), "icons", Dict()), "default", "")
    icon == "dyad://VehicleSystemsComponents/Vehicle/Blocks/Equation.svg" ||
        push!(issues, "equation block must use the shared y = f(u) icon")
    isfile(joinpath(@__DIR__, "..", "assets", "Vehicle", "Blocks", "Equation.svg")) ||
        push!(issues, "shared equation icon asset is missing")
    ds = declarations(key)
    inputs = sort!([n for (n, t) in ds if t == "RealInput"]; by = n -> tryparse(Int, replace(n, "u" => "")) === nothing ? typemax(Int) : parse(Int, n[2:end]))
    inputs == ["u" * string(i) for i in 1:length(inputs)] && !isempty(inputs) ||
        push!(issues, "equation block inputs must be contiguous u1, u2, ...")
    get(ds, "y", nothing) == "RealOutput" && length(ds) == length(inputs) + 1 ||
        push!(issues, "equation block must expose only RealInput u1... and RealOutput y")
    for raw in split(first(sections), '\n')
        occursin(r"\bparameter\b", raw) || continue
        occursin(r"^\s*parameter\s+\w+::[\w.]+\s*(?:=|$)", raw) ||
            push!(issues, "equation block parameters must be scalar: " * strip(raw))
    end
    issues
end

# Return findings rather than aborting at the first bad route or absent placement.
function audit(key)
    issues = is_equation_block(key) ? equation_block_issues(key) : String[]
    report(s) = push!(issues, "$key: $s")
    links, _ = merged_meta(key)
    used, expected = Set{String}(), Set{String}()
    kept = Set{String}()
    allowed = get(KEPT_RELATIONS, key, Set{String}())
    opens = get(OPEN_PORTS, key, Set{String}())
    for (name, (type, owner)) in members(key)
        box = placement(links, name, "diagram")
        isnothing(box) && is_connector(type, owner) && (box = placement(links, name, "icon"))
        isnothing(box) && report("missing diagram placement: $name")
        child = resolve_type(type, owner)
        if isnothing(child)
            is_connector(type, owner) || (report("unresolved member $name::$type"); continue)
            push!(expected, name)
        else
            child_links, _ = merged_meta(child)
            for (port, (ptype, powner)) in members(child)
                is_connector(ptype, powner) || continue
                push!(expected, "$name.$port")
                isnothing(placement(child_links, port, "icon")) &&
                    isnothing(placement(child_links, port, "diagram")) &&
                    report("no icon anchor for $name.$port")
            end
        end
        isnothing(box) && continue
        coords = isnothing(child) ? [(box[k*"1"] + box[k*"2"]) / 2 for k in ("x", "y")] :
            [box[k] for k in ("x1", "x2", "y1", "y2")]
        all(x -> 0 <= x <= 1000, coords) || report("placement outside frame: $name")
    end
    own_ports = sort!([name for (name, (type, owner)) in members(key) if is_connector(type, owner)])
    for kind in ("icon", "diagram"), (i, a) in enumerate(own_ports), b in own_ports[i+1:end]
        A, B = placement(links, a, kind), placement(links, b, kind)
        (isnothing(A) || isnothing(B)) && continue
        overlap = all(max(min(A[k*"1"], A[k*"2"]), min(B[k*"1"], B[k*"2"])) <=
            min(max(A[k*"1"], A[k*"2"]), max(B[k*"1"], B[k*"2"])) for k in ("x", "y"))
        overlap && report("overlapping $kind ports: $a and $b")
    end
    # Include inherited connections and equations; exemptions belong to their declaring type.
    function relations(k)
        for base in bases(k)
            parent = resolve_type(base, k)
            isnothing(parent) || relations(parent)
        end
        text = code_only(definitions[k].text)
        append!(issues, ["$key: conditional connect in $k:$line $raw" for (_, line, raw) in
            nested_connections(definitions[k].file, text)])
        relation_text = split(text, r"(?m)^relations\s*$"; limit = 2)
        if length(relation_text) == 2
            body = first(split(relation_text[2], r"(?m)^metadata\s"; limit = 2))
            found = Set{String}()
            for raw in split(body, '\n')
                line = strip(replace(raw, r"\s*\{\^\w+\}\s*$" => ""))
                occursin(r"(?<![<>=!])=(?!=)", line) || continue
                push!(found, line)
                if definitions[k].local_source
                    (is_equation_block(k) || line in get(KEPT_RELATIONS, k, Set{String}())) || report("unapproved relation in $k: $line")
                    # A retained constitutive/diagnostic equation can consume or define a port.
                    if is_equation_block(k) || line in get(KEPT_RELATIONS, k, Set{String}())
                        for token in eachmatch(r"\b\w+(?:\.\w+)*\b", line)
                            endpoint = String(token.match)
                            endpoint in expected && push!(used, endpoint)
                            root = first(split(endpoint, '.'))
                            root in expected && push!(used, root)
                        end
                    end
                end
            end
            k == key && union!(kept, found)
        end
        for c in eachmatch(r"\bconnect\s*\(([^)]*)\)(?:\s*\{\^(\w+)\})?", text)
            ends = strip.(split(c.captures[1], ','))
            tag = c.captures[2]
            for endpoint in ends
                occursin(r"^\w+(?:\.\w+)?$", endpoint) || report("not a direct-child endpoint: $endpoint")
                endpoint in expected || report("unplaced or unknown endpoint: $endpoint")
                push!(used, endpoint)
            end
            isnothing(tag) && (report("untagged connect: $(c.match)"); continue)
            dyad = get(get(links, tag, Dict()), "Dyad", Dict())
            edges = get(dyad, "edges", [])
            js = get(dyad, "junctions", [])
            vertices = Set(vcat(collect(1:length(ends)), collect(-length(js):-1)))
            adjacent = Dict(v => Set{Int}() for v in vertices)
            for edge in edges
                a, b = edge["S"], edge["E"]
                if !(a in vertices && b in vertices) || a == b
                    report("invalid edge in $tag: $a -> $b")
                    continue
                end
                push!(adjacent[a], b); push!(adjacent[b], a)
            end
            reached, pending = Set{Int}(), [1]
            while !isempty(pending)
                v = pop!(pending)
                v in reached && continue
                push!(reached, v)
                append!(pending, collect(get(adjacent, v, Set{Int}())))
            end
            reached == vertices || report("missing/disconnected edge routing: $tag")
            for j in -length(js):-1
                length(adjacent[j]) >= 2 || report("dangling junction $j in $tag")
            end
        end
    end
    relations(key)
    for endpoint in setdiff(expected, used, opens)
        is_equation_block(key) && continue
        report("unconnected port (wire or explicitly OPEN_PORTS): $endpoint")
    end
    for endpoint in opens
        parts = split(endpoint, '.')
        if length(parts) == 1 && haskey(members(key), endpoint)
            type = members(key)[endpoint][1]
        elseif length(parts) == 2 && haskey(members(key), parts[1])
            type, owner = members(key)[parts[1]]
            child = resolve_type(type, owner)
            type = isnothing(child) ? "" : get(members(child), parts[2], ("", ""))[1]
        else
            type = ""
        end
        type in ("RealInput", "IntegerInput", "BooleanInput", "ClockInput") &&
            report("OPEN_PORTS cannot hide an undriven input: $endpoint")
    end
    for endpoint in setdiff(opens, setdiff(expected, used))
        report("stale OPEN_PORTS allowance: $endpoint")
    end
    for line in setdiff(allowed, kept)
        report("stale KEPT_RELATIONS allowance: $line")
    end
    # Avoid indexing bad edge endpoints a second time in the geometry pass.
    if !any(s -> occursin("invalid edge", s), issues)
        view = canvas(key)
        foreach(u -> report("unresolved geometry: $u"), view.unresolved)
        for (tag, path) in view.wires
            for (x, y) in path
                0 <= x <= 1000 && 0 <= y <= 1000 || report("wire outside frame: $tag ($x, $y)")
            end
            for (p, q) in zip(path, path[2:end])
                abs(p[1] - q[1]) > 0.5 && abs(p[2] - q[2]) > 0.5 && report("diagonal (missing bend): $tag $p -> $q")
            end
        end
        for (tag, x, y) in view.junctions
            0 <= x <= 1000 && 0 <= y <= 1000 || report("junction outside frame: $tag ($x, $y)")
        end
        names = sort!(collect(keys(view.blocks)))
        for (i, a) in enumerate(names), b in names[i+1:end]
            A, B = view.blocks[a], view.blocks[b]
            A[1] < B[3] && B[1] < A[3] && A[2] < B[4] && B[2] < A[4] && report("parts/40-unit labels overlap: $a and $b")
        end
    end
    issues
end
end # module ExtraCanvasAudit

@testset "Extra pack canvas" begin
    audit = ExtraCanvasAudit
    @test length(audit.ROOTS) >= 19 # Eighteen requested electric types and Planar (plus fixtures/Blocks).
    @test all("VehicleSystemsComponents.Vehicle.Electric." * n in audit.ROOTS for n in audit.ELECTRIC_COMPONENTS)
    @test "VehicleSystemsComponents.Vehicle.Planar.PlanarBEVTheveninWLTC" in audit.ROOTS
    @test all(haskey(audit.definitions, key) for key in audit.ROOTS)
    @test all(key in audit.ROOTS for key in keys(audit.KEPT_RELATIONS))
    @test all(key in audit.ROOTS for key in keys(audit.OPEN_PORTS))
    for key in audit.ROOTS
        @testset "$key" begin
            findings = audit.audit(key)
            isempty(findings) || @error "Extra pack canvas audit" findings
            @test isempty(findings)
        end
    end
end
