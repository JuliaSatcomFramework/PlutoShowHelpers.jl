# PlutoShowHelpers

[![Stable Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaSatcomFramework.github.io/PlutoShowHelpers.jl/stable)
[![In development documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaSatcomFramework.github.io/PlutoShowHelpers.jl/dev)
[![Test workflow status](https://github.com/JuliaSatcomFramework/PlutoShowHelpers.jl/actions/workflows/Test.yml/badge.svg?branch=main)](https://github.com/JuliaSatcomFramework/PlutoShowHelpers.jl/actions/workflows/Test.yml?query=branch%3Amain)
[![Docs workflow Status](https://github.com/JuliaSatcomFramework/PlutoShowHelpers.jl/actions/workflows/Docs.yml/badge.svg?branch=main)](https://github.com/JuliaSatcomFramework/PlutoShowHelpers.jl/actions/workflows/Docs.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/JuliaSatcomFramework/PlutoShowHelpers.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaSatcomFramework/PlutoShowHelpers.jl)

A framework for customizing `show` methods on Julia types so they render well across different contexts:

- **REPL** — compact single-line (`show(io, x)`) and expanded multi-line (`show(io, MIME"text/plain"(), x)`) representations
- **Pluto notebooks** — interactive collapsible tree structures with per-field visibility control
- **Other HTML environments** — via `show_outside_pluto` fallback

Define a single [`show_namedtuple`](https://JuliaSatcomFramework.github.io/PlutoShowHelpers.jl/stable/guide/) method to control which fields are shown and how they are transformed, and the package handles rendering in each context automatically.

## Quick Example

```julia
using PlutoShowHelpers

struct Satellite
    name::String
    altitude_km::Float64
    inclination_deg::Float64
    active::Bool
end

@default_show_overload Satellite

PlutoShowHelpers.show_namedtuple(s::Satellite) = (;
    name = s.name,
    altitude = s.altitude_km,
    inclination = s.inclination_deg,
    active = HideWhenCompact(s.active),  # hidden in compact view
)

PlutoShowHelpers.shortname(::Satellite) = "Sat"
PlutoShowHelpers.repl_summary(s::Satellite) = "Satellite($(s.name))"
```

```
julia> Satellite("ISS", 408.0, 51.6, true)
Satellite(ISS):
  name = "ISS"
  altitude = 408.0
  inclination = 51.6
  active = true

julia> show(stdout, Satellite("ISS", 408.0, 51.6, true))
Sat("ISS", 408.0, 51.6)
```

See the [documentation](https://JuliaSatcomFramework.github.io/PlutoShowHelpers.jl/stable/) for the full guide, including field visibility control, name customization, nested types, and Pluto-specific rendering.
