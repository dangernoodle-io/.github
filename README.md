## Reusable Workflows

Shared GitHub Actions workflows consumed by other `dangernoodle-io` repositories.

| Workflow | Purpose |
|---|---|
| [`auto-label-conventional.yml`](#auto-label-conventionalyml) | Label PRs from conventional-commit prefix in the title |
| [`gh-release.yml`](#gh-releaseyml) | Publish a GitHub release with shared release-notes config |
| [`go-build.yml`](#go-buildyml) | Build, lint, and test Go projects |
| [`go-release.yml`](#go-releaseyml) | Release a Go project via GoReleaser with GPG signing |
| [`maven.yml`](#mavenyml) | Build and optionally release Maven projects |
| [`path-changes.yml`](#path-changesyml) | Detect changed-path filters for a PR via dorny/paths-filter |
| [`pio-test.yml`](#pio-testyml) | PlatformIO host tests + cppcheck + gcovr coverage |
| [`plugin-test.yml`](#plugin-testyml) | Test Claude Code plugins via `node:test` |
| [`terraform-provider-test.yml`](#terraform-provider-testyml) | Test Terraform providers across version matrix |

This repo's own (non-reusable) `.github/workflows/ci.yml` runs `ci-result-gate`'s bats tests,
lints every workflow (`actionlint`), shellchecks every script under `.github/` (`shellcheck`),
asserts `uses:` version consistency (`action-versions`), and gates on itself via the local
(`./`) action.

---

## CI Scripts (`.github/scripts/ci/`)

Logic for this repo's own `ci.yml` lives in scripts, not inline YAML.

### `actionlint.sh`

Downloads a pinned, checksum-verified `actionlint` release and lints every workflow in
`.github/workflows/`. Bump the pinned version + checksum at the top of the script to upgrade
actionlint.

### `shellcheck-all.sh`

Globs every `*.sh` under `.github/` (including composite-action scripts like
`.github/actions/ci-result-gate/gate.sh` and `.github/actions/marketplace-update/update.sh`,
plus the CI scripts themselves) and runs `shellcheck -x -S info` across all of them.

### `assert-action-versions.sh`

Scans every `uses:` in `.github/workflows/**` and `.github/actions/**` and hard-fails on any
mismatch against an explicit `EXPECTED` table declared at the top of the script — a uniformly
outdated repo still fails, not just internally-inconsistent pins. Bump a version there when
intentionally upgrading an action everywhere. `uses: ./...` (local refs) are skipped; reusable
workflow calls (`owner/repo/.github/workflows/x.yml@ref`) are skipped too, since this org's
convention is to always call those at `@main` (see Conventions below) rather than pin a version.
An action used but missing from the table is a hard failure, so new adoptions can't silently
evade the check.

---

### `auto-label-conventional.yml`

Labels pull requests based on conventional-commit prefix in the title. Supports all standard conventional types: `feat(new-component)`, `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `chore`, `build`, `ci`, `style`, and `revert`.

**Inputs**

None.

**Usage**

```yaml
on:
  pull_request:
    types: [opened, edited, synchronize]

jobs:
  auto-label:
    uses: dangernoodle-io/.github/.github/workflows/auto-label-conventional.yml@main
```

---

### `gh-release.yml`

Publishes a GitHub release with optional assets and custom release notes preamble. Automatically materializes `.github/release.yml` at runtime to configure release notes categories, ensuring consistent categorization across all repos without per-repo config files.

**Inputs**

| Input | Type | Default | Description |
|---|---|---|---|
| `tag` | string | `''` | Tag to release (defaults to the calling ref if empty) |
| `assets-artifact` | string | `''` | Optional artifact name whose files become release assets |
| `notes-preamble-artifact` | string | `''` | Optional artifact name containing a markdown file to prepend to auto-generated notes |

**Usage**

```yaml
jobs:
  release:
    uses: dangernoodle-io/.github/.github/workflows/gh-release.yml@main
    with:
      tag: v1.0.0
      assets-artifact: build-artifacts
    secrets: inherit
```

---

### `go-build.yml`

Runs build, lint, and tests for Go projects with optional Coveralls coverage (`build` job), and
an optional `acc` job that runs `make acc` for acceptance tests. The calling repo must provide a
`make acc` target when `enable-acc` is set.

**Inputs**

| Input | Type | Default | Description |
|---|---|---|---|
| `enable-coveralls` | boolean | `true` | Upload coverage to Coveralls |
| `enable-acc` | boolean | `false` | Run the `acc` job (`make acc` acceptance tests) |

**Usage**

```yaml
jobs:
  build:
    uses: dangernoodle-io/.github/.github/workflows/go-build.yml@main
    secrets: inherit
```

To enable acceptance tests, opt in per-repo via a repo/org variable:

```yaml
jobs:
  build:
    uses: dangernoodle-io/.github/.github/workflows/go-build.yml@main
    with:
      enable-acc: ${{ vars.ACC_<REPO> == '1' }}
    secrets: inherit
```

---

### `go-release.yml`

Releases a Go project via GoReleaser with GPG signing. Requires a `.goreleaser.yml` in the calling repo.

**Inputs**

| Input | Type | Default | Description |
|---|---|---|---|
| `homebrew` | boolean | `false` | Publish Homebrew formula to tap repo |
| `marketplace` | boolean | `false` | Update dangernoodle-marketplace ref after release |
| `plugin-name` | string | `''` | Plugin name in marketplace.json (required when marketplace=true) |

**Usage**

```yaml
jobs:
  release:
    uses: dangernoodle-io/.github/.github/workflows/go-release.yml@main
    with:
      homebrew: true
    secrets: inherit
```

To update the marketplace manifest after release:

```yaml
jobs:
  release:
    uses: dangernoodle-io/.github/.github/workflows/go-release.yml@main
    with:
      marketplace: true
      plugin-name: my-plugin
    secrets: inherit
```

---

### `maven.yml`

Builds and optionally releases Maven projects.

**Inputs**

| Input | Type | Default | Description |
|---|---|---|---|
| `maven-goals` | string | — | Maven goal(s) to run (required) |
| `maven-args` | string | `''` | Additional Maven arguments |
| `maven-version` | string | `3.9.9` | Maven version |
| `enable-coveralls` | boolean | `true` | Upload coverage to Coveralls |
| `release` | boolean | `false` | Enable release mode (GPG + SSH setup, Maven Central deploy) |

**Usage**

```yaml
jobs:
  build:
    uses: dangernoodle-io/.github/.github/workflows/maven.yml@main
    with:
      maven-goals: verify
    secrets: inherit
```

---

### `path-changes.yml`

Reusable `workflow_call` workflow that runs `dorny/paths-filter@v3` against a caller-supplied filters YAML and outputs a JSON array of the filter names that matched changed files. Intended to be called only on `pull_request` events.

**Inputs**

| Input | Type | Default | Description |
|---|---|---|---|
| `filters` | string | *(required)* | `dorny/paths-filter` filters YAML |

**Outputs**

| Output | Description |
|---|---|
| `changes` | JSON array of filter names that matched changed files |

**Usage**

```yaml
  changes:
    if: github.event_name == 'pull_request'
    uses: dangernoodle-io/.github/.github/workflows/path-changes.yml@main
    with:
      filters: |
        firmware:
          - 'src/**'
        python:
          - 'scripts/**'
```

Downstream jobs gate on a matched filter:

```yaml
if: github.event_name == 'pull_request' && contains(fromJSON(needs.changes.outputs.changes), 'firmware')
```

---

### `pio-test.yml`

Runs PlatformIO host tests + cppcheck + gcovr coverage for embedded projects (Arduino / ESP-IDF). Caches pip, PlatformIO toolchains, and per-project libdeps so cJSON / Unity / framework downloads are reused across runs.

Calling repo must provide a `Makefile` with `check` (lint) and `coverage` (test + gcovr) targets. The `coverage` target should produce `gcovr-coveralls.json`.

**Inputs**

| Input | Type | Default | Description |
|---|---|---|---|
| `cppcheck-apt-install` | boolean | `false` | Install cppcheck via apt before `make check` (for repos without it bundled) |
| `pre-build-script` | string | `''` | Shell to run before `make coverage` (e.g., asset/webui build) |
| `libdeps-cache-key-paths` | string | `**/platformio.ini` | Glob(s) hashed for the libdeps cache key |
| `enable-coveralls` | boolean | `true` | Upload coverage to Coveralls |

**Usage**

```yaml
jobs:
  test:
    uses: dangernoodle-io/.github/.github/workflows/pio-test.yml@main
    secrets: inherit
```

---

### `plugin-test.yml`

Runs tests for Claude Code plugins using Node.js built-in `node:test` runner. Executes `tests/run.sh` in the plugin directory.

**Inputs**

| Input | Type | Default | Description |
|---|---|---|---|
| `node-version` | string | `'24'` | Node.js version for test runner |
| `plugin-path` | string | `'plugin'` | Path to plugin directory (must contain `tests/run.sh`) |

**Usage**

```yaml
jobs:
  plugin-tests:
    uses: dangernoodle-io/.github/.github/workflows/plugin-test.yml@main
```

---

### `terraform-provider-test.yml`

Runs build, lint, code generation diff check, and acceptance tests across a Terraform version matrix (1.8–1.14).

**Inputs**

| Input | Type | Default | Description |
|---|---|---|---|
| `enable-coveralls` | boolean | `true` | Upload coverage to Coveralls (runs on 1.14 only) |

**Usage**

```yaml
jobs:
  test:
    uses: dangernoodle-io/.github/.github/workflows/terraform-provider-test.yml@main
    secrets: inherit
```

---

## Composite Actions

### `ci-result-gate`

Composite action that fails unless every `required` job result is `success`, tolerates `skipped` for `optional` jobs, and fails if any `fail-on-cancelled` job is `cancelled`. Inputs are space-separated `name=result` tokens — pass `needs.<job>.result` per name. An empty (or whitespace-only/unset) `required` is a hard failure — GitHub does not actually enforce `required: true` on composite-action inputs, so a gate with no required jobs would otherwise pass silently.

Covered by `bats` tests (`.github/actions/ci-result-gate/tests/gate.bats`), run by this repo's own `ci.yml` workflow.

**Inputs**

| Input | Type | Default | Description |
|---|---|---|---|
| `required` | string | *(required)* | Space-separated `name=result`; each must be `success` |
| `optional` | string | `''` | Space-separated `name=result`; each must be `success` or `skipped` |
| `fail-on-cancelled` | string | `''` | Space-separated `name=result`; fails if any is `cancelled` |

**Usage**

```yaml
  summary:
    if: always()
    needs: [check, test, smoke]
    runs-on: ubuntu-latest
    steps:
      - uses: dangernoodle-io/.github/.github/actions/ci-result-gate@main
        with:
          required: check=${{ needs.check.result }} test=${{ needs.test.result }}
          optional: smoke=${{ needs.smoke.result }}
```

---

## GitHub Slack App
```
/github subscribe dangernoodle-io/<repo>

/github subscribe dangernoodle-io/<repo>
    workflows:{event:"pull_request, workflow_dispatch", "push" branch:"main"}
```
