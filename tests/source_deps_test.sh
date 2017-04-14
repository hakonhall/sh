source source_deps.sh

function Main {
    BuildSourceDependencyGraph ../../../src
    declare -p MREPLY
    BuildSourceDependencyGraph ../../../tests
    declare -p MREPLY
}

Main "$@"
