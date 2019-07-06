#!/bin/bash

function install_lib_bash_if_not_exist {
    local my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"  # this gives the full path, even for sourced scripts
    if [[ ! -d "${my_dir}/lib_bash" ]]; then
        echo "*******************************************************************************"
        echo "* installing lib_bash into ${my_dir}/lib_bash"
        echo "*******************************************************************************"
        git clone https://github.com/bitranox/lib_bash.git ${my_dir}/lib_bash
        chmod -R +x ${my_dir}/lib_bash/*.sh
        echo "*******************************************************************************"
        echo "content : "
        echo "*******************************************************************************"
        ls -l
    fi
}

function update_lib_bash_if_exist {
    local my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"  # this gives the full path, even for sourced scripts
    if [[ -d "${my_dir}/lib_bash" ]]; then
        cd lib_bash
        local git_remote_hash=$(git --no-pager ls-remote --quiet | grep HEAD | awk '{print $1;}' )
        local git_local_hash=$(git --no-pager log --decorate=short --pretty=oneline -n1 | grep HEAD | awk '{print $1;}' )
        git fetch --all
        git reset --hard origin/master
        chmod -R +x ./*.sh
        cd ..
    fi
}

update_lib_bash_if_exist
install_lib_bash_if_not_exist
