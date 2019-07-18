#!/bin/bash

sudo_askpass="$(command -v ssh-askpass)"
export SUDO_ASKPASS="${sudo_askpass}"
export NO_AT_BRIDGE=1  # get rid of (ssh-askpass:25930): dbind-WARNING **: 18:46:12.019: Couldn't register with accessibility bus: Did not receive a reply.

export bitranox_debug_global="${bitranox_debug_global}"  # set to True for global Debug
export debug_lib_bash_wine="${debug_lib_bash_wine}"  # set to True for Debug in lib_bash_wine

# call the update script if nout sourced
if [[ "${0}" == "${BASH_SOURCE[0]}" ]] && [[ -d "${BASH_SOURCE%/*}" ]]; then "${BASH_SOURCE%/*}"/install_or_update.sh else "${PWD}"/install_or_update.sh ; fi


function include_dependencies {
    local my_dir
    # shellcheck disable=SC2164,SC2034  # SC2034=unused
    my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"  # this gives the full path, even for sourced scripts
    source /usr/local/lib_bash/lib_helpers.sh
}

include_dependencies  # we need to do that via a function to have local scope of my_dir


function get_wine_release_from_environment_or_default_to_devel {
    local wine_release
    wine_release="$(printenv wine_release)"
    if [[ -z "${wine_release}" ]]; then wine_release="devel"; fi
    echo "${wine_release}"
}

function get_and_export_wine_prefix_or_default_to_home_wine {
    ## set wine prefix to ${HOME}/.wine if not given by environment variable
    local wine_prefix
    wine_prefix="$(printenv WINEPREFIX)"
    if [[ -z "${wine_prefix}" ]]; then wine_prefix="${HOME}/.wine"; fi
    export WINEPREFIX="${wine_prefix}"
    echo "${wine_prefix}"
}

function get_and_export_wine_arch_or_default_to_win64 {
    local wine_arch
    wine_arch="$(printenv WINEARCH)"
    if [[ -z ${wine_arch} ]]; then wine_arch="win64"; fi
    export WINEARCH="${wine_arch}"
    echo "${wine_arch}"
}


function get_wine_windows_version_or_default_to_win10 {
    local wine_windows_version
    wine_windows_version="$(printenv wine_windows_version)"
    if [[ -z "${wine_windows_version}" ]]; then wine_windows_version="win10"; fi
    echo "${wine_windows_version}"
}


function is_overwrite_existing_wine_machine {
    local automatic_overwrite_existing_wine_machine
    automatic_overwrite_existing_wine_machine="$(printenv automatic_overwrite_existing_wine_machine)"
    if [[ "${automatic_overwrite_existing_wine_machine}" == "True" ]]; then
        return 0
    else
        return 1
    fi
}


function get_wine_version_number {
    wine --version
}

function get_and_export_wine_arch_from_wine_prefix {
    # $1: wine_prefix
    local wine_prefix wine_arch
    wine_prefix="${1}"
    wine_arch="$( grep "#arch=" "${wine_prefix}/system.reg" | cut -d "=" -f 2)"
    if [[ "${wine_arch}" != "win32" ]] && [[ "${wine_arch}" != "win64" ]]; then
        fail "\
FAILED: get_and_export_wine_arch_from_wine_prefix{IFS}\
CALLER: ${0}{IFS}\
ERROR : WINEARCH for WINEPREFIX=${wine_prefix} can not be determined{IFS}\
wine_arch=${wine_arch}"
    fi
    export WINEARCH="${wine_arch}"
    echo "${wine_arch}"
}


