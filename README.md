## Composite Actions

- `actions/checkout`: checkout and configure `git`
- `actions/maven` : configure `ssh` (releases), setup java and maven

## Reusable Workflows

- `workflows/maven.yml`: maven builds and releases

## GitHub Slack App
```
/github subscribe dangernoodle-io/<repo>

/github subscribe dangernoodle-io/<repo> 
    workflows:{event:"pull_request, workflow_dispatch", "push" branch:"main"}
```
