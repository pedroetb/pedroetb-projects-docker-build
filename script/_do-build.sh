#!/bin/sh

echo ""

latestPackagedImage=${PACKAGED_IMAGE_NAME}:${LATEST_TAG_VALUE}
dockerDefaultBuildOpts="--pull --force-rm"

if [ ${DOCKER_VERBOSE} -eq 0 ]
then
	dockerDefaultBuildOpts="${dockerDefaultBuildOpts} -q"
	dockerPushPullOpts="-q"
fi

if [ ! -z "${SSH_BUILD_REMOTE}" ]
then
	buildContextRoot="${remoteBuildHome}"
	dockerConfigPath="${REMOTE_BUILD_PATH}/.${randomValue}"
	setDockerConfig="DOCKER_CONFIG=${dockerConfigPath}"
fi

moveToBuildDirCmd="${buildContextRoot:+cd ${buildContextRoot};}"

getDockerVersion="docker version --format '{{.Server.Version}}'"
dockerVersion=$(runCmdOnTarget "${getDockerVersion}")

minDockerMajorVersion="23"
dockerMajorVersion=$(echo "${dockerVersion}" | cut -d '.' -f 1)

if [ "${dockerMajorVersion}" -lt ${minDockerMajorVersion} ]
then
	echo -e "${INFO_COLOR}Docker is outdated (v${dockerVersion} < v${minDockerMajorVersion}), forcing 'docker build' ..${NULL_COLOR}\n"
	FORCE_DOCKER_BUILD="1"
fi

if [ ${FORCE_DOCKER_BUILD} -eq 1 ]
then
	echo -e "${INFO_COLOR}When forcing 'docker build', env-file is not used. Use build args inside 'DOCKER_BUILD_OPTS' to set values${NULL_COLOR}\n"
fi

loginCmd="${moveToBuildDirCmd} grep \"^${dbldRegistryPassVarName}=\" \"${envBuildFilePath}\" | cut -d= -f2- | \
	${setDockerConfig} docker login -u \"${REGISTRY_USER}\" --password-stdin ${REGISTRY_URL}"

if [ -z "${REGISTRY_USER}" ] || [ -z "${REGISTRY_PASS}" ]
then
	echo -e "${INFO_COLOR}Docker registry credentials not found, omitting login and image push ..${NULL_COLOR}\n"
	OMIT_IMAGE_PUSH="1"
else
	echo -e "${INFO_COLOR}Login to registry ${DATA_COLOR}${REGISTRY_URL:-<default>}${INFO_COLOR} ..${NULL_COLOR}\n"
	if runCmdOnTarget "${loginCmd}"
	then
		loggedIn="1"
		echo -e "\n${PASS_COLOR}Login to registry was successful!${NULL_COLOR}"
	else
		echo -e "\n${FAIL_COLOR}Login to registry failed!${NULL_COLOR}"
	fi
fi

logoutCmd="${setDockerConfig} docker logout ${REGISTRY_URL}"

rmDockerConfigCmd="rm -rf ${dockerConfigPath}"

doLogoutCmd() {

	if [ ! -z ${loggedIn} ]
	then
		runCmdOnTarget "${logoutCmd}"
	fi

	if [ ! -z "${SSH_BUILD_REMOTE}" ]
	then
		runCmdOnTarget "${rmDockerConfigCmd}"
		eval "${closeSshCmd}"
	fi

	eval "${removeBuildEnvFile}"
}

if [ ! -z "${IMAGES_FOR_CACHING}" ]
then
	echo -e "${INFO_COLOR}Pulling Docker images to feed cache ..${NULL_COLOR}"
	echo -e "  ${INFO_COLOR} images [ ${DATA_COLOR}${IMAGES_FOR_CACHING}${INFO_COLOR} ]${NULL_COLOR}\n"

	pullCacheCmd="\
		pullFailure=0; \
		for imageToPull in ${IMAGES_FOR_CACHING}; \
		do \
			if ! ${setDockerConfig} docker pull ${dockerPushPullOpts} \${imageToPull}; \
			then
				pullFailure=1; \
			fi;
		done; \
		[ \${pullFailure} -eq 0 ]"

	if runCmdOnTarget "${pullCacheCmd}"
	then
		echo -e "\n${PASS_COLOR}Cache images successfully pulled!${NULL_COLOR}\n"
	else
		echo -e "\n${FAIL_COLOR}Any of cache images failed to be pulled!${NULL_COLOR}\n"
	fi
