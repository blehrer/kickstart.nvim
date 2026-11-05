-- Only attach in PKM vaults; upstream includes `.git` and wedges non-vault repos on open.
return {
  root_markers = { '.obsidian', '.moxide.toml' },
  workspace_required = true,
}
