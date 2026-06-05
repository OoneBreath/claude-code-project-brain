# Changelog

All notable changes to Project Brain are documented here. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/); the project uses semantic-ish versioning.

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
