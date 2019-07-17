#!/bin/bash

export SUDO_ASKPASS="$(command -v ssh-askpass)"
export NO_AT_BRIDGE=1  # get rid of (ssh-askpass:25930): dbind-WARNING **: 18:46:12.019: Couldn't register with accessibility bus: Did not receive a reply.

export bitranox_debug_global="${bitranox_debug_global}"  # set to True for global Debug
# export debug_lib_bash_wine="False"


function set_lib_bash_permissions {
    local user mydir
    user="$(printenv USER)"
    $(command -v sudo 2>/dev/null) chmod -R 0755 "/usr/local/lib_bash"
    $(command -v sudo 2>/dev/null) chmod -R +x /usr/local/lib_bash/*.sh
    $(command -v sudo 2>/dev/null) chown -R root /usr/local/lib_bash || "$(command -v sudo 2>/dev/null)" chown -R "${user}" /usr/local/lib_bash || echo "giving up set owner" # there is no user root on travis
    $(command -v sudo 2>/dev/null) chgrp -R root /usr/local/lib_bash || "$(command -v sudo 2>/dev/null)" chgrp -R "${user}" /usr/local/lib_bash || echo "giving up set group" # there is no user root on travis
}


function install_lib_bash {
    echo "installing lib_bash"
    $(command -v sudo 2>/dev/null) rm -fR /usr/local/lib_bash
    $(command -v sudo 2>/dev/null) git clone https://github.com/bitranox/lib_bash.git /usr/local/lib_bash > /dev/null 2>&1
    set_lib_bash_permissions
}


function install_or_update_lib_bash {
    if [[ -f "/usr/local/lib_bash/install_or_update.sh" ]]; then
        install_lib_bash
    else
        $(get_sudo) /usr/local/lib_bash/install_or_update.sh
    fi
}

install_or_update_lib_bash


function include_dependencies {
    source /usr/local/lib_bash/lib_helpers.sh
}
include_dependencies



function set_lib_bash_wine_permissions {
    local user mydir
    user="$(printenv USER)"
    $(get_sudo) chmod -R 0755 /usr/local/lib_bash_wine
    $(get_sudo) chmod -R +x /usr/local/lib_bash_wine/*.sh
    $(get_sudo) chown -R root /usr/local/lib_bash_wine || $(get_sudo) chown -R "${user}" /usr/local/lib_bash_wine || echo "giving up set owner" # there is no user root on travis
    $(get_sudo) chgrp -R root /usr/local/lib_bash_wine || $(get_sudo) chgrp -R "${user}" /usr/local/lib_bash_wine || echo "giving up set group" # there is no user root on travis
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
    local git_remote_hash=""
    local git_local_hash=""
    git_remote_hash=$(git --no-pager ls-remote --quiet https://github.com/bitranox/lib_bash_wine.git | grep HEAD | awk '{print $1;}' )
    git_local_hash=$( $(command -v sudo 2>/dev/null) cat /usr/local/lib_bash_wine/.git/refs/heads/master)
    if [[ "${git_remote_hash}" == "${git_local_hash}" ]]; then
        return 0
    else
        return 1
    fi
}

function install_lib_bash_wine {
    clr_green "installing lib_bash_wine"
    $(get_sudo) rm -fR /usr/local/lib_bash_wine
    $(get_sudo) git clone https://github.com/bitranox/lib_bash_wine.git /usr/local/lib_bash_wine > /dev/null 2>&1
    set_lib_bash_wine_permissions
}



function update_lib_bash_wine {
    clr_green "updating lib_bash_wine"
        (
            # create a subshell to preserve current directory
            cd /usr/local/lib_bash_wine  || fail "error in update_lib_bash_wine"
            $(get_sudo) git fetch --all  > /dev/null 2>&1
            $(get_sudo) git reset --hard origin/master  > /dev/null 2>&1
            set_lib_bash_wine_permissions
        )
    debug "${debug_lib_bash_wine}" "lib_bash_wine update complete"

}



if [[ "${0}" == "${BASH_SOURCE}" ]]; then    # if the script is not sourced
    if ! is_lib_bash_wine_installed; then install_lib_bash_wine ; fi

    if ! is_lib_bash_wine_up_to_date; then
        debug "${debug_lib_bash_wine}" "lib_bash_wine is not up to date"
        update_lib_bash_wine
        source "$(readlink -f "${BASH_SOURCE[0]}")"      # source ourself
        exit 0                                           # exit the old instance
    else
        debug "${debug_lib_bash_wine}" "lib_bash_wine is up to date"
    fi

fi
