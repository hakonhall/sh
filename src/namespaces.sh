if test -v SOURCE_NAMESPACES_SH
then
    return
fi
declare -r SOURCE_NAMESPACES_SH=true

source base.sh
source declare_unique.sh

declare -i NAMESPACES_next_id=0

function AssertValidVariableName {
    local id="$"

    if test "$id" == _
    then
        # $_ is an automatic variable
        :
    elif [[ "$id" =~ ^[0-9]+$ ]]
    then
        # An integer cannot name a variable
        :
    elif [[ "$id" =~ ^[a-zA-Z0-9_]+$ ]]
    then
        return 0
    fi

    Fatal "$func: \`$id': not a valid identifier"
}

function DeclareNewUniqueNamespace {
    local namespace_id="$((NAMESPACES_next_id++))"
    REPLY="$namespace_id"
}

function DeclareInNamespace {
    local namespace_id="$1"
    local name="$2"
    shift 2

    local full_name="NAMESPACES_${namespace_id}_${name}"
    if test -v "$full_name"
    then
        Fatal "Name '$name' has already been defined within namespace"
    fi

    InternalDeclare "$full_name" "$@"

    REPLY="$full_name"
}
