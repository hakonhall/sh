if test -v SOURCE_ASSERT_SH
then
    return
fi
declare -r SOURCE_ASSERT_SH=true

source base.sh
source match.sh

function AssertDeath {
    local expected_exit_status="$1"
    local expected_out_regex="$2"
    shift 2

    local -a command=("$@")

    local out
    if out="$( "${command[@]}" 2>&1 )"
    then
        local exit_status=$?
    else
        local exit_status=$?
    fi

    if (( exit_status != expected_exit_status )) || \
           ! Match "$out" "$expected_out_regex"
    then
        Fatal $'\n' \
              "Expected exit status: $expected_exit_status"$'\n' \
              "Actual   exit status: $exit_status"$'\n' \
              "Expected output matching: '$expected_out_regex'"$'\n' \
              "Actual   output:          '$out'"
    fi
}
