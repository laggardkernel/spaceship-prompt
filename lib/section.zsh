#!/usr/bin/env zsh
# vim:ft=zsh ts=2 sw=2 sts=2 et fenc=utf-8

# Internal variable for checking if prompt is opened
spaceship_prompt_opened="$SPACESHIP_PROMPT_FIRST_PREFIX_SHOW"

# Draw prompt section (bold is used as default)
# USAGE:
#   spaceship::section <color> [prefix] <content> [suffix]
spaceship::section() {
  local color prefix content suffix
  [[ -n $1 ]] && color="%F{$1}"  || color="%f"
  [[ -n $2 ]] && prefix="$2"     || prefix=""
  [[ -n $3 ]] && content="$3"    || content=""
  [[ -n $4 ]] && suffix="$4"     || suffix=""

  [[ -z $3 && -z $4 ]] && content=$2 prefix=''

  local result=""

  result+="%{%B%}" # set bold
  if [[ $spaceship_prompt_opened == true ]] && [[ $SPACESHIP_PROMPT_PREFIXES_SHOW == true ]]; then
    restult+="$prefix"
  fi
  spaceship_prompt_opened=true
  result+="%{%b%}" # unset bold

  result+="%{%B$color%}" # set color
  result+="$content"     # section content
  result+="%{%b%f%}"     # unset color

  result+="%{%B%}" # reset bold, if it was diabled before
  if [[ $SPACESHIP_PROMPT_SUFFIXES_SHOW == true ]]; then
    result+="$suffix"
  fi
  result+="%{%b%}" # unset bold

  echo -n "$result"
}

# Wrapper keeps alignment and index info for section functions
#
# @args
#   $1 string The command to execute
#   $2 string Section name
#   $3 string Alignment
#   $4 index Index
spaceship::async_wrapper() {
  local command="$1"

  echo -n "${2}·|·${3}·|·${4}·|·"
  ${command} ${3} ${4}
}

# Build prompt cache from section functions
# @description
#   This function loops through the prompt elements and calls
#   the related section functions.
#
# @args
#   $1 string left|right
spaceship::build_section_cache() {
  # Option EXTENDED_GLOB is set locally to force filename generation on
  # argument to conditions, i.e. allow usage of explicit glob qualifier (#q).
  # See the description of filename generation in
  # http://zsh.sourceforge.net/Doc/Release/Conditional-Expressions.html
  setopt EXTENDED_GLOB LOCAL_OPTIONS

  local -a alignments=("prompt" "rprompt")
  local sections_var
  local -a raw_sections
  local custom async section cache_key result
  local index

  [[ -n $1 ]] && alignments=("$1")

  for alignment in "${alignments[@]}"; do
    sections_var="SPACESHIP_${(U)alignment}_ORDER"
    raw_sections=(${(P)sections_var})

    # reload the sections once prompt order arrary is changed
    if [[ "${__ss_data[${alignment}_raw_sections]}" != "${raw_sections[*]}" ]]; then
      prompt_spaceship_teardown
      spaceship::load_sections "$alignment"
      prompt_spaceship_setup
      # always recompose the prompt. Cause the sections may be invalid and removed,
      # in that case we need to redo the iteration on current prompt order array
      spaceship::build_section_cache "$1"
      return
    fi

    index=1
    for section in ${=__ss_data[${alignment}_sections]}; do
      cache_key="${alignment}::${index}"

      spaceship::section_is_tagged_as "async" "${section}" "${alignment}" && async=true || async=false

      if ${async}; then
        async_job "spaceship_async_worker" "spaceship::async_wrapper" "spaceship_${section}" "${section}" "${alignment}" "${index}"

        # Placeholder
        __ss_section_cache[${cache_key}]="${section}·|·${alignment}·|·${index}·|·${SPACESHIP_SECTION_PLACEHOLDER}"
      else
        # Pass the alignment and index to the real section func in case that
        # the section func needs to know its position in the left/right prompt.
        # E.g. trigger re-rendering from vi_mode

        # Trick needed: keep single newline from section line_sep
        # https://unix.stackexchange.com/a/248229/246718
        result="$(spaceship_${section} ${alignment} ${index}; echo 'x')"
        result="${result%?}"
        __ss_section_cache[${cache_key}]="${section}·|·${alignment}·|·${index}·|·${result}"
      fi

    index=$((index + 1))
    done
  done

  spaceship::render
}

