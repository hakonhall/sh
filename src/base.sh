if test -v SOURCE_BASE_SH
then
    return
fi
declare SOURCE_BASE_SH=1

# Function output variables. REPLY is defined/builtin, see `read'.
declare REPLY2 REPLY3
declare -a AREPLY AREPLY2
declare -A MREPLY MREPLY2

# Usage: Fail [message...]
# Print message to stderr and exit
#
# The messages are concatenated, and a newline is appended.
#
# To print additional debugging information like stack trace, use Die.
function Fail {
    exec >&2

    local message
    for message
    do
        printf "%s" "$message"
    done
    printf "\n"

    exit 1
}

# Usage: Fatal [message...]
# Print message to stderr, dump debug info, and exit the process with status 1.
#
# The messages are concatenated and a newline is appended.  Additional
# information may be printed before and after the message (timestamp, stack
# trace, etc).
#
# To print an exact message and exit with an error (1), use Fail.
#
# Use Fatal for internal errors: Errors that should not happen and needs to be
# fixed by the developer of the shell script or library.  Stack trace can be
# important in these cases.
function Fatal {
    exec >&2

    printf "$FUNCNAME: "
    local message
    for message
    do
        printf "%s" "$message"
    done
    printf "\n"
    
    local -i frame
    for ((frame = 1; frame < ${#BASH_SOURCE[@]}; ++frame))
    do
        local -i frame_minus_one=$((frame - 1))
        local source="${BASH_SOURCE[$frame]}"
        local lineno="${BASH_LINENO[$frame_minus_one]}"
        local func="${FUNCNAME[frame]}"

        if test "$func" == main
        then
            local func_suffix=""
        else
            local func_suffix=" in $func"
        fi

        printf "  at %s:%d%s\n" "$source" "$lineno" "$func_suffix"
    done

    exit 1
}
