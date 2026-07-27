# Changelog

This file contains the changelog for the PlutoShowHelpers package. It follows the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

## [Unreleased]

### Added
- `disable_html_show!` — an opt-in call for documentation builds that makes Documenter render types handled by this package with their REPL (`text/plain`) representation instead of their HTML one. Documenter's `@example` blocks pick the richest MIME a value supports and gate that choice on `Base.showable`, so without it they render through `show_outside_pluto` rather than the REPL form. Call it once from `make.jl` before `makedocs`, or from a `@setup` block. Types defined afterwards are covered too, including those registered inside `@example` blocks. Accepts extra types positionally for hand-written `text/html` show methods, and an `exclude` keyword for types that should keep rendering as HTML.
- `uses_default_html_show` — the trait `disable_html_show!` uses to find those types. Declared for `CustomShowable` and emitted by `@default_show_overload`; it has no effect on how a type is shown.

## [0.3.6] - 2026-07-10

### Fixed
- `DisplayLength.show_inside_pluto` now uses `abs()` for the km threshold and divides by 1000 for km display
- `show_outside_pluto` docstring updated to match the actual 2-arg `show` fallback (changed in v0.2.0)
- `AsPlutoTree` docstring grammar fixes
- CHANGELOG package name corrected from "ReferenceViews"

### Added
- Docstrings for `InsidePluto`, `OutsidePluto`, `HideWhenCompact`, `HideWhenFull`, `HideAlways`, `DisplayLength`, `Ellipsis`, `longname`, `shortname`, `repl_summary`
- User-facing documentation using DocumenterVitepress with quickstart, guide, utility types, and API reference pages

## [0.3.5] - 2025-05-28

### Added
- `CONTEXT` — a package-scoped `ScopedValue` holding a `Dict{Any,Any}`. Types enabling PlutoShowHelpers functionality with `@default_show_overload` can use this to potentially have greater control on how to exploit the show machinery. For the moment kept as experimental.
- Added an experimental way to specify some fields' labels to still be shown inside the 2-arg show, relying on the newly introduced CONTEXT

## [0.3.4] - 2025-05-11

### Fixed
- Collapse status of PlutoTree objects should now persist at least upon reactive re-run of a cell (not with direct manual rerun)

## [0.3.3] - 05/11/2025
### Added
- Added a convenience macro `@default_show_overload` to simplify the overload of the show methods for a given type.

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
