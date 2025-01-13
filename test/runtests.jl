using TestItemRunner

@testitem "Aqua" begin
    using PlutoShowHelpers
    using Aqua
    Aqua.test_all(PlutoShowHelpers)
end