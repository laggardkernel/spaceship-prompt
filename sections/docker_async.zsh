#
# Docker
#
# Docker automates the repetitive tasks of setting up development environments
# Link: https://www.docker.com

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

SPACESHIP_DOCKER_SHOW="${SPACESHIP_DOCKER_SHOW=true}"
SPACESHIP_DOCKER_PREFIX="${SPACESHIP_DOCKER_PREFIX="on "}"
SPACESHIP_DOCKER_SUFFIX="${SPACESHIP_DOCKER_SUFFIX="$SPACESHIP_PROMPT_DEFAULT_SUFFIX"}"
SPACESHIP_DOCKER_SYMBOL="${SPACESHIP_DOCKER_SYMBOL="🐳 "}"
SPACESHIP_DOCKER_COLOR="${SPACESHIP_DOCKER_COLOR="cyan"}"
SPACESHIP_DOCKER_VERBOSE="${SPACESHIP_DOCKER_VERBOSE=false}"

# ------------------------------------------------------------------------------
# Section
# ------------------------------------------------------------------------------

spaceship_docker_exists_compose_file() {
  [[ -n "$COMPOSE_FILE" ]] || return 1

  # Better support for docker environment vars: https://docs.docker.com/compose/reference/envvars/

  # Use COMPOSE_PATH_SEPARATOR or colon as default
  local separator=${COMPOSE_PATH_SEPARATOR:-":"}

  # COMPOSE_FILE may have several filenames separated by colon, test all of them
  local filenames=("${(@ps/$separator/)COMPOSE_FILE}")

  # Must ensure all compose files exist
  # https://github.com/docker/docker.github.io/issues/5472
  for filename in $filenames; do
    if ! spaceship::upsearch "$filename" >/dev/null; then
      return 1
    fi
  done
  return 0
}

spaceship_async_job_load_docker_async() {
  [[ $SPACESHIP_DOCKER_SHOW == false ]] && return

  (( $+commands[docker] )) || return

  # Show Docker status only for Docker-specific folders
  spaceship::upsearch "Dockerfile" >/dev/null \
    || spaceship::upsearch "docker-compose.yml" >/dev/null \
    || spaceship_docker_exists_compose_file \
    || [[ -f /.dockerenv ]] \
    || return

  async_job spaceship spaceship_async_job_docker_async
}

spaceship_async_job_docker_async() {
  # if docker daemon isn't running you'll get an error saying it can't connect
  local docker_version=$(docker version -f "{{.Server.Version}}" 2>/dev/null)
  echo "$docker_version"
}

# Show current Docker version and connected machine
spaceship_docker_async() {
  [[ $SPACESHIP_DOCKER_SHOW == false ]] && return

  local docker_version

  docker_version="${SPACESHIP_ASYNC_RESULTS[spaceship_async_job_docker_async]}"

  [[ -z $docker_version ]] && return

  [[ $SPACESHIP_DOCKER_VERBOSE == false ]] && docker_version=${docker_version%-*}

  if [[ -n $DOCKER_MACHINE_NAME ]]; then
    docker_version+=" via ($DOCKER_MACHINE_NAME)"
  fi

  spaceship::section \
    "$SPACESHIP_DOCKER_COLOR" \
    "$SPACESHIP_DOCKER_PREFIX" \
    "${SPACESHIP_DOCKER_SYMBOL}v${docker_version}" \
    "$SPACESHIP_DOCKER_SUFFIX"
}
