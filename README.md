# docker-build

Docker building utilities and common actions. Inspired by <https://gitlab.com/redmic-project/docker/docker-deploy>

You can use it to build (locally or remotely) your own Docker images, supporting **docker compose build** with compose configuration and plain **docker build** command.

Support remote actions, connecting through SSH to other machines. This is useful to build Docker images for different architectures natively, for example. For remote building `docker >= v23` is required, because `docker compose >= v2` plugin is needed. Will fallback to `docker build` alternative if outdated.

Since `v2.1.0` multiarch Docker building and tagging is supported too, without needing extra native hosts. For building, you can declare platforms at your compose file and multi-arch will be enabled automatically (or you can set it explicitly if not using compose file). For tagging, source Docker image manifest will be checked to preserve multi-arch at resultant image tag automatically (or you can force using only current platform architecture for new image tag).

## Actions

* **build**:

  Build an image locally or at a remote Docker environment. Contains several stages:

  1. **definitions**:

     Set initial configuration values, getting environment values and with local defaults as fallback. Also prints the initial banner.

  1. **show-banner**:

     Prints the initial banner, with tool name and version.

  1. **prepare-target**:

     Check if target environment is local or remote, preparing connection and functions used at next steps.

  1. **ssh-config**:

     If target environment is remote, set connection options, add identity and define function to run commands at target.

  1. **prepare-env**:

     Try different paths to locate build configuration, retrieve environment variables from current environment and script arguments, prepare values for usage, etc.

  1. **check-config**:

     Validate *compose* configuration (if found). When configuration is missing or invalid, building will continue using `docker build` alternative.

  1. **prepare-build**:

     If target environment is remote, copy resources to remote environment, including build configuration, specific project resources, environment definition, etc.

  1. **do-build**:

     Automatically decide to use `docker compose build` or `docker build`, launch build process locally or remotely, create predefined image tags, push resultant image to Docker registry, clean temporary resources, etc.

* **tag**:

  Apply a new tag to an already built Docker image, locally or at a remote Docker environment. Contains several stages:

  1. **definitions**:

     Set initial configuration values, getting environment values and with local defaults as fallback. Also prints the initial banner.

  1. **show-banner**:

     Prints the initial banner, with tool name and version.

  1. **prepare-registry**:

     Check variables and apply default values if missing, for Docker registry configuration.

  1. **prepare-target**:

     Check if target environment is local or remote, preparing connection and functions used at next steps.

  1. **ssh-config**:

     If target environment is remote, set connection options, add identity and define function to run commands at target.

  1. **prepare-credentials**:

     Use a file to store registry credentials, to avoid using insecure CLI arguments for passwords.

  1. **prepare-tag**:

     Split image names and tags, check variables and apply default values if missing, for Docker tag application. When tagging at remote environment, send registry credentials to host.

  1. **do-tag**:

     Login to registries, check source image, apply new tag and push the result.

* **flatten**:

  Obtain a single-level Docker image name from a multi-level source. Useful to tag images from GitLab registry (multi-level: *group-name/path/to/project*) to DockerHub (single-level: *username/path-to-project*). The output image name can be retrieved as script result or into `TARGET_IMAGE_NAME` environment variable. Contains only **definitions** stage.

## Usage

You need to install **Docker** daemon to use this image from your host. Then, you can run it like:

```sh
docker run --rm --name docker-build \
  -e PACKAGED_IMAGE_NAME=test-image \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v $(pwd):/build \
  pedroetb/docker-build \
  <action> <arg1> <arg2> ...
```

Notice the `/build` mountpoint, containing current directory content from your host (where you ran the command). This is the default location where build resources and configuration must be located.

Also, Docker socket must be mounted to access local Docker daemon (needed to build locally).

Configuration is possible through environment variables and by script (`<action>`) parameters.

Using environment variables, you can configure:

* Behaviour of `docker-build` itself.
* Docker build arguments, using the `ENV_PREFIX` (`DBLD_` by default) prefix in your variable names and a convenient *compose* configuration (or using `DOCKER_BUILD_OPTS` directly).
* Variables inside *compose* configuration, using the `ENV_PREFIX` (`DBLD_` by default) prefix in your variable names.

