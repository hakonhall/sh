source assert.sh
source class.sh

function TestClass_init {
    @local x 1
    @local -a a a1 a2
    @local -A A k1 v1 k2 v2
}

function List_init {
    @local data "$1"
    @local ptr "$2"
    @local _priv private_value
}

function List_print {
    @field_name data
    echo "data=$_1"

    @field_name _priv
    local -n _priv="$_1"
    echo "_priv=$_priv"

    @field_name ptr
    local -n ptr="$_1"
    if (( ${#ptr} != 0 ))
    then
        @call .ptr.print
    fi
}

function List_access {
    @field_name ptr
    local -n ptr="$_1"
    if (( ${#ptr} == 0 ))
    then
        Fatal "Empty ptr"
    fi

    @field_name "$ptr"._priv
    local -n other_priv="$_1"
    echo "other's private data: $other_priv"
}

function Main {
    @new TestClass
    local test_object="$_1"
    @dump "$test_object"

    @new List 'd1' ''
    local o1="$_1"
    @dump "$o1"

    @new List 'd2' "$o1"
    local o2="$_1"
    @dump "$o2"

    @new List 'd3' "$o2"
    local o3="$_1"
    @dump "$o3"

    echo @_resolve_address "$o3".ptr.ptr.data
    @_resolve_address_of_ref "$o3".ptr.ptr.data
    echo "address=$_1"
    echo "field=$_2"

    @field_name "$o3".ptr.ptr.data
    local data1_varname="$_1"
    local -n data1="$data1_varname"
    echo "$data1_varname=$data1"

    AssertDeath 1 "'this' is not defined" @field_name .ptr
    AssertDeath 1 "Tried to access private field" @field_name "$o3"._priv

    AssertDeath 1 "does not have a field 'bar'" @field_name "$o1".bar

    @call @o3.print

    @call @o3.access
    AssertDeath 1 "List does not have a method 'zoo'" @call "$o3".zoo
}

Main "$@"
