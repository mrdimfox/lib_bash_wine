#!/bin/bash

sudo_askpass="$(command -v ssh-askpass)"
export SUDO_ASKPASS="${sudo_askpass}"
export NO_AT_BRIDGE=1  # get rid of (ssh-askpass:25930): dbind-WARNING **: 18:46:12.019: Couldn't register with accessibility bus: Did not receive a reply.

# call the update script if not sourced
if [[ "${0}" == "${BASH_SOURCE[0]}" ]] && [[ -d "${BASH_SOURCE%/*}" ]]; then "${BASH_SOURCE%/*}"/install_or_update.sh else "${PWD}"/install_or_update.sh ; fi


function include_dependencies {
    local my_dir
    # shellcheck disable=SC2164
    my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"  # this gives the full path, even for sourced scripts
    source /usr/local/lib_bash/lib_helpers.sh
    source "${my_dir}/900_000_lib_bash_wine.sh"
}

include_dependencies


function get_gecko_32_bit_msi_name_from_wine_prefix {
    # tested
    # $1: wine_prefix
    local wine_prefix wine_arch msi_file_name
    wine_prefix="${1}"
    wine_arch="$(get_and_export_wine_arch_from_wine_prefix "${wine_prefix}")"

    if [[ "${wine_arch}" == "win32" ]]; then
        # strings is a environment variable in travis, so we can not reach the command strings !!!!
        msi_file_name="$("$(cmd "strings")" "${wine_prefix}/drive_c/windows/system32/appwiz.cpl" | grep "wine_gecko" | grep ".msi")"
    else
        # strings is a environment variable in travis, so we can not reach the command strings !!!!
        msi_file_name="$("$(cmd "strings")" "${wine_prefix}/drive_c/windows/syswow64/appwiz.cpl" | grep "wine_gecko" | grep ".msi")"
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
        # strings is a environment variable in travis, so we can not reach the command strings !!!!
        msi_file_name="$("$(cmd "strings")" "${wine_prefix}/drive_c/windows/system32/appwiz.cpl" | grep "wine_gecko" | grep ".msi")"
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
    # there is another parameter: # &winev=????, not used here, https://github.com/wine-mirror/wine/blob/master/dlls/appwiz.cpl/addons.c

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

function download_gecko_msi_files {
    # $1 - wine_prefix
    # $2 - username
    local wine_prefix username wine_arch gecko_msi_name_32 gecko_msi_name_64 download_link backup_download_link wine_cache_directory
    wine_prefix="${1}"
    username="${2}"

    fail_if_wine_prefix_is_not_matching_user_home "${wine_prefix}" "${username}"

    wine_arch="$(get_and_export_wine_arch_from_wine_prefix "${wine_prefix}")"
    gecko_msi_name_32="$(get_gecko_32_bit_msi_name_from_wine_prefix "${wine_prefix}")"

    if ! is_msi_file_in_winecache "${username}" "${gecko_msi_name_32}"; then
        download_link="$(get_wine_gecko_download_link_from_msi_filename "${gecko_msi_name_32}")"
        backup_download_link="$(get_wine_gecko_download_backup_link_from_msi_filename "${gecko_msi_name_32}")"
        wine_cache_directory="$(get_wine_cache_directory_for_user)"
        download_msi_file_to_winecache "${username}" "${download_link}" "${gecko_msi_name_32}"
        if [[ ! -f "${wine_cache_directory}/${gecko_msi_name_32}" ]]; then
            download_msi_file_to_winecache "${username}" "${backup_download_link}" "${gecko_msi_name_32}"
        fi
    fi


    if [[ "${wine_arch}" == "win64" ]]; then
        gecko_msi_name_64="$(get_gecko_64_bit_msi_name_from_wine_prefix "${wine_prefix}")"
        if ! is_msi_file_in_winecache "${username}" "${gecko_msi_name_64}"; then
            download_link="$(get_wine_gecko_download_link_from_msi_filename "${gecko_msi_name_64}")"
            backup_download_link="$(get_wine_gecko_download_backup_link_from_msi_filename "${gecko_msi_name_64}")"
            download_msi_file_to_winecache "${username}" "${download_link}" "${gecko_msi_name_64}"
            if [[ ! -f "${wine_cache_directory}/${gecko_msi_name_64}" ]]; then
                download_msi_file_to_winecache "${username}" "${backup_download_link}" "${gecko_msi_name_64}"
            fi
        fi
    fi

}


function install_wine_gecko {
    # installs the matching wine_gecko on the existing wine machine
    # $1 : wine_prefix
    # $2 : username

    local wine_prefix username wine_arch gecko_32_bit_msi_name gecko_64_bit_msi_name wine_cache_directory dbg
    dbg="False"
    wine_prefix="${1}"
    username="${2}"

    fail_if_wine_prefix_is_not_matching_user_home "${wine_prefix}" "${username}"
    download_gecko_msi_files "${wine_prefix}" "${username}"

    wine_arch="$(get_and_export_wine_arch_from_wine_prefix "${wine_prefix}")"
    gecko_32_bit_msi_name="$(get_gecko_32_bit_msi_name_from_wine_prefix "${wine_prefix}")"
    wine_cache_directory="$(get_wine_cache_directory_for_user "${username}")"
    debug "${dbg}" "Installing 32 Bit Gecko: WINEPREFIX=${wine_prefix} WINEARCH=${wine_arch} wine msiexec /i ${wine_cache_directory}/${gecko_32_bit_msi_name}"
    WINEPREFIX="${wine_prefix}" WINEARCH="${wine_arch}" wine msiexec /i "${wine_cache_directory}/${gecko_32_bit_msi_name}"

    if [[ "${wine_arch}" == "win64" ]]; then
        gecko_64_bit_msi_name="$(get_gecko_64_bit_msi_name_from_wine_prefix "${wine_prefix}")"
        debug "${dbg}" "Installing 64 Bit Gecko: WINEPREFIX=${wine_prefix} WINEARCH=${wine_arch} wine msiexec /i ${wine_cache_directory}/${gecko_64_bit_msi_name}"
        WINEPREFIX="${wine_prefix}" WINEARCH="${wine_arch}" wine msiexec /i "${wine_cache_directory}/${gecko_64_bit_msi_name}"
    fi
}


## make it possible to call functions without source include
call_function_from_commandline "${0}" "${@}"
