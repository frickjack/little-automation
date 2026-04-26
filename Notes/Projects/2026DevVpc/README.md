# Dev VPC Project

## Overview

This is our vision for littleware software development infrastructure.  First, rather than have a powerful laptop, a developer has a thin client that remotely access a personal EC2 VM in a dev VPC under a dev AWS account.  The dev only runs the VM while working.  The VM has an IAM role that allows the developer to interact with the AWS resources he requires.  The dev accesses her VM via ssh using a helper script that adds the dev's current client IP address to the IP white-list of the VM's network security group.

## TODO

* IAM role
