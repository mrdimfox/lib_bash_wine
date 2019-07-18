#!/bin/bash

export SUDO_ASKPASS="$(command -v ssh-askpass)"
export NO_AT_BRIDGE=1  # get rid of (ssh-askpass:25930): dbind-WARNING **: 18:46:12.019: Couldn't register with accessibility bus: Did not receive a reply.


source ../900_000_lib_bash_wine.sh


function set_environment_for_32_bit_wine_machine {
    export wine_release="devel"
    export WINEPREFIX=${HOME}/wine/wine32_machine_01
    export WINEARCH="win32"
    export wine_windows_version="win10"
}

function set_environment_for_64_bit_wine_machine {
    export wine_release="devel"
    export WINEPREFIX=${HOME}/wine/wine64_machine_02
    export WINEARCH="win64"
    export wine_windows_version="win10"
}


function install_32_bit_wine_machine {
    set_environment_for_32_bit_wine_machine
    source ../900_000_lib_bash_wine.sh # we need to source here or our environment variables get lost
    source ../002_000_install_wine_machine.sh # we need to source here or our environment variables get lost
    install_wine_machine
}

function install_64_bit_wine_machine {
    set_environment_for_64_bit_wine_machine
    source ../900_000_lib_bash_wine.sh # we need to source here or our environment variables get lost
    source ../002_000_install_wine_machine.sh  # we need to source here or our environment variables get lost
    install_wine_machine
}


function test {
	# dummy_test 2>/dev/null || clr_green "no tests in ${BASH_SOURCE[0]}"

    # make sure lib_bash is properly included
    assert_equal "get_sudo" "/usr/bin/sudo"
	assert_pass "is_package_installed apt"

    # update libraries
    "$(get_sudo)" ../install_or_update.sh

	set_environment_for_32_bit_wine_machine
	assert_equal "get_and_export_wine_prefix_or_default_to_home_wine" "/home/consul/wine/wine32_machine_01"


    export automatic_overwrite_existing_wine_machine="True"
    # install_32_bit_wine_machine
    # install_64_bit_wine_machine

    set_environment_for_32_bit_wine_machine
    assert_equal "get_gecko_32_bit_msi_name" ""

    set_environment_for_64_bit_wine_machine
    assert_contains "get_gecko_32_bit_msi_name" "wine_gecko-"

}

test
