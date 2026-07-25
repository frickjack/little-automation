# TL;DR

Helpers for [codebuild](https://aws.amazon.com/codebuild/)
CI scripts (`buildspec.yml`)

## Command Reference

### branch-name

Resolve the current git branch name leveraging codebuild environment variables

```
little codebuild branch-name
```

### tag-name $major $devMinor $patch

Return the tag-name for a new commit into the `main` or `dev` branch:
* `$devMinor` must be an odd number
* if on the `dev` branch, then return `$major.$devMinor.$patch`
* if on the `main` branch, then return `$major.$devMinor+1.$patch
* otherwise empty string

### gh-log-filter

Filters out git commit metadata from stdin - ex:
```
git log origin/dev..HEAD | little codebuild gh-log-filter
```

### gh-pr-create

Generate a pull request with:
- `--base origin/dev`
- `--title "$(git branch --show-current)"`
- a description extracted from the commit messages on the current branch

Assumes the code has already been pushed.

Ex:
```
little codebuild gh-pr-create --dry-run
```
