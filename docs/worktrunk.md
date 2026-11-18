# Worktrunk workflow

- The dotfiles-managed configuration is symlinked to
  `~/.config/worktrunk/config.toml`.
- For `github.com/allegro-internal/opbox-allegro-installments`, it creates
  sibling worktrees under `<repo>-worktrees/<branch>`, outside the repository.
  Generated worktrees therefore do not need a project `.gitignore` entry.
- Detect and switch to the default branch with `wt switch ^`. Do not assume
  it is named `main` or `master`.
- On the default branch, write the task specification and commit it before
  creating the task worktree.
- Create a task worktree without changing the current shell directory:

  ```sh
  wt switch --create <branch> --base ^ --no-cd
  ```

  `--no-cd` prevents Worktrunk from changing the calling shell's directory;
  launch commands in the resulting worktree explicitly.
- Launch an interactive OpenCode session in a new worktree:

  ```sh
  cd ~/code/myapp
  wt switch --create add-authentication \
    --base ^ \
    --no-cd \
    -x opencode -- \
    --auto \
    --prompt "Implement docs/tasks/add-authentication.md"
  ```

  Here, `--base ^` uses the detected default branch, `--no-cd` keeps the
  calling shell where it is, and `-x opencode` launches OpenCode in the new
  worktree. The first `--` separates Worktrunk arguments from OpenCode
  arguments. OpenCode `--auto` approves permissions not explicitly denied,
  and `--prompt` provides the initial task. Select the agent interactively
  through `/agents`; do not use an interactive `--agent` flag.
- Choose an alternate worktree base when needed:
  - `--base @` uses the current branch/worktree and supports stacked worktrees.
  - `--base <branch>` uses a specific branch.
  - `--base -` uses the previous worktree.
  - `--base pr:123` and `--base mr:456` support PR/MR branches.

  For example, create a stacked worktree from the current worktree:

  ```sh
  wt switch --create add-tests --base @ --no-cd
  ```

  Specifications normally live on the detected default branch, while
  implementation work may intentionally branch from another base.
- From the task worktree, launch OpenCode with an explicit prompt:

  ```sh
  opencode --auto --prompt "Implement the task specification."
  ```

- Let the technical-support agent handle ports and development servers.
- Before committing, run the project's pre-commit checks. Then stage and
  commit local changes with:

  ```sh
  git add .
  wt step commit
  ```

- Keep one separate pull request per worktree.
- The user manually handles publishing a reviewed task branch to a separate
  pull request branch, if needed, and removes completed worktrees.
- Safety restrictions: do not push, merge, remove, reset, clean, or run other
  destructive commands. The agent may prepare and commit local changes only.
