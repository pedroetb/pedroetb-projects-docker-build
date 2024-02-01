#!/bin/sh

echo -e "${INFO_COLOR}Preparing source Docker registry access ..${NULL_COLOR}"

if [ -z "${SOURCE_REGISTRY_URL}" ]
then
	echo -e "  ${INFO_COLOR}source registry host not found, trying with 'REGISTRY_URL'.${NULL_COLOR}"
	SOURCE_REGISTRY_URL="${REGISTRY_URL}"
	if [ -z "${SOURCE_REGISTRY_URL}" ]
	then
		echo -e "  ${INFO_COLOR}source registry host not found, using Docker Hub as default. You can define it with 'SOURCE_REGISTRY_URL'.${NULL_COLOR}"
	else
		echo -e "  ${INFO_COLOR}source registry host set!${NULL_COLOR}"
	fi
fi

if [ -z "${SOURCE_REGISTRY_USER}" ]
then
	echo -e "  ${INFO_COLOR}source registry user not found, trying with 'REGISTRY_USER'.${NULL_COLOR}"
	SOURCE_REGISTRY_USER="${REGISTRY_USER}"
fi

if [ -z "${SOURCE_REGISTRY_PASS}" ]
then
	echo -e "  ${INFO_COLOR}source registry pass not found, trying with 'REGISTRY_PASS'.${NULL_COLOR}"
	SOURCE_REGISTRY_PASS="${REGISTRY_PASS}"
fi

if [ -z "${SOURCE_REGISTRY_USER}" ] || [ -z "${SOURCE_REGISTRY_PASS}" ]
then
	echo -e "  ${INFO_COLOR}Docker pull will be anonymous, because registry credentials for source were not found. You can define them with 'SOURCE_REGISTRY_USER' and 'SOURCE_REGISTRY_PASS'.${NULL_COLOR}\n"
else
	echo -e "  ${INFO_COLOR}source registry credentials set!${NULL_COLOR}\n"
fi

echo -e "${INFO_COLOR}Preparing target Docker registry access ..${NULL_COLOR}"

if [ -z "${TARGET_REGISTRY_URL}" ]
then
	echo -e "  ${INFO_COLOR}target registry host not found, trying with 'SOURCE_REGISTRY_URL'.${NULL_COLOR}"
	TARGET_REGISTRY_URL="${SOURCE_REGISTRY_URL}"
	if [ -z "${TARGET_REGISTRY_URL}" ]
	then
		echo -e "  ${INFO_COLOR}target registry host not found, using Docker Hub as default. You can define it with 'TARGET_REGISTRY_URL'.${NULL_COLOR}"
	else
		echo -e "  ${INFO_COLOR}target registry host set!${NULL_COLOR}"
	fi
fi

if [ -z "${TARGET_REGISTRY_USER}" ]
then
	echo -e "  ${INFO_COLOR}target registry user not found, trying with 'SOURCE_REGISTRY_USER'.${NULL_COLOR}"
	TARGET_REGISTRY_USER="${SOURCE_REGISTRY_USER}"
fi

if [ -z "${TARGET_REGISTRY_PASS}" ]
then
	echo -e "  ${INFO_COLOR}target registry pass not found, trying with 'SOURCE_REGISTRY_PASS'.${NULL_COLOR}"
	TARGET_REGISTRY_PASS="${SOURCE_REGISTRY_PASS}"
fi

if [ -z "${TARGET_REGISTRY_USER}" ] || [ -z "${TARGET_REGISTRY_PASS}" ]
then
	echo -e "  ${INFO_COLOR}Docker push will be omitted, because registry credentials for target were not found. You can define them with 'TARGET_REGISTRY_USER' and 'TARGET_REGISTRY_PASS'.${NULL_COLOR}\n"
	OMIT_IMAGE_PUSH="1"
else
	echo -e "  ${INFO_COLOR}target registry credentials set!${NULL_COLOR}\n"
fi
