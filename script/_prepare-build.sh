#!/bin/sh

echo -e "\n${INFO_COLOR}Preparing build configuration and resources ..${NULL_COLOR}"

checkDockerInstalled="command -v docker > /dev/null"
if ! runRemoteCmd "${checkDockerInstalled}"
then
	echo -e "\n${FAIL_COLOR}Docker is not available at build target host environment!${NULL_COLOR}"
	eval "${closeSshCmd}"
	eval "${removeBuildEnvFile}"
	exit 1
fi

remoteBuildHome="${REMOTE_BUILD_PATH}/${randomValue}"

echo -e "\n${INFO_COLOR}Sending building resources to remote ${DATA_COLOR}${remoteHost}${INFO_COLOR} ..${NULL_COLOR}"
echo -e "  ${INFO_COLOR}building path [ ${DATA_COLOR}${remoteBuildHome}${INFO_COLOR} ]${NULL_COLOR}\n"

# Create directory to hold build configuration files
if ! runRemoteCmd "mkdir -p ${remoteBuildHome}"
then
	echo -e "${FAIL_COLOR}Building path ${DATA_COLOR}${remoteBuildHome}${FAIL_COLOR} creation failed!${NULL_COLOR}"
	eval "${removeBuildEnvFile}"
	exit 1
fi

# Send build configuration files
ln -s $(pwd) /${randomValue}
if scp ${SSH_PARAMS} -qr /${randomValue} "${SSH_BUILD_REMOTE}:${REMOTE_BUILD_PATH}"
then
	echo -e "${PASS_COLOR}Building resources successfully sent!${NULL_COLOR}"
else
	echo -e "${FAIL_COLOR}Building resources sending failed!${NULL_COLOR}"
	eval "${removeBuildEnvFile}"
	exit 1
fi
