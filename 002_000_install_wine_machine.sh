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


function install_wine_machine {
    local linux_release_name wine_release wine_prefix wine_arch wine_windows_version wine_version_number automatic_overwrite_existing_wine_machine

    banner "Install Wine Machine"

    linux_release_name="$(get_linux_release_name)"
    wine_release="$(get_wine_release_from_environment_or_default_to_devel)"
    wine_prefix="$(get_and_export_wine_prefix_or_default_to_home_wine)"
    wine_arch="$(get_and_export_wine_arch_or_default_to_win64)"
    wine_windows_version="$(get_wine_windows_version_or_default_to_win10)"
    wine_version_number="$(get_wine_version_number)"
    automatic_overwrite_existing_wine_machine="$(printenv automatic_overwrite_existing_wine_machine)"

    banner "Setting up Wine Machine:${IFS}\
            linux_release_name=${linux_release_name}${IFS}\
            wine_release=${wine_release}${IFS}\
            wine_version=${wine_version_number}${IFS}\
            WINEPREFIX=${wine_prefix}${IFS}\
            WINEARCH=${wine_arch}${IFS}\
            wine_windows_version=${wine_windows_version}${IFS}\

            # this is only for display - otherwise use function is_overwrite_existing_wine_machine
            automatic_overwrite_existing_wine_machine=${automatic_overwrite_existing_wine_machine}"
            if [[ "${automatic_overwrite_existing_wine_machine}" != "True" ]]; then
                 automatic_overwrite_existing_wine_machine="False"
            fi

    if is_overwrite_existing_wine_machine; then
        banner_warning "Overwrite the old Wineprefix"
        $(get_sudo) rm -Rf "${wine_prefix}"
    fi

    mkdir -p "${wine_prefix}"
    # xvfb-run --auto-servernum winecfg # fails marshal_object couldnt get IPSFactory buffer for interface ...


    ####  when we use winecfg we need to switch off xvfb
    # if [[ ${is_xvfb_service_active} == "True" ]]; then
    #     clr_green "Stopping xvfb because winecfg crashes if it is enabled"
    #     $(get_sudo) service xvfb stop
    # fi

    banner "winecfg for Wine Machine, WINEPREFIX=${wine_prefix}, WINEARCH=${wine_arch}, wine_windows_version=${wine_windows_version}"


    #### winecfg
    # are we sure that Gecko etc. is installed ??? dunno, it works ...

    # shellcheck disable=SC1007  # we really set DISPLAY to an empty value
    # DISPLAY= wine non_existing_command.exe
    DISPLAY= winecfg

    # todo gecko 2.47 is not installed should be in ${HOME}.cache/wine/wine_gecko-2.47-x86.msi
    # user.reg
    # [Software\\Microsoft\\Installer\\Products\\79BDB9BB742C02F47B01B876566F1750\\SourceList] 1563404265
    #time=1d53cf30c1a0d3e
    # "LastUsedSource"="n;1;\\\\?\\Z:\\home\\consul\\.cache\\wine\\"
    # "PackageName"="wine_gecko-2.47-x86.msi"
    # todo wine-mono is not installed should be in ${HOME}.cache/wine/wine-mono-4.9.0.msi
    # user.reg
    # [Software\\Microsoft\\Installer\\Products\\7B5FB551490B356529D163F2481849D3\\SourceList] 1563404256
    ##time=1d53cf306b9cf0a
    #"LastUsedSource"="n;1;\\\\?\\Z:\\home\\consul\\.cache\\wine\\"
    #"PackageName"="wine-mono-4.9.0.msi"


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
    winetricks -q "${wine_windows_version}"

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
            wine_windows_version=${wine_windows_version}${IFS}\
            wine_path_reg_sz=$(get_wine_path_reg_sz)${IFS}\
            wine_path_reg_expand_sz=$(get_wine_path_reg_expand_sz)"
}

if [[ "${0}" == "${BASH_SOURCE[0]}" ]]; then    # if the script is not sourced
    install_wine_machine
fi


