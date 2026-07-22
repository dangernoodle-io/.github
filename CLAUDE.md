# dangernoodle-github

Central repository for reusable GitHub Actions workflows in the dangernoodle org.

## Purpose

Hosts shared workflows consumed via `workflow_call` from other repos.

## Workflows

`.github/workflows/ci.yml` is this repo's own (non-reusable) CI: runs `ci-result-gate`'s bats
tests, `actionlint` (workflows only), `shellcheck` (every `*.sh` under `.github/`),
`action-versions` (`uses:` pin consistency), then gates on itself via the local (`./`) action.

### `.github/scripts/ci/actionlint.sh`

Runs a pinned, checksum-verified `actionlint` against `.github/workflows/`.

### `.github/scripts/ci/shellcheck-all.sh`

Globs every `*.sh` under `.github/` (composite-action scripts — `gate.sh`, `update.sh` — plus
the CI scripts themselves) and runs `shellcheck -x -S info`. shellcheck is preinstalled on the
`ubuntu-latest` runner; no explicit install needed.

### `.github/scripts/ci/assert-action-versions.sh`

Hard-fails on any `uses:` pin (across `.github/workflows/**` and `.github/actions/**`) that
doesn't match the `EXPECTED` table declared at the top of the script (bump a pin there) —
catches both cross-file drift and a uniformly-outdated repo. `./` local refs and
reusable-workflow calls (`owner/repo/.github/workflows/x.yml@ref`, always called at `@main` per
convention) are exempt; every other action must have a table entry or the run fails.

### `.github/workflows/maven.yml`

Reusable Maven CI/CD workflow. Key inputs:

| Input | Default | Notes |
|---|---|---|
| `maven-goals` | *(required)* | e.g. `verify`, `deploy` |
| `maven-version` | `3.9.9` | |
| `maven-args` | `''` | Extra flags |
| `enable-coveralls` | `true` | Code coverage reporting |
| `release` | `false` | Enables GPG signing + Maven Central publish |

**Release mode** requires org secrets:
- `BUILD_BOT_GPG_PRIVATE_KEY` / `BUILD_BOT_GPG_PASSPHRASE` — signs commits/tags
- `BUILD_BOT_SSH_PRIVATE_KEY` — pushes release commits
- `BUILD_BOT_CENTRAL_USER` / `BUILD_BOT_CENTRAL_TOKEN` — Maven Central publish

Runtime: Java 21 (Temurin), Ubuntu latest.

### `.github/workflows/terraform-provider-test.yml`

Reusable Terraform provider CI workflow. Runs build, lint, generate diff check, and
acceptance tests across Terraform 1.8–1.14. Matrix floor is 1.8 (provider functions
support). Coverage uploaded to Coveralls on 1.14 only.

| Input | Default | Notes |
|---|---|---|
| `enable-coveralls` | `true` | Set `false` for repos not using Coveralls |

### `.github/workflows/go-build.yml`

Reusable Go CI workflow. Runs build, lint (golangci-lint), and tests with coverage. Single `verify` job.

| Input | Default | Notes |
|---|---|---|
| `enable-coveralls` | `true` | Set `false` for repos not using Coveralls |

### `.github/workflows/go-release.yml`

Reusable Go release workflow. Runs GoReleaser with GPG signing. Each calling repo provides its own `.goreleaser.yml`.

| Input | Default | Notes |
|---|---|---|
| `homebrew` | `false` | Publish Homebrew formula to tap repo |
| `marketplace` | `false` | Update dangernoodle-marketplace ref after release |
| `plugin-name` | `''` | Plugin name in marketplace.json (required when marketplace=true) |

Requires org secrets: `BUILD_BOT_GPG_PRIVATE_KEY`, `BUILD_BOT_GPG_PASSPHRASE`. When using marketplace mode, also requires `BUILD_BOT_SSH_PRIVATE_KEY`.

### `.github/workflows/pio-test.yml`

Reusable PlatformIO test workflow. Runs cppcheck + `pio test` + gcovr coverage with Coveralls upload. Caches pip (`~/.cache/pip`), PlatformIO toolchains (`~/.platformio`), and per-project libdeps (`**/.pio/libdeps`) so cJSON / Unity / framework downloads are reused across runs. Calling repo must provide a `Makefile` with `check` and `coverage` targets producing `gcovr-coveralls.json`.

