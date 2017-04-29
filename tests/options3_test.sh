source assert.sh
source options3.sh

function TestNewOption {
    @new Option "$@"
    @dump "$_1"
}

function TestOption {
    TestNewOption --foo1
    TestNewOption --foo2 false
    TestNewOption --foo3 true

    AssertDeath 1 'argument missing' TestNewOption
    AssertDeath 1 'not a valid option' TestNewOption not-an-option
    AssertDeath 1 'Too many arguments' TestNewOption --foo one two
}

function PrintValueOfOption {
    local option="$1"

    @call "$option".get_option
    local option_name="$_1"

    @call "$option".get_value
    local value="$_1"

    printf "Option $option: %q %q\n" "$option_name" "$value"
}

function TestParser {
    @new ArgumentParser
    local parser="$_1"

    @new Option --foo true
    local foo_option="$_1"
    @call "$parser".add_option "$foo_option"

    @new Option --bar
    local bar_option="$_1"
    @call "$parser".add_option "$bar_option"

    @new Option --zoo
    local zoo_option="$_1"
    @call "$parser".add_option "$zoo_option"

    @dump "$parser"

    @call "$parser".parse --bar --foo val arg1 arg2
    local -a args=("${_1a[@]}")

    @dump "$parser"

    PrintValueOfOption "$foo_option"
    PrintValueOfOption "$bar_option"
    PrintValueOfOption "$zoo_option"
    echo "args: '${args[*]}'"
}

function TestParser2 {
    @new ArgumentParser
    local parser="$_1"

    @call "$parser".define_option --foo true
    @call "$parser".define_option --bar
    @call "$parser".define_option --zoo

    @dump "$parser"
    @call "$parser".parse --bar --foo val arg1 arg2
    local -a args=("${_1a[@]}")

    @dump "$parser"

    PrintValueOfOption2 "$parser" --foo
    PrintValueOfOption2 "$parser" --bar
    PrintValueOfOption2 "$parser" --zoo
    echo "args: '${args[*]}'"
}

function PrintValueOfOption2 {
    local parser="$1"
    local option_name="$2"

    @call "$parser".get_option "$option_name"
    local option="$_1"

    @call "$option".get_value
    local value="$_1"

    printf "Option %s: %q %q\n" "$option" "$option_name" "$value"
}

function TestParserShortOption {
    @new ArgumentParser
    local parser="$_1"

    @call "$parser".define_option -f true
    @call "$parser".define_option -b
    @call "$parser".define_option -z

    @dump "$parser"
    @call "$parser".parse "$@"
    local -a args=("${_1a[@]}")

    @dump "$parser"

    PrintValueOfOption2 "$parser" -f
    PrintValueOfOption2 "$parser" -b
    PrintValueOfOption2 "$parser" -z
    echo "args: '${args[*]}'"
}

function TestParser3 {
    @new ArgumentParser
    local parser="$_1"

    @call "$parser".define_option --foo true
    @call "$parser".define_option --bar
    @call "$parser".define_option --zoo

    @call "$parser".parse arg1 --bar arg2 --foo val arg3
    local -a args=("${_1a[@]}")

    @call "$parser".get_option_value --foo
    echo "--foo $_1"

    @call "$parser".get_option_value --bar
    echo "--bar $_1"

    @call "$parser".get_option_value --zoo
    echo "--zoo $_1"

    echo "args: '${args[*]}'"
}

function TestGlobalOptionsWith {
    # DefineProgramOption -a -f -- --foo init_fooval
    # DefineProgramOption -o --foo -a -f -v init_fooval
    # DefineProgramOption --option --foo --alias -f --default-value init_fooval

    unset __foo _f __bar _b
    ClearProgramParser

    DefineProgramOption --foo init_fooval
    DefineProgramOption -f init_fval
    DefineProgramOption --bar
    DefineProgramOption -b
    
    echo ParseProgramArguments "$@"
    ParseProgramArguments "$@"

    printf "%s\n" "--foo='$__foo'"
    printf "%s\n" "-f='$_f'"
    printf "%s\n" "--bar='$__bar'"
    printf "%s\n" "-b='$_b'"
    printf "%s\n" "\${#_1a[@]}=${#_1a[*]}"
    printf "%s\n" "_1a='${_1a[*]}'"
}

function TestGlobalOptions {
    TestGlobalOptionsWith
    TestGlobalOptionsWith --foo fooval arg1 -b arg2 -f fval arg3
}

function TestAliases {
    @new ArgumentParser
    local parser="$_1"

    @new Option --foo initval
    local option="$_1"
    @call @option.add_alias -f

    @call @parser.add_option "$option"
    @call @parser.parse -f val
    @call @option.get_value
    echo "-f value: $_1"
}

function Main {
    TestOption
    TestParser
    TestParser2

    # All of these are equivalent
    TestParserShortOption -b -f val arg1 arg2
    TestParserShortOption -bf val arg1 arg2
    TestParserShortOption -bfval arg1 arg2
    TestParserShortOption arg1 -bfval arg2

    TestParser3
    TestGlobalOptions
    TestAliases
}

Main "$@"
