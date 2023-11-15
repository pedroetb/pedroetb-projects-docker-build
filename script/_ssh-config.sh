#!/bin/sh

remoteHost=$(echo "${SSH_BUILD_REMOTE}" | cut -f 2 -d '@')

if [ -z "${remoteHost}" ]
then
	echo -e "${FAIL_COLOR}You must define 'SSH_BUILD_REMOTE' in environment, with remote user and hostname (like 'ssh-user@ssh-remote')${NULL_COLOR}"
	exit 1
fi

if [ -z "${SSH_BUILD_KEY}" ]
then
	echo -e "${FAIL_COLOR}You must define 'SSH_BUILD_KEY' in environment, with a SSH private key accepted by remote server${NULL_COLOR}"
	exit 1
fi

# Prepare identity to connect to remote server
eval "$(ssh-agent -s)"
echo "${SSH_BUILD_KEY}" | tr -d '\r' | ssh-add - > /dev/null