# Refresh a single item in the cache, and redraw the prompt
#
# @args
#   $1 - string, section name
#   $2 - boolean, true if render the prompt after cache update
spaceship::refresh_cache_item() {
  local section="$1"
  local alignment index cache_key result

  for alignment in "prompt" "rprompt"; do
    for index in $(spaceship::find_in_array "${section}" "${__ss_data[${alignment}_sections]}"); do

      cache_key="${alignment}::${index}"

      spaceship::section_is_tagged_as "async" "${section}" "${alignment}" && async=true || async=false

      if ${async}; then
        async_job "spaceship_async_worker" "spaceship::async_wrapper" "spaceship_${section}" "${section}" "${alignment}" "${index}"

        __ss_section_cache[${cache_key}]="${section}·|·${alignment}·|·${index}·|·${SPACESHIP_SECTION_PLACEHOLDER}"

        # Async callback decides whether to trigger a re-rendering automatically
      else
        result="$(spaceship_${section} ${alignment} ${index}; echo 'x')"
        result="${result%?}"
        __ss_section_cache[${cache_key}]="${section}·|·${alignment}·|·${index}·|·${result}"
      fi
    done
  done
  [[ "$async" != "true" ]] && [[ "$2" == "true" ]] && spaceship::render
}

# Exchange result of prompt_<section> function in the cache and
# trigger re-rendering of prompt.
#
# @args
#   $1 job name, e.g. the function passed to async_job
#   $2 return code
#   $3 resulting (stdout) output from job execution
#   $4 execution time, floating point e.g. 0.0076138973 seconds
#   $5 resulting (stderr) error output from job execution
#   $6 has next result in buffer (0 = buffer empty, 1 = yes)
spaceship::async_callback() {
  local job="$1" ret="$2" output="$3" exec_time="$4" err="$5" has_next="$6"
  local section_meta cache_key

  # ignore the async evals used to alter worker environment
  if [[ "${job}" == "[async/eval]" ]] || \
     [[ "${job}" == ";" ]] || \
     [[ "${job}" == "[async]" ]]; then
    return
  fi

  # split input $output into an array - see https://unix.stackexchange.com/a/28873
  section_meta=("${(@s:·|·:)output}") # split on delimiter "·|·" (@s:<delim>:)
  cache_key="${section_meta[2]}::${section_meta[3]}"

  # Skip prompt re-rendering if both placeholder and section content are empty,
  # or section cache is unchanged
  if [[ "$SPACESHIP_SECTION_PLACEHOLDER" == "${section_meta[4]}" ]] \
    || [[ "${__ss_section_cache[${cache_key}]}" == "$output" ]]; then
    return
  else
    __ss_section_cache[${cache_key}]="${output}"
  fi

  # Delay prompt updates if there's another result in the buffer, which
  # prevents strange states in ZLE
  [[ "$has_next" == "0" ]] && spaceship::render "true"
}

