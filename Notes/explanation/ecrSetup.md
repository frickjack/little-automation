# TL;DR

Setup ECR repositories for developers to publish deployable code to,
and share with AWS accounts where our services run.

## Problem and Audience

Setting up an [ECR repository](https://aws.amazon.com/ecr/) 
for publishing docker images is a good first step toward deploying
a docker-packaged application on AWS (ECS, EKS, EC2, lambda, ...).
Although we use ECR like any other docker registry, there are
a few optimizations we can make when setting up a repository.

## Overview

### Docker Workflow and IAM

We should consider the workflow around the creation and use of our Docker images to decide who we should allow to create a new ECR repository, and who should push images to ECR.  In a typical docker
workflow a developer publishes a Dockerfile alongside her code,
and a continuous integration (CI) process kicks in to build and 
publish the Docker image.  When the new image passes all
its tests and is ready for release, then the developer
(or some other process) adds a semver (or some other standard)
release tag to the image.  All this development, 
test, and publishing takes place in an AWS account assigned
to the developer team linked with the docker image; but the
release-tagged images are available for use (`docker pull`)
in production accounts.

With the above workflow in mind, we updated the cloudformation
templates we use to setup our [user (admin, dev, operator)](https://github.com/frickjack/misc-stuff/blob/master/AWS/lib/cloudformation/accountSetup/iamSetup.json)
and [codebuild (CI)](https://github.com/frickjack/misc-stuff/blob/master/AWS/lib/cloudformation/cicd/cicdIam.json) IAM roles
to grant full ECR access in our developer account 
(currently we only have a dev account).

Next we developed a [cloudformation template](https://github.com/frickjack/misc-stuff/blob/dev/AWS/lib/cloudformation/cloud/ecr/ecr.json) for creating ECR repositories in our dev account.
Our template extends the standard cloudformation syntax with
[nunjucks](https://mozilla.github.io/nunjucks/) tags supported
by our [little stack](https://github.com/frickjack/misc-stuff/blob/dev/AWS/doc/stack.md) tools.

There are a couple things in the cloudformation repository definition to notice.  First, each repository has a resource policy that allows our production AWS accounts to pull images from ECR repositories in our dev accounts:

```
"RepositoryPolicyText" : {
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "AllowCrossAccountPull",
            "Effect": "Allow",
            "Principal": {
                "AWS": { "Ref": "ReaderAccountList" }
            },
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage"
            ]
        }
    ]
},
```

Second, each repository has a lifecycle policy that expires
non-production images.  This is especially important for ECR,
because ECR storage costs [ten cents per GByte/month](https://aws.amazon.com/ecr/pricing/), and Docker images can be large.

```
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "age out git dev tags",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": [
          "gitsha_",
          "gitbranch_",
          "gitpr_"
        ],
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 7
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 2,
      "description": "age out untagged images",
      "selection": {
        "tagStatus": "untagged",
        "countType": "imageCountMoreThan",
        "countNumber": 5
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
```

## Summary

Although we use ECR like any other docker registry, there are
a few optimizations we can make when setting up a repository.
First, we update our IAM policies to give users and CICD pipelines
the access they need to support our development and deployment processes.
Next, we add resource policies to our ECR repositories to allow
production accounts to pull docker images from repositories in developer accounts.
Finally, we attach lifecycle rules to each repository to avoid the expense
of storing unused images.
