#!/bin/sh

echo -e "\n${INFO_COLOR}Checking deployment configuration in compose files ..${NULL_COLOR}"
echo -e "  ${INFO_COLOR}compose files [ ${DATA_COLOR}${composeFilePath}${INFO_COLOR} ]${NULL_COLOR}\n"

anyComposeMissing=0
anyBuildConfigFound=0
for composeFilePathItem in $(echo ${composeFilePath} | tr ':' ' ')
do
	if [ -f "${composeFilePathItem}" ]
	then
		if grep -q "^\s\+build:\$" ${composeFilePathItem}
		then
			anyBuildConfigFound=1
		fi
	else
		echo -e "File ${DATA_COLOR}${composeFilePathItem}${INFO_COLOR} not found.${NULL_COLOR}\n"
		anyComposeMissing=1
		break
	fi
done

if [ "${anyComposeMissing}" -eq 1 ] || [ "${anyBuildConfigFound}" -eq 0 ]
then
	echo -e "${INFO_COLOR}Compose build configuration not found, omitting check ..${NULL_COLOR}"
	FORCE_DOCKER_BUILD=1
else
	if docker compose --env-file "./${envBuildFilePath}" config -q
	then
		echo -e "${PASS_COLOR}Valid compose configuration!${NULL_COLOR}"
	else
		echo -e "${FAIL_COLOR}Invalid compose configuration!${NULL_COLOR}"
		eval "${removeBuildEnvFile}"
		exit 1
	fi
fi
