# Configuration

Keep personal settings in `~/.config/worktrunk/config.toml`:

```toml
[projects."host/owner/repo"]
worktree-path = "{{ repo_path }}/.worktrees/{{ branch | sanitize }}"

[projects."host/owner/repo".pre-commit]
test = "..."
lint = "..."
```

Keep `.worktrees/` in the repository `.gitignore`. Do not overwrite unrelated
user configuration; approve hooks deliberately.
