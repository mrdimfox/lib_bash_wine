#!/bin/bash

function update_myself {
    /usr/local/lib_bash_wine/install_or_update_lib_bash_wine.sh "${@}" || exit 0              # exit old instance after updates
}

function include_dependencies {
    source /usr/local/lib_bash_wine/003_900_lib_install_wine_python_preinstalled.sh
}

include_dependencies
update_myself ${0} ${@}                                                              # pass own script name and parameters
install_wine_python_preinstalled "python37" "Python 3.7" "c:/Python37"
