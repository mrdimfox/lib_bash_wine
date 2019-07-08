#!/bin/bash

function include_dependencies {
    local my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"  # this gives the full path, even for sourced scripts
    source "${my_dir}/install_lib_bash.sh"
    source "${my_dir}/lib_bash/lib_color.sh"
    source "${my_dir}/lib_bash/lib_retry.sh"
    source "${my_dir}/lib_bash/lib_helpers.sh"
    source "${my_dir}/lib_wine.sh"
}

include_dependencies  # we need to do that via a function to have local scope of my_dir

banner "Install Wine Machine"
check_wine_prefix
check_wine_arch
check_wine_windows_version
check_headless_xvfb
wine_version_number=$(get_wine_version_number)

banner "Setup Wine Machine at ${WINEPREFIX}, WINEARCH=${WINEARCH}, wine_windows_version=${wine_windows_version}"
mkdir -p ${WINEPREFIX}
wine_drive_c_dir=${WINEPREFIX}/drive_c
# xvfb-run --auto-servernum winecfg # fails marshal_object couldnt get IPSFactory buffer for interface ...

if [[ ${xvfb_framebuffer_service_active} == "True" ]]; then sudo service xvfb stop ; fi   # winecfg fails if xvfb server is running
winecfg
if [[ ${xvfb_framebuffer_service_active} == "True" ]]; then sudo service xvfb start ; fi     # winecfg fails if xvfb server is running

clr_bold clr_green "Disable GUI Crash Dialogs"
winetricks nocrashdialog

clr_bold clr_bold clr_green "Set Windows Version to ${wine_windows_version}"
winetricks -q ${wine_windows_version}

banner "Install common Packets :"
banner "install windowscodecs"
retry winetricks -q windowscodecs

banner "install msxml3"
retry winetricks -q msxml3

banner "install msxml6"
retry winetricks -q msxml6

banner "FINISHED installing Wine Machine ${WINEPREFIX}, "
