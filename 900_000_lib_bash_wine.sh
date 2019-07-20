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


function wine_get_registry_data {
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
    result="$(WINEPREFIX="${wine_prefix}" WINEARCH="${wine_arch}" wine reg query "${reg_key}" /v "${reg_subkey}" | cut -d " " -f 3)"
    echo "${result}"
}

function wine_get_registry_data_type {
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


function wine_set_registry_data {
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
    data_type="$(wine_get_registry_data_type "${wine_prefix}" "${reg_key}" "${reg_subkey}")"
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



function is_overwrite_existing_wine_machine {
    local overwrite_existing_wine_machine
    overwrite_existing_wine_machine="$(printenv overwrite_existing_wine_machine)"
    if [[ "${overwrite_existing_wine_machine}" == "True" ]]; then
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


function wine_get_registry_path {
    # $1: wine_prefix
    # returns the path set in the wine registry
    local wine_prefix
    wine_prefix="${1}"
    wine_get_registry_data "${wine_prefix}" "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment" "PATH"
}


function wine_set_registry_path {
    # set or replace the registry path
    # $1: wine_prefix
    # $2: new_path # the new path to set like "C:\\windows\\system;c:/Program Files/PowerShell"
    local new_path wine_prefix
    wine_prefix="${1}"
    new_path="${2}"
    wine_set_registry_data "${wine_prefix}" "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment" "PATH" "${new_path}"
}



function prepend_path_to_wine_registry_path {
    # $1 : wine_prefix
    # $2 : path_to_add
    # path will not be added if it is already there
    local path_to_add current_path new_path wine_prefix
    wine_prefix="${1}"
    path_to_add="${2}"
    current_path="$(wine_get_registry_path "${wine_prefix}")"
    if is_str1_in_str2 "${path_to_add}" "${current_path}"; then
        new_path="${path_to_add};${current_path}"
        wine_set_registry_path "${wine_prefix}" "${new_path}"
    fi
}


function fix_wine_permissions {
    # $1: user
    # $2: wine_prefix
    local user wine_prefix
    user="${1}"
    wine_prefix="${2}"
    
    if is_str1_in_str2 "${user}" "${wine_prefix}"; then
        "$(cmd "sudo")" chown -R "${user}" "${wine_prefix}"
        "$(cmd "sudo")" chgrp -R "${user}" "${wine_prefix}"
    else
        fail "the USER ${user} and WINEPREFIX ${wine_prefix} dont match together"
    fi
}


function get_gecko_32_bit_msi_name_from_wine_prefix {
    # tested
    # $1: wine_prefix
    local wine_prefix wine_arch msi_file_name
    wine_prefix="${1}"
    wine_arch="$(get_and_export_wine_arch_from_wine_prefix "${wine_prefix}")"

    if [[ "${wine_arch}" == "win32" ]]; then
        msi_file_name="$(strings "${wine_prefix}/drive_c/windows/system32/appwiz.cpl" | grep wine_gecko | grep .msi)"
    else
        msi_file_name="$(strings "${wine_prefix}/drive_c/windows/syswow64/appwiz.cpl" | grep wine_gecko | grep .msi)"
    fi

    if [[ -z "${msi_file_name}" ]]; then
        fail "can not determine 32 Bit MSI File Name for wine prefix ${wine_prefix}"
    else
        echo "${msi_file_name}"
    fi
}


function get_gecko_64_bit_msi_name_from_wine_prefix {
    # tested
    # $1: wine_prefix
    local wine_prefix wine_arch msi_file_name
    wine_prefix="${1}"
    wine_arch="$(get_and_export_wine_arch_from_wine_prefix "${wine_prefix}")"

    if [[ "${wine_arch}" == "win32" ]]; then
        fail "can not get the Gecko 64 Bit msi Filename from a 32 Bit wine machine"
    else
        msi_file_name="$(strings "${wine_prefix}/drive_c/windows/system32/appwiz.cpl" | grep wine_gecko | grep .msi)"
    fi

    if [[ -z "${msi_file_name}" ]]; then
        fail "can not determine 32 Bit MSI File Name for wine prefix ${wine_prefix}"
    else
        echo "${msi_file_name}"
    fi

}


function get_gecko_version_from_msi_filename {
    # returns the version e.g. "2.47"
    # $1 : gecko_msi_name e.g. "wine_gecko-2.47-x86.msi", or "wine_gecko-2.47-x86.msi"
    local gecko_msi_name
    gecko_msi_name="${1}"
    echo "${gecko_msi_name}" | cut -d "-" -f 2
}

function get_gecko_architecture_from_msi_filename {
    # returns the version e.g. "x86" or "x86_64"
    # $1 : gecko_msi_name e.g. "wine_gecko-2.47-x86.msi", or "wine_gecko-2.47-x86_64.msi"
    local gecko_msi_name
    gecko_msi_name="${1}"
    echo "${gecko_msi_name}" | cut -d "-" -f 3 | cut -d "." -f 1
}


function get_wine_gecko_download_link_from_msi_filename {
    # gets the download link
    # correct Link1: https://source.winehq.org/winegecko.php?v=2.47&arch=x86
    # correct Link2: https://source.winehq.org/winegecko.php?v=2.47&arch=x86_64
    # there is another paramter: # &winev=????, not used here, https://github.com/wine-mirror/wine/blob/master/dlls/appwiz.cpl/addons.c

    # $1 - gecko_msi_name
    local gecko_msi_name version architecture
    gecko_msi_name="${1}"
    version="$(get_gecko_version_from_msi_filename "${gecko_msi_name}")"
    architecture="$(get_gecko_architecture_from_msi_filename "${gecko_msi_name}")"
    echo "https://source.winehq.org/winegecko.php?v=${version}&arch=${architecture}"
}

function get_wine_gecko_download_backup_link_from_msi_filename {
    # gets the download link
    # correct Link2: https://dl.winehq.org/wine/wine-gecko/2.47/wine_gecko-2.47-x86.msi
    # $1 - gecko_msi_name
    local gecko_msi_name version
    gecko_msi_name="${1}"
    version="$(get_gecko_version_from_msi_filename "${gecko_msi_name}")"
    echo "https://dl.winehq.org/wine/wine-gecko/${version}/${gecko_msi_name}"
}



function get_wine_cache_directory_for_user {
    # $1 username
    # returns /home/<user>/.cache/wine - may sound trivial but this returns the REAL home directory of that user
    # not just string replacement
    local username homedirectory wine_cache_directory
    username="${1}"
    homedirectory="$(get_home_directory_from_username "${username}")"
    wine_cache_directory="${homedirectory}/.cache/wine"
    echo ${wine_cache_directory}
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

    local username download_link msi_file_name wine_cache_directory
    username="${1}"
    download_link="${2}"
    msi_file_name="${3}"

    wine_cache_directory="$(get_wine_cache_directory_for_user "${username}")"
    "$(cmd "sudo")" mkdir -p "${wine_cache_directory}"
    "$(cmd "sudo")" chmod -R 0775 "${wine_cache_directory}"

    retry "$(cmd "sudo")" wget -O "${wine_cache_directory}/${msi_file_name}" "${download_link}"

    "$(cmd "sudo")" chmod -R 0775 "${wine_cache_directory}"
    "$(cmd "sudo")" chown -R "${username}.${username}" "${wine_cache_directory}"
}



function download_gecko_msi_files {
    # $1 - wine_prefix
    # $2 - username
    local wineprefix username winearch gecko_msi_name_32 gecko_msi_name_64
    wine_prefix="${1}"
    username="${2}"

    wine_arch="$(get_and_export_wine_arch_from_wine_prefix "${wine_prefix}")"


    gecko_msi_name_32="$(get_gecko_32_bit_msi_name_from_wine_prefix "${wine_prefix}")"
    if ! is_msi_file_in_winecache "${username}" "${gecko_msi_name_32}"; then
        download_msi_file_to_winecache "${wine_prefix}" "${username}" "${gecko_msi_name_32}"
    fi


    if [[ "${wine_arch}" == "win64" ]]; then
        gecko_msi_name_64="$(get_gecko_64_bit_msi_name_from_wine_prefix "${wine_prefix}")"
        if ! is_msi_file_in_winecache "${username}" "${gecko_msi_name_64}"; then
            download_msi_file_to_winecache "${wine_prefix}" "${username}" "${gecko_msi_name_64}"
        fi
    fi

}





function get_wine_mono_msi_name {
    # tested
    # $1: wine_prefix
    local wine_prefix
    wine_prefix="${1}"

    strings "${wine_prefix}/drive_c/windows/system32/appwiz.cpl" | grep wine-mono | grep .msi
}









## make it possible to call functions without source include
call_function_from_commandline "${0}" "${@}"
