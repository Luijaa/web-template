#!/usr/bin/env python3
"""Draft the next CHANGELOG section from merged PRs (docs/release.md).

Collects the "## CHANGELOG" section of every PR merged since the last release tag,
groups the lines by Keep a Changelog category and proposes a SemVer version.
Prints a draft only — the writer merges duplicate lines, checks the wording and
the version, then edits CHANGELOG.md by hand. Never creates tags or releases.

usage: scripts/prepare-release.py [--since vX.Y.Z] [--repo owner/name] [--ref main]
needs: gh (authenticated, read access to the repo)
"""
from __future__ import annotations

import argparse
import datetime
import json
import re
import subprocess
import sys
from zoneinfo import ZoneInfo

CATEGORIES = ["Added", "Changed", "Deprecated", "Removed", "Fixed", "Security"]
LINE = re.compile(r"^\s*(?:[-*]\s*)?(" + "|".join(CATEGORIES) + r")\s*:\s*(.*\S)?\s*$", re.I)
CLOSES = re.compile(r"\b(?:close[sd]?|fix(?:e[sd])?|resolve[sd]?)\s+#(\d+)", re.I)
MERGE_MSG = re.compile(r"^Merge pull request #(\d+)|\(#(\d+)\)\s*$", re.M)


def gh(*args: str) -> str:
    return subprocess.run(["gh", *args], check=True, capture_output=True, text=True).stdout


def changelog_section(body: str) -> list[tuple[str, str]] | None:
    """(category, text) pairs; [] when the PR says "-" (no user impact); None when missing/empty."""
    body = re.sub(r"<!--.*?-->", "", body or "", flags=re.S)
    m = re.search(r"^##\s*CHANGELOG\s*$(.*?)(?=^##\s|\Z)", body, re.M | re.S | re.I)
    if not m:
        return None
    entries, saw_dash = [], False
    for line in m.group(1).splitlines():
        if line.strip() in ("-", "—", "ไม่มี"):
            saw_dash = True
            continue
        hit = LINE.match(line)
        if hit and hit.group(2):
            entries.append((hit.group(1).capitalize(), hit.group(2).strip()))
    if entries:
        return entries
    return [] if saw_dash else None


