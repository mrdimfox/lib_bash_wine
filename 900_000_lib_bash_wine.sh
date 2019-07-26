#!/bin/bash

sudo_askpass="$(command -v ssh-askpass)"
export SUDO_ASKPASS="${sudo_askpass}"
export NO_AT_BRIDGE=1  # get rid of (ssh-askpass:25930): dbind-WARNING **: 18:46:12.019: Couldn't register with accessibility bus: Did not receive a reply.

# call the update script if not sourced
if [[ "${0}" == "${BASH_SOURCE[0]}" ]] && [[ -d "${BASH_SOURCE%/*}" ]]; then "${BASH_SOURCE%/*}"/install_or_update.sh else "${PWD}"/install_or_update.sh ; fi


function include_dependencies {
    local my_dir
    # shellcheck disable=SC2164,SC2034  # SC2034=unused
    my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"  # this gives the full path, even for sourced scripts
    source /usr/local/lib_bash/lib_helpers.sh
}

include_dependencies  # we need to do that via a function to have local scope of my_dir


function get_and_export_wine_arch_from_wine_prefix {
    # $1: wine_prefix
    local wine_prefix wine_arch
    wine_prefix="${1}"
    wine_arch="$( grep "#arch=" "${wine_prefix}/system.reg" | cut -d "=" -f 2)"
    if [[ "${wine_arch}" != "win32" ]] && [[ "${wine_arch}" != "win64" ]]; then
        fail "\
        FAILED: get_and_export_wine_arch_from_wine_prefix${IFS}\
        CALLER: ${0}${IFS}\
        ERROR : WINEARCH for WINEPREFIX=${wine_prefix} can not be determined${IFS}\
        wine_arch=${wine_arch}"
    fi
    export WINEARCH="${wine_arch}"
    echo "${wine_arch}"
}


function get_wine_registry_data {
    # $1 wine_prefix
    # $2 : the reg_key like "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment"
    #                    or "HKEY_CURRENT_USER\\...."
    # $3 : the reg_subkey like "PATH"
    # returns the data, e.g. c:\windows\... ;
    local reg_key reg_subkey result wine_prefix wine_arch
    wine_prefix="${1}"
    reg_key="${2}"
    reg_subkey="${3}"
    wine_arch="$(get_and_export_wine_arch_from_wine_prefix "${wine_prefix}")"
    # see https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/reg-query
    result="$(WINEPREFIX="${wine_prefix}" WINEARCH="${wine_arch}" wine reg query '${reg_key}' /v '${reg_subkey}' | cut -d " " -f 3)"
    echo "${result}"
}

function get_wine_registry_data_type {
    # $1 wine_prefix
    # $2 : the reg_key like "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment"
    # $3 : the reg_subkey like "PATH"
    # returns the Data Type, e.g. REG_SZ, REG_EXPAND_SZ
    local reg_key reg_subkey data wine_prefix wine_arch
    wine_prefix="${1}"
    reg_key="${2}"
    reg_subkey="${3}"
    wine_arch="$(get_and_export_wine_arch_from_wine_prefix "${wine_prefix}")"
    # see https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/reg-query
    data="$(WINEPREFIX="${wine_prefix}" WINEARCH="${wine_arch}" wine reg query "${reg_key}" /v "${reg_subkey}" | cut -d " " -f 2)"
    echo "${data}"
}


function set_wine_registry_data {
    # $1 : wine_prefix
    # $2 : the reg_key like "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment"
    # $3 : the reg_subkey like "PATH"
    # $4 : the data to write
    local reg_key reg_subkey data data_type wine_prefix wine_arch
    wine_prefix="${1}"
    reg_key="${2}"
    reg_subkey="${3}"
    data="${4}"
    wine_arch="$(get_and_export_wine_arch_from_wine_prefix "${wine_prefix}")"
    data_type="$(get_wine_registry_data_type "${wine_prefix}" "${reg_key}" "${reg_subkey}")"
    WINEPREFIX="${wine_prefix}" WINEARCH="${wine_arch}" wine reg add "${reg_key}" /t "${data_type}" /v "${reg_subkey}" /d "${data}" /f
}


function get_and_export_wine_release_from_environment_or_default_to_devel {
    local wine_release
    wine_release="$(printenv wine_release)"
    if [[ -z "${wine_release}" ]]; then wine_release="devel"; fi
    export wine_release="${wine_release}"
    echo "${wine_release}"
}

function get_and_export_wine_prefix_from_environment_or_default_to_home_wine {
    ## set wine prefix to ${HOME}/.wine if not given by environment variable
    local wine_prefix
    wine_prefix="$(printenv WINEPREFIX)"
    if [[ -z "${wine_prefix}" ]]; then wine_prefix="${HOME}/.wine"; fi
    export WINEPREFIX="${wine_prefix}"
    echo "${wine_prefix}"
}

function get_and_export_wine_arch_from_environment_or_default_to_win64 {
    local wine_arch
    wine_arch="$(printenv WINEARCH)"
    if [[ -z ${wine_arch} ]]; then wine_arch="win64"; fi
    export WINEARCH="${wine_arch}"
    echo "${wine_arch}"
}


function get_and_export_winetricks_windows_version_from_environment_or_default_to_win10 {
    local winetricks_windows_version
    winetricks_windows_version="$(printenv winetricks_windows_version)"
    if [[ -z "${winetricks_windows_version}" ]]; then winetricks_windows_version="win10"; fi
    export winetricks_windows_version="${winetricks_windows_version}"
    echo "${winetricks_windows_version}"
}


