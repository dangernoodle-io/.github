# dangernoodle-github

Central repository for reusable GitHub Actions workflows in the dangernoodle org.

## Purpose

Hosts shared workflows consumed via `workflow_call` from other repos.

## Workflows

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

### `.github/workflows/go-test.yml`

Reusable Go CI workflow. Runs build, lint (golangci-lint), and tests with coverage.

| Input | Default | Notes |
|---|---|---|
| `enable-coveralls` | `true` | Set `false` for repos not using Coveralls |

### `.github/workflows/go-release.yml`

Reusable Go release workflow. Runs GoReleaser with GPG signing. Each calling repo provides its own `.goreleaser.yml`.

Requires org secrets: `BUILD_BOT_GPG_PRIVATE_KEY`, `BUILD_BOT_GPG_PASSPHRASE`.

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