Using script parameters you can set:

* When action is *build*, Docker build arguments and variables inside *compose* configuration can be set by parameters. These parameters overwrite previous environment values, including those defined using the `ENV_PREFIX` (`DBLD_` by default) prefix.

## Configuration

### Docker build

You may define these environment variables (**bold** are mandatory):

| Variable name | Default value | Description |
| - | - | - |
| **PACKAGED_IMAGE_NAME** | - | Name of Docker image to be built (without tag). It will be available at build environment as `<IMAGE_NAME_VARIABLE_NAME>`. |
| *ALLOW_COMPOSE_ENV_FILE_INTERPOLATION* | `0` | Allow passing variable values directly from `COMPOSE_ENV_FILE_NAME` file (`.env` by default), to let *Compose* interpolate variables used into values. By default, values will be single-quoted before checking config and building with *Compose*, to avoid getting unwanted variable resolution. Useful only for `docker compose build` alternative. |
| *BUILD_SERVICE_NAME* | - | Name of service (among those defined into *compose* configuration) to be built. Default is empty, to build all services found (although tagging and pushing only accept one image at a time). |
| *COMPOSE_ENV_FILE_NAME* | `.env` | Name of variable definition file, without path. |
| *COMPOSE_FILE_NAME* | `compose.yaml` | Name of image build configuration file, without path. Support multiple files, separated by `:`. |
| *COMPOSE_PROJECT_DIRECTORY* | `build` | Path of directory which contains *compose* configuration. |
| *DOCKER_BUILD_CONTEXT* | `.` | Name of directory which `docker build` will use as context root. Not valid when using `docker compose build` alternative. |
| *DOCKER_BUILD_OPTS* | - | List of additional *docker build* options, used by both `docker compose build` and `docker build` alternatives. |
| *DOCKER_VERBOSE* | `0` | Show full output of Docker operations (`build`, `pull` and `push`) when enabled. |
| *DOCKERFILE_PATH* | `Dockerfile` | Path of `Dockerfile` file, relative to your project directories. Not valid when using `docker compose build` alternative. |
| *ENABLE_MULTIARCH_BUILD* | `0` | Perform image building for multiple platform architectures at once. Valid for both `docker compose build` and `docker build`. When using `docker compose build`, this will be enabled automatically if `platforms` keyword is detected at compose file, building for these architectures. If `docker build` is used (actually, `docker buildx build`), you must enable this explicitly and will build for architectures defined by `MULTIARCH_PLATFORM_LIST`. |
| *ENV_PREFIX* | `DBLD_` | Prefix used to identify variables to be defined in remote environment and service, available there without this prefix. Change this if default value collides with the beginning of your variable names. |
| *ENV_SPACE_REPLACEMENT* | `<dbld-space>` | Unique string (change this if that is not true for you) used to replace spaces into variable values while handling them. |
| *FORCE_DOCKER_BUILD* | `0` | Use always `docker build` alternative instead of `docker compose build`, even if *compose* configuration is available. |
| *IMAGE_NAME_VARIABLE_NAME* | `IMAGE_NAME` | Value used as name of variable which will contain `PACKAGED_IMAGE_NAME` value at build process. Useful only for `docker compose build` alternative, to use this variable inside *compose* configuration file. |
| *IMAGE_TAG_VARIABLE_NAME* | `IMAGE_TAG` | Value used as name of variable which will contain `PACKAGED_IMAGE_TAG` value at build process. Useful only for `docker compose build` alternative, to use this variable inside *compose* configuration file. |
| *IMAGES_FOR_CACHING* | - | Docker images, separated by space, which should be pulled before building to provide contents for `cache_from` (at *compose* file for `docker compose build` ) or `--cache-from` (at command arguments for `docker build`). |
| *LATEST_TAG_VALUE* | `latest` | Value used as Docker image tag, representing the most recent version of a Docker image. |
| *MULTIARCH_PLATFORM_LIST* | `linux/amd64,linux/386,linux/arm64/v8,linux/arm/v7,linux/arm/v6` | Platform architectures used by multiarch building, only when building with `docker build` alternative (actually, `docker buildx build`). When using `docker compose build`, you must define `platforms` into `build` section at your compose file. |
| *OMIT_IMAGE_PUSH* | `0` | Cancel image publication to Docker registry after a successful build. |
| *OMIT_LATEST_TAG* | `0` | Do not tag image as `<LATEST_TAG_VALUE>` after a successful build. |
| *PACKAGED_IMAGE_TAG* | `latest` | Tag of Docker image to be built (representing image version). It will be available at build environment as `<IMAGE_TAG_VARIABLE_NAME>`. |
| *REGISTRY_PASS* | - | Docker registry password, corresponding to a user with read/write permissions. **Required** to push built images to registry. |
| *REGISTRY_URL* | - | Docker registry address, where Docker must log in to retrieve and publicate images. Default is empty, to use Docker Hub registry. |
| *REGISTRY_USER* | - | Docker registry username, corresponding to a user with read/write permissions. **Required** to push built images to registry. |
| *REMOTE_BUILD_PATH* | `~/docker-build` | Path in remote host where building directory (used to hold temporary files) will be created. Only useful when running remote build. |
| *SSH_BUILD_CONTROL_PERSIST* | `10` | Number of seconds while SSH connection to remote host remain open (useful for short but frequent connections). |
| *SSH_BUILD_KEY* | - | Private key used to authenticate, paired with a public key accepted by remote host. **Required** to use remote building. |
| *SSH_BUILD_PORT* | `22` | Port used for SSH connection to remote host. |
| *SSH_BUILD_REMOTE* | - | SSH user and hostname (DNS or IP) of remote host where you are going to build. Omit to run build locally. **Required** to use remote building. |

