#!/bin/bash

OS_NAME="$(uname | awk '{print tolower($0)}')"

SHELL_DIR=$(dirname $0)

CMD=${1:-$CIRCLE_JOB}

RUN_PATH=${2:-$SHELL_DIR}

USERNAME=${CIRCLE_PROJECT_USERNAME}
REPONAME=${CIRCLE_PROJECT_REPONAME}

BRANCH=${CIRCLE_BRANCH:-master}

TG_USERNAME="${TG_USERNAME}"
TG_PROJECT="${TG_PROJECT}"
TG_VERSION="${TG_VERSION}"
TG_PHASE="${TG_PHASE}"

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

_prepare() {
    if [ "${TG_USERNAME}" == "" ] || [ "${TG_PROJECT}" == "" ] || [ "${TG_VERSION}" == "" ]; then
        _success
    fi

    if [ "${PERSONAL_TOKEN}" == "" ]; then
        _error "Not found PERSONAL_TOKEN"
    fi
    if [ ! -d "${RUN_PATH}/${TG_PROJECT}" ]; then
        _error "Not found ${TG_PROJECT}"
    fi

    _result "${TG_USERNAME}/${TG_PROJECT}:${TG_VERSION}"
}

_build_phase() {
    TMP=/tmp/releases

    curl -sL "https://api.github.com/repos/${USERNAME}/${REPONAME}/releases"
    curl -sL "https://api.github.com/repos/${USERNAME}/${REPONAME}/releases" > ${TMP}

    grep "${TG_VERSION}" ${TMP}

    PRERELEASE="$(cat ${TMP} | jq -r --arg VERSION "${TG_VERSION}" '.[] | select(.tag_name==$VERSION) | "\(.draft) \(.prerelease)"')"

    # draft prerelease
    _result "PRERELEASE: \"${PRERELEASE}\""

    if [ "${PRERELEASE}" != "false false" ]; then
        _success
    fi

    CIRCLE_API="https://circleci.com/api/v1.1/project/github/${USERNAME}/${REPONAME}"
    CIRCLE_URL="${CIRCLE_API}?circle-token=${PERSONAL_TOKEN}"

    LIST=$(ls ${RUN_PATH}/${TG_PROJECT} | grep 'values-' | grep '.yaml' | cut -d'-' -f2 | cut -d'.' -f1)

    for PHASE in ${LIST}; do
        PAYLOAD="{\"build_parameters\":{"
        PAYLOAD="${PAYLOAD}\"TG_USERNAME\":\"${TG_USERNAME}\","
        PAYLOAD="${PAYLOAD}\"TG_PROJECT\":\"${TG_PROJECT}\","
        PAYLOAD="${PAYLOAD}\"TG_VERSION\":\"${TG_VERSION}\","
        PAYLOAD="${PAYLOAD}\"TG_PHASE\":\"${PHASE}\""
        PAYLOAD="${PAYLOAD}}}"

        curl -X POST \
            -H "Content-Type: application/json" \
            -d "${PAYLOAD}" "${CIRCLE_URL}"

        _result "${PHASE}"
    done
}

_build_deploy_pr() {
    if [ ! -f ${RUN_PATH}/${TG_PROJECT}/values-${TG_PHASE}.yaml ]; then
        _error "Not found values-${TG_PHASE}.yaml"
    fi

    git config --global user.name "${GIT_USERNAME}"
    git config --global user.email "${GIT_USEREMAIL}"

    NEW_BRANCH="${TG_PROJECT}-${TG_PHASE}-${TG_VERSION}"
    MESSAGE="Deploy ${TG_PROJECT} ${TG_PHASE} ${TG_VERSION}"

    HAS="false"
    LIST="/tmp/branch-list"
    git branch -a > ${LIST}

    while read VAR; do
        ARR=(${VAR})
        if [ -z ${ARR[1]} ]; then
            if [ "${ARR[0]}" == "${NEW_BRANCH}" ]; then
                HAS="true"
            fi
        else
            if [ "${ARR[1]}" == "${NEW_BRANCH}" ]; then
                HAS="true"
            fi
        fi
    done < ${LIST}

    if [ "${HAS}" == "true" ]; then
        _success "${NEW_BRANCH}"
    fi

    _command "git branch ${NEW_BRANCH} ${BRANCH}"
    git branch ${NEW_BRANCH} ${BRANCH}

    _command "git checkout ${NEW_BRANCH}"
    git checkout ${NEW_BRANCH}

    _command "replace ${TG_VERSION}"
    _replace "s/tag: .*/tag: ${TG_VERSION}/g" ${RUN_PATH}/${TG_PROJECT}/values-${TG_PHASE}.yaml

    _command "git add --all"
    git add --all

    _command "git commit -m \"${MESSAGE}\""
    git commit -m "${MESSAGE}"

    _command "git push github.com/${USERNAME}/${REPONAME} ${NEW_BRANCH}"
    git push -q https://${GITHUB_TOKEN}@github.com/${USERNAME}/${REPONAME}.git ${NEW_BRANCH}

    # _command "hub push origin ${NEW_BRANCH}"
    # hub push origin ${NEW_BRANCH}

    _command "hub pull-request -f -b ${USERNAME}:master -h ${USERNAME}:${NEW_BRANCH} --no-edit"
    hub pull-request -f -b ${USERNAME}:master -h ${USERNAME}:${NEW_BRANCH} --no-edit
}

_prepare

if [ "${TG_PHASE}" == "" ]; then
    _build_phase
else
    _build_deploy_pr
fi

_success