def bump(current: str | None, entries: list[tuple[str, str]], breaking: bool) -> tuple[str, str]:
    if not current:
        return "1.0.0", "release แรก — ใช้ 0.x ถ้ายังไม่ขึ้น production จริง"
    major, minor, patch = (int(x) for x in current.split("."))
    kinds = {c for c, _ in entries}
    if breaking or "Removed" in kinds:
        if major == 0:
            return f"0.{minor + 1}.0", "MINOR (มี breaking/Removed แต่ยังเป็น 0.x)"
        return f"{major + 1}.0.0", "MAJOR — มี Removed หรือ breaking change (`!` / BREAKING CHANGE)"
    if kinds & {"Added", "Deprecated"}:
        return f"{major}.{minor + 1}.0", "MINOR — มี Added/Deprecated"
    return f"{major}.{minor}.{patch + 1}", "PATCH — มีแค่ Changed/Fixed/Security (ตรวจว่า Changed ไม่ทำของเดิมใช้ไม่ได้)"


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--since", help="release tag to start from (default: latest release)")
    ap.add_argument("--repo", help="owner/name (default: current repo)")
    ap.add_argument("--ref", default="main")
    a = ap.parse_args()

    repo = a.repo or json.loads(gh("repo", "view", "--json", "nameWithOwner"))["nameWithOwner"]
    since = a.since
    if not since:
        rel = json.loads(gh("release", "list", "-R", repo, "--limit", "1", "--exclude-drafts", "--json", "tagName"))
        since = rel[0]["tagName"] if rel else None

    if since:
        commits = [json.loads(line) for line in gh(
            "api", "--paginate", f"repos/{repo}/compare/{since}...{a.ref}",
            "--jq", ".commits[] | {sha, message: .commit.message}").splitlines() if line]
        shas = {c["sha"] for c in commits}
        candidates = {int(x or y) for c in commits for x, y in MERGE_MSG.findall(c["message"])}
        # "(#N)" also appears in feature-branch commits that cite an issue, so keep only
        # numbers that are PRs merged into this range (merge or squash commit in the compare).
        numbers = []
        for n in sorted(candidates):
            try:
                p = json.loads(gh("api", f"repos/{repo}/pulls/{n}"))
            except subprocess.CalledProcessError:
                continue  # an issue, not a PR
            if p.get("merged_at") and p.get("merge_commit_sha") in shas:
                numbers.append(n)
    else:
        prs = json.loads(gh("pr", "list", "-R", repo, "--state", "merged", "--base", a.ref, "--limit", "500", "--json", "number"))
        numbers = sorted(p["number"] for p in prs)

    grouped: dict[str, list[str]] = {c: [] for c in CATEGORIES}
    all_entries, missing, no_impact, refs, breaking = [], [], [], {}, False
    for n in numbers:
        pr = json.loads(gh("pr", "view", str(n), "-R", repo, "--json", "number,title,body,url"))
        issues = sorted({int(i) for i in CLOSES.findall(pr["body"] or "")})
        if re.match(r"^\w+(\(.+\))?!:", pr["title"]) or "BREAKING CHANGE" in (pr["body"] or ""):
            breaking = True
        entries = changelog_section(pr["body"])
        if entries is None:
            missing.append(f"- #{n} {pr['title']} — ไม่มีหัวข้อ `## CHANGELOG` (อ่าน diff แล้วตัดสินเอง)")
            continue
        if not entries:
            no_impact.append(f"#{n}")
            continue
        tag = ", ".join([f"[#{i}]" for i in issues] + [f"[#{n}]"])
        for i in issues:
            refs[i] = f"https://github.com/{repo}/issues/{i}"
        refs[n] = f"https://github.com/{repo}/pull/{n}"
        for cat, text in entries:
            grouped[cat].append(f"- {text} ({tag})")
            all_entries.append((cat, text))

    current = since.lstrip("v") if since else None
    version, why = bump(current, all_entries, breaking)
    today = datetime.datetime.now(ZoneInfo("Asia/Bangkok")).date().isoformat()

    out = [f"# ร่าง CHANGELOG — {repo} ตั้งแต่ {since or 'เริ่มโปรเจกต์'} ถึง {a.ref} ({len(numbers)} PR)", ""]
    if not all_entries and not missing:
        out.append("ไม่มีอะไรที่ผู้ใช้เห็นตั้งแต่ release ล่าสุด — ยังไม่ต้อง release")
        print("\n".join(out))
        return
    out += [f"เสนอเวอร์ชัน: **{version}** — {why} (คนตัดสินเลขสุดท้าย)", "",
            f"## [{version}] - {today}", ""]
    for cat in CATEGORIES:
        if grouped[cat]:
            out += [f"### {cat}", "", *grouped[cat], ""]
    if missing:
        out += ["## ต้องตรวจเอง (ไม่อยู่ในร่างด้านบน)", "", *missing, ""]
    if no_impact:
        out += [f"ไม่มีผลต่อผู้ใช้ (`-`): {', '.join(no_impact)}", ""]
    prev = f"compare/{since}...v{version}" if since else f"releases/tag/v{version}"
    out += ["## ลิงก์ท้ายไฟล์", "", f"[Unreleased]: https://github.com/{repo}/compare/v{version}...HEAD",
            f"[{version}]: https://github.com/{repo}/{prev}",
            *[f"[#{k}]: {v}" for k, v in sorted(refs.items())], "",
            "ก่อนใช้: รวมบรรทัดที่พูดเรื่องเดียวกัน, เช็คถ้อยคำกับ CONTEXT.md, ลบ [#N] ที่มีอยู่แล้วในไฟล์ — ดู docs/release.md"]
    print("\n".join(out))


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as e:
        sys.exit(f"gh failed: {' '.join(e.cmd)}\n{e.stderr}")
