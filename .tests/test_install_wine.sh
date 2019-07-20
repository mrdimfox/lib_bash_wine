#!/bin/bash

export SUDO_ASKPASS="$(command -v ssh-askpass)"
export NO_AT_BRIDGE=1  # get rid of (ssh-askpass:25930): dbind-WARNING **: 18:46:12.019: Couldn't register with accessibility bus: Did not receive a reply.


source ../900_000_lib_bash_wine.sh
source ../001_000_install_wine.sh

function run_tests {
    local wine_release
    wine_release="devel"

    # make sure lib_bash is properly included
	assert_pass "is_package_installed apt"

    install_wine "${wine_release}"

}

run_tests
