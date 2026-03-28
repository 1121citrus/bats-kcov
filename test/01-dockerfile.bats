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

@test "Dockerfile runs apt-get update" {
    run grep -F "apt-get update" "${DOCKERFILE}"
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

@test "Dockerfile cleans apt cache" {
    run grep -F "rm -rf /var/lib/apt/lists/*" "${DOCKERFILE}"
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

@test "Dockerfile installs kcov" {
    run grep -F "kcov" "${DOCKERFILE}"
    [ "$status" -eq 0 ]
}

@test "README documents SYS_PTRACE requirement" {
    run grep -F "SYS_PTRACE" "${repo_root}/README.md"
    [ "$status" -eq 0 ]
}
