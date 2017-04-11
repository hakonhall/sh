#!/bin/bash

source namespaces.sh

function Main {
    # declare unique (-u) namespace (-N)
    # declare2 -u -N
    DeclareNewUniqueNamespace
    local ns="$REPLY"

    # declare in namespace (-N)
    # declare2 -N
    DeclareInNamespace "$ns" foo "initial string"
    local name="$REPLY"
    declare -p "$name"
    local -n nameref="$name"
    nameref="changed"
    declare -p "$name"
}

Main "$@"
