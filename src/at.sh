if test -v SOURCE_AT_SH
then
    return
fi
declare -r SOURCE_AT_SH=true

source variable.sh
source match.sh

declare AT_IN_INIT=false
declare -i AT_NEXT_ID=0

function new {
    local class="$1"
    shift
    local -a init_args=("$@")

    local address="$(( AT_NEXT_ID++ ))"
    local ns=AT_NS_"$address"
    declare -g "$ns"_class="$class"
    declare -gA "$ns"_fields
    local -n fields="$ns"_fields
    fields=()

    local -i exit_code=0

    local init_function_name="$class"_init
    if declare -F > /dev/null
    then
        local this="$address"
        local previous_at_in_init="$AT_IN_INIT"
        AT_IN_INIT=true
        if "$init_function_name" "${init_args[@]}"
        then
            AT_IN_INIT="$previous_at_in_init"
        else
            exit_code=$?
            AT_IN_INIT="$previous_at_in_init"
        fi
    fi

    _1="$address"
    return "$exit_code"
}

# Usage: @local [-aAilrtu] NAME [VALUE...]
# Declare a member variable (field)
function @local {
    if ! test -v this
    then
        Fatal "'this' is not defined"
    fi

    if ! "$AT_IN_INIT"
    then
        Fatal "@local can only be called within the init function"
    fi

    local -A options=()

    while (( $# > 0 ))
    do
        if test "${1:0:1}" == -
        then
            local -i i=0
            for (( i=1; i<${#1}; ++i ))
            do
                local c="${1:$i:1}"
                case "$c" in
                    a|A|i|l|r|t|u)
                        options[-"$c"]=true
                        ;;
                    *)
                        Fatal "Unknown short option '$c'"
                        ;;
                esac
            done
            shift
        else
            break
        fi
    done

    if test -v options[-a] -a -v options[-A]
    then
        Fatal "Cannot specify both an indexed (-a) and associative (-A) array"
    fi

    if (( $# == 0 ))
    then
        Fatal "Missing member variable name"
    fi

    local field_name="$1"
    shift
    AssertValidVariableName "$field_name"
    local name=AT_NS_"$this"_field_"$field_name"

    if test -v "$name"
    then
        Fatal "'$field_name' has alread been defined"
    fi

    declare -g "${!options[@]}" "$name"

    local -n fields=AT_NS_"$this"_fields
    fields["$field_name"]="{options[*]}"

    if test -v options[-a]
    then
        local -n varref="$name"
        varref=("$@")
    elif test -v options[-A]
    then
        local -n varref="$name"
        varref=()

        while (( $# > 0 ))
        do
            if (( $# == 1 ))
            then
                Fatal "The arguments following the name of an associated " \
                      "array field name must come in key/value pairs"
            fi

            varref["$1"]="$2"
            shift 2
        done
    else
        if (( $# != 1 ))
        then
            Fatal "Defining a string member variable requires 1 value argument"
        fi

        local -n varref="$name"
        varref="$1"
    fi
}

# Usage: @ REF [ARG...]
# Resolve reference
#
# REF is of the form:
#   ADDR.MEMBER   Member variable or member function MEMBER of object with
#                 address ADDR as returned in _1 of 'new'.
#   .MEMBER       Same as ADDR.MEMBER with ADDR set to "$this".  Can be used
#                 in member function.
#
# If MEMBER has been defined as a member variable with @local in the CLASS_init
# function, _1 is set to the fully qualified name of that member variable (a
# unique global variable) with a prefix under AT_NS.  No ARG can be present.
# Use nameref (declare -n) to refer to the variable.
#
# Otherwise, if CLASS_MEMBER is a function, and that function is called with a
# variable 'this' set to ADDR, and arguments [ARG...].
function @ {
    if test -v this
    then
        local has_this=true
    else
        local has_this=false
    fi

    local ref="$1"
    shift

    local object member
    if ! Match "$ref" '^([a-zA-Z0-9_]+)?(\.([a-zA-Z0-9_]+))?$' object '' member
    then
        Fatal "Bad reference '$ref'"
    fi

    if (( ${#object} == 0 ))
    then
        if ! "$has_this"
        then
            Fatal "'this' variable were not defined"
        fi
        object="$this"
    fi

    if (( ${#member} > 0 ))
    then
        local field_name=AT_NS_"$object"_field_"$member"
        if test -v "$field_name"
        then
            if (( $# != 0 ))
            then
                Fatal "Not supported yet"
            fi

            _1="$field_name"
            return 0
        fi

        local class_varname=AT_NS_"$object"_class
        local -n class="$class_varname"

        local method="$class"_"$member"
        if declare -F "$method" > /dev/null
        then
            local this="$object"
            if "$method" "$@"
            then
                return 0
            else
                return $?
            fi
        fi
    fi

    Fatal "Not supported yet"
}

function @dump {
    local address="$1"

    local class_varname=AT_NS_"$address"_class
    local -n class="$class_varname"

    printf "Object %d of class %s\n" "$address" "$class"

    local -n fields=AT_NS_"$address"_fields
    local field
    for field in "${!fields[@]}"
    do
        @ "$address"."$field"
        printf "Field %s: %s\n" "$field" "$(declare -p "$_1")"
    done
}
