if test -v SOURCE_VARIABLE_SH
then
    return
fi
declare -r SOURCE_VARIABLE_SH=true

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
