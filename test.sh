source `dirname ${BASH_SOURCE[0]}`/messages.sh
source `dirname ${BASH_SOURCE[0]}`/shutils/commands.sh

function root_setup() {
    mkdir -p "$1"
    cd "$1"
}

function root_teardown() {
    cd /
    rm -rf "$1"
}

function is_test_function() {
    ([[ "$1" == "is_test_function" ]] || [[ "$1" == "run_test" ]] || [[ "$1" == "run_tests" ]] || [[ "$1" == "root_setup" ]] || [[ "$1" == "root_teardown" ]] || [[ "$1" == "expect" ]] || [[ "$1" == "fail" ]]) && return 1
    return 0
}

function run_test() {
    last_test_status=0

    workdir="$(mktemp -d -t tmp)"

    root_setup "$workdir"
    function_exists setup && setup
    echo -e "$MSG_RUN $1"
    eval $1
    [[ ! $? -eq 0 ]] && last_test_status=1
    function_exists teardown && teardown
    root_teardown "$workdir"
}

function run_tests() {
    local regex=".*[Tt]est.*"
    if [ "$1" != "" ]
    then
        regex="$1"
    fi
    for f in $(declare -f -F | cut -d ' ' -f 3)
    do
        if [[ $f =~ $regex ]] && is_test_function "$f"
        then
            local tests[${#tests[@]}]=$f
        fi
    done
    echo -e "$MSG_STATUS Running ${#tests[@]} test(s)"
    for t in ${tests[@]}
    do
        run_test $t
        if [ $last_test_status -eq 0 ]
        then
            echo -ne "$MSG_OK "
            passed_tests[${#passed_tests[@]}]=$t
        else
            echo -ne "$MSG_FAIL "
            failed_tests[${#failed_tests[@]}]=$t
        fi
        echo -e "$t"
    done
    echo -e "$MSG_STATUS ${#tests[@]} test(s) ran"
    [[ ${#passed_tests[@]} -gt 0 ]] && echo -e "$MSG_PASSED ${#passed_tests[@]} test(s)"
    for t in ${failed_tests[@]}
    do
        echo -e "$MSG_FAILED $t"
    done
}

function fail() {
    last_test_status=1
}

function expect() {
    if ! eval "$@"
    then
        echo -e "$MSG_FAILED Expectation failed for condition $@ (line ${BASH_LINENO[0]})"
        fail
    fi
}
