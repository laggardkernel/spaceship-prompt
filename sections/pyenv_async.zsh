#
# pyenv
#
# pyenv lets you easily switch between multiple versions of Python.
# Link: https://github.com/pyenv/pyenv

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

SPACESHIP_PYENV_SHOW="${SPACESHIP_PYENV_SHOW=true}"
SPACESHIP_PYENV_PREFIX="${SPACESHIP_PYENV_PREFIX="$SPACESHIP_PROMPT_DEFAULT_PREFIX"}"
SPACESHIP_PYENV_SUFFIX="${SPACESHIP_PYENV_SUFFIX="$SPACESHIP_PROMPT_DEFAULT_SUFFIX"}"
SPACESHIP_PYENV_SYMBOL="${SPACESHIP_PYENV_SYMBOL="🐍 "}"
SPACESHIP_PYENV_COLOR="${SPACESHIP_PYENV_COLOR="yellow"}"

# ------------------------------------------------------------------------------
# Section
# ------------------------------------------------------------------------------

# Show current version of pyenv Python, including system.
spaceship_async_job_load_pyenv_async() {
  [[ $SPACESHIP_PYENV_SHOW == false ]] && return

  (( $+commands[pyenv] )) || return # Do nothing if pyenv is not installed

  # Show pyenv python version only for Python-specific folders
  spaceship::upsearch ".python-version" >/dev/null \
    || spaceship::upsearch "requirements.txt" >/dev/null \
    || [[ -n *.py(#qN^/) ]] \
    || return

  async_job spaceship spaceship_async_job_pyenv_async
}

spaceship_async_job_pyenv_async() {
  local pyenv_status=${$(pyenv version-name 2>/dev/null)//:/ }
  echo "$pyenv_status"
}

spaceship_pyenv_async() {
  [[ $SPACESHIP_PYENV_SHOW == false ]] && return

  local pyenv_status

  # PYENV_VERSION precedes over others
  if [[ -z "${pyenv_status:=$PYENV_VERSION}" ]]; then
    pyenv_status="${SPACESHIP_ASYNC_RESULTS[spaceship_async_job_pyenv_async]}"
  fi

  [[ -z $pyenv_status ]] && return

  spaceship::section \
    "$SPACESHIP_PYENV_COLOR" \
    "$SPACESHIP_PYENV_PREFIX" \
    "${SPACESHIP_PYENV_SYMBOL}${pyenv_status}" \
    "$SPACESHIP_PYENV_SUFFIX"
}
