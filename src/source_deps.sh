if test -v SOURCE_SOURCE_DEPS_SH
then
    return
fi
declare -r SOURCE_SOURCE_DEPS_SH=true

source base.sh
source define.sh
source map.sh
source match.sh

function BuildSourceDependencyGraph {
    local dir="$1"

    pushd "$dir" > /dev/null

    if shopt -q nullglob
    then
        local unset_nullglob=false
    else
        local unset_nullglob=true
        shopt -sq nullglob
    fi

    local S='[[:space:]]'
    local C='[[:alnum:]_.-]' # Allowed character in filename

    # In general, a source statement can be very complex:
    #
    #   source "../${prefixes[$i]}_\
    #   $suffix}"
    #
    # we need to limit the complexity - only look at those source statements
    # that are of the simplest possible form: No slashes (source file must be
    # found in PATH), no quoting, no escaping (backslash), basic charset (C).
    local regex="^$S*(source|\.)$S+($C+)(\$|$S)"

    local -A source_list=()

    local file
    for file in *.sh
    do
        source_list["$file"]+=""

        while read -r
        do
            local line="$REPLY"

            local filename
            if ! Match "$line" "$regex" '' filename ''
            then
                continue
            fi

            if test -n "${source_list[$file]}"
            then
                source_list["$file"]+=" $filename"
            else
                source_list["$file"]+="$filename"
            fi
        done < "$file"
    done

    if "$unset_nullglob"
    then
        shopt -uq nullglob
    fi

    popd > /dev/null

    Map_CopyTo source_list MREPLY
}
