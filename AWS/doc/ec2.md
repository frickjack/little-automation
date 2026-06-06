# TL;DR

Helpers for interacting with `ec2`.

## Overview

The `little ec2` commands simplify interaction with ec2 virtual machines.


## Use

### public-ip

Get the public-ip of a running ec2 instance.
Fail if the instance is not running.

```
little ec2 public-ip
```

### ssh-config-filter $name $ip [$tag1 $tag2 ...]

Help configure `~/.ssh/config` to access an ec2 VM.

```
little ec2 ssh-config "$name" "$ip" <<< ~/.ssh/config
```

### ssh-config-update

Simplify adding an ec2 vm to `~/.ssh/config`

```
little ec2 ssh-config-update my-vm $instanceId

ssh my-vm
```
