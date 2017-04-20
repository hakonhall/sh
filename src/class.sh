if test -v SOURCE_CLASS_SH
then
    return
fi
declare -r SOURCE_CLASS_SH=true

# class.sh - Classes in Bash
#
# A class CLASS has member functions (methods) named CLASS_METHOD.  To create a
# new object of a class, use @new.
#
#   @new CLASS
#   local obj="$_1"
#
# The value "$obj" may best be described as the address of the object, making
# 'obj' a pointer to the object, but this distinction is rarely needed.  A
# special method CLASS_init (constructor) is called by @new, if it exists.
# Inside the constructor (only), member variables can be declared and set with
# @local.
#
#   @local -a array el1 el2
#
# Inside any method, the address of the current object is accessible as
# "$this".  You can get the fully qualified global variable name of any field
# FIELD using @field_name, which can be used with nameref (local -n) to change
# the field.
#
#   @field_name array
#   local -n array="$_1"
#   array+=(el3)
#
# Own methods can be called with @call
#
#   @call add el4
#
# which will call CLASS_add with 1 argument "el4".
#
# You can refer to other object's fields and methods by dotting the object:
#
#   @field_name obj.array
#   ...
#   @call obj.add el5
#
# Fields and methods starting with an underscore cannot be referenced in this
# way unless the dereferenced object is of the exact same class - they are
# private to the class.

source _class.sh

source variable.sh
source match.sh

declare CLASS_IN_INIT=false
declare -i CLASS_NEXT_ID=0

# Usage: @new CLASS [ARG...]
# Creates a new object of type CLASS
#
# Sets _1 to an identifier (address) that can be used to refer to the created
# object.  Any variable having the address as a value will be called a pointer.
#
# If there is a function CLASS_init (constructor), it will be called with the
# given args.  Inside the constructor, 'this' is a pointer to the object being
# created.  @local can be used to create global variables identifiable by the
# object pointer and a name.
function @new {
    local class="$1"
    shift
    local -a init_args=("$@")

    local address="$(( CLASS_NEXT_ID++ ))"
    local ns=CLASS_"$address"
    declare -g "$ns"_class="$class"
    declare -gA "$ns"_fields
    local -n fields="$ns"_fields
    fields=()

    local -i exit_code=0

    local init_function_name="$class"_init
    if declare -F > /dev/null
    then
        local saved_class_in_init="$CLASS_IN_INIT"
        CLASS_IN_INIT=true

        # Makes 'this' available as a variable in init function.
        local this="$address"

        if "$init_function_name" "${init_args[@]}"
        then
            :
        else
            # This should probably be fatal, but we'll leave it to the
            # constructor and client.
            exit_code=$?
        fi

        CLASS_IN_INIT="$saved_class_in_init"
    fi

    _1="$address"
    return "$exit_code"
}

# Usage: @local [-aAilrtu] NAME [VALUE...]
# Declare a member variable (field)
#
# Can only be called in the constructor.  Fields starting with an underscore
# cannot be accessed using dot notation.
function @local {
    if ! test -v this
    then
        Fatal "'this' is not defined"
    fi

    if ! "$CLASS_IN_INIT"
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
    local name=CLASS_"$this"_field_"$field_name"

    if test -v "$name"
    then
        Fatal "'$field_name' has alread been defined"
    fi

    declare -g "${!options[@]}" "$name"

    local -n fields=CLASS_"$this"_fields
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

function @field_name {
    @_resolve_address "$@"
    @_resolve_field "$_1" "$_2"
}

# Usage: @call REF [ARG...]
# Calls the member function given by REF with the given arguments.
#
# See @resolve for how REF is resolved.
function @call {
    local ref="$1"
    shift

    @_resolve_address "$ref"
    local address="$_1"
    local member="$_2"

    @_class "$address"
    local class="$_1"

    local method="$class"_"$member"
    if ! declare -F "$method" > /dev/null
    then
        Fatal "No such function '$method'"
    fi

    local this="$address"
    "$method" "$@"
}

function @dump {
    local address="$1"

    local class_varname=CLASS_"$address"_class
    local -n class="$class_varname"

    printf "%s object with address %d\n" "$class" "$address"

    local -n fields=CLASS_"$address"_fields
    local field
    for field in "${!fields[@]}"
    do
        @_resolve_field "$address" "$field"
        local varname="$_1"
        printf "Field %s: %s\n" "$field" "$(declare -p "$varname")"
    done
}
