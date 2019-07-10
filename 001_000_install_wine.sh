#!/bin/bash

function update_myself {
    /usr/lib/lib_bash_wine/install_or_update_lib_bash_wine.sh "${@}" || exit 0              # exit old instance after updates
}


function include_dependencies {
    source /usr/lib/lib_bash/lib_color.sh
    source /usr/lib/lib_bash/lib_retry.sh
    source /usr/lib/lib_bash/lib_helpers.sh
    source /usr/lib/lib_bash_wine/lib_bash_wine.sh
}
include_dependencies

function install_libfaudio0_on_disco {
    local linux_codename=$(get_linux_codename)          # @lib_bash/bash_helpers
    local sudo_command=$(get_sudo_command)
    if [[ "${linux_codename}" == "disco" ]]; then
        ${sudo_command} add-apt-repository ppa:cybermax-dexter/sdl2-backport -y
    fi

}

function install_wine {
    local sudo_command=$(get_sudo_command)                                                     # @lib_bash/bash_helpers
    local linux_codename=$(get_linux_codename)                                                 # @lib_bash/bash_helpers
    local wine_release=$(get_wine_release_from_environment_or_default_to_devel)                # @lib_bash_wine

    banner "Installing WINE and WINETRICKS: ${IFS}linux=${linux_codename}${IFS}wine_release=${wine_release}"

    clr_green "add 386 Architecture"
    retry ${sudo_command} dpkg --add-architecture i386

    clr_green "add Wine Keys"
    retry ${sudo_command} wget https://dl.winehq.org/wine-builds/winehq.key
    ${sudo_command} apt-key add winehq.key
    ${sudo_command} apt-add-repository "deb https://dl.winehq.org/wine-builds/ubuntu/ ${linux_codename} main"
    install_libfaudio0_on_disco

    clr_green "Wine Packages Update"
    retry sudo apt-get update

    clr_green "Wine Packages Install"
    # on 19.04 we need libfaudio0: sudo add-apt-repository ppa:cybermax-dexter/sdl2-backport
    retry ${sudo_command} apt-get install --install-recommends winehq-"${wine_release}" -y
    retry ${sudo_command} apt-get install cabextract -y
    retry ${sudo_command} apt-get install libxml2 -y
    retry ${sudo_command} apt-get install libpng-dev -y
    local wine_version_number=$(get_wine_version_number)
    clr_green "Wine Version ${wine_version_number} installed on ${linux_codename}"

    clr_green "Install latest Winetricks"
    ${sudo_command} rm -f /usr/bin/winetricks
    retry ${sudo_command} wget --directory-prefix=/usr/bin/ https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
    ${sudo_command} chmod +x /usr/bin/winetricks
    retry ${sudo_command} winetricks -q --self-update

    banner "FINISHED installing WINE and WINETRICKS: ${IFS}linux=${linux_codename}${IFS}wine_release=${wine_release}${IFS}wine_version=${wine_version_number}"
}


update_myself ${0} ${@}                                                              # pass own script name and parameters
install_wine