fi

buildCmd="${moveToBuildDirCmd} \
	if [ ${FORCE_DOCKER_BUILD} -eq 0 ]; \
	then \
		${setDockerConfig} docker compose \
			--env-file ${envBuildFilePath} \
			build \
			${dockerDefaultBuildOpts} \
			${DOCKER_BUILD_OPTS} \
			${BUILD_SERVICE_NAME}; \
	else \
		${setDockerConfig} docker pull ${dockerPushPullOpts} ${latestPackagedImage}; \
		${setDockerConfig} docker build \
			--cache-from ${latestPackagedImage} \
			-f ${DOCKERFILE_PATH} \
			${dockerDefaultBuildOpts} \
			${DOCKER_BUILD_OPTS} \
			-t ${PACKAGED_IMAGE_NAME}:${PACKAGED_IMAGE_TAG} \
			${buildContextRoot}${buildContextRoot:+/}${DOCKER_BUILD_CONTEXT}; \
	fi"

rmCmd="rm -rf ${remoteBuildHome}"

tagCmd="docker tag ${PACKAGED_IMAGE_NAME}:${PACKAGED_IMAGE_TAG} ${latestPackagedImage}"

pushBaseCmd="${setDockerConfig} docker push ${dockerPushPullOpts}"
pushOriginalTagCmd="${pushBaseCmd} ${PACKAGED_IMAGE_NAME}:${PACKAGED_IMAGE_TAG}"
pushLatestTagCmd="${pushBaseCmd} ${latestPackagedImage}"
pushCmd="${pushOriginalTagCmd}"

echo -e "${INFO_COLOR}Building ${DATA_COLOR}${PACKAGED_IMAGE_NAME}:${PACKAGED_IMAGE_TAG}${INFO_COLOR} image ..${NULL_COLOR}\n"

runCmdOnTarget "${buildCmd}"
buildCmdExitCode=${?}

if [ ! -z "${SSH_BUILD_REMOTE}" ]
then
	runCmdOnTarget "${rmCmd}"
fi

if [ ${buildCmdExitCode} -eq 0 ]
then
	echo -e "\n${PASS_COLOR}Image successfully built!${NULL_COLOR}\n"
else
	echo -e "\n${FAIL_COLOR}Image building failed!${NULL_COLOR}\n"
	doLogoutCmd
	exit 1
fi

if [ ${OMIT_LATEST_TAG} -eq 0 ]
then
	runCmdOnTarget "${tagCmd}"
	pushCmd="${pushCmd} && ${pushLatestTagCmd}"
	echo -e "\n${INFO_COLOR}Tagged image as ${DATA_COLOR}${LATEST_TAG_VALUE}${INFO_COLOR}!${NULL_COLOR}"
else
	echo -e "${INFO_COLOR}Omit tagging image as ${DATA_COLOR}${LATEST_TAG_VALUE}${INFO_COLOR}!${NULL_COLOR}"
fi

if [ ${OMIT_IMAGE_PUSH} -eq 0 ]
then
	echo -e "\n${INFO_COLOR}Pushing image to registry ..${NULL_COLOR}\n"
	if runCmdOnTarget "${pushCmd}"
	then
		echo -e "\n${PASS_COLOR}Image successfully pushed!${NULL_COLOR}"
	else
		echo -e "\n${FAIL_COLOR}Image push failed!${NULL_COLOR}"
		doLogoutCmd
		exit 1
	fi
else
	echo -e "\n${INFO_COLOR}Omit image pushing!${NULL_COLOR}"
fi

doLogoutCmd
