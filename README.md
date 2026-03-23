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

### `go-test.yml`

Runs build, lint, and tests for Go projects with optional Coveralls coverage.

**Inputs**

| Input | Type | Default | Description |
|---|---|---|---|
| `enable-coveralls` | boolean | `true` | Upload coverage to Coveralls |

**Usage**

```yaml
jobs:
  test:
    uses: dangernoodle-io/.github/.github/workflows/go-test.yml@main
    secrets: inherit
```

---

### `go-release.yml`

Releases a Go project via GoReleaser with GPG signing. Requires a `.goreleaser.yml` in the calling repo.

**Usage**

```yaml
jobs:
  release:
    uses: dangernoodle-io/.github/.github/workflows/go-release.yml@main
    secrets: inherit
```

---

## GitHub Slack App
```
/github subscribe dangernoodle-io/<repo>

/github subscribe dangernoodle-io/<repo>
    workflows:{event:"pull_request, workflow_dispatch", "push" branch:"main"}
```
