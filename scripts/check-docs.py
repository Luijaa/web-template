#!/usr/bin/env python3
"""Structure check for design docs, ADRs and the docs index (make docs-check).

Every agent and person must produce the same shape of documents, so this checks
the parts a reviewer would otherwise have to eyeball: required headings, status
values, leftover TODOs in approved work and index entries. Standard library only.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

# optional argument: repo root to check (default: the repo this script lives in)
ROOT = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
errors: list[str] = []


def err(path: Path, msg: str) -> None:
    errors.append(f"{path.relative_to(ROOT)}: {msg}")


def front_matter(path: Path, text: str) -> dict[str, str]:
    m = re.match(r"---\n(.*?)\n---\n", text, re.S)
    if not m:
        err(path, "missing front matter (--- … ---)")
        return {}
    meta = {}
    for line in m.group(1).splitlines():
        if ":" in line:
            key, value = line.split(":", 1)
            meta[key.strip()] = value.split(" #", 1)[0].strip().strip('"')
    return meta


def sections(text: str) -> dict[int, str]:
    """Body of each '## N. title' section keyed by N."""
    parts = re.split(r"^## (\d+)\. .*$", text, flags=re.M)
    return {int(parts[i]): parts[i + 1] for i in range(1, len(parts) - 1, 2)}


def check_design() -> None:
    folder = DOCS / "design"
    if not folder.is_dir():
        return
    index = (folder / "README.md").read_text(encoding="utf-8") if (folder / "README.md").exists() else ""
    for path in sorted(folder.glob("*.md")):
        if path.name in ("README.md", "template.md"):
            continue
        text = path.read_text(encoding="utf-8")
        meta = front_matter(path, text)
        status = meta.get("status", "")
        kind = meta.get("type", "")
        if not (status in ("draft", "proposed", "approved") or status.startswith("superseded by ")):
            err(path, f"status must be draft | proposed | approved | superseded by <file> (got '{status}')")
        if kind not in ("system", "feature"):
            err(path, f"type must be system | feature (got '{kind}')")
        if kind == "system" and path.name != "system.md":
            err(path, "type: system belongs in docs/design/system.md")
        if kind == "feature" and not re.match(r"^\d+-[a-z0-9-]+\.md$", path.name):
            err(path, "feature design file name must be <epic number>-<slug>.md")
        if path.name not in index:
            err(path, "not listed in docs/design/README.md")

        body = re.sub(r"<!--.*?-->", "", text, flags=re.S)  # template guidance lives in comments
        secs = sections(body)
        numbers = [int(n) for n in re.findall(r"^## (\d+)\. ", text, flags=re.M)]
        if numbers != list(range(1, 16)):
            err(path, f"needs headings '## 1.' … '## 15.' once each, in order (found {numbers})")
        threat = secs.get(10, "")
        for word in ("Spoofing", "Tampering", "Repudiation", "Information disclosure",
                     "Denial of service", "Elevation of privilege"):
            if word.lower() not in threat.replace("**", "").lower():
                err(path, f"section 10 (threat model) is missing the {word} row")
        if kind == "system" and secs.get(15, "").strip().startswith("ไม่เกี่ยว"):
            err(path, "section 15 is required for type: system")

        if status in ("proposed", "approved"):
            if "TODO" in body:
                err(path, f"status {status} but TODO is still present")
        if status == "approved":
            if not meta.get("approved-by"):
                err(path, "status approved needs approved-by")
            if "- [ ]" in secs.get(14, ""):
                err(path, "status approved but section 14 still has open questions (- [ ])")


ADR_STATUS = re.compile(r"^(proposed|accepted|rejected|deprecated|superseded by ADR-\d{4})$")


def check_adr() -> None:
    folder = DOCS / "adr"
    if not folder.is_dir():
        return
    index = (folder / "README.md").read_text(encoding="utf-8")
    for path in sorted(folder.glob("*.md")):
        if path.name in ("README.md", "template.md"):
            continue
        if not re.match(r"^\d{4}-[a-z0-9-]+\.md$", path.name):
            err(path, "ADR file name must be NNNN-<slug>.md")
        meta = front_matter(path, path.read_text(encoding="utf-8"))
        if meta and not ADR_STATUS.match(meta.get("status", "")):
            err(path, f"ADR status must be proposed | accepted | rejected | deprecated | superseded by ADR-NNNN (got '{meta.get('status')}')")
        if path.name not in index:
            err(path, "not listed in docs/adr/README.md")


def check_index() -> None:
    index_path = DOCS / "README.md"
    if not index_path.exists():
        return
    index = index_path.read_text(encoding="utf-8")
    for path in sorted(DOCS.iterdir()):
        if path.name.startswith(".") or path.name == "README.md":
            continue
        name = path.name + "/" if path.is_dir() else path.name
        if path.suffix == ".md" or path.is_dir():
            if f"({name}" not in index and f"`{name}" not in index:
                err(path, "not listed in docs/README.md (Diátaxis index)")


check_design()
check_adr()
check_index()
if errors:
    print("docs-check failed:")
    for e in errors:
        print(f"  - {e}")
    sys.exit(1)
print("docs-check: ok")
