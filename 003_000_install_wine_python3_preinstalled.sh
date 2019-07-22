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
    source "${my_dir}/003_900_lib_install_wine_python_preinstalled.sh"
}

include_dependencies




if [[ "${0}" == "${BASH_SOURCE[0]}" ]]; then    # if the script is not sourced
    install_wine_python_preinstalled "python37" "Python 3.7" "c:\\Python37"
fi



# https://docs.python.org/3/using/windows.html


# get latest release number :
# https://www.python.org/downloads/windows/
# grep Latest Python 3 Release
# download the file

# TARGET : /home/consul/.cache/wine
# chmod 0775

# windowscodecs : first builtin, then native --> winetricks alldlls=builtin
# section [Software\\Wine\\DllOverrides] 1563781801
# user.reg : "*msxml3"="native" -->  "*msxml3"="builtin,native"

#### python 3.7
# options see : https://docs.python.org/3/using/windows.html
# wine /home/consul/.cache/wine/python-3.7.4.exe /passive InstallAllUsers=1  PrependPath=1  DefaultAllUsersTargetDir=<dir>
# wine python --version


# most tests pass - later if needed !
# wine /home/consul/wine/wine32_machine_01/drive_c/Program Files/Python37-32/Tools/scripts/run_tests.py


# python-3.7.4.exe /passive InstallAllUsers=1  PrependPath=1


# https://www.python.org/ftp/python/3.7.4/python-3.7.4.exe /passive InstallAllUsers=1  PrependPath=1


