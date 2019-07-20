#!/bin/bash

export SUDO_ASKPASS="$(command -v ssh-askpass)"
export NO_AT_BRIDGE=1  # get rid of (ssh-askpass:25930): dbind-WARNING **: 18:46:12.019: Couldn't register with accessibility bus: Did not receive a reply.

../install_or_update.sh
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

function run_tests {
    local linux_release_name wine_release winetricks_windows_version overwrite_existing_wine_machine
    wine_release="devel"
    winetricks_windows_version="win10"
    user="$(printenv USER)"
    overwrite_existing_wine_machine="True"


    set_variable_for_32_bit_wine_machine
    install_wine_machine "${wine_release}" "${global_wine_prefix}" "${global_wine_arch}" "${winetricks_windows_version}" "${user}" "${overwrite_existing_wine_machine}"
    # do it again with overwrite = False to check if we can upgrade an existing wine machine
    install_wine_machine "${wine_release}" "${global_wine_prefix}" "${global_wine_arch}" "${winetricks_windows_version}" "${user}" "False"


    set_variable_for_64_bit_wine_machine
    install_wine_machine "${wine_release}" "${global_wine_prefix}" "${global_wine_arch}" "${winetricks_windows_version}" "${user}" "${overwrite_existing_wine_machine}"
    # do it again with overwrite = False to check if we can upgrade an existing wine machine
    install_wine_machine "${wine_release}" "${global_wine_prefix}" "${global_wine_arch}" "${winetricks_windows_version}" "${user}" "False"

}

run_tests
