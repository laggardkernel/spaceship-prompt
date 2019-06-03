#
# Node.js
#
# Node.js is a JavaScript runtime built on Chrome's V8 JavaScript engine.
# Link: https://nodejs.org/

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

SPACESHIP_NODE_SHOW="${SPACESHIP_NODE_SHOW=true}"
SPACESHIP_NODE_PREFIX="${SPACESHIP_NODE_PREFIX="$SPACESHIP_PROMPT_DEFAULT_PREFIX"}"
SPACESHIP_NODE_SUFFIX="${SPACESHIP_NODE_SUFFIX="$SPACESHIP_PROMPT_DEFAULT_SUFFIX"}"
SPACESHIP_NODE_SYMBOL="${SPACESHIP_NODE_SYMBOL="⬢ "}"
SPACESHIP_NODE_DEFAULT_VERSION="${SPACESHIP_NODE_DEFAULT_VERSION=""}"
SPACESHIP_NODE_COLOR="${SPACESHIP_NODE_COLOR="green"}"

# ------------------------------------------------------------------------------
# Section
# ------------------------------------------------------------------------------

spaceship_async_job_load_node_async() {
  [[ $SPACESHIP_NODE_SHOW == false ]] && return

  (( $+commands[nodenv] )) || (( $+commands[nvm] )) || (( $+commands[node] )) || return

  # Show NODE status only for JS-specific folders
  spaceship::upsearch "package.json" >/dev/null \
    || spaceship::upsearch "node_modules" "dir" >/dev/null \
    || [[ -n *.js(#qN^/) ]] || return

  async_job spaceship spaceship_async_job_node_async
}

spaceship_async_job_node_async() {
  local node_version=""

  if (( $+commands[nodenv] )); then
    node_version=$(nodenv version-name)
  elif (( $+commands[nvm] )); then
    node_version=$(nvm current 2>/dev/null)
  elif spaceship::exists node; then
    node_version=$(node -v 2>/dev/null)
  fi

  echo "$node_version"
}

# Show current version of node, exception system.
spaceship_node_async() {
  [[ $SPACESHIP_NODE_SHOW == false ]] && return

  local node_version

  # PYENV_VERSION precedes over others
  if [[ -z "${node_version:=$NODENV_VERSION}" ]]; then
    node_version="${SPACESHIP_ASYNC_RESULTS[spaceship_async_job_node_async]}"
  fi

  if [[ -z $node_version ]] \
    || [[ $node_version == $SPACESHIP_NODE_DEFAULT_VERSION ]] \
    || [[ $node_version == system ]] || [[ $node_version == node ]]; then
    return
  fi

  spaceship::section \
    "$SPACESHIP_NODE_COLOR" \
    "$SPACESHIP_NODE_PREFIX" \
    "${SPACESHIP_NODE_SYMBOL}${node_version}" \
    "$SPACESHIP_NODE_SUFFIX"
}
