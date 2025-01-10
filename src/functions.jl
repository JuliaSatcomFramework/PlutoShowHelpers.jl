# Taken from PlutoRunner.jl
objectid2str(@nospecialize(x)) = string(objectid(x); base=16)::String

# Wrapping the function in PlutoRunner.jl
function tree_data(x, io)
    @nospecialize
    out = if is_inside_pluto(io)
        Main.PlutoRunner.tree_data(x, io)::Dict{Symbol, Any}
    else
        @warn "This function wrapper is not supposed to be called outside of Pluto"
        Dict{Symbol, Any}()
    end
    return out
end

# Just create n tabs characters
_tabs(n::Int) = repeat("\t", n)

# Create random alphanumeric strings starting with a letter
rand_lower() = rand('a':'z')
rand_upper() = rand('A':'Z')
rand_digit() = rand('0':'9')
rand_char() = rand(Bool) ? rand_lower() : rand_upper()
rand_alphanumeric() = rand(Bool) ? rand_digit() : rand_char()

function random_class(size = 6)
    io = IOBuffer()
    write(io, rand_char())
    for _ in 2:size
        write(io, rand_alphanumeric())
    end
    return String(take!(io))
end

# Show methods overloadables
"""
    show_inside_pluto(io::IO, x)
This function is used inside the show method for [`ShowWrapper`](@ref) for MIME of type `text/html` only if the passed `io` is inside Pluto. 
    
This function defaults to calling [`show_outside_pluto`](@ref) if not overloaded for the specific type of `x`.
"""
function show_inside_pluto(io::IO, x)
    @nospecialize
    show_outside_pluto(io, x)
end

"""
    show_outside_pluto(io::IO, x)
This function is used inside the show method for [`ShowWrapper`](@ref) for MIME of type `text/html` only if the passed `io` is outside Pluto.

This function defaults to calling [`show`](@ref) with MIME of type `text/plain` if not overloaded for the specific type of `x`.
"""
function show_outside_pluto(io::IO, x)
    @nospecialize
    @warn "show_outside_pluto is not overloaded for $(typeof(x)), defaulting to output of show(io, MIME\"text/plain\", x)"
    show(io, MIME"text/plain"(), x)
end

# Customize shown names of type
longname(@nospecialize(x); context=nothing) = longname(typeof(x); context)
longname(x::DataType; context=nothing) = repr(x; context)
shortname(@nospecialize(x)) = shortname(typeof(x))
shortname(x::DataType) = nameof(x) |> string

# This needs to be overloaded if one wants custom multiline type name in the REPL
repl_summary(@nospecialize(x)) = Base.summary(x)

"""
    function show_namedtuple(x) end
This function takes an instance of a type and generate the corresponding NamedTuple specifying the fileds to show and how the content of each field should eventually be processed.

Adding a method to this function for a specific type is required for customizing how objects are shown via the convenience show methods of this package (e.g. see [`AsPlutoTree`](@ref)).

By default it just translates the provided object into a NamedTuple using `ntfromstruct` from NamedTupleTools.jl.
"""
show_namedtuple(@nospecialize(x)) = ntfromstruct(x)

# This function is used for convenience to extract the wraped element for some of the types defined in this package, like HideWhenCompact
unwrap(@nospecialize(x)) = x
unwrap(x::HideWhenCompact) = x.item
unwrap(x::AsPlutoTree) = x.element
unwrap(x::DefaultShowOverload) = x.item
# Used to create adapt the dict of tree_data from namedtuple to the original struct type
function modify_tree_data_dict!(d::Dict{Symbol, Any}, item)
    d[:objectid] = objectid2str(item)
    d[:type] = :struct
    d[:prefix] = longname(item)
    d[:prefix_short] = shortname(item)
    # We transforms fieldnames from strings to symbols
    d[:elements] = Any[(Symbol(t[1]), t[2]) for t in d[:elements]]
    return nothing
end

add_tabs(tabs::Int) = s -> let 
    io = IOBuffer()
    for _ in 1:tabs
        print(io, "\t")
    end
    print(io, s)
    return String(take!(io))
end

function default_plutotree_style(class::String, hide_when_compact; tabs = 0)
    any(hide_when_compact) || return ""
    io = IOBuffer()
    f(n) = _tabs(n)
    selector = isempty(class) ? "" : ".$class "
    first_shown = findfirst(!, hide_when_compact)
    last_shown = findlast(!, hide_when_compact)
    println(io, f(tabs)..., "<style>")
    tabs += 1
    for (i, n) in enumerate(findall(hide_when_compact))
        print(io, f(tabs)..., selector, "pluto-tree.collapsed p-r:nth-child($(n))")
        println(io, (i == sum(hide_when_compact) ? " {" : ","))
    end
    tabs += 1
    println(io, f(tabs)..., "display: none;")
    tabs -= 1
    println(io, f(tabs)..., "}")
    if first_shown !== 1 # Remove the margin on the first shown field
        println(io, f(tabs)..., selector, "pluto-tree.collapsed p-r:nth-child($(first_shown)) {")
        println(io, f(tabs+1)..., "margin-left: 0;")
        println(io, f(tabs)..., "}")
    end
    if last_shown !== length(hide_when_compact) # Remove the comma on the last shwon element
        println(io, f(tabs)..., selector,"pluto-tree.collapsed p-r:nth-child($(last_shown)):after {")
        println(io, f(tabs+1)..., "content: none;")
        println(io, f(tabs)..., "}")
    end
    tabs -= 1
    println(io, f(tabs)..., "</style>")
    return String(take!(io))
end

# This function split a number into two parts for showing in HTML
function split_digits_html(val; digits = nothing, sigdigits = nothing, suffix = "")
    roundval = round(val; digits, sigdigits)
    full = "<digits class='full'>$val$suffix</digits>"
    rounded = "<digits class='rounded'>$roundval$suffix</digits>"
    out = "<pre class='no-block'>$full$rounded</pre>"
    return out
end
