#!/bin/bash

source function_doc.sh

# Usage: TestFunction [OPTION...] ARGS...
# This is a one-line description.
#
# The previous line had # without a space after.
function TestFunction {
    return 0
}

function Main {
    GetFunctionDoc TestFunction

    # No \n before last EOF, since the function doc (should) end with a
    # newline.
    printf "REPLY=<<EOF\n%sEOF\n" "$REPLY"
}

Main "$@"
