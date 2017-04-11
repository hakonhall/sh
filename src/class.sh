if test -v SOURCED -a -v SOURCED[namespaces]
then
    return 0
fi
declare -A SOURCED
SOURCED[namespaces]=true


declare -i NAMESPACES_next_id=0

function Fail {
    echo "Error: $*" >&2
    exit 1
}

function CheckIdentifier {
    local func="$1"
    local id="$2"

    if test "$id" == _
    then
        :
    elif [[ "$id" =~ ^[0-9]+$ ]]
    then
        :
    elif [[ "$id" =~ ^[a-zA-Z0-9_]+$ ]]
    then
        return 0
    fi

    Fail "$func: \`$id': not a valid identifier"
}

# Usage: declare_unique [-aAiltux] [--] [value...]
# Declare and initialize a globally unique variable, the name stored in REPLY.
#
# The variable is initialized to an empty string/array if VALUE is absent.  For
# an indexed and associative arrays, each VALUE denotes element of the compound
# assignment.
#
# See 'declare' for explanation of attributes.  The -g global attribute is
# implicit.  The -n nameref, -r readonly, -f function names, and -F inhibit
# functions attributes of 'declare' are illegal with 'declare_unique'.
#
# Example: Declare a globally unique string variable and sets it to the empty
# string, the name assigned to the variable REPLY.
#   declare_unique
#
# Example: Declare a globally unique associative array, initialized with two
# elements with key/value pair k1/v1 and k2/v2.
#   declare_unique -A '[k1]=v1' '[k2]=v2'
function declare_unique {
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
                    Fail "declare_unique: The '$attribute' attribute is not supported"
                    ;;
                [a-zA-Z])
                    :
                    ;;
                *)
                    # Make sure we don't allow e.g. space to let through to the
                    # eval below.
                    Fail "declare_unique: invalid attribute '$attribute'"
                    ;;
            esac
        done

        options+=("$option")
        shift
    done

    local -a args=("$@")

    local full_name="declare_unique_$((NAMESPACES_next_id++))"
    
    # The -g is implicit
    # Both options and full_name are guaranteed to be safe for eval, see above
    eval "declare -g ${options[*]} $full_name"
    local -n nameref="$full_name"

    case "$type" in
        a|A)
            nameref=("${args[@]}")
            ;;
        *)
            case "$#" in
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

    REPLY="$full_name"
}

function ns.create {
    case "$#" in
        0) local id="$((NAMESPACES_next_id++))" ;;
        1)
            # Why doesn't the caller just use global variables (and how does
            # the caller guarantee no other part of the program uses the same
            # id?)?
            # TODO: Consider banning this case.
            local id="$1"
            CheckIdentifier ns.create "$id"
            ;;
        *)
            Fail "CreateNamespace takes 0-1 arguments"
            ;;
    esac

    eval "declare -gA NAMESPACES__${id}vars=()"

    OUT="$id"
}

function ns.declare {
    local namespace_id="$1"

    local attribute=""
    if test "${2:0:1}" == -
    then
        case "$2" in
            -a|-A|-i)
                attribute="$2"
                shift
                ;;
            *)
                Fail "Unknown attribute '$2'"
                ;;
        esac
    fi

    local name="$2"
    shift 2
    local -a args=("$@")

    if ! Match "${namespace_id}" '^[0-9]+$' ||
                ((namespace_id >= NAMESPACES_next_id))
    then
        Fail "Bad namespace '$namespace_id'"
    fi
    local namespace="NAMESPACES_${namespace_id}"

    CheckIdentifier ns.declare "$name"

    local -n vars="${namespace}vars"
    if test -v vars["$name"]
    then
        Fail "A variable '$name' has already been defined in the namespace $namespace_id"
    fi
    vars["$name"]="$attribute"

    local full_name="${namespace}_${name}"
    eval "declare -g $attribute $full_name"
    local -n var="$full_name"

    case "$attribute" in
        -a)
            var=("${args[@]}")
            ;;
        -A)
            # Each "${args[@]}" is of the form [x]=y, but both x and y may
            # contain e.g. spaces. y may contains special characters.
            local assignment
            for assignment in "${args[@]}"
            do
                local key value
                if ! Match "$assignment" '^\[([^]]+)\]=(.*)$' key value
                then
                    Fail "Associative arrays (maps) must be initialized with elements of the form: [key]=value."
                fi
                var["$key"]="$value"
            done
            ;;
        -i|'')
            # Both integer and string can be done in the same way
            case "$#" in
                0) : ;;
                1)
                    var="$1"
                    ;;
                *)
                    shift
                    Fail "Arguments following initializer of variable: '$*'"
                    ;;
            esac
            ;;
        *)
            Fail "Internal error: Unknown declaration attribute '$attribute'"
            ;;
    esac
}

function ns.full_name {
    case "$#" in
        1)
            local key="$1"
            ;;
        2)
            local namespace_id="$1"
            local name="$2"

            local key="${namespace_id}_${name}"
            ;;
        *)
            Fail "Wrong number of arguments: $#"
            ;;
    esac

    local full_name="NAMESPACES_$key"
    if ! test -v "$full_name"
    then
        Fail "There is no variable with key '$key'"
    fi

    OUT="$full_name"
}

function Main {
    declare_unique
    local axis_varname="$REPLY"
    echo "axis_varname=$axis_varname"
    local -n axis="$axis_varname"
    axis=foo

    local -n axis2="$axis_varname"
    echo "axis2=$axis2"

    unset axis
    echo "After axis2=$axis2"


    declare_unique value1
    local foo_varname="$REPLY"
    echo "foo_varname=$foo_varname"
    local -n fooref="$foo_varname"
    echo "Before fooref=$fooref"
    fooref=bar
    echo "After fooref=$fooref"
    unset fooref


    declare_unique -a
    local colors_varname="$REPLY"
    local -n colors="$colors_varname"
    colors=(red green)

    local -n colors2="$colors_varname"
    echo "colors2=${colors2[*]}"
    unset colors2
    echo "After: colors2=${colors2[*]}"
}

Main "$@"
