#!/bin/bash

source ../900_000_lib_bash_wine.sh


function test {
	# dummy_test 2>/dev/null || clr_green "no tests in ${BASH_SOURCE[0]}"

    # make sure lib_bash is properly included
    assert_equal "get_sudo" "/usr/bin/sudo"
	assert_pass "is_package_installed apt"



}
test
