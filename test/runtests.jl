using TestItemRunner

@run_package_tests filter = ti -> :after ∉ ti.tags verbose=true
@run_package_tests filter = ti -> :after ∈ ti.tags verbose=true
