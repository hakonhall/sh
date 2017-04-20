source assert.sh
source variable.sh

function TestCompressInt {
    local -i i="$1"
    CompressInt "$i"
    echo "CompressInt $i -> _1='$_1'"
}

function Main {
    AssertValidVariableName fooBar_
    AssertDeath 1 'not a valid identifier' AssertValidVariableName 234
    AssertDeath 1 'not a valid identifier' AssertValidVariableName _
    AssertDeath 1 'not a valid identifier' AssertValidVariableName @

    AssertDeath 1 'Only positive numbers can be compressed' CompressInt -1
    TestCompressInt 0
    TestCompressInt 1
    TestCompressInt 9
    TestCompressInt 10
    TestCompressInt 35
    TestCompressInt 36
    TestCompressInt 61
    TestCompressInt 62
    TestCompressInt 123
    TestCompressInt 124
    TestCompressInt $(( 62 * 62 - 1 ))
    TestCompressInt $(( 62 * 62 ))
}

Main "$@"
