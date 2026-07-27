```@meta
CurrentModule = PlutoShowHelpers
```

# [Guide](@id guide)

## How Show Dispatch Works

Julia's `show` system has multiple methods that fire in different contexts:

| Method | When it fires |
|--------|--------------|
| `show(io, x)` | 2-arg: string interpolation, `repr(x)`, compact contexts |
| `show(io, MIME"text/plain"(), x)` | 3-arg: REPL display, multi-line output |
| `show(io, MIME"text/html"(), x)` | HTML rendering (Pluto, Jupyter, docs) |

PlutoShowHelpers hooks into `text/html` to detect whether the output is going to Pluto, and provides separate rendering paths for each context. The [`DefaultShowOverload`](@ref) type handles all three `show` methods with a single customization point.

## DefaultShowOverload

[`DefaultShowOverload`](@ref) is the main entry point. Wrap your type in it and you get
customizable show methods for all three contexts.

The easiest way to set this up is the [`@default_show_overload`](@ref) macro:

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

# Orbit is defined here rather than in a loaded package, so it is registered after the
# disable_html_show! call in make.jl. See "Using These Types in Documenter" below.
PlutoShowHelpers.disable_html_show!()
nothing # hide
```

This is equivalent to defining:
```julia
Base.show(io::IO, x::Orbit) = show(io, DefaultShowOverload(x))
Base.show(io::IO, mime::MIME"text/html", x::Orbit) = show(io, mime, DefaultShowOverload(x))
Base.show(io::IO, mime::MIME"text/plain", x::Orbit) = show(io, mime, DefaultShowOverload(x))
```

Without any further customization, all fields are shown using their original names:

```@example guide
orb = Orbit(7000.0, 0.001, 0.9, 1.2, 0.5, 0.0)
```

## Customizing Fields with `show_namedtuple`

[`show_namedtuple`](@ref) is the primary customization point. It takes an instance of
your type and returns a `NamedTuple` specifying which fields to show and how to
transform them.

!!! note
    `show_namedtuple` and other interface functions are **not exported**. Extend them
    as `PlutoShowHelpers.show_namedtuple(...)`.

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

Now the 3-arg (expanded) show uses the custom field names:

```@repl guide
orb
```

And the 2-arg (compact) show hides fields wrapped in `HideWhenCompact`:

```@repl guide
repr(orb)
```

### Different Fields for Pluto vs. REPL

`show_namedtuple` accepts a second argument to specialize for different contexts:

```julia
PlutoShowHelpers.show_namedtuple(o::Orbit, ::InsidePluto) = ...   # Pluto tree view
PlutoShowHelpers.show_namedtuple(o::Orbit, ::OutsidePluto) = ...  # REPL / non-Pluto
```

Both default to calling the 1-arg version, so you only need the 2-arg form when the
Pluto and REPL representations should differ.

## Field Visibility

Three wrapper types control when fields appear:

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

## Name Customization

Three functions control how your type's name appears:

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

## Hiding Field Labels

Use Julia's gensym syntax (`var"#name"`) in the `NamedTuple` returned by
`show_namedtuple` to suppress a field's label. The value is still shown, but
without the `name = ` prefix. This is especially useful in combination with
[`Ellipsis`](@ref PlutoShowHelpers.Ellipsis) to show truncated content without
a distracting label (see the [Ellipsis section](@ref ellipsis-guide) below).

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

## AsPlutoTree

[`AsPlutoTree`](@ref) wraps any object to render it as Pluto's native interactive tree widget.
It is useful when you want a custom `text/html` show for non-Pluto contexts but still want
the tree view inside Pluto:

```julia
function Base.show(io::IO, mime::MIME"text/html", x::MyType)
    if is_inside_pluto(io)
        show(io, mime, AsPlutoTree(x))
    else
        # Custom non-Pluto HTML rendering
    end
