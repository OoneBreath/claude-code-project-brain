---
project: acme-api
topic: cache
tags: [redis, invalidation, performance]
status: verified
trust: human
last_done: 2026-05-12
review_by: 2026-11-12
version: 2
---

**Problem:** after a record was updated, the API kept serving stale data from Redis;
users saw old values for up to a minute.

**Solution (v2):** invalidate the specific key `record:{id}` inside the write transaction
instead of relying on TTL. Confirmed: updates are now reflected immediately.

**v1 (superseded):** 60s TTL on cached records — too slow, users still saw stale data.
