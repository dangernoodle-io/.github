#!/usr/bin/env bash
# Fails if any `uses:` pin in .github/workflows/** or .github/actions/** does
# not match the expected version declared below. Catches both drift between
# workflows (one bumped, another forgotten) and a repo that is uniformly
# outdated against upstream.
#
# - `uses: ./...` (local action refs) are skipped — they carry no version.
# - `uses: owner/repo/.github/workflows/x.yml@ref` (reusable workflow calls)
#   are skipped too: the org convention is to always call these at `@main`
#   (see README "Conventions"), so there is no version to pin/compare — a
#   drifted `@ref` there is a deliberate choice, not accidental staleness.
# - Every other `uses:` must have an entry in EXPECTED below. An action used
#   but missing from the table is a hard failure — add it deliberately so
#   the table can't silently go stale as new actions are adopted.
set -euo pipefail

declare -A EXPECTED=(
  ["actions/cache"]="v5"
  ["actions/checkout"]="v6"
  ["actions/download-artifact"]="v4"
  ["actions/github-script"]="v7"
  ["actions/setup-go"]="v6"
  ["actions/setup-java"]="v5"
  ["actions/setup-node"]="v4"
  ["actions/setup-python"]="v6"
  ["coverallsapp/github-action"]="v2"
  ["crazy-max/ghaction-import-gpg"]="v7"
  ["dorny/paths-filter"]="v3"
  ["golangci/golangci-lint-action"]="v9"
  ["goreleaser/goreleaser-action"]="v7"
  ["hashicorp/setup-terraform"]="v4"
  ["stCarolas/setup-maven"]="v5.1"
  ["webfactory/ssh-agent"]="v0.10.0"
)

fail=0

while IFS=: read -r file lineno rest; do
  # rest looks like: "      uses: owner/repo@ref" (optionally quoted)
  value="${rest#*uses:}"
  value="${value#"${value%%[![:space:]]*}"}"        # ltrim
  value="${value%%[[:space:]]#*}"                   # strip trailing comment (must be whitespace-preceded, per YAML)
  value="${value%"${value##*[![:space:]]}"}"        # rtrim
  value="${value%\"}"; value="${value#\"}"
  value="${value%\'}"; value="${value#\'}"

  if [[ "$value" == ./* ]]; then
    continue
  fi

  if [[ "$value" == */.github/workflows/*@* ]]; then
    continue
  fi

  name="${value%@*}"
  version="${value##*@}"

  expected="${EXPECTED[$name]:-}"
  if [ -z "$expected" ]; then
    echo "::error file=${file},line=${lineno}::assert-action-versions: '${name}' has no expected version in the EXPECTED table (.github/scripts/ci/assert-action-versions.sh) — add it deliberately"
    fail=1
    continue
  fi

  if [ "$version" != "$expected" ]; then
    echo "::error file=${file},line=${lineno}::assert-action-versions: ${name}@${version} does not match expected ${name}@${expected} — pin it to ${expected} (or update EXPECTED in .github/scripts/ci/assert-action-versions.sh if ${version} is now the intended version everywhere)"
    fail=1
  fi
done < <(grep -rnE '^\s*(-\s+)?uses:\s*\S+/\S+@\S+' .github/workflows .github/actions --include='*.yml')

exit $fail
