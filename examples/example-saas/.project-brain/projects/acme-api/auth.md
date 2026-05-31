---
project: acme-api
topic: auth
tags: [auth, sessions, tokens]
status: in-progress
last_done: 2026-05-20
version: 1
---

**Problem:** sessions expire abruptly mid-request and users get logged out; we want short-lived
access tokens with silent refresh.

**Approach (in progress):** tRPC middleware issues a 15-minute access token plus a rotating
refresh token stored httpOnly. The refresh endpoint and rotation are wired up; client-side silent
refresh on 401 is **not done yet**.

**Open:** decide where to keep the refresh-token denylist (Redis vs DB) and add tests for the
rotation edge case (two tabs refreshing at once).
