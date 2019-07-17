#!/bin/bash

export SUDO_ASKPASS="$(command -v ssh-askpass)"
export NO_AT_BRIDGE=1  # get rid of (ssh-askpass:25930): dbind-WARNING **: 18:46:12.019: Couldn't register with accessibility bus: Did not receive a reply.

export bitranox_debug_global="${bitranox_debug_global}"  # set to True for global Debug
# export debug_lib_bash_wine="False"



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

function install_wine_machine {
    banner "Install Wine Machine"
    local linux_release_name=$(get_linux_release_name)                                  # @lib_bash/bash_helpers
    local wine_release=$(get_wine_release_from_environment_or_default_to_devel)         # @lib_bash_wine
    local wine_prefix=$(get_and_export_wine_prefix_or_default_to_home_wine)             # @lib_bash_wine
    local wine_arch=$(get_and_export_wine_arch_or_default_to_win64)                     #@lib_bash_wine
    local wine_windows_version=$(get_wine_windows_version_or_default_to_win10)          # @lib_bash_wine
    local is_xvfb_service_active=$(get_is_xvfb_service_active)                          # @lib_bash_wine
    local wine_version_number=$(get_wine_version_number)                                # @lib_bash_wine
    local automatic_overwrite_existing_wine_machine=$(get_overwrite_existing_wine_machine)    # @lib_bash_wine

    banner "Setup Wine Machine:${IFS}\
            linux_release_name=${linux_release_name}${IFS}\
            wine_release=${wine_release}${IFS}\
            wine_version=${wine_version_number}${IFS}\
            WINEPREFIX=${wine_prefix}${IFS}\
            WINEARCH=${wine_arch}${IFS}\
            wine_windows_version=${wine_windows_version}${IFS}\
            automatic_overwrite_existing_wine_machine=${automatic_overwrite_existing_wine_machine}"


    if [[ "$(get_overwrite_existing_wine_machine)" == True ]]; then
        banner_warning "Overwrite the old Wineprefix"
        $(get_sudo) rm -Rf ${wine_prefix}
    fi

    mkdir -p ${wine_prefix}
    wine_drive_c_dir=${wine_prefix}/drive_c
    # xvfb-run --auto-servernum winecfg # fails marshal_object couldnt get IPSFactory buffer for interface ...


    ####  when we use winecfg we need to switch off xvfb
    # if [[ ${is_xvfb_service_active} == "True" ]]; then
    #     clr_green "Stopping xvfb because winecfg crashes if it is enabled"
    #     $(get_sudo) service xvfb stop
    # fi

    banner "winecfg for Wine Machine, WINEPREFIX=${wine_prefix}, WINEARCH=${wine_arch}, wine_windows_version=${wine_windows_version}"


    #### winecfg
    # are we sure that Gecko etc. is installed ??? dunno, it works ...
    DISPLAY= wine pgen.exe
    # gecko 2.47 is installed ... looks good.

    fix_wine_permissions

    ####  when we use winecfg we need to switch off xvfb
    # if [[ ${is_xvfb_service_active} == "True" ]]; then
    #    clr_green " "
    #    clr_green "restarting xvfb"
    #    $(get_sudo) service xvfb start
    #fi

    banner "Disable GUI Crash Dialogs"
    winetricks nocrashdialog

    banner "Set Windows Version to ${wine_windows_version}"
    winetricks -q ${wine_windows_version}

    banner "Install common Packages"

    banner "install windowscodecs"
    retry winetricks -q windowscodecs

    banner "install msxml3"
    retry winetricks -q msxml3

    banner "install msxml6"
    retry winetricks -q msxml6

    banner "FINISHED installing Wine MachineWine Machine:${IFS}\
            linux_release_name=${linux_release_name}${IFS}\
            wine_release=${wine_release}${IFS}\
            wine_version=${wine_version_number}${IFS}\
            WINEPREFIX=${wine_prefix}${IFS}\
            WINEARCH=${wine_arch}${IFS}\
            wine_windows_version=${wine_windows_version}"
}

function tests {
	local my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"  # this gives the full path, even for sourced scripts
	debug "${debug_lib_bash_wine}" "no tests"
}

if [[ "${0}" == "${BASH_SOURCE}" ]]; then    # if the script is not sourced
    install_wine_machine
fi


