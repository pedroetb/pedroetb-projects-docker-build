#!/bin/sh

echo -e "\n${INFO_COLOR}Tagging ${DATA_COLOR}${SOURCE_IMAGE}${INFO_COLOR} image ..${NULL_COLOR}\n"

if [ -z "${SSH_BUILD_REMOTE}" ]
then
	cmdPrefix="eval"
else
	cmdPrefix="ssh ${SSH_PARAMS} ${SSH_BUILD_REMOTE}"
	randomValue="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)"
	dockerConfigPath="${REMOTE_BUILD_PATH}/.${randomValue}"
	setDockerConfig="DOCKER_CONFIG=${dockerConfigPath}"
fi

loginSourceCmd="${setDockerConfig} docker login -u \"${SOURCE_REGISTRY_USER}\" -p \"${SOURCE_REGISTRY_PASS}\" ${SOURCE_REGISTRY_URL}"

loginTargetCmd="${setDockerConfig} docker login -u \"${TARGET_REGISTRY_USER}\" -p \"${TARGET_REGISTRY_PASS}\" ${TARGET_REGISTRY_URL}"

logoutSourceCmd="${setDockerConfig} docker logout ${SOURCE_REGISTRY_URL}"

logoutTargetCmd="${setDockerConfig} docker logout ${TARGET_REGISTRY_URL}"

rmDockerConfigCmd="rm -rf ${dockerConfigPath}"

doLogoutCmd() {

	if [ ! -z ${loggedInSource} ]
	then
		$(echo ${cmdPrefix}) ${logoutSourceCmd}
	fi

	if [ ! -z ${loggedInTarget} ]
	then
		$(echo ${cmdPrefix}) ${logoutTargetCmd}
	fi

	if [ ! -z "${SSH_BUILD_REMOTE}" ]
	then
		$(echo ${cmdPrefix}) ${rmDockerConfigCmd}
	fi
}

pullCmd="${setDockerConfig} docker pull ${SOURCE_IMAGE}"

tagCmd="docker tag ${SOURCE_IMAGE} ${TARGET_IMAGE}"
tagLatestCmd="docker tag ${SOURCE_IMAGE} ${targetImageName}:${LATEST_TAG_VALUE}"

pushOriginalTagCmd="${setDockerConfig} docker push ${TARGET_IMAGE}"
pushLatestTagCmd="${setDockerConfig} docker push ${targetImageName}:${LATEST_TAG_VALUE}"
pushCmd="${pushOriginalTagCmd}"

if [ ! -z "${SOURCE_REGISTRY_USER}" ] && [ ! -z "${SOURCE_REGISTRY_PASS}" ]
then
	if $(echo ${cmdPrefix}) ${loginSourceCmd}
	then
		loggedInSource="1"
	fi
fi

if $(echo ${cmdPrefix}) ${pullCmd}
then
	echo -e "\n${PASS_COLOR}Source image ${DATA_COLOR}${SOURCE_IMAGE}${PASS_COLOR} successfully pulled${NULL_COLOR}\n"
else
	echo -e "\n${FAIL_COLOR}Source image ${DATA_COLOR}${SOURCE_IMAGE}${FAIL_COLOR} pull failed!${NULL_COLOR}\n"
	doLogoutCmd
	exit 1
fi

if $(echo ${cmdPrefix}) ${tagCmd}
then
	echo -e "${PASS_COLOR}Image ${DATA_COLOR}${targetImageName}${PASS_COLOR} successfully tagged as ${DATA_COLOR}${targetImageTag}${NULL_COLOR}\n"
else
	echo -e "\n${FAIL_COLOR}Image ${DATA_COLOR}${targetImageName}${FAIL_COLOR} tagging failed!${NULL_COLOR}\n"
	doLogoutCmd
	exit 1
fi

if [ ${OMIT_LATEST_TAG} -eq 0 ]
then
	pushCmd="${pushCmd} && ${pushLatestTagCmd}"

	if $(echo ${cmdPrefix}) ${tagLatestCmd}
	then
		echo -e "${PASS_COLOR}Image ${DATA_COLOR}${targetImageName}${PASS_COLOR} successfully tagged as ${DATA_COLOR}${LATEST_TAG_VALUE}${NULL_COLOR}\n"
	else
		echo -e "\n${FAIL_COLOR}Image ${DATA_COLOR}${targetImageName}${FAIL_COLOR} tagging failed!${NULL_COLOR}\n"
		doLogoutCmd
		exit 1
	fi
fi

if [ ${OMIT_IMAGE_PUSH} -eq 0 ]
then
	if [ ! -z "${TARGET_REGISTRY_USER}" ] && [ ! -z "${TARGET_REGISTRY_PASS}" ]
	then
		if [ "${TARGET_REGISTRY_USER}" != "${SOURCE_REGISTRY_USER}" ] || [ "${TARGET_REGISTRY_URL}" != "${SOURCE_REGISTRY_URL}" ]
		then
			if $(echo ${cmdPrefix}) ${loginTargetCmd}
			then
				loggedInTarget="1"
			fi
		fi
	fi

	if $(echo ${cmdPrefix}) ${pushCmd}
	then
		echo -e "\n${PASS_COLOR}Image successfully pushed!${NULL_COLOR}"
	else
		echo -e "\n${FAIL_COLOR}Image push failed!${NULL_COLOR}"
		doLogoutCmd
		exit 1
	fi
fi

doLogoutCmd
