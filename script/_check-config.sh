#!/bin/sh

echo -e "\n${INFO_COLOR}Checking deployment configuration in docker-compose files ..${NULL_COLOR}"
echo -e "  ${INFO_COLOR}compose files [ ${DATA_COLOR}${composeFilePath}${INFO_COLOR} ]${NULL_COLOR}\n"

if [ ! -f "${composeFilePath}" ]
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
