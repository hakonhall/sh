if test -v SOURCE_OPTIONS_SH
then
    return
fi
declare -r SOURCE_OPTIONS_SH=1

# options3.sh - Define and parse options.

source base.sh
source class.sh
source match.sh

declare OPTIONS_ARGUMENT_PARSER=""
declare OPTIONS_DEFINE_PROGRAM_OPTION_PARSER=""

# See Option_init
function DefineProgramOption {
    @call @OPTIONS_ARGUMENT_PARSER.define_option "$@"
}

# For an option --foo, sets a global variable __foo.
function ParseProgramArguments {
    @call @OPTIONS_ARGUMENT_PARSER.parse "$@"
    local args=("${_1a[@]}")

    @call @OPTIONS_ARGUMENT_PARSER.get_options
    local -a option_names=("${_1a[@]}")

    local option_name
    for option_name in "${option_names[@]}"
    do
        @call @option_name.get_option
        local option="$_1"

        @call @option_name.get_value
        local value="$_1"

        local global_option_name="${option//-/_}"
        declare -g "$global_option_name"=""
        local -n global_option="$global_option_name"
        global_option="$value"
    done

    _1a=("${args[@]}")
}

function ClearProgramParser {
    @call @OPTIONS_ARGUMENT_PARSER.clear
}

