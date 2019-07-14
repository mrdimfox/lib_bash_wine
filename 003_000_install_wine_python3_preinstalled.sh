#!/bin/bash

function update_myself {
    /usr/local/lib_bash_wine/install_or_update.sh "${@}" || exit 0              # exit old instance after updates
}


if [[ -z "${1}" ]]; then
    update_myself ${0}
else
    update_myself ${0} ${@}  > /dev/null 2>&1  # suppress messages here, not to spoil up answers from functions  when called verbatim
fi



function include_dependencies {
    source /usr/local/lib_bash_wine/003_900_lib_install_wine_python_preinstalled.sh
}



include_dependencies


install_wine_python_preinstalled "python37" "Python 3.7" "c:/Python37"
