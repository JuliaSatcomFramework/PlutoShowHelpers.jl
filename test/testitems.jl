@testsnippet setup_basics begin
    using PlutoShowHelpers
    using Test
    using PlutoShowHelpers: is_inside_pluto, HideWhenCompact, HideWhenFull, HideAlways, show_namedtuple, DualDisplayAngle, DisplayLength, Ellipsis, show_inside_pluto, show_outside_pluto, tree_data, unwrap, unwrap_hide, random_class, repl_summary
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

    # Test Float32 representation
    d = DualDisplayAngle(Float32(π/2); digits = 2)
    @test repr(d) == "90° (1.57f0 rad)"
end

@testitem "DisplayLength" begin
    using Test
    
    # Test meters
    l = DisplayLength(123.456)
    @test repr(l) == "123.456 m"
    
    # Test kilometers
    l = DisplayLength(1234.567)
    @test repr(l) == "1.235 km"
    l = DisplayLength(-1234.567)
    @test repr(l) == "-1.235 km"

    # Test with custom digits
    l = DisplayLength(123.456, digits=1)
    @test repr(l) == "123.5 m"

    # Test Float32 representation
    l = DisplayLength(1.324f0; digits = 1)
    @test repr(l) == "1.3f0 m"

    # Test with NaN
    l = DisplayLength(NaN)
    @test repr(l) == "NaN"
end

@testitem "Utility Functions" setup = [setup_basics] begin
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

    struct UtilityTest
        a::Int
    end

    ut = UtilityTest(42)
    @test repl_summary(ut) === Base.summary(ut)

    @test_logs (:warn, r"This function wrapper") tree_data(ut)
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

@testitem "DefaultShowOverload" setup = [setup_basics] begin
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
    nt = show_namedtuple(ts)
    @test show_namedtuple(nt, OutsidePluto()) === nt
    @test show_namedtuple(nt, InsidePluto()) === nt

    @test_logs (:warn, r"is not overloaded") show_inside_pluto(IOBuffer(), ts)

    wrapped = DefaultShowOverload(ts)

    @test repr(wrapped) === "ShortName(1.23)" # We test hiding in compact mode
    @test repr(MIME"text/plain"(), wrapped) === "LongName:\n  a = 42\n" # We test hiding in compact mode

    # Test not warn for not overloaded show outside pluto
    @test_logs (:warn, r"is not overloaded") repr(MIME"text/html"(), wrapped; context = :is_pluto => false)
    
    # Test unwrapping
    @test unwrap(wrapped) === ts
end

@testitem "print_2arg_names" setup = [setup_basics] begin
    using PlutoShowHelpers: CONTEXT, DefaultShowOverload, OutsidePluto

    struct P2ArgStruct
        a::Int
        b::Int
        c::Int
    end

    # show_namedtuple mutates CONTEXT[] to opt :b into label printing in 2-arg show
    PlutoShowHelpers.show_namedtuple(t::P2ArgStruct, ::OutsidePluto) = begin
        CONTEXT[][:print_2arg_names] = (:b,)
        (; a = t.a, b = t.b, c = t.c)
    end
    PlutoShowHelpers.shortname(::P2ArgStruct) = "P2A"
    PlutoShowHelpers.repl_summary(::P2ArgStruct) = "P2ArgStruct"

    wrapped = DefaultShowOverload(P2ArgStruct(1, 2, 3))

    # 2-arg show: only :b has a label
    @test repr(wrapped) == "P2A(1, b = 2, 3)"

    # 3-arg show: all labels shown regardless (unaffected by :print_2arg_names)
    @test repr(MIME"text/plain"(), wrapped) == "P2ArgStruct:\n  a = 1\n  b = 2\n  c = 3\n"
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

@testitem "Inside Pluto" setup = [setup_basics] tags = [:after] begin
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

    PlutoShowHelpers.show_namedtuple(x::InPlutoStruct, ::InsidePluto) = (;
        a = HideWhenCompact(x.a),
        b = HideWhenFull(x.b),
        c = HideAlways(x.c),
        var"#asd" = 3,
        d = HideWhenCompact(x.d),
    )

    is = InPlutoStruct(1, 2, 3, 4)
    tree_data(is)

    wrapped = DefaultShowOverload(is)
    s = repr(MIME"text/html"(), wrapped; context)
    @test contains(s, "class='as-pluto-tree'")
    @test contains(s, "const body = dummy")

    s = repr(MIME"text/html"(), DualDisplayAngle(π/2); context)
    @test contains(s, "class='deg'")
    @test contains(s, "class='rad'")

    s = repr(MIME"text/html"(), DisplayLength(1234.567); context)
    @test contains(s, "class='m'")
    @test contains(s, " km")

    s = repr(MIME"text/html"(), DisplayLength(456.789); context)
    @test contains(s, "class='m'")
    @test contains(s, " m")

    s = repr(MIME"text/html"(), Ellipsis(); context)
    @test contains(s, "<ellipsis></ellipsis>")
