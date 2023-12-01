#!/bin/sh

remoteUser=$(echo "${SSH_BUILD_REMOTE}" | cut -d '@' -f 1)
remoteHost=$(echo "${SSH_BUILD_REMOTE}" | cut -d '@' -f 2)

if [ -z "${remoteHost}" ]
then
	echo -e "${FAIL_COLOR}Remote host not found, define 'SSH_BUILD_REMOTE' with remote user and hostname (like 'ssh-user@ssh-remote')${NULL_COLOR}"
	exit 1
fi

if [ -z "${SSH_BUILD_KEY}" ]
then
	echo -e "${FAIL_COLOR}You must define 'SSH_BUILD_KEY' in environment, with a SSH private key accepted by remote host${NULL_COLOR}"
	exit 1
fi

# Prepare identity to connect to remote server
eval "$(ssh-agent)" > /dev/null
echo "${SSH_BUILD_KEY}" | tr -d '\r' | ssh-add - > /dev/null 2>&1

closeSshCmd="ssh -l ${remoteUser} ${SSH_PARAMS} -q -O exit \"${remoteHost}\""

runRemoteCmd() {
	ssh -l ${remoteUser} ${SSH_PARAMS} "${remoteHost}" "${1}"
}

# Check remote connectivity
if ! runRemoteCmd ":" &> /dev/null
then
	echo -e "\n${FAIL_COLOR}Failed to connect to host ${DATA_COLOR}${remoteHost}${FAIL_COLOR} at port ${DATA_COLOR}${SSH_BUILD_PORT}${FAIL_COLOR} with user ${DATA_COLOR}${remoteUser}${FAIL_COLOR}!${NULL_COLOR}"
	eval "${closeSshCmd}"
	exit 1
fi
