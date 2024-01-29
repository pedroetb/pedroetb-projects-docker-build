#!/bin/sh

if [ -z "${SSH_BUILD_REMOTE}" ]
then
	echo -e "${INFO_COLOR}Running Docker build locally ..${NULL_COLOR}"

	runCmdOnTarget() {
		eval "${1}"
	}
else
	. _ssh-config.sh

	echo -e "${INFO_COLOR}Running Docker build at remote target ${DATA_COLOR}${remoteHost}${INFO_COLOR}..${NULL_COLOR}"

	runCmdOnTarget() {
		runRemoteCmd "${1}"
	}
fi
