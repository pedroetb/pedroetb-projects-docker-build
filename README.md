# docker-build

Docker building utilities and common actions. Inspired by https://gitlab.com/redmic-project/docker/docker-deploy

You can use it to build (locally or remotely) your own Docker images, supporting **docker-compose** build configuration and plain **docker build** command.

Support remote actions, connecting through SSH to other machines. This is useful to build Docker images for different architectures natively, for example.

## Actions

* **build**: Build an image locally or at a remote Docker environment. Contains several stages:

  * *prepare-env*: Try different paths to locate build configuration, retrieve environment variables from current environment and script arguments, prepare values for usage, etc.

  * *check-config*: Validate *docker-compose* configuration (if found). When configuration is missing or invalid, building will continue using `docker build` alternative.

  * *prepare-build*: Copy resources to remote environment (when available), including build configuration, specific project resources, environment definition, etc.

  * *do-build*: Automatically decide to use `docker-compose build` or `docker build`, launch build process locally or remotely, create predefined image tags, push resultant image to Docker registry, clean temporary resources, etc.

* **tag**: Apply a new tag to an already built Docker image, locally or at a remote Docker environment. Contains several stages:

  * *prepare-registry*: Check variables and apply default values if missing, for Docker registry configuration.

  * *prepare-tag*: Split image names and tags, check variables and apply default values if missing, for Docker tag application.

  * *do-tag*: Login to registries, pull source image, apply new tag and push the result.

* **flatten**: Obtain a single-level Docker image name from a multi-level source. Useful to tag images from GitLab registry (multi-level: *group-name/path/to/project*) to DockerHub (single-level: *username/path-to-project*). The output image name can be retrieved as script result or into `TARGET_IMAGE_NAME` environment variable.

## Usage

You need to install **Docker** daemon to use this image from your host. Then, you can run it like:

```
$ docker run --rm --name docker-build \
	-e PACKAGED_IMAGE_NAME=test-image \
	-v /var/run/docker.sock:/var/run/docker.sock:ro \
	-v $(pwd):/build \
	pedroetb/docker-build \
	<action> <arg1> <arg2> ...
```

Notice the `/build` mountpoint, containing current directory content from your host (where you ran the command). This is the default location where build resources and configuration must be located.

Also, Docker socket must be mounted to access local Docker daemon (needed to build locally).

Configuration is possible through environment variables and by script (<action>) parameters.

Using environment variables, you can configure:

* Behaviour of this image itself.
* Docker build arguments, using the `ENV_PREFIX` prefix in your variable names and a convenient *docker-compose* configuration (or using `DOCKER_BUILD_OPTS` directly).
* Variables inside *docker-compose* configuration (using the `ENV_PREFIX` prefix in your variable names).

Using script parameters you can set:

* When action is *build*, Docker build arguments and variables inside *docker-compose* configuration can be set by parameters. These parameters overwrite previous environment values, including those defined using the `ENV_PREFIX` prefix.

## Configuration

### Docker build

You may define these environment variables (**bold** are mandatory):

* **PACKAGED_IMAGE_NAME**: Name of Docker image to be built (without tag). It will be available at build environment as `<IMAGE_NAME_VARIABLE_NAME>`.

* *COMPOSE_ENV_FILE_NAME*: Name of variable definition file, without path. Default `.env`.

* *COMPOSE_FILE_NAME*: Name of image build configuration file, without path. Default `docker-compose.yml`.

* *COMPOSE_PROJECT_DIRECTORY*: Path of directory which contains *docker-compose* configuration. Default `deploy`.

* *DOCKER_BUILD_CONTEXT*: Name of directory which `docker build` will use as context root. Not valid when using `docker-compose build` alternative. Default `.`.

* *DOCKER_BUILD_OPTS*: List of additional *docker build* options, used by both `docker-compose build` and `docker build` alternatives.

* *ENV_PREFIX*: Prefix used to identify variables to be defined in remote environment and service, available there without this prefix. Change this if default value collides with the beginning of your variable names. Default `DBLD_`.

* *ENV_SPACE_REPLACEMENT*: Unique string (change this if that is not true for you) used to replace spaces into variable values while handling them. Default `<dbld-space>`.

* *FORCE_DOCKER_BUILD*: Use always `docker build` alternative instead of `docker-compose build`, even if *docker-compose* configuration is available. Default `0`.

* *IMAGE_NAME_VARIABLE_NAME*: Value used as name of variable which will contain `PACKAGED_IMAGE_NAME` value at build process. Useful only for `docker-compose build` alternative, to use this variable inside *docker-compose* configuration file. Default `IMAGE_NAME`.

* *IMAGE_TAG_VARIABLE_NAME*: Value used as name of variable which will contain `PACKAGED_IMAGE_TAG` value at build process. Useful only for `docker-compose build` alternative, to use this variable inside *docker-compose* configuration file. Default `IMAGE_TAG`.

* *LATEST_TAG_VALUE*: Value used as Docker image tag, representing the most recent version of a Docker image. Default `latest`.