end


@testitem "CONTEXT ScopedValue" setup = [setup_basics] begin
    using PlutoShowHelpers: CONTEXT, DefaultShowOverload, OutsidePluto, Ellipsis

    @test isempty(CONTEXT[])

    struct CTXTestStruct
        v::Int
    end
    PlutoShowHelpers.show_namedtuple(t::CTXTestStruct, ::OutsidePluto) = (; v = t.v)
    PlutoShowHelpers.shortname(::CTXTestStruct) =
        get(CONTEXT[], MIME, missing) === missing ? "Full" : "Short"

    @test PlutoShowHelpers.shortname(CTXTestStruct(1)) == "Full"
    @test repr(DefaultShowOverload(CTXTestStruct(1))) == "Short(1)"

    struct WrapsDDA
        angle::DualDisplayAngle
    end
    PlutoShowHelpers.show_namedtuple(t::WrapsDDA, ::OutsidePluto) = (; angle = t.angle)
    s = repr(DefaultShowOverload(WrapsDDA(DualDisplayAngle(π/2))))
    @test !contains(s, "rad")  # compact form omits the radians part

    struct HasEllipsis end
    PlutoShowHelpers.show_namedtuple(::HasEllipsis, ::OutsidePluto) = (; var"#e" = Ellipsis())
    wrapped_e = DefaultShowOverload(HasEllipsis())
    @test contains(repr(MIME"text/plain"(), wrapped_e), "\u22ee")  # 3-arg: VDOTS
    @test contains(repr(wrapped_e), "\u2026")                      # 2-arg: HDOTS
end

@testitem "DefaultShowOverload Macro" setup = [setup_basics] begin  
    struct ShowTest
        a::Int
        b::String
        c::Float64
    end

    struct MAH end

    @default_show_overload Union{ShowTest, MAH}

    @test which(Base.show, (IO, ShowTest)) == which(Base.show, (IO, MAH))

    PlutoShowHelpers.show_namedtuple(::ShowTest, ::OutsidePluto) = (;
        only = "Override!"
    )

    st = ShowTest(1, "hello", 1.23)
    @test contains(repr(st), "Override!")
    @test contains(repr(MIME"text/html"(), st), "Override!")
    @test contains(repr(MIME"text/plain"(), st), "Override!")
end

# Tagged :after because disable_html_show! adds Base.showable methods for types owned by
# neither Base nor PlutoShowHelpers, which the Aqua piracy check flags if it runs later.
@testitem "disable_html_show!" tags = [:after] begin
    using PlutoShowHelpers
    using PlutoShowHelpers: disable_html_show!, uses_default_html_show, CustomShowable
    using Test

    struct ViaMacro
        x::Int
    end
    @default_show_overload ViaMacro

    struct ViaSubtyping <: CustomShowable
        x::Int
    end
    PlutoShowHelpers.show_outside_pluto(io::IO, v::ViaSubtyping) = print(io, "<b>", v.x, "</b>")

    struct StaysHTML
        x::Int
    end
    @default_show_overload StaysHTML

    struct NoOverload
        x::Int
    end

    # The trait is declared by the macro and by CustomShowable, and by nothing else.
    @test uses_default_html_show(ViaMacro)
    @test uses_default_html_show(ViaSubtyping)
    @test !uses_default_html_show(NoOverload)

    m, s, k = ViaMacro(1), ViaSubtyping(2), StaysHTML(3)

    # No pre-state assertion for `s`: the method disabling it is installed on the abstract
    # CustomShowable, so it survives in a reused test process and catches any later subtype.
    @test showable(MIME"text/html"(), m)
    @test showable(MIME"text/html"(), k)

    plain_before = repr(MIME"text/plain"(), m)
    html_before = repr(MIME"text/html"(), s)

    disabled = disable_html_show!(; exclude = (StaysHTML,))

    @test ViaMacro in disabled
    @test CustomShowable in disabled
    @test StaysHTML ∉ disabled

    # ViaMacro is disabled by its own method, ViaSubtyping by the abstract CustomShowable
    # method alone, StaysHTML kept by an explicit `= true`.
    @test !invokelatest(showable, MIME"text/html"(), m)
    @test !invokelatest(showable, MIME"text/html"(), s)
    @test invokelatest(showable, MIME"text/html"(), k)

    # Only MIME negotiation changes; rendering is untouched. `repr` calls `show` directly
    # and never consults `showable`, so HTML is still produced on demand.
    @test invokelatest(repr, MIME"text/plain"(), m) == plain_before
    @test invokelatest(repr, MIME"text/html"(), s) == html_before == "<b>2</b>"
end