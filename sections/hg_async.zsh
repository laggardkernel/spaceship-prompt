#
# Mercurial (hg)
#

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

SPACESHIP_HG_SHOW="${SPACESHIP_HG_SHOW=true}"
SPACESHIP_HG_PREFIX="${SPACESHIP_HG_PREFIX="on "}"
SPACESHIP_HG_SUFFIX="${SPACESHIP_HG_SUFFIX="$SPACESHIP_PROMPT_DEFAULT_SUFFIX"}"
SPACESHIP_HG_SYMBOL="${SPACESHIP_HG_SYMBOL="☿ "}"

# ------------------------------------------------------------------------------
# Dependencies
# ------------------------------------------------------------------------------

source "$SPACESHIP_ROOT/sections/hg_branch_async.zsh"
source "$SPACESHIP_ROOT/sections/hg_status_async.zsh"

# ------------------------------------------------------------------------------
# Section
# ------------------------------------------------------------------------------

# Show both hg branch and hg status:
#   spaceship_hg_branch_async
#   spaceship_hg_status_async

spaceship_async_job_load_hg_async() {
  [[ $SPACESHIP_HG_SHOW == false ]] && return

  async_job spaceship spaceship_async_job_hg_branch_async
  async_job spaceship spaceship_async_job_hg_status_async
}

spaceship_hg_async() {

  local hg_branch="${SPACESHIP_ASYNC_RESULTS[spaceship_async_job_hg_branch_async]}"
  local hg_status="${SPACESHIP_ASYNC_RESULTS[spaceship_async_job_hg_status_async]}"

  [[ -z $hg_branch ]] && return

  spaceship::section \
    'white' \
    "$SPACESHIP_HG_PREFIX" \
    "${hg_branch}${hg_status}" \
    "$SPACESHIP_HG_SUFFIX"
}
