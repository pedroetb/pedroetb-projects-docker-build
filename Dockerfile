ARG PARENT_IMAGE_NAME=docker \
	PARENT_IMAGE_TAG=cli

FROM ${PARENT_IMAGE_NAME}:${PARENT_IMAGE_TAG}

LABEL maintainer="pedroetb@gmail.com"

WORKDIR /build

ENTRYPOINT ["/bin/sh", "-c"]

ENV BUILDX_GIT_INFO=false

ARG OPENSSH_VERSION \
	PASS_VERSION

RUN apk --update --no-cache add \
	openssh-client-default="${OPENSSH_VERSION}" \
	pass="${PASS_VERSION}"

COPY script/ /script/

RUN \
	binPath=/usr/bin; \
	for filePath in /script/*; \
	do \
		fileName=$(basename "${filePath}"); \
		ln -s "${filePath}" "${binPath}/${fileName}"; \
		ln -s "${filePath}" "${binPath}/${fileName%.*}"; \
	done \
	echo '{"credsStore":"pass"}' > /root/.docker/config.json

ARG VERSION

LABEL version="${VERSION}"

RUN echo "${VERSION}" > /version
