---
name: project-brain
description: >-
  Persistent, navigable project memory for Claude Code that survives across
  sessions and months. Use when the user wants to set up project memory ("set up
  project brain", "init brain"), recall how something was solved before ("how did
  we solve the cache", "what did we do with auth"), check whether a task was
  already done before redoing it ("did we already swap the logo?"), or save what
  was accomplished after finishing work. Especially for multi-project / multi-server
  setups where Claude must remember each project's stack, decisions and pitfalls
  without re-reading huge docs every session.
---

# Project Brain

Persistent project memory you (Claude) navigate through a **small index** instead of
re-reading large docs every session. Only the index is ever loaded eagerly; detail
lives in topic files read **on demand**. The index is your token budget — keep it small.

## Where the brain lives

A `.project-brain/` directory at the workspace (or repo) root:

```
.project-brain/
  index.md                  # THE MAP. Small. Read this FIRST. Projects -> topics -> status + pointer
  projects/
    <project>/
      <topic>.md            # Detail: problem, solution, status, version, tags
```

One brain can catalog **many projects** (a server hosting several repos) or just **one**
(a single repo). Multi-project is the default shape — each project is a section in `index.md`.

## How to behave every session

If `.project-brain/index.md` exists, **read it first** (it is small by design). It tells you
what each project is, its stack, and what has already been done. Drill into a topic file
only when you actually need that detail.

When this skill is invoked, choose the mode that matches the request:

### Mode: init — create the brain
Use when no `.project-brain/` exists, or the user says "set up / init project brain".
1. Create `.project-brain/` and `.project-brain/projects/`.
2. Detect projects in the workspace: top-level git repos, `package.json`, `pyproject.toml`,
   `go.mod`, `Cargo.toml`, `composer.json`, etc. For each, infer a name and stack.
3. Write `index.md` from `templates/index.md`, adding one section per detected project with
   its stack filled in. Leave the topic lists empty (you will fill them as work happens).
4. Append a tiny pointer to the workspace `CLAUDE.md` (create it if missing) using
   `templates/CLAUDE-snippet.md` — this is what makes future sessions read the map first.
   Keep this pointer to a few lines; do not duplicate content into it.
5. Tell the user what you created and how to use recall/save.

### Mode: recall — "how did we do X" / "did we already do X"
1. Read **only** `index.md`.
2. Find the matching project + topic line; note its `[status · date · vN]`.
3. Read **only** that one topic file for detail. Do not read sibling topic files.
4. If the user is asking to redo something already marked `✓ done` or `✓ verified`,
   **say so and ask**: repeat it, or make a new change? Never silently redo finished work.
5. For cross-cutting questions ("everything Redis", "all auth work"), grep topic-file
   frontmatter `tags:` rather than reading files whole.

### Mode: save — after completing work
1. Identify project + topic (one topic = one meaningful unit of work, not every tiny edit).
2. Create/update `projects/<project>/<topic>.md` from `templates/topic.md`:
   - If new: fill frontmatter + body.
   - If it existed: **bump `version`**, and keep the previous approach as a short
     `vN (superseded): ...` line in the body. Do not erase history.
   - Set `status` to the real outcome (see legend).
3. Update the matching line in `index.md`: status-with-outcome + date + version + pointer.
   Keep it to **one line**. All detail goes in the topic file, never in the index.
4. If the project section doesn't exist in `index.md` yet, add it.

## index.md format

```markdown
# Project Brain — index

> Read this first. Drill into projects/<name>/<topic>.md only when you need detail.

## acme-api  (Node · tRPC · Drizzle · MySQL · Redis)
- cache → Redis invalidation on ad update   [✓ verified 2026-05-12 · v2] → projects/acme-api/cache.md
- auth  → tRPC session handling             [⚠ in-progress 2026-04-30]   → projects/acme-api/auth.md

## acme-web  (React · TypeScript · Vite)
- (no topics yet)
```

**Status legend** (carry the OUTCOME, not just "done"):
- `✓ verified` — done and confirmed working
- `✓ done` — done, not independently confirmed
- `⚠ in-progress` — started, not finished
- `✗ failed` — tried, did not work (kept so we don't repeat it)
- `⨯ superseded` — replaced by a newer approach (see the topic's latest version)

## topic file frontmatter

```markdown
---
project: acme-api
topic: cache
tags: [redis, invalidation, performance]
status: verified          # verified | done | in-progress | failed | superseded
last_done: 2026-05-12
version: 2
---

**Problem:** stale Redis entries after an ad is updated.

**Solution (v2):** invalidate by key `ad:{id}` on write instead of a blanket flush.

**v1 (superseded):** 60s TTL — too slow, users saw stale data.
```

## Rules (the whole point — do not skip)

- **The index is the budget.** It is the only thing read eagerly. Keep each line to one line;
  push all detail into topic files read on demand. A bloated index defeats the purpose.
- **Status = outcome.** Distinguish "done and works" from "tried and failed" from "in progress".
- **Never silently redo finished work.** Surface what exists and ask.
- **Version, don't overwrite.** Keep the trail of what was tried and why it changed.
- **Tag topics** so cross-project recall works via grep on `tags:`.
- **Don't over-fragment.** One file per meaningful topic, not per keystroke. Dozens of files
  good; hundreds of micro-files bad.
- **Keep CLAUDE.md pointer tiny.** It points to the map; it is not a copy of the map.