# Usage: @new Option OPTION [VALUE]
# Define option
#
# OPTION is e.g. '--foo'.  Without VALUE, the option is 'false' by default, and
# set to 'true' if the option was specified on the command line (see
# ArgumentParser_parse).
#
# With VALUE, the option must take an argument as in '--foo=VAL' or '--foo
# VAL'.  The initial value of the option is VALUE.
function Option_init {
    if (( $# == 0 ))
    then
        Fatal "Option argument missing"
    fi
    @call _verify_option_string "$1"
    @local option "$1"

    # An alias -f of an option --foo means that both ${aliases[--foo]} and
    # ${aliases[-f]} will have the address of the option object.
    @local -A aliases "$1" "$this"

    if (( $# > 1))
    then
        @local _has_argument true
        @local _value "$2"
        shift
    else
        @local _has_argument false
        @local _value false
    fi

    if (( $# != 1 ))
    then
        Fatal "Too many arguments"
    fi
}

# Set _1 to the name of the option name, e.g. '--foo'
function Option_get_option {
    @field_name option
    local -n option="$_1"
    _1="$option"
}

# Set _1 to whether the option takes an argument or not ('false' or 'true')
function Option_has_argument {
    @field_name _has_argument
    local -n _has_argument="$_1"
    _1="$_has_argument"
}

# Set _1 to the value of the option
function Option_get_value {
    @field_name _value
    local -n _value="$_1"
    _1="$_value"
}

# Set the value of the option to "$1"
function Option_set_value {
    local value="$1"

    @field_name _has_argument
    local -n _has_argument="$_1"

    if "$_has_argument"
    then
        :
    else
        AssertTrueOrFalse "$value"
    fi

    @field_name _value
    local -n _value="$_1"
    _value="$value"
}

# Make $1 an alias of the option
function Option_add_alias {
    local alias="$1"

    @field_name aliases
    local -n aliases="$_1"
    aliases["$alias"]="$this"
}

# Set _1 to the name of an associative array mapping an (alias) option name to
# the address of the option.
function Option_get_aliases {
    @field_name aliases
}

function ArgumentParser_init {
    @local -A options
    @local -a args
}

function ArgumentParser_clear {
    @field_name options
    local -n options="$_1"
    options=()

    @field_name args
    local -n args="$_1"
    args=()
}

function ArgumentParser_define_option {
    @new Option "$@"
    local option="$_1"
    @call "$parser".add_option "$option"
    _1="$option"
}

# You probably want to use ArgumentParser_define_option
function ArgumentParser_add_option {
    local option="$1"

    @call @option.get_aliases
    local -n option_aliases="$_1"

    @field_name options
    local -n options="$_1"

    local alias
    for alias in "${!option_aliases[@]}"
    do
        if test -v options["$alias"]
        then
            Fatal "Option '$alias' is already defined"
        fi

        local option_value="${option_aliases[$alias]}"
        if test "$option_value" != "$option"
        then
            Fatal "Inconsistent value of alias: '$option_value' != '$option'"
        fi
        options["$alias"]="$option"
    done
}

function ArgumentParser_get_option {
    local option_name="$1"

    @field_name options
    local -n options="$_1"

    if ! test -v options["$option_name"]
    then
        Fatal "Unknown option '$option_name'"
    fi

    _1="${options[$option_name]}"
}

function ArgumentParser_get_options {
    @field_name options
    local -n options="$_1"

    _1a=("${options[@]}")
}

function ArgumentParser_get_option_value {
    local option_name="$1"

    @call get_option "$option_name"
    @call "$_1".get_value
}

function ArgumentParser_parse {

    @field_name options
    local -n options="$_1"

    @field_name args
    local -n args="$_1"
    args=()

    while (( $# > 0 ))
    do
        local option_name option_assignment option_value

        if test "$1" == --
        then
            shift
            break
        elif Match "$1" '^(--[a-zA-Z0-9][a-zA-Z0-9_-]*)(=(.*))?$' \
                   option_name option_assignment option_value
        then
            if ! test -v options["$option_name"]
            then
                Fail "Unknown option '$option_name'"
            fi

            local option="${options[$option_name]}"
            @call "$option".has_argument
            local has_argument="$_1"
            
            if "$has_argument"
            then
                if (( ${#option_assignment} > 0 ))
                then
                    # option_value already has the option value
                    shift
                elif (( $# == 0 ))
                then
                    Fail "Missing argument to option '$option_name'"
                else
                    option_value="$2"
                    shift 2
                fi
            elif (( ${#option_assignment} > 0 ))
            then
                Fail "Option '$option_name' does not take an argument"
            else
                option_value=true
                shift
            fi

            @call "$option".set_value "$option_value"
        elif test "${1:0:1}" == - && (( ${#1} > 1 ))
        then
            local -i i=1
            for (( i=1; i<${#1}; ++i ))
            do
                local option_name=-"${1:$i:1}"

                if ! test -v options["$option_name"]
                then
                    Fail "Unknown option '$option_name'"
                fi

                local option="${options[$option_name]}"
                @call "$option".has_argument
                local has_argument="$_1"
            
                if "$has_argument"
                then
                    if (( i + 1 == ${#1} ))
                    then
                        if (( $# == 0 ))
                        then
                            Fail "Missing argument to option '$option_name'"
                        else
                            option_value="$2"
                            shift
                        fi
                    else
                        local -i j=$(( i+1 ))
                        option_value="${1:$j}"
                    fi

                    @call "$option".set_value "$option_value"

                    # Make sure we break out of the for-loop
                    break
                else
                    option_value=true
                    @call "$option".set_value "$option_value"
                fi
            done

            shift
        elif true
        then
            args+=("$1")
            shift
        else
            break
        fi
    done

    args+=("$@")
    _1a=("${args[@]}")
}

function Option__verify_option_string {
    local option="$1"

    if ! Match "$option" '^((-[a-zA-Z])|(--[a-zA-Z0-9][a-zA-Z0-9_-]*))$'
    then
        Fatal "'$option' is not a valid option"
    fi
}

function Options_initialize {
    @new ArgumentParser
    OPTIONS_ARGUMENT_PARSER="$_1"

    # @new ArgumentParser
    # OPTIONS_DEFINE_PROGRAM_OPTION_PARSER="$_1"

    # @new Option --alias ""
    # local alias_option="$_1"
    # @call @alias_option.add_alias -a
    # @call @OPTIONS_DEFINE_PROGRAM_OPTION_PARSER.add_option "$alias_option"
}

Options_initialize
