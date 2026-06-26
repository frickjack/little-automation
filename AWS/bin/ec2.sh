#!/bin/bash

source "${LITTLE_HOME}/lib/bash/utils.sh"

# lib -------------------------------

vm-name2id() {
    local name="$1"
    local sshConfig="$2"
    local instId

    if [[ -z "$name" ]]; then
        gen3_log_err "describe-vm requires ssh-config name or aws instance id"
        return 1
    fi
    if [[ "$name" =~ ^i- ]]; then
        instId="$name"
    else
        local awkScript="$(cat - <<EOM
/^[A-Z]/ { skipHost="true" }
\$0 == "Host " name { skipHost="false" }
skipHost=="false" { print; }
EOM
    )"
        sshConfig="${sshConfig:-"$(cat "$HOME/.ssh/config")"}"
        instId="$(
            awk -v "name=$name" "$awkScript" <<< "$sshConfig" \
            | awk -F : '/Tag ec2-instance-id/ { print $2 }'
            )"
    fi
    if [[ ! "$instId" =~ ^i- ]]; then
        gen3_log_err "unable to determine instance-id from name or ssh/config"
        return 1
    fi
    echo "$instId"
}

vm-describe() {
    aws ec2 describe-instances --output json --instance-ids "$(vm-name2id "$@")"
}

vm-public-ip() {
    local info
    info="$(vm-describe "$@")" || return 1
    jq -e -r '.Reservations[0].Instances[0] | .PublicIpAddress' <<< "$info"
}

vm-start() {
    gen3_log_info "if state is stopped, then start the given vm"
    aws ec2 start-instances --instance-ids "$(vm-name2id "$@")"
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

    # Put the host at the top of the file,
    # so Match blocks are below it
    cat - <<EOM
Host $name
    HostName $publicIp
    Tag little-trusted:true
EOM
    local tag
    for tag in "$@"; do
        echo "    Tag $tag"
    done
    echo ""

    # remove existing config for Host $name
    local awkScript="$(cat - <<EOM
/^[A-Z]/ { skipHost="false" }
\$0 == "Host " name { skipHost="true" }
skipHost=="false" { print; }
EOM
    )"
    awk -v "name=$name" "$awkScript" <<< "$currentConfig"
    # add the new config
    
    if [[ -z "$currentConfig" ]]; then
        gen3_log_err "ssh-config read empty config - add IdentityFile directive to little-trusted matching rule"
        cat - <<EOM
Match tagged little-trusted:true
   ServerAliveInterval 120
   ForwardAgent yes
   User ec2-user
   IdentityFile ~/.ssh/id

EOM
    fi
}

vm-install-tools() {
    local -a commands=(
        "dnf check-update"
        "dnf upgrade -y"
        'dnf install docker'
        'usermod -a -G docker ec2-user'
        'dnf install java-25-amazon-corretto-devel'
        'dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo'
        "rpm --import https://packages.microsoft.com/keys/microsoft.asc"
        'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
        'dnf install -y code'
        'dnf install -y gh'
    )
}

ssh-config-update() {
    local name="$1"
    local instanceId="$2"
    local sshPath="$HOME/.ssh/config"

    [[ -n "$name" ]] || {
        gen3_log_err "ssh-config-update requires name argument"
        return 1
    }
    if [[ -z "$instanceId" ]]; then
        instanceId="$(vm-name2id "$name")"
    fi
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
    
    ip="$(vm-public-ip $instanceId)" \
    && cp "$sshPath" "${sshPath}.bak" \
    && newConfig="$(ssh-config-filter "$name" "$ip" "ec2-instance-id:$instanceId" < "$sshPath")" \
    && tee "$sshPath" <<< "$newConfig"
}

mds-get-token() {
    curl -f -s -X PUT "http://169.254.169.254/latest/api/token" \
        -H "X-aws-ec2-metadata-token-ttl-seconds: 360"
}

mds-kurl() {
    local token="$1"
    shift
    local path="${1:-"/latest/meta-data/iam/info"}"
    shift

    [[ -n "$token" ]] || { gen3_log_err "mds-kurl requires token"; return 1; }
    [[ -n "$path" ]] || { gen3_log_err "mds-kurl requires a path"; return 1; }
    local -a args=()
    curl -f -s -H "X-aws-ec2-metadata-token: $token" "http://169.254.169.254/$path" "$@"
}

caller-identity() {
    aws sts get-caller-identity
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
