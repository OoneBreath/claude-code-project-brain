#!/usr/bin/env bash
# brain-check --fix: regenerates a missing/stale index.compact, and rotates a project's
# _session.md past 5 active lines into _session.cold.md (newest-first order preserved
# across both files). Locks in both behaviors + idempotency (second --fix = no-op).
set -euo pipefail

SKILL="$(cd "$(dirname "${BASH_SOURCE[0]}")/../skills/project-brain" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

BRAIN="$TMP/.project-brain"
mkdir -p "$BRAIN/projects/acme"

cat > "$BRAIN/index.md" <<'EOF'
# Project Brain — index

## acme  (Go)
- cache → cache notes  [✓ verified 2026-01-10 · v1] → projects/acme/cache.md
EOF

cat > "$BRAIN/projects/acme/cache.md" <<'EOF'
---
project: acme
topic: cache
status: verified
last_done: 2026-01-10
version: 1
---
Cache invalidation notes long enough to not be a thin topic. Padding padding padding
padding padding padding padding padding padding padding padding padding padding padding
padding padding padding padding padding padding padding padding padding padding padding.
EOF

cat > "$BRAIN/projects/acme/_session.md" <<'EOF'
# Session log — acme (newest first; keep to 5)

> resume 2026-08-16 · done: e8 (newest) · next: x · blocker: none

> resume 2026-08-10 · done: e7 · next: x · blocker: none

> resume 2026-08-05 · done: e6 · next: x · blocker: none

> resume 2026-08-01 · done: e5 · next: x · blocker: none

> resume 2026-07-20 · done: e4 · next: x · blocker: none

> resume 2026-07-10 · done: e3 · next: x · blocker: none

> resume 2026-07-01 · done: e2 · next: x · blocker: none

> resume 2026-06-01 · done: e1 (oldest) · next: x · blocker: none
EOF

fail() { echo "✗ $1"; exit 1; }

# 1. no index.compact yet -> --fix creates it
[ -f "$BRAIN/index.compact" ] && fail "setup: index.compact should not exist yet"
out="$(python3 "$SKILL/brain-check" "$TMP" --fix 2>&1)" || fail "brain-check --fix errored: $out"
echo "$out" | grep -q "regenerated index.compact" || fail "did not report regenerating index.compact"
[ -f "$BRAIN/index.compact" ] || fail "index.compact was not created"

# 2. 8 entries in _session.md -> 3 rotated to _session.cold.md
echo "$out" | grep -q "rotated 3 old line(s)" || fail "did not report rotating 3 lines"
active="$(grep -c '^> resume' "$BRAIN/projects/acme/_session.md")"
[ "$active" -eq 5 ] || fail "_session.md should have 5 active entries, has $active"
grep -q "e8 (newest)" "$BRAIN/projects/acme/_session.md" || fail "newest entry missing from _session.md"
grep -q "e4" "$BRAIN/projects/acme/_session.md" || fail "5th-newest entry (e4) missing from _session.md"
grep -q "e3" "$BRAIN/projects/acme/_session.md" && fail "e3 should have been rotated out of _session.md"

[ -f "$BRAIN/projects/acme/_session.cold.md" ] || fail "_session.cold.md was not created"
cold="$(cat "$BRAIN/projects/acme/_session.cold.md")"
echo "$cold" | grep -q "e3" || fail "e3 missing from _session.cold.md"
echo "$cold" | grep -q "e1 (oldest)" || fail "e1 missing from _session.cold.md"
# newest-first: e3 (just rotated, newest of the overflow) must appear before e1 (oldest overall)
e3_line="$(grep -n 'e3 ' "$BRAIN/projects/acme/_session.cold.md" | head -1 | cut -d: -f1)"
e1_line="$(grep -n 'e1 (oldest)' "$BRAIN/projects/acme/_session.cold.md" | head -1 | cut -d: -f1)"
[ "$e3_line" -lt "$e1_line" ] || fail "_session.cold.md not newest-first after rotation"

# 3. idempotent: second --fix is a no-op
out2="$(python3 "$SKILL/brain-check" "$TMP" --fix 2>&1)" || fail "second --fix errored: $out2"
echo "$out2" | grep -q "nothing to fix" || fail "second --fix should report nothing to fix, got: $out2"

echo "✓ test-brain-check-fix: PASS"
