#!/bin/bash

sudo_askpass="$(command -v ssh-askpass)"
export SUDO_ASKPASS="${sudo_askpass}"
export NO_AT_BRIDGE=1  # get rid of (ssh-askpass:25930): dbind-WARNING **: 18:46:12.019: Couldn't register with accessibility bus: Did not receive a reply.

function set_lib_bash_permissions {
    local user
    user="$(printenv USER)"
    $(command -v sudo 2>/dev/null) chmod -R 0755 "/usr/local/lib_bash"
    $(command -v sudo 2>/dev/null) chmod -R +x /usr/local/lib_bash/*.sh
    $(command -v sudo 2>/dev/null) chown -R root /usr/local/lib_bash || "$(command -v sudo 2>/dev/null)" chown -R "${user}" /usr/local/lib_bash || echo "giving up set owner" # there is no user root on travis
    $(command -v sudo 2>/dev/null) chgrp -R root /usr/local/lib_bash || "$(command -v sudo 2>/dev/null)" chgrp -R "${user}" /usr/local/lib_bash || echo "giving up set group" # there is no user root on travis
}


function install_lib_bash {
    echo "installing lib_bash"
    $(command -v sudo 2>/dev/null) rm -fR /usr/local/lib_bash
    $(command -v sudo 2>/dev/null) git clone https://github.com/mrdimfox/lib_bash.git /usr/local/lib_bash > /dev/null 2>&1
    set_lib_bash_permissions
}


function install_or_update_lib_bash {
    if [[ -f "/usr/local/lib_bash/install_or_update.sh" ]]; then
        # file exists - so update
        $(command -v sudo 2>/dev/null) /usr/local/lib_bash/install_or_update.sh
    else
        install_lib_bash

    fi
}

install_or_update_lib_bash


function include_dependencies {
    source /usr/local/lib_bash/lib_helpers.sh
}
include_dependencies



function set_lib_bash_wine_permissions {
    local user
    user="$(printenv USER)"
    "$(cmd "sudo")" chmod -R 0755 /usr/local/lib_bash_wine
    "$(cmd "sudo")" chmod -R +x /usr/local/lib_bash_wine/*.sh
    "$(cmd "sudo")" chown -R root /usr/local/lib_bash_wine || "$(cmd "sudo")" chown -R "${user}" /usr/local/lib_bash_wine || echo "giving up set owner" # there is no user root on travis
    "$(cmd "sudo")" chgrp -R root /usr/local/lib_bash_wine || "$(cmd "sudo")" chgrp -R "${user}" /usr/local/lib_bash_wine || echo "giving up set group" # there is no user root on travis
}

# if it is not installed on the right place, we install it on /usr/local/bin
function is_lib_bash_wine_installed {
        if [[ -f "/usr/local/lib_bash_wine/install_or_update.sh" ]]; then
            return 0
        else
            return 1
        fi
}


# this checks the install directory version - but it might be installed for testing somewere else - that will not be updated.
function is_lib_bash_wine_up_to_date {
    local git_remote_hash git_local_hash
    git_remote_hash=$(git --no-pager ls-remote --quiet https://github.com/mrdimfox/lib_bash_wine.git | grep HEAD | awk '{print $1;}' )
    git_local_hash=$(cat /usr/local/lib_bash_wine/.git/refs/heads/master)
    if [[ "${git_remote_hash}" == "${git_local_hash}" ]]; then
        return 0
    else
        return 1
    fi
}

function install_lib_bash_wine {
    clr_green "installing lib_bash_wine"
    "$(cmd "sudo")" rm -fR /usr/local/lib_bash_wine
    "$(cmd "sudo")" git clone https://github.com/mrdimfox/lib_bash_wine.git /usr/local/lib_bash_wine > /dev/null 2>&1
    set_lib_bash_wine_permissions
}



function update_lib_bash_wine {
    clr_green "updating lib_bash_wine"
        (
            # create a subshell to preserve current directory
            cd /usr/local/lib_bash_wine  || fail "error in update_lib_bash_wine"
            "$(cmd "sudo")" git fetch --all  > /dev/null 2>&1
            "$(cmd "sudo")" git reset --hard origin/master  > /dev/null 2>&1
            set_lib_bash_wine_permissions
        )

}



if [[ "${0}" == "${BASH_SOURCE[0]}" ]]; then    # if the script is not sourced
    if ! is_lib_bash_wine_installed; then install_lib_bash_wine ; fi   # if it is just downloaded but not installed at the right place !!!

    if ! is_lib_bash_wine_up_to_date; then
        update_lib_bash_wine
        source "$(readlink -f "${BASH_SOURCE[0]}")"      # source ourself
        exit 0                                           # exit the old instance
    fi

fi
