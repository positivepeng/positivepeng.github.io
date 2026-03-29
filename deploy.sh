#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PUBLIC_DIR="$ROOT_DIR/public"
TMP_DIR="$(mktemp -d)"
WORKTREE_DIR="$TMP_DIR/gh-pages"
COMMIT_MSG="${1:-Publish site}"

cleanup() {
  if git -C "$ROOT_DIR" worktree list | grep -Fq "$WORKTREE_DIR"; then
    git -C "$ROOT_DIR" worktree remove --force "$WORKTREE_DIR" >/dev/null 2>&1 || true
  fi
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "Committing and pushing main branch..."
cd "$ROOT_DIR"
git add -A
if git diff --cached --quiet; then
  echo "No changes to commit on main."
else
  git commit -m "$COMMIT_MSG"
  git push origin main
fi

echo "Building site from main..."
hugo --source "$ROOT_DIR" --destination "$PUBLIC_DIR" --cleanDestinationDir

if [ ! -f "$PUBLIC_DIR/index.html" ]; then
  echo "Build check failed: public/index.html not found"
  exit 1
fi

if ! grep -q "busuanzi_value_site_pv" "$PUBLIC_DIR/index.html"; then
  echo "Build check failed: busuanzi marker missing in public/index.html"
  exit 1
fi

echo "Preparing gh-pages worktree..."
git -C "$ROOT_DIR" show-ref --verify --quiet refs/heads/gh-pages || {
  echo "Branch gh-pages not found locally. Run: git branch gh-pages origin/gh-pages"
  exit 1
}

git -C "$ROOT_DIR" worktree add --force "$WORKTREE_DIR" gh-pages >/dev/null

echo "Syncing built files to gh-pages..."
rsync -a --delete --exclude ".git" "$PUBLIC_DIR/" "$WORKTREE_DIR/"

cd "$WORKTREE_DIR"
git add -A

# if git diff --cached --quiet; then
#   echo "No changes to publish."
#   exit 0
# fi

git commit -m "$COMMIT_MSG"
git push origin gh-pages

echo "Publish completed: gh-pages updated."
