if test -v SOURCE_MAP_SH
then
    return
fi
declare -r SOURCE_MAP_SH=true

# In particular MREPLY* may be passed as input or output from these functions.

function Map_AddTo {
    local -n Map_from="$1"
    local -n Map_to="$2"

    local Map_key
    for Map_key in "${!Map_from[@]}"
    do
        Map_to["$Map_key"]="${Map_from[$Map_key]}"
    done
}

function Map_CopyTo {
    local Map_from_name="$1"
    local Map_to_name="$2"
    
    local -n Map_to="$Map_to_name"
    Map_to=()
    Map_AddTo "$Map_from_name" "$Map_to_name"
}

# Returns in AREPLY, the array of keys in Map_left that are not in Map_right.
function Map_KeyDiff {
    local -n Map_left="$1"
    local -n Map_right="$2"

    local -a Map_diff=()
    local Map_key
    for Map_key in "${!Map_left[@]}"
    do
        if ! test -v Map_right["$Map_key"]
        then
            Map_diff+=("$Map_key")
        fi
    done

    AREPLY=("${Map_diff[@]}")
}
