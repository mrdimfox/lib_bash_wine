#!/bin/bash


function include_dependencies {
    local my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"  # this gives the full path, even for sourced scripts
    source /usr/local/lib_bash/lib_color.sh
    source /usr/local/lib_bash/lib_retry.sh
    source /usr/local/lib_bash/lib_helpers.sh
}

include_dependencies  # we need to do that via a function to have local scope of my_dir


function fail {
  clr_bold clr_red "${1}" >&2
  exit 1
}


function get_wine_release_from_environment_or_default_to_devel {
    if [[ -z ${wine_release} ]]; then
        echo "devel"
    else
        echo "${wine_release}"
    fi
}

function get_and_export_wine_prefix_or_default_to_home_wine {
    ## set wine prefix to ${HOME}/.wine if not given by environment variable
    if [[ -z ${WINEPREFIX} ]]; then
        local wine_prefix="${HOME}/.wine"
    else
        local wine_prefix="${WINEPREFIX}"
    fi
    export WINEPREFIX="${wine_prefix}"
    echo "${wine_prefix}"
}

function get_and_export_wine_arch_or_default_to_win64 {
    if [[ -z ${WINEARCH} ]]; then
            local wine_arch="win64"
    else
        local wine_arch="${WINEARCH}"
    fi
    export WINEARCH="${wine_arch}"
    echo "${wine_arch}"
}


function get_wine_windows_version_or_default_to_win10 {
    if [[ -z ${wine_windows_version} ]]; then
            local wine_win_ver=${wine_windows_version}
        else
            local wine_win_ver="win10"
        fi
    echo "${wine_win_ver}"
}


function get_is_xvfb_service_active {
    local is_xvfb_active="False"
    systemctl is-active --quiet xvfb && is_xvfb_active="True"
    echo "${is_xvfb_active}"
}

function get_wine_version_number {
    local wine_version_number=`wine --version`
    echo "${wine_version_number}"
}

function get_and_export_wine_arch_from_wine_prefix {
    # $1: wine_prefix
    local wine_prefix="${1}"
    local wine_arch=$(cat ${wine_prefix}/system.reg | grep "#arch=" | cut -d "=" -f 2)
    if [[ "${wine_arch}" != "win32" ]] && [[ "${wine_arch}" != "win64" ]]; then
        fail "get_and_export_wine_arch_from_wine_prefix: WINEARCH for WINEPREFIX=${wine_prefix} can not be determined, wine_arch=${wine_arch}"
    fi
    export WINEARCH="${wine_arch}"
    echo "${wine_arch}"
}


function get_str_32_or_64_from_wine_prefix {
    # $1: wine_prefix
    # returns "32" or "64" for the given wine_prefix
    local wine_prefix="${1}"
    local wine_arch=$(get_and_export_wine_arch_from_wine_prefix \"${wine_prefix}\")
    if [[ ${wine_arch} == "win32" ]]; then
        echo "32"
    elif [[ ${wine_arch} == "win64" ]]; then
        echo "64"
    else
        fail "get_str_32_or_64_from_wine_prefix: can not determine architecture for wine_prefix=${wine_prefix}, wine_arch=${wine_arch}"
    fi
}


function get_str_x86_or_x64_from_wine_prefix {
    # $1: wine_prefix
    # returns "x86" or "x64" for the given wine_prefix
    local wine_prefix="${1}"
    local wine_arch=$(get_and_export_wine_arch_from_wine_prefix \"${wine_prefix}\")
    if [[ ${wine_arch} == "win32" ]]; then
        echo "x86"
    elif [[ ${wine_arch} == "win64" ]]; then
        echo "x64"
    else
        fail "get_str_x86_or_x64_from_wine_prefix: can not determine architecture for wine_prefix=${wine_prefix}, wine_arch=${wine_arch}"
    fi
}




function get_is_wine_path_reg_sz_set {
    local wine_current_reg_path="`wine reg QUERY \"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\" /v PATH | grep -c REG_SZ`"
    if [[ "${wine_current_reg_path}" == "0" ]]; then
        echo "False"
    else
        echo "True"
    fi
}

function get_is_wine_path_reg_expand_sz_set {
    local wine_current_reg_path="`wine reg QUERY \"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\" /v PATH | grep REG_EXPAND_SZ | sed 's/^.*REG_EXPAND_SZ\s*//'`"
    if [[ "${wine_current_reg_path}" == "0" ]]; then
        echo "False"
    else
        echo "True"
    fi
}

function get_wine_path_reg_sz {
    local wine_current_reg_path="`wine reg QUERY \"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\" /v PATH | grep REG_SZ | sed 's/^.*REG_SZ\s*//'`"
    echo "${wine_current_reg_path}"
}

function get_wine_path_reg_expand_sz {
    local wine_current_reg_path="`wine reg QUERY \"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\" /v PATH | grep REG_EXPAND_SZ | sed 's/^.*REG_EXPAND_SZ\s*//'`"
    echo "${wine_current_reg_path}"
}


function set_wine_path_reg_sz {
    # $1: new_wine_path
    local new_wine_path="${1}"
    wine reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /t REG_SZ /v PATH /d "${new_wine_path}" /f
}


function set_wine_path_reg_expand_sz {
    # $1: new_wine_path
    local new_wine_path="${1}"
    wine reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /t REG_EXPAND_SZ /v PATH /d "${new_wine_path}" /f
}


function get_prepended_path {
    # $1: path_to_add
    # $2: current_path
    local path_to_add="${1}"
    local current_path="${2}"
    local prepended_path="${current_path}"
    if [[ "$(get_is_string1_in_string2 \"${path_to_add}\" \"${current_path}\")" == "False" ]]; then
        prepended_path="${path_to_add};${current_path}"
    fi
    echo "${prepended_path}"
}


function prepend_path_to_wine_registry {
    local add_path="${1}"
    local current_path_reg_sz=""
    local new_path_reg_sz=""
    local current_path_reg_expand_sz=""
    local new_path_reg_expand_sz=""


    if [[ $(get_is_wine_path_reg_sz_set) == "True" ]]; then
        clr_green "add path_reg_sz to Wine Registry"
        current_path_reg_sz="$(get_wine_path_reg_sz)"
        new_path_reg_sz="$(get_prepended_path \"${add_path}\" \"${current_path_reg_sz}\")"
        set_wine_path_reg_sz "${new_path_reg_sz}"
    fi

    if [[ $(get_is_wine_path_reg_expand_sz_set) == "True" ]]; then
        clr_green "add path_reg_expand_sz to Wine Registry"
        current_path_reg_expand_sz="$(get_wine_path_reg_expand_sz)"
        new_path_reg_expand_sz="$(get_prepended_path \"${add_path}\" \"${current_path_reg_expand_sz}\")"
        set_wine_path_reg_expand_sz "${new_path_reg_expand_sz}"
    fi
    banner "Adding wine paths done:${IFS}original path_reg_sz: ${current_path_reg_sz}${IFS}     new path_reg_sz: ${new_path_reg_sz}${IFS}original path_reg_expand_sz: ${current_path_reg_expand_sz}${IFS}     new path_reg_expand_sz: ${new_path_reg_expand_sz}"
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
    $(which sudo) chown -R ${USER} ${WINEPREFIX}
    $(which sudo) chgrp -R ${USER} ${WINEPREFIX}
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


function get_overwrite_existing_wine_machine {
    local overwrite_existing_wine_machine=${automatic_overwrite_existing_wine_machine}
    if [[ "${overwrite_existing_wine_machine}" == "True" ]]; then
        echo "True"
    else
        echo "False"
    fi
}