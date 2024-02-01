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

		if grep -q "^\s\+platforms:\$" ${composeFilePathItem}
		then
			ENABLE_MULTIARCH_BUILD=1
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
	if [ ${ALLOW_COMPOSE_ENV_FILE_INTERPOLATION} -eq 0 ]
	then
		while IFS= read -r envLine
		do
			if [ -z "${envLine}" ] || echo "${envLine}" | grep -q '^[#| ]'
			then
				continue
			else
				variableName=$(echo "${envLine}" | cut -d '=' -f 1)
				variableValue=$(echo "${envLine}" | cut -d '=' -f 2-)

				if echo "${variableValue}" | grep -q '\$\$' || echo "${variableValue}" | grep -q "^'"
				then
					envConfigContent="${envConfigContent}${variableName}=${variableValue}\\n"
				else
					envConfigContent="${envConfigContent}${variableName}='${variableValue}'\\n"
				fi
			fi
		done < "${envBuildFilePath}"
		echo -e "${envConfigContent}" > "${envBuildFilePath}"
	fi

	if docker compose --env-file "${envBuildFilePath}" config -q
	then
		echo -e "  ${PASS_COLOR}valid compose configuration!${NULL_COLOR}"
	else
		echo -e "  ${FAIL_COLOR}invalid compose configuration!${NULL_COLOR}"
		eval "${removeBuildEnvFile}"
		exit 1
	fi
fi