* *OMIT_IMAGE_PUSH*: Cancel image publication to Docker registry after a successful build. Default `0`.

* *OMIT_LATEST_TAG*: Do not tag image as `<LATEST_TAG_VALUE>` after a successful build. Default `0`.

* *PACKAGED_IMAGE_TAG*: Tag of Docker image to be built (representing image version). It will be available at build environment as `<IMAGE_TAG_VARIABLE_NAME>`. Default `latest`.

* *REGISTRY_PASS*: Docker registry password, corresponding to a user with read/write permissions. **Required** to push built images to registry.

* *REGISTRY_URL*: Docker registry address, where Docker must log in to retrieve and publicate images. Default is empty, to use Docker Hub registry.

* *REGISTRY_USER*: Docker registry username, corresponding to a user with read/write permissions. **Required** to push built images to registry.

* *REMOTE_BUILD_PATH*: Path in remote host where building directory (used to hold temporary files) will be created. Only useful when running remote build. Default `~/docker-build`.

* *SSH_BUILD_CONTROL_PERSIST*: Number of seconds while SSH connection to remote host remain open (useful for short but frequent connections). Default `10`.

* *SSH_BUILD_KEY*: Private key used to authenticate, paired with a public key accepted by remote host. **Required** to use remote building.

* *SSH_BUILD_PORT*: Port used for SSH connection to remote host. Default `22`.

* *SSH_BUILD_REMOTE*: SSH user and hostname (DNS or IP) of remote host where you are going to build. Omit to run build locally.

### Docker tag

* **SOURCE_IMAGE**: Identification (`<name:tag>`) of Docker image to use as source. Can be provided as first argument too.

* **TARGET_IMAGE**: Identification (`<name:tag>`) of Docker image to use as target. Can be provided as second argument too.

* *LATEST_TAG_VALUE*: Value used as Docker image tag, representing the most recent version of a Docker image. Default `latest`.

* *OMIT_IMAGE_PUSH*: Cancel image publication to Docker registry after a successful tag. Default `0`.

* *OMIT_LATEST_TAG*: Do not tag image as `<LATEST_TAG_VALUE>` after a successful tag. Default `0`.

* *SOURCE_REGISTRY_PASS*: Docker registry password, corresponding to a user with read permissions at source registry. Default is `<REGISTRY_PASS>`.

* *SOURCE_REGISTRY_URL*: Docker registry address, where Docker must log in to retrieve images. Default is `<REGISTRY_URL>`.

* *SOURCE_REGISTRY_USER*: Docker registry username, corresponding to a user with read permissions at source registry. Default is `<REGISTRY_USER>`.

* *SSH_BUILD_CONTROL_PERSIST*: Number of seconds while SSH connection to remote host remain open (useful for short but frequent connections). Default `10`.

* *SSH_BUILD_KEY*: Private key used to authenticate, paired with a public key accepted by remote host. **Required** to use remote building.

* *SSH_BUILD_PORT*: Port used for SSH connection to remote host. Default `22`.

* *SSH_BUILD_REMOTE*: SSH user and hostname (DNS or IP) of remote host where you are going to build. Omit to run build locally.

* *TARGET_REGISTRY_PASS*: Docker registry password, corresponding to a user with read/write permissions at target registry. Default is `<SOURCE_REGISTRY_PASS>`. **Required** to push tagged images to registry.

* *TARGET_REGISTRY_URL*: Docker registry address, where Docker must log in to publicate images. Default is `<SOURCE_REGISTRY_URL>`.

* *TARGET_REGISTRY_USER*: Docker registry username, corresponding to a user with read/write permissions at target registry. Default is `<SOURCE_REGISTRY_USER>`. **Required** to push tagged images to registry.

### Docker flatten

You may define these environment variables (**bold** are mandatory):

* **SOURCE_IMAGE_NAME**: Name of Docker image to flatten (without tag). Can be provided as first argument too.

* *PRESERVE_ROOT_LEVEL*: Keep first segment of image name (portion before first `/`). If `ROOT_NAME` is defined, this portion acts as a prefix for the name; if not, this becomes the `ROOT_NAME`. Default `0`.

* *ROOT_NAME*: Text used to prepend to the flatten image name, separated by `/`. For example, in Docker Hub this typically is the username.

### Your images

When using *build* action, you can configure your own image arguments through variables:

* Define any variable whose name is prefixed by `ENV_PREFIX` prefix:
	1. Set variable `docker run ... -e DBLD_ANY_NAME=value ... build`.
	2. `ANY_NAME` will be set into image as argument with `value` value.

* Pass any variable as build script parameter (without `ENV_PREFIX` prefix):
	1. Set parameter to build script: `docker run ... build ANY_NAME=value`.
	2. `ANY_NAME` will be set into image as argument with `value` value.

## Examples

### Build (local)

