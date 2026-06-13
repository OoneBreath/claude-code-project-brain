# Decisions — acme-api (newest first)
# YYYY-MM: <chosen> > <rejected> — <why>   ·  read at planning time, not loaded eagerly

2026-05: Drizzle > Prisma — lighter, owns the SQL, no engine binary in the deploy image
2026-05: key-based Redis invalidation > TTL — TTL served stale data for up to a minute (see cache.md)
