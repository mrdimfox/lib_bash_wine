#!/bin/bash

function update_myself {
    /usr/lib/lib_bash_wine/install_or_update_lib_bash_wine.sh "${@}" || exit 0              # exit old instance after updates
}


function include_dependencies {
    source /usr/lib/lib_bash/lib_color.sh
    source /usr/lib/lib_bash/lib_retry.sh
    source /usr/lib/lib_bash/lib_helpers.sh
    source /usr/lib/lib_bash_wine/900_000_lib_bash_wine.sh
}

include_dependencies  # me need to do that via a function to have local scope of my_dir

function install_powershell_core {

    local linux_codename=$(get_linux_codename)                                  # @lib_bash/bash_helpers
    local wine_release=$(get_wine_release_from_environment_or_default_to_devel) # @lib_bash_wine
    local wine_prefix=$(get_and_export_wine_prefix_or_default_to_home_wine)     # @lib_bash_wine
    local wine_arch=$(get_and_export_wine_arch_from_wine_prefix "${wine_prefix}")          # @lib_bash_wine
    local wine_version_number=$(get_wine_version_number)  # @lib_bash_wine

    local wine_drive_c_dir=${wine_prefix}/drive_c
    local decompress_dir=${HOME}/bitranox_decompress
    local powershell_install_dir=${wine_drive_c_dir}/windows/system32/powershell
    local powershell_version="6.2.1"
    local powershell_path_to_add="c:/windows/system32/powershell/"

    banner "Installing Powershell Core:${IFS}linux=${linux_codename}${IFS}wine_release=${wine_release}${IFS}wine_version=${wine_version_number}${IFS}WINEPREFIX=${wine_prefix}${IFS}WINEARCH=${wine_arch}"
    mkdir -p ${powershell_install_dir}

    (
        # creating now scope to preserve current directory
        cd ${powershell_install_dir}

        if [[ "${wine_arch}" == "win32" ]]
            then
                clr_green "Download Powershell ${powershell_version} 32 Bit"
                rm -f ./powershell.zip
                retry wget -nc --no-check-certificate -O powershell.zip https://github.com/PowerShell/PowerShell/releases/download/v${powershell_version}/PowerShell-${powershell_version}-win-x86.zip
            else
                clr_green "Download Powershell ${powershell_version} 64 Bit"
                rm -f ./powershell.zip
                retry wget -nc --no-check-certificate -O powershell.zip https://github.com/PowerShell/PowerShell/releases/download/v${powershell_version}/PowerShell-${powershell_version}-win-x64.zip
            fi

        unzip -oqq ./powershell.zip -d ${powershell_install_dir}
        rm -f ./powershell.zip

        clr_green "Adding path to wine registry: ${powershell_path_to_add}"
        prepend_path_to_wine_registry "${powershell_path_to_add}"


        banner "Test Powershell ${powershell_version}"
        wine pwsh -ExecutionPolicy unrestricted -Command "get-executionpolicy"
        banner "Finished installing Powershell Core:${IFS}linux=${linux_codename}${IFS}wine_release=${wine_release}${IFS}wine_version=${wine_version_number}${IFS}WINEPREFIX=${wine_prefix}${IFS}WINEARCH=${wine_arch}${IFS}powershell_core_version=${powershell_version}"
    )

}

update_myself ${0} ${@}                                                              # pass own script name and parameters
install_powershell_core
