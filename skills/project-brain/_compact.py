"""_compact — shared logic for the dual-format index (ETAP 1).

index.md is the SINGLE SOURCE OF TRUTH (human-readable, hand-edited).
index.compact is GENERATED one-way from it (md -> compact, never the reverse) and
is what an agent reads at session start — same information, far fewer tokens.

This module is the one place the compact format is defined, imported by both
`brain-compact` (writes it) and `brain-check` (verifies it is up to date). Keeping
the renderer in one module is what stops the writer and the checker from drifting.

No third-party dependencies — Python 3 stdlib only.
"""
import os
import re

VALID_STATUS = ["verified", "done", "in-progress", "failed", "superseded"]

# md status word -> compact code. ✓ is split into ✓v/✓d because index.md uses one ✓
# glyph for both "verified" and "done"; the legend documents the suffix.
STATUS_CODE = {
    "verified": "✓v",
    "done": "✓d",
    "in-progress": "⚠",
    "failed": "✗",
    "superseded": "⨯",
}

HEADER_LINES = [
    "# Project Brain — compact index · generated from index.md · DO NOT EDIT",
    '# legend: "P <name>  <stack·tags>" then one line/topic: "<topic> <status> <date> <vN>"',
    "#   status: ✓v=verified ✓d=done ⚠=in-progress ✗=failed ⨯=superseded",
    "#   pointer = projects/<name>/<topic>.md  (inline only when it differs)",
]


def find_brain(arg):
    """Resolve a .project-brain dir from a path, a workspace containing one, or cwd."""
    cand = arg or "."
    if os.path.basename(os.path.normpath(cand)) == ".project-brain" and os.path.isdir(cand):
        return cand
    pb = os.path.join(cand, ".project-brain")
    if os.path.isdir(pb):
        return pb
    if os.path.isfile(os.path.join(cand, "index.md")):
        return cand
    return None


def read_text(path):
    with open(path, encoding="utf-8") as fh:
        return fh.read()


def _status_of(bracket):
    for s in VALID_STATUS:
        if s in bracket:
            return s
    return None


def parse_index(text):
    """Parse index.md into [{name, stack:[...], topics:[{slug,status,date,ver,pointer}]}]."""
    projects = []
    cur = None
    for line in text.splitlines():
        m = re.match(r"^##\s+(.*)$", line)
        if m:
            head = m.group(1).strip()
            mp = re.match(r"^(.*?)\s*\((.*)\)\s*$", head)
            if mp:
                name = mp.group(1).strip()
                stack = [p.strip() for p in re.split(r"·", mp.group(2)) if p.strip()]
            else:
                name, stack = head, []
            cur = {"name": name, "stack": stack, "topics": []}
            projects.append(cur)
            continue
        if cur is None:
            continue
        ls = line.strip()
        if not ls.startswith("-"):
            continue
        body = ls[1:].strip()
        if not body or body.startswith("("):  # "(no topics yet)" placeholder
            continue
        slug = re.split(r"→", body)[0].strip()
        slug = slug.split()[0] if slug.split() else slug
        status = date = ver = pointer = None
        mb = re.search(r"\[([^\]]*)\]", body)
        if mb:
            bracket = mb.group(1)
            status = STATUS_CODE.get(_status_of(bracket))
            md = re.search(r"\d{4}-\d{2}-\d{2}", bracket)
            date = md.group(0) if md else None
            mv = re.search(r"\bv(\d+)\b", bracket)
            ver = "v" + mv.group(1) if mv else None
        mptr = re.search(r"(projects/\S+\.md)", body)
        if mptr:
            pointer = mptr.group(1)
        cur["topics"].append(
            {"slug": slug, "status": status, "date": date, "ver": ver, "pointer": pointer}
        )
    return projects


def render_compact(text, gen_date=None):
    """Render index.md text into the compact representation (deterministic)."""
    projects = parse_index(text)
    out = list(HEADER_LINES)
    meta = "@src index.md"
    if gen_date:
        meta += f"  @gen {gen_date}"
    out.append(meta)
    out.append("")
    for p in projects:
        head = "P " + p["name"]
        if p["stack"]:
            head += "  " + "·".join(p["stack"])
        out.append(head)
        if not p["topics"]:
            out.append("  -")
            continue
        for t in p["topics"]:
            parts = [t["slug"]]
            for key in ("status", "date", "ver"):
                if t[key]:
                    parts.append(t[key])
            default = f"projects/{p['name']}/{t['slug']}.md"
            if t["pointer"] and t["pointer"] != default:
                parts.append(t["pointer"])
            out.append("  " + " ".join(parts))
    return "\n".join(out) + "\n"


def data_lines(compact_text):
    """The meaningful lines of a compact file: comments (#) and metadata (@) stripped.

    Used to compare two compact renderings for *content* equality while ignoring the
    legend and the volatile @gen timestamp — so the consistency check is deterministic.
    """
    return [
        ln for ln in compact_text.splitlines()
        if ln and not ln.startswith("#") and not ln.startswith("@")
    ]
