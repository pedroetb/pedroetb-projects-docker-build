#!/bin/sh

echo -e "\n${INFO_COLOR}Building ${DATA_COLOR}${PACKAGED_IMAGE_NAME}:${PACKAGED_IMAGE_TAG}${INFO_COLOR} image ..${NULL_COLOR}\n"

latestPackagedImage=${PACKAGED_IMAGE_NAME}:${LATEST_TAG_VALUE}
dockerDefaultBuildOpts="--pull --force-rm"

if [ -z "${SSH_BUILD_REMOTE}" ]
then
	cmdPrefix="eval"
else
	cmdPrefix="ssh ${SSH_PARAMS} ${SSH_BUILD_REMOTE}"

	buildContextRoot="${remoteBuildHome}"
	dockerConfigPath="${REMOTE_BUILD_PATH}/.${randomValue}"
	setDockerConfig="DOCKER_CONFIG=${dockerConfigPath}"
fi

getDockerVersion="docker version --format '{{.Client.Version}}'"
dockerVersion=$($(echo ${cmdPrefix}) ${getDockerVersion})

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

loginCmd="${setDockerConfig} docker login -u \"${REGISTRY_USER}\" -p \"${REGISTRY_PASS}\" ${REGISTRY_URL}"

logoutCmd="${setDockerConfig} docker logout ${REGISTRY_URL}"

rmDockerConfigCmd="rm -rf ${dockerConfigPath}"

doLogoutCmd() {

	if [ ! -z ${loggedIn} ]
	then
		$(echo ${cmdPrefix}) ${logoutCmd}
	fi

	if [ ! -z "${SSH_BUILD_REMOTE}" ]
	then
		$(echo ${cmdPrefix}) ${rmDockerConfigCmd}
		eval "${closeSshCmd}"
	fi

	eval "${removeBuildEnvFile}"
}

buildCmd="\
	${buildContextRoot:+cd ${buildContextRoot};} \
	${setDockerConfig}${setDockerConfig:+;} \
	if [ ${FORCE_DOCKER_BUILD} -eq 0 ]; \
	then \
		docker compose \
			--env-file ${envBuildFilePath} \
			build \
			${dockerDefaultBuildOpts} \
			${DOCKER_BUILD_OPTS} \
			${BUILD_SERVICE_NAME}; \
	else \
		docker pull ${latestPackagedImage}; \
		docker build \
			--cache-from ${latestPackagedImage} \
			${dockerDefaultBuildOpts} \
			${DOCKER_BUILD_OPTS} \
			-t ${PACKAGED_IMAGE_NAME}:${PACKAGED_IMAGE_TAG} \
			${buildContextRoot}${buildContextRoot:+/}${DOCKER_BUILD_CONTEXT}; \
	fi"

rmCmd="rm -rf ${remoteBuildHome}"

tagCmd="docker tag ${PACKAGED_IMAGE_NAME}:${PACKAGED_IMAGE_TAG} ${latestPackagedImage}"

pushOriginalTagCmd="${setDockerConfig} docker push ${PACKAGED_IMAGE_NAME}:${PACKAGED_IMAGE_TAG}"
pushLatestTagCmd="${setDockerConfig} docker push ${latestPackagedImage}"
pushCmd="${pushOriginalTagCmd} && ${pushLatestTagCmd}"

if [ -z "${REGISTRY_USER}" ] || [ -z "${REGISTRY_PASS}" ]
then
	echo -e "${INFO_COLOR}Docker registry credentials not found, omitting login and image push ..${NULL_COLOR}\n"
	OMIT_IMAGE_PUSH="1"
else
	if $(echo ${cmdPrefix}) ${loginCmd}
	then
		loggedIn="1"
	fi
fi

$(echo ${cmdPrefix}) ${buildCmd}
buildCmdExitCode=${?}

if [ ! -z "${SSH_BUILD_REMOTE}" ]
then
	$(echo ${cmdPrefix}) ${rmCmd}
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
	$(echo ${cmdPrefix}) ${tagCmd}
fi

if [ ${OMIT_IMAGE_PUSH} -eq 0 ]
then
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
