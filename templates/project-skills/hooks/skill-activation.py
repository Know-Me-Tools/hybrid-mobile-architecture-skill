#!/usr/bin/env python3
"""Advisory skill activation adapter generated from the Builder manifest.

This adapter never blocks a prompt and owns no lifecycle or mutation state.
Prometheus remains authoritative for project identity, signed KBD events, CRDT
claims/conflicts, pause, revise, resume, and cancel.
"""

from __future__ import annotations

import json
import os
from pathlib import Path
import sys


def manifest_path() -> Path | None:
    configured = os.environ.get("KNOWME_BUILDER_ACTIVATION_MANIFEST")
    candidates = [Path(configured) if configured else None]
    candidates.append(Path.cwd() / ".knowme-builder" / "activation-manifest.json")
    candidates.extend(
        ancestor / "templates" / "activation-manifest.json"
        for ancestor in Path(__file__).resolve().parents
    )
    return next((path for path in candidates if path and path.is_file()), None)


def matched_skills(prompt: str, manifest: dict[str, object]) -> list[str]:
    normalized = prompt.casefold()
    matches: list[str] = []
    for skill in manifest.get("skills", []):
        if not isinstance(skill, dict):
            continue
        name = skill.get("name")
        terms = skill.get("terms", [])
        if isinstance(name, str) and any(
            isinstance(term, str) and term.casefold() in normalized
            for term in terms
        ):
            matches.append(name)
    return matches


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0
    path = manifest_path()
    if path is None:
        return 0
    try:
        manifest = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return 0
    hits = matched_skills(str(payload.get("prompt", "") or ""), manifest)
    if not hits:
        return 0
    context = [
        "KnowMe Builder skills relevant to this prompt; invoke only those whose "
        "contract actually applies:",
        *[f"  - {name}" for name in hits],
    ]
    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "UserPromptSubmit",
                    "additionalContext": "\n".join(context),
                }
            }
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