# Spaceship Render function.
# Goes through cache and renders each entry.
#
# @args
#   $1 - boolean True if rendered through ZLE widget (in async mode)
spaceship::render() {
  local RPROMPT_PREFIX RPROMPT_SUFFIX
  local -a section_meta
  local alignment cache_key

  # Reset prompt storage
  __ss_unsafe[prompt]=""
  __ss_unsafe[rprompt]=""

  # Process cache
  for cache_key in "${(o@kn)__ss_section_cache}"; do
    section_meta=("${(@s:·|·:)${__ss_section_cache[$cache_key]}}")

    [[ -z "${section_meta[4]}" ]] && continue # Skip if section is empty

    __ss_unsafe[${section_meta[2]}]+="${section_meta[4]}"
  done

  # Left: PROMPT
  # Allow iTerm integration to work
  [[ "${ITERM_SHELL_INTEGRATION_INSTALLED:-}" == "Yes" ]] \
    && __ss_unsafe[prompt]="%{$(iterm2_prompt_mark)%}${__ss_unsafe[prompt]}"

  local NEWLINE=$'\n'

  [[ "$SPACESHIP_PROMPT_ADD_NEWLINE" == true ]] \
    && __ss_unsafe[prompt]="$NEWLINE${__ss_unsafe[prompt]}"

  # By evaluating $__ss_unsafe[prompt] here in __ss_render we avoid
  # the evaluation of $PROMPT being interrupted.
  # For security $PROMPT is never set directly. This way the prompt render is
  # forced to evaluate the variable and the contents of $__ss_unsafe[prompt]
  # are never executed. The same applies to $RPROMPT.
  PROMPT='${__ss_unsafe[prompt]}'

  # Right: RPROMPT
  if [[ "$SPACESHIP_RPROMPT_ON_NEWLINE" != true ]]; then
    # The right prompt should be on the same line as the first line of the left
    # prompt. To do so, there is just a quite ugly workaround: Before zsh draws
    # the RPROMPT, we advise it, to go one line up. At the end of RPROMPT, we
    # advise it to go one line down. See:
    # http://superuser.com/questions/357107/zsh-right-justify-in-ps1
    RPROMPT_PREFIX='%{'$'\e[1A''%}' # one line up
    RPROMPT_SUFFIX='%{'$'\e[1B''%}' # one line down
    __ss_unsafe[rprompt]="${RPROMPT_PREFIX}${__ss_unsafe[rprompt]}${RPROMPT_SUFFIX}"
  fi
  RPROMPT='${__ss_unsafe[rprompt]}'

  # .reset-prompt: bypass the zsh-syntax-highlighting wrapper
  # https://github.com/sorin-ionescu/prezto/issues/1026
  # https://github.com/zsh-users/zsh-autosuggestions/issues/107#issuecomment-183824034
  [[ "$1" == "true" ]] && zle .reset-prompt && zle -R
}

# PS2
# Continuation interactive prompt
spaceship_ps2() {
  local char="${SPACESHIP_CHAR_SYMBOL_SECONDARY="$SPACESHIP_CHAR_SYMBOL"}"
  spaceship::section "$SPACESHIP_CHAR_COLOR_SECONDARY" "$char"
}

# ------------------------------------------------------------------------------
# SETUP
# Setup requirements for prompt
# ------------------------------------------------------------------------------

# Runs once when user opens a terminal
# All preparation before drawing prompt should be done here
prompt_spaceship_setup() {
  # Global section cache
  typeset -gAh __ss_section_cache=()

  # __ss_unsafe must be a global variable, because we set
  # PROMPT='$__ss_unsafe[left]', so without letting ZSH
  # expand this value (single quotes). This is a workaround
  # to avoid double expansion of the contents of the PROMPT.
  typeset -gAh __ss_unsafe=()

  # The value below was set to better support 32-bit CPUs.
  # It's the maximum _signed_ integer value on 32-bit CPUs.
  # Please don't change it until 19 January of 2038. ;)

  # Disable false display of command execution time
  SPACESHIP_EXEC_TIME_start=0x7FFFFFFF

  # This variable is a magic variable used when loading themes with zsh's prompt
  # function. It will ensure the proper prompt options are set.
  prompt_opts=(cr percent sp subst)

  # Borrowed from promptinit, sets the prompt options in case the prompt was not
  # initialized via promptinit.
  setopt noprompt{bang,cr,percent,subst} "prompt${^prompt_opts[@]}"

  # initialize timing functions
  zmodload zsh/datetime

  # Initialize math functions
  zmodload zsh/mathfunc

  # initialize hooks
  autoload -Uz add-zsh-hook

  add-zsh-hook precmd spaceship::precmd

  # Add exec_time hooks
  add-zsh-hook preexec spaceship::preexec

  # hook into chpwd for bindkey support
  add-zsh-hook chpwd spaceship::chpwd

  # Disable python virtualenv environment prompt prefix
  VIRTUAL_ENV_DISABLE_PROMPT=true

  # Expose Spaceship to environment variables
  PS2='$(spaceship_ps2)'
}

# This function removes spaceship hooks and resets the prompts.
prompt_spaceship_teardown() {
  add-zsh-hook -D precmd spaceship\*
  add-zsh-hook -D preexec spaceship\*
  add-zsh-hook -D chpwd spaceship\*
  PROMPT='%m%# '
  RPROMPT=
  PS2='%_> '
  unset __ss_section_cache
  unset __ss_unsafe
}
