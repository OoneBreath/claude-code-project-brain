#!/usr/bin/env bash
# brain-find: matches by tag/slug/project (fast path) and, with --body, full text.
set -euo pipefail

SKILL="$(cd "$(dirname "${BASH_SOURCE[0]}")/../skills/project-brain" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

BRAIN="$TMP/.project-brain"
mkdir -p "$BRAIN/projects/acme" "$BRAIN/people"

cat > "$BRAIN/index.md" <<'EOF'
# Project Brain — index

## acme  (Go)
- cache → cache notes  [✓ verified 2026-01-10 · v1] → projects/acme/cache.md
- billing → billing notes  [⚠ in-progress 2026-01-12 · v1] → projects/acme/billing.md

# People
- jane-doe → client  [active 2026-01-10]  → people/jane-doe.md
EOF

cat > "$BRAIN/projects/acme/cache.md" <<'EOF'
---
project: acme
topic: cache
tags: [redis, invalidation, performance]
status: verified
version: 1
---
Cache invalidation notes long enough to not be a thin topic. Padding padding padding
padding padding padding padding padding padding padding padding padding padding padding
padding padding padding padding padding padding padding padding padding padding padding.
EOF

cat > "$BRAIN/projects/acme/billing.md" <<'EOF'
---
project: acme
topic: billing
tags: [stripe, invoices]
status: in-progress
version: 1
---
Stripe integration notes long enough to not be a thin topic. Padding padding padding
padding padding padding padding padding padding padding padding padding padding padding
padding padding padding padding padding padding padding padding padding padding padding.
Mentions a rare word: zzflorble, only findable via --body.
EOF

cat > "$BRAIN/people/jane-doe.md" <<'EOF'
---
person: jane-doe
tags: [contract, primary-contact]
status: active
version: 1
---
Padding padding padding padding padding padding padding padding padding padding padding
padding padding padding padding padding padding padding padding padding padding padding.
EOF

fail() { echo "✗ $1"; exit 1; }

# 1. tag match (fast path)
out="$(python3 "$SKILL/brain-find" redis "$TMP" 2>&1)" || fail "brain-find errored: $out"
echo "$out" | grep -q "cache.md" || fail "tag match did not find cache.md"
echo "$out" | grep -q "billing.md" && fail "tag match should not find billing.md for 'redis'"

# 2. slug match
out="$(python3 "$SKILL/brain-find" billing "$TMP" 2>&1)"
echo "$out" | grep -q "billing.md" || fail "slug match did not find billing.md"

# 3. person match (tags + project field)
out="$(python3 "$SKILL/brain-find" contract "$TMP" 2>&1)"
echo "$out" | grep -q "jane-doe.md" || fail "tag match did not find jane-doe.md"

# 4. no match without --body
out="$(python3 "$SKILL/brain-find" zzflorble "$TMP" 2>&1)"
echo "$out" | grep -q "billing.md" && fail "rare body word should NOT match without --body"
echo "$out" | grep -qi "no matches" || fail "expected 'no matches' without --body, got: $out"

# 5. --body finds it
out="$(python3 "$SKILL/brain-find" zzflorble "$TMP" --body 2>&1)"
echo "$out" | grep -q "billing.md" || fail "--body did not find zzflorble in billing.md"

# 6. case-insensitive
out="$(python3 "$SKILL/brain-find" REDIS "$TMP" 2>&1)"
echo "$out" | grep -q "cache.md" || fail "match should be case-insensitive"

echo "✓ test-brain-find: PASS"
