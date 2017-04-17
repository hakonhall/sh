#!/bin/bash

source base.sh

function Main {
    Fatal "a" "b"
}

Main "$@"
