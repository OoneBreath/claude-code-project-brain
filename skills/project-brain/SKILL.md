---
name: project-brain
version: 1.1.2
author: Slawomir Luzny <info@fixflex.co.uk> (https://fixflex.co.uk)
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

**Default is a LIGHT init — keep it cheap. Do NOT read the codebase.**
1. Create `.project-brain/` and `.project-brain/projects/`.
2. Detect projects from cheap signals only: top-level dirs, git repos, `package.json`,
   `pyproject.toml`, `go.mod`, `Cargo.toml`, `composer.json`. Infer name + stack from those
   files — do not read source to do this. **Skip non-project directories** —
   `node_modules`, `venv`, `.venv`, `target`, `dist`, `build`, `.cache`, `snap`,
   `android-sdk`, `flutter`, `.git` — and anything that is clearly a toolchain or data dump,
   not a codebase. When unsure, ask rather than adding noise.
3. Write `index.md` from `templates/index.md`, one section per project with the stack filled in
   and the topic list empty. Topics get filled as real work happens (via `save`).
4. Append a tiny pointer to the workspace `CLAUDE.md` (create it if missing) using
   `templates/CLAUDE-snippet.md` — this is what makes future sessions read the map first.
   Keep the pointer to a few lines; never duplicate the map into it.
5. Tell the user what you created, and that the brain fills in as you work.

**Optional DEEP backfill — only when the user explicitly asks** ("scan the project / populate the
brain from the codebase"). This pre-fills topic files by reading the project, so it spends real
tokens once.

To keep it cheap and accurate, **read the project's own distilled docs first** — `README`,
`CHANGELOG`, `docs/`, ADRs, design notes — and fall back to reading source only for the gaps. The
result reflects what the project actually documents: a well-documented repo backfills richer than a
bare one. It summarises what's there; it does not invent context. Set the user's expectations
accordingly — this is not magic, and two different projects will produce different depth.

Before starting: warn the user it is a one-time upfront cost that pays back on every later session,
and offer to scope it to **one project at a time** rather than the whole workspace.

### Mode: recall — "how did we do X" / "did we already do X"
1. Read **only** `index.md`.
2. Find the matching project + topic line; note its `[status · date · vN]`.
3. Read **only** that one topic file for detail. Do not read sibling topic files.
4. If the user is asking to redo something already marked `✓ done` or `✓ verified`,
   **say so and ask**: repeat it, or make a new change? Never silently redo finished work.
5. **Weigh how much to trust it** before acting on it (see *Provenance & staleness*):
   - `trust: human` = a person vouched for this — treat as reliable. Absent or `trust: ai-inferred`
     = the AI wrote it without confirmation — useful, but verify before you rely on it.
   - Past its `review_by`, or `last_done` long ago = possibly stale. Say "this was confirmed back
     in <date> — worth re-checking?" rather than presenting it as current fact.
6. For cross-cutting questions ("everything Redis", "all auth work"), grep topic-file
   frontmatter `tags:` rather than reading files whole.

### Mode: save — after completing work
1. Identify project + topic (one topic = one meaningful unit of work, not every tiny edit).
2. Create/update `projects/<project>/<topic>.md` from `templates/topic.md`:
   - If new: fill frontmatter + body.
   - If it existed: **bump `version`**, and keep the previous approach as a short
     `vN (superseded): ...` line in the body. Do not erase history.
   - Set `status` to the real outcome (see legend).
   - Set `trust` honestly: `human` only when the user actually confirmed it (or you verified it
     end-to-end); otherwise `ai-inferred`. Never label your own guess `human`.
   - Make sure `project:` equals the folder name — a mismatch is how projects get mixed up.
   - Optionally set `review_by:` for facts that age (credentials, versions, "current" anything).
3. Update the matching line in `index.md`: status-with-outcome + date + version + pointer.
   Keep it to **one line**. All detail goes in the topic file, never in the index.
4. If the project section doesn't exist in `index.md` yet, add it.
5. Run `brain-check` (see Validate) so the index line and the topic file can't silently drift.

### Validate — keep the two sources of truth in sync
Run the bundled validator any time, and especially after a `save`:
```
python3 ~/.claude/skills/project-brain/brain-check [workspace]
```
It checks that every pointer resolves, frontmatter is well-formed with a valid status, and the
status in `index.md` matches the status in the topic file. It also flags (as advisory warnings)
an invalid `trust:`, a topic past its staleness horizon, and a `project:` that doesn't match its
folder. Add `--strict` to additionally flag topics that name-drop another project without a
`cross_refs:` (off by default — noisy on coupled brains). Exit code 1 = real errors to fix; warnings
(staleness, provenance, cross-project, thin topics, orphans, over-fragmentation) are advisory.

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

## Provenance & staleness — memory that knows what it doesn't know

`status` answers *"did the work succeed?"*. Two more (optional) fields answer *"can I trust this
note, and is it still current?"* — the thing flat notes never tell you:

- **`trust:`** — who vouches for the note. `human` = a person confirmed it (gospel). `ai-inferred`
  (or absent) = the AI wrote it without confirmation; useful, but verify before relying on it. This
  keeps a model's own guesses from hardening into "facts" just because they're written down.
- **`review_by:`** — an optional expiry date. Past it (or, with no `review_by`, once `last_done` is
  older than ~180 days), `brain-check` flags a *finished* topic as stale: re-confirm before
  trusting. Memory with an expiry date, instead of treating last year's note as still true.

When you recall a topic, factor both in (see Mode: recall). When you save, set `trust` honestly and
add `review_by` to anything that ages — credentials, versions, "current" prod state.

## Don't mix projects up — the cross-project guard

The multi-project case is where memory rots into wrong answers: a fact from project A applied to
project B. Two guards:
- **Always on:** a topic's `project:` **must equal the folder** it lives under (`projects/<project>/`).
  `brain-check` warns on any mismatch — that's almost always a misfiled, contaminating note.
- **Opt-in (`brain-check --strict`):** flags a topic that name-drops another known project in its body
  without declaring it in `cross_refs:`. Off by default on purpose — in tightly-coupled setups
  projects reference each other legitimately, so this is noise unless you want strict isolation.

## topic file frontmatter

```markdown
---
project: acme-api         # MUST match the folder under projects/
topic: cache
tags: [redis, invalidation, performance]
status: verified          # verified | done | in-progress | failed | superseded  (did the work succeed?)
trust: human              # human | ai-inferred  (who vouches for this? absent = ai-inferred)
last_done: 2026-05-12
review_by: 2026-11-12      # optional: re-confirm by this date, else flagged stale
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
- **Reference code by stable anchors, not line numbers.** Point to `file.ts` + a function or
  symbol name, not `file.ts:273` — line numbers rot on the first refactor. This is narrative
  memory, not a live index, so write references that survive editing.
- **Be honest about provenance.** Mark `trust: human` only when a person actually confirmed it.
  Your own inference is `ai-inferred` — writing it down does not make it true.
- **Keep the map clean — suggest, don't auto-save.** The brain is valuable because a human chose
  what is worth remembering. Never bulk-dump a session into it. When work is done, *propose* what to
  save and let the user decide. (The bundled `brain-nudge` Stop hook only reminds — it cannot write.)
- **Keep CLAUDE.md pointer tiny.** It points to the map; it is not a copy of the map.

## Optional: the save reminder (brain-nudge hook)

A bundled `Stop` hook (`brain-nudge`) reminds you to keep the brain current. When a session changed
files but `index.md` wasn't updated, it surfaces a one-time note: *"you did work — want to save any
of it?"*. It **never writes to the brain and never blocks** — auto-saving everything would turn the
map into a swamp. It only nudges; the human still decides what is worth keeping.

- Installed as a **plugin**, the hook is wired up automatically (`hooks/hooks.json`).
- Installed as a **skill only**, add it yourself in `~/.claude/settings.json`:
  ```json
  { "hooks": { "Stop": [ { "hooks": [
    { "type": "command", "command": "~/.claude/skills/project-brain/brain-nudge" }
  ] } ] } }
  ```

## Keeping the brain lean — archiving

Topic files are **cold storage**: only `index.md` is read eagerly, so a topic file costs nothing
until something opens it. That means the brain's per-session weight is bounded by the **index**,
not by the total amount of history you keep — a brain with hundreds of topic files is still cheap
as long as the index stays a list of one-liners. This is the whole reason it doesn't rot like a
flat `notes.md` that grows heavier every session.

So you almost never need to delete anything. When a topic is genuinely dead (obsolete, replaced,
no longer a project), **archive instead of delete**:

1. Remove its **one line** from `index.md` — this is what actually frees eager-token budget.
2. **Keep the topic file** (optionally move it to `projects/<project>/_archive/`). History survives
   and is still findable by grep if it's ever needed again.

Never auto-delete a user's notes — durable memory is the point. Archiving is a manual, occasional
tidy: the index is the only thing that needs to stay lean, and dropping a line from it is enough.
Use `last_done` dates and the `⨯ superseded` status to spot what's stale.

---

*Project Brain — built and maintained by **Slawomir Luzny** ([fixflex.co.uk](https://fixflex.co.uk)).
MIT licensed. Contributions and issues: https://github.com/OoneBreath/claude-code-project-brain*
