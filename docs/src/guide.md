```@meta
CurrentModule = PlutoShowHelpers
```

# [How-to Guide](@id guide)

Recipes for common display tasks. Each section is self-contained — jump to the one that
matches your problem. For the model behind these recipes, see [How It Works](@ref concepts);
for exact signatures and defaults, see the [API Reference](@ref).

!!! note
    `show_namedtuple` and the other interface functions are **not exported**. Extend them
    as `PlutoShowHelpers.show_namedtuple(...)`.

## Give your type customized show methods

Apply [`@default_show_overload`](@ref) to the type:

```@example guide
using PlutoShowHelpers

struct Orbit
    semi_major_axis::Float64
    eccentricity::Float64
    inclination::Float64
    raan::Float64
    arg_periapsis::Float64
    true_anomaly::Float64
end

@default_show_overload Orbit
nothing # hide
```

This is equivalent to defining:

```julia
Base.show(io::IO, x::Orbit) = show(io, DefaultShowOverload(x))
Base.show(io::IO, mime::MIME"text/html", x::Orbit) = show(io, mime, DefaultShowOverload(x))
Base.show(io::IO, mime::MIME"text/plain", x::Orbit) = show(io, mime, DefaultShowOverload(x))
```

Without further customization, all fields are shown using their original names:

```@example guide
orb = Orbit(7000.0, 0.001, 0.9, 1.2, 0.5, 0.0)
```

To cover several types at once, pass a `Union`:

```julia
@default_show_overload Union{Engine, Spacecraft}
```

## Choose which fields appear, and rename them

Add a method to [`show_namedtuple`](@ref PlutoShowHelpers.show_namedtuple) returning a
`NamedTuple`. The keys become the displayed labels, the values the displayed content:

```@example guide
PlutoShowHelpers.show_namedtuple(o::Orbit) = (;
    sma = o.semi_major_axis,
    ecc = HideWhenCompact(o.eccentricity),
    inc = o.inclination,
    Ω = HideWhenCompact(o.raan),
    ω = HideWhenCompact(o.arg_periapsis),
    ν = HideWhenCompact(o.true_anomaly),
)
nothing # hide
```

The 3-arg (expanded) show now uses the custom field names:

```@repl guide
orb
```

and the 2-arg (compact) show drops the fields wrapped in `HideWhenCompact`:

```@repl guide
repr(orb)
```

## Hide a field in some contexts

Wrap the value in one of three markers:

| Wrapper | 2-arg (compact) | 3-arg (expanded) | Pluto collapsed | Pluto expanded |
|---------|:---:|:---:|:---:|:---:|
| [`HideWhenCompact`](@ref) | hidden | shown | hidden | shown |
| [`HideWhenFull`](@ref) | shown | hidden | shown | hidden |
| [`HideAlways`](@ref) | hidden | hidden | hidden | hidden |

```@example visibility
using PlutoShowHelpers

struct SensorReading
    value::Float64
    unit::String
    timestamp::Float64
    raw_bytes::Vector{UInt8}
end

@default_show_overload SensorReading

PlutoShowHelpers.show_namedtuple(s::SensorReading) = (;
    value = s.value,
    unit = s.unit,
    timestamp = HideWhenCompact(s.timestamp),
    raw = HideAlways(s.raw_bytes),
)
nothing # hide
```

```@repl visibility
reading = SensorReading(23.5, "°C", 1720000000.0, UInt8[0x01, 0x02])
repr(reading)
```

The `raw` field never appears, and `timestamp` only shows in the expanded view.

## Hide a field's label

Use Julia's gensym key syntax (`var"#name"`) in the returned `NamedTuple`. The value is
still shown, but without the `name = ` prefix:

```@example gensym
using PlutoShowHelpers

struct Point
    x::Float64
    y::Float64
end

@default_show_overload Point

PlutoShowHelpers.show_namedtuple(p::Point) = (;
    var"#x" = p.x,
    var"#y" = p.y,
)

PlutoShowHelpers.shortname(::Point) = "Point"
nothing # hide
```

```@repl gensym
Point(1.0, 2.0)
repr(Point(1.0, 2.0))
```

Each key must still be unique, so number them (`var"#1"`, `var"#2"`, …) when suppressing
several labels in a row.

## Customize the displayed type name

Three functions control the name, each used in a different context:

| Function | Used in | Default |
|----------|---------|---------|
| [`shortname`](@ref PlutoShowHelpers.shortname) | 2-arg show: `ShortName(...)` | `nameof(typeof(x))` |
| [`longname`](@ref PlutoShowHelpers.longname) | Pluto tree header | `nameof(typeof(x))` |
| [`repl_summary`](@ref PlutoShowHelpers.repl_summary) | 3-arg show header: `Summary:` | `Base.summary(x)` |

