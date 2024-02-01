#!/bin/sh

echo -e "\n${INFO_COLOR}Tagging ${DATA_COLOR}${SOURCE_IMAGE}${INFO_COLOR} image ..${NULL_COLOR}\n"

if [ ${DOCKER_VERBOSE} -eq 0 ]
then
	dockerPushPullOpts="-q"
fi

loginSourceCmd="${moveToTagDirCmd} grep \"^${dbldSourceRegistryPassVarName}=\" \"${envTagFilePath}\" | cut -d '=' -f 2- | \
	${setDockerConfig} docker login -u \"${SOURCE_REGISTRY_USER}\" --password-stdin ${SOURCE_REGISTRY_URL}"

loginTargetCmd="${moveToTagDirCmd} grep \"^${dbldTargetRegistryPassVarName}=\" \"${envTagFilePath}\" | cut -d '=' -f 2- | \
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
fi

echo -e "${INFO_COLOR}Checking multi-arch availability for source image ..${NULL_COLOR}"

enableMultiArchTagging=0

getSourceImageMediaTypeCmd="${setDockerConfig} docker buildx imagetools inspect \
	--format '{{json .Manifest.MediaType}}' \
	${SOURCE_IMAGE} | tr -d '\"'"

sourceImageMediaType=$(runCmdOnTarget "${getSourceImageMediaTypeCmd}")
getSourceImageMediaTypeCmdExitCode=${?}

if [ ${getSourceImageMediaTypeCmdExitCode} -eq 0 ]
then
	if [ ${sourceImageMediaType} = "application/vnd.docker.distribution.manifest.list.v2+json" ] || [ ${sourceImageMediaType} = "application/vnd.oci.image.index.v1+json" ]
	then
		echo -e "  ${INFO_COLOR}detected multi-arch source image manifest!${NULL_COLOR}"
		echo -e "  ${INFO_COLOR}mediaType: ${DATA_COLOR}${sourceImageMediaType}${INFO_COLOR}${NULL_COLOR}"
		if [ ${FORCE_SINGLEARCH_TAG} -eq 0 ]
		then
			enableMultiArchTagging=1
			echo -e "  ${INFO_COLOR}enabling multi-arch tagging!${NULL_COLOR}"
		else
			echo -e "  ${INFO_COLOR}single-arch tagging is forced, disabling multi-arch tagging!${NULL_COLOR}"
		fi
	else
		echo -e "  ${INFO_COLOR}detected single-arch source image manifest!${NULL_COLOR}"
		echo -e "  ${INFO_COLOR}mediaType: ${DATA_COLOR}${sourceImageMediaType}${INFO_COLOR}${NULL_COLOR}"
		echo -e "  ${INFO_COLOR}disabling multi-arch tagging!${NULL_COLOR}"
	fi

	echo ""
else
	echo -e "\n${FAIL_COLOR}Getting source image manifest from registry failed, disabling multi-arch tagging!${NULL_COLOR}\n"
fi

if [ ${enableMultiArchTagging} -eq 1 ]
then
	multiArchTaggerName="dbld-multiarch-tagger-${randomValue}"

	createMultiArchTaggerCmd="${setDockerConfig} docker buildx create \
		--driver docker-container \
		--name ${multiArchTaggerName} \
		--use > /dev/null"

	runCmdOnTarget "${createMultiArchTaggerCmd}"

	multiArchTags="${targetImageTag}"
	multiArchTagOpts="--tag ${TARGET_IMAGE}"

	if [ ${OMIT_LATEST_TAG} -eq 0 ]
	then
		multiArchTags="${multiArchTags}, ${LATEST_TAG_VALUE}"
		multiArchTagOpts="${multiArchTagOpts} --tag ${targetImageName}:${LATEST_TAG_VALUE}"
	fi

	if [ ${OMIT_IMAGE_PUSH} -eq 1 ]
	then
		echo -e "${INFO_COLOR}Image push omitted for multi-arch tagging, showing resultant image manifest only ..${NULL_COLOR}\n"
		multiArchTagOpts="${multiArchTagOpts} --dry-run"
	fi

	multiArchTagCmd="docker buildx imagetools create ${multiArchTagOpts} ${SOURCE_IMAGE}"

	if [ ${DOCKER_VERBOSE} -eq 0 ]
	then
		multiArchTagCmd="${multiArchTagCmd} 2> /dev/null"
	fi

	runCmdOnTarget "${multiArchTagCmd}"
	multiArchTagCmdExitCode=${?}

	removeMultiArchTaggerCmd="${setDockerConfig} docker buildx rm ${multiArchTaggerName} 2> /dev/null"
	runCmdOnTarget "${removeMultiArchTaggerCmd}"

	if [ ${multiArchTagCmdExitCode} -eq 0 ]
	then
		if [ ${DOCKER_VERBOSE} -eq 1 ] || [ ${OMIT_IMAGE_PUSH} -eq 1 ]
		then
			echo ""
		fi

		echo -e "${PASS_COLOR}Image ${DATA_COLOR}${targetImageName}${PASS_COLOR} successfully tagged as ${DATA_COLOR}${multiArchTags}${PASS_COLOR} for multiple architectures!${NULL_COLOR}\n"
	else
		echo -e "\n${FAIL_COLOR}Image ${DATA_COLOR}${targetImageName}${FAIL_COLOR} tagging for multiple architectures failed!${NULL_COLOR}\n"
		doLogoutCmd
		exit 1
	fi
