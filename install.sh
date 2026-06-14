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
SETTINGS="${HOME}/.claude/settings.json"
HOOK_CMD="${DEST}/brain-nudge"

if [ ! -f "${SRC}/SKILL.md" ]; then
  echo "error: ${SRC}/SKILL.md not found — run this from inside the repo." >&2
  exit 1
fi

mkdir -p "${DEST}"
cp -R "${SRC}/." "${DEST}/"
echo "✓ Installed project-brain skill to ${DEST}"

# Register the brain-nudge Stop hook in settings.json.
# Skill-mode installs (unlike the plugin) don't get the hook wired automatically,
# so we MERGE it in: never overwrite existing settings (permissions, model, ...),
# idempotent (skip if already present), back up + show a diff before writing.
# Uses node (a hard dependency of Claude Code) so there's no jq requirement.
register_stop_hook() {
  if ! command -v node >/dev/null 2>&1; then
    echo "  ! node not found — skipping Stop-hook registration."
    echo "    Add it by hand: a Stop hook running ${HOOK_CMD}"
    return 0
  fi
  mkdir -p "$(dirname "$SETTINGS")"
  local tmp; tmp="$(mktemp)"
  local rc=0
  node - "$SETTINGS" "$HOOK_CMD" "$tmp" <<'NODE' || rc=$?
const fs = require('fs');
const [, , settingsPath, hookCmd, outPath] = process.argv;
let cfg = {};
try {
  const raw = fs.existsSync(settingsPath) ? fs.readFileSync(settingsPath, 'utf8').trim() : '';
  cfg = raw ? JSON.parse(raw) : {};
} catch (e) {
  process.exit(3); // existing settings.json is not valid JSON -> do not touch it
}
cfg.hooks = cfg.hooks || {};
let stop = Array.isArray(cfg.hooks.Stop) ? cfg.hooks.Stop
         : (cfg.hooks.Stop ? [cfg.hooks.Stop] : []);
if (JSON.stringify(stop).includes('brain-nudge')) process.exit(10); // already registered
stop.push({ hooks: [{ type: 'command', command: hookCmd }] });
cfg.hooks.Stop = stop;
fs.writeFileSync(outPath, JSON.stringify(cfg, null, 2) + '\n');
process.exit(0);
NODE
  case "$rc" in
    10) echo "  ✓ Stop hook already registered — settings.json unchanged"; rm -f "$tmp"; return 0 ;;
    3)  echo "  ! settings.json is not valid JSON — left untouched, hook not added"; rm -f "$tmp"; return 0 ;;
    0)  : ;;
    *)  echo "  ! hook registration failed (node rc=$rc) — settings.json left untouched"; rm -f "$tmp"; return 0 ;;
  esac
  echo "  + registering Project Brain Stop hook (brain-nudge):"
  echo "  --- settings.json diff ---"
  if [ -f "$SETTINGS" ]; then
    diff -u "$SETTINGS" "$tmp" | sed 's/^/    /' || true
  else
    echo "    (creating new settings.json)"
    sed 's/^/    /' "$tmp"
  fi
  [ -f "$SETTINGS" ] && cp "$SETTINGS" "${SETTINGS}.bak-$(date +%Y%m%d-%H%M%S)"
  mv "$tmp" "$SETTINGS"
  echo "  ✓ settings.json updated (previous version backed up)"
}
register_stop_hook

echo "  Start a Claude Code session and run:  /project-brain  (then 'init')"