### Docker tag

You may define these environment variables (**bold** are mandatory):

| Variable name | Default value | Description |
| - | - | - |
| **SOURCE_IMAGE** | - | Identification (`<name:tag>`) of Docker image to use as source. Can be provided as first argument too. |
| **TARGET_IMAGE** | - | Identification (`<name:tag>`) of Docker image to use as target. Can be provided as second argument too. |
| *DOCKER_VERBOSE* | `0` | Show full output of Docker operations (`build`, `pull` and `push`) when enabled. |
| *FORCE_SINGLEARCH_TAG* | `0` | Perform image tagging without preserving original image manifest for multi-arch source images, incuding only current platform architecture (where docker-build is running) for new tag. When disabled, all platform architectures found at source image manifest are included for new tag. |
| *LATEST_TAG_VALUE* | `latest` | Value used as Docker image tag, representing the most recent version of a Docker image. |
| *OMIT_IMAGE_PUSH* | `0` | Cancel image publication to Docker registry after a successful tag. |
| *OMIT_LATEST_TAG* | `0` | Do not tag image as `<LATEST_TAG_VALUE>` after a successful tag. |
| *REMOTE_BUILD_PATH* | `~/docker-build` | Path in remote host where tagging directory (used to hold temporary files) will be created. Only useful when running remote build. |
| *SOURCE_REGISTRY_PASS* | `<REGISTRY_PASS>` | Docker registry password, corresponding to a user with read permissions at source registry. |
| *SOURCE_REGISTRY_URL* | `<REGISTRY_URL>` | Docker registry address, where Docker must log in to retrieve images. |
| *SOURCE_REGISTRY_USER* | `<REGISTRY_USER>` | Docker registry username, corresponding to a user with read permissions at source registry. |
| *SSH_BUILD_CONTROL_PERSIST* | `10` | Number of seconds while SSH connection to remote host remain open (useful for short but frequent connections. |
| *SSH_BUILD_KEY* | - | Private key used to authenticate, paired with a public key accepted by remote host. **Required** to use remote building. |
| *SSH_BUILD_PORT* | `22` | Port used for SSH connection to remote host. |
| *SSH_BUILD_REMOTE* | - | SSH user and hostname (DNS or IP) of remote host where you are going to build. Omit to run build locally. |
| *TARGET_REGISTRY_PASS* | `<SOURCE_REGISTRY_PASS>` | Docker registry password, corresponding to a user with read/write permissions at target registry. **Required** to push tagged images to registry. |
| *TARGET_REGISTRY_URL* | `<SOURCE_REGISTRY_URL>` | Docker registry address, where Docker must log in to publicate images. |
| *TARGET_REGISTRY_USER* | `<SOURCE_REGISTRY_USER>` | Docker registry username, corresponding to a user with read/write permissions at target registry. **Required** to push tagged images to registry. |

### Docker flatten

You may define these environment variables (**bold** are mandatory):

| Variable name | Default value | Description |
| - | - | - |
| **SOURCE_IMAGE_NAME** | - | Name of Docker image to flatten (without tag). Can be provided as first argument too. |
| *PRESERVE_ROOT_LEVEL* | `0` | Keep first segment of image name (portion before first `/`). If `ROOT_NAME` is defined, this portion acts as a prefix for the name; if not, this becomes the `ROOT_NAME`. |
| *ROOT_NAME* | - | Text used to prepend to the flatten image name, separated by `/`. For example, in Docker Hub this typically is the username. |

### Your images

When using *build* action, you can configure your own image arguments through variables:

> Note that you must declare them at your compose files too (into `build.args` section, for example).

* Define any variable whose name is prefixed by `ENV_PREFIX` prefix:

  1. Set variable `docker run ... -e DBLD_ANY_NAME=value ... build`.
  2. `ANY_NAME` will be available to set into image as argument with `value` value.

* Pass any variable as build script parameter (without `ENV_PREFIX` prefix):

  1. Set parameter to build script: `docker run ... build ANY_NAME=value`.
  2. `ANY_NAME` will be available to set into image as argument with `value` value.

## Examples

### Build (local)

```sh
$ ls -a .
.  ..  build Dockerfile

$ ls -a build
.  ..  compose.yaml  .env

$ docker run --rm --name docker-build \
  -e PACKAGED_IMAGE_NAME=test-image \
  -e DBLD_VARIABLE_1="variable 1" \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v $(pwd):/build \
  pedroetb/docker-build \
  build VARIABLE_2="variable 2"
```

1. You must define a Docker image to built, at Dockerfile file.
2. You may define a build configuration, using `compose.yaml` file at least. If no configuration is provided, `docker build` will be used automatically.
3. To use Docker inside container (needed to build locally), you must mount `/var/run/docker.sock` from your host.
4. Start image building. In this example:
   * at localhost
   * building `test-image:latest` Docker image from *Dockerfile*
   * using `docker compose build` with *compose.yaml* configuration
   * with `VARIABLE_1` and `VARIABLE_2` set

### Build (remote)

```sh
$ ls -a .
.  ..  build Dockerfile

$ ls -a build
.  ..  compose.yaml  .env

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
  -e SSH_BUILD_REMOTE=user@domain.net \
  -e SSH_BUILD_KEY \
  -e PACKAGED_IMAGE_NAME=test-image \
  -e DBLD_VARIABLE_1="variable 1" \
  -v $(pwd):/build \
  pedroetb/docker-build \
  build VARIABLE_2="variable 2"
```

1. You must define a Docker image to built, at Dockerfile file.
2. You may define a build configuration, using `compose.yaml` file at least. If no configuration is provided, `docker build` will be used automatically.
3. To authenticate, you must use a **private key** allowed in the remote host.
4. Start image building. In this example:
   * at `domain.net` remote host
   * identified as `user`
   * authenticated through a RSA-1024 private key
   * building `test-image:latest` Docker image from *Dockerfile*
   * using `docker compose build` with *compose.yaml* configuration
   * with `VARIABLE_1` and `VARIABLE_2` set

### Flatten and tag (local)

```sh
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
