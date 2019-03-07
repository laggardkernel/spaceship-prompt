#
# Git
#

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

SPACESHIP_GIT_SHOW="${SPACESHIP_GIT_SHOW=true}"
SPACESHIP_GIT_PREFIX="${SPACESHIP_GIT_PREFIX="on "}"
SPACESHIP_GIT_SUFFIX="${SPACESHIP_GIT_SUFFIX="$SPACESHIP_PROMPT_DEFAULT_SUFFIX"}"
SPACESHIP_GIT_SYMBOL="${SPACESHIP_GIT_SYMBOL=" "}"

# ------------------------------------------------------------------------------
# Dependencies
# ------------------------------------------------------------------------------

source "$SPACESHIP_ROOT/sections/git_branch_async.zsh"
source "$SPACESHIP_ROOT/sections/git_status_async.zsh"

# ------------------------------------------------------------------------------
# Section
# ------------------------------------------------------------------------------

# Show both git branch and git status:
#   spaceship_git_branch_async
#   spaceship_git_status_async

spaceship_async_job_load_git_async() {
  [[ $SPACESHIP_GIT_SHOW == false ]] && return

  async_job spaceship spaceship_async_job_git_branch_async
  async_job spaceship spaceship_async_job_git_status_async
}

spaceship_git_async() {

  local git_branch=${SPACESHIP_ASYNC_RESULTS[spaceship_async_job_git_branch_async]}
  local git_status=${SPACESHIP_ASYNC_RESULTS[spaceship_async_job_git_status_async]}

  [[ -z $git_branch ]] && return

  spaceship::section \
    'white' \
    "$SPACESHIP_GIT_PREFIX" \
    "${git_branch}${git_status}" \
    "$SPACESHIP_GIT_SUFFIX"
}
