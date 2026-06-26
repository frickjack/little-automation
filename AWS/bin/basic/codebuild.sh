#!/bin/bash
#
# Some helpers for CI buildspec
#

source "${LITTLE_HOME}/lib/bash/utils.sh"

branch-name() {
    local BRANCH_NAME
    if [ -n "$CODEBUILD_WEBHOOK_HEAD_REF" ]; then
        BRANCH_NAME=$(sed 's|refs/heads/||' <<< "$CODEBUILD_WEBHOOK_HEAD_REF")
    elif [ -n "$CODEBUILD_SOURCE_VERSION" ] && [[ "$CODEBUILD_SOURCE_VERSION" != arn:* ]]; then
        BRANCH_NAME=$CODEBUILD_SOURCE_VERSION
    else
        BRANCH_NAME=$(git branch -a --contains HEAD | grep -v 'remotes/origin/HEAD' | head -n 1 | sed 's|^\* ||' | sed 's|remotes/origin/||')
    fi
    echo "$BRANCH_NAME"
}

is-version-num() {
    [[ $1 == 0 || $1 =~ ^[1-9][0-9]*$ ]]
}

tag-name() {
    local major="$1"
    local devMinor="$2"
    local patch="$3"

    is-version-num "$major" || { gen3_log_err "invalid major: $major"; return 1; }
    is-version-num "$devMinor" || { gen3_log_err "invalid devMinor: $devMinor"; return 1; }
    is-version-num "$patch" || { gen3_log_err "invalid patch: $patch"; return 1; }

    [[ $((devMinor % 2)) == 1 ]] || { gen3_log_err "devMinor must be odd: $devMinor"; return 1; }

    local branchName
    local tagName
    branchName="${4:-"$(branch-name)"}" || return 1
    if [[ "main" == "$branchName" ]]; then
        tagName="$major.$((devMinor + 1)).$patch"
    elif [[ "dev" == "$branchName" ]]; then
        tagName="$major.$devMinor.$patch";
    fi
    echo "$tagName"
}


if [[ $# -lt 1 ]]; then
    little helper codebuild
fi

"$@"
