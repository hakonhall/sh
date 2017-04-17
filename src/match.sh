if test -v SOURCE_MATCH_SH
then
    return
fi
declare -r SOURCE_MATCH_SH=1

source base.sh

# Usage: Match TEXT REGEX [VARNAME...]
# Match the text against the regex, capturing subgroups in varname.
#
# Return 0 on success, and in case each matched subgroup of the regex will be
# saved to non-empty varnames.  Example:
#
#   local Is
#   if Match "$text" '^( |_)*:(foo+):(a|b)' '' foo
#   then
#     ... "$foo" contains the part of "$text" that matched foo+
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
            local Match_varname="${Match_varnames[$Match_i]}"
            if test "$Match_varname" != ""
            then
                local -n Match_varref="$Match_varname"
                Match_varref="${BASH_REMATCH[$Match_group]}"
            fi
        done

        return 0
    elif test $? == 2
    then
        Fatal "Bad regex '$Match_regex'"
    else
        return 1
    fi
}
