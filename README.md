# Project Brain — persistent memory for Claude Code

**Stop re-explaining your projects to the AI every session.**

![Project Brain in action — Claude reads the project map, recalls how the cache fix was done, and refuses to silently redo verified work](docs/demo.gif)

Project Brain is a [Claude Code](https://claude.com/claude-code) skill that gives Claude a
small, navigable map of your projects — their stack, decisions, pitfalls, and what's already
been done — so it stops forgetting, stops mixing projects up, and stops re-reading a
1000-line README into context on every single task.

It is **not** a database, a server, or another AI wrapper. It's a convention plus a skill:
a `.project-brain/` folder of plain markdown that Claude reads through an index, loading
detail only when it's actually needed.

---

## The problem

Every new Claude Code session, on every project:

- explain the architecture
- explain the deployment
- explain the stack
- explain the history
- explain the known pitfalls

…again. And after a few hours of work the model starts mixing details between projects —
this one is FastAPI + Postgres, that one is Node + tRPC + MySQL — and quietly redoing things
you already finished last week.

## The fix

```
.project-brain/
  index.md                  # a small MAP: projects → topics → status + pointer
  projects/
    <project>/
      <topic>.md            # the detail, read only when needed
```

Claude reads the **small index** first. When you ask *"how did we solve the cache issue?"* it
follows one pointer to one file — not the whole knowledge base. When you ask it to *"swap the
logo"* and the map says that was done and verified three days ago, it tells you and asks
whether you want to repeat it or do something new.

**Before**
> *Every session:* re-explain architecture, deployment, stack, history, pitfalls.

**After**
> *Claude already knows:* the stack, what was done, what worked, what failed, what's in progress —
> and reads only the one topic relevant to your question.

---

## What it actually saves

Be honest with yourself about why you'd use this:

- **Fewer tokens — when it applies.** If you currently keep everything in a giant always-loaded
  doc, splitting into a small index + on-demand topic files genuinely cuts per-session context.
  If you don't, the token win is modest.
- **Fewer hallucinations.** The map is an anchor. The model stops inventing your deployment or
  swapping one project's stack for another's.
- **Multi-month memory.** Come back to a project after three months and Claude still knows how it
  works — without you pasting a kilometre of README.

## Two things make it better than a flat notes file

1. **Status carries the outcome, not just "done":** `✓ verified` vs `✗ failed` vs `⚠ in-progress`.
   The model knows the difference between *"done and works"* and *"we tried that and it broke."*
2. **Versioning, not overwriting.** When an approach is replaced, the old one is kept as a
   superseded note — so the trail of *what was tried and why it changed* survives.

---

## Install

```bash
git clone https://github.com/OoneBreath/claude-code-project-brain.git
cd claude-code-project-brain
./install.sh        # copies the skill into ~/.claude/skills/  (run on each machine)
```

**Start a new Claude Code session after installing** — skills are loaded at session start, so the
skill won't show up in a session that was already open.

Then, in a session inside your workspace:

```
/project-brain        →  "init"     set up .project-brain/ and detect your projects
/project-brain        →  "how did we solve X?"   recall through the index
```

Run `init` once **per workspace**. The skill is installed per machine (`~/.claude/skills/`), but the
memory (`.project-brain/`) lives per project — so on a server hosting several repos, point `init` at
the workspace root and it catalogs them all in one brain.

After that you mostly don't think about it: Claude reads the map at the start, checks it before
redoing work, and updates it when a unit of work is done.

> **A note on the first run.** `init` is light by design — it detects your projects from
> `package.json` / `pyproject.toml` / git and writes a small index. It does **not** read your
> source, so it's cheap. The brain then fills in gradually as you actually work.
>
> If you want Claude to pre-populate the brain by reading an existing codebase ("deep backfill"),
> that's a one-time upfront token cost — Claude has to read your code and docs to summarise them.
> Think of it as an investment: you pay tokens once to get organised, and every later session is
> cheaper and sharper. Scope it to one project at a time. The skill will warn you before doing it.
>
> The result reflects what your project actually documents — a repo with a solid README/CHANGELOG
> backfills richer than a bare one. It summarises what's there; it doesn't invent context. So expect
> the depth to vary by project, not a fixed result.

## How it works

- The skill lives in `~/.claude/skills/project-brain/` (personal scope, per machine).
- `init` creates `.project-brain/` in your workspace, detects projects (git repos, `package.json`,
  `pyproject.toml`, …), and drops a tiny pointer into your `CLAUDE.md` so future sessions read the
  map first.
- One brain can catalog **many projects on one server** or just a single repo.
- Everything is plain markdown you can read, edit, and commit yourself.
- A bundled `brain-check` validator (`python3 ~/.claude/skills/project-brain/brain-check`) catches
  broken pointers, malformed frontmatter, and index↔topic status drift — run it after big changes.
- **It doesn't bloat over time.** Topic files are cold storage — only the index is ever loaded
  eagerly, so the per-session cost is bounded by the index, not by how much history you keep.
  Unlike a flat `notes.md` that gets heavier every session, the brain stays light. To tidy a dead
  topic you *archive* it (drop its one line from the index, keep the file) — nothing auto-deletes.

> **Your brain is yours — and it's private by default.** A real `.project-brain/` ends up holding
> infra details (DB names, ports, server paths, hostnames). Decide per project whether to commit it
> (travels with the repo, shared with your team) or keep it out of version control. This repo ships
> a `.gitignore` that ignores `.project-brain/` precisely so the skill's own repo never accidentally
> carries a real brain.

---

## Background

Project Brain came out of running several independent SaaS products at once — among them
[Sentinel AI](https://sentinel-ai.info) (server security & database autopilot) and
[24ad.info](https://24ad.info) (an AI-assisted classifieds platform), alongside a multi-server
fleet-intelligence backend, an anti-spam service and a content tool. When every project carries
thousands of lines of context, the cost of the AI forgetting — or quietly mixing two projects up
— is real. This is the working memory that keeps them straight. The pattern isn't theoretical.

## License

MIT — see [LICENSE](LICENSE).
