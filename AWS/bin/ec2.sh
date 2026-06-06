#!/bin/bash

source "${LITTLE_HOME}/lib/bash/utils.sh"

# lib -------------------------------

public-ip() {
    local instanceId="$1"

    [[ -n "$instanceId" ]] || {
        gen3_log_err "public-ip requires instanceId"
        return 1
    }
    local info
    info="$(aws ec2 describe-instances --output json --instance-ids "$instanceId")" || return 1
    cat - <<< "$info"
}

#
# Cat ~/.ssh/config updated with Host with public-ip for given instance-id
#
ssh-config-filter() {
    local name="$1"
    local publicIp="$2"

    [[ -n "$name" ]] || {
        gen3_log_err "ssh-config requires Host name"
        return 1
    }
    [[ -n "$publicIp" ]] || {
        gen3_log_err "ssh-config requires publicIp"
        return 1
    }
    shift
    shift
    local currentConfig=""
    currentConfig="$(cat -)"
    if [[ -z "$currentConfig" ]]; then
        gen3_log_err "ssh-config read empty config - add IdentityFile directive to little-trusted matching rule"
        cat - <<EOM
Match tag little-trusted:true
   ServerAliveInterval 120
   ForwardAgent yes
   User ec2-user
   IdentityFile ~/.ssh/id

EOM
    fi
    # remove existing config for Host $name
    local awkScript="$(cat - <<EOM
/^[A-Z]/ { skipHost="false" }
\$0 == "Host " name { skipHost="true" }
skipHost=="false" { print; }
EOM
    )"
    awk -v "name=$name" "$awkScript" <<< "$currentConfig"
    # add the new config
    cat - <<EOM

Host $name
    HostName: $publicIp
    Tag little-trusted:true
EOM
    local tag
    for tag in "$@"; do
        echo "    Tag $tag"
    done
    echo ""
}

ssh-config-update() {
    local name="$1"
    local instanceId="$2"
    local sshPath="$HOME/.ssh/config"

    [[ -n "$name" ]] || {
        gen3_log_err "ssh-config-update requires name argument"
        return 1
    }
    [[ -n "$instanceId" ]] || {
        gen3_log_err "ssh-config-update requires instanceId argument"
        return 1
    }
    [[ -f "$sshPath" ]] || {
        gen3_log_err "ssh-config does not exist: $sshPath"
        return 1
    }

    local ip
    local newConfig
    cp "$sshPath" "${sshPath}.bak" \
    && ip="$(little ec2 public-ip $instanceId)" \
    && newConfig="$(ssh-config-filter "$name" "$ip" <<< ~/.ssh/config)" \
    && tee "$sshPath" <<< "$newConfig"
}

help() {
    little help ec2
}

# main -----------------------

if [[ -z "$GEN3_SOURCE_ONLY" ]]; then
    if [[ $# -lt 1 ]]; then
        help
        return 1
    fi

    "$@"
fi
