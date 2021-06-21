# TL;DR

Howto design, develop, test, document, deploy

## Source layout

This repository has multiple things going on, and has
evolved over time.  Let's try to find some order in the chaos.

## Repository Management

[Angular style](https://medium.com/@menuka/writing-meaningful-git-commit-messages-a62756b65c81) commit messages.

[Gitflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow) branch management.  A short-lived branches should rebase (rather than merge) to sync up with the long-lived parent it branches off of.

### little tools

The `AWS/little.sh` script is the entry point to a suite of
command line automation tools.  We usually invoke the script
through an alias:
```
alias little='bash ~/Code/little-automation/AWS/little.sh'
```

The `little` tool sets up some environment (AWS credentials, paths, etc), 
then calls through to 
another script under `AWS/bin/`.  For example, `little stack ...`
calls through to `AWS/bin/stack.sh`.
The various little tools are documented under `AWS/doc/`, and the
`little help <toolName>` command helps access that documentation.
Finally, the `little testsuite` tool executes the unit tests under `AWS/test/`

```
- AWS/
  |- little.sh
  |- bin/
  |- doc/
  |- lib/
  |- test/
```

### Cloudformation

We use [cloudformation](https://aws.amazon.com/cloudformation/) to automate our infrastructure provisioning.  Our basic approach is to develop a
template that define the infrastructure that can be deployed by a stack.
Each instantiation of a stack supplies parameters that customize the
template for that particular stack's needs.  Because cloudformation
templates do not natively provide the flexibility we need, we extend
our templates with [nunjucks](https://mozilla.github.io/nunjucks/) rules  supported
by our [little stack](https://github.com/frickjack/little-automation/blob/dev/AWS/doc/stack.md) tools.


```
- AWS/
  |- lib/cloudformation/
  |- db/cloudformation/
```

TODO - more here!!!


## Dev-test

```
little testsuite
```

## Linting

Currently no linting enforcement in this repo.

## CICD

The [buildspec.yml](../../buildspec.yml) file defines a [codebuild](https://aws.amazon.com/codebuild/) pipeline that builds and tests code committed to the github repository.

## Publish new release

Before publishing a new version - be sure to update both the [package version](../../package.json) and the [release notes](../reference/releaseNotes.md).

The [codebuild](https://aws.amazon.com/codebuild/) integration in
most of our repositories loads the `main` branch of this github
repo to access the `little` tools.  We also add a semver tag
when we merge new code into the main branch; the git tag should match the module version in `package.json`.  Furthermore, we require that all git tags be applied to the `main` branch - which is our `release` branch in our simplified [gitflow](https://datasift.github.io/gitflow/IntroducingGitFlow.html)
branching strategy.

```
(
  version="$(jq -r .version < package.json)"
  git tag -a "$version" -m "release details in Notes/reference/releaseNotes.md#$version"
  git push origin $version
)
```
