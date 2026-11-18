# Commands

```sh
wt switch ^
wt switch --create <branch> --base ^ --no-cd
opencode --auto --prompt "Implement the task specification."
git add .
wt step commit
```

`--no-cd` keeps the calling shell in its current directory; run commands in the
new worktree explicitly. Use `^` for the detected default branch.
