# Cleankeeper

A GitHub Action to clean obsoleted [Greenkeeper](https://greenkeeper.io/)'s branches

- Run on merge pull request event

- It will automatically removes branches which have:
  - `greenkeeper/` prefix
  - same package name with merged ref
  - smaller version(semver or numeric) than merged ref
  
## Example

In your `.github/main.workflow`

```workflow
workflow "My Workflow" {
  on = "pull_request"
  resolves = ["Cleankeeper"]
}

action "Cleankeeper" {
  uses = "cometkim/cleankeeper@master"
  secrets = ["GITHUB_TOKEN"]
}
```
