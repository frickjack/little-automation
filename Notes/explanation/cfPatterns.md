# TL;DR

Managing cloudformation template complexity with the
`little stack` tools and [nunjucks](https://mozilla.github.io/nunjucks/)

## Problem and Audience

Since [cloudformation](https://aws.amazon.com/cloudformation/) templates
do not natively support the dynamic resource provisioning patterns
required for many cloud architectures, various
extensions and template generators have emerged
(like [CDK](https://aws.amazon.com/cdk/) 
and [SAM](https://aws.amazon.com/serverless/sam/)).
The [little stack](https://github.com/frickjack/little-automation/blob/main/AWS/doc/stack.md) tools allow the use of the [nunjucks](https://mozilla.github.io/nunjucks/) template language in cloudformation templates
to support various infrastructure patterns.

## Overview of little tools

The [little tools](https://github.com/frickjack/little-automation/blob/main/AWS/doc/README.md) include the [little stack](https://github.com/frickjack/little-automation/blob/main/AWS/doc/stack.md) helpers
for deploying infrastructure defined by a declarative template file.  The little tools include their own [library](https://github.com/frickjack/little-automation/tree/main/AWS/lib/cloudformation) of cloudformation templates.  Ideally a template is defined in a
generic way, but accepts input parameters that allow
different stacks (like prod and dev) to be deployed, so a `(template.json, parameters.json)` pair defines each infrastructure stack.  The end user follows this workflow.

* select a cloudformation template from the [library](https://github.com/frickjack/little-automation/tree/main/AWS/lib/cloudformation)
* create a parameters json file defining the input variables that
the template requires - the parameters file format extends
the cli skeleton (from `aws cloudformation update-stack --generate-cli-skeleton`) with a `littleware` block - for example:

```
{
    "StackName": "name of the stack",
    "Capabilities": [
        ... cloudformation capabilities if any 
        "CAPABILITY_NAMED_IAM"
    ],
    "TimeoutInMinutes": 5,
    "EnableTerminationProtection": true,
    "Parameters" : [
        ... cloudformation input parameters
    ],
    "Tags": [
        ... tags for the stack
            {
                "Key": "org",
                "Value": "applications"
            },
            {
                "Key": "project",
                "Value": "api.frickjack.com"
            },
            {
                "Key": "stack",
                "Value": "reuben"
            },
            {
                "Key": "stage",
                "Value": "dev"
            },
            {
              "Key": "role",
              "Value": "api"
            }
    ],
    "Littleware": {
        "TemplatePath": "lib/cloudformation/cloud/api/authclient/root.json ... path to the template",
        "Variables": { ... supplemental nunjucks input variables
            "authnapi": {
                "lambdaVersions": [
                    {
                        "resourceName": "lambdaVer20200523r0",
                        "description": "initial prod version"
                    },
                    {
                        "resourceName": "lambdaD001000003D20200618r0",
                        "description": "little-authn 1.0.3"
                    },
                    {
                        "resourceName": "lambda20201205r0",
                        "description": "little-authn 1.0.4"
                    },
                    {
                        "resourceName": "lambda20201216r0",
                        "description": "little-authn 1.0.5"
                    }
                ],
                "prodLambdaVersion": "lambda20201216r0",
                "gatewayDeployments": [
                    {
                        "resourceName": "deploy20200523r0",
                        "description": "initial deployment"
                    }
                ],
                "prodDeployment": "deploy20200523r0",
                "betaDeployment": "deploy20200523r0"
            },
            "sessmgr": {
                "kmsKeys": [
                    "sessmgr20210416"
                ],
                "kmsSigningKey": "sessmgr20210416",
                "kmsOldKey": "sessmgr20210416",
                "kmsNewKey": "sessmgr20210416",
                "jwksUrl": "https://cognito-idp.us-east-2.amazonaws.com/us-east-2_860PcgyKN/.well-known/jwks.json",
                "cloudDomain": "dev.aws-us-east-2.frickjack.com",
                "cookieDomain": ".frickjack.com",
                "lambdaImage": "027326493842.dkr.ecr.us-east-2.amazonaws.com/little/session_mgr:3.0.0",
                "lambdaVersions": [
                    {
                        "resourceName": "sessmgr20210416v2m6p1",
                        "description": "initial prod version"
                    },
                    {
                        "resourceName": "sessmgr20210515v3m0p0",
                        "description": "v3.0.0"
                    }
                ],
                "prodLambdaVersion": "sessmgr20210515v3m0p0",
                "gatewayDeployments": [
                    {
                        "resourceName": "deploy20210416r0",
                        "description": "initial deployment"
                    },
                    {
                        "resourceName": "deploy20210514",
                        "description": "add /versions"
                    }
                ],
                "prodDeployment": "deploy20210514",
                "betaDeployment": "deploy20210514"
            }
        }
    }
}
```

* use the various `little stack` commands to create, update, and monitor the cloudformation stack - for example:
```
little stack filter ./stackParams.json
little stack validate ./stackParams.json
little stack create ./stackParams.json
little stack events ./stackParams.json
little stack update ./stackParams.json
...
```

## Cloudformation Patterns

Here are a couple examples to illustrate how `little stack`
cloudformation templates use `nunjucks` to implement
patterns that would be difficult with `cloudformation` alone.

### Template decomposition

Splitting a large template between multiple files makes it
easier to work with, and nunjucks' [import](https://mozilla.github.io/nunjucks/templating.html#import) directive provides the functionality to do that.  For example, the `root.json` file of this [api gateway](https://github.com/frickjack/little-automation/tree/main/AWS/lib/cloudformation/cloud/api/authclient) template imports separate files to define resources for each API accessed via the gateway.

```
{% import "./authnApiStage.js.njk" as authnApi with context %}
{% import "./sessionMgrApiStage.js.njk" as sessmgr with context %}
```

The same import functionality allows the api resource to import its openapi definition from an external file:
```
    "apiGateway": {
      "Type" : "AWS::ApiGateway::RestApi",
      "Properties" : {
          "Description" : "simple call-through to lambda api",
          "EndpointConfiguration" : {
            "Types": ["EDGE"]
          },
          "MinimumCompressionSize" : 128,
          "Name" : "{{ "authn_api-" + stackParameters.DomainName }}",
          "Body": {% include "./authnOpenApi.json" %},
          "Tags": [
            {{ stackTagsStr }}
          ]
        }
    },
```

### Resource Versioning

Resource versioning is a pattern that a few AWS API's
(lambda, kms, and API gateway deployments anyway) rely on,
but is not supported well by cloudformation.  For example,
this [little template](https://github.com/frickjack/little-automation/blob/dev/AWS/lib/cloudformation/cloud/api/authclient/sessionMgrApiStage.js.njk)
deploys infrastructure for littleware's session manager API.  The "beta" stage of the API is backed by a lambda function, and the "prod" stage of the API is backed by a lambda alias that references a lambda version (snapshot) of the same lambda function.  When a user wants to test new lambda code, she updates a variable in the parameters file to point at the Docker image with the new code (a sample parameters file is [here](https://github.com/frickjack/little-automation/blob/main/AWS/lib/cloudformation/cloud/api/authclient/sampleStackParams.json))

```
"Littleware": {
  "TemplatePath": "lib/cloudformation/cloud/api/authclient/apiGateway.json",
  "Variables": {
        ...
    "sessmgr": {
      ...
      "lambdaImage": "027326493842.dkr.ecr.us-east-2.amazonaws.com/little/session_mgr:2.6.1",
      ...
```

When the new code is ready to be promoted to production, then the developer publishes a new version of the lambda, and points the production alias at that version.  The parameters file defines variables like these:
```
    "lambdaImage": "027326493842.dkr.ecr.us-east-2.amazonaws.com/little/session_mgr:2.6.1",
    "lambdaVersions": [
        {
            "resourceName": "sessmgrVer20210416r0",
            "description": "initial prod version"
        }
    ],
    "prodLambdaVersion": "sessmgrVer20210416r0",
```

The nunjucks-enhanced cloudformation template looks like this:
```
    {% for item in stackVariables.sessmgr.lambdaVersions %}
      "{{ item.resourceName }}": {
        "Type" : "AWS::Lambda::Version",
        "Properties" : {
            "FunctionName" : { "Ref": "sessMgrLambda" },
            "Description": "{{ item.description }}"
          }
      },
    {% endfor %}

    "sessMgrLambdaAlias": {
      "Type" : "AWS::Lambda::Alias",
      "Properties" : {
          "Description" : "prod stage lambda alias",
          "FunctionName" : { "Ref": "sessMgrLambda" },
          "FunctionVersion" : { "Fn::GetAtt": ["{{ stackVariables.sessmgr.prodLambdaVersion }}", "Version"] },
          "Name" : "gateway_prod"
        }
    },

```

The kms API supports a similar mechanism for rotating keys where user code accesses an encryption key through an alias that can be moved to point at a new (rotated) key.  Littleware's session manager infrastructure defines 3 alias to asymmetric KMS keys used to sign and verify JWT's: `kmsSigningAlias`, `kmsNewAlias`, `kmsOldAlias`.  The signing alias points at the key for signing tokens (tokens expire after an hour).  The "old" alias points at the key that was used for signing JWT's in the past, so token verification code can load the old public key after a key rotation.  The "new" alias points at the key that will become the signing key after the next key rotation.  We define the "new" key, so that verification code can just load all 3 keys at startup time, and continue to work after a key rotation (assuming keys rotate less frequently than we restart our services).

The `little stack` parameters file defines a name for each kms key managed by a stack, and a target for each kms alias.
```
            "sessmgr": {
                "kmsKeys": [
                    "sessmgr20210416"
                ],
                "kmsSigningKey": "sessmgr20210416",
                "kmsOldKey": "sessmgr20210416",
                "kmsNewKey": "sessmgr20210416",
```

The template consumes those variables.
```
    {#
       Support KMS key rotation.
       Add a new key when it's time to rotate, and
       move the key alias there. 
    #}
    {% for keyName in stackVariables.sessmgr.kmsKeys %}
    "{{ keyName }}": {
      "Type" : "AWS::KMS::Key",
      "Properties" : {
          "Description" : "asymmetric kms key for session mgr jwt signing and validation",
          "KeyPolicy" : {
              "Id": "key-consolepolicy-3",
              "Version": "2012-10-17",
              "Statement": [
                  {
                    "Sid": "Enable IAM User Permissions",
                    "Effect": "Allow",
                    "Principal": {
                      "AWS": {"Fn::Join": ["", 
                        ["arn:aws:iam::", {"Ref": "AWS::AccountId"}, ":root"]
                        ]}
                    },
                    "Action": "kms:*",
                    "Resource": "*"
                  }
              ]
          },
          "KeySpec" : "ECC_NIST_P256",
          "KeyUsage" : "SIGN_VERIFY",
          "PendingWindowInDays" : 7,
          "Tags": [
            { "Key": "Name", "Value": "{{ keyName }}" },
            {{ stackTagsStr }}
          ]
        }
    },
    {% endfor %}
 
    {% set kmsSigningAlias %}{{ "alias/littleware/api/" + (stackParameters.DomainName | replace(".", "-")) + "/sessMgrSigningKey" }}{% endset %}

    {# old signing key - rotated out #}
    {% set kmsOldAlias %}{{ "alias/littleware/api/" + (stackParameters.DomainName | replace(".", "-")) + "/sessMgrOldKey" }}{% endset %}

    {# new signing key - not yet used for signing #}
    {% set kmsNewAlias %}{{ "alias/littleware/api/" + (stackParameters.DomainName | replace(".", "-")) + "/sessMgrNewKey" }}{% endset %}

    "kmsSigningKey": {
      "Type" : "AWS::KMS::Alias",
      "Properties" : {
          "AliasName" : "{{ kmsSigningAlias }}",
          "TargetKeyId" : { "Ref": "{{ stackVariables.sessmgr.kmsSigningKey }}" }
        }
    },
    "kmsOldKey": {
      "Type" : "AWS::KMS::Alias",
      "Properties" : {
          "AliasName" : "{{ kmsOldAlias }}",
          "TargetKeyId" : { "Ref": "{{ stackVariables.sessmgr.kmsOldKey }}" }
        }
    },
    "kmsNewKey": {
      "Type" : "AWS::KMS::Alias",
      "Properties" : {
          "AliasName" : "{{ kmsNewAlias }}",
          "TargetKeyId" : { "Ref": "{{ stackVariables.sessmgr.kmsNewKey }}" }
        }
    },

```

The kms alias names are passed as part of the json configuration to the session manager lambda function.  Nunjucks' [dump](https://mozilla.github.io/nunjucks/templating.html#dump) filter makes it easy to generate and stringify json:
```
    "sessMgrLambda": {
      "Type" : "AWS::Lambda::Function",
      "Properties" : {
        "PackageType": "Image",
        "Code" : {
          "ImageUri": "{{ stackVariables.sessmgr.lambdaImage }}"
        },
        "Description" : "session manager API lambda",
        "Environment" : {
          "Variables": {
            "JAVA_TOOL_OPTIONS": "-Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager",
            "LITTLE_CLOUDMGR": {{
              {
                "little.cloudmgr.domain" : stackVariables.sessmgr.cloudDomain,
                "little.cloudmgr.sessionmgr.type": "aws",
                "little.cloudmgr.sessionmgr.localconfig": {}, 
                "little.cloudmgr.sessionmgr.awsconfig": {
                    "kmsPublicKeys": [
                      kmsSigningAlias, kmsOldAlias, kmsNewAlias
                    ],
                    "kmsSigningKey": kmsSigningAlias,
                    "oidcJwksUrl": stackVariables.sessmgr.jwksUrl
                },
                "little.cloudmgr.sessionmgr.lambdaconfig": {
                    "corsDomainWhiteList": [ stackVariables.sessmgr.cookieDomain ],
                    "cookieDomain": stackVariables.sessmgr.cookieDomain
                }
              } | dump | dump
            }}
          }
        },
        "FunctionName" : { "Fn::Join": [ "-", ["sessmgr", "{{ stackParameters.DomainName | replace(".", "-") }}",  { "Ref": "StackName" }, { "Ref": "StageName" }, "prod"]] },
        "MemorySize" : 768,
        "Role" : { "Fn::GetAtt": ["sessMgrRole", "Arn"] },
        "Tags": [
          {{ stackTagsStr }}
        ],
        "Timeout" : 5,
        "TracingConfig" : {
          "Mode": "Active"
        }
      }
    },

```

## Summary

The [little stack](https://github.com/frickjack/little-automation/blob/main/AWS/doc/stack.md) tools allow the use of the [nunjucks](https://mozilla.github.io/nunjucks/) template language in cloudformation templates
to support various infrastructure patterns.
