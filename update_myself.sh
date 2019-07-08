#!/bin/bash

function get_sudo_exists {
    # we need this for travis - there is no sudo command !
    if [[ -f /usr/bin/sudo ]]; then
        echo "True"
    else
        echo "False"
    fi
}

function get_sudo_command {
    # we need this for travis - there is no sudo command !
    if [[ $(get_sudo_exists) == "True" ]]; then
        local sudo_command="sudo"
        echo ${sudo_command}
    else
        local sudo_command=""
        echo ${sudo_command}
    fi
}

function include_dependencies {
    local my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"  # this gives the full path, even for sourced scripts
    local sudo_command=$(get_sudo_command)
    ${sudo_command} chmod -R +x "${my_dir}"/*.sh
    ${sudo_command} chmod -R +x "${my_dir}"/lib_install/*.sh
    source "${my_dir}/install_lib_bash.sh"
    source /usr/lib/lib_bash/lib_color.sh
    source /usr/lib/lib_bash/lib_retry.sh
    source /usr/lib/lib_bash/lib_helpers.sh
    source "${my_dir}/lib_install/install_essentials.sh"
}

include_dependencies  # we need to do that via a function to have local scope of my_dir

function update_myself {
    local sudo_command=$(get_sudo_command)
    retry ${sudo_command} git fetch --all > /dev/null 2>&1
    ${sudo_command} git reset --hard origin/master > /dev/null 2>&1
    local my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"  # this gives the full path, even for sourced scripts
    ${sudo_command} chmod -R 0755 "${my_dir}"
    ${sudo_command} chmod -R +x "${my_dir}"/*.sh
    ${sudo_command} chmod -R +x "${my_dir}"/lib_install/*.sh
    ${sudo_command} chown -R "${USER}" "${my_dir}"
    ${sudo_command} chgrp -R "${USER}" "${my_dir}"
}


function check_upgrade {
    # parameter: $1 script_name
    # parameter: $2 script_args
    local caller_command=("$@")
    local git_remote_hash=$(git --no-pager ls-remote --quiet | grep HEAD | awk '{print $1;}')
    local git_local_hash=$(git --no-pager log --decorate=short --pretty=oneline -n1 | grep HEAD | awk '{print $1;}')

    if [[ ${git_remote_hash} == ${git_local_hash} ]]; then
        clr_green "Version up to date"
    else
        banner "new Version, updating skripts..."
        update_myself

        # running the new Version of the calling script
        "${caller_command[@]}"

        # exit this old instance with error code 100
        exit 100
    fi
}

check_upgrade "${@}"  # needs caller name and parameters
