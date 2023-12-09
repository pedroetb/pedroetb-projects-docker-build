#!/bin/sh

envTagFilePath=".env-tag"
removeTagEnvFile="rm ${envTagFilePath}"

addCredentialToEnv() {
	envDefs="${envDefs}${1}\\n"
}

if [ ! -z "${SOURCE_REGISTRY_USER}" ] && [ ! -z "${SOURCE_REGISTRY_PASS}" ]
then
	dbldSourceRegistryPassVarName=DOCKER_BUILD_SOURCE_REGISTRY_PASS
	addCredentialToEnv "${dbldSourceRegistryPassVarName}=${SOURCE_REGISTRY_PASS}"
fi

if [ ! -z "${TARGET_REGISTRY_USER}" ] && [ ! -z "${TARGET_REGISTRY_PASS}" ]
then
	dbldTargetRegistryPassVarName=DOCKER_BUILD_TARGET_REGISTRY_PASS
	addCredentialToEnv "${dbldTargetRegistryPassVarName}=${TARGET_REGISTRY_PASS}"
fi

echo -e ${envDefs} > "${envTagFilePath}"
