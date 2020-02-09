#!/bin/sh

echo -e "\n${INFO_COLOR}Building ${DATA_COLOR}${PACKAGED_IMAGE_NAME}:${PACKAGED_IMAGE_TAG}${INFO_COLOR} image ..${NULL_COLOR}\n"

latestPackagedImage=${PACKAGED_IMAGE_NAME}:${LATEST_TAG_VALUE}
dockerDefaultBuildOpts="--pull --force-rm"

if [ -z "${SSH_BUILD_REMOTE}" ]
then
	cmdPrefix="eval"
else
	cmdPrefix="ssh ${SSH_PARAMS} ${SSH_BUILD_REMOTE}"
	buildContextRoot="${REMOTE_BUILD_HOME}"
fi

checkComposeInstalled="command -v docker-compose"

minComposeVersion="1.25.0"
checkComposeVersion="[ \"\$(printf '%s\n' \"${minComposeVersion}\" \"\$(docker-compose -v | cut -d ' ' -f 3 | cut -d ',' -f 1)\" | sort -V | head -n1)\" = \"${minComposeVersion}\" ]"

if $(echo ${cmdPrefix}) ${checkComposeInstalled}
then
	if ! $(echo ${cmdPrefix}) ${checkComposeVersion}
	then
		echo -e "${INFO_COLOR}Docker-compose is outdated (< ${minComposeVersion}), forcing 'docker build' ..${NULL_COLOR}"
		FORCE_DOCKER_BUILD="1"
	fi
else
	echo -e "${INFO_COLOR}Docker-compose is not installed, forcing 'docker build' ..${NULL_COLOR}"
	FORCE_DOCKER_BUILD="1"
fi

loginCmd="docker login -u \"${REGISTRY_USER}\" -p \"${REGISTRY_PASS}\" ${REGISTRY_URL}"

buildCmd="\
	${buildContextRoot:+cd ${buildContextRoot};} \
	if [ ${FORCE_DOCKER_BUILD} -eq 0 ] && grep -q \"^\\s\\+build:\$\" ${composeFilePath}; \
	then \
		docker-compose \
			--env-file ${envFilePath} \
			build \
			${dockerDefaultBuildOpts} \
			${DOCKER_BUILD_OPTS}; \
	else \
		docker pull ${latestPackagedImage}; \
		docker build \
			--cache-from ${latestPackagedImage} \
			${dockerDefaultBuildOpts} \
			${DOCKER_BUILD_OPTS} \
			-t ${PACKAGED_IMAGE_NAME}:${PACKAGED_IMAGE_TAG} \
			${buildContextRoot}${buildContextRoot:+/}${DOCKER_BUILD_CONTEXT}; \
	fi"

rmCmd="rm -rf ${REMOTE_BUILD_HOME}"

tagCmd="docker tag ${PACKAGED_IMAGE_NAME}:${PACKAGED_IMAGE_TAG} ${latestPackagedImage}"

pushCmd="docker push ${PACKAGED_IMAGE_NAME}"

if [ -z "${REGISTRY_USER}" ] || [ -z "${REGISTRY_PASS}" ]
then
	echo -e "${INFO_COLOR}Docker registry credentials not found, omitting login and image push ..${NULL_COLOR}\n"
	OMIT_IMAGE_PUSH="1"
else
	$(echo ${cmdPrefix}) ${loginCmd}
fi

$(echo ${cmdPrefix}) ${buildCmd}
buildCmdExitCode=${?}

$(echo ${cmdPrefix}) ${rmCmd}

if [ ${buildCmdExitCode} -eq 0 ]
then
	echo -e "\n${PASS_COLOR}Image successfully built!${NULL_COLOR}\n"
else
	echo -e "\n${FAIL_COLOR}Image building failed!${NULL_COLOR}\n"
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
		exit 1
	fi
fi
