"""
    abstract type CustomShowable end
This is the base abstract type which overloads the MIME"text/html" show method
to dispatch to either [`show_inside_pluto`](@ref) or
[`show_outside_pluto`](@ref) depending on whether the IO being rendered on is
inside or outside of Pluto.

The show method for `CustomShowable` is defined as follows:
```julia
function Base.show(io::IO, mime::MIME"text/html", x::CustomShowable)
    @nospecialize
    if is_inside_pluto(io) # Coming from AbstractPlutoDingetjes but also re-exported by this package
        show_inside_pluto(io, x) # Function defined in this package and to eventually be extended for custom types
    else
        show_outside_pluto(io, x) # Function defined in this package and to eventually be extended for custom types
    end
end
```
"""
abstract type CustomShowable end

struct InsidePluto end
struct OutsidePluto end

function Base.show(io::IO, mime::MIME"text/html", x::CustomShowable)
    @nospecialize
    if is_inside_pluto(io)
        show_inside_pluto(io, x)
    else
        show_outside_pluto(io, x)
    end
end

# This is used to hide some fields either in compact view, full view or always. These will default to simply forwarding show methods and are only parsed within the show methods of AsPlutoTree and DefaultShowOverload for assessing when to hide
abstract type AbstractHidden <: CustomShowable end

struct HideWhenCompact <: AbstractHidden
    item
end
struct HideWhenFull <: AbstractHidden
    item
end
struct HideAlways <: AbstractHidden
    item
end


""" 
    struct AsPlutoTree <: CustomShowable
This struct is used to wrap objects within their own show HTML method so that
they are displayed using the standard tree-like structure used by Pluto to
display structs.

It is mostly useful when requiring  custom HTML method that is relevant outside
of Pluto but one wants their structure to keeps showing as a tree structure
inside Pluto.

This can be done by loading  defining the following custom show method for one's own type `MyType`:
```julia
function Base.show(io::IO, mime::MIME"text/html", x::MyType) 
    if is_inside_pluto(io) # This is coming from AbstractPlutoDingetjes but is also re-exported by this package
        show(io, mime, AsPlutoTree(x))
    else
        # Custom non-Pluto code
    end
end
```

Alternatively, one can make `MyType` a subtype of `CustomShowable` which
automatically defines the `show` method as above (see the docstring of
[`CustomShowable`](@ref)).
"""
struct AsPlutoTree <: CustomShowable
    element
    class::Union{Nothing, String}
    style::Union{Nothing, String}
end
AsPlutoTree(element; class = nothing, style = nothing) = AsPlutoTree(element, class, style)

# This basicaly replicates the show method for EmbedDisplay in Pluto
function show_inside_pluto(io::IO, wrapped::AsPlutoTree)
    item = unwrap(wrapped)
    nt = show_namedtuple(item, InsidePluto())::NamedTuple
    class = @something wrapped.class random_class()
    # This is the style that will eventually hide fields when compact
    default_style = default_plutotree_style(class, nt)
    # Remove the hide when compact wrapper now
    body = tree_data(map(unwrap_hide, nt), io)
    # Modify the resulting dict 
    modify_tree_data_dict!(body, item)
    mime = MIME"application/vnd.pluto.tree+object"()
    result = @htl("""
    <div class='as-pluto-tree'>
    <pluto-display class=$(class)></pluto-display><script id=$(random_class())>
        const body = $(published_to_js(body));
        const mime = $(string(mime));
        
        const create_new = this == null || this._mime !== mime;
        
        const display = create_new ? currentScript.previousElementSibling : this;
        
        display.persist_js_state = true;
        display.sanitize_html = false;
        display.body = body;
        if(create_new) {
            // only set the mime if necessary, it triggers a second preact update
            display.mime = mime;
            // add it also as unwatched property to prevent interference from Preact
            display._mime = mime;
        }
        return display;
        </script>
        $(default_style |> HypertextLiteral.Bypass)
    </div>
    """
    )
    show(io, MIME"text/html"(), result)
end

# Display length and angle

"""
    DualDisplayAngle(angle)
Take an angle **in radians** and display it via `show` in both radians and degrees.
"""
struct DualDisplayAngle{T} <: CustomShowable
    angle::T
    digits::Union{Nothing, Int}
    sigdigits::Union{Nothing, Int}
    function DualDisplayAngle(angle::Real; digits = nothing, sigdigits = nothing)
        @assert isnothing(digits) || isnothing(sigdigits) "You can only provide one out of digits and sigdigits"
        angle = float(angle)
        if isnothing(digits) && isnothing(sigdigits)
            digits = 3 # Default to 3 digits
        end
        new{typeof(angle)}(angle, digits, sigdigits)
    end
end

function show_inside_pluto(io::IO, x::DualDisplayAngle)
    (; digits, sigdigits) = x
    degs = """<span class='deg'>$(split_digits_html(rad2deg(x.angle); digits, sigdigits, suffix="°"))</span>"""
    rads = """<span class='rad'>$(split_digits_html(x.angle; digits, sigdigits, suffix=" rad"))</span>"""
    style = """
    <style>
        digits.full {
            display: none;
        }
        pluto-tree.collapsed display-angle .rad {
            display: none;
        }
        display-angle .rad {
            margin-left: 5px;
        }
        display-angle .rad:before {
            content: "(";
        }
        display-angle .rad:after {
            content: ")";
        }
    </style>
    """
    out = """<display-angle>$degs$rads$style</display-angle>"""
    write(io, out)
