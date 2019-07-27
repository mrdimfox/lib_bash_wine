#!/bin/bash

sudo_askpass="$(command -v ssh-askpass)"
export SUDO_ASKPASS="${sudo_askpass}"
export NO_AT_BRIDGE=1  # get rid of (ssh-askpass:25930): dbind-WARNING **: 18:46:12.019: Couldn't register with accessibility bus: Did not receive a reply.

# call the update script if not sourced
if [[ "${0}" == "${BASH_SOURCE[0]}" ]] && [[ -d "${BASH_SOURCE%/*}" ]]; then "${BASH_SOURCE%/*}"/install_or_update.sh else "${PWD}"/install_or_update.sh ; fi


function include_dependencies {
    local my_dir
    my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"  # this gives the full path, even for sourced scripts
    source /usr/local/lib_bash/lib_helpers.sh
    source "${my_dir}/900_000_lib_bash_wine.sh"
}

include_dependencies


function get_mono_msi_name_from_wine_prefix {
    # tested
    # $1: wine_prefix
    # returns : wine-mono-4.9.0.msi
    local wine_prefix mono_msi_file_name
    wine_prefix="${1}"
    sleep 10
    mono_msi_file_name=$(cat "${wine_prefix}/drive_c/windows/system32/appwiz.cpl" | strings | grep "wine-mono" | grep ".msi")
    echo "${mono_msi_file_name}"
}


function get_mono_version_from_msi_filename {
    # returns the version e.g. "4.9.0"
    # $1 : mono_msi_name e.g. "wine-mono-4.9.0.msi"
    local mono_msi_name
    mono_msi_name="${1}"
    echo "${mono_msi_name}" | cut -d "-" -f 3 | sed "s/.msi//g"
}


function get_wine_mono_download_link_from_msi_filename {
    # gets the download link
    # correct Link1: https://source.winehq.org/winemono.php?v=4.9.0
    # correct Link2: https://dl.winehq.org/wine/wine-mono/4.9.0/wine-mono-4.9.0.msi
    # there is another parameter: # &winev=????, not used here, https://github.com/wine-mirror/wine/blob/master/dlls/appwiz.cpl/addons.c

    # $1 - mono_msi_name
    local mono_msi_name version
    mono_msi_name="${1}"
    version="$(get_mono_version_from_msi_filename "${mono_msi_name}")"
    echo "https://source.winehq.org/winemono.php?v=${version}"
}

function get_wine_mono_download_backup_link_from_msi_filename {
    # gets the download link
    # correct Link2: https://dl.winehq.org/wine/wine-mono/4.9.0/wine-mono-4.9.0.msi
    # $1 - mono_msi_name
    local mono_msi_name version
    mono_msi_name="${1}"
    version="$(get_mono_version_from_msi_filename "${mono_msi_name}")"
    echo "https://dl.winehq.org/wine/wine-mono/${version}/${mono_msi_name}"
}

function download_mono_msi_files {
    # $1 - wine_prefix
    # $2 - username
    local wine_prefix username wine_arch mono_msi_name download_link backup_download_link wine_cache_directory
    wine_prefix="${1}"
    username="${2}"

    fail_if_wine_prefix_is_not_matching_user_home "${wine_prefix}" "${username}"

    wine_arch="$(get_and_export_wine_arch_from_wine_prefix "${wine_prefix}")"
    mono_msi_name="$(get_mono_msi_name_from_wine_prefix "${wine_prefix}")"
    clr_blue "mono_msi_name=${mono_msi_name}"

    if ! is_msi_file_in_winecache "${username}" "${mono_msi_name}"; then
        download_link="$(get_wine_mono_download_link_from_msi_filename "${mono_msi_name}")"
        backup_download_link="$(get_wine_mono_download_backup_link_from_msi_filename "${mono_msi_name}")"
        wine_cache_directory="$(get_wine_cache_directory_for_user)"
        download_msi_file_to_winecache "${username}" "${download_link}" "${mono_msi_name}"
        if [[ ! -f "${wine_cache_directory}/${mono_msi_name}" ]]; then
            download_msi_file_to_winecache "${username}" "${backup_download_link}" "${mono_msi_name}"
        fi
    fi
}


function install_wine_mono {
    # installs the matching wine_gecko on the existing wine machine
    # $1 : wine_prefix
    # $2 : username

    local wine_prefix username wine_arch mono_msi_name gecko_64_bit_msi_name dbg wine_cache_directory
    wine_prefix="${1}"
    username="${2}"
    dbg="True"
    fail_if_wine_prefix_is_not_matching_user_home "${wine_prefix}" "${username}"
    download_mono_msi_files "${wine_prefix}" "${username}"

    wine_arch="$(get_and_export_wine_arch_from_wine_prefix "${wine_prefix}")"
    mono_msi_name="$(get_mono_msi_name_from_wine_prefix "${wine_prefix}")"
    wine_cache_directory="$(get_wine_cache_directory_for_user "${username}")"
    debug "${dbg}" "Installing 32 Bit Mono: WINEPREFIX=${wine_prefix} WINEARCH=${wine_arch} wine msiexec /i ${wine_cache_directory}/${mono_msi_name}"
    WINEPREFIX="${wine_prefix}" WINEARCH="${wine_arch}" wine msiexec /i "${wine_cache_directory}/${mono_msi_name}"
}


## make it possible to call functions without source include
call_function_from_commandline "${0}" "${@}"
