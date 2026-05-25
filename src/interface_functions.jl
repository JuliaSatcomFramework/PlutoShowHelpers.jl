# Show methods overloadables
"""
    show_inside_pluto(io::IO, x)
This function is used inside the show method for subtypes of
[`CustomShowable`](@ref), like [`DefaultShowOverload`](@ref) and
[`AsPlutoTree`](@ref), for MIME of type `text/html` only if the passed `io` is
inside Pluto.

This function defaults to calling [`show_outside_pluto`](@ref) if not overloaded for the specific type of `x`.
"""
function show_inside_pluto(io::IO, x)
    @nospecialize
    show_outside_pluto(io, x)
end

"""
    show_outside_pluto(io::IO, x)
This function is used inside the show method for subtypes of
[`CustomShowable`](@ref), like [`DefaultShowOverload`](@ref) and
[`AsPlutoTree`](@ref), for MIME of type `text/html` only if the passed `io` is
outside Pluto.

This function defaults to calling [`show`](@ref) with MIME of type `text/plain` if not overloaded for the specific type of `x`.
"""
function show_outside_pluto(io::IO, x)
    @nospecialize
    @warn "show_outside_pluto is not overloaded for $(typeof(x)), defaulting to output of show(io, x)"
    show(io, x)
end

# Customize shown names of type
longname(@nospecialize(x)) = longname(typeof(x))
longname(x::DataType) = nameof(x) |> string
shortname(@nospecialize(x)) = shortname(typeof(x))
shortname(x::DataType) = nameof(x) |> string

# This needs to be overloaded if one wants custom multiline type name in the REPL
repl_summary(@nospecialize(x)) = Base.summary(x)

"""
    show_namedtuple(x)
    show_namedtuple(x, ::InsidePluto) = show_namedtuple(x)
    show_namedtuple(x, ::OutsidePluto) = show_namedtuple(x)
This function takes an instance of a type and generate the corresponding
NamedTuple specifying the fields to show and how the content of each field
should eventually be processed.

Adding one (or more) method(s) to this function for a specific type is required for customizing
how objects are shown via the convenience show methods of this package (i.e. see
[`AsPlutoTree`](@ref) and [`DefaultShowOverload`](@ref)).

The 2-arg versions can be used to have a different specialized method for showing an object
when called outside or inside of Pluto. They both default to simply calling the 1-arg version.

By default, the 1-arg version just translates the provided object into a
NamedTuple using `getfields` from ConstructionBase.jl.
"""
show_namedtuple(@nospecialize(x)) = getfields(x)
show_namedtuple(@nospecialize(x), ::InsidePluto) = show_namedtuple(x)
show_namedtuple(@nospecialize(x), ::OutsidePluto) = show_namedtuple(x)

"""
    with_iocontext(f, io::IO, ps::Pair{Symbol}...)

Execute `f(nio)` where `nio` is an [`IOContext`](@ref) derived from `io` with the
additional key-value pairs `ps`. For the duration of `f`, the new context is also
stored in the package-scoped [`CURRENT_IO`](@ref) `ScopedValue`, making the same
keys accessible via [`get_from_iocontext`](@ref) from *any* code called inside `f`
— including functions that do not receive an IO argument (e.g. [`shortname`](@ref),
[`longname`](@ref)).

# Example

```julia
with_iocontext(io, :my_flag => true) do nio
    # get(nio, :my_flag, false)          === true
    # get_from_iocontext(:my_flag, false) === true  (no `io` needed)
    show(nio, x)
end
```
"""
function with_iocontext(f, io::IO, ps::Pair{Symbol}...)
    nio = IOContext(io, ps...)
    ScopedValues.with(CURRENT_IO => nio) do
        f(nio)
    end
end

"""
    get_from_iocontext(key, default; nothrow = true)

Retrieve the value associated with `key` from the package-scoped IO context
(populated by [`with_iocontext`](@ref)), or `default` when the key is absent or
no context is active.

This is the counterpart to `get(io, key, default)` for code that has **no direct
access to the IO argument** — for instance inside [`shortname`](@ref) or
[`longname`](@ref) overloads. The context is stored in the `ScopedValue`
[`CURRENT_IO`](@ref) and is only populated while execution is inside a
[`with_iocontext`](@ref) block.

## Arguments
- `key::Symbol` – key to look up in the active IO context.
- `default` – value returned when `key` is absent or no context is active.
- `nothrow::Bool` (keyword, default `true`) – when `false`, an `ArgumentError` is
  thrown instead of returning `default` if no IO context has been set.

# Example

```julia
# Adapt the display name depending on the show context:
function PlutoShowHelpers.shortname(::MyType)
    mime = get_from_iocontext(:input_mime, missing)
    mime === missing    && return "MyType"          # called outside show
    mime === nothing    && return "MT"              # inside 2-arg show (compact)
    mime isa MIME"text/html" && return "<b>MyType</b>"  # inside HTML show
    return "MyType"
end
```
"""
function get_from_iocontext(key, default; nothrow = true)
    if !isassigned(CURRENT_IO)
        nothrow && return default
        throw(ArgumentError(
            "No current IO context is set; this function is only valid inside a `with_iocontext` block."))
    end
    get(CURRENT_IO[], key, default)
end