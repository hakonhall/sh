if test -v SOURCE_OPTIONS_SH
then
    return
fi
declare -r SOURCE_OPTIONS_SH=1

# Shell module options - Define and parse options.

source base.sh
source match.sh

declare -r OPTION_REGEX='^(-[a-zA-Z0-9]|--[a-zA-Z0-9][_a-zA-Z0-9-]*)$'
declare -A OPTION_TAKES_ARG=()
declare -A OPTION_TO_CANONICAL=()


# An option --foo-bar is represented by a global variable __foo_bar.  Options
# without argument have value false or true (option present).
function DefineOption {
    local option="$1"
    local takes_argument="${2:-false}"
    local default_value="${3:-false}"
    local optional_alias_option="${4:-}"

    if ! Match "$option" "$OPTION_REGEX"
    then
        Fatal "Option doesn't match regex '$OPTION_REGEX': '$option'"
    fi

    if test -v OPTION_TO_CANONICAL["$option"]
    then
        Fatal "Option '$option' has already been defined"
    fi

    # Must match the corresponding line in ParseOption
    local variable_name="${option//-/_}"
    if test -v "$variable_name"
    then
        Fatal "Variable '$variable_name' derived from option '$option' is already defined"
    fi

    declare -g "$variable_name"="$default_value"
    OPTION_TO_CANONICAL["$option"]="$option"
    OPTION_TAKES_ARG["$option"]="$takes_argument"

    if ((${#optional_alias_option} > 0))
    then
        if ! Match "$optional_alias_option" "$OPTION_REGEX"
        then
            Fatal "Alias option doesn't match '$OPTION_REGEX': '$optional_alias_option'"
        fi

        if test -v OPTION_TO_CANONICAL["$optional_alias_option"]
        then
            Fatal "Option '$optional_alias_option' has already been defined"
        fi

        OPTION_TO_CANONICAL["$optional_alias_option"]="$option"
    fi
}

function ParseOptions {
    # $1 must be the name of an associative array that names all options (that
    # does NOT take an additional argument, see _arg_options_ref).
    #
    # The name MUST NOT start with an underscore.
    local -n ParseOptions_options_ref="$1"

    # $2 must be the name of an associative array that names all options that
    # always takes exactly one additional argument.
    #
    # The name MUST NOT start with an underscore.
    local -n ParseOptions_arg_options_ref="$2"

    # Name of an array of git options that always takes exactly one
    # argument.
    #
    # The name MUST NOT start with an underscore.
    local -n ParseOptions_git_arg_options_ref="$3"

    shift 3

    local -A ParseOptions_valid_options
    SetHashtableFromArray ParseOptions_valid_options ParseOptions_options_ref true
    local -A ParseOptions_valid_arg_options
    SetHashtableFromArray ParseOptions_valid_arg_options ParseOptions_arg_options_ref true
    local -A ParseOptions_valid_git_arg_options
    SetHashtableFromArray ParseOptions_valid_git_arg_options ParseOptions_git_arg_options_ref true

    local -A ParseOptions_options=()
    local -a ParseOptions_git_options=()
    while (($# > 0))
    do
        local ParseOptions_arg="$1"
        
        if test "$ParseOptions_arg" == --
        then
            shift
            break
        elif test "${ParseOptions_arg:0:1}" == -
        then
            shift

            local ParseOptions_is_option="${ParseOptions_valid_options[$ParseOptions_arg]}"
            if ((${#ParseOptions_is_option} > 0))
            then
                ParseOptions_options["$ParseOptions_arg"]=true
            else
                local ParseOptions_is_arg_option="${ParseOptions_valid_arg_options[$ParseOptions_arg]}"
                if ((${#ParseOptions_is_arg_option} > 0))
                then
                    if (($# == 0))
                    then
                        Fatal "Missing argument to '$ParseOptions_arg'"
                    fi
                    local ParseOptions_value="$1"
                    shift
                    ParseOptions_options["$ParseOptions_arg"]="$ParseOptions_value"
                else
                    local ParseOptions_is_git_arg_option="${ParseOptions_valid_git_arg_options[$ParseOptions_arg]}"
                    if ((${#ParseOptions_is_git_arg_option} > 0))
                    then
                        if (($# == 0))
                        then
                            Fatal "Missing argument to '$ParseOptions_arg'"
                        fi
                        local ParseOptions_value="$1"
                        shift
                        ParseOptions_git_options+=("$ParseOptions_arg" "$ParseOptions_value")
                    else
                        ParseOptions_git_options+=("$ParseOptions_arg")
                    fi
                fi
            fi
        else
            break
        fi
    done

    # options
    CopyHashtableTo ParseOptions_options OUTH

    # Unrecognized options and git options (with arguments if some of the git
    # options require so, see ParseOptions_with_args above), in same order as
    # "$@".
    OUTA=("${ParseOptions_git_options[@]}")

    # Array of arguments - i.e. those arguments following the options.
    OUTA2=("$@")
}

function ClearOptions {
    local canonical_option
    for canonical_option in "${!OPTION_TAKES_ARG[@]}"
    do
        # WARNING: Must match line in DefineOption.
        local variable_name="${canonical_option//-/_}"
        unset "$variable_name"
    done

    OPTION_TAKES_ARG=()
    OPTION_TO_CANONICAL=()
}    

function ParseOption {
    local option="$1"
    local arg="$2"

    if ! Match "$option" "$OPTION_REGEX"
    then
        return 1
    fi

    if ! test -v OPTION_TO_CANONICAL["$option"]
    then
        return 1
    fi

    local canonical_option="${OPTION_TO_CANONICAL[$option]}"

    # Must match the corresponding line in DefineOption
    local variable_name="${canonical_option//-/_}"

    local -n ParseOption_variable_ref="$variable_name"

    local arg2_consumed

    if test "${OPTION_TAKES_ARG[$canonical_option]}" == true
    then
        ParseOption_variable_ref="$arg"
        arg2_consumed=true
    else
        ParseOption_variable_ref=true
        arg2_consumed=false
    fi

    OUT="$arg2_consumed"
    return 0
}
