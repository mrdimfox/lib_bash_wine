#!/bin/bash

function update_myself {
    /usr/local/lib_bash_wine/install_or_update_lib_bash_wine.sh "${@}" || exit 0              # exit old instance after updates
}

function include_dependencies {
    source /usr/local/lib_bash_wine/003_900_lib_install_wine_python_preinstalled.sh
}

include_dependencies  # we need to do that via a function to have local scope of my_dir
update_myself ${0} ${@}                                                              # pass own script name and parameters
install_wine_python_preinstalled "python27" "Python 2.7" "c:/Python27"
