if test -v SOURCE_MATCH_SH
then
    return
fi
declare -r SOURCE_MATCH_SH=1

source base.sh

function Match {
    local Match_text="$1"
    local Match_regex="$2"
    shift 2
    local -a Match_varnames=("$@")

    if [[ $Match_text =~ $Match_regex ]]
    then
        local -i Match_num_vars="${#Match_varnames[@]}"
        local -i Match_num_groups="$(( ${#BASH_REMATCH[@]} - 1 ))"
        if ((Match_num_vars > Match_num_groups))
        then
            Fatal "There are more variables passed ($Match_num_vars) than " \
                  "groups defined ($Match_num_groups)"
        fi

        local -i Match_i
        for ((Match_i = 0; Match_i < Match_num_vars; ++Match_i))
        do
            local -i Match_group=$((Match_i + 1))
            local -n Match_varref="${Match_varnames[$Match_i]}"
            Match_varref="${BASH_REMATCH[$Match_group]}"
        done

        return 0
    elif test $? == 2
    then
        Fatal "Bad regex '$Match_regex'"
    else
        return 1
    fi
}
