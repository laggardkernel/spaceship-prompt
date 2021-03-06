#
# Background jobs
#

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

SPACESHIP_JOBS_SHOW="${SPACESHIP_JOBS_SHOW=true}"
SPACESHIP_JOBS_PREFIX="${SPACESHIP_JOBS_PREFIX=""}"
SPACESHIP_JOBS_SUFFIX="${SPACESHIP_JOBS_SUFFIX=" "}"
SPACESHIP_JOBS_SYMBOL="${SPACESHIP_JOBS_SYMBOL="✦"}"
SPACESHIP_JOBS_COLOR="${SPACESHIP_JOBS_COLOR="blue"}"
SPACESHIP_JOBS_AMOUNT_PREFIX="${SPACESHIP_JOBS_AMOUNT_PREFIX=""}"
SPACESHIP_JOBS_AMOUNT_SUFFIX="${SPACESHIP_JOBS_AMOUNT_SUFFIX=""}"
SPACESHIP_JOBS_AMOUNT_THRESHOLD="${SPACESHIP_JOBS_AMOUNT_THRESHOLD=1}"
SPACESHIP_JOBS_EXPANDED="${SPACESHIP_JOBS_EXPANDED=false}"

# ------------------------------------------------------------------------------
# Section
# ------------------------------------------------------------------------------

# Show icon if there's a working jobs in the background
spaceship_jobs() {
  [[ $SPACESHIP_JOBS_SHOW == false ]] && return

  local jobs_running jobs_suspended jobs_total jobs_print

  jobs_running=${__SS_DATA[jobs_running]:-0}
  jobs_suspended=${__SS_DATA[jobs_suspended]:-0}
  jobs_total=$(( jobs_running + jobs_suspended ))

  (( $jobs_total > 0 )) || return

  if (( $jobs_total > $SPACESHIP_JOBS_AMOUNT_THRESHOLD )); then
    # display job count info
    if [[ "${(L)SPACESHIP_JOBS_EXPANDED}" == "true" ]]; then
      jobs_print="${jobs_running:-0}r ${jobs_suspended:-0}s"
    else
      jobs_print="${jobs_total}"
    fi
  else
    jobs_print=''
    SPACESHIP_JOBS_AMOUNT_PREFIX=''
    SPACESHIP_JOBS_AMOUNT_SUFFIX=''
  fi

  spaceship::section \
    "$SPACESHIP_JOBS_COLOR" \
    "$SPACESHIP_JOBS_PREFIX" \
    "${SPACESHIP_JOBS_SYMBOL}${SPACESHIP_JOBS_AMOUNT_PREFIX}${jobs_print}${SPACESHIP_JOBS_AMOUNT_SUFFIX}" \
    "$SPACESHIP_JOBS_SUFFIX"
}
