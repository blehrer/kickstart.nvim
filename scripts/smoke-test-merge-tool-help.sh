#!/usr/bin/env bash
# Simulates a git mergetool session and smoke-tests merge-tool-help.
set -euo pipefail

CONFIG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/local" <<'EOF'
line one
line two local
line three
EOF

cat > "$TMP/base" <<'EOF'
line one
line two
line three
EOF

cat > "$TMP/remote" <<'EOF'
line one
line two remote
line three
EOF

cat > "$TMP/merged" <<'EOF'
line one
<<<<<<< LOCAL
line two local
=======
line two remote
>>>>>>> REMOTE
line three
EOF

export LOCAL="$TMP/local"
export BASE="$TMP/base"
export REMOTE="$TMP/remote"
export MERGED="$TMP/merged"

NVIM="nvim"
if ! command -v nvim >/dev/null 2>&1; then
  echo "nvim not found, skipping"
  exit 0
fi

"$NVIM" --headless \
  -u "$CONFIG_ROOT/init.lua" \
  -c "edit $LOCAL | vnew $BASE | vnew $REMOTE | belowright split $MERGED | windo diffthis" \
  -c "lua local d=require('merge-tool-help.detect'); assert(d.is_session(), 'session'); assert(d.role_of_buf(1)=='LOCAL' or d.role_of_buf(vim.fn.bufnr('$LOCAL'))=='LOCAL', 'local role'); assert(d.has_conflict_markers(vim.fn.bufnr('$MERGED')), 'markers');" \
  -c "lua local l=require('merge-tool-help.layout'); local x=l.get_layout(nil, vim.api.nvim_get_current_win()); assert(#x.slots>=2, 'slots');" \
  -c "lua local r=require('merge-tool-help.render'); local tree={type='leaf',slot={index=1}}; local lines=r.render_tree(tree,1,1); assert(#lines>0,'render');" \
  -c "qa!"

echo "merge-tool-help smoke test passed"
