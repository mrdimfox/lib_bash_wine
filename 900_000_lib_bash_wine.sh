#!/bin/bash

function include_dependencies {
    local my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"  # this gives the full path, even for sourced scripts
    source /usr/lib/lib_bash/lib_color.sh
    source /usr/lib/lib_bash/lib_retry.sh
    source /usr/lib/lib_bash/lib_helpers.sh
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
    local wine_arch=$( cat "${wine_prefix}"/system.reg | grep "#arch=" | cut -d "=" -f 2 )
    if [[ "${wine_arch}" != "win32" ]] && [[ "${wine_arch}" != "win64" ]]; then
        fail "WINEARCH for WINEPREFIX=${wine_prefix} can not be determined"
    fi
    export WINEARCH="${wine_arch}"
    echo "${wine_arch}"
}


function prepend_path_to_wine_registry {
    local add_pythonpath="${1}"
    local wine_new_reg_path=""
    local wine_actual_reg_path=""
    local wine_current_reg_path=""
    clr_green "add Path Settings to Registry"
    # local wine_current_reg_path="`wine reg QUERY \"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\" /v PATH | grep REG_SZ | sed 's/^.*REG_SZ\s*//'`"
    wine_current_reg_path="`wine reg QUERY \"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\" /v PATH | grep "_SZ" | sed 's/^.*_SZ\s*//'`"
    clr_green "current Wine Registry Path=${wine_current_reg_path}"
    if [[ "$(get_is_string1_in_string2) \"${add_pythonpath}\" \"${wine_current_reg_path}\"" == "False" ]]; then
        wine_new_reg_path="${add_pythonpath};${wine_current_reg_path}"
        clr_green "new Wine Registry PATH=${wine_new_reg_path}"
        wine reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /t REG_SZ /v PATH /d "${wine_new_reg_path}" /f
        # local wine_actual_reg_path="`wine reg QUERY \"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\" /v PATH | grep REG_SZ | sed 's/^.*REG_SZ\s*//'`"
        wine_actual_reg_path="`wine reg QUERY \"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\" /v PATH | grep "\_SZ" | sed 's/^.*_SZ\s*//'`"
        clr_green "adding Path done"
    else
        clr_green "Path was already added"
        # local wine_actual_reg_path="`wine reg QUERY \"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\" /v PATH | grep REG_SZ | sed 's/^.*REG_SZ\s*//'`"
        wine_actual_reg_path="`wine reg QUERY \"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\" /v PATH | grep "_SZ" | sed 's/^.*_SZ\s*//'`"
    fi
    clr_green "new Wine Registry PATH=${wine_actual_reg_path}"
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
