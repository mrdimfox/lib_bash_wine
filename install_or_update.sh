#!/bin/bash


# export bitranox_debug_global=False
export debug_lib_bash_wine="False"


function install_or_update_lib_bash {
    if [[ -f "/usr/local/lib_bash/install_or_update.sh" ]]; then
        source /usr/local/lib_bash/lib_color.sh
        $(command -v sudo 2>/dev/null) /usr/local/lib_bash/install_or_update.sh
    else
        $(command -v sudo 2>/dev/null) rm -fR /usr/local/lib_bash
        $(command -v sudo 2>/dev/null) git clone https://github.com/bitranox/lib_bash.git /usr/local/lib_bash > /dev/null 2>&1
        $(command -v sudo 2>/dev/null) chmod -R 0755 /usr/local/lib_bash
        $(command -v sudo 2>/dev/null) chmod -R +x /usr/local/lib_bash/*.sh
        $(command -v sudo 2>/dev/null) chown -R root /usr/local/lib_bash || $(command -v sudo 2>/dev/null) chown -R ${USER} /usr/local/lib_bash  || echo "giving up set owner" # there is no user root on travis
        $(command -v sudo 2>/dev/null) chgrp -R root /usr/local/lib_bash || $(command -v sudo 2>/dev/null) chgrp -R ${USER} /usr/local/lib_bash  || echo "giving up set group" # there is no user root on travis
    fi
}

install_or_update_lib_bash

function include_dependencies {
    source /usr/local/lib_bash/lib_color.sh
    source /usr/local/lib_bash/lib_retry.sh
    source /usr/local/lib_bash/lib_helpers.sh
}

include_dependencies


function set_lib_bash_wine_permissions {
    $(get_sudo) chmod -R 0755 /usr/local/lib_bash_wine
    $(get_sudo) chmod -R +x /usr/local/lib_bash_wine/*.sh
    $(get_sudo) chown -R root /usr/local/lib_bash_wine || $(get_sudo) chown -R ${USER} /usr/local/lib_bash_wine || echo "giving up set owner" # there is no user root on travis
    $(get_sudo) chgrp -R root /usr/local/lib_bash_wine || $(get_sudo) chgrp -R ${USER} /usr/local/lib_bash_wine || echo "giving up set group" # there is no user root on travis
}

function is_lib_bash_wine_installed {
        if [[ -f "/usr/local/lib_bash_wine/install_or_update.sh" ]]; then
            echo "True"
        else
            echo "False"
        fi
}


function is_lib_bash_wine_up_to_date {
    local git_remote_hash=$(git --no-pager ls-remote --quiet https://github.com/bitranox/lib_bash_wine.git | grep HEAD | awk '{print $1;}' )
    local git_local_hash=$( $(get_sudo) cat /usr/local/lib_bash_wine/.git/refs/heads/master)
    if [[ "${git_remote_hash}" == "${git_local_hash}" ]]; then
        echo "True"
    else
        echo "False"
    fi
}

function install_lib_bash_wine {
    clr_green "installing lib_bash_wine"
    $(get_sudo) rm -fR /usr/local/lib_bash_wine
    $(get_sudo) git clone https://github.com/bitranox/lib_bash_wine.git /usr/local/lib_bash_wine > /dev/null 2>&1
    set_lib_bash_wine_permissions
}


function restart_calling_script {
    local caller_command=("${@}")
    if [[ ${#caller_command[@]} -eq 0 ]]; then
        debug "${debug_lib_bash_wine}" "no caller command - exit 0"
        # no parameters passed
        exit 0
    else
        # parameters passed, running the new Version of the calling script
        debug "${debug_lib_bash_wine}" "calling command : ${@}"

        eval "${caller_command[@]}"
        debug "${debug_lib_bash_wine}" "after calling command ${@} : exiting with 100"
        exit 100
    fi
}


function update_lib_bash_wine {
    clr_green "updating lib_bash_wine"
        (
            # create a subshell to preserve current directory
            cd /usr/local/lib_bash_wine
            $(get_sudo) git fetch --all  > /dev/null 2>&1
            $(get_sudo) git reset --hard origin/master  > /dev/null 2>&1
            set_lib_bash_wine_permissions
        )
    debug "${debug_lib_bash_wine}" "lib_bash_wine update complete"

}

function tests {
	local my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"  # this gives the full path, even for sourced scripts
	debug "${debug_lib_bash_wine}" "no tests"
}


if [[ "${0}" == "${BASH_SOURCE}" ]]; then    # if the script is not sourced
    if [[ $(is_lib_bash_wine_installed) == "True" ]]; then
        if [[ $(is_lib_bash_wine_up_to_date) == "False" ]]; then
            debug "${debug_lib_bash_wine}" "lib_bash_wine is not up to date"
            update_lib_bash_wine
            debug "${debug_lib_bash_wine}" "call restart_calling_script ${@}"
            restart_calling_script  "${@}"
            debug "${debug_lib_bash_wine}" "call restart_calling_script ${@} returned ${?}"
        else
            debug "${debug_lib_bash_wine}" "lib_bash_wine is up to date"
        fi

    else
        install_lib_bash_wine
    fi
fi
