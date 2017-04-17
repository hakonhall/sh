source source_deps.sh

function Main {
    BuildSourceDependencyGraph ../testdir/src
    declare -p MREPLY
    BuildSourceDependencyGraph ../testdir/tests
    declare -p MREPLY
}

Main "$@"
