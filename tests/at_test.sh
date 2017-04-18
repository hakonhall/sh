source at.sh

function complex_init {
    echo "this='$this'"
    echo "complex_init arguments: '$*'"

    @local -i x "$1"
    @ .x
    declare -p _1
    @local -i y "$2"
    @ .y
    declare -p _1
}

function complex_add {
    local -i x="$1"
    local -i y="$2"

    @ .x
    local -n this_x="$_1"
    this_x+=x

    @ .y
    local -n this_y="$_1"
    this_y+=y
}

function TestNew {
    echo new "$@"
    new "$@"
    local address="$_1"
    declare -p address
}

function Main {
    TestNew complex 1 2
    local c="$_1"

    @ "$c".x
    declare -p _1
    declare -p AT_NS_0_field_x

    @ "$c".add 3 4

    @dump "$c"
}

Main "$@"
