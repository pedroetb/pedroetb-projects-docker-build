#!/bin/sh

COMPOSE_FILE_NAME="${COMPOSE_FILE_NAME:-docker-compose.yml}"
COMPOSE_ENV_FILE_NAME="${COMPOSE_ENV_FILE_NAME:-.env}"
COMPOSE_PROJECT_DIRECTORY="${COMPOSE_PROJECT_DIRECTORY:-deploy}"

ENV_PREFIX="${ENV_PREFIX:-DBLD_}"
ENV_SPACE_REPLACEMENT="${ENV_SPACE_REPLACEMENT:-<dbld-space>}"

DOCKER_BUILD_CONTEXT="${DOCKER_BUILD_CONTEXT:-.}"
REMOTE_BUILD_PATH="${REMOTE_BUILD_PATH:-~/docker-build}"

IMAGE_NAME_VARIABLE_NAME="${IMAGE_NAME_VARIABLE_NAME:-IMAGE_NAME}"
IMAGE_TAG_VARIABLE_NAME="${IMAGE_TAG_VARIABLE_NAME:-IMAGE_TAG}"
LATEST_TAG_VALUE="${LATEST_TAG_VALUE:-latest}"
OMIT_LATEST_TAG="${OMIT_LATEST_TAG:-0}"
FORCE_DOCKER_BUILD="${FORCE_DOCKER_BUILD:-0}"
OMIT_IMAGE_PUSH="${OMIT_IMAGE_PUSH:-0}"

INFO_COLOR='\033[1;36m'
DATA_COLOR='\033[1;33m'
FAIL_COLOR='\033[0;31m'
PASS_COLOR='\033[0;32m'
NULL_COLOR='\033[0m'

SSH_PORT="${SSH_PORT:-22}"
SSH_CONTROL_PERSIST="${SSH_CONTROL_PERSIST:-10}"
SSH_PARAMS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=error \
	-o "ControlPath=\"/ssh_connection_socket_%h_%p_%r\"" -o ControlMaster=auto \
	-o ControlPersist=${SSH_CONTROL_PERSIST} -o Port=${SSH_PORT}"