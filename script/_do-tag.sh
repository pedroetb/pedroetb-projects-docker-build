#!/bin/sh

echo -e "\n${INFO_COLOR}Tagging ${DATA_COLOR}${SOURCE_IMAGE}${INFO_COLOR} image ..${NULL_COLOR}\n"

if [ ${DOCKER_VERBOSE} -eq 0 ]
then
	dockerPushPullOpts="-q"
fi

loginSourceCmd="${moveToTagDirCmd} grep \"^${dbldSourceRegistryPassVarName}=\" \"${envTagFilePath}\" | cut -d= -f2- | \
	${setDockerConfig} docker login -u \"${SOURCE_REGISTRY_USER}\" --password-stdin ${SOURCE_REGISTRY_URL}"

loginTargetCmd="${moveToTagDirCmd} grep \"^${dbldTargetRegistryPassVarName}=\" \"${envTagFilePath}\" | cut -d= -f2- | \
	${setDockerConfig} docker login -u \"${TARGET_REGISTRY_USER}\" --password-stdin ${TARGET_REGISTRY_URL}"

logoutSourceCmd="${setDockerConfig} docker logout ${SOURCE_REGISTRY_URL}"

logoutTargetCmd="${setDockerConfig} docker logout ${TARGET_REGISTRY_URL}"

rmDockerConfigCmd="rm -rf ${remoteTagHome}"

doLogoutCmd() {

	if [ ! -z ${loggedInSource} ]
	then
		runCmdOnTarget "${logoutSourceCmd}"
	fi

	if [ ! -z ${loggedInTarget} ]
	then
		runCmdOnTarget "${logoutTargetCmd}"
	fi

	if [ ! -z "${SSH_BUILD_REMOTE}" ]
	then
		runCmdOnTarget "${rmDockerConfigCmd}"
		eval "${closeSshCmd}"
	fi

	eval "${removeTagEnvFile}"
}

pullCmd="${setDockerConfig} docker pull ${dockerPushPullOpts} ${SOURCE_IMAGE}"

tagCmd="docker tag ${SOURCE_IMAGE} ${TARGET_IMAGE}"
tagLatestCmd="docker tag ${SOURCE_IMAGE} ${targetImageName}:${LATEST_TAG_VALUE}"

pushBaseCmd="${setDockerConfig} docker push ${dockerPushPullOpts}"
pushOriginalTagCmd="${pushBaseCmd} ${TARGET_IMAGE}"
pushLatestTagCmd="${pushBaseCmd} ${targetImageName}:${LATEST_TAG_VALUE}"
pushCmd="${pushOriginalTagCmd}"

if [ ! -z "${SOURCE_REGISTRY_USER}" ] && [ ! -z "${SOURCE_REGISTRY_PASS}" ]
then
	echo -e "${INFO_COLOR}Login to source registry ${DATA_COLOR}${SOURCE_REGISTRY_URL:-<default>}${INFO_COLOR} ..${NULL_COLOR}\n"
	if runCmdOnTarget "${loginSourceCmd}"
	then
		loggedInSource="1"
		echo -e "\n${PASS_COLOR}Login to source registry was successful!${NULL_COLOR}\n"
	else
		echo -e "\n${FAIL_COLOR}Login to source registry failed!${NULL_COLOR}\n"
	fi
fi

if runCmdOnTarget "${pullCmd}"
then
	# Avoid race condition between pull and tag
	checkSourceImageIsAlreadyAvailable="docker image inspect ${SOURCE_IMAGE} > /dev/null 2>&1"
	while ! runCmdOnTarget "${checkSourceImageIsAlreadyAvailable}"
	do
		sleep 1
	done
	echo -e "\n${PASS_COLOR}Source image ${DATA_COLOR}${SOURCE_IMAGE}${PASS_COLOR} successfully pulled${NULL_COLOR}\n"
else
	echo -e "\n${FAIL_COLOR}Source image ${DATA_COLOR}${SOURCE_IMAGE}${FAIL_COLOR} pull failed!${NULL_COLOR}\n"
	doLogoutCmd
	exit 1
fi

if runCmdOnTarget "${tagCmd}"
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

	if runCmdOnTarget "${tagLatestCmd}"
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
			echo -e "${INFO_COLOR}Login to target registry ${DATA_COLOR}${TARGET_REGISTRY_URL:-<default>}${INFO_COLOR} ..${NULL_COLOR}\n"
			if runCmdOnTarget "${loginTargetCmd}"
			then
				loggedInTarget="1"
				echo -e "\n${PASS_COLOR}Login to target registry was successful!${NULL_COLOR}\n"
			else
				echo -e "\n${FAIL_COLOR}Login to target registry failed!${NULL_COLOR}\n"
			fi
		fi
	fi

	if runCmdOnTarget "${pushCmd}"
	then
		echo -e "\n${PASS_COLOR}Image successfully pushed!${NULL_COLOR}\n"
	else
		echo -e "\n${FAIL_COLOR}Image push failed!${NULL_COLOR}\n"
		doLogoutCmd
		exit 1
	fi
fi

doLogoutCmd
