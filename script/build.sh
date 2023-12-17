#!/bin/sh

. _definitions.sh
. _show-banner.sh

if [ -z "${PACKAGED_IMAGE_NAME}" ]
then
	echo -e "${FAIL_COLOR}You must define 'PACKAGED_IMAGE_NAME' in environment, with the name of Docker image to build${NULL_COLOR}"
	exit 1
fi

if [ -z "${PACKAGED_IMAGE_TAG}" ]
then
	echo -e "${INFO_COLOR}Using ${DATA_COLOR}${LATEST_TAG_VALUE}${INFO_COLOR} as 'PACKAGED_IMAGE_TAG' because it is undefined, you can set it with the tag of Docker image to build${NULL_COLOR}"
	PACKAGED_IMAGE_TAG="${LATEST_TAG_VALUE}"
fi

. _prepare-target.sh

. _prepare-env.sh

. _check-config.sh

if [ ! -z "${SSH_BUILD_REMOTE}" ]
then
	. _prepare-build.sh
fi

. _do-build.sh
