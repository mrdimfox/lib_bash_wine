#!/bin/bash

sudo_askpass="$(command -v ssh-askpass)"
export SUDO_ASKPASS="${sudo_askpass}"
export NO_AT_BRIDGE=1  # get rid of (ssh-askpass:25930): dbind-WARNING **: 18:46:12.019: Couldn't register with accessibility bus: Did not receive a reply.

export bitranox_debug_global="${bitranox_debug_global}"  # set to True for global Debug
export debug_lib_bash_wine="${debug_lib_bash_wine}"  # set to True for Debug in lib_bash_wine

# call the update script if nout sourced
if [[ "${0}" == "${BASH_SOURCE[0]}" ]] && [[ -d "${BASH_SOURCE%/*}" ]]; then "${BASH_SOURCE%/*}"/install_or_update.sh else "${PWD}"/install_or_update.sh ; fi



function update_myself {
    /usr/local/lib_bash_wine/install_or_update.sh "${@}" || exit 0              # exit old instance after updates
}


update_myself ${0}

function include_dependencies {
    source /usr/local/lib_bash/lib_color.sh
    source /usr/local/lib_bash/lib_retry.sh
    source /usr/local/lib_bash/lib_helpers.sh
    source /usr/local/lib_bash_wine/900_000_lib_bash_wine.sh
}

include_dependencies  # we need to do that via a function to have local scope of my_dir


function download_latest_portable_git_html {
    # $1: decompress_dir
    local decompress_dir="${1}"
    retry wget -O ${decompress_dir}/latest_portable_git.html https://github.com/git-for-windows/git/releases/latest
}

function get_portable_git_filename {
    # $1: decompress_dir
    # $2: str_32_or_64_bit - 32 or 64
    # returns for instance "PortableGit-2.22.0-64-bit.7z.exe"
    local decompress_dir="${1}"
    local str_32_or_64_bit="${2}"
    local portable_git_filename=$(cat ${decompress_dir}/latest_portable_git.html | grep "<td>PortableGit" | grep "64-bit" | cut -d ">" -f 2 | cut -d "<" -f 1)    # --> PortableGit-2.22.0-64-bit.7z.exe
    if [[ -z ${portable_git_filename} ]]; then
        fail "lib_bash_wine/004_000_install_wine_git_portable@get_portable_git_filename : can not get PortableGit Filename, decompress_dir=${decompress_dir}, str_32_or_64_bit=${str_32_or_64_bit}"
    else
        echo ${portable_git_filename}
    fi
}

function get_portable_git_version {
    # $1: decompress_dir
    # $2: str_32_or_64_bit - 32 or 64
    # returns for instance "2.22.0"
    local decompress_dir="${1}"
    local str_32_or_64_bit="${2}"
    local portable_git_filename=$(get_portable_git_filename ${decompress_dir} ${str_32_or_64_bit})
    local portable_git_version=$(echo ${portable_git_filename} | cut -d "-" -f 2)
    echo ${portable_git_version}
}


function get_latest_download_link_for_git_portable {
    # $1: decompress_dir
    # $2: str_32_or_64_bit - 32 or 64
    # download_latest_portable_git_html needs to be called before, to have the html file !!!
    local decompress_dir="${1}"
    local str_32_or_64_bit="${2}"
    local portable_git_filename=$(get_portable_git_filename ${decompress_dir} ${str_32_or_64_bit})
    local portable_git_version=$(get_portable_git_version ${decompress_dir} ${str_32_or_64_bit})
    local download_link="https://github.com/git-for-windows/git/releases/download/v${portable_git_version}.windows.1/${portable_git_filename}"
    echo "${download_link}"
}


function install_git_portable {

    local linux_release_name=$(get_linux_release_name)                                  # @lib_bash/bash_helpers
    local wine_release=$(get_wine_release_from_environment_or_default_to_devel) # @lib_bash_wine
    local wine_prefix=$(get_and_export_wine_prefix_or_default_to_home_wine)     # @lib_bash_wine
    local wine_arch=$(get_and_export_wine_arch_from_wine_prefix "${wine_prefix}")          # @lib_bash_wine
    local wine_version_number=$(get_wine_version_number)  # @lib_bash_wine

    local wine_drive_c_dir=${wine_prefix}/drive_c
    local decompress_dir=${HOME}/bitranox_decompress
    local str_32_or_64_bit=$(get_str_32_or_64_from_wine_prefix ${wine_prefix})          # returns "32" oder "64"
    local str_x86_or_x64=$(get_str_x86_or_x64_from_wine_prefix ${wine_prefix})      # returns "x86" oder "x64"
    local git_path_to_add="c:/Program Files/PortableGit"
    local git_install_dir="${wine_drive_c_dir}/Program Files/PortableGit"

    download_latest_portable_git_html ${decompress_dir}
    local portable_git_version=$(get_portable_git_version ${decompress_dir} ${str_32_or_64_bit})
    local latest_download_link_for_git_portable=$(get_latest_download_link_for_git_portable ${decompress_dir} ${str_32_or_64_bit})
    local portable_git_filename=$(get_portable_git_filename ${decompress_dir} ${str_32_or_64_bit})

    banner "Installing or upgrading latest PortableGit:${IFS}\
    Portable Git Version=${portable_git_version}${IFS}\
    linux_release_name=${linux_release_name}${IFS}\
    wine_release=${wine_release}${IFS}\
    wine_version=${wine_version_number}${IFS}\
    WINEPREFIX=${wine_prefix}${IFS}\
    WINEARCH=${wine_arch}"

    mkdir -p ${decompress_dir}  # here we dont need sudo because its the home directory

    banner "Downloading latest Git Portable Binaries from ${latest_download_link_for_git_portable}"
    if [[ ! -f ${decompress_dir}/${portable_git_filename} ]]; then
        retry wget -nc --no-check-certificate -O ${decompress_dir}/${portable_git_filename} ${latest_download_link_for_git_portable}
    else
        clr_green "file ${decompress_dir}/${portable_git_filename} does already exist"
    fi

    clr_green "Unzip Git Portable Binaries Master to ${git_path_to_add}"

    $(get_sudo) rm -Rf "${git_install_dir}"
    # see : https://sevenzip.osdn.jp/chm/cmdline/switches/index.htm
    7z e ${decompress_dir}/${portable_git_filename} -o"${git_install_dir}" -y -bb0 -bd
    $(get_sudo) chmod -R 0755 "${git_install_dir}"

    clr_green "Adding path to wine registry: ${git_path_to_add}"
    prepend_path_to_wine_registry_path "${git_path_to_add}"

    clr_green "Test Git"
    wine git --version

    banner "You might remove the directory ${decompress_dir} if You have space issues${IFS}and dont plan to install some more wine machines"
    banner "Finished installing Git Portable:${IFS}linux_release_name=${linux_release_name}${IFS}wine_release=${wine_release}${IFS}wine_version=${wine_version_number}${IFS}WINEPREFIX=${wine_prefix}${IFS}WINEARCH=${wine_arch}"
}


if [[ "${0}" == "${BASH_SOURCE}" ]]; then    # if the script is not sourced
    install_git_portable
fi