```@example names
using PlutoShowHelpers

struct MyLongTypeName
    x::Int
end

@default_show_overload MyLongTypeName

PlutoShowHelpers.shortname(::MyLongTypeName) = "MLT"
PlutoShowHelpers.repl_summary(t::MyLongTypeName) = "MyLongTypeName(x=$(t.x))"
nothing # hide
```

```@repl names
t = MyLongTypeName(42)
repr(t)
```

## [Indicate truncated content](@id ellipsis-guide)

Use [`Ellipsis`](@ref PlutoShowHelpers.Ellipsis) in place of the omitted values. It renders
as horizontal dots (`…`) in compact contexts and vertical dots (`⋮`) in expanded ones. Pair
it with a gensym key so it appears without a label:

```@example ellipsis
using PlutoShowHelpers

struct LargeCollection
    items::Vector{Int}
end

@default_show_overload LargeCollection

function PlutoShowHelpers.show_namedtuple(c::LargeCollection)
    n = length(c.items)
    if n <= 3
        return (; (Symbol("#$i") => c.items[i] for i in 1:n)...)
    end
    return (;
        var"#1" = c.items[1],
        var"#2" = c.items[2],
        var"#dots" = Ellipsis(),
        var"#last" = c.items[end],
    )
end

PlutoShowHelpers.shortname(::LargeCollection) = "LargeCollection"
nothing # hide
```

```@repl ellipsis
LargeCollection([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
repr(LargeCollection([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]))
```

## Show different fields in Pluto and the REPL

`show_namedtuple` accepts a second argument for context dispatch:

```julia
PlutoShowHelpers.show_namedtuple(o::Orbit, ::InsidePluto) = ...   # Pluto tree view
PlutoShowHelpers.show_namedtuple(o::Orbit, ::OutsidePluto) = ...  # REPL / non-Pluto
```

Both default to calling the 1-arg version, so define these only when the two
representations should genuinely differ. A typical case is a large array: worth browsing in
the Pluto tree, worth collapsing to a size description in the REPL.

```@example pluto_repl
using PlutoShowHelpers

struct SimulationResult
    timesteps::Int
    converged::Bool
    final_error::Float64
    history::Vector{Float64}
end

@default_show_overload SimulationResult

# REPL: hide the potentially large history vector
function PlutoShowHelpers.show_namedtuple(r::SimulationResult, ::OutsidePluto)
    (;
        timesteps = r.timesteps,
        converged = r.converged,
        final_error = r.final_error,
        history = HideAlways("$(length(r.history)) entries"),
    )
end

# Pluto: show everything, history is navigable in the tree
PlutoShowHelpers.show_namedtuple(r::SimulationResult, ::InsidePluto) = (;
    timesteps = r.timesteps,
    converged = r.converged,
    final_error = r.final_error,
    history = r.history,
)

PlutoShowHelpers.shortname(::SimulationResult) = "SimResult"
PlutoShowHelpers.repl_summary(r::SimulationResult) = "SimulationResult ($(r.timesteps) steps)"
nothing # hide
```

```@repl pluto_repl
SimulationResult(100, true, 1e-8, rand(100))
```

In Pluto, the full `history` vector is browsable in the interactive tree.

## Pretty-print a nested custom type

Wrap the nested value in [`DefaultShowOverload`](@ref) inside `show_namedtuple`. This gets
recursive pretty-printing without committing type piracy:

```@example nested
using PlutoShowHelpers

struct Engine
    thrust_kN::Float64
    isp_s::Float64
    propellant::Symbol
end

struct Spacecraft
    name::String
    mass_kg::Float64
    engine::Engine
end

@default_show_overload Union{Engine, Spacecraft}

PlutoShowHelpers.show_namedtuple(e::Engine) = (;
    thrust = e.thrust_kN,
    isp = e.isp_s,
    propellant = HideWhenCompact(e.propellant),
)
PlutoShowHelpers.shortname(::Engine) = "Engine"

function PlutoShowHelpers.show_namedtuple(sc::Spacecraft)
    (;
        name = sc.name,
        mass = sc.mass_kg,
        engine = DefaultShowOverload(sc.engine), # nested pretty-printing
    )
end
PlutoShowHelpers.shortname(::Spacecraft) = "SC"
PlutoShowHelpers.repl_summary(sc::Spacecraft) = "Spacecraft($(sc.name))"
nothing # hide
```

```@repl nested
sc = Spacecraft("Explorer", 1200.0, Engine(4.5, 320.0, :hydrazine))
show(stdout, sc)
```

The `Engine` inside `Spacecraft` renders with its own `shortname` and hiding rules. Without
the wrapper, it would show as a raw struct.

## Hide fields that are empty

`show_namedtuple` runs per instance, so apply `HideAlways` conditionally:

