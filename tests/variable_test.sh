source assert.sh
source variable.sh

function Main {
    AssertValidVariableName fooBar_
    AssertDeath 1 'not a valid identifier' AssertValidVariableName 234
    AssertDeath 1 'not a valid identifier' AssertValidVariableName _
    AssertDeath 1 'not a valid identifier' AssertValidVariableName @
}

Main "$@"
