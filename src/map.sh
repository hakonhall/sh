if test -v SOURCE_MAP_SH
then
    return
fi
declare -r SOURCE_MAP_SH=true

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
