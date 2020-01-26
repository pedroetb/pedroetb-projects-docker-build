ARG DOCKER_COMPOSE_VERSION=1.25.1
FROM docker/compose:${DOCKER_COMPOSE_VERSION}

LABEL maintainer="pedroetb@gmail.com"

ARG OPENSSH_CLIENT_VERSION=8.1_p1-r0
RUN apk --update --no-cache add \
	openssh-client=${OPENSSH_CLIENT_VERSION}

COPY script/ /script/
RUN \
	binPath=/usr/bin; \
	for filePath in /script/*; \
	do \
		fileName=$(basename "${filePath}"); \
		chmod 755 "${filePath}"; \
		ln -s "${filePath}" "${binPath}/${fileName}"; \
		ln -s "${filePath}" "${binPath}/${fileName%.*}"; \
	done

WORKDIR /build

ENTRYPOINT ["/bin/sh", "-c"]
