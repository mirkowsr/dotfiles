---
description: Create a Worktrunk task worktree
---

Use `$ARGUMENTS` for the task branch and prompt. Detect the repository default
branch and use `^`; never assume `main` or `master`. Create the worktree with:

`wt switch --create <branch> --base ^ --no-cd`

In the resulting worktree, provide launch guidance using
`opencode --auto --prompt "..."`. Do not push or merge.
