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

The Grype advisory (Stage 5a) is non-gating and reports all findings for
visibility. Alpine-based findings are expected to be minimal.

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
    -w /code \
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
