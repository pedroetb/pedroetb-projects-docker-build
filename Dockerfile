ARG DOCKER_VERSION
FROM docker:${DOCKER_VERSION}

LABEL maintainer="pedroetb@gmail.com"

ARG VERSION OPENSSH_VERSION
ENV VERSION=${VERSION}
LABEL version=${VERSION}

RUN apk --update --no-cache add \
	openssh-client-default="${OPENSSH_VERSION}"

COPY script/ /script/
RUN \
	binPath=/usr/bin; \
	for filePath in /script/*; \
	do \
		fileName=$(basename "${filePath}"); \
		ln -s "${filePath}" "${binPath}/${fileName}"; \
		ln -s "${filePath}" "${binPath}/${fileName%.*}"; \
	done

WORKDIR /build

ENTRYPOINT ["/bin/sh", "-c"]