## todo get windows ProductName
## HKEY_LOCAL_MACHINE\Software\Wow6432Node\Microsoft\Windows NT\CurrentVersion
## Software\\Microsoft\\Windows NT\\CurrentVersion
## "ProductName"="Microsoft Windows 10" --> sometimes wrong
## "CurrentVersion"="10.0" --> sometimes wring


function get_and_export_overwrite_existing_wine_machine_from_environment_or_default_to_false {
    local overwrite_existing_wine_machine
    overwrite_existing_wine_machine="$(printenv overwrite_existing_wine_machine)"
    if [[ -z "${overwrite_existing_wine_machine}" ]]; then overwrite_existing_wine_machine="False"; fi
    export overwrite_existing_wine_machine="${overwrite_existing_wine_machine}"
    echo "${overwrite_existing_wine_machine}"
}


function get_wine_version_number {
    wine --version
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
        fail "\
        FAILED: get_str_32_or_64_from_wine_prefix{IFS}\
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


function get_wine_registry_path {
    # $1: wine_prefix
    # returns the path set in the wine registry
    local wine_prefix
    wine_prefix="${1}"
    get_wine_registry_data "${wine_prefix}" "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment" "PATH"
}


function set_wine_registry_path {
    # set or replace the registry path
    # $1: wine_prefix
    # $2: new_path # the new path to set like "C:\\windows\\system;c:/Program Files/PowerShell"
    local new_path wine_prefix
    wine_prefix="${1}"
    new_path="${2}"
    set_wine_registry_data "${wine_prefix}" "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment" "PATH" "${new_path}"
}



function prepend_path_to_wine_registry_path {
    # $1 : wine_prefix
    # $2 : path_to_add
    # path will not be added if it is already there
    local path_to_add current_path new_path wine_prefix
    wine_prefix="${1}"
    path_to_add="${2}"
    current_path="$(get_wine_registry_path "${wine_prefix}")"
    if is_str1_in_str2 "${path_to_add}" "${current_path}"; then
        new_path="${path_to_add};${current_path}"
        set_wine_registry_path "${wine_prefix}" "${new_path}"
    fi
}


function get_wine_cache_directory_for_user {
    # $1 username
    # returns /home/<user>/.cache/wine - may sound trivial but this returns the REAL home directory of that user
    # not just string replacement
    local username homedirectory wine_cache_directory
    username="${1}"
    homedirectory="$(get_home_directory_from_username "${username}")"
    wine_cache_directory="${homedirectory}/.cache/wine"
    echo "${wine_cache_directory}"
}


function fail_if_wine_prefix_is_not_matching_user_home {
    # $1: wine_prefix
    # $2: username
    local wine_prefix username user_home
    wine_prefix="${1}"
    username="${2}"
    user_home="$(get_home_directory_from_username "${username}")"

    if [[ "${wine_prefix}" == "${user_home}"* ]]; then
        return 0
    else
        fail "the wine_prefix ${wine_prefix} is not within the user home directory ${user_home}"
    fi


}


function fix_wine_permissions {
    # $1: wine_prefix
    # $2: user

    local user wine_prefix wine_cache_directory
    wine_prefix="${1}"
    user="${2}"

    fail_if_wine_prefix_is_not_matching_user_home "${wine_prefix}" "${user}"

    wine_cache_directory="$(get_wine_cache_directory_for_user "${user}")"

    "$(cmd "sudo")" chown -R "${user}"."${user}" "${wine_prefix}"
    "$(cmd "sudo")" chmod -R 0775 "${wine_prefix}"

    "$(cmd "sudo")" chown -R "${user}"."${user}" "${wine_cache_directory}"
    "$(cmd "sudo")" chmod -R 0775 "${wine_cache_directory}"
}


function is_msi_file_in_winecache {
    # returns true if the file is in the wine cache for the given user
    # $1: username
    # $2: msi_file_name (without path)
    local username msi_file_name wine_cache_directory
    username="${1}"
    msi_file_name="${2}"
    wine_cache_directory="$(get_wine_cache_directory_for_user "${username}")"
    if [[ -f "${wine_cache_directory}/${msi_file_name}" ]]; then
        return 0
    else
        return 1
    fi
}


function download_msi_file_to_winecache {
    # $1: username
    # $2: download_link
    # $3: msi_file_name (without path)

    local username download_link msi_file_name wine_cache_directory dbg
    dbg="False"
    username="${1}"
    download_link="${2}"
    msi_file_name="${3}"

    wine_cache_directory="$(get_wine_cache_directory_for_user "${username}")"
    "$(cmd "sudo")" mkdir -p "${wine_cache_directory}"
    "$(cmd "sudo")" chmod -R 0775 "${wine_cache_directory}"

    debug "${dbg}" "wine_cache_directory = ${wine_cache_directory}, msi_file_name=${msi_file_name}, download_link=${download_link},"

    # shellcheck disable=SC2016 # Expressions don't expand in single quotes
    # we need additional quotes in the link, because of possible "&" in the link
    retry "$(cmd "sudo")" wget -nv -c -O "${wine_cache_directory}/${msi_file_name}" '${download_link}'

    "$(cmd "sudo")" chmod -R 0775 "${wine_cache_directory}"
    "$(cmd "sudo")" chown -R "${username}.${username}" "${wine_cache_directory}"
}

function wait_for_system_reg_to_be_created {
    # winecfg needs some time to write the system.reg - we need to wait for it.
    # $1: wine_prefix
    local wine_prefix
    wine_prefix="${1}"
    while [[ ! -f "${wine_prefix}/system.reg" ]]; do
        clr_blue "wait for winecfg to finish creating ${wine_prefix}/system.reg"
        sleep 1
    done
    sleep 1
}


## make it possible to call functions without source include
call_function_from_commandline "${0}" "${@}"
