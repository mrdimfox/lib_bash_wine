#!/bin/bash

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
    ../002_000_install_wine_machine.sh
}

function install_64_bit_wine_machine {
    set_environment_for_64_bit_wine_machine
    ../002_000_install_wine_machine.sh
}


function test {
	# dummy_test 2>/dev/null || clr_green "no tests in ${BASH_SOURCE[0]}"

    # make sure lib_bash is properly included
    assert_equal "get_sudo" "/usr/bin/sudo"
	assert_pass "is_package_installed apt"
    export automatic_overwrite_existing_wine_machine="True"
    install_32_bit_wine_machine
    install_64_bit_wine_machine

}

test
