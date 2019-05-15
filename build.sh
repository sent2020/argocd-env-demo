#!/bin/bash

OS_NAME="$(uname | awk '{print tolower($0)}')"

SHELL_DIR=$(dirname $0)

CMD=${1:-$CIRCLE_JOB}

RUN_PATH=${2:-$SHELL_DIR}

USERNAME=${CIRCLE_PROJECT_USERNAME:-nalbam}
REPONAME=${CIRCLE_PROJECT_REPONAME:-argocd-env-demo}

BRANCH=${CIRCLE_BRANCH:-master}

NAME=
PHASE=
VERSION=

GIT_USERNAME="bot"
GIT_USEREMAIL="bot@nalbam.com"

################################################################################

# command -v tput > /dev/null && TPUT=true
TPUT=

_echo() {
    if [ "${TPUT}" != "" ] && [ "$2" != "" ]; then
        echo -e "$(tput setaf $2)$1$(tput sgr0)"
    else
        echo -e "$1"
    fi
}

_result() {
    echo
    _echo "# $@" 4
}

_command() {
    echo
    _echo "$ $@" 3
}

_success() {
    echo
    _echo "+ $@" 2
    exit 0
}

_error() {
    echo
    _echo "- $@" 1
    exit 1
}

_replace() {
    if [ "${OS_NAME}" == "darwin" ]; then
        sed -i "" -e "$1" $2
    else
        sed -i -e "$1" $2
    fi
}

################################################################################

_success
