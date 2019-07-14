#!/bin/bash

# function include_dependencies {
#     my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"  # this gives the full path, even for sourced scripts
#     source "${my_dir}/lib_color.sh"
#     source "${my_dir}/lib_helpers.sh"
#
# }
#
# include_dependencies  # we need to do that via a function to have local scope of my_dir

function install_or_update_lib_bash {
    if [[ -f "/usr/local/lib_bash/install_or_update.sh" ]]; then
        # $(which sudo) /usr/local/lib_bash/install_or_update.sh
        echo "lib_bash already installed"
    else
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


function is_lib_bash_wine_to_update {
    local git_remote_hash=$(git --no-pager ls-remote --quiet https://github.com/bitranox/lib_bash_wine.git | grep HEAD | awk '{print $1;}' )
    local git_local_hash=$( $(which sudo) cat /usr/local/lib_bash_wine/.git/refs/heads/master)
    if [[ "${git_remote_hash}" == "${git_local_hash}" ]]; then
        echo "False"
    else
        echo "True"
    fi
}

function install_lib_bash_wine {
    clr_green "installing lib_bash_wine"
    $(which sudo) rm -fR /usr/local/lib_bash_wine
    $(which sudo) git clone https://github.com/bitranox/lib_bash_wine.git /usr/local/lib_bash_wine > /dev/null 2>&1
    set_lib_bash_wine_permissions
}


function restart_calling_script {
    local caller_command=("$@")
    if [ ${#caller_command[@]} -eq 0 ]; then
        echo "lib_bash_wine: no caller command - exit 0"
        # no parameters passed
        exit 0
    else
        # parameters passed, running the new Version of the calling script
        echo "lib_bash_wine: calling command : $@ - exit 100"
        "${caller_command[@]}"
        # exit this old instance with error code 100
        exit 100
    fi
}


function update_lib_bash_wine {
    if [[ $(is_lib_bash_wine_to_update) == "True" ]]; then
        clr_green "lib_bash_wine needs to update"
        (
            # create a subshell to preserve current directory
            cd /usr/local/lib_bash_wine
            $(which sudo) git fetch --all  > /dev/null 2>&1
            $(which sudo) git reset --hard origin/master  > /dev/null 2>&1
            set_lib_bash_wine_permissions
        )
        clr_green "lib_bash_wine update complete"
    else
        clr_green "lib_bash_wine is up to date"
    fi
}


if [[ $(is_lib_bash_wine_installed) == "True" ]]; then
    update_lib_bash_wine
    restart_calling_script  "${@}" || exit 0 # needs caller name and parameters
else
    install_lib_bash_wine
fi