```@example conditional
using PlutoShowHelpers

struct Pipeline
    name::String
    steps::Vector{Symbol}
    errors::Vector{String}
    metadata::Dict{String,Any}
end

@default_show_overload Pipeline

function PlutoShowHelpers.show_namedtuple(p::Pipeline, ::OutsidePluto)
    errors = isempty(p.errors) ? HideAlways(p.errors) : p.errors
    metadata = isempty(p.metadata) ? HideAlways(p.metadata) : p.metadata
    (;
        name = p.name,
        steps = p.steps,
        errors,
        metadata,
    )
end
PlutoShowHelpers.shortname(::Pipeline) = "Pipeline"
nothing # hide
```

```@repl conditional
Pipeline("build", [:compile, :link], String[], Dict())
Pipeline("build", [:compile, :link], ["link failed"], Dict("retry" => 3))
```

Empty `errors` and `metadata` are fully hidden; non-empty ones appear.

## Show a computed summary instead of fields in compact view

Put the summary behind `HideWhenFull` and the real fields behind `HideWhenCompact`, so the
two never appear together:

```@example aliases
using PlutoShowHelpers

struct GeoCoordinate
    lat::Float64
    lon::Float64
    alt::Float64
end

@default_show_overload GeoCoordinate

function PlutoShowHelpers.show_namedtuple(g::GeoCoordinate, ::OutsidePluto)
    compact = HideWhenFull("$(round(g.lat; digits=1))°, $(round(g.lon; digits=1))°")
    (;
        var"#summary" = compact,
        lat = HideWhenCompact(g.lat),
        lon = HideWhenCompact(g.lon),
        alt = HideWhenCompact(g.alt),
    )
end
PlutoShowHelpers.shortname(::GeoCoordinate) = "Geo"
PlutoShowHelpers.repl_summary(::GeoCoordinate) = "GeoCoordinate"
nothing # hide
```

```@repl aliases
coord = GeoCoordinate(48.8566, 2.3522, 35.0)
show(stdout, coord)
```

The compact form shows just `Geo(48.9°, 2.4°)`, the expanded form all three labelled fields.

## Replace a field that does not render usefully

Function-valued fields and large internal buffers are best swapped for a descriptive value
or an [`Ellipsis`](@ref PlutoShowHelpers.Ellipsis):

```@example replace
using PlutoShowHelpers

struct Interpolator
    nodes::Vector{Float64}
    values::Vector{Float64}
    interp_func::Function
end

@default_show_overload Interpolator

function PlutoShowHelpers.show_namedtuple(interp::Interpolator)
    (;
        nodes = length(interp.nodes),
        range = (first(interp.nodes), last(interp.nodes)),
        interp_func = Ellipsis(), # function can't be displayed usefully
    )
end
PlutoShowHelpers.shortname(::Interpolator) = "Interpolator"
nothing # hide
```

```@repl replace
Interpolator([0.0, 1.0, 2.0, 3.0], [0.0, 1.0, 4.0, 9.0], x -> x^2)
```

## [Print field labels in compact show](@id howto-context)

By default the 2-arg show omits labels: `MyType(val1, val2, ...)`. To opt specific fields
into label printing, set `:print_2arg_names` in `CONTEXT` from within `show_namedtuple`:

```@example context
using PlutoShowHelpers
using PlutoShowHelpers: CONTEXT

struct Config
    backend::Symbol
    threads::Int
    verbose::Bool
end

@default_show_overload Config

function PlutoShowHelpers.show_namedtuple(c::Config, ::OutsidePluto)
    CONTEXT[][:print_2arg_names] = (:backend,)
    return (;
        backend = c.backend,
        threads = c.threads,
        verbose = HideWhenCompact(c.verbose),
    )
end

PlutoShowHelpers.shortname(::Config) = "Config"
nothing # hide
```

```@repl context
Config(:gpu, 8, false)
repr(Config(:gpu, 8, false))
```

The `backend` field keeps its label in the compact form while `threads` does not.

!!! warning "Experimental API"
    The `CONTEXT` mechanism is experimental and may change in future versions. See
    [CONTEXT](@ref concepts) for what it is and why it exists.

## Keep the Pluto tree but hand-write the other HTML

Wrap the object in [`AsPlutoTree`](@ref) on the Pluto branch:

```julia
function Base.show(io::IO, mime::MIME"text/html", x::MyType)
    if is_inside_pluto(io)
        show(io, mime, AsPlutoTree(x))
    else
        # Custom non-Pluto HTML rendering
    end
end
```

`AsPlutoTree` also accepts `class` and `style` keyword arguments for CSS customization of
the tree container.

If you do not need a hand-written non-Pluto branch, subtype [`CustomShowable`](@ref)
instead — the `text/html` show then routes to
[`show_inside_pluto`](@ref PlutoShowHelpers.show_inside_pluto) or
[`show_outside_pluto`](@ref PlutoShowHelpers.show_outside_pluto) automatically.

## Render these types in your own documentation

See [Use These Types in Documenter](@ref documenter).
