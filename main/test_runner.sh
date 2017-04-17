#!/bin/bash

source base.sh

function Pass {
    local testname="$1"

    cd test/"$testname"
    rm -rf expected
    cp -r actual expected

    # Avoid touching pass, as running 'make pass' again would then skip
    # $testname and pass the next test. Instead we force the user to call
    # 'make' after each 'make pass' to see the status of the next test to
    # handle.
    #touch pass

    echo "Expectancy now match last actual result for test '$testname'"
    exit 1
}

function Test {
    local test="$1"

    local test_filename="$1"_test.sh

    rm -rf test/"$test"/actual
    mkdir -p test/"$test"/actual
    cd test/"$test"/actual

    if "$test_filename" > stdout 2> stderr
    then
        echo $? > exit_status
    else
        echo $? > exit_status
    fi

    cd ..

    if ! test -d expected
    then
        mkdir expected
        echo 0 > expected/exit_status
        touch expected/stdout expected/stderr
    fi

    if diff -Naur expected actual
    then
        touch pass
        # printf "%-20s PASSED\n" "$test"
        return 0
    else
        # printf "%-20s FAILED\n" "$test"
        return 1
    fi
}

function Main {
    if test "$1" == --pass
    then
        local force_pass=true
        shift
    else
        local force_pass=false
    fi

    local testfile="$1"

    if ! [[ "$testfile" =~ ^tests/(.*)_test.sh ]]
    then
        Die "Test file must end in _test.sh: '$testfile'"
    fi
    local test="${BASH_REMATCH[1]}"

    if $force_pass
    then
        Pass "$test"
    else
        Test "$test"
    fi
}

Main "$@"
