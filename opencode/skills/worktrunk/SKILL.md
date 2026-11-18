---
name: worktrunk
description: Safe Worktrunk workflows for OpenCode task worktrees.
---

# Worktrunk

- Detect the default branch and use `^`; never assume `main` or `master`.
- On the default branch, write and commit the task specification before creating a worktree.
- Use one worktree per task or PR.
- Create without changing the caller's directory: `wt switch --create <branch> --base ^ --no-cd`.
- In the resulting worktree, launch `opencode --auto --prompt "..."`.
- Ask the technical-support agent to handle ports and dev servers.
- Run checks, then `git add .` followed by `wt step commit`; do not use plain `git commit`.
- Do not push, merge, remove worktrees, or run destructive commands.
- Read `references/` only when the detail is needed.
