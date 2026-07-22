#!/usr/bin/env bats
# Fixture-driven tests for .github/scripts/ci/assert-action-versions.sh's
# `uses:` parsing, in particular trailing inline-comment handling.

setup() {
  SCRIPT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)/assert-action-versions.sh"
  WORKDIR="$(mktemp -d)"
  mkdir -p "${WORKDIR}/.github/workflows" "${WORKDIR}/.github/actions"
}

teardown() {
  rm -rf "${WORKDIR}"
}

@test "trailing inline comment after uses: is stripped before version comparison" {
  cat > "${WORKDIR}/.github/workflows/fixture.yml" <<'YAML'
jobs:
  example:
    steps:
      - uses: actions/checkout@v6  # pinned
YAML
  cd "${WORKDIR}"
  run "${SCRIPT}"
  [ "$status" -eq 0 ]
}

@test "trailing inline comment does not mask a real version mismatch" {
  cat > "${WORKDIR}/.github/workflows/fixture.yml" <<'YAML'
jobs:
  example:
    steps:
      - uses: actions/checkout@v5  # pinned
YAML
  cd "${WORKDIR}"
  run "${SCRIPT}"
  [ "$status" -ne 0 ]
  [[ "$output" == *"actions/checkout@v5 does not match expected actions/checkout@v6"* ]]
}

@test "quoted uses: with trailing inline comment is stripped before version comparison" {
  cat > "${WORKDIR}/.github/workflows/fixture.yml" <<'YAML'
jobs:
  example:
    steps:
      - uses: "actions/checkout@v6"  # pinned
YAML
  cd "${WORKDIR}"
  run "${SCRIPT}"
  [ "$status" -eq 0 ]
}

@test "hash with no whitespace boundary is part of the ref, not a comment" {
  cat > "${WORKDIR}/.github/workflows/fixture.yml" <<'YAML'
jobs:
  example:
    steps:
      - uses: actions/checkout@v6#extra
YAML
  cd "${WORKDIR}"
  run "${SCRIPT}"
  [ "$status" -ne 0 ]
  [[ "$output" == *"actions/checkout@v6#extra does not match expected actions/checkout@v6"* ]]
}

@test "tab-preceded hash is treated as a comment" {
  printf 'jobs:\n  example:\n    steps:\n      - uses: actions/checkout@v6\t# pinned\n' \
    > "${WORKDIR}/.github/workflows/fixture.yml"
  cd "${WORKDIR}"
  run "${SCRIPT}"
  [ "$status" -eq 0 ]
}
