source options.sh

declare -rA TAKE_ARGS2=(
    [-f]=true [--foo]=true [--bar]=false [-b]=false [-c]=false)

function HandleOptionCallback {
    local -n hoc_options="$1"
    local hoc_option="$2"

    if ! test -v TAKE_ARGS2["$hoc_option"]
    then
        _2="Unknown option '$hoc_option'"
        return 1
    fi

    if test "${TAKE_ARGS2[$hoc_option]}" == true
    then
        if (( $# < 3 ))
        then
            return 1
        fi
        local value="$3"
        hoc_options["$hoc_option"]="$value"
        _1=1
        return 0
    else
        hoc_options["$hoc_option"]=true
        _1=0
        return 0
    fi
}

function TestParseOption {
    local -A options=([e]=E)
    echo ParseOption HandleOptionCallback options "$@"
    if ParseOption HandleOptionCallback options "$@"
    then
        declare -p _1
        declare -p options
    else
        declare -p _2
    fi
}

function TestParseOptions {
    TestParseOption b
    TestParseOption -b
    TestParseOption --bar
    TestParseOption -f
    TestParseOption -fval
    TestParseOption -f val
    TestParseOption --foo
    TestParseOption --foo val
    TestParseOption -bc
    TestParseOption -bcfval
    TestParseOption -bcf val
    TestParseOption -@
    TestParseOption --f@@
}

function Test1ParseOptions2 {
    __zoo=init
    __kid=false
    _c=false

    echo ParseOptions2 "$@"
    ParseOptions2 "$@"
    declare -p _1a __zoo __kid _c
}

function TestParseOptions2 {
    declare -gA Options_option_ids=(
        [--zoo]=zid [-z]=zid [--kar]=kid [-k]=kid [-c]=cid
    )
    declare -g __zoo=""
    declare -gA Options_option_info_zid=([-a]=true [varname]=__zoo)
    declare -g __kid=""
    declare -gA Options_option_info_kid=([varname]=__kid)
    declare -g _c=""
    declare -gA Options_option_info_cid=([varname]=_c)

    Test1ParseOptions2
    Test1ParseOptions2 arg1 arg2
    Test1ParseOptions2 -k
    Test1ParseOptions2 arg1 --zoo val arg2 -c
}

function Main {
    TestParseOptions
    TestParseOptions2
}

Main "$@"