```
$ ls -a .
.  ..  deploy Dockerfile

$ ls -a deploy
.  ..  docker-compose.yml  .env

$ docker run --rm --name docker-build \
	-e PACKAGED_IMAGE_NAME=test-image \
	-e DBLD_VARIABLE_1="variable 1" \
	-v /var/run/docker.sock:/var/run/docker.sock:ro \
	-v $(pwd):/build \
	pedroetb/docker-build \
	build VARIABLE_2="variable 2"
```

1. You must define a Docker image to built, at Dockerfile file.
2. You may define a build configuration, using `docker-compose.yml` file at least. If no configuration is provided, `docker build` will be used automatically.
3. To use Docker inside container (needed to build locally), you must mount `/var/run/docker.sock` from your host.
4. Start image building. In this example:
	* at localhost
	* building `test-image:latest` Docker image from *Dockerfile*
	* using `docker-compose build` with *docker-compose.yml* configuration
	* with `VARIABLE_1` and `VARIABLE_2` set

### Build (remote)

```
$ ls -a .
.  ..  deploy Dockerfile

$ ls -a deploy
.  ..  docker-compose.yml  .env

$ export SSH_BUILD_KEY="
-----BEGIN RSA PRIVATE KEY-----
MIICXQIBAAKBgQDozua2ox1gweQ8/889/8ViH/9sI95+/6px1B+IKSJvmf1qLkD4
3xskMYsWuWmYhfXA8G1gYndTKvEPOB5rfzIT1/bL4jifNqL2cPnRvAvX5u9ddS2b
Qv+LceM37PcIxawYCpoLjoWrr9QMSZz6h62ciX4BbeH8SEXqNSHIrucEzwIDAQAB
AoGAev+9MycwwUsPTA8XLjlwzmv7ZeX5in2HTsZ0tlqNQAtKsQuo9hPh4hhu1N22
5Yd5FKuyDedYBc+9Nn4+zCqSiJltEXqpI1NQAwim1dBPos1940gBUPMMlXiwdMYV
MnozZaSo369P12DIK9r0iEwQlUi68koaH3zbTd6y28kqVtkCQQD1IGIo4mtaQ7tJ
SAlQI5ZZZPbF2NPFkAEK/8YkW1jC90vLRME9Qk4HnyKIjKCWq9Ij3VC+S8sJcbC2
uOWKN5JbAkEA8yKiH6S4v5B9zXUurCz2iZhD/tB1RYPD8YoRgkQ/cu7h4V9qtuII
Xk/ddxiuk+x3Fa4YLgUZEZ6I9YkrznQ5nQJATWevd4egLL3Mq2RjBHpoZMw8HNfO
b8l8etOv5xUtX0umFIcemlCQwVlgF0yI/Ws+jXK6p4zZjZ7oFZsnaNEJlwJBAMjG
lci5ttKCWFCc7wDBVIlFUwkOTXktGVbRpCnFf/vCJod8ytvhBfYTz5d0q11+DMy7
aj4+eXgiSYkxUBp5wcUCQQCZVEsjFFFnJCkZRyNqlCXrRsvpPNExg0BxnMcymEA8
sIhl4aG94WSKaj6MdST5Dzt/0qbyJXCThChJbahWToou
-----END RSA PRIVATE KEY-----
"

$ docker run --rm --name docker-build \
	-e SSH_BUILD_REMOTE=user@domain.net -e SSH_BUILD_KEY \
	-e PACKAGED_IMAGE_NAME=test-image \
	-e DBLD_VARIABLE_1="variable 1" \
	-v $(pwd):/build \
	pedroetb/docker-build \
	build VARIABLE_2="variable 2"
```

1. You must define a Docker image to built, at Dockerfile file.
2. You may define a build configuration, using `docker-compose.yml` file at least. If no configuration is provided, `docker build` will be used automatically.
3. To authenticate, you must use a **private key** allowed in the remote host.
4. Start image building. In this example:
	* at `domain.net` remote host
	* identified as `user`
	* authenticated through a RSA-1024 private key
	* building `test-image:latest` Docker image from *Dockerfile*
	* using `docker-compose build` with *docker-compose.yml* configuration
	* with `VARIABLE_1` and `VARIABLE_2` set

### Flatten and tag (local)

```
$ docker run --rm --name docker-build \
	-e SOURCE_IMAGE_NAME=docker/compose \
	-e PRESERVE_ROOT_LEVEL=1 \
	-e ROOT_NAME=pedroetb \
	-v /var/run/docker.sock:/var/run/docker.sock:ro \
	pedroetb/docker-build \
	"tag \${SOURCE_IMAGE_NAME}:latest \$(flatten):newtag"
```

1. To use Docker inside container (needed to tag locally), you must mount `/var/run/docker.sock` from your host.
2. Start image tagging. In this example:
	* at localhost
	* flattening source Docker image name to use as tag target
	* preserving source root level `docker` and with custom target root name `pedroetb`
	* tagging `docker/compose:latest` as `pedroetb/docker-compose:newtag`
	* omitting image push because target Docker registry credentials are not defined
