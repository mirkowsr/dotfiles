#!/bin/bash

set -euo pipefail

readonly DRY_RUN="${WT_SETUP_DRY_RUN:-0}"
readonly CONFIG_PATH="${WORKTRUNK_CONFIG_PATH:-${XDG_CONFIG_HOME:-$HOME/.config}/worktrunk/config.toml}"

case "${1:-}" in
  -h|--help)
    cat <<'EOF'
Usage: bash worktrunk/setup-project.sh [--help|-h]

Configure private Worktrunk settings for the current Git repository.

Options:
  -h, --help  Show this help and exit without inspecting project state.

Set WT_SETUP_DRY_RUN=1 to preview changes without writing them.
EOF
    exit 0
    ;;
esac

die() {
  printf 'worktrunk setup: %s\n' "$*" >&2
  exit 1
}

ask() {
  local prompt="$1"
  local answer
  if [ "$DRY_RUN" = 1 ]; then
    printf '%s [dry-run: yes]\n' "$prompt"
    return 0
  fi
  printf '%s [y/N] ' "$prompt"
  IFS= read -r answer || return 1
  case "$answer" in
    y|Y|yes|Yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

command -v git >/dev/null 2>&1 || die "git is required."
command -v wt >/dev/null 2>&1 || die "wt is required; run bash/setup-worktrunk.sh first."
repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" ||
  die "run this script from inside a Git repository."
cd "$repo_root"

wt_info="$(wt config show 2>&1)" || die "could not inspect Worktrunk configuration."
identifier="$(printf '%s\n' "$wt_info" | awk '/Identifier:/ { print $NF; exit }')"
[ -n "$identifier" ] || die "Worktrunk did not report a project identifier."

default_branch="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
default_branch="${default_branch#origin/}"
if [ -z "$default_branch" ]; then
  default_branch="$(git remote show origin 2>/dev/null |
    awk '/HEAD branch:/ { print $NF; exit }')"
fi
[ -n "$default_branch" ] || default_branch="(not detected; Worktrunk ^ remains authoritative)"

printf 'Repository: %s\nProject identifier: %s\nDetected default branch: %s\n' \
  "$repo_root" "$identifier" "$default_branch"

worktree_path='{{ repo_path }}/.worktrees/{{ branch | sanitize }}'
printf 'Suggested private worktree path: %s\n' "$worktree_path"

declare -a hook_names=()
declare -a hook_commands=()
add_hook() {
  local name="$1"
  local command="$2"
  local existing
  for existing in "${hook_names[@]-}"; do
    [ "$existing" = "$name" ] && return
  done
  hook_names+=("$name")
  hook_commands+=("$command")
}

if [ -f package.json ]; then
  while IFS=$'\t' read -r name command; do
    [ -n "$name" ] && add_hook "$name" "$command"
  done < <(python3 - <<'PY'
import json
from pathlib import Path

try:
    scripts = json.loads(Path("package.json").read_text()).get("scripts", {})
except (OSError, ValueError):
    scripts = {}
for key in ("test", "lint", "typecheck", "type-check"):
    if key in scripts:
        normalized = "typecheck" if key == "type-check" else key
        print(f"{normalized}\tnpm run {key}")
PY
  )
fi

if [ -f Makefile ]; then
  for name in test lint typecheck; do
    if grep -Eq "^${name}([[:space:]]|:)" Makefile; then
      add_hook "$name" "make $name"
    fi
  done
fi
[ -f Cargo.toml ] && add_hook test "cargo test"
[ -f go.mod ] && add_hook test "go test ./..."
if [ -f pyproject.toml ] || [ -f pytest.ini ] || [ -f setup.cfg ]; then
  [ -d tests ] || [ -d test ] && add_hook test "pytest"
  grep -Eq '(^|\[)tool\.(ruff|pylint)|\[flake8\]' pyproject.toml setup.cfg 2>/dev/null &&
    add_hook lint "ruff check ." || true
fi

if [ "${#hook_names[@]}" -eq 0 ]; then
  printf 'No common test, lint, or typecheck commands were detected.\n'
else
  printf 'Detected candidate hooks:\n'
  for i in "${!hook_names[@]}"; do
    printf '  %s = %s\n' "${hook_names[$i]}" "${hook_commands[$i]}"
  done
fi

gitignore_path="$repo_root/.gitignore"
gitignore_change=0
if grep -qxF '.worktrees/' "$gitignore_path" 2>/dev/null; then
  printf '.worktrees/ is already present in .gitignore.\n'
else
  if ask "Add .worktrees/ to $gitignore_path?"; then
    gitignore_change=1
  fi
fi

selected_hooks=()
selected_commands=()
for i in "${!hook_names[@]}"; do
  if ask "Configure ${hook_names[$i]} hook (${hook_commands[$i]})?"; then
    selected_hooks+=("${hook_names[$i]}")
    selected_commands+=("${hook_commands[$i]}")
  fi