| Input | Default | Notes |
|---|---|---|
| `cppcheck-apt-install` | `false` | Set true for repos without cppcheck bundled |
| `pre-build-script` | `''` | Shell to run before `make coverage` (e.g., webui build) |
| `libdeps-cache-key-paths` | `**/platformio.ini` | Glob(s) hashed for libdeps cache invalidation |
| `enable-coveralls` | `true` | Coveralls upload |

### `.github/workflows/plugin-test.yml`

Reusable Claude Code plugin test workflow. Runs `tests/run.sh` inside the plugin directory using Node.js built-in `node:test` runner. Zero npm deps required.

| Input | Default | Notes |
|---|---|---|
| `node-version` | `'24'` | Node.js version for test runner |
| `plugin-path` | `'plugin'` | Path to plugin directory (must contain `tests/run.sh`) |

### `.github/workflows/gh-release.yml`

Reusable release workflow that materializes `.github/release.yml` at runtime before invoking `gh release create --generate-notes`. Centralized config — consuming repos no longer need their own copy.

Release notes categories: New Components, New APIs, Fixes, Performance, Refactors, Documentation, Tests, Build, Other Changes.

### `.github/workflows/auto-label-conventional.yml`

Reusable workflow that auto-labels PRs by conventional-commit type in the title. Labels all standard types: `feat(new-component)` → new-component; `feat` → enhancement; `fix` → bug; `docs` → documentation; `refactor` → refactor; `perf` → performance; `test` → test; `chore` → chore; `build` → build; `ci` → ci; `style` → style; `revert` → revert.

### `.github/workflows/path-changes.yml`

Reusable `workflow_call` workflow that runs `dorny/paths-filter@v3` with a caller-supplied filters YAML and exposes the matched filter names as a JSON array. Intended to be called only on `pull_request` events; consumers gate downstream jobs with `contains(fromJSON(needs.<job>.outputs.changes), '<name>')`.

| Input/Output | Direction | Required/Default | Notes |
|---|---|---|---|
| `filters` | input | required | `dorny/paths-filter` filters YAML |
| `changes` | output | — | JSON array of filter names that matched changed files |

## Composite Actions

### `.github/actions/marketplace-update`

Composite action to update the dangernoodle-marketplace manifest with a new plugin ref and push a signed commit.

| Input | Required | Notes |
|---|---|---|
| `plugin-name` | yes | Name matching an entry in `.claude-plugin/marketplace.json` |
| `ref` | yes | Git tag/ref to set (e.g. `v0.3.1`) |
| `ssh-private-key` | yes | SSH private key for marketplace repo access |
| `gpg-private-key` | yes | GPG private key for signing commits |
| `gpg-passphrase` | yes | GPG passphrase for unlocking the private key |

Clones `dangernoodle-marketplace`, uses `jq` to update `.claude-plugin/marketplace.json` with the new ref, commits with GPG signing, and pushes to origin/main. Designed to be called from `go-release.yml` post-release.

### `.github/actions/ci-result-gate`

Composite action that fails unless every `required` job result is `success`, tolerates `skipped` for `optional` jobs, and fails if any `fail-on-cancelled` job is `cancelled`. All inputs are space-separated `name=result` tokens — pass `needs.<job>.result` per name. An empty (or whitespace-only/unset) `required` is a hard failure, not a silent pass. Logic lives in `gate.sh`, covered by `tests/gate.bats`.

| Input | Required | Default | Notes |
|---|---|---|---|
| `required` | yes | — | Space-separated `name=result`; each must be `success` |
| `optional` | no | `''` | Space-separated `name=result`; each must be `success` or `skipped` |
| `fail-on-cancelled` | no | `''` | Space-separated `name=result`; fails if any is `cancelled` |

## Conventions

- Workflows must use `workflow_call` trigger to be reusable
- Callers reference as `dangernoodle-io/.github/.github/workflows/<file>.yml@main`
  (repo is `.github` on GitHub, checked out locally as `dangernoodle-github`)
- `secrets: inherit` at call site — no explicit secret declarations needed
- Keep workflows generic — no repo-specific logic here

## Maintenance

When adding or modifying a workflow:
1. Update `README.md` — document all inputs/outputs and include a caller snippet.
   Keep the `## GitHub Slack App` section unchanged.
2. Update this file (`CLAUDE.md`) with concise, relevant details about the workflow.