else
	pullCmd="${setDockerConfig} docker pull ${dockerPushPullOpts} ${SOURCE_IMAGE}"

	if [ ${DOCKER_VERBOSE} -eq 0 ]
	then
		pullCmd="${pullCmd} > /dev/null"
	fi

	tagCmd="docker tag ${SOURCE_IMAGE} ${TARGET_IMAGE}"
	tagLatestCmd="docker tag ${SOURCE_IMAGE} ${targetImageName}:${LATEST_TAG_VALUE}"

	pushBaseCmd="${setDockerConfig} docker push ${dockerPushPullOpts}"
	pushOriginalTagCmd="${pushBaseCmd} ${TARGET_IMAGE}"
	pushLatestTagCmd="${pushBaseCmd} ${targetImageName}:${LATEST_TAG_VALUE}"
	pushCmd="${pushOriginalTagCmd}"

	if runCmdOnTarget "${pullCmd}"
	then
		# Avoid race condition between pull and tag
		checkSourceImageIsAlreadyAvailable="docker image inspect ${SOURCE_IMAGE} > /dev/null 2>&1"
		while ! runCmdOnTarget "${checkSourceImageIsAlreadyAvailable}"
		do
			sleep 1
		done

		if [ ${DOCKER_VERBOSE} -eq 1 ]
		then
			echo ""
		fi

		echo -e "${PASS_COLOR}Source image ${DATA_COLOR}${SOURCE_IMAGE}${PASS_COLOR} successfully pulled${NULL_COLOR}\n"
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
			# Avoid race condition between tag and push
			checkLatestImageIsAlreadyAvailable="docker image inspect ${targetImageName}:${LATEST_TAG_VALUE} > /dev/null 2>&1"
			while ! runCmdOnTarget "${checkLatestImageIsAlreadyAvailable}"
			do
				sleep 1
			done

			echo -e "${PASS_COLOR}Image ${DATA_COLOR}${targetImageName}${PASS_COLOR} successfully tagged as ${DATA_COLOR}${LATEST_TAG_VALUE}${NULL_COLOR}\n"
		else
			echo -e "\n${FAIL_COLOR}Image ${DATA_COLOR}${targetImageName}${FAIL_COLOR} tagging failed!${NULL_COLOR}\n"
			doLogoutCmd
			exit 1
		fi
	fi

	if [ ${OMIT_IMAGE_PUSH} -eq 0 ]
	then
		# Avoid race condition between tag and push
		checkTargetImageIsAlreadyAvailable="docker image inspect ${TARGET_IMAGE} > /dev/null 2>&1"
		while ! runCmdOnTarget "${checkTargetImageIsAlreadyAvailable}"
		do
			sleep 1
		done

		if runCmdOnTarget "${pushCmd}"
		then
			echo -e "\n${PASS_COLOR}Image successfully pushed!${NULL_COLOR}\n"
		else
			echo -e "\n${FAIL_COLOR}Image push failed!${NULL_COLOR}\n"
			doLogoutCmd
			exit 1
		fi
	fi
fi

doLogoutCmd
