# test — bats-kcov test suite

[Bats](https://github.com/bats-core/bats-core) tests for `bats-kcov`.
The `build` script runs the suite inside the official `bats/bats:1.13.0`
container so no local bats installation is required.

## Running

```sh
# Via the build script (recommended — same environment as CI):
./build

# Skip all other stages and run only tests:
./build --no-lint --no-scan

# Directly with a local bats installation:
bats test/01-dockerfile.bats test/02-image-metadata.bats test/03-build.bats
```

## Files

| File | Description |
| --- | --- |
| `01-dockerfile.bats` | Static checks on `Dockerfile` and `README.md` content |
| `02-image-metadata.bats` | OCI label and build-arg wiring checks |
| `03-build.bats` | `build` option parsing and stage-control tests |
| `test_helper.bash` | Minimal bats helper sourced by all test files |

## Test files

### 01-dockerfile.bats

Static assertions that verify the `Dockerfile` and `README.md` contain the
expected content.

| Test | What it checks |
| --- | --- |
| `Dockerfile installs packages with apk` | `apk add` is used to install packages |
| `Dockerfile installs bats` | `bats` is listed in the `apk add` block |
| `Dockerfile installs jq` | `jq` is listed in the `apk add` block |
| `Dockerfile uses apk --no-cache flag` | `--no-cache` eliminates the need for cache cleanup |
| `Dockerfile sets WORKDIR to /code` | `WORKDIR /code` sets the default working directory |
| `ENTRYPOINT is reset to empty` | `ENTRYPOINT []` allows arbitrary commands |
| `CMD defaults to /bin/bash` | `CMD ["/bin/bash"]` sets the default |
| `README documents SYS_PTRACE` | `SYS_PTRACE` appears in `README.md` |

### 02-image-metadata.bats

OCI metadata assertions verified via static Dockerfile analysis.

| Test | What it checks |
| --- | --- |
| `Dockerfile declares ARG VERSION` | `ARG VERSION=` is declared |
| `Dockerfile declares ARG GIT_COMMIT` | `ARG GIT_COMMIT=` is declared |
| `Dockerfile declares ARG BUILD_DATE` | `ARG BUILD_DATE=` is declared |
| `Dockerfile has LABEL org.opencontainers.image.title` | `title` label exists |
| `LABEL org.opencontainers.image.description` | `description` label exists |
| `Dockerfile has LABEL org.opencontainers.image.url` | `url` label is present |
| `LABEL org.opencontainers.image.source` | `source` label exists |
| `LABEL org.opencontainers.image.licenses` | `licenses` label exists |
| `version label uses VERSION` | Uses `"${VERSION}"` as label value |
| `revision label uses GIT_COMMIT` | Uses `"${GIT_COMMIT}"` as label value |
| `created label uses BUILD_DATE` | Uses `"${BUILD_DATE}"` as label value |

### 03-build.bats

Tests for the `build` script itself. Validates argument parsing, stage control,
cache rules, and dry-run mode.

| Test | What it checks |
| --- | --- |
| `build --help shows usage` | `--help` exits 0 and prints `SYNOPSIS` |
| `build rejects unknown options` | Unknown flags exit 1 with "Unknown option" |
| `build --version requires an argument` | Missing argument exits non-zero |
| `build --platform requires an argument` | Missing argument exits non-zero |
| `build --registry requires an argument` | Missing argument exits non-zero |
| `build --cache requires CACHE_RULES argument` | Missing argument exits 1 |
| `build --cache rejects --* argument` | Rejects flag-like argument |
| `build --advise scout enables Scout` | Stage 5b is printed in dry-run output |
| `build --advise dive enables Dive` | Stage 5c is printed in dry-run output |
| `build --advise all enables all` | Shows all advisory stages |
| `build --no-advise disables all advisements` | No stage 5 output |
| `build --no-scan suppresses advisements` | Advisements off when scan is off |
| `--no-scan + --advise keeps advisements` | `--advise` overrides `--no-scan` |
| `build --advice is accepted as a synonym for --advise` | Alias works |
| `build --advise rejects unknown advisement name` | Unknown name exits 1 |
| `build --cache reset=all resets caches` | Both cache reset messages appear |
| `build --cache rejects invalid rule format` | Malformed rule exits non-zero |
| `build --cache rejects unknown rule key` | Bad key exits 1 |
| `build --cache rejects unknown cache target` | Bad target exits 1 |
| `build --dry-run prints DRY RUN prefix` | `[DRY RUN]` appears in output |
| `build --dry-run prints build command` | Stage 2 is printed |
| `build --dry-run --no-smoke skips smoke` | Stage 3b does not appear |

## Quick start

```sh
# Run all tests through the build script (recommended):
./build --no-lint --no-scan

# Run only Dockerfile and metadata tests with a local bats installation:
bats test/01-dockerfile.bats test/02-image-metadata.bats
```
