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

# Usage: Compress INT
# Set _1 to a string short that can be part of a variable name.
function CompressInt {
    local -i i="$1"

    # Use a 62-based system with the following mappings:
    #    0 ->  0
    #   ...
    #    9 ->  9
    #   10 ->  a
    #   ...
    #   35 ->  z
    #   36 ->  A
    #   ...
    #   61 ->  Z
    #   62 -> 10
    #   ...
    local map=0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ

    local string=""

    if (( i < 0 ))
    then
        Fatal "Only positive numbers can be compressed"
    elif (( i == 0 ))
    then
        string="0"
    else
        local -i left="$i"

        while (( left > 0 ))
        do
            local -i remainder=$(( left % 62 ))
            local c="${map:$remainder:1}"
            string="$c$string"
            left=$(( left / 62 ))
        done
    fi

    _1="$string"
}
