# syntax=docker/dockerfile:1

# bats-kcov — kcov code-coverage collector pre-bundled with bats and jq.
# Intended for measuring bash/shell test coverage in CI pipelines.
# Copyright (C) 2026 James Hanlon [mailto:jim@hanlonsoftware.com]
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Stage 1: extract kcov binaries from the upstream image.
# python3, binutils, binutils-dev, and sqlite-libs are present in this image
# for kcov's build environment but are not runtime dependencies of the kcov
# binary itself (verified via ldd). They are not copied to the runtime stage.
# checkov:skip=CKV_DOCKER_7: pinned by digest — tag retained for readability
FROM kcov/kcov:latest-alpine@sha256:6e6f3f62461100d789ae5b91e0534b65ff1b88f47564ee8edc845096835cd99f AS kcov-src

# Stage 2: runtime image on a supported Alpine release.
# Only the libraries actually required by the kcov binary (per ldd) are
# installed, plus bats and jq. Dependabot tracks digest changes for both
# the kcov/kcov:latest-alpine and alpine:3.24 tags.
# checkov:skip=CKV_DOCKER_7: pinned by digest — tag retained for readability
FROM alpine:3.24@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b

ARG VERSION=dev
ENV BATS_KCOV_VERSION=${VERSION}

ARG GIT_COMMIT=unknown
ARG BUILD_DATE=unknown

# OCI image annotation labels (https://github.com/opencontainers/image-spec/blob/main/annotations.md).
# These are embedded in the image manifest and surfaced by 'docker inspect',
# 'docker scout', and supply-chain tooling (Syft, Grype, cosign, etc.).
LABEL org.opencontainers.image.title="bats-kcov" \
      org.opencontainers.image.description="kcov code-coverage collector pre-bundled with bats and jq for measuring bash test coverage." \
      org.opencontainers.image.url="https://github.com/1121citrus/bats-kcov" \
      org.opencontainers.image.source="https://github.com/1121citrus/bats-kcov" \
      org.opencontainers.image.licenses="AGPL-3.0-or-later" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.created="${BUILD_DATE}"

# DL3017: upgrade is intentional — applies Alpine security patches that
# postdate the pinned base image digest; remove when upstream republishes.
# DL3018: version pinning omitted; versions are managed via digest pin.
#
# Alpine 3.24 has not yet published its musl CVE-2026-107891 (High) fix.
# Pin only the patched musl 1.2.6-r6 packages (musl and musl-utils, both
# present in the base image) from edge; nothing else is taken from edge.
# Remove this edge pin once Alpine 3.24 ships musl 1.2.6-r6 in its stable
# repository.  The edge install is retried (3 attempts, 15 s apart) so a
# single transient CDN/TLS failure does not fail the build; the build still
# fails if every attempt fails or the wrong musl ends up installed.
SHELL ["/bin/ash", "-o", "errexit", "-o", "pipefail", "-c"]
# hadolint ignore=DL3017,DL3018
RUN apk upgrade --no-cache \
    && apk add --no-cache \
        bats \
        brotli-libs \
        bzip2 \
        c-ares \
        elfutils \
        jq \
        libcurl \
        libgcc \
        libidn2 \
        libpsl \
        libstdc++ \
        libunistring \
        musl-fts \
        nghttp2-libs \
        openssl \
        xz-libs \
        zlib \
        zstd-libs \
    && for attempt in 1 2 3; do \
           apk add --no-cache \
               --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main \
               "musl=1.2.6-r6" "musl-utils=1.2.6-r6" \
           && break; \
           [ "${attempt}" -lt 3 ] || exit 1; \
           echo "edge musl install failed (attempt ${attempt}/3)" >&2; \
           sleep 15; \
       done \
    && apk info -v --installed musl | grep -qxF 'musl-1.2.6-r6'

COPY --from=kcov-src /usr/local/bin/kcov /usr/local/bin/kcov
COPY --from=kcov-src /usr/local/bin/kcov-system-daemon \
    /usr/local/bin/kcov-system-daemon

WORKDIR /code

COPY --chmod=755 bin/bats-coverage /usr/local/bin/bats-coverage

ENTRYPOINT []
CMD ["/bin/bash"]
