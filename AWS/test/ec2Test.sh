test-ec2-ssh-config-filter-empty() {
  local expected="$(cat - <<EOM
Host dev
    HostName 10.10.0.5
    Tag little-trusted:true
    Tag ec2-instance-id:i-123

Match tagged little-trusted:true
   ServerAliveInterval 120
   ForwardAgent yes
   User ec2-user
   IdentityFile ~/.ssh/id

EOM
  )"
  local result
  result="$(little ec2 ssh-config-filter dev 10.10.0.5 ec2-instance-id:i-123 <<< "")" \
  && [[ "$result" == "$expected" ]]
  because $? "little ec2 ssh-config-filter got expected result: $result"
}

test-ec2-ssh-config-filter-no-match() {
  local input="$(cat - <<EOM
Host *
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes

Host other
    HostName 10.10.0.10
    Tag little-trusted:true
    Tag ec2-instance-id:i-456

Match tagged little-trusted:true
    ServerAliveInterval 120
    ForwardAgent yes
    User ec2-user
    IdentityFile ~/.ssh/id

EOM
  )"
  local expected="$(cat - <<EOM
Host dev
    HostName 10.10.0.5
    Tag little-trusted:true
    Tag ec2-instance-id:i-123

$input
EOM
  )"
  local result
  result="$(little ec2 ssh-config-filter dev 10.10.0.5 ec2-instance-id:i-123 <<< "$input")" \
  && [[ "$result" == "$expected" ]]
  because $? "little ec2 ssh-config-filter got expected result:\n-----\n$result\n------\n$expected\n----"
}

test-ec2-ssh-config-filter-overwrite() {
  local input="$(cat - <<EOM
Host dev
    HostName 10.10.0.3
    Tag little-trusted:true
    Tag ec2-instance-id:i-111

Host *
   IdentityFile ~/.ssh/id_ed25519
   IdentitiesOnly yes

Host other
    HostName 10.10.0.10
    Tag little-trusted:true
    Tag ec2-instance-id:456

Match tagged little-trusted:true
   ServerAliveInterval 120
   ForwardAgent yes
   User ec2-user
   IdentityFile ~/.ssh/id

EOM
  )"
  local expected="$(cat - <<EOM
Host dev
    HostName 10.10.0.5
    Tag little-trusted:true
    Tag ec2-instance-id:i-123

Host *
   IdentityFile ~/.ssh/id_ed25519
   IdentitiesOnly yes

Host other
    HostName 10.10.0.10
    Tag little-trusted:true
    Tag ec2-instance-id:456

Match tagged little-trusted:true
   ServerAliveInterval 120
   ForwardAgent yes
   User ec2-user
   IdentityFile ~/.ssh/id

EOM
  )"
  local result
  result="$(little ec2 ssh-config-filter dev 10.10.0.5 ec2-instance-id:i-123 <<< "$input")" \
  && [[ "$result" == "$expected" ]]
  because $? "little ec2 ssh-config-filter got expected result: $result"
}

test-ec2-vm-name2id() {
  local sshConfig="$(cat - <<EOM
Host dev
    HostName 10.10.0.5
    Tag little-trusted:true
    Tag ec2-instance-id:i-123

Host *
   IdentityFile ~/.ssh/id_ed25519
   IdentitiesOnly yes

Host other
    HostName 10.10.0.10
    Tag little-trusted:true
    Tag ec2-instance-id:i-456

Match tagged little-trusted:true
   ServerAliveInterval 120
   ForwardAgent yes
   User ec2-user
   IdentityFile ~/.ssh/id

EOM
  )"
  local result
  result="$(little ec2 vm-name2id i-abc)"; because $? "little ec2 vm-name2id i-abc runs ok"
  [[ "$result" == "i-abc" ]]; because $? "little ec2 vm-name2id i-abc gives expected result: $result"
  result="$(little ec2 vm-name2id dev "$sshConfig")"; because $? "little ec2 vm-name2id dev runs ok"
  [[ "$result" == "i-123" ]]; because $? "little ec2 vm-name2id dev gives expected result: $result"
}

#---

shunit_runtest "test-ec2-ssh-config-filter-empty" "local,ec2"
shunit_runtest "test-ec2-ssh-config-filter-no-match" "local,ec2"
shunit_runtest "test-ec2-ssh-config-filter-overwrite" "local,ec2"
shunit_runtest "test-ec2-vm-name2id" "local,ec2"
