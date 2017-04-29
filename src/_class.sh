
function @_qualify_class {
    local address="$1"
    _1=CLASS_"$address"_class
}

function @_qualify_fields {
    local address="$1"
    _1=CLASS_"$address"_fields
}

function @_qualify_field {
    local address="$1"
    local field_name="$2"

    _1=CLASS_"$address"_field_"$field_name"
}

function @_qualify_field_options {
    local address="$1"
    local field_name="$2"
    _1=CLASS_"$address"_options_"$field_name"
}

function @_verify_address {
    local address="$1"

    @_qualify_class "$address"
    local qualified_class="$_1"

    if ! test -v "$qualified_class"
    then
        Fatal "'$address' is not a valid object address"
    fi
}

# The address is assumed to be verified.
# We need to verify the field_name is a valid field name, and verify the field
# name has been defined.
function @_resolve_field {
    local address="$1"
    local field_name="$2"

    # See @local
    AssertValidVariableName "$field_name"
    @_qualify_field "$address" "$field_name"
    local qualified_field_name="$_1"
    if ! declare -p "$qualified_field_name" &> /dev/null
    then
        @class "$address"
        local class="$_1"

        Fatal "$class@$address does not have a field '$field_name'"
    fi
}

function @_resolve_address_of_ref {
    local _resolve_address_of_ref_ptr _resolve_address_of_ref_suffix
    if Match "$1" '@([^.]+)(.*)' _resolve_address_of_ref_ptr \
             _resolve_address_of_ref_suffix
    then
        local -n _resolve_address_of_ref_address="$_resolve_address_of_ref_ptr"
        @_resolve_address_of_ref2 "$_resolve_address_of_ref_address$_resolve_address_of_ref_suffix"
    else
        @_resolve_address_of_ref2 "$1"
    fi
}

function @_resolve_address_of_ref2 {
    local ref="$1"

    if (( ${#ref} == 0 ))
    then
        Fatal "Empty reference"
    fi

    local address
    local field
    if Match "$ref" '^([^.]+)$' field
    then
        AssertValidVariableName "$field"

        if ! test -v this
        then
            Fatal "'this' is not defined"
        fi

        @_verify_address "$this"
        address="$this"
    else
        address="${ref%%.*}"
        if (( ${#address} == 0 ))
        then
            if ! test -v this
            then
                Fatal "'this' is not defined"
            fi

            @_verify_address "$this"
            address="$this"
        else
            @_verify_address "$address"
        fi

        # ADDRFIELD1 '.' ADDRFIELD2 '.' ... ADDRFIELDN '.' FIELD
        local suffix="${ref#*.}"

        local addrfield
        while Match "$suffix" '^([^.]+)\.(.*)$' addrfield suffix
        do
            AssertValidVariableName "$addrfield"

            @_resolve_field "$address" "$addrfield"
            local new_address_varname="$_1"

            # By internal consistency, since the field resolved, the field
            # options is implicitly verified so we can use @_qualify*.
            @_qualify_field_options "$address" "$addrfield"
            local -n field_options="$_1"
            if test -v field_options[-a] -o -v field_options[-A]
            then
                Fatal "Trying to dereference a non-string"
            fi

            local -n new_address="$new_address_varname"
            @_verify_address "$new_address"

            address="$new_address"
        done

        field="$suffix"
        AssertValidVariableName "$field"
        if test "${field:0:1}" == _
        then
            # Still allow it if the class is identical.
            if test -v this
            then
                @class "$this"
                local this_class="$_1"

                @class "$address"
                local address_class="$_1"

                if test "$this_class" == "$address_class"
                then
                    : # OK
                else
                    Fatal "Tried to access private field: '$field'"
                fi
            else
                Fatal "Tried to access private field: '$field'"
            fi
        fi
    fi

    _1="$address"
    _2="$field"
}
