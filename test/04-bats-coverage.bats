#!/usr/bin/env bats

# test/04-bats-coverage.bats — static analysis of bin/bats-coverage.
#
# All tests are content-based (grep the script source) and do not require
# kcov, Docker, or a live image.  Tests verify structural invariants that
# protect against regressions in the bats-coverage script itself.
#
# Copyright (C) 2026 James Hanlon [mailto:jim@hanlonsoftware.com]
# SPDX-License-Identifier: AGPL-3.0-or-later

load "test_helper"

setup() {
    repo_root=$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)
    SCRIPT="${repo_root}/bin/bats-coverage"
}

# ============================================================================
# Basic structural checks
# ============================================================================

@test "bats-coverage script is executable" {
    [ -x "${SCRIPT}" ]
}

@test "bats-coverage uses set -euo pipefail" {
    run grep -F 'set -euo pipefail' "${SCRIPT}"
    [ "$status" -eq 0 ]
}

@test "bats-coverage prints usage when called with no arguments" {
    run "${SCRIPT}" 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage:"* ]]
}

# ============================================================================
# Issue 1: exit status must mirror bats test outcomes
# ============================================================================

@test "bats-coverage captures bats exit status into bats_rc" {
    run grep -F 'bats_rc' "${SCRIPT}"
    [ "$status" -eq 0 ]
}

@test "bats-coverage does not suppress kcov exit status with || true" {
    # '|| true' after the kcov invocation discards the exit code and must
    # not be present; the fix captures it into bats_rc instead.
    run grep -E '^\s*bats "\$@".*\|\| true' "${SCRIPT}"
    [ "$status" -ne 0 ]
}

@test "bats-coverage exits with bats_rc at end of script" {
    run grep -F 'exit "${bats_rc}"' "${SCRIPT}"
    [ "$status" -eq 0 ]
}

# ============================================================================
# Issue 2: coverage report must include an Overall summary line
# ============================================================================

@test "bats-coverage prints an Overall summary via jq" {
    # The second jq block must emit 'Overall: ...' — this is the structural
    # assertion that a coverage report summary is produced after each run.
    run grep -F '"Overall: "' "${SCRIPT}"
    [ "$status" -eq 0 ]
}

# ============================================================================
# Issue 3: --min-coverage threshold option
# ============================================================================

@test "bats-coverage accepts --min-coverage option" {
    run grep -F -- '--min-coverage)' "${SCRIPT}"
    [ "$status" -eq 0 ]
}

@test "bats-coverage exits 2 when coverage is below threshold (documented)" {
    run grep -F 'exit 2' "${SCRIPT}"
    [ "$status" -eq 0 ]
}

@test "bats-coverage --min-coverage is listed in usage output" {
    run "${SCRIPT}" 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"--min-coverage"* ]]
}

@test "bats-coverage prints threshold-failure message to stderr" {
    # The failure message must name the actual and required percentages.
    run grep -F 'below required' "${SCRIPT}"
    [ "$status" -eq 0 ]
}
