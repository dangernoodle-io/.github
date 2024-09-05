## Workflow Templates

- `maven-build.yml` : used for pull requests and code pushed to `main`
- `maven-release.yml`: used for running the maven release process

## GitHub Slack App
```
/github subscribe dangernoodle-io/<repo>

/github subscribe dangernoodle-io/<repo> 
    workflows:{event:"pull_request, workflow_dispatch", "push" branch:"main"}
```
