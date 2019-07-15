#!/bin/bash


export bitranox_debug="True"


function install_or_update_lib_bash {
    if [[ -f "/usr/local/lib_bash/install_or_update.sh" ]]; then
        source /usr/local/lib_bash/lib_color.sh
        if [[ "${bitranox_debug}" == "True" ]]; then clr_blue "lib_bash_wine\install_or_update.sh@install_or_update_lib_bash: lib bash already installed, calling /usr/local/lib_bash/install_or_update.sh"; fi
        $(which sudo) /usr/local/lib_bash/install_or_update.sh
    else
        if [[ "${bitranox_debug}" == "True" ]]; then echo "lib_bash_wine\install_or_update.sh@install_or_update_lib_bash: installing lib_bash"; fi
        $(which sudo) rm -fR /usr/local/lib_bash
        $(which sudo) git clone https://github.com/bitranox/lib_bash.git /usr/local/lib_bash > /dev/null 2>&1
        $(which sudo) chmod -R 0755 /usr/local/lib_bash
        $(which sudo) chmod -R +x /usr/local/lib_bash/*.sh
        $(which sudo) chown -R root /usr/local/lib_bash || $(which sudo) chown -R ${USER} /usr/local/lib_bash  || echo "giving up set owner" # there is no user root on travis
        $(which sudo) chgrp -R root /usr/local/lib_bash || $(which sudo) chgrp -R ${USER} /usr/local/lib_bash  || echo "giving up set group" # there is no user root on travis
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
    $(which sudo) chmod -R 0755 /usr/local/lib_bash_wine
    $(which sudo) chmod -R +x /usr/local/lib_bash_wine/*.sh
    $(which sudo) chown -R root /usr/local/lib_bash_wine || $(which sudo) chown -R ${USER} /usr/local/lib_bash_wine || echo "giving up set owner" # there is no user root on travis
    $(which sudo) chgrp -R root /usr/local/lib_bash_wine || $(which sudo) chgrp -R ${USER} /usr/local/lib_bash_wine || echo "giving up set group" # there is no user root on travis
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
    local git_local_hash=$( $(which sudo) cat /usr/local/lib_bash_wine/.git/refs/heads/master)
    if [[ "${git_remote_hash}" == "${git_local_hash}" ]]; then
        echo "True"
    else
        echo "False"
    fi
}

function install_lib_bash_wine {
    clr_green "installing lib_bash_wine"
    $(which sudo) rm -fR /usr/local/lib_bash_wine
    $(which sudo) git clone https://github.com/bitranox/lib_bash_wine.git /usr/local/lib_bash_wine > /dev/null 2>&1
    set_lib_bash_wine_permissions
}


function restart_calling_script {
    local caller_command=("${@}")
    if [[ ${#caller_command[@]} -eq 0 ]]; then
        if [[ "${bitranox_debug}" == "True" ]]; then clr_blue "lib_bash_install\install_or_update.sh@restart_calling_script: no caller command - exit 0"; fi
        # no parameters passed
        exit 0
    else
        # parameters passed, running the new Version of the calling script
        if [[ "${bitranox_debug}" == "True" ]]; then clr_blue "lib_bash_install\install_or_update.sh@restart_calling_script: calling command : ${@}"; fi
        eval "${caller_command[@]}"
        if [[ "${bitranox_debug}" == "True" ]]; then clr_blue "lib_bash_install\install_or_update.sh@restart_calling_script: after calling command : ${@} - exiting with 100"; fi
        exit 100
    fi
}


function update_lib_bash_wine {
    if [[ "${bitranox_debug}" == "True" ]]; then clr_blue "lib_bash_wine\install_or_update.sh@update_lib_bash_wine: updating lib_bash_wine"; fi
        (
            # create a subshell to preserve current directory
            cd /usr/local/lib_bash_wine
            $(which sudo) git fetch --all  > /dev/null 2>&1
            $(which sudo) git reset --hard origin/master  > /dev/null 2>&1
            set_lib_bash_wine_permissions
        )
    if [[ "${bitranox_debug}" == "True" ]]; then clr_blue "lib_bash_wine\install_or_update.sh@update_lib_bash_wine: lib_bash_wine update complete"; fi
}


function tests {
	clr_green "no tests in ${0}"
	exit 0
}


if [[ $(is_lib_bash_wine_installed) == "True" ]]; then
    if [[ $(is_lib_bash_wine_up_to_date) == "False" ]]; then
        if [[ "${bitranox_debug}" == "True" ]]; then clr_blue "lib_bash_wine\install_or_update.sh@main: lib_bash_wine is not up to date"; fi
        update_lib_bash_wine
        if [[ "${bitranox_debug}" == "True" ]]; then clr_blue "lib_bash_wine\install_or_update.sh@main: call restart_calling_script ${@}"; fi
        restart_calling_script  "${@}"
        if [[ "${bitranox_debug}" == "True" ]]; then clr_blue "lib_bash_wine\install_or_update.sh@main: call restart_calling_script ${@} returned ${?}"; fi
    else
        if [[ "${bitranox_debug}" == "True" ]]; then clr_blue "lib_bash_wine\install_or_update.sh@main: lib_bash_wine is up to date"; fi
    fi

else
    install_lib_bash_wine
fi
