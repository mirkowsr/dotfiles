# Safety

- Never push, merge, remove worktrees, delete branches, reset, clean, or use
  other destructive commands.
- Stage with `git add .`, then use `wt step commit`, never plain `git commit`.
- Do not approve unknown hooks or install dependencies without explicit
  instruction.
- Confirm paths and current worktree before changing files.
