if test -v SOURCE_CLASS_SH
then
    return
fi
declare -r SOURCE_CLASS_SH=true

# Idea: A class Class:

#  - All "member" functions MUST start with Class__, and the first function
#    argument must be a "this" argument.

#  - All variables that are supposed to be referenced (set or gotten) across
#    member functions, must be set via the "this" argument.
#
#  - Calling a member function MUST be using a utility function (@?) that
#    ensures the correct ...
#
#
# function Class_append {
#   local this="$1"
#   shift
#   local element="$1"
#
#   ResolveGlobalVariableName "$this" list
#   local REPLY

# @ "$object" append el1 el2
#
# Say "Foo" is the name of the object class.  This is stored in "$object".
# This then ends up calling:
#
# local this="$object"
# Foo_append el1 el2
function @ {
    :
}
