# Security Policy

## Reporting a vulnerability

If you discover a security issue in Project Brain, please report it privately
rather than opening a public issue.

- **Email:** info@fixflex.co.uk
- Include: a description of the issue, steps to reproduce, and the affected
  version (see `version` in `SKILL.md` / `.claude-plugin/plugin.json`).

You can expect an acknowledgement within a few days. Once the issue is confirmed
and fixed, the change will be noted in `CHANGELOG.md`.

## Scope

Project Brain is a Claude Code skill that reads and writes plain-text Markdown
files under a `.project-brain/` directory in your project, plus an optional
`Stop` hook (`brain-nudge`) that only *suggests* saving — it never writes on its own.

Things worth keeping in mind:

- **Your brain files are plain text.** Do not store secrets, API keys, or
  passwords in `.project-brain/` notes — treat them like any other committed
  source file. Use placeholders (e.g. `<API_KEY>`) instead.
- The skill runs with the same permissions as your Claude Code session and does
  not transmit your notes anywhere; everything stays in your repo.

## Supported versions

Only the latest released version receives fixes. Please update before reporting.
