if test -v SOURCE_FUNCTION_DOC_SH
then
    return
fi
declare -r SOURCE_FUNCTION_DOC_SH=true

source base.sh
source match.sh

# Set REPLY to the comment content immediately preceding func.
function GetFunctionDoc {
    local func="$1"

    local disable_extdebug
    if shopt -q extdebug
    then
        disable_extdebug=false
    else
        disable_extdebug=true
        shopt -qs extdebug
    fi

    local out
    if ! out=$(declare -F "$func")
    then
        Fatal "Failed to list source and line number for function '$func'"
    fi

    local -i func_lineno
    local func_source
    # Format of `declare -F FUNCTION_NAME' is:
    #   FUNCTION_NAME SPACE LINENO SPACE SOURCE_PATH
    if ! Match "$out" '^[^ ]+ ([0-9]+) (.*)$' func_lineno func_source
    then
        Fatal "Unexpected output of declare -f '$func': $out"
    fi

    local -a lines=()
    # The -O 1 ensures that lines[$func_lineno] is the line containing the
    # function definition.  It also makes it easier to report line numbers in
    # the file, since the lines index is the line number.
    if ! mapfile -O 1 lines < "$func_source"
    then
        Fatal "Failed to read '$func_source'"
    fi

    # Sanity-checking that lines[$func_lineno] defines the function is not
    # trivial, since a function like Func may be defined as follows:
    #
    #   function Fu\
    #   nc {
    #     ...
    #   }
    #
    # However this may be a bit esoteric and we may want to not support it.
    
    if (( $func_lineno > ${#lines[@]} ))
    then
        Fatal "Failed to find the line ($func_lineno) in '$func_source' " \
              "defining the function '$func'"
    fi
       
    local -a function_doc_lines=()

    local -i lineno
    for ((lineno = func_lineno - 1; lineno > 1; --lineno))
    do
        local line="${lines[$lineno]}"
        if test "${line:0:2}" == "# "
        then
            function_doc_lines["$lineno"]="${line:2}"
        elif test "${line:0:1}" == "#"
        then
            function_doc_lines["$lineno"]="${line:1}"
        else
            break
        fi
    done

    local function_doc=""
    local line
    for line in "${function_doc_lines[@]}"
    do
        function_doc+="$line"
    done

    REPLY="$function_doc"
}
