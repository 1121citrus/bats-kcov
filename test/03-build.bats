#!/usr/bin/env bats

# test/03-build.bats — tests for the build script.
# Validates option parsing, stage control, caching, and dry-run mode.
#
# Copyright (C) 2026 James Hanlon [mailto:jim@hanlonsoftware.com]
# SPDX-License-Identifier: AGPL-3.0-or-later

setup() {
    export BUILD_SCRIPT="${BATS_TEST_DIRNAME}/../build"
}

# ============================================================================
# CLI option parsing tests
# ============================================================================

@test "build --help outputs usage information" {
    run "${BUILD_SCRIPT}" --help
    [[ $status -eq 0 ]]
    [[ "$output" == *"SYNOPSIS"* ]]
    [[ "$output" == *"--advise"* ]]
    [[ "$output" == *"--cache"* ]]
}

@test "build rejects unknown options" {
    run "${BUILD_SCRIPT}" --unknown-option 2>&1
    [[ $status -eq 1 ]]
    [[ "$output" == *"Unknown option"* ]]
}

@test "build --version requires an argument" {
    run "${BUILD_SCRIPT}" --version 2>&1
    [[ $status -eq 1 ]]
}

@test "build --platform requires an argument" {
    run "${BUILD_SCRIPT}" --platform 2>&1
    [[ $status -eq 1 ]]
}

@test "build --registry requires an argument" {
    run "${BUILD_SCRIPT}" --registry 2>&1
    [[ $status -eq 1 ]]
}

@test "build --cache requires CACHE_RULES argument" {
    run "${BUILD_SCRIPT}" --cache 2>&1
    [[ $status -eq 1 ]]
    [[ "$output" == *"--cache requires CACHE_RULES"* ]]
}

@test "build --cache rejects argument starting with --" {
    run "${BUILD_SCRIPT}" --cache --advise 2>&1
    [[ $status -eq 1 ]]
    [[ "$output" == *"--cache requires CACHE_RULES"* ]]
}

# ============================================================================
# Advisement option parsing tests
# ============================================================================

@test "build --advise scout enables Scout" {
    run "${BUILD_SCRIPT}" \
        --advise scout --dry-run --no-lint --no-test --no-scan 2>&1
    [[ $status -eq 0 ]]
    [[ "$output" == *"Stage 5b: Advise (Scout)"* ]]
}

@test "build --advise dive enables Dive" {
    run "${BUILD_SCRIPT}" \
        --advise dive --dry-run --no-lint --no-test --no-scan 2>&1
    [[ $status -eq 0 ]]
    [[ "$output" == *"Stage 5c: Advise (Dive)"* ]]
}

@test "build --advise all enables Grype, Scout, and Dive" {
    run "${BUILD_SCRIPT}" \
        --advise all --dry-run --no-lint --no-test --no-scan 2>&1
    [[ $status -eq 0 ]]
    [[ "$output" == *"Stage 5a: Advise (Grype)"* ]]
    [[ "$output" == *"Stage 5b: Advise (Scout)"* ]]
    [[ "$output" == *"Stage 5c: Advise (Dive)"* ]]
}

@test "build --no-advise disables all advisements" {
    run "${BUILD_SCRIPT}" \
        --no-advise --dry-run --no-lint --no-test --no-scan 2>&1
    [[ $status -eq 0 ]]
    [[ "$output" != *"Stage 5a"* ]]
    [[ "$output" != *"Stage 5b"* ]]
    [[ "$output" != *"Stage 5c"* ]]
}

@test "build --no-scan suppresses advisements by default" {
    run "${BUILD_SCRIPT}" \
        --no-scan --dry-run --no-lint --no-test 2>&1
    [[ $status -eq 0 ]]
    [[ "$output" != *"Stage 5a"* ]]
    [[ "$output" != *"Stage 5b"* ]]
    [[ "$output" != *"Stage 5c"* ]]
}

@test "build --no-scan with explicit --advise keeps advisements" {
    run "${BUILD_SCRIPT}" \
        --no-scan --advise grype --dry-run --no-lint --no-test 2>&1
    [[ $status -eq 0 ]]
    [[ "$output" == *"Stage 5a: Advise (Grype)"* ]]
}

