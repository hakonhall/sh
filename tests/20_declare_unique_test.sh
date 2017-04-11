#!/bin/bash

source declare_unique.sh

function DeclareUnique {
    declare_unique "$@"
    eval "declare -p -- $REPLY"
}

function Main {
    DeclareUnique

    DeclareUnique -a
    DeclareUnique -a a b c
    DeclareUnique -a -- -element1 -element2

    DeclareUnique -A
    DeclareUnique -A '[]key1"' val1 key2 'val2 "\  [ ]'
}

Main "$@"
