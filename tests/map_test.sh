source map.sh

function Main {
    local -A map=([a]=A [b]=B)
    local -A tomap=([c]=C)

    Map_AddTo map tomap
    declare -p tomap

    Map_CopyTo map tomap
    declare -p tomap

    local -A foo=([a]=A [b]=B [c]=C [d]=D)
    local -A bar=([b]=B [c]=C [e]=E)
    Map_KeyDiff foo bar
    declare -p AREPLY
}

Main "$@"
