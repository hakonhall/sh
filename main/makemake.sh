#!/bin/bash

if ! test -d src -a -d main -a -d tests
then
    echo "PWD doesn't look like a hakonhall/sh directory"
    exit 1
fi

export PATH+=":$PWD/src:$PWD/tests"

source define.sh
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

    local -A test_dep_list=()
    local -A test_dep_map=()

    # If a test T depends on A, B, and C, and another test T2 depends on a
    # strict subset, e.g. A and B, then make sure the T2 test completes
    # successfully before trying to run test T.
    #
    # We need to map a string (the test file name) to a set (map/associative
    # array ignoring the values).  More generally, it would be nice to map a
    # string to any type (string, array, map, or namespace).  Likewise, it
    # would be nice to allow an array of any type: Allow the elements of array
    # and map to be any type.
    #
    # Can be achieved with 1 level of indirection: The value in the map (or
    # array) is the name of a variable with the correct type.

    local testfile
    for testfile in "${!TESTS_DEPS[@]}"
    do
        TRANSITIVE_DEPS=()
        FindTransitiveDependenciesFor "$testfile"

        DefineGlobalVariable -cA
        local test_dep_varname="$REPLY"
        local -n test_dep="$test_dep_varname"
        Map_CopyTo TRANSITIVE_DEPS test_dep
        test_dep_map["$testfile"]="$test_dep_varname"
        test_dep_list["$testfile"]="${!TRANSITIVE_DEPS[*]}"
    done

    local test
    for test in "${!test_dep_map[@]}"
    do
        local prefix="${test%_test.sh}"
        local dep_list="${test_dep_list[$test]}"

        # Find all those tests that should run before ourself: Those tests that
        # have a strict subset of 'source' dependencies are assumed to test
        # more basic stuff and should run first.

        local -n test_deps="${test_dep_map[$test]}"

        local -a prerequisite_test_targets=()
        local -a more_basic_tests=()
        local other_test
        for other_test in "${!test_dep_map[@]}"
        do
            local -n other_test_deps="${test_dep_map[$other_test]}"

            if (( ${#other_test_deps[@]} < ${#test_deps[@]} ))
            then
                local subset=true

                local dep
                for dep in "${!other_test_deps[@]}"
                do
                    if ! test -v test_deps["$dep"]
                    then
                        subset=false
                        break
                    fi
                done

                if "$subset"
                then
                    local stem="${other_test%_test.sh}"
                    prerequisite_test_targets+=(test/"$stem"/pass)
                    more_basic_tests+=("$other_test")
                fi
            fi
        done

        printf "test/%s/pass: tests/%s_test.sh %s %s\n" \
               "$prefix" "$prefix" "$dep_list" "${prerequisite_test_targets[*]}"
        printf "\ttest_runner.sh \$(FORCE_PASS) $<\n"
        printf "\n"
    done
}

Main "$@"