end
```

Alternatively, making your type a subtype of [`CustomShowable`](@ref) achieves the
same routing automatically — the `text/html` show dispatches to
[`show_inside_pluto`](@ref PlutoShowHelpers.show_inside_pluto) or
[`show_outside_pluto`](@ref PlutoShowHelpers.show_outside_pluto) based on the IO context.

`AsPlutoTree` also accepts optional `class` and `style` keyword arguments for
CSS customization of the tree container.

## [Ellipsis](@id ellipsis-guide)

[`Ellipsis`](@ref PlutoShowHelpers.Ellipsis) is a display element that renders as horizontal dots (`…`) in compact
contexts and vertical dots (`⋮`) in expanded contexts. Wrap it in a gensym field to
indicate truncated content:

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

## CONTEXT (Experimental)

!!! warning "Experimental API"
    The `CONTEXT` mechanism is experimental and may change in future versions.

`CONTEXT` is a package-scoped `ScopedValue` holding a `Dict{Any,Any}` that is set
during show calls. It allows `show_namedtuple` to communicate with downstream
rendering (e.g., the `shortname` function or nested show methods).

### Showing Labels in 2-arg Show

By default, the 2-arg (compact) show omits field labels: `MyType(val1, val2, ...)`.
To opt specific fields into label printing, set `:print_2arg_names` in CONTEXT
from within `show_namedtuple`:

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

## Using These Types in Documenter

Documenter's `@example` blocks display a result using the richest MIME type the value
supports, and ask `Base.showable` which those are. Because `@default_show_overload` and
[`CustomShowable`](@ref) both define a `text/html` method, `@example` blocks pick HTML —
which outside Pluto falls back to
[`show_outside_pluto`](@ref PlutoShowHelpers.show_outside_pluto) and is rarely what you
want in a manual.

Call [`disable_html_show!`](@ref PlutoShowHelpers.disable_html_show!) once per build to
make those blocks use the REPL (`text/plain`) rendering instead. Either from `make.jl`,
before `makedocs`:

```julia
using MyPackage
using PlutoShowHelpers

PlutoShowHelpers.disable_html_show!()
```

or from a `@setup` block in a page:

````markdown
```@setup tutorial
using PlutoShowHelpers
PlutoShowHelpers.disable_html_show!()
```
````

It picks up every type registered by [`@default_show_overload`](@ref) and every subtype of
[`CustomShowable`](@ref). Pass types whose `text/html` show you wrote by hand as positional
arguments, and types that should keep rendering as HTML via `exclude`:

```julia
PlutoShowHelpers.disable_html_show!(MyHandWrittenType; exclude = (MyPlotType,))
```

`@repl` blocks never consult `showable`, so they are already text-only and need none of
this. The call also leaves `show(io, MIME"text/html"(), x)` and Pluto rendering untouched —
it changes only which MIME Documenter asks for.

!!! note "Call it after your types are defined"
    `disable_html_show!` only gives a method to types that exist when it runs. Calling it
    in `make.jl` after `using MyPackage` covers everything that package defines. A type
    registered later — such as one defined with [`@default_show_overload`](@ref) inside an
    `@example` block, as on this page — needs another call after its definition. Subtypes
    of [`CustomShowable`](@ref) are exempt, because their method is installed on the
    abstract type and so covers subtypes defined at any point.

This documentation is built with the call in place, so the `@example` blocks throughout
this guide show the same output you would get in the REPL.

## Advanced Patterns

### Nested Types

When a type contains fields that are themselves custom types, wrap them in
[`DefaultShowOverload`](@ref) inside `show_namedtuple` to get recursive
pretty-printing without type piracy:

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

The `Engine` inside `Spacecraft` renders with its own `shortname` and hiding
rules. Without the `DefaultShowOverload` wrapper, it would show as a raw struct.

### Conditional Field Hiding

Use `HideAlways` dynamically to suppress fields that are empty or at their
default values, keeping the output clean:

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

### Compact Aliases with HideWhenFull

A common pattern is to show a short computed summary in compact view and the
full struct fields in expanded view. Use `HideWhenFull` for the compact alias
and `HideWhenCompact` for the full fields:

```@example aliases
using PlutoShowHelpers

struct GeoCoordinate
    lat::Float64
    lon::Float64
    alt::Float64
end

@default_show_overload GeoCoordinate

function PlutoShowHelpers.show_namedtuple(g::GeoCoordinate, ::OutsidePluto)
    # Compact alias: shown only in 2-arg show, hidden in expanded view
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

The compact form shows just `Geo(48.9°, 2.4°)` while the expanded form shows
all three fields with their labels.

### Replacing Non-Displayable Fields

Function-valued fields or large internal buffers don't render well. Replace them
with [`Ellipsis`](@ref PlutoShowHelpers.Ellipsis) or a descriptive string:

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

### Different Representations for Pluto and REPL

Use the `InsidePluto` / `OutsidePluto` dispatch to show different fields in
each context. A typical use is showing a compact summary in the REPL while
providing all fields in the Pluto tree:

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

In Pluto, the full `history` vector would be browsable in the interactive tree.
In the REPL, it's replaced with a compact size description.
