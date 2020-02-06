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
