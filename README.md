## Reusable Workflows

Shared GitHub Actions workflows consumed by other `dangernoodle-io` repositories.

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

### `go-build.yml`

Runs build, lint, and tests for Go projects with optional Coveralls coverage.

**Inputs**

| Input | Type | Default | Description |
|---|---|---|---|
| `enable-coveralls` | boolean | `true` | Upload coverage to Coveralls |

**Usage**

```yaml
jobs:
  build:
    uses: dangernoodle-io/.github/.github/workflows/go-build.yml@main
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
| `node-version` | string | `'20'` | Node.js version for test runner |
| `plugin-path` | string | `'plugin'` | Path to plugin directory (must contain `tests/run.sh`) |

**Usage**

```yaml
jobs:
  plugin-tests:
    uses: dangernoodle-io/.github/.github/workflows/plugin-test.yml@main
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

## GitHub Slack App
```
/github subscribe dangernoodle-io/<repo>

/github subscribe dangernoodle-io/<repo>
    workflows:{event:"pull_request, workflow_dispatch", "push" branch:"main"}
```
