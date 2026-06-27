test-cb-branch-name() {
  local branchName
  unset CODEBUILD_WEBHOOK_BASE_REF
  unset CODEBUILD_WEBHOOK_EVENT
  unset CODEBUILD_WEBHOOK_HEAD_REF
  unset CODEBUILD_SOURCE_VERSION

  branchName="$(CODEBUILD_WEBHOOK_BASE_REF="refs/heads/frick" CODEBUILD_WEBHOOK_EVENT=PULL_REQUEST_MERGED little codebuild branch-name)" \
      && [[ "frick" == "$branchName" ]];
      because $? "codebuild branch-name leverages CODEBUILD_WEBHOOK_BASE_REF when PR merged"

  branchName="$(CODEBUILD_WEBHOOK_HEAD_REF="refs/heads/bla" little codebuild branch-name)" \
      && [[ "bla" == "$branchName" ]];
      because $? "codebuild branch-name leverages CODEBUILD_WEBHOOK_HEAD_REF"
  
  branchName="$(CODEBUILD_SOURCE_VERSION="bla" little codebuild branch-name)" \
      && [[ "bla" == "$branchName" ]];
      because $? "codebuild branch-name leverages CODEBUILD_SOURCE_VERSION"

  branchName="$(little codebuild branch-name)" \
      && [[ -n "$branchName" ]];
      because $? "codebuild branch-name falls back to git cli"
}

test-cb-is-version() {
  little codebuild is-version-num 0; because $? "0 is a valid version number"
  ! little codebuild is-version-num -1; because $? "-1 is not a valid version number"
  ! little codebuild is-version-num 01; because $? "01 is not a valid version number"
  little codebuild is-version-num 1234; because $? "1234 is a valid version number"
}

test-cb-tag-name() {
  local result
  result="$(little codebuild tag-name 1 1 3 main)" \
      && [[ "1.2.3" == "$result" ]];
      because $? "tag-name 1 1 3 main unexpected result: $result"
  result=""
  result="$(little codebuild tag-name 1 1 3 dev)" \
      && [[ "1.1.3" == "$result" ]];
      because $? "tag-name 1 1 3 dev unexpected result: $result"
  result="$(little codebuild tag-name 1 1 3 bla)" \
      && [[ "" == "$result" ]];
      because $? "tag-name 1 1 3 bla unexpected result: $result"
  ! little codebuild tag-name 1 2 3 bla;
      because $? "tag-name with even devMinor version should fail"
}

shunit_runtest "test-cb-branch-name" "local,codebuild"
shunit_runtest "test-cb-is-version" "local,codebuild"
shunit_runtest "test-cb-tag-name" "local,codebuild"
