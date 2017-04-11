#!/bin/bash

source match.sh

function TestMatch {
    local text="$1"
    local regex="$2"
    shift 2

    if Match "$text" "$regex" "$@"
    then
        echo "Matched"
        declare -p "$@"
    else
        echo "No match"
    fi
}

function Main {
    local s i
    TestMatch "This is a long text" '([st]) (i)' s i
    TestMatch "This is a long text" '([st]) (i)' s
    TestMatch "This is a long text" 'doesnt match' s i
}

Main "$@"
