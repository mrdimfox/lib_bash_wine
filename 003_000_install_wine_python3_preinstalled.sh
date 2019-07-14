#!/bin/bash

function update_myself {
    /usr/local/lib_bash_wine/install_or_update.sh "${@}" || exit 0              # exit old instance after updates
}


update_myself ${0}



function include_dependencies {
    source /usr/local/lib_bash_wine/003_900_lib_install_wine_python_preinstalled.sh
}



include_dependencies


install_wine_python_preinstalled "python37" "Python 3.7" "c:/Python37"
