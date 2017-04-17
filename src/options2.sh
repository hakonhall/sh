if test -v SOURCE_OPTIONS_SH
then
    return
fi
declare -r SOURCE_OPTIONS_SH=1

# Shell module options - Define and parse options.
#
# Make a globally unique variable prefix, and pass that in as the first
# argument to each of the functions below (parameter named 'this').

source base.sh
source define.sh
source map.sh
source match.sh

declare -r OPTIONS_SHORT_OPTION='^-[a-zA-Z]$'
declare -r OPTIONS_LONG_OPTION='^(--[a-zA-Z0-9][a-zA-Z0-9_-]*)(=(.*))?$'

# Usage: ParseOption VALOPTS ARG [ARG2...]
# Parse the next command-line argument
#
# On success, 0 is returned and:
#  - REPLY is set to the number of arguments parsed, between 0 and 2.
#  - REPLY2 is set to "true" if, after discarding the number of arguments given
#    by REPLY, the next argument may be an option and ParseOption can be called
#    again.  Otherwise "false" is returned.  "false" is returned if ARG is "--"
#    (discarding "--"), or "-", or if ARG does not begin with "-".
#  - MREPLY is an associative array with the option names and values, set by
#    ARG (and ARG2 if necessary).  There may any number of name/value pairs set.
#
# On parse failure, 1 is returned and REPLY is set to a descriptive error
# message.
#
# VALOPTS is the name of an associative array.  The name MUST NOT be prefixed
# by "ParseOption".  VALOPTS must be set to "true" for each option that
# requires a value argument.  For instance if VALOPTS is "foo" and
# foo=([-a]=true [-b]=false), then passing "-a" "bar" as ARG ARG2, bar is taken
# as it's value of that option, setting MREPLY[-a]=bar.  With "-b" "bar",
# MREPLY[-b]=true and "bar" is not consumed (REPLY).
function ParseOption {
    local -n ParseOption_need_arg_map="$1"
    local ParseOption_arg="$2"

    if test "$ParseOption_arg" == --
    then
        REPLY=1
        REPLY2=false
        MREPLY=()
        return 0
    elif test "${ParseOption_arg:0:2}" == --
    then
        local ParseOption_option ParseOption_assignment ParseOption_value
        if ! Match "$ParseOption_arg" "$OPTIONS_LONG_OPTION" \
             ParseOption_option ParseOption_assignment ParseOption_value
        then
            REPLY="Long option '$ParseOption_arg' is not a valid"
            return 1
        fi

        if test -v ParseOption_need_arg_map["$ParseOption_option"] \
                -a "${ParseOption_need_arg_map[$ParseOption_option]}" == true
        then
            if test -n "$ParseOption_assignment"
            then
                # Example: --foo=val
                REPLY=1
                REPLY2=true
                MREPLY=(["$ParseOption_option"]="$ParseOption_value")
                return 0
            elif (( $# < 3 ))
            then
                # Example: --foo, but --foo takes an ParseOption_arg and no
                # ARG2 was provided
                REPLY="Missing argument to '$ParseOption_option'"
                return 1
            else
                # Example: --foo val
                REPLY=2
                REPLY2=true
                MREPLY=(["$ParseOption_option"]="$3")
                return 0
            fi
        elif test -n "$ParseOption_assignment"
        then
            # Example: --foo=val, but foo is supposed to take no argument
            REPLY="Option '$ParseOption_option' takes no argument"
            return 1
        else
            # Example: --foo
            REPLY=1
            REPLY2=true
            MREPLY=(["$ParseOption_option"]="true")
            return 0
        fi
    elif test "$ParseOption_arg" == -
    then
        # This is really a very special argument.  Some treat "-" as stdin, so
        # we try to support that by forcing - be parsed as the first
        # non-option.
        REPLY=0
        REPLY2=false
        MREPLY=()
        return 0
    elif test "${ParseOption_arg:0:1}" == -
    then
        MREPLY=()

        local -i ParseOption_i
        for ((ParseOption_i = 1; ParseOption_i < ${#ParseOption_arg};
              ++ParseOption_i))
        do
            local ParseOption_c="${ParseOption_arg:$ParseOption_i:1}"
            
            if ! Match "$ParseOption_c" '[a-zA-Z0-9]'
            then
                REPLY="Invalid short option '$ParseOption_c'"
                return 1
            fi

            if test -v ParseOption_need_arg_map[-"$ParseOption_c"] \
                    -a "${ParseOption_need_arg_map[-$ParseOption_c]}" == true
            then
                if (( ParseOption_i + 1 < ${#ParseOption_arg} ))
                then
                    # Example: -fval
                    local -i ParseOption_j=ParseOption_i+1
                    MREPLY[-"$ParseOption_c"]="${ParseOption_arg:$ParseOption_j}"
                    REPLY=1
                    REPLY2=true
                    return 0
                elif (( $# < 3 ))
                then
                    # Example: -f, but -f takes an argument and no ARG2 was
                    # provided
                    REPLY="Missing argument to short option '$ParseOption_c'"
                    return 1
                else
                    # Example: -f val
                    REPLY=2
                    REPLY2=true
                    MREPLY[-"$ParseOption_c"]="$3"
                    return 0
                fi
            else
                # Example: -f
                MREPLY[-"$ParseOption_c"]=true
            fi
        done

        REPLY=1
        REPLY2=true
        return 0
    else
        REPLY=0
        REPLY2=false
        return 0
    fi
}

# Usage: DefineOption [OPTION...] NS OPT [ALIAS...]
# Define option to be parsed with ParseOptions
#
# NS is a globally unique variable prefix to use for defining various
# variables. OPT is the option to define, e.g. --foo or -f. ALIAS are option
# aliases: Say OPT is --foo, then -f could be an alias.
#
# Options:
#   -d VALUE  Default value of the option, "false" by default.
#   -n NS     Define the option with a "${NS}_" prefix
function DefineOption {

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
function ParseOption2 {
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

    local -n option_ids="$context"_option_ids

    if ! test -v option_ids["$option"]
    then
        _2="Unknown option '$option'"
        return 2
    fi
    local option_id="${option_ids[$option]}"

    local -n option_info="$context"_option_info_"$option_id"

    local -n option_varname="${option_info[varname]}"
    if test -v option_info[-a] -a "${option_info[-a]}" == true
    then
        if (( $# < 3 ))
        then
            return 1
        fi

        option_varname="$3"
        _1=1
        return 0
    else
        option_varname=true
        _1=0
        return 0
    fi
}

function ParseOptions2 {
    local -A our_options=([-n]=true)

    local ns=Options

    local -a non_options=()
    while (( $# > 0 ))
    do
        if test "$1" == --
        then
            break
        fi

        if ! ParseOption2 Options_OptionCallback "$ns" "$@"
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
