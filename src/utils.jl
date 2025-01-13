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
# Just helper function for debugging in Pluto
function tree_data(x)
    io = if is_inside_pluto()
        IOContext(IOBuffer(), :is_pluto => true)
    else
        IOContext(IOBuffer())
    end
    return tree_data(x, io)
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


# This function is used for convenience to extract the wraped element for some of the types defined in this package, like HideWhenCompact
unwrap_hide(@nospecialize(x)) = x
unwrap_hide(@nospecialize(x::AbstractHidden)) = x.item
unwrap(@nospecialize(x)) = x
unwrap(@nospecialize(x::AbstractHidden)) = unwrap_hide(x)
unwrap(x::AsPlutoTree) = x.element
unwrap(x::DefaultShowOverload) = x.item

function unwrap_symbol(::Val{T}) where T
    @nospecialize
    @assert T isa Symbol "You can only use Val wrapping symbols"
    return T::Symbol
end

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

function default_plutotree_style(class::String, nt; ntabs = 0)
    io = IOBuffer()
    selector = isempty(class) ? "" : ".$class > * > "
    println(io, _tabs(ntabs)..., "<style>")
    add_aspluto_tree_style!(io, nt; ntabs = ntabs+1, selector)
    add_hide_when_compact_style!(io, nt; ntabs = ntabs+1, selector)
    add_hide_when_full_style!(io, nt; ntabs = ntabs+1, selector)
    hide_labels_style!(io, nt; ntabs = ntabs+1, selector)
    add_ellipsis_style!(io, nt; ntabs = ntabs+1, selector)
    println(io, _tabs(ntabs)..., "</style>")
    return String(take!(io))
end

function add_aspluto_tree_style!(io, nt; ntabs = 0, selector = "")
    println(io, _tabs(ntabs)..., ".as-pluto-tree {")
    println(io, _tabs(ntabs+1)..., "white-space: normal;")
    println(io, _tabs(ntabs)..., "}")
end

function add_ellipsis_style!(io, nt; ntabs = 0, selector = "")
    println(io, _tabs(ntabs)..., selector, "pluto-tree.collapsed ellipsis:before {")
    println(io, _tabs(ntabs+1)..., "content: '...';")
    println(io, _tabs(ntabs)..., "}")
    println(io)
    println(io, _tabs(ntabs)..., selector, "pluto-tree:not(.collapsed) ellipsis:before {")
    println(io, _tabs(ntabs+1)..., "content: '$VDOTS';")
    println(io, _tabs(ntabs)..., "}")
    return
end

function add_hide_when_full_style!(io, nt; ntabs = 0, selector = "")
    hide_when_full = map(x -> x isa Union{HideWhenFull, HideAlways}, values(nt))
    any(hide_when_full) || return 
    ntabs += 1
    for (i, n) in enumerate(findall(hide_when_full))
        print(io, _tabs(ntabs)..., selector, "pluto-tree:not(.collapsed) > * > p-r:nth-child($(n))")
        println(io, (i == sum(hide_when_full) ? " {" : ","))
    end
    ntabs += 1
    println(io, _tabs(ntabs)..., "display: none;")
    ntabs -= 1
    println(io, _tabs(ntabs)..., "}")
    return
end

function add_hide_when_compact_style!(io, nt; ntabs = 0, selector = "")
    hide_when_compact = map(x -> x isa Union{HideWhenCompact, HideAlways}, values(nt))
    any(hide_when_compact) || return 
    first_shown = findfirst(!, hide_when_compact)
    last_shown = findlast(!, hide_when_compact)
    ntabs += 1
    for (i, n) in enumerate(findall(hide_when_compact))
        print(io, _tabs(ntabs)..., selector, "pluto-tree.collapsed > * > p-r:nth-child($(n))")
        println(io, (i == sum(hide_when_compact) ? " {" : ","))
    end
    ntabs += 1
    println(io, _tabs(ntabs)..., "display: none;")
    ntabs -= 1
    println(io, _tabs(ntabs)..., "}")
    if first_shown !== 1 # Remove the margin on the first shown field
        println(io, _tabs(ntabs)..., selector, "pluto-tree.collapsed > * > p-r:nth-child($(first_shown)) {")
        println(io, _tabs(ntabs+1)..., "margin-left: 0;")
        println(io, _tabs(ntabs)..., "}")
    end
    if last_shown !== length(hide_when_compact) # Remove the comma on the last shwon element
        println(io, _tabs(ntabs)..., selector,"pluto-tree.collapsed > * > p-r:nth-child($(last_shown)):after {")
        println(io, _tabs(ntabs+1)..., "content: none;")
        println(io, _tabs(ntabs)..., "}")
    end
    return
end

function hide_labels_style!(io, nt; ntabs = 0, selector = "")
    hide_labels = map(Base.isgensym, keys(nt))
    any(hide_labels) || return
    ntabs += 1
    for (i, n) in enumerate(findall(hide_labels))
        print(io, _tabs(ntabs)..., selector, "pluto-tree:not(.collapsed) > * > p-r:nth-child($(n)) > p-k")
        println(io, (i == sum(hide_labels) ? " {" : ","))
    end
    println(io, _tabs(ntabs)..., "display: none;")
    ntabs -= 1
    println(io, _tabs(ntabs)..., "}")
    return
end

# This function split a number into two parts for showing in HTML
function split_digits_html(val; digits = nothing, sigdigits = nothing, suffix = "")
    roundval = round(val; digits, sigdigits)
    full = "<digits class='full'>$val$suffix</digits>"
    rounded = "<digits class='rounded'>$roundval$suffix</digits>"
    out = "<pre class='no-block'>$full$rounded</pre>"
    return out
end
