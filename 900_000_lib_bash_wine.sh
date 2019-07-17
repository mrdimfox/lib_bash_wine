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


function get_is_xvfb_service_active {
    local is_xvfb_active="False"
    systemctl is-active --quiet xvfb && is_xvfb_active="True"
    echo "${is_xvfb_active}"
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




function get_is_wine_path_reg_sz_set {
    local wine_current_reg_path
    wine_current_reg_path="$(wine reg QUERY "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment" /v PATH | grep -c REG_SZ)"
    if [[ "${wine_current_reg_path}" == "0" ]]; then
        echo "False"
    else
        echo "True"
    fi
}

function get_is_wine_path_reg_expand_sz_set {
    local wine_current_reg_path
    wine_current_reg_path="$(wine reg QUERY "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment" /v PATH | grep REG_EXPAND_SZ | sed 's/^.*REG_EXPAND_SZ\s*//')"
    if [[ "${wine_current_reg_path}" == "0" ]]; then
        echo "False"
    else
        echo "True"
    fi
}

function get_wine_path_reg_sz {
    local wine_current_reg_path
    wine_current_reg_path="$(wine reg QUERY "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment" /v PATH | grep REG_SZ | sed 's/^.*REG_SZ\s*//')"
    echo "${wine_current_reg_path}"
}

function get_wine_path_reg_expand_sz {
    local wine_current_reg_path
    wine_current_reg_path="$(wine reg QUERY "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment" /v PATH | grep REG_EXPAND_SZ | sed 's/^.*REG_EXPAND_SZ\s*//')"
    echo "${wine_current_reg_path}"
}


function set_wine_path_reg_sz {
    # $1: new_wine_path
    local new_wine_path
    new_wine_path="${1}"
    wine reg add "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment" /t REG_SZ /v PATH /d "${new_wine_path}" /f
}


function set_wine_path_reg_expand_sz {
    # $1: new_wine_path
    local new_wine_path
    new_wine_path="${1}"
    wine reg add "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment" /t REG_EXPAND_SZ /v PATH /d "${new_wine_path}" /f
}


function get_prepended_path {
    # $1: path_to_add
    # $2: current_path
    local path_to_add current_path prepended_path
    path_to_add="${1}"
    current_path="${2}"
    prepended_path="${current_path}"
    if is_str1_in_str2 "\"${path_to_add}\" \"${current_path}\""; then
        prepended_path="${path_to_add};${current_path}"
    fi
    echo "${prepended_path}"
}


function prepend_path_to_wine_registry {
    local add_path current_path_reg_sz new_path_reg_sz current_path_reg_expand_sz new_path_reg_expand_sz
    add_path="${1}"
    current_path_reg_sz=""
    new_path_reg_sz=""
    current_path_reg_expand_sz=""
    new_path_reg_expand_sz=""

    if [[ $(get_is_wine_path_reg_sz_set) == "True" ]]; then
        clr_green "add path_reg_sz to Wine Registry"
        current_path_reg_sz="$(get_wine_path_reg_sz)"
        new_path_reg_sz=$(get_prepended_path "${add_path}" "${current_path_reg_sz}")
        set_wine_path_reg_sz "${new_path_reg_sz}"
    fi

    if [[ $(get_is_wine_path_reg_expand_sz_set) == "True" ]]; then
        clr_green "add path_reg_expand_sz to Wine Registry"
        current_path_reg_expand_sz="$(get_wine_path_reg_expand_sz)"
        new_path_reg_expand_sz=$(get_prepended_path "${add_path}" "${current_path_reg_expand_sz}")
        set_wine_path_reg_expand_sz "${new_path_reg_expand_sz}"
    fi
    banner "\
Adding wine paths done:${IFS}\
original path_reg_sz: ${current_path_reg_sz}${IFS}\
     new path_reg_sz: ${new_path_reg_sz}${IFS}\
     original path_reg_expand_sz: ${current_path_reg_expand_sz}${IFS}\
          new path_reg_expand_sz: ${new_path_reg_expand_sz}"
}


## make it possible to call functions without source include
# Check if the function exists (bash specific)
if [[ ! -z "$1" ]]
    then
        if declare -f "${1}" > /dev/null
        then
          # call arguments verbatim
          "$@"
        else
          # Show a helpful error
          function_name="${1}"
          library_name="${0}"
          fail "\"${function_name}\" is not a known function name of \"${library_name}\""
        fi
	fi


function fix_wine_permissions {
    local user
    user="$(printenv USER)"
    "$(get_sudo)" chown -R "${user}" "${WINEPREFIX}"
    "$(get_sudo)" chgrp -R "${user}" "${WINEPREFIX}"
}

function tests {
    # shellcheck disable=SC2164
	# local my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"  # this gives the full path, even for sourced scripts
	# debug "${debug_lib_bash_wine}" "no tests"
	test_get_prepended_path
}


## make it possible to call functions without source include
call_function_from_commandline "${0}" "${@}"
