#!/bin/sh

. _definitions.sh

if [ ! -z "${1}" ]
then
	SOURCE_IMAGE_NAME="${1}"
fi

if [ -z "${SOURCE_IMAGE_NAME}" ]
then
	echo -e "${FAIL_COLOR}You must define 'SOURCE_IMAGE_NAME' in environment (or provide it as first script argument), with the name of Docker image to use as source${NULL_COLOR}"
	exit 1
fi

if [ ${PRESERVE_ROOT_LEVEL} -eq 1 ]
then
	rootLevel="$(echo ${SOURCE_IMAGE_NAME} | cut -d '/' -f 1)"

	if [ -z ${ROOT_NAME} ]
	then
		ROOT_NAME="${rootLevel}"
	else
		omitCut="1"
	fi
fi

if [ -z ${omitCut} ]
then
	SOURCE_IMAGE_NAME="$(echo ${SOURCE_IMAGE_NAME} | cut -d '/' -f 2-)"
fi

flattenImageName="$(echo ${SOURCE_IMAGE_NAME} | sed 's/\//-/g')"

export TARGET_IMAGE_NAME="${ROOT_NAME}${ROOT_NAME:+/}${flattenImageName}"
echo ${TARGET_IMAGE_NAME}
