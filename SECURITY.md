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

`bats-kcov` is built on `kcov/kcov:v42`, a Debian 11 (bullseye) image.
Debian 11 reached end-of-life in June 2024; many of its package versions will
never receive backported fixes. These CVEs are accepted because:

- The image is a build tool, not a production runtime.
- It runs in an isolated, short-lived container during CI.
- It has no inbound network exposure.
- It is in the same trust category as other CI tool images
  (shellcheck, hadolint, bats/bats).

The Trivy scan stage (Stage 4) passes because it runs with `--ignore-unfixed`.
The Grype advisory (Stage 5a) reports all findings including won't-fix items
for visibility; the entries below are the known Critical/High won't-fix CVEs
as of April 2026.

Any new fixable Critical/High findings that appear in the Trivy gating scan
must be remediated immediately.

### Known unfixable Critical/High CVEs (Debian 11 won't-fix)

All entries below carry `(won't fix)` in Debian's security tracker — they
cannot be resolved without replacing `kcov/kcov:v42` with a Debian 12+
base image, which upstream kcov does not currently provide.

| Package | Version | CVE | Severity | Description |
| --- | --- | --- | --- | --- |
| `libcurl4` | 7.74.0-1.3+deb11u16 | CVE-2023-23914 | **Critical** | curl HSTS bypass via cleartext redirect |
| `libdb5.3` | 5.3.28+dfsg1-0.8 | CVE-2019-8457 | **Critical** | Berkeley DB heap out-of-bounds read via crafted SQL |
| `zlib1g` | 1:1.2.11.dfsg-2+deb11u2 | CVE-2023-45853 | **Critical** | zlib integer overflow in MiniZip minizip/zip.c |
| `bash` | 5.1-2+deb11u1 | CVE-2022-3715 | High | bash heap buffer overflow in parameter transformation |
| `dpkg` | 1.20.13 | CVE-2025-6297 | High | dpkg arbitrary file overwrite via crafted package |
| `libc-bin`, `libc6` | 2.31-13+deb11u13 | CVE-2025-15281 | High | glibc buffer overflow in nscd |
| `libc-bin`, `libc6` | 2.31-13+deb11u13 | CVE-2026-0861 | High | glibc use-after-free in getaddrinfo |
| `libc-bin`, `libc6` | 2.31-13+deb11u13 | CVE-2026-0915 | High | glibc stack overflow in iconv conversion |
| `libcurl4` | 7.74.0-1.3+deb11u16 | CVE-2022-43551 | High | curl HSTS bypass with multiple redirects |
| `libcurl4` | 7.74.0-1.3+deb11u16 | CVE-2022-42916 | High | curl HSTS bypass via IDN host name |
| `libgcrypt20` | 1.8.7-6 | CVE-2021-33560 | High | ElGamal encryption side-channel (Manger attack) |
| `libldap-2.4-2` | 2.4.57+dfsg-3+deb11u1 | CVE-2023-2953 | High | OpenLDAP slapd null pointer dereference |
| `libldap-common` | 2.4.57+dfsg-3+deb11u1 | CVE-2023-2953 | High | OpenLDAP slapd null pointer dereference |
| `libtasn1-6` | 4.16.0-2+deb11u2 | CVE-2025-13151 | High | libtasn1 heap buffer overflow |
| `libzstd1` | 1.4.8+dfsg-2.1 | CVE-2022-4899 | High | zstd null pointer dereference via crafted input |

### Remediation path

The only path to resolving the above CVEs is a base-image upgrade.  Monitor
the [kcov releases page](https://github.com/SimonKagstrom/kcov/releases) for
a Debian 12 (bookworm) or Alpine-based image.  When available, update the
`FROM` line and remove this table.

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
