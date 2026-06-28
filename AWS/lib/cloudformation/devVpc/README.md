# TL;DR

Setup VPC with developer VM's for dev-test

## Tests

```
little stack filter ./sampleStackParams.json
```

## Notes

* security-group allows unrestricted egress and in-VPC traffic
* security-group supports an ingress whitelist, but defaults to unrestricted ingress to port 22
* we assume a model where a dev starts his VM to work, then stops when not working - ex:
```
aws ec2 describe-vpcs
aws ec2 describe-instances --filter Name=VpcId,Value=$theId
aws ec2 start-instances --instance-ids $id
aws ec2 stop-instances --instance-ids $id
```

## Resources

