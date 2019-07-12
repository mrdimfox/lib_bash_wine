#!/bin/bash

function update_myself {
    /usr/local/lib_bash_wine/install_or_update.sh "${@}" || exit 0              # exit old instance after updates
}


function include_dependencies {
    source /usr/local/lib_bash/lib_color.sh
    source /usr/local/lib_bash/lib_retry.sh
    source /usr/local/lib_bash/lib_helpers.sh
    source /usr/local/lib_bash_wine/900_000_lib_bash_wine.sh
}
include_dependencies

function install_libfaudio0_if_not_installed {
    if [[ "$(get_is_package_installed libfaudio0)" == "False" ]]; then
        $(which sudo) add-apt-repository ppa:cybermax-dexter/sdl2-backport -y
    fi

}

function fallback_to_mono_bionic_version {
    echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" | $(which sudo) tee /etc/apt/sources.list.d/mono-official-stable.list
    $(which sudo) apt-get update
}

function install_wine {
    local linux_release_name=$(get_linux_release_name)                                                 # @lib_bash/bash_helpers
    local wine_release=$(get_wine_release_from_environment_or_default_to_devel)                # @lib_bash_wine

    banner "Installing WINE and WINETRICKS: ${IFS}linux_release_name=${linux_release_name}${IFS}wine_release=${wine_release}"

    clr_green "add 386 Architecture"
    retry $(which sudo) dpkg --add-architecture i386

    clr_green "add Wine Keys"
    retry $(which sudo) wget https://dl.winehq.org/wine-builds/winehq.key
    $(which sudo) apt-key add winehq.key
    $(which sudo) apt-add-repository "deb https://dl.winehq.org/wine-builds/ubuntu/ ${linux_release_name} main"
    install_libfaudio0_if_not_installed

    clr_green "Wine Packages Update"
    retry sudo apt-get update

    clr_green "Wine Packages Install"
    retry $(which sudo) apt-get install --install-recommends winehq-"${wine_release}" -y
    retry $(which sudo) apt-get install cabextract -y
    retry $(which sudo) apt-get install libxml2 -y
    retry $(which sudo) apt-get install libpng-dev -y
    local wine_version_number=$(get_wine_version_number)
    clr_green "Wine Version ${wine_version_number} installed on ${linux_release_name}"

    clr_green "Install mono complete"
    retry $(which sudo) apt-get install gnupg ca-certificates
    retry $(which sudo) apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
    echo "deb https://download.mono-project.com/repo/ubuntu stable-${linux_release_name} main" | $(which sudo) tee /etc/apt/sources.list.d/mono-official-stable.list
    $(which sudo) apt-get update || fallback_to_mono_bionic_version
    retry $(which sudo) apt-get install mono-devel -y
    retry $(which sudo) apt-get install mono-dbg -y
    retry $(which sudo) apt-get install mono-xsp4 -y
    linux_update   # @lib_bash/bash_helpers

    clr_green "Install latest Winetricks"
    $(which sudo) rm -f /usr/bin/winetricks
    retry $(which sudo) wget --directory-prefix=/usr/bin/ https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
    $(which sudo) chmod +x /usr/bin/winetricks
    retry $(which sudo) winetricks -q --self-update

    banner "FINISHED installing WINE and WINETRICKS: ${IFS}linux_release_name=${linux_release_name}${IFS}wine_release=${wine_release}${IFS}wine_version=${wine_version_number}"
}


update_myself ${0} ${@}                                                              # pass own script name and parameters
install_wine
