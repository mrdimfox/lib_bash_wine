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


function install_wine_gecko {
    # installs the matching wine_gecko on the existing wine machine
    # $1 : wine_prefix
    local wine_prefix wine_arch gecko_32_bit_msi_name gecko_64_bit_msi_name
    wine_prefix="${1}"
    wine_arch="$(get_and_export_wine_arch_from_wine_prefix "${wine_prefix}")"
    gecko_32_bit_msi_name="$(get_gecko_32_bit_msi_name "${wine_prefix}")"
    gecko_64_bit_msi_name="$(get_gecko_64_bit_msi_name "${wine_prefix}")"



    # strings -a /home/consul/wine/wine32_machine_01/drive_c/windows/system32/appwiz.cpl | grep wine_gecko | grep .msi --> wine_gecko-2.47-x86.msi
    # correct: https://dl.winehq.org/wine/wine-gecko/2.47/wine_gecko-2.47-x86.msi
    # correct: https://dl.winehq.org/wine/wine-gecko/2.47/wine_gecko-2.47-x86_64.msi
    # correct : https://dl.winehq.org/wine/wine-mono/4.9.0/wine-mono-4.9.0.msi - für beide !!!

    # Übereinstimmungen in Binärdatei /home/consul/wine/wine32_machine_01/drive_c/windows/system32/appwiz.cpl
    # Übereinstimmungen in Binärdatei /home/consul/wine/wine64_machine_02/drive_c/windows/syswow64/appwiz.cpl
    # Übereinstimmungen in Binärdatei /home/consul/wine/wine64_machine_02/drive_c/windows/system32/appwiz.cpl



}


function install_wine_mono {
    # installs the matching wine-mono on the existing wine machine
    # $1: wine_prefix
    local wine_prefix wine_arch wine_mono_msi_name
    wine_prefix="${1}"
    wine_arch="$(get_and_export_wine_arch_from_wine_prefix "${wine_prefix}")"
    wine_mono_msi_name="$(get_wine_mono_msi_name)"


}




