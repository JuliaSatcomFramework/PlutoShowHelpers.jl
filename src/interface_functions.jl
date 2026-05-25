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

function with_iocontext(f, io, ps::Pair{Symbol}...)
    # Create the new IO context
    nio = IOContext(io, ps...)
    # Execute the provided function with the new IO context as only argument
    f(nio)
end

function get_from_iocontext(key, default; nothrow = true)
    isassigned(CURRENT_IO) || nothrow ? (return default) : throw(ArgumentError("No current IO context is not set, this function should only be called from show methods coming from PlutoShowHelpers."))
    get(CURRENT_IO[], key, default)
end