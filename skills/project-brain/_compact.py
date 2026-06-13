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
    '# legend: "<P> <name>  <stack·tags>" then one line/topic: "<topic> <status> <date> <vN>"',
    "#   status: ✓v=verified ✓d=done ⚠=in-progress ✗=failed ⨯=superseded",
    "#   pointer = projects/<name>/<topic>.md  (inline only when it differs)",
    "#   tiers:  P+ = HOT (active, full)  ·  P = WARM  ·  COLD (archived) omitted — read on demand",
    "#   when active projects > 15, WARM collapses to: P <name> <stack> · N topics, last <date>",
]

HOT_MAX = 3            # at most this many projects are HOT (always full in compact)
PROJECT_THRESHOLD = 15  # above this many ACTIVE projects, WARM collapses to keep compact small


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
            # optional trailing tier markers, e.g. "## billing (Go) {hot}" or "{archived}"
            markers = set()
            for grp in re.findall(r"\{([^}]*)\}", head):
                markers.update(t.lower() for t in re.split(r"[,\s]+", grp.strip()) if t)
            head = re.sub(r"\s*\{[^}]*\}", "", head).strip()
            mp = re.match(r"^(.*?)\s*\((.*)\)\s*$", head)
            if mp:
                name = mp.group(1).strip()
                stack = [p.strip() for p in re.split(r"·", mp.group(2)) if p.strip()]
            else:
                name, stack = head, []
            cur = {
                "name": name,
                "stack": stack,
                "topics": [],
                "hot": "hot" in markers,
                "archived": "archived" in markers or name.startswith("_"),
            }
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


def _recency(project):
    """A project's most recent activity = the latest topic date (YYYY-MM-DD sorts lexically)."""
    dates = [t["date"] for t in project["topics"] if t["date"]]
    return max(dates) if dates else ""


def assign_tiers(projects):
    """Annotate each project with 'recency' and 'tier' (HOT | WARM | COLD). Deterministic.

    COLD  = archived ({archived} marker or a name starting with '_') — never in compact.
    HOT   = up to HOT_MAX active projects: {hot}-pinned first, then the most recently active.
    WARM  = the remaining active projects.
    """
    for p in projects:
        p["recency"] = _recency(p)
    active = [p for p in projects if not p["archived"]]
    pinned = [p for p in active if p["hot"]]
    rest = [p for p in active if not p["hot"]]
    # recency desc, name asc as a stable tiebreak — order of index.md must not change the tiers
    rest = sorted(sorted(rest, key=lambda p: p["name"]), key=lambda p: p["recency"], reverse=True)
    hot_ids = {id(p) for p in (pinned + rest)[:HOT_MAX]}
    for p in projects:
        if p["archived"]:
            p["tier"] = "COLD"
        elif id(p) in hot_ids:
            p["tier"] = "HOT"
        else:
            p["tier"] = "WARM"
    return projects


def render_compact(text, gen_date=None):
    """Render index.md text into the compact representation (deterministic, tier-aware)."""
    projects = parse_index(text)
    assign_tiers(projects)
    active = [p for p in projects if p["tier"] != "COLD"]
    collapse_warm = len(active) > PROJECT_THRESHOLD

    out = list(HEADER_LINES)
    meta = "@src index.md"
    if gen_date:
        meta += f"  @gen {gen_date}"
    out.append(meta)
    out.append("")
    for p in projects:
        if p["tier"] == "COLD":
            continue  # archived: read on demand, never weigh on the eager budget
        head = ("P+ " if p["tier"] == "HOT" else "P ") + p["name"]
        if p["stack"]:
            head += "  " + "·".join(p["stack"])
        if p["tier"] == "WARM" and collapse_warm:
            n = len(p["topics"])
            tail = f"  · {n} topic{'' if n == 1 else 's'}"
            if p["recency"]:
                tail += f", last {p['recency']}"
            out.append(head + tail)
            continue
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
