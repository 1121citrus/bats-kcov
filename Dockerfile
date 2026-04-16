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

# Pin to the latest stable release so Dependabot can track base-image updates.
# Note: kcov/kcov:latest currently tracks a pre-release; v42 is the most
# recent stable tag.
FROM kcov/kcov:v42

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

# Apply OS security patches to fix upstream CVEs in the kcov/kcov base image.
# DL3005: apt-get upgrade is intentional — the base image is not rebuilt
# frequently enough to stay current with security patches.
# hadolint ignore=DL3005,DL3008
RUN apt-get update -qq \
        && apt-get upgrade -y --no-install-recommends \
        && apt-get install -y --no-install-recommends \
            bats \
            jq \
        && rm -rf /var/lib/apt/lists/*

COPY --chmod=755 bin/bats-coverage /usr/local/bin/bats-coverage

ENTRYPOINT []
CMD ["/bin/bash"]
