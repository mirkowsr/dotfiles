if [[ -n "${BASH_VERSION:-}" ]] &&
  command -v wt >/dev/null 2>&1 &&
  [[ -z "${_WORKTRUNK_BASH_INIT:-}" ]]; then
  eval "$(wt config shell init bash)"
  _WORKTRUNK_BASH_INIT=1
fi
