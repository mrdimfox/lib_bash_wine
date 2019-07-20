#!/bin/bash

source ../900_000_lib_bash_wine.sh

export SUDO_ASKPASS="$(command -v ssh-askpass)"
export NO_AT_BRIDGE=1  # get rid of (ssh-askpass:25930): dbind-WARNING **: 18:46:12.019: Couldn't register with accessibility bus: Did not receive a reply.

function run_all_tests {
    # shellcheck disable=SC2164
    # local my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"  # this gives the full path, even for sourced scripts
    local files_to_test actual_file_to_test user

    files_to_test=($(ls ./test_*.sh))
    for actual_file_to_test in "${files_to_test[@]}"
    do
        "${actual_file_to_test}"
    done
    ./shellcheck.sh
    clr_green "test ok in $(get_own_script_name "${BASH_SOURCE[0]}")"
    sleep 1
}

run_all_tests