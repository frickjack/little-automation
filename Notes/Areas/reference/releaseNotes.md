# TL;DR

Some basic information on our tagged releases.
Notes:
- `git log tag1...tag2` shows the commit log between versions
- [gitReleaseFlow](../explanation/gitReleaseFlow.md) explains our tagging and release process

## Versions 1.3.X/1.4.X

- update codebuild `buildSpec.yml` with automatic tagging to implement our [gitflow](../explanation/gitReleaseFlow.md) process
    * introduce `little codebuild`
    * [issue 26](https://github.com/frickjack/little-automation/issues/26)
- [dev VPC](../../Projects/Active/2026DevVpc/README.md) project
    * [devvpc](../../../AWS/lib/cloudformation/devVpc/README.md) cloudformation stack
    * [issue 25](https://github.com/frickjack/little-automation/issues/25)


## Version 1.2.4

### Features

* s3web little stack for jamstack web sites

## Version 1.2.3

### Features

* route53 little stack

### Improvements

* rename misc-stuff repo to little-automation

## Version 1.2.1

### Features

* ecr cloudformation and helper tool
* little avro helper

### Improvements

* codebuild to standard5 build image - supports nodejs14
* codebuild buildspec uses AWS_REGION environment variable

### Fixes

* various

### Notes

## Version 1.2.2

### Improvements

* little stack compress json
* CICD to nodejs14
* api gateway  session manager stage

## Version 1.2.0

### Features

* introduce nunjucks cloudformation templating
* introduce SSM parameter helpers as a free alternative to AWS secrets manager
* little s3gzcp local remote
* little markdown
* devTest docs

### Improvements

* evolve api gateway deployment

### Fixes

### Notes

## Version 1.1.0

### Features

### Improvements

* rename CLI - `arun` to `little`

### Fixes

### Notes
