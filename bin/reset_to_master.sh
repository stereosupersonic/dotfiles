#!/usr/bin/env bash
# check_and_set_master.sh
# Checks all subdirectories (one level) for git repos
# and switches to master if confirmed.

set -euo pipefail

for dir in */; do
  # Skip if not a directory
  [ -d "$dir" ] || continue

  # Enter directory
  cd "$dir" || continue

  # Check if it's a git repo
  if [ -d ".git" ]; then
    echo "📁 Checking repo: $dir"
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

    if [ "$current_branch" != "master" ]; then
      echo "⚠️  Current branch is '$current_branch' (not master)"
      read -rp "Switch to 'master'? (y/N): " answer
      if [[ "$answer" =~ ^[Yy]$ ]]; then
        git fetch origin master >/dev/null 2>&1 || echo "⚠️ Could not fetch origin/master"
        git checkout master || echo "❌ Failed to switch branch in $dir"
        git pull origin master || echo "❌ Failed to pull latest changes in $dir"
        echo "✅ Switched to master in $dir"
      else
        echo "⏩ Skipping $dir"
      fi
    else
      echo "✅ Already on master"
    fi
  fi

  # Return to parent
  cd - >/dev/null || exit
  echo
done

echo "🎯 Done!"
