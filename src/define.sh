if test -v SOURCE_DEFINE_SH
then
    return
fi
declare -r SOURCE_DEFINE_SH=true

source base.sh

declare -i DEFINE_next_id=0
declare -A DEFINE_namespaces=()

function AssertValidVariableName {
    local id="$1"

    if test "$id" == _
    then
        # $_ is an automatic variable
        :
    elif [[ "$id" =~ ^[0-9]+$ ]]
    then
        # An integer cannot name a variable
        :
    elif [[ "$id" =~ ^[a-zA-Z0-9_]+$ ]]
    then
        return 0
    else
        # E.g. empty string, @£@$, etc.
        :
    fi

    Fatal "$func: \`$id': not a valid identifier"
}

function ResolveGlobalVariableName {
    local namespace="$1"
    local name="$2"
    REPLY="${namespace}_${name}"
}

# Usage: DefineGlobalVariable [OPTION...] [NAME] [VALUE...]
# Declare and set a global variable.
#
# The main benefit of DefineGlobalVariable over `declare' is the ability to
# define namespaces, see below.
#
# NAME is declared with the given options, and then set according to the type
# of the declaration:
#   - An indexed array (-a) with VALUE as the elements.
#   - An associative array (-A) with each pair of VALUE definig a key/value
#     pair.
#   - A namespace (-N). No VALUE can be present.
#   - Otherwise the type is string, and at most one VALUE must be present.
#     Without VALUE, the string is initialized to the empty string.
#
# Options
#   -a             Make NAME an (indexed) array (see `declare')
#   -A             Make NAME an associative array (map) (see `declare')
#   -c             Create a unique NAME to return in REPLY
#   -i             Convert value(s) to integer (see `declare')
#   -l             Convert value(s) to lower-case (see `declare')
#   -N             Make NAME a namespace
#   -o NAMESPACE   Define NAME in the given namespace, returning the full
#                  global name in REPLY
#   -r             Make NAME readonly (see `declare')
#   -u             Convert value(s) to upper-case (see `declare')
#   -x             Export NAME to environment for commands (see `declare')
#
# All options of `declare' are valid above, except: fFngt ("g" is implicit)
#
# A namespace serves as a container for other variables: You can define
# strings, arrays, and maps (associative arrays) "within" a namespace. To
# identify such a variable you need the name of the namespace, returned in
# REPLY from a DefineGlobalVariable's -N, and an identifier unique within the
# namespace.  In reality, every such variable has a globally unique variable
# name returned in REPLY from DefineGlobalVariable (with -o), or explicitly
# later with ResolveGlobalVariableName.  Use `declare -n' to bind to that name
# with a short reference variable.  Example:
#
#   DeclareGlobalVariable -cN
#   local ns="$1"
#   ... pass along $ns to various functions
#   DeclareGlobalVariable -i -o "$ns" doors 3
#   local -n doorsref="$REPLY"
#   doorsref+=2
#   DeclareGlobalVariable -i -o "$ns" wheels 4
#   ...
#   ResolveGlobalVariableName "$ns" doors
#   local -n doorsref="$REPLY"
#   doorsref=3
function DefineGlobalVariable {
    local -A options=()
    local -a declare_options=()

    while true
    do
        local arg="$1"

        if test "$arg" == --
        then
            shift
            break
        elif test "$arg" == -
        then
            Fatal "Bad argument \`-'"
        elif test "${arg:0:1}" == -
        then
            shift

            local -i i
            for (( i = 1; i < ${#arg}; ++i))
            do
                local option="${arg:$i:1}"

                case "$option" in
                    a)
                        if test -v options[N]
                        then
                            Fatal "Cannot convert a namespace to indexed array"
                        fi
                        options["$option"]="true"
                        declare_options+=(-"$option")
                        ;;
                    A)
                        if test -v options[N]
                        then
                            Fatal "Cannot convert a namespace to associative array"
                        fi
                        options["$option"]="true"
                        declare_options+=(-"$option")
                        ;;
                    N)
                        if test -v options[a]
                        then
                            Fatal "Cannot convert an indexed array to namespace"
                        fi
                        if test -v options[A]
                        then
                            Fatal "Cannot convert an associative array to namespace"
                        fi
                        options["$option"]="true"
                        ;;
                    o)
                        local namespace
                        if (( i + 1 < ${#arg} ))
                        then
                            # The -o argument is the rest of $arg.
                            namespace="${args:$((i + 1))}"
                        elif (( $# == 0 ))
                        then
                            Fatal "Missing argument to -o"
                        else
                            namespace="$1"
                            shift
                        fi

                        if ! test -v DEFINE_namespaces["$namespace"]
                        then
                            Fatal "Unknown namespace '$namespace'"
                        fi
                        options["$option"]="$namespace"
                        # Ensure the for-loop breaks
                        i="${#arg}"
                        break
                        ;;
                    c)
                        options["$option"]="true"
                        ;;
                    i|l|r|u|x)
                        options["$option"]="true"
                        declare_options+=(-"$option")
                        ;;
                    *) Fatal "Unknown option '$option'" ;;
                esac
            done
        else
            break
        fi
    done

    # "$@" contains the non-option arguments

    if test -v options[o]
    then
        if test -v options[c]
        then
            local bare_name="$((DEFINE_next_id++))"
        elif (( $# == 0 ))
        then
            Fatal "Missing argument NAME"
        else
            local bare_name="$1"
            shift
        fi
            
        ResolveGlobalVariableName "${options[o]}" "$bare_name"
        local name="$REPLY"
    elif test -v options[c]
    then
        local name="DEFINE_$((DEFINE_next_id++))"
    elif (( $# == 0))
    then
        Fatal "Missing argument NAME"
    else
        local name="$1"
        shift
    fi

    if test -v "$name"
    then
        Fatal "The variable '$name' has already been set"
    fi

    if test -v options[N]
    then
        if test -v options[a] -o \
                -v options[A] -o \
                -v options[i] -o \
                -v options[l] -o \
                -v options[r] -o \
                -v options[u] -o \
                -v options[x]
        then
            Fatal "'-N' options excludes options: aAilrux"
        fi

        if (( $# != 0 ))
        then
            Fatal "Defining a namespace takes no value arguments"
        fi
        DEFINE_namespaces["$name"]=true
    else
        eval "declare -g ${declare_options[*]} $name"
        local -n variable="$name"

        if test -v options[a]
        then
            variable=("$@")
        elif test -v options[A]
        then
            variable=()

            local -i i
            while (($# > 0))
            do
                if (($# == 1))
                then
                    Fatal "An associative array (map) must be initialized with " \
                          "an even number of VALUE arguments (each pair being a " \
                          "key/value pair"
                fi

                local key="$1"
                local value="$2"
                shift 2

                variable["$key"]="$value"
            done
        else
            case "$#" in
                0) variable="" ;;
                1) variable="$1" ;;
                *) Fatal "Defining a string takes exactly one value argument" ;;
            esac
        fi
    fi

    REPLY="$name"
}
