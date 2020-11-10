#!/bin/sh

echo -e "\n${INFO_COLOR}Checking deployment configuration in docker-compose files ..${NULL_COLOR}"
echo -e "  ${INFO_COLOR}compose files [ ${DATA_COLOR}${composeFilePath}${INFO_COLOR} ]${NULL_COLOR}\n"

anyComposeMissing=0
for composeFilePathItem in $(echo ${composeFilePath} | tr ':' ' ')
do
	if [ ! -f "${composeFilePathItem}" ]
	then
		echo -e "${DATA_COLOR}${composeFilePathItem}${INFO_COLOR} not found.${NULL_COLOR}"
		anyComposeMissing=1
	fi
done

if [ "${anyComposeMissing}" -eq 1 ]
then
	echo -e "${INFO_COLOR}Docker-compose configuration not found, omitting check ..${NULL_COLOR}"
	FORCE_DOCKER_BUILD=1
else
	if docker-compose --env-file "./${envFilePath}" config > /dev/null
	then
		echo -e "${PASS_COLOR}Valid docker-compose configuration!${NULL_COLOR}"
	else
		echo -e "${FAIL_COLOR}Invalid docker-compose configuration!${NULL_COLOR}"
		exit 1
	fi
fi
