#!/bin/bash

export SUDO_ASKPASS="$(command -v ssh-askpass)"
export NO_AT_BRIDGE=1  # get rid of (ssh-askpass:25930): dbind-WARNING **: 18:46:12.019: Couldn't register with accessibility bus: Did not receive a reply.

source ../900_000_lib_bash_wine.sh
source ../002_000_install_wine_machine.sh
"$(cmd sudo)"../install_or_update.sh


function set_variable_for_32_bit_wine_machine {
    global_wine_prefix="${HOME}/wine/wine32_machine_01"
    global_wine_arch="$(get_and_export_wine_arch_from_wine_prefix "${global_wine_prefix}")"
}

function set_variable_for_64_bit_wine_machine {
    global_wine_prefix="${HOME}/wine/wine64_machine_02"
    global_wine_arch="$(get_and_export_wine_arch_from_wine_prefix "${global_wine_prefix}")"
}

function run_tests {
    local linux_release_name wine_release winetricks_windows_version wine_version_number delete_cached_files user
    delete_cached_files="False"
    linux_release_name="$(get_linux_release_name)"
    wine_release="devel"
    winetricks_windows_version="win10"
    wine_version_number="$(get_wine_version_number)"

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

    ### test get mono commons
    assert_equal "get_mono_version_from_msi_filename wine_mono-2.47-x86.msi" "2.47"
    assert_equal "get_mono_architecture_from_msi_filename wine_mono-2.47-x86.msi" "x86"
    assert_equal "get_wine_mono_download_link_from_msi_filename wine_mono-2.47-x86.msi" "https://source.winehq.org/winemono.php?v=2.47&arch=x86"
    assert_equal "get_wine_mono_download_backup_link_from_msi_filename wine_mono-2.47-x86.msi" "https://dl.winehq.org/wine/wine-mono/2.47/wine_mono-2.47-x86.msi"

    ### test get mono 32
    set_variable_for_32_bit_wine_machine
    assert_contains "get_mono_msi_name_from_wine_prefix ${global_wine_prefix}" "wine-mono-"    # wine-mono-4.9.0.msi
    assert_contains "get_mono_msi_name_from_wine_prefix ${global_wine_prefix}" ".msi"


    # test mono download 32
    clr_green "test download mono for 32 Bit Wine"
    if [[ "${delete_cached_files}" == "True" ]]; then rm -f "${HOME}/.cache/wine/$(get_mono_32_bit_msi_name_from_wine_prefix "${global_wine_prefix}")"; fi
    assert_pass "download_mono_msi_files ${global_wine_prefix} ${user}"
    assert_pass "download_mono_msi_files ${global_wine_prefix} ${user}" # try a second time - it is already there
    assert_pass "test -f ${HOME}/.cache/wine/$(get_mono_32_bit_msi_name_from_wine_prefix "${global_wine_prefix}")"
    if [[ "${delete_cached_files}" == "True" ]]; then rm -f "${HOME}/.cache/wine/$(get_mono_32_bit_msi_name_from_wine_prefix "${global_wine_prefix}")"; fi

    clr_green "test install mono32 for 32 Bit wine"
    install_wine_mono "${global_wine_prefix}" "${user}"


    ### test get mono 64
    set_variable_for_64_bit_wine_machine
    assert_contains "get_mono_msi_name_from_wine_prefix ${global_wine_prefix}" "wine-mono-"    # wine-mono-4.9.0.msi
    assert_contains "get_mono_msi_name_from_wine_prefix ${global_wine_prefix}" ".msi"


    clr_green "test download 32 Bit mono for 64 Bit Wine"
    set_variable_for_32_bit_wine_machine
    if [[ "${delete_cached_files}" == "True" ]]; then rm -f "${HOME}/.cache/wine/$(get_mono_32_bit_msi_name_from_wine_prefix "${global_wine_prefix}")"; fi
    assert_pass "download_mono_msi_files ${global_wine_prefix} ${user}"
    assert_pass "download_mono_msi_files ${global_wine_prefix} ${user}" # try a second time - it is already there
    assert_pass "test -f ${HOME}/.cache/wine/$(get_mono_32_bit_msi_name_from_wine_prefix "${global_wine_prefix}")"
    if [[ "${delete_cached_files}" == "True" ]]; then rm -f "${HOME}/.cache/wine/$(get_mono_32_bit_msi_name_from_wine_prefix "${global_wine_prefix}")"; fi


    clr_green "test download 32/64 Bit mono for 64 Bit Wine"
    set_variable_for_64_bit_wine_machine
    if [[ "${delete_cached_files}" == "True" ]]; then rm -f "${HOME}/.cache/wine/$(get_mono_64_bit_msi_name_from_wine_prefix "${global_wine_prefix}")"; fi
    assert_pass "download_mono_msi_files ${global_wine_prefix} ${user}"
    assert_pass "download_mono_msi_files ${global_wine_prefix} ${user}" # try a second time - it is already there
    assert_pass "test -f ${HOME}/.cache/wine/$(get_mono_64_bit_msi_name_from_wine_prefix "${global_wine_prefix}")"
    if [[ "${delete_cached_files}" == "True" ]]; then rm -f "${HOME}/.cache/wine/$(get_mono_32_bit_msi_name_from_wine_prefix "${global_wine_prefix}")"; fi
    if [[ "${delete_cached_files}" == "True" ]]; then rm -f "${HOME}/.cache/wine/$(get_mono_64_bit_msi_name_from_wine_prefix "${global_wine_prefix}")"; fi

    clr_green "test install mono32 & mono64 for 64 Bit Wine"
    install_wine_mono "${global_wine_prefix}" "${user}"

}

run_tests
