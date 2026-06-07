#!/usr/bin/env bash
# Project Brain — persistent project memory for Claude Code.
# Author: Slawomir Luzny <info@fixflex.co.uk> (https://fixflex.co.uk) — MIT licensed.
# Repo:   https://github.com/OoneBreath/claude-code-project-brain
#
# Install the project-brain skill for Claude Code (personal scope).
# Re-run any time to update. Run on every machine where you use Claude Code.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skills/project-brain"
DEST="${HOME}/.claude/skills/project-brain"

if [ ! -f "${SRC}/SKILL.md" ]; then
  echo "error: ${SRC}/SKILL.md not found — run this from inside the repo." >&2
  exit 1
fi

mkdir -p "${DEST}"
cp -R "${SRC}/." "${DEST}/"

echo "✓ Installed project-brain skill to ${DEST}"
echo "  Start a Claude Code session and run:  /project-brain  (then 'init')"
