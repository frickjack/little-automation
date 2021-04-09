#!/bin/bash

source "${LITTLE_HOME}/lib/bash/utils.sh"

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
  local registry
  registry="$(gen3_ecr_registry)" || return 1
  aws ecr describe-repositories | jq -r --arg registry "$registry" '.repositories[] | $registry + "/" + .repositoryName'
}


gen3_ecr_registry() {
  local accountId
  local region

  region="$(aws configure get region)" || return 1
  accountId="$(aws sts get-caller-identity | jq -e -r .Account)" || return 1

  local ecrReg="${accountId}.dkr.ecr.${region}.amazonaws.com"

  echo "$ecrReg"
}

gen3_ecr_scanreport() {
  local repo="$1"
  shift || return 1
  local tag="$1"
  shift || return 1
  local reg="$(gen3_ecr_registry)"
  repo="${repo#reg}"
  aws ecr describe-image-scan-findings --repository-name "$repo" --image-id "imageTag=$tag"
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
    "login")
      gen3_ecr_login "$@"
      ;;
    "registry")
      gen3_ecr_registry "$@"
      ;;
    "scanreport")
      gen3_ecr_scanreport "$@"
      ;;
    *)
      little help ecr
      exit 1
      ;;
  esac
fi
