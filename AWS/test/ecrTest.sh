test_ecr_registry() {
  local reg
  reg="$(little ecr registry)" && [[ "$reg" =~ [0-9]{1,}.dkr.ecr.[a-z0-9-]{1,}.amazonaws.com ]]; because $? "little ecr registry got expected value: $reg"
}

test_ecr_login() {
  little ecr login; because $? "little ecr login works"
}


test_ecr_list() {
  local repoList
  local numRepo
  repoList="$(little ecr list)" && numRepo="$(wc -l <<< "$repoList")" && [[ "$numRepo" -gt 0 ]]; because $? "little ecr list looks ok: $repoList"
}

shunit_runtest "test_ecr_registry" "local,ecr"
shunit_runtest "test_ecr_login" "ecr"
shunit_runtest "test_ecr_list" "ecr"
