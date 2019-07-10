#!/bin/bash

function include_dependencies {
    source /usr/lib/lib_bash/lib_color.sh
    source /usr/lib/lib_bash/lib_retry.sh
    source /usr/lib/lib_bash/lib_helpers.sh
    source /usr/lib/lib_bash_wine/900_000_lib_bash_wine.sh
}

include_dependencies  # we need to do that via a function to have local scope of my_dir

function install_wine_python_preinstalled {
    # $1: python_version_short, eg. "python27", "python37"
    # $2: python_version_doc, eg. "Python 2.7", "Python 3.7"
    # $3: python_directory_prefix, eg. "c:/Python27", "c:/Python37" - will become "c:/Python27-32", "c:/Python27-64", "c:/Python37-32", "c:/Python37-64" depending on the Wine Arch
    # these values can not be set freely, because they depend on the repositories to download the preinstalled python versions - change with care !

    local python_version_short="${1}"
    local python_version_doc="${2}"
    local python_directory_prefix="${3}"

    local linux_codename=$(get_linux_codename)                                  # @lib_bash/bash_helpers
    local wine_release=$(get_wine_release_from_environment_or_default_to_devel) # @lib_bash_wine
    local wine_prefix=$(get_and_export_wine_prefix_or_default_to_home_wine)     # @lib_bash_wine
    local wine_arch=$(get_and_export_wine_arch_from_wine_prefix "${wine_prefix}")          # @lib_bash_wine
    local wine_version_number=$(get_wine_version_number)  # @lib_bash_wine

    local wine_drive_c_dir=${wine_prefix}/drive_c
    local decompress_dir=${HOME}/bitranox_decompress

    local pythonpath_to_add=""

    banner "Installing {$python_version_doc}:${IFS}linux=${linux_codename}${IFS}wine_release=${wine_release}${IFS}wine_version=${wine_version_number}${IFS}WINEPREFIX=${wine_prefix}${IFS}WINEARCH=${wine_arch}"
    mkdir -p ${decompress_dir}  # here we dont need sudo because its the home directory


    banner "Downloading ${python_version_doc} Binaries from https://github.com/bitranox/binaries_${python_version_short}_wine/archive/master.zip"
    retry_nofail wget -nc --no-check-certificate -O ${decompress_dir}/binaries_${python_version_short}_wine-master.zip https://github.com/bitranox/binaries_${python_version_short}_wine/archive/master.zip
    clr_green "Unzip ${python_version_doc} Master to ${decompress_dir}"
    unzip -oqq ${decompress_dir}/binaries_${python_version_short}_wine-master.zip -d ${decompress_dir}
    clr_green "Joining Multipart Zip for ${wine_arch} to ${decompress_dir}/binaries_${python_version_short}_wine-master/bin"
    if [[ "${wine_arch}" == "win32" ]]; then
        cat ${decompress_dir}/binaries_${python_version_short}_wine-master/bin/python*_wine_32* > ${decompress_dir}/binaries_${python_version_short}_wine-master/bin/joined_${python_version_short}.zip
        pythonpath_to_add="${python_directory_prefix}-32;${python_directory_prefix}-32/Scripts"
    else
        cat ${decompress_dir}/binaries_${python_version_short}_wine-master/bin/python*_wine_64* > ${decompress_dir}/binaries_${python_version_short}_wine-master/bin/joined_${python_version_short}.zip
        pythonpath_to_add="${python_directory_prefix}-64;${python_directory_prefix}-64/Scripts"
    fi

    clr_green "Unzip ${python_version_doc} for ${wine_arch} to ${wine_drive_c_dir}"
    unzip -oqq ${decompress_dir}/binaries_${python_version_short}_wine-master/bin/joined_${python_version_short}.zip -d ${wine_drive_c_dir}

    clr_green "Adding path to wine registry: ${pythonpath_to_add}"
    prepend_path_to_wine_registry "${pythonpath_to_add}"

    clr_green "Test python"
    wine pip install --user --upgrade pip

    banner "You might remove the directory ${decompress_dir} if You have space issues${IFS}and dont plan to install some more wine machines"
    banner "Finished installing {$python_version_doc}:${IFS}linux=${linux_codename}${IFS}wine_release=${wine_release}${IFS}wine_version=${wine_version_number}${IFS}WINEPREFIX=${wine_prefix}${IFS}WINEARCH=${wine_arch}"

}