done

printf '\nPrivate config preview (%s):\n' "$CONFIG_PATH"
printf '[projects."%s"]\nworktree-path = "%s"\n' "$identifier" "$worktree_path"
if [ "${#selected_hooks[@]}" -gt 0 ]; then
  printf '[projects."%s".pre-commit]\n' "$identifier"
  for i in "${!selected_hooks[@]}"; do
    printf '%s = %s\n' "${selected_hooks[$i]}" "${selected_commands[$i]}"
  done
fi

if [ "$DRY_RUN" = 1 ]; then
  printf 'Dry run: private Worktrunk configuration not written.\n'
elif ! ask "Write this private Worktrunk configuration?"; then
  printf 'No private Worktrunk configuration written.\n'
else
  mkdir -p "$(dirname "$CONFIG_PATH")"
  hook_args=()
  for i in "${!selected_hooks[@]}"; do
    hook_args+=("${selected_hooks[$i]}" "${selected_commands[$i]}")
  done
  WT_SETUP_CONFIG_PATH="$CONFIG_PATH" PROJECT_ID="$identifier" WORKTREE_PATH="$worktree_path" \
    python3 - "${hook_args[@]}" <<'PY'
import json
import os
import re
import sys
import tempfile
import tomllib
from pathlib import Path

path = Path(os.environ["WT_SETUP_CONFIG_PATH"])
text = path.read_text() if path.exists() else ""
try:
    data = tomllib.loads(text)
except tomllib.TOMLDecodeError as exc:
    raise SystemExit(f"refusing to edit invalid TOML in {path}: {exc}")

project = os.environ["PROJECT_ID"]
worktree = os.environ["WORKTREE_PATH"]
hooks = dict(zip(sys.argv[1::2], sys.argv[2::2]))
project_key = f'projects."{project}"'
header = f'[{project_key}]'
project_data = data.get("projects", {}).get(project, {})
if not isinstance(project_data, dict):
    raise SystemExit(f"refusing to edit unexpected project entry: {project}")

def section_end(source, start):
    match = re.search(r"(?m)^\[", source[start:])
    return start + match.start() if match else len(source)

if not text:
    text = f'{header}\nworktree-path = {json.dumps(worktree)}\n'
elif header not in text:
    text = text.rstrip() + f'\n\n{header}\nworktree-path = {json.dumps(worktree)}\n'
elif "worktree-path" not in project_data:
    match = re.search(rf"(?m)^{re.escape(header)}\s*$", text)
    if not match:
        raise SystemExit("refusing to edit an ambiguous project table.")
    position = section_end(text, match.end())
    text = text[:position] + f'worktree-path = {json.dumps(worktree)}\n' + text[position:]

if hooks:
    precommit = project_data.get("pre-commit", {})
    if precommit and not isinstance(precommit, dict):
        raise SystemExit("refusing to merge non-table pre-commit hooks.")
    hook_header = f'{project_key}.pre-commit'
    existing_hook = re.search(rf"(?m)^\[{re.escape(hook_header)}\]\s*$", text)
    if not precommit and existing_hook is None:
        additions = f'\n[{hook_header}]\n'
        additions += "".join(f'{name} = {json.dumps(command)}\n' for name, command in hooks.items())
        text = text.rstrip() + additions
    else:
        match = existing_hook
        if not match:
            raise SystemExit("refusing to locate the existing pre-commit table.")
        missing = [(n, c) for n, c in hooks.items() if n not in precommit]
        position = section_end(text, match.end())
        text = text[:position] + "".join(
            f'{name} = {json.dumps(command)}\n' for name, command in missing
        ) + text[position:]

try:
    tomllib.loads(text)
except tomllib.TOMLDecodeError as exc:
    raise SystemExit(f"refusing to write invalid merged TOML: {exc}")
path.parent.mkdir(parents=True, exist_ok=True)
fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent, text=True)
try:
    with os.fdopen(fd, "w") as output:
        output.write(text.rstrip() + "\n")
    os.replace(temporary, path)
except BaseException:
    Path(temporary).unlink(missing_ok=True)
    raise
PY
  printf 'Private Worktrunk configuration updated.\n'
fi

if [ "$gitignore_change" -eq 1 ]; then
  printf '\n.gitignore preview:\n.worktrees/\n'
  if [ "$DRY_RUN" = 1 ]; then
    printf 'Dry run: .gitignore not updated.\n'
  elif ask "Write .worktrees/ to $gitignore_path?"; then
    if [ -s "$gitignore_path" ] && [ "$(tail -c 1 "$gitignore_path" | wc -l)" -eq 0 ]; then
      printf '\n' >> "$gitignore_path"
    fi
    printf '.worktrees/\n' >> "$gitignore_path"
    printf '.gitignore updated.\n'
  else
    printf '.gitignore unchanged.\n'
  fi
fi

printf 'Setup complete. Hooks remain subject to Worktrunk approval.\n'
