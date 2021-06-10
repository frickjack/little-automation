# TL;DR

Setup cloudformation-S3 jamstack with cloudformation.

# Problem and Audience

A simple clouformation template makes it easy to stamp out AWS infrastructure for a jamstack web site.  A [jamstack](https://jamstack.org/) is a web site composed of static presentation (non-API) resources (html, css, javascript) assembled at build time - as opposed to a site that requires some kind of dynamic server side rendering of resources at request time.  A nice feature of this architecture is that it allows a site to be served inexpensively from a serverless object storage system like [S3](https://aws.amazon.com/s3/).  We manage https://apps.frickjack.com by copying presentation resources to an S3 bucket that acts as an origin for a [cloudfront](https://aws.amazon.com/cloudfront/) distribution.

We originally setup the infrastructure for https://apps.frickjack.com by clicking around the AWS web console (like [this](https://aws.amazon.com/premiumsupport/knowledge-center/cloudfront-serve-static-website/)), but we want to tear down that infrastructure, and move to [cloudformation](https://aws.amazon.com/cloudformation/) managed infrastructure to realize the benefits of infrastructure as code including:

* it is less work to manipulate infrastructure by editing json files than clicking through the web console
* a cloudformation template allows us to deploy multiple copies of our architecture (for different products, test environments, etc) in a consistent way
* cloudformation templates capture best practices and institutional conventions, and allow infrastructure to evolve over time
* tracking the cloudformation template and parameters in git gives an audit trail
* cloudformation makes automation easy

## Jamstack Requirements

We have a handful of requirements for our jamstack infrastructure.  First we want the S3 bucket to remain private and encrypted.  Even though the content of the bucket is publicly accessible via the cloudfront CDN, making the origin bucket conform to standard S3 best practices simplifies compliance, since we do not need to note exceptions to organization policies that expect a bucket to be private and encrypted.  The cloudfront CDN is granted access to the private bucket via a bucket policy that gives read permission to an [origin access identity](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html) associated with the cloudfront distribution.

Most of our other requirements are addressed by adjusting knobs on our cloudfront configuration.  For example, we want all http traffic to be redirected to https.  We want to use an input parameter to our cloudformation stack to associate an alias domain with the distribution - we manage the DNS setup for the alias in another Route53 stack.  We use another input parameter to feed the ARN of our[ACM-managed](https://aws.amazon.com/certificate-manager/) TLS certificate.  We configure cloudfront to require clients to use TLS 1.2 or better.

Finally, our [little stack](https://github.com/frickjack/little-automation/blob/master/AWS/doc/stack.md) tools make it easy to follow the tagging conventions that we want to enforce across our infrastructure.

## the little stack

We setup the following template (also in [github](https://github.com/frickjack/little-automation/blob/master/AWS/lib/cloudformation/cloud/s3web/s3web.json)) to start managing our jamstack infrastructure with cloudformation.  The template takes advantage of the [nunjucks](https://mozilla.github.io/nunjucks/) extensions to cloudformation templates supported by our [little stack](https://github.com/frickjack/little-automation/blob/master/AWS/doc/stack.md) automation.

One "gotcha" that we ran into was that we originally intended to setup a new stack with the apps.frickjack.com domain alias already in use by our live CDN, copy our web content to the new bucket (modify our [codebuild](https://aws.amazon.com/codebuild/) CI pipeline [configuration](https://github.com/frickjack/little-apps/blob/master/buildspec.yml) to do that for us), then update DNS to point the apps.frickjack.com domain at the new CDN.  However, it turns out that cloudfront does not allow two distributions to have the same alias, so we setup our new CDN with a temporary alias, then took a few minutes of downtime while we removed the apps.frickjack.com alias from the old CDN, then updated our new stack.

```
{
  "AWSTemplateFormatVersion": "2010-09-09",
  "Metadata": {
    "License": "Apache-2.0"
  },
  "Description":
    "Generalize AWS s3-cdn sample template from - https://github.com/awslabs/aws-cloudformation-templates/blob/master/aws/services/S3/S3_Website_With_CloudFront_Distribution.yaml",
  "Parameters": {
    "CertificateArn": {
      "Type": "String",
      "Description": "ACM Certificate ARN"
    },
    "DomainName": {
      "Type": "String",
      "Description": "The DNS name of the new cloudfront distro",
      "AllowedPattern": "(?!-)[a-zA-Z0-9-.]{1,63}(?<!-)",
      "ConstraintDescription": "must be a valid DNS zone name."
    },
    "BucketSuffix": {
      "Type": "String",
      "Description": "The suffix of the bucket name - prefix is account number",
      "AllowedPattern": "[a-zA-Z0-9-]{1,63}",
      "ConstraintDescription": "must be a valid S3-DNS name"
    }
  },
  "Resources": {
    "S3Bucket": {
      "Type": "AWS::S3::Bucket",
      "Properties": {
        "AccessControl": "Private",
        "BucketName": { "Fn::Join": [ "-", [ { "Ref" : "AWS::AccountId" }, { "Ref": "BucketSuffix" } ] ] },
        "BucketEncryption": {
          "ServerSideEncryptionConfiguration" : [ 
            {
              "BucketKeyEnabled" : "true",
              "ServerSideEncryptionByDefault" : {
                "SSEAlgorithm": "AES256"
              }
            }
          ]
        },        
        "WebsiteConfiguration": {
          "IndexDocument": "index.html",
          "ErrorDocument": "error.html"
        },
        "Tags": [
          {{ stackTagsStr }}
        ]
      }
    },
    "CloudFrontOriginIdentity": {
      "Type": "AWS::CloudFront::CloudFrontOriginAccessIdentity",
      "Properties": {
        "CloudFrontOriginAccessIdentityConfig": {
          "Comment": "origin identity"
        }
      }
    },
    "BucketPolicy": {
      "Type": "AWS::S3::BucketPolicy",
      "Properties": {
        "Bucket": { "Ref": "S3Bucket" },
        "PolicyDocument": {
          "Version": "2012-10-17",
          "Statement": [
            { 
              "Effect": "Allow",
              "Principal": {
                "AWS": { "Fn::Sub": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${CloudFrontOriginIdentity}" }
              },
              "Action": "s3:GetObject",
              "Resource": { "Fn::Sub": "arn:aws:s3:::${S3Bucket}/*" }
            }
          ]
        }
      }
    },
    "CdnDistribution": {
      "Type": "AWS::CloudFront::Distribution",
      "Properties": {
        "DistributionConfig": {
          "Aliases": [
            { "Ref": "DomainName" }
          ],
          "Origins": [
            { 
              "DomainName": { "Fn::Sub": "${S3Bucket}.s3.${AWS::Region}.amazonaws.com" },
              "Id": "S3-private-bucket",
              "S3OriginConfig": {
                "OriginAccessIdentity": { "Fn::Sub": "origin-access-identity/cloudfront/${CloudFrontOriginIdentity}" }
              }
            }
          ],
          "DefaultRootObject": "index.html",
          "Enabled": "true",
          "Comment": { "Ref": "DomainName" },
          "DefaultCacheBehavior": {
            "AllowedMethods": [ "GET", "HEAD", "OPTIONS" ],
            "CachedMethods": [ "GET", "HEAD", "OPTIONS" ],
            "TargetOriginId": "S3-private-bucket",
            "ForwardedValues": {
              "QueryString": "false",
              "Cookies": {
                "Forward": "none"
              }
            },
            "ViewerProtocolPolicy": "redirect-to-https"
          },
          "ViewerCertificate": {
            "AcmCertificateArn": { "Ref": "CertificateArn" },
            "SslSupportMethod": "sni-only",
            "MinimumProtocolVersion": "TLSv1.2_2019"
          }
        },
        "Tags": [
          { "Key": "Name", "Value": { "Ref": "DomainName" } },
          {{ stackTagsStr }}
        ]
      }
    }
  },
  "Outputs": {
    "CdnAliasDomain": {
      "Value": { "Fn::GetAtt": [ "CdnDistribution", "DomainName" ] },
      "Description": "The URL of the newly created website"
    },
    "BucketName": {
      "Value": { "Ref": "S3Bucket" },
      "Description": "Name of S3 bucket to hold website content"
    }
  }
}

```

# Summary

A simple clouformation template makes it easy to stamp out AWS infrastructure for a jamstack web site.
