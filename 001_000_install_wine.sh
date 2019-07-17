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
include_dependencies

function install_libfaudio0_if_not_installed {
    # from linux > 18.x we need libfaudio0
    if [[ "$(get_linux_release_number_major)" -ge 18 ]] && is_package_installed libfaudio0; then
        $(get_sudo) apt-get install libfaudio0 -y || $(get_sudo) add-apt-repository ppa:cybermax-dexter/sdl2-backport -y
    fi

}

function fallback_to_mono_bionic_version {
    echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" | $(get_sudo) tee /etc/apt/sources.list.d/mono-official-stable.list
    $(get_sudo) apt-get update
}

function install_wine {
    local linux_release_name=$(get_linux_release_name)                                                 # @lib_bash/bash_helpers
    local wine_release=$(get_wine_release_from_environment_or_default_to_devel)                # @lib_bash_wine

    banner "Installing WINE and WINETRICKS: ${IFS}linux_release_name=${linux_release_name}${IFS}wine_release=${wine_release}"

    clr_green "add 386 Architecture"
    retry $(get_sudo) dpkg --add-architecture i386

    clr_green "add Wine Keys"
    retry $(get_sudo) wget https://dl.winehq.org/wine-builds/winehq.key
    $(get_sudo) apt-key add winehq.key
    $(get_sudo) apt-add-repository "deb https://dl.winehq.org/wine-builds/ubuntu/ ${linux_release_name} main"
    install_libfaudio0_if_not_installed

    clr_green "Wine Packages Update"
    retry sudo apt-get update

    clr_green "Wine Packages Install"
    retry $(get_sudo) apt-get install --install-recommends winehq-"${wine_release}" -y
    retry $(get_sudo) apt-get install cabextract -y
    retry $(get_sudo) apt-get install libxml2 -y
    retry $(get_sudo) apt-get install libpng-dev -y
    local wine_version_number=$(get_wine_version_number)
    clr_green "Wine Version ${wine_version_number} installed on ${linux_release_name}"

    clr_green "Install mono complete"
    retry $(get_sudo) apt-get install gnupg ca-certificates
    retry $(get_sudo) apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
    echo "deb https://download.mono-project.com/repo/ubuntu stable-${linux_release_name} main" | $(get_sudo) tee /etc/apt/sources.list.d/mono-official-stable.list
    $(get_sudo) apt-get update || fallback_to_mono_bionic_version
    retry $(get_sudo) apt-get install mono-devel -y
    retry $(get_sudo) apt-get install mono-dbg -y
    retry $(get_sudo) apt-get install mono-xsp4 -y
    linux_update   # @lib_bash/bash_helpers

    clr_green "Install latest Winetricks"
    $(get_sudo) rm -f /usr/bin/winetricks
    retry $(get_sudo) wget --directory-prefix=/usr/bin/ https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
    $(get_sudo) chmod +x /usr/bin/winetricks
    retry $(get_sudo) winetricks -q --self-update

    banner "FINISHED installing WINE and WINETRICKS: ${IFS}linux_release_name=${linux_release_name}${IFS}wine_release=${wine_release}${IFS}wine_version=${wine_version_number}"
}

function tests {
	local my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"  # this gives the full path, even for sourced scripts
	debug "${debug_lib_bash_wine}" "no tests"
}


if [[ "${0}" == "${BASH_SOURCE}" ]]; then    # if the script is not sourced
    install_wine
fi
