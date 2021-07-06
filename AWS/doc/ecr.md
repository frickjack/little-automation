# TL;DR

Helpers for interacting with [ECR](https://aws.amazon.com/ecr/).
Only works on the `cdistest` admin VM - which has the necessary AWS 
permissions for interacting with the cdistest docker registry.

## Command Reference

### registry

Get the base path of the registry.
Ex:
```
reg="$(little ecr registry)"
```

### login

Authenticate docker with the ECR registry if necessary.
Ex:
```
little ecr login
```

### list

List the repositories in the registry.
Ex:
```
little ecr list
```

### scanreport

Get the image-scan report for the given image

```
little ecr scanreport little/session_mgr latest
```

## AWS Cheat Sheet

```
aws ecr list-images --repository-name little/session_mgr
```