# Shell module first  -  Detect first execution
#
# This file should be sourced with `source' or `.' from another shell module or
# shell program.

if test -v FIRST
then
    return
fi

declare -A FIRST=()

# Usage: First [global_id]
# Return 0 the first time First is called with the given global_id, otherwise 1.
function First {
    # Why prefix with "_"? Because it allows calling First without arguments.
    local global_id="_${1:-}"

    if test -v FIRST["$global_id"]
    then
        return 1
    else
        FIRST["$global_id"]=1
        return 0
    fi
}
