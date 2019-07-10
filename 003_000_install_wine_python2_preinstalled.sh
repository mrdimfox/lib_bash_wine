#!/bin/bash

function update_myself {
    /usr/lib/lib_bash_wine/install_or_update_lib_bash_wine.sh "${@}" || exit 0              # exit old instance after updates
}

function include_dependencies {
    source /usr/lib/lib_bash/lib_color.sh
    source /usr/lib/lib_bash/lib_retry.sh
    source /usr/lib/lib_bash/lib_helpers.sh
    source /usr/lib/lib_bash_wine/lib_bash_wine.sh
}

include_dependencies  # we need to do that via a function to have local scope of my_dir

function install_wine_python2_preinstalled {

    local sudo_command=$(get_sudo_command)                                      # @lib_bash/bash_helpers
    local linux_codename=$(get_linux_codename)                                  # @lib_bash/bash_helpers
    local wine_release=$(get_wine_release_from_environment_or_default_to_devel) # @lib_bash_wine
    local wine_prefix=$(get_and_export_wine_prefix_or_default_to_home_wine)     # @lib_bash_wine
    local wine_arch=$(get_and_export_wine_arch_or_default_to_win64)             # @lib_bash_wine
    local wine_windows_version=$(get_wine_windows_version_or_default_to_win10)  # @lib_bash_wine
    local wine_version_number=$(get_wine_version_number)  # @lib_bash_wine

    local wine_drive_c_dir=${wine_prefix}/drive_c
    local decompress_dir=${HOME}/bitranox_decompress

    local python_version_short=python27
    local python_version_doc="Python 2.7"
    local pythonpath_to_add=""

    banner "Installing Python 2.7:${IFS}linux=${linux_codename}${IFS}wine_release=${wine_release}${IFS}wine_version=${wine_version_number}${IFS}WINEPREFIX=${wine_prefix}${IFS}WINEARCH=${wine_arch}${IFS}wine_windows_version=${wine_windows_version}"
    mkdir -p ${decompress_dir}  # here we dont need sudo because its the home directory

    banner "Downloading ${python_version_doc} Binaries from https://github.com/bitranox/binaries_${python_version_short}_wine/archive/master.zip"
    retry wget -nc --no-check-certificate -O ${decompress_dir}/binaries_${python_version_short}_wine-master.zip https://github.com/bitranox/binaries_${python_version_short}_wine/archive/master.zip
    clr_green "Unzip ${python_version_doc} Master to ${decompress_dir}"
    unzip -nqq ${decompress_dir}/binaries_${python_version_short}_wine-master.zip -d ${decompress_dir}

    if [[ "${wine_arch}" == "win32" ]]; then
        clr_green "Joining Multipart Zip for ${wine_arch} to ${decompress_dir}/binaries_${python_version_short}_wine-master/bin"
        cat ${decompress_dir}/binaries_${python_version_short}_wine-master/bin/python*_wine_32* > ${decompress_dir}/binaries_${python_version_short}_wine-master/bin/joined_${python_version_short}.zip
        pythonpath_to_add="c:/Python27-32;c:/Python27-32/Scripts"
    else
        clr_green "Joining Multipart Zip for ${wine_arch} to ${decompress_dir}/binaries_${python_version_short}_wine-master/bin"
        cat ${decompress_dir}/binaries_${python_version_short}_wine-master/bin/python*_wine_64* > ${decompress_dir}/binaries_${python_version_short}_wine-master/bin/joined_${python_version_short}.zip
        pythonpath_to_add="c:/Python27-64;c:/Python27-64/Scripts"
    fi

    clr_green "Unzip ${python_version_doc} for ${wine_arch} to ${wine_drive_c_dir}"
    unzip -qq ${decompress_dir}/binaries_${python_version_short}_wine-master/bin/joined_${python_version_short}.zip -d ${wine_drive_c_dir}

    clr_green "Appending path to wine pythonpath: ${pythonpath_to_add}"
    prepend_path_to_wine_registry "${pythonpath_to_add}"

    banner "You might remove the directory ${decompress_dir} if You have space issues and dont plan to install some more wine machines"
    banner "Finished installing Python 2.7:${IFS}linux=${linux_codename}${IFS}wine_release=${wine_release}${IFS}wine_version=${wine_version_number}${IFS}WINEPREFIX=${wine_prefix}${IFS}WINEARCH=${wine_arch}${IFS}wine_windows_version=${wine_windows_version}"

}

update_myself ${0} ${@}                                                              # pass own script name and parameters
install_wine_python2_preinstalled
