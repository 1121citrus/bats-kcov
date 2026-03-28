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

`bats-kcov` is built on `kcov/kcov`, a Debian-based image. Debian system
packages may contain CVEs with no available fix. These are accepted because:

- The image is a build tool, not a production runtime.
- It runs in an isolated, short-lived container during CI.
- It has no inbound network exposure.
- It is in the same trust category as other CI tool images
  (shellcheck, hadolint, bats/bats).

Any Trivy findings against this image that block the scan stage represent newly
fixable CVEs that should be remediated. See `SECURITY.md` in the active release
for the current known-unfixed inventory.

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
