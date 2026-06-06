test-ec2-ssh-config-filter-empty() {
  local expected="$(cat - <<EOM
Match tag little-trusted:true
   ServerAliveInterval 120
   ForwardAgent yes
   User ec2-user
   IdentityFile ~/.ssh/id


Host dev
    HostName: 10.10.0.5
    Tag little-trusted:true
    Tag aws-id:123

EOM
  )"
  local result
  result="$(little ec2 ssh-config-filter dev 10.10.0.5 aws-id:123 <<< "")" \
  && [[ "$result" == "$expected" ]]
  because $? "little ec2 ssh-config-filter got expected result: $result"
}

test-ec2-ssh-config-filter-no-match() {
  local input="$(cat - <<EOM
Host *
   IdentityFile ~/.ssh/id_ed25519
   IdentitiesOnly yes

Match tag little-trusted:true
   ServerAliveInterval 120
   ForwardAgent yes
   User ec2-user
   IdentityFile ~/.ssh/id

Host other
    HostName: 10.10.0.10
    Tag little-trusted:true
    Tag aws-id:456

EOM
  )"
  local expected="$(cat - <<EOM
$input

Host dev
    HostName: 10.10.0.5
    Tag little-trusted:true
    Tag aws-id:123

EOM
  )"
  local result
  result="$(little ec2 ssh-config-filter dev 10.10.0.5 aws-id:123 <<< "$input")" \
  && [[ "$result" == "$expected" ]]
  because $? "little ec2 ssh-config-filter got expected result: $result"
}

test-ec2-ssh-config-filter-overwrite() {
  local input="$(cat - <<EOM
Host *
   IdentityFile ~/.ssh/id_ed25519
   IdentitiesOnly yes

Match tag little-trusted:true
   ServerAliveInterval 120
   ForwardAgent yes
   User ec2-user
   IdentityFile ~/.ssh/id

Host dev
    HostName: 10.10.0.3
    Tag little-trusted:true
    Tag aws-id:111

Host other
    HostName: 10.10.0.10
    Tag little-trusted:true
    Tag aws-id:456

EOM
  )"
  local expected="$(cat - <<EOM
Host *
   IdentityFile ~/.ssh/id_ed25519
   IdentitiesOnly yes

Match tag little-trusted:true
   ServerAliveInterval 120
   ForwardAgent yes
   User ec2-user
   IdentityFile ~/.ssh/id

Host other
    HostName: 10.10.0.10
    Tag little-trusted:true
    Tag aws-id:456

Host dev
    HostName: 10.10.0.5
    Tag little-trusted:true
    Tag aws-id:123

EOM
  )"
  local result
  result="$(little ec2 ssh-config-filter dev 10.10.0.5 aws-id:123 <<< "$input")" \
  && [[ "$result" == "$expected" ]]
  because $? "little ec2 ssh-config-filter got expected result: $result"
}

#---

shunit_runtest "test-ec2-ssh-config-filter-empty" "local,ec2"
shunit_runtest "test-ec2-ssh-config-filter-no-match" "local,ec2"
shunit_runtest "test-ec2-ssh-config-filter-overwrite" "local,ec2"
