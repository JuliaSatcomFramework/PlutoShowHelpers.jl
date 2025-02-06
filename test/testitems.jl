@testsnippet setup_basics begin
    using PlutoShowHelpers
    using Test
    using PlutoShowHelpers: is_inside_pluto, HideWhenCompact, HideWhenFull, HideAlways, show_namedtuple, DualDisplayAngle, DisplayLength, Ellipsis
end

@testitem "Aqua" begin
    using PlutoShowHelpers
    using Aqua
    Aqua.test_all(PlutoShowHelpers)
end

@testitem "DualDisplayAngle" begin
    d = DualDisplayAngle(π/2)

    s = repr(d)
    @test s === "90° (1.571 rad)"

    @test s === repr(MIME"text/plain"(), d)

    d = DualDisplayAngle(π/2, digits = 2)
    s = repr(d)
    @test s === "90° (1.57 rad)"
end

@testitem "DisplayLength" begin
    using Test
    
    # Test meters
    l = DisplayLength(123.456)
    @test repr(l) == "123.456 m"
    
    # Test kilometers
    l = DisplayLength(1234.567)
    @test repr(l) == "1.235 km"
    
    # Test with custom digits
    l = DisplayLength(123.456, digits=1)
    @test repr(l) == "123.5 m"
    
    # Test with NaN
    l = DisplayLength(NaN)
    @test repr(l) == "NaN"
end

@testitem "Utility Functions" begin
    using Test
    using PlutoShowHelpers: unwrap, unwrap_hide, random_class
    
    # Test unwrap and unwrap_hide
    x = 42
    @test unwrap(x) === x
    @test unwrap_hide(x) === x
    
    # Test random_class
    class = random_class()
    @test length(class) == 6
    @test isnothing(match(r"^[0-9]", class)) # Should not start with a number
    @test !isnothing(match(r"^[a-zA-Z][a-zA-Z0-9]{5}$", class))
    
    # Test with custom size
    class = random_class(8)
    @test length(class) == 8
end

@testitem "AbstractHidden Types" begin
    using Test
    using PlutoShowHelpers: HideWhenCompact, HideWhenFull, HideAlways, unwrap, unwrap_hide
    
    x = 42
    hwc = HideWhenCompact(x)
    hwf = HideWhenFull(x)
    ha = HideAlways(x)
    
    # Test unwrapping
    @test unwrap(hwc) === x
    @test unwrap(hwf) === x
    @test unwrap(ha) === x
    
    @test unwrap_hide(hwc) === x
    @test unwrap_hide(hwf) === x
    @test unwrap_hide(ha) === x
end

@testitem "DefaultShowOverload" begin
    using Test
    using PlutoShowHelpers: DefaultShowOverload, unwrap, OutsidePluto, HideWhenCompact, HideWhenFull, HideAlways
    
    # Create a simple struct to test with
    struct TestStruct
        a::Int
        b::String
        c::Float64
    end

    PlutoShowHelpers.show_namedtuple(t::TestStruct, ::OutsidePluto) = (;
        a = HideWhenCompact(t.a), 
        b = HideAlways(t.b), 
        c = HideWhenFull(t.c)
    )

    PlutoShowHelpers.shortname(::TestStruct) = "ShortName"
    PlutoShowHelpers.repl_summary(::TestStruct) = "LongName"
    
    ts = TestStruct(42, "hello", 1.23)
    wrapped = DefaultShowOverload(ts)

    @test repr(wrapped) === "ShortName(1.23)" # We test hiding in compact mode
    @test repr(MIME"text/plain"(), wrapped) === "LongName:\n  a = 42\n" # We test hiding in compact mode

    # Test not warn for not overloaded show outside pluto
    @test_logs (:warn, r"is not overloaded") repr(MIME"text/html"(), wrapped; context = :is_pluto => false)
    
    # Test unwrapping
    @test unwrap(wrapped) === ts
end

@testitem "Ellipsis" begin
    using Test
    using PlutoShowHelpers: Ellipsis
    
    e = Ellipsis()
    
    # Test basic representation
    @test !isempty(repr(e))
    
    # Test MIME text/plain representation
    @test !isempty(repr("text/plain", e))
end

@testitem "Inside Pluto" tags = [:after] begin
    # We have to load PlutoRunner in Main to "emulate" being inside Pluto
    Core.eval(Main, :(import PlutoRunner))

    # We also have to define a dummy function for the `core_published_to_js` function extracted from the IOContext in `publish_to_js`
    function core_published_to_js(io::IO, x::Any)
        write(io, "dummy")
    end
    context = IOContext(IOBuffer(), :is_pluto => true, :pluto_published_to_js => core_published_to_js)

    struct InPlutoStruct
        a::Int
        b::Int
        c::Int
        d::Int
    end
    wrapped = DefaultShowOverload(InPlutoStruct(1, 2, 3, 4))
    s = repr(MIME"text/html"(), wrapped; context)
    @test contains(s, "class='as-pluto-tree'")
    @test contains(s, "const body = dummy")

    s = repr(MIME"text/html"(), DualDisplayAngle(π/2); context)
    @test contains(s, "class='deg'")
    @test contains(s, "class='rad'")

    s = repr(MIME"text/html"(), DisplayLength(1234.567); context)
    @test contains(s, "class='m'")

    s = repr(MIME"text/html"(), Ellipsis(); context)
    @test contains(s, "<ellipsis></ellipsis>")
end


