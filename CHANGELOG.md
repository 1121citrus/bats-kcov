# Changelog

## [0.0.2](https://github.com/1121citrus/bats-kcov/releases/tag/v0.0.2) - 2026-03-28

### Changed

* Pin base image to `kcov/kcov:v42`; add Dependabot Docker tracking.

## [0.0.1](https://github.com/1121citrus/bats-kcov/releases/tag/v0.0.1) - 2026-03-28

### Added

* Initial release: kcov bundled with bats and jq for measuring bash test
  coverage in CI pipelines.
* OCI image labels with version, revision, and created metadata.
* `build` script with lint, build, test, smoke, scan, and advisory stages.
* Bats test suite covering Dockerfile structure, OCI metadata, and build
  script option parsing.
