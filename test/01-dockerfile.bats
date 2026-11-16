#!/usr/bin/env bats

# test/01-dockerfile.bats — static checks on Dockerfile and README content.
#
# Copyright (C) 2026 James Hanlon [mailto:jim@hanlonsoftware.com]
# SPDX-License-Identifier: AGPL-3.0-or-later

load "test_helper"

setup() {
    repo_root=$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)
    DOCKERFILE="${repo_root}/Dockerfile"
}

@test "Dockerfile installs packages with apk" {
    run grep -F "apk add" "${DOCKERFILE}"
    [ "$status" -eq 0 ]
}

@test "Dockerfile installs bats" {
    run grep -F "bats" "${DOCKERFILE}"
    [ "$status" -eq 0 ]
}

@test "Dockerfile installs jq" {
    run grep -F "jq" "${DOCKERFILE}"
    [ "$status" -eq 0 ]
}

@test "Dockerfile uses apk --no-cache flag" {
    run grep -F "apk add --no-cache" "${DOCKERFILE}"
    [ "$status" -eq 0 ]
}

@test "Dockerfile sets WORKDIR to /code" {
    run grep -F 'WORKDIR /code' "${DOCKERFILE}"
    [ "$status" -eq 0 ]
}

@test "Dockerfile resets ENTRYPOINT to empty" {
    run grep -F 'ENTRYPOINT []' "${DOCKERFILE}"
    [ "$status" -eq 0 ]
}

@test "Dockerfile sets CMD to /bin/bash" {
    run grep -F 'CMD ["/bin/bash"]' "${DOCKERFILE}"
    [ "$status" -eq 0 ]
}

@test "Dockerfile uses kcov/kcov as build stage source" {
    run grep -E 'FROM kcov/kcov' "${DOCKERFILE}"
    [ "$status" -eq 0 ]
}

@test "Dockerfile copies bats-coverage to /usr/local/bin" {
    run grep -F 'bin/bats-coverage /usr/local/bin/bats-coverage' "${DOCKERFILE}"
    [ "$status" -eq 0 ]
}

@test "README documents SYS_PTRACE requirement" {
    run grep -F "SYS_PTRACE" "${repo_root}/README.md"
    [ "$status" -eq 0 ]
}

@test "Dockerfile pins patched musl packages from Alpine edge" {
    run grep -F -- '--repository=https://dl-cdn.alpinelinux.org/alpine/edge/main' "${DOCKERFILE}"
    [ "$status" -eq 0 ]
    run grep -F '"musl=1.2.6-r6" "musl-utils=1.2.6-r6"' "${DOCKERFILE}"
    [ "$status" -eq 0 ]
}

@test "Dockerfile pulls only musl packages from Alpine edge" {
    run grep -c -F -- '--repository=https://dl-cdn.alpinelinux.org/alpine/edge' "${DOCKERFILE}"
    [ "$output" -eq 1 ]
    run grep -F -A 1 -- '--repository=https://dl-cdn.alpinelinux.org/alpine/edge/main' "${DOCKERFILE}"
    [ "$status" -eq 0 ]
    [[ "${lines[1]}" =~ ^[[:space:]]*\"musl=1\.2\.6-r6\"\ \"musl-utils=1\.2\.6-r6\"\ \\$ ]]
}

@test "Dockerfile retries the edge musl install a bounded number of times" {
    run grep -F 'for attempt in 1 2 3; do' "${DOCKERFILE}"
    [ "$status" -eq 0 ]
    run grep -F '[ "${attempt}" -lt 3 ] || exit 1' "${DOCKERFILE}"
    [ "$status" -eq 0 ]
    run grep -F 'sleep 15' "${DOCKERFILE}"
    [ "$status" -eq 0 ]
}

@test "Dockerfile verifies installed musl version" {
    run grep -F "apk info -v --installed musl | grep -qxF 'musl-1.2.6-r6'" \
        "${DOCKERFILE}"
    [ "$status" -eq 0 ]
}

@test "Dockerfile enables pipefail before the musl version check" {
    run grep -F 'SHELL ["/bin/ash", "-o", "errexit", "-o", "pipefail", "-c"]' \
        "${DOCKERFILE}"
    [ "$status" -eq 0 ]
}

@test "Dockerfile documents removing the edge musl pin" {
    run grep -F 'Remove this edge pin once Alpine 3.24 ships musl 1.2.6-r6' \
        "${DOCKERFILE}"
    [ "$status" -eq 0 ]
}
