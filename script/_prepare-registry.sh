#!/bin/sh

if [ -z "${SOURCE_REGISTRY_USER}" ]
then
	echo -e "${INFO_COLOR}Source Docker registry user not found, trying with 'REGISTRY_USER' ..${NULL_COLOR}"
	SOURCE_REGISTRY_USER="${REGISTRY_USER}"
fi

if [ -z "${SOURCE_REGISTRY_PASS}" ]
then
	echo -e "${INFO_COLOR}Source Docker registry pass not found, trying with 'REGISTRY_PASS' ..${NULL_COLOR}"
	SOURCE_REGISTRY_PASS="${REGISTRY_PASS}"
fi

if [ -z "${SOURCE_REGISTRY_USER}" ] || [ -z "${SOURCE_REGISTRY_PASS}" ]
then
	echo -e "${INFO_COLOR}Docker pull will be anonymous, because registry credentials for source not found. Define them with 'SOURCE_REGISTRY_USER' and 'SOURCE_REGISTRY_PASS' ..${NULL_COLOR}"
fi

if [ -z "${SOURCE_REGISTRY_URL}" ]
then
	echo -e "${INFO_COLOR}Source Docker registry not found, trying with 'REGISTRY_URL' ..${NULL_COLOR}"
	SOURCE_REGISTRY_URL="${REGISTRY_URL}"
	if [ -z "${SOURCE_REGISTRY_URL}" ]
	then
		echo -e "${INFO_COLOR}Source Docker registry not found, using Docker Hub as default. Define it with 'SOURCE_REGISTRY_URL' ..${NULL_COLOR}"
	fi
fi

echo ""

if [ -z "${TARGET_REGISTRY_USER}" ]
then
	echo -e "${INFO_COLOR}Target Docker registry user not found, trying with 'SOURCE_REGISTRY_USER' ..${NULL_COLOR}"
	TARGET_REGISTRY_USER="${SOURCE_REGISTRY_USER}"
fi

if [ -z "${TARGET_REGISTRY_PASS}" ]
then
	echo -e "${INFO_COLOR}Target Docker registry pass not found, trying with 'SOURCE_REGISTRY_PASS' ..${NULL_COLOR}"
	TARGET_REGISTRY_PASS="${SOURCE_REGISTRY_PASS}"
fi

if [ -z "${TARGET_REGISTRY_USER}" ] || [ -z "${TARGET_REGISTRY_PASS}" ]
then
	echo -e "${INFO_COLOR}Docker push will be omitted, because registry credentials for target not found. Define them with 'TARGET_REGISTRY_USER' and 'TARGET_REGISTRY_PASS' ..${NULL_COLOR}"
	OMIT_IMAGE_PUSH="1"
fi

if [ -z "${TARGET_REGISTRY_URL}" ]
then
	echo -e "${INFO_COLOR}Target Docker registry not found, trying with 'SOURCE_REGISTRY_URL' ..${NULL_COLOR}"
	TARGET_REGISTRY_URL="${SOURCE_REGISTRY_URL}"
	if [ -z "${TARGET_REGISTRY_URL}" ]
	then
		echo -e "${INFO_COLOR}Target Docker registry not found, using Docker Hub as default. Define it with 'TARGET_REGISTRY_URL' ..${NULL_COLOR}"
	fi
fi
