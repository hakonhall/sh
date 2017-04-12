source define.sh

function TestDefine {
    DefineGlobalVariable "$@"
    local name="$REPLY"
    echo "name='$name'"
    # The following may fail (with -N)
    declare -p "$name" 2>&1 || true
    REPLY="$name"
}

function Main {
    TestDefine emptystring
    TestDefine string value
    TestDefine -a emptyarray
    TestDefine -a array a1 a2 a3
    TestDefine -A emptymap
    TestDefine -A map k1 a1 k2 a2 '[] "' a3

    TestDefine -N ns
    TestDefine -cN
    local ns="$REPLY"
    TestDefine -o ns -N subns

    TestDefine -o "$ns" doors 3
    local -n doors="$REPLY"
    doors=5

    ResolveGlobalVariableName "$ns" doors
    local -n doors2="$REPLY"
    declare -p doors2
    echo "doors = $doors2"

    TestDefine -o "$ns" -A dashboard vents 4 speedometer 1
    TestDefine -o "$ns" -a seat_placements r1l r1r r2l r2m r2r

    TestDefine -c -- -val1
}

Main "$@"