@test "build --advice is accepted as a synonym for --advise" {
    run "${BUILD_SCRIPT}" \
        --advice dive --dry-run --no-lint --no-test --no-scan 2>&1
    [[ $status -eq 0 ]]
    [[ "$output" == *"Stage 5c: Advise (Dive)"* ]]
}

@test "build --advise rejects unknown advisement name" {
    run "${BUILD_SCRIPT}" --advise unknown 2>&1
    [[ $status -eq 1 ]]
    [[ "$output" == *"Unknown advisement"* ]]
}

# ============================================================================
# Cache control tests
# ============================================================================

@test "build --cache reset=all resets both caches" {
    run "${BUILD_SCRIPT}" \
        --cache 'reset=all' --dry-run --no-lint --no-test --no-scan 2>&1
    [[ $status -eq 0 ]]
    [[ "$output" == *"Cache: reset Trivy DB"* ]]
    [[ "$output" == *"Cache: reset Grype DB"* ]]
}

@test "build --cache rejects invalid rule format" {
    run "${BUILD_SCRIPT}" --cache 'notakey' 2>&1
    [[ $status -eq 1 ]]
}

@test "build --cache rejects unknown rule key" {
    run "${BUILD_SCRIPT}" --cache 'unknown=trivy' 2>&1
    [[ $status -eq 1 ]]
    [[ "$output" == *"Unknown --cache rule key"* ]]
}

@test "build --cache rejects unknown cache target" {
    run "${BUILD_SCRIPT}" --cache 'reset=badtarget' 2>&1
    [[ $status -eq 1 ]]
    [[ "$output" == *"Unknown cache target"* ]]
}

# ============================================================================
# Dry-run mode tests
# ============================================================================

@test "build --dry-run prints DRY RUN prefix" {
    run "${BUILD_SCRIPT}" --dry-run --no-lint --no-test --no-scan 2>&1
    [[ $status -eq 0 ]]
    [[ "$output" == *"[DRY RUN]"* ]]
}

@test "build --dry-run prints build command" {
    run "${BUILD_SCRIPT}" --dry-run --no-lint --no-test --no-scan 2>&1
    [[ $status -eq 0 ]]
    [[ "$output" == *"Stage 2: Build"* ]]
}

@test "build --dry-run passes KCOV_TAG build-arg" {
    run "${BUILD_SCRIPT}" --dry-run --no-lint --no-test --no-scan 2>&1
    [[ $status -eq 0 ]]
    [[ "$output" == *"KCOV_TAG="* ]]
}

@test "build --kcov-tag overrides default KCOV_TAG" {
    run "${BUILD_SCRIPT}" --kcov-tag v42 --dry-run --no-lint --no-test --no-scan 2>&1
    [[ $status -eq 0 ]]
    [[ "$output" == *"KCOV_TAG=v42"* ]]
}

@test "build --dry-run with --no-smoke skips smoke stage" {
    run "${BUILD_SCRIPT}" \
        --dry-run --no-lint --no-test --no-smoke --no-scan 2>&1
    [[ $status -eq 0 ]]
    [[ "$output" != *"Stage 3b: Smoke"* ]]
}

@test "build --dry-run prints Stage 3c: Coverage" {
    run "${BUILD_SCRIPT}" \
        --dry-run --no-lint --no-smoke --no-scan 2>&1
    [[ $status -eq 0 ]]
    [[ "$output" == *"Stage 3c: Coverage"* ]]
}

@test "build --no-coverage skips coverage stage" {
    run "${BUILD_SCRIPT}" \
        --no-coverage --dry-run --no-lint --no-smoke --no-scan 2>&1
    [[ $status -eq 0 ]]
    [[ "$output" != *"Stage 3c: Coverage"* ]]
}

@test "build --no-test also skips coverage stage" {
    run "${BUILD_SCRIPT}" \
        --no-test --dry-run --no-lint --no-smoke --no-scan 2>&1
    [[ $status -eq 0 ]]
    [[ "$output" != *"Stage 3c: Coverage"* ]]
}
