#!/bin/bash

export SUDO_ASKPASS="$(command -v ssh-askpass)"
export NO_AT_BRIDGE=1  # get rid of (ssh-askpass:25930): dbind-WARNING **: 18:46:12.019: Couldn't register with accessibility bus: Did not receive a reply.


source ../900_000_lib_bash_wine.sh


function set_environment_for_32_bit_wine_machine {
    export wine_release="devel"
    export WINEPREFIX=${HOME}/wine/wine32_machine_01
    export WINEARCH="win32"
    export winetricks_windows_version="win10"
}

function set_environment_for_64_bit_wine_machine {
    export wine_release="devel"
    export WINEPREFIX=${HOME}/wine/wine64_machine_02
    export WINEARCH="win64"
    export winetricks_windows_version="win10"
}

function test {
    local linux_release_name wine_release wine_prefix wine_arch winetricks_windows_version wine_version_number automatic_overwrite_existing_wine_machine
    linux_release_name="$(get_linux_release_name)"
    wine_release="$(get_and_export_wine_release_from_environment_or_default_to_devel)"
    wine_prefix="$(get_and_export_wine_prefix_from_environment_or_default_to_home_wine)"
    wine_arch="$(get_and_export_wine_arch_from_wine_prefix "${wine_prefix}")"
    winetricks_windows_version="$(get_and_export_winetricks_windows_version_from_environment_or_default_to_win10)"
    wine_version_number="$(get_wine_version_number)"
    automatic_overwrite_existing_wine_machine="$(printenv automatic_overwrite_existing_wine_machine)"

    # make sure lib_bash is properly included
	assert_pass "is_package_installed apt"

    # update libraries
    ""$(cmd "sudo")"" ../install_or_update.sh

    ### test get gecko 32
    set_environment_for_32_bit_wine_machine
    wine_prefix="$(get_and_export_wine_prefix_from_environment_or_default_to_home_wine)"
    wine_arch="$(get_and_export_wine_arch_from_wine_prefix "${wine_prefix}")"
    assert_contains "get_gecko_32_bit_msi_name ${wine_prefix}" "wine_gecko-"
    assert_contains "get_gecko_32_bit_msi_name ${wine_prefix}" "-x86.msi"
    assert_equals "get_gecko_64_bit_msi_name ${wine_prefix}" ""

    ### test get gecko 64
    set_environment_for_64_bit_wine_machine
    wine_prefix="$(get_and_export_wine_prefix_from_environment_or_default_to_home_wine)"
    wine_arch="$(get_and_export_wine_arch_from_wine_prefix "${wine_prefix}")"
    assert_contains "get_gecko_32_bit_msi_name ${wine_prefix}" "wine_gecko-"
    assert_contains "get_gecko_32_bit_msi_name ${wine_prefix}" "-x86.msi"
    assert_contains "get_gecko_64_bit_msi_name ${wine_prefix}" "wine_gecko-"
    assert_contains "get_gecko_64_bit_msi_name ${wine_prefix}" "-x86_64.msi"

    ### test get wine-mono 32
    set_environment_for_32_bit_wine_machine
    wine_prefix="$(get_and_export_wine_prefix_from_environment_or_default_to_home_wine)"
    wine_arch="$(get_and_export_wine_arch_from_wine_prefix "${wine_prefix}")"
    assert_contains "get_wine_mono_msi_name" "wine-mono"
    assert_contains "get_wine_mono_msi_name" ".msi"

    ### test get wine-mono 64
    set_environment_for_64_bit_wine_machine
    wine_prefix="$(get_and_export_wine_prefix_from_environment_or_default_to_home_wine)"
    wine_arch="$(get_and_export_wine_arch_from_wine_prefix "${wine_prefix}")"
    assert_contains "get_wine_mono_msi_name" "wine-mono"
    assert_contains "get_wine_mono_msi_name" ".msi"


}

test
