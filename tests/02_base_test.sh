#!/bin/bash

source base.sh

function Main {
    Fail "a" "b"
}

Main "$@"
