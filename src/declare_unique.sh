if test -v SOURCE_DECLARE_UNIQUE_SH
then
    return 0
fi
declare SOURCE_DECLARE_UNIQUE_SH=1

declare -i DECLARE_UNIQUE_next_id=0

# Usage: declare_unique [-aAiltux] [--] [initval...]
# Declare and initialize a globally unique variable, the name stored in REPLY.
#
# The variable is initialized to an empty string/array if INITVAL is absent.
# Otherwise, at most one INITVAL can be present for a string, and for an
# associative array the INITVAL must come in pairs of key/value.
#
# See 'declare' for explanation of attributes.  The -g global attribute is
# implicit.  The -n nameref, -r readonly, -f function names, and -F inhibit
# functions attributes of 'declare' are illegal with 'declare_unique'.
#
# Returns 0 on success, or otherwise exits the process with an error message.
#
# Example: Declares an empty string variable with a globally unique name
# assigned to REPLY.
#   declare_unique
#
# Example: Declare an associative array, initialized with two elements.
#   declare_unique -A key1 val1 key2 val2

# declare unique (-u)
# declare2 -u

function declare_unique {
    local name="declare_unique_$((DECLARE_UNIQUE_next_id++))"
    InternalDeclare "$name" "$@"
    REPLY="$name"
}

function InternalDeclare {
    local name="$1"
    shift

    local type="" # meaning string
    local -a options=() # To be passed to declare

    while true
    do
        if (($# == 0))
        then
            break
        elif test "$1" == --
        then
            shift
            break
        elif test "${1:0:1}" != -
        then
            break
        fi

        local option="$1"

        local -i i
        for ((i = 1; i < ${#option}; ++i))
        do
            local attribute="${option:$i:1}"
            case "$attribute" in
                a|A)
                    # If both a and A have been defined, bash will report an
                    # error below when declaring the variable.
                    type="$attribute"
                    ;;
                n|r|f|F)
                    Fatal "Attribute not supported with $FUNCNAME: '$attribute'"
                    ;;
                [a-zA-Z])
                    :
                    ;;
                *)
                    # Make sure we don't allow e.g. space to let through to the
                    # eval below.
                    Fatal "Invalid attribute '$attribute'"
                    ;;
            esac
        done

        options+=("$option")
        shift
    done

    local -a args=("$@")

    # The -g is implicit
    # Both options and name are guaranteed to be safe for eval, see above
    eval "declare -g ${options[*]} $name"
    local -n nameref="$name"

    case "$type" in
        a)
            nameref=("${args[@]}")
            ;;
        A)
            # In case ${#args[@]} is 0, e.g. `declare -p' on name will fail
            # with "not found" instead of succeeding with ...=(), unless we
            # initialize the associative array.  This is why we define
            # associative arrays to be initialized without VALUE argument.
            nameref=()

            if ((${#args[@]} % 2 != 0))
            then
                Fatal "There must be an even number of arguments to declare_unique -A"
            fi

            local -i i
            for ((i = 0; i < ${#args[@]}; i+=2))
            do
                local key="${args[$i]}"
                local value="${args[$((i + 1))]}"
                nameref["$key"]="$value"
            done
            ;;
        *)
            case "${#args[@]}" in
                0) nameref="" ;;
                1) nameref="${args[0]}" ;;
                *)
                    # Conforming 'declare' behavior:
                    #   declare x=(a b)
                    # will implicitly define x to be an array.
                    nameref=("${args[@]}")
                    ;;
            esac
            ;;
    esac
}
