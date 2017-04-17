source options.sh

declare -rA TAKE_ARGS=(
    [-f]=true [--foo]=true [--bar]=false [-b]=false [-c]=false)

function HandleOptionCallback {
    local -n hoc_options="$1"
    local hoc_option="$2"

    if ! test -v TAKE_ARGS["$hoc_option"]
    then
        _2="Unknown option '$hoc_option'"
        return 1
    fi

    if test "${TAKE_ARGS[$hoc_option]}" == true
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

function Test1ParseOption {
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

function TestParseOption {
    Test1ParseOption b
    Test1ParseOption -b
    Test1ParseOption --bar
    Test1ParseOption -f
    Test1ParseOption -fval
    Test1ParseOption -f val
    Test1ParseOption --foo
    Test1ParseOption --foo val
    Test1ParseOption -bc
    Test1ParseOption -bcfval
    Test1ParseOption -bcf val
    Test1ParseOption -@
    Test1ParseOption --f@@
}

function Test1ParseOptions {
    __zoo=init
    __kid=false
    _c=false

    echo ParseOptions "$@"
    ParseOptions "$@"
    declare -p _1a __zoo __kid _c
}

function TestParseOptions {
    declare -gA Options_option_ids=(
        [--zoo]=zid [-z]=zid [--kar]=kid [-k]=kid [-c]=cid
    )
    declare -g __zoo=""
    declare -gA Options_option_info_zid=([-a]=true [varname]=__zoo)
    declare -g __kid=""
    declare -gA Options_option_info_kid=([varname]=__kid)
    declare -g _c=""
    declare -gA Options_option_info_cid=([varname]=_c)

    Test1ParseOptions --
    Test1ParseOptions -- arg1 arg2
    Test1ParseOptions -- -k
    Test1ParseOptions -- arg1 --zoo val arg2 -c
}

function Test1DefineOption {
    unset Options_option_ids

    echo DefineOption "$@"
    DefineOption "$@"
    declare -p Options_option_ids
}

function TestDefineOption {
    Test1DefineOption -- --single -s -S
    declare -p Options_option_info___single

    Test1DefineOption -- --tool -t
    declare -p Options_option_info___tool
}

function Main {
    TestParseOption
    TestParseOptions
    TestDefineOption
}

Main "$@"
