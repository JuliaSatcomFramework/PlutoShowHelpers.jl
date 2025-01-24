using TestItemRunner

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
