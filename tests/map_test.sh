source map.sh

function Main {
    local -A map=([a]=A [b]=B)
    local -A tomap=([c]=C)

    Map_AddTo map tomap
    declare -p tomap

    Map_CopyTo map tomap
    declare -p tomap
}

Main "$@"
