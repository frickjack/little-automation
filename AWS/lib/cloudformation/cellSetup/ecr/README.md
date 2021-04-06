# TL;DR

Cloudformation template for managing ECR repositories.

## Overview

This template assumes a model where a developer account
hosts docker images that might be deployed into one or more
production accounts.

The template leverages the nunjucks template extensions supported
by the `little stack` commands.  The template accepts two parameters:

* a list of repository names
* a list of account ids to grant read access to the repositories

### Image expiration

The template sets up rules to expire untagged images,
and to expire images tagged with `gitsha_`, `gitpr_`, or `gitbranch_`
prefixes.  The idea is to allow developers several days
to test images under development, but to require semver tags
for long lived images.

## Tests

```
little stack filter ./sampleStackParams.json
```

### authclient

The `authclient/smokeTest.sh` runs an interactive test from the underlying `@littleware/little-authn` node module.  The test walks the caller through a simple OIDC flow to verify the basic functionality of an API domain.

```
# Set the `LITTLE_AUTHN_BASE` environment variable to test a different domain.

LITTLE_AUTHN_BASE=https://api.frickjack.com/authn bash ./smokeTest.sh
```


## Notes

Note: the iamSetup account-level stack deploys an [ApiGatewayAccount](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-apigateway-account.html) resource to give `apigateway` access to `cloudwatch logs`.  You'll need to create that resource yourself or add it to this template if you do not deploy the iamSetups stack.

## Resources

* https://gist.github.com/singledigit/2c4d7232fa96d9e98a3de89cf6ebe7a5
* https://raw.githubusercontent.com/mbradburn/cognito-sample/master/template.yaml
* https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-apigateway-authorizer.html
* https://blog.jayway.com/2016/08/17/introduction-to-cloudformation-for-api-gateway/
* https://blog.jayway.com/2016/09/18/introduction-swagger-cloudformation-api-gateway/
* https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-swagger-extensions-integration-requestParameters.html
* https://stackoverflow.com/questions/36096603/in-aws-api-gateway-how-do-i-include-a-stage-parameter-as-part-of-the-event-vari
* https://stackoverflow.com/questions/36181805/how-to-get-the-name-of-the-stage-in-an-aws-lambda-function-linked-to-api-gateway