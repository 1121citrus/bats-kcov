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
    # The usage message is emitted when no positional args are given.
    # Verified via source inspection since jq may not be present in the
    # static-test container (bats/bats:1.13.0 does not include jq).
    run grep -F 'Usage: bats-coverage' "${SCRIPT}"
    [ "$status" -eq 0 ]
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
    # Verified via source inspection since jq may not be present in the
    # static-test container (bats/bats:1.13.0 does not include jq).
    run grep -F -- '--min-coverage <pct>' "${SCRIPT}"
    [ "$status" -eq 0 ]
}

@test "bats-coverage prints threshold-failure message to stderr" {
    # The failure message must name the actual and required percentages.
    run grep -F 'below required' "${SCRIPT}"
    [ "$status" -eq 0 ]
}

# ============================================================================
# Issue 4: input validation
# ============================================================================

@test "bats-coverage validates --src directory is readable" {
    run grep -F 'not readable' "${SCRIPT}"
    [ "$status" -eq 0 ]
}

@test "bats-coverage validates output parent directory is writable" {
    run grep -F 'not writable' "${SCRIPT}"
    [ "$status" -eq 0 ]
}

@test "bats-coverage validates --src before running kcov" {
    # The --src check must appear before the kcov invocation line.
    src_line=$(grep -n 'not readable' "${SCRIPT}" | head -1 | cut -d: -f1)
    kcov_line=$(grep -n '^kcov' "${SCRIPT}" | head -1 | cut -d: -f1)
    [ "${src_line}" -lt "${kcov_line}" ]
}

@test "bats-coverage rejects --min-coverage outside 0-100" {
    run grep -F '0 and 100' "${SCRIPT}"
    [ "$status" -eq 0 ]
}

# ============================================================================
# Issue 10: jq dependency guard
# ============================================================================

@test "bats-coverage checks for jq before use" {
    run grep -F 'command -v jq' "${SCRIPT}"
    [ "$status" -eq 0 ]
}

@test "bats-coverage exits 127 when jq is missing" {
    run grep -F 'exit 127' "${SCRIPT}"
    [ "$status" -eq 0 ]
}

@test "bats-coverage jq check occurs before option parsing" {
    jq_line=$(grep -n 'command -v jq' "${SCRIPT}" | head -1 | cut -d: -f1)
    while_line=$(grep -n '^while ' "${SCRIPT}" | head -1 | cut -d: -f1)
    [ "${jq_line}" -lt "${while_line}" ]
}

# ============================================================================
# Issue 5: hadolint must use failure-threshold: error
# ============================================================================

@test ".hadolint.yaml failure-threshold is set to error" {
    run grep -F 'failure-threshold: error' "${repo_root}/.hadolint.yaml"
    [ "$status" -eq 0 ]
}

# ============================================================================
# Issue 6: version.txt must match the latest CHANGELOG entry
# ============================================================================

@test "version.txt matches the latest version in CHANGELOG.md" {
    version=$(cat "${repo_root}/version.txt")
    # Extract the first version number from a '## [x.y.z]' heading.
    changelog_version=$(grep -oE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' \
        "${repo_root}/CHANGELOG.md" | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    [ "${version}" = "${changelog_version}" ]
}
