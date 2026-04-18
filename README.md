# 1121citrus/bats-kcov

A Docker image bundling [kcov](https://github.com/SimonKagstrom/kcov),
[bats](https://github.com/bats-core/bats-core), and
[jq](https://jqlang.github.io/jq/) for measuring bash/shell test coverage in
CI pipelines.

`kcov` is a coverage tool for languages with DWARF debug information support.
For bash scripts, it instruments code using Linux's `ptrace(2)` API to record
which lines are executed.

## Contents

- [Synopsis](#synopsis)
- [Usage](#usage)
  - [bats-coverage (recommended)](#bats-coverage-recommended)
  - [Integration with a build script](#integration-with-a-build-script)
  - [Direct kcov invocation](#direct-kcov-invocation)
- [Build arguments](#build-arguments)
- [Requirements](#requirements)
- [Building](#building)
- [Attributions and provenance](#attributions-and-provenance)

## Synopsis

This image packages three tools together so CI pipelines can measure bash
coverage without an inline image build step:

| Tool | Purpose |
| --- | --- |
| `kcov` | Bash coverage via `ptrace(2)` with LCOV/JSON output |
| `bats` | Bash Automated Testing System — the test runner |
| `jq` | JSON processor for parsing kcov's `coverage.json` output |

## Usage

### bats-coverage (recommended)

The image ships `bats-coverage`, a command that runs the bats suite under kcov
and prints a per-file line-coverage report. Pass `--src` to set the directory
to measure (default: `/code/src`):

```sh
docker run --rm \
    --cap-add SYS_PTRACE \
    --security-opt seccomp=unconfined \
    -v "$PWD:/code:ro" \
    -w /code \
    1121citrus/bats-kcov \
    bats-coverage test/01-unit.bats test/02-functional.bats
```

Output:

```text
rotate.sh: 87.5% (42/48 lines)
helpers.sh: 100% (12/12 lines)
Overall: 54/60 lines
```

The `--security-opt seccomp=unconfined` flag is required on macOS Docker
Desktop (and many CI environments) because kcov uses `ptrace(2)` calls that
the default seccomp profile blocks.

#### Options

| Option | Default | Description |
| --- | --- | --- |
| `--src <dir>` | `/code/src` | Directory containing bash source files. Passed to kcov `--bash-parse-files-in-dir` for static analysis. kcov reads this directory to build a list of all bash files so it can report 0% for files that were never executed. |
| `--include <paths>` | same as `--src` | Comma-separated paths whose *execution* to count. Passed to kcov `--include-path`. Restricts the coverage report to these paths only. Set this to a subdirectory of `--src` when you want to exclude generated or vendor files from the report while still parsing the full source tree. Defaults to the same value as `--src`. |
| `--output <dir>` | `/tmp/coverage` | kcov output directory |
| `--min-coverage <n>` | _(disabled)_ | Fail with exit code 2 when overall line coverage is below `<n>` percent (integer or decimal). Tests still run and the report is still printed. |

**Exit codes:**

| Code | Meaning |
| ---- | ------- |
| `0` | All tests passed (and coverage ≥ `--min-coverage` if set) |
| `1` | One or more bats tests failed |
| `2` | Coverage threshold not met (tests may have passed) |

### Integration with a build script

Drop-in replacement for the inline `docker build` pattern:

```bash
# Before: inline build adds bats + jq to kcov/kcov at build time.
_img=$(docker build --quiet - <<EOF
FROM kcov/kcov:v42
RUN apt-get update -qq && apt-get install -y bats jq \
    && rm -rf /var/lib/apt/lists/*
EOF
)
docker run --rm --cap-add SYS_PTRACE --security-opt seccomp=unconfined \
    -v "$PWD:/code:ro" -w /code "${_img}" bash -c 'kcov ... bats ...'

# After: use bats-coverage directly.
docker run --rm \
    --cap-add SYS_PTRACE \
    --security-opt seccomp=unconfined \
    -v "$PWD:/code:ro" \
    -w /code \
    1121citrus/bats-kcov \
    bats-coverage test/*.bats
```

### Direct kcov invocation

For full control over kcov flags, invoke kcov directly:

```sh
docker run --rm \
    --cap-add SYS_PTRACE \
    --security-opt seccomp=unconfined \
    -v "$PWD:/code:ro" \
    -w /code \
    1121citrus/bats-kcov \
    bash -euo pipefail -c '
        kcov --include-path=/code/src \
             --bash-parse-files-in-dir=/code/src \
             /tmp/coverage \
             bats test/01-unit.bats test/02-functional.bats
    '
```

## Build arguments

| Build arg | Default | Description |
| --- | --- | --- |
| `VERSION` | `dev` | Version in `BATS_KCOV_VERSION` and OCI `version` label |
| `GIT_COMMIT` | `unknown` | Git SHA in the OCI `revision` label |
| `BUILD_DATE` | `unknown` | Build timestamp in the OCI `created` label |

## Requirements

- **`SYS_PTRACE` capability** — kcov uses `ptrace(2)` to instrument processes.
  Pass `--cap-add SYS_PTRACE` to `docker run`.
- **`seccomp=unconfined`** — required on macOS Docker Desktop and many CI
  runners where the default seccomp profile blocks ptrace calls. Pass
  `--security-opt seccomp=unconfined` to `docker run`.
- **Linux kernel** — kcov relies on Linux-specific tracing APIs. The container
  must run on a Linux kernel (not natively on macOS or Windows host kernels).
  macOS Docker Desktop provides this via the Linux VM.

## Building

### Development build (local, not pushed)

```sh
./build
```

The `build` script runs linting (hadolint, shellcheck, markdownlint), builds
the image locally, runs bats tests, and scans with Trivy.
See `./build --help` for all flags.

### Production build (CI/CD)

See [`.github/CI-WORKFLOWS.md`](.github/CI-WORKFLOWS.md) for the full CI/CD
pipeline documentation.

## Attributions and provenance

| Component | Author | Source | License |
| --- | --- | --- | --- |
| [kcov](https://github.com/SimonKagstrom/kcov) | Simon Kagstrom | [SimonKagstrom/kcov](https://github.com/SimonKagstrom/kcov) | GPL-2.0 |
| [bats](https://github.com/bats-core/bats-core) | bats-core contributors | [bats-core/bats-core](https://github.com/bats-core/bats-core) | MIT |
| [jq](https://jqlang.github.io/jq/) | Stephen Dolan et al. | [jqlang/jq](https://github.com/jqlang/jq) | MIT |
| `bats-kcov` (this project) | James Hanlon | — | AGPL-3.0-or-later |

Published Docker images include an embedded **SBOM** (Software Bill of
Materials) in SPDX format and an **in-toto provenance attestation**
(`mode=max`). These can be inspected with:

```sh
# List attestations
docker buildx imagetools inspect 1121citrus/bats-kcov:latest

# Extract SBOM
docker scout sbom 1121citrus/bats-kcov:latest

# Scan for vulnerabilities
trivy image 1121citrus/bats-kcov:latest
```
