# Project Brain — index

> Read this first. Drill into projects/<name>/<topic>.md only when you need detail.
> Status legend: ✓ verified · ✓ done · ⚠ in-progress · ✗ failed · ⨯ superseded

! never: deploy outside the EU (client is GDPR-bound)

## acme-api  (Node · tRPC · Drizzle · MySQL · Redis)
! never: store PII in Redis
> resume 2026-05-20 · done: refresh endpoint + rotation · next: client silent refresh on 401 · blocker: refresh-token denylist store (Redis vs DB) undecided
- cache  → Redis invalidation on record update   [✓ verified 2026-05-12 · v2] → projects/acme-api/cache.md
- auth   → tRPC session + refresh tokens          [⚠ in-progress 2026-05-20]   → projects/acme-api/auth.md

## acme-web  (React · TypeScript · Vite · Tailwind)
- (no topics yet)

# People
- jane-doe → client · Acme Corp · billing + annual contract  [active 2026-06-10] → people/jane-doe.md
