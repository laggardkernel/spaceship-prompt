#
# Vagrant
#
# Vagrant enables users to create and configure lightweight, reproducible, and portable development environments.
# Link: https://www.vagrantup.com

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

SPACESHIP_VAGRANT_SHOW="${SPACESHIP_VAGRANT_SHOW=true}"
SPACESHIP_VAGRANT_PREFIX="${SPACESHIP_VAGRANT_PREFIX="on "}"
SPACESHIP_VAGRANT_SUFFIX="${SPACESHIP_VAGRANT_SUFFIX="$SPACESHIP_PROMPT_DEFAULT_SUFFIX"}"
SPACESHIP_VAGRANT_SYMBOL="${SPACESHIP_VAGRANT_SYMBOL="Ｖ"}"
SPACESHIP_VAGRANT_COLOR_ON="${SPACESHIP_VAGRANT_COLOR_ON="27"}" # dodgerblue2
SPACESHIP_VAGRANT_COLOR_OFF="${SPACESHIP_VAGRANT_COLOR_OFF="247"}" # grey62
SPACESHIP_VAGRANT_COLOR_SUSPENDED="${SPACESHIP_VAGRANT_COLOR_SUSPENDED="214"}" # orange1
SPACESHIP_VAGRANT_COLOR=""
SPACESHIP_VAGRANT_SHOW_TEXT="${SPACESHIP_VAGRANT_SHOW_TEXT="true"}"

# ------------------------------------------------------------------------------
# Section
# ------------------------------------------------------------------------------

# Show current Vagrant status
spaceship_vagrant() {
  [[ $SPACESHIP_VAGRANT_SHOW == false ]] && return

  (( $+commands[vagrant] )) || return

  # Show Vagrant status only for Vagrant-specific folders
  local project_root=$(spaceship::upsearch "${VAGRANT_VAGRANTFILE:-Vagrantfile}")
  [[ -n $project_root ]] || return

  local vagrant_index="${VAGRANT_HOME:-$HOME/.vagrant.d}/data/machine-index/index"

  if (( $+commands[jq] )); then
    local vagrant_status=$(jq -r --arg dir "$project_root" '.machines[] | select(.vagrantfile_path == $dir).state' "$vagrant_index")
  else
    local vagrant_status=$(<"$vagrant_index" python -c 'import sys, os, json;
json_file = json.load(sys.stdin)["machines"]
for box in json_file:
  if (json_file[box]["vagrantfile_path"] == os.getcwd()):
    print (json_file[box]["state"])
    break;
')
  fi

  # possible status: running, poweroff(halt), saved(suspend)
  if [[ -z ${vagrant_status} ]]; then
    return
  elif [[ $vagrant_status == poweroff ]]; then
    SPACESHIP_VAGRANT_COLOR="$SPACESHIP_VAGRANT_COLOR_OFF"
  elif [[ $vagrant_status == running ]]; then
    SPACESHIP_VAGRANT_COLOR="$SPACESHIP_VAGRANT_COLOR_ON"
  elif [[ $vagrant_status == saved ]]; then
    SPACESHIP_VAGRANT_COLOR="$SPACESHIP_VAGRANT_COLOR_SUSPENDED"
  fi

  [[ $SPACESHIP_VAGRANT_SHOW_TEXT == "false" ]] && vagrant_status=""

  spaceship::section \
    "$SPACESHIP_VAGRANT_COLOR" \
    "$SPACESHIP_VAGRANT_PREFIX" \
    "${SPACESHIP_VAGRANT_SYMBOL}${vagrant_status}" \
    "$SPACESHIP_VAGRANT_SUFFIX"
}
