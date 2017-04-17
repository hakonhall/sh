if test -v SOURCE_OPTIONS_SH
then
    return
fi
declare -r SOURCE_OPTIONS_SH=1

# Shell module options - Define and parse options.

source base.sh

# Problem:
#  - How does ParseOptions parse its own options?
#  - It could perhaps define its options (DefineOption) and then call
#    ParseOptions?  But then, how does DefineOption parse ITS options?

function InternalParseOptions {
    local -n InternalParseOptions_options="$1"
    shift

    for 

function ParseOptions {
    local -A options=([-n]="")
    InternalParseOptions options "$@"
}




declare -r OPTIONS_SHORT_OPTION='^-[a-zA-Z]$'
declare -r OPTIONS_LONG_OPTION='^(--[a-zA-Z0-9][a-zA-Z0-9_-]*)(=(.*))?$'

# Hard-coded option variables for DefineOption, since DefineOption cannot set
# them.
declare -A Options_option_DefineOption_ids=([-a]=_a [-v]=_v)
declare Options_option_DefineOption_info__a=([varname]=DefineOption__a)
declare Options_option_DefineOption_info__v=(
    [varname]=DefineOption__v [-a]=true)
declare DefineOption__a=false
declare DefineOption__v=""

function DefineOption {
    ParseOptions -n DefineOption -- "$@"
    set -- "${_1a[@]}"

    if (( $# == 0 ))
    then
        Fatal "Missing option to be defined"
    fi

    local option="$1"
    shift

    # Prefix for the option variables
    local ns=""

    # Prefix for metadata of option
    local context=Options_option
    if (( ${#ns} > 0 ))
    then
        context+=_"$ns"
    fi

    local ids_varname="$context"_ids
    declare -gA "$ids_varname"
    local -n ids="$ids_varname"

    if test -v ids["$option"]
    then
        Fatal "Option '$option' has already been defined"
    fi

    local id="${option//-/_}"
    AssertValidVariableName "$id"

    ids["$option"]="$id"

    local info_varname="$context"_info_"$id"
    declare -gA "$info_varname"
    local -n info="$info_varname"

    if (( ${#ns} == 0 ))
    then
        local varname="$id"
    else
        if ! test "${id:0:1}" == _
        then
            Fatal "Expected first char of option name '$id' to be _"
        fi
        # Should we really add a _ between ns and id?  Long options then
        # gets three consequtive _: ns___foo.  With _, it follows the standard
        # practice for namespaces of NS_REST, which allows for other stuff to
        # be put in the same namespace, without conflicting with the options.
        local varname="$ns"_"$id"
    fi

    info[varname]="$varname"

    local alias
    for alias in "$@"
    do
        ids["$alias"]="$id"
    done        
}

# Usage: DefineOption [OPTION...] -- OPT [ALIAS...]
# Define an option to be parsed with ParseOptions later
#
# NS is a globally unique variable prefix to use for defining various
# variables. OPT is the option to define, e.g. --foo or -f. ALIAS are option
# aliases: Say OPT is --foo, then -f could be an alias.
#
# Options:
#   -d VALUE  Default value of the option, "false" by default.
#   -n NS     Define the option with a "${NS}_" prefix
function DefineOption2 {

    local -A options_with_args=([-d]=true [-n]=true)
    local -A allowed_options=([-a]=true)
    Map_AddTo options_with_args allowed_options

    local -A options=()
    while (( $# > 0 ))
    do
        if ! ParseOption options_with_args "$@"
        then
            Fatal "$REPLY"
        fi
        local shifts="$REPLY"
        local more="$REPLY2"
        local -A arg_options
        Map_CopyTo MREPLY arg_options

        Map_KeyDiff arg_options allowed_options
        local -a disallowed_options=("${AREPLY[@]}")
        if (( ${#disallowed_options[@]} > 0 ))
        then
            Fatal "Unknown options: ${disallowed_options[*]}"
        fi

        Map_AddTo arg_options options

        shift "$shifts"

        if ! "$more"
        then
            break
        fi
    done

    if (( $# == 0 ))
    then
        Fatal "No option specified"
    fi

    local option="$1"
    shift

    local option_varname="${option//-/_}"
    AssertValidVariableName "$option_varname"

    local -a define_options=()
    if test -v options[-n]
    then
        local namespace="${options[-n]}"
        AssertValidVariableName "$namespace"

        # The option variables are namespace-less without -n.
        define_options+=(-o "${options[-n]}")
    else
        local namespace=OPTIONS
    fi

    ResolveGlobalVariableName "$namespace" alias_map
    local alias_map_varname="$REPLY"
    if test -v "$alias_map_varname"
    then
        if ! declare -Ap "$alias_map_varname" &> /dev/null
        then
            Fatal "Variable '$alias_map_varname' already defined as non-map"
        fi
    else
        DefineGlobalVariable -A "$alias_map_varname"
    fi

    local -n alias_map="$alias_map_varname"
    if test -v alias_map["$option"]
    then
        Fatal "Option '$option' has already been defined"
    fi

    local option_default_value="${options[-d]:-false}"

    DefineGlobalVariable "${define_options[@]}" \
                         "$option_varname" "$option_default_value"
    local fq_option_varname="$REPLY"

    alias_map["$option"]="$fq_option_varname"

    local alias
    for alias in "$@"
    do
        alias_map["$option"]="$fq_option_varname"
    done

    REPLY="$fq_option_varname"
}

# Usage: ParseOption CALLBACK CONTEXT ARG [ARG2...]
# Parse next command-line argument ARG
#
# In order to parse ARG the next argument ARG2 MAY have to be present.  Absence
# of ARG2 will in this case be interpreted as an error.  Arguments following
# ARG2 are ignored.  This makes it easy for the caller to just pass "$@".
#
# CALLBACK must be a function not prefixed with Options and with the following
# interface:
# 
#   Usage: CALLBACK CONTEXT OPTION [VALUE]
#   Register the presence of OPTION.
#
#   CONTEXT has been passed unaltered through ParseOption.  OPTION is either a
#   long option like --foo, or short option like -f.
#
#   Returns 0 on success, in case "$_1" has the number consumed arguments (0-1).
#   Returns 1 if VALUE was not present and is required.
#   Returns 2 on other failure, in case "$_2" has been set to a descriptive
#   error message.
#
# Returns 0 on success, in case _1 is set to the number of arguments consumed
# (0-2).
#
# On error, 1 is returned and _2 is set to an appropriate error message.
function ParseOption {
    local Options_parse_callback="$1"
    local Options_parse_context="$2"
    local Options_parse_arg="$3"
    shift 3
    
    if test "${Options_parse_arg:0:2}" == --
    then
        local Options_parse_option Options_parse_assignment Options_parse_value
        if ! Match "$Options_parse_arg" "$OPTIONS_LONG_OPTION" \
             Options_parse_option Options_parse_assignment Options_parse_value
        then
            _2="Invalid long option '$Options_parse_arg'"
            return 1
        fi

        if (( ${#Options_parse_assignment} == 0 ))
        then
            if "$Options_parse_callback" "$Options_parse_context" \
                                  "$Options_parse_option"
            then
                # Example: --foo
                _1=1
                return 0
            elif test $? == 1
            then
                if (( $# == 0 ))
                then
                    # Example: --foo, but --foo takes an argument and no ARG2
                    # was provided
                    _2="Missing argument to '$Options_parse_arg'"
                    return 1
                else
                    local Options_parse_arg2="$1"
                    if "$Options_parse_callback" "$Options_parse_context" \
                                                 "$Options_parse_option" \
                                                 "$Options_parse_arg2"
                     
                    then
                        # Example: --foo val
                        _1=2
                        return 0
                    else
                        # Example: --foo val, but callback reported an error
                        _2="$_2"
                        return 1
                    fi
                fi
            else
                # Example: --foo, but callback reported an error
                _2="$_2"
                return 1
            fi
        else
            if "$Options_parse_callback" "$Options_parse_context" \
                                         "$Options_parse_option" \
                                         "$Options_parse_value"
            then
                local shifts="$_1"

                # Example: --foo=val
                _1=1
                return 0
            else
                # Example: --foo=val, but callback reported an error
                _2="$_2"
                return 1
            fi
        fi
    elif test "${Options_parse_arg:0:1}" == -
    then
        _1A=()

        local -i Options_parse_i
        for ((Options_parse_i = 1; Options_parse_i < ${#Options_parse_arg};
              ++Options_parse_i))
        do
            local Options_parse_c="${Options_parse_arg:$Options_parse_i:1}"
            local Options_parse_option=-"$Options_parse_c"
            
            if ! Match "$Options_parse_c" '[a-zA-Z]'
            then
                _2="Invalid short option '$Options_parse_option'"
                return 1
            fi

            if "$Options_parse_callback" "$Options_parse_context" \
                                         "$Options_parse_option"
            then
                # Example: -f
                :
            elif test $? == 1
            then
                if (( Options_parse_i + 1 < ${#Options_parse_arg} ))
                then
                    local -i Options_parse_j=Options_parse_i+1
                    local Options_parse_value="${Options_parse_arg:$Options_parse_j}"
                    if "$Options_parse_callback" "$Options_parse_context" \
                                                 "$Options_parse_option" \
                                                 "$Options_parse_value"
                    then
                        # Example: -fval
                        _1=1
                        return 0
                    else
                        # Example: -fval, but callback failed
                        _2="$_2"
                        return 1
                    fi
                elif (( $# == 0 ))
                then
                    # Example: -f, but -f takes an argument and no ARG2 was
                    # provided
                    _2="Missing argument to '$Options_parse_arg'"
                    return 1
                else
                    local Options_parse_arg2="$1"
                    if "$Options_parse_callback" "$Options_parse_context" \
                                                 "$Options_parse_option" \
                                                 "$Options_parse_arg2"
                     
                    then
                        # Example: -f val
                        _1=1
                        return 0
                    else
                        # Example: -f val, but callback reported an error
                        _2="$_2"
                        return 1
                    fi
                fi
            else
                # -f, but callback reported error
                _2="$_2"
                return 1
            fi
        done

        _1=1
        return 0
    else
        _1=0
        return 0
    fi
}

function Options_OptionCallback {
    local context="$1"
    local option="$2"

    local -n ids="$context"_ids

    if ! test -v ids["$option"]
    then
        _2="Unknown option '$option'"
        return 2
    fi
    local id="${ids[$option]}"

    local -n info="$context"_info_"$id"

    local -n varname="${info[varname]}"
    if test -v info[-a] -a "${info[-a]}" == true
    then
        if (( $# < 3 ))
        then
            return 1
        fi

        varname="$3"
        _1=1
        return 0
    else
        varname=true
        _1=0
        return 0
    fi
}

# Usage: ParseOptions [OPTION...] -- [ARG...]
# Parse the command line arguments ARG for options and non-options
function ParseOptions {
    while true
    do
        if (( $# == 0 ))
        then
            Fatal "Missing --"
        fi

        if test "$1" == --
        then
            shift
            break
        fi

        shift
    done
            

    local -A our_options=([-n]=true)

    local ns=""

    local context=Options_option
    if (( ${#ns} > 0 ))
    then
        context+=_"$ns"
    fi

    local -a non_options=()
    while (( $# > 0 ))
    do
        if test "$1" == --
        then
            break
        fi

        if ! ParseOption Options_OptionCallback "$context" "$@"
        then
            Fatal "$_2"
        fi

        local shifts="$_1"

        if (( shifts == 0 ))
        then
            non_options+=("$1")
            shift
        else
            shift "$shifts"
        fi
    done

    non_options+=("$@")

    _1a=("${non_options[@]}")
}
