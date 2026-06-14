# Changelog

All notable changes to Project Brain are documented here. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/); the project uses semantic-ish versioning.

## [2.0.0] — 2026-06-14

Project Brain 2.0 — a major release built in ten stages. **Backward compatible:** every existing
`.project-brain/` keeps working (new fields are optional, new `brain-check` signals are advisory
warnings, exit 1 stays errors-only), and still **zero dependencies** (Python 3 stdlib only).

### Added
- **Dual-format index.** `index.md` stays the single, hand-edited source of truth; a generated
  `index.compact` (one-way, deterministic, 0-token Python — `brain-compact`) is what an agent reads at
  session start. Measured on the author's real 6-project / 15-topic brain: `index.md` 3415 B →
  `index.compact` 1655 B (**−52%, ~440 tokens**); each topic's index line shrinks ~106 → ~24 chars.
  The saving scales with how much prose your summaries carry — on a tiny demo brain the fixed legend
  overhead can make the compact *larger*, so it's for brains with real accumulated content. A missing
  or stale compact → agents fall back to `index.md`, so it never breaks.
- **HOT / WARM / COLD tiers** in the compact — automatic by recency plus a `{hot}` pin (max 3); WARM
  collapses to a one-liner once a brain has **> 15 active projects**; COLD (`{archived}`) is omitted.
  Bounds the eager token cost as a brain grows.
- **One-line session summary.** A `> resume <date> · done/next/blocker` line per project (surfaced in
  the compact for HOT as `~ …`), with rolling history in `_session.md` (5 lines, older → `.cold.md`).
- **Memory hygiene.** `! never:` hard rules (brain-wide or per-project, always in the compact);
  `trust:` extended to `human`=FACT | `ai-inferred` | `pref`; an over-long-topic (> 40 lines) warning;
  delta-load (an `@updated` header + a documented protocol — reload only what changed).
- **Decision log.** `_decisions.md` (per project) + brain-wide `decisions.md` — `YYYY-MM: chosen >
  rejected — why`, read at planning time so a rejected option isn't quietly re-proposed.
- **`brain-check --report`** (a grouped, readable rundown) and a **conflict detector** — flags a
  project that names two of the same mutually-exclusive tech (a relational DB or a host). Tuned on a
  real brain: dropped `oracle` because it matched `oracle.py`, not the database.
- **`brain-export`** — bundle the brain into ONE pasteable file for claude.ai / Gemini / ChatGPT, with
  `--project` / `--max-tokens` and **infra (IPs, ports, paths, hosts, secrets) redacted by default**
  (`--include-infra` to opt in).
- **`people/`** — agreements with humans (client / partner / vendor): `people/<slug>.md`, a `# People`
  index section, a `@people` compact block, a relationship status (`active|prospect|paused|closed`),
  validated like topics.
- **`brain-check --diff <date>`** — what changed since a date (topics, session lines, resume,
  decisions, people), read straight from the brain's own dates — no git.

### Changed
- **README rebuilt**: cross-tool header (Claude Code · Cursor · Windsurf · any file-reading agent),
  the unique advantages surfaced up front, a "How is this different from native Session Memory /
  ClaudeMem?" comparison, and a "What's new in 2.0" section.
- `brain-check`, `brain-compact`, and `brain-export` share one renderer module (`_compact.py`), so the
  compact format has a single definition and the writer and the validator can't drift.

## [1.1.2] — 2026-06-07

Docs and attribution only — no behavior change.

### Added
- `CONTRIBUTING.md` and `SECURITY.md` — how to contribute, and how to report a vulnerability
  privately (with a reminder never to store secrets in brain notes).
- README section **"Works across tools (same brain, different agents)"** — the same `.project-brain/`
  was read and written by Claude Code and by Windsurf (state persisted across a restart), and read by
  a third-party agent over SSH. Documents the honest limit: managing a brain needs a capable agentic
  model — a small local 7B model failed the read→use→write loop and hallucinated the brain's contents.

### Changed
- Author attribution now also travels with the **distributed** skill: `author:` in `SKILL.md`
  frontmatter + an attribution footer, plus an author/repo/license header in `install.sh`
  (previously attribution lived only in `LICENSE`, `README`, and the plugin manifest).

## [1.1.1] — 2026-06-05

### Changed
- The cross-project body-mention check is now **opt-in via `brain-check --strict`** (was on by
  default). On tightly-coupled multi-project brains, projects reference each other on purpose, so
  flagging every legitimate mention was noise. The precise guard — `project:` must match its folder —
  stays **always on**. Found by testing against a real interconnected brain before shipping.

## [1.1.0] — 2026-06-05

Backward compatible: every new field is optional and every new check is an advisory **warning**,
so existing brains keep passing `brain-check` untouched.

### Added
- **Provenance (`trust:`)** — mark a note `human` (a person confirmed it) or `ai-inferred` (the model
  wrote it without confirmation). Recall weighs it; the validator checks the value.
- **Staleness (`review_by:`)** — a finished topic past its `review_by` date (or, with none, older than
  a ~180-day horizon) is flagged "re-confirm before trusting".
- **Cross-project guard** — `brain-check` warns when a topic's `project:` doesn't match its folder, or
  when a topic name-drops another project without declaring it in `cross_refs:`.
- **`brain-nudge` Stop hook** — reminds you to save when a session changed files but the brain wasn't
  updated. It only suggests; it never writes to the brain and never blocks. Auto-wired for plugin
  installs via `hooks/hooks.json`; skill-only users can add a one-line `Stop` hook.
- **Plugin manifest** (`.claude-plugin/plugin.json`) — name, version, author, homepage, repository,
  license, keywords; enables installing as a Claude Code plugin.

### Changed
- `brain-check` extended with the provenance, staleness, and cross-project checks (still zero-dep).
- Topic template and `SKILL.md` document the new optional fields and the suggest-don't-save rule.

## [1.0.0] — 2026-06-01

Initial public release.

### Added
- The `.project-brain/` convention: a small `index.md` map plus on-demand `projects/<name>/<topic>.md`
  topic files (cold storage — only the index is loaded eagerly).
- `project-brain` skill with `init` / `recall` / `save` modes.
- Status-with-outcome legend (`verified` / `done` / `in-progress` / `failed` / `superseded`).
- Versioning instead of overwriting; archiving instead of deleting.
- `brain-check` validator (pointers resolve, frontmatter valid, index↔topic status in sync).
