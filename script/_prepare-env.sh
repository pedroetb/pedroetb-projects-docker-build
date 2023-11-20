#!/bin/sh

if [ ! -d "${COMPOSE_PROJECT_DIRECTORY}" ]
then
	echo -e "\n${INFO_COLOR}Directory ${DATA_COLOR}${COMPOSE_PROJECT_DIRECTORY}${INFO_COLOR} containing compose configuration not found, fallback to project root directory ..${NULL_COLOR}"
	COMPOSE_PROJECT_DIRECTORY=""
fi

composeFileNameExpanded=$(echo ${COMPOSE_FILE_NAME} | sed "s#:#:${COMPOSE_PROJECT_DIRECTORY}${COMPOSE_PROJECT_DIRECTORY:+\/}#g")
composeFilePath="${COMPOSE_PROJECT_DIRECTORY}${COMPOSE_PROJECT_DIRECTORY:+/}${composeFileNameExpanded}"

envFilePath="${COMPOSE_PROJECT_DIRECTORY}${COMPOSE_PROJECT_DIRECTORY:+/}${COMPOSE_ENV_FILE_NAME}"
envBuildFilePath="${envFilePath}-build"
if [ -f "${envFilePath}" ]
then
	cp -a "${envFilePath}" "${envBuildFilePath}"
else
	touch "${envBuildFilePath}"
fi
removeBuildEnvFile="rm ${envBuildFilePath}"

echo -e "\n${INFO_COLOR}Setting environment variables to local and build target host environments ..${NULL_COLOR}"
echo -en "  ${INFO_COLOR}variable names [ ${DATA_COLOR}COMPOSE_FILE${INFO_COLOR}"

envDefs="COMPOSE_FILE=${composeFilePath}"

addVariableToEnv() {
	envDefs="${envDefs}\\n${1}"
	variableName=$(echo "${1}" | cut -d '=' -f 1)
	echo -en "${INFO_COLOR}, ${DATA_COLOR}${variableName}${INFO_COLOR}"
}

# Include predefined variables first
addVariableToEnv "${IMAGE_NAME_VARIABLE_NAME}=${PACKAGED_IMAGE_NAME}"
addVariableToEnv "${IMAGE_TAG_VARIABLE_NAME}=${PACKAGED_IMAGE_TAG}"

# Include variables in current environment prefixed by ENV_PREFIX
currEnv=$(env | grep "^${ENV_PREFIX}" | sed "s/${ENV_PREFIX}//g" | sed "s/ /${ENV_SPACE_REPLACEMENT}/g")
for currEnvItem in ${currEnv}
do
	cleanItem=$(echo "${currEnvItem}" | sed "s/${ENV_SPACE_REPLACEMENT}/ /g")
	addVariableToEnv "${cleanItem}"
done

# Include variables passed by arguments, overwriting environment values
for arg in "${@}"
do
	addVariableToEnv "${arg}"
done

echo -e " ]${NULL_COLOR}"

# Set .env file with collected environment variables
echo -e ${envDefs} >> "${envBuildFilePath}"
