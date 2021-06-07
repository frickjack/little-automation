# TL;DR

Track route53 records with cloudformation.

# Problem and Audience

Managing route53 records with cloudformation is a good idea for the same reasons that tracking other resources with cloudformation (or terraform or whatever) is better than clicking around in the web console:

* it is less work to manipulate route53 records by editing json files than clicking through the web console
* tracking the cloudformation template and parameters in git gives an audit trail
* cloudformation makes automation easy

We setup the following cloudformation template to start managing our simple route53 zones with cloudformation.  The template takes advantage of the [nunjucks](https://mozilla.github.io/nunjucks/) extensions to cloudformation templates supported by our [little stack](https://github.com/frickjack/little-automation/blob/master/AWS/doc/stack.md) automation.

```
{
  "AWSTemplateFormatVersion": "2010-09-09",
  "Parameters": {
    "DomainName": {
      "Type": "String",
      "Description": "the domain name"
    }
  },
  "Resources": {
    "HostedZone": {
      "Type" : "AWS::Route53::HostedZone",
      "Properties" : {
          "HostedZoneTags" : [ 
            {{ stackTagsStr }}
          ],
          "Name" : { "Ref": "DomainName" }
        }
    }
    
    {% if stackVariables.aliasList.length %}
    ,
      {% for item in stackVariables.aliasList %}
      "AliasA{{ item.resourceName }}": {
        "Type" : "AWS::Route53::RecordSet",
        "Properties" : {
            "AliasTarget" : {
              "DNSName" : "{{ item.target }}",
              "HostedZoneId": "{{ item.hostedZoneId }}"
            },
            "Comment" : "{{ item.comment }}",
            "HostedZoneId" : { "Ref": "HostedZone" },
            "Name" : "{{ item.domainName }}",
            "Type" : "A"
          }
      },
      "AliasAaaa{{ item.resourceName }}": {
        "Type" : "AWS::Route53::RecordSet",
        "Properties" : {
            "AliasTarget" : {
              "DNSName" : "{{ item.target }}",
              "HostedZoneId": "{{ item.hostedZoneId }}"
            },
            "Comment" : "{{ item.comment }}",
            "HostedZoneId" : { "Ref": "HostedZone" },
            "Name" : "{{ item.domainName }}",
            "Type" : "AAAA"
          }
      }

      {% if not loop.last %} , {% endif %}
      {% endfor %}
    {% endif %}

    {% if stackVariables.mxConfig %}
    ,
    "MX": {
      "Type" : "AWS::Route53::RecordSet",
      "Properties" : {
          "Comment" : "mx mail config",
          "HostedZoneId" : { "Ref": "HostedZone" },
          "Name" : { "Ref": "DomainName" },
          "ResourceRecords" : {{ stackVariables.mxConfig.resourceRecords | dump }},
          "TTL" : "900",
          "Type" : "MX"
        }
    }
    {% endif %}

    {% if stackVariables.cnameList.length %}
    ,
    {% for item in stackVariables.cnameList %}
    "Cname{{item.resourceName}}": {
      "Type" : "AWS::Route53::RecordSet",
      "Properties" : {
          "Comment" : "{{ item.comment }}",
          "HostedZoneId" : { "Ref": "HostedZone" },
          "Name" : "{{ item.domainName }}",
          "ResourceRecords" : [ "{{ item.target }}" ],
          "TTL" : "900",
          "Type" : "CNAME"
        }
    }
    {% if not loop.last %} , {% endif %}
    {% endfor %}

    {% endif %}

    {% if stackVariables.txtList.length %}
    ,
    {% for item in stackVariables.txtList %}
    "Txt{{item.resourceName}}": {
      "Type" : "AWS::Route53::RecordSet",
      "Properties" : {
          "Comment" : "{{ item.comment }}",
          "HostedZoneId" : { "Ref": "HostedZone" },
          "Name" : { "Ref": "DomainName" },
          "ResourceRecords" : [ {{ item.txtValue | dump }} ],
          "TTL" : "900",
          "Type" : "TXT"
        }
    }
    {% if not loop.last %} , {% endif %}
    {% endfor %}

    {% endif %}

  },

  "Outputs": {
    "NameServers": {
      "Description": "hosted zone nameservers",
      "Value": { "Fn::Join": [",", { "Fn::GetAtt": [ "HostedZone", "NameServers" ] }] }
    }
  }
}

```

# Summary

Managing route53 zones with cloudformation is the right thing to do.
