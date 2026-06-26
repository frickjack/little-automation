# TL;DR

Helpers for interacting with `ec2`.

## Overview

The `little ec2` commands simplify interaction with ec2 virtual machines.


## Use

### caller-identity

Shortcut for `aws sts caller-identity`

### public-ip $instanceId

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

### ssh-config-update $name $instanceId

Simplify adding an ec2 vm to `~/.ssh/config`

Ex:
```
little ec2 ssh-config-update my-vm $instanceId

ssh my-vm sudo systemctl shutdown

little ec2 start my-vm && little ec2 ssh-config-update my-vm

ssh my-vm
```

### vm-name2id $nameOrId

Return a given ec2 instance-id unchanged (if starts with "i-"),
otherwise look for the given name in ~/.ssh/config and
extract the instance id from the tag applied by the
ssh-config-update command (see above)

Ex:
```
$ little ec2 vm-name2id frickjack
i-03b04bcf494c6c12f
```

### vm-start $nameOrId

Start the specified EC2 VM

### vm-describe $nameOrId

Shortcut for `aws ec2 describe-instances`

### vm-public-ip $nameOrId

Shortcut for `vm-describe $nameOrId | jq ...`

### mds-get-token

Retrieve a token for interacting with the metadata service
(http://169.254.169.254) on an EC2 instance

### mds-kurl $token ${path:-/latest/meta-data/iam/info} ...

Shortcut for `curl -H '... mds token' http://169.254.169.254/$path ...`
