#!/bin/bash

sudo_askpass="$(command -v ssh-askpass)"
export SUDO_ASKPASS="${sudo_askpass}"
export NO_AT_BRIDGE=1  # get rid of (ssh-askpass:25930): dbind-WARNING **: 18:46:12.019: Couldn't register with accessibility bus: Did not receive a reply.

source ../900_000_lib_bash_wine.sh


function set_variable_for_32_bit_wine_machine {
    global_wine_prefix="${HOME}/wine/wine32_machine_01"
}

function set_variable_for_64_bit_wine_machine {
    global_wine_prefix="${HOME}/wine/wine64_machine_02"
}

function run_tests {
    local wine_arch
    set_variable_for_32_bit_wine_machine
    assert_equal "get_and_export_wine_arch_from_wine_prefix ${global_wine_prefix}" "win32"       # test get arch
    set_variable_for_64_bit_wine_machine
    assert_equal "get_and_export_wine_arch_from_wine_prefix ${global_wine_prefix}" "win64"       # test get arch


    set_variable_for_32_bit_wine_machine


    wine_arch="$(get_and_export_wine_arch_from_wine_prefix ${global_wine_prefix})"
    reg_key="HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment"
    reg_subkey="PATH"
    # eval WINEPREFIX="${global_wine_prefix}" WINEARCH="${wine_arch}" wine reg query "${reg_key}" /v "${reg_subkey}" | cut -d " " -f 3
    # eval "WINEPREFIX="${global_wine_prefix}" WINEARCH="${wine_arch}" wine reg query '${reg_key}' /v '${reg_subkey}'"

    # eval "WINEPREFIX="${global_wine_prefix}" WINEARCH="${wine_arch}" wine reg query \"${reg_key}\" /v \"${reg_subkey}\""

    xxx="$(WINEPREFIX="${global_wine_prefix}" WINEARCH="${wine_arch}" wine reg query "${reg_key}" /v "${reg_subkey}" | grep "${reg_subkey}")"
    # echo "${xxx}" | cut -f 1




    # clr_green "$(get_wine_registry_data "${global_wine_prefix}" "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment" "PATH")"

    # clr_green $(get_wine_registry_path "${global_wine_prefix}")
}

run_tests
