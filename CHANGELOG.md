# Changelog

<!-- markdownlint-configure-file {"MD024": {"siblings_only": true}} -->

## [1.0.2](https://github.com/1121citrus/bats-kcov/releases/tag/v1.0.2) - 2026-05-03

### Changed

* Add Gitleaks CI workflow.
* Regenerate build scripts with Gitleaks advisement support.

## [1.0.1](https://github.com/1121citrus/bats-kcov/releases/tag/v1.0.1) - 2026-04-30

### Changed

* Regenerate build script from fixed templates, including dry-run Stage 3
  guard, descriptor/provenance SHA sync, and dev-latest tag handling.
* Add leading docstrings to generated build functions.
* Add Phase 2 test/staging integration to generated build script.
* Pin `shared-github-workflows` reference to `@v1`.
* Add regression test coverage for `_timed` and grype fix behavior.

## [1.0.0](https://github.com/1121citrus/bats-kcov/releases/tag/v1.0.0) - 2026-04-20

### Changed

* Apply generated Phase 3 build script.
* Add grype ignore list and fix `_timed` set -e incompatibility in scan path.

## [0.1.0](https://github.com/1121citrus/bats-kcov/releases/tag/v0.1.0) - 2026-04-18

### Changed

* Add scanner DB staleness warning in build flow.
* Migrate base image from `kcov/kcov:v42` to `kcov/kcov:latest-alpine`.
* Set default container working directory to `/code`.
* Add `--min-coverage` option to `bats-coverage`.
* Add `bats-coverage` input validation, jq dependency guard, and proper exit
  status propagation.

### Fixed

* Upgrade packages to resolve post-digest base image CVEs.
* Tighten hadolint failure threshold from warning to error.
* Sync `version.txt` and `CHANGELOG.md` with git tags.
* Update security docs and remove release-please workflow/docs.
* Clarify `--src` versus `--include` behavior and populate `.gitignore`.

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