function get_str_32_or_64_from_wine_prefix {
    # $1: wine_prefix
    # returns "32" or "64" for the given wine_prefix
    local wine_prefix wine_arch
    wine_prefix="${1}"
    wine_arch="$(get_and_export_wine_arch_from_wine_prefix "${wine_prefix}")"
    if [[ ${wine_arch} == "win32" ]]; then
        echo "32"
    elif [[ ${wine_arch} == "win64" ]]; then
        echo "64"
    else
        fail "FAILED: get_str_32_or_64_from_wine_prefix{IFS}\
              CALLER: ${0}{IFS}\
              ERROR : str_32_or_64 can not be determined{IFS}\
              wine_prefix=${wine_prefix}{IFS}\
              wine_arch=${wine_arch}"
    fi
}


function get_str_x86_or_x64_from_wine_prefix {
    # $1: wine_prefix
    # returns "x86" or "x64" for the given wine_prefix
    local wine_prefix wine_arch

    wine_prefix="${1}"
    wine_arch="$(get_and_export_wine_arch_from_wine_prefix "${wine_prefix}")"
    if [[ ${wine_arch} == "win32" ]]; then
        echo "x86"
    elif [[ ${wine_arch} == "win64" ]]; then
        echo "x64"
    else
        fail "get_str_x86_or_x64_from_wine_prefix: can not determine architecture for wine_prefix=${wine_prefix}, wine_arch=${wine_arch}"
    fi
}


function wine_get_user_registry_data {
    # $1 : the reg_key like "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment"
    # $2 : the reg_subkey like "PATH"
    # returns the data, e.g. c:\windows\... ;
    local reg_key reg_subkey result
    reg_key="${1}"
    reg_subkey="${2}"
    # see https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/reg-query
    result="$(wine reg query "${reg_key}" /v "${reg_subkey}" | cut -d " " -f 3)"
    echo "${result}"
}

function wine_get_user_registry_type {
    # $1 : the reg_key like "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment"
    # $2 : the reg_subkey like "PATH"
    # returns the Data Type, e.g. REG_SZ, REG_EXPAND_SZ
    local reg_key reg_subkey data
    reg_key="${1}"
    reg_subkey="${2}"
    # see https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/reg-query
    data="$(wine reg query "${reg_key}" /v "${reg_subkey}" | cut -d " " -f 2)"
    echo "${data}"
}


function wine_set_user_registry_data {
    # $1 : the reg_key like "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment"
    # $2 : the reg_subkey like "PATH"
    # $3 : the data to write
   local reg_key reg_subkey data data_type
    reg_key="${1}"
    reg_subkey="${2}"
    data="${3}"
    data_type="$(wine_get_user_registry_type "${reg_key}" "${reg_subkey}")"
    wine reg add "${reg_key}" /t "${data_type}" /v "${reg_subkey}" /d "${data}" /f
}


function wine_get_user_registry_path {
    # returns the path set in the wine registry
    wine_query_user_registry "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment" "PATH"
}


function wine_set_user_registry_path {
    # set or replace the registry path
    # $1: new_path # the new path to set like "C:\\windows\\system;c:/Program Files/PowerShell"
    local new_path
    new_path="${1}"
    wine_set_user_registry_data "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment" "PATH" "${new_path}"
}



function prepend_path_to_wine_registry_path {
    # $1 : path_to_add
    # path will not be added if it is already there
    local path_to_add current_path new_path
    path_to_add="${1}"
    current_path="$(wine_get_user_registry_path)"
    if is_str1_in_str2 "${path_to_add}" "${current_path}"; then
        new_path="${path_to_add};${current_path}"
        wine_set_user_registry_path "${new_path}"
    fi
}


function fix_wine_permissions {
    local user
    user="$(printenv USER)"
    "$(get_sudo)" chown -R "${user}" "${WINEPREFIX}"
    "$(get_sudo)" chgrp -R "${user}" "${WINEPREFIX}"
}


function get_gecko_32_bit_msi_name {
    local wine_prefix
    wine_prefix="$(get_and_export_wine_prefix_or_default_to_home_wine)"
    strings "${wine_prefix}/drive_c/windows/system32/appwiz.cpl" | grep wine_gecko | grep .msi
}


## make it possible to call functions without source include
call_function_from_commandline "${0}" "${@}"
