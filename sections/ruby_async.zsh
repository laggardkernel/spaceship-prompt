#
# Ruby
#
# A dynamic, reflective, object-oriented, general-purpose programming language.
# Link: https://www.ruby-lang.org/

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

SPACESHIP_RUBY_SHOW="${SPACESHIP_RUBY_SHOW=true}"
SPACESHIP_RUBY_PREFIX="${SPACESHIP_RUBY_PREFIX="$SPACESHIP_PROMPT_DEFAULT_PREFIX"}"
SPACESHIP_RUBY_SUFFIX="${SPACESHIP_RUBY_SUFFIX="$SPACESHIP_PROMPT_DEFAULT_SUFFIX"}"
SPACESHIP_RUBY_SYMBOL="${SPACESHIP_RUBY_SYMBOL="💎 "}"
SPACESHIP_RUBY_COLOR="${SPACESHIP_RUBY_COLOR="red"}"

# ------------------------------------------------------------------------------
# Section
# ------------------------------------------------------------------------------

spaceship_async_job_load_ruby_async() {
  [[ $SPACESHIP_RUBY_SHOW == false ]] && return

  (( $+commands[rbenv] )) || (( $+commands[rvm-prompt] )) \
    || (( $+commands[chruby] )) || (( $+commands[asdf] )) \
    || return

  # Show versions only for Ruby-specific folders
  spaceship::upsearch "Gemfile" >/dev/null \
    || spaceship::upsearch "Rakefile" >/dev/null \
    || [[ -n *.rb(#qN^/) ]] || return

  async_job spaceship spaceship_async_job_ruby_async
}

spaceship_async_job_ruby_async() {
  local ruby_version=""

  if (( $+commands[rbenv] )); then
    ruby_version=$(rbenv version-name)
  elif (( $+commands[rvm-prompt] )); then
    ruby_version=$(rvm-prompt i v g)
  elif (( $+commands[chruby] )); then
    ruby_version=$(chruby | sed -n -e 's/ \* //p')
  elif (( $+commands[asdf] )); then
    # split output on space and return first element
    ruby_version=${$(asdf current ruby)[1]}
  fi

  echo "$ruby_version"
}
# Show current version of Ruby
spaceship_ruby_async() {
  [[ $SPACESHIP_RUBY_SHOW == false ]] && return

  local ruby_version

  # RBENV_VERSION precedes over others
  if [[ -z "${ruby_version:=$RBENV_VERSION}" ]]; then
    ruby_version="${SPACESHIP_ASYNC_RESULTS[spaceship_async_job_ruby_async]}"
  fi

  if [[ -z $ruby_version ]] || [[ $ruby_version == "system" ]]; then
    return
  fi

  [[ -z $ruby_version || "${ruby_version}" == "system" ]] && return

  spaceship::section \
    "$SPACESHIP_RUBY_COLOR" \
    "$SPACESHIP_RUBY_PREFIX" \
    "${SPACESHIP_RUBY_SYMBOL}${ruby_version}" \
    "$SPACESHIP_RUBY_SUFFIX"
}
