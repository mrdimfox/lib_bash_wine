#!/bin/bash

sudo_askpass="$(command -v ssh-askpass)"
export SUDO_ASKPASS="${sudo_askpass}"
export NO_AT_BRIDGE=1  # get rid of (ssh-askpass:25930): dbind-WARNING **: 18:46:12.019: Couldn't register with accessibility bus: Did not receive a reply.

source ../900_000_lib_bash_wine.sh
source ../002_000_install_wine_machine.sh


function set_variable_for_32_bit_wine_machine {
    global_wine_prefix="${HOME}/wine/wine32_machine_01"
}

function set_variable_for_64_bit_wine_machine {
    global_wine_prefix="${HOME}/wine/wine64_machine_02"
}

function run_tests {
    local delete_cached_files user
    delete_cached_files="True"

    user="$(printenv USER)"

    # make sure lib_bash is properly included
	assert_pass "is_package_installed apt"

    # update libraries
    "$(cmd "sudo")" ../install_or_update.sh


    ### test library
    assert_equal "get_wine_cache_directory_for_user ${user}" "/home/${user}/.cache/wine"
    assert_fail "is_msi_file_in_winecache ${user} some_file"
    echo "test" > "${HOME}/.cache/wine/test.txt"
    assert_pass "is_msi_file_in_winecache ${user} test.txt"
    rm -f "${HOME}/.cache/wine/test.txt"
    assert_pass "download_msi_file_to_winecache ${user} https://dl.winehq.org/robots.txt test.txt"
    assert_pass "is_msi_file_in_winecache ${user} test.txt"
    rm -f "${HOME}/.cache/wine/test.txt"


    ### test get gecko commons
    assert_equal "get_gecko_version_from_msi_filename wine_gecko-2.47-x86.msi" "2.47"
    assert_equal "get_gecko_architecture_from_msi_filename wine_gecko-2.47-x86.msi" "x86"
    assert_equal "get_gecko_architecture_from_msi_filename wine_gecko-2.47-x86_64.msi" "x86_64"
    assert_equal "get_wine_gecko_download_link_from_msi_filename wine_gecko-2.47-x86.msi" "https://source.winehq.org/winegecko.php?v=2.47&arch=x86"
    assert_equal "get_wine_gecko_download_backup_link_from_msi_filename wine_gecko-2.47-x86.msi" "https://dl.winehq.org/wine/wine-gecko/2.47/wine_gecko-2.47-x86.msi"

    ### test get gecko 32
    set_variable_for_32_bit_wine_machine
    assert_contains "get_gecko_32_bit_msi_name_from_wine_prefix ${global_wine_prefix}" "wine_gecko-"
    assert_contains "get_gecko_32_bit_msi_name_from_wine_prefix ${global_wine_prefix}" "-x86.msi"

    # test gecko download 32
    clr_green "test download 32 Bit Gecko for 32 Bit Wine"
    if [[ "${delete_cached_files}" == "True" ]]; then rm -f "${HOME}/.cache/wine/$(get_gecko_32_bit_msi_name_from_wine_prefix "${global_wine_prefix}")"; fi
    assert_pass "download_gecko_msi_files ${global_wine_prefix} ${user}"
    assert_pass "download_gecko_msi_files ${global_wine_prefix} ${user}" # try a second time - it is already there
    assert_pass "test -f ${HOME}/.cache/wine/$(get_gecko_32_bit_msi_name_from_wine_prefix "${global_wine_prefix}")"
    if [[ "${delete_cached_files}" == "True" ]]; then rm -f "${HOME}/.cache/wine/$(get_gecko_32_bit_msi_name_from_wine_prefix "${global_wine_prefix}")"; fi

    clr_green "test install gecko32 for 32 Bit wine"
    install_wine_gecko "${global_wine_prefix}" "${user}"


    ### test get gecko 64
    set_variable_for_64_bit_wine_machine
    assert_contains "get_gecko_32_bit_msi_name_from_wine_prefix ${global_wine_prefix}" "wine_gecko-"
    assert_contains "get_gecko_32_bit_msi_name_from_wine_prefix ${global_wine_prefix}" "-x86.msi"
    assert_contains "get_gecko_64_bit_msi_name_from_wine_prefix ${global_wine_prefix}" "wine_gecko-"
    assert_contains "get_gecko_64_bit_msi_name_from_wine_prefix ${global_wine_prefix}" "-x86_64.msi"

    clr_green "test download 32 Bit Gecko for 64 Bit Wine"
    if [[ "${delete_cached_files}" == "True" ]]; then rm -f "${HOME}/.cache/wine/$(get_gecko_32_bit_msi_name_from_wine_prefix "${global_wine_prefix}")"; fi
    assert_pass "download_gecko_msi_files ${global_wine_prefix} ${user}"
    assert_pass "download_gecko_msi_files ${global_wine_prefix} ${user}" # try a second time - it is already there
    assert_pass "test -f ${HOME}/.cache/wine/$(get_gecko_32_bit_msi_name_from_wine_prefix "${global_wine_prefix}")"
    if [[ "${delete_cached_files}" == "True" ]]; then rm -f "${HOME}/.cache/wine/$(get_gecko_32_bit_msi_name_from_wine_prefix "${global_wine_prefix}")"; fi


    clr_green "test download 64 Bit Gecko for 64 Bit Wine"
    set_variable_for_64_bit_wine_machine
    if [[ "${delete_cached_files}" == "True" ]]; then rm -f "${HOME}/.cache/wine/$(get_gecko_64_bit_msi_name_from_wine_prefix "${global_wine_prefix}")"; fi
    assert_pass "download_gecko_msi_files ${global_wine_prefix} ${user}"
    assert_pass "download_gecko_msi_files ${global_wine_prefix} ${user}" # try a second time - it is already there
    assert_pass "test -f ${HOME}/.cache/wine/$(get_gecko_64_bit_msi_name_from_wine_prefix "${global_wine_prefix}")"
    if [[ "${delete_cached_files}" == "True" ]]; then rm -f "${HOME}/.cache/wine/$(get_gecko_32_bit_msi_name_from_wine_prefix "${global_wine_prefix}")"; fi
    if [[ "${delete_cached_files}" == "True" ]]; then rm -f "${HOME}/.cache/wine/$(get_gecko_64_bit_msi_name_from_wine_prefix "${global_wine_prefix}")"; fi

    clr_green "test install gecko32 & gecko64 for 64 Bit Wine"
    install_wine_gecko "${global_wine_prefix}" "${user}"

}

run_tests
