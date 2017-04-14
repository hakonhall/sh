#!/bin/bash

if ! test -d src -a -d main -a -d tests
then
    echo "PWD doesn't look like a hakonhall/sh directory"
    exit 1
fi

export PATH+=":$PWD/src:$PWD/tests"

source source_deps.sh

declare -A SRC_DEPS=()
declare -A TESTS_DEPS=()
declare -A UNIFIED_DEPS=()
declare -A TRANSITIVE_DEPS=()

function FindTransitiveDependenciesFor {
    local file="$1"

    local depfile
    # Must be unquoted
    for depfile in ${UNIFIED_DEPS["$file"]}
    do
        if ! test -v TRANSITIVE_DEPS["src/$depfile"]
        then
            TRANSITIVE_DEPS["src/$depfile"]=true
            FindTransitiveDependenciesFor "$depfile"
        fi
    done
}    

function Main {
    BuildSourceDependencyGraph src
    Map_CopyTo MREPLY SRC_DEPS
    
    BuildSourceDependencyGraph tests
    Map_CopyTo MREPLY TESTS_DEPS
    
    Map_AddTo SRC_DEPS UNIFIED_DEPS
    Map_AddTo TESTS_DEPS UNIFIED_DEPS

    local -A test_deps=()

    local testfile
    for testfile in "${!TESTS_DEPS[@]}"
    do
        TRANSITIVE_DEPS=()
        FindTransitiveDependenciesFor "$testfile"

        test_deps["$testfile"]="${!TRANSITIVE_DEPS[*]}"
    done

    local test
    for test in "${!test_deps[@]}"
    do
        local prefix="${test%_test.sh}"
        local dep="${test_deps[$test]}"
        printf "test/%s/pass: tests/%s_test.sh %s\n" \
               "$prefix" "$prefix" "$dep"
        printf "\ttest_runner.sh \$(FORCE_PASS) $<\n"
        printf "\n"
    done
}

Main "$@"
