# Changelog

<!-- markdownlint-configure-file {"MD024": {"siblings_only": true}} -->

## [1.0.4](https://github.com/1121citrus/bats-kcov/releases/tag/v1.0.4) - 2026-10-30

### Changed

* Regenerate `build` and `test/run-all` from the current generator: add a
  bash >= 4.0 version guard, replace non-portable `readlink -f` in
  `script_dir` resolution with a portable resolver, and fix Docker Scout
  CVE scanning to actually gate (`--exit-code --only-severity
  critical,high`) instead of a bare `docker scout cves` invocation that
  always exited 0 regardless of findings. `test/run-all` now invokes
  `bats --recursive test` and is brought fully under generator control.
* Bump `alpine` 3.22 → 3.24 and `actions/checkout` 6.0.2 → 7.0.0
  (Dependabot PRs #4 and #5).
* Grant `contents: write` in `.github/workflows/ci.yml` so the shared
  `pipeline.yml@v1` caller's promote job can start (the job's own `if`
  guard still keeps it from running, since `auto-promote` defaults to
  off here).
* Add `dev` to the CI workflow's push and pull-request branch triggers.
* Migrate `.github/workflows/ci.yml` to a single call into the shared
  `pipeline.yml@v1` caller (bats test mode, smoke commands including an
  entrypoint check and the E2E bats-coverage run).
* Restrict the DockerHub push job to version-tag releases only; `staging`
  branch pushes still run build/test/scan but no longer publish an
  unstable tag.

### Documentation

* Add a "Development toolchain" section to `CLAUDE.md` directing model
  agents to use `./build` for all CI operations instead of installing or
  locating host-side tools.

## [1.0.3](https://github.com/1121citrus/bats-kcov/releases/tag/v1.0.3) - 2026-06-10

### Changed

* Rebase runtime image from `kcov/kcov:latest-alpine` (Alpine 3.20, EOL) to
  `alpine:3.22` via a multi-stage build. The kcov binary is extracted from
  the upstream image; only its verified runtime library dependencies (per
  `ldd`) are installed in the final image.
* Remove `python3`, `binutils`, `binutils-dev`, and `sqlite-libs` from the
  runtime image — these were present in the kcov build stage but are not
  runtime dependencies of the kcov binary.
* Pin `alpine:3.22` by digest; add Dependabot tracking for the new pin.
* Shrink `.grype.yaml` ignore list from 29 entries to 3 (busybox
  `CVE-2025-60876`, Medium, no fix in Alpine 3.22).
* Update `SECURITY.md` to document multi-stage architecture and revised CVE
  table.

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
