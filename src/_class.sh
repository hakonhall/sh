function @_class {
    local address="$1"
    local -n class=CLASS_"$address"_class
    _1="$class"
}

function @_fields_name {
    local address="$1"
    _1=CLASS_"$address"_fields
}

function @_verify_address {
    local address="$1"
    if ! test -v CLASS_"$address"_class
    then
        Fatal "'$address' is not a valid object address"
    fi
}

function @_resolve_field {
    local address="$1"
    local field_name="$2"

    _1=CLASS_"$address"_field_"$field_name"
}

function @_resolve_address {
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

            local -n fields=CLASS_"$address"_fields
            if test -v fields[-a] -o -v fields[-A]
            then
                Fatal "Trying to dereference a non-string"
            fi

            @_resolve_field "$address" "$addrfield"
            local -n new_address="$_1"
            address="$new_address"

            @_verify_address "$address"
        done

        field="$suffix"
        AssertValidVariableName "$field"
        if test "${field:0:1}" == _
        then
            # Still allow it if the class is identical.
            if test -v this
            then
                @_class "$this"
                local this_class="$_1"

                @_class "$address"
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
