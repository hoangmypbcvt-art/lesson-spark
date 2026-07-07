#!/usr/bin/env bash
# Stop hook: after Claude finishes a turn in this project, if there are
# uncommitted changes and lint passes, auto-commit + push to origin/main.
# Vercel is connected to this GitHub repo and redeploys on push automatically.
set -uo pipefail
cd "/d/Hoc tao app/lesson-spark-main/lesson-spark-main" || exit 0

LOG="/tmp/claude-autopush.log"
{
  echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="

  if [ -z "$(git status --porcelain 2>/dev/null)" ]; then
    echo "no changes, skipping"
    exit 0
  fi

  if ! bun run lint; then
    echo "lint failed, skipping auto-push"
    exit 0
  fi

  git add -A
  git commit -q -m "Auto-update $(date -u +%Y-%m-%dT%H:%M:%SZ)"

  if git push origin main; then
    echo "pushed to origin/main"
  else
    echo "push failed (check git credentials / remote)"
  fi
} >> "$LOG" 2>&1
