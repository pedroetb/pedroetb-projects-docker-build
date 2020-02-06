#!/bin/sh

. _definitions.sh

. _prepare-registry.sh

if [ -z "${SSH_REMOTE}" ]
then
	echo -e "\n${INFO_COLOR}Running Docker build locally ..${NULL_COLOR}"
else
	. _ssh-config.sh
	echo -e "\n${INFO_COLOR}Running Docker build at remote target ${DATA_COLOR}${remoteHost}${INFO_COLOR}..${NULL_COLOR}"
fi

. _prepare-tag.sh

. _do-tag.sh
