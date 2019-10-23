#!/bin/bash

OS_NAME="$(uname | awk '{print tolower($0)}')"

SHELL_DIR=$(dirname $0)

_deploy_pre() {
  if [ -z "${GITHUB_TOKEN}" ]; then
    _error "GITHUB_TOKEN is not set."
  fi

  if [ -z "${TARGET_ID}" ]; then
    _error "TARGET_ID is not set."
  fi

  if [ -z "${VERSION}" ]; then
    _error "VERSION is not set."
  fi

  if [ -z "${CONFIGURE}" ]; then
    CONFIGURE=./gitops.json
  fi
}

_deploy() {
  _deploy_pre

}

# _deploy

echo $GITHUB_EVENT_PATH
cat $GITHUB_EVENT_PATH
