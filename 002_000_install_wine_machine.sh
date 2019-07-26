#!/bin/bash

sudo_askpass="$(command -v ssh-askpass)"
export SUDO_ASKPASS="${sudo_askpass}"
export NO_AT_BRIDGE=1  # get rid of (ssh-askpass:25930): dbind-WARNING **: 18:46:12.019: Couldn't register with accessibility bus: Did not receive a reply.

# call the update script if not sourced
if [[ "${0}" == "${BASH_SOURCE[0]}" ]] && [[ -d "${BASH_SOURCE%/*}" ]]; then "${BASH_SOURCE%/*}"/install_or_update.sh else "${PWD}"/install_or_update.sh ; fi




function include_dependencies {
    local my_dir
    # shellcheck disable=SC2164
    my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"  # this gives the full path, even for sourced scripts
    source /usr/local/lib_bash/lib_helpers.sh
    source "${my_dir}/900_000_lib_bash_wine.sh"
    source "${my_dir}/900_001_lib_bash_wine_mono.sh"
    source "${my_dir}/900_002_lib_bash_wine_gecko.sh"
}

include_dependencies



function install_wine_machine {
    # $1 : wine_release                                 # [stable|devel|staging]
    # $2 : wine_prefix                                  # "${HOME}/wine/my_wine_01"
    # $3 : wine_arch                                    # [win32|win64]
    # $4 : winetricks_windows_version                   # [win7|win10....] - see winetricks list-all | grep version
    # $5 : user                                         # printenv USER
    # $6 : overwrite_existing_wine_machine    # ["True"|"False"]

    local linux_release_name wine_release wine_prefix wine_arch winetricks_windows_version wine_version_number overwrite_existing_wine_machine user

    banner "Install Wine Machine"
    wine_release="${1}"
    wine_prefix="${2}"
    wine_arch="${3}"
    winetricks_windows_version="${4}"
    user="${5}"
    overwrite_existing_wine_machine="${6}"

    linux_release_name="$(get_linux_release_name)"
    wine_version_number="$(get_wine_version_number)"


    # this is only for display - otherwise use function is_overwrite_existing_wine_machine
    if [[ "${overwrite_existing_wine_machine}" != "True" ]]; then
         overwrite_existing_wine_machine="False"
    fi


    banner "Setting up Wine Machine:${IFS}\
            linux_release_name=${linux_release_name}${IFS}\
            wine_release=${wine_release}${IFS}\
            wine_version=${wine_version_number}${IFS}\
            WINEPREFIX=${wine_prefix}${IFS}\
            WINEARCH=${wine_arch}${IFS}\
            winetricks_windows_version=${winetricks_windows_version}${IFS}\
            overwrite_existing_wine_machine=${overwrite_existing_wine_machine}"


    if [[ "${overwrite_existing_wine_machine}" == "True" ]] && [[ -d ${wine_prefix} ]]; then
         banner_warning "Overwriting old Wine Machine ${wine_prefix}"
         if [[ "${wine_prefix}" == "/home/${user}"* ]]; then
            "$(cmd "sudo")" rm -Rf "${wine_prefix}"
         else
            fail "can not remove wineprefix ${wine_prefix} because it does not belong to user ${user}"
         fi
    fi


    mkdir -p "${wine_prefix}"

    banner "winecfg for Wine Machine, WINEPREFIX=${wine_prefix}, WINEARCH=${wine_arch}, winetricks_windows_version=${winetricks_windows_version}"

    # shellcheck disable=SC1007  # we really set DISPLAY to an empty value
    # DISPLAY= wine non_existing_command.exe
    DISPLAY= WINEPREFIX="${wine_prefix}" WINEARCH="${wine_arch}" winecfg
    wait_for_file_to_be_created "${wine_prefix}"/system.reg
    fix_wine_permissions "${wine_prefix}" "${user}" # it is cheap, just in case

    banner "Installing wine mono on ${wine_prefix}"
    install_wine_mono "${wine_prefix}" "${user}"
    fix_wine_permissions "${wine_prefix}" "${user}" # it is cheap, just in case

    banner "Installing wine gecko on ${wine_prefix}"
    install_wine_gecko "${wine_prefix}" "${user}"
    fix_wine_permissions "${wine_prefix}" "${user}" # it is cheap, just in case

    banner "Disable GUI Crash Dialogs on ${wine_prefix}"
    WINEPREFIX="${wine_prefix}" WINEARCH="${wine_arch}" winetricks nocrashdialog
    fix_wine_permissions "${wine_prefix}" "${user}" # it is cheap, just in case

    banner "Set Windows Version on ${wine_prefix} to ${winetricks_windows_version}"
    retry WINEPREFIX="${wine_prefix}" WINEARCH="${wine_arch}" winetricks -q "${winetricks_windows_version}"
    fix_wine_permissions "${wine_prefix}" "${user}" # it is cheap, just in case

    banner "Install common Packages"


#    banner "install windowscodecs (needs to be set to builtin,native for python3)"
#    retry WINEPREFIX="${wine_prefix}" WINEARCH="${wine_arch}" winetricks -q windowscodecs --optout
#    # winetricks -q windowscodecs sets the windows version back to windows2000
#    # bug reported under https://github.com/Winetricks/winetricks/issues/1283
#    # so we need to set it back to what it was.
#    retry WINEPREFIX="${wine_prefix}" WINEARCH="${wine_arch}" winetricks -q "${winetricks_windows_version}"
#    fix_wine_permissions "${wine_prefix}" "${user}" # it is cheap, just in case

#    banner "install msxml3"
#    retry WINEPREFIX="${wine_prefix}" WINEARCH="${wine_arch}" winetricks -q msxml3 --optout
#    fix_wine_permissions "${wine_prefix}" "${user}" # it is cheap, just in case

#    banner "install msxml6"
#    retry WINEPREFIX="${wine_prefix}" WINEARCH="${wine_arch}" winetricks -q msxml6 --optout
#    fix_wine_permissions "${wine_prefix}" "${user}" # it is cheap, just in case

    banner "FINISHED installing Wine MachineWine Machine:${IFS}\
            linux_release_name=${linux_release_name}${IFS}\
            wine_release=${wine_release}${IFS}\
            wine_version=${wine_version_number}${IFS}\
            WINEPREFIX=${wine_prefix}${IFS}\
            WINEARCH=${wine_arch}${IFS}\
            winetricks_windows_version=${winetricks_windows_version}${IFS}\
            wine_path=$(get_wine_registry_path "${wine_prefix}")"
}

if [[ "${0}" == "${BASH_SOURCE[0]}" ]]; then    # if the script is not sourced
    wine_release="$(get_and_export_wine_release_from_environment_or_default_to_devel)"
    wine_prefix="$(get_and_export_wine_prefix_from_environment_or_default_to_home_wine)"
    wine_arch="$(get_and_export_wine_arch_from_environment_or_default_to_win64)"
    winetricks_windows_version="$(get_and_export_winetricks_windows_version_from_environment_or_default_to_win10)"
    user="$(printenv USER)"
    overwrite_existing_wine_machine="$(get_and_export_overwrite_existing_wine_machine_from_environment_or_default_to_false)"

    install_wine_machine "${wine_release}" "${wine_prefix}" "${wine_arch}" "${winetricks_windows_version}" "${user}" "${overwrite_existing_wine_machine}"
fi
