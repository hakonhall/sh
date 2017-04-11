if test -v SOURCED -a -v SOURCED[program]
then
    return 0
fi
declare -A SOURCED
SOURCED[program]=true

if ((${#BASH_SOURCE[@]} > 1))
then
    # This file is sourced and used as a library.
    # Could also use BASH_LINENO, but NOT BASH_ARGC nor FUNCNAME.
    : 
else
    Main "$@"
fi
