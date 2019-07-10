#!/bin/bash

function include_dependencies {
    local my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"  # this gives the full path, even for sourced scripts
    source "${my_dir}/install_lib_bash.sh"
    source "${my_dir}/lib_bash/lib_color.sh"
    source "${my_dir}/lib_bash/lib_retry.sh"
    source "${my_dir}/lib_bash/lib_helpers.sh"
    source "${my_dir}/lib_wine.sh"
}

include_dependencies  # me need to do that via a function to have local scope of my_dir

banner "Install Powershell Core"
get_and_export_wine_prefix_or_default_to_home_wine  # @lib_bash_wine
get_and_export_wine_arch_or_default_to_win64        # @lib_bash_wine

wine_drive_c_dir=${WINEPREFIX}/drive_c
powershell_install_dir=${wine_drive_c_dir}/windows/system32/powershell
mkdir -p ${powershell_install_dir}

cd ${powershell_install_dir}

if [[ "${WINEARCH}" == "win32" ]]
    then
        clr_green "Download Powershell 32 Bit"
        sudo wget -nc --no-check-certificate -O powershell.zip https://github.com/PowerShell/PowerShell/releases/download/v6.2.0/PowerShell-6.2.0-win-x86.zip
    else
        clr_green "Download Powershell 64 Bit"
        sudo wget -nc --no-check-certificate -O powershell.zip https://github.com/PowerShell/PowerShell/releases/download/v6.2.0/PowerShell-6.2.0-win-x64.zip
    fi

unzip -qq ./powershell.zip -d ${powershell_install_dir}

clr_green "Test Powershell"
wine ${powershell_install_dir}/pwsh -ExecutionPolicy unrestricted -Command "get-executionpolicy"

banner "FINISHED installing Powershell Core on Wine Machine ${WINEPREFIX}"


