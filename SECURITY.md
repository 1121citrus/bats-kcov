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

`bats-kcov` uses a multi-stage build. Stage 1 pulls the kcov binary from
`kcov/kcov:latest-alpine` (Alpine 3.20); Stage 2 builds the runtime image
on `alpine:3.22` (a supported release), installing only the libraries
verified as kcov runtime dependencies via `ldd`. Packages present in the
kcov build stage but not needed at runtime — `python3`, `binutils`,
`binutils-dev`, and `sqlite-libs` — are not carried into the final image
and do not appear in scan results.

Both upstream image digests are pinned for reproducibility. Dependabot tracks
digest changes for both `kcov/kcov:latest-alpine` and `alpine:3.22` and will
open a PR when either is updated.

The Trivy gating scan (Stage 4) must pass with zero unfixed Critical/High
findings. Any new fixable findings must be remediated immediately by updating
the relevant pinned digest.

The Grype gating scan (Stage 4b) mirrors the Trivy policy: only Critical/High
findings block the build (`fail-on-severity: high`). CVEs with no fix
available in Alpine 3.22 are ignored via `.grype.yaml`. When a pinned digest
is updated, re-evaluate the ignore list and remove entries that are now fixed.

### Known unfixed CVEs (Alpine 3.22)

The following CVEs have no patch in Alpine 3.22 at the current pinned digest
and are listed in `.grype.yaml`. Remove each entry once the upstream Alpine
package publishes a fix and the digest is updated.

| Severity | CVE | Package | Reason |
| --- | --- | --- | --- |
| MEDIUM | CVE-2025-60876 | busybox 1.37.x | No fix in Alpine 3.22; required Alpine base layer |

### Updating pinned digests

When Dependabot (or manual inspection) signals that either upstream image
has been updated, pull the new image, retrieve its digest, and update the
corresponding `FROM` line in the `Dockerfile`:

```bash
# kcov binary source
docker pull kcov/kcov:latest-alpine
docker inspect kcov/kcov:latest-alpine --format '{{index .RepoDigests 0}}'

# Alpine runtime base
docker pull alpine:3.22
docker buildx imagetools inspect alpine:3.22 --format '{{.Manifest.Digest}}'
```

After updating either digest, rebuild, re-run tests, and re-evaluate the
`.grype.yaml` ignore list — entries for packages that are now fixed should
be removed.

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
