#!/bin/sh

echo -e "\n${INFO_COLOR}Setting source and target Docker images ..${NULL_COLOR}"

if [ ! -z "${1}" ]
then
	SOURCE_IMAGE="${1}"
fi

if [ ! -z "${2}" ]
then
	TARGET_IMAGE="${2}"
fi

if [ -z "${SOURCE_IMAGE}" ]
then
	echo -e "${FAIL_COLOR}You must define 'SOURCE_IMAGE' in environment (or provide it as first script argument), with the <name:tag> of Docker image to use as source${NULL_COLOR}"
	exit 1
fi

if [ -z "${TARGET_IMAGE}" ]
then
	echo -e "${FAIL_COLOR}You must define 'TARGET_IMAGE' in environment (or provide it as second script argument), with the <name:tag> of Docker image to use as target${NULL_COLOR}"
	exit 1
fi

sourceImageName="$(echo ${SOURCE_IMAGE} | cut -d ':' -f 1)"
if echo "${SOURCE_IMAGE}" | grep -q ':'
then
	sourceImageTag="$(echo ${SOURCE_IMAGE} | cut -d ':' -f 2-)"
fi

targetImageName="$(echo ${TARGET_IMAGE} | cut -d ':' -f 1)"
if echo "${TARGET_IMAGE}" | grep -q ':'
then
	targetImageTag="$(echo ${TARGET_IMAGE} | cut -d ':' -f 2-)"
fi

if [ -z "${sourceImageTag}" ]
then
	echo -e "${INFO_COLOR}Source Docker image tag not found, using default '${DATA_COLOR}${LATEST_TAG_VALUE}${INFO_COLOR}' ..${NULL_COLOR}"
	sourceImageTag="${LATEST_TAG_VALUE}"
	SOURCE_IMAGE="${sourceImageName}:${sourceImageTag}"
fi

if [ -z "${targetImageTag}" ]
then
	echo -e "${INFO_COLOR}Target Docker image tag not found, using default '${DATA_COLOR}${LATEST_TAG_VALUE}${INFO_COLOR}' ..${NULL_COLOR}"
	targetImageTag="${LATEST_TAG_VALUE}"
	TARGET_IMAGE="${targetImageName}:${targetImageTag}"
fi

echo -e "  ${INFO_COLOR}source: ${DATA_COLOR}${SOURCE_IMAGE}${INFO_COLOR}"
echo -e "  ${INFO_COLOR}target: ${DATA_COLOR}${TARGET_IMAGE}${INFO_COLOR}"

if [ "${sourceImageName}" == "${targetImageName}" ] && [ "${sourceImageTag}" == "${targetImageTag}" ]
then
	echo -e "\n${FAIL_COLOR}Source and target Docker images are the same, omitting task ..${NULL_COLOR}"
	exit 1
fi

if [ "${targetImageTag}" == "${LATEST_TAG_VALUE}" ]
then
	OMIT_LATEST_TAG="1"
fi

if [ ! -z "${SSH_BUILD_REMOTE}" ]
then
	echo -e "\n${INFO_COLOR}Preparing tag resources ..${NULL_COLOR}"

	checkDockerInstalled="command -v docker > /dev/null"
	if ! runRemoteCmd "${checkDockerInstalled}"
	then
		echo -e "\n${FAIL_COLOR}Docker is not available at tag target host environment!${NULL_COLOR}"
		eval "${closeSshCmd}"
		eval "${removeTagEnvFile}"
		exit 1
	fi

	randomValue="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)"
	remoteTagHome="${REMOTE_BUILD_PATH}/${randomValue}"
	setDockerConfig="DOCKER_CONFIG=${remoteTagHome}"

	moveAndSetDockerConfigCmd="${remoteTagHome:+cd ${remoteTagHome};}${setDockerConfig}${setDockerConfig:+;}"

	echo -e "\n${INFO_COLOR}Sending tag resources to remote ${DATA_COLOR}${remoteHost}${INFO_COLOR} ..${NULL_COLOR}"
	echo -e "  ${INFO_COLOR}tagging path [ ${DATA_COLOR}${remoteTagHome}${INFO_COLOR} ]${NULL_COLOR}\n"

	if ! runRemoteCmd "mkdir -p ${remoteTagHome}"
	then
		echo -e "${FAIL_COLOR}Tagging path ${DATA_COLOR}${remoteTagHome}${FAIL_COLOR} creation failed!${NULL_COLOR}"
		eval "${removeTagEnvFile}"
		exit 1
	fi

	if scp ${SSH_PARAMS} -q ${envTagFilePath} "${SSH_BUILD_REMOTE}:${remoteTagHome}/"
	then
		echo -e "${PASS_COLOR}Tagging resources successfully sent!${NULL_COLOR}"
	else
		echo -e "${FAIL_COLOR}Tagging resources sending failed!${NULL_COLOR}"
		eval "${removeTagEnvFile}"
		exit 1
	fi
fi
