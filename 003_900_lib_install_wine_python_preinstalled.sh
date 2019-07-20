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
    # shellcheck disable=SC2164
    my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"  # this gives the full path, even for sourced scripts
    source /usr/local/lib_bash/lib_helpers.sh
    source "${my_dir}/900_000_lib_bash_wine.sh"
}

include_dependencies


function install_wine_python_preinstalled {
    # $1: python_version_short, eg. "python37"
    # $2: python_version_doc, eg. "Python 3.7"
    # $3: python_directory_prefix, eg. "c:/Python37" - will become "c:/Python37-32", "c:/Python37-64" depending on the Wine Arch
    # these values can not be set freely, because they depend on the repositories to download the preinstalled python versions - change with care !
    local python_version_short python_version_doc python_directory_prefix linux_release_name wine_release wine_prefix wine_arch wine_version_number wine_drive_c_dir decompress_dir pythonpath_to_add

    python_version_short="${1}"
    python_version_doc="${2}"
    python_directory_prefix="${3}"

    linux_release_name="$(get_linux_release_name)"
    wine_release="$(get_and_export_wine_release_from_environment_or_default_to_devel)"
    wine_prefix="$(get_and_export_wine_prefix_from_environment_or_default_to_home_wine)"
    wine_arch="$(get_and_export_wine_arch_from_wine_prefix "${wine_prefix}")"
    wine_version_number="$(get_wine_version_number)"

    wine_drive_c_dir="${wine_prefix}/drive_c"
    decompress_dir="${HOME}/bitranox_decompress"

    banner "\
Installing {$python_version_doc}:${IFS}\
linux_release_name=${linux_release_name}${IFS}\
wine_release=${wine_release}${IFS}\
wine_version=${wine_version_number}${IFS}\
WINEPREFIX=${wine_prefix}${IFS}\
WINEARCH=${wine_arch}"

    mkdir -p "${decompress_dir}"  # here we dont need sudo because its the home directory

    banner "Downloading ${python_version_doc} Binaries from https://github.com/bitranox/binaries_${python_version_short}_wine/archive/master.zip"

    retry_nofail wget -nv -c -nc --no-check-certificate -O "${decompress_dir}/binaries_${python_version_short}_wine-master.zip" "https://github.com/bitranox/binaries_${python_version_short}_wine/archive/master.zip"
    clr_green "Unzip ${python_version_doc} Master to ${decompress_dir}"
    unzip -oqq "${decompress_dir}/binaries_${python_version_short}_wine-master.zip" -d "${decompress_dir}"
    clr_green "Joining Multipart Zip for ${wine_arch} to ${decompress_dir}/binaries_${python_version_short}_wine-master/bin"
    if [[ "${wine_arch}" == "win32" ]]; then
        cat "${decompress_dir}/binaries_${python_version_short}_wine-master/bin/python*_wine_32*" > "${decompress_dir}/binaries_${python_version_short}_wine-master/bin/joined_${python_version_short}.zip"
        pythonpath_to_add="${python_directory_prefix}-32;${python_directory_prefix}-32\\Scripts"
    else
        cat "${decompress_dir}/binaries_${python_version_short}_wine-master/bin/python*_wine_64*" > "${decompress_dir}/binaries_${python_version_short}_wine-master/bin/joined_${python_version_short}.zip"
        pythonpath_to_add="${python_directory_prefix}-64;${python_directory_prefix}-64\\Scripts"
    fi

    clr_green "Unzip ${python_version_doc} for ${wine_arch} to ${wine_drive_c_dir}"
    unzip -oqq "${decompress_dir}/binaries_${python_version_short}_wine-master/bin/joined_${python_version_short}.zip" -d "${wine_drive_c_dir}"

    clr_green "Adding path to wine registry: ${pythonpath_to_add}"
    prepend_path_to_wine_registry_path "${wine_prefix}" "${pythonpath_to_add}"

    clr_green "Test python"
    wine pip install --user --upgrade pip

    banner "You might remove the directory ${decompress_dir} if You have space issues${IFS}and dont plan to install some more wine machines"
    banner "Finished installing {$python_version_doc}:${IFS}linux_release_name=${linux_release_name}${IFS}wine_release=${wine_release}${IFS}wine_version=${wine_version_number}${IFS}WINEPREFIX=${wine_prefix}${IFS}WINEARCH=${wine_arch}"

}


call_function_from_commandline "${0}" "${@}"