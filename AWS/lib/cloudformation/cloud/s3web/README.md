# TL;DR

Cloudformation template for managing route53 hosted zone.

## Overview

This template supports a simple hosted zone with simple routing to alias, txt, mx, and cname records configured via littleware nunjucks variables - see [./sampleStackParams.json](./sampleStackParams.json).

## Tests

```
little stack filter ./sampleStackParams.json
```


## Notes

## Resources

* https://hackernoon.com/how-to-configure-cloudfront-using-cloudformation-template-2c263u56