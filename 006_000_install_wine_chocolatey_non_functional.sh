#!/bin/bash

function update_myself {
    /usr/local/lib_bash_wine/install_or_update_lib_bash_wine.sh "${@}" || exit 0              # exit old instance after updates
}


function include_dependencies {
    source /usr/local/lib_bash/lib_color.sh
    source /usr/local/lib_bash/lib_retry.sh
    source /usr/local/lib_bash/lib_helpers.sh
    source /usr/local/lib_bash_wine/900_000_lib_bash_wine.sh
}


function install_wine_choco {
    local linux_release=$(get_linux_codename)                                  # @lib_bash/bash_helpers
    local wine_release=$(get_wine_release_from_environment_or_default_to_devel) # @lib_bash_wine
    local wine_prefix=$(get_and_export_wine_prefix_or_default_to_home_wine)     # @lib_bash_wine
    local wine_arch=$(get_and_export_wine_arch_from_wine_prefix "${wine_prefix}")          # @lib_bash_wine
    local wine_version_number=$(get_wine_version_number)  # @lib_bash_wine

    local wine_drive_c_dir=${wine_prefix}/drive_c
    local decompress_dir=${HOME}/bitranox_decompress
    local powershell_install_dir=${wine_drive_c_dir}/windows/system32/powershell


    (
        cd ${powershell_install_dir}
        # wine ${powershell_install_dir}/pwsh -ExecutionPolicy unrestricted get-executionpolicy
        # wine ${powershell_install_dir}/pwsh.exe -NoProfile -InputFormat None -ExecutionPolicy unrestricted -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
        # wine ${powershell_install_dir}/pwsh.exe -NoProfile -ExecutionPolicy Bypass -Command "((new-object net.webclient).DownloadFile('https://chocolatey.org/install.ps1','install.ps1'))"
        wget --no-check-certificate -O install.ps1 https://chocolatey.org/install.ps1
        wine ${powershell_install_dir}/pwsh.exe -NoProfile -ExecutionPolicy Bypass -Command "& 'install.ps1' %*"
    )

}

update_myself ${0} ${@}                                                              # pass own script name and parameters
install_wine_choco
