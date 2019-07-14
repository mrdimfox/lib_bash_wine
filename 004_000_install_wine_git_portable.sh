#!/bin/bash


function update_myself {
    /usr/local/lib_bash_wine/install_or_update.sh "${@}" || exit 0              # exit old instance after updates
}


if [[ ! -z "$1" ]] && declare -f "${1}" ; then
    update_myself ${0}
else
    update_myself ${0} ${@}  > /dev/null 2>&1  # suppress messages here, not to spoil up answers from functions  when called verbatim
fi


function include_dependencies {
    source /usr/local/lib_bash/lib_color.sh
    source /usr/local/lib_bash/lib_retry.sh
    source /usr/local/lib_bash/lib_helpers.sh
    source /usr/local/lib_bash_wine/900_000_lib_bash_wine.sh
}

include_dependencies  # we need to do that via a function to have local scope of my_dir


function install_git_portable {

    local linux_release_name=$(get_linux_release_name)                                  # @lib_bash/bash_helpers
    local wine_release=$(get_wine_release_from_environment_or_default_to_devel) # @lib_bash_wine
    local wine_prefix=$(get_and_export_wine_prefix_or_default_to_home_wine)     # @lib_bash_wine
    local wine_arch=$(get_and_export_wine_arch_from_wine_prefix "${wine_prefix}")          # @lib_bash_wine
    local wine_version_number=$(get_wine_version_number)  # @lib_bash_wine

    local wine_drive_c_dir=${wine_prefix}/drive_c
    local decompress_dir=${HOME}/bitranox_decompress

    local git_path_to_add=""

    banner "Installing Git Portable:${IFS}linux_release_name=${linux_release_name}${IFS}wine_release=${wine_release}${IFS}wine_version=${wine_version_number}${IFS}WINEPREFIX=${wine_prefix}${IFS}WINEARCH=${wine_arch}"
    mkdir -p ${decompress_dir}  # here we dont need sudo because its the home directory

    clr_green "Download Git Portable Binaries"
    banner "Downloading Git Portable Binaries from https://github.com/bitranox/binaries_portable_git/archive/master.zip"
    retry_nofail wget -nc --no-check-certificate -O ${decompress_dir}/binaries_portable_git-master.zip https://github.com/bitranox/binaries_portable_git/archive/master.zip

    clr_green "Unzip Git Portable Binaries Master to ${decompress_dir}"
    unzip -oqq ${decompress_dir}/binaries_portable_git-master.zip -d ${decompress_dir}

    clr_green "Joining Multipart Zip for ${wine_arch} to ${decompress_dir}/binaries_portable_git-master/bin"
    if [[ "${wine_arch}" == "win32" ]]; then
        cat ${decompress_dir}/binaries_portable_git-master/bin/PortableGit32* > ${decompress_dir}/binaries_portable_git-master/bin/joined_PortableGit.zip
        git_path_to_add="c:/PortableGit32/cmd"
    else
        cat ${decompress_dir}/binaries_portable_git-master/bin/PortableGit64* > ${decompress_dir}/binaries_portable_git-master/bin/joined_PortableGit.zip
        git_path_to_add="c:/PortableGit64/cmd"
    fi

    clr_green "Unzip Git Portable Binaries for ${wine_arch} to ${wine_drive_c_dir}"
    unzip -oqq ${decompress_dir}/binaries_portable_git-master/bin/joined_PortableGit.zip -d ${wine_drive_c_dir}

    clr_green "Adding path to wine registry: ${git_path_to_add}"
    prepend_path_to_wine_registry "${git_path_to_add}"

    clr_green "Test Git"
    wine git --version

    banner "You might remove the directory ${decompress_dir} if You have space issues${IFS}and dont plan to install some more wine machines"
    banner "Finished installing Git Portable:${IFS}linux_release_name=${linux_release_name}${IFS}wine_release=${wine_release}${IFS}wine_version=${wine_version_number}${IFS}WINEPREFIX=${wine_prefix}${IFS}WINEARCH=${wine_arch}"
}


install_git_portable