function install_wine_machine {
    # $1 : wine_release                                 # [stable|devel|staging]
    # $2 : wine_prefix                                  # "${HOME}/wine/my_wine_01"
    # $3 : wine_arch                                    # [win32|win64]
    # $4 : winetricks_windows_version                   # [win7|win10....] - see wintricks list-all | grep version
    # $5 : user                                         # printenv USER
    # $6 : automatic_overwrite_existing_wine_machine    # ["True"|"False"]

    local linux_release_name wine_release wine_prefix wine_arch winetricks_windows_version wine_version_number automatic_overwrite_existing_wine_machine user

    banner "Install Wine Machine"
    wine_release="${1}"
    wine_prefix="${2}"
    wine_arch="${3}"
    winetricks_windows_version="${4}"
    user="${5}"
    automatic_overwrite_existing_wine_machine="${6}"

    linux_release_name="$(get_linux_release_name)"
    wine_version_number="$(get_wine_version_number)"



    banner "Setting up Wine Machine:${IFS}\
            linux_release_name=${linux_release_name}${IFS}\
            wine_release=${wine_release}${IFS}\
            wine_version=${wine_version_number}${IFS}\
            WINEPREFIX=${wine_prefix}${IFS}\
            WINEARCH=${wine_arch}${IFS}\
            winetricks_windows_version=${winetricks_windows_version}${IFS}\

            # this is only for display - otherwise use function is_overwrite_existing_wine_machine
            automatic_overwrite_existing_wine_machine=${automatic_overwrite_existing_wine_machine}"
            if [[ "${automatic_overwrite_existing_wine_machine}" != "True" ]]; then
                 automatic_overwrite_existing_wine_machine="False"
            fi

    if is_overwrite_existing_wine_machine; then
        banner_warning "Overwrite the old Wineprefix"
        "$(cmd "sudo")" rm -Rf "${wine_prefix}"
    fi

    mkdir -p "${wine_prefix}"
    # xvfb-run --auto-servernum winecfg # fails marshal_object couldnt get IPSFactory buffer for interface ...


    ####  when we use winecfg we need to switch off xvfb
    # if [[ ${is_xvfb_service_active} == "True" ]]; then
    #     clr_green "Stopping xvfb because winecfg crashes if it is enabled"
    #     "$(cmd "sudo")" service xvfb stop
    # fi

    banner "winecfg for Wine Machine, WINEPREFIX=${wine_prefix}, WINEARCH=${wine_arch}, winetricks_windows_version=${winetricks_windows_version}"


    #### winecfg
    # are we sure that Gecko etc. is installed ??? dunno, it works ...

    # shellcheck disable=SC1007  # we really set DISPLAY to an empty value
    # DISPLAY= wine non_existing_command.exe
    DISPLAY= WINEPREFIX="${wine_prefix}" WINEARCH="${wine_arch}" winecfg
    fix_wine_permissions "${user}" "${wine_prefix}" # it is cheap, just in case

    banner "Installing wine gecko"
    install_wine_gecko "${wine_prefix}"
    fix_wine_permissions "${user}" "${wine_prefix}" # it is cheap, just in case

    banner "Installing wine mono"
    install_wine_mono "${wine_prefix}"
    fix_wine_permissions "${user}" "${wine_prefix}" # it is cheap, just in case

    banner "Disable GUI Crash Dialogs"
    WINEPREFIX="${wine_prefix}" WINEARCH="${wine_arch}" winetricks nocrashdialog
    fix_wine_permissions "${user}" "${wine_prefix}" # it is cheap, just in case

    banner "Set Windows Version to ${winetricks_windows_version}"
    WINEPREFIX="${wine_prefix}" WINEARCH="${wine_arch}" winetricks -q "${winetricks_windows_version}"
    fix_wine_permissions "${user}" "${wine_prefix}" # it is cheap, just in case

    banner "Install common Packages"

    banner "install windowscodecs"
    retry WINEPREFIX="${wine_prefix}" WINEARCH="${wine_arch}" winetricks -q windowscodecs
    fix_wine_permissions "${user}" "${wine_prefix}" # it is cheap, just in case

    banner "install msxml3"
    retry WINEPREFIX="${wine_prefix}" WINEARCH="${wine_arch}" winetricks -q msxml3
    fix_wine_permissions "${user}" "${wine_prefix}" # it is cheap, just in case

    banner "install msxml6"
    retry WINEPREFIX="${wine_prefix}" WINEARCH="${wine_arch}" winetricks -q msxml6
    fix_wine_permissions "${user}" "${wine_prefix}" # it is cheap, just in case

    banner "FINISHED installing Wine MachineWine Machine:${IFS}\
            linux_release_name=${linux_release_name}${IFS}\
            wine_release=${wine_release}${IFS}\
            wine_version=${wine_version_number}${IFS}\
            WINEPREFIX=${wine_prefix}${IFS}\
            WINEARCH=${wine_arch}${IFS}\
            winetricks_windows_version=${winetricks_windows_version}${IFS}\
            wine_path_reg_sz=$(get_wine_path_reg_sz)${IFS}\
            wine_path_reg_expand_sz=$(get_wine_path_reg_expand_sz)"
}

if [[ "${0}" == "${BASH_SOURCE[0]}" ]]; then    # if the script is not sourced
    wine_release="$(get_and_export_wine_release_from_environment_or_default_to_devel)"
    wine_prefix="$(get_and_export_wine_prefix_from_environment_or_default_to_home_wine)"
    wine_arch="$(get_and_export_wine_arch_from_environment_or_default_to_win64)"
    winetricks_windows_version="$(get_and_export_winetricks_windows_version_from_environment_or_default_to_win10)"
    user="$(printenv USER)"
    automatic_overwrite_existing_wine_machine=

    install_wine_machine "${wine_release}" "${wine_prefix}" "${wine_arch}" "${winetricks_windows_version}" "${user}" "${automatic_overwrite_existing_wine_machine}"
fi
