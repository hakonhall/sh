if test -v SOURCED
then
    # What, using $()!? This is to avoid declaring a global variable.
    if test -v SOURCED["$(printf "%q" "${BASH_SOURCE[1]}")"]
    then
        return 0
    else
        SOURCED["$(printf "%q" "${BASH_SOURCE[1]}")"]=true
        return 1
    fi
else
    declare -A SOURCED=(["$(printf "%q" "${BASH_SOURCE[1]}")"]=true)
fi
