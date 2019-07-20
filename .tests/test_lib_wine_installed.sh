#!/bin/bash

export SUDO_ASKPASS="$(command -v ssh-askpass)"
export NO_AT_BRIDGE=1  # get rid of (ssh-askpass:25930): dbind-WARNING **: 18:46:12.019: Couldn't register with accessibility bus: Did not receive a reply.


source ../900_000_lib_bash_wine.sh
source ../002_000_install_wine_machine.sh


function set_variable_for_32_bit_wine_machine {
    global_wine_prefix="${HOME}/wine/wine32_machine_01"
    global_wine_arch="$(get_and_export_wine_arch_from_wine_prefix "${global_wine_prefix}")"
}

function set_variable_for_64_bit_wine_machine {
    global_wine_prefix="${HOME}/wine/wine64_machine_02"
    global_wine_arch="$(get_and_export_wine_arch_from_wine_prefix "${global_wine_prefix}")"
}

function test {
    local linux_release_name wine_release winetricks_windows_version wine_version_number overwrite_existing_wine_machine
    linux_release_name="$(get_linux_release_name)"
    wine_release="devel"
    winetricks_windows_version="win10"
    wine_version_number="$(get_wine_version_number)"
    overwrite_existing_wine_machine="True"

    # make sure lib_bash is properly included
	assert_pass "is_package_installed apt"

    # update libraries
    "$(cmd "sudo")" ../install_or_update.sh


    ### test get gecko commons
    assert_equal "get_gecko_version_from_msi_filename wine_gecko-2.47-x86.msi" "2.47"
    assert_equal "get_gecko_architecture_from_msi_filename wine_gecko-2.47-x86.msi" "x86"
    assert_equal "get_gecko_architecture_from_msi_filename wine_gecko-2.47-x86_64.msi" "x86_64"
    assert_equal "get_wine_gecko_download_link_from_msi_filename wine_gecko-2.47-x86.msi" "https://source.winehq.org/winegecko.php?v=2.47&arch=x86"
    assert_equal "get_wine_gecko_download_backup_link_from_msi_filename wine_gecko-2.47-x86.msi" "https://dl.winehq.org/wine/wine-gecko/2.47/wine_gecko-2.47-x86.msi"

    ### test get gecko 32
    set_variable_for_32_bit_wine_machine
    assert_contains "get_gecko_32_bit_msi_name_from_wine_prefix ${global_wine_prefix}" "wine_gecko-"
    assert_contains "get_gecko_32_bit_msi_name_from_wine_prefix ${global_wine_prefix}" "-x86.msi"

    ### test get gecko 64
    set_variable_for_64_bit_wine_machine
    assert_contains "get_gecko_32_bit_msi_name_from_wine_prefix ${global_wine_prefix}" "wine_gecko-"
    assert_contains "get_gecko_32_bit_msi_name_from_wine_prefix ${global_wine_prefix}" "-x86.msi"
    assert_contains "get_gecko_64_bit_msi_name_from_wine_prefix ${global_wine_prefix}" "wine_gecko-"
    assert_contains "get_gecko_64_bit_msi_name_from_wine_prefix ${global_wine_prefix}" "-x86_64.msi"


    ### test get wine-mono 32
    set_variable_for_32_bit_wine_machine
    assert_contains "get_wine_mono_msi_name ${global_wine_prefix}" "wine-mono"
    assert_contains "get_wine_mono_msi_name ${global_wine_prefix}" ".msi"

    ### test get wine-mono 64
    set_variable_for_64_bit_wine_machine
    assert_contains "get_wine_mono_msi_name ${global_wine_prefix}" "wine-mono"
    assert_contains "get_wine_mono_msi_name ${global_wine_prefix}" ".msi"

}

test
