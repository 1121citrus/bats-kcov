# Security

## Threat model

`bats-kcov` is a CI build tool image. It is used exclusively during the test
and coverage measurement stages of a build pipeline — never deployed as a
runtime service.

Its trust boundary is: a short-lived container with read-only access to the
source tree under test. The primary security consideration is the elevated
capability required by kcov.

| Threat | Mitigation |
| --- | --- |
| Privilege escalation | `SYS_PTRACE` only in short-lived coverage runs |
| Base image CVEs | Documented below; image is a CI build tool, not runtime |
| Supply-chain compromise | SBOM + provenance; see supply-chain section |

## Required capabilities

kcov requires the `SYS_PTRACE` capability and `seccomp=unconfined` (on macOS
Docker Desktop and many CI runners) to instrument processes via `ptrace(2)`.

These permissions are scoped to the coverage measurement container only and
should not be applied to production workloads.

## Base image CVEs

`bats-kcov` is built on `kcov/kcov:latest-alpine` (Alpine 3.20), pinned by
digest for reproducibility. Alpine's rolling security model means packages are
current at build time; no long-lived won't-fix CVEs are carried forward.

The Trivy gating scan (Stage 4) must pass with zero unfixed Critical/High
findings. Any new fixable findings must be remediated immediately by updating
the pinned digest to the latest `latest-alpine` image.

The Grype gating scan (Stage 4b) mirrors the Trivy policy: only Critical/High
findings block the build (`fail-on-severity: high`), and CVEs with no fix
available in Alpine 3.20 are ignored via `.grype.yaml`. When the pinned digest
is updated, re-evaluate the ignore list and remove entries that are now fixed.

### Known unfixed CVEs (Alpine 3.20)

The following HIGH CVEs have no patch in Alpine 3.20 at the current pinned
digest and are suppressed in `.grype.yaml`.  Remove each entry once the
upstream Alpine package publishes a fix and the digest is updated.

| Severity | CVE | Package | Reason |
| --- | --- | --- | --- |
| HIGH | CVE-2025-69650 | binutils / binutils-dev 2.42-r1 | No fix in Alpine 3.20; required by kcov |
| HIGH | CVE-2025-69649 | binutils / binutils-dev 2.42-r1 | No fix in Alpine 3.20; required by kcov |
| HIGH | CVE-2025-5245 | binutils / binutils-dev 2.42-r1 | No fix in Alpine 3.20; required by kcov |
| HIGH | CVE-2025-5244 | binutils / binutils-dev 2.42-r1 | No fix in Alpine 3.20; required by kcov |
| HIGH | CVE-2024-53427 | jq 1.7.1-r0 | Fixed in Alpine 3.22 (jq 1.8.1); no 3.20 backport |
| HIGH | CVE-2025-48060 | jq 1.7.1-r0 | Fixed in Alpine 3.22 (jq 1.8.1); no 3.20 backport |
| HIGH | CVE-2026-3805 | curl ≤8.14.1-r2 | No fix in Alpine 3.20 at time of writing |
| HIGH | CVE-2025-31498 | c-ares ≤1.33.1-r0 | No fix in Alpine 3.20; curl dependency |
| CRITICAL | CVE-2025-3277 | sqlite-libs 3.45.3-r3 | No fix in Alpine 3.20 |
| HIGH | CVE-2025-70873 | sqlite-libs 3.45.3-r3 | No fix in Alpine 3.20 |
| HIGH | CVE-2026-27135 | nghttp2 ≤1.62.1-r0 | No fix in Alpine 3.20; curl dependency |
| HIGH | CVE-2025-13836 | python3 3.12.13-r0 | No fix in Alpine 3.20; kcov base image dependency |

### Updating the pinned digest

When Dependabot (or manual inspection) signals that `kcov/kcov:latest-alpine`
has been updated, pull the new image, retrieve its digest, and update the
`FROM` line in the `Dockerfile`:

```bash
docker pull kcov/kcov:latest-alpine
docker inspect kcov/kcov:latest-alpine --format '{{index .RepoDigests 0}}'
# Update the FROM line with the new digest, then rebuild and re-run tests.
```

## Docker hardening

When running a coverage measurement pass, apply the minimum required
permissions:

```yaml
docker run --rm \
    --cap-add SYS_PTRACE \
    --security-opt seccomp=unconfined \
    --read-only \
    --tmpfs /tmp \
    -v "$PWD/src:/code/src:ro" \
    1121citrus/bats-kcov \
    bash -c 'kcov ...'
```

## Supply-chain verification

Every image published to Docker Hub includes:

- An **SPDX SBOM** listing all OS packages.
- An **in-toto provenance attestation** (`mode=max`) that records the exact
  Dockerfile, build arguments, and source commit used.

Verify them with:

```sh
# Inspect attestations
docker buildx imagetools inspect 1121citrus/bats-kcov:latest

# Scan for known CVEs
trivy image 1121citrus/bats-kcov:latest
```

## Reporting vulnerabilities

Report security vulnerabilities through the
[GitHub Security tab](https://github.com/1121citrus/bats-kcov/security).
Do not open a public GitHub issue for security vulnerabilities.
