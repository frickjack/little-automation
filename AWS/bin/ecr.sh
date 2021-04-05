#!/bin/bash

source "${LITTLE_HOME}/lib/bash/utils.sh"


# constants -----------------------


accountList=(
053927701465
199578515826
222487244010
236714345101
258867494168
302170346065
345060017512
446046036926
454671780472
474789003679
504226487987
562749638216
584476192960
636151780898
662843554732
663707118480
728066667777
813684607867
830067555646
895962626746
980870151884
)

principalStr=""
for it in "${accountList[@]}"; do
  principalStr="${principalStr},\"arn:aws:iam::${it}:root\""
done

policy="$(cat - <<EOM
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "AllowCrossAccountPull",
            "Effect": "Allow",
            "Principal": {
                "AWS": [ ${principalStr#,} ]
            },
            "Action": [
               "ecr:GetAuthorizationToken",
               "ecr:BatchCheckLayerAvailability",
               "ecr:GetDownloadUrlForLayer",
               "ecr:BatchGetImage"
            ]
        }
    ]
}
EOM
)";

if ! jq -r . <<< "$policy" > /dev/null; then
  gen3_log_err "failed validating ecr repo policy: $policy"
  exit 1
fi


# lib -------------------------------

gen3_ecr_login() {
  local region

  region="$(aws configure get region)" || return 1

  if gen3_time_since ecr-login is 36000; then
    # re-authenticate every 10 hours
    aws ecr get-login-password --region "$region" | docker login --username AWS --password-stdin $(gen3_ecr_registry) 1>&2 || return 1
  fi
}


#
# List the `gen3/` repository names (in the current account)
#
gen3_ecr_repolist() {
  aws ecr describe-repositories | jq -r '.repositories[] | .repositoryName'
}


gen3_ecr_registry() {
  local accountId
  local region

  region="$(aws configure get region)" || return 1
  accountId="$(aws sts get-caller-identity | jq -e -r .Account)" || return 1

  local ecrReg="707767160287.dkr.ecr.${region}.amazonaws.com"

  echo "$ecrReg"
}

# main -----------------------

if [[ -z "$GEN3_SOURCE_ONLY" ]]; then
  # Support sourcing this file for test suite
  command="$1"
  shift
  case "$command" in
    "list")
      gen3_ecr_repolist "$@"
      ;;
    "quaylogin")
      gen3_quay_login "$@"
      ;;
    "login")
      gen3_ecr_login "$@"
      ;;
    "registry")
      gen3_ecr_registry "$@"
      ;;
    *)
      little help ecr
      exit 1
      ;;
  esac
fi