end
function Base.show(io::IO, x::DualDisplayAngle)
    (; digits, sigdigits) = x
    f(x) = get(io, :full_precision, false) ? x : round(x; digits, sigdigits)
    g(x) = isinteger(f(x)) ? round(Int, f(x)) : f(x)
    compact = get(io, :compact, false) || get(io, :inside_2arg_show, false)
    rads = x.angle
    isnan(rads) && return print(io, "NaN")
    degs = rad2deg(rads)
    print(io, repr(g(degs)), "°")
    if !compact
        print(io, " (")
        print(io, repr(g(rads)))
        print(io, " rad)")
    end
end

struct DisplayLength{T} <: CustomShowable
    length::T
    digits::Union{Nothing, Int}
    sigdigits::Union{Nothing, Int}
    function DisplayLength(length::Real; digits = nothing, sigdigits = nothing)
        @assert isnothing(digits) || isnothing(sigdigits) "You can only provide one out of digits and sigdigits"
        length = float(length)
        if isnothing(digits) && isnothing(sigdigits)
            digits = 3 # Default to 3 digits
        end
        new{typeof(length)}(length, digits, sigdigits)
    end
end

function Base.show(io::IO, l::DisplayLength)
    (; digits, sigdigits) = l
    f(x) = get(io, :full_precision, false) ? x : round(x; digits, sigdigits)
    g(x) = isinteger(f(x)) ? round(Int, f(x)) : f(x)
    len = l.length
    isnan(len) && return print(io, "NaN")
    if abs(len) < 1000
        print(io, repr(g(len)), " m")
    else
        len /= 1000
        print(io, repr(g(len)), " km")
    end
end

function show_inside_pluto(io::IO, x::DisplayLength)
    (; digits, sigdigits) = x
    suffix = x.length < 1000 ? " m" : " km"
    len = """<span class='m'>$(split_digits_html(x.length; digits, sigdigits, suffix))</span>"""
    style = """
    <style>
        digits.full {
            display: none;
        }
    </style>
    """
    out = """<display-length>$len$style</display-length>"""
    write(io, out)
end

"""
    struct DefaultShowOverload end
This is a type that can be used to simplify custom show for one's own types.

To leverage the default show functionality, it is sufficient to show the instance of the desired type inside a `DefaultShowOverload` wrapper and show it directly like so:
```julia
Base.show(io::IO, x::MyType) = show(io, DefaultShowOverload(x))
Base.show(io::IO, mime::MIME"text/html", x::MyType) = show(io, mime, DefaultShowOverload(x))
Base.show(io::IO, mime::MIME"text/plain", x::MyType) = show(io, mime, DefaultShowOverload(x))
```

Per-type customization of default show can then be achieved by optionally adding a specific method for the following functions:
- [`show_namedtuple`](@ref)
- [`repl_summary`](@ref)
- [`longname`](@ref)
- [`shortname`](@ref)
- [`show_inside_pluto`](@ref)
- [`show_outside_pluto`](@ref)

"""
struct DefaultShowOverload <: CustomShowable
    item
end

function show_inside_pluto(io::IO, x::DefaultShowOverload) 
    show_inside_pluto(io, AsPlutoTree(unwrap(x)))
end

function Base.show(io::IO, mime::MIME"text/plain", x::DefaultShowOverload)
    item = unwrap(x)
    nt = show_namedtuple(item, OutsidePluto())::NamedTuple
    f(n) = repeat(" ", n)
    io = IOContext(io, :inside_3arg_show => true, :inside_2arg_show => false)
    println(io, repl_summary(item), ":")
    for (nm, val) in pairs(nt)
        val isa Union{HideAlways, HideWhenFull} && continue
        print(io, f(2))
        Base.isgensym(nm) || print(io, nm, " = ")
        show(io, unwrap_hide(val))
        println(io)
    end
end

function Base.show(io::IO, x::DefaultShowOverload)
    item = unwrap(x)
    nt = show_namedtuple(item, OutsidePluto())::NamedTuple
    compact = get(io, :compact, false)
    nio = IOContext(io, :inside_2arg_show => true, :inside_3arg_show => false) # We use a custom compact flag mostly to deal with DualDisplayAngle
    print(nio, shortname(item), "(")
    first = true
    SHOULD_HIDE = Union{HideAlways, HideWhenCompact}
    for (nm, val) in pairs(nt)
        val isa SHOULD_HIDE && continue # Skip fields that should be hidden
        first || print(nio, ", ")
        # We don't print labels by default for 2-arg show 
        # compact || val isa SHOULD_HIDE || Base.isgensym(nm) || print(nio, nm, " = ")
        show(nio, unwrap_hide(val))
        first = false
    end
    print(nio, ")")
end

show_outside_pluto(io::IO, x::DefaultShowOverload) = show_outside_pluto(io, unwrap(x))

struct Ellipsis <: CustomShowable end

Base.show(io::IO, x::Ellipsis) = print(io, get(io, :inside_3arg_show, false) ? VDOTS : HDOTS)
Base.show(io::IO, mime::MIME"text/plain", x::Ellipsis) = print(io, VDOTS)
function show_inside_pluto(io::IO, x::Ellipsis)
    show(io, MIME"text/html"(), @htl("""
    <ellipsis></ellipsis>
    """))
end

