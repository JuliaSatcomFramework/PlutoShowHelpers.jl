# Changelog

This file contains the changelog for the ReferenceViews package. It follows the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

## Unreleased

## [0.3.2] - 07/02/2025
### Fixed
- Fixed `DisplayLength{Float32}` not printing with the `fn` suffix

## [0.3.1] - 06/02/2025

### Fixed
- Fixed the km display for negative values of DisplayLength

## [0.3.0] - 06/02/2025
This version added full code coverage to ensure there are no obvious runtime errors.

### Changed
- The `DualDisplayAngle` and `DisplayLength` are now using parametric to allow storing Float32 values (and showing them as Float32).
- The `NamedTupleTools` dependency was switched with `ConstructionBase` to align with the rest of the ecosystem.

## [0.2.0] - 24/01/2025

### Changed
- The default show for `show_outside_pluto` is using 2-arg show as fallback instead of the 3-arg show with `MIME"text/plain"`.

### Fixes
- Fixed a method overwriting in the package for `show_outside_pluto` 

## [0.1.0] - 10/01/2025
- Initial release
