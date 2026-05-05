# TL;DR

Templates for CICD stacks (codebuild, pipeline, ...)


## Overview

This folder has two cloudformation templates to setup codebuild:
* cicdIam.json - sets up IAM role used by ..
* nodeBuild.json - sets up codebuild resource for a github repo

The build requires access to a github token:

* setup github access token (see https://docs.aws.amazon.com/codebuild/latest/userguide/sample-access-tokens.html).  Save the token in AWS ssm:


ex:
```
little ssm put-parameter dev.cicd.main.active.github-token "$ghToken" "github token expires 2027/02"
```

## cicdIam permissions

The `kms` permissions are for the `littleware` cloudmgr test suite.

The `lambda` and `ecr` permissions are there for publishing
new Docker images, etc.

## nodeBuild template

### Parameters

* ProjectName - something like `cicd-gitrepo-name`
* GithubRepo - ex: https://github.com/frickjack/little-elements.git
* ServiceRole - arn of codebuild service role (see the [cicdIam stack](./cicdIam.json))

## Resources

* https://docs.aws.amazon.com/codebuild/latest/userguide/sample-access-tokens.html
* https://docs.aws.amazon.com/en_pv/codebuild/latest/userguide/sample-github-pull-request.html
* https://aws.amazon.com/blogs/security/how-to-create-and-retrieve-secrets-managed-in-aws-secrets-manager-using-aws-cloudformation-template/
* https://github.com/npm/npm/issues/8356
* https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html