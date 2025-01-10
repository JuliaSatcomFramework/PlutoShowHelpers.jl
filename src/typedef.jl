abstract type CustomShowable end

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

struct AsPlutoTree <: CustomShowable
    element
    class::Union{Nothing, String}
    style::Union{Nothing, String}
end
AsPlutoTree(element; class = nothing, style = nothing) = AsPlutoTree(element, class, style)

# This basicaly replicates the show method for EmbedDisplay in Pluto
function show_inside_pluto(io::IO, wrapped::AsPlutoTree)
    item = unwrap(wrapped)
    nt = show_namedtuple(item)
    class = @something wrapped.class random_class()
    # This is the style that will eventually hide fields when compact
    default_style = default_plutotree_style(class, nt)
    # Remove the hide when compact wrapper now
    body = tree_data(map(unwrap_hide, nt), io)
    # Modify the resulting dict 
    modify_tree_data_dict!(body, item)
    mime = MIME"application/vnd.pluto.tree+object"()
    result = @htl("""
    <div class="as-pluto-tree">
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
struct DualDisplayAngle <: CustomShowable
    angle::Float64
    digits::Union{Nothing, Int}
    sigdigits::Union{Nothing, Int}
    function DualDisplayAngle(angle; digits = nothing, sigdigits = nothing)
        @assert isnothing(digits) || isnothing(sigdigits) "You can only provide one out of digits and sigdigits"
        if isnothing(digits) && isnothing(sigdigits)
            digits = 3 # Default to 3 digits
        end
        new(angle, digits, sigdigits)
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
    compact = get(io, :compact, false) || get(io, :custom_compact, false)
    rads = x.angle
    isnan(rads) && return print(io, "NaN")
    degs = rad2deg(rads)
    print(io, repr(f(degs)), "°")
    if !compact
        print(io, " (")
        print(io, repr(f(rads)))
        print(io, " rad)")
    end
end

struct DisplayLength
    length::Float64
    digits::Union{Nothing, Int}
    sigdigits::Union{Nothing, Int}
    function DisplayLength(length; digits = nothing, sigdigits = nothing)
        @assert isnothing(digits) || isnothing(sigdigits) "You can only provide one out of digits and sigdigits"
        if isnothing(digits) && isnothing(sigdigits)
            digits = 3 # Default to 3 digits
        end
        new(length, digits, sigdigits)
    end
end

function Base.show(io::IO, l::DisplayLength)
    (; digits, sigdigits) = l
    f(x) = get(io, :full_precision, false) ? x : round(x; digits, sigdigits)
    len = l.length
    isnan(len) && return print(io, "NaN")
    if len < 1000
        print(io, f(len), " m")
    else
        len /= 1000
        print(io, f(len), " km")
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
Base.show(io::IO, mime::Union{MIME"text/html", MIME"text/plain"}, x::MyType) = show(io, mime, DefaultShowOverload(x))
```

Per-type customization of default show can then be achieved by optionally adding a specific method for the following functions:
- [`show_namedtuple`](@ref)
- [`repl_summary`](@ref)
- [`longname`](@ref)
- [`shortname`](@ref)

"""
struct DefaultShowOverload <: CustomShowable
    item
end

function show_inside_pluto(io::IO, x::DefaultShowOverload) 
    show_inside_pluto(io, AsPlutoTree(unwrap(x)))
end

function Base.show(io::IO, mime::MIME"text/plain", x::DefaultShowOverload)
    item = unwrap(x)
    nt = show_namedtuple(item)
    f(n) = repeat(" ", n)
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
    nt = show_namedtuple(item)::NamedTuple
    compact = get(io, :compact, false)
    nio = IOContext(io, :custom_compact => true) # We use a custom compact flag mostly to deal with DualDisplayAngle
    print(nio, shortname(item), "(")
    first = true
    SHOULD_HIDE = Union{HideAlways, HideWhenCompact}
    for (nm, val) in pairs(nt)
        val isa SHOULD_HIDE && continue # Skip fields that should be hidden
        first || print(nio, ", ")
        compact || val isa SHOULD_HIDE || print(nio, nm, " = ")
        show(nio, unwrap_hide(val))
        first = false
    end
    print(nio, ")")
end

function Base.show(io::IO, mime::MIME"text/html", x::DefaultShowOverload)
    show(io, mime, AsPlutoTree(unwrap(x)))
end
